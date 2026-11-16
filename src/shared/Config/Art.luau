--!strict
-- Estilo visual (low-poly de colores saturados, ver design/GDD.md): colores, cantidades de
-- decorado e iluminación/atmósfera por zona. Bajar las cantidades si va lento en móvil.

local Art = {}

Art.seed = 2026 -- cambia la semilla para recolocar palmeras, árboles, rocas y nubes

Art.palms = 10
Art.forestTrees = 16
Art.clouds = 10
Art.islandTrees = 40 -- árboles sueltos por la isla (fuera de zonas)
Art.islandBushes = 50 -- arbustos y flores sueltos
Art.volcanoSmokeRate = 3
Art.pathWidth = 8
Art.lampSpacing = 24

Art.colors = {
	sea = Color3.fromRGB(40, 150, 220),
	grass = Color3.fromRGB(110, 190, 80),
	path = Color3.fromRGB(235, 205, 140),
	plotGrass = Color3.fromRGB(130, 200, 90),
	fence = Color3.fromRGB(160, 110, 60),
	chest = Color3.fromRGB(150, 90, 40),
	gold = Color3.fromRGB(255, 200, 40),
}

Art.lighting = {
	clockTime = 14.5,
	brightness = 2.5,
	ambient = Color3.fromRGB(110, 110, 120),
	outdoorAmbient = Color3.fromRGB(150, 150, 160),
	saturation = 0.2,
	contrast = 0.05,
}

-- Atmósfera de cada zona (el cliente la cambia suavemente al entrar en cada una).
Art.ambience = {
	PlayaRara = { color = Color3.fromRGB(200, 225, 255), density = 0.25, decay = Color3.fromRGB(140, 180, 220), haze = 1, tint = Color3.fromRGB(255, 255, 255) },
	BosqueRuidoso = { color = Color3.fromRGB(170, 220, 170), density = 0.35, decay = Color3.fromRGB(90, 140, 90), haze = 1.5, tint = Color3.fromRGB(235, 255, 235) },
	VolcanTimido = { color = Color3.fromRGB(255, 170, 130), density = 0.4, decay = Color3.fromRGB(160, 70, 50), haze = 2, tint = Color3.fromRGB(255, 225, 205) },
	NubePegajosa = { color = Color3.fromRGB(255, 225, 250), density = 0.3, decay = Color3.fromRGB(220, 190, 240), haze = 1.5, tint = Color3.fromRGB(250, 240, 255) },
	PantanoCristal = { color = Color3.fromRGB(150, 225, 215), density = 0.4, decay = Color3.fromRGB(60, 130, 130), haze = 2, tint = Color3.fromRGB(225, 255, 250) },
	RelojeriaAbandonada = { color = Color3.fromRGB(230, 200, 150), density = 0.38, decay = Color3.fromRGB(140, 105, 70), haze = 2, tint = Color3.fromRGB(255, 240, 215) },
	ValleTitanes = { color = Color3.fromRGB(190, 210, 190), density = 0.35, decay = Color3.fromRGB(100, 120, 105), haze = 1.5, tint = Color3.fromRGB(240, 250, 240) },
	ObservatorioAstral = { color = Color3.fromRGB(120, 130, 220), density = 0.4, decay = Color3.fromRGB(50, 50, 120), haze = 1.5, tint = Color3.fromRGB(220, 225, 255) },
	SantuarioEclipse = { color = Color3.fromRGB(90, 85, 120), density = 0.45, decay = Color3.fromRGB(30, 25, 50), haze = 2.5, tint = Color3.fromRGB(215, 215, 240) },
}
Art.ambienceTweenSeconds = 2

-- Detalle de los modelos de los bichos (server/CritterArt): 2 = completo; 1 = sin los adornos
-- pequeños (cada bicho tiene entonces en torno a un tercio menos de piezas). Bájalo a 1 si el juego
-- va lento en móviles modestos.
Art.critterDetail = 2

-- Animaciones de los bichos (client/CritterAnimator).
Art.animation = {
	fps = 30, -- fotogramas por segundo de la animación (menos = más ligero en móvil)
	maxDistance = 70, -- solo se animan los bichos a esta distancia de la cámara
	speed = 3,
	bobHeight = 0.04, -- balanceo, en proporción al tamaño del bicho
	blinkEverySeconds = 4,
	blinkSeconds = 0.12,
	wingSpeed = 4,
	wingDegrees = 25,
	wagDegrees = 15,
	dropSpeed = 0.8,
	-- Los que flotan o vuelan se balancean más.
	flying = {
		gaviota_pirata = true,
		murcielago_magma = true,
		dragon_algodon = true,
		sombra_pendulo = true,
		caballero_eclipse = true,
	} :: { [string]: boolean },
	-- Los que ruedan al moverse: eje sobre el que giran ("Z" = voltereta lateral, "X" = rueda hacia delante).
	rolling = { estrella_ninja = "Z", erizo_tambor = "X" } :: { [string]: string },
	spinSpeed = 2.5, -- piezas "Giro" (hélices, engranajes, llaves de cuerda): vueltas por segundo aprox.
	pulseSpeed = 1.2, -- piezas "Brillo" (grietas de lava, núcleos): latido de la luz
	pulseDepth = 0.45, -- cuánto se apagan en cada latido (0 = nada)
	hueSeconds = 1, -- piezas "Arcoiris": cada cuánto cambian de color
	headTurnSeconds = 6, -- piezas "Cabeza": una vuelta completa cada este tiempo
	swingDegrees = 22, -- piezas "Pendulo"
}

-- Terreno del campo (WorldArt).
Art.terrain = {
	depth = 24, -- grosor del suelo bajo la superficie
	sideHillOffset = 22, -- colinas a cada lado, por fuera de los muros
	hillSpacing = 22,
	hillSize = { min = 18, max = 28 },
	surfaceOffset = 2, -- el terreno se rellena hasta GroundY - 2 y su superficie visible queda en GroundY
	-- Altura de la hierba animada (0,1 = muy corta, 1 = alta). Bajada a petición del usuario.
	grassLength = 0.25,
	waterColor = Color3.fromRGB(30, 140, 200),
}

-- Límite infranqueable: muros invisibles alrededor del campo (y techo).
Art.boundary = {
	height = 400,
	thickness = 6,
	segmentLength = 500, -- largo de cada tramo de muro lateral
	ceilingHeight = 120, -- techo invisible sobre el suelo
	-- Si un jugador cae por debajo del suelo o sale del campo, vuelve a su santuario.
	respawnBelowY = -10,
	respawnMargin = 6,
	checkSeconds = 0.5,
}

-- Color de cada temática (puertas, dinteles).
Art.themeColors = {
	PlayaRara = Color3.fromRGB(255, 190, 80),
	BosqueRuidoso = Color3.fromRGB(70, 170, 80),
	VolcanTimido = Color3.fromRGB(230, 90, 50),
	NubePegajosa = Color3.fromRGB(190, 160, 255),
	PantanoCristal = Color3.fromRGB(60, 200, 190),
	RelojeriaAbandonada = Color3.fromRGB(200, 150, 70),
	ValleTitanes = Color3.fromRGB(120, 150, 120),
	ObservatorioAstral = Color3.fromRGB(80, 90, 220),
	SantuarioEclipse = Color3.fromRGB(70, 60, 100),
}

-- Plaza de los santuarios.
Art.hub = {
	avenueWidth = 18,
	trees = 10,
	flowers = 24,
}

-- Decorado por bóveda (por temática). Pocas piezas: van muchas bóvedas seguidas.
Art.vaultDecor = {
	palms = 5,
	umbrellas = 1,
	trees = 7,
	bushes = 3,
	mushrooms = 2,
	lavaRocks = 5,
	clouds = 4,
	crystals = 3,
	rocks = 4,
	ponds = 4, -- Pantano de Cristal
	reeds = 6,
	gears = 5, -- Relojería Abandonada
	pendulums = 2,
	titanPieces = 3, -- Valle de los Titanes
	pillars = 5,
	starOrbs = 8, -- Observatorio Astral
	obelisks = 6, -- Santuario del Eclipse
}

-- Noche (el cliente tiñe la pantalla; el servidor oscurece el cielo).
Art.night = {
	tint = Color3.fromRGB(150, 170, 255),
	brightness = 0.6,
	ambient = Color3.fromRGB(60, 70, 110),
}

-- Material del suelo de cada zona (Terrain).
Art.zoneMaterials = {
	PlayaRara = Enum.Material.Sand,
	BosqueRuidoso = Enum.Material.LeafyGrass,
	VolcanTimido = Enum.Material.Basalt,
	NubePegajosa = Enum.Material.Snow,
	PantanoCristal = Enum.Material.Mud,
	RelojeriaAbandonada = Enum.Material.Brick,
	ValleTitanes = Enum.Material.Limestone,
	ObservatorioAstral = Enum.Material.Slate,
	SantuarioEclipse = Enum.Material.Asphalt,
}

return Art
