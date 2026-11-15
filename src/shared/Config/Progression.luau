--!strict
-- Zonas y mejoras. Precios en monedas del juego.

local Progression = {}

-- En este orden: cada zona necesita la anterior desbloqueada.
Progression.Zones = {
	{ id = "PlayaRara", name = "Playa Rara", unlockCost = 0 },
	{ id = "BosqueRuidoso", name = "Bosque Ruidoso", unlockCost = 2_500 },
	{ id = "VolcanTimido", name = "Volcán Tímido", unlockCost = 40_000 },
	{ id = "NubePegajosa", name = "Nube Pegajosa", unlockCost = 600_000 },
}

-- Cada mejora: coste del nivel n = baseCost * growth^(n-1)
Progression.Upgrades = {
	Red = { title = "Red", description = "Zona verde más grande", maxLevel = 10, baseCost = 50, growth = 1.8, bonusPerLevel = 0.02 },
	Botas = { title = "Botas", description = "Corres más rápido", maxLevel = 10, baseCost = 40, growth = 1.7, bonusPerLevel = 1 },
	Santuario = { title = "Santuario", description = "Más huecos para bichos", maxLevel = 12, baseCost = 100, growth = 2.0, bonusPerLevel = 1 },
	Iman = { title = "Imán", description = "Cobras el cofre desde más lejos", maxLevel = 5, baseCost = 500, growth = 2.5, bonusPerLevel = 4 },
}

-- Orden en el menú de MEJORAS.
Progression.UpgradeOrder = { "Botas", "Red", "Santuario", "Iman" }

Progression.StartingSlots = 3
Progression.SaveIntervalSeconds = 120

return Progression
