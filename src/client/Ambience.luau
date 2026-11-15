--!strict
-- Atmósfera por zona: al entrar en una zona, la niebla y el tono de color cambian suavemente
-- (playa azulada, bosque verde, volcán anaranjado, nube rosada). Solo en este cliente.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))
local Gameplay = require(Config:WaitForChild("Gameplay"))

local CHECK_SECONDS = 0.5

local Ambience = {}

local function zoneAt(position: Vector3): string
	for zoneId, area in Gameplay.Zones do
		local offset = Vector3.new(position.X - area.center.X, 0, position.Z - area.center.Z)
		if offset.Magnitude <= area.radius then
			return zoneId
		end
	end
	return "PlayaRara" -- fuera de las zonas (santuarios, caminos) se usa la de la playa
end

local function apply(zoneId: string)
	local settings = Art.ambience[zoneId]
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local correction = Lighting:FindFirstChild("ColorZona")
	local info = TweenInfo.new(Art.ambienceTweenSeconds)
	if settings and atmosphere then
		TweenService:Create(atmosphere, info, {
			Color = settings.color,
			Density = settings.density,
			Decay = settings.decay,
			Haze = settings.haze,
		}):Play()
	end
	if settings and correction and correction:IsA("ColorCorrectionEffect") then
		TweenService:Create(correction, info, { TintColor = settings.tint }):Play()
	end
end

function Ambience.Start()
	task.spawn(function()
		local current = ""
		while true do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local zone = zoneAt(root.Position)
				if zone ~= current then
					current = zone
					apply(zone)
				end
			end
			task.wait(CHECK_SECONDS)
		end
	end)
end

return Ambience
