--!strict
-- Productos de pago.
--
-- CÓMO PONER LOS IDS REALES:
--   1. Publica el juego y entra en https://create.roblox.com > tu experiencia > Monetización.
--   2. Crea cada Pase (Passes) y cada Producto de desarrollador (Developer Products) con el precio de abajo.
--   3. Copia el número de ID de cada uno y ponlo aquí en lugar del 0.
-- Mientras un id sea 0, la tienda lo muestra pero al pulsar avisa de que aún no está configurado.

local Shop = {}

Shop.GamePasses = {
	DobleMonedas = { id = 0, price = 99, title = "x2 Monedas", description = "Tus bichos generan el doble para siempre" },
	RedDorada = { id = 0, price = 149, title = "Red Dorada", description = "Zona verde al máximo en todas las capturas" },
	VIP = { id = 0, price = 299, title = "VIP", description = "+1 hueco en el santuario y nombre especial" },
}

Shop.DevProducts = {
	PackInicio = {
		id = 0,
		price = 49,
		oneTime = true,
		showAfterMinutes = 5,
		title = "Pack de inicio",
		description = "5 cebos + un bicho raro",
		baits = 5,
		critterRarity = "Raro",
	},
	Cebo = { id = 0, price = 25, title = "Cebo", description = "Ponlo en la entrada de otro santuario: atrae uno de sus bichos", baits = 1 },
	SuerteX2 = { id = 0, price = 49, durationSeconds = 15 * 60, title = "Suerte x2", description = "15 min con bichos raros reservados para ti" },
}

-- Orden en el menú de TIENDA.
Shop.PassOrder = { "DobleMonedas", "RedDorada", "VIP" }
Shop.ProductOrder = { "PackInicio", "SuerteX2", "Cebo" }

-- Ventajas de los pases.
Shop.Perks = {
	doubleCoinsMultiplier = 2,
	vipExtraSlots = 1,
}

Shop.PrivateServerPrice = 99

-- Suscripción de Roblox (en el código de Roblox se llama "Premium"). Roblox paga al creador por el
-- tiempo que juegan los suscriptores, así que conviene darles una ventaja pequeña y ofrecerla
-- después de un logro, nunca al entrar (GDD).
Shop.Premium = {
	incomeBonus = 0.1, -- +10 % de monedas para los suscriptores
	offerAfterStep = "zona_2", -- se ofrece una sola vez, al abrir por primera vez la bóveda 2 (Config/Analytics)
}
return Shop
