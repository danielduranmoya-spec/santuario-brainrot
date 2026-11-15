--!strict
-- Ajustes del bucle principal: aparición de bichos, minijuego de captura y santuarios.
-- Única fuente de verdad de estos números (ver design/GDD.md, "Bucle de 30 segundos").

local Gameplay = {}

-- Altura del suelo (la parte de arriba del Baseplate está en Y = 0).
Gameplay.GroundY = 0

Gameplay.Spawning = {
	zone = "PlayaRara", -- única zona construida en esta fase
	center = Vector3.new(0, 0, 0),
	minRadius = 18, -- studs desde el centro
	maxRadius = 50,
	intervalSeconds = 3, -- cada cuánto intenta aparecer un bicho
	maxCritters = 12, -- bichos salvajes a la vez
	despawnSeconds = 120, -- un bicho sin atrapar desaparece tras este tiempo
	wanderIntervalSeconds = 3,
	wanderChance = 0.6, -- probabilidad de que un bicho se mueva en cada paso
	wanderDistance = 8,
	wanderSpeed = 5, -- studs/s
	tutorialDistance = 12, -- el primer bicho aparece justo delante del jugador
	tutorialDelaySeconds = 1,
	labelMaxDistance = 90,
}

Gameplay.Catching = {
	range = 10, -- distancia a la que aparece el aviso "Atrapar" (ProximityPrompt)
	rangeTolerance = 4, -- margen extra que acepta el servidor (lag)
	requestCooldownSeconds = 0.4,
	barCycleSeconds = 1.6, -- ida y vuelta del marcador de la barra
	timeoutSeconds = 6, -- si no pulsas en este tiempo, el bicho huye
	latencyToleranceSeconds = 0.15, -- el servidor mira también un poco antes de recibir el toque
	sampleStepSeconds = 0.01,
	fleeDistance = 16,
	fleeSpeedMultiplier = 3,
	carryHeight = 3, -- studs por encima de la cabeza
	releaseDistance = 6,
	depositCheckSeconds = 0.25,
}

Gameplay.Sanctuary = {
	plotCount = 6, -- un santuario por jugador, hasta 6 jugadores
	ringRadius = 75, -- los santuarios forman un anillo alrededor de la playa
	plotSize = 28,
	depositMargin = 2, -- studs fuera de la parcela que aún cuentan para soltar el bicho
	slotColumns = 5,
	slotSpacing = 5,
	slotStartZ = -3,
	collectRadius = 4, -- distancia al cofre para cobrar (el Imán la ampliará)
	collectCheckSeconds = 0.2,
	coinTickSeconds = 1,
	labelMaxDistance = 120,
}

-- Diámetro (studs) de la bola provisional de cada rareza.
Gameplay.CritterSizes = {
	Comun = 2.5,
	PocoComun = 3,
	Raro = 3.5,
	Epico = 4,
	Legendario = 5,
}

return Gameplay
