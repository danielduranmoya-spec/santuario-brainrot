--!strict
-- Índice de bichos (Config/Index). El servidor manda:
--   * Cada captura (CritterSpawner.OnCaught) suma 1 a las capturas totales y, si es la primera vez
--     que atrapas ese bicho, lo descubre.
--   * Al completar una rareza o llegar a un número de capturas se da el premio, una sola vez
--     (se apunta en profile.indexClaimed).
--   * A quien ya tenía bichos de antes de que existiera el índice, se le descubren al entrar.
-- El cliente (client/Bestiary) solo lee los atributos Discovered, IndexClaimed y TotalCaught.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local IndexConfig = require(Config:WaitForChild("Index"))
local Format = require(Shared:WaitForChild("Format"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local CritterSpawner = require(script.Parent:WaitForChild("CritterSpawner"))

type Reward = IndexConfig.Reward

local Bestiary = {}

local isKnown: { [string]: boolean } = {}
for _, def in CrittersConfig.List do
	isKnown[def.id] = true
end

-- Bichos que cuentan para completar cada rareza (los de evento no: van en Limitados).
local byRarity: { [string]: { string } } = {}
for _, def in CrittersConfig.List do
	if not def.eventOnly then
		local list = byRarity[def.rarity] or {}
		table.insert(list, def.id)
		byRarity[def.rarity] = list
	end
end

-- Da un premio y devuelve el texto ("+500 💰, +1 cebo").
local function give(player: Player, profile: Data.Profile, reward: Reward): string
	local parts = {}
	local coins = reward.coins
	if coins and coins > 0 then
		Economy.AddCoins(player, coins)
		table.insert(parts, "+" .. Format.number(coins) .. " 💰")
	end
	local baits = reward.baits
	if baits and baits > 0 then
		profile.baits += baits
		table.insert(parts, "+" .. baits .. (if baits == 1 then " cebo" else " cebos"))
	end
	local minutes = reward.luckMinutes
	if minutes and minutes > 0 then
		profile.luckUntil = math.max(profile.luckUntil, os.time()) + minutes * 60
		table.insert(parts, minutes .. " min de Suerte x2")
	end
	return table.concat(parts, ", ")
end

local function claim(player: Player, profile: Data.Profile, key: string, title: string, reward: Reward)
	if table.find(profile.indexClaimed, key) then
		return
	end
	table.insert(profile.indexClaimed, key)
	local text = give(player, profile, reward)
	Remotes.Notify:FireClient(player, "📖 " .. title .. " Premio: " .. text)
	Remotes.Effect:FireClient(player, "recompensa")
end

-- Revisa todos los premios (por si se añaden nuevos en Config, también se dan al entrar).
local function checkRewards(player: Player, profile: Data.Profile)
	for _, rarity in CrittersConfig.RarityOrder do
		local ids = byRarity[rarity]
		local reward = IndexConfig.RarityRewards[rarity]
		if ids and reward then
			local complete = true
			for _, id in ids do
				if not table.find(profile.discovered, id) then
					complete = false
					break
				end
			end
			if complete then
				claim(player, profile, "rareza:" .. rarity, "¡Has completado los bichos " .. CrittersConfig.Rarities[rarity].label .. " del índice!", reward)
			end
		end
	end
	for _, milestone in IndexConfig.Milestones do
		if profile.totalCaught >= milestone.count then
			claim(player, profile, "capturas:" .. milestone.count, "¡" .. milestone.count .. " capturas!", milestone)
		end
	end
end

local function discover(profile: Data.Profile, id: string): boolean
	if isKnown[id] and not table.find(profile.discovered, id) then
		table.insert(profile.discovered, id)
		return true
	end
	return false
end

local function onCaught(player: Player, def: CrittersConfig.Critter)
	local profile = Data.Get(player)
	if not profile then
		return
	end
	profile.totalCaught += 1
	if discover(profile, def.id) then
		Remotes.Notify:FireClient(player, "📖 ¡Nuevo en tu índice: " .. def.name .. "! (" .. #profile.discovered .. "/" .. #CrittersConfig.List .. ")")
	end
	checkRewards(player, profile)
	Data.Replicate(player)
end

function Bestiary.Start()
	CritterSpawner.OnCaught(function(player, def)
		onCaught(player, def)
	end)
	Data.OnLoaded(function(player, profile)
		-- Bichos que ya tenía en el santuario: cuentan como descubiertos.
		for _, entry in profile.critters do
			local id = MutationMath.decode(entry)
			discover(profile, id)
		end
		checkRewards(player, profile)
		Data.Replicate(player)
	end)
end

return Bestiary
