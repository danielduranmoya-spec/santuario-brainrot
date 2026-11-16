--!strict
-- Bichos y rarezas. Única fuente de verdad del balance (ver design/GDD.md).

export type Rarity = "Comun" | "PocoComun" | "Raro" | "Epico" | "Legendario"

export type Critter = {
	id: string,
	name: string,
	rarity: Rarity,
	coinsPerSecond: number,
	zone: string,
	eventOnly: boolean?, -- solo aparece en eventos (Lluvia de Bichos), nunca en las bóvedas normales
}

local Critters = {}

-- Probabilidad relativa de aparición y tamaño de la zona verde del minijuego (0-1).
Critters.Rarities = {
	Comun = { label = "Común", weight = 60, catchWindow = 0.35, color = Color3.fromRGB(200, 200, 200) },
	PocoComun = { label = "Poco común", weight = 25, catchWindow = 0.25, color = Color3.fromRGB(90, 200, 90) },
	Raro = { label = "Raro", weight = 10, catchWindow = 0.18, color = Color3.fromRGB(70, 140, 255) },
	Epico = { label = "Épico", weight = 4, catchWindow = 0.12, color = Color3.fromRGB(170, 80, 255) },
	Legendario = { label = "Legendario", weight = 1, catchWindow = 0.08, color = Color3.fromRGB(255, 190, 40) },
}

Critters.List = {
	{ id = "pez_con_piernas", name = "Pez con Piernas", rarity = "Comun", coinsPerSecond = 1, zone = "PlayaRara" },
	{ id = "cangrejo_timido", name = "Cangrejo Tímido", rarity = "Comun", coinsPerSecond = 2, zone = "PlayaRara" },
	{ id = "tostada_voladora", name = "Tostada Voladora", rarity = "PocoComun", coinsPerSecond = 5, zone = "PlayaRara" },
	{ id = "seta_cantante", name = "Seta Cantante", rarity = "PocoComun", coinsPerSecond = 15, zone = "BosqueRuidoso" },
	{ id = "cactus_estornudo", name = "Cactus Estornudo", rarity = "Raro", coinsPerSecond = 40, zone = "BosqueRuidoso" },
	{ id = "roca_con_bigote", name = "Roca con Bigote", rarity = "Epico", coinsPerSecond = 300, zone = "VolcanTimido" },
	{ id = "nube_grunona", name = "Nube Gruñona", rarity = "Legendario", coinsPerSecond = 2500, zone = "NubePegajosa" },
	-- Exclusivo de la Lluvia de Bichos de los sábados (Config/Events.LluviaDeBichos).
	{ id = "rana_paraguas", name = "Rana con Paraguas", rarity = "Epico", coinsPerSecond = 120, zone = "Evento", eventOnly = true },
} :: { Critter }

return Critters
