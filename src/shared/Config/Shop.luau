--!strict
-- Productos de pago. Sustituye los id = 0 por los IDs reales al crearlos en el Creator Hub.

local Shop = {}

Shop.GamePasses = {
	DobleMonedas = { id = 0, price = 99 },
	RedDorada = { id = 0, price = 149 },
	VIP = { id = 0, price = 299 },
}

Shop.DevProducts = {
	PackInicio = { id = 0, price = 49, oneTime = true, showAfterMinutes = 5 },
	Cebo = { id = 0, price = 25 },
	SuerteX2 = { id = 0, price = 49, durationSeconds = 15 * 60 },
}

Shop.PrivateServerPrice = 99

return Shop
