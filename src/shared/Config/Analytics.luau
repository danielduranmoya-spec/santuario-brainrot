--!strict
-- Analítica del embudo (GDD: "Eventos de analítica"). Se ven en el Creator Hub > tu experiencia >
-- Analíticas > Embudos (Onboarding). Cada paso se envía una sola vez por jugador (se guarda en su
-- perfil), así el embudo muestra cuántos jugadores nuevos llegan a cada punto y dónde se van.

local Analytics = {}

-- Pasos del embudo de los primeros minutos, en orden. No cambies el orden una vez publicado:
-- añade los nuevos al final.
Analytics.OnboardingSteps = {
	"entra", -- 1. ha cargado sus datos
	"primera_captura", -- 2. ha ganado el minijuego por primera vez
	"primer_bicho", -- 3. ha dejado su primer bicho en el santuario
	"primer_cobro", -- 4. ha cobrado el cofre
	"primera_mejora", -- 5. ha comprado una mejora
	"zona_2", -- 6. ha abierto la bóveda 2
	"zona_3", -- 7. ha abierto la bóveda 3
}

-- Eventos sueltos (Analíticas > Eventos personalizados).
Analytics.CustomEvents = {
	primeraCompra = "primera_compra",
	legendario = "legendario_atrapado",
	robo = "cebo_robo",
	valla = "valla_comprada",
	codigo = "codigo_canjeado",
}

return Analytics
