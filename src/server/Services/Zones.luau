--!strict
-- Zonas del mapa (piezas grises): un círculo de suelo por zona y, en las de pago, una barrera
-- con una puerta "Desbloquear". El servidor deja la barrera atravesable; cada cliente la vuelve
-- sólida solo para sí mismo mientras no tenga la zona (ver client/ZoneBarriers). Aun así,
-- el servidor no deja atrapar bichos de una zona bloqueada (CritterSpawner).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Progression = require(Config:WaitForChild("Progression"))
local Format = require(Shared:WaitForChild("Format"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local B = Gameplay.ZoneBarrier

local Zones = {}

local folder = Instance.new("Folder")
folder.Name = "Zonas"
folder.Parent = Workspace

local gates: { [string]: BasePart } = {}
local lastAction: { [Player]: number } = {}

local function newPart(name: string, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function newBillboard(adornee: BasePart, text: string, offsetY: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Cartel"
	gui.Size = UDim2.new(12, 0, 3, 0) -- en studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 250
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = gui
end

-- Zona anterior en el orden de Progression.Zones (hay que tenerla para comprar esta).
local function previousZone(zoneId: string): string?
	for i, zone in Progression.Zones do
		if zone.id == zoneId then
			return if i > 1 then Progression.Zones[i - 1].id else nil
		end
	end
	return nil
end

local function tryUnlock(player: Player, zoneId: string)
	local now = os.clock()
	if now - (lastAction[player] or 0) < Gameplay.Menus.actionCooldownSeconds then
		return
	end
	lastAction[player] = now

	local profile = Data.Get(player)
	local zone = nil
	for _, candidate in Progression.Zones do
		if candidate.id == zoneId then
			zone = candidate
		end
	end
	local gate = gates[zoneId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not profile or not zone or not gate or not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - gate.Position).Magnitude > B.promptDistance + Gameplay.Catching.rangeTolerance then
		return
	end
	if profile.zones[zoneId] then
		return
	end
	local previous = previousZone(zoneId)
	if previous and not profile.zones[previous] then
		Remotes.Notify:FireClient(player, "Primero desbloquea la zona anterior.")
		return
	end
	if not Economy.TrySpend(player, zone.unlockCost) then
		Remotes.Notify:FireClient(player, "Necesitas " .. Format.number(zone.unlockCost) .. " monedas para " .. zone.name .. ".")
		return
	end
	profile.zones[zoneId] = true
	Data.Replicate(player)
	Remotes.Notify:FireClient(player, "🔓 ¡Has desbloqueado " .. zone.name .. "!")
	Remotes.Effect:FireClient(player, "desbloqueo", gate.Position)
end

local function buildZone(zone: { id: string, name: string, unlockCost: number })
	local area = Gameplay.Zones[zone.id]
	if not area then
		return
	end
	local model = Instance.new("Model")
	model.Name = zone.id
	model:SetAttribute("ZoneId", zone.id)
	-- Con StreamingEnabled, que la zona llegue entera a todos los clientes y no se descargue.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- Suelo de color (fino y sin colisión: se camina sobre el Baseplate).
	local floor = newPart("Suelo", model)
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(0.2, area.radius * 2, area.radius * 2)
	floor.CFrame = CFrame.new(area.center + Vector3.new(0, Gameplay.GroundY + 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	floor.Color = area.color
	floor.Material = Enum.Material.SmoothPlastic
	floor.CanCollide = false
	floor.CanQuery = false

	if zone.unlockCost > 0 then
		local barrier = newPart("Barrera", model)
		barrier.Shape = Enum.PartType.Cylinder
		barrier.Size = Vector3.new(B.height, area.radius * 2, area.radius * 2)
		barrier.CFrame = CFrame.new(area.center + Vector3.new(0, Gameplay.GroundY + B.height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		barrier.Color = area.color
		barrier.Material = Enum.Material.ForceField
		barrier.Transparency = B.transparency
		barrier.CanCollide = false -- el cliente la hace sólida si no tienes la zona
		barrier.CanQuery = false
		barrier:SetAttribute("ZoneId", zone.id)

		-- Puerta: en el borde de la barrera que mira a la playa.
		local beach = Gameplay.Zones.PlayaRara.center
		local toBeach = Vector3.new(beach.X - area.center.X, 0, beach.Z - area.center.Z).Unit
		local gatePosition = area.center + toBeach * (area.radius + B.gateDistance) + Vector3.new(0, Gameplay.GroundY + 3, 0)
		local gate = newPart("Puerta", model)
		gate.Size = Vector3.new(4, 6, 1)
		gate.CFrame = CFrame.lookAt(gatePosition, gatePosition + toBeach)
		gate.Color = Color3.fromRGB(255, 200, 40)
		gate.Material = Enum.Material.Neon
		gate.CanCollide = false
		gate:SetAttribute("ZoneId", zone.id)
		gate.Transparency = 0.25
		gates[zone.id] = gate

		-- Arco de piedra alrededor de la puerta (se queda aunque la puerta desaparezca al desbloquear).
		for _, side in { -1, 1 } do
			local pillar = newPart("Pilar", model)
			pillar.Size = Vector3.new(1.4, 8, 1.4)
			pillar.CFrame = gate.CFrame * CFrame.new(side * 2.9, 1, 0)
			pillar.Color = Color3.fromRGB(150, 140, 130)
			pillar.Material = Enum.Material.Slate
		end
		local lintel = newPart("Dintel", model)
		lintel.Size = Vector3.new(7.2, 1.2, 1.8)
		lintel.CFrame = gate.CFrame * CFrame.new(0, 5.4, 0)
		lintel.Color = area.color
		lintel.Material = Enum.Material.Slate
		newBillboard(gate, "🔒 " .. zone.name .. "\n" .. Format.number(zone.unlockCost) .. " 💰", 7)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Desbloquear"
		prompt.ActionText = "Desbloquear (" .. Format.number(zone.unlockCost) .. " 💰)"
		prompt.ObjectText = zone.name
		prompt.HoldDuration = B.promptHoldSeconds
		prompt.MaxActivationDistance = B.promptDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = gate
		prompt.Triggered:Connect(function(player: Player)
			tryUnlock(player, zone.id)
		end)
	end

	model.Parent = folder
end

-- ¿Ha desbloqueado el jugador esta zona?
function Zones.IsUnlocked(player: Player, zoneId: string): boolean
	local profile = Data.Get(player)
	return profile ~= nil and profile.zones[zoneId] == true
end

-- Zona en la que está una posición (o nil si está fuera de todas).
function Zones.ZoneAt(position: Vector3): string?
	for zoneId, area in Gameplay.Zones do
		local offset = Vector3.new(position.X - area.center.X, 0, position.Z - area.center.Z)
		if offset.Magnitude <= area.radius then
			return zoneId
		end
	end
	return nil
end

function Zones.Start()
	for _, zone in Progression.Zones do
		buildZone(zone)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)
end

return Zones
