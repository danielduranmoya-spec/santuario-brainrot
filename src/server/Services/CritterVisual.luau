--!strict
-- Aspecto de un bicho: una pieza raíz invisible (la que se mueve, se suelda al jugador y lleva el
-- ProximityPrompt) con el modelo por piezas de CritterArt soldado encima, un aro del color de su
-- rareza en el suelo, luz para Raro o más, chispas para Épico y Legendario, y su etiqueta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Art = require(Config:WaitForChild("Art"))

local CritterArt = require(script.Parent:WaitForChild("CritterArt"))

type CritterDef = CrittersConfig.Critter

local CritterVisual = {}

local SPARKLES_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local function newText(name: string, parent: Instance, position: UDim2, color: Color3, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.5)
	label.Position = position
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = parent
	return label
end

local function detailPart(root: BasePart, spec: CritterArt.PartSpec, scale: number): BasePart
	local part = Instance.new("Part")
	part.Name = spec.name or "Detalle"
	part.Transparency = spec.transparency or 0
	if spec.shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	elseif spec.shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
	elseif spec.shape == "Wedge" then
		part.Shape = Enum.PartType.Wedge
	end
	part.Size = spec.size * scale
	if spec.shape == "Ellipsoid" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
	part.Color = spec.color
	part.Material = spec.material or Enum.Material.SmoothPlastic
	if spec.reflectance then
		part.Reflectance = spec.reflectance
	end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	local rot = spec.rot or Vector3.zero
	local offset = CFrame.new(spec.pos * scale) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
	local rot2 = spec.rot2
	if rot2 then
		offset *= CFrame.Angles(math.rad(rot2.X), math.rad(rot2.Y), math.rad(rot2.Z))
	end
	-- Punto de giro de las piezas animadas (alas, colas, mandíbulas...), para el cliente.
	if spec.pivot then
		part:SetAttribute("Pivot", spec.pivot * scale)
	end
	part.CFrame = root.CFrame * offset
	-- Weld clásico con desplazamiento fijo: la pieza sigue a la raíz aunque la raíz se coloque
	-- antes de estar en el Workspace (un WeldConstraint ahí se quedaría con la posición vieja).
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = root
	return part
end

function CritterVisual.create(def: CritterDef): Part
	local rarity = CrittersConfig.Rarities[def.rarity]
	local size = Gameplay.CritterSizes[def.rarity]

	-- Raíz invisible: es la "caja" del bicho para moverlo, soldarlo y el aviso Atrapar.
	local root = Instance.new("Part")
	root.Name = def.id
	root.Shape = Enum.PartType.Ball
	root.Size = Vector3.new(size, size, size)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CastShadow = false
	root:SetAttribute("CritterId", def.id)
	root:SetAttribute("Rarity", def.rarity)

	local specs = CritterArt[def.id]
	if specs then
		for _, spec in specs do
			-- Los adornos pequeños se pueden quitar para aligerar (Config/Art.critterDetail).
			if not spec.fine or Art.critterDetail >= 2 then
				detailPart(root, spec, size)
			end
		end
	else
		-- Sin modelo todavía: bola del color de la rareza para que se vea igual.
		root.Transparency = 0
		root.Color = rarity.color
	end

	-- Aro de rareza en el suelo (siempre visible, barato).
	local ring = detailPart(root, {
		shape = "Cylinder",
		size = Vector3.new(0.05, 1.3, 1.3),
		pos = Vector3.new(0, -0.46, 0),
		color = rarity.color,
		rot = Vector3.new(0, 0, 90),
		material = Enum.Material.Neon,
	}, size)
	ring.Name = "AroRareza"
	ring.Transparency = 0.4

	local glow = Gameplay.RarityGlow[def.rarity]
	if glow and glow.light > 0 then
		local light = Instance.new("PointLight")
		light.Color = rarity.color
		light.Range = glow.light
		light.Brightness = glow.brightness
		light.Parent = root
	end
	if glow and glow.sparkles > 0 then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Chispas"
		sparkles.Texture = SPARKLES_TEXTURE
		sparkles.Color = ColorSequence.new(rarity.color)
		sparkles.LightEmission = 1
		sparkles.Rate = glow.sparkles
		sparkles.Lifetime = NumberRange.new(0.8, 1.4)
		sparkles.Speed = NumberRange.new(1, 2)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(size * 0.15, 0)
		sparkles.Parent = root
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Etiqueta"
	gui.Size = UDim2.new(5.5, 0, 1.4, 0) -- en studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, size / 2 + 1.5, 0)
	gui.MaxDistance = Gameplay.Spawning.labelMaxDistance
	gui.LightInfluence = 0
	gui.Parent = root
	newText("Nombre", gui, UDim2.fromScale(0, 0), Color3.new(1, 1, 1), def.name)
	newText("Detalle", gui, UDim2.fromScale(0, 0.5), rarity.color, rarity.label)

	return root
end

-- Cambia la segunda línea de la etiqueta (por ejemplo "+5/s" en el santuario).
function CritterVisual.setDetail(part: BasePart, text: string)
	local gui = part:FindFirstChild("Etiqueta")
	local detail = gui and gui:FindFirstChild("Detalle")
	if detail and detail:IsA("TextLabel") then
		detail.Text = text
	end
end

return CritterVisual
