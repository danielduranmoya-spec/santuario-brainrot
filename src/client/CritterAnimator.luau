--!strict
-- Animaciones sencillas de los bichos, solo en este cliente (no gastan red):
--   * todo el cuerpo se balancea arriba y abajo (los voladores, más);
--   * "Parpado": parpadeo cada pocos segundos;
--   * "Ala": aleteo;  "Cola": vaivén;  "Pinza": se abre y se cierra;  "Gota": cae y vuelve a empezar;
--   * "Giro": gira sobre su eje (hélices, engranajes, llaves de cuerda);  "Brillo": late la luz;
--   * "Arcoiris": cambia de color;  "Cabeza": da una vuelta completa de vez en cuando;
--   * "Pendulo": se balancea de lado a lado;
--   * los bichos de Art.animation.rolling ruedan o dan volteretas mientras se mueven.
-- Las piezas con el atributo "Pivot" (lo pone server/CritterVisual) giran alrededor de ese punto,
-- así un ala o una cabeza de varias piezas se mueve como un solo bloque.
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
	welds: { { weld: Weld, base: CFrame, role: string, pivot: Vector3?, color: Color3 } },
	phase: number,
	flying: boolean,
	nextBlink: number,
	rollAxis: string?,
	rollAngle: number,
	lastPosition: Vector3,
}

local tracked: { [BasePart]: Tracked } = {}
local rng = Random.new()
local TWO_PI = math.pi * 2

-- Giro `rotation` alrededor del punto `pivot` (en el espacio de la raíz del bicho).
local function aroundPivot(pivot: Vector3, rotation: CFrame): CFrame
	return CFrame.new(pivot) * rotation * CFrame.new(-pivot)
end

-- Suaviza 0..1 (arranca y frena despacio).
local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

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
		rollAxis = A.rolling[root:GetAttribute("CritterId") :: string],
		rollAngle = 0,
		lastPosition = root.Position,
	}
	for _, child in root:GetChildren() do
		local weld = child:FindFirstChildOfClass("Weld")
		if child:IsA("BasePart") and weld and child.Name ~= "AroRareza" then
			local pivot = child:GetAttribute("Pivot")
			table.insert(entry.welds, {
				weld = weld,
				base = weld.C0,
				role = child.Name,
				pivot = if typeof(pivot) == "Vector3" then pivot else nil,
				color = child.Color,
			})
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
				-- Dormido (de noche): respira despacio y con los ojos cerrados.
				local sleeping = root:GetAttribute("Sleeping") == true
				local zz = root:FindFirstChild("Zz")
				if sleeping and not zz then
					local gui = Instance.new("BillboardGui")
					gui.Name = "Zz"
					gui.Size = UDim2.new(2.5, 0, 1.5, 0)
					-- A un lado del bicho, para no taparse con su etiqueta de nombre.
					gui.StudsOffsetWorldSpace = Vector3.new(size * 0.7 + 1.2, size * 0.2, 0)
					gui.LightInfluence = 0
					gui.Parent = root
					local label = Instance.new("TextLabel")
					label.Size = UDim2.fromScale(1, 1)
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.GothamBlack
					label.TextScaled = true
					label.TextColor3 = Color3.fromRGB(200, 220, 255)
					label.TextStrokeTransparency = 0.3
					label.Text = "Zz"
					label.Parent = gui
				elseif not sleeping and zz then
					zz:Destroy()
				end
				local t = now * (if sleeping then A.speed * 0.3 else A.speed) + entry.phase
				local bob = math.sin(t) * A.bobHeight * size * (if entry.flying and not sleeping then 2.5 else 1)
				local blinking = sleeping or now >= entry.nextBlink
				if now >= entry.nextBlink + A.blinkSeconds then
					entry.nextBlink = now + rng:NextNumber(A.blinkEverySeconds * 0.5, A.blinkEverySeconds * 1.5)
				end
				local body = CFrame.new(0, bob, 0)

				-- Rodar o dar volteretas mientras se mueve; al pararse, vuelve a quedar derecho.
				local rollAxis = entry.rollAxis
				if rollAxis then
					local moved = (root.Position - entry.lastPosition).Magnitude
					entry.lastPosition = root.Position
					if moved > 0.01 and moved < size * 2 and not sleeping then
						entry.rollAngle += moved / (size * 0.5)
					else
						local upright = math.round(entry.rollAngle / TWO_PI) * TWO_PI
						entry.rollAngle += (upright - entry.rollAngle) * 0.25
					end
					if rollAxis == "Z" then
						body *= CFrame.Angles(0, 0, entry.rollAngle)
					else
						body *= CFrame.Angles(-entry.rollAngle, 0, 0)
					end
				end

				for _, item in entry.welds do
					local role = item.role
					local base = item.base
					local pivot = item.pivot
					local piece = item.weld.Part1 :: BasePart
					if role == "Parpado" then
						piece.Transparency = if blinking then 0 else 1
						item.weld.C0 = body * base
					elseif role == "Ala" then
						local side = if (pivot or base.Position).X >= 0 then 1 else -1
						local flap = CFrame.Angles(0, 0, side * math.sin(t * A.wingSpeed) * math.rad(A.wingDegrees))
						item.weld.C0 = if pivot then body * aroundPivot(pivot, flap) * base else body * base * flap
					elseif role == "Cola" then
						local swing = math.sin(t * 2) * math.rad(A.wagDegrees)
						item.weld.C0 = if pivot then body * aroundPivot(pivot, CFrame.Angles(0, swing, 0)) * base else body * base * CFrame.Angles(swing, 0, 0)
					elseif role == "Pinza" then
						if pivot then
							-- Mandíbula: solo se abre hacia arriba (el frente del bicho es -Z).
							local open = math.abs(math.sin(t * 2)) * math.rad(A.wagDegrees)
							item.weld.C0 = body * aroundPivot(pivot, CFrame.Angles(open, 0, 0)) * base
						else
							item.weld.C0 = body * base * CFrame.Angles(math.sin(t * 2) * math.rad(A.wagDegrees), 0, 0)
						end
					elseif role == "Pendulo" then
						local swing = CFrame.Angles(0, 0, math.sin(t * 1.5) * math.rad(A.swingDegrees))
						item.weld.C0 = if pivot then body * aroundPivot(pivot, swing) * base else body * base * swing
					elseif role == "Cabeza" then
						-- Una vuelta completa, rápida, y luego un rato quieta.
						local cycle = ((now + entry.phase) / A.headTurnSeconds) % 1
						local turn = if cycle < 0.35 and not sleeping then smooth(cycle / 0.35) * TWO_PI else 0
						local spin = CFrame.Angles(0, turn, 0)
						item.weld.C0 = if pivot then body * aroundPivot(pivot, spin) * base else body * base * spin
					elseif role == "Giro" then
						item.weld.C0 = body * base * CFrame.Angles(if sleeping then 0 else now * A.spinSpeed * TWO_PI, 0, 0)
					elseif role == "Brillo" then
						piece.Transparency = (0.5 + 0.5 * math.sin(t * A.pulseSpeed)) * A.pulseDepth
						item.weld.C0 = body * base
					elseif role == "Arcoiris" then
						local step = (now + entry.phase) / A.hueSeconds
						local hue, saturation, value = item.color:ToHSV()
						-- Salta de color en cada paso, con una transición corta para que no parpadee.
						local blend = smooth(math.clamp((step % 1) * 4, 0, 1))
						local shift = (math.floor(step) + blend) * 0.19
						piece.Color = Color3.fromHSV((hue + shift) % 1, math.max(saturation, 0.75), math.max(value, 0.95))
						item.weld.C0 = body * base
					elseif role == "Gota" then
						local fall = (now * A.dropSpeed + entry.phase) % 1
						item.weld.C0 = body * base * CFrame.new(0, -fall * size * 0.3, 0)
						piece.Transparency = fall
					else
						item.weld.C0 = body * base
					end
				end
			end
		end
	end)
end

return CritterAnimator
