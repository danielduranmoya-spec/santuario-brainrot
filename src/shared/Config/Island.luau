--!strict
-- Isla Santuario: dónde está cada cosa del mapa (ver design/Mapa.md). Única fuente de verdad del
-- trazado. Los cálculos que usan estos números están en Shared/VaultMath (zonas) y Shared/Layout
-- (plaza, santuarios, máquinas, rankings).
--
-- Ángulos en grados sobre el plano XZ: posición = (cos(a) * radio, sin(a) * radio). La avenida
-- principal sale de la plaza hacia +Z (90°) y lleva a la zona 1; las zonas siguen en sentido
-- antihorario alrededor de la isla.

local Island = {}

-- Plaza central: árbol gigante, estanque en anillo y farolas.
Island.Hub = {
	plazaRadius = 50, -- empedrado
	pondInner = 14, -- estanque alrededor del árbol (de pondInner a pondOuter)
	pondOuter = 20,
	lawnRadius = 138, -- césped llano alrededor (santuarios, puestos y máquinas)
	wallRadius = 146, -- seto que rodea la plaza: solo se sale por la avenida (a la zona 1)
	avenueAngle = 90, -- dirección de la avenida que lleva a la zona 1
	avenueWidth = 14,
	lampCount = 12,
}

-- Santuarios en círculo alrededor de la plaza, mirando al árbol. Ángulos que dejan libre la avenida.
-- Cada 60°, empezando a 30° de la avenida, que pasa entre los santuarios 1 y 6.
Island.Plots = {
	radius = 94,
	angles = { 120, 60, 180, 0, 240, 300 } :: { number }, -- en orden de llegada de jugadores
}

-- Máquinas de fusión: a los lados de la avenida, al salir de la plaza.
Island.Machines = { radius = 128, spread = 11 } -- grados a cada lado de la avenida

-- Rankings: al otro lado de la plaza, frente a la avenida.
Island.Leaderboards = { radius = 128, angle = 270, spacing = 24 }

-- Puestos de eventos (Config/Events los ordena): ángulo y radio de cada uno.
Island.Stands = {
	{ angle = 70, radius = 66 },
	{ angle = 110, radius = 66 },
	{ angle = 270, radius = 66 },
}

-- Punto de aparición: en la plaza, entre la avenida y el árbol.
Island.spawnAngle = 90
Island.spawnRadius = 36

-- Costa: la isla es un círculo con la orilla ondulada. Más allá, mar.
Island.Coast = {
	radius = 345, -- radio medio de la orilla
	wobble = 20, -- cuánto entra y sale la orilla
	beachWidth = 22,
	seaSize = 2000,
	seaDepth = 14,
}

-- Zonas (bóvedas) 1-7 en un anillo alrededor de la plaza. La 4 (Nube Pegajosa) flota sobre su hueco.
-- Las 8 en adelante son islas flotantes en espiral sobre el mar, cada vez más altas.
Island.Zones = {
	ringRadius = 228, -- centro de las zonas del anillo
	ringStep = 360 / 7, -- grados entre zonas del anillo
	width = 110, -- ancho (hacia fuera de la isla)
	length = 140, -- largo (en el sentido del camino)
	floatingLift = { [4] = 74 } :: { [number]: number }, -- zonas del anillo que flotan (altura extra)
	-- Espiral de islas flotantes (zona 8 en adelante).
	spiralRadius = 440,
	spiralStep = 34, -- grados entre islas
	spiralStartAngle = 90 + 6.5 * 360 / 7, -- tras la zona 7
	spiralBaseLift = 64, -- altura de la zona 8 sobre el suelo
	spiralLiftPerZone = 16,
	spiralWidth = 100,
	spiralLength = 110,
	-- Puente de la costa de la zona 7 a la primera isla flotante (zona 8).
	bridgeAngle = 90 + 6.2 * 360 / 7,
	bridgeRadius = 300,
	gateWidth = 26, -- hueco del arco de entrada
	gateHeight = 24,
}

-- Accidentes del paisaje (decorado: no cambian la lógica).
Island.Landmarks = {
	volcano = { angle = 90 + 2 * 360 / 7, radius = 400, height = 120, baseRadius = 95, craterRadius = 16 },
	waterfall = { zone = 4 }, -- la cascada cae desde la isla de la zona 4 al lago de debajo
	lighthouse = { angle = 90 - 360 / 7 * 0.5 },
	dock = { angle = 90 + 360 / 7 * 0.25 },
}

return Island
