--!strict
-- Eventos del servidor. Horas en UTC (Madrid = UTC+1 en invierno, UTC+2 en verano).

local Events = {}

-- Bicho legendario de servidor: cada 8 minutos aparece uno para todos en la bóveda 1 (la que
-- todos tienen abierta), con aviso de 15 s. El primero en atraparlo se lo queda y sale en el chat.
Events.ServerLegendary = {
	intervalSeconds = 8 * 60,
	warningSeconds = 15,
	critterId = "lobo_tormenta",
	lifetimeSeconds = 90, -- si nadie lo atrapa en este tiempo, se va volando
	firstDelaySeconds = 4 * 60, -- el primero del servidor sale antes, para que los nuevos lo vean pronto
}

-- Lluvia de Bichos: sábados 18:00 (Madrid en invierno), 30 min. Aparecen bichos x3 y, de vez en
-- cuando, el bicho exclusivo de la semana (en Config/Critters, con eventOnly = true).
-- En verano (UTC+2) cambia hourUTC a 16 para que siga siendo a las 18:00 en Madrid.
Events.LluviaDeBichos = {
	weekday = 7, -- sábado (os.date: 1 = domingo)
	hourUTC = 17, -- 18:00 en Madrid en invierno
	durationMinutes = 30,
	spawnMultiplier = 3,
	exclusiveCritterId = "ajolote_chubasquero",
	exclusiveChance = 0.12, -- probabilidad de que cada bicho que aparece sea el exclusivo
}

-- Robo amable: pones un cebo en la entrada del santuario de otro jugador. Si en durationSeconds el
-- dueño no lo espanta (tocándolo) ni compra una valla, uno de sus bichos (nunca legendario) se va
-- contigo. Nadie pierde más de un bicho cada cooldownPerVictimSeconds.
Events.Bait = {
	durationSeconds = 20,
	cooldownPerVictimSeconds = 10 * 60,
	fenceDurationSeconds = 10 * 60,
	fenceCost = 1_000,
	minVictimCritters = 3, -- no se puede poner cebo a quien tiene menos bichos (protege a los nuevos)
	promptHoldSeconds = 1,
	promptDistance = 10,
	neverSteal = { Legendario = true, Mitico = true, Secreto = true }, -- rarezas que nunca se escapan
}

Events.DailyRewardStreakDays = 7

-- Premio de cada día de la racha (uno por día, tantos como DailyRewardStreakDays).
-- Si un día pasa sin entrar, la racha vuelve al día 1. Tras el día 7 vuelve a empezar.
Events.DailyRewards = {
	{ coins = 100 },
	{ coins = 250 },
	{ coins = 500 },
	{ coins = 900 },
	{ coins = 1_500 },
	{ coins = 2_500 },
	{ coins = 0, critterRarity = "Raro" }, -- GDD: el día 7 da un bicho raro
}

-- Stands de eventos en la plaza (server/Services/EventStands): un puesto con su encargado, cartel
-- "EVENTO" con cuenta atrás y aviso "Hablar" que explica el evento. Están a los lados de la avenida,
-- entre las entradas de los santuarios, mirando hacia ella. `kind` dice qué cuenta atrás enseñan.
Events.Stands = {
	{
		id = "Tormenta",
		kind = "legendario",
		title = "LOBO DE TORMENTA",
		keeper = "Tormentina",
		position = Vector2.new(-21, 29),
		color = Color3.fromRGB(70, 110, 220),
		accent = Color3.fromRGB(255, 205, 60),
		talk = "⛈ Soy Tormentina. Cada 8 minutos el Lobo de Tormenta baja a la Playa Rara. ¡El primero que lo atrape se lo queda! Mira mi cartel para saber cuándo.",
	},
	{
		id = "Lluvia",
		kind = "lluvia",
		title = "LLUVIA DE BICHOS",
		keeper = "Don Chubasco",
		position = Vector2.new(21, 29),
		color = Color3.fromRGB(60, 170, 200),
		accent = Color3.fromRGB(190, 240, 255),
		talk = "🌧 Soy Don Chubasco. Los sábados a las 18:00 llueven bichos: salen el triple durante 30 minutos y a veces el Ajolote Chubasquero, que solo aparece ese día.",
	},
	{
		id = "Mutaciones",
		kind = "mutacion",
		title = "MUTACIONES",
		keeper = "Alquimista Mutia",
		position = Vector2.new(-21, 87),
		color = Color3.fromRGB(150, 70, 220),
		accent = Color3.fromRGB(120, 255, 200),
		talk = "⚗ Soy Mutia. Cada 20 minutos llega un evento de mutación y salen más bichos de Oro, Diamante, Neón... ¡Y en la TIENDA puedes invocar uno para todo el servidor!",
	},
} :: { { id: string, kind: string, title: string, keeper: string, position: Vector2, color: Color3, accent: Color3, talk: string } }
Events.standPromptDistance = 10

return Events
