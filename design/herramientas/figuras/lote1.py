"""Bichos comunes y poco comunes (figura de juguete, proporciones de animal real)."""
from fig import *


def legs4(pts, r0, r1, color, name="Patas", paw=None):
    """Patas: cada una es (cadera, rodilla, pie)."""
    objs = []
    for hip, knee, foot in pts:
        objs.append(tube([hip, knee, foot], r0, r1))
        if paw:
            objs.append(sph((foot[0], foot[1] - 0.03, foot[2] - 0.01), (r1 * 1.5, r1 * 2.0, r1 * 0.9)))
    piece(name, objs, color)


class caracol_turbo:
    ID, RARITY = "caracol_turbo", (200, 200, 200)

    @staticmethod
    def build():
        foot = (226, 200, 150)
        piece("Cuerpo", [body([((0, -0.2, 0.18), (0.32, 1.05, 0.18)), ((0, -0.95, 0.42), (0.2, 0.22, 0.3)),
                               ((0, -1.08, 0.7), (0.16, 0.16, 0.16))])], foot)
        for s in (-1, 1):
            piece(f"Antena_{'I' if s < 0 else 'D'}", [tube([(s * 0.06, -1.1, 0.8), (s * 0.14, -1.18, 1.08), (s * 0.2, -1.2, 1.3)], 0.025, 0.018),
                                                       sph((s * 0.2, -1.2, 1.32), 0.06)], foot, anim="Cola", pivot=(s * 0.06, -1.1, 0.8))
        eyes((0, -1.22, 0.74), 0.08, 0.06, white=(250, 250, 246))
        # concha turbo: espiral de anillos azules y rojos
        shell = []
        for i in range(9):
            t = i / 8
            ang = t * math.pi * 2.6
            r = 0.55 * (1 - t * 0.75)
            c = (0, 0.25 + math.cos(ang) * 0.36 * (1 - t), 0.72 + math.sin(ang) * 0.36 * (1 - t))
            shell.append(torus(c, r, r * 0.38, rot=(0, 90, 0)))
        piece("Concha", shell[::2], (60, 140, 230))
        piece("ConchaRaya", shell[1::2], (230, 70, 70))
        piece("Tobera", [cyl((0, 0.85, 0.55), 0.11, 0.16, rot=(90, 0, 0)), torus((0, 0.99, 0.55), 0.11, 0.03, rot=(90, 0, 0))], (150, 150, 160), material="Metal")
        piece("Brillo_Fuego", [cone((0, 1.18, 0.55), 0.09, 0.2, rot=(-90, 0, 0))], (255, 170, 40), material="Neon")
        piece("Gafas", [torus((s * 0.09, -1.27, 0.76), 0.07, 0.018, rot=(90, 0, 0)) for s in (-1, 1)] +
              [torus((0, -1.12, 0.78), 0.19, 0.012, rot=(0, 0, 0))], (60, 60, 70), keep=True)


class estrella_ninja:
    ID, RARITY = "estrella_ninja", (200, 200, 200)
    YAW = -20

    @staticmethod
    def build():
        orange = (245, 130, 60)
        arms = []
        for k in range(5):
            a = math.radians(90 + k * 72)
            tip = (math.cos(a) * 0.95, 0, 0.52 + math.sin(a) * 0.95)
            for t, rr in ((0.35, 0.2), (0.55, 0.16), (0.75, 0.12), (0.92, 0.085)):
                arms.append(((math.cos(a) * t, 0, 0.52 + math.sin(a) * t), (rr, rr * 0.8, rr)))
        piece("Cuerpo", [body([((0, 0, 0.52), (0.36, 0.2, 0.36))] + arms, voxel=0.025)], orange)
        dots = []
        for k in range(5):
            a = math.radians(90 + k * 72)
            for d in (0.42, 0.66):
                dots.append(sph((math.cos(a) * d, -0.17, 0.52 + math.sin(a) * d), 0.035))
        piece("Motas", dots, (255, 220, 160), fine=True)
        piece("Cinta", [torus((0, 0.0, 0.62), 0.3, 0.05, rot=(90, 0, 0))], (220, 40, 50))
        piece("Cola_Nudo", [tube([(0.28, 0.1, 0.65), (0.5, 0.2, 0.7), (0.66, 0.25, 0.6)], 0.035, 0.015),
                            tube([(0.28, 0.1, 0.62), (0.48, 0.25, 0.5), (0.58, 0.3, 0.38)], 0.035, 0.015)], (220, 40, 50), pivot=(0.28, 0.1, 0.63))
        eyes((0, -0.24, 0.55), 0.11, 0.07)
        piece("Shuriken", [cyl((0.62, -0.05, 0.1), 0.12, 0.012, rot=(90, 0, 0))] +
              [cone((0.62 + math.cos(math.radians(a)) * 0.12, -0.05, 0.1 + math.sin(math.radians(a)) * 0.12), 0.04, 0.05,
                    rot=(0, -a + 90, 0)) for a in (0, 90, 180, 270)], (170, 175, 185), material="Metal")


class pulpo_cubo:
    ID, RARITY = "pulpo_cubo", (200, 200, 200)

    @staticmethod
    def build():
        purple = (150, 90, 210)
        piece("Cuerpo", [body([((0, 0, 0.75), (0.42, 0.4, 0.42)), ((0, 0.1, 1.05), (0.34, 0.34, 0.34))])], purple)
        tent = []
        for k in range(8):
            a = math.radians(k * 45 + 22)
            d = Vector((math.cos(a), math.sin(a), 0))
            p0 = Vector((0, 0, 0.5)) + d * 0.25
            p1 = Vector((0, 0, 0.2)) + d * 0.55
            p2 = Vector((0, 0, 0.06)) + d * 0.85 + Vector((-d.y, d.x, 0)) * 0.12
            p3 = Vector((0, 0, 0.14)) + d * 1.02 + Vector((-d.y, d.x, 0)) * 0.25
            tent.append(tube([tuple(p0), tuple(p1), tuple(p2), tuple(p3)], 0.11, 0.025))
        piece("Tentaculos", tent, (165, 105, 220))
        suckers = []
        for k in range(8):
            a = math.radians(k * 45 + 22)
            d = Vector((math.cos(a), math.sin(a), 0))
            for t in (0.45, 0.65):
                suckers.append(sph(tuple(Vector((0, 0, 0.13 if t > 0.5 else 0.2)) + d * t - Vector((0, 0, 0.06))), 0.035))
        piece("Ventosas", suckers, (230, 190, 240), fine=True)
        eyes((0, -0.38, 0.86), 0.16, 0.1)
        piece("Cubo", [cyl((0, 0.08, 1.38), (0.36, 0.36), 0.2), cone((0, 0.08, 1.62), 0.36, 0.08, r2=0.0, rot=(180, 0, 0))], (225, 50, 50))
        piece("CuboBorde", [torus((0, 0.08, 1.2), 0.36, 0.03), torus((0, 0.08, 1.57), 0.33, 0.025)], (255, 220, 70))
        piece("Asa", [torus((0, 0.08, 1.58), 0.3, 0.015, rot=(90, 0, 0))], (150, 150, 160), material="Metal")


class gaviota_pirata:
    ID, RARITY = "gaviota_pirata", (90, 200, 90)

    @staticmethod
    def build():
        white, grey = (245, 245, 245), (150, 160, 175)
        piece("Cuerpo", [body([((0, 0, 0.75), (0.26, 0.5, 0.28), (12, 0, 0)), ((0, -0.42, 1.08), (0.17, 0.18, 0.17)),
                               ((0, 0.5, 0.82), (0.12, 0.28, 0.06), (-10, 0, 0))])], white)
        piece("Pico", [cone((0, -0.66, 1.07), 0.06, 0.16, rot=(90, 0, 0)), sph((0, -0.66, 1.03), (0.03, 0.06, 0.02))], (250, 190, 50))
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            pts = [(s * 0.22, 0.0, 0.92), (s * 0.7, 0.05, 1.05), (s * 1.25, 0.15, 1.0)]
            feathers = [sph(((pts[0][0] + pts[2][0] * 0.6) / 1.6 * 1.2, 0.12, 1.0), (0.42, 0.22, 0.04), rot=(0, s * -8, 0))]
            feathers.append(sph((s * 0.95, 0.15, 1.02), (0.36, 0.17, 0.035), rot=(0, s * 6, s * -8)))
            piece(f"Ala_{side}", feathers, grey, pivot=pts[0])
            piece(f"AlaPunta_{side}", [sph((s * 1.25, 0.18, 1.01), (0.16, 0.1, 0.03))], (40, 40, 45), anim="Ala", pivot=pts[0])
        legs = [tube([(s * 0.1, 0.05, 0.5), (s * 0.11, 0.0, 0.25), (s * 0.12, -0.05, 0.03)], 0.025, 0.02) for s in (-1, 1)]
        legs += [sph((s * 0.12, -0.12, 0.02), (0.08, 0.1, 0.015)) for s in (-1, 1)]
        piece("Patas", legs, (250, 170, 60))
        eyes((0, -0.52, 1.14), 0.11, 0.04, white=(255, 255, 255))
        piece("Parche", [sph((0.12, -0.53, 1.15), (0.06, 0.03, 0.06)), torus((0, -0.42, 1.13), 0.18, 0.008, rot=(10, 30, 0))], (25, 25, 30), keep=True)
        piece("Sombrero", [box((0, -0.38, 1.33), (0.5, 0.06, 0.18)), cone((0, -0.38, 1.38), 0.18, 0.12, rot=(0, 0, 0))], (250, 245, 230))
        piece("Calavera", [sph((0, -0.42, 1.36), 0.035)], (30, 30, 30), fine=True)


class erizo_tambor:
    ID, RARITY = "erizo_tambor", (90, 200, 90)

    @staticmethod
    def build():
        brown, face = (130, 90, 60), (235, 205, 165)
        piece("Cuerpo", [body([((0, 0.1, 0.5), (0.45, 0.6, 0.42)), ((0, -0.48, 0.42), (0.24, 0.24, 0.22))])], brown)
        piece("Cara", [body([((0, -0.62, 0.4), (0.2, 0.22, 0.17)), ((0, -0.82, 0.38), (0.07, 0.12, 0.07))], voxel=0.02)], face)
        piece("Nariz", [sph((0, -0.94, 0.4), 0.045)], (30, 25, 25), keep=True)
        eyes((0, -0.72, 0.5), 0.1, 0.04, white=None)
        rainbow = [(255, 80, 80), (255, 160, 50), (250, 220, 60), (90, 200, 110), (80, 150, 250), (160, 100, 240)]
        spikes = {i: [] for i in range(6)}
        k = 0
        rnd = __import__("random").Random(4)
        center, R = Vector((0, 0.1, 0.5)), Vector((0.45, 0.6, 0.42))
        for _ in range(140):
            u, v = rnd.uniform(-1, 1), rnd.uniform(0, 1)
            th = rnd.uniform(0, math.pi * 2)
            n = Vector((math.cos(th) * math.sqrt(1 - u * u), math.sin(th) * math.sqrt(1 - u * u), u))
            if n.z < 0.05 or n.y < -0.45:
                continue
            base = center + Vector((n.x * R.x, n.y * R.y, n.z * R.z)) * 0.92
            d = Vector((n.x / R.x, n.y / R.y, n.z / R.z)).normalized()
            tip = base + d * 0.3
            rot = d.to_track_quat("Z", "Y").to_euler()
            spikes[k % 6].append(cone(tuple((base + tip) / 2), 0.045, 0.16, rot=tuple(math.degrees(x) for x in rot)))
            k += 1
        for i, c in enumerate(rainbow):
            piece(f"Puas_{i}", spikes[i], c)
        legs4([((s * 0.25, y, 0.25), (s * 0.27, y - 0.02, 0.12), (s * 0.27, y - 0.05, 0.02)) for s in (-1, 1) for y in (-0.3, 0.4)], 0.07, 0.05, face, paw=True)
        piece("Tambor", [cyl((0.42, -0.5, 0.28), 0.16, 0.08, rot=(90, 0, 30))], (220, 60, 60))
        piece("Parche", [cyl((0.42, -0.5, 0.28), 0.15, 0.085, rot=(90, 0, 30))], (250, 240, 220))
        piece("Pinza_Palillos", [cyl((s * 0.2 + 0.1, -0.75, 0.55), 0.015, 0.16, rot=(40, s * 20, 0)) for s in (-1, 1)] +
              [sph((s * 0.2 + 0.1, -0.85, 0.66), 0.035) for s in (-1, 1)], (200, 160, 110), pivot=(0.1, -0.7, 0.45))


class camaleon_neon:
    ID, RARITY = "camaleon_neon", (90, 200, 90)

    @staticmethod
    def build():
        green, lime = (60, 220, 90), (190, 255, 80)
        piece("Cuerpo", [body([((0, 0, 0.62), (0.3, 0.55, 0.36)), ((0, -0.55, 0.78), (0.22, 0.27, 0.24)),
                               ((0, -0.4, 0.98), (0.05, 0.25, 0.08), (-30, 0, 0))])], green)
        # cola enrollada
        pts = [(0, 0.5, 0.6), (0, 0.8, 0.5), (0, 0.95, 0.3), (0, 0.85, 0.12), (0, 0.7, 0.18), (0, 0.72, 0.3)]
        piece("Cola", [tube(pts, 0.13, 0.05)], green, pivot=(0, 0.5, 0.6))
        piece("Rayas", [torus((0, y, 0.62), 0.24 - abs(y) * 0.1, 0.02, rot=(90, 0, 0)) for y in (-0.25, 0.0, 0.25)], lime, material="Neon", anim="Arcoiris")
        piece("Cresta", [cone((0, y, 0.92 - abs(y) * 0.2), 0.04, 0.06) for y in (-0.3, -0.15, 0, 0.15, 0.3)], lime, fine=True)
        legs = []
        for s in (-1, 1):
            for y in (-0.3, 0.3):
                legs.append(tube([(s * 0.24, y, 0.55), (s * 0.4, y - 0.05, 0.4), (s * 0.36, y - 0.12, 0.04)], 0.07, 0.045))
                legs += [sph((s * 0.36 + k * 0.035, y - 0.16, 0.03), (0.03, 0.06, 0.025)) for k in (-1, 1)]
        piece("Patas", legs, green)
        # ojos de torreta con pupila
        tur = [sph((s * 0.19, -0.64, 0.9), 0.11) for s in (-1, 1)]
        piece("Torretas", tur, green)
        piece("Pupilas", [sph((s * 0.25, -0.71, 0.91), 0.045) for s in (-1, 1)], (20, 20, 25), keep=True)
        piece("Lengua", [tube([(0, -0.78, 0.68), (0, -0.95, 0.66), (0.05, -1.05, 0.7)], 0.02, 0.015), sph((0.05, -1.06, 0.7), 0.04)], (255, 90, 160), anim="Pendulo", pivot=(0, -0.78, 0.68))


class buho_despertador:
    ID, RARITY = "buho_despertador", (70, 140, 255)

    @staticmethod
    def build():
        brown, cream = (140, 95, 60), (240, 220, 180)
        piece("Cuerpo", [body([((0, 0, 0.8), (0.42, 0.38, 0.55)), ((0, -0.05, 1.45), (0.38, 0.34, 0.32))])], brown)
        piece("Orejas", [cone((s * 0.24, 0.0, 1.8), 0.09, 0.14, rot=(0, s * 20, 0)) for s in (-1, 1)], brown)
        piece("Cara", [sph((s * 0.15, -0.26, 1.45), (0.18, 0.08, 0.17)) for s in (-1, 1)], cream)
        eyes((0, -0.3, 1.47), 0.15, 0.1, iris=(40, 30, 20), lid=brown)
        piece("Pico", [cone((0, -0.4, 1.33), 0.05, 0.1, rot=(150, 0, 0))], (250, 180, 50))
        # reloj despertador en la barriga
        piece("Reloj", [cyl((0, -0.38, 0.8), 0.3, 0.06, rot=(90, 0, 0))], (230, 60, 60))
        piece("Esfera", [cyl((0, -0.42, 0.8), 0.25, 0.04, rot=(90, 0, 0))], (250, 250, 245))
        piece("Pendulo_Agujas", [box((0, -0.47, 0.88), (0.025, 0.01, 0.17)), box((0.05, -0.47, 0.8), (0.12, 0.01, 0.025), rot=(0, 30, 0))], (30, 30, 30), anim="Giro", pivot=(0, -0.47, 0.8))
        piece("Campanas", [sph((s * 0.24, -0.22, 1.12), (0.12, 0.12, 0.09)) for s in (-1, 1)] +
              [cyl((s * 0.24, -0.22, 1.2), 0.015, 0.05) for s in (-1, 1)], (240, 200, 60), material="Metal")
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Ala_{side}", [sph((s * 0.44, 0.05, 0.9), (0.12, 0.3, 0.45), rot=(10, 0, s * 10))], (120, 80, 50), pivot=(s * 0.4, 0, 1.25))
        piece("Patas", [cone((s * 0.14 + k * 0.05, -0.2, 0.05), 0.03, 0.08, rot=(80, 0, 0)) for s in (-1, 1) for k in (-1, 0, 1)], (240, 170, 60))


LOTE = [caracol_turbo, estrella_ninja, pulpo_cubo, gaviota_pirata, erizo_tambor, camaleon_neon, buho_despertador]
