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
local ZoneBarriers = require(script.Parent:WaitForChild("ZoneBarriers"))

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

local function newButton(name: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.Visible = false
	button.Parent = gui
	addCorner(button)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(420, 130)
	limit.Parent = button
	return button
end

local coinsLabel = newLabel("Monedas", UDim2.fromScale(0.3, 0.07), UDim2.fromScale(0.5, 0.06), gui)
coinsLabel.TextColor3 = COLOR_GOLD
coinsLabel.Text = "💰 0"

local hintLabel = newLabel("Pista", UDim2.fromScale(0.7, 0.055), UDim2.fromScale(0.5, 0.14), gui)
hintLabel.Visible = false

local toastLabel = newLabel("Aviso", UDim2.fromScale(0.7, 0.08), UDim2.fromScale(0.5, 0.25), gui)
toastLabel.TextWrapped = true
toastLabel.Visible = false

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

local function updateGuide(carrying: boolean)
	local beam = guideBeam
	if not beam then
		return
	end
	if carrying and (guideTarget == nil or guideTarget.Parent == nil) then
		local base = getOwnPlotBase()
		if base then
			local target = Instance.new("Attachment")
			target.Name = "GuiaDestino"
			target.Position = Vector3.new(0, 3, 0)
			target.Parent = base
			guideTarget = target
		end
	end
	beam.Attachment1 = guideTarget
	beam.Enabled = carrying and guideTarget ~= nil
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

-- ===================== Monedas =====================

local function bindCoins()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Monedas") :: IntValue
	local last = coins.Value
	coinsLabel.Text = "💰 " .. Format.number(coins.Value)
	coins.Changed:Connect(function()
		local value = coins.Value
		coinsLabel.Text = "💰 " .. Format.number(value)
		if value > last then
			hasCollected = true
			coinsLabel.Size = UDim2.fromScale(0.33, 0.08)
			TweenService:Create(coinsLabel, TweenInfo.new(0.25), { Size = UDim2.fromScale(0.3, 0.07) }):Play()
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

-- Menús de MEJORAS/TIENDA y barreras de zona.
Menus.OnLocalNotice = function(text: string)
	showToast(text)
end
Menus.Start()
ZoneBarriers.Start()

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
	updateGuide(carrying)

	local hint: string? = nil
	if carrying then
		hint = "🏠 Lleva el bicho a tu santuario (sigue el rayo amarillo)"
	elseif not hasCaught then
		hint = "👉 Acércate a un bicho y pulsa Atrapar"
	elseif not hasCollected then
		hint = "💰 Pisa el cofre dorado de tu santuario para cobrar"
	end
	hintLabel.Visible = hint ~= nil and current == nil
	hintLabel.Text = hint or ""
end)

print("Santuario de Bichos Raros: cliente listo")
