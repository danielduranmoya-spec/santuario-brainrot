--!strict
-- Interfaz de los eventos y del robo amable (solo enseña cosas y pide acciones al servidor):
--   * Avisos para todos (Remotes.Announce): salen en pantalla y en el chat.
--   * Cartel arriba a la derecha con cuentas atrás: legendario, Lluvia de Bichos, cebo, valla.
--   * Marca "⭐ LEGENDARIO" sobre el bicho legendario de servidor.
--   * Botón CASA de noche (si Config/Events.DayNight.sendHome = "boton") y botón VALLA cuando te
--     ponen un cebo.
--   * Esconde los avisos "Poner cebo" en tu propio santuario o si no tienes cebos, y el "Espantar"
--     de los cebos que no son tuyos.
-- Los tiempos (BaitedUntil, FenceUntil, LegendaryAt, RainEndsAt) son segundos UTC, como
-- Workspace:GetServerTimeNow().

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Events = require(Config:WaitForChild("Events"))
local Format = require(Shared:WaitForChild("Format"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))
local ButtonStyle = require(script.Parent:WaitForChild("ButtonStyle"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Announce = remotes:WaitForChild("Announce") :: RemoteEvent
local GoHome = remotes:WaitForChild("GoHome") :: RemoteEvent
local BuyFence = remotes:WaitForChild("BuyFence") :: RemoteEvent

local COLOR_DARK = Color3.fromRGB(25, 25, 35)
local COLOR_GOLD = Color3.fromRGB(255, 200, 40)
local COLOR_HOME = Color3.fromRGB(90, 120, 230)
local COLOR_FENCE = Color3.fromRGB(60, 180, 230)

local LiveHud = {}

type Toast = (text: string, color: Color3?) -> ()

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

local function postToChat(text: string)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general and general:IsA("TextChannel") then
			general:DisplaySystemMessage(text)
		end
	end)
end

local function newBigButton(gui: ScreenGui, key: string, text: string, color: Color3, anchor: Vector2, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = key
	button.AnchorPoint = anchor
	button.Position = position
	button.Size = UDim2.fromScale(0.2, 0.08)
	button.TextScaled = true
	button.Text = text
	button.Visible = false
	button.Parent = gui
	ButtonStyle.text(button, key, color)
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(140, 48)
	limit.MaxSize = Vector2.new(300, 90)
	limit.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.14, 0)
	padding.PaddingBottom = UDim.new(0.14, 0)
	padding.PaddingLeft = UDim.new(0.06, 0)
	padding.PaddingRight = UDim.new(0.06, 0)
	padding.Parent = button
	Effects.BindButton(button)
	return button
end

-- Marca el bicho legendario de servidor para que se vea desde lejos.
local function markLegendary(child: Instance)
	if not child:IsA("BasePart") or child:GetAttribute("EventTag") ~= "legendario" then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MarcaLegendario"
	billboard.Size = UDim2.new(10, 0, 2.5, 0)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, child.Size.Y / 2 + 5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 400
	billboard.Parent = child
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.LuckiestGuy
	text.TextScaled = true
	text.TextColor3 = COLOR_GOLD
	text.TextStrokeTransparency = 0
	text.Text = "⭐ LEGENDARIO ⭐"
	text.Parent = billboard
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.7
	highlight.FillColor = COLOR_GOLD
	highlight.OutlineColor = Color3.fromRGB(255, 240, 160)
	highlight.Parent = child
	-- Se quita al atraparlo (el servidor borra el atributo).
	child:GetAttributeChangedSignal("EventTag"):Connect(function()
		if child:GetAttribute("EventTag") == nil then
			billboard:Destroy()
			highlight:Destroy()
		end
	end)
end

-- Avisos de cebo: "Poner cebo" solo en santuarios ajenos y si tienes cebos; "Espantar" solo el dueño.
local function refreshPrompts()
	local baits = (player:GetAttribute("Baits") :: number?) or 0
	local plots = Workspace:FindFirstChild("Santuarios")
	if plots then
		for _, model in plots:GetChildren() do
			local ownerId = model:GetAttribute("OwnerUserId")
			local anchor = model:FindFirstChild("PuntoCebo")
			local prompt = anchor and anchor:FindFirstChild("PonerCebo")
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = ownerId ~= nil and ownerId ~= player.UserId and baits > 0
				prompt.ObjectText = "Robo amable · tienes " .. baits .. (if baits == 1 then " cebo" else " cebos")
			end
		end
	end
	for _, child in Workspace:GetChildren() do
		if child.Name == "Cebo" then
			local prompt = child:FindFirstChild("Espantar")
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = prompt:GetAttribute("OnlyFor") == player.UserId
			end
		end
	end
end

function LiveHud.Start(gui: ScreenGui, toast: Toast)
	-- Cartel de eventos arriba a la derecha (bajo los botones de Roblox).
	local banner = Instance.new("TextLabel")
	banner.Name = "CartelEventos"
	banner.AnchorPoint = Vector2.new(1, 0)
	banner.Position = UDim2.new(1, -12, 0, 58)
	banner.Size = UDim2.fromScale(0.3, 0.05)
	banner.BackgroundColor3 = COLOR_DARK
	banner.BackgroundTransparency = 0.25
	banner.TextColor3 = Color3.new(1, 1, 1)
	banner.Font = Enum.Font.GothamBold
	banner.TextScaled = true
	banner.Visible = false
	banner.Parent = gui
	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0.3, 0)
	bannerCorner.Parent = banner
	local bannerLimit = Instance.new("UISizeConstraint")
	bannerLimit.MinSize = Vector2.new(200, 30)
	bannerLimit.MaxSize = Vector2.new(380, 44)
	bannerLimit.Parent = banner
	local bannerPadding = Instance.new("UIPadding")
	bannerPadding.PaddingTop = UDim.new(0.15, 0)
	bannerPadding.PaddingBottom = UDim.new(0.15, 0)
	bannerPadding.PaddingLeft = UDim.new(0.04, 0)
	bannerPadding.PaddingRight = UDim.new(0.04, 0)
	bannerPadding.Parent = banner
	local bannerStroke = Instance.new("UIStroke")
	bannerStroke.Thickness = 2
	bannerStroke.Transparency = 0.2
	bannerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bannerStroke.Parent = banner

	local homeButton = newBigButton(gui, "Casa", "🏠 CASA", COLOR_HOME, Vector2.new(0.5, 1), UDim2.fromScale(0.5, 0.86))
	local fenceButton = newBigButton(gui, "Valla", "🛡 VALLA " .. Format.number(Events.Bait.fenceCost) .. " 💰", COLOR_FENCE, Vector2.new(1, 0), UDim2.new(1, -12, 0, 110))

	homeButton.Activated:Connect(function()
		GoHome:FireServer()
	end)
	fenceButton.Activated:Connect(function()
		BuyFence:FireServer()
	end)

	Announce.OnClientEvent:Connect(function(text: string, color: Color3?)
		toast(text, color)
		postToChat(text)
		Effects.Play("recompensa")
	end)

	-- Al empezar un cebo en tu santuario: sonido de alerta.
	player:GetAttributeChangedSignal("BaitedUntil"):Connect(function()
		if player:GetAttribute("BaitedUntil") ~= nil then
			Effects.Play("alerta_noche")
		end
	end)

	local critters = Workspace:WaitForChild("Critters")
	critters.ChildAdded:Connect(markLegendary)
	for _, child in critters:GetChildren() do
		markLegendary(child)
	end

	task.spawn(function()
		while true do
			refreshPrompts()
			task.wait(1)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local serverNow = Workspace:GetServerTimeNow()

		-- Cartel: lo más urgente primero.
		local text: string? = nil
		local color = COLOR_GOLD
		local baitedUntil = player:GetAttribute("BaitedUntil") :: number?
		local fenceUntil = (player:GetAttribute("FenceUntil") :: number?) or 0
		local legendaryAt = ReplicatedStorage:GetAttribute("LegendaryAt") :: number?
		local rainEndsAt = ReplicatedStorage:GetAttribute("RainEndsAt") :: number?
		local fenced = fenceUntil > serverNow
		local baited = baitedUntil ~= nil and baitedUntil > serverNow and not fenced
		if baited and baitedUntil then
			text = "🍰 ¡Cebo de " .. tostring(player:GetAttribute("BaitedBy") or "alguien") .. " en tu santuario! " .. clock(baitedUntil - serverNow)
			color = Color3.fromRGB(255, 120, 120)
		elseif legendaryAt and legendaryAt > serverNow then
			text = "⭐ Legendario en la Playa Rara en " .. clock(legendaryAt - serverNow)
		elseif rainEndsAt and rainEndsAt > serverNow then
			text = "🌧 Lluvia de Bichos x" .. Events.LluviaDeBichos.spawnMultiplier .. " · quedan " .. clock(rainEndsAt - serverNow)
			color = Color3.fromRGB(140, 200, 255)
		elseif fenced then
			text = "🛡 Valla puesta · " .. clock(fenceUntil - serverNow)
			color = COLOR_FENCE
		end
		banner.Visible = text ~= nil
		banner.Text = text or ""
		banner.TextColor3 = color
		bannerStroke.Color = color

		-- VALLA: solo mientras te están poniendo un cebo.
		fenceButton.Visible = baited
		fenceButton.Position = UDim2.new(1, -12, 0, if banner.Visible then 110 else 58)

		-- CASA: de noche, si estás en una bóveda (y el juego no te lleva solo).
		local night = ReplicatedStorage:GetAttribute("IsNight") == true
		local mode = ReplicatedStorage:GetAttribute("NightSendHome")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local inVault = false
		if root and root:IsA("BasePart") then
			inVault = VaultMath.vaultAt(root.Position) ~= nil
		end
		homeButton.Visible = night and mode == "boton" and inVault
	end)
end

return LiveHud
