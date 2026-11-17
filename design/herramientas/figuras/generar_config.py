"""Genera src/shared/Config/CritterMeshes.luau a partir de <carpeta>/<id>.json (por defecto out2/).
Uso: python3 generar_config.py [carpeta] [ruta_del_repo]"""
import glob
import json
import os
import sys
from pathlib import Path

HERE = Path(__file__).parent
SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "out2"
REPO = Path(sys.argv[2]) if len(sys.argv) > 2 else HERE.parents[2]


def v(x):
    return "Vector3.new(%s)" % ", ".join("%.4g" % a for a in x)


lines = [
    "--!strict",
    "-- GENERADO por design/herramientas/figuras/generar_config.py: no editar a mano.",
    "-- Piezas de los modelos 3D de los bichos (estilo figura). Cada bicho es un Model importado en",
    "-- ReplicatedStorage.Assets.Bichos.<id> con una MeshPart por pieza (ver design/Bichos3D.md).",
    "-- pos y size en unidades del bicho (1 = su diámetro, como Shared/CritterArt); anim = papel para",
    "-- client/CritterAnimator; pivot = punto de giro de las piezas animadas; textured = la pieza lleva",
    "-- su textura (color y relieve) importada con el FBX, así que no se le cambia el color.",
    "",
    "export type MeshPiece = {",
    "\tname: string,",
    "\tanim: string,",
    "\tpos: Vector3,",
    "\tsize: Vector3,",
    "\tcolor: Color3,",
    "\tmaterial: Enum.Material,",
    "\tpivot: Vector3?,",
    "\tkeep: boolean?,",
    "\tfine: boolean?,",
    "\ttextured: boolean?,",
    "}",
    "",
    "local CritterMeshes: { [string]: { MeshPiece } } = {}",
    "",
]
count = 0
for path in sorted(glob.glob(str(SRC / "*.json"))):
    cid = os.path.basename(path)[:-5]
    meta = json.load(open(path))
    count += 1
    lines.append(f"CritterMeshes.{cid} = {{")
    for m in meta:
        anim = m["anim"]
        if anim == "Cabeza":
            anim = "Craneo"  # "Cabeza" da vueltas en el animador: solo si se pide a propósito
        parts = [f'name = "{m["name"]}"', f'anim = "{anim}"', f'pos = {v(m["pos"])}', f'size = {v(m["size"])}',
                 "color = Color3.fromRGB(%d, %d, %d)" % tuple(int(c) for c in m["color"]), f'material = Enum.Material.{m["material"]}']
        if m.get("pivot"):
            parts.append(f'pivot = {v(m["pivot"])}')
        if m.get("keep"):
            parts.append("keep = true")
        if m.get("fine"):
            parts.append("fine = true")
        if m.get("texture"):
            parts.append("textured = true")
        lines.append("\t{ " + ", ".join(parts) + " },")
    lines.append("}")
lines += ["", "return CritterMeshes", ""]
(REPO / "src/shared/Config/CritterMeshes.luau").write_text("\n".join(lines))
print(count, "bichos")
