--!strict
-- Mutaciones: dos capas independientes que se sortean cuando aparece cada bicho, Color y Tamaño.
-- Sus multiplicadores se multiplican entre sí y con lo que produce el bicho
-- (Radioactivo x6 y Enorme x7 = x42). Ver design/Mutaciones.md.

export type Particles = {
	color: Color3,
	rate: number,
	smoke: boolean?, -- humo que sube en vez de chispas
}

export type ColorDef = {
	id: string,
	label: string, -- se añade al nombre del bicho ("" = nada)
	multiplier: number,
	chance: number, -- % base (la lista suma 100)
	tint: Color3?, -- color con el que se repinta el bicho
	blend: number?, -- cuánto queda del color original de cada pieza (0 = nada, 1 = todo)
	material: Enum.Material?,
	transparency: number?,
	reflectance: number?,
	light: Color3?, -- aura de luz
	particles: Particles?,
	rainbow: boolean?, -- el cliente le va cambiando el color (client/CritterAnimator)
}

export type SizeDef = {
	id: string,
	label: string,
	multiplier: number,
	chance: number, -- % (la lista suma 100)
	scale: number, -- tamaño del modelo en las bóvedas (1 = normal)
	sanctuaryScale: number, -- tamaño en el pedestal (menor, para que no pise a los vecinos)
	catchPenalty: number, -- lo que se resta a la zona verde (0-1)
}

export type MachineDef = {
	id: string,
	title: string,
	from: string, -- tamaño de los bichos que entran
	to: string, -- tamaño del bicho que sale
	count: number, -- cuántos bichos iguales hacen falta
	costSeconds: number, -- cuesta lo que produce el bicho base en estos segundos...
	minCost: number, -- ...con este mínimo de monedas
	color: Color3,
}

export type EventDef = {
	id: string,
	name: string,
	article: string, -- "una Fiebre del Oro", para el aviso de quien la invoca
	boosts: { [string]: number }, -- % de cada color mientras dura (sustituye al % base)
	weight: number, -- peso en el sorteo automático (menos = más raro)
	product: string, -- producto de desarrollador que lo invoca (Config/Shop.DevProducts)
	color: Color3, -- color del aviso y de las partículas del cielo
	tint: Color3, -- tono con el que se tiñe la pantalla
	icon: string,
}

local Mutations = {}

-- De menos a más valioso. El % de "Normal" es lo que sobra hasta 100.
Mutations.Colors = {
	{ id = "Normal", label = "", multiplier = 1, chance = 89.83 },
	{
		id = "Oro",
		label = "Oro",
		multiplier = 2,
		chance = 6,
		tint = Color3.fromRGB(255, 200, 40),
		blend = 0.15,
		material = Enum.Material.Foil,
		reflectance = 0.25,
		particles = { color = Color3.fromRGB(255, 230, 90), rate = 6 },
	},
	{
		id = "Diamante",
		label = "Diamante",
		multiplier = 3,
		chance = 2.5,
		tint = Color3.fromRGB(120, 215, 255),
		blend = 0.1,
		material = Enum.Material.Glass,
		transparency = 0.25,
		reflectance = 0.3,
		particles = { color = Color3.fromRGB(255, 255, 255), rate = 8 },
	},
	{
		id = "Neon",
		label = "Neón",
		multiplier = 4,
		chance = 1,
		tint = Color3.fromRGB(255, 40, 200),
		blend = 0.35,
		material = Enum.Material.Neon,
		light = Color3.fromRGB(255, 60, 210),
		particles = { color = Color3.fromRGB(120, 255, 255), rate = 10 },
	},
	{
		id = "Arcoiris",
		label = "Arcoíris",
		multiplier = 5,
		chance = 0.4,
		tint = Color3.fromRGB(255, 90, 90),
		blend = 0,
		material = Enum.Material.SmoothPlastic,
		rainbow = true,
		particles = { color = Color3.fromRGB(255, 255, 255), rate = 6 },
	},
	{
		id = "Radioactivo",
		label = "Radioactivo",
		multiplier = 6,
		chance = 0.2,
		tint = Color3.fromRGB(110, 255, 40),
		blend = 0.15,
		material = Enum.Material.Neon,
		light = Color3.fromRGB(110, 255, 40),
		particles = { color = Color3.fromRGB(90, 230, 40), rate = 10, smoke = true },
	},
	{
		id = "Espectral",
		label = "Espectral",
		multiplier = 7,
		chance = 0.06,
		tint = Color3.fromRGB(190, 235, 255),
		blend = 0.3,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.5,
		light = Color3.fromRGB(130, 210, 255),
		particles = { color = Color3.fromRGB(150, 220, 255), rate = 8, smoke = true },
	},
	{
		id = "Vacio",
		label = "Vacío",
		multiplier = 8,
		chance = 0.01,
		tint = Color3.fromRGB(4, 0, 10),
		blend = 0,
		material = Enum.Material.Neon, -- Neon en negro se ve negro plano, sin sombras
		light = Color3.fromRGB(90, 30, 160),
		particles = { color = Color3.fromRGB(70, 20, 120), rate = 14, smoke = true },
	},
} :: { ColorDef }

Mutations.Sizes = {
	{ id = "Normal", label = "", multiplier = 1, chance = 96.5, scale = 1, sanctuaryScale = 1, catchPenalty = 0 },
	{ id = "Grande", label = "Grande", multiplier = 3, chance = 3, scale = 1.6, sanctuaryScale = 1.3, catchPenalty = 0.02 },
	{ id = "Enorme", label = "Enorme", multiplier = 7, chance = 0.5, scale = 2.5, sanctuaryScale = 1.6, catchPenalty = 0.04 },
} :: { SizeDef }

-- La zona verde nunca baja de aquí por muy grande que sea el bicho.
Mutations.minCatchWindow = 0.015

-- Pase Red Titánica: probabilidad de que el bicho crezca un tamaño al atraparlo.
Mutations.redTitanicaChance = 0.1

-- Máquinas de fusión (solo cambian el tamaño). Están en la plaza, junto a la entrada de las bóvedas.
-- El color se hereda eligiendo al azar uno de los bichos que entran: si todos son del mismo color
-- se conserva seguro; con 2 Oro y 3 Normales, 40 % de que salga Oro.
Mutations.Machines = {
	{ id = "Agrandadora", title = "Agrandadora", from = "Normal", to = "Grande", count = 5, costSeconds = 300, minCost = 100, color = Color3.fromRGB(90, 200, 255) },
	{ id = "Titanica", title = "Titánica", from = "Grande", to = "Enorme", count = 4, costSeconds = 900, minCost = 1_000, color = Color3.fromRGB(255, 120, 60) },
} :: { MachineDef }

Mutations.MachinePlacement = {
	-- Dónde van: a los lados de la avenida (Config/Island.Machines y Shared/Layout).
	promptDistance = 12,
	requestCooldownSeconds = 0.5,
}

-- Eventos de mutación: cada `intervalSeconds` empieza uno solo (sorteado por peso) y dura
-- `durationSeconds`. Mientras dura, el % de sus colores sube para TODOS los bichos que aparezcan.
-- También se pueden invocar con Robux (Config/Shop); si ya hay uno en marcha, espera su turno.
Mutations.Events = {
	intervalSeconds = 20 * 60,
	durationSeconds = 5 * 60,
	List = {
		{
			id = "FiebreOro",
			name = "Fiebre del Oro",
			article = "una Fiebre del Oro",
			boosts = { Oro = 18 },
			weight = 26,
			product = "InvocarFiebreOro",
			color = Color3.fromRGB(255, 205, 60),
			tint = Color3.fromRGB(255, 232, 170),
			icon = "🟡",
		},
		{
			id = "LluviaCristales",
			name = "Lluvia de Cristales",
			article = "una Lluvia de Cristales",
			boosts = { Diamante = 10 },
			weight = 23,
			product = "InvocarLluviaCristales",
			color = Color3.fromRGB(130, 220, 255),
			tint = Color3.fromRGB(190, 230, 255),
			icon = "💎",
		},
		{
			id = "SobrecargaNeon",
			name = "Sobrecarga Neón",
			article = "una Sobrecarga Neón",
			boosts = { Neon = 5 },
			weight = 20,
			product = "InvocarSobrecargaNeon",
			color = Color3.fromRGB(255, 70, 215),
			tint = Color3.fromRGB(255, 190, 240),
			icon = "⚡",
		},
		{
			id = "AuroraArcoiris",
			name = "Aurora Arcoíris",
			article = "una Aurora Arcoíris",
			boosts = { Arcoiris = 3.2 },
			weight = 15,
			product = "InvocarAuroraArcoiris",
			color = Color3.fromRGB(150, 255, 190),
			tint = Color3.fromRGB(215, 255, 225),
			icon = "🌈",
		},
		{
			id = "FugaRadioactiva",
			name = "Fuga Radioactiva",
			article = "una Fuga Radioactiva",
			boosts = { Radioactivo = 2 },
			weight = 11,
			product = "InvocarFugaRadioactiva",
			color = Color3.fromRGB(120, 255, 50),
			tint = Color3.fromRGB(200, 255, 170),
			icon = "☢",
		},
		{
			id = "GrietaVacio",
			name = "Grieta del Vacío",
			article = "una Grieta del Vacío",
			boosts = { Espectral = 0.9, Vacio = 0.15 },
			weight = 5, -- evento raro
			product = "InvocarGrietaVacio",
			color = Color3.fromRGB(170, 90, 255),
			tint = Color3.fromRGB(175, 150, 215),
			icon = "🕳",
		},
	} :: { EventDef },
}

Mutations.announceColor = Color3.fromRGB(255, 205, 60) -- dorado: aviso global de quien invoca un evento

-- Aviso a todo el servidor cuando aparece un bicho con mutación rara (color x tamaño >= minMultiplier:
-- Arcoíris o mejor, cualquier Enorme, o Grande con Oro o mejor). Sale arriba en pantalla y el bicho
-- lleva una baliza visible desde lejos. Con 5 sale más o menos uno cada 5 minutos (1 % de los bichos).
Mutations.rareAlert = {
	minMultiplier = 5,
	showSeconds = 6, -- tiempo del aviso en pantalla
	beaconMaxDistance = 600, -- studs desde los que se ve la baliza
}

return Mutations
