"""Ejecuta el servidor del juego en la simulación de Roblox y vuelca el mapa construido a JSON.
Uso: python3 simular.py <carpeta_repo> <salida.json>"""
import json, subprocess, sys
from pathlib import Path

repo, out = Path(sys.argv[1]), Path(sys.argv[2])
HERE = Path(__file__).parent

def long_str(s):
    level = 1
    while ("]" + "=" * level + "]") in s:
        level += 1
    return "[" + "=" * level + "[\n" + s + "]" + "=" * level + "]"

entries = []
mapping = [("src/shared", ["ReplicatedStorage", "Shared"]), ("src/server", ["ServerScriptService", "Server"]),
           ("src/client", ["StarterPlayer", "StarterPlayerScripts", "Client"])]
for rel, base in mapping:
    root = repo / rel
    for f in sorted(root.rglob("*.luau")):
        parts = list(f.relative_to(root).parts)
        name = parts[-1][:-5]
        cls = "ModuleScript"
        if name.endswith(".server"):
            name, cls = name[:-7], "Script"
        elif name.endswith(".client"):
            name, cls = name[:-7], "LocalScript"
        entries.append((base + parts[:-1], name, cls, f.read_text()))

lines = ['local RBX = require("./rbx")', "local game = RBX.game", "local scripts = {}"]
for path, name, cls, src in entries:
    lines.append("do local node = game:GetService(%s)" % json.dumps(path[0]))
    for p in path[1:]:
        lines.append("node = RBX.folder(node, %s)" % json.dumps(p))
    lines.append("scripts[%s] = RBX.addSource(node, %s, %s, %s) end" % (json.dumps("/".join(path + [name])), json.dumps(name), json.dumps(cls), long_str(src)))
lines.append((HERE / (sys.argv[3] if len(sys.argv) > 3 else "volcar.luau")).read_text())
(HERE / "_bundle.luau").write_text("\n".join(lines))
r = subprocess.run([str(HERE / "luau"), str(HERE / "_bundle.luau")], capture_output=True, text=True, cwd=HERE)
if len(sys.argv) > 3:
    print(r.stdout[-3000:], r.stderr[-2000:])
    sys.exit(0)
if r.returncode != 0 or not r.stdout.strip().startswith("{"):
    print(r.stdout[-3000:], r.stderr[-3000:])
    sys.exit(1)
data = json.loads(r.stdout)
out.write_text(json.dumps(data))
print(f"{len(data['parts'])} piezas, {len(data['terrain'])} rellenos de terreno, {len(data['lights'])} luces")
for l in data["logs"][:40]:
    print("  ", l)
