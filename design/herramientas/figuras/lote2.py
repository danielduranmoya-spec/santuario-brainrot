"""Bichos raros, épicos y legendarios (figura de juguete)."""
from fig import *
from lote1 import legs4


def quadruped(color, length=1.0, height=0.55, thick=0.26, neck=0.25, head=0.2, snout=0.18):
    """Cuerpo de cuadrúpedo realista: lomo, pecho, cuello y cabeza con hocico (mira a -Y)."""
    L = length
    return body([
        ((0, 0.05 * L, height), (thick, L * 0.42, thick * 0.95)),
        ((0, -0.32 * L, height + 0.02), (thick * 1.08, L * 0.2, thick * 1.05)),
        ((0, 0.32 * L, height + 0.02), (thick * 0.95, L * 0.18, thick * 0.95)),
        ((0, -0.55 * L, height + neck), (thick * 0.6, 0.14, neck * 0.6), (30, 0, 0)),
        ((0, -0.66 * L, height + neck + 0.12), (head, head * 1.1, head * 0.9)),
        ((0, -0.66 * L - head - snout * 0.5, height + neck + 0.06), (head * 0.55, snout, head * 0.5)),
    ], voxel=0.025)


class salamandra_chispa:
    ID, RARITY = "salamandra_chispa", (70, 140, 255)

    @staticmethod
    def build():
        dark, spot = (50, 40, 50), (255, 150, 40)
        piece("Cuerpo", [body([((0, 0, 0.22), (0.22, 0.6, 0.15)), ((0, -0.62, 0.26), (0.19, 0.22, 0.13)),
                               ((0, -0.82, 0.25), (0.15, 0.14, 0.1))])], dark)
        piece("Cola", [tube([(0, 0.5, 0.22), (0.15, 0.9, 0.17), (0.05, 1.3, 0.12), (-0.15, 1.55, 0.1)], 0.13, 0.02)], dark, pivot=(0, 0.5, 0.22))
        legs = []
        for s in (-1, 1):
            for y in (-0.35, 0.3):
                legs.append(tube([(s * 0.18, y, 0.2), (s * 0.36, y - 0.05, 0.18), (s * 0.4, y - 0.12, 0.02)], 0.06, 0.04))
                legs += [sph((s * 0.4 + k * 0.035, y - 0.17, 0.02), (0.02, 0.05, 0.015)) for k in (-1, 0, 1)]
        piece("Patas", legs, dark)
        rnd = __import__("random").Random(9)
        dots = [sph((rnd.uniform(-0.15, 0.15), rnd.uniform(-0.7, 0.5), 0.33 + rnd.uniform(-0.02, 0.02)), (0.05, 0.06, 0.02)) for _ in range(16)]
        piece("Brillo_Manchas", dots, spot, material="Neon")
        piece("Cresta", [cone((0, y, 0.38 - abs(y + 0.1) * 0.08), 0.04, 0.08 + 0.04 * (1 - abs(y)), rot=(0, 0, 0)) for y in (-0.6, -0.4, -0.2, 0, 0.2, 0.4)], (255, 90, 30), material="Neon", anim="Brillo")
        eyes((0, -0.82, 0.33), 0.1, 0.055, iris=(30, 20, 10))
        piece("Gota_Chispa", [sph((0.05, -1.0, 0.35), 0.03), sph((-0.08, -0.98, 0.42), 0.022)], (255, 220, 80), material="Neon", fine=True)


class planta_beatbox:
    ID, RARITY = "planta_beatbox", (70, 140, 255)

    @staticmethod
    def build():
        green, pink = (60, 170, 70), (250, 90, 110)
        piece("Maceta", [cyl((0, 0, 0.18), (0.32, 0.32), 0.18, subd=1), torus((0, 0, 0.36), 0.33, 0.04)], (200, 110, 70))
        piece("Tierra", [cyl((0, 0, 0.35), (0.3, 0.3), 0.02)], (90, 60, 40))
        piece("Tallo", [tube([(0, 0, 0.35), (0.06, -0.04, 0.7), (-0.03, -0.08, 1.0)], 0.06, 0.045)], green)
        piece("Hojas", [sph((s * 0.25, 0, 0.48), (0.25, 0.08, 0.03), rot=(0, s * -25, 0)) for s in (-1, 1)], green)
        # cabeza: dos mandíbulas tipo venus atrapamoscas
        piece("Cabeza", [body([((0, -0.15, 1.18), (0.32, 0.24, 0.14)), ((0, -0.2, 1.1), (0.28, 0.2, 0.08))])], green, pivot=(0, -0.05, 1.05))
        piece("Pinza_Boca", [sph((0, -0.17, 1.0), (0.28, 0.22, 0.09))], green, pivot=(0, -0.0, 1.05))
        piece("Interior", [sph((0, -0.2, 1.08), (0.25, 0.19, 0.05))], pink)
        teeth = [cone((math.sin(a) * 0.27, -0.2 - math.cos(a) * 0.2, 1.08), 0.022, 0.05, rot=(0, 0, 0)) for a in [i * 0.4 - 1.4 for i in range(8)]]
        piece("Dientes", teeth, (255, 255, 240), fine=True)
        piece("Gafas", [box((s * 0.12, -0.35, 1.25), (0.18, 0.03, 0.09)) for s in (-1, 1)] + [box((0, -0.35, 1.27), (0.08, 0.02, 0.02))], (20, 20, 25), keep=True)
        piece("Brillo_Gafas", [box((s * 0.12 - 0.04, -0.37, 1.27), (0.05, 0.01, 0.02)) for s in (-1, 1)], (255, 255, 255), material="Neon", keep=True, fine=True)
        piece("Notas", [sph((0.4, -0.3, 1.4), (0.05, 0.03, 0.04)), cyl((0.44, -0.3, 1.5), 0.01, 0.1)], (255, 220, 60), material="Neon", anim="Gota")


class golem_obsidiana:
    ID, RARITY = "golem_obsidiana", (170, 80, 255)

    @staticmethod
    def build():
        obs, obs2, lava = (40, 34, 48), (70, 60, 80), (255, 110, 25)
        rot = [(5, 3, 8), (-6, 4, -5), (8, -6, 3)]
        piece("Cuerpo", [box((0, 0, 1.1), (0.9, 0.6, 0.75), rot=(3, 0, 2), bevel=0.08), box((0, -0.05, 1.6), (0.5, 0.45, 0.35), rot=(-5, 4, 0), bevel=0.06)], obs)
        piece("Cabeza", [box((0, -0.1, 1.9), (0.36, 0.34, 0.3), rot=(4, -3, 2), bevel=0.05)], obs2)
        piece("Brillo_Nucleo", [sph((0, -0.31, 1.15), (0.14, 0.05, 0.14))], lava, material="Neon")
        piece("Brillo_Grietas", [tube([(0.2, -0.31, 1.35), (0.1, -0.32, 1.2), (0.25, -0.31, 0.9)], 0.018, 0.01),
                                 tube([(-0.25, -0.31, 1.3), (-0.12, -0.32, 1.15), (-0.3, -0.31, 0.85)], 0.018, 0.01)], lava, material="Neon")
        piece("Ojos", [box((s * 0.08, -0.28, 1.93), (0.07, 0.02, 0.035)) for s in (-1, 1)], (255, 160, 40), material="Neon", keep=True)
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            arm = [box((s * 0.6, 0, 1.3), (0.3, 0.32, 0.35), rot=rot[0], bevel=0.05), box((s * 0.66, -0.05, 0.95), (0.26, 0.28, 0.4), rot=rot[1], bevel=0.05),
                   box((s * 0.68, -0.1, 0.6), (0.36, 0.36, 0.3), rot=rot[2], bevel=0.06)]
            piece(f"Brazo_{side}", arm, obs2, anim="Pendulo", pivot=(s * 0.6, 0, 1.4))
            piece(f"Pierna_{side}", [box((s * 0.24, 0, 0.42), (0.32, 0.36, 0.5), rot=rot[(s + 1) // 2], bevel=0.05), box((s * 0.25, -0.06, 0.1), (0.36, 0.46, 0.2), bevel=0.05)], obs)
        crystals = [cone((x, 0.25, 1.75 + abs(x) * 0.3), 0.06, 0.18, rot=(-20, x * 60, 0)) for x in (-0.25, 0.0, 0.2)]
        piece("Cristales", crystals, (120, 90, 170), material="Glass")


class ajolote_chubasquero:
    ID, RARITY = "ajolote_chubasquero", (170, 80, 255)

    @staticmethod
    def build():
        pink, yellow, red = (255, 170, 200), (255, 215, 50), (230, 50, 50)
        piece("Cuerpo", [body([((0, 0, 0.75), (0.32, 0.28, 0.42))])], yellow)
        piece("Cabeza", [body([((0, -0.05, 1.3), (0.34, 0.3, 0.26))])], pink)
        piece("Capucha", [sph((0, 0.02, 1.36), (0.37, 0.33, 0.3)), cone((0, -0.18, 1.62), 0.32, 0.06, rot=(20, 0, 0))], yellow)
        gills = []
        for s in (-1, 1):
            for k, a in enumerate((20, 45, 70)):
                ang = math.radians(a)
                gills.append(tube([(s * 0.3, 0.0, 1.3), (s * (0.3 + math.cos(ang) * 0.2), 0.02, 1.3 + math.sin(ang) * 0.2),
                                   (s * (0.3 + math.cos(ang) * 0.3), 0.0, 1.3 + math.sin(ang) * 0.32)], 0.04, 0.02))
        piece("Branquias", gills, (255, 110, 160))
        eyes((0, -0.3, 1.32), 0.15, 0.05, white=None)
        piece("Boca", [torus((0, -0.33, 1.22), 0.06, 0.008, rot=(90, 0, 0))], (180, 60, 90), keep=True, fine=True)
        piece("Botones", [sph((0, -0.29, 0.95 - k * 0.15), 0.035) for k in range(3)], (60, 60, 70), fine=True)
        piece("Botas", [cyl((s * 0.15, -0.03, 0.15), 0.11, 0.15, subd=1) for s in (-1, 1)] + [sph((s * 0.15, -0.12, 0.05), (0.11, 0.14, 0.06)) for s in (-1, 1)], red)
        piece("Brazos", [tube([(s * 0.28, -0.05, 0.95), (s * 0.4, -0.12, 0.75), (s * 0.38, -0.2, 0.6)], 0.07, 0.05) for s in (-1, 1)], yellow)
        piece("Manos", [sph((s * 0.38, -0.22, 0.56), 0.06) for s in (-1, 1)], pink)
        piece("Cola", [tube([(0, 0.25, 0.4), (0, 0.5, 0.28), (0, 0.7, 0.2)], 0.1, 0.03)], pink, pivot=(0, 0.25, 0.4))
        piece("Paraguas", [cyl((0.45, -0.1, 1.2), 0.015, 0.5), cone((0.45, -0.1, 1.8), 0.4, 0.12, rot=(0, 0, 0)), torus((0.45, -0.12, 0.72), 0.05, 0.012, rot=(90, 0, 0))], (90, 160, 250))


class lobo_tormenta:
    ID, RARITY = "lobo_tormenta", (255, 190, 40)

    @staticmethod
    def build():
        fur, belly, cloud = (90, 100, 130), (170, 180, 200), (210, 215, 230)
        piece("Cuerpo", [quadruped(fur, length=1.3, height=0.72, thick=0.24, neck=0.3, head=0.2, snout=0.2)], fur)
        piece("Pecho", [body([((0, -0.52, 0.75), (0.2, 0.15, 0.25)), ((0, -1.05, 0.98), (0.09, 0.15, 0.05))], voxel=0.02)], belly)
        piece("Nariz", [sph((0, -1.32, 1.03), (0.045, 0.035, 0.035))], (25, 25, 30), keep=True)
        for s in (-1, 1):
            piece(f"Oreja_{'I' if s < 0 else 'D'}", [cone((s * 0.12, -0.82, 1.32), 0.08, 0.13, rot=(-10, s * 15, 0))], fur)
        eyes((0, -1.06, 1.12), 0.09, 0.035, iris=(120, 220, 255))
        legs4([((s * 0.16, y, 0.6), (s * 0.18, y + (0.05 if y > 0 else -0.02), 0.32), (s * 0.18, y - 0.03, 0.03)) for s in (-1, 1) for y in (-0.45, 0.4)], 0.075, 0.05, fur, paw=True)
        piece("Cola", [tube([(0, 0.55, 0.8), (0, 0.85, 0.72), (0, 1.1, 0.55), (0, 1.22, 0.42)], 0.11, 0.05)], fur, pivot=(0, 0.55, 0.8))
        # melena de nube de tormenta y rayos
        mane = [sph((x * 0.18, -0.7 + abs(x) * 0.05, 1.0 + (abs(x) % 2) * 0.08), 0.15) for x in (-1.5, -0.7, 0, 0.7, 1.5)]
        mane += [sph((x * 0.14, -0.55, 1.18), 0.13) for x in (-1, 0, 1)]
        piece("Melena", mane, cloud)
        bolts = []
        for x, y in ((0.2, -0.2), (-0.15, 0.25)):
            bolts.append(box((x, y, 1.12), (0.04, 0.03, 0.18), rot=(0, 25, 0)))
            bolts.append(box((x + 0.05, y, 0.98), (0.04, 0.03, 0.16), rot=(0, -25, 0)))
        piece("Brillo_Rayos", bolts, (255, 240, 90), material="Neon")


class dragon_algodon:
    ID, RARITY = "dragon_algodon", (255, 190, 40)
    WIDE = 1.6

    @staticmethod
    def build():
        pink, light, blue = (255, 170, 210), (255, 220, 240), (160, 210, 255)
        piece("Cuerpo", [body([((0, 0.1, 0.6), (0.3, 0.45, 0.32)), ((0, -0.35, 0.95), (0.16, 0.18, 0.28), (25, 0, 0)),
                               ((0, -0.5, 1.25), (0.2, 0.24, 0.17)), ((0, -0.72, 1.2), (0.12, 0.14, 0.09))])], pink)
        piece("Barriga", [body([((0, -0.15, 0.62), (0.2, 0.28, 0.26))], voxel=0.02)], light)
        piece("Cola", [tube([(0, 0.5, 0.5), (0.1, 0.85, 0.35), (-0.05, 1.15, 0.3), (0, 1.35, 0.42)], 0.16, 0.04), sph((0, 1.38, 0.45), 0.09)], pink, pivot=(0, 0.5, 0.5))
        horns = [cone((s * 0.1, -0.42, 1.45), 0.04, 0.1, rot=(-25, s * 15, 0)) for s in (-1, 1)]
        piece("Cuernos", horns, (255, 245, 220))
        eyes((0, -0.66, 1.3), 0.1, 0.05, iris=(90, 60, 150))
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            S = (s * 0.22, 0.05, 0.9)
            outline = [S, (s * 0.6, 0.0, 1.25), (s * 1.0, 0.05, 1.3), *lib.scallop((s * 1.0, 0.05, 1.3), (s * 0.85, 0.1, 0.85), 0.1, 3, (s * -1, 0, 0.3)),
                       (s * 0.85, 0.1, 0.85), *lib.scallop((s * 0.85, 0.1, 0.85), (s * 0.4, 0.15, 0.7), 0.08, 3, (s * -0.5, 0, 0.8)), (s * 0.4, 0.15, 0.7)]
            piece(f"Ala_{side}", [membrane(outline, 0.03, 0.05)], blue, pivot=S)
        clouds = [sph((x, y, z), r) for x, y, z, r in ((0, 0.1, 0.95, 0.13), (0.12, -0.1, 0.92, 0.1), (-0.12, 0.25, 0.9, 0.11), (0, 0.45, 0.8, 0.1), (0, -0.25, 1.15, 0.09))]
        piece("Nubes", clouds, (255, 255, 255))
        legs4([((s * 0.18, y, 0.45), (s * 0.22, y - 0.02, 0.22), (s * 0.22, y - 0.04, 0.03)) for s in (-1, 1) for y in (-0.15, 0.35)], 0.08, 0.055, pink, paw=True)


class garza_prisma:
    ID, RARITY = "garza_prisma", (255, 190, 40)
    WIDE = 1.5

    @staticmethod
    def build():
        white = (248, 248, 252)
        piece("Cuerpo", [body([((0, 0.05, 1.05), (0.2, 0.42, 0.24), (15, 0, 0)), ((0, 0.42, 1.0), (0.1, 0.22, 0.05), (-15, 0, 0))])], white)
        piece("Cuello", [tube([(0, -0.25, 1.15), (0, -0.4, 1.45), (0, -0.25, 1.7), (0, -0.35, 1.9)], 0.09, 0.06)], white)
        piece("Cabeza", [sph((0, -0.38, 1.95), (0.08, 0.11, 0.08))], white)
        piece("Pico", [cone((0, -0.6, 1.94), 0.03, 0.17, rot=(92, 0, 0))], (250, 200, 60))
        piece("Penacho", [tube([(0, -0.32, 2.0), (0, -0.15, 2.08), (0, 0.05, 2.02)], 0.015, 0.006)], (40, 40, 50), fine=True)
        eyes((0, -0.44, 1.97), 0.065, 0.022, white=None, iris=(30, 30, 30))
        legs = [tube([(s * 0.07, 0.05, 0.85), (s * 0.08, 0.1, 0.45), (s * 0.08, 0.02, 0.03)], 0.02, 0.016) for s in (-1, 1)]
        legs += [cone((s * 0.08 + k * 0.04, -0.05, 0.02), 0.012, 0.08, rot=(90, 0, k * 20)) for s in (-1, 1) for k in (-1, 0, 1)]
        piece("Patas", legs, (60, 60, 70))
        rainbow = [(255, 80, 80), (255, 170, 50), (250, 230, 70), (90, 210, 110), (80, 160, 255), (170, 110, 240)]
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            S = (s * 0.15, 0.0, 1.15)
            for i, c in enumerate(rainbow):
                feathers = [sph((s * (0.35 + i * 0.09), 0.05 + i * 0.05, 1.18 - i * 0.025), (0.2, 0.06, 0.02), rot=(0, s * (10 + i * 4), s * (-20 + i * 6)))]
                piece(f"Ala_{side}{i}", feathers, c, material="Glass" if i % 2 else "SmoothPlastic", anim="Ala", pivot=S)
        piece("Brillo_Prisma", [cone((0, 0.05, 1.32), 0.06, 0.08, rot=(0, 45, 0))], (220, 250, 255), material="Neon")


LOTE = [salamandra_chispa, planta_beatbox, golem_obsidiana, ajolote_chubasquero, lobo_tormenta, dragon_algodon, garza_prisma]
