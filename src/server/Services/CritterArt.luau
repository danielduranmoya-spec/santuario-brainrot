--!strict
-- Modelos low-poly de cada bicho (versión 2, más detallada), hechos con piezas simples
-- (bolas, bloques, cilindros y elipsoides). Viven en el repo como código y Rojo los sincroniza.
--
-- Cada pieza se describe en unidades del tamaño del bicho (1 = diámetro de su rareza en
-- Config/Gameplay.CritterSizes). El frente del bicho es -Z y el centro está en (0, 0, 0).
-- Las piezas con nombre se animan en el cliente (client/CritterAnimator):
--   "Parpado" (párpado: aparece un instante al parpadear), "Ala" (aletea), "Cola" (se balancea),
--   "Pinza" (se abre y cierra), "Gota" (gota que cae, para el estornudo y la lluvia).
-- Para añadir un bicho nuevo: crea su entrada aquí con el mismo id que en Config/Critters.

export type Shape = "Ball" | "Block" | "Cylinder" | "Ellipsoid" | "Wedge"

export type PartSpec = {
	shape: Shape,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	rot: Vector3?, -- grados (X, Y, Z)
	material: Enum.Material?,
	name: string?,
	transparency: number?,
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(25, 25, 30)
local BLUSH = Color3.fromRGB(255, 140, 160)

local function p(shape: Shape, size: Vector3, pos: Vector3, color: Color3, rot: Vector3?, material: Enum.Material?): PartSpec
	return { shape = shape, size = size, pos = pos, color = color, rot = rot, material = material }
end

local function named(spec: PartSpec, name: string, transparency: number?): PartSpec
	spec.name = name
	spec.transparency = transparency
	return spec
end

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- Ojos: blanco, pupila, brillo y un párpado del color de la piel (invisible hasta que parpadea).
local function eyes(list: { PartSpec }, spread: number, y: number, z: number, size: number, lidColor: Color3)
	for _, side in { -1, 1 } do
		local center = v(side * spread, y, z)
		table.insert(list, p("Ball", Vector3.one * size, center, WHITE))
		table.insert(list, p("Ball", Vector3.one * size * 0.55, center + v(0, -size * 0.05, -size * 0.3), BLACK))
		table.insert(list, p("Ball", Vector3.one * size * 0.18, center + v(side * size * 0.12, size * 0.12, -size * 0.48), WHITE))
		table.insert(list, named(p("Ball", Vector3.one * size * 1.08, center, lidColor), "Parpado", 1))
	end
end

-- Mofletes rosados.
local function cheeks(list: { PartSpec }, spread: number, y: number, z: number, size: number)
	for _, side in { -1, 1 } do
		table.insert(list, p("Ellipsoid", v(size, size * 0.6, size * 0.3), v(side * spread, y, z), BLUSH))
	end
end

local CritterArt: { [string]: { PartSpec } } = {}

do -- Pez con Piernas: pez naranja a rayas, de pie con zapatillas.
	local orange = Color3.fromRGB(255, 140, 40)
	local stripe = Color3.fromRGB(235, 95, 30)
	local belly = Color3.fromRGB(255, 225, 170)
	local skin = Color3.fromRGB(255, 205, 160)
	local list = {
		p("Ellipsoid", v(0.78, 0.62, 1.0), v(0, 0.12, -0.02), orange),
		p("Ellipsoid", v(0.6, 0.42, 0.78), v(0, 0.02, -0.08), belly),
		p("Ellipsoid", v(0.8, 0.64, 0.1), v(0, 0.12, 0.14), stripe),
		p("Ellipsoid", v(0.66, 0.52, 0.1), v(0, 0.13, 0.32), stripe),
		p("Block", v(0.05, 0.26, 0.42), v(0, 0.47, 0.05), stripe, v(15, 0, 0)),
		p("Ellipsoid", v(0.26, 0.11, 0.09), v(0, 0.04, -0.5), Color3.fromRGB(255, 120, 140)),
		named(p("Block", v(0.06, 0.36, 0.24), v(0, 0.27, 0.6), stripe, v(-35, 0, 0)), "Cola"),
		named(p("Block", v(0.06, 0.36, 0.24), v(0, 0.0, 0.6), stripe, v(35, 0, 0)), "Cola"),
	}
	for _, side in { -1, 1 } do
		table.insert(list, named(p("Ellipsoid", v(0.05, 0.16, 0.26), v(side * 0.39, 0.06, 0.05), stripe, v(0, side * 20, 0)), "Ala"))
		table.insert(list, p("Cylinder", v(0.28, 0.09, 0.09), v(side * 0.16, -0.3, 0), skin, v(0, 0, 90)))
		table.insert(list, p("Ellipsoid", v(0.17, 0.11, 0.28), v(side * 0.16, -0.45, -0.05), WHITE))
		table.insert(list, p("Block", v(0.17, 0.03, 0.27), v(side * 0.16, -0.5, -0.05), Color3.fromRGB(220, 50, 50)))
	end
	eyes(list, 0.2, 0.26, -0.36, 0.21, orange)
	CritterArt.pez_con_piernas = list
end

do -- Cangrejo Tímido: cangrejo rojo con caparazón moteado, pinzas abiertas y mofletes sonrojados.
	local red = Color3.fromRGB(230, 60, 50)
	local shell = Color3.fromRGB(245, 95, 70)
	local dark = Color3.fromRGB(175, 35, 35)
	local list = {
		p("Ellipsoid", v(1.05, 0.44, 0.82), v(0, -0.1, 0), red),
		p("Ellipsoid", v(0.82, 0.3, 0.62), v(0, 0.02, 0.04), shell),
		p("Ball", Vector3.one * 0.1, v(0.18, 0.13, 0.15), dark),
		p("Ball", Vector3.one * 0.08, v(-0.2, 0.12, 0.05), dark),
		p("Ball", Vector3.one * 0.07, v(0.0, 0.16, 0.25), dark),
		p("Block", v(0.14, 0.03, 0.02), v(0, -0.12, -0.41), BLACK),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Cylinder", v(0.22, 0.08, 0.08), v(side * 0.48, -0.06, -0.25), dark, v(0, side * 40, 0)))
		table.insert(list, p("Ellipsoid", v(0.3, 0.22, 0.34), v(side * 0.58, 0.02, -0.4), red))
		table.insert(list, named(p("Ellipsoid", v(0.22, 0.09, 0.26), v(side * 0.58, 0.14, -0.5), red, v(-20, 0, 0)), "Pinza"))
		for i = 0, 2 do
			table.insert(list, p("Block", v(0.32, 0.055, 0.055), v(side * 0.52, -0.3, -0.05 + i * 0.18), dark, v(0, side * (i - 1) * 15, side * 35)))
		end
		table.insert(list, p("Cylinder", v(0.22, 0.05, 0.05), v(side * 0.15, 0.18, -0.24), dark, v(0, 0, 90)))
	end
	cheeks(list, 0.3, -0.06, -0.38, 0.14)
	eyes(list, 0.15, 0.33, -0.24, 0.17, red)
	CritterArt.cangrejo_timido = list
end

do -- Tostada Voladora: rebanada tostadita con mantequilla, alas de plumas y sonrisa.
	local crust = Color3.fromRGB(175, 105, 45)
	local crumb = Color3.fromRGB(245, 210, 145)
	local toasted = Color3.fromRGB(215, 150, 75)
	local list = {
		p("Block", v(0.82, 0.78, 0.2), v(0, -0.02, 0), crust),
		p("Ellipsoid", v(0.9, 0.42, 0.2), v(0, 0.38, 0), crust),
		p("Block", v(0.7, 0.66, 0.22), v(0, -0.04, 0), crumb),
		p("Ellipsoid", v(0.76, 0.3, 0.22), v(0, 0.34, 0), crumb),
		p("Ellipsoid", v(0.5, 0.4, 0.23), v(0.05, 0.02, 0), toasted),
		p("Block", v(0.26, 0.05, 0.2), v(0.12, 0.38, -0.02), Color3.fromRGB(255, 235, 120), v(0, 0, 10)),
		p("Ball", Vector3.one * 0.05, v(-0.22, -0.25, -0.115), crust),
		p("Ball", Vector3.one * 0.04, v(0.25, -0.3, -0.115), crust),
		p("Block", v(0.08, 0.03, 0.02), v(-0.06, -0.15, -0.12), BLACK, v(0, 0, -25)),
		p("Block", v(0.08, 0.03, 0.02), v(0.06, -0.15, -0.12), BLACK, v(0, 0, 25)),
	}
	for _, side in { -1, 1 } do
		for i = 0, 2 do
			table.insert(list, named(p("Ellipsoid", v(0.5 - i * 0.1, 0.07, 0.2), v(side * (0.55 + i * 0.03), 0.28 - i * 0.12, 0.08), WHITE, v(0, 0, side * (25 - i * 15))), "Ala"))
		end
	end
	cheeks(list, 0.25, -0.08, -0.12, 0.12)
	eyes(list, 0.17, 0.12, -0.12, 0.18, crumb)
	CritterArt.tostada_voladora = list
end

do -- Seta Cantante: seta fucsia con lunares, láminas bajo el sombrero, faldita y boca cantando.
	local cap = Color3.fromRGB(225, 50, 150)
	local capDark = Color3.fromRGB(185, 35, 120)
	local stem = Color3.fromRGB(250, 240, 220)
	local list = {
		p("Cylinder", v(0.55, 0.42, 0.42), v(0, -0.22, 0), stem, v(0, 0, 90)),
		p("Cylinder", v(0.06, 0.56, 0.56), v(0, -0.03, 0), Color3.fromRGB(235, 220, 200), v(0, 0, 90)),
		p("Ellipsoid", v(0.96, 0.22, 0.96), v(0, 0.1, 0), Color3.fromRGB(255, 205, 225)),
		p("Ellipsoid", v(1.02, 0.5, 1.02), v(0, 0.22, 0), cap),
		p("Ellipsoid", v(0.6, 0.2, 0.6), v(0, 0.43, 0), capDark),
		p("Ball", Vector3.one * 0.16, v(0.27, 0.38, -0.22), WHITE),
		p("Ball", Vector3.one * 0.13, v(-0.32, 0.35, -0.04), WHITE),
		p("Ball", Vector3.one * 0.15, v(0.05, 0.46, 0.24), WHITE),
		p("Ball", Vector3.one * 0.1, v(-0.12, 0.42, -0.3), WHITE),
		p("Ball", Vector3.one * 0.11, v(0.35, 0.34, 0.15), WHITE),
		p("Ellipsoid", v(0.13, 0.15, 0.06), v(0, -0.32, -0.2), BLACK),
		p("Ellipsoid", v(0.08, 0.05, 0.04), v(0, -0.36, -0.21), Color3.fromRGB(255, 110, 130)),
		p("Ellipsoid", v(0.16, 0.08, 0.2), v(-0.12, -0.5, -0.05), stem),
		p("Ellipsoid", v(0.16, 0.08, 0.2), v(0.12, -0.5, -0.05), stem),
		named(p("Block", v(0.06, 0.16, 0.03), v(0.38, 0.0, -0.28), BLACK, v(0, 0, 10)), "Cola"),
		named(p("Ball", Vector3.one * 0.09, v(0.35, -0.08, -0.28), BLACK), "Cola"),
	}
	cheeks(list, 0.15, -0.24, -0.19, 0.1)
	eyes(list, 0.1, -0.14, -0.19, 0.14, stem)
	CritterArt.seta_cantante = list
end

do -- Cactus Estornudo: cactus acanalado en maceta, con espinas, flor y una gota de estornudo.
	local green = Color3.fromRGB(60, 175, 75)
	local ridge = Color3.fromRGB(40, 140, 60)
	local pot = Color3.fromRGB(205, 105, 60)
	local list = {
		p("Cylinder", v(0.22, 0.52, 0.52), v(0, -0.4, 0), pot, v(0, 0, 90)),
		p("Cylinder", v(0.07, 0.6, 0.6), v(0, -0.28, 0), Color3.fromRGB(225, 125, 75), v(0, 0, 90)),
		p("Cylinder", v(0.03, 0.5, 0.5), v(0, -0.24, 0), Color3.fromRGB(100, 70, 45), v(0, 0, 90)),
		p("Cylinder", v(0.72, 0.42, 0.42), v(0, 0.08, 0), green, v(0, 0, 90)),
		p("Ball", Vector3.one * 0.42, v(0, 0.43, 0), green),
		p("Ball", Vector3.one * 0.07, v(0, 0.13, -0.24), Color3.fromRGB(40, 120, 50)),
		named(p("Ball", Vector3.one * 0.07, v(0, 0.05, -0.26), Color3.fromRGB(150, 210, 255), nil, Enum.Material.Glass), "Gota"),
	}
	for i = 0, 3 do
		local angle = math.rad(45 + i * 90)
		table.insert(list, p("Block", v(0.04, 0.68, 0.04), v(math.cos(angle) * 0.2, 0.1, math.sin(angle) * 0.2), ridge))
		table.insert(list, p("Block", v(0.02, 0.06, 0.02), v(math.cos(angle) * 0.23, 0.25, math.sin(angle) * 0.23), WHITE))
	end
	for _, side in { -1, 1 } do
		table.insert(list, p("Cylinder", v(0.2, 0.16, 0.16), v(side * 0.29, 0.06, 0), green))
		table.insert(list, p("Cylinder", v(0.26, 0.16, 0.16), v(side * 0.4, 0.17, 0), green, v(0, 0, 90)))
		table.insert(list, p("Ball", Vector3.one * 0.16, v(side * 0.4, 0.3, 0), green))
	end
	for i = 0, 4 do
		local angle = math.rad(i * 72)
		table.insert(list, p("Ellipsoid", v(0.1, 0.05, 0.1), v(math.cos(angle) * 0.07, 0.66, math.sin(angle) * 0.07), Color3.fromRGB(255, 120, 180)))
	end
	table.insert(list, p("Ball", Vector3.one * 0.07, v(0, 0.68, 0), Color3.fromRGB(255, 220, 60)))
	eyes(list, 0.1, 0.26, -0.19, 0.13, green)
	CritterArt.cactus_estornudo = list
end

do -- Roca con Bigote: roca facetada con musgo, sombrero de copa, monóculo y bigote rizado.
	local stone = Color3.fromRGB(125, 125, 140)
	local light = Color3.fromRGB(160, 160, 175)
	local moss = Color3.fromRGB(90, 160, 70)
	local gold = Color3.fromRGB(255, 200, 40)
	local list = {
		p("Block", v(0.9, 0.66, 0.8), v(0, -0.14, 0), stone, nil, Enum.Material.Slate),
		p("Block", v(0.62, 0.3, 0.6), v(0.04, 0.24, 0.03), light, v(0, 20, 6), Enum.Material.Slate),
		p("Block", v(0.4, 0.4, 0.4), v(-0.36, -0.22, 0.2), stone, v(30, 40, 10), Enum.Material.Slate),
		p("Block", v(0.3, 0.3, 0.3), v(0.38, -0.3, 0.25), light, v(10, 25, 35), Enum.Material.Slate),
		p("Ellipsoid", v(0.35, 0.06, 0.3), v(-0.15, 0.39, 0.12), moss, nil, Enum.Material.Grass),
		p("Cylinder", v(0.04, 0.5, 0.5), v(0.04, 0.42, 0.02), BLACK, v(0, 0, 90)),
		p("Cylinder", v(0.3, 0.3, 0.3), v(0.04, 0.58, 0.02), BLACK, v(0, 0, 90)),
		p("Cylinder", v(0.06, 0.31, 0.31), v(0.04, 0.48, 0.02), Color3.fromRGB(170, 40, 60), v(0, 0, 90)),
		p("Cylinder", v(0.02, 0.22, 0.22), v(0.17, 0.14, -0.42), gold, v(0, 90, 0)),
		p("Cylinder", v(0.01, 0.19, 0.19), v(0.17, 0.14, -0.43), Color3.fromRGB(200, 230, 255), v(0, 90, 0), Enum.Material.Glass),
		p("Cylinder", v(0.3, 0.015, 0.015), v(0.27, 0.0, -0.42), gold, v(0, 0, 90)),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Ellipsoid", v(0.34, 0.11, 0.08), v(side * 0.16, -0.08, -0.43), BLACK, v(0, 0, side * -15)))
		table.insert(list, p("Ball", Vector3.one * 0.09, v(side * 0.33, -0.02, -0.43), BLACK))
		table.insert(list, p("Block", v(0.2, 0.06, 0.05), v(side * 0.17, 0.27, -0.41), BLACK, v(0, 0, side * 10)))
	end
	eyes(list, 0.17, 0.14, -0.41, 0.16, stone)
	CritterArt.roca_con_bigote = list
end

do -- Nube Gruñona: nube esponjosa con panza gris, rayo y gotas de lluvia, con el ceño fruncido.
	local cloud = Color3.fromRGB(228, 232, 245) -- algo gris para que no se queme con el brillo
	local shade = Color3.fromRGB(170, 175, 200)
	local list = {
		p("Ball", Vector3.one * 0.62, v(0, 0.04, 0), cloud),
		p("Ball", Vector3.one * 0.46, v(-0.36, -0.04, 0.04), cloud),
		p("Ball", Vector3.one * 0.46, v(0.36, -0.04, 0.04), cloud),
		p("Ball", Vector3.one * 0.42, v(0.13, 0.31, 0.08), cloud),
		p("Ball", Vector3.one * 0.36, v(-0.19, 0.27, 0.06), cloud),
		p("Ball", Vector3.one * 0.3, v(0.0, 0.1, 0.32), cloud),
		p("Ellipsoid", v(0.95, 0.22, 0.55), v(0, -0.22, 0.04), shade),
		p("Block", v(0.16, 0.03, 0.03), v(0, -0.11, -0.32), BLACK),
		p("Block", v(0.06, 0.18, 0.03), v(0.22, -0.4, -0.05), Color3.fromRGB(255, 220, 40), v(0, 0, 20), Enum.Material.Neon),
		p("Block", v(0.06, 0.18, 0.03), v(0.27, -0.55, -0.05), Color3.fromRGB(255, 220, 40), v(0, 0, -25), Enum.Material.Neon),
		named(p("Ball", Vector3.one * 0.07, v(-0.2, -0.42, 0), Color3.fromRGB(120, 180, 255), nil, Enum.Material.Glass), "Gota"),
		named(p("Ball", Vector3.one * 0.06, v(-0.05, -0.47, 0.1), Color3.fromRGB(120, 180, 255), nil, Enum.Material.Glass), "Gota"),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Block", v(0.17, 0.045, 0.04), v(side * 0.13, 0.22, -0.31), BLACK, v(0, 0, side * -22)))
	end
	eyes(list, 0.13, 0.09, -0.29, 0.15, cloud)
	CritterArt.nube_grunona = list
end

return CritterArt
