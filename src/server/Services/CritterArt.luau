--!strict
-- Modelos de cada bicho (versión 3: catálogo de 21 bichos), hechos por código con piezas simples
-- (bolas, bloques, cilindros, elipsoides y cuñas). Viven en el repo y Rojo los sincroniza.
--
-- Cada pieza se describe en unidades del tamaño del bicho (1 = diámetro de su rareza en
-- Config/Gameplay.CritterSizes). El frente del bicho es -Z, el suelo queda en Y = -0,5 y el centro
-- en (0, 0, 0). Las piezas con nombre se animan en el cliente (client/CritterAnimator):
--   "Parpado" (aparece un instante al parpadear), "Ala" (aletea), "Cola" (se balancea),
--   "Pinza" (se abre y cierra), "Gota" (cae y se desvanece), "Giro" (gira sobre su eje X),
--   "Brillo" (late la luz), "Arcoiris" (cambia de color), "Cabeza" (da una vuelta entera),
--   "Pendulo" (oscila de lado a lado).
-- Con `hinged` la pieza gira alrededor de un punto (el hombro de un ala, la bisagra de una boca),
-- así varias piezas se mueven como un solo bloque. Con `fine` se marca un adorno pequeño, que se
-- puede quitar para aligerar el juego (Config/Art.critterDetail).
-- Para añadir un bicho nuevo: crea su entrada aquí con el mismo id que en Config/Critters.
-- Para ver los modelos sin abrir Studio: design/herramientas/vista_previa_bichos.py.

export type Shape = "Ball" | "Block" | "Cylinder" | "Ellipsoid" | "Wedge"

export type PartSpec = {
	shape: Shape,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	rot: Vector3?, -- grados (X, Y, Z)
	rot2: Vector3?, -- segundo giro, aplicado después de `rot` (para dientes de engranaje en diagonal)
	material: Enum.Material?,
	name: string?,
	transparency: number?,
	reflectance: number?,
	pivot: Vector3?, -- punto de giro de una pieza animada
	fine: boolean?, -- adorno pequeño (se omite con Art.critterDetail = 1)
	keep: boolean?, -- no cambia con las mutaciones de color (ojos): así el bicho se sigue reconociendo
}

type Parts = { PartSpec }

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(25, 25, 30)
local BLUSH = Color3.fromRGB(255, 140, 160)
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass
local METAL = Enum.Material.Metal
local SLATE = Enum.Material.Slate
local GRASS = Enum.Material.Grass

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

local function p(shape: Shape, size: Vector3, pos: Vector3, color: Color3, rot: Vector3?, material: Enum.Material?): PartSpec
	return { shape = shape, size = size, pos = pos, color = color, rot = rot, material = material }
end

local function ball(size: number, pos: Vector3, color: Color3, material: Enum.Material?): PartSpec
	return p("Ball", Vector3.one * size, pos, color, nil, material)
end

local function add(list: Parts, spec: PartSpec): PartSpec
	table.insert(list, spec)
	return spec
end

local function named(spec: PartSpec, name: string, transparency: number?): PartSpec
	spec.name = name
	if transparency then
		spec.transparency = transparency
	end
	return spec
end

-- Pieza animada que gira alrededor de `pivot`.
local function hinged(spec: PartSpec, name: string, pivot: Vector3): PartSpec
	spec.name = name
	spec.pivot = pivot
	return spec
end

local function fine(spec: PartSpec): PartSpec
	spec.fine = true
	return spec
end

local function clear(spec: PartSpec, transparency: number): PartSpec
	spec.transparency = transparency
	return spec
end

local function shiny(spec: PartSpec, reflectance: number): PartSpec
	spec.reflectance = reflectance
	return spec
end

local function turned(spec: PartSpec, rot2: Vector3): PartSpec
	spec.rot2 = rot2
	return spec
end

-- Pieza alargada que va del punto `a` al punto `b` (su eje X queda en esa dirección).
-- `stretch` la alarga un poco para que los elipsoides encadenados se solapen.
local function seg(shape: Shape, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material?, stretch: number?): PartSpec
	local d = b - a
	local length = d.Magnitude
	local yaw = math.deg(math.atan2(-d.Z, d.X))
	local pitch = math.deg(math.asin(math.clamp(d.Y / length, -1, 1)))
	return p(shape, v(length * (stretch or 1), thickness, thickness), (a + b) / 2, color, v(0, yaw, pitch), material)
end

-- Tubo que pasa por una lista de puntos (cilindros con bolas en las uniones); el radio va de r0 a r1.
local function tube(list: Parts, points: { Vector3 }, r0: number, r1: number, color: Color3, material: Enum.Material?, name: string?, isFine: boolean?)
	local count = #points
	for i = 1, count do
		local radius = r0 + (r1 - r0) * (i - 1) / (count - 1)
		local joint = add(list, ball(radius * 2, points[i], color, material))
		joint.name = name
		joint.fine = isFine
		if i < count then
			local nextRadius = r0 + (r1 - r0) * i / (count - 1)
			local piece = add(list, seg("Cylinder", points[i], points[i + 1], radius + nextRadius, color, material))
			piece.name = name
			piece.fine = isFine
		end
	end
end

-- Un ojo: blanco, pupila, brillo y un párpado del color de la piel (invisible hasta que parpadea).
local function eye(list: Parts, center: Vector3, size: number, lidColor: Color3, side: number)
	add(list, ball(size, center, WHITE)).keep = true
	add(list, ball(size * 0.55, center + v(0, -size * 0.05, -size * 0.3), BLACK)).keep = true
	add(list, fine(ball(size * 0.18, center + v(side * size * 0.12, size * 0.12, -size * 0.48), WHITE))).keep = true
	add(list, named(ball(size * 1.08, center, lidColor), "Parpado", 1))
end

local function eyes(list: Parts, spread: number, y: number, z: number, size: number, lidColor: Color3)
	for _, side in { -1, 1 } do
		eye(list, v(side * spread, y, z), size, lidColor, side)
	end
end

-- Ojos rasgados de luz (para los bichos oscuros); el párpado los apaga al parpadear.
local function glowEyes(list: Parts, spread: number, y: number, z: number, size: number, color: Color3)
	for _, side in { -1, 1 } do
		add(list, p("Ellipsoid", v(size * 1.5, size * 0.8, size * 0.6), v(side * spread, y, z), color, v(0, 0, side * 18), NEON)).keep = true
		add(list, named(p("Ellipsoid", v(size * 1.6, size * 0.9, size * 0.7), v(side * spread, y, z), BLACK, v(0, 0, side * 18)), "Parpado", 1))
	end
end

-- Mofletes rosados.
local function cheeks(list: Parts, spread: number, y: number, z: number, size: number)
	for _, side in { -1, 1 } do
		add(list, p("Ellipsoid", v(size, size * 0.6, size * 0.3), v(side * spread, y, z), BLUSH))
	end
end

local CritterArt: { [string]: Parts } = {}

-- ============================== COMÚN ==============================

do -- Caracol Turbo: caracol marino con un motor fueraborda en la concha y estela de espuma.
	local skin = rgb(255, 214, 150)
	local skinDark = rgb(238, 178, 118)
	local shell = rgb(38, 190, 205)
	local shellDark = rgb(20, 135, 165)
	local red = rgb(235, 60, 55)
	local steel = rgb(150, 158, 170)
	local yellow = rgb(255, 215, 70)
	local list: Parts = {
		-- Cuerpo: pie largo con falda, cuello y cabeza.
		p("Ellipsoid", v(0.44, 0.2, 1.0), v(0, -0.38, 0.0), skin),
		p("Ellipsoid", v(0.5, 0.08, 1.06), v(0, -0.46, 0.0), skinDark),
		p("Ellipsoid", v(0.3, 0.44, 0.3), v(0, -0.2, -0.36), skin, v(-20, 0, 0)),
		ball(0.34, v(0, -0.04, -0.43), skin),
		p("Ellipsoid", v(0.16, 0.04, 0.05), v(0, -0.11, -0.585), rgb(190, 90, 80)),
		p("Ellipsoid", v(0.2, 0.1, 0.3), v(0, -0.42, 0.5), skin),
		-- Concha en espiral, con franja de carreras.
		p("Cylinder", v(0.36, 0.66, 0.66), v(0, 0.02, 0.1), shell),
		p("Cylinder", v(0.42, 0.48, 0.48), v(0, 0.03, 0.11), shellDark),
		p("Cylinder", v(0.47, 0.32, 0.32), v(0, 0.05, 0.13), shell),
		p("Cylinder", v(0.51, 0.17, 0.17), v(0, 0.06, 0.14), yellow),
		p("Cylinder", v(0.1, 0.69, 0.69), v(0, 0.02, 0.1), red),
		fine(p("Cylinder", v(0.03, 0.705, 0.705), v(0, 0.02, 0.1), WHITE)),
		-- Motor fueraborda: soporte, carcasa, tapa, eje y hélice.
		p("Block", v(0.1, 0.1, 0.16), v(0, -0.02, 0.46), steel, nil, METAL),
		p("Block", v(0.2, 0.22, 0.18), v(0, 0.06, 0.58), red),
		p("Ellipsoid", v(0.24, 0.1, 0.22), v(0, 0.18, 0.58), rgb(60, 60, 70)),
		fine(p("Block", v(0.21, 0.04, 0.19), v(0, 0.06, 0.58), WHITE)),
		fine(ball(0.05, v(0.12, 0.12, 0.58), yellow)),
		p("Cylinder", v(0.3, 0.06, 0.06), v(0, -0.18, 0.6), steel, v(0, 0, 90), METAL),
		p("Ellipsoid", v(0.1, 0.1, 0.18), v(0, -0.36, 0.62), steel, nil, METAL),
		named(p("Block", v(0.03, 0.26, 0.07), v(0, -0.36, 0.72), yellow, v(0, 90, 0)), "Giro"),
		named(p("Block", v(0.03, 0.07, 0.26), v(0, -0.36, 0.72), yellow, v(0, 90, 0)), "Giro"),
		-- Estela de espuma.
		fine(clear(p("Ellipsoid", v(0.2, 0.04, 0.16), v(0.1, -0.48, 0.84), WHITE), 0.25)),
		fine(clear(p("Ellipsoid", v(0.16, 0.04, 0.14), v(-0.1, -0.48, 0.92), WHITE), 0.4)),
		fine(clear(p("Ellipsoid", v(0.12, 0.03, 0.1), v(0.02, -0.48, 1.02), WHITE), 0.55)),
	}
	for _, side in { -1, 1 } do
		-- Antenas con los ojos arriba y tentáculos pequeños abajo.
		add(list, p("Cylinder", v(0.26, 0.055, 0.055), v(side * 0.1, 0.17, -0.45), skin, v(0, 0, 90)))
		add(list, fine(seg("Cylinder", v(side * 0.07, -0.12, -0.56), v(side * 0.1, -0.2, -0.66), 0.035, skinDark)))
	end
	eyes(list, 0.105, 0.32, -0.46, 0.17, skin)
	cheeks(list, 0.13, -0.07, -0.555, 0.08)
	CritterArt.caracol_turbo = list
end

do -- Estrella Ninja: estrella de mar con cinta roja en la frente y una katana de madera a la espalda.
	local coral = rgb(255, 125, 70)
	local light = rgb(255, 195, 125)
	local band = rgb(200, 30, 45)
	local wood = rgb(150, 100, 60)
	local list: Parts = {
		p("Ellipsoid", v(0.5, 0.5, 0.26), v(0, 0, 0), coral),
		p("Ellipsoid", v(0.34, 0.34, 0.1), v(0, -0.03, -0.1), light),
		-- Cinta ninja con nudo y dos tiras al viento.
		p("Block", v(0.47, 0.09, 0.29), v(0, 0.13, 0), band),
		ball(0.1, v(0.25, 0.13, 0.06), band),
		hinged(p("Block", v(0.24, 0.07, 0.02), v(0.37, 0.12, 0.1), band, v(0, -20, -18)), "Cola", v(0.25, 0.13, 0.06)),
		hinged(p("Block", v(0.2, 0.06, 0.02), v(0.35, 0.04, 0.12), band, v(0, -30, -40)), "Cola", v(0.25, 0.13, 0.06)),
		p("Block", v(0.08, 0.02, 0.02), v(0, -0.13, -0.14), BLACK),
		-- Katana de madera.
		p("Block", v(0.045, 0.56, 0.03), v(-0.04, 0.1, 0.16), wood, v(0, 0, 38)),
		fine(p("Block", v(0.12, 0.03, 0.05), v(-0.2, 0.3, 0.16), rgb(255, 205, 80), v(0, 0, 38))),
	}
	for i = 0, 4 do
		local degrees = 90 + i * 72
		local angle = math.rad(degrees)
		local dir = v(math.cos(angle), math.sin(angle), 0)
		add(list, p("Ellipsoid", v(0.44, 0.27, 0.22), dir * 0.27, coral, v(0, 0, degrees)))
		add(list, p("Ellipsoid", v(0.22, 0.16, 0.17), dir * 0.43, coral, v(0, 0, degrees)))
		add(list, fine(ball(0.06, dir * 0.3 + v(0, 0, -0.1), light)))
		add(list, fine(ball(0.045, dir * 0.43 + v(0, 0, -0.075), light)))
	end
	eyes(list, 0.1, -0.01, -0.13, 0.15, coral)
	cheeks(list, 0.18, -0.09, -0.115, 0.08)
	CritterArt.estrella_ninja = list
end

do -- Pulpo Cubo: pulpito morado con un cubo de playa de casco, que corre de lado con sus tentáculos.
	local purple = rgb(150, 95, 225)
	local dark = rgb(115, 65, 190)
	local sucker = rgb(235, 195, 255)
	local bucket = rgb(240, 70, 60)
	local yellow = rgb(255, 210, 60)
	local list: Parts = {
		p("Ellipsoid", v(0.68, 0.6, 0.64), v(0, -0.02, 0), purple),
		-- Cubo de playa boca abajo: borde, tres tramos cada vez más estrechos y una estrella.
		p("Cylinder", v(0.04, 0.76, 0.76), v(0, 0.16, 0), yellow, v(0, 0, 90)),
		p("Cylinder", v(0.14, 0.68, 0.68), v(0, 0.24, 0), bucket, v(0, 0, 90)),
		p("Cylinder", v(0.13, 0.62, 0.62), v(0, 0.37, 0), bucket, v(0, 0, 90)),
		p("Cylinder", v(0.1, 0.56, 0.56), v(0, 0.48, 0), bucket, v(0, 0, 90)),
		fine(p("Cylinder", v(0.03, 0.635, 0.635), v(0, 0.31, 0), WHITE, v(0, 0, 90))),
		p("Ellipsoid", v(0.16, 0.16, 0.05), v(0, 0.35, -0.305), yellow),
		p("Ball", Vector3.one * 0.07, v(0, -0.14, -0.3), rgb(90, 40, 120)),
		fine(ball(0.08, v(0.2, 0.06, 0.24), dark)),
		fine(ball(0.06, v(-0.24, 0.02, 0.2), dark)),
		fine(ball(0.07, v(-0.05, 0.0, 0.31), dark)),
	}
	-- Asa del cubo, echada hacia atrás.
	tube(list, { v(-0.36, 0.2, 0.02), v(-0.3, 0.04, 0.26), v(0, -0.04, 0.39), v(0.3, 0.04, 0.26), v(0.36, 0.2, 0.02) }, 0.016, 0.016, WHITE, nil, nil, true)
	-- Seis tentáculos con la punta rizada y ventosas.
	for i = 0, 5 do
		local angle = math.rad(30 + i * 60)
		local dir = v(math.cos(angle), 0, math.sin(angle))
		add(list, seg("Ellipsoid", dir * 0.18 + v(0, -0.2, 0), dir * 0.42 + v(0, -0.42, 0), 0.17, purple, nil, 1.2))
		add(list, seg("Ellipsoid", dir * 0.38 + v(0, -0.44, 0), dir * 0.6 + v(0, -0.43, 0), 0.12, purple, nil, 1.2))
		add(list, ball(0.1, dir * 0.63 + v(0, -0.38, 0), dark))
		add(list, fine(ball(0.05, dir * 0.5 + v(0, -0.48, 0), sucker)))
	end
	eyes(list, 0.16, 0.0, -0.275, 0.2, purple)
	cheeks(list, 0.25, -0.1, -0.24, 0.1)
	CritterArt.pulpo_cubo = list
end

-- ============================== POCO COMÚN ==============================

do -- Gaviota Pirata: gaviota con parche en el ojo, gorro de papel y un pendiente de oro.
	local white = rgb(248, 248, 250)
	local grey = rgb(150, 160, 175)
	local dark = rgb(45, 48, 60)
	local beak = rgb(255, 170, 40)
	local paper = rgb(240, 232, 208)
	local list: Parts = {
		p("Ellipsoid", v(0.5, 0.44, 0.74), v(0, -0.1, 0.04), white, v(12, 0, 0)),
		p("Ellipsoid", v(0.42, 0.3, 0.56), v(0, -0.02, 0.12), grey, v(12, 0, 0)),
		p("Ellipsoid", v(0.26, 0.32, 0.26), v(0, 0.04, -0.2), white, v(-25, 0, 0)),
		ball(0.38, v(0, 0.2, -0.26), white),
		-- Pico con la punta roja.
		p("Ellipsoid", v(0.13, 0.11, 0.3), v(0, 0.16, -0.5), beak),
		p("Ellipsoid", v(0.09, 0.07, 0.1), v(0, 0.135, -0.62), rgb(230, 60, 50)),
		-- Gorro de papel: ala y dos cuñas que forman el pico del gorro.
		p("Block", v(0.5, 0.05, 0.2), v(0, 0.385, -0.24), paper),
		p("Wedge", v(0.16, 0.26, 0.24), v(-0.12, 0.535, -0.24), paper, v(0, 90, 0)),
		p("Wedge", v(0.16, 0.26, 0.24), v(0.12, 0.535, -0.24), paper, v(0, -90, 0)),
		fine(p("Block", v(0.015, 0.25, 0.17), v(0, 0.53, -0.24), rgb(205, 195, 170))),
		fine(p("Block", v(0.3, 0.015, 0.21), v(0, 0.45, -0.24), rgb(205, 195, 170))),
		-- Parche con su cinta y pendiente.
		p("Ellipsoid", v(0.16, 0.16, 0.06), v(-0.11, 0.245, -0.415), BLACK),
		p("Cylinder", v(0.025, 0.4, 0.4), v(0, 0.2, -0.26), BLACK, v(0, 0, 55)),
		fine(ball(0.05, v(0.2, 0.12, -0.24), rgb(255, 205, 70), METAL)),
		p("Block", v(0.1, 0.025, 0.03), v(0.11, 0.335, -0.4), dark, v(0, 0, 12)),
	}
	eye(list, v(0.11, 0.24, -0.41), 0.14, white, 1)
	for _, side in { -1, 1 } do
		-- Alas grises con la punta negra.
		local shoulder = v(side * 0.22, 0.02, 0.06)
		add(list, hinged(p("Ellipsoid", v(0.64, 0.07, 0.38), v(side * 0.52, 0.02, 0.06), grey, v(0, 0, side * 8)), "Ala", shoulder))
		add(list, hinged(p("Ellipsoid", v(0.24, 0.06, 0.26), v(side * 0.84, 0.065, 0.08), dark, v(0, 0, side * 8)), "Ala", shoulder))
		add(list, fine(hinged(p("Ellipsoid", v(0.5, 0.05, 0.14), v(side * 0.52, 0.01, 0.23), white, v(0, 0, side * 8)), "Ala", shoulder)))
		-- Patas y pies palmeados.
		add(list, p("Cylinder", v(0.2, 0.04, 0.04), v(side * 0.1, -0.38, 0.06), beak, v(0, 0, 90)))
		add(list, p("Ellipsoid", v(0.17, 0.04, 0.22), v(side * 0.1, -0.48, 0.0), beak))
	end
	for i = -1, 1 do
		add(list, hinged(p("Block", v(0.1, 0.03, 0.28), v(i * 0.09, -0.0, 0.5), (i == 0) and dark or grey, v(14, i * -12, 0)), "Cola", v(0, -0.02, 0.36)))
	end
	CritterArt.gaviota_pirata = list
end

do -- Erizo Tambor: erizo con púas de colores como las láminas de un xilófono y dos baquetas.
	local fur = rgb(125, 88, 62)
	local cream = rgb(250, 225, 185)
	local wood = rgb(190, 140, 90)
	local keys = { rgb(240, 70, 70), rgb(255, 160, 50), rgb(255, 220, 60), rgb(90, 200, 110), rgb(70, 150, 240) }
	local list: Parts = {
		p("Ellipsoid", v(0.72, 0.58, 0.84), v(0, -0.14, 0.08), fur),
		p("Ellipsoid", v(0.56, 0.44, 0.5), v(0, -0.2, -0.22), cream),
		p("Ellipsoid", v(0.2, 0.16, 0.24), v(0, -0.2, -0.5), cream),
		ball(0.09, v(0, -0.17, -0.63), BLACK),
		p("Block", v(0.1, 0.02, 0.02), v(0, -0.275, -0.56), rgb(150, 90, 70)),
	}
	-- Púas-xilófono: cuatro filas de cinco láminas, cada color una nota.
	for row = 0, 3 do
		local z = -0.08 + row * 0.17
		local scale = 1 - row * row * 0.035
		for k = -2, 2 do
			local degrees = k * 24
			local a = math.rad(degrees)
			local pos = v(math.sin(a) * 0.36 * scale, -0.14 + math.cos(a) * 0.3 * scale, z)
			local key = p("Block", v(0.1, 0.24, 0.075), pos, keys[k + 3], v(18, 0, -degrees))
			key.fine = row % 2 == 1
			add(list, key)
		end
	end
	for _, side in { -1, 1 } do
		add(list, ball(0.15, v(side * 0.25, 0.03, -0.24), fur))
		add(list, fine(ball(0.08, v(side * 0.25, 0.03, -0.29), BLUSH)))
		-- Patitas y baquetas.
		add(list, p("Ellipsoid", v(0.16, 0.09, 0.2), v(side * 0.2, -0.455, -0.18), cream))
		add(list, p("Ellipsoid", v(0.17, 0.09, 0.22), v(side * 0.23, -0.455, 0.3), cream))
		add(list, ball(0.11, v(side * 0.28, -0.3, -0.32), cream))
		add(list, seg("Cylinder", v(side * 0.28, -0.3, -0.32), v(side * 0.36, -0.06, -0.52), 0.035, wood))
		add(list, ball(0.09, v(side * 0.36, -0.06, -0.52), rgb(235, 60, 60)))
	end
	eyes(list, 0.13, -0.1, -0.415, 0.15, cream)
	cheeks(list, 0.21, -0.22, -0.4, 0.09)
	CritterArt.erizo_tambor = list
end

do -- Camaleón Neón: camaleón que cambia de color fluorescente, con rayas de neón y cola en espiral.
	local green = rgb(110, 235, 70)
	local dark = rgb(40, 150, 85)
	local belly = rgb(220, 255, 160)
	local stripes = { rgb(255, 60, 200), rgb(40, 230, 255), rgb(255, 240, 60) }
	local list: Parts = {
		named(p("Ellipsoid", v(0.42, 0.46, 0.78), v(0, -0.1, 0.04), green), "Arcoiris"),
		p("Ellipsoid", v(0.3, 0.2, 0.62), v(0, -0.27, 0.02), belly),
		named(p("Ellipsoid", v(0.38, 0.34, 0.46), v(0, -0.02, -0.42), green), "Arcoiris"),
		named(p("Wedge", v(0.16, 0.15, 0.3), v(0, 0.17, -0.34), green), "Arcoiris"),
		p("Ellipsoid", v(0.36, 0.03, 0.3), v(0, -0.09, -0.5), dark),
		-- Lengua.
		fine(seg("Cylinder", v(0, -0.1, -0.62), v(0, -0.17, -0.82), 0.035, rgb(255, 110, 150))),
		fine(ball(0.075, v(0, -0.17, -0.83), rgb(255, 110, 150))),
	}
	-- Cresta del lomo.
	for i = 0, 4 do
		local z = -0.2 + i * 0.12
		local y = -0.1 + 0.23 * math.sqrt(1 - ((z - 0.04) / 0.39) ^ 2)
		add(list, p("Block", v(0.05, 0.11, 0.11), v(0, y, z), dark, v(45, 0, 0)))
	end
	for _, side in { -1, 1 } do
		-- Ojos de torreta.
		add(list, named(ball(0.21, v(side * 0.18, 0.06, -0.5), green), "Arcoiris"))
		eye(list, v(side * 0.235, 0.07, -0.555), 0.12, dark, side)
		-- Rayas de neón en los costados.
		for i = 1, 3 do
			add(list, p("Block", v(0.02, 0.2, 0.05), v(side * 0.2, -0.08, -0.28 + i * 0.16), stripes[i], v(0, 0, side * -10), NEON))
		end
		-- Patas con manos de pinza.
		for _, z in { -0.2, 0.26 } do
			local knee = v(side * 0.34, -0.3, z - 0.05)
			add(list, seg("Ellipsoid", v(side * 0.14, -0.2, z), knee, 0.1, dark, nil, 1.2))
			add(list, seg("Ellipsoid", knee, v(side * 0.36, -0.47, z - 0.1), 0.08, dark, nil, 1.2))
			add(list, p("Ellipsoid", v(0.14, 0.05, 0.17), v(side * 0.37, -0.475, z - 0.13), dark))
		end
	end
	-- Cola enrollada en espiral.
	local spiral: { Vector3 } = {}
	for j = 0, 6 do
		local theta = math.rad(200 - j * 60)
		local radius = 0.19 - j * 0.022
		table.insert(spiral, v(0, -0.2 + radius * math.sin(theta), 0.62 + radius * math.cos(theta)))
	end
	tube(list, spiral, 0.08, 0.025, green, nil, "Arcoiris")
	CritterArt.camaleon_neon = list
end

-- ============================== RARO ==============================

do -- Búho Despertador: búho redondo con un reloj en el pecho y dos campanas de despertador en la cabeza.
	local brown = rgb(140, 95, 60)
	local darkBrown = rgb(100, 65, 42)
	local cream = rgb(245, 222, 180)
	local red = rgb(220, 50, 50)
	local gold = rgb(255, 200, 60)
	local orange = rgb(255, 150, 40)
	local list: Parts = {
		p("Ellipsoid", v(0.74, 0.86, 0.64), v(0, -0.06, 0.02), brown),
		p("Ellipsoid", v(0.56, 0.6, 0.3), v(0, -0.14, -0.2), cream),
		-- Reloj: caja roja, esfera blanca, agujas a las diez y diez y marcas de las horas.
		p("Cylinder", v(0.08, 0.46, 0.46), v(0, -0.14, -0.34), red, v(0, 90, 0)),
		p("Cylinder", v(0.085, 0.38, 0.38), v(0, -0.14, -0.345), WHITE, v(0, 90, 0)),
		p("Block", v(0.025, 0.16, 0.015), v(0.06, -0.1, -0.392), BLACK, v(0, 0, -60)),
		p("Block", v(0.03, 0.11, 0.015), v(-0.045, -0.115, -0.392), BLACK, v(0, 0, 60)),
		ball(0.045, v(0, -0.14, -0.392), gold, METAL),
		-- Pico y cola.
		p("Ellipsoid", v(0.1, 0.14, 0.12), v(0, 0.11, -0.29), orange),
		p("Block", v(0.3, 0.1, 0.22), v(0, -0.4, 0.33), darkBrown, v(-30, 0, 0)),
		-- Martillo del despertador, entre las dos campanas.
		hinged(p("Cylinder", v(0.16, 0.03, 0.03), v(0, 0.47, 0.02), BLACK, v(0, 0, 90)), "Pendulo", v(0, 0.39, 0.02)),
		hinged(ball(0.08, v(0, 0.56, 0.02), BLACK), "Pendulo", v(0, 0.39, 0.02)),
	}
	for i = 0, 3 do
		local angle = math.rad(i * 90)
		add(list, fine(p("Block", v(0.02, 0.045, 0.012), v(math.sin(angle) * 0.15, -0.14 + math.cos(angle) * 0.15, -0.39), BLACK, v(0, 0, -i * 90))))
	end
	for _, side in { -1, 1 } do
		-- Discos de la cara, cejas de plumas y campanas doradas.
		add(list, p("Cylinder", v(0.04, 0.31, 0.31), v(side * 0.16, 0.2, -0.24), cream, v(0, 90, 0)))
		add(list, p("Ellipsoid", v(0.12, 0.28, 0.1), v(side * 0.27, 0.42, -0.06), darkBrown, v(0, 0, side * -28)))
		add(list, ball(0.25, v(side * 0.15, 0.4, 0.02), gold, METAL))
		add(list, fine(ball(0.06, v(side * 0.15, 0.53, 0.02), gold, METAL)))
		-- Alas con tres plumas.
		local shoulder = v(side * 0.3, 0.1, 0.02)
		add(list, hinged(p("Ellipsoid", v(0.2, 0.56, 0.44), v(side * 0.38, -0.1, 0.04), darkBrown, v(0, 0, side * 8)), "Ala", shoulder))
		for i = 0, 2 do
			add(list, fine(hinged(p("Ellipsoid", v(0.1, 0.2, 0.13), v(side * 0.41, -0.37, -0.08 + i * 0.12), brown), "Ala", shoulder)))
		end
		-- Garras.
		for j = -1, 1 do
			add(list, p("Ellipsoid", v(0.07, 0.06, 0.17), v(side * 0.16 + j * 0.07, -0.47, -0.22), orange))
		end
	end
	eyes(list, 0.16, 0.2, -0.27, 0.2, brown)
	CritterArt.buho_despertador = list
end

do -- Planta Beatbox: planta carnívora con gafas de sol y cadena de oro que escupe semillas a ritmo.
	local green = rgb(80, 185, 75)
	local darkGreen = rgb(45, 135, 60)
	local mouth = rgb(215, 45, 110)
	local gold = rgb(255, 205, 70)
	local hinge = v(0, 0.24, 0.2)
	local list: Parts = {
		-- Mandíbula de abajo, interior de la boca y lengua.
		p("Ellipsoid", v(0.64, 0.3, 0.7), v(0, 0.1, -0.12), green),
		p("Ellipsoid", v(0.54, 0.12, 0.6), v(0, 0.2, -0.13), mouth),
		fine(p("Ellipsoid", v(0.2, 0.06, 0.3), v(0, 0.25, -0.24), rgb(255, 130, 160))),
		-- Mandíbula de arriba (se abre y se cierra) con sus gafas de sol.
		hinged(p("Ellipsoid", v(0.66, 0.32, 0.72), v(0, 0.42, -0.12), green, v(10, 0, 0)), "Pinza", hinge),
		hinged(p("Ellipsoid", v(0.56, 0.1, 0.62), v(0, 0.33, -0.13), mouth, v(10, 0, 0)), "Pinza", hinge),
		hinged(p("Block", v(0.1, 0.03, 0.04), v(0, 0.55, -0.42), BLACK, v(10, 0, 0)), "Pinza", hinge),
		-- Hojas a modo de brazos.
		p("Ellipsoid", v(0.36, 0.06, 0.18), v(-0.24, -0.2, 0.12), green, v(0, 0, -30)),
		p("Ellipsoid", v(0.36, 0.06, 0.18), v(0.24, -0.2, 0.12), green, v(0, 0, 30)),
		-- Colgante de la cadena y semillas que salen disparadas.
		ball(0.09, v(0, -0.13, -0.02), gold, METAL),
		named(ball(0.07, v(0.06, 0.3, -0.52), rgb(70, 45, 30)), "Gota"),
		named(ball(0.06, v(-0.09, 0.27, -0.48), rgb(70, 45, 30)), "Gota"),
	}
	-- Roseta de hojas en el suelo y tallo curvo.
	for i = 0, 4 do
		local degrees = 20 + i * 72
		local angle = math.rad(degrees)
		add(list, p("Ellipsoid", v(0.52, 0.06, 0.26), v(math.cos(angle) * 0.3, -0.45, math.sin(angle) * 0.3), darkGreen, v(0, -degrees, 0)))
	end
	tube(list, { v(0, -0.46, 0.1), v(0.04, -0.3, 0.16), v(0, -0.12, 0.14), v(0, 0.02, 0.05) }, 0.07, 0.06, green)
	-- Dientes: abajo fijos, arriba se mueven con la mandíbula.
	for k = -3, 3 do
		local angle = math.rad(k * 25)
		add(list, p("Ellipsoid", v(0.06, 0.11, 0.06), v(math.sin(angle) * 0.27, 0.27, -0.12 - math.cos(angle) * 0.3), WHITE))
	end
	for k = -2, 2 do
		local angle = math.rad(k * 28)
		add(list, hinged(p("Ellipsoid", v(0.06, 0.11, 0.06), v(math.sin(angle) * 0.27, 0.36 - (1 - math.cos(angle)) * 0.08, -0.12 - math.cos(angle) * 0.31), WHITE), "Pinza", hinge))
	end
	for _, side in { -1, 1 } do
		add(list, hinged(p("Block", v(0.22, 0.13, 0.04), v(side * 0.15, 0.55, -0.42), BLACK, v(10, 0, 0)), "Pinza", hinge))
		add(list, fine(hinged(p("Block", v(0.07, 0.025, 0.045), v(side * 0.15 - 0.04, 0.58, -0.425), WHITE, v(10, 0, -30)), "Pinza", hinge)))
		add(list, fine(hinged(ball(0.09, v(side * 0.2, 0.52, 0.06), darkGreen), "Pinza", hinge)))
		add(list, fine(hinged(ball(0.07, v(side * 0.08, 0.56, 0.14), darkGreen), "Pinza", hinge)))
	end
	-- Cadena de oro alrededor del tallo.
	for k = -3, 3 do
		local angle = math.rad(k * 30)
		add(list, fine(ball(0.045, v(math.sin(angle) * 0.1, -0.04 - math.cos(angle) * 0.05, 0.07 - math.cos(angle) * 0.1), gold, METAL)))
	end
	CritterArt.planta_beatbox = list
end

do -- Salamandra Chispa: lagartija de roca volcánica con manchas de lava, llama en la cola y huellas de fuego.
	local rock = rgb(58, 42, 46)
	local rockLight = rgb(96, 66, 62)
	local lava = rgb(255, 120, 30)
	local hot = rgb(255, 225, 90)
	local list: Parts = {
		p("Ellipsoid", v(0.4, 0.26, 0.46), v(0, -0.26, -0.5), rock, nil, SLATE),
		p("Ellipsoid", v(0.34, 0.1, 0.42), v(0, -0.35, -0.5), rockLight),
		fine(ball(0.035, v(-0.06, -0.24, -0.72), lava, NEON)),
		fine(ball(0.035, v(0.06, -0.24, -0.72), lava, NEON)),
		-- Llama de la cola.
		named(p("Ellipsoid", v(0.13, 0.24, 0.13), v(0.03, -0.2, 0.76), lava, nil, NEON), "Brillo"),
		p("Ellipsoid", v(0.07, 0.14, 0.07), v(0.03, -0.23, 0.76), hot, nil, NEON),
		-- Huellas de fuego que va dejando.
		fine(clear(p("Ellipsoid", v(0.1, 0.02, 0.12), v(0.3, -0.49, 0.56), lava, nil, NEON), 0.15)),
		fine(clear(p("Ellipsoid", v(0.1, 0.02, 0.12), v(-0.28, -0.49, 0.7), lava, nil, NEON), 0.4)),
		fine(clear(p("Ellipsoid", v(0.1, 0.02, 0.12), v(0.26, -0.49, 0.84), lava, nil, NEON), 0.6)),
	}
	local spine = { v(0, -0.3, -0.3), v(0.07, -0.28, -0.08), v(-0.06, -0.29, 0.14), v(0.06, -0.32, 0.36), v(-0.04, -0.35, 0.56), v(0.03, -0.32, 0.72) }
	tube(list, spine, 0.17, 0.05, rock, SLATE)
	-- Manchas de lava y llamitas a lo largo del lomo.
	for i = 1, 5 do
		local radius = 0.17 - 0.024 * (i - 1)
		if i % 2 == 1 then
			add(list, named(p("Ellipsoid", v(radius * 1.1, 0.05, radius * 0.9), spine[i] + v(0, radius * 0.92, 0), lava, nil, NEON), "Brillo"))
		else
			add(list, p("Ellipsoid", v(0.06, 0.16, 0.09), spine[i] + v(0, radius + 0.04, 0), hot, v(-25, 0, 0), NEON))
		end
	end
	for _, side in { -1, 1 } do
		for _, z in { -0.08, 0.36 } do
			local knee = v(side * 0.34, -0.36, z - 0.06)
			add(list, seg("Ellipsoid", v(side * 0.08, -0.3, z), knee, 0.1, rock, nil, 1.2))
			add(list, seg("Ellipsoid", knee, v(side * 0.38, -0.47, z - 0.14), 0.08, rockLight, nil, 1.2))
			add(list, p("Ellipsoid", v(0.14, 0.04, 0.17), v(side * 0.39, -0.48, z - 0.17), rockLight))
			for j = -1, 1 do
				add(list, fine(ball(0.04, v(side * 0.39 + j * 0.045, -0.475, z - 0.26), lava, NEON)))
			end
		end
	end
	eyes(list, 0.13, -0.14, -0.57, 0.14, rock)
	CritterArt.salamandra_chispa = list
end

-- ============================== ÉPICO ==============================

do -- Gólem de Obsidiana: mini-titán de piedra volcánica con grietas de lava, núcleo ardiente y esquirlas.
	local obsidian = rgb(38, 32, 52)
	local facet = rgb(72, 62, 96)
	local crack = rgb(255, 130, 30)
	local list: Parts = {
		shiny(p("Block", v(0.62, 0.46, 0.44), v(0, 0.06, 0), obsidian, nil, SLATE), 0.2),
		p("Block", v(0.46, 0.26, 0.38), v(0, -0.2, 0), facet, nil, SLATE),
		shiny(p("Block", v(0.4, 0.3, 0.3), v(0, 0.1, -0.1), facet, v(0, 45, 0), SLATE), 0.2),
		named(ball(0.2, v(0, 0.08, -0.25), crack, NEON), "Brillo"),
		-- Cabeza con mandíbula saliente, ceño y ojos de brasa.
		p("Block", v(0.3, 0.22, 0.28), v(0, 0.4, -0.05), obsidian, nil, SLATE),
		p("Block", v(0.27, 0.08, 0.27), v(0, 0.3, -0.09), facet, nil, SLATE),
		p("Block", v(0.34, 0.06, 0.1), v(0, 0.475, -0.17), facet, nil, SLATE),
		fine(p("Block", v(0.04, 0.05, 0.03), v(-0.07, 0.355, -0.215), WHITE)),
		fine(p("Block", v(0.04, 0.05, 0.03), v(0.07, 0.355, -0.215), WHITE)),
		-- Grietas de lava en el torso.
		named(p("Block", v(0.17, 0.025, 0.02), v(-0.18, 0.18, -0.225), crack, v(0, 0, 30), NEON), "Brillo"),
		named(p("Block", v(0.15, 0.025, 0.02), v(-0.21, 0.02, -0.225), crack, v(0, 0, -40), NEON), "Brillo"),
		named(p("Block", v(0.17, 0.025, 0.02), v(0.18, 0.2, -0.225), crack, v(0, 0, -35), NEON), "Brillo"),
		named(p("Block", v(0.15, 0.025, 0.02), v(0.22, 0.0, -0.225), crack, v(0, 0, 25), NEON), "Brillo"),
		named(p("Block", v(0.2, 0.025, 0.02), v(0.02, -0.22, -0.195), crack, v(0, 0, 12), NEON), "Brillo"),
		-- Esquirlas de obsidiana en la espalda.
		shiny(p("Block", v(0.11, 0.4, 0.11), v(0, 0.32, 0.24), facet, v(-30, 0, 0), SLATE), 0.3),
		shiny(p("Block", v(0.09, 0.3, 0.09), v(-0.18, 0.26, 0.24), obsidian, v(-30, 0, 22), SLATE), 0.3),
		shiny(p("Block", v(0.09, 0.3, 0.09), v(0.18, 0.26, 0.24), obsidian, v(-30, 0, -22), SLATE), 0.3),
	}
	for _, side in { -1, 1 } do
		add(list, named(p("Block", v(0.08, 0.04, 0.02), v(side * 0.075, 0.41, -0.195), crack, v(0, 0, side * 16), NEON), "Brillo"))
		-- Hombros, brazos y puños.
		add(list, shiny(p("Block", v(0.32, 0.3, 0.36), v(side * 0.46, 0.22, 0), obsidian, v(0, 0, side * 15), SLATE), 0.2))
		add(list, p("Block", v(0.09, 0.28, 0.09), v(side * 0.5, 0.44, 0.02), facet, v(10, 30, side * -18), SLATE))
		add(list, fine(p("Block", v(0.06, 0.18, 0.06), v(side * 0.4, 0.42, -0.08), facet, v(-15, 20, side * 10), SLATE)))
		add(list, p("Block", v(0.2, 0.26, 0.22), v(side * 0.52, 0.0, 0), facet, nil, SLATE))
		add(list, p("Block", v(0.26, 0.3, 0.28), v(side * 0.55, -0.22, -0.04), obsidian, nil, SLATE))
		add(list, p("Block", v(0.3, 0.2, 0.32), v(side * 0.55, -0.4, -0.06), facet, nil, SLATE))
		add(list, named(p("Block", v(0.02, 0.16, 0.025), v(side * 0.685, -0.2, -0.05), crack, v(20, 0, 0), NEON), "Brillo"))
		add(list, fine(named(p("Block", v(0.2, 0.025, 0.02), v(side * 0.55, -0.38, -0.225), crack, nil, NEON), "Brillo")))
		-- Piernas y pies.
		add(list, p("Block", v(0.22, 0.22, 0.26), v(side * 0.16, -0.36, 0), obsidian, nil, SLATE))
		add(list, p("Block", v(0.26, 0.1, 0.34), v(side * 0.16, -0.455, -0.03), facet, nil, SLATE))
	end
	CritterArt.golem_obsidiana = list
end

do -- Murciélago de Magma: alas de roca oscura agrietada por las que brilla la lava.
	local rock = rgb(52, 42, 50)
	local light = rgb(92, 70, 76)
	local lava = rgb(255, 120, 30)
	local list: Parts = {
		p("Ellipsoid", v(0.42, 0.5, 0.4), v(0, -0.08, 0), rock, nil, SLATE),
		p("Ellipsoid", v(0.3, 0.32, 0.14), v(0, -0.1, -0.16), light),
		ball(0.4, v(0, 0.24, -0.06), rock, SLATE),
		p("Ellipsoid", v(0.18, 0.12, 0.12), v(0, 0.17, -0.24), light),
		ball(0.06, v(0, 0.2, -0.3), BLACK),
		-- Grieta de lava en el pecho y gotas de magma.
		named(p("Block", v(0.12, 0.025, 0.02), v(-0.04, -0.06, -0.235), lava, v(0, 0, -40), NEON), "Brillo"),
		named(p("Block", v(0.12, 0.025, 0.02), v(0.04, -0.13, -0.235), lava, v(0, 0, -40), NEON), "Brillo"),
		named(ball(0.06, v(0, -0.36, 0), lava, NEON), "Gota"),
		named(ball(0.05, v(0.12, -0.3, 0.04), lava, NEON), "Gota"),
	}
	for _, side in { -1, 1 } do
		-- Orejas grandes con el interior encendido, colmillos y pies.
		add(list, p("Ellipsoid", v(0.16, 0.36, 0.08), v(side * 0.17, 0.5, -0.02), rock, v(0, 0, side * -18)))
		add(list, named(p("Ellipsoid", v(0.08, 0.22, 0.05), v(side * 0.17, 0.49, -0.045), lava, v(0, 0, side * -18), NEON), "Brillo"))
		add(list, p("Ellipsoid", v(0.035, 0.08, 0.035), v(side * 0.05, 0.11, -0.27), WHITE))
		add(list, p("Ellipsoid", v(0.1, 0.07, 0.14), v(side * 0.09, -0.34, -0.04), light))
		-- Ala: brazo, tres dedos y tres paños de membrana con vetas de lava.
		local shoulder = v(side * 0.18, 0.06, 0.05)
		local wrist = v(side * 0.5, 0.34, 0.05)
		local tips = { v(side * 0.94, 0.3, 0.05), v(side * 0.86, -0.04, 0.05), v(side * 0.6, -0.26, 0.05) }
		add(list, hinged(seg("Cylinder", shoulder, wrist, 0.06, light), "Ala", shoulder))
		add(list, hinged(ball(0.09, wrist, light), "Ala", shoulder))
		for _, tip in tips do
			add(list, hinged(seg("Cylinder", wrist, tip, 0.04, light), "Ala", shoulder))
		end
		add(list, hinged(p("Block", v(0.42, 0.34, 0.02), v(side * 0.7, 0.15, 0.06), rock, v(0, 0, side * -12), SLATE), "Ala", shoulder))
		add(list, hinged(p("Block", v(0.34, 0.38, 0.02), v(side * 0.55, -0.04, 0.06), rock, v(0, 0, side * 28), SLATE), "Ala", shoulder))
		add(list, hinged(p("Block", v(0.24, 0.42, 0.02), v(side * 0.32, 0.04, 0.06), rock, nil, SLATE), "Ala", shoulder))
		add(list, hinged(p("Block", v(0.24, 0.02, 0.01), v(side * 0.7, 0.12, 0.045), lava, v(0, 0, side * -25), NEON), "Ala", shoulder))
		add(list, hinged(p("Block", v(0.2, 0.02, 0.01), v(side * 0.56, -0.06, 0.045), lava, v(0, 0, side * 50), NEON), "Ala", shoulder))
		add(list, hinged(p("Block", v(0.16, 0.02, 0.01), v(side * 0.34, 0.06, 0.045), lava, v(0, 0, side * -60), NEON), "Ala", shoulder))
		add(list, fine(hinged(p("Block", v(0.1, 0.02, 0.01), v(side * 0.78, 0.22, 0.045), lava, v(0, 0, side * 40), NEON), "Ala", shoulder)))
		add(list, fine(hinged(p("Block", v(0.1, 0.02, 0.01), v(side * 0.46, -0.14, 0.045), lava, v(0, 0, side * -20), NEON), "Ala", shoulder)))
	end
	eyes(list, 0.1, 0.28, -0.215, 0.13, rock)
	CritterArt.murcielago_magma = list
end

do -- Ajolote Chubasquero (exclusivo de la Lluvia de Bichos): ajolote rosa con chubasquero amarillo
	-- con capucha y botas de agua rojas.
	local pink = rgb(255, 175, 195)
	local gill = rgb(235, 80, 130)
	local yellow = rgb(255, 210, 40)
	local yellowDark = rgb(232, 172, 20)
	local boot = rgb(220, 55, 55)
	local drop = rgb(120, 180, 255)
	local list: Parts = {
		-- Chubasquero: cuerpo, faldón, solapa y capucha con pico.
		p("Ellipsoid", v(0.54, 0.52, 0.48), v(0, -0.2, 0.04), yellow),
		p("Ellipsoid", v(0.64, 0.14, 0.58), v(0, -0.36, 0.04), yellowDark),
		p("Block", v(0.03, 0.34, 0.02), v(0, -0.2, -0.2), yellowDark),
		fine(ball(0.05, v(0.045, -0.12, -0.215), WHITE)),
		fine(ball(0.05, v(0.045, -0.26, -0.205), WHITE)),
		p("Ellipsoid", v(0.82, 0.6, 0.5), v(0, 0.18, 0.1), yellow),
		ball(0.11, v(0, 0.5, 0.2), yellowDark),
		-- Cabeza ancha con sonrisa.
		p("Ellipsoid", v(0.72, 0.46, 0.5), v(0, 0.14, -0.08), pink),
		p("Ellipsoid", v(0.2, 0.03, 0.04), v(0, 0.05, -0.325), rgb(190, 80, 110)),
		-- Cola con aleta.
		hinged(p("Ellipsoid", v(0.1, 0.22, 0.42), v(0, -0.3, 0.42), pink, v(-15, 0, 0)), "Cola", v(0, -0.3, 0.24)),
		hinged(p("Ellipsoid", v(0.03, 0.3, 0.36), v(0, -0.26, 0.46), gill, v(-15, 0, 0)), "Cola", v(0, -0.3, 0.24)),
		named(ball(0.07, v(-0.42, 0.0, 0.1), drop, GLASS), "Gota"),
		named(ball(0.06, v(0.43, -0.02, 0.04), drop, GLASS), "Gota"),
	}
	for _, side in { -1, 1 } do
		-- Tres branquias plumosas a cada lado.
		for i = -1, 1 do
			add(list, p("Ellipsoid", v(0.28, 0.07, 0.08), v(side * 0.42, 0.2 + i * 0.12, -0.04), gill, v(0, 0, side * i * 28)))
		end
		-- Mangas, manos y botas.
		add(list, seg("Ellipsoid", v(side * 0.22, -0.12, 0), v(side * 0.36, -0.3, -0.08), 0.15, yellow, nil, 1.2))
		add(list, ball(0.1, v(side * 0.38, -0.33, -0.1), pink))
		add(list, p("Cylinder", v(0.14, 0.15, 0.15), v(side * 0.13, -0.4, -0.02), boot, v(0, 0, 90)))
		add(list, p("Ellipsoid", v(0.17, 0.1, 0.27), v(side * 0.13, -0.45, -0.08), boot))
		add(list, fine(p("Cylinder", v(0.03, 0.17, 0.17), v(side * 0.13, -0.33, -0.02), rgb(170, 35, 40), v(0, 0, 90))))
	end
	eyes(list, 0.2, 0.18, -0.29, 0.11, pink)
	cheeks(list, 0.28, 0.08, -0.25, 0.1)
	CritterArt.ajolote_chubasquero = list
end

-- ============================== LEGENDARIO ==============================

do -- Lobo de Tormenta: lobo de nube de tormenta con rayos en el pelaje, ojos eléctricos y lluvia bajo la panza.
	local storm = rgb(72, 82, 112)
	local dark = rgb(46, 52, 78)
	local fluff = rgb(150, 162, 195)
	local bolt = rgb(255, 235, 80)
	local electric = rgb(120, 240, 255)
	local drop = rgb(120, 180, 255)
	local tailBase = v(0, 0.0, 0.5)
	local list: Parts = {
		-- Cuerpo: pecho, lomo, grupa y vientre oscuro de nubarrón.
		ball(0.44, v(0, -0.02, -0.14), storm),
		p("Ellipsoid", v(0.38, 0.36, 0.56), v(0, -0.04, 0.12), storm),
		ball(0.38, v(0, -0.05, 0.36), storm),
		p("Ellipsoid", v(0.3, 0.2, 0.5), v(0, -0.18, 0.1), dark),
		p("Ellipsoid", v(0.28, 0.42, 0.3), v(0, 0.16, -0.26), storm, v(-30, 0, 0)),
		-- Cabeza: cráneo, hocico, mandíbula y trufa.
		p("Ellipsoid", v(0.32, 0.3, 0.34), v(0, 0.33, -0.38), storm),
		p("Ellipsoid", v(0.17, 0.14, 0.28), v(0, 0.28, -0.58), fluff),
		p("Ellipsoid", v(0.14, 0.05, 0.2), v(0, 0.2, -0.56), dark),
		ball(0.07, v(0, 0.3, -0.72), BLACK),
		-- Melena de nubes.
		ball(0.22, v(0, 0.0, -0.34), fluff),
		ball(0.2, v(0, 0.31, -0.13), fluff),
		fine(ball(0.14, v(0, 0.17, 0.0), fluff)),
		fine(ball(0.14, v(0, 0.16, 0.16), fluff)),
		fine(ball(0.13, v(0, 0.14, 0.3), fluff)),
		-- Cola de nubarrones rematada en un rayo.
		hinged(ball(0.2, v(0, 0.04, 0.56), storm), "Cola", tailBase),
		hinged(ball(0.25, v(0, 0.12, 0.7), storm), "Cola", tailBase),
		hinged(ball(0.19, v(0, 0.2, 0.83), fluff), "Cola", tailBase),
		hinged(p("Block", v(0.03, 0.14, 0.05), v(0, 0.31, 0.88), bolt, v(-30, 0, 0), NEON), "Cola", tailBase),
		hinged(p("Block", v(0.03, 0.12, 0.05), v(0, 0.4, 0.9), bolt, v(35, 0, 0), NEON), "Cola", tailBase),
		-- Lluvia bajo la panza.
		named(ball(0.045, v(0.05, -0.3, 0.05), drop, GLASS), "Gota"),
		named(ball(0.045, v(-0.06, -0.32, 0.2), drop, GLASS), "Gota"),
		named(ball(0.04, v(0.02, -0.3, -0.06), drop, GLASS), "Gota"),
	}
	for _, side in { -1, 1 } do
		-- Orejas, cejas, colmillos y melena lateral.
		add(list, p("Ellipsoid", v(0.11, 0.26, 0.07), v(side * 0.11, 0.52, -0.32), dark, v(-10, 0, side * -12)))
		add(list, fine(p("Ellipsoid", v(0.05, 0.16, 0.04), v(side * 0.11, 0.51, -0.345), fluff, v(-10, 0, side * -12))))
		add(list, p("Block", v(0.11, 0.03, 0.04), v(side * 0.09, 0.43, -0.5), dark, v(0, 0, side * 22)))
		add(list, p("Ellipsoid", v(0.03, 0.07, 0.03), v(side * 0.045, 0.2, -0.66), WHITE))
		add(list, ball(0.2, v(side * 0.16, 0.12, -0.24), fluff))
		add(list, ball(0.18, v(side * 0.12, 0.26, -0.16), fluff))
		-- Rayo en zigzag en el costado.
		add(list, named(p("Block", v(0.02, 0.15, 0.05), v(side * 0.2, 0.03, 0.02), bolt, v(28, 0, 0), NEON), "Brillo"))
		add(list, named(p("Block", v(0.02, 0.13, 0.05), v(side * 0.2, -0.06, 0.07), bolt, v(-38, 0, 0), NEON), "Brillo"))
		add(list, named(p("Block", v(0.02, 0.15, 0.05), v(side * 0.195, -0.15, 0.04), bolt, v(28, 0, 0), NEON), "Brillo"))
		-- Patas: muslo, caña y zarpa de nube.
		add(list, ball(0.25, v(side * 0.15, -0.14, 0.34), storm))
		for _, z in { -0.2, 0.36 } do
			add(list, seg("Ellipsoid", v(side * 0.13, -0.1, z), v(side * 0.13, -0.32, z + 0.02), 0.15, storm, nil, 1.2))
			add(list, seg("Cylinder", v(side * 0.13, -0.3, z + 0.02), v(side * 0.13, -0.45, z - 0.02), 0.09, dark))
			add(list, ball(0.14, v(side * 0.13, -0.45, z - 0.04), fluff))
		end
	end
	glowEyes(list, 0.09, 0.37, -0.52, 0.09, electric)
	CritterArt.lobo_tormenta = list
end

do -- Dragón de Algodón: serpiente alada de nubes rosas, con cuernos, bigotes y alitas de algodón.
	local pink = rgb(255, 178, 215)
	local light = rgb(255, 216, 236)
	local cream = rgb(255, 240, 200)
	local blue = rgb(150, 215, 255)
	local sprinkles = { rgb(255, 120, 160), rgb(130, 220, 255), rgb(255, 230, 110), rgb(170, 240, 170) }
	local list: Parts = {
		-- Cuello y cabeza.
		ball(0.3, v(0, 0.2, -0.36), light),
		ball(0.42, v(0, 0.34, -0.44), pink),
		p("Ellipsoid", v(0.26, 0.2, 0.24), v(0, 0.27, -0.64), light),
		p("Ellipsoid", v(0.12, 0.025, 0.04), v(0, 0.22, -0.745), rgb(210, 90, 130)),
		fine(ball(0.03, v(-0.05, 0.31, -0.755), rgb(210, 90, 130))),
		fine(ball(0.03, v(0.05, 0.31, -0.755), rgb(210, 90, 130))),
		-- Flequillo de algodón.
		ball(0.16, v(0, 0.56, -0.42), light),
		ball(0.14, v(0, 0.55, -0.3), light),
		fine(ball(0.11, v(0, 0.5, -0.2), light)),
	}
	-- Cuerpo ondulante: once bolas de algodón cada vez más pequeñas, con puntitos de colores.
	for i = 0, 10 do
		local t = i / 10
		local pos = v(0.1 * math.sin(t * 7), -0.02 + 0.2 * math.sin(t * 6.3 + 0.6), -0.3 + t)
		local size = 0.34 - t * 0.2
		add(list, ball(size, pos, (i % 2 == 0) and pink or light))
		if i % 2 == 1 then
			add(list, fine(ball(0.04, pos + v(0.06, size * 0.48, 0.02), sprinkles[(i // 2) % 4 + 1])))
			add(list, fine(ball(0.04, pos + v(-size * 0.4, size * 0.25, -0.03), sprinkles[(i // 2 + 2) % 4 + 1])))
		end
	end
	-- Borla de la cola.
	add(list, ball(0.17, v(0.07, 0.03, 0.78), cream))
	add(list, fine(ball(0.1, v(0.13, 0.11, 0.84), cream)))
	add(list, fine(ball(0.1, v(0.0, 0.1, 0.86), cream)))
	for _, side in { -1, 1 } do
		-- Cuernos y bigotes.
		add(list, p("Ellipsoid", v(0.07, 0.22, 0.07), v(side * 0.12, 0.58, -0.36), cream, v(20, 0, side * -15)))
		tube(list, { v(side * 0.12, 0.26, -0.68), v(side * 0.26, 0.3, -0.74), v(side * 0.34, 0.4, -0.7) }, 0.016, 0.01, blue, nil, nil, true)
		-- Alitas de algodón.
		local shoulder = v(side * 0.18, 0.24, -0.08)
		add(list, hinged(ball(0.22, v(side * 0.3, 0.32, -0.06), WHITE), "Ala", shoulder))
		add(list, hinged(ball(0.2, v(side * 0.46, 0.4, -0.04), WHITE), "Ala", shoulder))
		add(list, hinged(ball(0.15, v(side * 0.6, 0.43, -0.02), WHITE), "Ala", shoulder))
		add(list, hinged(ball(0.14, v(side * 0.45, 0.28, -0.04), light), "Ala", shoulder))
		-- Patitas.
		add(list, ball(0.12, v(side * 0.12, -0.02, -0.18), light))
		add(list, ball(0.11, v(side * 0.1, -0.24, 0.26), light))
	end
	eyes(list, 0.12, 0.4, -0.61, 0.15, pink)
	cheeks(list, 0.18, 0.3, -0.585, 0.09)
	CritterArt.dragon_algodon = list
end

do -- Garza de Prisma: garza de cristal translúcido con un corazón de luz y plumas con los colores del arcoíris.
	local glass = rgb(190, 235, 255)
	local gold = rgb(255, 205, 100)
	local rainbow = { rgb(255, 90, 110), rgb(255, 170, 60), rgb(255, 235, 90), rgb(110, 230, 140), rgb(90, 180, 255), rgb(180, 120, 255) }
	local list: Parts = {
		clear(p("Ellipsoid", v(0.34, 0.34, 0.56), v(0, 0.02, 0.08), glass, v(15, 0, 0), GLASS), 0.3),
		named(ball(0.15, v(0, 0.02, 0.06), WHITE, NEON), "Brillo"),
		-- Cabeza y pico largo.
		p("Ellipsoid", v(0.14, 0.13, 0.22), v(0, 0.55, -0.32), glass, nil, GLASS),
		seg("Cylinder", v(0, 0.545, -0.4), v(0, 0.5, -0.74), 0.04, gold),
		ball(0.04, v(0, 0.5, -0.74), gold),
		-- Pata levantada (la típica postura de garza) y pata de apoyo.
		seg("Cylinder", v(0.07, -0.1, 0.08), v(0.09, -0.25, -0.06), 0.03, gold),
		ball(0.045, v(0.09, -0.25, -0.06), gold),
		seg("Cylinder", v(0.09, -0.25, -0.06), v(0.09, -0.33, 0.06), 0.028, gold),
		p("Ellipsoid", v(0.08, 0.03, 0.12), v(0.09, -0.35, 0.03), gold, v(40, 0, 0)),
		seg("Cylinder", v(-0.07, -0.1, 0.08), v(-0.08, -0.3, 0.12), 0.03, gold),
		ball(0.045, v(-0.08, -0.3, 0.12), gold),
		seg("Cylinder", v(-0.08, -0.3, 0.12), v(-0.08, -0.48, 0.08), 0.028, gold),
	}
	-- Cuello en S.
	tube(list, { v(0, 0.1, -0.14), v(0, 0.26, -0.26), v(0, 0.4, -0.2), v(0, 0.52, -0.28) }, 0.055, 0.04, glass, GLASS)
	for j = -1, 1 do
		-- Dedos de la pata de apoyo, penacho que cambia de color y plumas de la cola.
		add(list, fine(seg("Cylinder", v(-0.08, -0.48, 0.08), v(-0.08 + j * 0.07, -0.49, -0.04), 0.022, gold)))
		add(list, named(seg("Block", v(0, 0.6, -0.28), v(j * 0.07, 0.72 - math.abs(j) * 0.04, -0.04), 0.03, rainbow[j + 5]), "Arcoiris"))
		add(list, clear(p("Block", v(0.05, 0.03, 0.36), v(j * 0.07, -0.02 - math.abs(j) * 0.02, 0.46), rainbow[j + 3], v(-22, j * -14, 0), GLASS), 0.2))
	end
	for _, side in { -1, 1 } do
		-- Alas plegadas: seis plumas de cristal en degradado.
		local shoulder = v(side * 0.14, 0.1, 0.02)
		for i = 1, 6 do
			local feather = p("Block", v(0.03, 0.12, 0.42 - i * 0.025), v(side * (0.17 + 0.006 * i), 0.14 - i * 0.045, 0.12 + i * 0.03), rainbow[i], v(22 - i * 4, 0, 0), GLASS)
			add(list, hinged(clear(feather, 0.2), "Ala", shoulder))
		end
		-- Destellos flotando alrededor.
		add(list, fine(named(p("Block", v(0.05, 0.05, 0.05), v(side * 0.36, 0.4, 0.1), rainbow[3 + side], v(45, 0, 45), NEON), "Brillo")))
		add(list, fine(named(p("Block", v(0.04, 0.04, 0.04), v(side * 0.3, -0.2, -0.2), rainbow[4 + side], v(45, 0, 45), NEON), "Brillo")))
	end
	eyes(list, 0.06, 0.575, -0.385, 0.06, glass)
	CritterArt.garza_prisma = list
end

-- ============================== MÍTICO ==============================

do -- Leviatán de Espejo: serpiente de agua de cristal líquido que asoma del agua en tres arcos.
	local mirror = rgb(185, 215, 235)
	local deep = rgb(70, 130, 175)
	local fin = rgb(120, 235, 240)
	local water = rgb(150, 215, 245)
	local glow = rgb(140, 255, 250)
	local list: Parts = {}
	-- Tres tramos del cuerpo: cuello, lomo y cola.
	tube(list, { v(0, -0.5, -0.08), v(0, -0.2, -0.2), v(0, 0.08, -0.3), v(0, 0.3, -0.4) }, 0.13, 0.11, mirror)
	tube(list, { v(0.12, -0.5, 0.0), v(0.13, -0.26, 0.1), v(0.12, -0.14, 0.22), v(0.1, -0.26, 0.34), v(0.08, -0.5, 0.42) }, 0.12, 0.1, mirror)
	tube(list, { v(-0.06, -0.5, 0.5), v(-0.08, -0.3, 0.6), v(-0.12, -0.14, 0.72), v(-0.18, -0.06, 0.84) }, 0.09, 0.03, mirror)
	-- Cabeza: cráneo, morro y mandíbula.
	add(list, p("Ellipsoid", v(0.3, 0.24, 0.44), v(0, 0.34, -0.52), mirror))
	add(list, p("Ellipsoid", v(0.22, 0.14, 0.26), v(0, 0.3, -0.74), mirror))
	for _, spec in list do
		spec.reflectance = 0.45 -- todo lo anterior es "espejo"
	end
	add(list, p("Ellipsoid", v(0.2, 0.07, 0.36), v(0, 0.23, -0.6), deep))
	-- Cresta de la cabeza y aletas del lomo, de cristal.
	add(list, clear(p("Ellipsoid", v(0.03, 0.22, 0.36), v(0, 0.5, -0.42), fin, v(-15, 0, 0), GLASS), 0.2))
	local fins = { v(0, 0.0, -0.14), v(0, 0.24, -0.24), v(0.13, -0.1, 0.1), v(0.125, 0.0, 0.22), v(0.1, -0.1, 0.34), v(-0.08, -0.16, 0.56), v(-0.12, -0.02, 0.7) }
	for i, pos in fins do
		local piece = clear(p("Ellipsoid", v(0.03, 0.2, 0.15), pos, fin, v(-25, 0, 0), GLASS), 0.2)
		piece.fine = i % 2 == 0
		add(list, piece)
	end
	-- Aleta de la cola.
	add(list, clear(p("Ellipsoid", v(0.03, 0.26, 0.16), v(-0.2, 0.02, 0.9), fin, v(-35, 0, 0), GLASS), 0.2))
	add(list, clear(p("Ellipsoid", v(0.03, 0.2, 0.14), v(-0.2, -0.12, 0.92), fin, v(35, 0, 0), GLASS), 0.2))
	-- Ondas donde entra y sale del agua.
	for _, pos in { v(0, -0.49, -0.08), v(0.12, -0.49, 0.0), v(0.08, -0.49, 0.42), v(-0.06, -0.49, 0.5) } do
		add(list, clear(p("Cylinder", v(0.02, 0.42, 0.42), pos, water, v(0, 0, 90)), 0.45))
		add(list, fine(clear(p("Cylinder", v(0.012, 0.6, 0.6), pos, water, v(0, 0, 90)), 0.7)))
	end
	for _, side in { -1, 1 } do
		-- Aletas a los lados de la cabeza y barbillas.
		add(list, clear(p("Ellipsoid", v(0.04, 0.24, 0.28), v(side * 0.18, 0.4, -0.38), fin, v(0, side * -28, side * -22), GLASS), 0.2))
		add(list, fine(seg("Cylinder", v(side * 0.08, 0.25, -0.82), v(side * 0.17, 0.11, -0.9), 0.022, fin)))
		add(list, fine(ball(0.035, v(side * 0.17, 0.11, -0.9), glow, NEON)))
	end
	add(list, named(ball(0.05, v(0.2, -0.1, 0.2), water, GLASS), "Gota"))
	add(list, named(ball(0.045, v(-0.1, 0.1, -0.3), water, GLASS), "Gota"))
	add(list, named(ball(0.045, v(-0.2, -0.2, 0.7), water, GLASS), "Gota"))
	glowEyes(list, 0.115, 0.4, -0.64, 0.08, glow)
	CritterArt.leviatan_espejo = list
end

do -- Búho de Cuerda: autómata dorado con engranajes a la vista, llave de cuerda y cabeza que da la vuelta entera.
	local brass = rgb(215, 165, 55)
	local dark = rgb(140, 95, 35)
	local steel = rgb(170, 175, 185)
	local amber = rgb(255, 170, 40)
	local hollow = rgb(40, 30, 28)
	local neck = v(0, 0.34, 0)
	local list: Parts = {
		-- Cuerpo de barril con dos aros de acero.
		p("Cylinder", v(0.46, 0.6, 0.6), v(0, -0.12, 0), brass, v(0, 0, 90), METAL),
		p("Ellipsoid", v(0.6, 0.24, 0.6), v(0, -0.35, 0), dark, nil, METAL),
		p("Ellipsoid", v(0.6, 0.2, 0.6), v(0, 0.11, 0), dark, nil, METAL),
		fine(p("Cylinder", v(0.04, 0.625, 0.625), v(0, -0.3, 0), steel, v(0, 0, 90), METAL)),
		fine(p("Cylinder", v(0.04, 0.625, 0.625), v(0, 0.06, 0), steel, v(0, 0, 90), METAL)),
		-- Ventana del pecho.
		p("Cylinder", v(0.03, 0.46, 0.46), v(0, -0.12, -0.28), steel, v(0, 90, 0), METAL),
		p("Cylinder", v(0.04, 0.4, 0.4), v(0, -0.12, -0.285), hollow, v(0, 90, 0)),
		-- Llave de cuerda en la espalda.
		named(p("Cylinder", v(0.2, 0.05, 0.05), v(0, -0.1, 0.38), steel, v(0, 90, 0), METAL), "Giro"),
		named(p("Block", v(0.05, 0.32, 0.04), v(0, -0.1, 0.5), brass, v(0, 90, 0), METAL), "Giro"),
		-- Cabeza giratoria: esfera, pico, manivela y remaches.
		hinged(ball(0.46, v(0, 0.36, 0), brass, METAL), "Cabeza", neck),
		hinged(p("Ellipsoid", v(0.08, 0.11, 0.11), v(0, 0.3, -0.23), steel, nil, METAL), "Cabeza", neck),
		hinged(p("Cylinder", v(0.1, 0.03, 0.03), v(0, 0.63, 0), steel, v(0, 0, 90), METAL), "Cabeza", neck),
		hinged(ball(0.07, v(0, 0.69, 0), amber, NEON), "Cabeza", neck),
		fine(p("Cylinder", v(0.12, 0.06, 0.06), v(0.14, 0.2, 0.26), dark, v(0, 0, 90), METAL)),
	}
	-- Engranajes: un disco y dientes cruzados; cada uno gira sobre su eje.
	local function gear(center: Vector3, diameter: number, color: Color3, diagonal: boolean)
		add(list, named(p("Cylinder", v(0.03, diameter * 0.8, diameter * 0.8), center, color, v(0, 90, 0), METAL), "Giro"))
		add(list, named(p("Block", v(0.03, diameter, diameter * 0.2), center, color, v(0, 90, 0), METAL), "Giro"))
		add(list, named(p("Block", v(0.03, diameter * 0.2, diameter), center, color, v(0, 90, 0), METAL), "Giro"))
		if diagonal then
			add(list, fine(named(turned(p("Block", v(0.03, diameter, diameter * 0.2), center, color, v(0, 90, 0), METAL), v(45, 0, 0)), "Giro")))
			add(list, fine(named(turned(p("Block", v(0.03, diameter, diameter * 0.2), center, color, v(0, 90, 0), METAL), v(-45, 0, 0)), "Giro")))
		end
	end
	gear(v(-0.07, -0.09, -0.315), 0.2, brass, true)
	gear(v(0.09, -0.17, -0.315), 0.14, steel, true)
	gear(v(0.07, -0.01, -0.315), 0.1, dark, false)
	for _, side in { -1, 1 } do
		-- Ojos de lente: aro, cristal encendido y pupila; penachos de latón.
		add(list, hinged(p("Cylinder", v(0.05, 0.21, 0.21), v(side * 0.11, 0.39, -0.2), dark, v(0, 90, 0), METAL), "Cabeza", neck))
		add(list, hinged(p("Cylinder", v(0.055, 0.15, 0.15), v(side * 0.11, 0.39, -0.205), amber, v(0, 90, 0), NEON), "Cabeza", neck))
		add(list, hinged(ball(0.06, v(side * 0.11, 0.39, -0.225), BLACK), "Cabeza", neck))
		add(list, hinged(p("Block", v(0.06, 0.2, 0.04), v(side * 0.17, 0.6, 0), dark, v(0, 0, side * -22), METAL), "Cabeza", neck))
		add(list, fine(hinged(ball(0.04, v(side * 0.22, 0.3, -0.06), steel, METAL), "Cabeza", neck)))
		-- Alas de tres placas, patas y garras.
		local shoulder = v(side * 0.3, 0.02, 0)
		for i = 0, 2 do
			add(list, hinged(p("Block", v(0.04, 0.42 - i * 0.07, 0.17), v(side * (0.34 + i * 0.015), -0.13 + i * 0.03, -0.1 + i * 0.12), (i == 1) and dark or brass, v(0, 0, side * (6 + i * 4)), METAL), "Ala", shoulder))
		end
		add(list, p("Cylinder", v(0.1, 0.05, 0.05), v(side * 0.12, -0.44, 0), steel, v(0, 0, 90), METAL))
		for j = -1, 1 do
			add(list, fine(p("Ellipsoid", v(0.04, 0.04, 0.15), v(side * 0.12 + j * 0.05, -0.48, -0.06), steel, nil, METAL)))
		end
	end
	CritterArt.buho_cuerda = list
end

do -- Coloso de Bronce: guardián mecánico cubierto de musgo, con el núcleo encendido y una flor en el hombro.
	local bronze = rgb(150, 105, 62)
	local darkBronze = rgb(105, 72, 45)
	local verdigris = rgb(88, 172, 142)
	local moss = rgb(92, 158, 72)
	local core = rgb(110, 255, 210)
	local list: Parts = {
		-- Torso, cintura y cadera.
		p("Ellipsoid", v(0.66, 0.56, 0.5), v(0, 0.1, 0.02), bronze, nil, METAL),
		p("Cylinder", v(0.2, 0.4, 0.4), v(0, -0.2, 0.02), darkBronze, v(0, 0, 90), METAL),
		p("Block", v(0.44, 0.12, 0.36), v(0, -0.3, 0.02), bronze, nil, METAL),
		-- Núcleo: marco, luz y aspas que giran.
		p("Cylinder", v(0.05, 0.3, 0.3), v(0, 0.1, -0.235), darkBronze, v(0, 90, 0), METAL),
		named(p("Cylinder", v(0.055, 0.21, 0.21), v(0, 0.1, -0.24), core, v(0, 90, 0), NEON), "Brillo"),
		named(p("Block", v(0.02, 0.28, 0.035), v(0, 0.1, -0.275), bronze, v(0, 90, 0), METAL), "Giro"),
		named(p("Block", v(0.02, 0.035, 0.28), v(0, 0.1, -0.275), bronze, v(0, 90, 0), METAL), "Giro"),
		-- Cabeza pequeña: collar, cúpula, visor y antena rota.
		p("Cylinder", v(0.06, 0.3, 0.3), v(0, 0.36, -0.02), verdigris, v(0, 0, 90), METAL),
		ball(0.25, v(0, 0.43, -0.04), darkBronze, METAL),
		named(p("Block", v(0.17, 0.035, 0.03), v(0, 0.44, -0.155), core, nil, NEON), "Brillo"),
		p("Cylinder", v(0.14, 0.02, 0.02), v(0.06, 0.6, 0), darkBronze, v(0, 0, 70), METAL),
		-- Musgo, cardenillo y enredaderas.
		p("Ellipsoid", v(0.36, 0.09, 0.32), v(-0.42, 0.43, 0.04), moss, nil, GRASS),
		p("Ellipsoid", v(0.2, 0.06, 0.2), v(0.02, 0.555, -0.02), moss, nil, GRASS),
		p("Ellipsoid", v(0.26, 0.07, 0.28), v(0.58, -0.08, -0.05), moss, nil, GRASS),
		fine(p("Ellipsoid", v(0.2, 0.18, 0.04), v(0.2, 0.26, -0.17), verdigris, v(0, -30, 0))),
		fine(p("Ellipsoid", v(0.18, 0.14, 0.04), v(-0.22, -0.02, -0.19), verdigris, v(0, 30, 0))),
		-- Flor en el hombro.
		fine(p("Cylinder", v(0.1, 0.015, 0.015), v(-0.46, 0.52, 0), moss, v(0, 0, 90))),
		fine(ball(0.06, v(-0.46, 0.58, 0), rgb(255, 220, 70))),
		-- Tubos de escape en la espalda.
		p("Cylinder", v(0.3, 0.08, 0.08), v(-0.14, 0.36, 0.26), darkBronze, v(0, 0, 90), METAL),
		p("Cylinder", v(0.3, 0.08, 0.08), v(0.14, 0.36, 0.26), darkBronze, v(0, 0, 90), METAL),
	}
	for i = 0, 3 do
		local angle = math.rad(45 + i * 90)
		add(list, fine(ball(0.05, v(-0.46 + math.cos(angle) * 0.045, 0.58, math.sin(angle) * 0.045), WHITE)))
	end
	tube(list, { v(-0.3, 0.36, -0.16), v(-0.27, 0.14, -0.25), v(-0.31, -0.04, -0.25) }, 0.016, 0.012, moss, nil, nil, true)
	-- Remaches alrededor del núcleo.
	for i = 0, 5 do
		local angle = math.rad(i * 60)
		add(list, fine(ball(0.035, v(math.cos(angle) * 0.17, 0.1 + math.sin(angle) * 0.17, -0.25), verdigris, METAL)))
	end
	for _, side in { -1, 1 } do
		-- Hombreras, brazos largos y puños enormes.
		add(list, ball(0.34, v(side * 0.42, 0.26, 0.02), bronze, METAL))
		add(list, p("Cylinder", v(0.05, 0.37, 0.37), v(side * 0.5, 0.26, 0.02), verdigris, nil, METAL))
		add(list, seg("Cylinder", v(side * 0.46, 0.2, 0.02), v(side * 0.56, -0.06, -0.02), 0.14, darkBronze, METAL))
		add(list, ball(0.19, v(side * 0.56, -0.06, -0.02), verdigris, METAL))
		add(list, p("Block", v(0.24, 0.32, 0.26), v(side * 0.58, -0.24, -0.06), bronze, nil, METAL))
		add(list, p("Block", v(0.28, 0.16, 0.3), v(side * 0.58, -0.42, -0.08), darkBronze, nil, METAL))
		for j = -1, 1 do
			add(list, fine(p("Block", v(0.07, 0.05, 0.04), v(side * 0.58 + j * 0.09, -0.42, -0.245), bronze, nil, METAL)))
		end
		-- Piernas cortas y pies anchos.
		add(list, p("Cylinder", v(0.14, 0.17, 0.17), v(side * 0.15, -0.38, 0.02), darkBronze, v(0, 0, 90), METAL))
		add(list, p("Block", v(0.24, 0.1, 0.34), v(side * 0.15, -0.455, -0.02), bronze, nil, METAL))
		add(list, fine(p("Cylinder", v(0.03, 0.1, 0.1), v(side * 0.14, 0.52, 0.26), verdigris, v(0, 0, 90), METAL)))
	end
	CritterArt.coloso_bronce = list
end

-- ============================== SECRETO ==============================

do -- Sombra de Péndulo: silueta encapuchada de sombra con ojos de luz, un reloj en el pecho y un péndulo que oscila.
	local shadow = rgb(20, 18, 30)
	local void = rgb(8, 7, 14)
	local gold = rgb(210, 165, 60)
	local light = rgb(235, 225, 255)
	local pivot = v(0, 0.0, -0.24)
	local list: Parts = {
		-- Capucha con su pico, hueco de la cara, hombros y manto que se deshace hacia abajo.
		p("Ellipsoid", v(0.44, 0.48, 0.44), v(0, 0.34, 0.02), shadow),
		p("Ellipsoid", v(0.16, 0.22, 0.24), v(0, 0.56, 0.14), shadow, v(40, 0, 0)),
		p("Ellipsoid", v(0.3, 0.34, 0.2), v(0, 0.31, -0.14), void),
		p("Ellipsoid", v(0.76, 0.3, 0.42), v(0, 0.1, 0.02), shadow),
		p("Ellipsoid", v(0.6, 0.44, 0.38), v(0, -0.1, 0.02), shadow),
		clear(p("Ellipsoid", v(0.46, 0.36, 0.32), v(0.02, -0.3, 0.03), shadow), 0.15),
		-- Reloj del pecho: aro de oro, esfera negra y agujas de luz.
		p("Cylinder", v(0.04, 0.27, 0.27), v(0, 0.02, -0.2), gold, v(0, 90, 0), METAL),
		p("Cylinder", v(0.045, 0.21, 0.21), v(0, 0.02, -0.205), void, v(0, 90, 0)),
		fine(p("Block", v(0.015, 0.09, 0.01), v(0.0, 0.055, -0.23), light, nil, NEON)),
		fine(p("Block", v(0.015, 0.07, 0.01), v(0.025, 0.0, -0.23), light, v(0, 0, 50), NEON)),
		-- Péndulo.
		hinged(p("Block", v(0.02, 0.36, 0.02), v(0, -0.2, -0.24), gold, nil, METAL), "Pendulo", pivot),
		hinged(p("Cylinder", v(0.04, 0.15, 0.15), v(0, -0.39, -0.24), gold, v(0, 90, 0), METAL), "Pendulo", pivot),
		hinged(ball(0.06, v(0, -0.39, -0.265), light, NEON), "Pendulo", pivot),
		-- Jirones de sombra que se desprenden.
		named(clear(ball(0.1, v(-0.3, -0.3, 0.1), shadow), 0.4), "Gota"),
		named(clear(ball(0.08, v(0.26, -0.2, 0.16), shadow), 0.4), "Gota"),
		named(clear(ball(0.07, v(0.05, -0.36, 0.2), shadow), 0.4), "Gota"),
	}
	-- Cola de humo.
	tube(list, { v(0.02, -0.38, 0.03), v(0.1, -0.45, 0.06), v(0.22, -0.47, 0.02), v(0.31, -0.42, -0.06) }, 0.1, 0.02, shadow)
	-- Las doce horas flotando detrás de la cabeza.
	for i = 0, 11 do
		local angle = math.rad(i * 30)
		local tick = p("Block", v(0.03, (i % 3 == 0) and 0.11 or 0.07, 0.02), v(math.sin(angle) * 0.38, 0.34 + math.cos(angle) * 0.38, 0.22), gold, v(0, 0, -i * 30), METAL)
		tick.fine = i % 3 ~= 0
		add(list, tick)
	end
	for _, side in { -1, 1 } do
		-- Brazos largos con dedos afilados.
		local elbow = v(side * 0.5, -0.14, -0.08)
		local hand = v(side * 0.46, -0.36, -0.16)
		add(list, seg("Ellipsoid", v(side * 0.32, 0.1, 0), elbow, 0.12, shadow, nil, 1.2))
		add(list, seg("Ellipsoid", elbow, hand, 0.085, shadow, nil, 1.2))
		for j = -1, 1 do
			add(list, seg("Cylinder", hand, v(side * 0.46 + j * 0.06, -0.49, -0.2 - math.abs(j) * 0.03), 0.026, void))
		end
	end
	glowEyes(list, 0.07, 0.33, -0.235, 0.07, light)
	CritterArt.sombra_pendulo = list
end

do -- Zorro de Tinta: zorro de tres colas hecho de humo oscuro y polvo de oro.
	local ink = rgb(22, 22, 38)
	local inkLight = rgb(50, 48, 82)
	local gold = rgb(255, 205, 80)
	local base = v(0, -0.2, 0.34)
	local list: Parts = {
		-- Sentado: cuartos traseros, pecho y pechera.
		ball(0.46, v(0, -0.26, 0.14), ink),
		p("Ellipsoid", v(0.36, 0.52, 0.36), v(0, -0.1, -0.1), ink, v(-10, 0, 0)),
		p("Ellipsoid", v(0.24, 0.3, 0.14), v(0, -0.06, -0.26), inkLight),
		-- Cabeza, hocico y trufa de oro.
		p("Ellipsoid", v(0.38, 0.32, 0.36), v(0, 0.27, -0.2), ink),
		p("Ellipsoid", v(0.16, 0.13, 0.26), v(0, 0.2, -0.42), ink),
		ball(0.06, v(0, 0.22, -0.55), gold, NEON),
		named(p("Block", v(0.06, 0.06, 0.02), v(0, 0.39, -0.335), gold, v(0, 0, 45), NEON), "Brillo"),
		-- Gotas de tinta y humo a ras de suelo.
		named(ball(0.06, v(0.2, 0.1, 0.5), ink), "Gota"),
		named(ball(0.05, v(-0.26, 0.2, 0.52), ink), "Gota"),
		fine(clear(ball(0.2, v(0.26, -0.42, 0.2), ink), 0.5)),
		fine(clear(ball(0.16, v(-0.28, -0.44, 0.1), ink), 0.5)),
		fine(clear(ball(0.14, v(0.0, -0.44, 0.42), ink), 0.5)),
	}
	-- Tres colas en abanico, con la punta de oro.
	for k = -1, 1 do
		local points = { base, base + v(k * 0.2, 0.2, 0.18), base + v(k * 0.42, 0.48, 0.24), base + v(k * 0.5, 0.74, 0.14), base + v(k * 0.44, 0.9, 0.02) }
		local widths = { 0.16, 0.24, 0.22, 0.14 }
		for i = 1, 4 do
			add(list, hinged(seg("Ellipsoid", points[i], points[i + 1], widths[i], (i == 3) and inkLight or ink, nil, 1.35), "Cola", base))
		end
		add(list, hinged(ball(0.09, points[5], gold, NEON), "Cola", base))
		add(list, fine(named(ball(0.035, points[3] + v(0.1, 0.06, -0.12), gold, NEON), "Brillo")))
		add(list, fine(named(ball(0.03, points[4] + v(-0.08, 0.02, -0.1), gold, NEON), "Brillo")))
	end
	for _, side in { -1, 1 } do
		-- Orejas con el interior dorado y mofletes de pelo.
		add(list, p("Ellipsoid", v(0.13, 0.34, 0.08), v(side * 0.13, 0.5, -0.16), ink, v(0, 0, side * -14)))
		add(list, p("Ellipsoid", v(0.06, 0.2, 0.04), v(side * 0.13, 0.49, -0.19), gold, v(0, 0, side * -14)))
		add(list, p("Ellipsoid", v(0.15, 0.14, 0.1), v(side * 0.18, 0.2, -0.24), inkLight, v(0, 0, side * 30)))
		-- Patas delanteras con la punta dorada y pies traseros.
		add(list, seg("Cylinder", v(side * 0.1, -0.2, -0.2), v(side * 0.1, -0.44, -0.24), 0.1, ink))
		add(list, ball(0.12, v(side * 0.1, -0.45, -0.26), ink))
		add(list, fine(p("Ellipsoid", v(0.1, 0.05, 0.08), v(side * 0.1, -0.47, -0.31), gold, nil, NEON)))
		add(list, p("Ellipsoid", v(0.14, 0.1, 0.28), v(side * 0.2, -0.45, 0.0), ink))
	end
	glowEyes(list, 0.1, 0.3, -0.365, 0.09, gold)
	CritterArt.zorro_tinta = list
end

do -- Caballero del Eclipse: armadura flotante vacía, con capa de sombra, halo de eclipse, escudo y espada de luz.
	local steel = rgb(44, 48, 68)
	local steelLight = rgb(84, 90, 120)
	local silver = rgb(215, 222, 240)
	local light = rgb(235, 240, 255)
	local cape = rgb(16, 14, 28)
	local void = rgb(8, 8, 14)
	local capeTop = v(0, 0.26, 0.16)
	local list: Parts = {
		-- Peto, abdomen, gorguera y cinturón.
		p("Block", v(0.46, 0.3, 0.3), v(0, 0.12, 0), steel, nil, METAL),
		p("Block", v(0.36, 0.2, 0.26), v(0, -0.08, 0), steelLight, nil, METAL),
		p("Block", v(0.5, 0.05, 0.32), v(0, 0.27, 0), silver, nil, METAL),
		p("Block", v(0.4, 0.06, 0.3), v(0, -0.19, 0), silver, nil, METAL),
		-- Emblema del eclipse en el pecho.
		named(p("Cylinder", v(0.03, 0.21, 0.21), v(0, 0.12, -0.155), light, v(0, 90, 0), NEON), "Brillo"),
		p("Cylinder", v(0.035, 0.155, 0.155), v(0, 0.12, -0.16), void, v(0, 90, 0)),
		-- Yelmo: casco, visor de luz, nasal y penacho de sombra.
		p("Ellipsoid", v(0.3, 0.34, 0.32), v(0, 0.46, 0), steelLight, nil, METAL),
		named(p("Block", v(0.2, 0.035, 0.04), v(0, 0.47, -0.15), light, nil, NEON), "Brillo"),
		p("Block", v(0.03, 0.2, 0.05), v(0, 0.43, -0.155), silver, nil, METAL),
		p("Ellipsoid", v(0.05, 0.22, 0.38), v(0, 0.62, 0.05), cape),
		-- Halo de eclipse detrás del yelmo.
		named(p("Cylinder", v(0.02, 0.58, 0.58), v(0, 0.5, 0.2), light, v(0, 90, 0), NEON), "Brillo"),
		p("Cylinder", v(0.02, 0.47, 0.47), v(0, 0.5, 0.188), void, v(0, 90, 0)),
		-- Faldar de tres placas.
		p("Block", v(0.15, 0.15, 0.04), v(0, -0.28, -0.14), steel, v(-12, 0, 0), METAL),
		p("Block", v(0.14, 0.14, 0.04), v(-0.16, -0.27, -0.11), steelLight, v(-12, 25, 0), METAL),
		p("Block", v(0.14, 0.14, 0.04), v(0.16, -0.27, -0.11), steelLight, v(-12, -25, 0), METAL),
		-- Capa de sombra, cada vez más deshecha hacia abajo.
		hinged(p("Block", v(0.56, 0.5, 0.03), v(0, 0.02, 0.2), cape, v(-8, 0, 0)), "Cola", capeTop),
		hinged(clear(p("Block", v(0.64, 0.3, 0.03), v(0, -0.34, 0.27), cape, v(-14, 0, 0)), 0.2), "Cola", capeTop),
		-- Espada de luz (guantelete derecho): hoja, filo, punta, guarda, empuñadura y pomo.
		shiny(p("Block", v(0.075, 0.62, 0.02), v(0.42, 0.43, -0.2), silver, nil, METAL), 0.4),
		named(p("Block", v(0.02, 0.6, 0.026), v(0.42, 0.43, -0.2), light, nil, NEON), "Brillo"),
		shiny(p("Block", v(0.053, 0.053, 0.02), v(0.42, 0.74, -0.2), silver, v(0, 0, 45), METAL), 0.4),
		p("Block", v(0.26, 0.04, 0.05), v(0.42, 0.1, -0.2), silver, nil, METAL),
		p("Cylinder", v(0.14, 0.04, 0.04), v(0.42, 0.02, -0.2), void, v(0, 0, 90)),
		ball(0.07, v(0.42, -0.07, -0.2), light, NEON),
		p("Block", v(0.13, 0.12, 0.14), v(0.42, 0.02, -0.2), steel, nil, METAL),
		fine(p("Block", v(0.15, 0.03, 0.16), v(0.42, -0.04, -0.2), silver, nil, METAL)),
		-- Escudo del eclipse (guantelete izquierdo).
		p("Block", v(0.12, 0.14, 0.13), v(-0.42, -0.04, -0.12), steel, nil, METAL),
		named(p("Cylinder", v(0.03, 0.4, 0.4), v(-0.44, 0.0, -0.215), light, v(0, 90, 0), NEON), "Brillo"),
		p("Cylinder", v(0.045, 0.34, 0.34), v(-0.44, 0.0, -0.22), steel, v(0, 90, 0), METAL),
		p("Cylinder", v(0.05, 0.12, 0.12), v(-0.44, 0.0, -0.225), void, v(0, 90, 0)),
	}
	for j = -2, 2 do
		if j ~= 0 then
			add(list, fine(hinged(clear(p("Block", v(0.1, 0.14, 0.02), v(j * 0.13, -0.5, 0.31), cape, v(-14, 0, j * 4)), 0.45), "Cola", capeTop)))
		end
	end
	for _, side in { -1, 1 } do
		-- Hombreras con borde de plata y púa.
		add(list, ball(0.27, v(side * 0.32, 0.24, 0), steelLight, METAL))
		add(list, p("Cylinder", v(0.03, 0.29, 0.29), v(side * 0.37, 0.24, 0), silver, nil, METAL))
		add(list, fine(p("Block", v(0.05, 0.14, 0.05), v(side * 0.36, 0.4, 0), silver, v(0, 0, side * -25), METAL)))
		-- Grebas y botas que flotan sueltas.
		add(list, p("Cylinder", v(0.13, 0.12, 0.12), v(side * 0.12, -0.42, 0), steel, v(0, 0, 90), METAL))
		add(list, p("Ellipsoid", v(0.13, 0.08, 0.22), v(side * 0.12, -0.5, -0.04), steelLight, nil, METAL))
		add(list, fine(p("Cylinder", v(0.03, 0.135, 0.135), v(side * 0.12, -0.36, 0), silver, v(0, 0, 90), METAL)))
	end
	CritterArt.caballero_eclipse = list
end

return CritterArt
