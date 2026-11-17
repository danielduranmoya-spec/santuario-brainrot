"""Murciélago de Magma (figura): murciélago orejudo de roca oscura con venas de lava."""
from fig import *

ID, RARITY = "murcielago_magma", (170, 80, 255)
ROCK, ROCK2, BONE, LAVA, CLAW = (66, 48, 54), (48, 34, 38), (110, 72, 72), (255, 110, 25), (40, 32, 32)


def wing(s):
    S, E, W = (s * 0.17, 0.02, 1.62), (s * 0.62, -0.02, 1.76), (s * 1.12, -0.06, 2.28)
    fingers = [((s * 1.85, -0.02, 2.24), (s * 2.7, 0.04, 1.84)), ((s * 1.7, 0.03, 1.72), (s * 2.42, 0.08, 0.95)),
               ((s * 1.42, 0.06, 1.4), (s * 1.82, 0.1, 0.66)), ((s * 1.2, 0.06, 1.34), (s * 1.18, 0.1, 0.6))]
    ankle, hip = (s * 0.3, 0.1, 0.86), (s * 0.14, 0.08, 1.24)

    def edge(a, b, d):
        mid = (Vector(a) + Vector(b)) / 2
        return lib.scallop(a, b, d, n=5, inward=tuple((Vector(W) - mid).normalized()))
    tips = [f[1] for f in fingers]
    outline = [S, E, W, fingers[0][0], tips[0]]
    for a, b in zip(tips, tips[1:]):
        outline += [*edge(a, b, 0.22), b]
    outline += [*edge(tips[-1], ankle, 0.22), ankle, hip]
    side = "I" if s < 0 else "D"
    piece(f"Ala_{side}", [membrane(outline, 0.03, 0.16)], (52, 34, 38), anim="Ala", pivot=S)
    bones = [tube([S, E, W], 0.042, 0.03), sph(E, 0.045), sph(W, 0.048)]
    for k, t in fingers:
        bones += [tube([W, k, t], 0.024, 0.01), sph(k, 0.026)]
    bones += [tube([W, (s * 1.1, -0.14, 2.38)], 0.025, 0.02)]
    piece(f"AlaHueso_{side}", bones, BONE, anim="Ala", pivot=S)
    # venas de lava en la membrana (tubos finos que brillan)
    veins = []
    for (k, t), d in zip(fingers[1:], (0.3, 0.5, 0.4)):
        mid = Vector(W).lerp(Vector(t), 0.55) + Vector((s * 0.15, 0.07, -0.05))
        veins.append(tube([W, tuple(mid), tuple(Vector(mid).lerp(Vector(t), 0.6) + Vector((0, 0.03, -0.18)))], 0.012, 0.006))
    piece(f"Ala_Lava{side}", veins, LAVA, material="Neon", anim="Ala", pivot=S)
    piece(f"Garra_{side}", [cone((s * 1.08, -0.2, 2.42), 0.022, 0.06, rot=(-60, 0, s * 10))], CLAW, anim="Ala", pivot=S)


def build():
    piece("Cuerpo", [body([((0, 0.06, 1.45), (0.26, 0.21, 0.34)), ((0, 0.08, 1.2), (0.15, 0.14, 0.18)),
                           ((0, 0.0, 1.7), (0.21, 0.18, 0.15))])], ROCK)
    piece("Cabeza", [body([((0, -0.08, 1.86), (0.16, 0.15, 0.14)), ((0, -0.22, 1.82), (0.08, 0.1, 0.07))], voxel=0.02)], ROCK2)
    piece("Grieta", [tube([(0.05, -0.17, 1.6), (-0.04, -0.2, 1.45), (0.06, -0.19, 1.3)], 0.014, 0.008),
                     tube([(-0.12, -0.15, 1.55), (-0.08, -0.18, 1.42)], 0.01, 0.006)], LAVA, material="Neon", anim="Brillo")
    for s in (-1, 1):
        side = "I" if s < 0 else "D"
        piece(f"Oreja_{side}", [sph((s * 0.15, -0.02, 2.3), (0.13, 0.045, 0.36), rot=(-14, s * 12, s * -10))], ROCK2)
        piece(f"Brillo_Oreja{side}", [sph((s * 0.148, -0.05, 2.28), (0.095, 0.02, 0.3), rot=(-14, s * 12, s * -10))], (255, 130, 40), material="Neon", anim="Brillo")
        wing(s)
    piece("Ojos", [sph((s * 0.085, -0.22, 1.89), (0.028, 0.022, 0.025)) for s in (-1, 1)], (255, 160, 40), material="Neon", keep=True)
    piece("Nariz", [sph((0, -0.315, 1.83), (0.03, 0.018, 0.022))], CLAW, keep=True)
    legs = []
    for s in (-1, 1):
        legs += [tube([(s * 0.1, 0.1, 1.28), (s * 0.14, 0.08, 1.24), (s * 0.3, 0.1, 0.86)], 0.032, 0.022)]
        legs += [cone((s * 0.3 + k * 0.025, 0.06, 0.78), 0.01, 0.04, rot=(170, 0, 0)) for k in (-1, 0, 1)]
    piece("Patas", legs, BONE)
    piece("Gota_1", [sph((0.04, 0.1, 0.92), (0.035, 0.035, 0.05))], LAVA, material="Neon", anim="Gota")
