--!strict
-- Límite infranqueable del mapa:
--   * un anillo de muros invisibles y muy altos alrededor de la zona jugable (por dentro de las
--     montañas del borde) y un techo invisible, para que ni saltando ni con Botas al máximo se pueda salir;
--   * por si acaso (un bug de física, un exploit...), si un jugador cae por debajo del suelo o aparece
--     fuera del límite, vuelve delante de su santuario.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))
local Gameplay = require(Config:WaitForChild("Gameplay"))

local Plots = require(script.Parent:WaitForChild("Plots"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local B = Art.boundary
local CENTER = Gameplay.Zones.PlayaRara.center

local Boundary = {}

local function invisibleWall(name: string, size: Vector3, cframe: CFrame, parent: Instance)
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Size = size
	wall.CFrame = cframe
	wall.Anchored = true
	wall.CanCollide = true
	wall.CanQuery = false
	wall.CanTouch = false
	wall.CastShadow = false
	wall.Transparency = 1
	wall.Parent = parent
end

local function build()
	local model = Instance.new("Model")
	model.Name = "Limites"
	-- Que el muro esté siempre cargado en todos los clientes (con StreamingEnabled).
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- Anillo de muros: cada tramo cubre su arco con un poco de solape para que no queden huecos.
	local arc = 2 * math.pi * B.radius / B.segments
	for i = 1, B.segments do
		local angle = (i - 0.5) / B.segments * math.pi * 2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = CENTER + direction * (B.radius + B.thickness / 2) + Vector3.new(0, B.height / 2 - 20, 0)
		invisibleWall("Muro", Vector3.new(arc * 1.15, B.height, B.thickness), CFrame.lookAt(position, position + direction), model)
	end

	-- Techo invisible.
	invisibleWall(
		"Techo",
		Vector3.new(B.thickness, (B.radius + B.thickness) * 2, (B.radius + B.thickness) * 2),
		CFrame.new(CENTER + Vector3.new(0, B.ceilingHeight, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		model
	)
	model.Parent = Workspace
end

local function rescue(player: Player, root: BasePart)
	local target = Plots.GetSafeCFrame(player)
		or CFrame.new(CENTER + Vector3.new(0, Gameplay.GroundY + 4, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	if player.Character then
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
			if root and root:IsA("BasePart") then
				local position = root.Position
				local horizontal = Vector3.new(position.X - CENTER.X, 0, position.Z - CENTER.Z).Magnitude
				if position.Y < B.respawnBelowY or horizontal > B.respawnBeyondRadius then
					rescue(player, root)
				end
			end
		end
	end
end

function Boundary.Start()
	build()
	task.spawn(watchLoop)
end

return Boundary
