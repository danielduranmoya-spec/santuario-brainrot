# Simulación aproximada del ritmo de la economía (no es código del juego: es documentación).
# Lee los números de src/shared/Config (bichos, rarezas por bóveda, precios, mejoras y mutaciones),
# así que si cambias el balance allí basta con volver a ejecutarla:
#     python3 design/simulacion_economia.py
#
# Un "jugador medio" va a la bóveda más alta que tiene abierta, mira 3 bichos y persigue el que más
# produce (las mutaciones se ven), lo atrapa (o falla y lo intenta con otro), vuelve al santuario,
# cobra y gasta: primero en la siguiente bóveda y, si no le llega, en mejoras baratas.
# Si el santuario está lleno, el bicho nuevo sustituye al más flojo (y este se vende), como en el juego.
# Cada 20 minutos hay un evento de mutación de 5 minutos (sorteado por peso).
#
# Responde a: ¿rompen las mutaciones (hasta Vacío x8 por Enorme x7 = x56) los precios de las bóvedas?
import random
import re
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CFG = ROOT / "src/shared/Config"


def read(name):
    return (CFG / name).read_text(encoding="utf8")


# ---------- Config del juego ----------
crit_text = read("Critters.luau")
CRITTERS = []
for m in re.finditer(r'\{ id = "(\w+)", name = "[^"]+", rarity = "(\w+)", coinsPerSecond = (\d+), zone = "\w+", vault = (\d+)(, eventOnly = true)?', crit_text):
    if not m.group(5):
        CRITTERS.append(dict(id=m.group(1), rarity=m.group(2), cps=int(m.group(3)), vault=int(m.group(4))))
WINDOW = {k: float(v) for k, v in re.findall(r'(\w+) = \{ label = "[^"]+", catchWindow = ([\d.]+)', crit_text)}
chances_block = re.search(r"Critters\.VaultChances = \{(.*?)\n\} ::", crit_text, re.S).group(1)
VAULT_CHANCES = []
for row in re.findall(r"\{([^{}]*)\},", chances_block):
    VAULT_CHANCES.append({k: float(v) for k, v in re.findall(r"(\w+) = ([\d.]+)", row)})

prog = read("Progression.luau")
VAULT_COST = [int(x.replace("_", "")) for x in re.findall(r"unlockCost = ([\d_]+)", prog)]
COST_GROWTH = int(re.search(r"costGrowth = (\d+)", prog).group(1))
VALUE_GROWTH = int(re.search(r"valueGrowth = (\d+)", prog).group(1))
VALUE_FROM = int(re.search(r"valueFromVault = (\d+)", prog).group(1))
UPG = {m[0]: dict(max=int(m[1]), base=float(m[2]), growth=float(m[3]), bonus=float(m[4]))
       for m in re.findall(r"(\w+) = \{ title = \"[^\"]+\", description = \"[^\"]+\", maxLevel = (\d+), baseCost = (\d+), growth = ([\d.]+), bonusPerLevel = ([\d.]+)", prog)}

mut = read("Mutations.luau")
colors_block = mut[mut.index("Mutations.Colors = {"):mut.index("Mutations.Sizes")]
COLORS = [(m[0], float(m[1]), float(m[2])) for m in re.findall(r'id = "(\w+)",\s*label = "[^"]*",\s*multiplier = (\d+),\s*chance = ([\d.]+)', colors_block)]
SIZES = [(m[0], float(m[1]), float(m[2])) for m in re.findall(r'id = "(\w+)", label = "[^"]*", multiplier = (\d+), chance = ([\d.]+)', mut)]
events_block = mut[mut.index("Mutations.Events = {"):]
EVENTS = []
for m in re.finditer(r"boosts = \{([^}]*)\},\s*weight = (\d+)", events_block):
    EVENTS.append(({k: float(v) for k, v in re.findall(r"(\w+) = ([\d.]+)", m.group(1))}, int(m.group(2))))
EVENT_INTERVAL = 20 * 60
EVENT_DURATION = 5 * 60
MACHINES = [dict(id=m[0], count=int(m[1]), cost_s=int(m[2]), min=int(m[3].replace("_", "")))
            for m in re.findall(r'id = "(\w+)", title = "[^"]+", from = "\w+", to = "\w+", count = (\d+), costSeconds = (\d+), minCost = ([\d_]+)', mut)]

STARTING_SLOTS = 3
SELL_SECONDS = 30


def vault_cost(n):
    if n <= len(VAULT_COST):
        return VAULT_COST[n - 1]
    return VAULT_COST[-1] * COST_GROWTH ** (n - len(VAULT_COST))


def value_mult(n):
    return 1 if n < VALUE_FROM else round(VALUE_GROWTH ** (n - VALUE_FROM + 1))


def critter_table(n):
    row = VAULT_CHANCES[min(n, len(VAULT_CHANCES)) - 1]
    by = {}
    for c in CRITTERS:
        if c["vault"] <= n:
            by.setdefault(c["rarity"], []).append(c)
    items = []
    for rarity, w in row.items():
        lst = by.get(rarity, [])
        for c in lst:
            items.append((c, w / len(lst)))
    return items


TABLES = {n: critter_table(n) for n in range(1, 13)}


def pick(r, n):
    items = TABLES[min(n, 12)]
    x = r.uniform(0, sum(w for _, w in items))
    for c, w in items:
        x -= w
        if x <= 0:
            return c
    return items[-1][0]


def roll_color(r, boosts):
    lst = []
    others = 0
    for cid, m, ch in COLORS:
        if cid == "Normal":
            continue
        ch = boosts.get(cid, ch) if boosts else ch
        others += ch
        lst.append((cid, m, ch))
    x = r.random() * 100
    for cid, m, ch in reversed(lst):
        x -= ch
        if x < 0:
            return cid, m
    return "Normal", 1


def roll_size(r):
    x = r.random() * 100
    for sid, m, ch in reversed(SIZES[1:]):
        x -= ch
        if x < 0:
            return sid, m
    return "Normal", 1


def run(seed, minutes=60, mutations=True, always_event=None, titanica=False):
    r = random.Random(seed)
    t = 0.0
    coins = 0.0
    maxv = 1
    lv = {k: 0 for k in UPG}
    slots = []  # ingresos por segundo de cada bicho del santuario
    times = {}
    best_mult = 1
    event_order = [r.choices([b for b, _ in EVENTS], weights=[w for _, w in EVENTS])[0] for _ in range(10)]

    def boosts_now():
        if always_event is not None:
            return always_event
        k = int(t // EVENT_INTERVAL)
        if t - k * EVENT_INTERVAL >= EVENT_INTERVAL - EVENT_DURATION and k < len(event_order):
            return event_order[k]
        return None

    def nslots():
        return STARTING_SLOTS + lv["Santuario"]

    t += 15
    slots.append(CRITTERS[0]["cps"])  # bicho del tutorial
    while t < minutes * 60:
        n = maxv
        # mira 3 bichos de la bóveda y va a por el que más produce
        seen = []
        for _ in range(3):
            c = pick(r, n)
            cm, sm = (roll_color(r, boosts_now())[1], roll_size(r)[1]) if mutations else (1, 1)
            seen.append((c["cps"] * value_mult(n) * cm * sm, c, cm, sm))
        seen.sort(key=lambda s: -s[0])
        speed = 16 + lv["Botas"] * UPG["Botas"]["bonus"]
        dist = 60 + 100 * (n - 1) + 50
        dt = 2 * dist / speed + 8
        # intenta el mejor; si falla, el siguiente
        caught = None
        for value, c, cm, sm in seen:
            window = min(0.9, WINDOW[c["rarity"]] + lv["Red"] * UPG["Red"]["bonus"])
            if sm == 3:
                window -= 0.02
            elif sm == 7:
                window -= 0.04
            window = max(0.015, window)
            dt += 4
            if r.random() < min(0.95, window * 1.6 + 0.05):
                caught = (value, cm, sm, c)
                break
        coins += sum(slots[: nslots()]) * dt
        t += dt
        if caught:
            value, cm, sm, c = caught
            if titanica and sm < 7 and r.random() < 0.1:
                value = value / sm * (3 if sm == 1 else 7)
                sm = 3 if sm == 1 else 7
            best_mult = max(best_mult, cm * sm)
            if len(slots) < nslots():
                slots.append(value)
            else:
                weakest = min(slots)
                if value > weakest:
                    slots.remove(weakest)
                    slots.append(value)
                    coins += weakest * SELL_SECONDS
        # gasta
        changed = True
        while changed:
            changed = False
            if coins >= vault_cost(maxv + 1):
                coins -= vault_cost(maxv + 1)
                maxv += 1
                times[maxv] = t
                changed = True
                continue
            for name in ["Santuario", "Botas", "Red"]:
                u = UPG[name]
                c2 = u["base"] * u["growth"] ** lv[name]
                if (name != "Santuario" or len(slots) >= nslots()) and coins >= c2 and c2 < vault_cost(maxv + 1) * 0.35 and lv[name] < u["max"]:
                    coins -= c2
                    lv[name] += 1
                    changed = True
                    break
    return times, best_mult


def summary(label, n_players=400, **kw):
    acc = {}
    mults = []
    for s in range(n_players):
        times, bm = run(s, **kw)
        mults.append(bm)
        for k, v in times.items():
            acc.setdefault(k, []).append(v / 60)
    print(f"\n{label}")
    print("  bóveda  mediana(min)  el 5% más rápido(min)  llegan en 60 min")
    for k in sorted(acc):
        v = sorted(acc[k])
        p5 = v[max(0, int(len(v) * 0.05) - 1)]
        print(f"  {k:>6}  {statistics.median(v):>12.1f}  {p5:>21.1f}  {len(v) / n_players * 100:>14.0f} %")
    big = sum(1 for m in mults if m >= 20) / n_players * 100
    print(f"  jugadores que consiguen algún bicho con mutación x20 o más: {big:.0f} %")


def fusion_cost_check():
    print("\nCoste de la fusión frente a lo que produce el bicho que sale (en minutos de su producción):")
    print("  bóveda  bicho               máquina      coste   produce/s del resultado   minutos")
    for n, cid in [(1, "caracol_turbo"), (4, "lobo_tormenta"), (9, "lobo_tormenta"), (9, "coloso_bronce")]:
        c = next(x for x in CRITTERS if x["id"] == cid)
        for m, (fsize, tsize) in zip(MACHINES, [(1, 3), (3, 7)]):
            base_cost = max(m["min"], c["cps"] * m["cost_s"])
            full = c["cps"] * value_mult(n)
            new_cost = max(m["min"], full * fsize * m["cost_s"])
            out = full * tsize
            print(f"  {n:>6}  {cid:18}  {m['id']:11} antes {base_cost:>14,.0f} = {base_cost / out / 60:6.2f} min | ahora {new_cost:>16,.0f} = {new_cost / out / 60:5.2f} min")


if __name__ == "__main__":
    print("Minuto en que se abre cada bóveda (400 jugadores simulados, 60 minutos de juego)")
    summary("Sin mutaciones", mutations=False)
    summary("Con mutaciones y eventos cada 20 min (como el juego)")
    summary("Con una Grieta del Vacío sin parar (peor caso: alguien invoca eventos todo el rato)", always_event=EVENTS[-1][0])
    summary("Con una Fiebre del Oro sin parar", always_event=EVENTS[0][0])
    summary("Con el pase Red Titánica", titanica=True)
    fusion_cost_check()
