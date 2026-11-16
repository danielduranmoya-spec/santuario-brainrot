--!strict
-- Zonas y mejoras. Precios en monedas del juego.

local Progression = {}

-- Bóvedas del campo, en orden: para entrar en una hay que haber abierto la anterior y pagar su precio.
-- Las 4 primeras tienen nombre, temática y precio fijos; en cada una salen los bichos de su temática.
Progression.Vaults = {
	{ theme = "PlayaRara", name = "Playa Rara", unlockCost = 0 },
	-- Ritmo simulado (jugador medio, ver design/Economia.md): bóveda 2 hacia el minuto 5 y la 3 hacia
	-- el minuto 12, dentro de la primera sesión. Antes eran 2.500 / 40.000 / 600.000 (minutos 11 y 35).
	{ theme = "BosqueRuidoso", name = "Bosque Ruidoso", unlockCost = 1_000 },
	{ theme = "VolcanTimido", name = "Volcán Tímido", unlockCost = 18_000 },
	{ theme = "NubePegajosa", name = "Nube Pegajosa", unlockCost = 300_000 },
}

-- A partir de la 5ª, las bóvedas se generan solas sin fin: la temática va rotando (Playa Rara II,
-- Bosque Ruidoso II...), aparecen bichos de todas las temáticas, cada vez más raros y más valiosos.
--   precio(n)        = precio de la 4ª × costGrowth^(n-4)
--   multiplicador(n) = valueGrowth^(n-4)  (los bichos de esa bóveda generan × eso)
--   suerte(n)        = 1 + luckPerVault × (n-4)  (más peso para las rarezas no comunes)
Progression.EndlessVaults = {
	costGrowth = 4,
	valueGrowth = 3,
	luckPerVault = 0.6,
	maxVaults = 60, -- tope de seguridad (en la práctica, sin fin)
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
