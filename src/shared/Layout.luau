--!strict
-- Posiciones de lo que hay en la plaza central (Config/Island): santuarios, máquinas de fusión,
-- rankings, puestos de eventos y punto de aparición. Las usan el servidor y el cliente.

local Config = script.Parent:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Island = require(Config:WaitForChild("Island"))

local G = Gameplay.GroundY
local HUB_CENTER = Vector3.new(0, G, 0)

local Layout = {}

Layout.HubCenter = HUB_CENTER

local function onRing(angleDegrees: number, radius: number, y: number?): Vector3
	local a = math.rad(angleDegrees)
	return Vector3.new(math.cos(a) * radius, y or G, math.sin(a) * radius)
end
Layout.onRing = onRing

-- Mira hacia el árbol (su -Z local apunta a la plaza).
local function facingHub(position: Vector3): CFrame
	return CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
end
Layout.facingHub = facingHub

-- Santuario n: centro de la parcela, con su entrada (-Z local) hacia el árbol.
function Layout.plot(index: number): CFrame
	local angles = Island.Plots.angles
	return facingHub(onRing(angles[(index - 1) % #angles + 1], Island.Plots.radius))
end

-- Máquina de fusión n: a un lado y otro de la avenida.
function Layout.machine(index: number): Vector3
	local side = if index % 2 == 1 then -1 else 1
	return onRing(Island.Hub.avenueAngle + side * Island.Machines.spread, Island.Machines.radius)
end

-- Ranking n (de #total): en fila, de cara a la plaza.
function Layout.leaderboard(index: number, total: number): CFrame
	local L = Island.Leaderboards
	local center = facingHub(onRing(L.angle, L.radius))
	return center * CFrame.new((index - (total + 1) / 2) * L.spacing, 0, 0)
end

-- Puesto de eventos n.
function Layout.stand(index: number): CFrame
	local def = Island.Stands[(index - 1) % #Island.Stands + 1]
	return facingHub(onRing(def.angle, def.radius))
end

function Layout.spawn(): Vector3
	return onRing(Island.spawnAngle, Island.spawnRadius, 0)
end

-- Distancia al centro de la isla en el plano.
function Layout.flatDistance(position: Vector3): number
	return Vector2.new(position.X, position.Z).Magnitude
end

return Layout
