"""Dibuja en Blender el mapa volcado por simular.py (piezas de Roblox + terreno) y saca capturas.
Uso: python3 render_mapa.py mapa.json salida_prefijo [vista ...]
Ejes: Roblox (X, Y arriba, Z) -> Blender (X, -Z, Y)."""
import json
import math
import sys

import bpy
from mathutils import Matrix, Vector

data = json.load(open(sys.argv[1]))
prefix = sys.argv[2]
views = sys.argv[3:] or ["aerea", "suelo"]

A = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))


def pos(v):
    return A @ Vector(v)


def srgb(x):
    return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4


TERRAIN = {  # colores por defecto del terreno de Roblox (aprox.)
    "Grass": (106, 127, 63), "LeafyGrass": (115, 132, 74), "Sand": (143, 126, 95), "Ground": (102, 92, 59),
    "Rock": (102, 108, 111), "Basalt": (30, 30, 37), "CrackedLava": (232, 156, 74), "Slate": (63, 127, 107),
    "Mud": (58, 46, 36), "Snow": (195, 199, 218), "Ice": (129, 194, 224), "Glacier": (101, 176, 234),
    "Water": (12, 84, 92), "Salt": (198, 189, 181), "Limestone": (206, 173, 148), "Sandstone": (137, 90, 71),
    "Pavement": (148, 148, 140), "Cobblestone": (132, 123, 90), "Asphalt": (115, 123, 107), "Brick": (138, 86, 62),
    "Concrete": (127, 102, 63), "WoodPlanks": (139, 109, 79), "Air": None,
}
for k, c in data.get("terrainColors", {}).items():
    TERRAIN[k] = tuple(int(x * 255) for x in c)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
mats = {}


def material(color, kind="Plastic", transparency=0.0, reflect=0.0):
    key = (tuple(round(c, 3) for c in color), kind, round(transparency, 2))
    if key in mats:
        return mats[key]
    m = bpy.data.materials.new(kind)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    lin = [srgb(c) for c in color]
    b.inputs["Base Color"].default_value = lin + [1]
    rough = {"SmoothPlastic": 0.35, "Glass": 0.05, "Metal": 0.35, "DiamondPlate": 0.3, "Marble": 0.3, "Foil": 0.2,
             "Neon": 0.5, "Ice": 0.1, "Glacier": 0.1}.get(kind, 0.7)
    b.inputs["Roughness"].default_value = rough
    if kind in ("Metal", "DiamondPlate", "Foil", "CorrodedMetal"):
        b.inputs["Metallic"].default_value = 0.8
    if kind == "Neon":
        b.inputs["Emission Color"].default_value = lin + [1]
        b.inputs["Emission Strength"].default_value = 4.0
    if kind in ("Glass", "ForceField") or transparency > 0:
        b.inputs["Alpha"].default_value = max(0.0, 1 - transparency) * (0.6 if kind == "Glass" else 1)
        m.blend_method = "BLEND" if hasattr(m, "blend_method") else None
    if reflect:
        b.inputs["Metallic"].default_value = min(1, reflect * 2)
        b.inputs["Roughness"].default_value = 0.15
    mats[key] = m
    return m


# Mallas base reutilizadas
def base_mesh(kind):
    if kind in bpy.data.meshes:
        return bpy.data.meshes[kind]
    if kind == "Block":
        bpy.ops.mesh.primitive_cube_add(size=1)
    elif kind == "Ball":
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.5, segments=24, ring_count=12)
    elif kind == "Cylinder":  # eje X de Roblox
        bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=1, vertices=24, rotation=(0, math.pi / 2, 0))
        bpy.ops.object.transform_apply(rotation=True)
    elif kind == "CylY":  # eje Y de Roblox (terreno)
        bpy.ops.mesh.primitive_cylinder_add(radius=1, depth=1, vertices=32, rotation=(math.pi / 2, 0, 0))
        bpy.ops.object.transform_apply(rotation=True)
    elif kind == "Wedge":
        import bmesh
        me = bpy.data.meshes.new("Wedge")
        bm = bmesh.new()
        # cuña de Roblox: rampa que sube hacia -Z (frente) ... en Roblox local: alta en +Z? baja en -Z
        pts = [(-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, -0.5, 0.5), (-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (0.5, 0.5, 0.5)]
        vs = [bm.verts.new(p) for p in pts]
        for f in [(0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)]:
            bm.faces.new([vs[i] for i in f])
        bm.normal_update()
        bm.to_mesh(me)
        bm.free()
        me.name = "Wedge"
        return me
    o = bpy.context.active_object
    me = o.data
    me.name = kind
    for p in me.polygons:
        p.use_smooth = kind != "Block"
    bpy.data.objects.remove(o)
    return me


def place(mesh_name, rbx_cf, size, mat, local_fix=None):
    me = base_mesh(mesh_name)
    if len(me.materials) == 0:
        me.materials.append(None)
    o = bpy.data.objects.new("p", me)
    scene.collection.objects.link(o)
    x, y, z, *r = rbx_cf
    R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
    Rb = A @ R
    if mesh_name == "Wedge":
        pass
    # mallas definidas en espacio local de Roblox: convertir local también (escala en ejes de Roblox)
    S = Matrix.Diagonal(Vector(size))
    M = (A @ R @ S).to_4x4()
    M.translation = pos((x, y, z))
    o.matrix_world = M
    o.material_slots[0].link = "OBJECT"
    o.material_slots[0].material = mat
    return o


# Las mallas base están en ejes de Roblox (Y arriba). Las de Blender se crean con Z arriba: las giro.
def to_rbx_local(me_name):
    me = base_mesh(me_name)
    if not me.get("rbx"):
        me.transform(A.inverted().to_4x4())
        me["rbx"] = True


for k in ("Block", "Ball", "Cylinder", "CylY"):
    to_rbx_local(k)
base_mesh("Wedge")["rbx"] = True

for p in data["parts"]:
    if p["t"] >= 0.98:
        continue
    shape = p["s"]
    size = p["size"]
    if p["ms"] and shape.startswith("Mesh"):
        size = [size[i] * p["ms"][i] for i in range(3)]
    kind = {"Block": "Block", "Ball": "Ball", "Cylinder": "Cylinder", "Wedge": "Wedge", "MeshSphere": "Ball",
            "MeshBrick": "Block", "MeshCylinder": "CylY", "CornerWedge": "Wedge"}.get(shape, "Block")
    if kind == "Ball" and shape == "Ball":
        d = min(size)
        size = [d, d, d]
    if kind == "Cylinder":
        d = min(size[1], size[2])
        size = [size[0], d, d]
    if kind == "CylY":
        size = [size[0] / 2, size[1], size[2] / 2]
    place(kind, p["cf"], size, material(p["c"], p["m"], p["t"], p["r"]))

import os
if os.environ.get("VOXELS", "1") == "1":
    sys.path.insert(0, "/home/claude/tools/luau")
    import voxeles
    meshes = voxeles.build(data["terrain"], TERRAIN)
    for name, (world, faces, cols) in meshes.items():
        verts = [tuple(pos(v)) for v in world]
        me = bpy.data.meshes.new(name)
        me.from_pydata(verts, [], [tuple(f[::-1]) for f in faces.tolist()])
        me.update()
        for p in me.polygons:
            p.use_smooth = True
        o = bpy.data.objects.new(name, me)
        scene.collection.objects.link(o)
        mm = bpy.data.materials.new(name)
        mm.use_nodes = True
        bsdf = mm.node_tree.nodes["Principled BSDF"]
        if cols is not None:
            attr = me.color_attributes.new("col", "FLOAT_COLOR", "POINT")
            lin = [[srgb(c) for c in col] + [1.0] for col in cols.tolist()]
            attr.data.foreach_set("color", [x for c in lin for x in c])
            vc = mm.node_tree.nodes.new("ShaderNodeVertexColor")
            vc.layer_name = "col"
            mm.node_tree.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
            bsdf.inputs["Roughness"].default_value = 0.85
        else:
            wc = data.get("waterColor") or [30 / 255, 140 / 255, 200 / 255]
            bsdf.inputs["Base Color"].default_value = [srgb(c) for c in wc] + [1]
            bsdf.inputs["Roughness"].default_value = 0.05
            bsdf.inputs["Transmission Weight"].default_value = 0.55
            bsdf.inputs["IOR"].default_value = 1.33
        me.materials.append(mm)
else:
    for idx, t in enumerate(data["terrain"]):
        col = TERRAIN.get(t["mat"])
        if col is None:
            continue
        eps = idx * 0.0004  # lo rellenado después tapa a lo de antes (como en Roblox)
        if "cf" in t:
            t["cf"] = list(t["cf"])
            t["cf"][1] += eps
        if "center" in t:
            t["center"] = [t["center"][0], t["center"][1] + eps, t["center"][2]]
        m = material([c / 255 for c in col], "Terrain_" + t["mat"], 0.0)
        if t["k"] == "block":
            place("Block", t["cf"], t["size"], m)
        elif t["k"] == "ball":
            c = t["center"]
            r = t["radius"] * 2
            place("Ball", [c[0], c[1], c[2], 1, 0, 0, 0, 1, 0, 0, 0, 1], [r, r, r], m)
        elif t["k"] == "cyl":
            place("CylY", t["cf"], [t["radius"], t["height"], t["radius"]], m)
        elif t["k"] == "wedge":
            place("Wedge", t["cf"], t["size"], m)


# Agua con algo de brillo
for key, m in mats.items():
    if m.name.startswith("Terrain_Water"):
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Roughness"].default_value = 0.05

for l in data["lights"]:
    ld = bpy.data.lights.new("l", "POINT")
    ld.color = l["c"]
    ld.energy = 400 * l["b"] * (l["range"] / 12)
    ld.shadow_soft_size = 1.0
    o = bpy.data.objects.new("l", ld)
    o.location = pos(l["p"])
    scene.collection.objects.link(o)

# Bichos en estilo figura (out/<id>.blend) en las posiciones de muestra.
FIG = os.environ.get("FIGURAS")
if FIG:
    import math as _m
    for c in data.get("critters", []):
        path = f"{FIG}/{c['id']}.blend"
        if not os.path.exists(path):
            continue
        with bpy.data.libraries.load(path) as (src, dst):
            dst.objects = [n for n in src.objects]
        holder = bpy.data.objects.new("bicho", None)
        scene.collection.objects.link(holder)
        for o in dst.objects:
            if o.type == "MESH":
                scene.collection.objects.link(o)
                o.parent = holder
        s = c["size"]
        holder.scale = (s, s, s)
        p = pos(c["p"])
        holder.location = (p.x, p.y, p.z + s * 0.5)
        holder.rotation_euler = (0, 0, c["yaw"])

# Mar hasta el horizonte (en Roblox la neblina de Atmosphere esconde el borde del agua).
bpy.ops.mesh.primitive_plane_add(size=20000, location=(0, 0, -0.85))
mar = bpy.context.active_object
mar.name = "mar_infinito"
mm = bpy.data.materials.new("mar")
mm.use_nodes = True
b = mm.node_tree.nodes["Principled BSDF"]
b.inputs["Base Color"].default_value = [srgb(30 / 255), srgb(140 / 255), srgb(200 / 255), 1]
b.inputs["Roughness"].default_value = 0.08
mar.data.materials.append(mm)

# Cielo de día y sol
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = int(os_env) if (os_env := __import__("os").environ.get("SAMPLES")) else 48
scene.cycles.use_denoising = True
scene.cycles.max_bounces = 4
scene.view_settings.view_transform = "Standard"
w = bpy.data.worlds.new("cielo")
w.use_nodes = True
nt = w.node_tree
grad = nt.nodes.new("ShaderNodeTexGradient")
tc = nt.nodes.new("ShaderNodeTexCoord")
sep = nt.nodes.new("ShaderNodeSeparateXYZ")
ramp = nt.nodes.new("ShaderNodeValToRGB")
nt.links.new(tc.outputs["Generated"], sep.inputs[0])
nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
ramp.color_ramp.elements[0].position = 0.5
ramp.color_ramp.elements[0].color = (0.75, 0.85, 0.95, 1)
ramp.color_ramp.elements[1].position = 0.75
ramp.color_ramp.elements[1].color = (0.25, 0.5, 0.95, 1)
nt.links.new(ramp.outputs["Color"], nt.nodes["Background"].inputs[0])
nt.nodes["Background"].inputs[1].default_value = 1.0
scene.world = w
sd = bpy.data.lights.new("sol", "SUN")
sd.energy = 3.2
sd.angle = math.radians(2)
so = bpy.data.objects.new("sol", sd)
so.rotation_euler = (math.radians(42), 0, math.radians(140))
scene.collection.objects.link(so)

VIEWS = {
    # nombre: (posición Roblox de la cámara, objetivo Roblox, lente)
    "aerea": ((150, 190, 230), (0, 0, -60), 30),
    "plaza": ((0, 60, 230), (0, 0, 40), 28),
    "suelo": ((0, 8, 70), (0, 6, -40), 24),
    "bovedas": ((-40, 45, -20), (10, 0, -150), 26),
    "cenital": ((0, 700, -100), (0, 0, -101), 50),
    "isla": ((620, 520, 900), (0, -20, 40), 26),
    "isla2": ((-750, 420, -650), (0, 0, 0), 26),
    "llegada": ((0, 12, 132), (0, 22, 0), 24),
    "plazaalta": ((150, 110, 230), (0, 10, 0), 24),
    "zonas": ((-60, 70, 230), (-260, 20, -200), 26),
    "volcan2": ((-170, 50, 250), (-500, 60, -100), 24),
    "nubes": ((80, 60, -200), (-150, 50, -300), 26),
}
for v in views:
    cpos, tgt, lens = VIEWS[v]
    cd = bpy.data.cameras.new(v)
    cd.lens = lens
    cd.clip_end = 5000
    cam = bpy.data.objects.new(v, cd)
    cam.location = pos(cpos)
    cam.rotation_euler = (pos(tgt) - pos(cpos)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    scene.render.filepath = f"{prefix}_{v}.png"
    bpy.ops.render.render(write_still=True)
    print("guardado", scene.render.filepath)
