--!strict
-- Monedas del jugador (leaderstats). Solo el servidor las cambia.
-- Guardado con DataStore: siguiente fase (semanas 9-10).

local Players = game:GetService("Players")

local Economy = {}

local function getCoinsValue(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Monedas")
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

function Economy.AddCoins(player: Player, amount: number)
	local coins = getCoinsValue(player)
	if coins and amount > 0 then
		coins.Value += math.floor(amount)
	end
end

function Economy.GetCoins(player: Player): number
	local coins = getCoinsValue(player)
	return if coins then coins.Value else 0
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Monedas"
	coins.Value = 0
	coins.Parent = leaderstats

	leaderstats.Parent = player
end

function Economy.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return Economy
