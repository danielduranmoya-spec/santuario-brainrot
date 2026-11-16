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

-- Ciclo de día y noche: de noche los bichos duermen y no se puede atrapar nada.
Events.DayNight = {
	daySeconds = 5 * 60,
	nightSeconds = 30,
	transitionSeconds = 4, -- lo que tarda la luz en cambiar
	dayClockTime = 14.5, -- hora que marca el cielo de día (0-24)
	nightClockTime = 22.5, -- de noche (se usa 22,5 y no 0 para que la luz cambie sin dar la vuelta al reloj)
	warningSeconds = 10, -- aviso (sonido y mensaje) antes de que anochezca
	musicFadeSeconds = 3, -- fundido entre la música de día y la de noche
	-- Qué pasa al anochecer si estás en una bóveda:
	--   "boton"   = aparece un botón CASA para volver cuando quieras (recomendado: cansa menos)
	--   "forzado" = te devuelve a tu santuario automáticamente (como antes)
	sendHome = "boton",
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

return Events
