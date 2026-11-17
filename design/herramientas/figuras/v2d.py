"""Bichos v2 (lote D): míticos y secretos."""
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


class leviatan_espejo:
    ID, RARITY, TITLE = "leviatan_espejo", (255, 70, 110), "Leviatán de Espejo"
    YAW = -40

    @staticmethod
    def build():
        scales = tex.furry("escamas", (150, 175, 205), (235, 245, 255), (195, 215, 235), fur=0.0, rough=0.15, spots=((255, 255, 255), 30))
        pts = [(0, 1.05, 0.08, 0.06), (0.12, 0.75, 0.42, 0.11), (0, 0.38, 0.72, 0.15), (-0.12, 0.0, 0.55, 0.17), (0, -0.25, 0.25, 0.17),
               (0.06, -0.5, 0.42, 0.16), (0, -0.62, 0.82, 0.15), (0, -0.78, 1.08, 0.14)]
        piece("Cuerpo", tex.sculpt("c", scales, [S((0, -0.86, 1.18), (0.16, 0.22, 0.13)), S((0, -1.06, 1.13), (0.1, 0.13, 0.07))], [pts], voxel=0.014), shader=scales, bake=True, budget=3400)
        piece("Escamas", [P("sphere", (x * 0.9, y, z + r * 0.85), (r * 0.5, r * 0.6, r * 0.18), rot=(0, 0, 0)) for x, y, z, r in pts[1:]], (220, 235, 250), material="Foil")
        fin = tex.veined("aleta", (90, 210, 230), (230, 255, 255), scale=6, width=0.05, bump=0.2, rough=0.1)
        fins = []
        for x, y, z, r in pts[1:-1]:
            fins.append(lib.membrane("f", [(0, y - 0.12, z + r * 0.8), (0, y, z + r * 0.8 + 0.22), (0, y + 0.14, z + r * 0.8)], M(), thickness=0.02, sag=0.0, subd=2))
        piece("Aletas", fins, shader=fin, bake=True, budget=900)
        piece("Cuernos", [P("cone", (s * 0.09, -0.8, 1.33), (0.035, 0.035, 0.14), rot=(-40, s * 18, 0)) for s in (-1, 1)], (130, 240, 250), material="Glass")
        piece("Bigotes", [lib.tube("b", [(s * 0.08, -1.12, 1.1), (s * 0.28, -1.22, 1.05), (s * 0.45, -1.15, 0.92)], 0.014, 0.005, M()) for s in (-1, 1)], (150, 240, 250), fine=True)
        eyes_almond((0, -1.02, 1.22), 0.08, 0.025, (60, 230, 230), tilt=25, glow=1)
        # columnas de agua de espejo, reflejos y ondas
        water = []
        for (x, y) in ((0, 1.05), (0, -0.25)):
            water.append(P("cyl", (x, y, 0.06), (0.32, 0.32, 0.03), subd=1))
        piece("Agua", water, (120, 220, 255), material="Glass")
        piece("Brillo_Ondas", rings((0, 1.05, 0.08), (0, 0, 0), (0.25, 0.42), 0.014) + rings((0, -0.25, 0.08), (0, 0, 0), (0.28, 0.46), 0.014), (190, 245, 255), material="Neon")
        rnd = random.Random(5)
        piece("Gota_Salpicaduras", [P("sphere", (rnd.uniform(-0.4, 0.4), rnd.choice((1.05, -0.25)) + rnd.uniform(-0.3, 0.3), rnd.uniform(0.15, 0.6)), (0.025, 0.025, 0.04)) for _ in range(12)], (170, 235, 255), material="Glass")
        piece("Brillo_Destellos", [P("sphere", (rnd.uniform(-0.3, 0.3), rnd.uniform(-1, 1), rnd.uniform(0.6, 1.3)), (0.012, 0.012, 0.05)) for _ in range(8)], (255, 255, 255), material="Neon", fine=True)
        point_light((0, -0.3, 0.6), (0.6, 0.9, 1), 5)


class buho_cuerda:
    ID, RARITY, TITLE = "buho_cuerda", (255, 70, 110), "Búho de Cuerda"

    @staticmethod
    def build():
        brass = tex.veined("laton", (205, 155, 70), (120, 80, 40), scale=4, width=0.015, bump=0.4, rough=0.3)
        copper = skin("cobre", (200, 115, 60), (150, 80, 45), bump=0.2, scale=20, rough=0.3)
        piece("Cuerpo", tex.sculpt("c", brass, [S((0, 0, 0.8), (0.4, 0.36, 0.52)), S((0, -0.03, 1.4), (0.36, 0.32, 0.3))],
                                   [[(s * 0.22, 0, 1.6, 0.08), (s * 0.3, 0, 1.82, 0.02)] for s in (-1, 1)], voxel=0.016), shader=brass, bake=True, budget=2400)
        piece("Placas", [P("torus", (0, 0, 0.55 + k * 0.17), (0.4 - abs(k - 2) * 0.03,) * 3, minor=0.06) for k in range(4)], shader=copper, bake=True, budget=900)
        piece("Remaches", [P("sphere", (math.cos(a) * 0.38, math.sin(a) * 0.34, 0.95), 0.025) for a in [i * 0.52 for i in range(12)]], (80, 60, 45), material="Metal", fine=True)
        for s in (-1, 1):
            piece(f"Lente_{'I' if s < 0 else 'D'}", [P("cyl", (s * 0.15, -0.27, 1.45), (0.14, 0.14, 0.05), rot=(90, 0, 0)), P("torus", (s * 0.15, -0.32, 1.45), (0.14,) * 3, rot=(90, 0, 0), minor=0.15)], (200, 115, 60), material="Metal")
        piece("Iris", [P("cyl", (s * 0.15, -0.33, 1.45), (0.1, 0.1, 0.01), rot=(90, 0, 0), subd=0) for s in (-1, 1)], (110, 240, 255), material="Neon", keep=True)
        piece("Giro_Pupilas", [P("cube", (s * 0.15, -0.345, 1.45), (0.12, 0.005, 0.015), subd=0) for s in (-1, 1)] + [P("cube", (s * 0.15, -0.345, 1.45), (0.015, 0.005, 0.12), subd=0) for s in (-1, 1)], (20, 40, 50), keep=True, pivot=(0, -0.345, 1.45))
        piece("Pico", [P("cone", (0, -0.39, 1.3), (0.05, 0.04, 0.1), rot=(150, 0, 0))], (200, 115, 60), material="Metal")
        # engranajes a la vista en la barriga (dos que giran), llave de cuerda, chispas y vapor
        def gear(c, r, n, rot=(90, 0, 0)):
            g = [P("cyl", c, (r, r, 0.025), rot=rot, subd=0)]
            for i in range(n):
                a = i / n * math.pi * 2
                g.append(P("cube", (c[0] + math.cos(a) * r, c[1], c[2] + math.sin(a) * r), (0.05, 0.04, 0.05), rot=(0, -math.degrees(a), 0), subd=0))
            return g
        piece("Giro_Engranaje", gear((0.06, -0.34, 0.85), 0.2, 12), (230, 180, 70), material="Metal", pivot=(0.06, -0.34, 0.85))
        piece("Giro_EngranajePeque", gear((-0.18, -0.33, 0.62), 0.11, 8), (200, 115, 60), material="Metal", pivot=(-0.18, -0.33, 0.62))
        piece("Giro_Llave", [P("cyl", (0, 0.45, 1.0), (0.03, 0.03, 0.1), rot=(90, 0, 0))] + [P("torus", (s * 0.11, 0.56, 1.0), (0.09,) * 3, rot=(90, 0, 90), minor=0.28) for s in (-1, 1)], (230, 180, 70), material="Metal", pivot=(0, 0.45, 1.0))
        wing = skin("alas", (190, 130, 60), (150, 95, 45), bump=0.3, scale=25, rough=0.3)
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Ala_{side}", tex.sculpt("w", wing, [S((s * 0.43, 0.05, 0.9), (0.1, 0.3, 0.42), (10, 0, s * 10))],
                                            [[(s * 0.45, 0.05 + k * 0.08, 0.68 - k * 0.04, 0.07), (s * 0.48, 0.1 + k * 0.08, 0.42 - k * 0.05, 0.012)] for k in range(3)], voxel=0.013, smooth=6),
                  shader=wing, bake=True, budget=700, anim="Ala", pivot=(s * 0.38, 0, 1.2))
        steam = tex.furry("vapor", (255, 255, 255), (210, 215, 225), fur=0.05, rough=0.9)
        piece("Vapor", tex.sculpt("v", steam, puffs([((s * 0.3, 0.05, 1.92), 0.08) for s in (-1, 1)] + [((s * 0.38, 0.05, 2.08), 0.06) for s in (-1, 1)], 3), [], voxel=0.01, smooth=4), shader=steam, bake=True, budget=700)
        rnd = random.Random(2)
        piece("Brillo_Chispas", [P("sphere", (rnd.uniform(-0.5, 0.5), -0.4 + rnd.uniform(-0.1, 0.1), rnd.uniform(0.4, 1.2)), 0.018) for _ in range(10)], (110, 240, 255), material="Neon", fine=True)
        piece("Patas", [P("cone", (s * 0.14 + k * 0.05, -0.22, 0.3), (0.03, 0.03, 0.08), rot=(80, 0, 0)) for s in (-1, 1) for k in (-1, 0, 1)], (90, 70, 50), material="Metal")
        point_light((0, -0.6, 1.45), (0.5, 0.9, 1), 5)


class coloso_bronce:
    ID, RARITY, TITLE = "coloso_bronce", (255, 70, 110), "Coloso de Bronce"

    @staticmethod
    def build():
        bronze = tex.veined("bronce", (180, 120, 60), (90, 160, 140), scale=3, width=0.03, bump=0.5, rough=0.3)  # pátina verde en las grietas
        piece("Cuerpo", tex.sculpt("c", bronze, [S((0, 0, 1.2), (0.5, 0.36, 0.42)), S((0, 0, 0.8), (0.36, 0.3, 0.3))],
                                   [[(s * 0.22, 0, 0.7, 0.15), (s * 0.25, -0.02, 0.35, 0.13), (s * 0.25, -0.06, 0.1, 0.13)] for s in (-1, 1)], voxel=0.016), shader=bronze, bake=True, budget=2600)
        piece("Craneo", [P("cube", (0, -0.05, 1.76), (0.19, 0.18, 0.17), subd=1, bevel=0.04), P("cyl", (0, -0.05, 1.95), (0.14, 0.14, 0.03))], shader=bronze, bake=True, budget=600)
        piece("Visor", [P("cube", (0, -0.235, 1.78), (0.15, 0.015, 0.035), subd=0)], (90, 255, 210), material="Neon", keep=True)
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Pendulo_Brazo{side}", tex.sculpt("a", bronze, [S((s * 0.6, 0, 1.45), (0.21, 0.21, 0.21)), S((s * 0.75, -0.14, 0.6), (0.17, 0.17, 0.15))],
                                                      [[(s * 0.6, 0, 1.4, 0.13), (s * 0.72, -0.05, 1.05, 0.11), (s * 0.74, -0.12, 0.7, 0.1)]], voxel=0.015),
                  shader=bronze, bake=True, budget=900, anim="Pendulo", pivot=(s * 0.58, 0, 1.45))
            piece(f"Pie_{side}", [P("cube", (s * 0.25, -0.1, 0.06), (0.14, 0.2, 0.06), subd=1, bevel=0.03)], shader=bronze, bake=True, budget=200)
        moss = tex.furry("musgo", (70, 140, 60), (120, 190, 80), fur=0.9, fur_scale=90, rough=0.9)
        piece("Musgo", tex.sculpt("m", moss, [S(c, (r, r, r * 0.6)) for c, r in (((0.35, -0.1, 1.58), 0.13), ((-0.4, 0.05, 1.56), 0.11), ((0.1, 0.22, 1.45), 0.14),
                                                                                     ((0.62, 0, 1.64), 0.09), ((-0.2, -0.3, 0.98), 0.07), ((0.0, -0.05, 2.0), 0.08))], [], voxel=0.012, smooth=4),
              shader=moss, bake=True, budget=900)
        piece("Florecillas", [P("sphere", (x, y, z), 0.03) for x, y, z in ((0.35, -0.2, 1.66), (-0.4, -0.04, 1.63), (0.12, 0.12, 1.55), (0.62, -0.06, 1.7), (0.02, -0.12, 2.05))], (255, 230, 120), fine=True)
        piece("Mariposa", [P("sphere", (0.25 + s * 0.04, -0.4, 2.15), (0.04, 0.008, 0.03), rot=(0, s * 30, 0)) for s in (-1, 1)], (120, 200, 255), material="Neon", anim="Gota")
        def gear(c, r, n):
            g = [P("cyl", c, (r, r, 0.03), rot=(90, 0, 0), subd=0)]
            for i in range(n):
                a = i / n * math.pi * 2
                g.append(P("cube", (c[0] + math.cos(a) * r, c[1], c[2] + math.sin(a) * r), (0.05, 0.04, 0.05), rot=(0, -math.degrees(a), 0), subd=0))
            return g
        piece("Giro_Engranaje", gear((0, -0.38, 1.2), 0.2, 12), (110, 80, 50), material="Metal", pivot=(0, -0.38, 1.2))
        piece("Brillo_Nucleo", [P("sphere", (0, -0.42, 1.2), 0.08)], (90, 255, 210), material="Neon")
        piece("Brillo_Venas", [lib.tube("v", [(0, -0.4, 1.2), (x * 0.25, -0.35, 1.2 + z * 0.2), (x * 0.45, -0.25, 1.2 + z * 0.35)], 0.014, 0.008, M()) for x, z in ((1, 1), (-1, 1), (1, -1), (-1, -1))], (90, 255, 210), material="Neon")
        piece("Hombreras", [P("sphere", (s * 0.62, 0, 1.6), (0.24, 0.2, 0.1)) for s in (-1, 1)], (210, 160, 70), material="Metal")
        point_light((0, -0.7, 1.25), (0.4, 1, 0.8), 6)


class sombra_pendulo:
    ID, RARITY, TITLE = "sombra_pendulo", (60, 235, 225), "Sombra de Péndulo"

    @staticmethod
    def build():
        shadow = tex.furry("sombra", (35, 25, 60), (90, 60, 150), (55, 40, 95), fur=0.15, fur_scale=12, rough=0.6)
        wisps = [[(x, y, 0.55, 0.14), (x * 1.5, y * 1.5, 0.3, 0.08), (x * 2.2, y * 2.2 + 0.1, 0.1, 0.01)] for x, y in ((0.15, 0.05), (-0.15, 0.05), (0.0, 0.18), (0.08, -0.15), (-0.1, -0.12))]
        wisps += [[(s * 0.3, -0.02, 1.25, 0.08), (s * 0.48, -0.1, 1.0, 0.06), (s * 0.45, -0.18, 0.78, 0.035)] for s in (-1, 1)]
        piece("Cuerpo", tex.sculpt("c", shadow, [S((0, 0, 1.1), (0.34, 0.3, 0.45)), S((0, 0, 0.7), (0.26, 0.24, 0.3)), S((0, -0.02, 1.62), (0.27, 0.25, 0.25))], wisps, voxel=0.014),
              shader=shadow, bake=True, budget=3000)
        piece("Ojos", [P("sphere", (s * 0.1, -0.25, 1.65), (0.06, 0.02, 0.035), rot=(0, s * -15, 0)) for s in (-1, 1)], (255, 240, 150), material="Neon", keep=True)
        piece("Sonrisa", [P("torus", (0, -0.24, 1.55), (0.1, 0.1, 0.1), rot=(90, 0, 0), minor=0.12)], (255, 240, 150), material="Neon", keep=True)
        piece("Brillo_Corona", [P("cone", (math.cos(a) * 0.2, math.sin(a) * 0.17, 1.92), (0.04, 0.04, 0.12)) for a in [i * 1.2566 for i in range(5)]], (255, 210, 90), material="Neon")
        # péndulo de oro con esfera de reloj, arcos de tiempo y números flotantes
        piece("Pendulo_Cadena", [P("cyl", (0.45, -0.18, 0.55), (0.012, 0.012, 0.22), subd=0)], (230, 190, 80), material="Metal", pivot=(0.45, -0.18, 0.78))
        piece("Pendulo_Disco", [P("cyl", (0.45, -0.18, 0.28), (0.12, 0.12, 0.02), rot=(90, 0, 0)), P("torus", (0.45, -0.2, 0.28), (0.12,) * 3, rot=(90, 0, 0), minor=0.12)], (240, 200, 90), material="Metal", pivot=(0.45, -0.18, 0.78))
        piece("Pendulo_Esfera", [P("cyl", (0.45, -0.21, 0.28), (0.09, 0.09, 0.005), rot=(90, 0, 0), subd=0)], (255, 250, 220), material="Neon", pivot=(0.45, -0.18, 0.78))
        arcs = [P("torus", (0, 0, 1.1), (r, r, r), rot=(70, 0, k * 40), minor=0.01 / r) for k, r in enumerate((0.6, 0.72, 0.85))]
        piece("Giro_Arcos", arcs, (150, 120, 255), material="Neon", pivot=(0, 0, 1.1))
        rnd = random.Random(7)
        piece("Gota_Numeros", [P("cube", (rnd.uniform(-0.7, 0.7), rnd.uniform(-0.3, 0.3), rnd.uniform(0.6, 1.9)), (0.015, 0.006, 0.06), rot=(0, rnd.uniform(-30, 30), 0), subd=0) for _ in range(12)], (255, 230, 150), material="Neon", fine=True)
        smoke = tex.furry("humo", (70, 50, 120), (20, 15, 35), fur=0.05, rough=0.9)
        piece("Humo", tex.sculpt("h", smoke, puffs([((x, y, 0.05), r) for x, y, r in ((0.3, 0.2, 0.12), (-0.3, 0.1, 0.12), (0.1, -0.25, 0.1), (-0.15, 0.3, 0.1))], 5), [], voxel=0.013, smooth=4),
              shader=smoke, bake=True, budget=1200)
        point_light((0, -0.5, 1.4), (0.7, 0.5, 1), 6)
        point_light((0.45, -0.4, 0.3), (1, 0.85, 0.5), 3)


class zorro_tinta:
    ID, RARITY, TITLE = "zorro_tinta", (60, 235, 225), "Zorro de Tinta"
    WIDE = 1.7

    @staticmethod
    def build():
        ink = tex.furry("tinta", (18, 18, 30), (55, 60, 95), (30, 32, 55), fur=0.45, fur_scale=60, rough=0.25, flow=(1, 0.3, 1))
        shapes = [S((0, -0.25, 0.68), (0.2, 0.27, 0.22)), S((0, 0.1, 0.66), (0.17, 0.3, 0.19)), S((0, -0.48, 0.86), (0.13, 0.15, 0.18), (-35, 0, 0)),
                  S((0, -0.62, 1.02), (0.15, 0.16, 0.13)), S((0, -0.8, 0.98), (0.07, 0.15, 0.065), (8, 0, 0))]
        limbs = []
        for s in (-1, 1):
            limbs += [[(s * 0.12, -0.3, 0.6, 0.09), (s * 0.13, -0.34, 0.32, 0.05), (s * 0.13, -0.38, 0.05, 0.045)],
                      [(s * 0.12, 0.28, 0.62, 0.12), (s * 0.13, 0.36, 0.38, 0.06), (s * 0.13, 0.32, 0.05, 0.045)],
                      [(s * 0.12, -0.62, 0.97, 0.05), (s * 0.22, -0.56, 0.93, 0.02), (s * 0.26, -0.52, 0.9, 0.005)]]
        piece("Cuerpo", tex.sculpt("c", ink, shapes, limbs, voxel=0.012), shader=ink, bake=True, budget=3000)
        piece("Orejas", [P("cone", (s * 0.1, -0.6, 1.2), (0.075, 0.04, 0.16), rot=(-8, s * 15, 0)) for s in (-1, 1)], shader=ink, bake=True, budget=300)
        piece("Brillo_Orejas", [P("cone", (s * 0.1, -0.625, 1.18), (0.045, 0.012, 0.11), rot=(-8, s * 15, 0)) for s in (-1, 1)], (255, 200, 80), material="Neon")
        eyes_almond((0, -0.76, 1.08), 0.07, 0.022, (255, 200, 60), tilt=30, glow=1)
        tails = []
        for ang in (-50, -25, 0, 25, 50):
            a = math.radians(ang)
            tails.append([(0, 0.35, 0.68, 0.08), (math.sin(a) * 0.3, 0.62, 0.92, 0.12), (math.sin(a) * 0.55, 0.78, 1.25, 0.11), (math.sin(a) * 0.62, 0.72, 1.5, 0.02)])
        piece("Cola", tex.sculpt("t", ink, [], tails, voxel=0.013, smooth=10), shader=ink, bake=True, budget=2200, pivot=(0, 0.35, 0.68))
        # puntas de las colas como pinceladas de tinta azul brillante, salpicaduras y caligrafía dorada
        piece("Brillo_Puntas", [P("sphere", (math.sin(math.radians(a)) * 0.6, 0.73, 1.47), (0.06, 0.06, 0.09)) for a in (-50, -25, 0, 25, 50)], (70, 140, 255), material="Neon")
        piece("Marcas", [lib.tube("m", [(s * 0.17, -0.25, 0.8), (s * 0.19, -0.05, 0.84), (s * 0.17, 0.2, 0.78), (s * 0.12, 0.32, 0.8)], 0.016, 0.006, M()) for s in (-1, 1)]
              + [lib.tube("m", [(0, -0.72, 1.12), (0, -0.6, 1.16), (0, -0.48, 1.1)], 0.012, 0.005, M())], (255, 200, 80), material="Neon")
        rnd = random.Random(3)
        piece("Charco", [P("cyl", (rnd.uniform(-0.3, 0.3), rnd.uniform(-0.4, 0.4), 0.005), (rnd.uniform(0.08, 0.2), rnd.uniform(0.06, 0.15), 0.005), subd=0) for _ in range(6)], (20, 20, 35), material="Glass")
        piece("Gota_Tinta", [P("sphere", (rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.8), rnd.uniform(0.2, 1.5)), (0.03, 0.03, 0.045)) for _ in range(10)], (40, 70, 200), material="Neon", fine=True)
        point_light((0, 0.7, 1.4), (0.4, 0.6, 1), 5)
        point_light((0, -0.9, 1.1), (1, 0.8, 0.4), 3)


class caballero_eclipse:
    ID, RARITY, TITLE = "caballero_eclipse", (60, 235, 225), "Caballero del Eclipse"

    @staticmethod
    def build():
        armor = tex.veined("armadura", (55, 50, 80), (200, 170, 255), scale=3, width=0.012, bump=0.3, rough=0.25)
        gold = skin("oro", (235, 200, 110), (180, 140, 60), bump=0.2, scale=20, rough=0.25)
        piece("Cuerpo", tex.sculpt("c", armor, [S((0, 0, 1.15), (0.3, 0.22, 0.32)), S((0, 0, 0.82), (0.24, 0.2, 0.18)), S((0, -0.02, 1.62), (0.2, 0.21, 0.22))],
                                   [[(s * 0.12, 0, 0.75, 0.09), (s * 0.13, -0.02, 0.4, 0.08), (s * 0.13, -0.04, 0.1, 0.08)] for s in (-1, 1)]
                                   + [[(s * 0.34, 0, 1.3, 0.07), (s * 0.42, -0.08, 1.05, 0.06), (s * 0.4, -0.16, 0.95, 0.06)] for s in (-1, 1)], voxel=0.013),
              shader=armor, bake=True, budget=2600)
        piece("Visera", [P("cube", (0, -0.22, 1.63), (0.22, 0.02, 0.03), subd=0)], (230, 220, 255), material="Neon", keep=True)
        piece("Hombreras", [P("sphere", (s * 0.34, 0, 1.38), (0.17, 0.17, 0.1)) for s in (-1, 1)] + [P("torus", (0, 0, 1.48), (0.2, 0.2, 0.2), minor=0.15)], shader=gold, bake=True, budget=700)
        cape = tex.veined("capa", (60, 30, 110), (190, 150, 255), scale=5, width=0.01, bump=0.1, rough=0.6)
        piece("Cola_Capa", lib.membrane("k", [(-0.3, 0.18, 1.45), (0.3, 0.18, 1.45), (0.45, 0.42, 0.25), *lib.scallop((0.45, 0.42, 0.25), (-0.45, 0.42, 0.25), 0.06, 6, (0, 0, 1)), (-0.45, 0.42, 0.25)],
                                          M(), thickness=0.03, sag=0.08, subd=2), shader=cape, bake=True, budget=800, anim="Cola", pivot=(0, 0.18, 1.45))
        piece("Penacho", tex.sculpt("p", cape, [], [[(0, 0, 1.82, 0.05), (0, 0.15, 1.95, 0.06), (0, 0.35, 1.82, 0.04), (0, 0.45, 1.6, 0.01)]], voxel=0.01), shader=cape, bake=True, budget=400)
        # escudo de eclipse (sol tapado con corona de luz), espada de luz y polvo de estrellas
        piece("Escudo", [P("cyl", (-0.46, -0.22, 1.0), (0.3, 0.3, 0.035), rot=(90, 0, -10))], (20, 18, 30))
        piece("Brillo_Corona", [P("torus", (-0.46, -0.26, 1.0), (0.3, 0.3, 0.3), rot=(90, 0, -10), minor=0.09)], (255, 220, 120), material="Neon")
        rays = [P("cone", (-0.46 + math.cos(a) * 0.4, -0.26, 1.0 + math.sin(a) * 0.4), (0.03, 0.01, 0.08), rot=(0, 90 - math.degrees(a), 0), subd=0) for a in [i * math.pi / 6 for i in range(12)]]
        piece("Giro_Rayos", rays, (255, 200, 90), material="Neon", pivot=(-0.46, -0.26, 1.0))
        piece("Espada", [P("cube", (0.42, -0.24, 0.88), (0.22, 0.05, 0.04), subd=0), P("cyl", (0.42, -0.2, 0.78), (0.025, 0.025, 0.08), subd=0), P("sphere", (0.42, -0.2, 0.69), 0.035)], (230, 200, 110), material="Metal")
        piece("Brillo_Filo", [P("cube", (0.42, -0.25, 1.32), (0.06, 0.02, 0.85), subd=0)], (190, 160, 255), material="Neon")
        rnd = random.Random(11)
        piece("Gota_Estrellas", [P("sphere", (rnd.uniform(-0.8, 0.8), rnd.uniform(-0.5, 0.5), rnd.uniform(0.3, 2.0)), (0.02, 0.02, 0.02)) for _ in range(16)], (255, 255, 230), material="Neon", fine=True)
        point_light((-0.46, -0.6, 1.0), (1, 0.85, 0.5), 6)
        point_light((0.42, -0.6, 1.3), (0.7, 0.6, 1), 5)


LOTE = [leviatan_espejo, buho_cuerda, coloso_bronce, sombra_pendulo, zorro_tinta, caballero_eclipse]
