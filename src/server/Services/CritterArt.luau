--!strict
-- Modelos low-poly de cada bicho, hechos con piezas simples (bolas, bloques, cilindros y elipsoides).
-- Así viven en el repo como código, Rojo los sincroniza y no dependen de modelos externos.
--
-- Cada pieza se describe en unidades del tamaño del bicho (1 = diámetro de su rareza en
-- Config/Gameplay.CritterSizes). El frente del bicho es -Z y el centro está en (0, 0, 0).
-- Para añadir un bicho nuevo: crea su entrada aquí con el mismo id que en Config/Critters.

export type Shape = "Ball" | "Block" | "Cylinder" | "Ellipsoid" | "Wedge"

export type PartSpec = {
	shape: Shape,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	rot: Vector3?, -- grados (X, Y, Z)
	material: Enum.Material?,
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(25, 25, 30)

local function p(shape: Shape, size: Vector3, pos: Vector3, color: Color3, rot: Vector3?, material: Enum.Material?): PartSpec
	return { shape = shape, size = size, pos = pos, color = color, rot = rot, material = material }
end

-- Ojos saltones: blanco + pupila mirando al frente.
local function eyes(list: { PartSpec }, spread: number, y: number, z: number, size: number)
	for _, side in { -1, 1 } do
		table.insert(list, p("Ball", Vector3.one * size, Vector3.new(side * spread, y, z), WHITE))
		table.insert(list, p("Ball", Vector3.one * size * 0.5, Vector3.new(side * spread, y, z - size * 0.38), BLACK))
	end
end

local CritterArt: { [string]: { PartSpec } } = {}

do -- Pez con Piernas: pez naranja de pie sobre dos piernecitas.
	local orange = Color3.fromRGB(255, 140, 40)
	local dark = Color3.fromRGB(220, 90, 30)
	local skin = Color3.fromRGB(255, 205, 150)
	local list = {
		p("Ellipsoid", Vector3.new(0.75, 0.6, 1.05), Vector3.new(0, 0.12, 0), orange),
		p("Block", Vector3.new(0.08, 0.42, 0.42), Vector3.new(0, 0.15, 0.62), dark, Vector3.new(45, 0, 0)),
		p("Block", Vector3.new(0.06, 0.22, 0.32), Vector3.new(0, 0.45, 0.05), dark, Vector3.new(20, 0, 0)),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Cylinder", Vector3.new(0.3, 0.09, 0.09), Vector3.new(side * 0.17, -0.3, 0), skin, Vector3.new(0, 0, 90)))
		table.insert(list, p("Block", Vector3.new(0.17, 0.06, 0.26), Vector3.new(side * 0.17, -0.46, -0.06), skin))
	end
	eyes(list, 0.2, 0.25, -0.38, 0.2)
	CritterArt.pez_con_piernas = list
end

do -- Cangrejo Tímido: cangrejo rojo con pinzas y ojos en antenas, mirando al suelo.
	local red = Color3.fromRGB(230, 60, 50)
	local dark = Color3.fromRGB(180, 40, 40)
	local list = {
		p("Ellipsoid", Vector3.new(1.05, 0.42, 0.8), Vector3.new(0, -0.1, 0), red),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Ellipsoid", Vector3.new(0.3, 0.24, 0.36), Vector3.new(side * 0.55, 0.02, -0.35), dark))
		table.insert(list, p("Block", Vector3.new(0.34, 0.06, 0.06), Vector3.new(side * 0.55, -0.3, 0), dark, Vector3.new(0, 0, side * 30)))
		table.insert(list, p("Block", Vector3.new(0.34, 0.06, 0.06), Vector3.new(side * 0.5, -0.3, 0.25), dark, Vector3.new(0, 0, side * 30)))
		table.insert(list, p("Cylinder", Vector3.new(0.22, 0.05, 0.05), Vector3.new(side * 0.15, 0.18, -0.22), dark, Vector3.new(0, 0, 90)))
	end
	eyes(list, 0.15, 0.33, -0.22, 0.17)
	CritterArt.cangrejo_timido = list
end

do -- Tostada Voladora: rebanada de pan con alas.
	local crust = Color3.fromRGB(175, 105, 45)
	local crumb = Color3.fromRGB(245, 210, 145)
	local list = {
		p("Block", Vector3.new(0.82, 0.78, 0.2), Vector3.new(0, -0.02, 0), crust),
		p("Ellipsoid", Vector3.new(0.9, 0.4, 0.2), Vector3.new(0, 0.38, 0), crust),
		p("Block", Vector3.new(0.7, 0.66, 0.22), Vector3.new(0, -0.04, 0), crumb),
		p("Ellipsoid", Vector3.new(0.76, 0.3, 0.22), Vector3.new(0, 0.34, 0), crumb),
		p("Block", Vector3.new(0.2, 0.04, 0.02), Vector3.new(0, -0.14, -0.12), BLACK),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Ellipsoid", Vector3.new(0.6, 0.07, 0.34), Vector3.new(side * 0.62, 0.22, 0.08), WHITE, Vector3.new(0, 0, side * 25)))
	end
	eyes(list, 0.17, 0.14, -0.12, 0.18)
	CritterArt.tostada_voladora = list
end

do -- Seta Cantante: seta fucsia con lunares, boca abierta cantando.
	local cap = Color3.fromRGB(225, 50, 150)
	local stem = Color3.fromRGB(250, 240, 220)
	local list = {
		p("Cylinder", Vector3.new(0.55, 0.42, 0.42), Vector3.new(0, -0.22, 0), stem, Vector3.new(0, 0, 90)),
		p("Ellipsoid", Vector3.new(1, 0.5, 1), Vector3.new(0, 0.2, 0), cap),
		p("Ball", Vector3.one * 0.15, Vector3.new(0.25, 0.38, -0.22), WHITE),
		p("Ball", Vector3.one * 0.13, Vector3.new(-0.3, 0.35, -0.02), WHITE),
		p("Ball", Vector3.one * 0.14, Vector3.new(0.05, 0.44, 0.24), WHITE),
		p("Ball", Vector3.one * 0.11, Vector3.new(0, -0.33, -0.19), BLACK),
	}
	eyes(list, 0.1, -0.15, -0.19, 0.14)
	CritterArt.seta_cantante = list
end

do -- Cactus Estornudo: cactus en maceta con brazos y una flor.
	local green = Color3.fromRGB(60, 175, 75)
	local pot = Color3.fromRGB(200, 100, 60)
	local list = {
		p("Block", Vector3.new(0.5, 0.18, 0.5), Vector3.new(0, -0.42, 0), pot),
		p("Cylinder", Vector3.new(0.75, 0.4, 0.4), Vector3.new(0, -0.02, 0), green, Vector3.new(0, 0, 90)),
		p("Ball", Vector3.one * 0.4, Vector3.new(0, 0.35, 0), green),
		p("Ball", Vector3.one * 0.16, Vector3.new(0, 0.57, 0), Color3.fromRGB(255, 120, 180)),
		p("Ball", Vector3.one * 0.08, Vector3.new(0, 0.08, -0.21), Color3.fromRGB(40, 120, 50)),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Cylinder", Vector3.new(0.22, 0.16, 0.16), Vector3.new(side * 0.3, -0.02, 0), green))
		table.insert(list, p("Cylinder", Vector3.new(0.28, 0.16, 0.16), Vector3.new(side * 0.41, 0.1, 0), green, Vector3.new(0, 0, 90)))
	end
	eyes(list, 0.1, 0.2, -0.2, 0.13)
	CritterArt.cactus_estornudo = list
end

do -- Roca con Bigote: roca facetada con un bigote elegante y cejas pobladas.
	local stone = Color3.fromRGB(125, 125, 140)
	local light = Color3.fromRGB(160, 160, 175)
	local list = {
		p("Block", Vector3.new(0.9, 0.68, 0.8), Vector3.new(0, -0.12, 0), stone, nil, Enum.Material.Slate),
		p("Block", Vector3.new(0.6, 0.26, 0.55), Vector3.new(0.05, 0.3, 0.05), light, Vector3.new(0, 20, 8), Enum.Material.Slate),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Ellipsoid", Vector3.new(0.34, 0.11, 0.08), Vector3.new(side * 0.16, -0.06, -0.42), BLACK, Vector3.new(0, 0, side * -15)))
		table.insert(list, p("Block", Vector3.new(0.2, 0.06, 0.05), Vector3.new(side * 0.17, 0.27, -0.41), BLACK, Vector3.new(0, 0, side * 10)))
	end
	eyes(list, 0.17, 0.14, -0.41, 0.16)
	CritterArt.roca_con_bigote = list
end

do -- Nube Gruñona: nube esponjosa con el ceño fruncido.
	local cloud = Color3.fromRGB(245, 245, 255)
	local list = {
		p("Ball", Vector3.one * 0.62, Vector3.new(0, 0.02, 0), cloud),
		p("Ball", Vector3.one * 0.45, Vector3.new(-0.36, -0.06, 0.04), cloud),
		p("Ball", Vector3.one * 0.45, Vector3.new(0.36, -0.06, 0.04), cloud),
		p("Ball", Vector3.one * 0.4, Vector3.new(0.12, 0.3, 0.08), cloud),
		p("Ball", Vector3.one * 0.34, Vector3.new(-0.18, 0.26, 0.06), cloud),
		p("Block", Vector3.new(0.16, 0.03, 0.03), Vector3.new(0, -0.12, -0.31), BLACK),
	}
	for _, side in { -1, 1 } do
		table.insert(list, p("Block", Vector3.new(0.17, 0.04, 0.04), Vector3.new(side * 0.13, 0.21, -0.3), BLACK, Vector3.new(0, 0, side * -22)))
	end
	eyes(list, 0.13, 0.08, -0.29, 0.15)
	CritterArt.nube_grunona = list
end

return CritterArt
