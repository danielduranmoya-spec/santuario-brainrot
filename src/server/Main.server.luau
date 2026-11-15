--!strict
-- Punto de entrada del servidor. Por ahora: leaderstats de Monedas.
-- Siguientes pasos (semanas 7-8, ver design/GDD.md): Services/CritterSpawner, Services/Sanctuary,
-- Services/Data (DataStore) y Services/Purchases (ProcessReceipt).

local Players = game:GetService("Players")

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Monedas"
	coins.Value = 0
	coins.Parent = leaderstats

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
