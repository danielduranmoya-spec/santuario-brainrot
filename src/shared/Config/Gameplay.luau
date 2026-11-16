--!strict
-- Ajustes del bucle principal: zonas del mapa, aparición de bichos, minijuego de captura,
-- santuarios y guardado. Única fuente de verdad de estos números (ver design/GDD.md).

local Gameplay = {}

-- Altura del suelo. El terreno (Terrain) se dibuja en celdas de 4 studs y su superficie queda en Y = 2.
Gameplay.GroundY = 2
Gameplay.BaseWalkSpeed = 16 -- la mejora Botas suma a esto
Gameplay.MaxCatchWindow = 0.9 -- tope de la zona verde con todas las mejoras

-- Mapa: un campo recto y largo. Al principio (Z positiva) está la plaza con los santuarios;
-- desde startZ hacia -Z vienen las bóvedas, una detrás de otra, todas del mismo ancho.
-- Cada bóveda se paga para entrar (precios en Progression.Vaults / Progression.EndlessVaults).
Gameplay.Field = {
	width = 160, -- ancho del campo (plaza y bóvedas), de -80 a 80 en X
	startZ = -30, -- donde termina la plaza y empieza la bóveda 1
	hubLength = 200, -- largo de la plaza de santuarios (de startZ a startZ + hubLength)
	spawn = Vector3.new(0, 0, 60), -- punto de aparición (en la plaza, entre los santuarios)
	vaultLength = 100, -- largo de cada bóveda
	-- Menos bóvedas construidas de antemano = menos piezas (va más fluido en móvil). Antes 6 y 3.
	initialVaults = 4, -- bóvedas construidas al arrancar el servidor
	aheadVaults = 2, -- bóvedas construidas por delante de la más lejana que alguien haya abierto
	crittersPerVault = 6, -- bichos salvajes a la vez en cada bóveda
	edgeMargin = 10, -- los bichos no aparecen pegados a muros ni puertas
}

-- Puertas entre bóvedas (cada cliente la vuelve sólida solo para sí mismo si no la ha pagado).
Gameplay.VaultDoor = {
	height = 26,
	thickness = 2,
	transparency = 0.55,
	promptDistance = 14,
	promptHoldSeconds = 0.5,
}

Gameplay.Spawning = {
	intervalSeconds = 3, -- cada cuánto intenta aparecer un bicho en cada zona
	despawnSeconds = 120, -- un bicho sin atrapar desaparece tras este tiempo
	wanderIntervalSeconds = 3,
	wanderChance = 0.6, -- probabilidad de que un bicho se mueva en cada paso
	wanderDistance = 8,
	wanderSpeed = 5, -- studs/s
	tutorialDistance = 12, -- el primer bicho aparece justo delante del jugador (en la plaza)
	tutorialDelaySeconds = 1,
	labelMaxDistance = 45, -- etiquetas de bichos solo de cerca (menos amontonadas)
}

-- Suerte x2 (producto de pago): mientras dure, aparece cerca del jugador un bicho reservado
-- para él, con todas las rarezas menos la más común de esa bóveda multiplicadas.
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
	plotCount = 6, -- un santuario por jugador, hasta 6 jugadores (3 a cada lado de la plaza)
	sideX = 54, -- distancia del centro de cada santuario a la avenida central
	firstZ = 0, -- Z del primer par de santuarios (el más cercano a las bóvedas)
	spacingZ = 58, -- distancia entre santuarios del mismo lado
	plotSize = 46,
	depositMargin = 2, -- studs fuera de la parcela que aún cuentan para soltar el bicho
	slotColumns = 4,
	slotSpacing = 8.5,
	slotStartZ = -5, -- primera fila de pedestales (el frente de la parcela está en -plotSize/2)
	collectRadius = 5, -- distancia al cofre para cobrar (el Imán la amplía)
	collectCheckSeconds = 0.2,
	coinTickSeconds = 1,
	labelMaxDistance = 120,
	-- Si el santuario está lleno y traes un bicho que genera más que el más flojo, lo sustituye y el
	-- flojo se vende por sellValueSeconds segundos de lo que generaba. Así siempre merece la pena
	-- atrapar bichos mejores, aunque no tengas huecos libres.
	autoReplaceWeakest = true,
	sellValueSeconds = 30,
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

-- Objetivos de los primeros minutos (client/Main, panel "Objetivos" a la derecha). Se dan por
-- hechos con lo que el servidor ya guarda (bichos, bóvedas, mejoras), así que a quien vuelve no se
-- le repiten. Simulado: un jugador nuevo los termina hacia el minuto 4-5 (design/Economia.md).
Gameplay.Tutorial = {
	critterGoal = 3, -- "Ten 3 bichos en tu santuario"
	vaultGoal = 2, -- "Abre la bóveda 2"
	doneHideSeconds = 6, -- el panel desaparece al terminar
}

-- Rankings físicos detrás de los santuarios (server/Services/Leaderboards). Usan OrderedDataStore,
-- así que son globales (todos los servidores). En Studio sin publicar enseñan solo este servidor.
Gameplay.Leaderboards = {
	updateSeconds = 60, -- cada cuánto se guardan las puntuaciones y se redibujan los carteles
	rows = 10,
	storeVersion = 1, -- cambiarlo empieza los rankings de cero
	z = 158, -- detrás de la última fila de santuarios, mirando hacia la plaza
	spacingX = 26,
	size = Vector3.new(18, 24, 1),
	Boards = {
		{ id = "Robux", title = "MÁS ROBUX GASTADOS", subtitle = "Apoyo al juego", stat = "robuxSpent", suffix = " R$", color = Color3.fromRGB(80, 200, 120) },
		{ id = "Monedas", title = "MÁS MONEDAS", subtitle = "Monedas que tiene ahora", stat = "coins", suffix = " 💰", color = Color3.fromRGB(255, 200, 40) },
		{ id = "Capturas", title = "MÁS BICHOS", subtitle = "Bichos capturados en total", stat = "totalCaught", suffix = "", color = Color3.fromRGB(90, 170, 255) },
	} :: { { id: string, title: string, subtitle: string, stat: string, suffix: string, color: Color3 } },
}

Gameplay.Menus = {
	upgradesAfterCritters = 1, -- el botón MEJORAS sale al tener este número de bichos en el santuario
	shopAfterSeconds = 60, -- GDD: nada de tiendas antes del primer minuto
	codesAfterSeconds = 60, -- el botón CÓDIGOS, también tras el primer minuto
	actionCooldownSeconds = 0.3,
	codeCooldownSeconds = 2, -- entre intentos de canjear un código
}

-- Defensa contra trampas (server/Services/Guard). Cada petición del cliente gasta una ficha de su
-- "cubo": se rellena a `rate` fichas por segundo y caben como mucho `burst`. Sin fichas, la petición
-- se ignora. Si alguien acumula muchas peticiones ignoradas seguidas, se le expulsa (es un script).
Gameplay.Security = {
	limits = {
		AttemptCatch = { rate = 2, burst = 4 },
		ReleaseCarried = { rate = 2, burst = 4 },
		BuyUpgrade = { rate = 5, burst = 10 },
		PromptPurchase = { rate = 2, burst = 4 },
		RedeemCode = { rate = 0.5, burst = 3 },
		BuyFence = { rate = 1, burst = 3 },
		Fuse = { rate = 2, burst = 4 },
		Default = { rate = 5, burst = 10 },
	} :: { [string]: { rate: number, burst: number } },
	floodWindowSeconds = 10, -- se cuentan las peticiones ignoradas en esta ventana...
	floodKickAfter = 150, -- ...y con tantas se expulsa al jugador (un humano no llega ni a 20)
	kickOnFlood = true,
	-- Margen para el toque de la barra: el servidor mira hacia atrás lo que tarda en llegar el toque
	-- (la mitad del ping de ida y vuelta del jugador, más un poco), nunca más de
	-- Catching.latencyToleranceSeconds. Así un tramposo no puede elegir el mejor instante.
	pingShare = 0.6,
	pingExtraSeconds = 0.03,
	distanceTolerance = 4, -- studs de margen al comprobar que estás junto a una máquina o un santuario
	-- Teletransporte: si el personaje se mueve en horizontal más rápido que su WalkSpeed x speedSlack
	-- + speedExtraStuds por segundo, durante teleportBlockSeconds no puede empezar capturas.
	speedCheckSeconds = 1, -- ventana larga: un tirón de red no parece un teletransporte
	speedSlack = 1.5,
	speedExtraStuds = 12,
	teleportBlockSeconds = 3,
}

-- Brillo de cada rareza: alcance de la luz (0 = sin luz) y chispas por segundo (0 = sin chispas).
Gameplay.RarityGlow = {
	Comun = { light = 0, brightness = 0, sparkles = 0 },
	PocoComun = { light = 0, brightness = 0, sparkles = 0 },
	Raro = { light = 8, brightness = 3, sparkles = 1 },
	Epico = { light = 10, brightness = 3, sparkles = 4 },
	Legendario = { light = 14, brightness = 2, sparkles = 8 },
	Mitico = { light = 16, brightness = 2.5, sparkles = 12 },
	Secreto = { light = 18, brightness = 3, sparkles = 16 },
}

-- Los bichos se elevan un poco para quedar por encima del suelo de color de cada zona.
Gameplay.CritterLift = 0.3

-- Efecto al atrapar según rareza (más cuanto más raro): chispas, confeti de colores, onda de
-- choque en el suelo; flash = destello de luz; column = columna de luz hacia el cielo.
-- Cantidades moderadas para que vaya bien en móvil.
Gameplay.CatchBurst = {
	Comun = { particles = 12, confetti = 20, flash = false, column = false },
	PocoComun = { particles = 18, confetti = 28, flash = false, column = false },
	Raro = { particles = 28, confetti = 40, flash = true, column = true },
	Epico = { particles = 40, confetti = 55, flash = true, column = true },
	Legendario = { particles = 60, confetti = 80, flash = true, column = true },
	Mitico = { particles = 70, confetti = 90, flash = true, column = true },
	Secreto = { particles = 80, confetti = 100, flash = true, column = true },
}

-- Tamaño (studs) de cada rareza: cuanto más raro, más grande.
Gameplay.CritterSizes = {
	Comun = 3,
	PocoComun = 3.8,
	Raro = 4.8,
	Epico = 6,
	Legendario = 7.5,
	Mitico = 8, -- no más de slotSpacing (8,5): si no, se pisan en los pedestales
	Secreto = 8.5,
}

-- Movimiento de cada rareza: multiplica la velocidad y la distancia de paseo (Spawning).
-- Cuanto más raro, más rápido y más lejos corretea. Al empezar la barra el bicho se para,
-- así que la captura sigue siendo justa.
Gameplay.RarityMotion = {
	Comun = { speed = 1, distance = 1 },
	PocoComun = { speed = 1.3, distance = 1.2 },
	Raro = { speed = 1.7, distance = 1.4 },
	Epico = { speed = 2.2, distance = 1.7 },
	Legendario = { speed = 2.8, distance = 2 },
	Mitico = { speed = 3.4, distance = 2.3 },
	Secreto = { speed = 4, distance = 2.6 },
}

return Gameplay
