"""Librería para modelar los bichos en estilo figura de juguete y exportarlos para Roblox.

Cada bicho es una lista de PIEZAS (mallas con nombre). El nombre antes de "_" es el que entiende
el animador del juego (Ala, Cola, Parpado, Pinza, Gota, Giro, Brillo, Arcoiris, Cabeza, Pendulo).
Ejes de Blender: Z arriba, el bicho mira hacia -Y. Al exportar se pasa a los ejes de Roblox
(Y arriba, mira hacia -Z) y se normaliza: 1 unidad = diámetro del bicho, suelo en Y = -0,5.
"""
import json
import math
import sys

import bpy
import bmesh  # noqa: F401
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent / "base"))
import lib  # noqa: E402  (blob, prim, tube, membrane, scallop, srgb)

PIECES = {}  # nombre -> dict(obj, color, material, anim, pivot, keep, fine)


def reset():
    PIECES.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _mat(color, material):
    key = f"m_{color}_{material}"
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = [lib.srgb(c) for c in color] + [1]
    b.inputs["Roughness"].default_value = {"Metal": 0.3, "Glass": 0.05, "Neon": 0.5, "Foil": 0.15}.get(material, 0.42)
    b.inputs["Coat Weight"].default_value = 0.2
    if material in ("Metal", "Foil", "DiamondPlate"):
        b.inputs["Metallic"].default_value = 0.85
    if material == "Neon":
        b.inputs["Emission Color"].default_value = [lib.srgb(c) for c in color] + [1]
        b.inputs["Emission Strength"].default_value = 3.0
    if material == "Glass":
        b.inputs["Transmission Weight"].default_value = 0.7
    return m


def _apply(o):
    bpy.context.view_layer.objects.active = o
    for m in list(o.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=m.name)
        except RuntimeError:
            o.modifiers.remove(m)


def piece(name, objs, color, material="SmoothPlastic", anim=None, pivot=None, keep=False, fine=False):
    """Une `objs` en una sola malla llamada `name` con ese color/material de Roblox."""
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
        _apply(o)
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
    j.data.materials.append(_mat(color, material))
    for p in j.data.polygons:
        p.use_smooth = True
    PIECES[name] = dict(obj=j, color=list(color), material=material, anim=anim or name.split("_")[0],
                        pivot=list(pivot) if pivot else None, keep=keep, fine=fine)
    return j


# ----------------------------------------------------------------------- formas
def body(shapes, voxel=0.03, smooth=12):
    """Cuerpo orgánico: elipsoides (centro, radios, giro) fundidos (ver lib.blob)."""
    return lib.blob("tmp", shapes, bpy.data.materials.get("_") or lib.mat("_", (200, 200, 200)), voxel=voxel, smooth=smooth)


def sph(loc, r, rot=(0, 0, 0)):
    if not isinstance(r, (list, tuple)):
        r = (r, r, r)
    return lib.prim("s", "sphere", lib.mat("_", (200, 200, 200)), loc, r, rot=rot, subd=1)


def cone(loc, r, h, rot=(0, 0, 0), r2=0.0):
    return lib.prim("c", "cone", lib.mat("_", (200, 200, 200)), loc, (r, r, h), rot=rot, subd=1, r2=r2)


def cyl(loc, r, h, rot=(0, 0, 0), subd=0):
    if not isinstance(r, (list, tuple)):
        r = (r, r)
    return lib.prim("y", "cyl", lib.mat("_", (200, 200, 200)), loc, (r[0], r[1], h), rot=rot, subd=subd)


def box(loc, size, rot=(0, 0, 0), bevel=0.02):
    return lib.prim("b", "cube", lib.mat("_", (200, 200, 200)), loc, tuple(s / 2 for s in size), rot=rot, subd=0, bevel=bevel)


def torus(loc, R, r, rot=(0, 0, 0)):
    return lib.prim("t", "torus", lib.mat("_", (200, 200, 200)), loc, (R, R, R), rot=rot, minor=r / R, subd=1)


def tube(points, r0, r1):
    return lib.tube("tubo", points, r0, r1, lib.mat("_", (200, 200, 200)), res=6)


def membrane(outline, thickness=0.02, sag=0.0):
    return lib.membrane("memb", outline, lib.mat("_", (200, 200, 200)), thickness=thickness, sag=sag, subd=2)


def eyes(center, spread, r, look=(0, -1, 0), white=(250, 250, 246), iris=(25, 22, 30), shine=True, lid=None):
    """Par de ojos de figura: globo, pupila y brillo. Con `lid` (color de la piel) añade párpados
    (el animador los enseña un instante para parpadear)."""
    cx, cy, cz = center
    lo = Vector(look).normalized()
    globes, pupils, glints, lids = [], [], [], []
    for s in (-1, 1):
        c = Vector((cx + s * spread, cy, cz))
        d = (lo + Vector((s * 0.25, 0, 0))).normalized()
        if white:
            globes.append(sph(tuple(c), r))
        pc = c + d * r * 0.55
        pupils.append(sph(tuple(pc), (r * 0.6, r * 0.6, r * 0.64)))
        if shine:
            glints.append(sph(tuple(pc + d * r * 0.45 + Vector((0, 0, r * 0.25)) - Vector((s * r * 0.12, 0, 0))), r * 0.18))
        if lid:
            lids.append(sph(tuple(c), r * 1.08))
    if globes:
        piece("Ojos", globes, white, keep=True)
    piece("Pupilas", pupils, iris, keep=True)
    if glints:
        piece("Brillos", glints, (255, 255, 255), material="Neon", keep=True, fine=True)
    if lids:
        piece("Parpado", lids, lid)


# ----------------------------------------------------------------------- exportar
def _to_rbx(v):
    return Vector((-v.x, v.z, v.y))  # Blender -> Roblox (mira a -Y -> mira a -Z)


def export(cid, out_dir, wide=1.9, budget=9000):
    """Normaliza el bicho, reduce polígonos, guarda metadatos (JSON) y lo deja listo para el FBX."""
    objs = [p["obj"] for p in PIECES.values()]
    mins = Vector((1e9,) * 3)
    maxs = Vector((-1e9,) * 3)
    for o in objs:
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            mins = Vector(map(min, mins, w))
            maxs = Vector(map(max, maxs, w))
    dims = maxs - mins
    scale = 1.0 / max(dims.z, dims.y / 1.45, dims.x / wide)  # los alargados pueden pasar un poco del diámetro
    offset = Vector(((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z))
    total = sum(sum(len(f.vertices) - 2 for f in p["obj"].data.polygons) for p in PIECES.values())
    ratio = min(1.0, budget / max(1, total))
    meta = []
    for name, p in PIECES.items():
        o = p["obj"]
        # normalizar
        o.data.transform(Matrix.Translation(-offset))
        o.data.transform(Matrix.Scale(scale, 4))
        o.data.transform(Matrix.Translation((0, 0, -0.5)))
        # reducir polígonos si hace falta
        tris = sum(len(f.vertices) - 2 for f in o.data.polygons)
        if ratio < 1 and tris > 60:
            m = o.modifiers.new("dec", "DECIMATE")
            m.ratio = max(ratio, 60 / tris)
            _apply(o)
        # centro y tamaño de la pieza (en ejes de Roblox)
        lo = Vector((1e9,) * 3)
        hi = Vector((-1e9,) * 3)
        for v in o.data.vertices:
            lo = Vector(map(min, lo, v.co))
            hi = Vector(map(max, hi, v.co))
        center = (lo + hi) / 2
        o.data.transform(Matrix.Translation(-center))
        o.location = center
        size_b = hi - lo
        rc = _to_rbx(center)
        rs = Vector((size_b.x, size_b.z, size_b.y))
        piv = None
        if p["pivot"]:
            pv = (Vector(p["pivot"]) - offset) * scale + Vector((0, 0, -0.5))
            piv = list(_to_rbx(pv))
        meta.append(dict(name=name, anim=p["anim"], pos=list(rc), size=[max(0.002, x) for x in rs], color=p["color"],
                         material=p["material"], pivot=piv, keep=p["keep"], fine=p["fine"],
                         tris=sum(len(f.vertices) - 2 for f in o.data.polygons)))
    json.dump(meta, open(f"{out_dir}/{cid}.json", "w"), indent=1)
    return meta


def save_fbx(cid, out_dir):
    """FBX de un bicho: un objeto vacío con el id y dentro sus piezas (girado para Roblox)."""
    root = bpy.data.objects.new(cid, None)
    bpy.context.scene.collection.objects.link(root)
    for p in PIECES.values():
        p["obj"].parent = root
    root.rotation_euler = (0, 0, math.pi)  # el FBX pasa -Z de Blender... ver _to_rbx
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for p in PIECES.values():
        p["obj"].select_set(True)
    bpy.ops.export_scene.fbx(filepath=f"{out_dir}/{cid}.fbx", use_selection=True, object_types={"EMPTY", "MESH"},
                             apply_scale_options="FBX_SCALE_UNITS", bake_space_transform=False, mesh_smooth_type="FACE",
                             global_scale=10.0, use_mesh_modifiers=True, add_leaf_bones=False)
    root.rotation_euler = (0, 0, 0)
    bpy.ops.wm.save_as_mainfile(filepath=f"{out_dir}/{cid}.blend")


def preview(path, ring_rgb, size=420, yaw=-30):
    """Render de comprobación (normalizado: el bicho mide 1 de alto aprox.)."""
    lib.stage(ring_rgb, ground_z=-0.5, ring_r=0.6)
    for o in bpy.data.objects:
        if o.name == "aro_rareza" or o.type == "LIGHT":
            pass
    # ajustar luces a la escala pequeña
    for o in bpy.data.objects:
        if o.type == "LIGHT":
            o.location = o.location * 0.28
            o.data.energy *= 0.08
    lib.camera(target=(0, 0, 0.0), dist=4.2, yaw=yaw, pitch=12, lens=55)
    scene = bpy.context.scene
    scene.cycles.samples = 24
    lib.render(path, size)
