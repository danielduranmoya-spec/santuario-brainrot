--!strict
-- Índice de bichos (botón ÍNDICE): todos los bichos del juego por rareza. Los que aún no has
-- atrapado salen como una silueta negra con "???"; al atraparlos se ven con sus colores y su nombre.
-- Arriba: cuántos has descubierto y tus capturas totales con el próximo premio. En cada rareza, el
-- premio por completarla (✓ si ya lo tienes). Los bichos de evento van en "Limitados".
-- Solo lee atributos que pone el servidor (Discovered, IndexClaimed, TotalCaught); los premios los da
-- server/Services/Bestiary. Los modelos se dibujan una vez en un ViewportFrame con shared/CritterArt;
-- la silueta es el mismo modelo con la luz del visor apagada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local IndexConfig = require(Config:WaitForChild("Index"))
local Format = require(Shared:WaitForChild("Format"))
local CritterArt = require(Shared:WaitForChild("CritterArt"))
local Menus = require(script.Parent:WaitForChild("Menus"))

type Tile = { def: CrittersConfig.Critter, viewport: ViewportFrame, name: TextLabel }
type Section = { rarity: string?, header: TextLabel, ids: { string } }

local MODEL_SCALE = 4 -- studs por unidad de CritterArt dentro del visor
local TILE_SIZE = Vector2.new(112, 132)
local COLOR_GOLD = Color3.fromRGB(255, 200, 40)
local COLOR_DONE = Color3.fromRGB(120, 230, 120)

local Bestiary = {}

local function listAttribute(name: string): { [string]: boolean }
	local set = {}
	for _, item in string.split(tostring(player:GetAttribute(name) or ""), ",") do
		if item ~= "" then
			set[item] = true
		end
	end
	return set
end

local function rewardText(reward: IndexConfig.Reward): string
	local parts = {}
	if reward.coins then
		table.insert(parts, Format.number(reward.coins) .. " 💰")
	end
	if reward.baits then
		table.insert(parts, reward.baits .. (if reward.baits == 1 then " cebo" else " cebos"))
	end
	if reward.luckMinutes then
		table.insert(parts, reward.luckMinutes .. " min Suerte x2")
	end
	return table.concat(parts, " + ")
end

-- Monta el modelo del bicho dentro del visor (piezas sueltas, ancladas, sin scripts).
local function buildModel(def: CrittersConfig.Critter, viewport: ViewportFrame)
	local model = Instance.new("Model")
	local specs = CritterArt[def.id]
	if specs then
		for _, spec in specs do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			if spec.shape == "Ball" then
				part.Shape = Enum.PartType.Ball
			elseif spec.shape == "Cylinder" then
				part.Shape = Enum.PartType.Cylinder
			elseif spec.shape == "Wedge" then
				part.Shape = Enum.PartType.Wedge
			end
			part.Size = spec.size * MODEL_SCALE
			if spec.shape == "Ellipsoid" then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = part
			end
			part.Color = spec.color
			part.Material = spec.material or Enum.Material.SmoothPlastic
			part.Transparency = spec.transparency or 0
			local rot = spec.rot or Vector3.zero
			local cframe = CFrame.new(spec.pos * MODEL_SCALE) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
			local rot2 = spec.rot2
			if rot2 then
				cframe *= CFrame.Angles(math.rad(rot2.X), math.rad(rot2.Y), math.rad(rot2.Z))
			end
			part.CFrame = cframe
			part.Parent = model
		end
	end
	model.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	-- El frente del bicho es -Z: la cámara lo mira desde delante y un poco desde arriba y el lado.
	camera.CFrame = CFrame.lookAt(Vector3.new(3.2, 2.2, -6.8), Vector3.new(0, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
end

local function setDiscovered(tile: Tile, discovered: boolean)
	if discovered then
		tile.viewport.Ambient = Color3.fromRGB(170, 170, 170)
		tile.viewport.LightColor = Color3.new(1, 1, 1)
		tile.viewport.ImageColor3 = Color3.new(1, 1, 1)
		tile.name.Text = tile.def.name
	else
		-- Silueta: sin luz todo el modelo sale negro.
		tile.viewport.Ambient = Color3.new(0, 0, 0)
		tile.viewport.LightColor = Color3.new(0, 0, 0)
		tile.viewport.ImageColor3 = IndexConfig.silhouetteColor
		tile.name.Text = "???"
	end
end

local function drawBookIcon(area: Frame)
	local function box(size: UDim2, position: UDim2, color: Color3, radius: number?): Frame
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = size
		f.Position = position
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Parent = area
		if radius then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(radius, 0)
			c.Parent = f
		end
		return f
	end
	box(UDim2.fromScale(0.62, 0.78), UDim2.fromScale(0.5, 0.52), Color3.fromRGB(70, 120, 230), 0.12)
	box(UDim2.fromScale(0.08, 0.78), UDim2.fromScale(0.23, 0.52), Color3.fromRGB(40, 70, 160))
	box(UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.56, 0.86), Color3.new(1, 1, 1))
	box(UDim2.fromScale(0.28, 0.28), UDim2.fromScale(0.56, 0.46), COLOR_GOLD, 1)
end

function Bestiary.Start()
	local button, badge = Menus.AddSideButton("ÍNDICE", "Indice", Color3.fromRGB(80, 140, 255), Color3.fromRGB(40, 70, 190), drawBookIcon, 4)
	badge.Visible = false
	local panel, list = Menus.AddPanel("Índice de bichos")

	local function text(parent: Instance, size: UDim2, value: string, order: number): TextLabel
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = size
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.5
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = value
		label.LayoutOrder = order
		label.Parent = parent
		return label
	end

	-- Resumen arriba.
	local summary = text(list, UDim2.new(1, -12, 0, 34), "", 0)
	summary.TextColor3 = COLOR_GOLD
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -12, 0, 14)
	track.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
	track.BorderSizePixel = 0
	track.LayoutOrder = 1
	track.Parent = list
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = COLOR_DONE
	fill.BorderSizePixel = 0
	fill.Parent = track
	for _, f in { track, fill } do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
	end
	local milestoneLabel = text(list, UDim2.new(1, -12, 0, 28), "", 2)
	milestoneLabel.Font = Enum.Font.GothamBold

	-- Secciones por rareza y la de Limitados.
	local tiles: { Tile } = {}
	local sections: { Section } = {}
	local order = 10
	local function addSection(title: string, rarity: string?, color: Color3, defs: { CrittersConfig.Critter })
		if #defs == 0 then
			return
		end
		local header = text(list, UDim2.new(1, -12, 0, 32), title, order)
		header.TextColor3 = color
		order += 1
		local grid = Instance.new("Frame")
		grid.BackgroundTransparency = 1
		grid.Size = UDim2.new(1, -12, 0, 0)
		grid.AutomaticSize = Enum.AutomaticSize.Y
		grid.LayoutOrder = order
		grid.Parent = list
		order += 1
		local layout = Instance.new("UIGridLayout")
		layout.CellSize = UDim2.fromOffset(TILE_SIZE.X, TILE_SIZE.Y)
		layout.CellPadding = UDim2.fromOffset(8, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = grid
		local ids = {}
		for i, def in defs do
			local cell = Instance.new("Frame")
			cell.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.45)
			cell.LayoutOrder = i
			cell.Parent = grid
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0.12, 0)
			c.Parent = cell
			local stroke = Instance.new("UIStroke")
			stroke.Color = color
			stroke.Thickness = 2
			stroke.Parent = cell
			local viewport = Instance.new("ViewportFrame")
			viewport.BackgroundTransparency = 1
			viewport.Size = UDim2.fromScale(1, 0.76)
			viewport.LightDirection = Vector3.new(-1, -1, 1)
			viewport.Parent = cell
			buildModel(def, viewport)
			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Size = UDim2.fromScale(0.92, 0.2)
			name.Position = UDim2.fromScale(0.04, 0.78)
			name.Font = Enum.Font.GothamBold
			name.TextScaled = true
			name.TextColor3 = Color3.new(1, 1, 1)
			name.TextStrokeTransparency = 0.4
			name.Parent = cell
			local tile: Tile = { def = def, viewport = viewport, name = name }
			table.insert(tiles, tile)
			table.insert(ids, def.id)
		end
		table.insert(sections, { rarity = rarity, header = header, ids = ids })
	end
	for _, rarity in CrittersConfig.RarityOrder do
		local defs = {}
		for _, def in CrittersConfig.List do
			if def.rarity == rarity and not def.eventOnly then
				table.insert(defs, def)
			end
		end
		local info = CrittersConfig.Rarities[rarity]
		addSection(info.label, rarity, info.color, defs)
	end
	local limited = {}
	for _, def in CrittersConfig.List do
		if def.eventOnly then
			table.insert(limited, def)
		end
	end
	addSection("⭐ Limitados (solo en eventos)", nil, COLOR_GOLD, limited)

	local seenCount = -1
	local function refresh()
		local discovered = listAttribute("Discovered")
		local claimed = listAttribute("IndexClaimed")
		local found = 0
		for _, tile in tiles do
			local isFound = discovered[tile.def.id] == true
			setDiscovered(tile, isFound)
			if isFound then
				found += 1
			end
		end
		summary.Text = "📖 Descubiertos: " .. found .. "/" .. #tiles
		fill.Size = UDim2.fromScale(found / math.max(#tiles, 1), 1)

		local total = (player:GetAttribute("TotalCaught") :: number?) or 0
		local nextMilestone: IndexConfig.Milestone? = nil
		for _, milestone in IndexConfig.Milestones do
			if not claimed["capturas:" .. milestone.count] then
				nextMilestone = milestone
				break
			end
		end
		milestoneLabel.Text = "🎯 Capturas: " .. Format.number(total)
			.. (if nextMilestone then " · a las " .. nextMilestone.count .. ": " .. rewardText(nextMilestone) else " · ¡todos los premios conseguidos!")

		for _, section in sections do
			local have = 0
			for _, id in section.ids do
				if discovered[id] then
					have += 1
				end
			end
			local rarity = section.rarity
			if rarity then
				local label = CrittersConfig.Rarities[rarity].label
				local reward = IndexConfig.RarityRewards[rarity]
				local done = claimed["rareza:" .. rarity] == true
				section.header.Text = label .. "  " .. have .. "/" .. #section.ids
					.. (if done then "  ✓ premio conseguido" elseif reward then "  · premio: " .. rewardText(reward) else "")
			end
		end

		-- "!" en el botón cuando descubres uno nuevo y aún no has mirado el índice.
		if seenCount >= 0 and found > seenCount and not panel.Visible then
			badge.Visible = true
		end
		if panel.Visible or seenCount < 0 then
			seenCount = found
		end
	end

	button.Activated:Connect(function()
		Menus.Toggle(panel)
		badge.Visible = false
		refresh()
	end)
	for _, attribute in { "Discovered", "IndexClaimed", "TotalCaught" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()
end

return Bestiary
