--!strict
-- Máquinas de fusión (Config/Mutations.Machines), en la plaza junto a la entrada de las bóvedas:
--   * Agrandadora: 5 bichos iguales de tamaño Normal + monedas = 1 Grande.
--   * Titánica: 4 Grandes iguales + monedas = 1 Enorme.
-- Solo cambian el tamaño. El color del resultado se hereda de uno de los bichos que entran,
-- elegido al azar: todos del mismo color = se conserva seguro; 2 Oro + 3 Normales = 40 % Oro.
-- El cliente solo dice qué máquina, qué bicho y qué color prefiere meter primero; el servidor
-- comprueba que los tiene, cobra y hace el cambio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Mutations = require(Config:WaitForChild("Mutations"))
local Format = require(Shared:WaitForChild("Format"))
local Layout = require(Shared:WaitForChild("Layout"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Guard = require(script.Parent:WaitForChild("Guard"))

type MachineDef = Mutations.MachineDef


local P = Mutations.MachinePlacement
local Fusion = {}

local rng = Random.new()
local lastAction: { [Player]: number } = {}
local machinePositions: { [string]: Vector3 } = {} -- dónde está cada máquina (para validar distancia)

local defsById: { [string]: CrittersConfig.Critter } = {}
for _, def in CrittersConfig.List do
	defsById[def.id] = def
end

local function notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, text)
end

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Una máquina: base de metal, tolva de cristal con luz, chimenea y cartel.
local function buildMachine(def: MachineDef, position: Vector3)
	local model = Instance.new("Model")
	model.Name = "Maquina" .. def.id
	local origin = CFrame.new(position)
	local metal = Color3.fromRGB(70, 75, 90)

	local base = newPart("Base", Vector3.new(9, 2, 9), origin * CFrame.new(0, 1, 0), metal, Enum.Material.DiamondPlate, model)
	newPart("Cuerpo", Vector3.new(7, 6, 7), origin * CFrame.new(0, 5, 0), def.color, Enum.Material.Metal, model)
	local glass = newPart("Tolva", Vector3.new(5, 4, 5), origin * CFrame.new(0, 10, 0), def.color, Enum.Material.Glass, model)
	glass.Transparency = 0.45
	local core = newPart("Nucleo", Vector3.new(2.4, 2.4, 2.4), origin * CFrame.new(0, 10, 0), Color3.new(1, 1, 1), Enum.Material.Neon, model)
	core.Shape = Enum.PartType.Ball
	core.CanCollide = false
	newPart("Tapa", Vector3.new(6, 0.8, 6), origin * CFrame.new(0, 12.4, 0), metal, Enum.Material.Metal, model)
	newPart("Chimenea", Vector3.new(1.6, 4, 1.6), origin * CFrame.new(2.4, 14.6, 2.4), metal, Enum.Material.Metal, model)
	for _, side in { -1, 1 } do
		newPart("Tubo", Vector3.new(1.2, 6, 1.2), origin * CFrame.new(side * 4.1, 5, 0), Color3.fromRGB(200, 200, 210), Enum.Material.Metal, model)
	end

	local light = Instance.new("PointLight")
	light.Color = def.color
	light.Range = 18
	light.Brightness = 1.5
	light.Parent = core

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(14, 0, 4, 0) -- en studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.Parent = core
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = string.upper(def.title) .. "\n" .. def.count .. " iguales = 1 " .. MutationMath.size(def.to).label
	label.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Usar"
	prompt.ObjectText = def.title
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = P.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = base
	prompt.Triggered:Connect(function(player: Player)
		Remotes.OpenMachine:FireClient(player, def.id)
	end)

	model.Parent = Workspace
	machinePositions[def.id] = base.Position
end

local function onFuse(player: Player, machineId: unknown, critterId: unknown, preferColor: unknown)
	local now = os.clock()
	if now - (lastAction[player] or 0) < P.requestCooldownSeconds then
		return
	end
	lastAction[player] = now
	if type(machineId) ~= "string" or type(critterId) ~= "string" or type(preferColor) ~= "string" then
		return
	end
	local machine = MutationMath.machine(machineId)
	local def = defsById[critterId]
	local profile = Data.Get(player)
	if not machine or not def or not profile then
		return
	end
	-- Hay que estar junto a la máquina (el menú solo se abre allí, pero un tramposo puede pedirlo desde lejos).
	local machinePosition = machinePositions[machine.id]
	if not machinePosition or not Guard.IsNear(player, machinePosition, P.promptDistance) then
		notify(player, "Acércate a la máquina " .. machine.title .. " para usarla.")
		return
	end

	-- Bichos del jugador que sirven: ese bicho y del tamaño que pide la máquina.
	local candidates: { { index: number, color: string, multiplier: number, value: number } } = {}
	for index, entry in profile.critters do
		local id, multiplier, color, size = MutationMath.decode(entry)
		if id == critterId and size == machine.from then
			table.insert(candidates, { index = index, color = color, multiplier = multiplier, value = multiplier * MutationMath.color(color).multiplier })
		end
	end
	if #candidates < machine.count then
		notify(player, "Necesitas " .. machine.count .. " " .. def.name .. " de tamaño " .. machine.from .. " (tienes " .. #candidates .. ").")
		return
	end
	-- Entran primero los del color preferido y después los que menos valen.
	table.sort(candidates, function(a, b)
		local aPreferred = a.color == preferColor
		local bPreferred = b.color == preferColor
		if aPreferred ~= bPreferred then
			return aPreferred
		end
		if a.value ~= b.value then
			return a.value < b.value
		end
		return a.index < b.index
	end)

	local used = {}
	local multiplier = math.huge
	for i = 1, machine.count do
		local candidate = candidates[i]
		table.insert(used, candidate)
		multiplier = math.min(multiplier, candidate.multiplier) -- el multiplicador de bóveda más bajo
	end

	local cost = MutationMath.fusionCost(machine, def.coinsPerSecond, multiplier)
	if not Economy.TrySpend(player, cost) then
		notify(player, "Te faltan monedas: la " .. machine.title .. " cuesta " .. Format.number(cost) .. " 💰 para este bicho.")
		return
	end
	local color = used[rng:NextInteger(1, #used)].color

	-- Se quitan de mayor a menor índice para no descolocar la lista; el nuevo ocupa el primer hueco.
	table.sort(used, function(a, b)
		return a.index > b.index
	end)
	local firstIndex = used[#used].index
	for _, candidate in used do
		table.remove(profile.critters, candidate.index)
	end
	table.insert(profile.critters, math.min(firstIndex, #profile.critters + 1), MutationMath.encode(def.id, multiplier, color, machine.to))
	Plots.Refresh(player)

	local name = MutationMath.displayName(def.name, color, machine.to) .. (if multiplier > 1 then " x" .. multiplier else "")
	notify(player, "⚙ ¡Fusión completada! Has conseguido: " .. name .. ".")
	Remotes.Effect:FireClient(player, "captura_mia")
end

function Fusion.Start()
	-- A los lados de la avenida que sale de la plaza hacia la zona 1 (Shared/Layout).
	for index, machine in Mutations.Machines do
		buildMachine(machine, Layout.machine(index))
	end
	Guard.Connect(Remotes.Fuse, "Fuse", onFuse)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)
end

return Fusion
