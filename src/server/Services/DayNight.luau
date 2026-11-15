--!strict
-- Ciclo de día y noche (Config/Events.DayNight): 5 minutos de día y 30 segundos de noche.
--   * Publica el estado en ReplicatedStorage (atributos IsNight y PhaseEndsAt, en tiempo de servidor)
--     para que el cliente enseñe la cuenta atrás.
--   * Cambia la luz del cielo poco a poco (Lighting se replica a todos).
--   * Avisa a quien escuche (CritterSpawner) para dormir/despertar a los bichos: de noche no se
--     puede atrapar nada (validado en el servidor).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Events = require(Config:WaitForChild("Events"))
local Art = require(Config:WaitForChild("Art"))

local C = Events.DayNight

local DayNight = {}

local isNight = false
local listeners: { (boolean) -> () } = {}

function DayNight.IsNight(): boolean
	return isNight
end

-- `callback(isNight)` se llama cada vez que cambia.
function DayNight.OnChanged(callback: (boolean) -> ())
	table.insert(listeners, callback)
end

local function applyLighting(night: boolean)
	local info = TweenInfo.new(C.transitionSeconds, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, {
		ClockTime = if night then C.nightClockTime else C.dayClockTime,
		Brightness = if night then Art.night.brightness else Art.lighting.brightness,
		OutdoorAmbient = if night then Art.night.ambient else Art.lighting.outdoorAmbient,
	}):Play()
end

local function setPhase(night: boolean, duration: number)
	isNight = night
	ReplicatedStorage:SetAttribute("IsNight", night)
	ReplicatedStorage:SetAttribute("PhaseEndsAt", Workspace:GetServerTimeNow() + duration)
	applyLighting(night)
	for _, callback in listeners do
		task.spawn(callback, night)
	end
end

local phaseEndsAt = 0

local function startPhase(night: boolean)
	local duration = if night then C.nightSeconds else C.daySeconds
	phaseEndsAt = os.clock() + duration
	setPhase(night, duration)
end

function DayNight.Start()
	ReplicatedStorage:SetAttribute("NightWarningSeconds", C.warningSeconds)
	startPhase(false)
	task.spawn(function()
		while true do
			task.wait(0.25)
			if os.clock() >= phaseEndsAt then
				startPhase(not isNight)
			end
		end
	end)

	-- Solo en Studio: ServerStorage.DebugNoche:Invoke(true) hace de noche ya; (false), de día.
	if RunService:IsStudio() then
		local debugNight = Instance.new("BindableFunction")
		debugNight.Name = "DebugNoche"
		debugNight.OnInvoke = function(night: boolean)
			startPhase(night == true)
			return isNight
		end
		debugNight.Parent = ServerStorage
	end
end

return DayNight
