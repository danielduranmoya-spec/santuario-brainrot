--!strict
-- Santuarios: cada jugador recibe una parcela al entrar. Los bichos colocados en sus huecos
-- generan monedas que se acumulan en el cofre dorado; el dueño las cobra al pisarlo
-- (la mejora Imán ampliará esa distancia en la siguiente fase).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Format = require(Shared:WaitForChild("Format"))

local Economy = require(script.Parent:WaitForChild("Economy"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local CritterVisual = require(script.Parent:WaitForChild("CritterVisual"))

type CritterDef = CrittersConfig.Critter

type Placed = {
	def: CritterDef,
	part: BasePart,
}

type Plot = {
	index: number,
	model: Model,
	origin: CFrame, -- centro de la parcela a ras de suelo; -Z mira hacia la playa
	ownerLabel: TextLabel,
	pendingLabel: TextLabel,
	collectPad: BasePart,
	slotPads: { BasePart },
	owner: Player?,
	placed: { Placed },
	pending: number,
	slotCount: number,
}

local S = Gameplay.Sanctuary
local MAX_SLOTS = Progression.StartingSlots + Progression.Upgrades.Santuario.maxLevel

local Plots = {}

local folder = Instance.new("Folder")
folder.Name = "Santuarios"
folder.Parent = Workspace

local plots: { Plot } = {}
local byPlayer: { [Player]: Plot } = {}

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
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
	label.Parent = gui
	return label
end

local function slotOffset(i: number): CFrame
	local column = (i - 1) % S.slotColumns
	local row = (i - 1) // S.slotColumns
	local x = (column - (S.slotColumns - 1) / 2) * S.slotSpacing
	local z = S.slotStartZ + row * S.slotSpacing
	return CFrame.new(x, 1.2, z)
end

local function updatePendingLabel(plot: Plot)
	plot.pendingLabel.Text = "💰 " .. Format.number(plot.pending) .. "\nPísame para cobrar"
end

local function refreshSlots(plot: Plot)
	for i, pad in plot.slotPads do
		local unlocked = i <= plot.slotCount
		pad.Transparency = if unlocked then 0 else 1
		pad.CanQuery = unlocked
	end
end

local function buildPlot(index: number): Plot
	local center = Gameplay.Spawning.center
	local angle = (index - 1) / S.plotCount * math.pi * 2
	local position = Vector3.new(
		center.X + math.cos(angle) * S.ringRadius,
		Gameplay.GroundY,
		center.Z + math.sin(angle) * S.ringRadius
	)
	local origin = CFrame.lookAt(position, Vector3.new(center.X, Gameplay.GroundY, center.Z))

	local model = Instance.new("Model")
	model.Name = "Santuario" .. index
	model:SetAttribute("PlotIndex", index)

	local base = newPart("Suelo", Vector3.new(S.plotSize, 1, S.plotSize), origin * CFrame.new(0, 0.5, 0), Color3.fromRGB(120, 170, 120), model)
	base.Material = Enum.Material.Grass
	model.PrimaryPart = base
	local ownerLabel = newBillboard(base, 16, 3, 9)
	ownerLabel.Text = "Santuario libre"

	local collectPad = newPart(
		"Cofre",
		Vector3.new(1, 5, 5),
		origin * CFrame.new(0, 1.5, -S.plotSize / 2 + 4) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(255, 200, 40),
		model
	)
	collectPad.Shape = Enum.PartType.Cylinder
	collectPad.Material = Enum.Material.Neon
	local pendingLabel = newBillboard(collectPad, 8, 2.5, 3)

	local slotPads = {}
	for i = 1, MAX_SLOTS do
		local pad = newPart("Hueco" .. i, Vector3.new(4, 0.4, 4), origin * slotOffset(i), Color3.fromRGB(200, 230, 200), model)
		pad.CanCollide = false
		table.insert(slotPads, pad)
	end

	model.Parent = folder

	local plot: Plot = {
		index = index,
		model = model,
		origin = origin,
		ownerLabel = ownerLabel,
		pendingLabel = pendingLabel,
		collectPad = collectPad,
		slotPads = slotPads,
		owner = nil,
		placed = {},
		pending = 0,
		slotCount = Progression.StartingSlots,
	}
	refreshSlots(plot)
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

local function assign(player: Player)
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.pending = 0
			plot.slotCount = Progression.StartingSlots -- la mejora Santuario lo subirá
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			plot.ownerLabel.Text = "Santuario de " .. player.DisplayName
			byPlayer[player] = plot
			refreshSlots(plot)
			updatePendingLabel(plot)
			return
		end
	end
	Remotes.Notify:FireClient(player, "No quedan santuarios libres en este servidor.")
end

local function release(player: Player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	byPlayer[player] = nil
	for _, placed in plot.placed do
		placed.part:Destroy()
	end
	plot.placed = {}
	plot.owner = nil
	plot.pending = 0
	plot.model:SetAttribute("OwnerUserId", nil)
	plot.ownerLabel.Text = "Santuario libre"
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

-- Coloca un bicho en el primer hueco libre. Devuelve si se pudo y el mensaje para el jugador.
function Plots.AddCritter(player: Player, def: CritterDef): (boolean, string)
	local plot = byPlayer[player]
	if not plot then
		return false, "No tienes santuario en este servidor."
	end
	if #plot.placed >= plot.slotCount then
		return false, "¡Tu santuario está lleno! Pulsa SOLTAR para liberar al bicho."
	end

	local pad = plot.slotPads[#plot.placed + 1]
	local part = CritterVisual.create(def)
	part.CFrame = pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + part.Size.Y / 2, 0)
	CritterVisual.setDetail(part, "+" .. Format.number(def.coinsPerSecond) .. "/s")
	part.Parent = plot.model
	table.insert(plot.placed, { def = def, part = part })

	return true, "¡" .. def.name .. " ya genera +" .. Format.number(def.coinsPerSecond) .. " monedas/s!"
end

function Plots.GetIncomePerSecond(player: Player): number
	local plot = byPlayer[player]
	local total = 0
	if plot then
		for _, placed in plot.placed do
			total += placed.def.coinsPerSecond
		end
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

-- Si el dueño pisa el cofre, cobra lo acumulado.
local function collectLoop()
	while true do
		task.wait(S.collectCheckSeconds)
		for _, plot in plots do
			local owner = plot.owner
			local root = owner and getRoot(owner)
			if owner and root and plot.pending >= 1 then
				local offset = root.Position - plot.collectPad.Position
				local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flatDistance <= S.collectRadius then
					local amount = math.floor(plot.pending)
					plot.pending -= amount
					Economy.AddCoins(owner, amount)
					updatePendingLabel(plot)
				end
			end
		end
	end
end

-- Si el sitio no tiene SpawnLocation (plantilla vacía), creamos una en el centro de la playa.
local function ensureSpawnLocation()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			return
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Gameplay.Spawning.center + Vector3.new(0, Gameplay.GroundY + 0.5, 0)
	spawn.Parent = Workspace
end

function Plots.Start()
	ensureSpawnLocation()
	for i = 1, S.plotCount do
		table.insert(plots, buildPlot(i))
	end
	Players.PlayerAdded:Connect(assign)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do
		assign(player)
	end
	task.spawn(coinLoop)
	task.spawn(collectLoop)
end

return Plots
