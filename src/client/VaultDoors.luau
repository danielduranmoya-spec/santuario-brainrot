--!strict
-- Puertas de las bóvedas: el servidor las deja atravesables; aquí, solo para este jugador, se vuelven
-- sólidas si no ha abierto esa bóveda, y desaparecen (con su panel de precio) cuando la abre.
-- Es solo comodidad: el servidor igualmente no deja atrapar bichos de bóvedas cerradas.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local VaultDoors = {}

local function maxVault(): number
	return (player:GetAttribute("MaxVault") :: number?) or 1
end

local function apply(vaultModel: Instance)
	local index = vaultModel:GetAttribute("VaultIndex")
	if typeof(index) ~= "number" then
		return
	end
	local open = index <= maxVault()
	local door = vaultModel:FindFirstChild("Puerta")
	if door and door:IsA("BasePart") then
		door.CanCollide = not open
		door.LocalTransparencyModifier = if open then 1 else 0
	end
	local panel = vaultModel:FindFirstChild("Panel")
	if panel and panel:IsA("BasePart") then
		panel.LocalTransparencyModifier = if open then 1 else 0
		local text = panel:FindFirstChild("Texto")
		if text and text:IsA("SurfaceGui") then
			text.Enabled = not open
		end
		local prompt = panel:FindFirstChild("Abrir")
		if prompt and prompt:IsA("ProximityPrompt") then
			-- Solo se ofrece abrir la siguiente; las demás enseñan su precio pero no el botón.
			prompt.Enabled = index == maxVault() + 1
		end
	end
end

-- Panel de la siguiente bóveda por abrir (para guiar al jugador hasta él).
function VaultDoors.NextPanel(): BasePart?
	local folder = Workspace:FindFirstChild("Bovedas")
	local model = folder and folder:FindFirstChild("Boveda" .. (maxVault() + 1))
	local panel = model and model:FindFirstChild("Panel")
	return if panel and panel:IsA("BasePart") then panel else nil
end

function VaultDoors.Start()
	local folder = Workspace:WaitForChild("Bovedas")
	local function applyAll()
		for _, vaultModel in folder:GetChildren() do
			apply(vaultModel)
		end
	end
	-- Las piezas pueden llegar más tarde que el modelo (streaming) y se construyen bóvedas nuevas.
	folder.DescendantAdded:Connect(function(descendant)
		local vaultModel = descendant:FindFirstAncestorWhichIsA("Model")
		if vaultModel and vaultModel.Parent == folder then
			task.defer(apply, vaultModel)
		end
	end)
	player:GetAttributeChangedSignal("MaxVault"):Connect(applyAll)
	applyAll()
end

return VaultDoors
