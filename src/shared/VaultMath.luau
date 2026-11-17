--!strict
-- Cálculos de las zonas o bóvedas (posición en la isla, nombre, temática, precio, valor y suerte).
-- Los usan el servidor y el cliente, así los dos ven lo mismo. Bóveda 1 = la primera tras la plaza.

local Config = script.Parent:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local CrittersConfig = require(Config:WaitForChild("Critters"))

local Island = require(Config:WaitForChild("Island"))
local NAMED = Progression.Vaults
local ENDLESS = Progression.EndlessVaults
local ROMAN = { "", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX", " X", " XI", " XII", " XIII", " XIV", " XV" }

local VaultMath = {}

VaultMath.MaxVaults = ENDLESS.maxVaults

-- Trazado de la isla (Config/Island): las zonas 1-7 forman un anillo alrededor de la plaza y de la 8
-- en adelante son islas flotantes en espiral sobre el mar. Cada zona es un rectángulo con su propio
-- giro: su -Z local apunta en el sentido del camino y su X local hacia fuera de la isla.
local Z = Island.Zones
local HUB = Island.Hub

local frames: { [number]: CFrame } = {}
local sizes: { [number]: Vector2 } = {}

local function ringAngle(n: number): number
	if n <= 7 then
		return math.rad(HUB.avenueAngle + (n - 1) * Z.ringStep)
	end
	return math.rad(Z.spiralStartAngle + (n - 8) * Z.spiralStep)
end

for n = 1, ENDLESS.maxVaults do
	local angle = ringAngle(n)
	local radius, lift, size
	if n <= 7 then
		radius, lift, size = Z.ringRadius, Z.floatingLift[n] or 0, Vector2.new(Z.width, Z.length)
	else
		radius = Z.spiralRadius
		lift = Z.spiralBaseLift + (n - 8) * Z.spiralLiftPerZone
		size = Vector2.new(Z.spiralWidth, Z.spiralLength)
	end
	local center = Vector3.new(math.cos(angle) * radius, Gameplay.GroundY + lift, math.sin(angle) * radius)
	local forward = Vector3.new(-math.sin(angle), 0, math.cos(angle)) -- tangente: sentido del camino
	frames[n] = CFrame.lookAt(center, center + forward)
	sizes[n] = size
end

-- CFrame del centro de la zona n, a la altura de su suelo.
function VaultMath.frame(n: number): CFrame
	return frames[math.clamp(n, 1, ENDLESS.maxVaults)]
end

-- Ancho (X local) y largo (Z local) de la zona n.
function VaultMath.size(n: number): Vector2
	return sizes[math.clamp(n, 1, ENDLESS.maxVaults)]
end

function VaultMath.center(n: number): Vector3
	return VaultMath.frame(n).Position
end

function VaultMath.floorY(n: number): number
	return VaultMath.frame(n).Position.Y
end

-- La zona n flota (isla en el aire) en vez de estar sobre el suelo de la isla.
function VaultMath.isFloating(n: number): boolean
	return n >= 8 or Z.floatingLift[n] ~= nil
end

-- Arco de entrada de la zona n (su -Z local apunta hacia la zona):
--   * 1: la salida de la avenida en el seto de la plaza;
--   * 2-7: en la cresta de roca que separa su sector del anterior, donde pasa el camino;
--   * 8: al principio del puente que sale de la costa de la zona 7 hacia la primera isla flotante;
--   * 9 en adelante: al final de la isla anterior, donde empieza el puente a la siguiente.
function VaultMath.gate(n: number): CFrame
	local G = Gameplay.GroundY
	if n == 1 then
		local a = math.rad(HUB.avenueAngle)
		local p = Vector3.new(math.cos(a) * HUB.wallRadius, G, math.sin(a) * HUB.wallRadius)
		return CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a)))
	elseif n <= 7 then
		local a = math.rad(HUB.avenueAngle + (n - 1.5) * Z.ringStep)
		local p = Vector3.new(math.cos(a) * Z.ringRadius, G, math.sin(a) * Z.ringRadius)
		return CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
	elseif n == 8 then
		local a = math.rad(Z.bridgeAngle)
		local p = Vector3.new(math.cos(a) * Z.bridgeRadius, G, math.sin(a) * Z.bridgeRadius)
		local target = VaultMath.entry(8)
		return CFrame.lookAt(p, Vector3.new(target.X, G, target.Z))
	end
	local from = VaultMath.exit(n - 1)
	local target = VaultMath.entry(n)
	return CFrame.lookAt(from.Position, Vector3.new(target.X, from.Position.Y, target.Z))
end

-- Borde de entrada de la zona n (donde llega el camino o el puente).
function VaultMath.entry(n: number): Vector3
	return (VaultMath.frame(n) * CFrame.new(0, 0, VaultMath.size(n).Y / 2)).Position
end

-- Salida de la zona n (borde del final del camino), mirando hacia fuera.
function VaultMath.exit(n: number): CFrame
	return VaultMath.frame(n) * CFrame.new(0, 0, -VaultMath.size(n).Y / 2)
end

-- Punto de la zona n a partir de coordenadas relativas (u, v entre -0,5 y 0,5: ancho y largo).
function VaultMath.point(n: number, u: number, v: number): Vector3
	local size = VaultMath.size(n)
	return VaultMath.frame(n) * Vector3.new(u * size.X, 0, v * size.Y)
end

-- Mantiene un punto dentro de la zona n, a `margin` studs de los bordes.
function VaultMath.clamp(n: number, point: Vector3, margin: number): Vector3
	local cf = VaultMath.frame(n)
	local size = VaultMath.size(n)
	local p = cf:PointToObjectSpace(point)
	local hx, hz = math.max(0, size.X / 2 - margin), math.max(0, size.Y / 2 - margin)
	return cf * Vector3.new(math.clamp(p.X, -hx, hx), p.Y, math.clamp(p.Z, -hz, hz))
end

-- Zona en la que está una posición (nil si está en la plaza, en un puente o fuera de la isla).
-- Las zonas 1-7 son sectores del anillo entre el seto de la plaza y la costa; las flotantes (la 4 y
-- de la 8 en adelante) cuentan también su isla en el aire.
local SECTOR_START = HUB.avenueAngle - Z.ringStep / 2
function VaultMath.vaultAt(position: Vector3): number?
	local G = Gameplay.GroundY
	for n = 4, ENDLESS.maxVaults do
		if n == 4 or n >= 8 then
			local cf = frames[n]
			local size = sizes[n]
			local p = cf:PointToObjectSpace(position)
			if math.abs(p.X) <= size.X / 2 + 6 and math.abs(p.Z) <= size.Y / 2 + 6 and p.Y > -12 and p.Y < 60 then
				return n
			end
		end
	end
	local r = Vector2.new(position.X, position.Z).Magnitude
	if r < HUB.wallRadius or r > Island.Coast.radius + Island.Coast.wobble + 20 or position.Y > G + 50 then
		return nil
	end
	local angle = math.deg(math.atan2(position.Z, position.X))
	return math.floor(((angle - SECTOR_START) % 360) / Z.ringStep) + 1
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
