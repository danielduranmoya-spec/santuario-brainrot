--!strict
-- Robo amable con cebo y valla (Config/Events.Bait, GDD "Elemento social").
--   1. Junto a la entrada de cada santuario hay un aviso "Poner cebo". Si tienes cebos (TIENDA o
--      códigos) y el santuario es de otro jugador, pones uno: dura durationSeconds.
--   2. El dueño recibe un aviso y puede defenderse: ir a la entrada y "Espantar" el cebo, o comprar
--      una VALLA con monedas (10 min de protección; también se puede comprar antes).
--   3. Si nadie lo impide, uno de sus bichos (nunca legendario) se va al santuario del que puso el
--      cebo. Nadie pierde más de un bicho cada cooldownPerVictimSeconds, y a quien tiene pocos
--      bichos no se le puede poner cebo.
-- Todo se valida aquí (el cliente solo enseña el botón VALLA y la cuenta atrás).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Events = require(Config:WaitForChild("Events"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Format = require(Shared:WaitForChild("Format"))
local MutationMath = require(Shared:WaitForChild("MutationMath"))

local Data = require(script.Parent:WaitForChild("Data"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))

local B = Events.Bait
local S = Gameplay.Sanctuary

type ActiveBait = {
	thief: Player,
	victim: Player,
	part: BasePart,
	endsAt: number, -- os.clock()
}

local Bait = {}

local active: { [Player]: ActiveBait } = {} -- por víctima: como mucho un cebo por santuario
local lastAction: { [Player]: number } = {}

local function notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, text)
end

local function canBeStolen(def: CrittersConfig.Critter): boolean
	return not B.neverSteal[def.rarity]
end

local function hasFence(profile: Data.Profile): boolean
	return profile.fenceUntil > os.time()
end

local function passCooldown(player: Player): boolean
	local now = os.clock()
	if now - (lastAction[player] or 0) < Gameplay.Menus.actionCooldownSeconds then
		return false
	end
	lastAction[player] = now
	return true
end

-- Quita el cebo de un santuario (espantado, valla, o el ladrón o la víctima se han ido).
local function clearBait(victim: Player)
	local bait = active[victim]
	if not bait then
		return
	end
	active[victim] = nil
	bait.part:Destroy()
	if victim.Parent then
		victim:SetAttribute("BaitedUntil", nil)
		victim:SetAttribute("BaitedBy", nil)
	end
end

-- Pastel de cebo con un aviso "Espantar" que solo puede usar el dueño del santuario.
local function createBaitPart(victim: Player, origin: CFrame): BasePart
	local part = Instance.new("Part")
	part.Name = "Cebo"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(1.4, 2.6, 2.6)
	part.CFrame = origin * CFrame.new(0, 1.6, -S.plotSize / 2 - 4) * CFrame.Angles(0, 0, math.rad(90))
	part.Color = Color3.fromRGB(255, 170, 200)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	local cherry = Instance.new("Part")
	cherry.Name = "Cereza"
	cherry.Shape = Enum.PartType.Ball
	cherry.Size = Vector3.one * 0.8
	cherry.CFrame = part.CFrame * CFrame.new(1, 0, 0)
	cherry.Color = Color3.fromRGB(220, 30, 50)
	cherry.Anchored = true
	cherry.CanCollide = false
	cherry.CanQuery = false
	cherry.Parent = part
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 200, 230)
	sparkles.Parent = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Espantar"
	prompt.ActionText = "Espantar"
	prompt.ObjectText = "Cebo"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = B.promptDistance
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OnlyFor", victim.UserId) -- el cliente lo oculta a los demás
	prompt.Parent = part
	prompt.Triggered:Connect(function(player: Player)
		local bait = active[victim]
		if player ~= victim or not bait or bait.part ~= part then
			return
		end
		clearBait(victim)
		notify(victim, "🛡 ¡Has espantado el cebo! Tus bichos están a salvo.")
		if bait.thief.Parent then
			notify(bait.thief, "😅 " .. victim.DisplayName .. " ha espantado tu cebo.")
		end
	end)
	part.Parent = Workspace
	return part
end

-- Cuando acaba el tiempo: si sigue el cebo, uno de los bichos se va con el ladrón.
local function resolve(bait: ActiveBait)
	if active[bait.victim] ~= bait then
		return -- ya se espantó o se puso una valla
	end
	clearBait(bait.victim)
	local thief, victim = bait.thief, bait.victim
	local victimProfile = Data.Get(victim)
	if not thief.Parent or not victim.Parent or not victimProfile or not Data.Get(thief) then
		return
	end
	if hasFence(victimProfile) then
		return
	end
	local def, multiplier, color, size = Plots.TakeRandomCritter(victim, canBeStolen)
	if not def then
		notify(thief, "El cebo no ha atraído a ningún bicho.")
		return
	end
	victimProfile.lastStolenAt = os.time()
	Plots.GrantCritter(thief, def, multiplier, color, size)
	Data.Replicate(victim)
	Data.Replicate(thief)
	local name = MutationMath.displayName(def.name, color, size) .. (if multiplier > 1 then " x" .. multiplier else "")
	notify(thief, "🍰 ¡" .. name .. " ha seguido tu cebo hasta tu santuario!")
	notify(victim, "😢 Tu " .. name .. " se ha ido detrás del cebo de " .. thief.DisplayName .. ". Compra una VALLA para que no vuelva a pasar.")
	Remotes.Effect:FireClient(thief, "recompensa")
	Analytics.Custom(thief, "cebo_robo")
end

local function placeBait(thief: Player, victim: Player?, origin: CFrame)
	if not passCooldown(thief) then
		return
	end
	local thiefProfile = Data.Get(thief)
	local victimProfile = victim and Data.Get(victim)
	if not victim or not thiefProfile or not victimProfile then
		notify(thief, "Este santuario está libre: no hay bichos que atraer.")
		return
	end
	if victim == thief then
		return
	end
	if thiefProfile.baits < 1 then
		notify(thief, "No tienes cebos. Consíguelos en la TIENDA o con CÓDIGOS.")
		return
	end
	if active[victim] then
		notify(thief, "Ya hay un cebo en este santuario.")
		return
	end
	if hasFence(victimProfile) then
		notify(thief, "🛡 " .. victim.DisplayName .. " tiene una valla: el cebo no sirve.")
		return
	end
	if os.time() - victimProfile.lastStolenAt < B.cooldownPerVictimSeconds then
		notify(thief, "Este santuario perdió un bicho hace poco. Prueba en otro.")
		return
	end
	if Plots.CountCritters(victim, canBeStolen) < B.minVictimCritters then
		notify(thief, victim.DisplayName .. " tiene muy pocos bichos. ¡Deja que crezca!")
		return
	end

	thiefProfile.baits -= 1
	Data.Replicate(thief)
	local bait: ActiveBait = {
		thief = thief,
		victim = victim,
		part = createBaitPart(victim, origin),
		endsAt = os.clock() + B.durationSeconds,
	}
	active[victim] = bait
	victim:SetAttribute("BaitedUntil", Workspace:GetServerTimeNow() + B.durationSeconds)
	victim:SetAttribute("BaitedBy", thief.DisplayName)
	notify(thief, "🍰 Cebo puesto. Si " .. victim.DisplayName .. " no lo espanta en " .. B.durationSeconds .. " s, uno de sus bichos vendrá contigo.")
	notify(victim, "🍰 ¡" .. thief.DisplayName .. " ha puesto un cebo en tu santuario! Espántalo en la entrada o pon una VALLA.")
	task.delay(B.durationSeconds, resolve, bait)
end

-- Valla: se paga con monedas y protege fenceDurationSeconds. Quita el cebo que hubiera.
local function onBuyFence(player: Player)
	if not passCooldown(player) then
		return
	end
	local profile = Data.Get(player)
	if not profile then
		return
	end
	if hasFence(profile) then
		notify(player, "🛡 Ya tienes una valla puesta.")
		return
	end
	if not Economy.TrySpend(player, B.fenceCost) then
		notify(player, "Te faltan " .. Format.number(B.fenceCost - Economy.GetCoins(player)) .. " 💰 para la valla.")
		return
	end
	profile.fenceUntil = os.time() + B.fenceDurationSeconds
	Data.Replicate(player)
	Plots.SetFence(player, true)
	local bait = active[player]
	clearBait(player)
	if bait and bait.thief.Parent then
		notify(bait.thief, "🛡 " .. player.DisplayName .. " ha puesto una valla y tu cebo ya no sirve.")
	end
	notify(player, "🛡 ¡Valla puesta durante " .. B.fenceDurationSeconds // 60 .. " minutos! Nadie puede atraer a tus bichos.")
	Remotes.Effect:FireClient(player, "compra")
	Analytics.Custom(player, "valla_comprada")
end

-- Un aviso "Poner cebo" delante de la entrada de cada santuario.
local function addBaitPrompt(plot: Plots.PlotInfo)
	local anchor = Instance.new("Part")
	anchor.Name = "PuntoCebo"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = plot.origin * CFrame.new(0, 3, -S.plotSize / 2 - 4)
	anchor.Parent = plot.model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PonerCebo"
	prompt.ActionText = "Poner cebo"
	prompt.ObjectText = "Robo amable"
	prompt.HoldDuration = B.promptHoldSeconds
	prompt.MaxActivationDistance = B.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt:SetAttribute("BaitPrompt", true) -- el cliente lo oculta en tu propio santuario y sin cebos
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player: Player)
		placeBait(player, plot.owner, plot.origin)
	end)
end

function Bait.Start()
	for _, plot in Plots.GetPlots() do
		addBaitPrompt(plot)
	end
	Remotes.BuyFence.OnServerEvent:Connect(onBuyFence)

	Data.OnLoaded(function(player, profile)
		if hasFence(profile) then
			Plots.SetFence(player, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
		clearBait(player)
		for victim, bait in active do
			if bait.thief == player then
				clearBait(victim)
			end
		end
	end)

	-- Cada segundo: quita la valla a quien se le ha acabado.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local profile = Data.Get(player)
				local shownUntil = (player:GetAttribute("FenceUntil") :: number?) or 0
				if profile and shownUntil > 0 and profile.fenceUntil <= now then
					player:SetAttribute("FenceUntil", 0)
					Plots.SetFence(player, false)
					notify(player, "🛡 Tu valla se ha acabado.")
				end
			end
		end
	end)
end

return Bait
