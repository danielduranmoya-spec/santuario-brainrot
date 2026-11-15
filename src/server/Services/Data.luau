--!strict
-- Guardado de datos del jugador con DataStore.
--   * Carga al entrar y guarda al salir, al cerrar el servidor (BindToClose) y cada SaveIntervalSeconds.
--   * Todo con pcall y reintentos.
--   * Reserva de sesión sencilla: mientras juegas, tus datos llevan la marca de este servidor. Si otro
--     servidor los tiene reservados (por ejemplo, saltaste de servidor), se espera un poco; si la reserva
--     es muy antigua, se ignora. Un servidor que pierde la reserva deja de guardar para no pisar datos.
--   * Si DataStore no está disponible (sitio sin publicar o Studio sin acceso a API), el juego funciona
--     igual sin guardar y avisa de cómo activarlo.
-- Cuando el juego crezca, migrar a ProfileStore (ver CLAUDE.md).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local CrittersConfig = require(Config:WaitForChild("Critters"))

local Remotes = require(script.Parent:WaitForChild("Remotes"))

export type Profile = {
	version: number,
	coins: number,
	critters: { string }, -- ids de los bichos del santuario, en orden de hueco
	upgrades: { [string]: number },
	zones: { [string]: boolean },
	starterPackBought: boolean,
	baits: number,
	luckUntil: number, -- os.time() hasta el que dura Suerte x2
	dailyStreak: number,
	lastDailyDay: number, -- día (UTC) de la última recompensa diaria
	receipts: { string }, -- últimas compras procesadas (para no darlas dos veces)
}

type Callback = (Player, Profile) -> ()
type ReleaseCallback = (Player, Profile?) -> ()

local D = Gameplay.Data
local PROFILE_VERSION = 1
local HOW_TO_ENABLE = "Para guardar en Studio: publica el sitio (Archivo > Publicar en Roblox) y activa "
	.. "Inicio > Configuración del juego > Seguridad > Enable Studio Access to API Services."

local Data = {}

local profiles: { [Player]: Profile } = {}
local persistent: { [Player]: boolean } = {} -- true si este servidor puede guardar sus datos
local releasing: { [Player]: boolean } = {}
local loadedCallbacks: { Callback } = {}
local releaseCallbacks: { ReleaseCallback } = {}

local critterIds: { [string]: boolean } = {}
for _, def in CrittersConfig.List do
	critterIds[def.id] = true
end

local store: DataStore? = nil
local storeAvailable = true
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(D.storeName)
	end)
	if ok then
		store = result
	else
		storeAvailable = false
		warn("[Data] DataStore no disponible: " .. tostring(result))
	end
end

local function keyFor(player: Player): string
	return "jugador_" .. player.UserId
end

-- Errores que significan "aquí no hay DataStore" (no merece la pena reintentar).
local function isUnavailableError(message: string): boolean
	return string.find(message, "Studio", 1, true) ~= nil
		or string.find(message, "publish", 1, true) ~= nil
		or string.find(message, "API", 1, true) ~= nil
end

local function defaultProfile(): Profile
	local upgrades = {}
	for name in Progression.Upgrades do
		upgrades[name] = 0
	end
	local zones = {}
	for _, zone in Progression.Zones do
		if zone.unlockCost == 0 then
			zones[zone.id] = true
		end
	end
	return {
		version = PROFILE_VERSION,
		coins = 0,
		critters = {},
		upgrades = upgrades,
		zones = zones,
		starterPackBought = false,
		baits = 0,
		luckUntil = 0,
		dailyStreak = 0,
		lastDailyDay = -1,
		receipts = {},
	}
end

-- Mezcla lo guardado con los valores por defecto: rellena campos nuevos y descarta lo que ya no existe.
local function reconcile(saved: any): Profile
	local profile = defaultProfile()
	if type(saved) ~= "table" then
		return profile
	end
	if type(saved.coins) == "number" and saved.coins == saved.coins then
		profile.coins = math.max(0, math.floor(saved.coins))
	end
	if type(saved.critters) == "table" then
		for _, id in saved.critters do
			if type(id) == "string" and critterIds[id] then
				table.insert(profile.critters, id)
			end
		end
	end
	if type(saved.upgrades) == "table" then
		for name, def in Progression.Upgrades do
			local level = saved.upgrades[name]
			if type(level) == "number" then
				profile.upgrades[name] = math.clamp(math.floor(level), 0, def.maxLevel)
			end
		end
	end
	if type(saved.zones) == "table" then
		for _, zone in Progression.Zones do
			if saved.zones[zone.id] == true then
				profile.zones[zone.id] = true
			end
		end
	end
	if type(saved.starterPackBought) == "boolean" then
		profile.starterPackBought = saved.starterPackBought
	end
	for _, field in { "baits", "luckUntil", "dailyStreak", "lastDailyDay" } do
		local value = saved[field]
		if type(value) == "number" and value == value then
			(profile :: any)[field] = math.floor(value)
		end
	end
	if type(saved.receipts) == "table" then
		for _, receipt in saved.receipts do
			if type(receipt) == "string" then
				table.insert(profile.receipts, receipt)
			end
		end
	end
	return profile
end

-- Carga (y reserva) los datos. Devuelve el perfil y si se podrá guardar.
-- Devuelve nil si falló de verdad (el jugador será expulsado para no perder su progreso).
local function load(player: Player): (Profile?, boolean)
	local dataStore = store
	if not storeAvailable or not dataStore then
		return defaultProfile(), false
	end

	local key = keyFor(player)
	local lockWaits = 0
	for attempt = 1, D.maxRetries + D.lockRetries do
		local lockedByOther = false
		local loaded: Profile? = nil
		local forceLock = lockWaits >= D.lockRetries
		local ok, err = pcall(function()
			dataStore:UpdateAsync(key, function(old: any)
				local lock = if type(old) == "table" then old.lock else nil
				if
					not forceLock
					and type(lock) == "table"
					and lock.jobId ~= game.JobId
					and type(lock.time) == "number"
					and os.time() - lock.time < D.lockTimeoutSeconds
				then
					lockedByOther = true
					return nil -- no escribir: otro servidor tiene los datos
				end
				lockedByOther = false
				local profile = reconcile(if type(old) == "table" then old.data else nil)
				loaded = profile
				return { data = profile, lock = { jobId = game.JobId, time = os.time() } }
			end)
		end)

		if ok and not lockedByOther and loaded then
			return loaded, true
		elseif ok and lockedByOther then
			lockWaits += 1
			task.wait(D.lockWaitSeconds)
		else
			local message = tostring(err)
			if isUnavailableError(message) then
				storeAvailable = false
				warn("[Data] DataStore no disponible: " .. message)
				return defaultProfile(), false
			end
			warn("[Data] Error al cargar (intento " .. attempt .. "): " .. message)
			task.wait(D.retryDelaySeconds * attempt)
		end
		if player.Parent == nil then
			return nil, false
		end
	end
	return nil, false
end

local function save(player: Player, releaseLock: boolean): boolean
	local profile = profiles[player]
	local dataStore = store
	if not profile or not persistent[player] or not dataStore then
		return false
	end
	local key = keyFor(player)
	for attempt = 1, D.maxRetries do
		local lostLock = false
		local ok, err = pcall(function()
			dataStore:UpdateAsync(key, function(old: any)
				local lock = if type(old) == "table" then old.lock else nil
				if type(lock) == "table" and lock.jobId ~= game.JobId then
					lostLock = true
					return nil
				end
				return {
					data = profile,
					lock = if releaseLock then nil else { jobId = game.JobId, time = os.time() },
				}
			end)
		end)
		if ok then
			if lostLock then
				warn("[Data] Otro servidor tiene ahora los datos de " .. player.Name .. "; este deja de guardar.")
				persistent[player] = false
				return false
			end
			return true
		end
		warn("[Data] Error al guardar (intento " .. attempt .. "): " .. tostring(err))
		task.wait(D.retryDelaySeconds * attempt)
	end
	return false
end

-- Copia en atributos del jugador lo que la interfaz necesita ver (el cliente no modifica nada).
function Data.Replicate(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	for name, level in profile.upgrades do
		player:SetAttribute("Upgrade_" .. name, level)
	end
	for _, zone in Progression.Zones do
		player:SetAttribute("Zone_" .. zone.id, profile.zones[zone.id] == true)
	end
	player:SetAttribute("CritterCount", #profile.critters)
	player:SetAttribute("StarterPackBought", profile.starterPackBought)
	player:SetAttribute("Baits", profile.baits)
	player:SetAttribute("LuckUntil", profile.luckUntil)
	player:SetAttribute("DailyStreak", profile.dailyStreak)
end

function Data.Get(player: Player): Profile?
	return profiles[player]
end

-- ¿Se guardan de verdad los datos de este jugador?
function Data.IsPersistent(player: Player): boolean
	return persistent[player] == true
end

-- Guarda ya (por ejemplo, tras una compra). Devuelve true si quedó guardado.
function Data.Save(player: Player): boolean
	return save(player, false)
end

-- Se llama cuando los datos de un jugador están listos (en el orden de registro).
function Data.OnLoaded(callback: Callback)
	table.insert(loadedCallbacks, callback)
end

-- Se llama al salir el jugador, justo antes del último guardado.
function Data.OnRelease(callback: ReleaseCallback)
	table.insert(releaseCallbacks, callback)
end

local function onPlayerAdded(player: Player)
	local profile, canSave = load(player)
	if player.Parent == nil then
		return
	end
	if not profile then
		player:Kick("No hemos podido cargar tus datos. Vuelve a entrar en un momento.")
		return
	end
	profiles[player] = profile
	persistent[player] = canSave
	Data.Replicate(player)
	player:SetAttribute("DataLoaded", true)
	player:SetAttribute("DataPersistent", canSave)

	if not canSave then
		warn("[Data] El progreso NO se guardará en esta sesión. " .. HOW_TO_ENABLE)
		task.delay(D.studioWarningDelaySeconds, function()
			if player.Parent and RunService:IsStudio() then
				Remotes.Notify:FireClient(player, "⚠ Sin guardado. " .. HOW_TO_ENABLE)
			end
		end)
	end

	for _, callback in loadedCallbacks do
		task.spawn(callback, player, profile)
	end
end

local function release(player: Player)
	if releasing[player] then
		return
	end
	releasing[player] = true
	local profile = profiles[player]
	for _, callback in releaseCallbacks do
		local ok, err = pcall(callback, player, profile)
		if not ok then
			warn("[Data] Error antes de guardar: " .. tostring(err))
		end
	end
	if profile then
		save(player, true)
	end
	profiles[player] = nil
	persistent[player] = nil
	releasing[player] = nil
end

local function autosaveLoop()
	while true do
		task.wait(Progression.SaveIntervalSeconds)
		for player in profiles do
			if not releasing[player] then
				task.spawn(save, player, false)
			end
		end
	end
end

function Data.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	task.spawn(autosaveLoop)

	-- Al cerrar el servidor: guarda a todos y espera a que terminen (también los que ya estaban saliendo).
	game:BindToClose(function()
		for player in profiles do
			task.spawn(release, player)
		end
		local deadline = os.clock() + D.closeTimeoutSeconds
		while next(profiles) ~= nil and os.clock() < deadline do
			task.wait()
		end
	end)
end

return Data
