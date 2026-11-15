--!strict
-- Tienda: game passes y developer products de Config/Shop.
--   * Los pases se comprueban al entrar y se marcan en el jugador con atributos Pass_<Nombre>.
--   * Los productos se conceden SOLO en MarketplaceService.ProcessReceipt, de forma idempotente:
--     cada compra (PurchaseId) se apunta en el perfil y nunca se da dos veces.
--   * Si un id es 0 (aún no creado en el Creator Hub), la tienda avisa en lugar de romperse.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local CrittersConfig = require(Config:WaitForChild("Critters"))
local Gameplay = require(Config:WaitForChild("Gameplay"))
local Shop = require(Config:WaitForChild("Shop"))

local Data = require(script.Parent:WaitForChild("Data"))
local Plots = require(script.Parent:WaitForChild("Plots"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local NOT_CONFIGURED = "Este producto aún no está a la venta (falta su ID en src/shared/Config/Shop.luau)."

local Purchases = {}

local joinedAt: { [Player]: number } = {}
local lastAction: { [Player]: number } = {}

local productNameById: { [number]: string } = {}
for name, product in Shop.DevProducts do
	if product.id ~= 0 then
		productNameById[product.id] = name
	end
end

local passNameById: { [number]: string } = {}
for name, pass in Shop.GamePasses do
	if pass.id ~= 0 then
		passNameById[pass.id] = name
	end
end

local function notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, text)
end

function Purchases.HasPass(player: Player, name: string): boolean
	return player:GetAttribute("Pass_" .. name) == true
end

local function setPass(player: Player, name: string, owned: boolean)
	player:SetAttribute("Pass_" .. name, owned)
	if name == "VIP" then
		Plots.Refresh(player)
	end
end

local function checkPasses(player: Player)
	for name, pass in Shop.GamePasses do
		local owned = false
		if pass.id ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			owned = ok and result == true
			if not ok then
				warn("[Purchases] No se pudo comprobar el pase " .. name .. ": " .. tostring(result))
			end
		end
		if player.Parent then
			setPass(player, name, owned)
		end
	end
end

local function firstCritterOfRarity(rarity: string): CrittersConfig.Critter?
	for _, def in CrittersConfig.List do
		if def.rarity == rarity then
			return def
		end
	end
	return nil
end

-- Qué da cada developer product. Se llama solo desde ProcessReceipt.
local grants: { [string]: (Player, Data.Profile) -> string } = {
	PackInicio = function(player, profile)
		local pack = Shop.DevProducts.PackInicio
		profile.starterPackBought = true
		profile.baits += pack.baits
		local def = firstCritterOfRarity(pack.critterRarity)
		if def then
			Plots.GrantCritter(player, def)
		end
		return "🎉 ¡Pack de inicio! +" .. pack.baits .. " cebos" .. (if def then " y " .. def.name else "")
	end,
	Cebo = function(_player, profile)
		profile.baits += Shop.DevProducts.Cebo.baits
		return "+" .. Shop.DevProducts.Cebo.baits .. " cebo"
	end,
	SuerteX2 = function(_player, profile)
		local duration = Shop.DevProducts.SuerteX2.durationSeconds
		profile.luckUntil = math.max(profile.luckUntil, os.time()) + duration
		return "🍀 ¡Suerte x2 durante " .. duration // 60 .. " minutos!"
	end,
}

local function processReceipt(info: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local profile = player and Data.Get(player)
	if not player or not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- se reintentará cuando vuelva a entrar
	end

	local purchaseId = tostring(info.PurchaseId)
	if table.find(profile.receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- ya se dio antes
	end

	local name = productNameById[info.ProductId]
	local grant = name and grants[name]
	if not grant then
		warn("[Purchases] Producto desconocido: " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, message = pcall(grant, player, profile)
	if not ok then
		warn("[Purchases] Error al dar " .. tostring(name) .. ": " .. tostring(message))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(profile.receipts, purchaseId)
	while #profile.receipts > Gameplay.Data.receiptHistory do
		table.remove(profile.receipts, 1)
	end
	Data.Replicate(player)

	-- Guardamos ya: si no se puede, Roblox volverá a llamar y el recibo apuntado evita darlo dos veces.
	if Data.IsPersistent(player) and not Data.Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	notify(player, message)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onPromptPurchase(player: Player, kind: unknown, name: unknown)
	local now = os.clock()
	if now - (lastAction[player] or 0) < Gameplay.Menus.actionCooldownSeconds then
		return
	end
	lastAction[player] = now
	if typeof(kind) ~= "string" or typeof(name) ~= "string" then
		return
	end

	if kind == "pass" then
		local pass = Shop.GamePasses[name]
		if not pass then
			return
		end
		if Purchases.HasPass(player, name) then
			notify(player, "Ya tienes " .. pass.title .. ".")
		elseif pass.id == 0 then
			notify(player, NOT_CONFIGURED)
		else
			MarketplaceService:PromptGamePassPurchase(player, pass.id)
		end
	elseif kind == "product" then
		local product = Shop.DevProducts[name]
		local profile = Data.Get(player)
		if not product or not profile then
			return
		end
		if name == "PackInicio" then
			local minutes = (os.clock() - (joinedAt[player] or now)) / 60
			if profile.starterPackBought or minutes < Shop.DevProducts.PackInicio.showAfterMinutes then
				return
			end
		end
		if product.id == 0 then
			notify(player, NOT_CONFIGURED)
		else
			MarketplaceService:PromptProductPurchase(player, product.id)
		end
	end
end

function Purchases.Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		local name = passNameById[passId]
		if purchased and name then
			setPass(player, name, true)
			notify(player, "🎉 ¡Gracias! Ya tienes " .. Shop.GamePasses[name].title .. ".")
		end
	end)
	Remotes.PromptPurchase.OnServerEvent:Connect(onPromptPurchase)

	local function onPlayerAdded(player: Player)
		joinedAt[player] = os.clock()
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		joinedAt[player] = nil
		lastAction[player] = nil
	end)
	Data.OnLoaded(function(player)
		checkPasses(player)
	end)
end

return Purchases
