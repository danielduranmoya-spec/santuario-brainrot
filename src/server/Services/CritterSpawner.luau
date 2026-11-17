--!strict
-- Bichos salvajes: aparecen dentro de cada bóveda (según su temática, suerte y rareza), pasean
-- despacio, se atrapan con el minijuego y se llevan al santuario.
--   * Solo se pueden atrapar en bóvedas que el jugador ha abierto.
--   * Al aparecer se sortean sus dos mutaciones, Color y Tamaño (Config/Mutations); los eventos de
--     mutación (Services/MutationEvents) suben el % de algunos colores. Las dos se guardan con el
--     bicho y multiplican lo que produce. Los bichos grandes tienen la zona verde más pequeña.
--   * Los bichos de las bóvedas sin fin (5ª en adelante) valen más: llevan un multiplicador que se
--     guarda con ellos en el santuario.
--
-- Captura (el servidor manda):
--   1. El jugador activa el ProximityPrompt "Atrapar". El servidor comprueba distancia, cooldown,
--      bóveda abierta; bloquea el bicho y elige la zona verde (catchWindow de su
--      rareza + mejora Red, o el máximo con el pase Red Dorada, menos la penalización por tamaño).
--   4. Con el pase Red Titánica, al atraparlo puede crecer un tamaño (Config/Mutations).
--   2. El cliente solo dibuja la barra y, al pulsar, envía "intento" + el momento en que pulsó.
--   3. El servidor recorta ese momento a una ventana corta antes de recibirlo y calcula él mismo dónde
--      estaba la aguja con el tiempo de servidor (CatchBar). Si estaba en verde, lo atrapas.
--
-- Eventos (Services/LiveEvents): SpawnEvent crea bichos especiales (el legendario de servidor) que
-- no cuentan para el tope de cada bóveda y tienen su propio tiempo de vida; SetSpawnBoost multiplica
-- la aparición (Lluvia de Bichos). OnCaught/OnExpired avisan cuando se atrapan o se van.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local CatchBar = require(Shared:WaitForChild("CatchBar"))
local UpgradeMath = require(Shared:WaitForChild("UpgradeMath"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))
local Mutations = require(Config:WaitForChild("Mutations"))

local Data = require(script.Parent:WaitForChild("Data"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Vaults = require(script.Parent:WaitForChild("Vaults"))
local MutationEvents = require(script.Parent:WaitForChild("MutationEvents"))
local CritterVisual = require(script.Parent:WaitForChild("CritterVisual"))

type CritterDef = CrittersConfig.Critter

type Wild = {
	uid: string,
	def: CritterDef,
	vault: number,
	multiplier: number,
	color: string, -- mutación de color (Config/Mutations.Colors)
	size: string, -- mutación de tamaño (Config/Mutations.Sizes)
	part: BasePart,
	prompt: ProximityPrompt,
	spawnedAt: number,
	lockedBy: Player?,
	reservedFor: Player?, -- solo este jugador puede atraparlo (tutorial o Suerte x2)
	isTutorial: boolean,
	tween: Tween?,
	eventTag: string?, -- bicho de evento ("legendario"): no cuenta para el tope de la bóveda
	expiresAt: number?, -- os.clock() en el que se va (si no, Spawning.despawnSeconds)
}

type Minigame = {
	critter: Wild,
	startTime: number,
	zoneCenter: number,
	zoneWidth: number,
}

type Carried = {
	def: CritterDef,
	vault: number,
	multiplier: number,
	color: string,
	size: string,
	part: BasePart,
	warnedFull: boolean,
}

local Spawning = Gameplay.Spawning
local Catching = Gameplay.Catching
local Luck = Gameplay.Luck
local F = Gameplay.Field

local CritterSpawner = {}

local rng = Random.new()

local folder = Instance.new("Folder")
folder.Name = "Critters"
folder.Parent = Workspace

local wild: { [string]: Wild } = {}
local minigames: { [Player]: Minigame } = {}
local carrying: { [Player]: Carried } = {}
local lastAction: { [Player]: number } = {}
local tutorialGiven: { [Player]: boolean } = {}
local luckCritter: { [Player]: Wild } = {}

-- Lluvia de Bichos: multiplicador de aparición y bicho exclusivo (o nada fuera del evento).
local spawnMultiplier = 1
local exclusiveDef: CritterDef? = nil
local exclusiveChance = 0

type CaughtCallback = (player: Player, def: CritterDef, eventTag: string?) -> ()
local caughtCallbacks: { CaughtCallback } = {}
local expiredCallbacks: { (def: CritterDef, eventTag: string) -> () } = {}

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, text)
end

-- Evita que un cliente mande peticiones en ráfaga.
local function passCooldown(player: Player): boolean
	local now = os.clock()
	if now - (lastAction[player] or 0) < Catching.requestCooldownSeconds then
		return false
	end
	lastAction[player] = now
	return true
end

local function countWild(vault: number): number
	local count = 0
	for _, w in wild do
		if w.vault == vault and w.reservedFor == nil and w.eventTag == nil then
			count += 1
		end
	end
	return count
end

-- Elige un bicho para la bóveda: primero la rareza (porcentajes de Config/Critters.VaultChances) y
-- luego, a partes iguales, uno de los bichos de esa rareza que ya salen ahí. Con `luck` > 1 las
-- rarezas por encima de la más común pesan más (Suerte x2).
local function pickCritter(vault: number, luck: number): CritterDef?
	return VaultMath.pickCritter(vault, luck, rng:NextNumber())
end

local function firstCommon(): CritterDef?
	for _, def in VaultMath.critterPool(1) do
		if def.rarity == "Comun" then
			return def
		end
	end
	return nil
end

-- Punto al azar dentro de la zona (cada zona es un rectángulo girado, ver Shared/VaultMath).
local function randomSpawnPoint(vault: number): Vector3
	local margin = F.edgeMargin
	local size = VaultMath.size(vault)
	local mu, mv = margin / size.X, margin / size.Y
	return VaultMath.point(vault, rng:NextNumber(-0.5 + mu, 0.5 - mu), rng:NextNumber(-0.5 + mv, 0.5 - mv))
end

-- Mantiene un punto dentro de su bóveda.
local function clampToVault(vault: number, point: Vector3): Vector3
	return VaultMath.clamp(vault, point, F.edgeMargin)
end

-- Altura real del suelo (Terrain) en un punto: el terreno no es perfectamente plano.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { Workspace.Terrain }
groundParams.IgnoreWater = true

-- `nearY`: altura aproximada del suelo de esa zona (las islas flotantes están más altas).
local function groundYAt(x: number, z: number, nearY: number?): number
	local base = nearY or Gameplay.GroundY
	local hit = Workspace:Raycast(Vector3.new(x, base + 40, z), Vector3.new(0, -80, 0), groundParams)
	return if hit then hit.Position.Y else base
end

local function refreshPrompt(w: Wild)
	w.prompt.Enabled = w.lockedBy == nil
end

local function setLocked(w: Wild, player: Player?)
	w.lockedBy = player
	refreshPrompt(w)
	w.part:SetAttribute("LockedBy", if player then player.UserId else nil)
end

local function moveTo(w: Wild, target: Vector3, speed: number)
	if w.tween then
		w.tween:Cancel()
		w.tween = nil
	end
	local from = w.part.Position
	local goal = Vector3.new(target.X, groundYAt(target.X, target.Z, w.part.Position.Y - w.part.Size.Y / 2) + w.part.Size.Y / 2 + Gameplay.CritterLift, target.Z)
	local distance = (goal - from).Magnitude
	if distance < 0.1 then
		return
	end
	local direction = Vector3.new(goal.X - from.X, 0, goal.Z - from.Z).Unit
	w.part.CFrame = CFrame.lookAt(from, from + direction)
	local tween = TweenService:Create(w.part, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(goal, goal + direction) })
	w.tween = tween
	tween:Play()
end

local function removeWild(w: Wild)
	if w.tween then
		w.tween:Cancel()
		w.tween = nil
	end
	wild[w.uid] = nil
	for player, lucky in luckCritter do
		if lucky == w then
			luckCritter[player] = nil
		end
	end
end

local startMinigame: (player: Player, w: Wild) -> ()

-- Nombre completo: "Caracol Turbo Diamante Grande x3".
local function fullName(def: CritterDef, multiplier: number, color: string, size: string): string
	return MutationMath.displayName(def.name, color, size) .. (if multiplier > 1 then " x" .. multiplier else "")
end

-- Sin `color`/`size` se sortean (con el evento de mutación que haya en marcha).
local function spawnWild(def: CritterDef, vault: number, groundPosition: Vector3, reservedFor: Player?, isTutorial: boolean, multiplier: number?, color: string?, size: string?): Wild
	local colorId = color or MutationMath.rollColor(rng:NextNumber(), MutationEvents.CurrentBoosts())
	local sizeId = size or MutationMath.rollSize(rng:NextNumber())
	local part = CritterVisual.create(def, colorId, sizeId)
	local uid = HttpService:GenerateGUID(false)
	local mult = multiplier or VaultMath.valueMultiplier(vault)
	local groundY = groundYAt(groundPosition.X, groundPosition.Z, groundPosition.Y)
	part.CFrame = CFrame.new(groundPosition.X, groundY + part.Size.Y / 2 + Gameplay.CritterLift, groundPosition.Z)
		* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	part:SetAttribute("CritterUid", uid)
	part:SetAttribute("Vault", vault)
	part:SetAttribute("Multiplier", mult)
	local totalMultiplier = mult * MutationMath.multiplier(colorId, sizeId)
	if totalMultiplier > 1 then
		CritterVisual.setDetail(part, CrittersConfig.Rarities[def.rarity].label .. " · x" .. totalMultiplier)
	end
	if reservedFor then
		part:SetAttribute("ReservedFor", reservedFor.UserId)
		if isTutorial then
			part:SetAttribute("TutorialFor", reservedFor.UserId)
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Atrapar"
	prompt.ObjectText = fullName(def, mult, colorId, sizeId)
	prompt.HoldDuration = 0
	-- La distancia se mide desde el centro: a los bichos grandes se les suma su radio.
	prompt.MaxActivationDistance = Catching.range + part.Size.Y / 2
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = part

	local w: Wild = {
		uid = uid,
		def = def,
		vault = vault,
		multiplier = mult,
		color = colorId,
		size = sizeId,
		part = part,
		prompt = prompt,
		spawnedAt = os.clock(),
		lockedBy = nil,
		reservedFor = reservedFor,
		isTutorial = isTutorial,
		tween = nil,
		eventTag = nil,
		expiresAt = nil,
	}
	refreshPrompt(w)
	prompt.Triggered:Connect(function(player: Player)
		startMinigame(player, w)
	end)

	-- Mutación rara recién sorteada (no un bicho soltado ni reservado): aviso para todos y baliza.
	-- El atributo va antes de meterlo en el Workspace para que llegue a la vez que el bicho.
	local mutationMultiplier = MutationMath.multiplier(colorId, sizeId)
	local isRare = color == nil and size == nil and reservedFor == nil and mutationMultiplier >= Mutations.rareAlert.minMultiplier
	if isRare then
		part:SetAttribute("RareMutation", true)
	end
	wild[uid] = w
	part.Parent = folder

	if isRare then
		local look = MutationMath.color(colorId)
		local tint = look.light or look.tint or Color3.fromRGB(255, 205, 60)
		Remotes.RareSpawn:FireAllClients(
			"🌟 ¡" .. MutationMath.displayName(def.name, colorId, sizeId) .. " (x" .. mutationMultiplier .. ") en la bóveda " .. vault .. "!",
			tint,
			vault
		)
	end
	return w
end

local function flee(w: Wild, player: Player)
	local root = getRoot(player)
	local away = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
	if root then
		local offset = w.part.Position - root.Position
		away = Vector3.new(offset.X, 0, offset.Z)
	end
	if away.Magnitude < 0.01 then
		away = Vector3.new(1, 0, 0)
	end
	local target = w.part.Position + away.Unit * Catching.fleeDistance
	if not w.isTutorial then
		target = clampToVault(w.vault, target)
	end
	moveTo(w, target, Spawning.wanderSpeed * Catching.fleeSpeedMultiplier * Gameplay.RarityMotion[w.def.rarity].speed)
end

-- Devuelve si se pudo y si el bicho ha crecido un tamaño (pase Red Titánica).
local function startCarrying(player: Player, w: Wild): (boolean, boolean)
	local root = getRoot(player)
	local character = player.Character
	if not root or not character then
		return false, false
	end
	removeWild(w)

	local part = w.part
	local size = w.size
	local grew = false
	-- Red Titánica: probabilidad de que crezca un tamaño al atraparlo (se decide en el servidor).
	if player:GetAttribute("Pass_RedTitanica") == true and rng:NextNumber() < Mutations.redTitanicaChance then
		local bigger = MutationMath.nextSize(size)
		if bigger then
			size = bigger
			grew = true
			part:Destroy()
			part = CritterVisual.create(w.def, w.color, size)
		end
	end
	if not grew then
		w.prompt:Destroy()
		for _, attribute in { "CritterUid", "LockedBy", "TutorialFor", "ReservedFor", "Vault", "EventTag", "RareMutation" } do
			part:SetAttribute(attribute, nil)
		end
	end
	w.size = size
	part:SetAttribute("Carried", true)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CFrame = root.CFrame * CFrame.new(0, Catching.carryHeight + part.Size.Y / 2, 0)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = character

	carrying[player] = { def = w.def, vault = w.vault, multiplier = w.multiplier, color = w.color, size = size, part = part, warnedFull = false }
	return true, grew
end

local function endMinigame(player: Player, success: boolean, failMessage: string?)
	local mg = minigames[player]
	if not mg then
		return
	end
	minigames[player] = nil
	local w = mg.critter

	local position = w.part.Position
	local caught, grew = false, false
	if success and w.part.Parent ~= nil then
		caught, grew = startCarrying(player, w)
	end
	if caught then
		local grewText = if grew then " 🕸 ¡Tu Red Titánica lo ha hecho crecer!" else ""
		Remotes.CatchResult:FireClient(player, true, "¡Has atrapado: " .. fullName(w.def, w.multiplier, w.color, w.size) .. "!" .. grewText .. " Llévalo a tu santuario.")
		Remotes.Effect:FireAllClients("captura", position, w.def.rarity) -- todos ven las chispas
		Remotes.Effect:FireClient(player, "captura_mia")
		Analytics.Step(player, "primera_captura")
		for _, callback in caughtCallbacks do
			task.spawn(callback, player, w.def, w.eventTag)
		end
		return
	end

	if w.part.Parent ~= nil then
		setLocked(w, nil)
		flee(w, player)
	end
	Remotes.Effect:FireClient(player, "fallo", position)
	Remotes.CatchResult:FireClient(player, false, failMessage or "¡Se ha escapado!")
end

local function catchWindowFor(player: Player, def: CritterDef, size: string): number
	local base = CrittersConfig.Rarities[def.rarity].catchWindow
	local profile = Data.Get(player)
	local redLevel = if profile then profile.upgrades.Red or 0 else 0
	if player:GetAttribute("Pass_RedDorada") == true then
		redLevel = Progression.Upgrades.Red.maxLevel
	end
	return MutationMath.catchWindow(UpgradeMath.catchWindow(base, redLevel), size)
end

startMinigame = function(player: Player, w: Wild)
	if not passCooldown(player) then
		return
	end
	if minigames[player] then
		return
	end
	if carrying[player] then
		notify(player, "Ya llevas un bicho. ¡Llévalo a tu santuario!")
		return
	end
	if wild[w.uid] ~= w or w.lockedBy then
		return
	end
	if w.reservedFor and w.reservedFor ~= player then
		notify(player, "Este bicho es de otro jugador.")
		return
	end
	if not Vaults.IsUnlocked(player, w.vault) then
		notify(player, "Primero abre la bóveda " .. w.vault .. ".")
		return
	end
	local root = getRoot(player)
	if not root or (root.Position - w.part.Position).Magnitude > Catching.range + w.part.Size.Y / 2 + Catching.rangeTolerance then
		return
	end
	if Guard.MovedTooFast(player) then
		notify(player, "Espera un momento y vuelve a intentarlo.")
		return -- se ha movido más rápido de lo posible (teletransporte con trampas)
	end

	setLocked(w, player)
	if w.tween then
		w.tween:Cancel()
		w.tween = nil
	end

	local rarity = CrittersConfig.Rarities[w.def.rarity]
	local zoneWidth = catchWindowFor(player, w.def, w.size)
	local mg: Minigame = {
		critter = w,
		startTime = Workspace:GetServerTimeNow(),
		zoneCenter = rng:NextNumber(zoneWidth / 2, 1 - zoneWidth / 2),
		zoneWidth = zoneWidth,
	}
	minigames[player] = mg

	Remotes.StartMinigame:FireClient(player, {
		name = fullName(w.def, w.multiplier, w.color, w.size),
		rarity = rarity.label,
		color = rarity.color,
		startTime = mg.startTime,
		cycle = Catching.barCycleSeconds,
		zoneCenter = mg.zoneCenter,
		zoneWidth = mg.zoneWidth,
		timeout = Catching.timeoutSeconds,
	})

	task.delay(Catching.timeoutSeconds, function()
		if minigames[player] == mg then
			endMinigame(player, false, "¡Tardaste demasiado! El bicho ha huido.")
		end
	end)
end

local function onAttemptCatch(player: Player, pressedAt: unknown)
	local mg = minigames[player]
	if not mg then
		return
	end
	local now = Workspace:GetServerTimeNow()
	-- El momento que dice el cliente solo se acepta dentro de una ventana corta antes de ahora.
	local moment = now
	if typeof(pressedAt) == "number" and pressedAt == pressedAt then
		-- Solo se mira hacia atrás lo que tarda en llegar el toque con el ping de este jugador.
		moment = math.clamp(pressedAt, now - Guard.CatchTolerance(player), now)
	end
	local elapsed = moment - mg.startTime
	local hit = elapsed >= 0 and CatchBar.isInZone(CatchBar.markerAt(elapsed, Catching.barCycleSeconds), mg.zoneCenter, mg.zoneWidth)
	endMinigame(player, hit, "¡Fallaste! El bicho ha huido.")
end

local function onReleaseCarried(player: Player)
	if not passCooldown(player) then
		return
	end
	local carried = carrying[player]
	if not carried then
		return
	end
	carrying[player] = nil
	carried.part:Destroy()

	local root = getRoot(player)
	local vault = carried.vault
	local drop = randomSpawnPoint(vault)
	if root then
		local front = (root.CFrame * CFrame.new(0, 0, -Catching.releaseDistance)).Position
		local here = VaultMath.vaultAt(front)
		if here and here <= Vaults.Generated() then
			vault = here
			drop = front
		end
	end
	spawnWild(carried.def, vault, Vector3.new(drop.X, VaultMath.floorY(vault), drop.Z), nil, false, carried.multiplier, carried.color, carried.size)
	notify(player, "Has soltado a " .. MutationMath.displayName(carried.def.name, carried.color, carried.size) .. ".")
end

-- Cada poco: si llevas un bicho y estás en tu santuario, se coloca en un pedestal libre.
local function depositLoop()
	while true do
		task.wait(Catching.depositCheckSeconds)
		for player, carried in carrying do
			local root = getRoot(player)
			if root and Plots.IsInOwnPlot(player, root.Position) then
				local ok, message = Plots.AddCritter(player, carried.def, carried.multiplier, carried.color, carried.size)
				if ok then
					carrying[player] = nil
					carried.part:Destroy()
					notify(player, message)
				elseif not carried.warnedFull then
					carried.warnedFull = true
					notify(player, message)
				end
			else
				carried.warnedFull = false
			end
		end
	end
end

-- Mantiene bichos en las bóvedas construidas hasta una más allá de la más lejana abierta.
local function spawnLoop()
	while true do
		task.wait(Spawning.intervalSeconds)
		local last = math.min(Vaults.Generated(), Vaults.HighestOpen() + 1)
		-- Durante la Lluvia de Bichos caben más bichos y salen varios a la vez.
		local cap = F.crittersPerVault * spawnMultiplier
		for vault = 1, last do
			for _ = 1, spawnMultiplier do
				if countWild(vault) >= cap then
					break
				end
				local def = pickCritter(vault, 1)
				local exclusive = exclusiveDef
				if exclusive and rng:NextNumber() < exclusiveChance then
					def = exclusive
				end
				if def then
					spawnWild(def, vault, randomSpawnPoint(vault), nil, false)
				end
			end
		end
	end
end

-- Suerte x2: un bicho reservado para el jugador, cerca de él, en la bóveda donde esté.
local function luckLoop()
	while true do
		task.wait(Luck.personalSpawnSeconds)
		for _, player in Players:GetPlayers() do
			local profile = Data.Get(player)
			local root = getRoot(player)
			if profile and root and profile.luckUntil > os.time() and luckCritter[player] == nil then
				local vault = VaultMath.vaultAt(root.Position)
				if vault and Vaults.IsUnlocked(player, vault) then
					local def = pickCritter(vault, Luck.rarityMultiplier)
					if def then
						local angle = rng:NextNumber(0, math.pi * 2)
						local point = clampToVault(vault, root.Position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * Luck.spawnDistance)
						luckCritter[player] = spawnWild(def, vault, point, player, false)
						notify(player, "🍀 ¡Ha aparecido un bicho de la suerte solo para ti: " .. def.name .. "!")
					end
				end
			end
		end
	end
end

local function wanderLoop()
	while true do
		task.wait(Spawning.wanderIntervalSeconds)
		local now = os.clock()
		for _, w in wild do
			if w.lockedBy == nil and not w.isTutorial then
				local expired = if w.expiresAt then now >= w.expiresAt else now - w.spawnedAt > Spawning.despawnSeconds
				if expired then
					removeWild(w)
					w.part:Destroy()
					local tag = w.eventTag
					if tag then
						for _, callback in expiredCallbacks do
							task.spawn(callback, w.def, tag)
						end
					end
				elseif rng:NextNumber() < Spawning.wanderChance then
					-- Cuanto más raro, más rápido y más lejos corretea (Config/Gameplay.RarityMotion).
					local motion = Gameplay.RarityMotion[w.def.rarity]
					local offset = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * Spawning.wanderDistance * motion.distance
					moveTo(w, clampToVault(w.vault, w.part.Position + offset), Spawning.wanderSpeed * motion.speed)
				end
			end
		end
	end
end

-- Primeros 60 s del GDD: un bicho común aparece justo delante del jugador, en la plaza.
local function giveTutorialCritter(player: Player, character: Model)
	if tutorialGiven[player] then
		return
	end
	tutorialGiven[player] = true
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") then
		return
	end
	task.wait(Spawning.tutorialDelaySeconds)
	if player.Parent == nil then
		return
	end
	local def = firstCommon()
	if not def then
		return
	end
	local front = (root.CFrame * CFrame.new(0, 0, -Spawning.tutorialDistance)).Position
	local w = spawnWild(def, 1, Vector3.new(front.X, Gameplay.GroundY, front.Z), player, true, 1, "Normal", "Normal")
	-- que mire al jugador
	w.part.CFrame = CFrame.lookAt(w.part.Position, Vector3.new(root.Position.X, w.part.Position.Y, root.Position.Z))
end

-- Si el jugador muere o se va: se cancela el minijuego y el bicho que llevaba vuelve a su bóveda.
local function dropEverything(player: Player)
	if minigames[player] then
		endMinigame(player, false, "¡El bicho se ha escapado!")
	end
	local carried = carrying[player]
	if carried then
		carrying[player] = nil
		carried.part:Destroy()
		spawnWild(carried.def, carried.vault, randomSpawnPoint(carried.vault), nil, false, carried.multiplier, carried.color, carried.size)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		giveTutorialCritter(player, character)
	end)
	player.CharacterRemoving:Connect(function()
		dropEverything(player)
	end)
	if player.Character then
		task.spawn(giveTutorialCritter, player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	dropEverything(player)
	for _, w in wild do
		if w.reservedFor == player then
			removeWild(w)
			w.part:Destroy()
		end
	end
	lastAction[player] = nil
	tutorialGiven[player] = nil
	luckCritter[player] = nil
end

-- Crea un bicho de evento en la bóveda `vault` (cualquiera que la tenga abierta puede atraparlo).
-- Vive `lifetime` segundos; al atraparse o irse avisa por OnCaught / OnExpired con su `tag`.
function CritterSpawner.SpawnEvent(def: CritterDef, vault: number, tag: string, lifetime: number): BasePart
	local w = spawnWild(def, vault, randomSpawnPoint(vault), nil, false, 1)
	w.eventTag = tag
	w.expiresAt = os.clock() + lifetime
	w.part:SetAttribute("EventTag", tag)
	return w.part
end

function CritterSpawner.OnCaught(callback: CaughtCallback)
	table.insert(caughtCallbacks, callback)
end

function CritterSpawner.OnExpired(callback: (def: CritterDef, eventTag: string) -> ())
	table.insert(expiredCallbacks, callback)
end

-- Lluvia de Bichos: `multiplier` bichos a la vez (1 = normal) y, con probabilidad `chance`, el
-- bicho exclusivo `exclusive` en lugar del normal.
function CritterSpawner.SetSpawnBoost(multiplier: number, exclusive: CritterDef?, chance: number)
	spawnMultiplier = math.max(1, math.floor(multiplier))
	exclusiveDef = exclusive
	exclusiveChance = chance
end

function CritterSpawner.Start()
	Guard.Connect(Remotes.AttemptCatch, "AttemptCatch", onAttemptCatch)
	Guard.Connect(Remotes.ReleaseCarried, "ReleaseCarried", onReleaseCarried)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	task.spawn(spawnLoop)
	task.spawn(wanderLoop)
	task.spawn(depositLoop)
	task.spawn(luckLoop)

	-- Solo en Studio, para revisar modelos y probar capturas (no existen en el juego publicado):
	--   ServerStorage.DebugCrearBicho:Invoke(player, "id_del_bicho", "Oro", "Enorme") crea ese bicho
	--   delante del jugador (el color y el tamaño son opcionales: sin ellos se sortean).
	if RunService:IsStudio() then
		local debugSpawn = Instance.new("BindableFunction")
		debugSpawn.Name = "DebugCrearBicho"
		debugSpawn.OnInvoke = function(player: Player, critterId: string, color: string?, size: string?)
			local root = getRoot(player)
			for _, def in CrittersConfig.List do
				if def.id == critterId and root then
					local front = (root.CFrame * CFrame.new(0, 0, -8)).Position
					local vault = VaultMath.vaultAt(front) or 1
					spawnWild(def, vault, Vector3.new(front.X, VaultMath.floorY(vault), front.Z), player, false, nil, color, size)
					return true
				end
			end
			return false
		end
		debugSpawn.Parent = ServerStorage
	end
end

return CritterSpawner
