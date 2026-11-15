--!strict
-- Santuarios: cada jugador recibe una parcela al entrar, en la plaza del principio del campo
-- (3 a cada lado de la avenida, mirando hacia ella). Cada parcela tiene suelo de piedra y hierba,
-- muros bajos con farolillos, arco de entrada con el nombre del dueño, pedestales para los bichos
-- (los que aún no tienes se ven apagados: se abren con la mejora Santuario) y una plataforma dorada
-- con cofre donde se acumulan las monedas; el dueño las cobra al pisarla (el Imán amplía la distancia).
-- Los bichos se guardan en el perfil como "id" o "id*multiplicador" (bóvedas lejanas valen más).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Shop = require(Config:WaitForChild("Shop"))
local Art = require(Config:WaitForChild("Art"))
local Format = require(Shared:WaitForChild("Format"))
local UpgradeMath = require(Shared:WaitForChild("UpgradeMath"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local CritterVisual = require(script.Parent:WaitForChild("CritterVisual"))

type CritterDef = CrittersConfig.Critter

type Plot = {
	index: number,
	model: Model,
	origin: CFrame, -- centro de la parcela a ras de suelo; -Z mira hacia la avenida (la entrada)
	ownerLabels: { TextLabel },
	pendingLabel: TextLabel,
	waitingLabel: TextLabel,
	collectPad: BasePart,
	slotPads: { BasePart },
	owner: Player?,
	parts: { BasePart }, -- bichos dibujados en los pedestales
	pending: number,
	slotCount: number,
}

local S = Gameplay.Sanctuary
local G = Gameplay.GroundY
local FLOOR_TOP = 0.8 -- altura del suelo de la parcela sobre el terreno
local MAX_SLOTS = UpgradeMath.slotCount(Progression.Upgrades.Santuario.maxLevel, true)
local STONE = Color3.fromRGB(165, 158, 150)
local STONE_DARK = Color3.fromRGB(120, 115, 110)
local PEDESTAL_TOP = Color3.fromRGB(235, 225, 200)
local LOCKED = Color3.fromRGB(90, 90, 95)

local defsById: { [string]: CritterDef } = {}
for _, def in CrittersConfig.List do
	defsById[def.id] = def
end

local Plots = {}

local folder = Instance.new("Folder")
folder.Name = "Santuarios"
folder.Parent = Workspace

local plots: { Plot } = {}
local byPlayer: { [Player]: Plot } = {}

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function small(part: BasePart): BasePart
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	return part
end

local function newBillboard(adornee: BasePart, width: number, height: number, offsetY: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(width, 0, height, 0) -- en studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = S.labelMaxDistance
	gui.LightInfluence = 0
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = ""
	label.Parent = gui
	return label
end

local function newSurfaceLabel(part: BasePart, face: Enum.NormalId): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Art.colors.gold
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return label
end

local function slotOffset(i: number): CFrame
	local column = (i - 1) % S.slotColumns
	local row = (i - 1) // S.slotColumns
	local x = (column - (S.slotColumns - 1) / 2) * S.slotSpacing
	local z = S.slotStartZ + row * S.slotSpacing
	return CFrame.new(x, FLOOR_TOP, z)
end

local function updatePendingLabel(plot: Plot)
	plot.pendingLabel.Text = "💰 " .. Format.number(plot.pending) .. "\nPísame para cobrar"
end

local function setOwnerText(plot: Plot, text: string)
	for _, label in plot.ownerLabels do
		label.Text = text
	end
end

local function buildPlot(index: number): Plot
	local side = if index % 2 == 1 then -1 else 1
	local row = (index - 1) // 2
	local z = S.firstZ + row * S.spacingZ
	local position = Vector3.new(side * S.sideX, G, z)
	local origin = CFrame.lookAt(position, Vector3.new(0, G, z))
	local half = S.plotSize / 2

	local model = Instance.new("Model")
	model.Name = "Santuario" .. index
	model:SetAttribute("PlotIndex", index)
	-- Con StreamingEnabled, que el santuario llegue entero (el rayo guía apunta a su suelo).
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- Suelo: borde de piedra y hierba dentro, con un camino de baldosas de la entrada al cofre.
	local base = newPart("Suelo", Vector3.new(S.plotSize, FLOOR_TOP, S.plotSize), origin * CFrame.new(0, FLOOR_TOP / 2, 0), STONE, model, Enum.Material.Slate)
	model.PrimaryPart = base
	newPart("Cesped", Vector3.new(S.plotSize - 3, 0.1, S.plotSize - 3), origin * CFrame.new(0, FLOOR_TOP + 0.05, 1), Art.colors.plotGrass, model, Enum.Material.Grass).CanCollide = false
	for i = 0, 2 do
		small(newPart("Baldosa", Vector3.new(4, 0.12, 3), origin * CFrame.new(0, FLOOR_TOP + 0.12, -half + 2 + i * 3.4), Color3.fromRGB(215, 205, 190), model, Enum.Material.Slate))
	end

	-- Muros bajos de piedra (lados y fondo) con farolillos en las esquinas.
	local wallHeight = 3
	local function wall(from: Vector3, to: Vector3)
		local middle = (from + to) / 2
		local length = (to - from).Magnitude
		newPart("Muro", Vector3.new(1.2, wallHeight, length), origin * CFrame.lookAt(middle + Vector3.new(0, FLOOR_TOP + wallHeight / 2, 0), to + Vector3.new(0, FLOOR_TOP + wallHeight / 2, 0)), STONE, model, Enum.Material.Slate)
		small(newPart("Remate", Vector3.new(1.6, 0.4, length), origin * CFrame.lookAt(middle + Vector3.new(0, FLOOR_TOP + wallHeight + 0.2, 0), to + Vector3.new(0, FLOOR_TOP + wallHeight + 0.2, 0)), STONE_DARK, model, Enum.Material.Slate))
	end
	wall(Vector3.new(-half, 0, -half + 6), Vector3.new(-half, 0, half))
	wall(Vector3.new(half, 0, -half + 6), Vector3.new(half, 0, half))
	wall(Vector3.new(-half, 0, half), Vector3.new(half, 0, half))
	-- Tramos delanteros a los lados de la entrada.
	wall(Vector3.new(-half, 0, -half), Vector3.new(-6, 0, -half))
	wall(Vector3.new(6, 0, -half), Vector3.new(half, 0, -half))
	for _, corner in { Vector3.new(-half, 0, -half), Vector3.new(half, 0, -half), Vector3.new(-half, 0, half), Vector3.new(half, 0, half) } do
		newPart("Pilar", Vector3.new(2.2, wallHeight + 2, 2.2), origin * CFrame.new(corner + Vector3.new(0, FLOOR_TOP + (wallHeight + 2) / 2, 0)), STONE_DARK, model, Enum.Material.Slate)
		local lantern = small(newPart("Farolillo", Vector3.new(1, 1, 1), origin * CFrame.new(corner + Vector3.new(0, FLOOR_TOP + wallHeight + 2.6, 0)), Color3.fromRGB(255, 220, 140), model, Enum.Material.Neon))
		local light = Instance.new("PointLight")
		light.Range = 12
		light.Brightness = 0.8
		light.Color = Color3.fromRGB(255, 210, 140)
		light.Parent = lantern
	end

	-- Arco de entrada con el nombre del dueño (se lee desde la avenida y desde dentro).
	for _, x in { -6, 6 } do
		newPart("Arco", Vector3.new(1.8, 10, 1.8), origin * CFrame.new(x, FLOOR_TOP + 5, -half), Color3.fromRGB(150, 105, 60), model, Enum.Material.Wood)
	end
	local board = newPart("Cartel", Vector3.new(14, 3, 0.6), origin * CFrame.new(0, FLOOR_TOP + 10.5, -half), Color3.fromRGB(110, 75, 45), model, Enum.Material.Wood)
	local ownerLabels = { newSurfaceLabel(board, Enum.NormalId.Front), newSurfaceLabel(board, Enum.NormalId.Back) }

	-- Plataforma dorada de cobro con cofre.
	local padCFrame = origin * CFrame.new(0, FLOOR_TOP + 0.15, -half + 9)
	local collectPad = newPart("Cofre", Vector3.new(0.3, 7, 7), padCFrame * CFrame.Angles(0, 0, math.rad(90)), Art.colors.gold, model, Enum.Material.Neon)
	collectPad.Shape = Enum.PartType.Cylinder
	collectPad.Transparency = 0.15
	local ring = small(newPart("AroCofre", Vector3.new(0.35, 8, 8), padCFrame * CFrame.new(0, -0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 105, 40), model, Enum.Material.Wood))
	ring.Shape = Enum.PartType.Cylinder
	local pendingLabel = newBillboard(collectPad, 9, 2.8, 6)
	local chestBase = padCFrame * CFrame.new(0, 0, 3.6)
	small(newPart("CofreCaja", Vector3.new(3.4, 2, 2.2), chestBase * CFrame.new(0, 1.1, 0), Art.colors.chest, model, Enum.Material.Wood))
	local lid = small(newPart("CofreTapa", Vector3.new(2.2, 3.4, 2.2), chestBase * CFrame.new(0, 2.1, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)), Art.colors.chest, model, Enum.Material.Wood))
	lid.Shape = Enum.PartType.Cylinder
	for _, x in { -1.2, 1.2 } do
		small(newPart("CofreBanda", Vector3.new(0.25, 3.2, 2.3), chestBase * CFrame.new(x, 1.6, 0), Art.colors.gold, model))
	end
	small(newPart("Monedas", Vector3.new(1.6, 0.6, 1.2), chestBase * CFrame.new(0, 2.9, -0.3), Art.colors.gold, model, Enum.Material.Neon))

	local waitingLabel = newBillboard(base, 16, 1.6, 9)
	waitingLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

	-- Pedestales para los bichos.
	local slotPads = {}
	for i = 1, MAX_SLOTS do
		local cf = origin * slotOffset(i)
		local pillar = small(newPart("Pedestal", Vector3.new(1.2, 4.6, 4.6), cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), STONE, model, Enum.Material.Slate))
		pillar.Shape = Enum.PartType.Cylinder
		pillar.CanCollide = true
		local top = small(newPart("Hueco" .. i, Vector3.new(0.3, 4, 4), cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), PEDESTAL_TOP, model))
		top.Shape = Enum.PartType.Cylinder
		table.insert(slotPads, top)
	end

	model.Parent = folder

	local plot: Plot = {
		index = index,
		model = model,
		origin = origin,
		ownerLabels = ownerLabels,
		pendingLabel = pendingLabel,
		waitingLabel = waitingLabel,
		collectPad = collectPad,
		slotPads = slotPads,
		owner = nil,
		parts = {},
		pending = 0,
		slotCount = Progression.StartingSlots,
	}
	setOwnerText(plot, "Santuario libre")
	updatePendingLabel(plot)
	return plot
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function isVip(player: Player): boolean
	return player:GetAttribute("Pass_VIP") == true
end

local function slotCountFor(player: Player): number
	local profile = Data.Get(player)
	local level = if profile then profile.upgrades.Santuario or 0 else 0
	return UpgradeMath.slotCount(level, isVip(player))
end

-- Monedas por segundo de un bicho guardado ("id" o "id*multiplicador").
local function entryIncome(entry: string): (CritterDef?, number, number)
	local id, multiplier = VaultMath.decodeCritter(entry)
	local def = defsById[id]
	return def, multiplier, if def then def.coinsPerSecond * multiplier else 0
end

-- Vuelve a dibujar los pedestales y los bichos del santuario a partir del perfil.
local function render(plot: Plot)
	for _, part in plot.parts do
		part:Destroy()
	end
	plot.parts = {}

	local owner = plot.owner
	local profile = owner and Data.Get(owner)
	plot.slotCount = if owner then slotCountFor(owner) else Progression.StartingSlots

	for i, pad in plot.slotPads do
		local unlocked = i <= plot.slotCount
		pad.Color = if unlocked then PEDESTAL_TOP else LOCKED
		pad.Material = if unlocked then Enum.Material.SmoothPlastic else Enum.Material.Slate
	end

	local waiting = 0
	if profile then
		for i, entry in profile.critters do
			local def, multiplier, income = entryIncome(entry)
			if i > plot.slotCount then
				waiting += 1
			elseif def then
				local pad = plot.slotPads[i]
				local part = CritterVisual.create(def)
				part.CFrame = plot.origin * slotOffset(i) * CFrame.new(0, 1.45 + part.Size.Y / 2, 0)
				CritterVisual.setDetail(part, (if multiplier > 1 then "x" .. multiplier .. " · " else "") .. "+" .. Format.number(income) .. "/s")
				part.Parent = plot.model
				table.insert(plot.parts, part)
				local _ = pad
			end
		end
	end
	plot.waitingLabel.Text = if waiting > 0 then "+" .. waiting .. " bichos esperando pedestal (mejora el Santuario)" else ""
	if owner then
		owner:SetAttribute("CritterCount", if profile then #profile.critters else 0)
		owner:SetAttribute("IncomePerSecond", Plots.GetIncomePerSecond(owner))
	end
end

local function assign(player: Player)
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.pending = 0
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			setOwnerText(plot, "Santuario de " .. player.DisplayName)
			byPlayer[player] = plot
			render(plot)
			updatePendingLabel(plot)
			return
		end
	end
	Remotes.Notify:FireClient(player, "No quedan santuarios libres en este servidor.")
end

-- Al salir: lo que quedaba en el cofre se suma a sus monedas antes del último guardado.
local function release(player: Player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	if plot.pending >= 1 then
		Economy.AddCoins(player, math.floor(plot.pending))
	end
	byPlayer[player] = nil
	plot.owner = nil
	plot.pending = 0
	plot.model:SetAttribute("OwnerUserId", nil)
	setOwnerText(plot, "Santuario libre")
	render(plot)
	updatePendingLabel(plot)
end

-- ¿Está esta posición dentro (o casi) de la parcela del jugador?
function Plots.IsInOwnPlot(player: Player, position: Vector3): boolean
	local plot = byPlayer[player]
	if not plot then
		return false
	end
	local localPosition = plot.origin:PointToObjectSpace(position)
	local half = S.plotSize / 2 + S.depositMargin
	return math.abs(localPosition.X) <= half and math.abs(localPosition.Z) <= half
end

-- Coloca un bicho capturado en el primer pedestal libre. Devuelve si se pudo y el mensaje.
function Plots.AddCritter(player: Player, def: CritterDef, multiplier: number?): (boolean, string)
	local plot = byPlayer[player]
	local profile = Data.Get(player)
	if not plot or not profile then
		return false, "No tienes santuario en este servidor."
	end
	if #profile.critters >= plot.slotCount then
		return false, "¡Tu santuario está lleno! Mejóralo en MEJORAS o pulsa SOLTAR."
	end
	local mult = multiplier or 1
	table.insert(profile.critters, VaultMath.encodeCritter(def.id, mult))
	render(plot)
	local pad = plot.slotPads[#profile.critters]
	if pad then
		Remotes.Effect:FireClient(player, "deposito", pad.Position + Vector3.new(0, 2, 0), def.rarity)
	end
	return true, "¡" .. def.name .. (if mult > 1 then " x" .. mult else "") .. " ya genera +" .. Format.number(def.coinsPerSecond * mult) .. " monedas/s!"
end

-- Da un bicho (premio o compra) aunque no haya hueco: si no cabe, espera a que mejores el santuario.
function Plots.GrantCritter(player: Player, def: CritterDef, multiplier: number?)
	local profile = Data.Get(player)
	if not profile then
		return
	end
	table.insert(profile.critters, VaultMath.encodeCritter(def.id, multiplier or 1))
	local plot = byPlayer[player]
	if plot then
		render(plot)
	end
end

-- Punto seguro delante del santuario del jugador (para reaparecer si se sale del mapa).
function Plots.GetSafeCFrame(player: Player): CFrame?
	local plot = byPlayer[player]
	if not plot then
		return nil
	end
	return plot.origin * CFrame.new(0, 4, -S.plotSize / 2 - 4)
end

-- Punto dentro del santuario, junto al cofre, mirando hacia dentro (para volver a casa de noche).
function Plots.GetHomeCFrame(player: Player): CFrame?
	local plot = byPlayer[player]
	if not plot then
		return nil
	end
	return plot.origin * CFrame.new(0, 5, -S.plotSize / 2 + 15) * CFrame.Angles(0, math.pi, 0)
end

-- Redibuja el santuario (tras mejorar el Santuario o comprar VIP).
function Plots.Refresh(player: Player)
	local plot = byPlayer[player]
	if plot then
		render(plot)
	end
end

function Plots.GetIncomePerSecond(player: Player): number
	local plot = byPlayer[player]
	local profile = Data.Get(player)
	local total = 0
	if plot and profile then
		for i, entry in profile.critters do
			if i <= plot.slotCount then
				local _, _, income = entryIncome(entry)
				total += income
			end
		end
	end
	if player:GetAttribute("Pass_DobleMonedas") == true then
		total *= Shop.Perks.doubleCoinsMultiplier
	end
	return total
end

-- Cada segundo: los bichos de cada santuario llenan su cofre.
local function coinLoop()
	while true do
		task.wait(S.coinTickSeconds)
		for _, plot in plots do
			local owner = plot.owner
			if owner then
				local income = Plots.GetIncomePerSecond(owner)
				if income > 0 then
					plot.pending += income * S.coinTickSeconds
					updatePendingLabel(plot)
				end
			end
		end
	end
end

-- Si el dueño está cerca del cofre (más lejos con el Imán), cobra lo acumulado.
local function collectLoop()
	while true do
		task.wait(S.collectCheckSeconds)
		for _, plot in plots do
			local owner = plot.owner
			local root = owner and getRoot(owner)
			local profile = owner and Data.Get(owner)
			if owner and root and profile and plot.pending >= 1 then
				local offset = root.Position - plot.collectPad.Position
				local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flatDistance <= UpgradeMath.collectRadius(profile.upgrades.Iman or 0) then
					local amount = math.floor(plot.pending)
					plot.pending -= amount
					Economy.AddCoins(owner, amount)
					updatePendingLabel(plot)
					Remotes.Effect:FireClient(owner, "monedas", plot.collectPad.Position, amount)
				end
			end
		end
	end
end

-- Si el sitio no tiene SpawnLocation (plantilla vacía), creamos una en la plaza.
local function ensureSpawnLocation()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			return
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Gameplay.Field.spawn + Vector3.new(0, G + 0.5, 0)
	spawn.Parent = Workspace
end

function Plots.Start()
	ensureSpawnLocation()
	for i = 1, S.plotCount do
		table.insert(plots, buildPlot(i))
	end
	Players.PlayerAdded:Connect(assign)
	for _, player in Players:GetPlayers() do
		assign(player)
	end
	Data.OnLoaded(function(player)
		Plots.Refresh(player)
	end)
	Data.OnRelease(function(player)
		release(player)
	end)
	task.spawn(coinLoop)
	task.spawn(collectLoop)
end

return Plots
