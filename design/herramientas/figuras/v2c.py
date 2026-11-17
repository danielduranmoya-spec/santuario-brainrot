"""Bichos v2 (lote C): raros, épicos y legendarios."""
import math
import random

from mathutils import Vector

import lib
import tex
from fig2 import bolt, piece, point_light, puffs
from v2a import S, eyes_almond
from v2b import P, flame, rings, skin


def M():
    return lib.mat("_d", (200, 200, 200))


class salamandra_chispa:
    ID, RARITY, TITLE = "salamandra_chispa", (70, 140, 255), "Salamandra Chispa"

    @staticmethod
    def build():
        sk = skin("sal", (45, 35, 50), (90, 60, 70), bump=0.35, scale=60, spots=((255, 140, 30), 7), rough=0.3)
        shapes = [S((0, 0, 0.24), (0.24, 0.6, 0.17)), S((0, -0.62, 0.3), (0.2, 0.23, 0.15)), S((0, -0.84, 0.28), (0.15, 0.15, 0.1))]
        limbs = [[(s * 0.17, y, 0.22, 0.07), (s * 0.36, y - 0.04, 0.2, 0.05), (s * 0.42, y - 0.14, 0.03, 0.04)] for s in (-1, 1) for y in (-0.36, 0.3)]
        piece("Cuerpo", tex.sculpt("c", sk, shapes, limbs, voxel=0.013), shader=sk, bake=True, budget=3200)
        piece("Cola", tex.sculpt("t", sk, [], [[(0, 0.5, 0.24, 0.14), (0.15, 0.9, 0.2, 0.1), (0.05, 1.25, 0.14, 0.06), (-0.15, 1.5, 0.12, 0.02)]], voxel=0.012, smooth=10),
              shader=sk, bake=True, budget=1200, pivot=(0, 0.5, 0.24))
        eyes_almond((0, -0.88, 0.37), 0.1, 0.03, (255, 160, 40), tilt=15, glow=1)
        # cresta de llamas a lo largo del lomo y la cola, chispas y brasas
        f1, f2, f3 = [], [], []
        for k, y in enumerate((-0.7, -0.45, -0.2, 0.05, 0.3, 0.6, 0.9, 1.2)):
            h = 0.62 - abs(y - 0.1) * 0.22
            z = 0.38 if y < 0.5 else 0.3 - (y - 0.5) * 0.15
            o, m, i = flame((0.0 + (0.08 * math.sin(y * 3) if y > 0.5 else 0), y, z - 0.03), (0, 0.35, 1), max(0.25, h), 0.11)
            f1.append(o); f2.append(m); f3.append(i)
            if k % 2 == 0:
                point_light((0, y, z + 0.2), (1, 0.55, 0.2), 4)
        piece("Brillo_Llamas", f1, (255, 90, 20), material="Neon")
        piece("Brillo_LlamasMedio", f2, (255, 190, 50), material="Neon")
        piece("Brillo_LlamasCentro", f3, (255, 250, 200), material="Neon")
        rnd = random.Random(3)
        piece("Gota_Chispas", [P("sphere", (rnd.uniform(-0.4, 0.4), rnd.uniform(-1.1, 1.2), rnd.uniform(0.5, 0.95)), (0.025, 0.025, 0.04)) for _ in range(10)], (255, 220, 90), material="Neon", fine=True)
        piece("Charco", [P("cyl", (0, 0, 0.005), (0.55, 0.9, 0.005), subd=0)], (90, 25, 15))
        piece("Brillo_Brasas", [P("sphere", (rnd.uniform(-0.45, 0.45), rnd.uniform(-0.8, 0.8), 0.01), (0.04, 0.04, 0.012)) for _ in range(14)], (255, 120, 30), material="Neon", fine=True)


class planta_beatbox:
    ID, RARITY, TITLE = "planta_beatbox", (70, 140, 255), "Planta Beatbox"

    @staticmethod
    def build():
        leaf = skin("hoja", (50, 160, 60), (130, 210, 90), bump=0.3, scale=35)
        pot = skin("maceta", (205, 110, 70), (160, 80, 50), bump=0.2, scale=14)
        piece("Maceta", [P("cyl", (0, 0, 0.2), (0.3, 0.3, 0.2), subd=1), P("torus", (0, 0, 0.4), (0.33, 0.33, 0.33), minor=0.13)], shader=pot, bake=True, budget=700)
        piece("Tierra", [P("cyl", (0, 0, 0.38), (0.29, 0.29, 0.02), subd=0)], (80, 55, 40))
        piece("Tallo", tex.sculpt("t", leaf, [], [[(0, 0, 0.38, 0.07), (0.08, -0.04, 0.7, 0.055), (-0.04, -0.06, 0.95, 0.05)],
                                                  [(0, 0, 0.42, 0.04), (0.25, 0.0, 0.52, 0.07), (0.42, 0.02, 0.5, 0.01)], [(0, 0, 0.42, 0.04), (-0.25, 0.04, 0.55, 0.07), (-0.44, 0.05, 0.56, 0.01)]],
                                 voxel=0.012, smooth=8), shader=leaf, bake=True, budget=1200)
        head = skin("cabeza", (60, 175, 65), (250, 90, 110), (200, 120, 90), bump=0.25, scale=40)
        piece("Craneo", tex.sculpt("h", head, [S((0, -0.12, 1.22), (0.42, 0.32, 0.16))], [], voxel=0.012), shader=head, bake=True, budget=900, pivot=(0, -0.0, 1.05))
        piece("Pinza_Boca", tex.sculpt("b", head, [S((0, -0.14, 0.98), (0.4, 0.3, 0.12))], [], voxel=0.012), shader=head, bake=True, budget=900, pivot=(0, 0.0, 1.05))
        piece("Interior", [P("sphere", (0, -0.18, 1.1), (0.28, 0.21, 0.06))], (255, 100, 120))
        piece("Dientes", [P("cone", (math.sin(a) * 0.3, -0.16 - math.cos(a) * 0.22, z), (0.025, 0.025, 0.06), rot=(0 if z < 1.1 else 180, 0, 0)) for a in [i * 0.42 - 1.47 for i in range(8)] for z in (1.06, 1.14)], (255, 255, 240), fine=True)
        piece("Gafas", [P("cube", (s * 0.13, -0.36, 1.28), (0.2, 0.03, 0.1), subd=0, bevel=0.02) for s in (-1, 1)] + [P("cube", (0, -0.36, 1.3), (0.08, 0.02, 0.02), subd=0)], (20, 20, 25), keep=True)
        piece("Brillo_Gafas", [P("cube", (s * 0.13 - 0.04, -0.38, 1.3), (0.06, 0.01, 0.025), subd=0) for s in (-1, 1)], (120, 255, 240), material="Neon", keep=True)
        # altavoces a los lados, ondas de sonido y notas de neón
        piece("Altavoces", [P("cube", (s * 0.48, 0.0, 0.22), (0.2, 0.18, 0.4), subd=0, bevel=0.02) for s in (-1, 1)], (35, 35, 45))
        piece("Pinza_Conos", [P("cyl", (s * 0.48, -0.1, z), (0.065, 0.065, 0.01), rot=(90, 0, 0), subd=0) for s in (-1, 1) for z in (0.12, 0.3)], (200, 200, 210), material="Metal", pivot=(0, -0.1, 0.2))
        waves = []
        for s in (-1, 1):
            waves += [P("torus", (s * 0.48, -0.15, 0.25), (r, r, r), rot=(90, 0, 0), minor=0.012 / r) for r in (0.18, 0.28)]
        piece("Brillo_Ondas", waves, (255, 60, 200), material="Neon")
        notes = []
        for x, y, z in ((0.62, -0.2, 1.3), (-0.66, -0.15, 1.15), (0.45, -0.1, 1.62)):
            notes += [P("sphere", (x, y, z), (0.06, 0.03, 0.045)), P("cube", (x + 0.05, y, z + 0.12), (0.012, 0.012, 0.12), subd=0), P("cube", (x + 0.1, y, z + 0.22), (0.05, 0.012, 0.02), subd=0)]
        piece("Gota_Notas", notes, (120, 255, 240), material="Neon")
        point_light((0, -0.5, 1.2), (1, 0.4, 0.9), 5)


class golem_obsidiana:
    ID, RARITY, TITLE = "golem_obsidiana", (170, 80, 255), "Gólem de Obsidiana"

    @staticmethod
    def build():
        rock = tex.veined("roca", (42, 36, 52), (255, 110, 25), scale=2.2, width=0.025, bump=0.8, rough=0.3)
        def chunk(c, s, r):
            o = P("cube", c, s, rot=r, subd=1, bevel=0.06)
            return o
        piece("Cuerpo", [chunk((0, 0, 1.1), (0.46, 0.3, 0.38), (3, 0, 2)), chunk((0, -0.05, 1.58), (0.27, 0.23, 0.18), (-5, 4, 0)),
                         chunk((0.22, 0.05, 1.42), (0.14, 0.14, 0.12), (10, 20, 5)), chunk((-0.24, 0.06, 1.4), (0.13, 0.13, 0.12), (-8, -15, 10))], shader=rock, bake=True, budget=1600)
        piece("Craneo", [chunk((0, -0.08, 1.9), (0.19, 0.17, 0.15), (4, -3, 2))], shader=rock, bake=True, budget=300)
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Pendulo_Brazo{side}", [chunk((s * 0.62, 0, 1.3), (0.16, 0.16, 0.18), (5, 3, 8)), chunk((s * 0.68, -0.05, 0.95), (0.13, 0.14, 0.2), (-6, 4, -5)),
                                           chunk((s * 0.72, -0.1, 0.58), (0.2, 0.2, 0.17), (8, -6, 3))], shader=rock, bake=True, budget=600, anim="Pendulo", pivot=(s * 0.6, 0, 1.42))
            piece(f"Pierna_{side}", [chunk((s * 0.25, 0, 0.42), (0.16, 0.18, 0.25), (3, 0, s * 3)), chunk((s * 0.26, -0.07, 0.1), (0.19, 0.24, 0.1), (0, 0, 0))], shader=rock, bake=True, budget=400)
        # núcleo de lava, grietas que brillan, ojos y cristales en la espalda; goteo de lava
        piece("Brillo_Nucleo", [P("sphere", (0, -0.31, 1.15), (0.15, 0.06, 0.15))], (255, 120, 25), material="Neon")
        piece("Brillo_Halo", rings((0, -0.34, 1.15), (90, 0, 0), (0.22,), 0.02), (255, 200, 80), material="Neon")
        cracks = []
        for (a, b, c) in (((0.2, -0.31, 1.4), (0.1, -0.32, 1.25), (0.28, -0.31, 0.88)), ((-0.25, -0.31, 1.35), (-0.12, -0.32, 1.2), (-0.32, -0.31, 0.85)),
                          ((0.6, -0.17, 1.35), (0.66, -0.2, 1.05), (0.7, -0.29, 0.68)), ((-0.6, -0.17, 1.35), (-0.66, -0.2, 1.05), (-0.72, -0.29, 0.68))):
            cracks.append(lib.tube("g", [a, b, c], 0.022, 0.012, M()))
        piece("Brillo_Grietas", cracks, (255, 110, 25), material="Neon")
        piece("Ojos", [P("cube", (s * 0.08, -0.255, 1.93), (0.07, 0.02, 0.035), subd=0) for s in (-1, 1)], (255, 190, 60), material="Neon", keep=True)
        piece("Cristales", [P("cone", (x, 0.22, 1.72 + abs(x) * 0.3), (0.08, 0.08, 0.25), rot=(-25, x * 70, 0), subd=0) for x in (-0.28, -0.1, 0.08, 0.24)], (160, 90, 255), material="Glass")
        piece("Brillo_Cristales", [P("cone", (x, 0.22, 1.72 + abs(x) * 0.3), (0.04, 0.04, 0.18), rot=(-25, x * 70, 0), subd=0) for x in (-0.28, -0.1, 0.08, 0.24)], (200, 140, 255), material="Neon")
        piece("Gota_Lava", [P("sphere", (0.05, -0.33, 0.85), (0.04, 0.04, 0.06)), P("sphere", (-0.72, -0.3, 0.4), (0.035, 0.035, 0.05))], (255, 120, 25), material="Neon")
        point_light((0, -0.6, 1.15), (1, 0.5, 0.15), 10)
        point_light((0, 0.4, 1.9), (0.7, 0.4, 1), 5)


class murcielago_magma:
    ID, RARITY, TITLE = "murcielago_magma", (170, 80, 255), "Murciélago de Magma"
    WIDE = 1.95

    @staticmethod
    def build():
        body = tex.furry("cuerpo", (60, 44, 50), (95, 70, 72), fur=0.7, fur_scale=80, flow=(1, 1, 0.35))
        piece("Cuerpo", tex.sculpt("c", body, [S((0, 0.06, 1.45), (0.27, 0.22, 0.35)), S((0, 0.08, 1.18), (0.16, 0.15, 0.2)), S((0, 0.0, 1.72), (0.22, 0.19, 0.16)),
                                                S((0, -0.08, 1.88), (0.17, 0.16, 0.15)), S((0, -0.23, 1.84), (0.085, 0.1, 0.075))],
                                   [[(s * 0.1, 0.1, 1.28, 0.04), (s * 0.16, 0.08, 1.15, 0.03), (s * 0.3, 0.1, 0.88, 0.022)] for s in (-1, 1)], voxel=0.012), shader=body, bake=True, budget=2600)
        ear = tex.furry("oreja", (55, 38, 44), (80, 55, 60), fur=0.2, fur_scale=50)
        piece("Orejas", [P("sphere", (s * 0.15, -0.02, 2.32), (0.13, 0.045, 0.36), rot=(-14, s * 12, s * -10)) for s in (-1, 1)], shader=ear, bake=True, budget=500)
        piece("Brillo_Orejas", [P("sphere", (s * 0.148, -0.05, 2.3), (0.095, 0.02, 0.3), rot=(-14, s * 12, s * -10)) for s in (-1, 1)], (255, 120, 30), material="Neon")
        piece("Ojos", [P("sphere", (s * 0.085, -0.22, 1.9), (0.032, 0.024, 0.028)) for s in (-1, 1)], (255, 190, 50), material="Neon", keep=True)
        piece("Colmillos", [P("cone", (s * 0.04, -0.3, 1.79), (0.012, 0.012, 0.03), rot=(180, 0, 0)) for s in (-1, 1)], (250, 245, 230), fine=True)
        memb = tex.veined("membrana", (42, 26, 30), (255, 120, 30), scale=1.3, width=0.03)
        bone = skin("hueso", (95, 62, 62), (130, 90, 88), bump=0.1, scale=20)
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            S0, E, W = (s * 0.17, 0.02, 1.62), (s * 0.62, -0.02, 1.76), (s * 1.12, -0.06, 2.28)
            fingers = [((s * 1.85, -0.02, 2.24), (s * 2.7, 0.04, 1.84)), ((s * 1.7, 0.03, 1.72), (s * 2.42, 0.08, 0.95)),
                       ((s * 1.42, 0.06, 1.4), (s * 1.82, 0.1, 0.66)), ((s * 1.2, 0.06, 1.34), (s * 1.18, 0.1, 0.6))]
            ankle, hip = (s * 0.3, 0.1, 0.86), (s * 0.14, 0.08, 1.24)
            tips = [f[1] for f in fingers]

            def edge(a, b, dd):
                mid = (Vector(a) + Vector(b)) / 2
                return lib.scallop(a, b, dd, n=5, inward=tuple((Vector(W) - mid).normalized()))
            outline = [S0, E, W, fingers[0][0], tips[0]]
            for a, b in zip(tips, tips[1:]):
                outline += [*edge(a, b, 0.22), b]
            outline += [*edge(tips[-1], ankle, 0.22), ankle, hip]
            piece(f"Ala_{side}", lib.membrane("m", outline, M(), thickness=0.03, sag=0.16, subd=2), shader=memb, bake=True, budget=1100, anim="Ala", pivot=S0)
            bones = [lib.tube("b", [S0, E, W], 0.045, 0.032, M()), P("sphere", E, 0.048), P("sphere", W, 0.05)]
            for k, t in fingers:
                bones += [lib.tube("f", [W, k, t], 0.026, 0.01, M()), P("sphere", k, 0.028)]
            piece(f"AlaHueso_{side}", bones, shader=bone, bake=True, budget=700, anim="Ala", pivot=S0)
            piece(f"Ala_Garra{side}", [P("cone", (s * 1.1, -0.17, 2.4), (0.025, 0.025, 0.07), rot=(-60, 0, s * 10))], (35, 28, 28), anim="Ala", pivot=S0)
        # gotas de magma que caen, brasas y halo de calor
        piece("Gota_Magma", [P("sphere", (0.04, 0.1, 0.75), (0.04, 0.04, 0.06)), P("sphere", (-0.06, 0.12, 0.5), (0.03, 0.03, 0.05)), P("sphere", (0.02, 0.1, 0.25), (0.025, 0.025, 0.04))], (255, 120, 25), material="Neon")
        rnd = random.Random(6)
        piece("Brillo_Brasas", [P("sphere", (rnd.uniform(-1.6, 1.6), rnd.uniform(-0.3, 0.3), rnd.uniform(0.7, 2.4)), 0.022) for _ in range(14)], (255, 170, 60), material="Neon", fine=True)
        point_light((0, -0.3, 2.2), (1, 0.5, 0.15), 6)
        point_light((0, 0.2, 0.6), (1, 0.5, 0.15), 4)


class ajolote_chubasquero:
    ID, RARITY, TITLE = "ajolote_chubasquero", (170, 80, 255), "Ajolote Chubasquero"

    @staticmethod
    def build():
        pink = skin("ajolote", (255, 170, 200), (255, 215, 228), bump=0.2, scale=30, rough=0.3)
        coat = skin("chubasquero", (255, 215, 40), (240, 170, 20), bump=0.1, scale=10, rough=0.25)
        piece("Cuerpo", tex.sculpt("c", coat, [S((0, 0, 0.72), (0.33, 0.29, 0.42)), S((0, 0.02, 0.4), (0.36, 0.31, 0.22))],
                                   [[(s * 0.28, -0.05, 0.95, 0.09), (s * 0.4, -0.13, 0.75, 0.075), (s * 0.38, -0.22, 0.6, 0.065)] for s in (-1, 1)], voxel=0.014), shader=coat, bake=True, budget=2200)
        piece("Craneo", tex.sculpt("h", pink, [S((0, -0.05, 1.28), (0.35, 0.3, 0.26))], [], voxel=0.013), shader=pink, bake=True, budget=1200)
        piece("Capucha", tex.sculpt("k", coat, [S((0, 0.04, 1.36), (0.38, 0.33, 0.3)), S((0, -0.16, 1.6), (0.33, 0.12, 0.05), (20, 0, 0))], [], voxel=0.013), shader=coat, bake=True, budget=900)
        gills = []
        for s in (-1, 1):
            for a in (15, 45, 75):
                g = math.radians(a)
                gills.append([(s * 0.3, -0.02, 1.3, 0.05), (s * (0.3 + math.cos(g) * 0.2), 0.0, 1.3 + math.sin(g) * 0.2, 0.04), (s * (0.3 + math.cos(g) * 0.33), -0.02, 1.3 + math.sin(g) * 0.34, 0.02)])
        piece("Branquias", tex.sculpt("g", pink, [], gills, voxel=0.01, smooth=6), (255, 110, 160), shader=skin("bran", (255, 90, 150), (255, 160, 200), bump=0.4, scale=60), bake=True, budget=1000)
        eyes_almond((0, -0.3, 1.32), 0.15, 0.04, (40, 30, 50), tilt=0, glow=0, pupil_slit=False)
        piece("Boca", [P("torus", (0, -0.33, 1.2), (0.07, 0.07, 0.07), rot=(90, 0, 0), minor=0.12)], (190, 70, 100), keep=True, fine=True)
        piece("Botones", [P("sphere", (0, -0.29, 0.95 - k * 0.15), 0.035) for k in range(3)], (60, 60, 70), fine=True)
        piece("Manos", [P("sphere", (s * 0.38, -0.24, 0.56), 0.07) for s in (-1, 1)], (255, 170, 200))
        boots = skin("botas", (230, 45, 50), (170, 25, 35), bump=0.05, scale=8, rough=0.2)
        piece("Botas", [P("cyl", (s * 0.15, -0.03, 0.12), (0.12, 0.12, 0.12)) for s in (-1, 1)] + [P("sphere", (s * 0.15, -0.12, 0.04), (0.12, 0.15, 0.05)) for s in (-1, 1)], shader=boots, bake=True, budget=600)
        piece("Cola", tex.sculpt("t", pink, [], [[(0, 0.25, 0.42, 0.11), (0, 0.5, 0.3, 0.07), (0, 0.72, 0.2, 0.02)]], voxel=0.012), shader=pink, bake=True, budget=500, pivot=(0, 0.25, 0.42))
        # paraguas con lluvia mágica: nube encima, gotas brillantes y charco
        umb = skin("paraguas", (80, 160, 250), (40, 100, 200), bump=0.05, scale=6, rough=0.3)
        piece("Paraguas", [P("cone", (0.42, -0.12, 1.85), (0.5, 0.5, 0.14))], shader=umb, bake=True, budget=500)
        piece("Baston", [P("cyl", (0.42, -0.12, 1.25), (0.015, 0.015, 0.58), subd=0), P("torus", (0.47, -0.12, 0.67), (0.05, 0.05, 0.05), rot=(90, 0, 0), minor=0.25)], (60, 60, 70))
        cloud = tex.furry("nubecilla", (250, 252, 255), (150, 165, 200), fur=0.1, fur_scale=15, rough=0.9)
        piece("Nube", tex.sculpt("n", cloud, puffs([((0.42, -0.12, 2.25), 0.16), ((0.22, -0.1, 2.2), 0.12), ((0.62, -0.14, 2.2), 0.12)], 2), [], voxel=0.012, smooth=5), shader=cloud, bake=True, budget=900)
        rnd = random.Random(4)
        piece("Gota_Lluvia", [P("sphere", (0.42 + rnd.uniform(-0.55, 0.55), -0.12 + rnd.uniform(-0.3, 0.3), rnd.uniform(0.2, 1.9)), (0.018, 0.018, 0.045)) for _ in range(16)], (140, 210, 255), material="Neon")
        piece("Charco", [P("cyl", (0.1, -0.1, 0.005), (0.6, 0.5, 0.005), subd=0)], (120, 190, 240), material="Glass")
        piece("Brillo_Ondas", rings((0.1, -0.1, 0.012), (0, 0, 0), (0.25, 0.4), 0.008), (190, 235, 255), material="Neon", fine=True)
        point_light((0.4, -0.3, 1.6), (0.5, 0.8, 1), 4)


class dragon_algodon:
    ID, RARITY, TITLE = "dragon_algodon", (255, 190, 40), "Dragón de Algodón"
    WIDE = 1.8

    @staticmethod
    def build():
        sk = tex.furry("algodon", (255, 160, 205), (255, 225, 240), (255, 190, 222), fur=0.6, fur_scale=35, flow=(1, 1, 1))
        shapes = [S((0, 0.1, 0.62), (0.3, 0.45, 0.32)), S((0, -0.36, 0.97), (0.17, 0.19, 0.28), (25, 0, 0)), S((0, -0.52, 1.26), (0.2, 0.23, 0.18)),
                  S((0, -0.74, 1.22), (0.12, 0.15, 0.1))]
        limbs = [[(s * 0.18, y, 0.5, 0.11), (s * 0.22, y - 0.02, 0.25, 0.08), (s * 0.22, y - 0.05, 0.05, 0.075)] for s in (-1, 1) for y in (-0.15, 0.35)]
        piece("Cuerpo", tex.sculpt("c", sk, shapes, limbs, voxel=0.015), shader=sk, bake=True, budget=3200)
        piece("Cola", tex.sculpt("t", sk, [], [[(0, 0.5, 0.52, 0.15), (0.12, 0.85, 0.38, 0.1), (-0.05, 1.15, 0.33, 0.06), (0.0, 1.3, 0.45, 0.03)]], voxel=0.013), shader=sk, bake=True, budget=800, pivot=(0, 0.5, 0.52))
        piece("Cuernos", [P("cone", (s * 0.1, -0.44, 1.47), (0.04, 0.04, 0.1), rot=(-25, s * 15, 0)) for s in (-1, 1)], (255, 245, 210), material="Metal")
        eyes_almond((0, -0.68, 1.32), 0.1, 0.04, (150, 90, 230), tilt=-10, glow=1)
        wing = tex.furry("alas", (150, 200, 255), (210, 235, 255), fur=0.2, fur_scale=20)
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            S0 = (s * 0.22, 0.05, 0.9)
            outline = [S0, (s * 0.6, 0.0, 1.3), (s * 1.05, 0.05, 1.38), *lib.scallop((s * 1.05, 0.05, 1.38), (s * 0.9, 0.1, 0.85), 0.1, 3, (s * -1, 0, 0.3)),
                       (s * 0.9, 0.1, 0.85), *lib.scallop((s * 0.9, 0.1, 0.85), (s * 0.4, 0.15, 0.7), 0.08, 3, (s * -0.5, 0, 0.8)), (s * 0.4, 0.15, 0.7)]
            piece(f"Ala_{side}", lib.membrane("w", outline, M(), thickness=0.035, sag=0.05, subd=2), shader=wing, bake=True, budget=700, anim="Ala", pivot=S0)
        # nubes de algodón de azúcar alrededor, chispitas de azúcar y una nube en la punta de la cola
        cloud = tex.furry("nube", (255, 255, 255), (255, 200, 230), fur=0.25, fur_scale=25, rough=0.85)
        ring = [((math.cos(a) * 0.5, 0.1 + math.sin(a) * 0.55, 0.15), 0.13) for a in [i * 0.8 for i in range(8)]]
        ring += [((0, 0.1, 0.95), 0.14), ((0.12, -0.1, 0.92), 0.11), ((-0.13, 0.28, 0.9), 0.12), ((0.02, 1.33, 0.5), 0.1)]
        piece("Nubes", tex.sculpt("n", cloud, puffs(ring, 6), [], voxel=0.013, smooth=5), shader=cloud, bake=True, budget=2200)
        rnd = random.Random(9)
        cols = [(255, 120, 200), (130, 220, 255), (255, 240, 120)]
        for k, c in enumerate(cols):
            piece(f"Gota_Azucar{k}", [P("sphere", (rnd.uniform(-0.9, 0.9), rnd.uniform(-0.8, 0.8), rnd.uniform(0.3, 1.6)), 0.024) for _ in range(6)], c, material="Neon", fine=True)
        point_light((0, -0.6, 1.5), (1, 0.7, 0.9), 4)


class garza_prisma:
    ID, RARITY, TITLE = "garza_prisma", (255, 190, 40), "Garza de Prisma"
    WIDE = 1.8

    @staticmethod
    def build():
        fe = tex.furry("plumas", (240, 242, 250), (255, 255, 255), fur=0.35, fur_scale=50, flow=(1, 0.3, 1))
        piece("Cuerpo", tex.sculpt("c", fe, [S((0, 0.05, 1.05), (0.2, 0.42, 0.24), (15, 0, 0)), S((0, -0.38, 1.95), (0.08, 0.11, 0.08))],
                                   [[(0, -0.22, 1.12, 0.1), (0, -0.4, 1.45, 0.07), (0, -0.25, 1.72, 0.06), (0, -0.36, 1.92, 0.065)], [(0, 0.4, 1.0, 0.09), (0, 0.65, 0.92, 0.03)]], voxel=0.012),
              shader=fe, bake=True, budget=2600)
        piece("Pico", [P("cone", (0, -0.62, 1.94), (0.03, 0.025, 0.18), rot=(92, 0, 0))], (250, 200, 60))
        piece("Penacho", [lib.tube("p", [(0, -0.32, 2.0), (0, -0.12, 2.1), (0, 0.08, 2.05)], 0.016, 0.006, M())], (40, 40, 60), fine=True)
        eyes_almond((0, -0.45, 1.98), 0.065, 0.016, (255, 200, 60), tilt=0, glow=0)
        piece("Patas", [lib.tube("l", [(s * 0.07, 0.05, 0.85), (s * 0.08, 0.1, 0.45), (s * 0.08, 0.02, 0.03)], 0.022, 0.016, M()) for s in (-1, 1)]
              + [P("cone", (s * 0.08 + k * 0.04, -0.05, 0.02), (0.012, 0.012, 0.08), rot=(90, 0, k * 20)) for s in (-1, 1) for k in (-1, 0, 1)], (60, 60, 75))
        # alas de cristal de arcoíris (plumas de prisma) que brillan, y rayos de luz que salen del prisma
        rainbow = [(255, 80, 80), (255, 170, 50), (250, 230, 70), (90, 210, 110), (80, 160, 255), (170, 110, 240)]
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            S0 = (s * 0.15, 0.0, 1.15)
            for i, c in enumerate(rainbow):
                f = [P("cone", (s * (0.35 + i * 0.11), 0.05 + i * 0.05, 1.3 + i * 0.04), (0.07, 0.025, 0.3), rot=(0, s * (-60 + i * 8), 0), subd=0)]
                piece(f"Ala_{side}{i}", f, c, material="Glass", anim="Ala", pivot=S0)
                piece(f"Ala_Brillo{side}{i}", [P("cone", (s * (0.35 + i * 0.11), 0.05 + i * 0.05, 1.3 + i * 0.04), (0.025, 0.01, 0.24), rot=(0, s * (-60 + i * 8), 0), subd=0)], c, material="Neon", anim="Ala", pivot=S0)
        piece("Brillo_Prisma", [P("cone", (0, 0.05, 1.35), (0.09, 0.09, 0.12), rot=(0, 45, 0), subd=0), P("cone", (0, 0.05, 1.11), (0.09, 0.09, 0.12), rot=(180, 45, 0), subd=0)], (230, 250, 255), material="Glass")
        beams = []
        for i, c in enumerate(rainbow):
            a = math.radians(-50 + i * 20)
            beams.append((P("cube", (math.sin(a) * 0.45, 0.25, 1.23 + math.cos(a) * 0.45), (0.012, 0.006, 0.35), rot=(0, math.degrees(a), 0), subd=0), c))
        for i, (o, c) in enumerate(beams):
            piece(f"Arcoiris_Rayo{i}", [o], c, material="Neon", fine=True)
        point_light((0, 0.1, 1.25), (1, 1, 1), 5)


LOTE = [salamandra_chispa, planta_beatbox, golem_obsidiana, murcielago_magma, ajolote_chubasquero, dragon_algodon, garza_prisma]
