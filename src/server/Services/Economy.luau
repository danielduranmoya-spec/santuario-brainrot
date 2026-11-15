--!strict
-- Monedas del jugador. El valor real está en su perfil guardado (Services/Data);
-- leaderstats.Monedas es solo una copia para que se vea. Solo el servidor las cambia.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Data = require(script.Parent:WaitForChild("Data"))

local Economy = {}

local function getCoinsValue(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Monedas")
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

local function sync(player: Player)
	local profile = Data.Get(player)
	local coins = getCoinsValue(player)
	if profile and coins then
		coins.Value = profile.coins
	end
end

function Economy.GetCoins(player: Player): number
	local profile = Data.Get(player)
	return if profile then profile.coins else 0
end

function Economy.AddCoins(player: Player, amount: number)
	local profile = Data.Get(player)
	if profile and amount > 0 then
		profile.coins += math.floor(amount)
		sync(player)
	end
end

-- Cobra `amount` si el jugador lo tiene. Devuelve si se pudo.
function Economy.TrySpend(player: Player, amount: number): boolean
	local profile = Data.Get(player)
	if not profile or amount < 0 or profile.coins < amount then
		return false
	end
	profile.coins -= math.floor(amount)
	sync(player)
	return true
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Monedas"
	coins.Value = 0
	coins.Parent = leaderstats

	leaderstats.Parent = player
	sync(player)
end

function Economy.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Data.OnLoaded(function(player)
		sync(player)
	end)

	-- Solo en Studio: ServerStorage.DebugDarMonedas:Invoke(player, cantidad) para probar mejoras y zonas
	-- desde la barra de comandos o el MCP. No existe en el juego publicado.
	if RunService:IsStudio() then
		local debugGive = Instance.new("BindableFunction")
		debugGive.Name = "DebugDarMonedas"
		debugGive.OnInvoke = function(player: Player, amount: number)
			Economy.AddCoins(player, amount)
			return Economy.GetCoins(player)
		end
		debugGive.Parent = ServerStorage
	end
end

return Economy
