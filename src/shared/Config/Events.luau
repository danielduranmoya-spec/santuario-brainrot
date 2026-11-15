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

return Events
