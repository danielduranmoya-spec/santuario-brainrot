--!strict
-- Interfaz de los eventos y del robo amable (solo enseña cosas y pide acciones al servidor):
--   * Avisos para todos (Remotes.Announce): salen en pantalla y en el chat.
--   * Cartel arriba a la derecha con cuentas atrás: legendario, Lluvia de Bichos, evento de
--     mutación (Fiebre del Oro, Grieta del Vacío...), cebo, valla.
--   * Marca "⭐ LEGENDARIO" sobre el bicho legendario de servidor.
--   * Mutación rara (Remotes.RareSpawn): aviso grande arriba unos segundos, sonido y una baliza con
--     la distancia sobre el bicho, que se ve desde lejos (Config/Mutations.rareAlert).
--   * Botón VALLA cuando te ponen un cebo.
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
local MutationMath = require(Shared:WaitForChild("MutationMath"))
local Mutations = require(Config:WaitForChild("Mutations"))
local ButtonStyle = require(script.Parent:WaitForChild("ButtonStyle"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Announce = remotes:WaitForChild("Announce") :: RemoteEvent
local BuyFence = remotes:WaitForChild("BuyFence") :: RemoteEvent
local RareSpawn = remotes:WaitForChild("RareSpawn") :: RemoteEvent

local COLOR_DARK = Color3.fromRGB(25, 25, 35)
local COLOR_GOLD = Color3.fromRGB(255, 200, 40)
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

-- Baliza sobre un bicho con mutación rara: nombre y distancia, visible desde lejos y por encima de
-- todo. Tamaño en píxeles, así se lee igual en un móvil que en un ordenador.
local beacons: { [BasePart]: TextLabel } = {}

local function markRare(child: Instance)
	if not child:IsA("BasePart") or child:GetAttribute("RareMutation") ~= true or beacons[child] then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BalizaMutacion"
	billboard.Size = UDim2.fromOffset(190, 54)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, child.Size.Y / 2 + 4, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = Mutations.rareAlert.beaconMaxDistance
	billboard.Parent = child
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = COLOR_DARK
	text.BackgroundTransparency = 0.35
	text.Font = Enum.Font.GothamBlack
	text.TextScaled = true
	text.TextColor3 = COLOR_GOLD
	text.TextStrokeTransparency = 0
	text.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = text
	local nameText = "✨ " .. MutationMath.displayName("", tostring(child:GetAttribute("MutationColor") or ""), tostring(child:GetAttribute("MutationSize") or ""))
	text:SetAttribute("Base", nameText)
	text.Text = nameText
	beacons[child] = text
	local function remove()
		if beacons[child] == text then
			beacons[child] = nil
			billboard:Destroy()
		end
	end
	child:GetAttributeChangedSignal("RareMutation"):Connect(function()
		if child:GetAttribute("RareMutation") ~= true then
			remove() -- alguien lo ha atrapado
		end
	end)
	child.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			remove()
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

	-- Aviso de mutación rara: arriba en el centro (encima de la pista), nunca en el centro de la pantalla.
	local rare = Instance.new("TextLabel")
	rare.Name = "AvisoMutacionRara"
	rare.AnchorPoint = Vector2.new(0.5, 0.5)
	rare.Position = UDim2.fromScale(0.5, 0.14)
	rare.Size = UDim2.fromScale(0.62, 0.075)
	rare.BackgroundColor3 = COLOR_DARK
	rare.BackgroundTransparency = 0.15
	rare.Font = Enum.Font.GothamBlack
	rare.TextScaled = true
	rare.TextColor3 = Color3.new(1, 1, 1)
	rare.TextStrokeTransparency = 0.3
	rare.ZIndex = 4
	rare.Visible = false
	rare.Parent = gui
	local rareCorner = Instance.new("UICorner")
	rareCorner.CornerRadius = UDim.new(0.3, 0)
	rareCorner.Parent = rare
	local rareStroke = Instance.new("UIStroke")
	rareStroke.Thickness = 3
	rareStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rareStroke.Parent = rare
	local rareLimit = Instance.new("UISizeConstraint")
	rareLimit.MinSize = Vector2.new(300, 40)
	rareLimit.MaxSize = Vector2.new(760, 70)
	rareLimit.Parent = rare
	local rarePadding = Instance.new("UIPadding")
	rarePadding.PaddingTop = UDim.new(0.12, 0)
	rarePadding.PaddingBottom = UDim.new(0.12, 0)
	rarePadding.PaddingLeft = UDim.new(0.03, 0)
	rarePadding.PaddingRight = UDim.new(0.03, 0)
	rarePadding.Parent = rare
	local rareId = 0
	RareSpawn.OnClientEvent:Connect(function(text: string, color: Color3, vault: number)
		local maxVault = (player:GetAttribute("MaxVault") :: number?) or 1
		local tail = if vault <= maxVault then " ¡Corre, sigue la baliza!" else " Abre esa bóveda para atraparlo."
		rareId += 1
		local myId = rareId
		rare.Text = text .. tail
		rareStroke.Color = color
		rare.Visible = true
		Effects.Pop(rare)
		Effects.Play("alerta")
		postToChat(text)
		task.delay(Mutations.rareAlert.showSeconds, function()
			if rareId == myId then
				rare.Visible = false
			end
		end)
	end)

	local fenceButton = newBigButton(gui, "Valla", "🛡 VALLA " .. Format.number(Events.Bait.fenceCost) .. " 💰", COLOR_FENCE, Vector2.new(1, 0), UDim2.new(1, -12, 0, 110))

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
			Effects.Play("alerta")
		end
	end)

	local critters = Workspace:WaitForChild("Critters")
	critters.ChildAdded:Connect(markLegendary)
	critters.ChildAdded:Connect(markRare)
	for _, child in critters:GetChildren() do
		markLegendary(child)
		markRare(child)
	end
	-- Distancia en las balizas, dos veces por segundo.
	task.spawn(function()
		while true do
			task.wait(0.5)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				for part, label in beacons do
					local meters = math.floor((part.Position - root.Position).Magnitude + 0.5)
					label.Text = tostring(label:GetAttribute("Base")) .. "\n" .. meters .. " m"
				end
			end
		end
	end)

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
		local mutationId = ReplicatedStorage:GetAttribute("MutationEvent") :: string?
		local mutationEvent = if mutationId then MutationMath.event(mutationId) else nil
		local mutationEndsAt = ReplicatedStorage:GetAttribute("MutationEventEndsAt") :: number?
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
		elseif mutationEvent and mutationEndsAt and mutationEndsAt > serverNow then
			text = mutationEvent.icon .. " " .. mutationEvent.name .. " · quedan " .. clock(mutationEndsAt - serverNow)
			color = mutationEvent.color
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
	end)
end

return LiveHud
