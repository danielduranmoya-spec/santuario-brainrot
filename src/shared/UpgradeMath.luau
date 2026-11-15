--!strict
-- Cálculos de las mejoras a partir de Config/Progression. Los usan el servidor (para aplicar
-- y cobrar) y el cliente (para enseñar precios y efectos), así siempre coinciden.

local Config = script.Parent:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Shop = require(Config:WaitForChild("Shop"))

local Upgrades = Progression.Upgrades

local UpgradeMath = {}

-- Coste de subir al nivel `nextLevel` (1 = primera compra).
function UpgradeMath.cost(name: string, nextLevel: number): number
	local def = Upgrades[name]
	return math.floor(def.baseCost * def.growth ^ (nextLevel - 1) + 0.5)
end

function UpgradeMath.catchWindow(baseWindow: number, redLevel: number): number
	return math.min(baseWindow + redLevel * Upgrades.Red.bonusPerLevel, Gameplay.MaxCatchWindow)
end

function UpgradeMath.walkSpeed(level: number): number
	return Gameplay.BaseWalkSpeed + level * Upgrades.Botas.bonusPerLevel
end

function UpgradeMath.slotCount(level: number, isVip: boolean): number
	return Progression.StartingSlots + level * Upgrades.Santuario.bonusPerLevel + (if isVip then Shop.Perks.vipExtraSlots else 0)
end

function UpgradeMath.collectRadius(level: number): number
	return Gameplay.Sanctuary.collectRadius + level * Upgrades.Iman.bonusPerLevel
end

-- Texto corto con el efecto de una mejora en un nivel (para el menú).
function UpgradeMath.effectText(name: string, level: number): string
	if name == "Red" then
		return "+" .. math.floor(level * Upgrades.Red.bonusPerLevel * 100 + 0.5) .. "% zona verde"
	elseif name == "Botas" then
		return "velocidad " .. UpgradeMath.walkSpeed(level)
	elseif name == "Santuario" then
		return UpgradeMath.slotCount(level, false) .. " huecos"
	elseif name == "Iman" then
		return "cobro a " .. UpgradeMath.collectRadius(level) .. " studs"
	end
	return ""
end

return UpgradeMath
