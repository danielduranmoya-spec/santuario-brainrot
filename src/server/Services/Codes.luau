--!strict
-- Códigos de recompensa (Config/Codes). El cliente manda el texto; el servidor lo limpia, comprueba
-- que existe, que no ha caducado y que ese jugador no lo ha canjeado ya, y da el premio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CodesConfig = require(Config:WaitForChild("Codes"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Format = require(Shared:WaitForChild("Format"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))

local Codes = {}

local lastAttempt: { [Player]: number } = {}

local function notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, text)
end

local function onRedeem(player: Player, raw: unknown)
	local now = os.clock()
	if now - (lastAttempt[player] or 0) < Gameplay.Menus.codeCooldownSeconds then
		notify(player, "Espera un momento antes de probar otro código.")
		return
	end
	lastAttempt[player] = now
	if typeof(raw) ~= "string" or #raw > CodesConfig.maxLength * 4 then
		return
	end
	-- Sin espacios y en mayúsculas: "  bichos " vale igual que "BICHOS".
	local code = string.upper((string.gsub(raw, "%s+", "")))
	local reward = CodesConfig.List[code]
	local profile = Data.Get(player)
	if not profile then
		return
	end
	if not reward then
		notify(player, "❌ Ese código no existe.")
		return
	end
	if reward.expiresAt and os.time() > reward.expiresAt then
		notify(player, "⌛ Ese código ya ha caducado.")
		return
	end
	if table.find(profile.redeemedCodes, code) then
		notify(player, "Ya has canjeado " .. code .. ".")
		return
	end

	table.insert(profile.redeemedCodes, code)
	local parts = {}
	if reward.coins and reward.coins > 0 then
		Economy.AddCoins(player, reward.coins)
		table.insert(parts, Format.number(reward.coins) .. " 💰")
	end
	if reward.baits and reward.baits > 0 then
		profile.baits += reward.baits
		table.insert(parts, reward.baits .. (if reward.baits == 1 then " cebo" else " cebos"))
	end
	if reward.luckMinutes and reward.luckMinutes > 0 then
		profile.luckUntil = math.max(profile.luckUntil, os.time()) + reward.luckMinutes * 60
		table.insert(parts, reward.luckMinutes .. " min de Suerte x2")
	end
	Data.Replicate(player)
	notify(player, "🎁 ¡Código " .. code .. " canjeado! " .. table.concat(parts, " + "))
	Remotes.Effect:FireClient(player, "recompensa")
	Analytics.Custom(player, "codigo_canjeado")
end

function Codes.Start()
	Guard.Connect(Remotes.RedeemCode, "RedeemCode", onRedeem)
	Players.PlayerRemoving:Connect(function(player)
		lastAttempt[player] = nil
	end)
end

return Codes
