--!strict
-- Índice de bichos (client/Bestiary + server/Services/Bestiary): cada bicho que atrapas por primera
-- vez se descubre y deja de verse como una silueta negra. Premios:
--   * al completar una rareza (todos sus bichos de bóveda; los de evento van aparte, en Limitados);
--   * al llegar a un número de capturas en total (cuenta cada captura, repetidos incluidos).
-- Cada premio se da una sola vez (se guarda en el perfil). Los premios de las rarezas altas están
-- pensados para ayudar a abrir la bóveda siguiente a la que hace falta para completarlas, nunca
-- para saltarse varias (precios en Config/Progression).

export type Reward = {
	coins: number?,
	baits: number?,
	luckMinutes: number?, -- minutos de Suerte x2
}

export type Milestone = {
	count: number, -- capturas totales necesarias
	coins: number?,
	baits: number?,
	luckMinutes: number?,
}

local Index = {}

-- Premio por completar cada rareza (y bóveda en la que se puede completar, como referencia).
Index.RarityRewards = {
	Comun = { coins = 500 }, -- bóveda 1 (la 2 cuesta 1.000)
	PocoComun = { coins = 3_000, baits = 1 }, -- bóveda 2
	Raro = { coins = 20_000, baits = 1 }, -- bóveda 3 (la 4 cuesta 300.000)
	Epico = { coins = 100_000, baits = 1, luckMinutes = 5 }, -- bóveda 3
	Legendario = { coins = 1_500_000, baits = 2, luckMinutes = 10 }, -- bóveda 5 (la 6 cuesta 4,8 M)
	Mitico = { coins = 30_000_000, baits = 3, luckMinutes = 15 }, -- bóveda 5-7 (la 8 cuesta 77 M)
	Secreto = { coins = 500_000_000, baits = 5, luckMinutes = 30 }, -- bóveda 8-9
} :: { [string]: Reward }

-- Premios por capturas totales.
Index.Milestones = {
	{ count = 10, coins = 300 },
	{ count = 25, coins = 2_000, baits = 1 },
	{ count = 50, coins = 10_000 },
	{ count = 100, coins = 60_000, baits = 1, luckMinutes = 5 },
	{ count = 250, coins = 600_000, baits = 2 },
	{ count = 500, coins = 6_000_000, luckMinutes = 10 },
	{ count = 1000, coins = 60_000_000, baits = 5, luckMinutes = 15 },
} :: { Milestone }

-- Cómo se ven las siluetas de los bichos sin descubrir.
Index.silhouetteColor = Color3.fromRGB(15, 15, 20)

return Index
