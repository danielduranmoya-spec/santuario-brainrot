--!strict
-- Santuarios: cada jugador recibe una parcela al entrar. Sus bichos (guardados en el perfil) se
-- colocan en los huecos y generan monedas que se acumulan en el cofre dorado; el dueño las cobra
-- al pisarlo (el Imán amplía la distancia). Si tiene más bichos que huecos, los demás esperan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Shop = require(Config:WaitForChild("Shop"))
local Format = require(Shared:WaitForChild("Format"))
local UpgradeMath = require(Shared:WaitForChild("UpgradeMath"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local CritterVisual = require(script.Parent:WaitForChild("CritterVisual"))

type CritterDef = CrittersConfig.Critter

type Plot = {
	index: number,
	model: Model,
	origin: CFrame, -- centro de la parcela a ras de suelo; -Z mira hacia la playa
	ownerLabel: TextLabel,
	pendingLabel: TextLabel,
	waitingLabel: TextLabel,
	collectPad: BasePart,
	slotPads: { BasePart },
	owner: Player?,
	parts: { BasePart }, -- bichos dibujados en los huecos
	pending: number,
	slotCount: number,
}

local S = Gameplay.Sanctuary
local MAX_SLOTS = UpgradeMath.slotCount(Progression.Upgrades.Santuario.maxLevel, true)

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

local function buildPlot(index: number): Plot
	local center = Gameplay.Zones.PlayaRara.center
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
	-- Con StreamingEnabled, que el santuario llegue entero (el rayo guía apunta a su suelo).
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

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

	local waitingLabel = newBillboard(base, 14, 1.5, 6.5)
	waitingLabel.TextColor3 = Color3.fromRGB(255, 220, 120)

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
		waitingLabel = waitingLabel,
		collectPad = collectPad,
		slotPads = slotPads,
		owner = nil,
		parts = {},
		pending = 0,
		slotCount = Progression.StartingSlots,
	}
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

-- Vuelve a dibujar los huecos y los bichos del santuario a partir del perfil.
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
		pad.Transparency = if unlocked then 0 else 1
		pad.CanQuery = unlocked
	end

	local waiting = 0
	if profile then
		for i, id in profile.critters do
			local def = defsById[id]
			if i > plot.slotCount then
				waiting += 1
			elseif def then
				local pad = plot.slotPads[i]
				local part = CritterVisual.create(def)
				part.CFrame = pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + part.Size.Y / 2, 0)
				CritterVisual.setDetail(part, "+" .. Format.number(def.coinsPerSecond) .. "/s")
				part.Parent = plot.model
				table.insert(plot.parts, part)
			end
		end
	end
	plot.waitingLabel.Text = if waiting > 0 then "+" .. waiting .. " bichos esperando hueco (mejora el Santuario)" else ""
	if owner then
		owner:SetAttribute("CritterCount", if profile then #profile.critters else 0)
	end
end

local function assign(player: Player)
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.pending = 0
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			plot.ownerLabel.Text = "Santuario de " .. player.DisplayName
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
	plot.ownerLabel.Text = "Santuario libre"
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

-- Coloca un bicho capturado en el primer hueco libre. Devuelve si se pudo y el mensaje para el jugador.
function Plots.AddCritter(player: Player, def: CritterDef): (boolean, string)
	local plot = byPlayer[player]
	local profile = Data.Get(player)
	if not plot or not profile then
		return false, "No tienes santuario en este servidor."
	end
	if #profile.critters >= plot.slotCount then
		return false, "¡Tu santuario está lleno! Mejóralo en MEJORAS o pulsa SOLTAR."
	end
	table.insert(profile.critters, def.id)
	render(plot)
	return true, "¡" .. def.name .. " ya genera +" .. Format.number(def.coinsPerSecond) .. " monedas/s!"
end

-- Da un bicho (premio o compra) aunque no haya hueco: si no cabe, espera a que mejores el santuario.
function Plots.GrantCritter(player: Player, def: CritterDef)
	local profile = Data.Get(player)
	if not profile then
		return
	end
	table.insert(profile.critters, def.id)
	local plot = byPlayer[player]
	if plot then
		render(plot)
	end
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
		for i, id in profile.critters do
			local def = defsById[id]
			if i <= plot.slotCount and def then
				total += def.coinsPerSecond
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
	spawn.Position = Gameplay.Zones.PlayaRara.center + Vector3.new(0, Gameplay.GroundY + 0.5, 0)
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
