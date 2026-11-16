--!strict
-- Analítica del embudo (Config/Analytics) con AnalyticsService de Roblox.
--   * Step(player, "nombre"): paso del embudo de los primeros minutos. Se envía una sola vez por
--     jugador en toda su vida (se apunta en su perfil), así el embudo cuenta jugadores, no visitas.
--   * Custom(player, "evento", valor?): evento suelto (legendario, robo, valla, código...).
-- Los datos se ven en el Creator Hub > tu experiencia > Analíticas (tardan unas horas en aparecer).
-- En Studio no se envía nada a Roblox; solo se escribe en la consola para comprobarlo.

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local AnalyticsConfig = require(Config:WaitForChild("Analytics"))

local Data = require(script.Parent:WaitForChild("Data"))

local Analytics = {}

local stepIndex: { [string]: number } = {}
for i, name in AnalyticsConfig.OnboardingSteps do
	stepIndex[name] = i
end

local stepListeners: { (Player, string) -> () } = {}

-- `callback(player, paso)` se llama la primera vez que un jugador completa cada paso.
function Analytics.OnStep(callback: (Player, string) -> ())
	table.insert(stepListeners, callback)
end

function Analytics.Step(player: Player, name: string)
	local index = stepIndex[name]
	local profile = Data.Get(player)
	if not index or not profile or table.find(profile.funnelSteps, name) then
		return
	end
	table.insert(profile.funnelSteps, name)
	if RunService:IsStudio() then
		print("[Analytics] Paso " .. index .. " (" .. name .. ") de " .. player.Name)
	else
		local ok, err = pcall(function()
			AnalyticsService:LogOnboardingStepEvent(player, index, name)
		end)
		if not ok then
			warn("[Analytics] " .. tostring(err))
		end
	end
	for _, callback in stepListeners do
		task.spawn(callback, player, name)
	end
end

function Analytics.Custom(player: Player, eventName: string, value: number?)
	if RunService:IsStudio() then
		print("[Analytics] Evento " .. eventName .. " de " .. player.Name .. (if value then " = " .. value else ""))
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
	if not ok then
		warn("[Analytics] " .. tostring(err))
	end
end

function Analytics.Start()
	Data.OnLoaded(function(player)
		Analytics.Step(player, "entra")
	end)
end

return Analytics
