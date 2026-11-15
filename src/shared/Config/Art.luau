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
}
Art.ambienceTweenSeconds = 2

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
	flying = { tostada_voladora = true, nube_grunona = true }, -- se balancean más
}

-- Terreno del mapa (WorldArt). Los radios se miden desde el centro de la Playa.
Art.terrain = {
	islandRadius = 300, -- hierba jugable
	shoreWidth = 24, -- arena entre la hierba y el mar
	islandDepth = 24, -- grosor de la isla bajo el suelo
	seaRadius = 520, -- hasta dónde llega el mar
	seaDepth = 30,
	waterLevel = -2, -- superficie del mar (el suelo de la isla está en 0)
	mountainRadius = 318, -- anillo de montañas en el borde
	mountainCount = 30,
	mountainSize = { min = 26, max = 40 },
	waterColor = Color3.fromRGB(30, 140, 200),
	surfaceOffset = 2, -- el terreno se rellena hasta GroundY - 2 y su superficie visible queda en GroundY
}

-- Límite infranqueable: muro invisible alrededor del mapa jugable (y techo).
Art.boundary = {
	radius = 296, -- por dentro de las montañas
	segments = 48,
	height = 400,
	thickness = 6,
	ceilingHeight = 260,
	-- Si un jugador cae por debajo de esta altura o sale de este radio, vuelve a su santuario.
	respawnBelowY = -8,
	respawnBeyondRadius = 305,
	checkSeconds = 0.5,
}

-- Material del suelo de cada zona (Terrain).
Art.zoneMaterials = {
	PlayaRara = Enum.Material.Sand,
	BosqueRuidoso = Enum.Material.LeafyGrass,
	VolcanTimido = Enum.Material.Basalt,
	NubePegajosa = Enum.Material.Snow,
}

return Art
