--!strict
-- Animaciones sencillas de los bichos, solo en este cliente (no gastan red):
--   * todo el cuerpo se balancea arriba y abajo (los voladores, más);
--   * "Parpado": parpadeo cada pocos segundos;
--   * "Ala": aleteo;  "Cola" y "Pinza": vaivén;  "Gota": cae y vuelve a empezar.
-- Cada pieza va soldada a la raíz con un Weld; aquí se cambia su C0 a partir del original.
-- Para cuidar el móvil: solo se animan los bichos cercanos y a ~30 fotogramas por segundo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))

local A = Art.animation

local CritterAnimator = {}

type Tracked = {
	root: BasePart,
	welds: { { weld: Weld, base: CFrame, role: string } },
	phase: number,
	flying: boolean,
	nextBlink: number,
}

local tracked: { [BasePart]: Tracked } = {}
local rng = Random.new()

local function track(root: Instance)
	if not root:IsA("BasePart") or tracked[root] or root:GetAttribute("CritterId") == nil then
		return
	end
	local entry: Tracked = {
		root = root,
		welds = {},
		phase = rng:NextNumber(0, math.pi * 2),
		flying = A.flying[root:GetAttribute("CritterId") :: string] == true,
		nextBlink = os.clock() + rng:NextNumber(1, A.blinkEverySeconds),
	}
	for _, child in root:GetChildren() do
		local weld = child:FindFirstChildOfClass("Weld")
		if child:IsA("BasePart") and weld and child.Name ~= "AroRareza" then
			table.insert(entry.welds, { weld = weld, base = weld.C0, role = child.Name })
		end
	end
	tracked[root] = entry
	root.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			tracked[root] = nil
		end
	end)
end

local function watch(container: Instance)
	for _, descendant in container:GetDescendants() do
		track(descendant)
	end
	container.DescendantAdded:Connect(function(descendant)
		-- Esperamos un fotograma: las piezas del bicho llegan justo después de la raíz.
		task.defer(track, descendant)
	end)
end

function CritterAnimator.Start()
	watch(Workspace:WaitForChild("Critters"))
	watch(Workspace:WaitForChild("Santuarios"))
	-- Los bichos que lleva un jugador están en su personaje.
	local function watchCharacter(character: Model)
		character.ChildAdded:Connect(function(child)
			task.defer(track, child)
		end)
	end
	for _, other in Players:GetPlayers() do
		if other.Character then
			watchCharacter(other.Character)
		end
		other.CharacterAdded:Connect(watchCharacter)
	end
	Players.PlayerAdded:Connect(function(other)
		other.CharacterAdded:Connect(watchCharacter)
	end)

	local accumulator = 0
	RunService.RenderStepped:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 / A.fps then
			return
		end
		accumulator = 0
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local cameraPosition = camera.CFrame.Position
		local now = os.clock()

		for root, entry in tracked do
			if (root.Position - cameraPosition).Magnitude <= A.maxDistance then
				local size = root.Size.Y
				local t = now * A.speed + entry.phase
				local bob = math.sin(t) * A.bobHeight * size * (if entry.flying then 2.5 else 1)
				local blinking = now >= entry.nextBlink
				if now >= entry.nextBlink + A.blinkSeconds then
					entry.nextBlink = now + rng:NextNumber(A.blinkEverySeconds * 0.5, A.blinkEverySeconds * 1.5)
				end
				local body = CFrame.new(0, bob, 0)
				for _, item in entry.welds do
					local role = item.role
					local base = item.base
					if role == "Parpado" then
						item.weld.Part1.Transparency = if blinking then 0 else 1
						item.weld.C0 = body * base
					elseif role == "Ala" then
						local side = if base.Position.X >= 0 then 1 else -1
						item.weld.C0 = body * base * CFrame.Angles(0, 0, side * math.sin(t * A.wingSpeed) * math.rad(A.wingDegrees))
					elseif role == "Cola" or role == "Pinza" then
						item.weld.C0 = body * base * CFrame.Angles(math.sin(t * 2) * math.rad(A.wagDegrees), 0, 0)
					elseif role == "Gota" then
						local fall = (now * A.dropSpeed + entry.phase) % 1
						item.weld.C0 = body * base * CFrame.new(0, -fall * size * 0.3, 0)
						item.weld.Part1.Transparency = fall
					else
						item.weld.C0 = body * base
					end
				end
			end
		end
	end)
end

return CritterAnimator
