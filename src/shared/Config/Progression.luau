--!strict
-- Zonas y mejoras. Precios en monedas del juego.

local Progression = {}

Progression.Zones = {
	{ id = "PlayaRara", name = "Playa Rara", unlockCost = 0 },
	{ id = "BosqueRuidoso", name = "Bosque Ruidoso", unlockCost = 2_500 },
	{ id = "VolcanTimido", name = "Volcán Tímido", unlockCost = 40_000 },
	{ id = "NubePegajosa", name = "Nube Pegajosa", unlockCost = 600_000 },
}

-- Cada mejora: coste del nivel n = baseCost * growth^(n-1)
Progression.Upgrades = {
	Red = { maxLevel = 10, baseCost = 50, growth = 1.8, bonusPerLevel = 0.02 }, -- +zona verde
	Botas = { maxLevel = 10, baseCost = 40, growth = 1.7, bonusPerLevel = 1 }, -- +WalkSpeed
	Santuario = { maxLevel = 12, baseCost = 100, growth = 2.0, bonusPerLevel = 1 }, -- +huecos
	Iman = { maxLevel = 5, baseCost = 500, growth = 2.5, bonusPerLevel = 4 }, -- +studs de recogida
}

Progression.StartingSlots = 3
Progression.SaveIntervalSeconds = 120

return Progression
