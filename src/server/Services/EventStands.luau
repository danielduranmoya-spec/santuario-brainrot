--!strict
-- Stands de eventos en la plaza (Config/Events.Stands): un puesto de madera con tejado del color del
-- evento, farolillos, su encargado y un cartel "EVENTO" con la cuenta atrás, que se ve desde lejos.
-- El aviso "Hablar" explica el evento. Las cuentas atrás salen de los atributos que publican
-- LiveEvents (legendario y Lluvia de Bichos) y MutationEvents en ReplicatedStorage.
-- Para añadir otro stand: una entrada más en Config/Events.Stands con un `kind` de los de abajo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Events = require(Config:WaitForChild("Events"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))
local Layout = require(Shared:WaitForChild("Layout"))

local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Guard = require(script.Parent:WaitForChild("Guard"))

type StandDef = typeof(Events.Stands[1])

local G = Gameplay.GroundY
local WOOD = Color3.fromRGB(140, 95, 55)
local WOOD_DARK = Color3.fromRGB(100, 65, 40)
local SKIN = Color3.fromRGB(240, 200, 160)

local EventStands = {}

local labels: { { def: StandDef, label: TextLabel } } = {}

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	if s >= 86400 then
		return string.format("%dd %dh", s // 86400, (s % 86400) // 3600)
	elseif s >= 3600 then
		return string.format("%dh %02dm", s // 3600, (s % 3600) // 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

-- Texto de la cuenta atrás de cada tipo de stand.
local function countdown(kind: string): string
	local now = Workspace:GetServerTimeNow()
	if kind == "legendario" then
		if ReplicatedStorage:GetAttribute("LegendaryAlive") == true then
			return "¡AHORA EN LA PLAYA RARA!"
		end
		local nextAt = ReplicatedStorage:GetAttribute("LegendaryNextAt") :: number?
		return if nextAt then "PRÓXIMO EN " .. clock(nextAt - now) else "MUY PRONTO"
	elseif kind == "lluvia" then
		local endsAt = ReplicatedStorage:GetAttribute("RainEndsAt") :: number?
		if endsAt and endsAt > now then
			return "¡LLUEVE! QUEDAN " .. clock(endsAt - now)
		end
		local nextAt = ReplicatedStorage:GetAttribute("RainNextAt") :: number?
		return if nextAt then "EMPIEZA EN " .. clock(nextAt - now) else "SÁBADOS 18:00"
	elseif kind == "mutacion" then
		local id = ReplicatedStorage:GetAttribute("MutationEvent") :: string?
		local event = if id then MutationMath.event(id) else nil
		local endsAt = ReplicatedStorage:GetAttribute("MutationEventEndsAt") :: number?
		if event and endsAt then
			return string.upper(event.name) .. " · " .. clock(endsAt - now)
		end
		local nextAt = ReplicatedStorage:GetAttribute("MutationEventNextAt") :: number?
		return if nextAt then "PRÓXIMO EN " .. clock(nextAt - now) else "CADA 20 MIN"
	end
	return ""
end

-- Encargado del stand: muñeco de bloques con sombrero del color del evento.
local function buildKeeper(def: StandDef, base: CFrame, parent: Instance): BasePart
	local keeper = Instance.new("Model")
	keeper.Name = def.keeper
	keeper.Parent = parent
	for _, side in { -0.5, 0.5 } do
		newPart("Pierna", Vector3.new(0.9, 2, 0.9), base * CFrame.new(side, 1, 0), WOOD_DARK, Enum.Material.SmoothPlastic, keeper)
	end
	local torso = newPart("Cuerpo", Vector3.new(2, 2, 1), base * CFrame.new(0, 3, 0), def.color, Enum.Material.Fabric, keeper)
	for _, side in { -1.45, 1.45 } do
		newPart("Brazo", Vector3.new(0.8, 2, 0.8), base * CFrame.new(side, 3, 0), def.color, Enum.Material.Fabric, keeper)
	end
	local head = newPart("Cabeza", Vector3.new(1.4, 1.4, 1.4), base * CFrame.new(0, 4.7, 0), SKIN, Enum.Material.SmoothPlastic, keeper)
	for _, side in { -0.3, 0.3 } do
		newPart("Ojo", Vector3.new(0.18, 0.28, 0.05), base * CFrame.new(side, 4.85, -0.71), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic, keeper)
	end
	newPart("Ala", Vector3.new(2.4, 0.2, 2.4), base * CFrame.new(0, 5.45, 0), def.accent, Enum.Material.SmoothPlastic, keeper)
	newPart("Sombrero", Vector3.new(1.4, 1.2, 1.4), base * CFrame.new(0, 6.1, 0), def.color, Enum.Material.SmoothPlastic, keeper)
	for _, part in keeper:GetChildren() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	torso.CanCollide = true
	local _ = head
	return torso
end

local function buildStand(def: StandDef, index: number, folder: Instance)
	-- El frente del stand (-Z local) mira al árbol de la plaza (Shared/Layout).
	local origin = Layout.stand(index)
	local model = Instance.new("Model")
	model.Name = "Stand" .. def.id
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	newPart("Tarima", Vector3.new(12, 0.6, 8), origin * CFrame.new(0, 0.3, 0), WOOD_DARK, Enum.Material.WoodPlanks, model)
	-- Mostrador delante, con franja del color del evento.
	newPart("Mostrador", Vector3.new(10, 3, 1.6), origin * CFrame.new(0, 2.1, -2.6), WOOD, Enum.Material.WoodPlanks, model)
	newPart("Franja", Vector3.new(10.2, 0.8, 1.7), origin * CFrame.new(0, 2.6, -2.6), def.color, Enum.Material.Fabric, model)
	newPart("Encimera", Vector3.new(10.6, 0.3, 2.2), origin * CFrame.new(0, 3.75, -2.6), WOOD_DARK, Enum.Material.Wood, model)
	-- Postes, pared del fondo y tejado a dos aguas.
	for _, x in { -5.4, 5.4 } do
		for _, z in { -3.4, 3.4 } do
			newPart("Poste", Vector3.new(0.6, 9, 0.6), origin * CFrame.new(x, 4.8, z), WOOD, Enum.Material.Wood, model)
		end
	end
	newPart("Fondo", Vector3.new(11, 8, 0.4), origin * CFrame.new(0, 4.6, 3.5), def.color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Fabric, model)
	for _, side in { -1, 1 } do
		newPart("Tejado", Vector3.new(13, 0.5, 5), origin * CFrame.new(0, 9.9, side * 2) * CFrame.Angles(math.rad(side * 18), 0, 0), def.color, Enum.Material.Fabric, model)
	end
	newPart("Remate", Vector3.new(13.4, 0.5, 0.6), origin * CFrame.new(0, 10.75, 0), def.accent, Enum.Material.SmoothPlastic, model)
	-- Farolillos a los lados.
	for _, x in { -5.4, 5.4 } do
		local lantern = newPart("Farolillo", Vector3.new(0.9, 1.2, 0.9), origin * CFrame.new(x, 7.6, -3.9), def.accent, Enum.Material.Neon, model)
		lantern.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = def.accent
		light.Range = 10
		light.Brightness = 1
		light.Parent = lantern
	end
	-- Algo encima del mostrador: una esfera brillante del color del evento.
	local orb = newPart("Orbe", Vector3.one * 1.4, origin * CFrame.new(0, 4.6, -2.6), def.accent, Enum.Material.Neon, model, Enum.PartType.Ball)
	orb.CanCollide = false

	local keeperBody = buildKeeper(def, origin * CFrame.new(0, 0.6, 0.6), model)

	-- Cartel flotante: EVENTO, nombre y cuenta atrás.
	local sign = Instance.new("BillboardGui")
	sign.Name = "Cartel"
	sign.Size = UDim2.new(14, 0, 5.5, 0) -- en studs
	sign.StudsOffsetWorldSpace = Vector3.new(0, 10, 0) -- por encima del tejado
	sign.MaxDistance = 160
	sign.LightInfluence = 0
	sign.Parent = orb
	local function line(name: string, y: number, height: number, font: Enum.Font, color: Color3, text: string): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.fromScale(1, height)
		label.Position = UDim2.fromScale(0, y)
		label.BackgroundTransparency = 1
		label.Font = font
		label.TextScaled = true
		label.TextColor3 = color
		label.TextStrokeTransparency = 0
		label.Text = text
		label.Parent = sign
		return label
	end
	line("Evento", 0, 0.38, Enum.Font.LuckiestGuy, Color3.fromRGB(255, 90, 220), "EVENTO")
	line("Nombre", 0.4, 0.3, Enum.Font.GothamBlack, def.accent, def.title)
	local timer = line("CuentaAtras", 0.72, 0.28, Enum.Font.GothamBold, Color3.new(1, 1, 1), "")
	table.insert(labels, { def = def, label = timer })

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hablar"
	prompt.ObjectText = def.keeper
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Events.standPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = keeperBody
	prompt.Triggered:Connect(function(player: Player)
		if not Guard.Allow(player, "Default") or not Guard.IsNear(player, keeperBody.Position, Events.standPromptDistance) then
			return
		end
		Remotes.Notify:FireClient(player, def.talk .. "\n" .. def.title .. ": " .. countdown(def.kind))
	end)

	model.Parent = folder
end

function EventStands.Start()
	local folder = Instance.new("Folder")
	folder.Name = "StandsEventos"
	folder.Parent = Workspace
	for index, def in Events.Stands do
		buildStand(def, index, folder)
	end
	task.spawn(function()
		while true do
			for _, item in labels do
				item.label.Text = countdown(item.def.kind)
			end
			task.wait(1)
		end
	end)
end

return EventStands
