"""Bichos v2: esculpidos de una pieza, con texturas horneadas y efectos fantásticos más vistosos.

Igual que fig.py (piezas con nombre = papel en la animación), pero:
  * las piezas con `bake=True` se hornean a textura (color + normales) y se exportan con ella;
  * las demás (ojos, neón, metal) llevan color liso, como antes.
Uso: python3 hacer2.py <modulo>[:id] ...
"""
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent / "base"))
sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))
import lib  # noqa: E402
import tex  # noqa: E402

PIECES = {}
FX = []  # luces de la vista previa (en coordenadas de modelado)
NORM = {}


def reset():
    PIECES.clear()
    FX.clear()
    lib.reset()


def _apply_mods(o):
    bpy.context.view_layer.objects.active = o
    for m in list(o.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=m.name)
        except RuntimeError:
            o.modifiers.remove(m)


def piece(name, objs, color=(200, 200, 200), material="SmoothPlastic", anim=None, pivot=None, keep=False, fine=False,
          bake=False, shader=None, budget=None):
    """Une `objs` en una malla `name`. `shader`: material de Blender a usar (p. ej. tex.furry); si no,
    uno liso con `color`. `bake`: hornear `shader` a textura. `budget`: triángulos máximos de la pieza."""
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
    meshes = []
    for o in objs:
        if o.type == "CURVE":
            bpy.ops.object.select_all(action="DESELECT")
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.convert(target="MESH")
            o = bpy.context.active_object
        _apply_mods(o)
        meshes.append(o)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    j = bpy.context.active_object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    j.name = name
    j.data.materials.clear()
    if shader is None:
        shader = lib.mat(f"m_{name}", color, rough={"Metal": 0.3, "Glass": 0.05, "Neon": 0.5, "Foil": 0.15}.get(material, 0.4),
                         emission=color if material == "Neon" else None, strength=3.0,
                         metallic=0.85 if material in ("Metal", "Foil") else 0.0, alpha=0.6 if material == "Glass" else 1.0)
    j.data.materials.append(shader)
    for p in j.data.polygons:
        p.use_smooth = True
    PIECES[name] = dict(obj=j, color=list(color), material=material, anim=anim or name.split("_")[0], pivot=pivot,
                        keep=keep, fine=fine, bake=bake, budget=budget)
    return j


def _tris(o):
    return sum(len(f.vertices) - 2 for f in o.data.polygons)


def _rbx(v):
    return Vector((-v.x, v.z, v.y))


def export(cid, out_dir, wide=1.9, deep=1.45, budget=11000, tex_res=512):
    objs = [p["obj"] for p in PIECES.values()]
    mins, maxs = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in objs:
        for v in o.data.vertices:
            mins = Vector(map(min, mins, v.co))
            maxs = Vector(map(max, maxs, v.co))
    dims = maxs - mins
    scale = 1.0 / max(dims.z, dims.y / deep, dims.x / wide)
    offset = Vector(((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z))
    NORM.update(scale=scale, offset=offset)
    total = sum(_tris(p["obj"]) for p in PIECES.values())
    ratio = min(1.0, budget / max(1, total))
    meta = []
    os.makedirs(f"{out_dir}/tex", exist_ok=True)
    for name, p in PIECES.items():
        o = p["obj"]
        o.data.transform(Matrix.Translation(-offset))
        o.data.transform(Matrix.Scale(scale, 4))
        o.data.transform(Matrix.Translation((0, 0, -0.5)))
        t = _tris(o)
        target = p["budget"] or t * ratio
        if t > target and t > 60:
            m = o.modifiers.new("dec", "DECIMATE")
            m.ratio = max(target / t, 60 / t)
            _apply_mods(o)
        texture = None
        if p["bake"]:
            imgs = tex.bake(o, res=tex_res)
            for kind, img in imgs.items():
                img.filepath_raw = f"{out_dir}/tex/{cid}_{name}_{kind}.png"
                img.file_format = "PNG"
                img.save()
            texture = f"{cid}_{name}"
        lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
        for v in o.data.vertices:
            lo = Vector(map(min, lo, v.co))
            hi = Vector(map(max, hi, v.co))
        center = (lo + hi) / 2
        o.data.transform(Matrix.Translation(-center))
        o.location = center
        sb = hi - lo
        piv = None
        if p["pivot"]:
            piv = list(_rbx((Vector(p["pivot"]) - offset) * scale + Vector((0, 0, -0.5))))
        meta.append(dict(name=name, anim=p["anim"], pos=list(_rbx(center)), size=[max(0.002, x) for x in (sb.x, sb.z, sb.y)],
                         color=p["color"], material=p["material"], pivot=piv, keep=p["keep"], fine=p["fine"],
                         texture=texture, tris=_tris(o)))
    json.dump(meta, open(f"{out_dir}/{cid}.json", "w"), indent=1)
    return meta


def save(cid, out_dir):
    root = bpy.data.objects.new(cid, None)
    bpy.context.scene.collection.objects.link(root)
    for p in PIECES.values():
        p["obj"].parent = root
    bpy.ops.wm.save_as_mainfile(filepath=f"{out_dir}/{cid}.blend")


def preview(path, ring_rgb, yaw=-32, pitch=10, size=560, dist=3.1, target=(0, 0, -0.04)):
    lib.stage(ring_rgb, ground_z=-0.5, ring_r=0.62)
    for o in bpy.data.objects:
        if o.type == "LIGHT" and o.name in ("key", "fill", "rim"):
            o.location = o.location * 0.3
            o.data.energy *= 0.09
    for loc, color, energy in FX:
        ld = bpy.data.lights.new("fx", "POINT")
        ld.energy = energy * NORM["scale"] ** 2
        ld.color = color
        ld.shadow_soft_size = 0.02
        o = bpy.data.objects.new("fx", ld)
        o.location = (Vector(loc) - NORM["offset"]) * NORM["scale"] + Vector((0, 0, -0.5))
        bpy.context.scene.collection.objects.link(o)
    lib.camera(target=target, dist=dist, yaw=yaw, pitch=pitch, lens=55)
    scene = bpy.context.scene
    scene.cycles.samples = 48
    scene.view_settings.view_transform = "Standard"
    lib.render(path, size)


def point_light(loc, color, energy):
    """Luz para la vista previa (en el juego, una PointLight en la pieza que brilla)."""
    FX.append((loc, color, energy))


# ---------------------------------------------------------------- efectos fantásticos reutilizables
def bolt(start, direction, length, width=0.03, segments=5, seed=1, branch=True):
    """Rayo en zigzag (cajas finas encadenadas) con ramitas. Devuelve objetos."""
    import random
    rnd = random.Random(seed)
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 0, 1)))
    if side.length < 0.1:
        side = d.cross(Vector((1, 0, 0)))
    side.normalize()
    pts = [Vector(start)]
    for i in range(segments):
        jitter = side * (0.35 if i % 2 == 0 else -0.35) * length / segments * rnd.uniform(0.7, 1.4)
        pts.append(pts[-1] + d * length / segments + jitter)
    objs = []
    for a, b in zip(pts, pts[1:]):
        v = b - a
        rot = v.to_track_quat("Z", "Y").to_euler()
        objs.append(lib.prim("rayo", "cube", lib.mat("_", (255, 255, 255)), tuple((a + b) / 2), (width, width * 0.6, v.length / 2 + width * 0.6),
                             rot=tuple(math.degrees(x) for x in rot), subd=0))
    if branch:
        mid = pts[len(pts) // 2]
        objs += bolt(tuple(mid), tuple((d + side * 0.9).normalized()), length * 0.4, width * 0.7, 3, seed + 7, branch=False)
    return objs


def puffs(centers, rnd_seed=1, small=0.5):
    """Nube: bolas grandes con bolitas alrededor (se esculpen juntas)."""
    import random
    rnd = random.Random(rnd_seed)
    shapes = []
    for c, r in centers:
        shapes.append((c, (r, r, r * 0.92)))
        for _ in range(3):
            o = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-0.3, 1))).normalized() * r * 0.8
            rr = r * rnd.uniform(0.45, small + 0.2)
            shapes.append((tuple(Vector(c) + o), (rr, rr, rr)))
    return shapes
