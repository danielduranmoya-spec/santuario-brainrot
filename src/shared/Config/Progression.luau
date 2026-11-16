--!strict
-- Zonas y mejoras. Precios en monedas del juego.

local Progression = {}

-- Bóvedas del campo, en orden: para entrar en una hay que haber abierto la anterior y pagar su precio.
-- Las 9 primeras tienen nombre, temática y precio fijos. Qué rarezas salen en cada una está en
-- Config/Critters.VaultChances, y qué bichos, en el campo `vault` de cada bicho.
Progression.Vaults = {
	{ theme = "PlayaRara", name = "Playa Rara", unlockCost = 0 },
	-- Ritmo simulado (jugador medio, ver design/Economia.md): bóveda 2 hacia el minuto 5 y la 3 hacia
	-- el minuto 12, dentro de la primera sesión.
	{ theme = "BosqueRuidoso", name = "Bosque Ruidoso", unlockCost = 1_000 },
	{ theme = "VolcanTimido", name = "Volcán Tímido", unlockCost = 18_000 },
	{ theme = "NubePegajosa", name = "Nube Pegajosa", unlockCost = 300_000 },
	-- Desde aquí cada bóveda cuesta x4 la anterior y sus bichos generan x3 (ver EndlessVaults).
	{ theme = "PantanoCristal", name = "Pantano de Cristal", unlockCost = 1_200_000 },
	{ theme = "RelojeriaAbandonada", name = "Relojería Abandonada", unlockCost = 4_800_000 },
	{ theme = "ValleTitanes", name = "Valle de los Titanes", unlockCost = 19_000_000 },
	{ theme = "ObservatorioAstral", name = "Observatorio Astral", unlockCost = 77_000_000 },
	{ theme = "SantuarioEclipse", name = "Santuario del Eclipse", unlockCost = 310_000_000 },
}

-- Multiplicador de ingresos y bóvedas sin fin a partir de la 10ª (la temática va rotando: Playa
-- Rara II, Bosque Ruidoso II...; las rarezas se quedan con los porcentajes de la bóveda 9).
--   multiplicador(n) = valueGrowth^(n - valueFromVault + 1)  desde la bóveda valueFromVault
--                      (bóveda 5 → x3, bóveda 6 → x9...): los bichos atrapados ahí generan × eso
--   precio(n)        = precio de la 9ª × costGrowth^(n-9)  para las bóvedas sin nombre
Progression.EndlessVaults = {
	costGrowth = 4,
	valueGrowth = 3,
	valueFromVault = 5,
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
