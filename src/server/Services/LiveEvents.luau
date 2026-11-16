--!strict
-- Eventos de servidor (Config/Events), lo que hace que la gente vuelva y juegue junta:
--   * Bicho legendario de servidor: cada 8 minutos, con aviso de 15 s, aparece uno en la bóveda 1
--     (todos la tienen abierta). El primero que lo atrapa se lo queda y sale en el chat.
--   * Lluvia de Bichos: los sábados a las 18:00 (Madrid), 30 min con bichos x3 y el bicho
--     exclusivo de la semana.
-- El cliente lee los atributos de ReplicatedStorage para el cartel con la cuenta atrás:
--   LegendaryAt (tiempo de servidor en que aparece), RainEndsAt y RainNextAt (os.time UTC).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Events = require(Config:WaitForChild("Events"))

local Remotes = require(script.Parent:WaitForChild("Remotes"))
local DayNight = require(script.Parent:WaitForChild("DayNight"))
local CritterSpawner = require(script.Parent:WaitForChild("CritterSpawner"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))

local L = Events.ServerLegendary
local R = Events.LluviaDeBichos
local SECONDS_PER_DAY = 24 * 60 * 60
local LEGENDARY_TAG = "legendario"
local GOLD = Color3.fromRGB(255, 200, 40)
local RAIN = Color3.fromRGB(120, 190, 255)

local LiveEvents = {}

local defsById: { [string]: CrittersConfig.Critter } = {}
for _, def in CrittersConfig.List do
	defsById[def.id] = def
end

local function announce(text: string, color: Color3?)
	Remotes.Announce:FireAllClients(text, color)
end

-- ===================== Legendario de servidor =====================

local legendaryAlive = false
local forceLegendary = false -- solo Studio: DebugLegendario

local function runLegendary()
	local def = defsById[L.critterId]
	if not def then
		warn("[LiveEvents] No existe el bicho legendario " .. tostring(L.critterId) .. " en Config/Critters")
		return
	end
	local nextAt = os.clock() + L.firstDelaySeconds
	local warned = false
	while true do
		task.wait(0.5)
		local now = os.clock()
		if forceLegendary and not warned then
			forceLegendary = false
			nextAt = now + L.warningSeconds
		end
		if legendaryAlive or #Players:GetPlayers() == 0 then
			-- Uno cada vez, y no gastamos el aviso en un servidor vacío.
			nextAt = math.max(nextAt, now + L.warningSeconds + 1)
		elseif not warned and now >= nextAt - L.warningSeconds then
			if DayNight.IsNight() then
				-- De noche los bichos duermen: se retrasa hasta que amanezca.
				nextAt = now + L.warningSeconds + 1
			else
				warned = true
				ReplicatedStorage:SetAttribute("LegendaryAt", Workspace:GetServerTimeNow() + (nextAt - now))
				announce("⭐ ¡Un bicho LEGENDARIO aparecerá en " .. math.ceil(nextAt - now) .. " s en la Playa Rara! ¡Corre!", GOLD)
			end
		elseif warned and now >= nextAt then
			warned = false
			ReplicatedStorage:SetAttribute("LegendaryAt", nil)
			nextAt = now + L.intervalSeconds
			legendaryAlive = true
			CritterSpawner.SpawnEvent(def, 1, LEGENDARY_TAG, L.lifetimeSeconds)
			announce("⭐ ¡Ha aparecido la " .. def.name .. " LEGENDARIA en la Playa Rara! El primero que la atrape se la queda.", GOLD)
		end
	end
end

-- ===================== Lluvia de Bichos =====================

local forcedRain: boolean? = nil -- solo Studio: DebugLluvia
local rainActive = false

-- ¿Hay lluvia ahora? Devuelve también cuándo termina (os.time UTC).
local function rainWindow(now: number): (boolean, number)
	if forcedRain ~= nil then
		return forcedRain, if forcedRain then now + R.durationMinutes * 60 else 0
	end
	local t = os.date("!*t", now)
	if t.wday ~= R.weekday then
		return false, 0
	end
	local start = now - (t.hour * 3600 + t.min * 60 + t.sec) + R.hourUTC * 3600
	local finish = start + R.durationMinutes * 60
	return now >= start and now < finish, finish
end

-- Próximo comienzo de la lluvia (os.time UTC).
local function nextRainStart(now: number): number
	local t = os.date("!*t", now)
	local midnight = now - (t.hour * 3600 + t.min * 60 + t.sec)
	for d = 0, 7 do
		local wday = (t.wday - 1 + d) % 7 + 1
		local start = midnight + d * SECONDS_PER_DAY + R.hourUTC * 3600
		if wday == R.weekday and start > now then
			return start
		end
	end
	return now + 7 * SECONDS_PER_DAY
end

local function updateRain()
	local now = os.time()
	local active, endsAt = rainWindow(now)
	ReplicatedStorage:SetAttribute("RainNextAt", nextRainStart(now))
	if active == rainActive then
		return
	end
	rainActive = active
	if active then
		CritterSpawner.SetSpawnBoost(R.spawnMultiplier, defsById[R.exclusiveCritterId], R.exclusiveChance)
		ReplicatedStorage:SetAttribute("RainEndsAt", endsAt)
		local exclusive = defsById[R.exclusiveCritterId]
		announce(
			"🌧 ¡Empieza la LLUVIA DE BICHOS! " .. R.durationMinutes .. " minutos con bichos x" .. R.spawnMultiplier
				.. (if exclusive then " y la " .. exclusive.name .. ", que solo sale hoy." else "."),
			RAIN
		)
	else
		CritterSpawner.SetSpawnBoost(1, nil, 0)
		ReplicatedStorage:SetAttribute("RainEndsAt", nil)
		announce("🌤 Ha terminado la Lluvia de Bichos. ¡Vuelve el próximo sábado!", RAIN)
	end
end

function LiveEvents.IsRaining(): boolean
	return rainActive
end

function LiveEvents.Start()
	CritterSpawner.OnCaught(function(player, def, tag)
		if tag == LEGENDARY_TAG then
			legendaryAlive = false
			announce("🏆 ¡" .. player.DisplayName .. " ha atrapado a la " .. def.name .. " LEGENDARIA!", GOLD)
			Analytics.Custom(player, "legendario_atrapado")
		end
	end)
	CritterSpawner.OnExpired(function(def, tag)
		if tag == LEGENDARY_TAG then
			legendaryAlive = false
			announce("💨 La " .. def.name .. " legendaria se ha ido volando. ¡Vuelve en " .. L.intervalSeconds // 60 .. " minutos!", GOLD)
		end
	end)
	task.spawn(runLegendary)
	task.spawn(function()
		while true do
			updateRain()
			task.wait(5)
		end
	end)

	-- Solo en Studio, para probar:
	--   ServerStorage.DebugLluvia:Invoke(true) empieza la lluvia; (false) la termina; (nil) vuelve al horario.
	--   ServerStorage.DebugLegendario:Invoke() hace que el legendario salga en 15 s.
	if RunService:IsStudio() then
		local debugRain = Instance.new("BindableFunction")
		debugRain.Name = "DebugLluvia"
		debugRain.OnInvoke = function(on: boolean?)
			forcedRain = on
			updateRain()
			return rainActive
		end
		debugRain.Parent = ServerStorage

		local debugLegendary = Instance.new("BindableFunction")
		debugLegendary.Name = "DebugLegendario"
		debugLegendary.OnInvoke = function()
			legendaryAlive = false
			forceLegendary = true -- el bucle lo ve en medio segundo y da el aviso de 15 s
			return true
		end
		debugLegendary.Parent = ServerStorage
	end
end

return LiveEvents
