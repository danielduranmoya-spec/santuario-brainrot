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
	if n <= #NAMED then
		return 1
	end
	return math.floor(ENDLESS.valueGrowth ^ (n - #NAMED) + 0.5)
end

function VaultMath.luck(n: number): number
	if n <= #NAMED then
		return 1
	end
	return 1 + ENDLESS.luckPerVault * (n - #NAMED)
end

-- Bichos que pueden aparecer: los de su temática en las 4 primeras; todos a partir de la 5ª.
function VaultMath.critterPool(n: number): { CrittersConfig.Critter }
	local pool = {}
	local theme = VaultMath.theme(n)
	for _, def in CrittersConfig.List do
		if def.eventOnly then
			continue -- los bichos de evento solo salen durante su evento
		end
		if n > #NAMED or def.zone == theme then
			table.insert(pool, def)
		end
	end
	return pool
end

-- Texto de un bicho guardado: "id" o "id*multiplicador".
function VaultMath.encodeCritter(id: string, multiplier: number): string
	return if multiplier > 1 then id .. "*" .. multiplier else id
end

function VaultMath.decodeCritter(entry: string): (string, number)
	local id, multiplier = string.match(entry, "^([%w_]+)%*(%d+)$")
	if id and multiplier then
		return id, tonumber(multiplier) or 1
	end
	return entry, 1
end

return VaultMath
