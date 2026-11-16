#!/usr/bin/env python3
"""Vista previa de los modelos de los bichos sin abrir Roblox Studio.

Lee src/server/Services/CritterArt.luau, ejecuta su código con un intérprete de Lua (paquete
`lupa`) y escribe design/herramientas/vista_previa_bichos.html: una página que dibuja los 21
bichos en 3D en el navegador (con un deslizador para girarlos).

Uso:   pip install lupa
       python3 design/herramientas/vista_previa_bichos.py

Es solo una ayuda para diseñar: los colores, materiales y luces de Roblox no son idénticos.
"""
import json
import re
import sys
from pathlib import Path

from lupa import lua54

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "src/server/Services/CritterArt.luau"
CRITTERS = ROOT / "src/shared/Config/Critters.luau"
GAMEPLAY = ROOT / "src/shared/Config/Gameplay.luau"
OUT = Path(__file__).with_name("vista_previa_bichos.html")
TEMPLATE = Path(__file__).with_name("vista_previa_plantilla.html")

# Lo mínimo de Roblox que usa CritterArt (Vector3, Color3, Enum, math.clamp...).
SHIM = r"""
local V = {}
V.__index = function(t, k)
  if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
  return nil
end
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__unm = function(a) return vec(-a.X, -a.Y, -a.Z) end
V.__mul = function(a, b)
  if type(a) == "number" then return vec(a * b.X, a * b.Y, a * b.Z) end
  if type(b) == "number" then return vec(a.X * b, a.Y * b, a.Z * b) end
  return vec(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V.__div = function(a, b) return vec(a.X / b, a.Y / b, a.Z / b) end
Vector3 = { new = vec, one = vec(1, 1, 1), zero = vec(0, 0, 0) }
Color3 = { fromRGB = function(r, g, b) return { r = r, g = g, b = b } end }
Enum = { Material = setmetatable({}, { __index = function(_, k) return k end }) }
math.atan2 = math.atan
math.clamp = function(x, lo, hi) return math.max(lo, math.min(hi, x)) end
"""


def luau_to_lua(source: str) -> str:
    """Quita lo que Lua 5.4 no entiende de Luau (tipos, `+=`, recorrer tablas sin ipairs)."""
    lines = []
    skipping = False
    for line in source.splitlines():
        stripped = line.strip()
        if skipping:
            if stripped == "}":
                skipping = False
            continue
        if stripped.startswith("--!"):
            continue
        if re.match(r"^(export\s+)?type\s+\w+\s*=", stripped):
            if stripped.endswith("{"):
                skipping = True
            continue
        if re.match(r"^\s*(local\s+)?function\b", line):
            head, sep, rest = line.partition("(")
            args, sep2, tail = rest.rpartition(")")
            args = re.sub(r"(\w+)\s*:\s*[^,]+", r"\1", args)
            line = head + "(" + args + ")"
        else:
            line = re.sub(r"^(\s*local\s+\w+)\s*:\s*[^=]+=", r"\1 =", line)
        m = re.match(r"^(\s*for\s+[\w, ]+\s+in\s+)(.+)(\s+do\s*)$", line)
        if m and not re.match(r"(ipairs|pairs)\(", m.group(2)):
            line = f"{m.group(1)}ipairs({m.group(2)}){m.group(3)}"
        m = re.match(r"^(\s*)([\w.\[\]]+)\s*([+\-*/])=\s*(.+)$", line)
        if m:
            line = f"{m.group(1)}{m.group(2)} = {m.group(2)} {m.group(3)} ({m.group(4)})"
        lines.append(line)
    return "\n".join(lines)


def parse_config():
    """Nombre, rareza y tamaño de cada bicho (leídos de los Config con expresiones regulares)."""
    text = CRITTERS.read_text(encoding="utf8")
    critters = {}
    for m in re.finditer(r'id = "(\w+)", name = "([^"]+)", rarity = "(\w+)", coinsPerSecond = (\d+)', text):
        critters[m.group(1)] = {"name": m.group(2), "rarity": m.group(3), "coins": int(m.group(4))}
    labels = dict(re.findall(r'(\w+) = \{ label = "([^"]+)"', text))
    colors = {k: [int(x) for x in rgb.split(",")] for k, rgb in re.findall(r"(\w+) = \{ label[^}]*Color3\.fromRGB\(([^)]+)\)", text)}
    sizes_block = re.search(r"Gameplay\.CritterSizes = \{(.*?)\}", GAMEPLAY.read_text(encoding="utf8"), re.S).group(1)
    sizes = {k: float(val) for k, val in re.findall(r"(\w+) = ([\d.]+)", sizes_block)}
    for info in critters.values():
        info["label"] = labels[info["rarity"]]
        info["rarityColor"] = colors[info["rarity"]]
        info["size"] = sizes[info["rarity"]]
    return critters


def main():
    lua = lua54.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(SHIM)
    art = lua.execute(luau_to_lua(ART.read_text(encoding="utf8")))
    critters = parse_config()

    def vec(value):
        return [value.X, value.Y, value.Z] if value is not None else None

    models = []
    for critter_id, info in critters.items():
        specs = art[critter_id]
        if specs is None:
            print(f"AVISO: {critter_id} no tiene modelo en CritterArt", file=sys.stderr)
            continue
        parts = []
        for spec in specs.values():
            parts.append({
                "shape": spec.shape, "size": vec(spec.size), "pos": vec(spec.pos),
                "color": [spec.color.r, spec.color.g, spec.color.b],
                "rot": vec(spec.rot), "rot2": vec(spec.rot2), "material": spec.material,
                "name": spec.name, "transparency": spec.transparency, "reflectance": spec.reflectance,
                "fine": bool(spec.fine),
            })
        models.append({"id": critter_id, **info, "parts": parts})
        print(f"{info['name']:24} {info['label']:12} {len(parts):3} piezas ({sum(1 for x in parts if not x['fine'])} sin adornos)")
    for critter_id in art.keys():
        if critter_id not in critters:
            print(f"AVISO: el modelo {critter_id} no está en Config/Critters", file=sys.stderr)
    html = TEMPLATE.read_text(encoding="utf8").replace("/*MODELOS*/[]", json.dumps(models, ensure_ascii=False))
    OUT.write_text(html, encoding="utf8")
    print(f"Escrito {OUT}")


if __name__ == "__main__":
    main()
