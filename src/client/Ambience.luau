--!strict
-- Atmósfera: al entrar en una bóveda, la niebla y el tono de color cambian suavemente según su
-- temática (playa azulada, bosque verde, volcán anaranjado, nube rosada). Durante un evento de
-- mutación (Config/Mutations.Events) todo se tiñe del color del evento y caen partículas del cielo.
-- Solo en este cliente.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))

local CHECK_SECONDS = 0.5

local Ambience = {}

local function themeAt(position: Vector3): string
	local vault = VaultMath.vaultAt(position)
	return if vault then VaultMath.theme(vault) else "PlayaRara" -- la plaza usa la de la playa
end

local SKY_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local E = Art.mutationEvent

-- Cielo del evento: una pieza invisible sobre el jugador que suelta partículas hacia abajo.
local skyPart = Instance.new("Part")
skyPart.Name = "CieloEvento"
skyPart.Anchored = true
skyPart.CanCollide = false
skyPart.CanQuery = false
skyPart.CanTouch = false
skyPart.Transparency = 1
skyPart.Size = Vector3.new(E.skySize, 1, E.skySize)
local skyEmitter = Instance.new("ParticleEmitter")
skyEmitter.Texture = SKY_TEXTURE
skyEmitter.EmissionDirection = Enum.NormalId.Bottom
skyEmitter.Speed = NumberRange.new(E.fallSpeed * 0.7, E.fallSpeed)
skyEmitter.Lifetime = NumberRange.new(E.lifetime * 0.8, E.lifetime)
skyEmitter.Rate = E.rate
skyEmitter.LightEmission = 1
skyEmitter.Size = NumberSequence.new(0.5, 0.2)
skyEmitter.Enabled = false
skyEmitter.Parent = skyPart

local function apply(theme: string, eventId: string?)
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
		local event = if eventId then MutationMath.event(eventId) else nil
		local tint = if event then settings.tint:Lerp(event.tint, E.tintStrength) else settings.tint
		TweenService:Create(correction, info, { TintColor = tint }):Play()
	end
end

function Ambience.Start()
	skyPart.Parent = Workspace
	task.spawn(function()
		local current = ""
		while true do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local eventId = ReplicatedStorage:GetAttribute("MutationEvent") :: string?
			local event = if eventId then MutationMath.event(eventId) else nil
			if root and root:IsA("BasePart") then
				local key = themeAt(root.Position) .. "-" .. (eventId or "")
				if key ~= current then
					current = key
					apply(themeAt(root.Position), eventId)
				end
				skyPart.CFrame = CFrame.new(root.Position + Vector3.new(0, E.skyHeight, 0))
			end
			skyEmitter.Enabled = event ~= nil
			if event then
				skyEmitter.Color = ColorSequence.new(event.color)
			end
			task.wait(CHECK_SECONDS)
		end
	end)
end

return Ambience
