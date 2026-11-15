--!strict
-- Decoración low-poly del mapa, generada por código (vive en el repo y Rojo la sincroniza):
-- isla de hierba sobre el mar, Playa Rara con palmeras, Bosque Ruidoso con árboles y setas,
-- Volcán Tímido con su cono humeante y rocas de lava, Nube Pegajosa con nubes flotantes,
-- caminos de arena desde la playa a cada zona e iluminación base.
-- Todo es decorado: no cambia la lógica de zonas, barreras ni apariciones.
-- Pensado para móvil: pocas piezas, sin sombras en las pequeñas y partículas moderadas.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Art = require(Config:WaitForChild("Art"))

local WorldArt = {}

local rng = Random.new(Art.seed) -- semilla fija: el mapa sale siempre igual
local folder: Folder

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

-- Disco plano (cilindro tumbado) con la cara de arriba a la altura `topY`.
local function disc(name: string, center: Vector3, radius: number, thickness: number, topY: number, color: Color3, material: Enum.Material?): Part
	local d = part(
		name,
		Enum.PartType.Cylinder,
		Vector3.new(thickness, radius * 2, radius * 2),
		CFrame.new(center.X, topY - thickness / 2, center.Z) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material
	)
	d.CanQuery = false
	return d
end

local function ground(position: Vector3): CFrame
	return CFrame.new(position.X, Gameplay.GroundY, position.Z)
end

-- Punto al azar en un anillo alrededor de `center`.
local function ringPoint(center: Vector3, minRadius: number, maxRadius: number): Vector3
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(minRadius, maxRadius)
	return Vector3.new(center.X + math.cos(angle) * radius, Gameplay.GroundY, center.Z + math.sin(angle) * radius)
end

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = folder
	return m
end

-- ===== Elementos =====

local function palm(position: Vector3)
	local m = model("Palmera")
	local trunkColor = Color3.fromRGB(150, 105, 60)
	local tilt = rng:NextNumber(-12, 12)
	local yaw = rng:NextNumber(0, 360)
	local base = ground(position) * CFrame.Angles(0, math.rad(yaw), 0)
	local top = base
	for i = 0, 2 do
		local segment = base * CFrame.Angles(0, 0, math.rad(tilt * i * 0.6)) * CFrame.new(0, 2 + i * 3.6, 0)
		part("Tronco", Enum.PartType.Cylinder, Vector3.new(3.8, 1.4 - i * 0.2, 1.4 - i * 0.2), segment * CFrame.Angles(0, 0, math.rad(90)), trunkColor, Enum.Material.Wood, m)
		top = segment * CFrame.new(0, 1.9, 0)
	end
	for i = 1, 5 do
		local leaf = part(
			"Hoja",
			nil,
			Vector3.new(1.6, 0.25, 6),
			top * CFrame.Angles(0, math.rad(i * 72), 0) * CFrame.Angles(math.rad(-18), 0, 0) * CFrame.new(0, 0, -2.6),
			Color3.fromRGB(70, 185, 80),
			nil,
			m
		)
		leaf.CanCollide = false
		leaf.CastShadow = false
	end
	part("Coco", Enum.PartType.Ball, Vector3.one * 0.9, top * CFrame.new(0.5, -0.6, 0.3), Color3.fromRGB(110, 70, 40), nil, m).CanCollide = false
end

local function roundTree(position: Vector3)
	local m = model("Arbol")
	local height = rng:NextNumber(6, 9)
	part("Tronco", Enum.PartType.Cylinder, Vector3.new(height, 1.6, 1.6), ground(position) * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, m)
	local greens = { Color3.fromRGB(45, 140, 60), Color3.fromRGB(60, 165, 70), Color3.fromRGB(35, 120, 55) }
	for i = 1, 3 do
		local offset = Vector3.new(rng:NextNumber(-1.5, 1.5), height + rng:NextNumber(-0.5, 2), rng:NextNumber(-1.5, 1.5))
		local canopy = part("Copa", Enum.PartType.Ball, Vector3.one * rng:NextNumber(4.5, 6.5), ground(position) * CFrame.new(offset), greens[i], Enum.Material.Grass, m)
		canopy.CanCollide = false
	end
end

local function bigMushroom(position: Vector3)
	local m = model("SetaDecorativa")
	part("Pie", Enum.PartType.Cylinder, Vector3.new(2.5, 0.8, 0.8), ground(position) * CFrame.new(0, 1.25, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(245, 235, 215), nil, m).CanCollide = false
	local cap = part("Sombrero", nil, Vector3.new(2.6, 1.1, 2.6), ground(position) * CFrame.new(0, 2.7, 0), Color3.fromRGB(230, 70, 70), nil, m)
	cap.CanCollide = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = cap
end

local function rock(position: Vector3, color: Color3, scale: number, glowing: boolean)
	local r = part(
		"Roca",
		nil,
		Vector3.new(rng:NextNumber(1.5, 3), rng:NextNumber(1, 2), rng:NextNumber(1.5, 3)) * scale,
		ground(position) * CFrame.new(0, 0.6 * scale, 0) * CFrame.Angles(math.rad(rng:NextNumber(-15, 15)), math.rad(rng:NextNumber(0, 90)), math.rad(rng:NextNumber(-15, 15))),
		color,
		Enum.Material.Slate
	)
	r.CastShadow = scale > 1.5
	if glowing then
		local crack = part("Grieta", nil, Vector3.new(r.Size.X * 0.8, 0.15, 0.3), r.CFrame * CFrame.new(0, r.Size.Y / 2, 0), Color3.fromRGB(255, 110, 30), Enum.Material.Neon)
		crack.CanCollide = false
		crack.CastShadow = false
	end
end

local function cloudPuff(position: Vector3, scale: number)
	local m = model("Nube")
	for i = 1, 3 do
		local puff = part(
			"Bola",
			Enum.PartType.Ball,
			Vector3.one * scale * (1.2 - i * 0.2),
			CFrame.new(position + Vector3.new((i - 2) * scale * 0.55, (i % 2) * scale * 0.2, 0)),
			Color3.fromRGB(250, 250, 255),
			nil,
			m
		)
		puff.CanCollide = false
		puff.CastShadow = false
	end
end

local function volcano(zoneCenter: Vector3, radius: number)
	-- El cono va detrás de la zona (en el lado contrario a la playa) para no tapar los bichos.
	local beach = Gameplay.Zones.PlayaRara.center
	local away = Vector3.new(zoneCenter.X - beach.X, 0, zoneCenter.Z - beach.Z).Unit
	local base = zoneCenter + away * (radius + 22)
	local m = model("Volcan")
	local colors = { Color3.fromRGB(110, 55, 40), Color3.fromRGB(95, 45, 35), Color3.fromRGB(80, 40, 30), Color3.fromRGB(70, 35, 30) }
	local layers = #colors
	for i = 1, layers do
		local layerRadius = 30 - i * 6
		part("Capa", Enum.PartType.Cylinder, Vector3.new(8, layerRadius * 2, layerRadius * 2), ground(base) * CFrame.new(0, i * 7 - 3, 0) * CFrame.Angles(0, 0, math.rad(90)), colors[i], Enum.Material.Slate, m)
	end
	local lava = part("Lava", Enum.PartType.Cylinder, Vector3.new(1, 9, 9), ground(base) * CFrame.new(0, layers * 7 + 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 100, 20), Enum.Material.Neon, m)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(90, 85, 85))
	smoke.Rate = Art.volcanoSmokeRate
	smoke.Lifetime = NumberRange.new(5, 8)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 14) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.Orientation = Enum.ParticleOrientation.FacingCamera
	smoke.EmissionDirection = Enum.NormalId.Right -- el eje X del cilindro apunta hacia arriba
	smoke.Parent = lava
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 40)
	light.Range = 30
	light.Brightness = 2
	light.Parent = lava
end

-- Camino de arena desde el borde de la playa hasta la puerta de una zona.
local function path(zoneCenter: Vector3, zoneRadius: number)
	local beach = Gameplay.Zones.PlayaRara
	local direction = Vector3.new(zoneCenter.X - beach.center.X, 0, zoneCenter.Z - beach.center.Z).Unit
	local from = beach.center + direction * (beach.radius - 2)
	local to = zoneCenter - direction * zoneRadius
	local length = (to - from).Magnitude
	local middle = (from + to) / 2
	local strip = part(
		"Camino",
		nil,
		Vector3.new(Art.pathWidth, 0.2, length),
		CFrame.lookAt(Vector3.new(middle.X, Gameplay.GroundY + 0.05, middle.Z), Vector3.new(to.X, Gameplay.GroundY + 0.05, to.Z)),
		Art.colors.path,
		Enum.Material.Sand
	)
	strip.CanCollide = false
	strip.CanQuery = false
	-- Postes con farolillo a los lados.
	local steps = math.floor(length / Art.lampSpacing)
	for i = 1, steps do
		local point = from + direction * (i * Art.lampSpacing)
		local side = direction:Cross(Vector3.yAxis) * (Art.pathWidth / 2 + 1.5) * (if i % 2 == 0 then 1 else -1)
		local post = part("Poste", Enum.PartType.Cylinder, Vector3.new(5, 0.4, 0.4), ground(point + side) * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
		post.CastShadow = false
		local lamp = part("Farol", Enum.PartType.Ball, Vector3.one * 1, ground(point + side) * CFrame.new(0, 5.3, 0), Color3.fromRGB(255, 220, 140), Enum.Material.Neon)
		lamp.CanCollide = false
		lamp.CastShadow = false
	end
end

local function setupLighting()
	Lighting.ClockTime = Art.lighting.clockTime
	Lighting.Brightness = Art.lighting.brightness
	Lighting.Ambient = Art.lighting.ambient
	Lighting.OutdoorAmbient = Art.lighting.outdoorAmbient
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.3

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = Art.ambience.PlayaRara.density
	atmosphere.Color = Art.ambience.PlayaRara.color
	atmosphere.Decay = Art.ambience.PlayaRara.decay
	atmosphere.Haze = Art.ambience.PlayaRara.haze
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
end

-- El Baseplate de la plantilla pasa a ser el mar (se quita su textura de cuadrícula).
local function setupSea()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Art.colors.sea
		baseplate.Material = Enum.Material.SmoothPlastic
		for _, child in baseplate:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child:Destroy()
			end
		end
	end
end

function WorldArt.Start()
	folder = Instance.new("Folder")
	folder.Name = "Decorado"
	folder.Parent = Workspace

	setupLighting()
	setupSea()

	-- Isla de hierba bajo todo el juego (fina: se camina sobre el Baseplate).
	disc("Isla", Gameplay.Zones.PlayaRara.center, Art.islandRadius, 0.6, Gameplay.GroundY + 0.04, Art.colors.grass, Enum.Material.Grass)

	local zones = Gameplay.Zones

	-- Playa Rara: arena (la pone Zones), palmeras alrededor y conchas-roca.
	for i = 1, Art.palms do
		local angle = (i / Art.palms) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local radius = zones.PlayaRara.radius - rng:NextNumber(2, 6)
		palm(zones.PlayaRara.center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
	end
	for _ = 1, 6 do
		rock(ringPoint(zones.PlayaRara.center, 22, 46), Color3.fromRGB(215, 200, 170), 0.6, false)
	end

	-- Bosque Ruidoso: árboles en el borde y algunas setas gigantes.
	for i = 1, Art.forestTrees do
		local angle = (i / Art.forestTrees) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local radius = zones.BosqueRuidoso.radius - rng:NextNumber(3, 10)
		roundTree(zones.BosqueRuidoso.center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
	end
	for _ = 1, 4 do
		bigMushroom(ringPoint(zones.BosqueRuidoso.center, 8, 30))
	end

	-- Volcán Tímido: cono humeante detrás y rocas de lava dentro.
	volcano(zones.VolcanTimido.center, zones.VolcanTimido.radius)
	for _ = 1, 8 do
		rock(ringPoint(zones.VolcanTimido.center, 10, 42), Color3.fromRGB(60, 45, 45), rng:NextNumber(1, 2), true)
	end

	-- Nube Pegajosa: nubes flotando por encima.
	for _ = 1, Art.clouds do
		local point = ringPoint(zones.NubePegajosa.center, 5, 50)
		cloudPuff(point + Vector3.new(0, rng:NextNumber(12, 26), 0), rng:NextNumber(4, 7))
	end

	-- Caminos desde la playa.
	for zoneId, area in zones do
		if zoneId ~= "PlayaRara" then
			path(area.center, area.radius)
		end
	end
end

return WorldArt
