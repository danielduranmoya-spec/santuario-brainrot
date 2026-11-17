--!strict
-- Escenario de la Isla Santuario, generado por código (trazado en Config/Island, ver design/Mapa.md):
--   * Mar y una isla redonda de costa ondulada, con playa, rocas, un faro y un muelle con barcas.
--   * Plaza central: árbol gigante en flor con farolillos y pétalos, estanque en anillo con puentes,
--     farolas, bancos, parterres y un seto con una sola salida: la avenida, con farolas y banderines.
--   * Zonas 1-7 en sectores alrededor de la plaza, separadas por crestas de roca: suelo y decorado de
--     su temática (playa, bosque, volcán con río de lava, pantano de cristal, relojería, valle de
--     titanes). La zona 4 es una isla de nubes sobre su sector, con escaleras y una cascada.
--   * Zonas 8 en adelante (BuildVault, la llama Vaults): islas flotantes unidas por puentes colgantes.
--   * Iluminación, nubes del cielo, post-procesado moderado y hierba corta.
-- Todo es decorado: la lógica está en Vaults, Plots, Boundary y CritterSpawner. Números en Config/Art.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Art = require(Config:WaitForChild("Art"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))
local Island = require(Config:WaitForChild("Island"))
local Layout = require(Shared:WaitForChild("Layout"))

local WorldArt = {}

local T = Art.terrain
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

-- Apoya un objeto en el suelo en `position` (su Y es la altura del suelo: la isla no es plana y hay
-- islas flotantes).
local function ground(position: Vector3): CFrame
	return CFrame.new(position.X, position.Y, position.Z)
end

-- Bloque de Terrain con la cara de arriba a la altura `topY` (compensando el redondeo del terreno).
local function terrainBlock(centerX: number, centerZ: number, sizeX: number, sizeZ: number, height: number, topY: number, material: Enum.Material)
	terrain:FillBlock(CFrame.new(centerX, topY - T.surfaceOffset - height / 2, centerZ), Vector3.new(sizeX, height, sizeZ), material)
end

local function terrainDisc(center: Vector3, radius: number, height: number, topY: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(center.X, topY - T.surfaceOffset - height / 2, center.Z), height, radius, material)
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
-- ===== Isla Santuario (Config/Island) =====

local HUB = Island.Hub
local ZN = Island.Zones
local COAST = Island.Coast
local LM = Island.Landmarks
local D = Art.island

local function ringPos(angleDegrees: number, radius: number, y: number?): Vector3
	local a = math.rad(angleDegrees)
	return Vector3.new(math.cos(a) * radius, y or G, math.sin(a) * radius)
end

-- Radio de la orilla en un ángulo (la costa entra y sale un poco).
local function coastAt(angleDegrees: number): number
	local a = math.rad(angleDegrees)
	return COAST.radius + COAST.wobble * math.noise(math.cos(a) * 1.6 + 3.1, math.sin(a) * 1.6 + 1.7, 0.37) * 1.8
end

local function sectorCenterAngle(n: number): number
	return HUB.avenueAngle + (n - 1) * ZN.ringStep
end

-- Punto al azar en el sector de la zona n (1-7), entre los radios dados, lejos de las crestas y,
-- si `avoidPath`, del camino en anillo.
local function sectorPoint(rng: Random, n: number, rMin: number, rMax: number, avoidPath: boolean?): Vector3
	local half = ZN.ringStep / 2 - 5
	for _ = 1, 12 do
		local angle = sectorCenterAngle(n) + rng:NextNumber(-half, half)
		local radius = rng:NextNumber(rMin, math.min(rMax, coastAt(angle) - 18))
		if not avoidPath or math.abs(radius - ZN.ringRadius) > D.pathClearance then
			return ringPos(angle, radius)
		end
	end
	return ringPos(sectorCenterAngle(n), rMin)
end

-- Punto al azar en la isla flotante de la zona n (por sus bordes si `edge`, donde no molesta).
local function islandPoint(rng: Random, n: number, edge: boolean?): Vector3
	local size = VaultMath.size(n)
	local u = rng:NextNumber(-0.45, 0.45)
	local v = rng:NextNumber(-0.45, 0.45)
	if edge then
		if rng:NextNumber() < 0.5 then
			u = (if rng:NextNumber() < 0.5 then -1 else 1) * rng:NextNumber(0.36, 0.48)
		else
			v = (if rng:NextNumber() < 0.5 then -1 else 1) * rng:NextNumber(0.36, 0.48)
		end
	end
	local _ = size
	return VaultMath.point(n, u, v)
end

-- Tablón de `a` a `b` (puentes y rampas).
local function plank(name: string, a: Vector3, b: Vector3, width: number, color: Color3, material: Enum.Material, parent: Instance): Part
	local length = (b - a).Magnitude
	local p = part(name, nil, Vector3.new(width, 1, length + 0.6), CFrame.lookAt((a + b) / 2, b), color, material, parent)
	return p
end

-- Cuerda (decorado) de `a` a `b`.
local function rope(a: Vector3, b: Vector3, thickness: number, color: Color3, parent: Instance)
	local length = (b - a).Magnitude
	deco("Cuerda", nil, Vector3.new(thickness, thickness, length), CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Fabric, parent)
end

local WOOD = Color3.fromRGB(165, 115, 70)
local WOOD_DARK = Color3.fromRGB(120, 80, 50)
local STONE = Color3.fromRGB(196, 186, 170)
local ROPE = Color3.fromRGB(220, 200, 150)

-- Puente colgante de `from` a `to`, con postes y barandillas de cuerda.
local function bridge(from: Vector3, to: Vector3, parent: Instance)
	local m = model("Puente", parent)
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local count = math.max(2, math.ceil(flat.Magnitude / 6))
	local right = flat.Unit:Cross(Vector3.yAxis)
	local previous = from
	for i = 1, count do
		local t = i / count
		local sag = math.sin(math.pi * t) * math.min(4, flat.Magnitude / 40)
		local point = from:Lerp(to, t) - Vector3.new(0, sag, 0)
		plank("Tabla", previous, point, 7, if i % 2 == 0 then WOOD else WOOD_DARK, Enum.Material.WoodPlanks, m)
		if i % 2 == 0 or i == count then
			for _, side in { -1, 1 } do
				local base = point + right * side * 3.6
				part("Poste", nil, Vector3.new(0.6, 4, 0.6), CFrame.new(base + Vector3.new(0, 2, 0)), WOOD_DARK, Enum.Material.Wood, m)
			end
		end
		previous = point
	end
	-- Barandillas: dos cuerdas a lo largo, a la altura de la mano.
	for _, side in { -1, 1 } do
		local last = from + right * side * 3.6 + Vector3.new(0, 3.6, 0)
		for i = 1, count do
			local t = i / count
			local sag = math.sin(math.pi * t) * math.min(4, flat.Magnitude / 40)
			local point = from:Lerp(to, t) - Vector3.new(0, sag, 0) + right * side * 3.6 + Vector3.new(0, 3.6, 0)
			rope(last, point, 0.25, ROPE, m)
			last = point
		end
	end
end

-- Escalera en zigzag de `from` (suelo) a `to` (arriba): rampas de madera entre rocas que flotan.
local function switchback(from: Vector3, to: Vector3, parent: Instance)
	local m = model("Escalera", parent)
	local rise = to.Y - from.Y
	local steps = math.max(2, math.ceil(math.abs(rise) / 8))
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local side = flat.Unit:Cross(Vector3.yAxis)
	local nodes = { from }
	for i = 1, steps - 1 do
		local t = i / steps
		local lateral = (if i % 2 == 1 then 1 else -1) * D.switchbackWidth
		table.insert(nodes, from + flat * t + side * lateral + Vector3.new(0, rise * t, 0))
	end
	table.insert(nodes, to)
	for i, node in nodes do
		-- Rellano: roca flotante con hierba encima.
		local pad = part("Rellano", Enum.PartType.Cylinder, Vector3.new(1.4, 11, 11), CFrame.new(node - Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 185, 80), Enum.Material.Grass, m)
		pad.TopSurface = Enum.SurfaceType.Smooth
		if i > 1 and i < #nodes then
			ellipsoid(deco("Roca", nil, Vector3.new(10, 6, 10), CFrame.new(node - Vector3.new(0, 3.6, 0)), Color3.fromRGB(150, 125, 110), Enum.Material.Slate, m))
		end
		if i > 1 then
			plank("Rampa", nodes[i - 1] + Vector3.new(0, -0.4, 0), node + Vector3.new(0, -0.4, 0), 6, WOOD, Enum.Material.WoodPlanks, m)
		end
	end
end

-- ===== Terreno =====

local function buildSea()
	local size = COAST.seaSize
	terrain:FillBlock(CFrame.new(0, G - 3 - COAST.seaDepth / 2, 0), Vector3.new(size, COAST.seaDepth, size), Enum.Material.Water)
	terrain:FillBlock(CFrame.new(0, G - 3 - COAST.seaDepth - 3, 0), Vector3.new(size, 6, size), Enum.Material.Sand)
end

local function buildIslandGround()
	local depth = T.depth
	-- Núcleo de la isla y orilla ondulada: arena en el borde, hierba dentro.
	terrainDisc(Vector3.zero, COAST.radius - 60, depth, G, Enum.Material.Grass)
	for angle = 0, 359, 4 do
		local edge = coastAt(angle)
		terrainDisc(ringPos(angle, edge - COAST.beachWidth - 30), 30, depth, G, Enum.Material.Grass)
		terrainDisc(ringPos(angle, edge - 12), 16, depth, G - 1.2, Enum.Material.Sand)
		terrainDisc(ringPos(angle, edge - 2), 12, depth, G - 3.5, Enum.Material.Sand)
	end
end

-- Material del suelo de cada temática.
local SECTOR_GROUND: { [string]: Enum.Material } = {
	PlayaRara = Enum.Material.Sand,
	BosqueRuidoso = Enum.Material.LeafyGrass,
	VolcanTimido = Enum.Material.Basalt,
	NubePegajosa = Enum.Material.Grass,
	PantanoCristal = Enum.Material.Mud,
	RelojeriaAbandonada = Enum.Material.Brick,
	ValleTitanes = Enum.Material.LeafyGrass,
	ObservatorioAstral = Enum.Material.Grass,
	SantuarioEclipse = Enum.Material.Basalt,
}

-- Suelo del sector n con el material de su temática, con manchas del segundo material.
local function sectorGround(rng: Random, n: number)
	local theme = VaultMath.theme(n)
	local material = SECTOR_GROUND[theme]
	local half = ZN.ringStep / 2
	for radius = HUB.wallRadius + 16, COAST.radius - 20, 24 do
		local step = math.deg(22 / radius)
		for angle = sectorCenterAngle(n) - half + step / 2, sectorCenterAngle(n) + half - step / 2, step do
			if radius < coastAt(angle) - 30 then
				terrainDisc(ringPos(angle, radius), 17, 4, G, material)
			end
		end
	end
	local patches: { [string]: Enum.Material } = {
		BosqueRuidoso = Enum.Material.Grass,
		VolcanTimido = Enum.Material.CrackedLava,
		PantanoCristal = Enum.Material.Slate,
		RelojeriaAbandonada = Enum.Material.Cobblestone,
		ValleTitanes = Enum.Material.Rock,
		ObservatorioAstral = Enum.Material.Slate,
		NubePegajosa = Enum.Material.LeafyGrass,
	}
	local patch = patches[theme]
	if patch then
		for _ = 1, D.groundPatches do
			terrainDisc(sectorPoint(rng, n, HUB.wallRadius + 20, COAST.radius - 40, true), rng:NextNumber(6, 12), 4, G, patch)
		end
	end
end

-- Cresta de roca que separa los sectores (con hueco donde pasa el camino, salvo entre la 7 y la 1).
local function ridge(rng: Random, k: number, parent: Instance)
	local angle = HUB.avenueAngle + (k - 1.5) * ZN.ringStep
	local outer = coastAt(angle) + 6
	local gapHalf = ZN.gateWidth / 2 + 7
	local radius = HUB.wallRadius + 6
	while radius < outer do
		local inGap = k ~= 1 and math.abs(radius - ZN.ringRadius) < gapHalf
		if not inGap then
			local size = rng:NextNumber(9, 13) + 5 * math.clamp((radius - HUB.wallRadius) / 220, 0, 1)
			local center = ringPos(angle + rng:NextNumber(-1.2, 1.2), radius, G + size * 0.25)
			terrain:FillBall(center, size, Enum.Material.Rock)
			if rng:NextNumber() < 0.55 then
				terrain:FillBall(center + Vector3.new(0, size * 0.55, 0), size * 0.55, Enum.Material.LeafyGrass)
			end
			if rng:NextNumber() < 0.18 then
				pine(center + Vector3.new(0, size * 0.95, 0), parent)
			end
		end
		radius += 9
	end
	-- Estatuas en los extremos del hueco: dos rocas talladas que flanquean el arco.
	if k ~= 1 then
		for _, side in { -1, 1 } do
			local p = ringPos(angle, ZN.ringRadius + side * (gapHalf + 4))
			terrain:FillBall(p + Vector3.new(0, 6, 0), 10, Enum.Material.Rock)
		end
	end
end

-- Camino de tierra (bloques de terreno a lo largo de una polilínea).
local function pathAlong(points: { Vector3 }, width: number)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local flatA, flatB = Vector3.new(a.X, G, a.Z), Vector3.new(b.X, G, b.Z)
		local length = (flatB - flatA).Magnitude
		if length > 0.1 then
			local cf = CFrame.lookAt((flatA + flatB) / 2, flatB)
			terrain:FillBlock(cf * CFrame.new(0, -T.surfaceOffset - 2, 0), Vector3.new(width, 4, length + width * 0.6), Enum.Material.Ground)
		end
	end
end

local function buildPaths()
	-- Avenida: de la plaza al arco de la zona 1 y hasta el camino en anillo.
	local avenue = {}
	for radius = HUB.plazaRadius + 2, ZN.ringRadius, 12 do
		table.insert(avenue, ringPos(HUB.avenueAngle, radius))
	end
	pathAlong(avenue, HUB.avenueWidth)
	-- Camino en anillo: de la zona 1 a la 7, pasando por los arcos.
	local ring = {}
	local last = HUB.avenueAngle + 6 * ZN.ringStep + ZN.ringStep * 0.3
	for angle = HUB.avenueAngle, last, 3 do
		table.insert(ring, ringPos(angle, ZN.ringRadius))
	end
	pathAlong(ring, D.pathWidth)
	-- Ramal hacia el puente de la primera isla flotante.
	local gate8 = VaultMath.gate(8).Position
	pathAlong({ ringPos(ZN.bridgeAngle, ZN.ringRadius), Vector3.new(gate8.X, G, gate8.Z) }, D.pathWidth)
end

-- ===== Plaza central =====

local function giantTree(parent: Instance)
	local m = model("ArbolGigante", parent)
	local bark = Color3.fromRGB(115, 78, 52)
	local barkDark = Color3.fromRGB(90, 60, 40)
	local top = G + 1
	-- Tronco: tramos cada vez más finos, un poco torcidos.
	local center = Vector3.new(0, top, 0)
	local radius = 7.5
	for i = 1, 7 do
		local nextCenter = center + Vector3.new(math.sin(i * 1.3) * 0.9, 6, math.cos(i * 1.7) * 0.9)
		local piece = part("Tronco", Enum.PartType.Cylinder, Vector3.new(6.6, radius * 2, radius * 2), CFrame.lookAt((center + nextCenter) / 2, nextCenter) * CFrame.Angles(0, math.rad(90), 0), if i % 2 == 0 then bark else barkDark, Enum.Material.Wood, m)
		piece.CastShadow = true
		local knot = part("Nudo", Enum.PartType.Ball, Vector3.one * radius * 2.05, CFrame.new(nextCenter), if i % 2 == 0 then bark else barkDark, Enum.Material.Wood, m)
		knot.CastShadow = false
		center = nextCenter
		radius *= 0.9
	end
	local crown = center
	-- Raíces que se hunden en la isla del estanque.
	for i = 1, 7 do
		local a = math.rad(i * (360 / 7) + 12)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local from = Vector3.new(0, top + 4, 0) + dir * 4
		local to = Vector3.new(0, top - 0.5, 0) + dir * 12
		local root = part("Raiz", Enum.PartType.Cylinder, Vector3.new((to - from).Magnitude + 2, 3.2, 3.2), CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(0, math.rad(90), 0), barkDark, Enum.Material.Wood, m)
		root.CanCollide = false
	end
	-- Ramas y copa de flores rosas.
	local pinks = { Color3.fromRGB(255, 160, 200), Color3.fromRGB(255, 185, 215), Color3.fromRGB(250, 135, 185), Color3.fromRGB(255, 210, 230) }
	local rng = Random.new(Art.seed + 17)
	for i = 1, 6 do
		local a = math.rad(i * 60 + 20)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local tip = crown + dir * 17 + Vector3.new(0, 7, 0)
		deco("Rama", Enum.PartType.Cylinder, Vector3.new((tip - crown).Magnitude, 3, 3), CFrame.lookAt((crown + tip) / 2, tip) * CFrame.Angles(0, math.rad(90), 0), bark, Enum.Material.Wood, m)
		for j = 1, 3 do
			local ball = deco("Copa", Enum.PartType.Ball, Vector3.one * rng:NextNumber(13, 19), CFrame.new(tip + Vector3.new(rng:NextNumber(-5, 5), rng:NextNumber(-1, 6), rng:NextNumber(-5, 5))), pinks[(i + j) % #pinks + 1], Enum.Material.SmoothPlastic, m)
			ball.CastShadow = j == 1
		end
	end
	for j = 1, 5 do
		deco("Copa", Enum.PartType.Ball, Vector3.one * rng:NextNumber(18, 24), CFrame.new(crown + Vector3.new(rng:NextNumber(-6, 6), 12 + rng:NextNumber(0, 6), rng:NextNumber(-6, 6))), pinks[j % #pinks + 1], Enum.Material.SmoothPlastic, m).CastShadow = j == 1
	end
	-- Farolillos colgando de la copa.
	local gold = Color3.fromRGB(240, 190, 70)
	for i = 1, D.treeLanterns do
		local a = i * 2.39996
		local r = rng:NextNumber(10, 25)
		local anchor = crown + Vector3.new(math.cos(a) * r, rng:NextNumber(2, 6), math.sin(a) * r)
		local drop = rng:NextNumber(5, 9)
		local lantern = anchor - Vector3.new(0, drop, 0)
		rope(anchor, lantern + Vector3.new(0, 0.9, 0), 0.15, gold, m)
		local bulb = deco("Farolillo", Enum.PartType.Ball, Vector3.new(1.6, 1.9, 1.6), CFrame.new(lantern), if i % 3 == 0 then Color3.fromRGB(255, 120, 90) else Color3.fromRGB(255, 205, 120), Enum.Material.Neon, m)
		if i % 4 == 0 then
			local light = Instance.new("PointLight")
			light.Range = 16
			light.Brightness = 1.2
			light.Color = Color3.fromRGB(255, 190, 120)
			light.Parent = bulb
		end
	end
	-- Pétalos que caen.
	local petals = Instance.new("ParticleEmitter")
	petals.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	petals.Color = ColorSequence.new(Color3.fromRGB(255, 190, 220))
	petals.Size = NumberSequence.new(0.5)
	petals.Rate = D.petalRate
	petals.Lifetime = NumberRange.new(6, 9)
	petals.Speed = NumberRange.new(0.5, 1.5)
	petals.SpreadAngle = Vector2.new(180, 180)
	petals.Acceleration = Vector3.new(0.6, -1.6, 0.3)
	petals.LightEmission = 0.2
	local emitterPart = deco("Petalos", nil, Vector3.new(36, 1, 36), CFrame.new(crown + Vector3.new(0, 6, 0)), Color3.new(1, 1, 1), nil, m)
	emitterPart.Transparency = 1
	petals.Parent = emitterPart
end

local function buildHub(parent: Instance)
	local hub = model("Plaza", parent)
	local rng = Random.new(Art.seed + 3)
	-- Césped llano y empedrado.
	terrainDisc(Vector3.zero, HUB.lawnRadius + 12, 6, G, Enum.Material.Grass)
	terrainDisc(Vector3.zero, HUB.plazaRadius, 4, G, Enum.Material.Cobblestone)
	-- Estanque en anillo alrededor del árbol, con su borde de piedra y cuatro puentes.
	terrainDisc(Vector3.zero, HUB.pondOuter, 4, G - 0.8, Enum.Material.Water)
	terrainDisc(Vector3.zero, HUB.pondInner, 6, G + 1, Enum.Material.Cobblestone)
	for i = 0, 35 do
		local a = math.rad(i * 10)
		local p = Vector3.new(math.cos(a) * (HUB.pondOuter + 1), G + 0.4, math.sin(a) * (HUB.pondOuter + 1))
		part("Borde", nil, Vector3.new(3, 1.6, 4.6), CFrame.lookAt(p, Vector3.new(0, p.Y, 0)), Color3.fromRGB(170, 160, 150), Enum.Material.Slate, hub)
	end
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local from = dir * (HUB.pondInner - 1) + Vector3.new(0, G + 1.2, 0)
		local to = dir * (HUB.pondOuter + 3) + Vector3.new(0, G + 0.2, 0)
		plank("Puente", from, to, 6, WOOD, Enum.Material.WoodPlanks, hub)
		for _, side in { -1, 1 } do
			local s = dir:Cross(Vector3.yAxis) * side * 3.2
			deco("Barandilla", nil, Vector3.new(0.4, 0.4, (to - from).Magnitude), CFrame.lookAt((from + to) / 2 + s + Vector3.new(0, 2.6, 0), to + s + Vector3.new(0, 2.6, 0)), WOOD_DARK, Enum.Material.Wood, hub)
		end
	end
	giantTree(hub)
	-- Nenúfares en el estanque.
	for _ = 1, 10 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(HUB.pondInner + 1.5, HUB.pondOuter - 1.5)
		deco("Nenufar", Enum.PartType.Cylinder, Vector3.new(0.2, 2.6, 2.6), CFrame.new(math.cos(a) * r, G - 0.7, math.sin(a) * r) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 160, 70), nil, hub)
	end
	-- Farolas y bancos alrededor de la plaza.
	for i = 0, HUB.lampCount - 1 do
		local angle = HUB.avenueAngle + (i + 0.5) * 360 / HUB.lampCount
		lamp(ringPos(angle, HUB.plazaRadius - 3), hub)
		if i % 2 == 0 then
			local p = ringPos(angle + 360 / HUB.lampCount * 0.5, HUB.plazaRadius - 6)
			local cf = CFrame.lookAt(p, Vector3.new(0, G, 0))
			part("Asiento", nil, Vector3.new(6, 0.5, 2), cf * CFrame.new(0, 1.6, 0), WOOD, Enum.Material.WoodPlanks, hub)
			part("Respaldo", nil, Vector3.new(6, 2, 0.4), cf * CFrame.new(0, 2.8, 1), WOOD, Enum.Material.WoodPlanks, hub)
			for _, side in { -1, 1 } do
				deco("Pata", nil, Vector3.new(0.5, 1.5, 1.8), cf * CFrame.new(side * 2.6, 0.75, 0), Color3.fromRGB(60, 55, 65), Enum.Material.Metal, hub)
			end
		end
	end
	-- Parterres de flores entre los santuarios y árboles en flor.
	for i = 0, 5 do
		local angle = HUB.avenueAngle + 30 + i * 60
		if math.abs(((angle - HUB.avenueAngle + 180) % 360) - 180) > 20 then
			local p = ringPos(angle, Island.Plots.radius - 6)
			terrainDisc(p, 7, 4, G + 0.3, Enum.Material.Mud)
			for _ = 1, 4 do
				flowerPatch(rng, p + Vector3.new(rng:NextNumber(-4, 4), 0.3, rng:NextNumber(-4, 4)), hub)
			end
			roundTree(rng, ringPos(angle, Island.Plots.radius + 34), hub)
		end
	end
	-- Seto que rodea la plaza (con jardineras), con hueco en la avenida.
	local gap = math.deg((ZN.gateWidth + 4) / HUB.wallRadius) / 2
	local count = 64
	for i = 0, count - 1 do
		local a1 = HUB.avenueAngle + gap + (360 - 2 * gap) * i / count
		local a2 = HUB.avenueAngle + gap + (360 - 2 * gap) * (i + 1) / count
		local p1, p2 = ringPos(a1, HUB.wallRadius), ringPos(a2, HUB.wallRadius)
		local hedge = part("Seto", nil, Vector3.new(4.5, 6, (p2 - p1).Magnitude + 0.8), CFrame.lookAt((p1 + p2) / 2 + Vector3.new(0, 3, 0), p2 + Vector3.new(0, 3, 0)), if i % 2 == 0 then Color3.fromRGB(60, 150, 70) else Color3.fromRGB(70, 165, 75), Enum.Material.Grass, hub)
		hedge.CastShadow = false
		if i % 4 == 0 then
			for _ = 1, 2 do
				deco("Flor", Enum.PartType.Ball, Vector3.one * 0.8, hedge.CFrame * CFrame.new(rng:NextNumber(-1.6, 1.6), 3.1, rng:NextNumber(-2, 2)), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], nil, hub)
			end
		end
	end
	-- Avenida: farolas, banderines entre ellas y un poste con flechas a las zonas.
	local previousTops: { Vector3 }? = nil
	for radius = HUB.plazaRadius + 10, ZN.ringRadius - 30, 22 do
		local tops = {}
		for _, side in { -1, 1 } do
			local p = ringPos(HUB.avenueAngle + math.deg((HUB.avenueWidth / 2 + 3) / radius) * side, radius)
			lamp(p, hub)
			table.insert(tops, p + Vector3.new(0, 7.2, 0))
		end
		if previousTops then
			for k = 1, 2 do
				local a, b = previousTops[k], tops[k]
				rope(a, b, 0.12, Color3.fromRGB(255, 255, 255), hub)
				for f = 1, 5 do
					local p = a:Lerp(b, f / 6) - Vector3.new(0, math.sin(math.pi * f / 6) * 0.8 + 0.6, 0)
					local flag = deco("Banderin", nil, Vector3.new(0.1, 1.1, 1.1), CFrame.lookAt(p, p + (b - a)) * CFrame.Angles(math.rad(45), 0, 0), FLOWER_COLORS[(f + k) % #FLOWER_COLORS + 1], Enum.Material.Fabric, hub)
					flag.CastShadow = false
				end
			end
		end
		previousTops = tops
	end
	local signBase = ringPos(HUB.avenueAngle + 9, HUB.plazaRadius + 8)
	part("PosteCartel", Enum.PartType.Cylinder, Vector3.new(9, 0.8, 0.8), CFrame.new(signBase + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), WOOD_DARK, Enum.Material.Wood, hub)
	for i = 0, 2 do
		local arrow = part("Flecha", nil, Vector3.new(5, 1.1, 0.3), CFrame.new(signBase + Vector3.new(0, 7.8 - i * 1.5, 0)) * CFrame.Angles(0, math.rad(-HUB.avenueAngle + 90 + (i - 1) * 25), 0) * CFrame.new(2, 0, 0), Art.themeColors[VaultMath.theme(i + 1)], Enum.Material.WoodPlanks, hub)
		arrow.CastShadow = false
	end
end

-- ===== Accidentes del paisaje =====

local function buildVolcano(parent: Instance)
	local V = LM.volcano
	local m = model("Volcan", parent)
	local center = ringPos(V.angle, V.radius)
	local tiers = math.floor(V.height / 4) -- una capa por vóxel de terreno: ladera suave
	for i = 0, tiers - 1 do
		local t = i / tiers
		local radius = V.baseRadius * (1 - t) ^ 1.15 + V.craterRadius
		local top = G + V.height * (t + 1 / tiers)
		terrainDisc(center, radius, V.height / tiers + 8, top, if i > tiers - 5 then Enum.Material.Rock else Enum.Material.Basalt)
	end
	local summit = G + V.height
	-- Cráter con lava.
	terrain:FillCylinder(CFrame.new(center.X, summit + 2, center.Z), 16, V.craterRadius, Enum.Material.Air)
	terrainDisc(center, V.craterRadius, 6, summit - 6, Enum.Material.CrackedLava)
	local lava = deco("Lava", Enum.PartType.Cylinder, Vector3.new(1, V.craterRadius * 1.9, V.craterRadius * 1.9), CFrame.new(center.X, summit - 5.4, center.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 110, 20), Enum.Material.Neon, m)
	local glow = Instance.new("PointLight")
	glow.Range = 60
	glow.Brightness = 3
	glow.Color = Color3.fromRGB(255, 120, 40)
	glow.Parent = lava
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(90, 85, 90))
	smoke.Size = NumberSequence.new(10, 30)
	smoke.Transparency = NumberSequence.new(0.3, 1)
	smoke.Rate = Art.volcanoSmokeRate
	smoke.Lifetime = NumberRange.new(10, 14)
	smoke.Speed = NumberRange.new(5, 9)
	smoke.Parent = lava
	-- Río de lava: baja serpenteando hacia el mar, por fuera de la isla.
	local out = (center - Vector3.new(0, center.Y, 0)).Unit
	local side = out:Cross(Vector3.yAxis)
	local previous: Vector3? = nil
	for d = V.craterRadius, V.baseRadius + V.craterRadius + 10, 7 do
		local t = (d - V.craterRadius) / V.baseRadius
		local height = V.height * math.max(0, 1 - ((d - V.craterRadius) / V.baseRadius) ^ (1 / 1.15))
		local p = center + out * d + side * math.sin(t * 7) * 9 + Vector3.new(0, G + height + 0.6 - center.Y, 0)
		if previous then
			local piece = deco("Rio", nil, Vector3.new(6 + t * 4, 1, (p - previous).Magnitude + 1.5), CFrame.lookAt((previous + p) / 2, p), Color3.fromRGB(255, 100 + math.floor(t * 40), 20), Enum.Material.Neon, m)
			if math.floor(d) % 35 < 7 then
				local light = Instance.new("PointLight")
				light.Range = 24
				light.Brightness = 1.5
				light.Color = Color3.fromRGB(255, 120, 40)
				light.Parent = piece
			end
		end
		previous = p
	end
end

local function boat(rng: Random, position: Vector3, color: Color3, parent: Instance)
	local m = model("Barca", parent)
	local cf = CFrame.new(position) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	ellipsoid(part("Casco", nil, Vector3.new(5, 3, 14), cf, color, Enum.Material.SmoothPlastic, m))
	part("Cubierta", nil, Vector3.new(4, 0.4, 11), cf * CFrame.new(0, 0.9, 0), WOOD, Enum.Material.WoodPlanks, m)
	part("Mastil", Enum.PartType.Cylinder, Vector3.new(11, 0.5, 0.5), cf * CFrame.new(0, 6, -1) * CFrame.Angles(0, 0, math.rad(90)), WOOD_DARK, Enum.Material.Wood, m)
	deco("Vela", nil, Vector3.new(0.2, 7, 5), cf * CFrame.new(0, 6.5, 1.6) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(250, 245, 230), Enum.Material.Fabric, m)
end

local function buildCoastDetails(parent: Instance)
	local rng = Random.new(Art.seed + 11)
	local m = model("Costa", parent)
	-- Rocas en la orilla.
	for _ = 1, D.coastRocks do
		local angle = rng:NextNumber(0, 360)
		local p = ringPos(angle, coastAt(angle) + rng:NextNumber(-6, 14), G - 3)
		terrain:FillBall(p, rng:NextNumber(3, 7), if rng:NextNumber() < 0.5 then Enum.Material.Rock else Enum.Material.Sandstone)
	end
	-- Faro en la punta entre la zona 7 y la 1.
	local lh = ringPos(LM.lighthouse.angle, coastAt(LM.lighthouse.angle) - 4)
	terrain:FillBall(lh + Vector3.new(0, -2, 0), 16, Enum.Material.Rock)
	local base = lh + Vector3.new(0, 8, 0)
	for i = 0, 6 do
		local stripe = part("Torre", Enum.PartType.Cylinder, Vector3.new(4, 9 - i * 0.5, 9 - i * 0.5), CFrame.new(base + Vector3.new(0, 2 + i * 4, 0)) * CFrame.Angles(0, 0, math.rad(90)), if i % 2 == 0 then Color3.fromRGB(240, 70, 70) else Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic, m)
		stripe.CastShadow = true
	end
	part("Balcon", Enum.PartType.Cylinder, Vector3.new(0.8, 9, 9), CFrame.new(base + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 55, 65), Enum.Material.Metal, m)
	local beacon = deco("Luz", Enum.PartType.Ball, Vector3.one * 4.5, CFrame.new(base + Vector3.new(0, 33, 0)), Color3.fromRGB(255, 240, 160), Enum.Material.Neon, m)
	local light = Instance.new("PointLight")
	light.Range = 50
	light.Brightness = 2
	light.Color = Color3.fromRGB(255, 230, 160)
	light.Parent = beacon
	ellipsoid(part("Tejado", nil, Vector3.new(6, 5, 6), CFrame.new(base + Vector3.new(0, 36.5, 0)), Color3.fromRGB(240, 70, 70), Enum.Material.SmoothPlastic, m))
	-- Muelle con barcas en la playa (zona 1).
	local dockAngle = LM.dock.angle
	local start = ringPos(dockAngle, coastAt(dockAngle) - 14, G + 0.2)
	local out = Vector3.new(math.cos(math.rad(dockAngle)), 0, math.sin(math.rad(dockAngle)))
	for i = 0, 9 do
		local p = start + out * (i * 4)
		part("Tablon", nil, Vector3.new(8, 0.6, 4.2), CFrame.lookAt(p, p + out), if i % 2 == 0 then WOOD else WOOD_DARK, Enum.Material.WoodPlanks, m)
		if i % 3 == 0 then
			for _, side in { -1, 1 } do
				deco("Pilote", Enum.PartType.Cylinder, Vector3.new(7, 0.9, 0.9), CFrame.new(p + out:Cross(Vector3.yAxis) * side * 4 + Vector3.new(0, -1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), WOOD_DARK, Enum.Material.Wood, m)
			end
		end
	end
	local boatColors = { Color3.fromRGB(230, 80, 70), Color3.fromRGB(70, 150, 230), Color3.fromRGB(250, 200, 60) }
	for i, color in boatColors do
		local p = start + out * (14 + i * 9) + out:Cross(Vector3.yAxis) * ((i % 2) * 2 - 1) * 10 + Vector3.new(0, -2.6, 0)
		boat(rng, p, color, m)
	end
end


-- ===== Puntos de referencia de cada zona (se ven desde la plaza) =====

local function clockTower(position: Vector3, parent: Instance)
	local m = model("TorreReloj", parent)
	local brick = Color3.fromRGB(170, 115, 85)
	local trim = Color3.fromRGB(225, 200, 150)
	local base = CFrame.lookAt(position, Vector3.new(0, position.Y, 0)) -- la esfera mira a la plaza
	part("Base", nil, Vector3.new(16, 4, 16), base * CFrame.new(0, 2, 0), Color3.fromRGB(150, 140, 130), Enum.Material.Cobblestone, m)
	part("Torre", nil, Vector3.new(12, 44, 12), base * CFrame.new(0, 26, 0), brick, Enum.Material.Brick, m)
	for _, y in { 12, 26, 40 } do
		deco("Cornisa", nil, Vector3.new(13.2, 1, 13.2), base * CFrame.new(0, y, 0), trim, Enum.Material.SmoothPlastic, m)
	end
	part("Campanario", nil, Vector3.new(13, 10, 13), base * CFrame.new(0, 53, 0), trim, Enum.Material.SmoothPlastic, m)
	part("Tejado", nil, Vector3.new(14, 10, 14), base * CFrame.new(0, 62.5, 0) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(90, 70, 120), Enum.Material.Slate, m)
	ellipsoid(deco("Punta", nil, Vector3.new(3, 8, 3), base * CFrame.new(0, 70, 0), Art.colors.gold, Enum.Material.Metal, m))
	for _, side in { -1, 1 } do
		local face = base * CFrame.Angles(0, if side == 1 then 0 else math.pi, 0) * CFrame.new(0, 53, -6.6)
		deco("Esfera", Enum.PartType.Cylinder, Vector3.new(0.6, 9, 9), face * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(250, 245, 230), nil, m)
		deco("Aro", Enum.PartType.Cylinder, Vector3.new(0.5, 9.8, 9.8), face * CFrame.new(0, 0, 0.1) * CFrame.Angles(0, math.rad(90), 0), Art.colors.gold, Enum.Material.Metal, m)
		deco("Aguja", nil, Vector3.new(0.5, 3.6, 0.3), face * CFrame.new(0, 1.6, -0.4), Color3.fromRGB(30, 30, 35), nil, m)
		deco("Aguja", nil, Vector3.new(2.6, 0.5, 0.3), face * CFrame.Angles(0, 0, math.rad(30)) * CFrame.new(1.1, 0, -0.4), Color3.fromRGB(30, 30, 35), nil, m)
	end
	local bell = deco("Campana", Enum.PartType.Ball, Vector3.one * 5, base * CFrame.new(0, 52, 0), Art.colors.gold, Enum.Material.Metal, m)
	bell.CastShadow = false
	-- Engranajes gigantes a los pies de la torre.
	local rng = Random.new(Art.seed + 31)
	for i = 1, 3 do
		bigGear(rng, position + Vector3.new(math.cos(i * 2.1) * 13, 0, math.sin(i * 2.1) * 13), m)
	end
end

local function titanSword(position: Vector3, parent: Instance)
	local m = model("EspadaTitan", parent)
	terrain:FillBall(position + Vector3.new(0, 2, 0), 14, Enum.Material.Rock)
	terrain:FillBall(position + Vector3.new(0, 8, 0), 9, Enum.Material.LeafyGrass)
	local cf = CFrame.new(position + Vector3.new(0, 14, 0)) * CFrame.Angles(math.rad(8), math.rad(30), math.rad(-6))
	part("Hoja", nil, Vector3.new(7, 40, 1.6), cf * CFrame.new(0, 18, 0), Color3.fromRGB(190, 200, 210), Enum.Material.Metal, m)
	part("Filo", nil, Vector3.new(7.4, 40, 0.6), cf * CFrame.new(0, 18, 0), Color3.fromRGB(230, 235, 245), Enum.Material.Metal, m)
	part("Guarda", nil, Vector3.new(20, 3, 3.4), cf * CFrame.new(0, 39.5, 0), Color3.fromRGB(150, 120, 60), Enum.Material.Metal, m)
	part("Puño", Enum.PartType.Cylinder, Vector3.new(11, 2.6, 2.6), cf * CFrame.new(0, 46.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 70, 40), Enum.Material.Fabric, m)
	part("Pomo", Enum.PartType.Ball, Vector3.one * 4.6, cf * CFrame.new(0, 53, 0), Color3.fromRGB(150, 120, 60), Enum.Material.Metal, m)
	local gem = deco("Gema", Enum.PartType.Ball, Vector3.one * 2.4, cf * CFrame.new(0, 39.5, -1.6), Color3.fromRGB(80, 220, 160), Enum.Material.Neon, m)
	local light = Instance.new("PointLight")
	light.Range = 20
	light.Color = Color3.fromRGB(80, 220, 160)
	light.Parent = gem
	-- Hiedra que trepa por la hoja.
	for i = 1, 6 do
		deco("Hiedra", Enum.PartType.Ball, Vector3.one * (3 - i * 0.3), cf * CFrame.new(math.sin(i * 1.7) * 2.6, 4 + i * 3.4, -1), Color3.fromRGB(70, 150, 70), Enum.Material.Grass, m)
	end
end

local function lifeguardTower(position: Vector3, parent: Instance)
	local m = model("Socorrista", parent)
	local base = CFrame.lookAt(position, Vector3.new(position.X * 2, position.Y, position.Z * 2)) -- mira al mar
	for _, x in { -2.5, 2.5 } do
		for _, z in { -2.5, 2.5 } do
			part("Pata", nil, Vector3.new(0.6, 9, 0.6), base * CFrame.new(x, 4.5, z) * CFrame.Angles(math.rad(z * 1.2), 0, math.rad(-x * 1.2)), Color3.fromRGB(250, 250, 250), Enum.Material.WoodPlanks, m)
		end
	end
	part("Suelo", nil, Vector3.new(7, 0.6, 7), base * CFrame.new(0, 9, 0), WOOD, Enum.Material.WoodPlanks, m)
	part("Caseta", nil, Vector3.new(6, 4.5, 6), base * CFrame.new(0, 11.5, 0.5), Color3.fromRGB(240, 70, 70), Enum.Material.SmoothPlastic, m)
	part("Techo", nil, Vector3.new(7.4, 0.6, 7.4), base * CFrame.new(0, 14, 0.5), Color3.fromRGB(250, 250, 250), Enum.Material.SmoothPlastic, m)
	deco("Ventana", nil, Vector3.new(4.2, 2, 0.2), base * CFrame.new(0, 12, -2.6), Color3.fromRGB(150, 210, 240), Enum.Material.Glass, m)
	for i = 0, 5 do
		part("Escalon", nil, Vector3.new(3, 0.4, 1.2), base * CFrame.new(0, 1 + i * 1.4, 4 + i * 0.9), WOOD, Enum.Material.WoodPlanks, m)
	end
	local ring = deco("Flotador", Enum.PartType.Cylinder, Vector3.new(0.8, 3, 3), base * CFrame.new(3.4, 7.5, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 120, 60), nil, m)
	ring.CastShadow = false
end

local function boardwalk(rng: Random, n: number, parent: Instance)
	local m = model("Pasarela", parent)
	local start = sectorPoint(rng, n, ZN.ringRadius + 18, ZN.ringRadius + 30, true)
	local heading = rng:NextNumber(0, math.pi * 2)
	local p = start
	for i = 1, 14 do
		heading += rng:NextNumber(-0.35, 0.35)
		local nextP = p + Vector3.new(math.cos(heading), 0, math.sin(heading)) * 4.2
		if Layout.flatDistance(nextP) > COAST.radius - 30 or Layout.flatDistance(nextP) < HUB.wallRadius + 20 then
			heading += math.pi * 0.5
			nextP = p + Vector3.new(math.cos(heading), 0, math.sin(heading)) * 4.2
		end
		part("Tabla", nil, Vector3.new(5, 0.5, 4.4), CFrame.lookAt(p + Vector3.new(0, 1.4, 0), nextP + Vector3.new(0, 1.4, 0)), if i % 2 == 0 then WOOD else WOOD_DARK, Enum.Material.WoodPlanks, m)
		if i % 3 == 0 then
			for _, side in { -1, 1 } do
				local off = (nextP - p).Unit:Cross(Vector3.yAxis) * side * 2.7
				deco("Poste", Enum.PartType.Cylinder, Vector3.new(4, 0.6, 0.6), CFrame.new(p + off + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), WOOD_DARK, Enum.Material.Wood, m)
				local lantern = deco("Farolillo", Enum.PartType.Ball, Vector3.one * 0.9, CFrame.new(p + off + Vector3.new(0, 3.3, 0)), Color3.fromRGB(120, 255, 230), Enum.Material.Neon, m)
				lantern.CastShadow = false
			end
		end
		terrainDisc(p, 5, 4, G - 0.4, Enum.Material.Water)
		p = nextP
	end
end

-- Nubes grandes alrededor de la isla (decorado del cielo).
local function skyClouds(parent: Instance)
	local rng = Random.new(Art.seed + 77)
	local m = model("NubesCielo", parent)
	for i = 1, D.skyClouds do
		local angle = i / D.skyClouds * 360 + rng:NextNumber(-10, 10)
		local p = ringPos(angle, rng:NextNumber(COAST.radius * 0.6, COAST.radius * 1.5), G + rng:NextNumber(110, 170))
		for k = 1, 3 do
			cloudPuff(rng, p + Vector3.new(rng:NextNumber(-14, 14), rng:NextNumber(-3, 3), rng:NextNumber(-14, 14)), rng:NextNumber(10, 16) * (1 - k * 0.15), m)
		end
	end
end

-- ===== Decorado de cada zona =====

-- Radio de la isla flotante de la zona n (cubre todo su rectángulo).
local function islandRadius(n: number): number
	local size = VaultMath.size(n)
	return math.sqrt(size.X * size.X + size.Y * size.Y) / 2 + 6
end

-- Punto del borde de la isla flotante n, por delante (`side` = 1) o por detrás (-1), a su altura.
local function islandRim(n: number, side: number): Vector3
	return (VaultMath.frame(n) * CFrame.new(0, 0, side * (islandRadius(n) + 3))).Position
end

-- Isla flotante: base de roca, césped encima y nubes alrededor del borde.
local function floatingIsland(rng: Random, n: number, parent: Instance)
	local cf = VaultMath.frame(n)
	local theme = VaultMath.theme(n)
	local radius = islandRadius(n)
	local top = cf.Position.Y
	-- Panza de roca en cono (bolas cada vez más pequeñas hacia abajo) y césped encima.
	-- Panza de roca: discos cada vez más pequeños hacia abajo (un cono invertido), con salientes.
	local depth = radius * D.islandDepth
	local layers = math.floor(depth / 4)
	for i = 0, layers do
		local t = i / layers
		local r = radius * (1 - t) ^ 0.75 + 4
		local drift = Vector3.new(math.sin(t * 5 + n) * radius * 0.06, 0, math.cos(t * 4 + n) * radius * 0.06)
		local y = top - 6 - i * 4
		terrainDisc(Vector3.new(cf.Position.X, 0, cf.Position.Z) + drift, r, 6, y, if (i // 3) % 2 == 0 then Enum.Material.Rock else Enum.Material.Slate)
	end
	for _ = 1, 4 do
		local a = rng:NextNumber(0, math.pi * 2)
		local p = cf.Position + Vector3.new(math.cos(a) * radius * 0.55, -depth * rng:NextNumber(0.35, 0.6), math.sin(a) * radius * 0.55)
		terrain:FillBall(p, radius * rng:NextNumber(0.12, 0.18), Enum.Material.Rock)
	end
	terrain:FillCylinder(CFrame.new(cf.Position.X, top - T.surfaceOffset - 6, cf.Position.Z), 12, radius, Enum.Material.Ground)
	terrain:FillCylinder(CFrame.new(cf.Position.X, top - T.surfaceOffset - 1.5, cf.Position.Z), 3, radius - 2, if theme == "SantuarioEclipse" then Enum.Material.Basalt else Enum.Material.Grass)
	-- Manchas del material de su temática.
	for _ = 1, 8 do
		local p = islandPoint(rng, n)
		terrainDisc(p, rng:NextNumber(8, 16), 3, top, SECTOR_GROUND[theme] or Enum.Material.Grass)
	end
	for i = 1, D.islandClouds do
		local a = i / D.islandClouds * math.pi * 2
		local p = cf.Position + Vector3.new(math.cos(a) * (radius + 2), -3 + rng:NextNumber(-1, 1), math.sin(a) * (radius + 2))
		cloudPuff(rng, p, rng:NextNumber(5, 8), parent)
	end
end

local function decorateTheme(rng: Random, n: number, parent: Instance)
	local theme = VaultMath.theme(n)
	local floating = VaultMath.isFloating(n)
	local scale = if floating then D.floatingDecorScale else 1
	local function where(edge: boolean?): Vector3
		if floating then
			return islandPoint(rng, n, edge)
		end
		return sectorPoint(rng, n, HUB.wallRadius + 14, COAST.radius - 30, true)
	end
	local function count(base: number): number
		return math.max(1, math.floor(base * scale + 0.5))
	end
	if theme == "PlayaRara" then
		for _ = 1, count(D.beachPalms) do
			palm(rng, where(true), parent)
		end
		local colors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(90, 170, 255), Color3.fromRGB(255, 210, 60), Color3.fromRGB(120, 220, 120) }
		for i = 1, count(D.beachUmbrellas) do
			umbrella(rng, where(true), colors[(i - 1) % #colors + 1], parent)
		end
		for _ = 1, count(D.beachRocks) do
			local p = where(true)
			terrain:FillBall(p + Vector3.new(0, 0.5, 0), rng:NextNumber(1.5, 3.5), Enum.Material.Sandstone)
		end
		for _ = 1, count(3) do
			local p = where(true)
			terrainDisc(p, rng:NextNumber(5, 8), 4, p.Y - 0.5, Enum.Material.Water)
		end
		if not floating then
			lifeguardTower(ringPos(sectorCenterAngle(n) - 10, coastAt(sectorCenterAngle(n) - 10) - 22), parent)
		end
	elseif theme == "BosqueRuidoso" then
		for i = 1, count(D.forestTrees) do
			if i % 3 == 0 then
				pine(where(), parent)
			else
				roundTree(rng, where(), parent)
			end
		end
		for _ = 1, count(D.forestBushes) do
			bush(rng, where(), parent)
		end
		for _ = 1, count(D.forestMushrooms) do
			bigMushroom(rng, where(), if rng:NextNumber() < 0.5 then Color3.fromRGB(230, 70, 70) else Color3.fromRGB(225, 60, 150), parent)
		end
		for _ = 1, count(D.flowers) do
			flowerPatch(rng, where(), parent)
		end
		for _ = 1, count(2) do
			local p = where()
			terrainDisc(p, 10, 4, p.Y, Enum.Material.Mud)
			terrainDisc(p, 8, 3, p.Y - 0.3, Enum.Material.Water)
			reeds(rng, p + Vector3.new(8, 0, 0), parent)
		end
	elseif theme == "VolcanTimido" then
		for _ = 1, count(D.volcanoRocks) do
			local p = where()
			terrain:FillBall(p + Vector3.new(0, 1, 0), rng:NextNumber(2.5, 6), if rng:NextNumber() < 0.6 then Enum.Material.Basalt else Enum.Material.Rock)
		end
		for _ = 1, count(D.lavaPools) do
			local p = where()
			terrainDisc(p, 6, 4, p.Y, Enum.Material.CrackedLava)
			local pool = deco("Charco", Enum.PartType.Cylinder, Vector3.new(0.4, 7, 7), CFrame.new(p + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 110, 20), Enum.Material.Neon, parent)
			local light = Instance.new("PointLight")
			light.Range = 14
			light.Color = Color3.fromRGB(255, 120, 40)
			light.Parent = pool
		end
		for _ = 1, count(6) do
			pine(where(), parent)
		end
	elseif theme == "NubePegajosa" then
		for _ = 1, count(D.cloudTrees) do
			roundTree(rng, where(true), parent)
		end
		for _ = 1, count(D.flowers) do
			flowerPatch(rng, where(), parent)
		end
		for _ = 1, count(4) do
			crystals(rng, where(true), parent)
		end
		rainbow(VaultMath.frame(n).Position + Vector3.new(0, 4, 0), parent)
	elseif theme == "PantanoCristal" then
		if not floating then
			boardwalk(rng, n, parent)
		end
		for _ = 1, count(D.swampPools) do
			local p = where()
			terrainDisc(p, rng:NextNumber(7, 12), 4, p.Y - 0.4, Enum.Material.Water)
			reeds(rng, p + Vector3.new(rng:NextNumber(-8, 8), 0, rng:NextNumber(-8, 8)), parent)
		end
		for _ = 1, count(D.swampCrystals) do
			swampCrystal(rng, where(), parent)
		end
		for _ = 1, count(8) do
			crystals(rng, where(), parent)
		end
		for _ = 1, count(6) do
			roundTree(rng, where(), parent)
		end
	elseif theme == "RelojeriaAbandonada" then
		if not floating then
			clockTower(ringPos(sectorCenterAngle(n), ZN.ringRadius + ZN.width / 2 + 16), parent)
		end
		for _ = 1, count(D.gears) do
			bigGear(rng, where(), parent)
		end
		for _ = 1, count(D.clocks) do
			brokenClock(rng, where(), parent)
		end
		for _ = 1, count(D.pillars) do
			ruinPillar(rng, where(), parent)
		end
		for _ = 1, count(5) do
			lamp(where(), parent)
		end
	elseif theme == "ValleTitanes" then
		if not floating then
			titanSword(ringPos(sectorCenterAngle(n) + 8, ZN.ringRadius + ZN.width / 2 + 14), parent)
		end
		for _ = 1, count(D.titanPieces) do
			titanPiece(rng, where(), parent)
		end
		for _ = 1, count(D.pillars) do
			ruinPillar(rng, where(), parent)
		end
		for _ = 1, count(12) do
			local p = where()
			terrain:FillBall(p + Vector3.new(0, 1, 0), rng:NextNumber(3, 8), Enum.Material.Rock)
		end
		for _ = 1, count(10) do
			pine(where(), parent)
		end
	elseif theme == "ObservatorioAstral" then
		observatory(VaultMath.point(n, 0.3, -0.25), parent)
		for _ = 1, count(D.starOrbs) do
			starOrb(rng, where(true), parent)
		end
		for _ = 1, count(5) do
			crystals(rng, where(true), parent)
		end
	elseif theme == "SantuarioEclipse" then
		for _ = 1, count(D.obelisks) do
			obelisk(rng, where(true), parent)
		end
		eclipse(VaultMath.frame(n).Position + Vector3.new(0, 70, 0), parent)
	end
end

-- Zona 4: isla de nubes sobre el sector, con escaleras, cascada y lago.
local function cloudZoneExtras(rng: Random, n: number, parent: Instance)
	local m = model("Cascada", parent)
	local cf = VaultMath.frame(n)
	local size = VaultMath.size(n)
	-- Escalera de subida (cerca del arco de la zona) y de bajada (hacia el arco de la siguiente).
	local gateIn = VaultMath.gate(n).Position
	local gateOut = VaultMath.gate(n + 1).Position
	local entry = islandRim(n, 1)
	local exit = islandRim(n, -1)
	switchback(gateIn + (entry - gateIn) * Vector3.new(0.25, 0, 0.25) + Vector3.new(0, 0.3, 0), entry, m)
	switchback(gateOut + (exit - gateOut) * Vector3.new(0.25, 0, 0.25) + Vector3.new(0, 0.3, 0), exit, m)
	-- Cascada por el lado de fuera de la isla, hasta un lago.
	local edge = cf * CFrame.new(-(size.X / 2 + 10), 0, 0)
	local fallTop = edge.Position + Vector3.new(0, -2, 0)
	local fallBottom = Vector3.new(fallTop.X, G, fallTop.Z)
	terrainDisc(fallBottom, 30, 6, G - 0.8, Enum.Material.Water)
	terrainDisc(fallBottom, 34, 4, G - 0.2, Enum.Material.Sand)
	terrainDisc(fallBottom, 28, 6, G - 0.8, Enum.Material.Water)
	local water = deco("Agua", nil, Vector3.new(16, fallTop.Y - fallBottom.Y, 3), CFrame.lookAt((fallTop + fallBottom) / 2, (fallTop + fallBottom) / 2 + cf.RightVector), Color3.fromRGB(170, 220, 255), Enum.Material.Glass, m)
	water.Transparency = 0.35
	local mist = Instance.new("ParticleEmitter")
	mist.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	mist.Size = NumberSequence.new(4, 10)
	mist.Transparency = NumberSequence.new(0.4, 1)
	mist.Rate = 12
	mist.Lifetime = NumberRange.new(2, 3)
	mist.Speed = NumberRange.new(3, 6)
	mist.SpreadAngle = Vector2.new(60, 60)
	local foot = deco("Espuma", nil, Vector3.new(14, 1, 14), CFrame.new(fallBottom + Vector3.new(0, 0.5, 0)), Color3.new(1, 1, 1), nil, m)
	foot.Transparency = 1
	mist.Parent = foot
	for i = 1, 4 do
		cloudPuff(rng, fallBottom + Vector3.new(rng:NextNumber(-8, 8), 1, rng:NextNumber(-8, 8)), 3 + i * 0.5, m)
	end
end

function WorldArt.BuildVault(n: number)
	local rng = Random.new(Art.seed + n * 7919) -- cada zona sale siempre igual
	local m = model("DecoradoZona" .. n)
	if n <= 7 then
		-- El suelo de los sectores del anillo ya está (WorldArt.Start); aquí, la isla de la zona 4.
		if n == 4 then
			floatingIsland(rng, n, m)
			cloudZoneExtras(rng, n, m)
		end
		decorateTheme(rng, n, m)
		return
	end
	floatingIsland(rng, n, m)
	decorateTheme(rng, n, m)
	-- Puente desde el arco (en la costa de la zona 7 o al final de la isla anterior) hasta esta isla.
	local gate = VaultMath.gate(n).Position
	local rim = islandRim(n, 1) + Vector3.new(0, 0.3, 0)
	bridge(gate + (rim - gate).Unit * 2, rim, m)
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
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.4
	bloom.Parent = Lighting

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.05
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting
end

local function setupTerrainLook()
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(105, 190, 75))
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(70, 150, 60))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(240, 215, 150))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(140, 132, 140))
	terrain:SetMaterialColor(Enum.Material.Basalt, Color3.fromRGB(75, 55, 55))
	terrain:SetMaterialColor(Enum.Material.CrackedLava, Color3.fromRGB(230, 110, 50))
	terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(85, 110, 80))
	terrain:SetMaterialColor(Enum.Material.Slate, Color3.fromRGB(125, 122, 140))
	terrain:SetMaterialColor(Enum.Material.Brick, Color3.fromRGB(170, 120, 90))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(215, 185, 130))
	terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(245, 240, 255))
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(190, 180, 168))
	terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(205, 170, 120))
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
	local spawn = Layout.spawn()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Position = Vector3.new(spawn.X, G + descendant.Size.Y / 2, spawn.Z)
		end
	end

	terrain:Clear()
	setupLighting()
	setupTerrainLook()

	local rng = Random.new(Art.seed)
	local island = model("Isla")
	buildSea()
	buildIslandGround()
	for n = 1, 7 do
		sectorGround(rng, n)
	end
	buildHub(island)
	buildPaths()
	for k = 1, 7 do
		ridge(rng, k, island)
	end
	buildVolcano(island)
	buildCoastDetails(island)
	skyClouds(island)
end

return WorldArt
