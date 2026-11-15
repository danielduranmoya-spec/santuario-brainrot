--!strict
-- Eventos del servidor. Horas en UTC (Madrid = UTC+1 en invierno, UTC+2 en verano).

local Events = {}

Events.ServerLegendary = {
	intervalSeconds = 8 * 60,
	warningSeconds = 15,
}

Events.LluviaDeBichos = {
	weekday = 7, -- sábado (os.date: 1 = domingo)
	hourUTC = 17, -- 18:00 en Madrid en invierno
	durationMinutes = 30,
	spawnMultiplier = 3,
}

Events.Bait = {
	durationSeconds = 20,
	cooldownPerVictimSeconds = 10 * 60,
	fenceDurationSeconds = 10 * 60,
	fenceCost = 1_000,
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
