--!strict
-- Aspecto provisional (piezas grises) de un bicho: una bola del color de su rareza,
-- con cara y una etiqueta con su nombre. Se sustituirá por modelos low-poly en la semana 11.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))

type CritterDef = CrittersConfig.Critter

local CritterVisual = {}

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

function CritterVisual.create(def: CritterDef): Part
	local rarity = CrittersConfig.Rarities[def.rarity]
	local size = Gameplay.CritterSizes[def.rarity]

	local part = Instance.new("Part")
	part.Name = def.id
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Color = rarity.color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part:SetAttribute("CritterId", def.id)
	part:SetAttribute("Rarity", def.rarity)

	-- Cara: así se ve hacia dónde camina el bicho.
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = part

	local gui = Instance.new("BillboardGui")
	gui.Name = "Etiqueta"
	gui.Size = UDim2.new(8, 0, 2, 0) -- en studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, size / 2 + 1.5, 0)
	gui.MaxDistance = Gameplay.Spawning.labelMaxDistance
	gui.LightInfluence = 0
	gui.Parent = part
	newText("Nombre", gui, UDim2.fromScale(0, 0), Color3.new(1, 1, 1), def.name)
	newText("Detalle", gui, UDim2.fromScale(0, 0.5), rarity.color, rarity.label)

	return part
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
