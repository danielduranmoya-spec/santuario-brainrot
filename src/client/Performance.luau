--!strict
-- Rendimiento en este dispositivo (Config/Art.performance). Todo es local: no cambia nada para los
-- demás jugadores ni en el servidor.
--   * Bajo detalle (móviles, tablets o calidad gráfica baja): se quitan de la pantalla los adornos
--     pequeños de cada bicho (piezas con el atributo "Fine") y las partículas salen a la mitad.
--   * En todos los dispositivos: las partículas y luces de los bichos lejanos se apagan.
-- CritterAnimator llama a Performance.Prepare(raíz) con cada bicho nuevo antes de animarlo.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Art = require(Config:WaitForChild("Art"))

local PERF = Art.performance

type Effects = { root: BasePart, emitters: { ParticleEmitter }, lights: { Light }, on: boolean }

local Performance = {}

local function detectLowDetail(): boolean
	local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if PERF.lowDetailOnTouch and isTouch then
		return true
	end
	-- Calidad gráfica elegida a mano en el menú de Roblox (Automático no cuenta).
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	return ok and type(level) == "number" and level > 0 and level <= PERF.lowDetailQualityLevel
end

Performance.lowDetail = detectLowDetail()

local low = Performance.lowDetail
Performance.animationFps = if low then PERF.animationFps.low else PERF.animationFps.high
Performance.animationDistance = if low then PERF.animationDistance.low else PERF.animationDistance.high
local effectsDistance = if low then PERF.effectsDistance.low else PERF.effectsDistance.high
local rateScale = if low then PERF.particleRateScale.low else PERF.particleRateScale.high

local effects: { [BasePart]: Effects } = {}

-- Prepara un bicho recién llegado: quita adornos (bajo detalle) y apunta sus partículas y luces.
function Performance.Prepare(root: BasePart)
	if effects[root] then
		return
	end
	if Performance.lowDetail then
		for _, child in root:GetChildren() do
			if child:GetAttribute("Fine") == true then
				child:Destroy()
			end
		end
	end
	local entry: Effects = { root = root, emitters = {}, lights = {}, on = true }
	for _, child in root:GetChildren() do
		if child:IsA("ParticleEmitter") then
			if rateScale ~= 1 then
				child.Rate *= rateScale
			end
			table.insert(entry.emitters, child)
		elseif child:IsA("Light") then
			table.insert(entry.lights, child)
		end
	end
	if #entry.emitters > 0 or #entry.lights > 0 then
		effects[root] = entry
		root.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				effects[root] = nil
			end
		end)
	end
end

local function setOn(entry: Effects, on: boolean)
	if entry.on == on then
		return
	end
	entry.on = on
	for _, emitter in entry.emitters do
		emitter.Enabled = on
	end
	for _, light in entry.lights do
		light.Enabled = on
	end
end

function Performance.Start()
	task.spawn(function()
		while true do
			task.wait(PERF.cullCheckSeconds)
			local camera = Workspace.CurrentCamera
			if camera then
				local cameraPosition = camera.CFrame.Position
				for root, entry in effects do
					setOn(entry, (root.Position - cameraPosition).Magnitude <= effectsDistance)
				end
			end
		end
	end)
end

return Performance
