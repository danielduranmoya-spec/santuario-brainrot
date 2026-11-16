--!strict
-- Defensa contra trampas para todo lo que llega del cliente (Config/Gameplay.Security).
--   * Guard.Connect(remote, nombre, función): conecta un RemoteEvent con límite de peticiones por
--     segundo (cubo de fichas). Las peticiones de más se ignoran sin llegar a la función.
--   * Si un jugador acumula muchas peticiones ignoradas en poco tiempo, es un script: se le expulsa.
--   * Guard.IsNear(jugador, posición, distancia): comprueba en el servidor que el personaje está
--     de verdad junto a algo (máquinas, cebos...). Un tramposo puede activar avisos desde lejos.
--   * Guard.CatchTolerance(jugador): cuánto mirar hacia atrás al recibir un toque de la barra,
--     según el ping real del jugador.
-- Cada servicio sigue validando tipo y rango de los datos que recibe.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Gameplay = require(Config:WaitForChild("Gameplay"))

local SEC = Gameplay.Security

type Bucket = { tokens: number, updatedAt: number }

local Guard = {}

local buckets: { [Player]: { [string]: Bucket } } = {}
local lastSeen: { [Player]: { position: Vector3, at: number } } = {}
local blockedUntil: { [Player]: number } = {}
local dropped: { [Player]: { count: number, windowStart: number } } = {}

local function flag(player: Player, key: string)
	local now = os.clock()
	local entry = dropped[player]
	if not entry or now - entry.windowStart > SEC.floodWindowSeconds then
		entry = { count = 0, windowStart = now }
		dropped[player] = entry
	end
	entry.count += 1
	if entry.count == SEC.floodKickAfter then
		warn("[Guard] " .. player.Name .. " manda demasiadas peticiones (" .. key .. ")")
		if SEC.kickOnFlood then
			player:Kick("Se han detectado demasiadas acciones seguidas. Vuelve a entrar.")
		end
	end
end

-- ¿Puede `player` hacer ahora otra petición `key`? Gasta una ficha si puede.
function Guard.Allow(player: Player, key: string): boolean
	local limit = SEC.limits[key] or SEC.limits.Default
	local now = os.clock()
	local byKey = buckets[player]
	if not byKey then
		byKey = {}
		buckets[player] = byKey
	end
	local bucket = byKey[key]
	if not bucket then
		bucket = { tokens = limit.burst, updatedAt = now }
		byKey[key] = bucket
	end
	bucket.tokens = math.min(limit.burst, bucket.tokens + (now - bucket.updatedAt) * limit.rate)
	bucket.updatedAt = now
	if bucket.tokens < 1 then
		flag(player, key)
		return false
	end
	bucket.tokens -= 1
	return true
end

-- Conecta un RemoteEvent pasando antes por el límite de peticiones.
function Guard.Connect(remote: RemoteEvent, key: string, handler: (Player, ...any) -> ())
	remote.OnServerEvent:Connect(function(player: Player, ...)
		if Guard.Allow(player, key) then
			handler(player, ...)
		end
	end)
end

function Guard.GetRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- ¿Está el personaje a `distance` studs (más el margen de Security) de `position`?
function Guard.IsNear(player: Player, position: Vector3, distance: number): boolean
	local root = Guard.GetRoot(player)
	return root ~= nil and (root.Position - position).Magnitude <= distance + SEC.distanceTolerance
end

-- Segundos hacia atrás que se aceptan al recibir el toque de la barra de captura.
function Guard.CatchTolerance(player: Player): number
	local maxTolerance = Gameplay.Catching.latencyToleranceSeconds
	local ok, ping = pcall(function()
		return player:GetNetworkPing() -- ida y vuelta, en segundos
	end)
	if not ok or type(ping) ~= "number" or ping ~= ping then
		return maxTolerance
	end
	return math.clamp(ping * SEC.pingShare + SEC.pingExtraSeconds, SEC.pingExtraSeconds, maxTolerance)
end

-- El servidor ha movido al jugador a propósito (al aparecer, al volver dentro del mapa...):
-- ese salto no cuenta como teletransporte.
function Guard.NoteTeleport(player: Player)
	lastSeen[player] = nil
end

-- ¿Se ha movido hace poco más rápido de lo posible andando? (teletransporte con trampas)
function Guard.MovedTooFast(player: Player): boolean
	return (blockedUntil[player] or 0) > os.clock()
end

local function speedLoop()
	while true do
		task.wait(SEC.speedCheckSeconds)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local root = Guard.GetRoot(player)
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root and humanoid then
				local position = root.Position
				local seen = lastSeen[player]
				if seen then
					local flat = Vector3.new(position.X - seen.position.X, 0, position.Z - seen.position.Z).Magnitude
					local maxDistance = (humanoid.WalkSpeed * SEC.speedSlack + SEC.speedExtraStuds) * (now - seen.at)
					if flat > maxDistance then
						blockedUntil[player] = now + SEC.teleportBlockSeconds
					end
				end
				lastSeen[player] = { position = position, at = now }
			else
				lastSeen[player] = nil
			end
		end
	end
end

function Guard.Start()
	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function()
			Guard.NoteTeleport(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
		dropped[player] = nil
		lastSeen[player] = nil
		blockedUntil[player] = nil
	end)
	task.spawn(speedLoop)
end

return Guard
