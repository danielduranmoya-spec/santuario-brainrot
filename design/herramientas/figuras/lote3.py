"""Bichos míticos y secretos (figura de juguete)."""
from fig import *
from lote1 import legs4
from lote2 import quadruped


class leviatan_espejo:
    ID, RARITY = "leviatan_espejo", (255, 70, 110)

    @staticmethod
    def build():
        silver, fin = (200, 215, 230), (120, 230, 240)
        pts = [(0, 1.0, 0.1), (0.1, 0.7, 0.5), (0, 0.35, 0.75), (-0.1, 0.0, 0.55), (0, -0.25, 0.25), (0.05, -0.5, 0.45), (0, -0.62, 0.85), (0, -0.78, 1.1)]
        piece("Cuerpo", [tube(pts, 0.1, 0.17)], silver, material="Foil")
        piece("Cabeza", [body([((0, -0.85, 1.18), (0.16, 0.22, 0.13)), ((0, -1.05, 1.13), (0.1, 0.12, 0.07))], voxel=0.02)], silver, material="Foil")
        piece("Aletas", [cone(p, 0.06, 0.12, rot=(0, 0, 0)) for p in ((0, 0.7, 0.66), (0, 0.35, 0.92), (0, 0.0, 0.72), (0, -0.5, 0.62))], fin, material="Glass")
        piece("Bigotes", [tube([(s * 0.08, -1.1, 1.1), (s * 0.25, -1.2, 1.05), (s * 0.4, -1.15, 0.95)], 0.012, 0.005) for s in (-1, 1)], fin, fine=True)
        piece("Cuernos", [cone((s * 0.08, -0.8, 1.32), 0.035, 0.12, rot=(-35, s * 15, 0)) for s in (-1, 1)], fin)
        eyes((0, -1.0, 1.2), 0.08, 0.035, white=None, iris=(30, 200, 220))
        piece("Ondas", [torus((0, 1.0, 0.05), 0.15, 0.025), torus((0, -0.25, 0.12), 0.2, 0.025)], (150, 220, 255), material="Glass", anim="Brillo")


class buho_cuerda:
    ID, RARITY = "buho_cuerda", (255, 70, 110)

    @staticmethod
    def build():
        brass, copper, dark = (210, 160, 70), (190, 110, 60), (70, 55, 45)
        piece("Cuerpo", [body([((0, 0, 0.8), (0.4, 0.36, 0.52)), ((0, -0.03, 1.4), (0.36, 0.32, 0.3))])], brass, material="Metal")
        piece("Placas", [torus((0, 0, 0.6 + k * 0.18), 0.4 - abs(k - 2) * 0.03, 0.025) for k in range(4)], copper, material="Metal")
        piece("Remaches", [sph((math.cos(a) * 0.38, math.sin(a) * 0.34, 0.95), 0.025) for a in [i * 0.52 for i in range(12)]], dark, material="Metal", fine=True)
        for s in (-1, 1):
            piece(f"Ojo_{'I' if s < 0 else 'D'}", [cyl((s * 0.15, -0.27, 1.45), 0.13, 0.04, rot=(90, 0, 0)), torus((s * 0.15, -0.31, 1.45), 0.13, 0.02, rot=(90, 0, 0))], copper, material="Metal")
        piece("Ojos", [cyl((s * 0.15, -0.32, 1.45), 0.09, 0.01, rot=(90, 0, 0)) for s in (-1, 1)], (120, 230, 255), material="Neon", keep=True)
        piece("Pico", [cone((0, -0.38, 1.3), 0.05, 0.1, rot=(150, 0, 0))], copper, material="Metal")
        piece("Orejas", [cone((s * 0.22, 0, 1.75), 0.07, 0.14, rot=(0, s * 20, 0)) for s in (-1, 1)], copper, material="Metal")
        # engranaje en la barriga y llave de cuerda en la espalda
        teeth = [box((math.cos(a) * 0.23, -0.33, 0.8 + math.sin(a) * 0.23), (0.05, 0.04, 0.05), rot=(0, -math.degrees(a), 0)) for a in [i * 0.5236 for i in range(12)]]
        piece("Giro_Engranaje", [cyl((0, -0.33, 0.8), 0.21, 0.025, rot=(90, 0, 0))] + teeth, copper, material="Metal", pivot=(0, -0.33, 0.8))
        key = [cyl((0, 0.45, 1.0), 0.03, 0.08, rot=(90, 0, 0))] + [torus((s * 0.1, 0.55, 1.0), 0.08, 0.025, rot=(90, 0, 90)) for s in (-1, 1)]
        piece("Giro_Llave", key, dark, material="Metal", pivot=(0, 0.45, 1.0))
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Ala_{side}", [sph((s * 0.42, 0.05, 0.9), (0.1, 0.3, 0.42), rot=(10, 0, s * 10))] + [sph((s * 0.44, 0.05 + k * 0.08, 0.65 - k * 0.05), (0.08, 0.06, 0.15)) for k in range(3)], copper, material="Metal", pivot=(s * 0.38, 0, 1.2))
        piece("Patas", [cone((s * 0.14 + k * 0.05, -0.2, 0.05), 0.03, 0.08, rot=(80, 0, 0)) for s in (-1, 1) for k in (-1, 0, 1)], dark, material="Metal")


class coloso_bronce:
    ID, RARITY = "coloso_bronce", (255, 70, 110)

    @staticmethod
    def build():
        bronze, moss, dark = (175, 120, 60), (90, 150, 70), (90, 65, 40)
        piece("Cuerpo", [body([((0, 0, 1.2), (0.5, 0.36, 0.42)), ((0, 0, 0.8), (0.36, 0.3, 0.3))])], bronze, material="Metal")
        piece("Cabeza", [box((0, -0.05, 1.78), (0.36, 0.34, 0.32), bevel=0.06), cyl((0, -0.05, 1.98), 0.2, 0.05, subd=1)], bronze, material="Metal")
        piece("Visor", [box((0, -0.22, 1.8), (0.3, 0.02, 0.08))], (100, 240, 200), material="Neon", keep=True)
        for s in (-1, 1):
            side = "I" if s < 0 else "D"
            piece(f"Brazo_{side}", [sph((s * 0.58, 0, 1.45), 0.2), tube([(s * 0.6, 0, 1.4), (s * 0.72, -0.05, 1.05), (s * 0.74, -0.12, 0.7)], 0.12, 0.1),
                                    sph((s * 0.74, -0.14, 0.62), (0.16, 0.16, 0.14))], bronze, material="Metal", anim="Pendulo", pivot=(s * 0.58, 0, 1.45))
            piece(f"Pierna_{side}", [tube([(s * 0.22, 0, 0.7), (s * 0.25, -0.02, 0.35), (s * 0.25, -0.04, 0.12)], 0.14, 0.12), box((s * 0.25, -0.1, 0.06), (0.26, 0.38, 0.12), bevel=0.04)], bronze, material="Metal")
        piece("Musgo", [sph((x, y, z), r) for x, y, z, r in ((0.35, -0.1, 1.55, 0.12), (-0.4, 0.05, 1.52, 0.1), (0.1, 0.2, 1.4, 0.13), (-0.2, -0.28, 0.95, 0.08), (0.62, 0, 1.6, 0.08))], moss)
        piece("Florecillas", [sph((x, y, z), 0.03) for x, y, z in ((0.35, -0.18, 1.66), (-0.4, -0.02, 1.62), (0.12, 0.12, 1.52))], (255, 240, 120), fine=True)
        teeth = [box((math.cos(a) * 0.2, -0.38, 1.2 + math.sin(a) * 0.2), (0.05, 0.04, 0.05), rot=(0, -math.degrees(a), 0)) for a in [i * 0.628 for i in range(10)]]
        piece("Giro_Engranaje", [cyl((0, -0.38, 1.2), 0.18, 0.03, rot=(90, 0, 0))] + teeth, dark, material="Metal", pivot=(0, -0.38, 1.2))
        piece("Brillo_Nucleo", [sph((0, -0.41, 1.2), 0.07)], (100, 240, 200), material="Neon")


class sombra_pendulo:
    ID, RARITY = "sombra_pendulo", (60, 235, 225)

    @staticmethod
    def build():
        shadow, gold = (30, 25, 45), (240, 200, 90)
        piece("Cuerpo", [body([((0, 0, 1.1), (0.34, 0.3, 0.45)), ((0, 0, 0.65), (0.26, 0.24, 0.3)), ((0, -0.02, 1.6), (0.26, 0.24, 0.24))])], shadow)
        wisps = [cone((x, y, 0.32), 0.12, 0.3, rot=(180 + y * 30, x * 30, 0)) for x, y in ((-0.15, 0.05), (0.15, 0.0), (0, 0.15), (0.05, -0.12))]
        piece("Jirones", wisps, shadow, material="Glass")
        piece("Ojos", [sph((s * 0.1, -0.23, 1.63), (0.05, 0.02, 0.035)) for s in (-1, 1)], (255, 240, 160), material="Neon", keep=True)
        piece("Corona", [cone((math.cos(a) * 0.18, math.sin(a) * 0.16, 1.88), 0.035, 0.1) for a in [i * 1.2566 for i in range(5)]], gold, material="Neon", anim="Brillo")
        piece("Brazos", [tube([(s * 0.3, -0.02, 1.25), (s * 0.48, -0.1, 1.0), (s * 0.45, -0.18, 0.75)], 0.07, 0.03) for s in (-1, 1)], shadow)
        # péndulo que cuelga de la mano derecha
        piece("Pendulo_Cadena", [cyl((0.45, -0.18, 0.55), 0.01, 0.2)], gold, material="Metal", anim="Pendulo", pivot=(0.45, -0.18, 0.75))
        piece("Pendulo_Disco", [cyl((0.45, -0.18, 0.3), 0.1, 0.02, rot=(90, 0, 0)), torus((0.45, -0.2, 0.3), 0.1, 0.015, rot=(90, 0, 0))], gold, material="Metal", anim="Pendulo", pivot=(0.45, -0.18, 0.75))
        piece("Brillo_Reloj", [cyl((0.45, -0.21, 0.3), 0.07, 0.005, rot=(90, 0, 0))], (255, 250, 220), material="Neon")


class zorro_tinta:
    ID, RARITY = "zorro_tinta", (60, 235, 225)
    WIDE = 1.6

    @staticmethod
    def build():
        ink, gold, blue = (25, 25, 40), (240, 200, 90), (60, 80, 200)
        piece("Cuerpo", [quadruped(ink, length=1.0, height=0.6, thick=0.2, neck=0.25, head=0.17, snout=0.17)], ink)
        for s in (-1, 1):
            piece(f"Oreja_{'I' if s < 0 else 'D'}", [cone((s * 0.1, -0.62, 1.12), 0.07, 0.16, rot=(-8, s * 15, 0))], ink)
        piece("Brillo_Orejas", [cone((s * 0.1, -0.645, 1.1), 0.04, 0.1, rot=(-8, s * 15, 0)) for s in (-1, 1)], gold, material="Neon")
        eyes((0, -0.82, 0.98), 0.075, 0.035, white=None, iris=(255, 210, 90))
        legs4([((s * 0.13, y, 0.5), (s * 0.14, y + (0.04 if y > 0 else -0.02), 0.26), (s * 0.14, y - 0.03, 0.03)) for s in (-1, 1) for y in (-0.33, 0.32)], 0.06, 0.04, ink, paw=True)
        tails = []
        for k, ang in enumerate((-40, -15, 15, 40)):
            a = math.radians(ang)
            tails.append(tube([(0, 0.42, 0.65), (math.sin(a) * 0.3, 0.7, 0.9), (math.sin(a) * 0.55, 0.85, 1.2), (math.sin(a) * 0.62, 0.8, 1.42)], 0.09, 0.05))
        piece("Cola", tails, ink, pivot=(0, 0.42, 0.65))
        piece("Brillo_Puntas", [sph((math.sin(math.radians(a)) * 0.62, 0.8, 1.45), 0.06) for a in (-40, -15, 15, 40)], blue, material="Neon")
        piece("Gota_Tinta", [sph((0.05, -0.5, 0.25), (0.035, 0.035, 0.05)), sph((-0.08, 0.2, 0.3), (0.03, 0.03, 0.045))], ink, material="Glass", anim="Gota")
        piece("Marcas", [tube([(s * 0.2, -0.2, 0.68), (s * 0.21, 0.0, 0.72), (s * 0.2, 0.2, 0.66)], 0.015, 0.008) for s in (-1, 1)], gold, material="Neon", fine=True)


class caballero_eclipse:
    ID, RARITY = "caballero_eclipse", (60, 235, 225)

    @staticmethod
    def build():
        armor, dark, gold = (60, 55, 80), (25, 22, 35), (230, 200, 120)
        piece("Cuerpo", [body([((0, 0, 1.15), (0.3, 0.22, 0.32)), ((0, 0, 0.82), (0.24, 0.2, 0.18))])], armor, material="Metal")
        piece("Casco", [sph((0, -0.02, 1.62), (0.2, 0.21, 0.22)), box((0, -0.18, 1.6), (0.26, 0.06, 0.1))], armor, material="Metal")
        piece("Visera", [box((0, -0.215, 1.62), (0.2, 0.02, 0.025))], (240, 240, 255), material="Neon", keep=True)
        piece("Penacho", [tube([(0, 0.0, 1.82), (0, 0.15, 1.92), (0, 0.32, 1.78), (0, 0.4, 1.6)], 0.05, 0.02)], (170, 140, 240))
        piece("Hombreras", [sph((s * 0.34, 0, 1.36), (0.16, 0.16, 0.1)) for s in (-1, 1)], gold, material="Metal")
        piece("Capa", [membrane([(-0.3, 0.18, 1.4), (0.3, 0.18, 1.4), (0.38, 0.32, 0.4), *lib.scallop((0.38, 0.32, 0.4), (-0.38, 0.32, 0.4), 0.05, 5, (0, 0, 1)), (-0.38, 0.32, 0.4)], 0.025, 0.05)], (70, 40, 120), anim="Cola", pivot=(0, 0.18, 1.4))
        piece("Piernas", [tube([(s * 0.12, 0, 0.75), (s * 0.13, -0.02, 0.4), (s * 0.13, -0.04, 0.08)], 0.09, 0.08) for s in (-1, 1)] +
              [box((s * 0.13, -0.08, 0.05), (0.14, 0.26, 0.1)) for s in (-1, 1)], armor, material="Metal")
        # escudo eclipse (izquierda) y espada (derecha)
        piece("Escudo", [cyl((-0.42, -0.2, 1.0), 0.28, 0.03, rot=(90, 0, -10))], dark)
        piece("Brillo_Corona", [torus((-0.42, -0.24, 1.0), 0.26, 0.025, rot=(90, 0, -10))], (240, 240, 255), material="Neon")
        piece("Brazos", [tube([(s * 0.34, 0, 1.3), (s * 0.42, -0.08, 1.05), (s * 0.4, -0.16, 0.95)], 0.07, 0.06) for s in (-1, 1)], armor, material="Metal")
        piece("Espada", [box((0.42, -0.25, 1.25), (0.05, 0.02, 0.7)), box((0.42, -0.22, 0.88), (0.2, 0.05, 0.04)), cyl((0.42, -0.2, 0.78), 0.025, 0.08)], (210, 215, 230), material="Metal")
        piece("Brillo_Filo", [box((0.42, -0.262, 1.3), (0.012, 0.005, 0.55))], (200, 180, 255), material="Neon", fine=True)


LOTE = [leviatan_espejo, buho_cuerda, coloso_bronce, sombra_pendulo, zorro_tinta, caballero_eclipse]
