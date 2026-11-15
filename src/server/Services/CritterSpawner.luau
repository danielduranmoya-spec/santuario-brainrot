--!strict
-- Bichos salvajes: aparición por zona y peso de rareza, paseo lento, captura y transporte al santuario.
--
-- Captura (el servidor manda):
--   1. El jugador activa el ProximityPrompt "Atrapar" del bicho. El servidor comprueba distancia,
--      cooldown y que tenga la zona desbloqueada, bloquea el bicho y elige la zona verde
--      (catchWindow de su rareza + mejora Red, o el máximo con el pase Red Dorada).
--   2. El cliente solo dibuja la barra y, al pulsar, envía "intento" + el momento en que pulsó.
--   3. El servidor recorta ese momento a una ventana corta antes de recibirlo y calcula él mismo dónde
--      estaba la aguja con el tiempo de servidor (CatchBar). Si estaba en verde, lo atrapas.

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

local Data = require(script.Parent:WaitForChild("Data"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Zones = require(script.Parent:WaitForChild("Zones"))
local CritterVisual = require(script.Parent:WaitForChild("CritterVisual"))

type CritterDef = CrittersConfig.Critter

type Wild = {
	uid: string,
	def: CritterDef,
	zone: string,
	part: BasePart,
	prompt: ProximityPrompt,
	spawnedAt: number,
	lockedBy: Player?,
	reservedFor: Player?, -- solo este jugador puede atraparlo (tutorial o Suerte x2)
	isTutorial: boolean,
	tween: Tween?,
}

type Minigame = {
	critter: Wild,
	startTime: number,
	zoneCenter: number,
	zoneWidth: number,
}

type Carried = {
	def: CritterDef,
	part: BasePart,
	warnedFull: boolean,
}

local Spawning = Gameplay.Spawning
local Catching = Gameplay.Catching
local Luck = Gameplay.Luck

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

local function countWild(zone: string): number
	local count = 0
	for _, w in wild do
		if w.zone == zone and w.reservedFor == nil then
			count += 1
		end
	end
	return count
end

-- Elige un bicho de la zona: primero la rareza (según su peso) y luego un bicho de esa rareza.
-- Con `luckMultiplier` > 1, las rarezas no comunes pesan más.
local function pickCritter(zone: string, luckMultiplier: number): CritterDef?
	local byRarity: { [string]: { CritterDef } } = {}
	for _, def in CrittersConfig.List do
		if def.zone == zone then
			local list = byRarity[def.rarity]
			if not list then
				list = {}
				byRarity[def.rarity] = list
			end
			table.insert(list, def)
		end
	end

	local function weightOf(rarity: string): number
		local weight = CrittersConfig.Rarities[rarity].weight
		return if rarity == "Comun" then weight else weight * luckMultiplier
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

local function firstCommonOfZone(zone: string): CritterDef?
	for _, def in CrittersConfig.List do
		if def.zone == zone and def.rarity == "Comun" then
			return def
		end
	end
	return nil
end

local function randomSpawnPoint(zone: string): Vector3
	local area = Gameplay.Zones[zone]
	local angle = rng:NextNumber(0, math.pi * 2)
	-- raíz cuadrada para repartir los bichos por igual en el anillo
	local radius = math.sqrt(rng:NextNumber(area.minRadius ^ 2, area.radius ^ 2))
	return Vector3.new(area.center.X + math.cos(angle) * radius, Gameplay.GroundY, area.center.Z + math.sin(angle) * radius)
end

-- Mantiene un punto dentro del círculo de su zona.
local function clampToZone(zone: string, point: Vector3): Vector3
	local area = Gameplay.Zones[zone]
	local flat = Vector3.new(point.X - area.center.X, 0, point.Z - area.center.Z)
	if flat.Magnitude > area.radius then
		flat = flat.Unit * area.radius
	end
	return Vector3.new(area.center.X + flat.X, point.Y, area.center.Z + flat.Z)
end

local function setLocked(w: Wild, player: Player?)
	w.lockedBy = player
	w.prompt.Enabled = player == nil
	w.part:SetAttribute("LockedBy", if player then player.UserId else nil)
end

local function moveTo(w: Wild, target: Vector3, speed: number)
	if w.tween then
		w.tween:Cancel()
		w.tween = nil
	end
	local from = w.part.Position
	local goal = Vector3.new(target.X, from.Y, target.Z)
	local distance = (goal - from).Magnitude
	if distance < 0.1 then
		return
	end
	local direction = (goal - from).Unit
	w.part.CFrame = CFrame.lookAt(from, from + direction)
	local tween = TweenService:Create(
		w.part,
		TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.lookAt(goal, goal + direction) }
	)
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

local function spawnWild(def: CritterDef, zone: string, groundPosition: Vector3, reservedFor: Player?, isTutorial: boolean): Wild
	local part = CritterVisual.create(def)
	local uid = HttpService:GenerateGUID(false)
	part.CFrame = CFrame.new(groundPosition + Vector3.new(0, part.Size.Y / 2 + Gameplay.CritterLift, 0))
	part:SetAttribute("CritterUid", uid)
	part:SetAttribute("Zone", zone)
	if reservedFor then
		part:SetAttribute("ReservedFor", reservedFor.UserId)
		if isTutorial then
			part:SetAttribute("TutorialFor", reservedFor.UserId)
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Atrapar"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Catching.range
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = part

	local w: Wild = {
		uid = uid,
		def = def,
		zone = zone,
		part = part,
		prompt = prompt,
		spawnedAt = os.clock(),
		lockedBy = nil,
		reservedFor = reservedFor,
		isTutorial = isTutorial,
		tween = nil,
	}
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
	local target = clampToZone(w.zone, w.part.Position + away.Unit * Catching.fleeDistance)
	moveTo(w, target, Spawning.wanderSpeed * Catching.fleeSpeedMultiplier)
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
	for _, attribute in { "CritterUid", "LockedBy", "TutorialFor", "ReservedFor", "Zone" } do
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

	carrying[player] = { def = w.def, part = part, warnedFull = false }
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
		Remotes.CatchResult:FireClient(player, true, "¡Has atrapado: " .. w.def.name .. "! Llévalo a tu santuario.")
		Remotes.Effect:FireAllClients("captura", position, w.def.rarity) -- todos ven las chispas
		Remotes.Effect:FireClient(player, "captura_mia")
		return
	end

	if w.part.Parent ~= nil then
		setLocked(w, nil)
		flee(w, player)
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
	if not Zones.IsUnlocked(player, w.zone) then
		notify(player, "Primero desbloquea esta zona.")
		return
	end
	local root = getRoot(player)
	if not root or (root.Position - w.part.Position).Magnitude > Catching.range + Catching.rangeTolerance then
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
		name = w.def.name,
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
		moment = math.clamp(pressedAt, now - Catching.latencyToleranceSeconds, now)
	end

	local elapsed = moment - mg.startTime
	local hit = elapsed >= 0
		and CatchBar.isInZone(CatchBar.markerAt(elapsed, Catching.barCycleSeconds), mg.zoneCenter, mg.zoneWidth)
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
	local zone = carried.def.zone
	local drop = randomSpawnPoint(zone)
	if root then
		local front = (root.CFrame * CFrame.new(0, 0, -Catching.releaseDistance)).Position
		local here = Zones.ZoneAt(front)
		if here then
			zone = here
			drop = front
		end
	end
	spawnWild(carried.def, zone, Vector3.new(drop.X, Gameplay.GroundY, drop.Z), nil, false)
	notify(player, "Has soltado a " .. carried.def.name .. ".")
end

-- Cada poco: si llevas un bicho y estás en tu santuario, se coloca en un hueco libre.
local function depositLoop()
	while true do
		task.wait(Catching.depositCheckSeconds)
		for player, carried in carrying do
			local root = getRoot(player)
			if root and Plots.IsInOwnPlot(player, root.Position) then
				local ok, message = Plots.AddCritter(player, carried.def)
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

local function spawnLoop()
	while true do
		task.wait(Spawning.intervalSeconds)
		for zone, area in Gameplay.Zones do
			if countWild(zone) < area.maxCritters then
				local def = pickCritter(zone, 1)
				if def then
					spawnWild(def, zone, randomSpawnPoint(zone), nil, false)
				end
			end
		end
	end
end

-- Suerte x2: un bicho reservado para el jugador, cerca de él, en la zona donde esté.
local function luckLoop()
	while true do
		task.wait(Luck.personalSpawnSeconds)
		for _, player in Players:GetPlayers() do
			local profile = Data.Get(player)
			local root = getRoot(player)
			if profile and root and profile.luckUntil > os.time() and luckCritter[player] == nil then
				local zone = Zones.ZoneAt(root.Position)
				if zone and Zones.IsUnlocked(player, zone) then
					local def = pickCritter(zone, Luck.rarityMultiplier)
					if def then
						local angle = rng:NextNumber(0, math.pi * 2)
						local point = root.Position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * Luck.spawnDistance
						point = clampToZone(zone, point)
						luckCritter[player] = spawnWild(def, zone, Vector3.new(point.X, Gameplay.GroundY, point.Z), player, false)
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
				if now - w.spawnedAt > Spawning.despawnSeconds then
					removeWild(w)
					w.part:Destroy()
				elseif rng:NextNumber() < Spawning.wanderChance then
					local offset = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * Spawning.wanderDistance
					moveTo(w, clampToZone(w.zone, w.part.Position + offset), Spawning.wanderSpeed)
				end
			end
		end
	end
end

-- Primeros 60 s del GDD: un bicho común aparece justo delante del jugador.
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
	local zone = Spawning.tutorialZone
	local def = firstCommonOfZone(zone)
	if not def then
		return
	end
	local front = (root.CFrame * CFrame.new(0, 0, -Spawning.tutorialDistance)).Position
	local w = spawnWild(def, zone, Vector3.new(front.X, Gameplay.GroundY, front.Z), player, true)
	-- que mire al jugador
	w.part.CFrame = CFrame.lookAt(w.part.Position, Vector3.new(root.Position.X, w.part.Position.Y, root.Position.Z))
end

-- Si el jugador muere o se va: se cancela el minijuego y el bicho que llevaba vuelve a su zona.
local function dropEverything(player: Player)
	if minigames[player] then
		endMinigame(player, false, "¡El bicho se ha escapado!")
	end
	local carried = carrying[player]
	if carried then
		carrying[player] = nil
		carried.part:Destroy()
		local zone = carried.def.zone
		spawnWild(carried.def, zone, randomSpawnPoint(zone), nil, false)
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

function CritterSpawner.Start()
	Remotes.AttemptCatch.OnServerEvent:Connect(onAttemptCatch)
	Remotes.ReleaseCarried.OnServerEvent:Connect(onReleaseCarried)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	task.spawn(spawnLoop)
	task.spawn(wanderLoop)
	task.spawn(depositLoop)
	task.spawn(luckLoop)

	-- Solo en Studio: ServerStorage.DebugCrearBicho:Invoke(player, "id_del_bicho") crea ese bicho
	-- reservado delante del jugador, para revisar modelos y probar capturas. No existe en el juego publicado.
	if RunService:IsStudio() then
		local debugSpawn = Instance.new("BindableFunction")
		debugSpawn.Name = "DebugCrearBicho"
		debugSpawn.OnInvoke = function(player: Player, critterId: string)
			local root = getRoot(player)
			for _, def in CrittersConfig.List do
				if def.id == critterId and root then
					local front = (root.CFrame * CFrame.new(0, 0, -8)).Position
					local zone = Zones.ZoneAt(front) or def.zone
					spawnWild(def, zone, Vector3.new(front.X, Gameplay.GroundY, front.Z), player, false)
					return true
				end
			end
			return false
		end
		debugSpawn.Parent = ServerStorage
	end
end

return CritterSpawner
