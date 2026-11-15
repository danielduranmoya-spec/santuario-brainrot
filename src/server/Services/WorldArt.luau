--!strict
-- Escenario del juego (versión 2), generado por código al arrancar el servidor:
--   * Terrain: isla de hierba con playa de arena, mar alrededor, anillo de montañas nevadas en el
--     borde, suelo de cada zona con su material, caminos, estanque y rocas (las rocas de Terrain
--     no cuentan como piezas: son baratas en móvil).
--   * Piezas low-poly: palmeras, sombrillas, árboles redondos y pinos, arbustos y flores, setas
--     gigantes, volcán con lava y humo, nubes, cristales y arcoíris en la Nube Pegajosa, farolillos.
--   * Iluminación, nubes del cielo y post-procesado moderado.
-- Todo es decorado: no cambia la lógica de zonas, barreras ni apariciones. Los números están en
-- Config/Art y Config/Gameplay.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Art = require(Config:WaitForChild("Art"))

local WorldArt = {}

local T = Art.terrain
local terrain = Workspace.Terrain
local rng = Random.new(Art.seed) -- semilla fija: el mapa sale siempre igual
local folder: Folder

local BEACH = Gameplay.Zones.PlayaRara.center
local S = Gameplay.Sanctuary

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

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = folder
	return m
end

local function ground(position: Vector3): CFrame
	return CFrame.new(position.X, Gameplay.GroundY, position.Z)
end

local function flat(position: Vector3): Vector3
	return Vector3.new(position.X, 0, position.Z)
end

-- Centros de los santuarios (mismo cálculo que Plots) para no poner decorado encima.
local plotCenters: { Vector3 } = {}
for i = 1, S.plotCount do
	local angle = (i - 1) / S.plotCount * math.pi * 2
	table.insert(plotCenters, Vector3.new(BEACH.X + math.cos(angle) * S.ringRadius, 0, BEACH.Z + math.sin(angle) * S.ringRadius))
end

-- Segmentos de los caminos (de la playa a cada puerta).
type Segment = { from: Vector3, to: Vector3 }
local pathSegments: { Segment } = {}

local function distanceToSegment(point: Vector3, segment: Segment): number
	local ab = segment.to - segment.from
	local t = math.clamp((point - segment.from):Dot(ab) / ab:Dot(ab), 0, 1)
	return (point - (segment.from + ab * t)).Magnitude
end

-- ¿Se puede poner decorado aquí sin estorbar (santuarios, caminos, punto de aparición)?
local function isFree(point: Vector3, margin: number): boolean
	local here = flat(point)
	if (here - flat(BEACH)).Magnitude < 14 then
		return false
	end
	for _, center in plotCenters do
		if (here - center).Magnitude < S.plotSize * 0.75 + margin then
			return false
		end
	end
	for _, segment in pathSegments do
		if distanceToSegment(here, segment) < Art.pathWidth / 2 + 2 + margin then
			return false
		end
	end
	return here.Magnitude < Art.boundary.radius - 8
end

local function randomPoint(center: Vector3, minRadius: number, maxRadius: number): Vector3
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(minRadius, maxRadius)
	return Vector3.new(center.X + math.cos(angle) * radius, Gameplay.GroundY, center.Z + math.sin(angle) * radius)
end

-- Busca un sitio libre (o nil si no lo encuentra en unos intentos).
local function freePoint(center: Vector3, minRadius: number, maxRadius: number, margin: number): Vector3?
	for _ = 1, 12 do
		local point = randomPoint(center, minRadius, maxRadius)
		if isFree(point, margin) then
			return point
		end
	end
	return nil
end

-- Disco de Terrain con la cara de arriba a la altura `topY`.
-- (El terreno se dibuja en celdas de 4 studs y su superficie queda algo más alta de lo pedido:
-- surfaceOffset lo compensa para que el suelo quede a la altura de Gameplay.GroundY.)
local function terrainDisc(center: Vector3, radius: number, height: number, topY: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(center.X, topY - T.surfaceOffset - height / 2, center.Z), height, radius, material)
end

-- ===== Terreno =====

local function buildTerrain()
	terrain:Clear()
	-- Mar con fondo de arena.
	terrainDisc(BEACH, T.seaRadius, T.seaDepth, T.waterLevel, Enum.Material.Water)
	terrainDisc(BEACH, T.seaRadius, 4, T.waterLevel - T.seaDepth + 4, Enum.Material.Sand)
	-- Isla: orilla de arena y meseta de hierba.
	terrainDisc(BEACH, T.islandRadius + T.shoreWidth, T.islandDepth, Gameplay.GroundY - 1, Enum.Material.Sand)
	terrainDisc(BEACH, T.islandRadius, T.islandDepth, Gameplay.GroundY, Enum.Material.Grass)

	-- Suelo de cada zona.
	for zoneId, area in Gameplay.Zones do
		local material = Art.zoneMaterials[zoneId]
		if material then
			terrainDisc(area.center, area.radius + 2, 4, Gameplay.GroundY, material)
		end
	end
	-- Manchas de lava en el volcán y de hielo en la nube.
	for _ = 1, 6 do
		local spot = randomPoint(Gameplay.Zones.VolcanTimido.center, 8, 40)
		terrainDisc(spot, rng:NextNumber(3, 6), 4, Gameplay.GroundY, Enum.Material.CrackedLava)
	end
	for _ = 1, 5 do
		local spot = randomPoint(Gameplay.Zones.NubePegajosa.center, 8, 40)
		terrainDisc(spot, rng:NextNumber(3, 6), 4, Gameplay.GroundY, Enum.Material.Glacier)
	end

	-- Anillo de montañas nevadas en el borde (con el muro invisible por dentro: ver Boundary).
	for i = 1, T.mountainCount do
		local angle = (i / T.mountainCount) * math.pi * 2 + rng:NextNumber(-0.05, 0.05)
		local radius = rng:NextNumber(T.mountainSize.min, T.mountainSize.max)
		local distance = T.mountainRadius + rng:NextNumber(-4, 8)
		local center = Vector3.new(BEACH.X + math.cos(angle) * distance, Gameplay.GroundY - radius * 0.2, BEACH.Z + math.sin(angle) * distance)
		terrain:FillBall(center, radius, Enum.Material.Rock)
		terrain:FillBall(center + Vector3.new(0, radius * 0.45, 0), radius * 0.5, Enum.Material.Snow)
	end

	-- Estanque en el bosque.
	local forest = Gameplay.Zones.BosqueRuidoso.center
	local pond = forest + Vector3.new(24, 0, -14)
	terrainDisc(pond, 9, 4, Gameplay.GroundY, Enum.Material.Mud)
	terrainDisc(pond, 7, 3, Gameplay.GroundY - 0.2, Enum.Material.Water)

	-- Colores de los materiales: saturados, estilo low-poly.
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(105, 190, 75))
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(70, 150, 60))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(240, 215, 150))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(130, 125, 135))
	terrain:SetMaterialColor(Enum.Material.Basalt, Color3.fromRGB(75, 55, 55))
	terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(245, 240, 255))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(200, 165, 110))
	terrain.WaterColor = T.waterColor
	terrain.WaterTransparency = 0.6
	terrain.WaterWaveSize = 0.2
	terrain.WaterWaveSpeed = 8
	terrain.WaterReflectance = 0.6
	pcall(function()
		(terrain :: any).Decoration = true -- hierba animada sobre el material Grass
	end)

	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Parent = terrain
end

-- Caminos de tierra desde la playa a cada zona, con farolillos.
local function buildPaths()
	for zoneId, area in Gameplay.Zones do
		if zoneId ~= "PlayaRara" then
			local direction = flat(area.center - BEACH).Unit
			local from = BEACH + direction * (Gameplay.Zones.PlayaRara.radius - 2)
			local to = area.center - direction * area.radius
			table.insert(pathSegments, { from = flat(from), to = flat(to) })
			local length = (to - from).Magnitude
			local middle = (from + to) / 2
			terrain:FillBlock(
				CFrame.lookAt(Vector3.new(middle.X, Gameplay.GroundY - T.surfaceOffset - 2, middle.Z), Vector3.new(to.X, Gameplay.GroundY - T.surfaceOffset - 2, to.Z)),
				Vector3.new(Art.pathWidth, 4, length),
				Enum.Material.Ground
			)
			local steps = math.floor(length / Art.lampSpacing)
			for i = 1, steps do
				local point = from + direction * (i * Art.lampSpacing)
				local side = direction:Cross(Vector3.yAxis) * (Art.pathWidth / 2 + 1.5) * (if i % 2 == 0 then 1 else -1)
				local base = ground(point + side)
				part("Poste", Enum.PartType.Cylinder, Vector3.new(5, 0.4, 0.4), base * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 60, 40), Enum.Material.Wood).CastShadow = false
				deco("Tejadillo", nil, Vector3.new(1.4, 0.3, 1.4), base * CFrame.new(0, 5.9, 0), Color3.fromRGB(70, 50, 35), Enum.Material.Wood)
				local lamp = deco("Farol", Enum.PartType.Ball, Vector3.one * 1, base * CFrame.new(0, 5.2, 0), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
				local light = Instance.new("PointLight")
				light.Range = 10
				light.Brightness = 0.8
				light.Color = Color3.fromRGB(255, 210, 140)
				light.Parent = lamp
			end
		end
	end
end

-- ===== Vegetación y props =====

local function palm(position: Vector3)
	local m = model("Palmera")
	local trunk = Color3.fromRGB(150, 105, 60)
	local ring = Color3.fromRGB(120, 80, 45)
	local yaw = rng:NextNumber(0, 360)
	local lean = rng:NextNumber(6, 14)
	local cf = ground(position) * CFrame.Angles(0, math.rad(yaw), 0)
	for i = 0, 4 do
		cf = cf * CFrame.Angles(0, 0, math.rad(lean * 0.25))
		local segment = cf * CFrame.new(0, 1.3, 0)
		part("Tronco", Enum.PartType.Cylinder, Vector3.new(2.7, 1.3 - i * 0.12, 1.3 - i * 0.12), segment * CFrame.Angles(0, 0, math.rad(90)), trunk, Enum.Material.Wood, m)
		deco("Anillo", Enum.PartType.Cylinder, Vector3.new(0.35, 1.45 - i * 0.12, 1.45 - i * 0.12), cf * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)), ring, Enum.Material.Wood, m)
		cf = cf * CFrame.new(0, 2.6, 0)
	end
	local top = cf
	for i = 1, 7 do
		local frond = top * CFrame.Angles(0, math.rad(i * (360 / 7) + rng:NextNumber(-8, 8)), 0)
		local first = deco("Hoja", nil, Vector3.new(1.8, 0.2, 3.6), frond * CFrame.Angles(math.rad(-15), 0, 0) * CFrame.new(0, 0.2, -1.8), Color3.fromRGB(60, 175, 70), Enum.Material.Grass, m)
		deco("Hoja", nil, Vector3.new(1.4, 0.2, 3.2), first.CFrame * CFrame.new(0, 0, -1.6) * CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 0, -1.5), Color3.fromRGB(80, 195, 85), Enum.Material.Grass, m)
	end
	for i = 1, 3 do
		deco("Coco", Enum.PartType.Ball, Vector3.one * 0.9, top * CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(0.55, -0.5, 0), Color3.fromRGB(110, 70, 40), nil, m)
	end
end

local function umbrella(position: Vector3, color: Color3)
	local m = model("Sombrilla")
	local base = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), math.rad(8))
	part("Palo", Enum.PartType.Cylinder, Vector3.new(6, 0.25, 0.25), base * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(240, 240, 240), nil, m)
	local canopy = deco("Tela", nil, Vector3.new(7, 1.6, 7), base * CFrame.new(0, 6, 0), color, nil, m)
	ellipsoid(canopy)
	local stripe = deco("Raya", nil, Vector3.new(7.1, 1.2, 2.2), base * CFrame.new(0, 6.1, 0), Color3.fromRGB(255, 255, 255), nil, m)
	ellipsoid(stripe)
	deco("Toalla", nil, Vector3.new(3, 0.1, 5.5), ground(position) * CFrame.new(3, 0.1, 1) * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0), color, Enum.Material.Fabric, m)
end

local function roundTree(position: Vector3)
	local m = model("Arbol")
	local height = rng:NextNumber(7, 10)
	local base = ground(position) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
	part("Tronco", Enum.PartType.Cylinder, Vector3.new(height, 1.8, 1.8), base * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, m)
	for _, side in { -1, 1 } do
		deco("Rama", Enum.PartType.Cylinder, Vector3.new(3, 0.6, 0.6), base * CFrame.new(side * 1.2, height * 0.7, 0) * CFrame.Angles(0, 0, math.rad(side * 40)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, m)
		deco("Raiz", nil, Vector3.new(0.7, 0.8, 1.6), base * CFrame.new(side * 1, 0.3, 0) * CFrame.Angles(0, math.rad(90), math.rad(side * 25)), Color3.fromRGB(100, 68, 40), Enum.Material.Wood, m)
	end
	local greens = { Color3.fromRGB(45, 140, 60), Color3.fromRGB(65, 170, 70), Color3.fromRGB(35, 120, 55), Color3.fromRGB(80, 180, 80) }
	for i = 1, 4 do
		local offset = Vector3.new(rng:NextNumber(-2, 2), height + rng:NextNumber(-0.5, 2.5), rng:NextNumber(-2, 2))
		local canopy = deco("Copa", Enum.PartType.Ball, Vector3.one * rng:NextNumber(4.5, 6.5), base * CFrame.new(offset), greens[i], Enum.Material.Grass, m)
		canopy.CastShadow = i == 1
	end
	if rng:NextNumber() < 0.4 then
		deco("Manzana", Enum.PartType.Ball, Vector3.one * 0.7, base * CFrame.new(1.8, height - 0.8, -1.8), Color3.fromRGB(230, 50, 50), nil, m)
	end
end

local function pine(position: Vector3)
	local m = model("Pino")
	local base = ground(position)
	part("Tronco", Enum.PartType.Cylinder, Vector3.new(4, 1.2, 1.2), base * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(100, 70, 45), Enum.Material.Wood, m)
	for i = 0, 3 do
		local width = 7 - i * 1.6
		local tier = deco("Piso", nil, Vector3.new(width, 2.6, width), base * CFrame.new(0, 4 + i * 2.1, 0) * CFrame.Angles(0, math.rad(i * 22), 0), Color3.fromRGB(30 + i * 8, 110 + i * 10, 60), Enum.Material.Grass, m)
		ellipsoid(tier)
		tier.CastShadow = i == 0
	end
end

local function bush(position: Vector3)
	local m = model("Arbusto")
	for i = 1, 3 do
		deco("Hojas", Enum.PartType.Ball, Vector3.one * rng:NextNumber(1.8, 2.8), ground(position) * CFrame.new(rng:NextNumber(-1, 1), 0.9, rng:NextNumber(-1, 1)), Color3.fromRGB(50 + i * 15, 150 + i * 10, 60), Enum.Material.Grass, m)
	end
	if rng:NextNumber() < 0.5 then
		deco("Baya", Enum.PartType.Ball, Vector3.one * 0.4, ground(position) * CFrame.new(0.6, 1.9, -0.6), Color3.fromRGB(200, 40, 90), nil, m)
	end
end

local FLOWER_COLORS = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 200, 50), Color3.fromRGB(160, 110, 255), Color3.fromRGB(255, 255, 255) }
local function flowerPatch(position: Vector3)
	local m = model("Flores")
	for _ = 1, 3 do
		local spot = ground(position) * CFrame.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		deco("Tallo", nil, Vector3.new(0.12, 1, 0.12), spot * CFrame.new(0, 0.5, 0), Color3.fromRGB(60, 150, 60), nil, m)
		deco("Flor", Enum.PartType.Ball, Vector3.one * 0.5, spot * CFrame.new(0, 1.05, 0), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], nil, m)
	end
end

local function bigMushroom(position: Vector3, color: Color3)
	local m = model("SetaGigante")
	local height = rng:NextNumber(2.5, 4.5)
	part("Pie", Enum.PartType.Cylinder, Vector3.new(height, 0.9, 0.9), ground(position) * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(245, 235, 215), nil, m)
	local cap = deco("Sombrero", nil, Vector3.new(3, 1.3, 3), ground(position) * CFrame.new(0, height + 0.3, 0), color, nil, m)
	ellipsoid(cap)
	for i = 1, 3 do
		deco("Lunar", Enum.PartType.Ball, Vector3.one * 0.45, ground(position) * CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(0.9, height + 0.75, 0), Color3.fromRGB(255, 255, 255), nil, m)
	end
end

-- Roca de Terrain (no es una pieza): barata y con buen aspecto.
local function terrainRock(position: Vector3, radius: number, material: Enum.Material)
	terrain:FillBall(Vector3.new(position.X, Gameplay.GroundY + radius * 0.2, position.Z), radius, material)
end

local function volcano(zoneCenter: Vector3, radius: number)
	local away = flat(zoneCenter - BEACH).Unit
	local base = zoneCenter + away * (radius + 18)
	-- Cono de Terrain con cráter de lava.
	for i = 0, 6 do
		local layerRadius = 26 - i * 3.2
		terrainDisc(base, layerRadius, 4, Gameplay.GroundY + 4 + i * 4, if i % 2 == 0 then Enum.Material.Basalt else Enum.Material.Rock)
	end
	local craterTop = Gameplay.GroundY + 4 + 6 * 4
	terrainDisc(base, 5, 4, craterTop, Enum.Material.CrackedLava)
	local lava = deco("Lava", Enum.PartType.Cylinder, Vector3.new(0.6, 9, 9), CFrame.new(base.X, craterTop + 0.4, base.Z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 100, 20), Enum.Material.Neon)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(90, 85, 85))
	smoke.Rate = Art.volcanoSmokeRate
	smoke.Lifetime = NumberRange.new(5, 8)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 14) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.EmissionDirection = Enum.NormalId.Right -- el eje X del cilindro apunta hacia arriba
	smoke.Parent = lava
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = "rbxasset://textures/particles/fire_sparks_main.dds"
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 150, 50))
	embers.LightEmission = 1
	embers.Rate = 6
	embers.Lifetime = NumberRange.new(1, 2)
	embers.Speed = NumberRange.new(8, 14)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.EmissionDirection = Enum.NormalId.Right
	embers.Parent = lava
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 40)
	light.Range = 40
	light.Brightness = 3
	light.Parent = lava
end

local function cloudPuff(position: Vector3, scale: number)
	local m = model("Nube")
	for i = 1, 4 do
		deco("Bola", Enum.PartType.Ball, Vector3.one * scale * (1.25 - i * 0.18), CFrame.new(position + Vector3.new((i - 2.5) * scale * 0.5, (i % 2) * scale * 0.22, rng:NextNumber(-0.3, 0.3) * scale)), Color3.fromRGB(250, 250, 255), nil, m)
	end
end

local CRYSTAL_COLORS = { Color3.fromRGB(190, 160, 255), Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 180, 230) }
local function crystals(position: Vector3)
	local m = model("Cristales")
	local color = CRYSTAL_COLORS[rng:NextInteger(1, #CRYSTAL_COLORS)]
	for i = 1, 4 do
		local height = rng:NextNumber(2, 5)
		local c = part("Cristal", nil, Vector3.new(0.9, height, 0.9), ground(position) * CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), math.rad(i * 45), math.rad(rng:NextNumber(-20, 20))) * CFrame.new(0, height / 2, 0), color, Enum.Material.Glass, m)
		c.Transparency = 0.2
		c.CastShadow = false
	end
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 8
	glow.Brightness = 1
	glow.Parent = m:FindFirstChildWhichIsA("BasePart")
end

-- Arcoíris sobre la Nube Pegajosa (pocas piezas: arcos por tramos).
local function rainbow(center: Vector3)
	local m = model("Arcoiris")
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
	-- El punto de aparición de la plantilla se coloca sobre el terreno.
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Position = Vector3.new(descendant.Position.X, Gameplay.GroundY + descendant.Size.Y / 2, descendant.Position.Z)
		end
	end

	setupLighting()
	buildTerrain()
	buildPaths()

	local zones = Gameplay.Zones

	-- Playa Rara: palmeras en el borde, sombrillas y rocas.
	for i = 1, Art.palms do
		local angle = (i / Art.palms) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local radius = zones.PlayaRara.radius - rng:NextNumber(2, 6)
		local point = zones.PlayaRara.center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if isFree(point, 0) then
			palm(point)
		end
	end
	local umbrellaColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(70, 160, 255), Color3.fromRGB(255, 190, 50) }
	for i = 1, 3 do
		local point = freePoint(zones.PlayaRara.center, 25, 44, 2)
		if point then
			umbrella(point, umbrellaColors[i])
		end
	end
	for _ = 1, 8 do
		local point = freePoint(zones.PlayaRara.center, 20, 48, 0)
		if point then
			terrainRock(point, rng:NextNumber(1.5, 3), Enum.Material.Sandstone)
		end
	end

	-- Bosque Ruidoso: árboles redondos y pinos en el borde, arbustos, flores, setas y rocas con musgo.
	for i = 1, Art.forestTrees do
		local angle = (i / Art.forestTrees) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local radius = zones.BosqueRuidoso.radius - rng:NextNumber(3, 10)
		local point = zones.BosqueRuidoso.center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if isFree(point, 0) then
			if i % 3 == 0 then
				pine(point)
			else
				roundTree(point)
			end
		end
	end
	for _ = 1, 6 do
		local point = freePoint(zones.BosqueRuidoso.center, 8, 38, 0)
		if point then
			bush(point)
		end
	end
	for _ = 1, 4 do
		local point = freePoint(zones.BosqueRuidoso.center, 8, 34, 1)
		if point then
			bigMushroom(point, if rng:NextNumber() < 0.5 then Color3.fromRGB(230, 70, 70) else Color3.fromRGB(225, 60, 150))
		end
	end
	for _ = 1, 5 do
		local point = freePoint(zones.BosqueRuidoso.center, 6, 40, 0)
		if point then
			terrainRock(point, rng:NextNumber(2, 3.5), Enum.Material.Slate)
		end
	end

	-- Volcán Tímido: cono humeante detrás y rocas de basalto.
	volcano(zones.VolcanTimido.center, zones.VolcanTimido.radius)
	for _ = 1, 8 do
		local point = freePoint(zones.VolcanTimido.center, 10, 42, 0)
		if point then
			terrainRock(point, rng:NextNumber(2, 4), if rng:NextNumber() < 0.5 then Enum.Material.Basalt else Enum.Material.CrackedLava)
		end
	end

	-- Nube Pegajosa: nubes flotando, cristales y arcoíris.
	for _ = 1, Art.clouds do
		local point = randomPoint(zones.NubePegajosa.center, 5, 50)
		cloudPuff(point + Vector3.new(0, rng:NextNumber(14, 28), 0), rng:NextNumber(4, 7))
	end
	for _ = 1, 6 do
		local point = freePoint(zones.NubePegajosa.center, 10, 40, 1)
		if point then
			crystals(point)
		end
	end
	rainbow(zones.NubePegajosa.center + Vector3.new(0, 0, 20))

	-- Resto de la isla: árboles, arbustos y flores sueltos (fuera de zonas, santuarios y caminos).
	local function outsideZones(point: Vector3): boolean
		for _, area in zones do
			if (flat(point) - flat(area.center)).Magnitude < area.radius + 6 then
				return false
			end
		end
		return true
	end
	for _ = 1, Art.islandTrees do
		local point = freePoint(BEACH, 95, 280, 3)
		if point and outsideZones(point) then
			if rng:NextNumber() < 0.5 then
				roundTree(point)
			else
				pine(point)
			end
		end
	end
	for _ = 1, Art.islandBushes do
		local point = freePoint(BEACH, 60, 285, 0)
		if point and outsideZones(point) then
			if rng:NextNumber() < 0.5 then
				bush(point)
			else
				flowerPatch(point)
			end
		end
	end
end

return WorldArt
