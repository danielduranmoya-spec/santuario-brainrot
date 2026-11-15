--!strict
-- Campo de bóvedas sin fin. Cada bóveda es un tramo del campo con su temática; entre una y otra
-- hay un muro-puerta con un panel "Abrir bóveda": se paga una vez y queda abierta para siempre.
--   * El servidor deja el muro atravesable; cada cliente lo vuelve sólido solo para sí mismo si aún
--     no la ha pagado (client/VaultDoors). Además, el servidor no deja atrapar bichos de bóvedas
--     cerradas (CritterSpawner), así que saltarse el muro no sirve de nada.
--   * Se construyen initialVaults al arrancar y, cada vez que alguien abre una, aheadVaults más por
--     delante (terreno y decorado en WorldArt.BuildVault), hasta Progression.EndlessVaults.maxVaults.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Art = require(Config:WaitForChild("Art"))
local Format = require(Shared:WaitForChild("Format"))
local VaultMath = require(Shared:WaitForChild("VaultMath"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local WorldArt = require(script.Parent:WaitForChild("WorldArt"))
local Boundary = require(script.Parent:WaitForChild("Boundary"))

local F = Gameplay.Field
local D = Gameplay.VaultDoor

local Vaults = {}

local folder = Instance.new("Folder")
folder.Name = "Bovedas"
folder.Parent = Workspace

local generated = 0
local panels: { [number]: BasePart } = {}
local lastAction: { [Player]: number } = {}

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

local function newSurfaceText(part: BasePart, face: Enum.NormalId, text: string, color: Color3): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Texto"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0)
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.Parent = gui
	return label
end

local function tryUnlock(player: Player, n: number)
	local now = os.clock()
	if now - (lastAction[player] or 0) < Gameplay.Menus.actionCooldownSeconds then
		return
	end
	lastAction[player] = now

	local profile = Data.Get(player)
	local panel = panels[n]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not profile or not panel or not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - panel.Position).Magnitude > D.promptDistance + Gameplay.Catching.rangeTolerance then
		return
	end
	if profile.maxVault >= n then
		return
	end
	if profile.maxVault < n - 1 then
		Remotes.Notify:FireClient(player, "Primero abre la bóveda " .. (n - 1) .. ".")
		return
	end
	local cost = VaultMath.cost(n)
	if not Economy.TrySpend(player, cost) then
		Remotes.Notify:FireClient(player, "Te faltan " .. Format.number(cost - Economy.GetCoins(player)) .. " 💰 para " .. VaultMath.name(n) .. ".")
		return
	end
	profile.maxVault = n
	Data.Replicate(player)
	local multiplier = VaultMath.valueMultiplier(n)
	Remotes.Notify:FireClient(
		player,
		"🔓 ¡Has abierto la bóveda " .. n .. ": " .. VaultMath.name(n) .. "!" .. (if multiplier > 1 then " Sus bichos valen x" .. multiplier .. "." else "")
	)
	Remotes.Effect:FireClient(player, "desbloqueo", panel.Position)
	Vaults.EnsureGenerated(n + F.aheadVaults)
end

local function buildDoor(n: number)
	local theme = VaultMath.theme(n)
	local color = Art.themeColors[theme]
	local z = VaultMath.frontZ(n)
	local ground = Gameplay.GroundY

	local model = Instance.new("Model")
	model.Name = "Boveda" .. n
	model:SetAttribute("VaultIndex", n)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- Columnas a los lados y dintel con el nombre (se quedan aunque la puerta se abra).
	for _, side in { -1, 1 } do
		newPart("Columna", Vector3.new(6, D.height + 4, 6), CFrame.new(side * (F.width / 2 - 3), ground + (D.height + 4) / 2, z), Color3.fromRGB(150, 140, 130), Enum.Material.Slate, model)
		newPart("Remate", Vector3.new(8, 2, 8), CFrame.new(side * (F.width / 2 - 3), ground + D.height + 5, z), color, Enum.Material.SmoothPlastic, model)
	end
	local lintel = newPart("Dintel", Vector3.new(F.width, 4, 4), CFrame.new(0, ground + D.height + 2, z), color, Enum.Material.SmoothPlastic, model)
	local title = "BÓVEDA " .. n .. " · " .. string.upper(VaultMath.name(n))
	newSurfaceText(lintel, Enum.NormalId.Back, title, Color3.new(1, 1, 1)) -- cara que mira a la plaza (+Z)
	newSurfaceText(lintel, Enum.NormalId.Front, title, Color3.new(1, 1, 1))

	if n >= 2 then
		local door = newPart("Puerta", Vector3.new(F.width - 12, D.height, D.thickness), CFrame.new(0, ground + D.height / 2, z), color, Enum.Material.ForceField, model)
		door.Transparency = D.transparency
		door.CanCollide = false -- el cliente la vuelve sólida si no la tienes
		door.CanQuery = false

		local cost = VaultMath.cost(n)
		local multiplier = VaultMath.valueMultiplier(n)
		local panel = newPart("Panel", Vector3.new(14, 7, 1), CFrame.new(0, ground + 5.5, z + 1.6), Color3.fromRGB(40, 35, 50), Enum.Material.SmoothPlastic, model)
		panel.CanCollide = false
		newSurfaceText(
			panel,
			Enum.NormalId.Back,
			"🔒 " .. VaultMath.name(n) .. "\n" .. Format.number(cost) .. " 💰" .. (if multiplier > 1 then "\nbichos x" .. multiplier else ""),
			Art.colors.gold
		)
		panels[n] = panel

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Abrir"
		prompt.ActionText = "Abrir (" .. Format.number(cost) .. " 💰)"
		prompt.ObjectText = "Bóveda " .. n
		prompt.HoldDuration = D.promptHoldSeconds
		prompt.MaxActivationDistance = D.promptDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = panel
		prompt.Triggered:Connect(function(player: Player)
			tryUnlock(player, n)
		end)
	end
	model.Parent = folder
end

-- Construye las bóvedas que falten hasta `count` (terreno, decorado y puertas).
function Vaults.EnsureGenerated(count: number)
	count = math.min(count, VaultMath.MaxVaults)
	if count <= generated then
		return
	end
	for n = generated + 1, count do
		WorldArt.BuildVault(n)
		buildDoor(n)
	end
	generated = count
	Boundary.SetFieldEnd(VaultMath.backZ(generated))
	Workspace:SetAttribute("VaultsGenerated", generated)
end

function Vaults.Generated(): number
	return generated
end

function Vaults.IsUnlocked(player: Player, n: number): boolean
	local profile = Data.Get(player)
	return profile ~= nil and profile.maxVault >= n
end

-- La bóveda más lejana que tiene abierta alguien del servidor.
function Vaults.HighestOpen(): number
	local highest = 1
	for _, player in Players:GetPlayers() do
		local profile = Data.Get(player)
		if profile then
			highest = math.max(highest, profile.maxVault)
		end
	end
	return highest
end

function Vaults.Start()
	Vaults.EnsureGenerated(F.initialVaults)
	Data.OnLoaded(function(_player, profile)
		Vaults.EnsureGenerated(profile.maxVault + F.aheadVaults)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)
end

return Vaults
