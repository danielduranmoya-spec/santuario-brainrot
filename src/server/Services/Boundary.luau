--!strict
-- Límite infranqueable del campo (un rectángulo largo):
--   * muros invisibles y muy altos a los dos lados, detrás de la plaza y al final de la última bóveda
--     construida (se mueve cuando se construyen más), y un techo invisible, para que ni saltando ni con
--     Botas al máximo se pueda salir;
--   * por si acaso (un bug de física, un exploit...), si un jugador cae por debajo del suelo o aparece
--     fuera del límite, vuelve delante de su santuario.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))
local Gameplay = require(Config:WaitForChild("Gameplay"))

local Plots = require(script.Parent:WaitForChild("Plots"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local B = Art.boundary
local F = Gameplay.Field
local HALF = F.width / 2
local BACK_Z = F.startZ + F.hubLength -- detrás de la plaza

local Boundary = {}

local model: Model
local endWall: Part
local builtUntilZ = BACK_Z -- hasta dónde llegan ya los muros laterales y el techo
local fieldEndZ = F.startZ

local function invisibleWall(name: string, size: Vector3, position: Vector3): Part
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.CanCollide = true
	wall.CanQuery = false
	wall.CanTouch = false
	wall.CastShadow = false
	wall.Transparency = 1
	wall.Parent = model
	return wall
end

local function wallY(): number
	return Gameplay.GroundY - 20 + B.height / 2
end

-- Añade muros laterales y techo desde builtUntilZ hasta `toZ` (hacia -Z), en tramos.
local function extendSides(toZ: number)
	while builtUntilZ > toZ do
		local length = math.min(B.segmentLength, builtUntilZ - toZ)
		local middleZ = builtUntilZ - length / 2
		for _, side in { -1, 1 } do
			invisibleWall("Lateral", Vector3.new(B.thickness, B.height, length + 2), Vector3.new(side * (HALF + B.thickness / 2), wallY(), middleZ))
		end
		invisibleWall("Techo", Vector3.new(F.width + B.thickness * 2, B.thickness, length + 2), Vector3.new(0, Gameplay.GroundY + B.ceilingHeight, middleZ))
		builtUntilZ -= length
	end
end

-- Coloca el muro del final del campo (lo llama Vaults al construir más bóvedas).
function Boundary.SetFieldEnd(z: number)
	fieldEndZ = z
	extendSides(z - B.thickness)
	endWall.Position = Vector3.new(0, wallY(), z - B.thickness / 2)
end

local function isOutside(position: Vector3): boolean
	return position.Y < Gameplay.GroundY + B.respawnBelowY
		or math.abs(position.X) > HALF + B.respawnMargin
		or position.Z > BACK_Z + B.respawnMargin
		or position.Z < fieldEndZ - B.respawnMargin
end

local function rescue(player: Player, root: BasePart)
	local target = Plots.GetSafeCFrame(player) or CFrame.new(F.spawn + Vector3.new(0, Gameplay.GroundY + 4, 0))
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

	invisibleWall("Fondo", Vector3.new(F.width + B.thickness * 2, B.height, B.thickness), Vector3.new(0, wallY(), BACK_Z + B.thickness / 2))
	endWall = invisibleWall("Final", Vector3.new(F.width + B.thickness * 2, B.height, B.thickness), Vector3.new(0, wallY(), F.startZ))
	extendSides(F.startZ)
	task.spawn(watchLoop)
end

return Boundary
