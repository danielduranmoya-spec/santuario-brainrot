--!strict
-- Estilo visual (low-poly de colores saturados, ver design/GDD.md): colores, cantidades de
-- decorado e iluminación/atmósfera por zona. Bajar las cantidades si va lento en móvil.

local Art = {}

Art.seed = 2026 -- cambia la semilla para recolocar palmeras, árboles, rocas y nubes

Art.islandRadius = 310
Art.palms = 8
Art.forestTrees = 14
Art.clouds = 10
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

return Art
