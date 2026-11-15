--!strict
-- Ajustes del bucle principal: zonas del mapa, aparición de bichos, minijuego de captura,
-- santuarios y guardado. Única fuente de verdad de estos números (ver design/GDD.md).

local Gameplay = {}

-- Altura del suelo (la parte de arriba del Baseplate está en Y = 0).
Gameplay.GroundY = 0
Gameplay.BaseWalkSpeed = 16 -- la mejora Botas suma a esto
Gameplay.MaxCatchWindow = 0.9 -- tope de la zona verde con todas las mejoras

-- Zonas del mapa (sus costes están en Progression.Zones). La Playa Rara es el centro.
Gameplay.Zones = {
	PlayaRara = {
		center = Vector3.new(0, 0, 0),
		minRadius = 18, -- deja libre el punto de aparición del jugador
		radius = 50,
		maxCritters = 12,
		color = Color3.fromRGB(235, 215, 150),
	},
	BosqueRuidoso = {
		center = Vector3.new(0, 0, -200),
		minRadius = 6,
		radius = 45,
		maxCritters = 10,
		color = Color3.fromRGB(60, 130, 60),
	},
	VolcanTimido = {
		-- A 200 studs en diagonal, en el hueco entre dos santuarios (así el camino no los cruza).
		center = Vector3.new(173, 0, -100),
		minRadius = 6,
		radius = 45,
		maxCritters = 8,
		color = Color3.fromRGB(150, 60, 40),
	},
	NubePegajosa = {
		center = Vector3.new(0, 0, 200),
		minRadius = 6,
		radius = 45,
		maxCritters = 6,
		color = Color3.fromRGB(215, 220, 255),
	},
}

-- Barrera de las zonas bloqueadas (cada cliente la vuelve sólida solo para sí mismo).
Gameplay.ZoneBarrier = {
	height = 24,
	transparency = 0.6,
	gateDistance = 4, -- studs por fuera de la barrera donde está la puerta
	promptDistance = 12,
	promptHoldSeconds = 0.5,
}

Gameplay.Spawning = {
	intervalSeconds = 3, -- cada cuánto intenta aparecer un bicho en cada zona
	despawnSeconds = 120, -- un bicho sin atrapar desaparece tras este tiempo
	wanderIntervalSeconds = 3,
	wanderChance = 0.6, -- probabilidad de que un bicho se mueva en cada paso
	wanderDistance = 8,
	wanderSpeed = 5, -- studs/s
	tutorialZone = "PlayaRara",
	tutorialDistance = 12, -- el primer bicho aparece justo delante del jugador
	tutorialDelaySeconds = 1,
	labelMaxDistance = 45, -- etiquetas de bichos solo de cerca (menos amontonadas)
}

-- Suerte x2 (producto de pago): mientras dure, aparece cerca del jugador un bicho reservado
-- para él, con las rarezas no comunes multiplicadas.
Gameplay.Luck = {
	personalSpawnSeconds = 20,
	rarityMultiplier = 2,
	spawnDistance = 10,
}

Gameplay.Catching = {
	range = 10, -- distancia a la que aparece el aviso "Atrapar" (ProximityPrompt)
	rangeTolerance = 4, -- margen extra que acepta el servidor (lag)
	requestCooldownSeconds = 0.4,
	barCycleSeconds = 1.6, -- ida y vuelta del marcador de la barra
	timeoutSeconds = 6, -- si no pulsas en este tiempo, el bicho huye
	latencyToleranceSeconds = 0.15, -- el servidor mira también un poco antes de recibir el toque
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
	collectRadius = 4, -- distancia al cofre para cobrar (el Imán la amplía)
	collectCheckSeconds = 0.2,
	coinTickSeconds = 1,
	labelMaxDistance = 120,
}

Gameplay.Data = {
	storeName = "Jugadores_v1", -- cambiarlo borra el progreso de todos (empieza otro almacén)
	maxRetries = 5,
	retryDelaySeconds = 2, -- se multiplica por el número de intento
	lockTimeoutSeconds = 300, -- si otro servidor no renueva su reserva en este tiempo, se ignora
	lockWaitSeconds = 5,
	lockRetries = 3,
	receiptHistory = 50, -- compras recordadas para no darlas dos veces
	studioWarningDelaySeconds = 4,
	closeTimeoutSeconds = 25, -- Roblox da unos 30 s para guardar al cerrar el servidor
}

Gameplay.Menus = {
	upgradesAfterCritters = 1, -- el botón MEJORAS sale al tener este número de bichos en el santuario
	shopAfterSeconds = 60, -- GDD: nada de tiendas antes del primer minuto
	actionCooldownSeconds = 0.3,
}

-- Brillo de cada rareza: alcance de la luz (0 = sin luz) y chispas por segundo (0 = sin chispas).
Gameplay.RarityGlow = {
	Comun = { light = 0, brightness = 0, sparkles = 0 },
	PocoComun = { light = 0, brightness = 0, sparkles = 0 },
	Raro = { light = 8, brightness = 3, sparkles = 1 },
	Epico = { light = 10, brightness = 3, sparkles = 4 },
	Legendario = { light = 14, brightness = 4, sparkles = 10 },
}

-- Los bichos se elevan un poco para quedar por encima del suelo de color de cada zona.
Gameplay.CritterLift = 0.3

-- Partículas al atrapar según rareza (más cuanto más raro). flash = destello de luz.
Gameplay.CatchBurst = {
	Comun = { particles = 12, flash = false },
	PocoComun = { particles = 18, flash = false },
	Raro = { particles = 28, flash = true },
	Epico = { particles = 40, flash = true },
	Legendario = { particles = 60, flash = true },
}

-- Tamaño (studs) de cada rareza.
Gameplay.CritterSizes = {
	Comun = 2.5,
	PocoComun = 3,
	Raro = 3.5,
	Epico = 4,
	Legendario = 5,
}

return Gameplay
