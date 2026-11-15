--!strict
-- Atmósfera: al entrar en una bóveda, la niebla y el tono de color cambian suavemente según su
-- temática (playa azulada, bosque verde, volcán anaranjado, nube rosada). De noche, todo se tiñe de
-- azul oscuro. Solo en este cliente.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))

local CHECK_SECONDS = 0.5

local Ambience = {}

local function themeAt(position: Vector3): string
	local vault = VaultMath.vaultAt(position)
	return if vault then VaultMath.theme(vault) else "PlayaRara" -- la plaza usa la de la playa
end

local function apply(theme: string, night: boolean)
	local settings = Art.ambience[theme]
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
		local tint = if night then settings.tint:Lerp(Art.night.tint, 0.85) else settings.tint
		TweenService:Create(correction, info, { TintColor = tint }):Play()
	end
end

function Ambience.Start()
	task.spawn(function()
		local current = ""
		while true do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local night = ReplicatedStorage:GetAttribute("IsNight") == true
			if root and root:IsA("BasePart") then
				local key = themeAt(root.Position) .. (if night then "-noche" else "")
				if key ~= current then
					current = key
					apply(themeAt(root.Position), night)
				end
			end
			task.wait(CHECK_SECONDS)
		end
	end)
end

return Ambience
