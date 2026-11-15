--!strict
-- Mejoras con monedas: Red (zona verde), Botas (velocidad), Santuario (huecos), Imán (radio de cobro).
-- La compra se valida aquí: nombre, nivel máximo, cooldown y monedas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Format = require(Shared:WaitForChild("Format"))
local UpgradeMath = require(Shared:WaitForChild("UpgradeMath"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local Upgrades = {}

local lastAction: { [Player]: number } = {}

local function applyWalkSpeed(player: Player)
	local profile = Data.Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if profile and humanoid then
		humanoid.WalkSpeed = UpgradeMath.walkSpeed(profile.upgrades.Botas or 0)
	end
end

local function onBuyUpgrade(player: Player, name: unknown)
	local now = os.clock()
	if now - (lastAction[player] or 0) < Gameplay.Menus.actionCooldownSeconds then
		return
	end
	lastAction[player] = now

	if typeof(name) ~= "string" then
		return
	end
	local def = Progression.Upgrades[name]
	local profile = Data.Get(player)
	if not def or not profile then
		return
	end

	local level = profile.upgrades[name] or 0
	if level >= def.maxLevel then
		Remotes.Notify:FireClient(player, def.title .. " ya está al máximo.")
		return
	end
	local cost = UpgradeMath.cost(name, level + 1)
	if not Economy.TrySpend(player, cost) then
		Remotes.Notify:FireClient(player, "Te faltan " .. Format.number(cost - Economy.GetCoins(player)) .. " monedas.")
		return
	end

	profile.upgrades[name] = level + 1
	Data.Replicate(player)
	if name == "Botas" then
		applyWalkSpeed(player)
	elseif name == "Santuario" then
		Plots.Refresh(player)
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	Remotes.Effect:FireClient(player, "compra", if root and root:IsA("BasePart") then root.Position else nil)
	Remotes.Notify:FireClient(player, "⬆ " .. def.title .. " nivel " .. (level + 1) .. ": " .. UpgradeMath.effectText(name, level + 1))
end

function Upgrades.Start()
	Remotes.BuyUpgrade.OnServerEvent:Connect(onBuyUpgrade)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			applyWalkSpeed(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)
	Data.OnLoaded(function(player)
		applyWalkSpeed(player)
	end)
end

return Upgrades
