--!strict
-- Cálculos de las mutaciones (Config/Mutations) y formato con el que se guarda cada bicho.
-- Lo usan el servidor (sorteo, ingresos, fusión) y el cliente (menú de las máquinas).

local Config = script.Parent:WaitForChild("Config")
local Mutations = require(Config:WaitForChild("Mutations"))

export type ColorDef = Mutations.ColorDef
export type SizeDef = Mutations.SizeDef
export type EventDef = Mutations.EventDef
export type MachineDef = Mutations.MachineDef

local MutationMath = {}

local colorById: { [string]: ColorDef } = {}
for _, def in Mutations.Colors do
	colorById[def.id] = def
end
local sizeById: { [string]: SizeDef } = {}
for _, def in Mutations.Sizes do
	sizeById[def.id] = def
end

-- Un id desconocido (datos viejos o manipulados) cuenta como "Normal".
function MutationMath.color(id: string?): ColorDef
	return colorById[id or "Normal"] or colorById.Normal
end

function MutationMath.size(id: string?): SizeDef
	return sizeById[id or "Normal"] or sizeById.Normal
end

function MutationMath.multiplier(color: string?, size: string?): number
	return MutationMath.color(color).multiplier * MutationMath.size(size).multiplier
end

-- "Caracol Turbo Diamante Grande"
function MutationMath.displayName(name: string, color: string?, size: string?): string
	local text = name
	local colorLabel = MutationMath.color(color).label
	local sizeLabel = MutationMath.size(size).label
	if colorLabel ~= "" then
		text ..= " " .. colorLabel
	end
	if sizeLabel ~= "" then
		text ..= " " .. sizeLabel
	end
	return text
end

-- El tamaño siguiente (Normal -> Grande -> Enorme) o nil si ya es el mayor.
function MutationMath.nextSize(size: string?): string?
	local current = MutationMath.size(size)
	for index, def in Mutations.Sizes do
		if def == current then
			local nextDef = Mutations.Sizes[index + 1]
			return if nextDef then nextDef.id else nil
		end
	end
	return nil
end

-- % de cada color. Con un evento, sus colores usan el % del evento y "Normal" se queda el resto.
function MutationMath.colorChances(boosts: { [string]: number }?): { { def: ColorDef, chance: number } }
	local result = {}
	local others = 0
	for _, def in Mutations.Colors do
		if def.id ~= "Normal" then
			local chance = if boosts and boosts[def.id] then boosts[def.id] else def.chance
			others += chance
			table.insert(result, { def = def, chance = chance })
		end
	end
	table.insert(result, 1, { def = colorById.Normal, chance = math.max(0, 100 - others) })
	return result
end

-- Sortea un color. `roll` es un número al azar entre 0 y 1. Se recorre de más raro a más común.
function MutationMath.rollColor(roll: number, boosts: { [string]: number }?): string
	local list = MutationMath.colorChances(boosts)
	local left = roll * 100
	for index = #list, 2, -1 do
		left -= list[index].chance
		if left < 0 then
			return list[index].def.id
		end
	end
	return "Normal"
end

function MutationMath.rollSize(roll: number): string
	local left = roll * 100
	for index = #Mutations.Sizes, 2, -1 do
		left -= Mutations.Sizes[index].chance
		if left < 0 then
			return Mutations.Sizes[index].id
		end
	end
	return "Normal"
end

-- Zona verde después de restar la penalización por tamaño.
function MutationMath.catchWindow(window: number, size: string?): number
	local penalty = MutationMath.size(size).catchPenalty
	if penalty <= 0 then
		return window
	end
	return math.max(Mutations.minCatchWindow, window - penalty)
end

-- Texto de un bicho guardado: "id", "id*multiplicador" y, si tiene mutación, ":Color:Tamaño"
-- al final ("caracol_turbo:Oro:Grande", "garza_prisma*3:Normal:Enorme").
function MutationMath.encode(id: string, multiplier: number, color: string?, size: string?): string
	local text = if multiplier > 1 then id .. "*" .. multiplier else id
	local colorId = MutationMath.color(color).id
	local sizeId = MutationMath.size(size).id
	if colorId ~= "Normal" or sizeId ~= "Normal" then
		text ..= ":" .. colorId .. ":" .. sizeId
	end
	return text
end

-- Devuelve id, multiplicador de bóveda, color y tamaño. Las partidas antiguas ("id" o "id*3")
-- se leen como bichos sin mutación.
function MutationMath.decode(entry: string): (string, number, string, string)
	local base, color, size = string.match(entry, "^([^:]+):(%w+):(%w+)$")
	local text = base or entry
	local id, multiplier = string.match(text, "^([%w_]+)%*(%d+)$")
	return id or text, tonumber(multiplier) or 1, MutationMath.color(color).id, MutationMath.size(size).id
end

function MutationMath.machine(id: string): MachineDef?
	for _, def in Mutations.Machines do
		if def.id == id then
			return def
		end
	end
	return nil
end

-- Monedas que cuesta usar una máquina: lo que produce en `costSeconds` uno de los bichos que entran
-- (base x multiplicador de bóveda x tamaño de entrada; el color no cuenta, es pura suerte).
-- Antes no contaba la bóveda y en las bóvedas lejanas (x243) fusionar salía casi gratis.
function MutationMath.fusionCost(machine: MachineDef, coinsPerSecond: number, vaultMultiplier: number?): number
	local income = coinsPerSecond * (vaultMultiplier or 1) * MutationMath.size(machine.from).multiplier
	return math.max(machine.minCost, math.floor(income * machine.costSeconds))
end

function MutationMath.event(id: string): EventDef?
	for _, def in Mutations.Events.List do
		if def.id == id then
			return def
		end
	end
	return nil
end

function MutationMath.eventByProduct(product: string): EventDef?
	for _, def in Mutations.Events.List do
		if def.product == product then
			return def
		end
	end
	return nil
end

-- Sortea un evento por peso. `roll` entre 0 y 1.
function MutationMath.rollEvent(roll: number): EventDef
	local total = 0
	for _, def in Mutations.Events.List do
		total += def.weight
	end
	local left = roll * total
	for _, def in Mutations.Events.List do
		left -= def.weight
		if left < 0 then
			return def
		end
	end
	return Mutations.Events.List[1]
end

return MutationMath
