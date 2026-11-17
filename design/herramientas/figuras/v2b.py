"""Bichos v2 (lote B): comunes y poco comunes."""
import math
import random

from mathutils import Vector

import lib
import tex
from fig2 import bolt, piece, point_light, puffs
from v2a import S, eyes_almond



def P(kind, loc, scale, rot=(0, 0, 0), subd=1, **kw):
    if not isinstance(scale, (list, tuple)):
        scale = (scale, scale, scale)
    return lib.prim("x", kind, lib.mat("_d", (200, 200, 200)), loc, scale, rot=rot, subd=subd, **kw)


def skin(name, top, bottom, mid=None, bump=0.25, scale=40, spots=None, rough=0.45):
    return tex.furry(name, top, bottom, mid, fur=bump, fur_scale=scale, rough=rough, spots=spots, flow=(1, 1, 1))


def flame(base, direction, length, width):
    """Llama en capas (azul dentro, naranja y amarillo fuera)."""
    d = Vector(direction).normalized()
    rot = tuple(math.degrees(a) for a in d.to_track_quat("Z", "Y").to_euler())
    outer = P("cone", tuple(Vector(base) + d * length * 0.5), (width, width, length * 0.5), rot)
    mid = P("cone", tuple(Vector(base) + d * length * 0.38), (width * 0.7, width * 0.7, length * 0.38), rot)
    inner = P("cone", tuple(Vector(base) + d * length * 0.25), (width * 0.42, width * 0.42, length * 0.25), rot)
    return outer, mid, inner


def rings(center, axis_rot, radii, minor):
    return [P("torus", center, (r, r, r), rot=axis_rot, minor=minor / r) for r in radii]


class caracol_turbo:
    ID, RARITY, TITLE = "caracol_turbo", (200, 200, 200), "Caracol Turbo"

    @staticmethod
    def build():
        body = skin("babosa", (215, 180, 130), (250, 225, 180), bump=0.15, scale=30, rough=0.25)
        piece("Cuerpo", tex.sculpt("c", body, [S((0, -0.15, 0.13), (0.3, 1.0, 0.14)), S((0, -0.92, 0.36), (0.19, 0.22, 0.3), (-15, 0, 0)),
                                                S((0, -1.05, 0.62), (0.17, 0.18, 0.16))], [], voxel=0.014), shader=body, bake=True, budget=2600)
        piece("Cola", tex.sculpt("a", body, [], [[(s * 0.06, -1.1, 0.72, 0.035), (s * 0.13, -1.18, 0.95, 0.022), (s * 0.18, -1.2, 1.12, 0.02)] for s in (-1, 1)]
                                 + [], voxel=0.01, smooth=6), shader=body, bake=True, budget=500, pivot=(0, -1.1, 0.7))
        piece("Antenas", [P("sphere", (s * 0.18, -1.2, 1.15), 0.055) for s in (-1, 1)], (250, 225, 180))
        eyes_almond((0, -1.2, 0.68), 0.08, 0.035, (90, 200, 255), tilt=5, glow=0)
        piece("Gafas", [P("torus", (s * 0.08, -1.26, 0.7), (0.065, 0.065, 0.065), rot=(90, 0, 0), minor=0.3) for s in (-1, 1)]
              + [P("torus", (0, -1.08, 0.7), (0.19, 0.19, 0.19), minor=0.05)], (230, 50, 60), keep=True)
        piece("Cristales", [P("cyl", (s * 0.08, -1.28, 0.7), (0.055, 0.055, 0.005), rot=(90, 0, 0)) for s in (-1, 1)], (180, 230, 255), material="Glass", keep=True)
        # concha en espiral (tubo que se enrolla) con franjas de carreras
        shellm = skin("concha", (40, 110, 230), (20, 60, 160), (30, 90, 210), bump=0.1, scale=12, rough=0.2)
        pts = []
        for i in range(40):
            t = i / 39
            a = t * math.pi * 3.2
            r = 0.42 * (1 - t * 0.85)
            pts.append((0.0, 0.28 + math.cos(a) * r, 0.62 + math.sin(a) * r, 0.24 * (1 - t * 0.8) + 0.02))
        piece("Concha", tex.sculpt("s", shellm, [], [pts], voxel=0.014, smooth=8), shader=shellm, bake=True, budget=2400)
        lines = []
        for side in (-1, 1):
            lp = [(side * (p[3] * 0.92), p[1], p[2], 0.022) for p in pts[:34]]
            lines.append(lib.tube("l", [q[:3] for q in lp], 0.024, 0.012, lib.mat("_d", (1, 1, 1)), res=24))
        piece("Franja", lines, (250, 250, 250))
        piece("Rayo", [P("cube", (s2 * 0.25, 0.28, 0.62), (0.01, 0.08, 0.18), rot=(0, 0, 0), subd=0) for s2 in (-1, 1)], (255, 210, 40))
        # dos toberas turbo cromadas con llamas enormes
        noz, fl1, fl2, fl3 = [], [], [], []
        for s in (-1, 1):
            base = Vector((s * 0.13, 0.62, 1.02))
            d = Vector((s * 0.25, 0.8, 0.45)).normalized()
            rot = tuple(math.degrees(a) for a in d.to_track_quat("Z", "Y").to_euler())
            noz += [P("cyl", tuple(base), (0.09, 0.09, 0.12), rot=rot, subd=0), P("torus", tuple(base + d * 0.12), (0.095, 0.095, 0.095), rot=rot, minor=0.25)]
            o, m, i = flame(tuple(base + d * 0.12), tuple(d), 1.5, 0.24)
            fl1.append(o); fl2.append(m); fl3.append(i)
            point_light(tuple(base + d * 0.4), (1.0, 0.6, 0.2), 8)
        piece("Toberas", noz, (190, 195, 205), material="Metal")
        piece("Brillo_Llama", fl1, (255, 110, 30), material="Neon")
        piece("Brillo_LlamaMedia", fl2, (255, 210, 60), material="Neon")
        piece("Brillo_LlamaAzul", fl3, (120, 200, 255), material="Neon")
        piece("Estela", [P("cube", (s * 0.22, 0.2 + k * 0.25, 0.08 + k * 0.03), (0.01, 0.12, 0.01), subd=0) for s in (-1, 1) for k in range(3)], (255, 255, 255), material="Neon", fine=True)


class estrella_ninja:
    ID, RARITY, TITLE = "estrella_ninja", (200, 200, 200), "Estrella Ninja"
    YAW = -22

    @staticmethod
    def build():
        star = skin("estrella", (250, 120, 50), (255, 175, 110), bump=0.6, scale=55, spots=((255, 225, 170), 9))
        shapes = [S((0, 0, 0.62), (0.34, 0.2, 0.34))]
        limbs = []
        for k in range(5):
            a = math.radians(90 + k * 72)
            d = Vector((math.cos(a), 0, math.sin(a)))
            curl = Vector((0, -0.12 if k % 2 else 0.08, 0))
            limbs.append([(*(Vector((0, 0, 0.62)) + d * 0.25), 0.2), (*(Vector((0, 0, 0.62)) + d * 0.6 + curl * 0.5), 0.13), (*(Vector((0, 0, 0.62)) + d * 0.95 + curl), 0.04)])
        piece("Cuerpo", tex.sculpt("c", star, shapes, limbs, voxel=0.016), shader=star, bake=True, budget=3200)
        eyes_almond((0, -0.2, 0.72), 0.1, 0.045, (60, 40, 30), tilt=-10, glow=0, brow_shader=lib.mat("_b", (120, 50, 30)))
        band = skin("cinta", (220, 30, 45), (160, 20, 30), bump=0.2, scale=25)
        piece("Cinta", [P("torus", (0, -0.0, 0.84), (0.27, 0.27, 0.27), rot=(80, 0, 0), minor=0.17)], shader=band, bake=True, budget=500)
        piece("Cola_Cinta", tex.sculpt("t", band, [], [[(0.22, 0.1, 0.92, 0.05), (0.5, 0.25, 1.0, 0.045), (0.75, 0.32, 0.88, 0.035), (0.92, 0.3, 0.98, 0.02)],
                                                       [(0.22, 0.1, 0.9, 0.05), (0.45, 0.3, 0.8, 0.045), (0.68, 0.4, 0.66, 0.03), (0.8, 0.42, 0.7, 0.015)]], voxel=0.012, smooth=6),
              shader=band, bake=True, budget=700, pivot=(0.22, 0.1, 0.9))
        # shurikens que orbitan a su alrededor + estela de giro
        sh = []
        for k, (x, z) in enumerate(((0.75, 0.3), (-0.72, 1.05), (0.55, 1.35))):
            sh.append(P("cyl", (x, -0.1, z), (0.11, 0.11, 0.012), rot=(90, 0, k * 20), subd=0))
            for j in range(4):
                a = math.radians(j * 90 + k * 20)
                sh.append(P("cone", (x + math.cos(a) * 0.12, -0.1, z + math.sin(a) * 0.12), (0.045, 0.045, 0.07), rot=(0, 90 - math.degrees(a), 0), subd=0))
        piece("Giro_Shurikens", sh, (200, 205, 215), material="Metal", pivot=(0, 0, 0.62))
        piece("Brillo_Estela", [P("torus", (0, -0.1, 0.75), (0.85, 0.85, 0.85), rot=(90, 0, 0), minor=0.012)], (180, 230, 255), material="Neon", fine=True)
        # humo ninja en la base
        smoke = skin("humo", (190, 170, 230), (120, 100, 170), bump=0.1, scale=10, rough=0.9)
        piece("Humo", tex.sculpt("h", smoke, puffs([((x, y, 0.06), r) for x, y, r in ((0.3, 0.1, 0.13), (-0.3, 0.0, 0.12), (0.0, 0.2, 0.14), (0.15, -0.2, 0.1), (-0.18, -0.18, 0.1))], 4), [], voxel=0.014, smooth=5),
              shader=smoke, bake=True, budget=1600)


class pulpo_cubo:
    ID, RARITY, TITLE = "pulpo_cubo", (200, 200, 200), "Pulpo Cubo"

    @staticmethod
    def build():
        sk = skin("pulpo", (140, 70, 200), (220, 170, 240), (175, 110, 220), bump=0.3, scale=30, spots=((110, 50, 170), 14))
        limbs = []
        for k in range(8):
            a = math.radians(k * 45 + 22)
            d = Vector((math.cos(a), math.sin(a), 0))
            side = Vector((-d.y, d.x, 0)) * (1 if k % 2 else -1)
            pts = [Vector((0, 0, 0.5)) + d * 0.22, Vector((0, 0, 0.2)) + d * 0.5, Vector((0, 0, 0.06)) + d * 0.82 + side * 0.1,
                   Vector((0, 0, 0.12)) + d * 1.02 + side * 0.28, Vector((0, 0, 0.26)) + d * 1.0 + side * 0.38]
            limbs.append([(*p, r) for p, r in zip(pts, (0.13, 0.1, 0.07, 0.04, 0.012))])
        piece("Cuerpo", tex.sculpt("c", sk, [S((0, 0.04, 0.82), (0.42, 0.4, 0.44)), S((0, 0.12, 1.08), (0.33, 0.33, 0.3))], limbs, voxel=0.016), shader=sk, bake=True, budget=4200)
        rnd = random.Random(2)
        suck = []
        for k in range(8):
            a = math.radians(k * 45 + 22)
            d = Vector((math.cos(a), math.sin(a), 0))
            for t in (0.42, 0.62, 0.8):
                suck.append(P("sphere", tuple(Vector((0, 0, 0.13 if t > 0.55 else 0.19)) + d * t - Vector((0, 0, 0.06))), (0.035, 0.035, 0.02), subd=1))
        piece("Ventosas", suck, (240, 200, 245), fine=True)
        eyes_almond((0, -0.38, 0.9), 0.17, 0.06, (40, 30, 60), tilt=-5, glow=0)
        pail = skin("cubo", (230, 45, 50), (180, 30, 40), bump=0.05, scale=8, rough=0.3)
        piece("Cubo", [P("cone", (0, 0.1, 1.45), (0.3, 0.3, 0.24), subd=0, r2=1.28), P("torus", (0, 0.1, 1.69), (0.385, 0.385, 0.385), minor=0.05)], shader=pail, bake=True, budget=800)
        piece("Asa", [P("torus", (0, 0.1, 1.7), (0.37, 0.37, 0.37), rot=(90, 0, 0), minor=0.035)], (190, 195, 205), material="Metal")
        # agua que rebosa del cubo: chorro, gotas y burbujas
        water = []
        for k, (x, y) in enumerate(((0.3, -0.2), (-0.25, -0.25), (0.05, -0.36))):
            water.append(P("cone", (x, y, 1.55), (0.07, 0.07, 0.09), rot=(160 + k * 8, k * 10, 0)))
        water.append(P("cyl", (0, 0.1, 1.66), (0.36, 0.36, 0.01), subd=0))
        piece("Agua", water, (120, 210, 255), material="Glass")
        piece("Gota_Agua", [P("sphere", (0.38 + k * 0.05, -0.35 - k * 0.04, 1.35 - k * 0.2), (0.035, 0.035, 0.05)) for k in range(4)], (150, 220, 255), material="Glass")
        piece("Burbujas", [P("sphere", (rnd.uniform(-0.6, 0.6), rnd.uniform(-0.5, 0.4), rnd.uniform(1.0, 1.9)), rnd.uniform(0.025, 0.06)) for _ in range(9)], (200, 240, 255), material="Glass", fine=True)


class gaviota_pirata:
    ID, RARITY, TITLE = "gaviota_pirata", (90, 200, 90), "Gaviota Pirata"
    WIDE = 1.7

    @staticmethod
    def build():
        feathers = tex.furry("plumas", (235, 238, 242), (255, 255, 255), fur=0.35, fur_scale=45, flow=(1, 0.35, 1))
        piece("Cuerpo", tex.sculpt("c", feathers, [S((0, 0, 0.78), (0.25, 0.48, 0.28), (14, 0, 0)), S((0, -0.38, 1.08), (0.17, 0.19, 0.17))],
                                   [[(0, 0.35, 0.82, 0.14), (0, 0.6, 0.86, 0.06), (0, 0.72, 0.88, 0.01)]], voxel=0.014), shader=feathers, bake=True, budget=2600)
        piece("Pico", [P("cone", (0, -0.63, 1.06), (0.055, 0.04, 0.15), rot=(95, 0, 0)), P("sphere", (0, -0.7, 1.02), (0.025, 0.04, 0.02))], (250, 190, 50))
        piece("PicoMancha", [P("sphere", (0, -0.73, 1.03), (0.018, 0.02, 0.018))], (220, 50, 40), fine=True)
        wingm = tex.furry("ala", (120, 130, 150), (200, 205, 215), fur=0.4, fur_scale=40, flow=(0.3, 1, 1))
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Ala_{side}", tex.sculpt("w", wingm, [S((s * 0.42, 0.08, 1.08), (0.3, 0.22, 0.06), (0, s * -22, 0)), S((s * 0.8, 0.14, 1.28), (0.28, 0.18, 0.045), (0, s * -32, 0))],
                                            [[(s * 0.9, 0.1 + k * 0.07, 1.33 - k * 0.04, 0.05), (s * 1.12, 0.12 + k * 0.08, 1.48 - k * 0.07, 0.03), (s * 1.24, 0.14 + k * 0.09, 1.56 - k * 0.1, 0.006)] for k in range(4)],
                                            voxel=0.012, smooth=6), shader=wingm, bake=True, budget=1000, anim="Ala", pivot=(s * 0.2, 0.0, 0.92))
            piece(f"AlaPunta_{side}", [P("cone", (s * 1.2, 0.14 + k * 0.09, 1.53 - k * 0.1), (0.035, 0.012, 0.08), rot=(0, s * -55, 0)) for k in range(4)], (30, 30, 40), anim="Ala", pivot=(s * 0.2, 0.0, 0.92))
        piece("Patas", [lib.tube("p", [(s * 0.1, 0.05, 0.52), (s * 0.11, 0.0, 0.25), (s * 0.12, -0.05, 0.03)], 0.03, 0.022, lib.mat("_d", (200, 200, 200))) for s in (-1, 1)]
              + [P("sphere", (s * 0.12, -0.13, 0.02), (0.08, 0.11, 0.015)) for s in (-1, 1)], (250, 160, 60))
        eyes_almond((0, -0.48, 1.13), 0.1, 0.025, (250, 200, 60), tilt=-15, glow=0)
        piece("Parche", [P("sphere", (0.1, -0.53, 1.14), (0.055, 0.025, 0.05)), P("torus", (0, -0.4, 1.13), (0.18, 0.18, 0.18), rot=(10, 30, 0), minor=0.04)], (25, 25, 30), keep=True)
        hat = skin("sombrero", (40, 35, 45), (20, 18, 25), bump=0.1, scale=10)
        piece("Sombrero", [P("cyl", (0, -0.36, 1.27), (0.3, 0.22, 0.02), subd=1), P("sphere", (0, -0.36, 1.33), (0.17, 0.15, 0.1))]
              + [P("sphere", (s * 0.22, -0.36, 1.32), (0.12, 0.05, 0.08), rot=(0, s * -30, 0)) for s in (-1, 1)], shader=hat, bake=True, budget=900)
        piece("Calavera", [P("sphere", (0, -0.51, 1.36), 0.035), P("cube", (0, -0.51, 1.32), (0.05, 0.005, 0.005), rot=(0, 45, 0), subd=0), P("cube", (0, -0.51, 1.32), (0.05, 0.005, 0.005), rot=(0, -45, 0), subd=0)], (250, 250, 245), fine=True)
        piece("Pendiente", [P("torus", (0.17, -0.42, 1.0), (0.035, 0.035, 0.035), rot=(90, 0, 0), minor=0.25)], (255, 210, 60), material="Metal")
        # tesoro: monedas de oro y una perla
        rnd = random.Random(8)
        coins = [P("cyl", (rnd.uniform(-0.45, 0.45), rnd.uniform(-0.45, 0.3), 0.01 + i * 0.012), (0.085, 0.085, 0.012), rot=(rnd.uniform(-20, 20), rnd.uniform(-20, 20), 0), subd=0) for i in range(12)]
        coins += [P("cyl", (0.38, -0.3, 0.03 + i * 0.024), (0.085, 0.085, 0.012), subd=0) for i in range(6)]
        chest = skin("cofre", (150, 95, 50), (110, 65, 35), bump=0.4, scale=18)
        piece("Cofre", [P("cube", (-0.42, 0.25, 0.08), (0.16, 0.11, 0.08), subd=0, bevel=0.02)], shader=chest, bake=True, budget=200)
        piece("Monedas", coins + [P("cyl", (-0.42, 0.25, 0.17 + i * 0.02), (0.13 - i * 0.03, 0.08 - i * 0.015, 0.012), subd=0) for i in range(3)], (255, 200, 50), material="Metal")
        piece("Brillo_Oro", [P("sphere", (rnd.uniform(-0.4, 0.4), rnd.uniform(-0.4, 0.3), 0.12), (0.02, 0.02, 0.06)) for _ in range(6)], (255, 240, 150), material="Neon", fine=True)
        point_light((0, -0.2, 0.2), (1, 0.85, 0.4), 3)


class erizo_tambor:
    ID, RARITY, TITLE = "erizo_tambor", (90, 200, 90), "Erizo Tambor"

    @staticmethod
    def build():
        fur = tex.furry("cara", (205, 165, 120), (245, 225, 195), fur=0.4, fur_scale=50)
        piece("Cuerpo", tex.sculpt("c", fur, [S((0, 0.1, 0.48), (0.42, 0.55, 0.4)), S((0, -0.48, 0.42), (0.24, 0.24, 0.22)), S((0, -0.68, 0.39), (0.1, 0.15, 0.09))],
                                   [[(s * 0.25, y, 0.3, 0.08), (s * 0.27, y - 0.04, 0.1, 0.06), (s * 0.27, y - 0.08, 0.03, 0.055)] for s in (-1, 1) for y in (-0.3, 0.38)], voxel=0.016),
              shader=fur, bake=True, budget=3000)
        piece("Nariz", [P("sphere", (0, -0.83, 0.42), 0.045)], (30, 25, 25), keep=True)
        eyes_almond((0, -0.66, 0.52), 0.1, 0.03, (40, 25, 15), tilt=10, glow=0)
        rainbow = [(255, 80, 80), (255, 160, 50), (250, 220, 60), (90, 200, 110), (80, 150, 250), (170, 100, 240)]
        rnd = random.Random(4)
        groups = {i: [] for i in range(6)}
        center, R = Vector((0, 0.12, 0.5)), Vector((0.42, 0.56, 0.4))
        k = 0
        for _ in range(260):
            u, th = rnd.uniform(-1, 1), rnd.uniform(0, math.pi * 2)
            n = Vector((math.cos(th) * math.sqrt(1 - u * u), math.sin(th) * math.sqrt(1 - u * u), u))
            if n.z < 0.0 or n.y < -0.4:
                continue
            base = center + Vector((n.x * R.x, n.y * R.y, n.z * R.z)) * 0.9
            d = (Vector((n.x / R.x, n.y / R.y, n.z / R.z)).normalized() + Vector((0, 0.5, 0))).normalized()
            L = rnd.uniform(0.22, 0.32)
            rot = tuple(math.degrees(a) for a in d.to_track_quat("Z", "Y").to_euler())
            band = int((n.y + 0.4) / 1.4 * 6) % 6
            groups[band].append(P("cone", tuple(base + d * L / 2), (0.045, 0.045, L / 2), rot, subd=0))
            k += 1
        for i, c in enumerate(rainbow):
            piece(f"Puas_{i}", groups[i], c)
        drum = skin("tambor", (230, 50, 60), (170, 30, 40), bump=0.05, scale=6, rough=0.3)
        piece("Tambor", [P("cyl", (0.0, -0.95, 0.2), (0.22, 0.22, 0.12), rot=(0, 0, 0), subd=1)], shader=drum, bake=True, budget=500)
        piece("Parche", [P("cyl", (0.0, -0.95, 0.33), (0.21, 0.21, 0.01), subd=0)], (250, 240, 220))
        piece("Aros", [P("torus", (0.0, -0.95, z), (0.225, 0.225, 0.225), minor=0.08) for z in (0.09, 0.32)], (240, 200, 70), material="Metal")
        piece("Pinza_Palillos", [P("cyl", (s * 0.12, -0.85, 0.45), (0.018, 0.018, 0.16), rot=(-40, s * 25, 0), subd=0) for s in (-1, 1)]
              + [P("sphere", (s * 0.17, -0.93, 0.33), 0.04) for s in (-1, 1)], (210, 170, 120), pivot=(0, -0.75, 0.55))
        # ondas de sonido y notas musicales de neón
        piece("Brillo_Ondas", rings((0, -0.95, 0.36), (0, 0, 0), (0.32, 0.45, 0.58), 0.014), (120, 255, 200), material="Neon")
        notes = []
        for k, (x, y, z) in enumerate(((0.45, -0.7, 0.9), (-0.5, -0.6, 1.05), (0.2, -0.5, 1.25))):
            notes += [P("sphere", (x, y, z), (0.06, 0.03, 0.045), rot=(0, -20, 0)), P("cube", (x + 0.05, y, z + 0.12), (0.012, 0.012, 0.12), subd=0),
                      P("cube", (x + 0.1, y, z + 0.22), (0.05, 0.012, 0.02), rot=(0, -20, 0), subd=0)]
        piece("Gota_Notas", notes, (255, 230, 90), material="Neon")
        point_light((0, -0.9, 0.6), (0.5, 1, 0.8), 4)


class camaleon_neon:
    ID, RARITY, TITLE = "camaleon_neon", (90, 200, 90), "Camaleón Neón"

    @staticmethod
    def build():
        sk = skin("camaleon", (40, 190, 80), (170, 240, 120), (90, 220, 100), bump=0.5, scale=70)
        shapes = [S((0, 0.05, 0.62), (0.26, 0.5, 0.33)), S((0, -0.52, 0.76), (0.2, 0.25, 0.22)), S((0, -0.42, 0.98), (0.06, 0.22, 0.1), (-30, 0, 0))]
        limbs = [[(s * 0.2, y, 0.55, 0.075), (s * 0.36, y - 0.04, 0.38, 0.055), (s * 0.34, y - 0.1, 0.05, 0.04)] for s in (-1, 1) for y in (-0.28, 0.3)]
        piece("Cuerpo", tex.sculpt("c", sk, shapes, limbs, voxel=0.015), shader=sk, bake=True, budget=3000)
        tail = []
        for i in range(30):
            t = i / 29
            a = t * math.pi * 2.4
            r = 0.26 * (1 - t * 0.7)
            tail.append((0, 0.6 + math.sin(a) * r * 0.9 + t * 0.15, 0.4 + math.cos(a) * r, 0.11 * (1 - t * 0.75) + 0.02))
        piece("Cola", tex.sculpt("t", sk, [], [[(0, 0.42, 0.62, 0.15)] + tail], voxel=0.013, smooth=8), shader=sk, bake=True, budget=1600, pivot=(0, 0.45, 0.62))
        piece("Torretas", [P("sphere", (s * 0.19, -0.6, 0.86), 0.11) for s in (-1, 1)], (60, 200, 90))
        piece("Iris", [P("sphere", (s * 0.24, -0.68, 0.88), 0.05) for s in (-1, 1)], (255, 240, 80), material="Neon", keep=True)
        piece("Pupilas", [P("sphere", (s * 0.27, -0.71, 0.89), 0.025) for s in (-1, 1)], (15, 15, 20), keep=True)
        # franjas de neón que cambian de color y cresta brillante
        stripes = [P("torus", (0, y, 0.64), (0.27 - abs(y) * 0.12, 0.3 - abs(y) * 0.1, 0.3), rot=(90, 0, 0), minor=0.06) for y in (-0.3, -0.12, 0.06, 0.24)]
        piece("Arcoiris_Franjas", stripes, (255, 60, 220), material="Neon")
        piece("Brillo_Cresta", [P("cone", (0, y, 0.98 - abs(y + 0.1) * 0.25), (0.035, 0.035, 0.07)) for y in (-0.42, -0.25, -0.08, 0.1, 0.28)], (80, 255, 240), material="Neon")
        piece("Lengua", [lib.tube("l", [(0, -0.72, 0.7), (0, -0.95, 0.72), (0.06, -1.15, 0.8)], 0.025, 0.018, lib.mat("_d", (200, 200, 200))), P("sphere", (0.06, -1.17, 0.8), 0.045)], (255, 90, 170), anim="Pendulo", pivot=(0, -0.72, 0.7))
        piece("Gota_Mosca", [P("sphere", (0.1, -1.25, 0.86), 0.035)] + [P("sphere", (0.1 + s * 0.04, -1.25, 0.9), (0.04, 0.012, 0.02)) for s in (-1, 1)], (230, 255, 120), material="Neon")
        for k, c in enumerate(((255, 60, 220), (80, 255, 240))):
            point_light((0, -0.1 + k * 0.4, 0.95), tuple(x / 255 for x in c), 4)


class buho_despertador:
    ID, RARITY, TITLE = "buho_despertador", (70, 140, 255), "Búho Despertador"

    @staticmethod
    def build():
        fe = tex.furry("plumas", (125, 85, 55), (235, 210, 170), (180, 140, 100), fur=0.5, fur_scale=45, flow=(1, 1, 0.4))
        piece("Cuerpo", tex.sculpt("c", fe, [S((0, 0, 0.78), (0.42, 0.38, 0.55)), S((0, -0.04, 1.42), (0.38, 0.34, 0.32))],
                                   [[(s * 0.22, 0.0, 1.62, 0.09), (s * 0.3, 0.0, 1.82, 0.03), (s * 0.32, 0.0, 1.9, 0.006)] for s in (-1, 1)], voxel=0.016),
              shader=fe, bake=True, budget=3000)
        face = skin("cara", (245, 225, 190), (225, 200, 160), bump=0.3, scale=60)
        piece("Cara", [P("sphere", (s * 0.15, -0.26, 1.43), (0.18, 0.08, 0.17)) for s in (-1, 1)], shader=face, bake=True, budget=600)
        eyes_almond((0, -0.32, 1.46), 0.15, 0.07, (255, 170, 40), tilt=0, glow=1, lid_color=(125, 85, 55), pupil_slit=False)
        piece("Pico", [P("cone", (0, -0.42, 1.32), (0.05, 0.04, 0.1), rot=(155, 0, 0))], (250, 180, 50))
        wing = tex.furry("ala", (110, 70, 45), (170, 125, 85), fur=0.6, fur_scale=35, flow=(1, 1, 0.3))
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Ala_{side}", tex.sculpt("w", wing, [S((s * 0.43, 0.04, 0.9), (0.12, 0.3, 0.42), (10, 0, s * 10))],
                                            [[(s * 0.45, 0.04 + k * 0.08, 0.65 - k * 0.04, 0.07), (s * 0.48, 0.1 + k * 0.08, 0.45 - k * 0.05, 0.01)] for k in range(3)], voxel=0.013, smooth=8),
                  shader=wing, bake=True, budget=700, anim="Ala", pivot=(s * 0.4, 0, 1.22))
        clock = skin("reloj", (230, 55, 55), (170, 35, 40), bump=0.05, scale=8, rough=0.3)
        piece("Reloj", [P("cyl", (0, -0.36, 0.78), (0.3, 0.3, 0.07), rot=(90, 0, 0)), P("torus", (0, -0.43, 0.78), (0.3, 0.3, 0.3), rot=(90, 0, 0), minor=0.12)], shader=clock, bake=True, budget=700)
        piece("Esfera", [P("cyl", (0, -0.44, 0.78), (0.25, 0.25, 0.01), rot=(90, 0, 0), subd=0)], (252, 250, 240))
        piece("Marcas", [P("cube", (math.cos(a) * 0.2, -0.455, 0.78 + math.sin(a) * 0.2), (0.012, 0.004, 0.035), rot=(0, -math.degrees(a) + 90, 0), subd=0) for a in [i * math.pi / 6 for i in range(12)]], (40, 40, 45), fine=True)
        piece("Giro_Agujas", [P("cube", (0, -0.46, 0.85), (0.02, 0.006, 0.15), subd=0), P("cube", (0.05, -0.46, 0.78), (0.11, 0.006, 0.02), subd=0)], (30, 30, 35), pivot=(0, -0.46, 0.78))
        piece("Campanas", [P("sphere", (s * 0.27, -0.22, 1.13), (0.13, 0.13, 0.1)) for s in (-1, 1)] + [P("sphere", (0, -0.2, 1.2), 0.03)], (250, 205, 60), material="Metal")
        piece("Martillo", [P("cube", (0, -0.2, 1.15), (0.012, 0.012, 0.1), subd=0), P("sphere", (0, -0.2, 1.24), 0.03)], (200, 200, 210), material="Metal")
        # ondas de alarma que vibran alrededor de las campanas
        waves = []
        for s in (-1, 1):
            for k, r in enumerate((0.2, 0.3, 0.4)):
                waves.append(P("torus", (s * 0.27, -0.22, 1.13), (r, r, r), rot=(90, 0, 90), minor=0.012 / r))
        piece("Brillo_Alarma", waves, (255, 230, 90), material="Neon")
        point_light((0, -0.5, 1.15), (1, 0.85, 0.4), 5)
        piece("Patas", [P("cone", (s * 0.14 + k * 0.05, -0.22, 0.25), (0.03, 0.03, 0.08), rot=(80, 0, 0)) for s in (-1, 1) for k in (-1, 0, 1)], (240, 170, 60))


LOTE = [caracol_turbo, estrella_ninja, pulpo_cubo, gaviota_pirata, erizo_tambor, camaleon_neon, buho_despertador]
