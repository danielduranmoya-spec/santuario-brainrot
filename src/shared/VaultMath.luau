--!strict
-- Cálculos del campo de bóvedas (posición, nombre, temática, precio, valor y suerte de cada una).
-- Los usan el servidor y el cliente, así los dos ven lo mismo. Bóveda 1 = la primera tras la plaza.

local Config = script.Parent:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local CrittersConfig = require(Config:WaitForChild("Critters"))

local F = Gameplay.Field
local NAMED = Progression.Vaults
local ENDLESS = Progression.EndlessVaults
local ROMAN = { "", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX", " X", " XI", " XII", " XIII", " XIV", " XV" }

local VaultMath = {}

VaultMath.MaxVaults = ENDLESS.maxVaults

-- Z del borde delantero (el de la puerta, hacia la plaza) de la bóveda n.
function VaultMath.frontZ(n: number): number
	return F.startZ - (n - 1) * F.vaultLength
end

function VaultMath.backZ(n: number): number
	return VaultMath.frontZ(n) - F.vaultLength
end

function VaultMath.center(n: number): Vector3
	return Vector3.new(0, Gameplay.GroundY, VaultMath.frontZ(n) - F.vaultLength / 2)
end

-- Bóveda en la que está una posición (nil si está en la plaza o fuera del campo).
function VaultMath.vaultAt(position: Vector3): number?
	if position.Z > F.startZ or math.abs(position.X) > F.width / 2 then
		return nil
	end
	local n = math.floor((F.startZ - position.Z) / F.vaultLength) + 1
	return if n >= 1 and n <= ENDLESS.maxVaults then n else nil
end

function VaultMath.theme(n: number): string
	return NAMED[(n - 1) % #NAMED + 1].theme
end

function VaultMath.name(n: number): string
	if n <= #NAMED then
		return NAMED[n].name
	end
	local base = NAMED[(n - 1) % #NAMED + 1].name
	local cycle = (n - 1) // #NAMED + 1
	return base .. (ROMAN[cycle] or (" " .. cycle))
end

-- Redondea a 2 cifras significativas (precios bonitos: 9.600.000 en vez de 9.583.172).
local function niceRound(value: number): number
	if value < 100 then
		return math.floor(value)
	end
	local magnitude = 10 ^ (math.floor(math.log10(value)) - 1)
	return math.floor(value / magnitude + 0.5) * magnitude
end

function VaultMath.cost(n: number): number
	if n <= #NAMED then
		return NAMED[n].unlockCost
	end
	return niceRound(NAMED[#NAMED].unlockCost * ENDLESS.costGrowth ^ (n - #NAMED))
end

-- Cuánto multiplica la producción de los bichos atrapados en la bóveda n.
function VaultMath.valueMultiplier(n: number): number
	if n < ENDLESS.valueFromVault then
		return 1
	end
	return math.floor(ENDLESS.valueGrowth ^ (n - ENDLESS.valueFromVault + 1) + 0.5)
end

-- Porcentaje de cada rareza en la bóveda n (Config/Critters.VaultChances).
function VaultMath.rarityChances(n: number): { [string]: number }
	local rows = CrittersConfig.VaultChances
	return rows[math.clamp(n, 1, #rows)]
end

-- Bichos que pueden aparecer en la bóveda n: los suyos y los de todas las anteriores.
function VaultMath.critterPool(n: number): { CrittersConfig.Critter }
	local pool = {}
	for _, def in CrittersConfig.List do
		if not def.eventOnly and def.vault <= n then -- los de evento solo salen durante su evento
			table.insert(pool, def)
		end
	end
	return pool
end

export type CritterChance = { def: CrittersConfig.Critter, chance: number }

-- Reparto exacto por bicho en la bóveda n, en tanto por ciento (suma 100): el porcentaje de cada
-- rareza se divide a partes iguales entre sus bichos. Con `luck` > 1 (Suerte x2), todas las rarezas
-- menos la más común de esa bóveda pesan `luck` veces más.
function VaultMath.critterChances(n: number, luck: number?): { CritterChance }
	local chances = VaultMath.rarityChances(n)
	local byRarity: { [string]: { CrittersConfig.Critter } } = {}
	for _, def in VaultMath.critterPool(n) do
		local list = byRarity[def.rarity]
		if not list then
			list = {}
			byRarity[def.rarity] = list
		end
		table.insert(list, def)
	end
	local result: { CritterChance } = {}
	local total = 0
	local lowestSeen = false
	for _, rarity in CrittersConfig.RarityOrder do
		local list = byRarity[rarity]
		local weight = chances[rarity] or 0
		if list and weight > 0 then
			if lowestSeen then
				weight *= luck or 1
			end
			lowestSeen = true
			for _, def in list do
				table.insert(result, { def = def, chance = weight / #list })
				total += weight / #list
			end
		end
	end
	if total > 0 then
		for _, item in result do
			item.chance = item.chance / total * 100
		end
	end
	return result
end

-- Elige un bicho de la bóveda n con ese reparto. `roll` es un número al azar entre 0 y 1.
function VaultMath.pickCritter(n: number, luck: number, roll: number): CrittersConfig.Critter?
	local list = VaultMath.critterChances(n, luck)
	local left = roll * 100
	for _, item in list do
		left -= item.chance
		if left <= 0 then
			return item.def
		end
	end
	local last = list[#list]
	return if last then last.def else nil
end

return VaultMath
