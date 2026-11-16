--!strict
-- Bichos salvajes: aparecen dentro de cada bóveda (según su temática, suerte y rareza), pasean
-- despacio, se atrapan con el minijuego y se llevan al santuario.
--   * Solo se pueden atrapar en bóvedas que el jugador ha abierto, y nunca de noche (DayNight):
--     de noche duermen, no se mueven y su aviso "Atrapar" se apaga.
--   * Los bichos de las bóvedas sin fin (5ª en adelante) valen más: llevan un multiplicador que se
--     guarda con ellos en el santuario.
--
-- Captura (el servidor manda):
--   1. El jugador activa el ProximityPrompt "Atrapar". El servidor comprueba distancia, cooldown,
--      bóveda abierta y que sea de día; bloquea el bicho y elige la zona verde (catchWindow de su
--      rareza + mejora Red, o el máximo con el pase Red Dorada).
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

local Events = require(Config:WaitForChild("Events"))

local Data = require(script.Parent:WaitForChild("Data"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Vaults = require(script.Parent:WaitForChild("Vaults"))
local DayNight = require(script.Parent:WaitForChild("DayNight"))
local CritterVisual = require(script.Parent:WaitForChild("CritterVisual"))

type CritterDef = CrittersConfig.Critter

type Wild = {
	uid: string,
	def: CritterDef,
	vault: number,
	multiplier: number,
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
	part: BasePart,
	warnedFull: boolean,
}

local Spawning = Gameplay.Spawning
local Catching = Gameplay.Catching
local Luck = Gameplay.Luck
local F = Gameplay.Field
local NIGHT_MESSAGE = "🌙 Es de noche: los bichos duermen. ¡Vuelve cuando amanezca!"

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
local lastHomeRequest: { [Player]: number } = {}

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

-- Elige un bicho: primero la rareza (según su peso, con `luck` > 1 las no comunes pesan más)
-- y luego un bicho de esa rareza.
local function pickCritter(pool: { CritterDef }, luck: number): CritterDef?
	local byRarity: { [string]: { CritterDef } } = {}
	for _, def in pool do
		local list = byRarity[def.rarity]
		if not list then
			list = {}
			byRarity[def.rarity] = list
		end
		table.insert(list, def)
	end
	local function weightOf(rarity: string): number
		local weight = CrittersConfig.Rarities[rarity].weight
		return if rarity == "Comun" then weight else weight * luck
	end
	local total = 0
	for rarity in byRarity do
		total += weightOf(rarity)
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber(0, total)
	local chosen: { CritterDef }? = nil
	for rarity, list in byRarity do
		chosen = list
		roll -= weightOf(rarity)
		if roll <= 0 then
			break
		end
	end
	if not chosen then
		return nil
	end
	return chosen[rng:NextInteger(1, #chosen)]
end

local function firstCommon(): CritterDef?
	for _, def in VaultMath.critterPool(1) do
		if def.rarity == "Comun" then
			return def
		end
	end
	return nil
end

local function randomSpawnPoint(vault: number): Vector3
	local margin = F.edgeMargin
	local x = rng:NextNumber(-F.width / 2 + margin, F.width / 2 - margin)
	local z = rng:NextNumber(VaultMath.backZ(vault) + margin, VaultMath.frontZ(vault) - margin)
	return Vector3.new(x, Gameplay.GroundY, z)
end

-- Mantiene un punto dentro de su bóveda.
local function clampToVault(vault: number, point: Vector3): Vector3
	local margin = F.edgeMargin
	return Vector3.new(
		math.clamp(point.X, -F.width / 2 + margin, F.width / 2 - margin),
		point.Y,
		math.clamp(point.Z, VaultMath.backZ(vault) + margin, VaultMath.frontZ(vault) - margin)
	)
end

-- Altura real del suelo (Terrain) en un punto: el terreno no es perfectamente plano.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { Workspace.Terrain }
groundParams.IgnoreWater = true

local function groundYAt(x: number, z: number): number
	local hit = Workspace:Raycast(Vector3.new(x, Gameplay.GroundY + 60, z), Vector3.new(0, -120, 0), groundParams)
	return if hit then hit.Position.Y else Gameplay.GroundY
end

local function refreshPrompt(w: Wild)
	w.prompt.Enabled = w.lockedBy == nil and not DayNight.IsNight()
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
	local goal = Vector3.new(target.X, groundYAt(target.X, target.Z) + w.part.Size.Y / 2 + Gameplay.CritterLift, target.Z)
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

local function spawnWild(def: CritterDef, vault: number, groundPosition: Vector3, reservedFor: Player?, isTutorial: boolean, multiplier: number?): Wild
	local part = CritterVisual.create(def)
	local uid = HttpService:GenerateGUID(false)
	local mult = multiplier or VaultMath.valueMultiplier(vault)
	local groundY = groundYAt(groundPosition.X, groundPosition.Z)
	part.CFrame = CFrame.new(groundPosition.X, groundY + part.Size.Y / 2 + Gameplay.CritterLift, groundPosition.Z)
		* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	part:SetAttribute("CritterUid", uid)
	part:SetAttribute("Vault", vault)
	part:SetAttribute("Multiplier", mult)
	if mult > 1 then
		CritterVisual.setDetail(part, CrittersConfig.Rarities[def.rarity].label .. " · x" .. mult)
	end
	if reservedFor then
		part:SetAttribute("ReservedFor", reservedFor.UserId)
		if isTutorial then
			part:SetAttribute("TutorialFor", reservedFor.UserId)
		end
	end
	if DayNight.IsNight() then
		part:SetAttribute("Sleeping", true)
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Atrapar"
	prompt.ObjectText = def.name .. (if mult > 1 then " x" .. mult else "")
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

	wild[uid] = w
	part.Parent = folder
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

local function startCarrying(player: Player, w: Wild): boolean
	local root = getRoot(player)
	local character = player.Character
	if not root or not character then
		return false
	end
	removeWild(w)

	local part = w.part
	w.prompt:Destroy()
	for _, attribute in { "CritterUid", "LockedBy", "TutorialFor", "ReservedFor", "Vault", "Sleeping", "EventTag" } do
		part:SetAttribute(attribute, nil)
	end
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

	carrying[player] = { def = w.def, vault = w.vault, multiplier = w.multiplier, part = part, warnedFull = false }
	return true
end

local function endMinigame(player: Player, success: boolean, failMessage: string?)
	local mg = minigames[player]
	if not mg then
		return
	end
	minigames[player] = nil
	local w = mg.critter

	local position = w.part.Position
	if success and w.part.Parent ~= nil and startCarrying(player, w) then
		Remotes.CatchResult:FireClient(player, true, "¡Has atrapado: " .. w.def.name .. (if w.multiplier > 1 then " x" .. w.multiplier else "") .. "! Llévalo a tu santuario.")
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
		if not DayNight.IsNight() then
			flee(w, player)
		end
	end
	Remotes.Effect:FireClient(player, "fallo", position)
	Remotes.CatchResult:FireClient(player, false, failMessage or "¡Se ha escapado!")
end

local function catchWindowFor(player: Player, def: CritterDef): number
	local base = CrittersConfig.Rarities[def.rarity].catchWindow
	local profile = Data.Get(player)
	local redLevel = if profile then profile.upgrades.Red or 0 else 0
	if player:GetAttribute("Pass_RedDorada") == true then
		redLevel = Progression.Upgrades.Red.maxLevel
	end
	return UpgradeMath.catchWindow(base, redLevel)
end

startMinigame = function(player: Player, w: Wild)
	if not passCooldown(player) then
		return
	end
	if DayNight.IsNight() then
		notify(player, NIGHT_MESSAGE)
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

	setLocked(w, player)
	if w.tween then
		w.tween:Cancel()
		w.tween = nil
	end

	local rarity = CrittersConfig.Rarities[w.def.rarity]
	local zoneWidth = catchWindowFor(player, w.def)
	local mg: Minigame = {
		critter = w,
		startTime = Workspace:GetServerTimeNow(),
		zoneCenter = rng:NextNumber(zoneWidth / 2, 1 - zoneWidth / 2),
		zoneWidth = zoneWidth,
	}
	minigames[player] = mg

	Remotes.StartMinigame:FireClient(player, {
		name = w.def.name .. (if w.multiplier > 1 then " x" .. w.multiplier else ""),
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
	if DayNight.IsNight() then
		endMinigame(player, false, NIGHT_MESSAGE)
		return
	end
	local now = Workspace:GetServerTimeNow()
	-- El momento que dice el cliente solo se acepta dentro de una ventana corta antes de ahora.
	local moment = now
	if typeof(pressedAt) == "number" and pressedAt == pressedAt then
		moment = math.clamp(pressedAt, now - Catching.latencyToleranceSeconds, now)
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
	spawnWild(carried.def, vault, Vector3.new(drop.X, Gameplay.GroundY, drop.Z), nil, false, carried.multiplier)
	notify(player, "Has soltado a " .. carried.def.name .. ".")
end

-- Cada poco: si llevas un bicho y estás en tu santuario, se coloca en un pedestal libre.
local function depositLoop()
	while true do
		task.wait(Catching.depositCheckSeconds)
		for player, carried in carrying do
			local root = getRoot(player)
			if root and Plots.IsInOwnPlot(player, root.Position) then
				local ok, message = Plots.AddCritter(player, carried.def, carried.multiplier)
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
		if not DayNight.IsNight() then
			local last = math.min(Vaults.Generated(), Vaults.HighestOpen() + 1)
			-- Durante la Lluvia de Bichos caben más bichos y salen varios a la vez.
			local cap = F.crittersPerVault * spawnMultiplier
			for vault = 1, last do
				for _ = 1, spawnMultiplier do
					if countWild(vault) >= cap then
						break
					end
					local def = pickCritter(VaultMath.critterPool(vault), VaultMath.luck(vault))
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
end

-- Suerte x2: un bicho reservado para el jugador, cerca de él, en la bóveda donde esté.
local function luckLoop()
	while true do
		task.wait(Luck.personalSpawnSeconds)
		if not DayNight.IsNight() then
			for _, player in Players:GetPlayers() do
				local profile = Data.Get(player)
				local root = getRoot(player)
				if profile and root and profile.luckUntil > os.time() and luckCritter[player] == nil then
					local vault = VaultMath.vaultAt(root.Position)
					if vault and Vaults.IsUnlocked(player, vault) then
						local def = pickCritter(VaultMath.critterPool(vault), VaultMath.luck(vault) * Luck.rarityMultiplier)
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
end

local function wanderLoop()
	while true do
		task.wait(Spawning.wanderIntervalSeconds)
		if not DayNight.IsNight() then
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
end

-- Noche: los bichos se duermen (se paran, no se pueden atrapar). Día: despiertan.
-- Al anochecer, quien esté en una bóveda vuelve a su santuario. Si llevaba un bicho, se coloca en
-- un pedestal libre o, si no cabe, queda esperando hueco: no se pierde.
local function sendHomeAtNight(player: Player)
	local root = getRoot(player)
	local target = Plots.GetHomeCFrame(player)
	if not root or not target or not VaultMath.vaultAt(root.Position) then
		return
	end
	local carried = carrying[player]
	local saved = ""
	if carried then
		carrying[player] = nil
		carried.part:Destroy()
		local ok = Plots.AddCritter(player, carried.def, carried.multiplier)
		if not ok then
			Plots.GrantCritter(player, carried.def, carried.multiplier)
		end
		saved = " Tu " .. carried.def.name .. " ya está en el santuario."
	end
	root.AssemblyLinearVelocity = Vector3.zero
	if player.Character then
		player.Character:PivotTo(target)
	end
	notify(player, "🌙 Has vuelto a tu santuario." .. saved)
end

-- Botón CASA: solo de noche y desde una bóveda (de día hay que volver andando con el bicho).
local function onGoHome(player: Player)
	local now = os.clock()
	if now - (lastHomeRequest[player] or 0) < Gameplay.Menus.goHomeCooldownSeconds then
		return
	end
	lastHomeRequest[player] = now
	if not DayNight.IsNight() then
		return
	end
	sendHomeAtNight(player)
end

local function onNightChanged(night: boolean)
	if night then
		for player in minigames do
			endMinigame(player, false, NIGHT_MESSAGE)
		end
		-- "forzado": todos a casa. "boton": cada uno vuelve cuando quiera con el botón CASA (GoHome).
		if Events.DayNight.sendHome == "forzado" then
			for _, player in Players:GetPlayers() do
				task.spawn(sendHomeAtNight, player)
			end
		end
	end
	for _, w in wild do
		if night and w.tween then
			w.tween:Cancel()
			w.tween = nil
		end
		w.part:SetAttribute("Sleeping", if night then true else nil)
		refreshPrompt(w)
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
	local w = spawnWild(def, 1, Vector3.new(front.X, Gameplay.GroundY, front.Z), player, true, 1)
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
		spawnWild(carried.def, carried.vault, randomSpawnPoint(carried.vault), nil, false, carried.multiplier)
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
	lastHomeRequest[player] = nil
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
	Remotes.AttemptCatch.OnServerEvent:Connect(onAttemptCatch)
	Remotes.ReleaseCarried.OnServerEvent:Connect(onReleaseCarried)
	Remotes.GoHome.OnServerEvent:Connect(onGoHome)
	ReplicatedStorage:SetAttribute("NightSendHome", Events.DayNight.sendHome)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	DayNight.OnChanged(onNightChanged)
	task.spawn(spawnLoop)
	task.spawn(wanderLoop)
	task.spawn(depositLoop)
	task.spawn(luckLoop)

	-- Solo en Studio, para revisar modelos y probar capturas (no existen en el juego publicado):
	--   ServerStorage.DebugCrearBicho:Invoke(player, "id_del_bicho") crea ese bicho delante del jugador.
	--   ServerStorage.DebugNoche:Invoke(true/false) fuerza la noche o el día para probar.
	if RunService:IsStudio() then
		local debugSpawn = Instance.new("BindableFunction")
		debugSpawn.Name = "DebugCrearBicho"
		debugSpawn.OnInvoke = function(player: Player, critterId: string)
			local root = getRoot(player)
			for _, def in CrittersConfig.List do
				if def.id == critterId and root then
					local front = (root.CFrame * CFrame.new(0, 0, -8)).Position
					local vault = VaultMath.vaultAt(front) or 1
					spawnWild(def, vault, Vector3.new(front.X, Gameplay.GroundY, front.Z), player, false)
					return true
				end
			end
			return false
		end
		debugSpawn.Parent = ServerStorage
	end
end

return CritterSpawner
