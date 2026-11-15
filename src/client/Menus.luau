--!strict
-- Menús de MEJORAS y TIENDA (pensados para móvil: botones grandes y tamaños en escala).
-- Solo enseñan datos (atributos del jugador y leaderstats) y piden compras al servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Shop = require(Config:WaitForChild("Shop"))
local Format = require(Shared:WaitForChild("Format"))
local UpgradeMath = require(Shared:WaitForChild("UpgradeMath"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteEvent
local PromptPurchase = remotes:WaitForChild("PromptPurchase") :: RemoteEvent

local COLOR_DARK = Color3.fromRGB(25, 25, 35)
local COLOR_PANEL = Color3.fromRGB(40, 40, 55)
local COLOR_GOOD = Color3.fromRGB(70, 200, 90)
local COLOR_OFF = Color3.fromRGB(110, 110, 120)
local COLOR_ROBUX = Color3.fromRGB(60, 140, 255)
local COLOR_GOLD = Color3.fromRGB(255, 200, 40)
local ROW_HEIGHT = 84 -- píxeles por fila dentro de la lista

local Menus = {}

local function addCorner(parent: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(radius or 0.2, 0)
	corner.Parent = parent
end

local function newText(parent: Instance, size: UDim2, position: UDim2, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

local function newButton(parent: Instance, size: UDim2, position: UDim2, color: Color3, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = text
	button.Parent = parent
	addCorner(button)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.18, 0)
	padding.PaddingBottom = UDim.new(0.18, 0)
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0)
	padding.Parent = button
	return button
end

local function getCoins(): number
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Monedas")
	return if coins and coins:IsA("IntValue") then coins.Value else 0
end

-- Panel con título, botón de cerrar y lista con scroll.
local function newPanel(gui: ScreenGui, title: string): (Frame, ScrollingFrame)
	local panel = Instance.new("Frame")
	panel.Name = "Panel" .. title
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.75, 0.78)
	panel.BackgroundColor3 = COLOR_PANEL
	panel.Visible = false
	panel.ZIndex = 5
	panel.Parent = gui
	addCorner(panel, 0.04)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(640, 560)
	limit.Parent = panel

	local titleLabel = newText(panel, UDim2.fromScale(0.75, 0.1), UDim2.fromScale(0.04, 0.02), title)
	titleLabel.Font = Enum.Font.GothamBlack

	local close = newButton(panel, UDim2.fromScale(0.14, 0.1), UDim2.fromScale(0.84, 0.02), Color3.fromRGB(230, 80, 70), "X")
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	local list = Instance.new("ScrollingFrame")
	list.Name = "Lista"
	list.Position = UDim2.fromScale(0.03, 0.14)
	list.Size = UDim2.fromScale(0.94, 0.83)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 8
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	return panel, list
end

type Row = { frame: Frame, title: TextLabel, detail: TextLabel, button: TextButton }

local function newRow(list: ScrollingFrame, order: number): Row
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -12, 0, ROW_HEIGHT)
	frame.BackgroundColor3 = COLOR_DARK
	frame.LayoutOrder = order
	frame.Parent = list
	addCorner(frame, 0.15)
	local title = newText(frame, UDim2.fromScale(0.6, 0.45), UDim2.fromScale(0.03, 0.08), "")
	local detail = newText(frame, UDim2.fromScale(0.6, 0.35), UDim2.fromScale(0.03, 0.56), "")
	detail.Font = Enum.Font.Gotham
	detail.TextColor3 = Color3.fromRGB(210, 210, 220)
	local button = newButton(frame, UDim2.fromScale(0.33, 0.76), UDim2.fromScale(0.65, 0.12), COLOR_GOOD, "")
	return { frame = frame, title = title, detail = detail, button = button }
end

function Menus.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MenusUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	local startedAt = os.clock()

	-- Botones laterales (a la izquierda, por encima del joystick del móvil).
	local side = Instance.new("Frame")
	side.Name = "BotonesMenu"
	side.AnchorPoint = Vector2.new(0, 0.5)
	side.Position = UDim2.fromScale(0.015, 0.42)
	side.Size = UDim2.fromScale(0.16, 0.24)
	side.BackgroundTransparency = 1
	side.Parent = gui
	local sideLimit = Instance.new("UISizeConstraint")
	sideLimit.MaxSize = Vector2.new(220, 170)
	sideLimit.Parent = side
	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0.06, 0)
	sideLayout.Parent = side

	local upgradesButton = newButton(side, UDim2.fromScale(1, 0.46), UDim2.new(), COLOR_GOOD, "⬆ MEJORAS")
	upgradesButton.LayoutOrder = 1
	upgradesButton.Visible = false
	local shopButton = newButton(side, UDim2.fromScale(1, 0.46), UDim2.new(), COLOR_ROBUX, "🛒 TIENDA")
	shopButton.LayoutOrder = 2
	shopButton.Visible = false

	local upgradesPanel, upgradesList = newPanel(gui, "Mejoras")
	local shopPanel, shopList = newPanel(gui, "Tienda")

	upgradesButton.Activated:Connect(function()
		shopPanel.Visible = false
		upgradesPanel.Visible = not upgradesPanel.Visible
	end)
	shopButton.Activated:Connect(function()
		upgradesPanel.Visible = false
		shopPanel.Visible = not shopPanel.Visible
	end)

	-- ===== Mejoras =====
	local upgradeRows: { [string]: Row } = {}
	for i, name in Progression.UpgradeOrder do
		local row = newRow(upgradesList, i)
		row.button.Activated:Connect(function()
			BuyUpgrade:FireServer(name)
		end)
		upgradeRows[name] = row
	end

	local function refreshUpgrades()
		local coins = getCoins()
		for name, row in upgradeRows do
			local def = Progression.Upgrades[name]
			local level = (player:GetAttribute("Upgrade_" .. name) :: number?) or 0
			row.title.Text = def.title .. "  (nivel " .. level .. "/" .. def.maxLevel .. ")"
			if level >= def.maxLevel then
				row.detail.Text = def.description .. ": " .. UpgradeMath.effectText(name, level)
				row.button.Text = "MÁX"
				row.button.BackgroundColor3 = COLOR_OFF
			else
				local cost = UpgradeMath.cost(name, level + 1)
				row.detail.Text = UpgradeMath.effectText(name, level) .. " → " .. UpgradeMath.effectText(name, level + 1)
				row.button.Text = "💰 " .. Format.number(cost)
				row.button.BackgroundColor3 = if coins >= cost then COLOR_GOOD else COLOR_OFF
			end
		end
	end

	-- ===== Tienda =====
	type ShopEntry = { kind: string, name: string, row: Row }
	local shopEntries: { ShopEntry } = {}
	local order = 0
	for _, name in Shop.ProductOrder do
		order += 1
		local entry = { kind = "product", name = name, row = newRow(shopList, order) }
		table.insert(shopEntries, entry)
	end
	for _, name in Shop.PassOrder do
		order += 1
		local entry = { kind = "pass", name = name, row = newRow(shopList, order) }
		table.insert(shopEntries, entry)
	end
	local infoLabel = newText(shopList, UDim2.new(1, -12, 0, ROW_HEIGHT / 2), UDim2.new(), "")
	infoLabel.LayoutOrder = 0
	infoLabel.TextXAlignment = Enum.TextXAlignment.Center
	infoLabel.TextColor3 = COLOR_GOLD

	for _, entry in shopEntries do
		entry.row.button.Activated:Connect(function()
			PromptPurchase:FireServer(entry.kind, entry.name)
		end)
	end

	local starterAnnounced = false

	local function starterAvailable(): boolean
		local pack = Shop.DevProducts.PackInicio
		return player:GetAttribute("StarterPackBought") ~= true and (os.clock() - startedAt) / 60 >= pack.showAfterMinutes
	end

	local function refreshShop()
		for _, entry in shopEntries do
			local row = entry.row
			if entry.kind == "pass" then
				local pass = Shop.GamePasses[entry.name]
				local owned = player:GetAttribute("Pass_" .. entry.name) == true
				row.title.Text = pass.title
				row.detail.Text = pass.description
				row.button.Text = if owned then "✔ TUYO" else "R$ " .. pass.price
				row.button.BackgroundColor3 = if owned then COLOR_OFF else COLOR_ROBUX
			else
				local product = (Shop.DevProducts :: any)[entry.name]
				row.title.Text = product.title
				row.detail.Text = product.description
				row.button.Text = "R$ " .. product.price
				row.button.BackgroundColor3 = COLOR_ROBUX
				if entry.name == "PackInicio" then
					row.frame.Visible = starterAvailable()
				end
			end
		end
		local baits = (player:GetAttribute("Baits") :: number?) or 0
		local luckUntil = (player:GetAttribute("LuckUntil") :: number?) or 0
		local luckLeft = luckUntil - os.time()
		infoLabel.Text = "Cebos: " .. baits .. (if luckLeft > 0 then "   🍀 Suerte: " .. math.ceil(luckLeft / 60) .. " min" else "")
	end

	-- ===== Actualizaciones =====
	player.AttributeChanged:Connect(function()
		refreshUpgrades()
		refreshShop()
	end)
	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats")
		local coins = leaderstats:WaitForChild("Monedas") :: IntValue
		coins.Changed:Connect(refreshUpgrades)
		refreshUpgrades()
	end)
	refreshShop()

	-- Cada segundo: qué botones se ven (GDD: nada de menús ni tiendas al principio).
	task.spawn(function()
		while true do
			local critters = (player:GetAttribute("CritterCount") :: number?) or 0
			local seconds = os.clock() - startedAt
			upgradesButton.Visible = critters >= Gameplay.Menus.upgradesAfterCritters
			shopButton.Visible = seconds >= Gameplay.Menus.shopAfterSeconds
			if not starterAnnounced and starterAvailable() then
				starterAnnounced = true
				refreshShop()
				Menus.OnLocalNotice("🎁 ¡Pack de inicio disponible en la TIENDA!")
			end
			if shopPanel.Visible then
				refreshShop()
			end
			task.wait(1)
		end
	end)
end

-- Main.client lo sustituye por su función de avisos.
function Menus.OnLocalNotice(_text: string) end

return Menus
