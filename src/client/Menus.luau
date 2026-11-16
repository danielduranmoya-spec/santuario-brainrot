--!strict
-- Menús de MEJORAS, TIENDA y CÓDIGOS (pensados para móvil: botones grandes y tamaños en escala).
-- Solo enseñan datos (atributos del jugador y leaderstats) y piden compras al servidor.
-- El aspecto de los botones sale de Config/UiStyle (tres estilos para elegir, ver ButtonStyle).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Shop = require(Config:WaitForChild("Shop"))
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Mutations = require(Config:WaitForChild("Mutations"))
local UiStyle = require(Config:WaitForChild("UiStyle"))
local Format = require(Shared:WaitForChild("Format"))
local UpgradeMath = require(Shared:WaitForChild("UpgradeMath"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local ButtonStyle = require(script.Parent:WaitForChild("ButtonStyle"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteEvent
local PromptPurchase = remotes:WaitForChild("PromptPurchase") :: RemoteEvent
local RedeemCode = remotes:WaitForChild("RedeemCode") :: RemoteEvent
local Fuse = remotes:WaitForChild("Fuse") :: RemoteEvent
local OpenMachine = remotes:WaitForChild("OpenMachine") :: RemoteEvent

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

-- `key` es el nombre del botón en Config/UiStyle.Buttons (decide su estilo).
local function newButton(parent: Instance, size: UDim2, position: UDim2, color: Color3, text: string, key: string): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.TextScaled = true
	button.Text = text
	button.Parent = parent
	ButtonStyle.text(button, key, color)
	Effects.BindButton(button)
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

	local close = newButton(panel, UDim2.fromScale(0.14, 0.1), UDim2.fromScale(0.84, 0.02), Color3.fromRGB(230, 80, 70), "X", "Cerrar")
	-- En un móvil en horizontal la X medía ~30 píxeles: nunca menos de lo que pide un dedo.
	local closeLimit = Instance.new("UISizeConstraint")
	closeLimit.MinSize = Vector2.new(48, 44)
	closeLimit.Parent = close
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

-- ===== Iconos de los botones laterales (dibujados con piezas de interfaz, sin imágenes externas) =====

local function frame(parent: Instance, size: UDim2, position: UDim2, color: Color3, anchor: Vector2?): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = position
	f.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function round(f: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(radius, 0)
	corner.Parent = f
end

local function outline(f: GuiObject, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = f
end

local function gradient(f: GuiObject, top: Color3, bottom: Color3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bottom)
	g.Rotation = 90
	g.Parent = f
end

-- Destello de 4 puntas (dos barras cruzadas).
local function sparkle(parent: Instance, position: UDim2, size: number, color: Color3)
	for _, rotation in { 0, 90 } do
		local bar = frame(parent, UDim2.fromScale(size, size * 0.22), position, color)
		bar.Rotation = rotation
		round(bar, 1)
	end
end

-- Mejoras: flecha gruesa hacia arriba sobre un escalón, con destellos.
local function drawUpgradeIcon(area: Frame)
	local white = Color3.fromRGB(255, 255, 255)
	local dark = Color3.fromRGB(20, 90, 35)
	local step = frame(area, UDim2.fromScale(0.62, 0.16), UDim2.fromScale(0.5, 0.86), Color3.fromRGB(255, 215, 70))
	round(step, 0.4)
	outline(step, dark, 2)
	local shaft = frame(area, UDim2.fromScale(0.24, 0.38), UDim2.fromScale(0.5, 0.6), white)
	round(shaft, 0.2)
	outline(shaft, dark, 2)
	local head = frame(area, UDim2.fromScale(0.42, 0.42), UDim2.fromScale(0.5, 0.36), white)
	head.Rotation = 45
	head.SizeConstraint = Enum.SizeConstraint.RelativeXX
	round(head, 0.15)
	outline(head, dark, 2)
	-- Tapa la mitad de abajo del rombo para que quede una punta de flecha.
	local cover = frame(area, UDim2.fromScale(0.24, 0.2), UDim2.fromScale(0.5, 0.47), white)
	cover.ZIndex = head.ZIndex + 1
	sparkle(area, UDim2.fromScale(0.82, 0.22), 0.22, Color3.fromRGB(255, 240, 150))
	sparkle(area, UDim2.fromScale(0.18, 0.4), 0.14, Color3.fromRGB(255, 255, 255))
end

-- Tienda: bolsa de compras con asa y una moneda brillante delante.
local function drawShopIcon(area: Frame)
	local dark = Color3.fromRGB(45, 25, 120)
	local handle = frame(area, UDim2.fromScale(0.36, 0.32), UDim2.fromScale(0.46, 0.32), Color3.new(1, 1, 1))
	handle.BackgroundTransparency = 1
	round(handle, 1)
	outline(handle, Color3.fromRGB(255, 255, 255), 4)
	local bag = frame(area, UDim2.fromScale(0.62, 0.52), UDim2.fromScale(0.46, 0.64), Color3.fromRGB(255, 120, 170))
	round(bag, 0.18)
	gradient(bag, Color3.fromRGB(255, 160, 200), Color3.fromRGB(230, 70, 130))
	outline(bag, dark, 2)
	local band = frame(bag, UDim2.fromScale(1, 0.16), UDim2.fromScale(0.5, 0.2), Color3.fromRGB(255, 255, 255))
	band.BackgroundTransparency = 0.25
	local coin = frame(area, UDim2.fromScale(0.36, 0.36), UDim2.fromScale(0.74, 0.76), Color3.fromRGB(255, 205, 50))
	coin.SizeConstraint = Enum.SizeConstraint.RelativeXX
	round(coin, 1)
	gradient(coin, Color3.fromRGB(255, 240, 130), Color3.fromRGB(235, 160, 20))
	outline(coin, Color3.fromRGB(150, 90, 10), 2)
	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Font = Enum.Font.GothamBlack
	mark.TextScaled = true
	mark.TextColor3 = Color3.fromRGB(160, 95, 10)
	mark.Text = "$"
	mark.Parent = coin
	sparkle(area, UDim2.fromScale(0.86, 0.22), 0.2, Color3.fromRGB(255, 240, 150))
end

-- Códigos: regalo con lazo y una etiqueta con "#".
local function drawCodesIcon(area: Frame)
	local dark = Color3.fromRGB(110, 40, 10)
	local box = frame(area, UDim2.fromScale(0.62, 0.46), UDim2.fromScale(0.46, 0.66), Color3.fromRGB(255, 150, 50))
	round(box, 0.15)
	gradient(box, Color3.fromRGB(255, 190, 90), Color3.fromRGB(235, 110, 30))
	outline(box, dark, 2)
	local lid = frame(area, UDim2.fromScale(0.72, 0.16), UDim2.fromScale(0.46, 0.4), Color3.fromRGB(255, 120, 40))
	round(lid, 0.3)
	outline(lid, dark, 2)
	local ribbon = frame(area, UDim2.fromScale(0.14, 0.62), UDim2.fromScale(0.46, 0.6), Color3.fromRGB(255, 240, 120))
	ribbon.ZIndex = lid.ZIndex + 1
	for _, side in { -1, 1 } do
		local loop = frame(area, UDim2.fromScale(0.2, 0.2), UDim2.fromScale(0.46 + side * 0.11, 0.26), Color3.fromRGB(255, 240, 120))
		loop.SizeConstraint = Enum.SizeConstraint.RelativeXX
		loop.Rotation = side * 30
		round(loop, 0.5)
		outline(loop, dark, 2)
	end
	local tag = frame(area, UDim2.fromScale(0.34, 0.34), UDim2.fromScale(0.78, 0.8), Color3.fromRGB(255, 255, 255))
	tag.SizeConstraint = Enum.SizeConstraint.RelativeXX
	round(tag, 0.3)
	outline(tag, dark, 2)
	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Font = Enum.Font.GothamBlack
	mark.TextScaled = true
	mark.TextColor3 = dark
	mark.Text = "#"
	mark.Parent = tag
	sparkle(area, UDim2.fromScale(0.14, 0.24), 0.18, Color3.fromRGB(255, 255, 255))
end

-- Botón lateral con icono, nombre debajo, aviso "!" y un leve balanceo del icono; crece un poco al
-- pasar el ratón y bota al pulsarlo. Su aspecto depende del estilo (Config/UiStyle, clave `key`):
--   Caramelo: degradado, contorno oscuro, relieve abajo y brillo arriba.
--   Pegatina: color plano, borde blanco grueso, letra de cómic e inclinado.
--   Neon: fondo oscuro translúcido con borde y nombre del color del botón.
local function iconButton(parent: Instance, label: string, key: string, top: Color3, bottom: Color3, draw: (Frame) -> ()): (TextButton, Frame)
	local style = UiStyle.styleFor(key)
	local button = Instance.new("TextButton")
	button.Name = "Boton" .. key
	button.Size = UDim2.fromScale(1, 0.23) -- caben 4 en la columna (MEJORAS, TIENDA, CÓDIGOS, ÍNDICE)
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundColor3 = top
	button:SetAttribute("EstiloBoton", style)
	button.Parent = parent
	-- El alto manda (cabe siempre en la columna) y el ancho sale de la proporción.
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 0.85
	ratio.DominantAxis = Enum.DominantAxis.Height
	ratio.Parent = button

	local labelColor = Color3.new(1, 1, 1)
	local labelStroke = Color3.fromRGB(20, 20, 30)
	if style == "Caramelo" then
		round(button, 0.22)
		gradient(button, top, bottom)
		outline(button, Color3.fromRGB(20, 20, 30), 3)
		-- Relieve: franja oscura abajo (como un botón que sobresale) y brillo en la mitad de arriba.
		local base = frame(button, UDim2.fromScale(1, 0.12), UDim2.fromScale(0.5, 0.94), Color3.fromRGB(0, 0, 0))
		base.BackgroundTransparency = 0.65
		round(base, 0.5)
		local shine = frame(button, UDim2.fromScale(0.86, 0.3), UDim2.fromScale(0.5, 0.2), Color3.fromRGB(255, 255, 255))
		shine.BackgroundTransparency = 0.82
		round(shine, 0.5)
	elseif style == "Pegatina" then
		round(button, 0.32)
		outline(button, Color3.new(1, 1, 1), 4)
		button.Rotation = if key == "Tienda" then 3 else -3
	else -- Neon
		round(button, 0.2)
		button.BackgroundColor3 = Color3.fromRGB(18, 16, 30)
		button.BackgroundTransparency = 0.25
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.new(1, 1, 1)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = button
		local strokeGradient = Instance.new("UIGradient")
		strokeGradient.Color = ColorSequence.new(top, bottom)
		strokeGradient.Rotation = 90
		strokeGradient.Parent = stroke
		labelColor = top:Lerp(Color3.new(1, 1, 1), 0.35)
		labelStroke = Color3.fromRGB(0, 0, 0)
	end

	local area = frame(button, UDim2.fromScale(0.8, 0.62), UDim2.fromScale(0.5, 0.4), Color3.new(1, 1, 1))
	area.BackgroundTransparency = 1
	draw(area)

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(0.94, 0.22)
	text.Position = UDim2.fromScale(0.5, 0.86)
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.BackgroundTransparency = 1
	text.Font = UiStyle.Fonts[style]
	text.TextScaled = true
	text.TextColor3 = labelColor
	text.Text = label
	text.Parent = button
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 2
	textStroke.Color = labelStroke
	textStroke.Parent = text

	-- Aviso "!" (por ejemplo, cuando puedes pagar una mejora).
	local badge = frame(button, UDim2.fromScale(0.32, 0.32), UDim2.fromScale(0.92, 0.06), Color3.fromRGB(235, 50, 60))
	badge.SizeConstraint = Enum.SizeConstraint.RelativeXX
	badge.ZIndex = 5
	round(badge, 1)
	outline(badge, Color3.fromRGB(255, 255, 255), 2)
	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Font = Enum.Font.GothamBlack
	mark.TextScaled = true
	mark.TextColor3 = Color3.new(1, 1, 1)
	mark.Text = "!"
	mark.ZIndex = 6
	mark.Parent = badge
	badge.Visible = false

	-- Balanceo suave del icono y estados de ratón.
	TweenService:Create(area, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 5 }):Play()
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.07 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	button.Activated:Connect(function()
		Effects.Play("click")
		scale.Scale = 0.88
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	return button, badge
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
	local button = newButton(frame, UDim2.fromScale(0.33, 0.76), UDim2.fromScale(0.65, 0.12), COLOR_GOOD, "", "Comprar")
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
	-- Arriba a la izquierda, bajo la barra de Roblox: deja libre la esquina de abajo para la cartera.
	side.AnchorPoint = Vector2.new(0, 0)
	side.Position = UDim2.new(0, 12, 0, 54)
	side.Size = UDim2.new(0.12, 0, 0.78, 0)
	side.BackgroundTransparency = 1
	side.Parent = gui
	local sideLimit = Instance.new("UISizeConstraint")
	sideLimit.MaxSize = Vector2.new(120, 470)
	sideLimit.Parent = side
	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0.02, 0) -- 4 botones de 0.23 + 3 huecos = 0.98
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = side

	local upgradesButton, upgradesBadge = iconButton(side, "MEJORAS", "Mejoras", COLOR_GOOD, Color3.fromRGB(30, 130, 50), drawUpgradeIcon)
	upgradesButton.LayoutOrder = 1
	upgradesButton.Visible = false
	local shopButton, shopBadge = iconButton(side, "TIENDA", "Tienda", Color3.fromRGB(120, 90, 255), Color3.fromRGB(60, 40, 170), drawShopIcon)
	shopButton.LayoutOrder = 2
	shopButton.Visible = false
	shopBadge.Visible = false
	local codesButton, codesBadge = iconButton(side, "CÓDIGOS", "Codigos", Color3.fromRGB(255, 150, 50), Color3.fromRGB(210, 90, 20), drawCodesIcon)
	codesButton.LayoutOrder = 3
	codesButton.Visible = false
	codesBadge.Visible = false

	local upgradesPanel, upgradesList = newPanel(gui, "Mejoras")
	local shopPanel, shopList = newPanel(gui, "Tienda")
	local codesPanel, codesList = newPanel(gui, "Códigos")
	local panels = { upgradesPanel, shopPanel, codesPanel }
	local machinePanels: { [string]: { panel: Frame, list: ScrollingFrame } } = {}
	for _, machine in Mutations.Machines do
		local panel, list = newPanel(gui, machine.title)
		machinePanels[machine.id] = { panel = panel, list = list }
		table.insert(panels, panel)
	end

	-- Abre un panel y cierra los demás (o lo cierra si ya estaba abierto).
	local function toggle(panel: Frame)
		for _, other in panels do
			if other ~= panel then
				other.Visible = false
			end
		end
		panel.Visible = not panel.Visible
		if panel.Visible then
			Effects.Pop(panel)
		end
	end

	-- Para otros módulos del cliente (client/Bestiary): botón en la columna y panel que se abre con él.
	function Menus.AddSideButton(label: string, key: string, top: Color3, bottom: Color3, draw: (Frame) -> (), order: number): (TextButton, Frame)
		local button, badge = iconButton(side, label, key, top, bottom, draw)
		button.LayoutOrder = order
		return button, badge
	end
	function Menus.AddPanel(title: string): (Frame, ScrollingFrame)
		local panel, list = newPanel(gui, title)
		table.insert(panels, panel)
		return panel, list
	end
	Menus.Toggle = toggle
	upgradesButton.Activated:Connect(function()
		toggle(upgradesPanel)
	end)
	shopButton.Activated:Connect(function()
		toggle(shopPanel)
	end)
	codesButton.Activated:Connect(function()
		toggle(codesPanel)
	end)

	-- ===== Códigos =====
	-- Caja de texto y botón CANJEAR. El servidor comprueba el código y avisa del resultado.
	local codesHelp = newText(codesList, UDim2.new(1, -12, 0, ROW_HEIGHT * 0.6), UDim2.new(), "Escribe un código de recompensa:")
	codesHelp.LayoutOrder = 1
	codesHelp.TextXAlignment = Enum.TextXAlignment.Center
	local codesRow = Instance.new("Frame")
	codesRow.Size = UDim2.new(1, -12, 0, ROW_HEIGHT)
	codesRow.BackgroundColor3 = COLOR_DARK
	codesRow.LayoutOrder = 2
	codesRow.Parent = codesList
	addCorner(codesRow, 0.15)
	local codeBox = Instance.new("TextBox")
	codeBox.Size = UDim2.fromScale(0.58, 0.7)
	codeBox.Position = UDim2.fromScale(0.03, 0.15)
	codeBox.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	codeBox.TextColor3 = Color3.fromRGB(25, 25, 35)
	codeBox.PlaceholderText = "CÓDIGO"
	codeBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
	codeBox.Font = Enum.Font.GothamBold
	codeBox.TextScaled = true
	codeBox.ClearTextOnFocus = false
	codeBox.Text = ""
	codeBox.Parent = codesRow
	addCorner(codeBox, 0.2)
	local codePadding = Instance.new("UIPadding")
	codePadding.PaddingTop = UDim.new(0.2, 0)
	codePadding.PaddingBottom = UDim.new(0.2, 0)
	codePadding.PaddingLeft = UDim.new(0.04, 0)
	codePadding.Parent = codeBox
	local redeemButton = newButton(codesRow, UDim2.fromScale(0.33, 0.76), UDim2.fromScale(0.64, 0.12), Color3.fromRGB(255, 150, 50), "CANJEAR", "Canjear")
	local function redeem()
		local code = codeBox.Text
		if #code > 0 then
			RedeemCode:FireServer(code)
		end
	end
	redeemButton.Activated:Connect(redeem)
	codeBox.FocusLost:Connect(function(enterPressed: boolean)
		if enterPressed then
			redeem()
		end
	end)
	local codesTip = newText(codesList, UDim2.new(1, -12, 0, ROW_HEIGHT * 0.5), UDim2.new(), "Síguenos: con cada actualización hay códigos nuevos.")
	codesTip.LayoutOrder = 3
	codesTip.Font = Enum.Font.Gotham
	codesTip.TextColor3 = Color3.fromRGB(210, 210, 220)
	codesTip.TextXAlignment = Enum.TextXAlignment.Center

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
		local affordable = false
		for name in upgradeRows do
			local level = (player:GetAttribute("Upgrade_" .. name) :: number?) or 0
			if level < Progression.Upgrades[name].maxLevel and coins >= UpgradeMath.cost(name, level + 1) then
				affordable = true
			end
		end
		-- "!" en el botón cuando puedes pagar alguna mejora.
		upgradesBadge.Visible = affordable
		for name, row in upgradeRows do
			local def = Progression.Upgrades[name]
			local level = (player:GetAttribute("Upgrade_" .. name) :: number?) or 0
			row.title.Text = def.title .. "  (nivel " .. level .. "/" .. def.maxLevel .. ")"
			if level >= def.maxLevel then
				row.detail.Text = def.description .. ": " .. UpgradeMath.effectText(name, level)
				row.button.Text = "MÁX"
				ButtonStyle.setColor(row.button, COLOR_OFF)
			else
				local cost = UpgradeMath.cost(name, level + 1)
				row.detail.Text = UpgradeMath.effectText(name, level) .. " → " .. UpgradeMath.effectText(name, level + 1)
				row.button.Text = "💰 " .. Format.number(cost)
				ButtonStyle.setColor(row.button, if coins >= cost then COLOR_GOOD else COLOR_OFF)
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
				ButtonStyle.setColor(row.button, if owned then COLOR_OFF else COLOR_ROBUX)
			else
				local product = (Shop.DevProducts :: any)[entry.name]
				row.title.Text = product.title
				row.detail.Text = product.description
				row.button.Text = "R$ " .. product.price
				ButtonStyle.setColor(row.button, COLOR_ROBUX)
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

	-- ===== Máquinas de fusión =====
	-- Se abren al usar la máquina en la plaza. Una fila por cada bicho del que tienes ejemplares del
	-- tamaño que pide la máquina. El servidor vuelve a comprobarlo todo al fusionar.
	local defsById: { [string]: CrittersConfig.Critter } = {}
	for _, def in CrittersConfig.List do
		defsById[def.id] = def
	end
	local openMachine: string? = nil

	local function refreshMachine()
		local machine = if openMachine then MutationMath.machine(openMachine) else nil
		local entry = if openMachine then machinePanels[openMachine] else nil
		if not machine or not entry then
			return
		end
		for _, child in entry.list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local help = newText(entry.list, UDim2.new(1, -12, 0, ROW_HEIGHT * 0.7), UDim2.new(), machine.count .. " bichos iguales " .. MutationMath.size(machine.from).id .. " = 1 " .. MutationMath.size(machine.to).label .. " (x" .. MutationMath.size(machine.to).multiplier .. "). El color sale de uno de ellos al azar.")
		help.LayoutOrder = 0
		help.TextColor3 = COLOR_GOLD

		-- Cuántos tiene de cada bicho y de qué colores.
		local groups: { [string]: { [string]: number } } = {}
		local lowestMultiplier: { [string]: number } = {} -- el precio depende de la bóveda de origen
		local list = tostring(player:GetAttribute("CritterList") or "")
		for _, item in string.split(list, ",") do
			if item ~= "" then
				local id, multiplier, color, size = MutationMath.decode(item)
				if size == machine.from and defsById[id] then
					local colors = groups[id] or {}
					colors[color] = (colors[color] or 0) + 1
					groups[id] = colors
					lowestMultiplier[id] = math.min(lowestMultiplier[id] or math.huge, multiplier)
				end
			end
		end
		local order = 1
		for _, def in CrittersConfig.List do
			local colors = groups[def.id]
			if colors then
				local total = 0
				local best = "Normal"
				local parts = {}
				for _, colorDef in Mutations.Colors do
					local n = colors[colorDef.id]
					if n then
						total += n
						table.insert(parts, n .. " " .. (if colorDef.label ~= "" then colorDef.label else "Normal"))
						if colorDef.multiplier > MutationMath.color(best).multiplier then
							best = colorDef.id
						end
					end
				end
				local cost = MutationMath.fusionCost(machine, def.coinsPerSecond, lowestMultiplier[def.id])
				local ready = total >= machine.count and getCoins() >= cost
				local row = newRow(entry.list, order)
				order += 1
				row.title.Text = def.name .. "  " .. math.min(total, machine.count) .. "/" .. machine.count
				row.detail.Text = table.concat(parts, ", ") .. " · " .. Format.number(cost) .. " 💰"
				row.button.Text = if total < machine.count then "FALTAN " .. (machine.count - total) else "FUSIONAR"
				ButtonStyle.setColor(row.button, if ready then COLOR_GOOD else COLOR_OFF)
				row.button.Activated:Connect(function()
					-- Entran primero los del color más valioso (así no se pierde por azar si tienes de sobra).
					Fuse:FireServer(machine.id, def.id, best)
				end)
			end
		end
		if order == 1 then
			local empty = newText(entry.list, UDim2.new(1, -12, 0, ROW_HEIGHT), UDim2.new(), "Aún no tienes bichos de tamaño " .. MutationMath.size(machine.from).id .. " en tu santuario.")
			empty.LayoutOrder = 1
		end
	end

	OpenMachine.OnClientEvent:Connect(function(machineId: string)
		local entry = machinePanels[machineId]
		if not entry then
			return
		end
		openMachine = machineId
		refreshMachine()
		if not entry.panel.Visible then
			toggle(entry.panel)
		end
	end)
	player:GetAttributeChangedSignal("CritterList"):Connect(refreshMachine)

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
			codesButton.Visible = seconds >= Gameplay.Menus.codesAfterSeconds
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

-- Los rellena Menus.Start (client/Bestiary los usa después).
function Menus.AddSideButton(_label: string, _key: string, _top: Color3, _bottom: Color3, _draw: (Frame) -> (), _order: number): (TextButton, Frame)
	error("Menus.Start todavía no se ha llamado")
end
function Menus.AddPanel(_title: string): (Frame, ScrollingFrame)
	error("Menus.Start todavía no se ha llamado")
end
function Menus.Toggle(_panel: Frame) end

return Menus
