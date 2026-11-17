--!strict
-- Límites de la isla (Config/Island, Art.boundary):
--   * muros invisibles a lo largo de la costa (bajos: los puentes a las islas flotantes pasan por
--     encima), alrededor de la plaza (solo se sale por la avenida, a la zona 1) y sobre las crestas de
--     roca que separan las zonas 1-7 (con hueco en el arco de cada zona; la puerta la pone Vaults);
--   * por si acaso (caídas desde las islas flotantes, un bug de física, un exploit...), quien cae al
--     mar o por debajo del suelo vuelve delante de su santuario.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Island = require(Config:WaitForChild("Island"))
local Layout = require(Shared:WaitForChild("Layout"))

local Plots = require(script.Parent:WaitForChild("Plots"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local B = Art.boundary
local G = Gameplay.GroundY
local HUB = Island.Hub
local Z = Island.Zones
local COAST = Island.Coast.radius + Island.Coast.wobble + 14

local Boundary = {}

local model: Model

local function invisibleWall(name: string, size: Vector3, cframe: CFrame): Part
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Size = size
	wall.CFrame = cframe
	wall.Anchored = true
	wall.Transparency = 1
	wall.CanCollide = true
	wall.CanQuery = false
	wall.CanTouch = false
	wall.CastShadow = false
	wall.Parent = model
	return wall
end

-- Muro de `a` a `b` (en el plano), de `height` studs desde el suelo.
local function wallBetween(name: string, a: Vector3, b: Vector3, height: number)
	local flatA, flatB = Vector3.new(a.X, G, a.Z), Vector3.new(b.X, G, b.Z)
	local length = (flatB - flatA).Magnitude
	if length < 0.5 then
		return
	end
	local middle = (flatA + flatB) / 2 + Vector3.new(0, height / 2 - 6, 0)
	invisibleWall(name, Vector3.new(B.thickness, height, length + B.thickness), CFrame.lookAt(middle, middle + (flatB - flatA)))
end

local function ringPoint(angleDegrees: number, radius: number): Vector3
	local a = math.rad(angleDegrees)
	return Vector3.new(math.cos(a) * radius, G, math.sin(a) * radius)
end

-- Anillo de muros (de `from` a `to` grados) con `segments` tramos.
local function ring(name: string, radius: number, from: number, to: number, segments: number, height: number)
	for i = 0, segments - 1 do
		local a1 = from + (to - from) * i / segments
		local a2 = from + (to - from) * (i + 1) / segments
		wallBetween(name, ringPoint(a1, radius), ringPoint(a2, radius), height)
	end
end

local function buildWalls()
	-- Costa: muro bajo (los puentes pasan por encima), justo dentro del agua.
	ring("Costa", COAST, 0, 360, 72, B.coastHeight)
	-- Seto de la plaza: hueco en la avenida (arco de la zona 1).
	local gap = math.deg((Z.gateWidth + 2) / HUB.wallRadius) / 2
	ring("Plaza", HUB.wallRadius, HUB.avenueAngle + gap, HUB.avenueAngle + 360 - gap, 40, B.height)
	-- Crestas entre las zonas 1-7: la que separa la 7 de la 1 es entera; las demás, con hueco en el camino.
	for k = 1, 7 do
		local angle = HUB.avenueAngle + (k - 1.5) * Z.ringStep
		local inner, outer = ringPoint(angle, HUB.wallRadius), ringPoint(angle, COAST)
		if k == 1 then
			wallBetween("Cresta", inner, outer, B.height)
		else
			local gateIn = ringPoint(angle, Z.ringRadius - Z.gateWidth / 2 - 1)
			local gateOut = ringPoint(angle, Z.ringRadius + Z.gateWidth / 2 + 1)
			wallBetween("Cresta", inner, gateIn, B.height)
			wallBetween("Cresta", gateOut, outer, B.height)
		end
	end
end

local function isOutside(position: Vector3): boolean
	local r = Layout.flatDistance(position)
	return position.Y < G + B.respawnBelowY
		or (r > COAST + B.respawnMargin and position.Y < G + B.seaRescueAbove)
		or r > B.maxRadius
end

local function rescue(player: Player, root: BasePart)
	local target = Plots.GetSafeCFrame(player) or CFrame.new(Layout.spawn() + Vector3.new(0, G + 4, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	if player.Character then
		Guard.NoteTeleport(player)
		player.Character:PivotTo(target)
	end
	Remotes.Notify:FireClient(player, "¡Uy! Has vuelto a tu santuario.")
end

local function watchLoop()
	while true do
		task.wait(B.checkSeconds)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and isOutside(root.Position) then
				rescue(player, root)
			end
		end
	end
end

function Boundary.Start()
	model = Instance.new("Model")
	model.Name = "Limites"
	-- Que los muros estén siempre cargados en todos los clientes (con StreamingEnabled).
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = Workspace
	buildWalls()
	task.spawn(watchLoop)
end

return Boundary
