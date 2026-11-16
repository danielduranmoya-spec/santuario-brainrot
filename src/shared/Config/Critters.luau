--!strict
-- Bichos y rarezas. Única fuente de verdad del balance (ver design/GDD.md y design/Rarezas.md).
--
-- Cómo se elige el bicho que aparece en una bóveda:
--   1. Se sortea la RAREZA con los porcentajes de esa bóveda (Critters.VaultChances).
--   2. Dentro de la rareza, se reparte a partes iguales entre los bichos que ya salen en esa
--      bóveda (los que tienen `vault` menor o igual). Los de bóvedas anteriores siguen activos.

export type Rarity = "Comun" | "PocoComun" | "Raro" | "Epico" | "Legendario" | "Mitico" | "Secreto"

export type Critter = {
	id: string,
	name: string,
	rarity: Rarity,
	coinsPerSecond: number, -- monedas por segundo base (a partir de la bóveda 5 se multiplica, ver Progression)
	zone: string, -- temática de su zona de origen (o "Evento")
	vault: number, -- primera bóveda en la que aparece
	eventOnly: boolean?, -- solo aparece en eventos (Lluvia de Bichos), nunca en las bóvedas normales
}

export type RarityInfo = {
	label: string,
	catchWindow: number, -- tamaño de la zona verde del minijuego (0-1)
	color: Color3,
}

local Critters = {}

-- De menos a más rara.
Critters.RarityOrder = { "Comun", "PocoComun", "Raro", "Epico", "Legendario", "Mitico", "Secreto" } :: { Rarity }

-- La velocidad de cada rareza está en Config/Gameplay.RarityMotion.
Critters.Rarities = {
	Comun = { label = "Común", catchWindow = 0.35, color = Color3.fromRGB(200, 200, 200) },
	PocoComun = { label = "Poco común", catchWindow = 0.25, color = Color3.fromRGB(90, 200, 90) },
	Raro = { label = "Raro", catchWindow = 0.18, color = Color3.fromRGB(70, 140, 255) },
	Epico = { label = "Épico", catchWindow = 0.12, color = Color3.fromRGB(170, 80, 255) },
	Legendario = { label = "Legendario", catchWindow = 0.08, color = Color3.fromRGB(255, 190, 40) },
	Mitico = { label = "Mítico", catchWindow = 0.05, color = Color3.fromRGB(255, 70, 110) }, -- exige mejorar la Red
	Secreto = { label = "Secreto", catchWindow = 0.03, color = Color3.fromRGB(60, 235, 225) }, -- el trofeo de la v1.0
} :: { [string]: RarityInfo }

-- Porcentaje de cada rareza en cada bóveda (cada fila suma 100). El Común pierde 7 puntos por
-- bóveda de la 1 a la 5 y 12 por bóveda de la 5 a la 9, donde se extingue. Cada bóveda nueva abre
-- una sola rareza nueva. Las bóvedas posteriores a la última fila usan la última fila.
Critters.VaultChances = {
	{ Comun = 76, PocoComun = 24 }, -- 1 · Playa Rara
	{ Comun = 69, PocoComun = 26, Raro = 5 }, -- 2 · Bosque Ruidoso
	{ Comun = 62, PocoComun = 28, Raro = 8.5, Epico = 1.5 }, -- 3 · Volcán Tímido
	{ Comun = 55, PocoComun = 30, Raro = 11, Epico = 3.5, Legendario = 0.5 }, -- 4 · Nube Pegajosa
	{ Comun = 48, PocoComun = 32, Raro = 13, Epico = 5, Legendario = 1.3, Mitico = 0.7 }, -- 5 · Pantano de Cristal
	{ Comun = 36, PocoComun = 35.4, Raro = 16.1, Epico = 7.4, Legendario = 3, Mitico = 2.1 }, -- 6 · Relojería Abandonada
	{ Comun = 24, PocoComun = 38.4, Raro = 18.9, Epico = 9.8, Legendario = 5.1, Mitico = 3.8 }, -- 7 · Valle de los Titanes
	{ Comun = 12, PocoComun = 41, Raro = 21.5, Epico = 12.2, Legendario = 7.3, Mitico = 5.8, Secreto = 0.2 }, -- 8 · Observatorio Astral
	{ PocoComun = 43.5, Raro = 24, Epico = 14.5, Legendario = 9.5, Mitico = 8, Secreto = 0.5 }, -- 9 · Santuario del Eclipse
} :: { { [string]: number } }

-- 21 bichos, 3 por rareza. Los tres Míticos se abren juntos en la bóveda 5 y los tres Secretos en
-- la 8 (así lo pide el diseño), aunque cada uno tenga su zona de origen.
Critters.List = {
	-- Común
	{ id = "caracol_turbo", name = "Caracol Turbo", rarity = "Comun", coinsPerSecond = 1, zone = "PlayaRara", vault = 1 },
	{ id = "estrella_ninja", name = "Estrella Ninja", rarity = "Comun", coinsPerSecond = 2, zone = "PlayaRara", vault = 1 },
	{ id = "pulpo_cubo", name = "Pulpo Cubo", rarity = "Comun", coinsPerSecond = 3, zone = "PlayaRara", vault = 1 },
	-- Poco común
	{ id = "gaviota_pirata", name = "Gaviota Pirata", rarity = "PocoComun", coinsPerSecond = 5, zone = "PlayaRara", vault = 1 },
	{ id = "erizo_tambor", name = "Erizo Tambor", rarity = "PocoComun", coinsPerSecond = 15, zone = "BosqueRuidoso", vault = 2 },
	{ id = "camaleon_neon", name = "Camaleón Neón", rarity = "PocoComun", coinsPerSecond = 22, zone = "BosqueRuidoso", vault = 2 },
	-- Raro
	{ id = "buho_despertador", name = "Búho Despertador", rarity = "Raro", coinsPerSecond = 40, zone = "BosqueRuidoso", vault = 2 },
	{ id = "planta_beatbox", name = "Planta Beatbox", rarity = "Raro", coinsPerSecond = 65, zone = "BosqueRuidoso", vault = 2 },
	{ id = "salamandra_chispa", name = "Salamandra Chispa", rarity = "Raro", coinsPerSecond = 95, zone = "VolcanTimido", vault = 3 },
	-- Épico
	{ id = "golem_obsidiana", name = "Gólem de Obsidiana", rarity = "Epico", coinsPerSecond = 300, zone = "VolcanTimido", vault = 3 },
	{ id = "murcielago_magma", name = "Murciélago de Magma", rarity = "Epico", coinsPerSecond = 450, zone = "VolcanTimido", vault = 3 },
	-- Exclusivo de la Lluvia de Bichos de los sábados (Config/Events.LluviaDeBichos).
	{ id = "ajolote_chubasquero", name = "Ajolote Chubasquero", rarity = "Epico", coinsPerSecond = 120, zone = "Evento", vault = 1, eventOnly = true },
	-- Legendario (el Lobo de Tormenta es también el evento de servidor de cada 8 minutos)
	{ id = "lobo_tormenta", name = "Lobo de Tormenta", rarity = "Legendario", coinsPerSecond = 2500, zone = "NubePegajosa", vault = 4 },
	{ id = "dragon_algodon", name = "Dragón de Algodón", rarity = "Legendario", coinsPerSecond = 3200, zone = "NubePegajosa", vault = 4 },
	{ id = "garza_prisma", name = "Garza de Prisma", rarity = "Legendario", coinsPerSecond = 4500, zone = "PantanoCristal", vault = 5 },
	-- Mítico
	{ id = "leviatan_espejo", name = "Leviatán de Espejo", rarity = "Mitico", coinsPerSecond = 15000, zone = "PantanoCristal", vault = 5 },
	{ id = "buho_cuerda", name = "Búho de Cuerda", rarity = "Mitico", coinsPerSecond = 22000, zone = "RelojeriaAbandonada", vault = 5 },
	{ id = "coloso_bronce", name = "Coloso de Bronce", rarity = "Mitico", coinsPerSecond = 32000, zone = "ValleTitanes", vault = 5 },
	-- Secreto
	{ id = "sombra_pendulo", name = "Sombra de Péndulo", rarity = "Secreto", coinsPerSecond = 100000, zone = "ObservatorioAstral", vault = 8 },
	{ id = "zorro_tinta", name = "Zorro de Tinta", rarity = "Secreto", coinsPerSecond = 160000, zone = "ObservatorioAstral", vault = 8 },
	{ id = "caballero_eclipse", name = "Caballero del Eclipse", rarity = "Secreto", coinsPerSecond = 250000, zone = "SantuarioEclipse", vault = 8 },
} :: { Critter }

-- Bichos del catálogo anterior que aún puede haber en partidas guardadas: se cambian por uno
-- nuevo de la misma rareza para que nadie pierda lo que ya tenía (lo aplica server/Data).
Critters.Replaced = {
	pez_con_piernas = "caracol_turbo",
	cangrejo_timido = "estrella_ninja",
	tostada_voladora = "gaviota_pirata",
	seta_cantante = "erizo_tambor",
	cactus_estornudo = "buho_despertador",
	roca_con_bigote = "golem_obsidiana",
	nube_grunona = "lobo_tormenta",
	rana_paraguas = "ajolote_chubasquero",
} :: { [string]: string }

return Critters
