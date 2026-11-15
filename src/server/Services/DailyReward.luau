--!strict
-- Recompensa diaria con racha (Config/Events). Se da sola al entrar, una vez por día (UTC).
-- Si un día pasa sin entrar, la racha vuelve al día 1; tras el último día vuelve a empezar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Events = require(Config:WaitForChild("Events"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Format = require(Shared:WaitForChild("Format"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local SECONDS_PER_DAY = 24 * 60 * 60

local DailyReward = {}

local function firstCritterOfRarity(rarity: string): CrittersConfig.Critter?
	for _, def in CrittersConfig.List do
		if def.rarity == rarity then
			return def
		end
	end
	return nil
end

local function grant(player: Player, profile: Data.Profile)
	local today = os.time() // SECONDS_PER_DAY
	if profile.lastDailyDay == today then
		return
	end
	local days = Events.DailyRewardStreakDays
	local streak = if profile.lastDailyDay == today - 1 then profile.dailyStreak % days + 1 else 1
	local reward = Events.DailyRewards[streak]
	profile.lastDailyDay = today
	profile.dailyStreak = streak

	local parts = {}
	if reward and reward.coins > 0 then
		Economy.AddCoins(player, reward.coins)
		table.insert(parts, Format.number(reward.coins) .. " monedas")
	end
	local critterRarity = reward and (reward :: any).critterRarity
	if typeof(critterRarity) == "string" then
		local def = firstCritterOfRarity(critterRarity)
		if def then
			Plots.GrantCritter(player, def)
			table.insert(parts, "¡un bicho " .. CrittersConfig.Rarities[def.rarity].label .. ": " .. def.name .. "!")
		end
	end
	Data.Replicate(player)

	-- Esperamos un poco para que el aviso no se pise con los primeros mensajes de la partida.
	task.delay(Gameplay.Data.studioWarningDelaySeconds * 2, function()
		if player.Parent then
			Remotes.Effect:FireClient(player, "recompensa")
			Remotes.Notify:FireClient(player, "🎁 Recompensa diaria (día " .. streak .. "/" .. days .. "): " .. table.concat(parts, " y "))
		end
	end)
end

function DailyReward.Start()
	Data.OnLoaded(grant)
end

return DailyReward
