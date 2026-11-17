"""Bichos v2 (lote A)."""
import math
import random

from mathutils import Vector

import lib
import tex
from fig2 import FX, bolt, piece, point_light, puffs


def S(c, r, rot=(0, 0, 0)):
    return (c, r, rot)


def eyes_almond(center, spread, r, iris_rgb, tilt=25, glow=1.5, brow_shader=None, lid_color=None, pupil_slit=True):
    """Ojos de figura: globo, iris (con brillo propio), pupila y destello; cejas opcionales."""
    W, I, P, B, Br, Lid = [], [], [], [], [], []
    for s in (-1, 1):
        c = Vector(center) + Vector((s * spread, 0, 0))
        W.append(lib.prim("o", "sphere", lib.mat("_", (1, 1, 1)), tuple(c), (r * 1.5, r, r), rot=(0, 0, s * -tilt), subd=1))
        I.append(lib.prim("i", "sphere", lib.mat("_", (1, 1, 1)), tuple(c + Vector((s * 0.1 * r, -0.55 * r, 0))), (r, r * 0.66, r * 0.93), rot=(0, 0, s * -tilt), subd=1))
        P.append(lib.prim("p", "sphere", lib.mat("_", (1, 1, 1)), tuple(c + Vector((s * 0.13 * r, -0.95 * r, 0))), (r * (0.3 if pupil_slit else 0.5), r * 0.33, r * 0.72), rot=(0, 0, s * -tilt), subd=1))
        B.append(lib.prim("b", "sphere", lib.mat("_", (1, 1, 1)), tuple(c + Vector((s * -0.25 * r, -1.12 * r, 0.33 * r))), (r * 0.24,) * 3, subd=1))
        if brow_shader:
            Br.append(lib.prim("c", "sphere", lib.mat("_", (1, 1, 1)), tuple(c + Vector((s * 0.3 * r, 0.1 * r, 1.0 * r))), (r * 2.0, r * 1.1, r * 0.6), rot=(0, s * 15, s * -20), subd=1))
        if lid_color:
            Lid.append(lib.prim("l", "sphere", lib.mat("_", (1, 1, 1)), tuple(c), (r * 1.6, r * 1.1, r * 1.1), rot=(0, 0, s * -tilt), subd=1))
    piece("Ojos", W, (245, 248, 255), keep=True)
    piece("Iris", I, iris_rgb, material="Neon" if glow else "SmoothPlastic", keep=True)
    piece("Pupilas", P, (12, 14, 22), keep=True)
    piece("Brillos", B, (255, 255, 255), material="Neon", keep=True, fine=True)
    if Br:
        piece("Cejas", Br, (60, 60, 70), shader=brow_shader, bake=False)
    if Lid:
        piece("Parpado", Lid, lid_color)


class lobo_tormenta:
    ID, RARITY, TITLE = "lobo_tormenta", (255, 190, 40), "Lobo de Tormenta"

    @staticmethod
    def build():
        BACK, MID, BELLY = (62, 72, 104), (120, 132, 165), (215, 222, 238)
        fur = tex.furry("pelo", BACK, BELLY, MID, fur=0.55, fur_scale=70, flow=(1.0, 0.25, 1.0))
        shapes = [S((0, -0.3, 0.98), (0.27, 0.36, 0.31)), S((0, 0.1, 0.96), (0.22, 0.4, 0.25)), S((0, 0.4, 0.98), (0.23, 0.24, 0.26)),
                  S((0, -0.6, 1.2), (0.17, 0.2, 0.25), (-38, 0, 0)), S((0, -0.77, 1.42), (0.19, 0.2, 0.17)),
                  S((0, -0.98, 1.36), (0.095, 0.19, 0.085), (8, 0, 0)), S((0, -0.93, 1.29), (0.08, 0.15, 0.05))]
        limbs = []
        for s in (-1, 1):
            shapes += [S((s * 0.14, -0.74, 1.34), (0.1, 0.12, 0.12)), S((s * 0.15, -0.55, 0.05), (0.085, 0.12, 0.055)), S((s * 0.16, 0.44, 0.05), (0.085, 0.12, 0.055))]
            limbs += [[(s * 0.15, -0.36, 0.95, 0.15), (s * 0.16, -0.42, 0.62, 0.09), (s * 0.15, -0.45, 0.3, 0.065), (s * 0.15, -0.47, 0.1, 0.06), (s * 0.15, -0.53, 0.05, 0.06)],
                      [(s * 0.15, 0.36, 0.95, 0.18), (s * 0.17, 0.42, 0.68, 0.14), (s * 0.16, 0.53, 0.42, 0.075), (s * 0.16, 0.47, 0.18, 0.06), (s * 0.16, 0.42, 0.05, 0.06)],
                      [(s * 0.16, -0.76, 1.32, 0.07), (s * 0.27, -0.68, 1.27, 0.035), (s * 0.33, -0.62, 1.22, 0.008)],
                      [(s * 0.15, -0.72, 1.4, 0.05), (s * 0.25, -0.66, 1.4, 0.025), (s * 0.3, -0.6, 1.38, 0.006)]]
        piece("Cuerpo", tex.sculpt("c", fur, shapes, limbs), shader=fur, bake=True, budget=4200)
        piece("Cola", tex.sculpt("t", fur, [], [[(0, 0.55, 1.0, 0.08), (0, 0.72, 1.1, 0.14), (0, 0.86, 1.28, 0.16), (0.02, 0.92, 1.46, 0.11), (0.03, 0.9, 1.62, 0.01)],
                                                [(0.0, 0.86, 1.3, 0.1), (0.1, 0.93, 1.45, 0.04), (0.13, 0.92, 1.55, 0.006)]], smooth=12),
              shader=fur, bake=True, budget=900, pivot=(0, 0.55, 1.0))
        earm = tex.furry("orejas", BACK, MID, fur=0.3, fur_scale=90)
        piece("Orejas", [lib.prim("e", "cone", earm, (s * 0.12, -0.72, 1.62), (0.085, 0.05, 0.14), rot=(-12, s * 18, s * -8), subd=2) for s in (-1, 1)], shader=earm, bake=True, budget=500)
        piece("OrejasDentro", [lib.prim("e", "cone", earm, (s * 0.12, -0.745, 1.6), (0.05, 0.02, 0.1), rot=(-12, s * 18, s * -8), subd=2) for s in (-1, 1)], (235, 170, 180))
        eyes_almond((0, -0.9, 1.47), 0.105, 0.03, (110, 210, 255), brow_shader=lib.mat("_c", BACK))
        piece("Nariz", [lib.prim("n", "sphere", lib.mat("_", (1, 1, 1)), (0, -1.15, 1.4), (0.04, 0.03, 0.03), subd=1)], (25, 25, 32), keep=True)
        piece("Unas", [lib.prim("u", "cone", lib.mat("_", (1, 1, 1)), (s * (0.155 if y < 0 else 0.165) + k * 0.03, y, 0.025), (0.012, 0.012, 0.025), rot=(100, 0, 0), subd=1)
                       for s in (-1, 1) for y in (-0.6, 0.31) for k in (-1, 0, 1)], (40, 40, 50), fine=True)
        # --- La parte de tormenta: collar de nubes alrededor del cuello, rayos y chispas.
        cloud = tex.furry("nube", (255, 255, 255), (105, 115, 150), (205, 212, 232), fur=0.12, fur_scale=18, rough=0.9)
        axis = Vector((0, -0.25, 0.3)).normalized()
        u = Vector((1, 0, 0))
        w = axis.cross(u).normalized()
        center = Vector((0, -0.56, 1.18))
        ring = []
        rnd = random.Random(5)
        for i in range(11):
            a = i / 11 * math.pi * 2
            p = center + (u * math.cos(a) + w * math.sin(a)) * 0.27
            ring.append((tuple(p), rnd.uniform(0.11, 0.15)))
        ring += [((0.0, -0.4, 1.4), 0.13), ((0.12, -0.32, 1.33), 0.1), ((-0.12, -0.35, 1.34), 0.1)]  # nubes que suben por la nuca
        piece("Nubes", tex.sculpt("n", cloud, puffs(ring, 3), [], voxel=0.014, smooth=6), shader=cloud, bake=True, budget=2600)
        bolts = []
        for k, (start, d, L) in enumerate([((0.3, -0.62, 1.1), (0.6, -0.2, -1), 0.5), ((-0.3, -0.6, 1.08), (-0.6, -0.3, -1), 0.46),
                                           ((0.22, -0.4, 1.45), (0.5, 0.2, 1), 0.38), ((-0.2, -0.75, 1.0), (-0.3, -0.8, -0.9), 0.4),
                                           ((0.05, -0.3, 1.5), (-0.2, 0.3, 1), 0.32)]):
            bolts += bolt(start, d, L * 1.15, width=0.036, segments=5, seed=k + 2)
            point_light(start, (1.0, 0.85, 0.3), 9)
        piece("Brillo_Rayos", bolts, (255, 215, 40), material="Neon", anim="Brillo")
        sparks = [lib.prim("s", "sphere", lib.mat("_", (1, 1, 1)), (math.cos(a) * 0.4, -0.55 + math.sin(a) * 0.3, 1.25 + math.sin(a * 3) * 0.15), (0.022,) * 3, subd=1)
                  for a in [i * 0.9 for i in range(7)]]
        piece("Gota_Chispas", sparks, (200, 240, 255), material="Neon", fine=True)


LOTE = [lobo_tormenta]
