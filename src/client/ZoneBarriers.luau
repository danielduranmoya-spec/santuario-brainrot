--!strict
-- Barreras de zona: el servidor las deja atravesables; aquí, solo para este jugador, se vuelven
-- sólidas si no tiene la zona y desaparecen (con su puerta) cuando la desbloquea.
-- Es solo comodidad: el servidor igualmente no deja atrapar bichos de zonas bloqueadas.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local ZoneBarriers = {}

local function apply(zoneModel: Instance)
	local zoneId = zoneModel:GetAttribute("ZoneId")
	if typeof(zoneId) ~= "string" then
		return
	end
	local unlocked = player:GetAttribute("Zone_" .. zoneId) == true
	local barrier = zoneModel:FindFirstChild("Barrera")
	if barrier and barrier:IsA("BasePart") then
		barrier.CanCollide = not unlocked
		barrier.LocalTransparencyModifier = if unlocked then 1 else 0
	end
	local gate = zoneModel:FindFirstChild("Puerta")
	if gate and gate:IsA("BasePart") then
		gate.LocalTransparencyModifier = if unlocked then 1 else 0
		local sign = gate:FindFirstChild("Cartel")
		if sign and sign:IsA("BillboardGui") then
			sign.Enabled = not unlocked
		end
		local prompt = gate:FindFirstChild("Desbloquear")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = not unlocked
		end
	end
end

function ZoneBarriers.Start()
	local folder = Workspace:WaitForChild("Zonas")
	local function applyAll()
		for _, zoneModel in folder:GetChildren() do
			apply(zoneModel)
		end
	end
	-- Las piezas pueden llegar más tarde que el modelo (streaming): se vuelve a aplicar al llegar cada una.
	folder.DescendantAdded:Connect(function(descendant)
		local zoneModel = descendant:FindFirstAncestorWhichIsA("Model")
		if zoneModel and zoneModel.Parent == folder then
			task.defer(apply, zoneModel)
		end
	end)
	player.AttributeChanged:Connect(function(name: string)
		if string.sub(name, 1, 5) == "Zone_" then
			applyAll()
		end
	end)
	applyAll()
end

return ZoneBarriers
