--!strict
-- Cliente: interfaz (monedas, barra de captura, botón ¡AHORA!/SOLTAR, pistas y avisos) e input.
-- El cliente nunca decide capturas ni monedas: solo dibuja y pide cosas al servidor por RemoteEvent.
-- Pensado primero para móvil: tamaños en escala y botones grandes en el centro inferior
-- (abajo a la izquierda va el joystick y abajo a la derecha el salto).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CatchBar = require(Shared:WaitForChild("CatchBar"))
local Format = require(Shared:WaitForChild("Format"))
local Menus = require(script.Parent:WaitForChild("Menus"))
local VaultDoors = require(script.Parent:WaitForChild("VaultDoors"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))
local Gameplay = require(Shared:WaitForChild("Config"):WaitForChild("Gameplay"))
local Progression = require(Shared:WaitForChild("Config"):WaitForChild("Progression"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Ambience = require(script.Parent:WaitForChild("Ambience"))
local CritterAnimator = require(script.Parent:WaitForChild("CritterAnimator"))
local Performance = require(script.Parent:WaitForChild("Performance"))
local ButtonStyle = require(script.Parent:WaitForChild("ButtonStyle"))
local LiveHud = require(script.Parent:WaitForChild("LiveHud"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartMinigame = remotes:WaitForChild("StartMinigame") :: RemoteEvent
local CatchResult = remotes:WaitForChild("CatchResult") :: RemoteEvent
local Notify = remotes:WaitForChild("Notify") :: RemoteEvent
local AttemptCatch = remotes:WaitForChild("AttemptCatch") :: RemoteEvent
local ReleaseCarried = remotes:WaitForChild("ReleaseCarried") :: RemoteEvent

local critterFolder = Workspace:WaitForChild("Critters")
local plotsFolder = Workspace:WaitForChild("Santuarios")

local COLOR_DARK = Color3.fromRGB(25, 25, 35)
local COLOR_GOOD = Color3.fromRGB(70, 200, 90)
local COLOR_BAD = Color3.fromRGB(230, 80, 70)
local COLOR_GOLD = Color3.fromRGB(255, 200, 40)

type MinigameData = {
	name: string,
	rarity: string,
	color: Color3,
	startTime: number,
	cycle: number,
	zoneCenter: number,
	zoneWidth: number,
	timeout: number,
}

-- ===================== Interfaz =====================

-- Móvil o tablet: botones y textos con un tamaño mínimo en píxeles, para poder pulsarlos y leerlos.
local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Tamaño mínimo (y máximo) en píxeles de un elemento de la interfaz.
local function limitSize(object: GuiObject, minSize: Vector2?, maxSize: Vector2?)
	local limit = object:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint")
	if minSize then
		limit.MinSize = minSize
	end
	if maxSize then
		limit.MaxSize = maxSize
	end
	limit.Parent = object
end

local gui = Instance.new("ScreenGui")
gui.Name = "SantuarioUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(parent: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = parent
end

local function newLabel(name: string, size: UDim2, position: UDim2, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = size
	label.Position = position
	label.BackgroundColor3 = COLOR_DARK
	label.BackgroundTransparency = 0.3
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = parent
	addCorner(label)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.15, 0)
	padding.PaddingBottom = UDim.new(0.15, 0)
	padding.Parent = label
	return label
end

-- El estilo de cada botón sale de Config/UiStyle (su nombre `name` es la clave).
local function newButton(name: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Size = size
	button.Position = position
	button.TextScaled = true
	button.Visible = false
	button.Parent = gui
	ButtonStyle.text(button, name, color)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(420, 130)
	limit.Parent = button
	return button
end

-- En móvil, abajo a la izquierda está el joystick y abajo a la derecha el botón de saltar:
-- las esquinas de abajo se suben para no taparlos.
local CORNER_LIFT = if IS_TOUCH then -200 else -12

-- ===== Cartera (abajo a la izquierda): monedas y monedas por segundo =====
local wallet = Instance.new("Frame")
wallet.Name = "Cartera"
wallet.AnchorPoint = Vector2.new(0, 1)
wallet.Position = UDim2.new(0, 12, 1, CORNER_LIFT)
wallet.Size = UDim2.fromScale(0.26, 0.12)
wallet.BackgroundColor3 = COLOR_DARK
wallet.BackgroundTransparency = 0.25
wallet.Parent = gui
addCorner(wallet)
local walletLimit = Instance.new("UISizeConstraint")
walletLimit.MinSize = Vector2.new(170, 58)
walletLimit.MaxSize = Vector2.new(300, 92)
walletLimit.Parent = wallet
local walletStroke = Instance.new("UIStroke")
walletStroke.Color = COLOR_GOLD
walletStroke.Thickness = 2
walletStroke.Transparency = 0.3
walletStroke.Parent = wallet
local walletScale = Instance.new("UIScale")
walletScale.Parent = wallet

-- Moneda dibujada: círculo dorado con degradado, borde y símbolo.
local coinIcon = Instance.new("Frame")
coinIcon.Name = "IconoMoneda"
coinIcon.AnchorPoint = Vector2.new(0, 0.5)
coinIcon.Position = UDim2.new(0.04, 0, 0.5, 0)
coinIcon.Size = UDim2.fromScale(0.72, 0.72)
coinIcon.SizeConstraint = Enum.SizeConstraint.RelativeYY
coinIcon.BackgroundColor3 = COLOR_GOLD
coinIcon.Parent = wallet
local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(1, 0)
coinCorner.Parent = coinIcon
local coinGradient = Instance.new("UIGradient")
coinGradient.Color = ColorSequence.new(Color3.fromRGB(255, 235, 120), Color3.fromRGB(230, 150, 20))
coinGradient.Rotation = 90
coinGradient.Parent = coinIcon
local coinStroke = Instance.new("UIStroke")
coinStroke.Color = Color3.fromRGB(150, 90, 10)
coinStroke.Thickness = 2
coinStroke.Parent = coinIcon
local coinSymbol = Instance.new("TextLabel")
coinSymbol.Size = UDim2.fromScale(1, 1)
coinSymbol.BackgroundTransparency = 1
coinSymbol.Font = Enum.Font.GothamBlack
coinSymbol.TextScaled = true
coinSymbol.TextColor3 = Color3.fromRGB(160, 95, 10)
coinSymbol.Text = "$"
coinSymbol.Parent = coinIcon

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "Monedas"
coinsLabel.BackgroundTransparency = 1
coinsLabel.Position = UDim2.fromScale(0.34, 0.08)
coinsLabel.Size = UDim2.fromScale(0.62, 0.52)
coinsLabel.Font = Enum.Font.GothamBlack
coinsLabel.TextScaled = true
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.TextColor3 = COLOR_GOLD
coinsLabel.TextStrokeTransparency = 0.5
coinsLabel.Text = "0"
coinsLabel.Parent = wallet

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "Velocidad"
incomeLabel.BackgroundTransparency = 1
incomeLabel.Position = UDim2.fromScale(0.34, 0.6)
incomeLabel.Size = UDim2.fromScale(0.62, 0.32)
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextScaled = true
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.TextColor3 = Color3.fromRGB(140, 230, 140)
incomeLabel.Text = "⚡ +0/s"
incomeLabel.Parent = wallet

-- Siguiente bóveda: nombre, precio y barra de progreso con tus monedas.
local nextFrame = Instance.new("Frame")
nextFrame.Name = "SiguienteBoveda"
nextFrame.AnchorPoint = Vector2.new(0.5, 0.5)
nextFrame.Size = UDim2.fromScale(0.36, 0.045)
nextFrame.Position = UDim2.fromScale(0.5, 0.06)
nextFrame.BackgroundColor3 = COLOR_DARK
nextFrame.BackgroundTransparency = 0.3
nextFrame.Parent = gui
addCorner(nextFrame)
local nextFill = Instance.new("Frame")
nextFill.Name = "Progreso"
nextFill.Size = UDim2.fromScale(0, 1)
nextFill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
nextFill.BackgroundTransparency = 0.2
nextFill.Parent = nextFrame
addCorner(nextFill)
local nextText = Instance.new("TextLabel")
nextText.Size = UDim2.fromScale(1, 1)
nextText.BackgroundTransparency = 1
nextText.Font = Enum.Font.GothamBold
nextText.TextScaled = true
nextText.TextColor3 = Color3.new(1, 1, 1)
nextText.TextStrokeTransparency = 0.4
nextText.ZIndex = 2
nextText.Parent = nextFrame
local nextPadding = Instance.new("UIPadding")
nextPadding.PaddingTop = UDim.new(0.15, 0)
nextPadding.PaddingBottom = UDim.new(0.15, 0)
nextPadding.Parent = nextText

local hintLabel = newLabel("Pista", UDim2.fromScale(0.7, 0.055), UDim2.fromScale(0.5, 0.12), gui)
hintLabel.Visible = false
limitSize(hintLabel, Vector2.new(260, if IS_TOUCH then 34 else 28), Vector2.new(900, 60))

local toastLabel = newLabel("Aviso", UDim2.fromScale(0.7, 0.08), UDim2.fromScale(0.5, 0.22), gui)
toastLabel.TextWrapped = true
toastLabel.Visible = false
limitSize(toastLabel, Vector2.new(280, if IS_TOUCH then 46 else 36), Vector2.new(900, 90))
limitSize(nextFrame, Vector2.new(260, if IS_TOUCH then 26 else 22), Vector2.new(700, 44))

-- Barra del minijuego
local barTitle = newLabel("TituloBarra", UDim2.fromScale(0.6, 0.05), UDim2.fromScale(0.5, 0.64), gui)
barTitle.Visible = false

local bar = Instance.new("Frame")
bar.Name = "Barra"
bar.AnchorPoint = Vector2.new(0.5, 0.5)
bar.Size = UDim2.fromScale(0.6, 0.05)
bar.Position = UDim2.fromScale(0.5, 0.71)
bar.BackgroundColor3 = COLOR_DARK
bar.Visible = false
bar.Parent = gui
addCorner(bar)

local greenZone = Instance.new("Frame")
greenZone.Name = "ZonaVerde"
greenZone.BackgroundColor3 = COLOR_GOOD
greenZone.BorderSizePixel = 0
greenZone.Parent = bar

local marker = Instance.new("Frame")
marker.Name = "Aguja"
marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.Size = UDim2.new(0, 8, 1.6, 0)
marker.BackgroundColor3 = Color3.new(1, 1, 1)
marker.BorderSizePixel = 0
marker.ZIndex = 2
marker.Parent = bar

local nowButton = newButton("Ahora", UDim2.fromScale(0.3, 0.13), UDim2.fromScale(0.5, 0.93), COLOR_GOOD)
nowButton.Text = "¡AHORA!"

local releaseButton = newButton("Soltar", UDim2.fromScale(0.18, 0.07), UDim2.fromScale(0.5, 0.97), COLOR_BAD)
releaseButton.Text = "SOLTAR"

-- En un móvil en horizontal (unos 390 píxeles de alto) SOLTAR medía 27 píxeles: ahora nunca menos
-- de lo que pide un dedo (unos 48-56 píxeles de alto).
if IS_TOUCH then
	limitSize(nowButton, Vector2.new(220, 86), nil)
	limitSize(releaseButton, Vector2.new(170, 60), nil)
	limitSize(bar, Vector2.new(260, 30), nil)
	limitSize(barTitle, Vector2.new(240, 30), nil)
end

-- ===================== Estado =====================

local minigame: MinigameData? = nil
local waitingResult = false
local hasCaught = false
local hasCollected = false
local toastId = 0

local function showToast(text: string, color: Color3?)
	toastId += 1
	local myId = toastId
	toastLabel.Text = text
	toastLabel.TextColor3 = color or Color3.new(1, 1, 1)
	toastLabel.Visible = true
	Effects.Pop(toastLabel)
	-- Los avisos largos se quedan más tiempo en pantalla.
	task.delay(3 + #text / 25, function()
		if toastId == myId then
			toastLabel.Visible = false
		end
	end)
end

local function getCarried(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("Carried") then
			return child
		end
	end
	return nil
end

local function getOwnPlotBase(): BasePart?
	for _, model in plotsFolder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId then
			return model.PrimaryPart
		end
	end
	return nil
end

-- ===================== Guía hacia el santuario =====================
-- Mientras llevas un bicho, un rayo amarillo une tu personaje con tu santuario.

local guideBeam: Beam? = nil
local guideTarget: Attachment? = nil

local function setupGuide(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local from = Instance.new("Attachment")
	from.Name = "GuiaOrigen"
	from.Parent = root

	local beam = Instance.new("Beam")
	beam.Name = "GuiaSantuario"
	beam.Attachment0 = from
	beam.Color = ColorSequence.new(COLOR_GOLD)
	beam.Transparency = NumberSequence.new(0.3)
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Enabled = false
	beam.Parent = root
	guideBeam = beam
end

-- El rayo apunta a `part` (o se apaga con nil). Si llevas un bicho, a tu santuario; si ya tienes
-- monedas para la siguiente bóveda, a su puerta.
local function updateGuide(part: BasePart?)
	local beam = guideBeam
	if not beam then
		return
	end
	if part and (guideTarget == nil or guideTarget.Parent ~= part) then
		if guideTarget then
			guideTarget:Destroy()
		end
		local target = Instance.new("Attachment")
		target.Name = "GuiaDestino"
		target.Position = Vector3.new(0, 3, 0)
		target.Parent = part
		guideTarget = target
	end
	beam.Attachment1 = guideTarget
	beam.Enabled = part ~= nil and guideTarget ~= nil
end

player.CharacterAdded:Connect(setupGuide)
if player.Character then
	task.spawn(setupGuide, player.Character)
end

-- ===================== Flecha sobre el primer bicho =====================

local function markTutorial(child: Instance)
	if child:IsA("BasePart") and child:GetAttribute("TutorialFor") == player.UserId then
		local arrow = Instance.new("BillboardGui")
		arrow.Name = "Flecha"
		arrow.Size = UDim2.new(6, 0, 3, 0)
		arrow.StudsOffsetWorldSpace = Vector3.new(0, child.Size.Y / 2 + 4.5, 0)
		arrow.AlwaysOnTop = true
		arrow.LightInfluence = 0
		arrow.Parent = child
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = COLOR_GOLD
		text.TextStrokeTransparency = 0
		text.Text = "¡Atrápalo!\n⬇"
		text.Parent = arrow
	end
end

critterFolder.ChildAdded:Connect(markTutorial)
for _, child in critterFolder:GetChildren() do
	markTutorial(child)
end

-- ===================== Objetivos de los primeros minutos =====================
-- Panel pequeño a la derecha (el centro de la pantalla queda libre) con el objetivo actual y una
-- barra de progreso. Se apoya en lo que guarda el servidor, así que no se repite al volver a entrar.

local TUTORIAL = Gameplay.Tutorial

local objectives = Instance.new("Frame")
objectives.Name = "Objetivos"
objectives.AnchorPoint = Vector2.new(1, 0.5)
objectives.Position = UDim2.new(1, -12, 0.55, 0)
objectives.Size = UDim2.fromScale(0.24, 0.13)
objectives.BackgroundColor3 = COLOR_DARK
objectives.BackgroundTransparency = 0.25
objectives.Visible = false
objectives.Parent = gui
addCorner(objectives)
limitSize(objectives, Vector2.new(if IS_TOUCH then 210 else 190, if IS_TOUCH then 78 else 70), Vector2.new(330, 120))
local objectivesStroke = Instance.new("UIStroke")
objectivesStroke.Color = COLOR_GOLD
objectivesStroke.Thickness = 2
objectivesStroke.Transparency = 0.3
objectivesStroke.Parent = objectives

local objectivesTitle = Instance.new("TextLabel")
objectivesTitle.Name = "Titulo"
objectivesTitle.BackgroundTransparency = 1
objectivesTitle.Position = UDim2.fromScale(0.06, 0.06)
objectivesTitle.Size = UDim2.fromScale(0.88, 0.28)
objectivesTitle.Font = Enum.Font.GothamBlack
objectivesTitle.TextScaled = true
objectivesTitle.TextXAlignment = Enum.TextXAlignment.Left
objectivesTitle.TextColor3 = COLOR_GOLD
objectivesTitle.Parent = objectives

local objectivesText = Instance.new("TextLabel")
objectivesText.Name = "Objetivo"
objectivesText.BackgroundTransparency = 1
objectivesText.Position = UDim2.fromScale(0.06, 0.36)
objectivesText.Size = UDim2.fromScale(0.88, 0.4)
objectivesText.Font = Enum.Font.GothamBold
objectivesText.TextScaled = true
objectivesText.TextWrapped = true
objectivesText.TextXAlignment = Enum.TextXAlignment.Left
objectivesText.TextColor3 = Color3.new(1, 1, 1)
objectivesText.Parent = objectives

local objectivesTrack = Instance.new("Frame")
objectivesTrack.Name = "Progreso"
objectivesTrack.Position = UDim2.fromScale(0.06, 0.82)
objectivesTrack.Size = UDim2.fromScale(0.88, 0.09)
objectivesTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
objectivesTrack.BorderSizePixel = 0
objectivesTrack.Parent = objectives
addCorner(objectivesTrack)
local objectivesFill = Instance.new("Frame")
objectivesFill.Size = UDim2.fromScale(0, 1)
objectivesFill.BackgroundColor3 = COLOR_GOOD
objectivesFill.BorderSizePixel = 0
objectivesFill.Parent = objectivesTrack
addCorner(objectivesFill)

local function critterCount(): number
	return (player:GetAttribute("CritterCount") :: number?) or 0
end

local function anyUpgrade(): boolean
	for _, name in Progression.UpgradeOrder do
		if ((player:GetAttribute("Upgrade_" .. name) :: number?) or 0) > 0 then
			return true
		end
	end
	return false
end

-- Cada objetivo: texto y si ya está hecho.
local OBJECTIVES: { { text: string, done: () -> boolean } } = {
	{ text = "Atrapa un bicho: acércate y pulsa Atrapar", done = function()
		return hasCaught or critterCount() >= 1
	end },
	{ text = "Lleva el bicho a tu santuario", done = function()
		return critterCount() >= 1
	end },
	{ text = "Pisa el cofre dorado para cobrar", done = function()
		return hasCollected
	end },
	{ text = "Compra una mejora en MEJORAS", done = anyUpgrade },
	{ text = "Ten " .. TUTORIAL.critterGoal .. " bichos en tu santuario", done = function()
		return critterCount() >= TUTORIAL.critterGoal
	end },
	{ text = "Abre la bóveda " .. TUTORIAL.vaultGoal .. " (sigue el rayo amarillo)", done = function()
		return ((player:GetAttribute("MaxVault") :: number?) or 1) >= TUTORIAL.vaultGoal
	end },
}

local objectivesFinished = false
local lastObjective = 0
local dataReady = false -- hasta que llega la partida guardada no se sabe qué objetivos ya tiene

local function refreshObjectives()
	if objectivesFinished or not dataReady then
		return
	end
	local current = #OBJECTIVES + 1
	for index, objective in OBJECTIVES do
		if not objective.done() then
			current = index
			break
		end
	end
	if current > #OBJECTIVES then
		objectivesFinished = true
		if lastObjective == 0 then
			return -- ya los tenía todos al entrar: no se enseña nada
		end
		objectivesTitle.Text = "🎯 ¡Objetivos completados!"
		objectivesText.Text = "Ahora atrapa bichos más raros y abre más bóvedas."
		objectivesFill.Size = UDim2.fromScale(1, 1)
		Effects.Pop(objectives)
		Effects.Play("recompensa")
		task.delay(TUTORIAL.doneHideSeconds, function()
			objectives.Visible = false
		end)
		return
	end
	if current ~= lastObjective then
		if lastObjective ~= 0 then
			Effects.Pop(objectives) -- objetivo cumplido: salta el panel
		end
		lastObjective = current
		objectivesTitle.Text = "🎯 Objetivo " .. current .. "/" .. #OBJECTIVES
		objectivesText.Text = OBJECTIVES[current].text
		objectivesFill.Size = UDim2.fromScale((current - 1) / #OBJECTIVES, 1)
		objectives.Visible = true
	end
end

-- Quien vuelve con la partida avanzada ya sabe atrapar y cobrar: sin pistas de principiante.
local function onDataLoaded()
	if critterCount() >= 2 or ((player:GetAttribute("MaxVault") :: number?) or 1) >= 2 or anyUpgrade() then
		hasCaught = true
		hasCollected = true
	end
	dataReady = true
	refreshObjectives()
end
if player:GetAttribute("DataLoaded") == true then
	task.defer(onDataLoaded)
else
	local loadedConnection: RBXScriptConnection? = nil
	loadedConnection = player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
		if player:GetAttribute("DataLoaded") == true then
			if loadedConnection then
				loadedConnection:Disconnect()
			end
			onDataLoaded()
		end
	end)
end

task.spawn(function()
	while not objectivesFinished do
		refreshObjectives()
		task.wait(0.5)
	end
end)

-- ===================== Monedas =====================

local currentCoins = 0

local function updateIncome()
	local income = (player:GetAttribute("IncomePerSecond") :: number?) or 0
	incomeLabel.Text = "⚡ +" .. Format.number(income) .. " /s"
end

local function bindCoins()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Monedas") :: IntValue
	local last = coins.Value
	currentCoins = coins.Value
	coinsLabel.Text = Format.number(coins.Value)
	updateIncome()
	player:GetAttributeChangedSignal("IncomePerSecond"):Connect(updateIncome)
	coins.Changed:Connect(function()
		local value = coins.Value
		currentCoins = value
		coinsLabel.Text = Format.number(value)
		if value > last then
			hasCollected = true
			-- Bote de la cartera al ganar monedas.
			walletScale.Scale = 1.08
			TweenService:Create(walletScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		last = value
	end)
end
task.spawn(bindCoins)

-- ===================== Minijuego =====================

local function hideMinigame()
	minigame = nil
	waitingResult = false
	bar.Visible = false
	barTitle.Visible = false
end

StartMinigame.OnClientEvent:Connect(function(data: MinigameData)
	minigame = data
	waitingResult = false
	greenZone.Size = UDim2.fromScale(data.zoneWidth, 1)
	greenZone.Position = UDim2.fromScale(data.zoneCenter - data.zoneWidth / 2, 0)
	barTitle.Text = data.name .. " (" .. data.rarity .. ")"
	barTitle.TextColor3 = data.color
	bar.Visible = true
	barTitle.Visible = true
	Effects.Play("barra_inicio")
	Effects.Pop(bar)
	Effects.Pop(barTitle)
end)

CatchResult.OnClientEvent:Connect(function(success: boolean, message: string)
	hideMinigame()
	if success then
		hasCaught = true
	end
	showToast(message, if success then COLOR_GOOD else COLOR_BAD)
end)

Notify.OnClientEvent:Connect(function(message: string)
	showToast(message)
end)

-- Efectos y sonido, menús de MEJORAS/TIENDA, barreras de zona y atmósfera por zona.
Effects.Start()
Effects.BindButton(nowButton)
Effects.BindButton(releaseButton)
Menus.OnLocalNotice = function(text: string)
	showToast(text)
end
Menus.Start()
VaultDoors.Start()
Ambience.Start()
Performance.Start()
CritterAnimator.Start()
LiveHud.Start(gui, function(text: string, color: Color3?)
	showToast(text, color)
end)

local function tryCatch()
	if minigame and not waitingResult then
		waitingResult = true
		-- Solo mandamos el momento del toque; el servidor decide si fue en la zona verde.
		AttemptCatch:FireServer(Workspace:GetServerTimeNow())
	end
end

nowButton.Activated:Connect(tryCatch)
releaseButton.Activated:Connect(function()
	ReleaseCarried:FireServer()
end)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	-- La E y el botón X sirven aunque otro sistema ya los haya usado: durante la barra
	-- no hay avisos "Atrapar" activos que puedan quedárselos.
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		tryCatch()
	elseif processed then
		return
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and minigame then
		tryCatch()
	end
end)

-- ===================== Cada fotograma =====================

RunService.RenderStepped:Connect(function()
	local current = minigame
	local carrying = getCarried() ~= nil

	if current and not waitingResult then
		local elapsed = Workspace:GetServerTimeNow() - current.startTime
		marker.Position = UDim2.fromScale(CatchBar.markerAt(math.max(elapsed, 0), current.cycle), 0.5)
	end

	nowButton.Visible = current ~= nil
	releaseButton.Visible = carrying and current == nil
	-- Sin avisos "Atrapar" mientras juegas la barra o llevas un bicho (solo en este cliente).
	ProximityPromptService.Enabled = current == nil and not carrying

	-- Siguiente bóveda y su precio.
	local maxVault = (player:GetAttribute("MaxVault") :: number?) or 1
	local nextVault = maxVault + 1
	local nextCost = VaultMath.cost(nextVault)
	local canAfford = currentCoins >= nextCost
	nextText.Text = "🔒 Bóveda " .. nextVault .. " · " .. VaultMath.name(nextVault) .. ": " .. Format.number(currentCoins) .. " / " .. Format.number(nextCost) .. " 💰"
	nextFill.Size = UDim2.fromScale(math.clamp(currentCoins / math.max(nextCost, 1), 0, 1), 1)
	nextFill.BackgroundColor3 = if canAfford then COLOR_GOOD else Color3.fromRGB(90, 160, 255)

	-- Rayo guía: al santuario si llevas un bicho; a la puerta si ya puedes pagarla.
	if carrying then
		updateGuide(getOwnPlotBase())
	elseif canAfford and hasCaught then
		updateGuide(VaultDoors.NextPanel())
	else
		updateGuide(nil)
	end

	local hint: string? = nil
	if carrying then
		hint = "🏠 Lleva el bicho a tu santuario (sigue el rayo amarillo)"
	elseif not hasCaught then
		hint = "👉 Acércate a un bicho y pulsa Atrapar"
	elseif not hasCollected then
		hint = "💰 Pisa la plataforma dorada de tu santuario para cobrar"
	elseif canAfford then
		hint = "🔓 ¡Ya puedes abrir la bóveda " .. nextVault .. "! Sigue el rayo amarillo"
	end
	hintLabel.Visible = hint ~= nil and current == nil
	hintLabel.Text = hint or ""
end)

print("Santuario de Bichos Raros: cliente listo")
