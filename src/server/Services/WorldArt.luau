--!strict
-- Escenario del campo, generado por código:
--   * Plaza de los santuarios (al principio del campo): hierba, avenida de piedra, fuente, árboles,
--     flores y farolas.
--   * Cada bóveda (BuildVault, la llama Vaults): suelo de Terrain con el material de su temática,
--     colinas a los lados por fuera de los muros y decorado de su temática (palmeras y sombrillas,
--     árboles y setas, rocas de lava y un pequeño volcán, nubes, cristales y arcoíris; pantano con
--     estanques y cristales, engranajes y relojes, restos de titanes, observatorio y astros, y
--     obeliscos bajo un eclipse).
--   * Iluminación, nubes del cielo, post-procesado moderado y hierba corta.
-- Todo es decorado: la lógica está en Vaults, Plots y CritterSpawner. Números en Config/Art.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Art = require(Config:WaitForChild("Art"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))

local WorldArt = {}

local T = Art.terrain
local F = Gameplay.Field
local S = Gameplay.Sanctuary
local HALF = F.width / 2
local G = Gameplay.GroundY
local terrain = Workspace.Terrain
local folder: Folder

-- ===== Utilidades =====

local function part(name: string, shape: Enum.PartType?, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, parent: Instance?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = parent or folder
	return p
end

-- Pieza decorativa pequeña: sin colisión ni sombra (más ligera).
local function deco(name: string, shape: Enum.PartType?, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, parent: Instance?): Part
	local p = part(name, shape, size, cframe, color, material, parent)
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

local function ellipsoid(p: BasePart)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
end

local function model(name: string, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent or folder
	return m
end

local function ground(position: Vector3): CFrame
	return CFrame.new(position.X, G, position.Z)
end

-- Bloque de Terrain con la cara de arriba a la altura `topY` (compensando el redondeo del terreno).
local function terrainBlock(centerX: number, centerZ: number, sizeX: number, sizeZ: number, height: number, topY: number, material: Enum.Material)
	terrain:FillBlock(CFrame.new(centerX, topY - T.surfaceOffset - height / 2, centerZ), Vector3.new(sizeX, height, sizeZ), material)
end

local function terrainDisc(center: Vector3, radius: number, height: number, topY: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(center.X, topY - T.surfaceOffset - height / 2, center.Z), height, radius, material)
end

-- Colinas de roca con hierba a los dos lados del tramo [zFrom, zTo] (por fuera de los muros).
local function sideHills(rng: Random, zFrom: number, zTo: number)
	local z = zFrom
	while z > zTo do
		for _, side in { -1, 1 } do
			local radius = rng:NextNumber(Art.terrain.hillSize.min, Art.terrain.hillSize.max)
			local center = Vector3.new(side * (HALF + T.sideHillOffset + rng:NextNumber(-4, 6)), G - radius * 0.25, z)
			terrain:FillBall(center, radius, if rng:NextNumber() < 0.5 then Enum.Material.Rock else Enum.Material.Grass)
		end
		z -= T.hillSpacing
	end
end

-- ===== Elementos =====

local function palm(rng: Random, position: Vector3, parent: Instance)
	local m = model("Palmera", parent)
	local trunk = Color3.fromRGB(150, 105, 60)
	local ring = Color3.fromRGB(120, 80, 45)
	local lean = rng:NextNumber(6, 14)
	local cf = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
	for i = 0, 4 do
		cf = cf * CFrame.Angles(0, 0, math.rad(lean * 0.25))
		part("Tronco", Enum.PartType.Cylinder, Vector3.new(2.7, 1.3 - i * 0.12, 1.3 - i * 0.12), cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), trunk, Enum.Material.Wood, m)
		deco("Anillo", Enum.PartType.Cylinder, Vector3.new(0.35, 1.45 - i * 0.12, 1.45 - i * 0.12), cf * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)), ring, Enum.Material.Wood, m)
		cf = cf * CFrame.new(0, 2.6, 0)
	end
	for i = 1, 7 do
		local frond = cf * CFrame.Angles(0, math.rad(i * (360 / 7) + rng:NextNumber(-8, 8)), 0)
		local first = deco("Hoja", nil, Vector3.new(1.8, 0.2, 3.6), frond * CFrame.Angles(math.rad(-15), 0, 0) * CFrame.new(0, 0.2, -1.8), Color3.fromRGB(60, 175, 70), Enum.Material.Grass, m)
		deco("Hoja", nil, Vector3.new(1.4, 0.2, 3.2), first.CFrame * CFrame.new(0, 0, -1.6) * CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 0, -1.5), Color3.fromRGB(80, 195, 85), Enum.Material.Grass, m)
	end
	for i = 1, 3 do
		deco("Coco", Enum.PartType.Ball, Vector3.one * 0.9, cf * CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(0.55, -0.5, 0), Color3.fromRGB(110, 70, 40), nil, m)
	end
end

local function umbrella(rng: Random, position: Vector3, color: Color3, parent: Instance)
	local m = model("Sombrilla", parent)
	local base = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), math.rad(8))
	part("Palo", Enum.PartType.Cylinder, Vector3.new(6, 0.25, 0.25), base * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 240, 240), nil, m)
	ellipsoid(deco("Tela", nil, Vector3.new(7, 1.6, 7), base * CFrame.new(0, 6, 0), color, nil, m))
	ellipsoid(deco("Raya", nil, Vector3.new(7.1, 1.2, 2.2), base * CFrame.new(0, 6.1, 0), Color3.fromRGB(255, 255, 255), nil, m))
	deco("Toalla", nil, Vector3.new(3, 0.1, 5.5), ground(position) * CFrame.new(3, 0.1, 1), color, Enum.Material.Fabric, m)
end

local function roundTree(rng: Random, position: Vector3, parent: Instance)
	local m = model("Arbol", parent)
	local height = rng:NextNumber(7, 10)
	local base = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
	part("Tronco", Enum.PartType.Cylinder, Vector3.new(height, 1.8, 1.8), base * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, m)
	for _, side in { -1, 1 } do
		deco("Rama", Enum.PartType.Cylinder, Vector3.new(3, 0.6, 0.6), base * CFrame.new(side * 1.2, height * 0.7, 0) * CFrame.Angles(0, 0, math.rad(side * 40)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, m)
	end
	local greens = { Color3.fromRGB(45, 140, 60), Color3.fromRGB(65, 170, 70), Color3.fromRGB(35, 120, 55), Color3.fromRGB(80, 180, 80) }
	for i = 1, 4 do
		local offset = Vector3.new(rng:NextNumber(-2, 2), height + rng:NextNumber(-0.5, 2.5), rng:NextNumber(-2, 2))
		local canopy = deco("Copa", Enum.PartType.Ball, Vector3.one * rng:NextNumber(4.5, 6.5), base * CFrame.new(offset), greens[i], Enum.Material.Grass, m)
		canopy.CastShadow = i == 1
	end
end

local function pine(position: Vector3, parent: Instance)
	local m = model("Pino", parent)
	local base = ground(position)
	part("Tronco", Enum.PartType.Cylinder, Vector3.new(4, 1.2, 1.2), base * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(100, 70, 45), Enum.Material.Wood, m)
	for i = 0, 3 do
		local width = 7 - i * 1.6
		local tier = deco("Piso", nil, Vector3.new(width, 2.6, width), base * CFrame.new(0, 4 + i * 2.1, 0) * CFrame.Angles(0, math.rad(i * 22), 0), Color3.fromRGB(30 + i * 8, 110 + i * 10, 60), Enum.Material.Grass, m)
		ellipsoid(tier)
		tier.CastShadow = i == 0
	end
end

local function bush(rng: Random, position: Vector3, parent: Instance)
	local m = model("Arbusto", parent)
	for i = 1, 3 do
		deco("Hojas", Enum.PartType.Ball, Vector3.one * rng:NextNumber(1.8, 2.8), ground(position) * CFrame.new(rng:NextNumber(-1, 1), 0.9, rng:NextNumber(-1, 1)), Color3.fromRGB(50 + i * 15, 150 + i * 10, 60), Enum.Material.Grass, m)
	end
end

local FLOWER_COLORS = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 200, 50), Color3.fromRGB(160, 110, 255), Color3.fromRGB(255, 255, 255) }
local function flowerPatch(rng: Random, position: Vector3, parent: Instance)
	local m = model("Flores", parent)
	for _ = 1, 3 do
		local spot = ground(position) * CFrame.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		deco("Tallo", nil, Vector3.new(0.12, 1, 0.12), spot * CFrame.new(0, 0.5, 0), Color3.fromRGB(60, 150, 60), nil, m)
		deco("Flor", Enum.PartType.Ball, Vector3.one * 0.5, spot * CFrame.new(0, 1.05, 0), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], nil, m)
	end
end

local function bigMushroom(rng: Random, position: Vector3, color: Color3, parent: Instance)
	local m = model("SetaGigante", parent)
	local height = rng:NextNumber(2.5, 4.5)
	part("Pie", Enum.PartType.Cylinder, Vector3.new(height, 0.9, 0.9), ground(position) * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(245, 235, 215), nil, m)
	ellipsoid(deco("Sombrero", nil, Vector3.new(3, 1.3, 3), ground(position) * CFrame.new(0, height + 0.3, 0), color, nil, m))
	for i = 1, 3 do
		deco("Lunar", Enum.PartType.Ball, Vector3.one * 0.45, ground(position) * CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(0.9, height + 0.75, 0), Color3.fromRGB(255, 255, 255), nil, m)
	end
end

local function smallVolcano(position: Vector3, parent: Instance)
	for i = 0, 4 do
		terrainDisc(position, 16 - i * 3, 4, G + 4 + i * 4, if i % 2 == 0 then Enum.Material.Basalt else Enum.Material.Rock)
	end
	local craterTop = G + 4 + 4 * 4
	terrainDisc(position, 4, 4, craterTop, Enum.Material.CrackedLava)
	local lava = deco("Lava", Enum.PartType.Cylinder, Vector3.new(0.6, 7, 7), CFrame.new(position.X, craterTop + 0.4, position.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 100, 20), Enum.Material.Neon, parent)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(90, 85, 85))
	smoke.Rate = Art.volcanoSmokeRate
	smoke.Lifetime = NumberRange.new(5, 8)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 12) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.EmissionDirection = Enum.NormalId.Right -- el eje X del cilindro apunta hacia arriba
	smoke.Parent = lava
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 40)
	light.Range = 30
	light.Brightness = 2
	light.Parent = lava
end

local function cloudPuff(rng: Random, position: Vector3, scale: number, parent: Instance)
	local m = model("Nube", parent)
	for i = 1, 4 do
		deco("Bola", Enum.PartType.Ball, Vector3.one * scale * (1.25 - i * 0.18), CFrame.new(position + Vector3.new((i - 2.5) * scale * 0.5, (i % 2) * scale * 0.22, rng:NextNumber(-0.3, 0.3) * scale)), Color3.fromRGB(250, 250, 255), nil, m)
	end
end

local CRYSTAL_COLORS = { Color3.fromRGB(190, 160, 255), Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 180, 230) }
local function crystals(rng: Random, position: Vector3, parent: Instance)
	local m = model("Cristales", parent)
	local color = CRYSTAL_COLORS[rng:NextInteger(1, #CRYSTAL_COLORS)]
	for i = 1, 4 do
		local height = rng:NextNumber(2, 5)
		local c = part("Cristal", nil, Vector3.new(0.9, height, 0.9), ground(position) * CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), math.rad(i * 45), math.rad(rng:NextNumber(-20, 20))) * CFrame.new(0, height / 2, 0), color, Enum.Material.Glass, m)
		c.Transparency = 0.2
		c.CastShadow = false
	end
end

local function rainbow(center: Vector3, parent: Instance)
	local m = model("Arcoiris", parent)
	local colors = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 200, 255) }
	local segments = 12
	for band, color in colors do
		local radius = 34 - band * 2.2
		for i = 0, segments - 1 do
			local a0 = math.pi * i / segments
			local a1 = math.pi * (i + 1) / segments
			local p0 = center + Vector3.new(math.cos(a0) * radius, math.sin(a0) * radius, 0)
			local p1 = center + Vector3.new(math.cos(a1) * radius, math.sin(a1) * radius, 0)
			local piece = deco("Banda", nil, Vector3.new(2.2, 0.6, (p1 - p0).Magnitude + 0.4), CFrame.lookAt((p0 + p1) / 2, p1), color, Enum.Material.Neon, m)
			piece.Transparency = 0.25
		end
	end
end

-- ===== Decorado de las bóvedas 5 a 9 =====

-- Juncos de pantano con su espiga.
local function reeds(rng: Random, position: Vector3, parent: Instance)
	local m = model("Juncos", parent)
	for i = 1, 4 do
		local height = rng:NextNumber(4, 7)
		local cf = ground(position) * CFrame.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, math.rad(rng:NextNumber(-8, 8)))
		deco("Tallo", Enum.PartType.Cylinder, Vector3.new(height, 0.3, 0.3), cf * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 150, 110), Enum.Material.Grass, m)
		if i % 2 == 0 then
			deco("Espiga", Enum.PartType.Cylinder, Vector3.new(1.4, 0.7, 0.7), cf * CFrame.new(0, height, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 80, 50), nil, m)
		end
	end
end

-- Cristal grande y luminoso del pantano.
local function swampCrystal(rng: Random, position: Vector3, parent: Instance)
	local m = model("CristalPantano", parent)
	local color = if rng:NextNumber() < 0.5 then Color3.fromRGB(90, 235, 215) else Color3.fromRGB(150, 200, 255)
	for i = 1, 3 do
		local height = rng:NextNumber(4, 9)
		local c = part("Cristal", nil, Vector3.new(1.6, height, 1.6), ground(position) * CFrame.new((i - 2) * 1.6, 0, 0) * CFrame.Angles(math.rad(rng:NextNumber(-18, 18)), math.rad(i * 40), math.rad(rng:NextNumber(-18, 18))) * CFrame.new(0, height / 2 - 0.5, 0), color, Enum.Material.Glass, m)
		c.Transparency = 0.25
		c.CastShadow = false
	end
	local glow = deco("Brillo", Enum.PartType.Ball, Vector3.one * 1.4, ground(position) * CFrame.new(0, 1.4, 0), color, Enum.Material.Neon, m)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = glow
end

-- Engranaje medio enterrado (o tumbado) de la relojería.
local function bigGear(rng: Random, position: Vector3, parent: Instance)
	local m = model("Engranaje", parent)
	local radius = rng:NextNumber(4, 7)
	local color = if rng:NextNumber() < 0.5 then Color3.fromRGB(190, 140, 60) else Color3.fromRGB(120, 105, 95)
	local lying = rng:NextNumber() < 0.4
	local cf = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0)
	if lying then
		cf = cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)) -- eje hacia arriba
	else
		cf = cf * CFrame.new(0, radius * 0.45, 0) * CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), 0, 0)
	end
	part("Disco", Enum.PartType.Cylinder, Vector3.new(1.2, radius * 2, radius * 2), cf, color, Enum.Material.Metal, m)
	deco("Eje", Enum.PartType.Cylinder, Vector3.new(2, radius * 0.5, radius * 0.5), cf, Color3.fromRGB(70, 60, 55), Enum.Material.Metal, m)
	for i = 0, 3 do
		deco("Dientes", nil, Vector3.new(1.2, radius * 2.35, radius * 0.4), cf * CFrame.Angles(math.rad(i * 45), 0, 0), color, Enum.Material.Metal, m)
	end
end

-- Reloj de pie torcido, con su péndulo.
local function brokenClock(rng: Random, position: Vector3, parent: Instance)
	local m = model("RelojDePie", parent)
	local wood = Color3.fromRGB(110, 70, 45)
	local cf = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), math.rad(rng:NextNumber(-10, 10)))
	part("Caja", nil, Vector3.new(4, 14, 3), cf * CFrame.new(0, 7, 0), wood, Enum.Material.Wood, m)
	deco("Remate", nil, Vector3.new(5, 1, 3.6), cf * CFrame.new(0, 14.4, 0), Color3.fromRGB(85, 55, 35), Enum.Material.Wood, m)
	deco("Esfera", Enum.PartType.Cylinder, Vector3.new(0.3, 3.2, 3.2), cf * CFrame.new(0, 11.5, -1.5) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(245, 235, 210), nil, m)
	deco("Aguja", nil, Vector3.new(0.25, 1.3, 0.1), cf * CFrame.new(0.3, 11.9, -1.7) * CFrame.Angles(0, 0, math.rad(-30)), Color3.fromRGB(30, 30, 35), nil, m)
	deco("Aguja", nil, Vector3.new(0.2, 0.9, 0.1), cf * CFrame.new(-0.3, 11.7, -1.7) * CFrame.Angles(0, 0, math.rad(55)), Color3.fromRGB(30, 30, 35), nil, m)
	deco("Varilla", nil, Vector3.new(0.2, 5, 0.2), cf * CFrame.new(0.5, 6.3, -1.6) * CFrame.Angles(0, 0, math.rad(12)), Art.colors.gold, Enum.Material.Metal, m)
	deco("Pendulo", Enum.PartType.Cylinder, Vector3.new(0.3, 1.8, 1.8), cf * CFrame.new(1, 3.9, -1.6) * CFrame.Angles(0, math.rad(90), 0), Art.colors.gold, Enum.Material.Metal, m)
end

-- Columna antigua (entera o rota) con musgo.
local function ruinPillar(rng: Random, position: Vector3, parent: Instance)
	local m = model("ColumnaAntigua", parent)
	local stone = Color3.fromRGB(175, 170, 155)
	local height = rng:NextNumber(6, 16)
	local cf = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-4, 4)))
	part("Base", nil, Vector3.new(5, 1.2, 5), cf * CFrame.new(0, 0.6, 0), stone, Enum.Material.Slate, m)
	part("Fuste", Enum.PartType.Cylinder, Vector3.new(height, 3.4, 3.4), cf * CFrame.new(0, 1.2 + height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), stone, Enum.Material.Slate, m)
	local moss = deco("Musgo", nil, Vector3.new(4, 1.4, 4), cf * CFrame.new(0, 1.2 + height, 0), Color3.fromRGB(90, 150, 80), Enum.Material.Grass, m)
	ellipsoid(moss)
end

-- Resto de un titán de piedra: una mano que sale del suelo o una cabeza caída.
local function titanPiece(rng: Random, position: Vector3, parent: Instance)
	local m = model("RestoDeTitan", parent)
	local stone = Color3.fromRGB(150, 150, 140)
	local dark = Color3.fromRGB(115, 115, 110)
	local cf = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
	if rng:NextNumber() < 0.5 then
		part("Palma", nil, Vector3.new(9, 8, 3.5), cf * CFrame.new(0, 3, 0) * CFrame.Angles(math.rad(-12), 0, 0), stone, Enum.Material.Slate, m)
		for i = 0, 3 do
			part("Dedo", nil, Vector3.new(1.8, 6.5 + (i % 2) * 1.5, 2.2), cf * CFrame.new(-3.4 + i * 2.25, 9.5, -0.6) * CFrame.Angles(math.rad(-20), 0, 0), if i % 2 == 0 then stone else dark, Enum.Material.Slate, m)
		end
		part("Pulgar", nil, Vector3.new(2, 5, 2.4), cf * CFrame.new(5.6, 5, -0.5) * CFrame.Angles(0, 0, math.rad(-35)), dark, Enum.Material.Slate, m)
	else
		local head = part("Cabeza", nil, Vector3.new(10, 10, 9), cf * CFrame.new(0, 3.6, 0) * CFrame.Angles(0, 0, math.rad(18)), stone, Enum.Material.Slate, m)
		deco("Ceja", nil, Vector3.new(9, 1.4, 1.5), head.CFrame * CFrame.new(0, 1.6, -4.6), dark, Enum.Material.Slate, m)
		deco("Nariz", nil, Vector3.new(1.8, 4, 1.8), head.CFrame * CFrame.new(0, -0.6, -4.9), dark, Enum.Material.Slate, m)
		for _, side in { -1, 1 } do
			deco("Ojo", nil, Vector3.new(2, 1, 0.6), head.CFrame * CFrame.new(side * 2.4, 0.4, -4.5), Color3.fromRGB(60, 235, 200), Enum.Material.Neon, m)
		end
		local moss = deco("Musgo", nil, Vector3.new(9, 2.5, 8), head.CFrame * CFrame.new(0, 5, 0), Color3.fromRGB(90, 150, 80), Enum.Material.Grass, m)
		ellipsoid(moss)
	end
end

-- Cúpula de observatorio con su telescopio.
local function observatory(position: Vector3, parent: Instance)
	local m = model("Observatorio", parent)
	local cf = ground(position)
	part("Torre", Enum.PartType.Cylinder, Vector3.new(8, 14, 14), cf * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(205, 205, 220), Enum.Material.Slate, m)
	part("Cupula", Enum.PartType.Ball, Vector3.one * 14, cf * CFrame.new(0, 8, 0), Color3.fromRGB(70, 80, 170), Enum.Material.Metal, m)
	deco("Telescopio", Enum.PartType.Cylinder, Vector3.new(12, 2.4, 2.4), cf * CFrame.new(0, 14, -3) * CFrame.Angles(0, math.rad(90), math.rad(-50)), Color3.fromRGB(215, 180, 80), Enum.Material.Metal, m)
	deco("Lente", Enum.PartType.Ball, Vector3.one * 2.2, cf * CFrame.new(0, 18.5, -6.8), Color3.fromRGB(150, 220, 255), Enum.Material.Neon, m)
end

-- Astro flotante con su anillo.
local STAR_COLORS = { Color3.fromRGB(255, 230, 140), Color3.fromRGB(150, 200, 255), Color3.fromRGB(230, 160, 255) }
local function starOrb(rng: Random, position: Vector3, parent: Instance)
	local color = STAR_COLORS[rng:NextInteger(1, #STAR_COLORS)]
	local size = rng:NextNumber(1.2, 3)
	local cf = CFrame.new(position) * CFrame.Angles(math.rad(rng:NextNumber(-40, 40)), 0, math.rad(rng:NextNumber(-40, 40)))
	deco("Astro", Enum.PartType.Ball, Vector3.one * size, cf, color, Enum.Material.Neon, parent)
	if size > 2 then
		local ring = deco("Anillo", Enum.PartType.Cylinder, Vector3.new(0.15, size * 2.2, size * 2.2), cf * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Neon, parent)
		ring.Transparency = 0.6
	end
end

-- Obelisco oscuro con una veta de luz plateada.
local function obelisk(rng: Random, position: Vector3, parent: Instance)
	local m = model("Obelisco", parent)
	local height = rng:NextNumber(10, 20)
	local cf = ground(position) * CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-5, 5)))
	part("Cuerpo", nil, Vector3.new(3.4, height, 3.4), cf * CFrame.new(0, height / 2, 0), Color3.fromRGB(28, 26, 40), Enum.Material.Slate, m)
	deco("Punta", nil, Vector3.new(2.4, 2.4, 2.4), cf * CFrame.new(0, height, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Color3.fromRGB(28, 26, 40), Enum.Material.Slate, m)
	deco("Veta", nil, Vector3.new(0.4, height * 0.7, 3.5), cf * CFrame.new(0, height * 0.5, 0), Color3.fromRGB(225, 230, 255), Enum.Material.Neon, m)
end

-- El eclipse: disco negro en el cielo con su corona de luz.
local function eclipse(position: Vector3, parent: Instance)
	local m = model("Eclipse", parent)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0) -- el eje del disco mira a la plaza
	local corona = deco("Corona", Enum.PartType.Cylinder, Vector3.new(0.6, 34, 34), cf, Color3.fromRGB(235, 235, 255), Enum.Material.Neon, m)
	corona.Transparency = 0.15
	deco("Luna", Enum.PartType.Cylinder, Vector3.new(1.2, 29, 29), cf, Color3.fromRGB(12, 10, 20), nil, m)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(220, 220, 255)
	light.Range = 60
	light.Brightness = 1.5
	light.Parent = corona
end

local function lamp(position: Vector3, parent: Instance)
	local base = ground(position)
	part("Poste", Enum.PartType.Cylinder, Vector3.new(6, 0.45, 0.45), base * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 55, 65), Enum.Material.Metal, parent).CastShadow = false
	deco("Tejadillo", nil, Vector3.new(1.5, 0.3, 1.5), base * CFrame.new(0, 6.9, 0), Color3.fromRGB(60, 55, 65), Enum.Material.Metal, parent)
	local bulb = deco("Farol", Enum.PartType.Ball, Vector3.one * 1.1, base * CFrame.new(0, 6.2, 0), Color3.fromRGB(255, 220, 140), Enum.Material.Neon, parent)
	local light = Instance.new("PointLight")
	light.Range = 14
	light.Brightness = 1
	light.Color = Color3.fromRGB(255, 210, 140)
	light.Parent = bulb
end

-- Punto al azar dentro de la franja lateral de una bóveda (los bichos corretean por el centro).
local function edgePoint(rng: Random, n: number): Vector3
	local side = if rng:NextNumber() < 0.5 then -1 else 1
	local x = side * rng:NextNumber(HALF - 22, HALF - 8)
	local z = rng:NextNumber(VaultMath.backZ(n) + 8, VaultMath.frontZ(n) - 8)
	return Vector3.new(x, G, z)
end

local function anyPoint(rng: Random, n: number): Vector3
	local x = rng:NextNumber(-HALF + 14, HALF - 14)
	local z = rng:NextNumber(VaultMath.backZ(n) + 12, VaultMath.frontZ(n) - 12)
	return Vector3.new(x, G, z)
end

-- ===== Bóvedas =====

function WorldArt.BuildVault(n: number)
	local rng = Random.new(Art.seed + n * 7919) -- cada bóveda sale siempre igual
	local theme = VaultMath.theme(n)
	local front = VaultMath.frontZ(n)
	local back = VaultMath.backZ(n)
	local centerZ = (front + back) / 2
	local D = Art.vaultDecor
	local m = model("DecoradoBoveda" .. n)

	-- Suelo: capa base de hierba y encima el material de la temática.
	terrainBlock(0, centerZ, F.width + 120, F.vaultLength, T.depth, G, Enum.Material.Grass)
	terrainBlock(0, centerZ, F.width, F.vaultLength, 4, G, Art.zoneMaterials[theme])
	sideHills(rng, front, back)

	if theme == "PlayaRara" then
		for _ = 1, D.palms do
			palm(rng, edgePoint(rng, n), m)
		end
		for _ = 1, D.umbrellas do
			umbrella(rng, edgePoint(rng, n), Color3.fromRGB(255, 90, 90), m)
		end
		for _ = 1, D.rocks do
			local p = edgePoint(rng, n)
			terrain:FillBall(Vector3.new(p.X, G + 0.5, p.Z), rng:NextNumber(1.5, 3), Enum.Material.Sandstone)
		end
	elseif theme == "BosqueRuidoso" then
		for i = 1, D.trees do
			if i % 3 == 0 then
				pine(edgePoint(rng, n), m)
			else
				roundTree(rng, edgePoint(rng, n), m)
			end
		end
		for _ = 1, D.bushes do
			bush(rng, edgePoint(rng, n), m)
		end
		for _ = 1, D.mushrooms do
			bigMushroom(rng, anyPoint(rng, n), if rng:NextNumber() < 0.5 then Color3.fromRGB(230, 70, 70) else Color3.fromRGB(225, 60, 150), m)
		end
		local pond = edgePoint(rng, n)
		terrainDisc(pond, 8, 4, G, Enum.Material.Mud)
		terrainDisc(pond, 6, 3, G - 0.2, Enum.Material.Water)
	elseif theme == "VolcanTimido" then
		smallVolcano(Vector3.new((if rng:NextNumber() < 0.5 then -1 else 1) * (HALF - 14), G, centerZ), m)
		for _ = 1, D.lavaRocks do
			local p = anyPoint(rng, n)
			terrainDisc(p, rng:NextNumber(3, 5), 4, G, Enum.Material.CrackedLava)
		end
		for _ = 1, D.rocks do
			local p = edgePoint(rng, n)
			terrain:FillBall(Vector3.new(p.X, G + 0.5, p.Z), rng:NextNumber(2, 4), Enum.Material.Basalt)
		end
	elseif theme == "NubePegajosa" then
		for _ = 1, D.clouds do
			cloudPuff(rng, anyPoint(rng, n) + Vector3.new(0, rng:NextNumber(14, 26), 0), rng:NextNumber(4, 7), m)
		end
		for _ = 1, D.crystals do
			crystals(rng, edgePoint(rng, n), m)
		end
		for _ = 1, 4 do
			local p = anyPoint(rng, n)
			terrainDisc(p, rng:NextNumber(3, 6), 4, G, Enum.Material.Glacier)
		end
		rainbow(Vector3.new(0, G, back + 10), m)
	elseif theme == "PantanoCristal" then
		for _ = 1, D.ponds do
			local p = anyPoint(rng, n)
			local radius = rng:NextNumber(5, 9)
			terrainDisc(p, radius + 2, 4, G, Enum.Material.Ground)
			terrainDisc(p, radius, 3, G - 0.2, Enum.Material.Water)
		end
		for _ = 1, D.crystals do
			swampCrystal(rng, edgePoint(rng, n), m)
		end
		for _ = 1, D.reeds do
			reeds(rng, edgePoint(rng, n), m)
		end
		for i = 1, D.bushes do
			bigMushroom(rng, edgePoint(rng, n), if i % 2 == 0 then Color3.fromRGB(70, 200, 190) else Color3.fromRGB(130, 120, 230), m)
		end
	elseif theme == "RelojeriaAbandonada" then
		for _ = 1, D.gears do
			bigGear(rng, edgePoint(rng, n), m)
		end
		for _ = 1, D.pendulums do
			brokenClock(rng, edgePoint(rng, n), m)
		end
		for _ = 1, 4 do
			local p = anyPoint(rng, n)
			terrainDisc(p, rng:NextNumber(3, 6), 4, G, Enum.Material.WoodPlanks)
		end
	elseif theme == "ValleTitanes" then
		for _ = 1, D.titanPieces do
			titanPiece(rng, edgePoint(rng, n), m)
		end
		for _ = 1, D.pillars do
			ruinPillar(rng, edgePoint(rng, n), m)
		end
		for _ = 1, 5 do
			local p = anyPoint(rng, n)
			terrainDisc(p, rng:NextNumber(4, 8), 4, G, Enum.Material.LeafyGrass)
		end
		for _ = 1, D.rocks do
			local p = edgePoint(rng, n)
			terrain:FillBall(Vector3.new(p.X, G + 0.5, p.Z), rng:NextNumber(2, 4), Enum.Material.Rock)
		end
	elseif theme == "ObservatorioAstral" then
		observatory(Vector3.new((if rng:NextNumber() < 0.5 then -1 else 1) * (HALF - 16), G, centerZ), m)
		for _ = 1, D.starOrbs do
			starOrb(rng, anyPoint(rng, n) + Vector3.new(0, rng:NextNumber(12, 30), 0), m)
		end
		for _ = 1, D.crystals do
			crystals(rng, edgePoint(rng, n), m)
		end
		for _ = 1, 4 do
			local p = anyPoint(rng, n)
			terrainDisc(p, rng:NextNumber(3, 6), 4, G, Enum.Material.Glacier)
		end
	else -- SantuarioEclipse
		eclipse(Vector3.new(0, G + 46, back + 6), m)
		for _ = 1, D.obelisks do
			obelisk(rng, edgePoint(rng, n), m)
		end
		for _ = 1, 5 do
			local p = anyPoint(rng, n)
			terrainDisc(p, rng:NextNumber(3, 6), 4, G, Enum.Material.Basalt)
		end
		for _ = 1, D.starOrbs // 2 do
			starOrb(rng, anyPoint(rng, n) + Vector3.new(0, rng:NextNumber(14, 28), 0), m)
		end
	end
end

-- ===== Plaza de los santuarios =====

local function buildHub()
	local rng = Random.new(Art.seed)
	local back = F.startZ + F.hubLength
	local centerZ = (F.startZ + back) / 2
	local H = Art.hub

	terrainBlock(0, centerZ, F.width + 120, F.hubLength + 40, T.depth, G, Enum.Material.Grass)
	-- Avenida de piedra por el centro, hasta la entrada de la bóveda 1.
	terrainBlock(0, centerZ, H.avenueWidth, F.hubLength, 4, G, Enum.Material.Cobblestone)
	-- Plaza redonda en el punto de aparición.
	terrainDisc(F.spawn, 16, 4, G, Enum.Material.Cobblestone)
	-- Bajo los santuarios, piedra en vez de hierba (si no, la hierba animada atraviesa su suelo).
	for index = 1, S.plotCount do
		local side = if index % 2 == 1 then -1 else 1
		local z = S.firstZ + ((index - 1) // 2) * S.spacingZ
		terrainBlock(side * S.sideX, z, S.plotSize + 4, S.plotSize + 4, 4, G, Enum.Material.Cobblestone)
	end
	sideHills(rng, back + 40, F.startZ)
	-- Colinas también detrás de la plaza.
	for x = -HALF - 20, HALF + 20, T.hillSpacing do
		terrain:FillBall(Vector3.new(x, G - 4, back + T.sideHillOffset), rng:NextNumber(T.hillSize.min, T.hillSize.max), Enum.Material.Grass)
	end

	local hub = model("Plaza")
	-- Fuente en el centro de la plaza.
	local spawnPoint = Vector3.new(F.spawn.X, G, F.spawn.Z + 14)
	part("Pilon", Enum.PartType.Cylinder, Vector3.new(1.6, 12, 12), ground(spawnPoint) * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 195, 190), Enum.Material.Slate, hub)
	local water = deco("Agua", Enum.PartType.Cylinder, Vector3.new(0.3, 10.5, 10.5), ground(spawnPoint) * CFrame.new(0, 1.55, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(80, 180, 240), Enum.Material.Glass, hub)
	water.Transparency = 0.3
	part("Columna", Enum.PartType.Cylinder, Vector3.new(5, 1.6, 1.6), ground(spawnPoint) * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 195, 190), Enum.Material.Slate, hub)
	deco("Copa", Enum.PartType.Ball, Vector3.one * 2.4, ground(spawnPoint) * CFrame.new(0, 6.3, 0), Art.colors.gold, Enum.Material.Neon, hub)
	local splash = Instance.new("ParticleEmitter")
	splash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	splash.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255))
	splash.Rate = 8
	splash.Lifetime = NumberRange.new(0.8, 1.2)
	splash.Speed = NumberRange.new(6, 9)
	splash.SpreadAngle = Vector2.new(25, 25)
	splash.Acceleration = Vector3.new(0, -20, 0)
	splash.Size = NumberSequence.new(0.6, 0)
	splash.Parent = hub:FindFirstChild("Copa")

	-- Farolas a los lados de la avenida.
	for z = F.startZ + 12, back - 12, 30 do
		for _, side in { -1, 1 } do
			lamp(Vector3.new(side * (H.avenueWidth / 2 + 2), G, z), hub)
		end
	end
	-- Árboles y flores en el borde y detrás de los santuarios.
	for _ = 1, H.trees do
		local x = (if rng:NextNumber() < 0.5 then -1 else 1) * rng:NextNumber(HALF - 6, HALF - 2)
		roundTree(rng, Vector3.new(x, G, rng:NextNumber(F.startZ + 10, back - 10)), hub)
	end
	for _ = 1, H.flowers do
		local x = rng:NextNumber(-H.avenueWidth * 1.4, H.avenueWidth * 1.4)
		if math.abs(x) > H.avenueWidth / 2 + 1 then
			flowerPatch(rng, Vector3.new(x, G, rng:NextNumber(F.startZ + 6, back - 6)), hub)
		end
	end
	-- Arco de entrada al campo de bóvedas.
	local arch = model("ArcoEntrada", hub)
	for _, side in { -1, 1 } do
		part("Pilar", nil, Vector3.new(3, 14, 3), CFrame.new(side * (H.avenueWidth / 2 + 3), G + 7, F.startZ + 4), Color3.fromRGB(150, 140, 130), Enum.Material.Slate, arch)
	end
	part("Dintel", nil, Vector3.new(H.avenueWidth + 9, 2.5, 3.5), CFrame.new(0, G + 15, F.startZ + 4), Art.colors.gold, Enum.Material.SmoothPlastic, arch)
end

-- ===== Iluminación =====

local function setupLighting()
	Lighting.ClockTime = Art.lighting.clockTime
	Lighting.Brightness = Art.lighting.brightness
	Lighting.Ambient = Art.lighting.ambient
	Lighting.OutdoorAmbient = Art.lighting.outdoorAmbient
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = Art.ambience.PlayaRara.density
	atmosphere.Color = Art.ambience.PlayaRara.color
	atmosphere.Decay = Art.ambience.PlayaRara.decay
	atmosphere.Haze = Art.ambience.PlayaRara.haze
	atmosphere.Glare = 0.3
	atmosphere.Parent = Lighting

	local correction = Lighting:FindFirstChild("ColorZona") or Instance.new("ColorCorrectionEffect")
	correction.Name = "ColorZona"
	;(correction :: ColorCorrectionEffect).Saturation = Art.lighting.saturation
	;(correction :: ColorCorrectionEffect).Contrast = Art.lighting.contrast
	correction.Parent = Lighting

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 20
	bloom.Threshold = 1.5
	bloom.Parent = Lighting

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.04
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting
end

local function setupTerrainLook()
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(105, 190, 75))
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(70, 150, 60))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(240, 215, 150))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(130, 125, 135))
	terrain:SetMaterialColor(Enum.Material.Basalt, Color3.fromRGB(75, 55, 55))
	terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(245, 240, 255))
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(175, 165, 155))
	terrain.WaterColor = T.waterColor
	terrain.WaterTransparency = 0.6
	terrain.WaterWaveSize = 0.15
	-- Hierba animada, pero corta (Config/Art.terrain.grassLength).
	pcall(function()
		(terrain :: any).Decoration = true
	end)
	pcall(function()
		(terrain :: any).GrassLength = T.grassLength
	end)
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.5
	clouds.Density = 0.6
	clouds.Parent = terrain
end

-- ===== Arranque =====

function WorldArt.Start()
	folder = Instance.new("Folder")
	folder.Name = "Decorado"
	folder.Parent = Workspace

	-- El Baseplate de la plantilla se sustituye por el terreno.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	-- El punto de aparición se coloca en la plaza, sobre el terreno.
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Position = Vector3.new(F.spawn.X, G + descendant.Size.Y / 2, F.spawn.Z)
		end
	end

	terrain:Clear()
	setupLighting()
	setupTerrainLook()
	buildHub()
end

return WorldArt
