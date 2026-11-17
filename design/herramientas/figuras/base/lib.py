"""Utilidades para modelar bichos en Blender (bpy) por código y renderizarlos.
Ejes de Blender: Z arriba, el bicho mira hacia -Y.
"""
import math
import bpy
from mathutils import Vector, Euler


def srgb(x):
    x = x / 255
    return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, rough=0.42, emission=None, strength=4.0, metallic=0.0, coat=0.25, sss=0.0, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    c = [srgb(x) for x in color] + [1]
    b.inputs["Base Color"].default_value = c
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Coat Weight"].default_value = coat
    if sss:
        b.inputs["Subsurface Weight"].default_value = sss
        b.inputs["Subsurface Radius"].default_value = (0.3, 0.15, 0.1)
    if emission:
        b.inputs["Emission Color"].default_value = [srgb(x) for x in emission] + [1]
        b.inputs["Emission Strength"].default_value = strength
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
        b.inputs["Transmission Weight"].default_value = 0.6
    m["rgb"] = list(color)
    return m


def _finish(obj, material, smooth=True):
    obj.data.materials.clear()
    obj.data.materials.append(material)
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    return obj


def blob(name, shapes, material, voxel=0.028, smooth=12):
    """Forma orgánica esculpida: elipsoides (centro, radios (rx,ry,rz), giro_grados?) unidos con un
    remallado de vóxeles y suavizados para que las uniones queden redondeadas, como arcilla."""
    objs = []
    for i, s in enumerate(shapes):
        co, radii = s[0], s[1]
        rot = s[2] if len(s) > 2 else (0, 0, 0)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1, location=co)
        o = bpy.context.active_object
        o.scale = radii
        o.rotation_euler = [math.radians(a) for a in rot]
        objs.append(o)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    r = obj.modifiers.new("remesh", "REMESH")
    r.mode = "VOXEL"
    r.voxel_size = voxel
    if smooth:
        sm = obj.modifiers.new("smooth", "SMOOTH")
        sm.factor = 0.9
        sm.iterations = smooth
    bpy.ops.object.modifier_apply(modifier="remesh")
    if smooth:
        bpy.ops.object.modifier_apply(modifier="smooth")
    return _finish(obj, material)


def prim(name, kind, material, loc=(0, 0, 0), scale=(1, 1, 1), rot=(0, 0, 0), subd=2, **kw):
    """Primitiva suavizada: 'sphere', 'cone', 'cyl', 'torus', 'cube'."""
    ops = {
        "sphere": lambda: bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1),
        "cone": lambda: bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=1, radius2=kw.get("r2", 0.0), depth=2),
        "cyl": lambda: bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=1, depth=2),
        "torus": lambda: bpy.ops.mesh.primitive_torus_add(major_radius=1, minor_radius=kw.get("minor", 0.25), major_segments=40, minor_segments=14),
        "cube": lambda: bpy.ops.mesh.primitive_cube_add(size=2),
    }
    ops[kind]()
    obj = bpy.context.active_object
    obj.name = name
    obj.location = loc
    obj.scale = scale
    obj.rotation_euler = [math.radians(a) for a in rot]
    if subd:
        m = obj.modifiers.new("subd", "SUBSURF")
        m.levels = subd
        m.render_levels = subd
    if kw.get("bevel"):
        bv = obj.modifiers.new("bevel", "BEVEL")
        bv.width = kw["bevel"]
        bv.segments = 3
        obj.modifiers.move(len(obj.modifiers) - 1, 0)
    return _finish(obj, material, smooth=kind != "cube" or bool(subd))


def eye(name, center, r, look=(0, -1, 0), white=True, mats=None):
    """Ojo brillante de dibujo: globo oscuro, iris opcional y dos reflejos blancos."""
    dark, shine, whitem = mats
    c = Vector(center)
    d = Vector(look).normalized()
    parts = []
    if white:
        parts.append(prim(name + "_blanco", "sphere", whitem, c, (r * 1.08,) * 3, subd=1))
        c = c + d * r * 0.35
        r = r * 0.82
    parts.append(prim(name + "_pupila", "sphere", dark, c, (r, r, r * 1.12), subd=1))
    up = Vector((0, 0, 1))
    side = d.cross(up).normalized()
    parts.append(prim(name + "_brillo1", "sphere", shine, c + d * r * 0.8 + up * r * 0.38 - side * r * 0.3, (r * 0.3,) * 3, subd=1))
    parts.append(prim(name + "_brillo2", "sphere", shine, c + d * r * 0.88 - up * r * 0.25 + side * r * 0.3, (r * 0.14,) * 3, subd=1))
    return parts


def apply_all():
    """Aplica modificadores (para exportar)."""
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH" and obj.modifiers:
            bpy.context.view_layer.objects.active = obj
            for m in list(obj.modifiers):
                bpy.ops.object.modifier_apply(modifier=m.name)


def stage(ring_rgb, ground_z=0.0, ring_r=1.1):
    """Luces, cámara, suelo que solo recoge sombra y aro de rareza."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 96
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.6, 0.75, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.35
    scene.world = world

    def light(name, kind, loc, energy, size, color=(1, 1, 1)):
        ld = bpy.data.lights.new(name, kind)
        ld.energy = energy
        ld.color = color
        if kind == "AREA":
            ld.size = size
        o = bpy.data.objects.new(name, ld)
        o.location = loc
        d = Vector((0, 0, 0.8)) - Vector(loc)
        o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(o)

    light("key", "AREA", (-3.2, -4.0, 5.0), 260, 4.0, (1.0, 0.96, 0.9))
    light("fill", "AREA", (4.0, -3.0, 2.0), 70, 5.0, (0.85, 0.9, 1.0))
    light("rim", "AREA", (1.5, 4.5, 4.0), 260, 3.0, (0.9, 0.95, 1.0))

    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, ground_z))
    ground = bpy.context.active_object
    ground.is_shadow_catcher = True
    ring_m = mat("aro", ring_rgb, emission=ring_rgb, strength=1.2)
    ring = prim("aro_rareza", "torus", ring_m, (0, 0, ground_z + 0.01), (ring_r, ring_r, 0.25), minor=0.06, subd=1)
    ring["preview_only"] = True
    ground["preview_only"] = True


def camera(target=(0, 0, 0.8), dist=6.5, yaw=-30, pitch=14, lens=55):
    scene = bpy.context.scene
    cd = bpy.data.cameras.new("cam")
    cd.lens = lens
    cam = bpy.data.objects.new("cam", cd)
    t = Vector(target)
    yr, pr = math.radians(yaw), math.radians(pitch)
    cam.location = t + Vector((math.sin(yr) * math.cos(pr), -math.cos(yr) * math.cos(pr), math.sin(pr))) * dist
    cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam


def render(path, size=640):
    scene = bpy.context.scene
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def lava_rock(name, base, crack=(255, 110, 20), scale=6.0, width=0.06, glow=6.0, rough=0.8, bump=0.4, fur=False, distort=0.0):
    """Roca volcánica: base oscura con relieve y grietas (Voronoi) por las que brilla la lava."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    N, L = nt.nodes, nt.links
    b = N["Principled BSDF"]
    b.inputs["Base Color"].default_value = [srgb(x) for x in base] + [1]
    b.inputs["Roughness"].default_value = rough
    tc = N.new("ShaderNodeTexCoord")
    vor = N.new("ShaderNodeTexVoronoi")
    vor.feature = "DISTANCE_TO_EDGE"
    vor.inputs["Scale"].default_value = scale
    if distort:
        dn = N.new("ShaderNodeTexNoise")
        dn.inputs["Scale"].default_value = scale * 1.5
        dn.inputs["Detail"].default_value = 4
        mix = N.new("ShaderNodeMix")
        mix.data_type = "VECTOR"
        mix.inputs["Factor"].default_value = distort
        L.new(tc.outputs["Object"], dn.inputs["Vector"])
        L.new(tc.outputs["Object"], mix.inputs[4])
        L.new(dn.outputs["Color"], mix.inputs[5])
        L.new(mix.outputs[1], vor.inputs["Vector"])
    else:
        L.new(tc.outputs["Object"], vor.inputs["Vector"])
    ramp = N.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (1, 1, 1, 1)
    ramp.color_ramp.elements[1].position = width
    ramp.color_ramp.elements[1].color = (0, 0, 0, 1)
    L.new(vor.outputs["Distance"], ramp.inputs["Fac"])
    L.new(ramp.outputs["Color"], b.inputs["Emission Strength"])
    b.inputs["Emission Color"].default_value = [srgb(x) for x in crack] + [1]
    # la fuerza: multiplicar la máscara
    mul = N.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = glow
    L.new(ramp.outputs["Color"], mul.inputs[0])
    L.new(mul.outputs[0], b.inputs["Emission Strength"])
    if bump:
        noise = N.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = scale * (6 if fur else 2.5)
        noise.inputs["Detail"].default_value = 8
        L.new(tc.outputs["Object"], noise.inputs["Vector"])
        bn = N.new("ShaderNodeBump")
        bn.inputs["Strength"].default_value = bump
        L.new(noise.outputs["Fac"], bn.inputs["Height"])
        L.new(bn.outputs["Normal"], b.inputs["Normal"])
    m["rgb"] = list(base)
    return m


def tube(name, points, r0, r1, material, res=12):
    """Tubo suave (curva con grosor que va de r0 a r1) que pasa por los puntos."""
    cd = bpy.data.curves.new(name, "CURVE")
    cd.dimensions = "3D"
    cd.bevel_depth = 1.0
    cd.bevel_resolution = 4
    cd.use_fill_caps = True
    sp = cd.splines.new("NURBS")
    sp.points.add(len(points) - 1)
    for i, pt in enumerate(points):
        t = i / (len(points) - 1)
        sp.points[i].co = (*pt, 1)
        sp.points[i].radius = r0 + (r1 - r0) * t
    sp.order_u = min(4, len(points))
    sp.use_endpoint_u = True
    sp.resolution_u = res
    o = bpy.data.objects.new(name, cd)
    bpy.context.scene.collection.objects.link(o)
    cd.materials.append(material)
    return o


def membrane(name, outline, material, thickness=0.02, sag=0.0, subd=2):
    """Membrana de ala: polígono (lista de puntos en orden) rellenado en abanico desde su centro,
    con un poco de grosor y suavizado. `sag` hunde el centro hacia +Y (la tela se curva con el aire)."""
    import bmesh
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    cx = sum(p[0] for p in outline) / len(outline)
    cy = sum(p[1] for p in outline) / len(outline) + sag
    cz = sum(p[2] for p in outline) / len(outline)
    c = bm.verts.new((cx, cy, cz))
    vs = [bm.verts.new(p) for p in outline]
    for i in range(len(vs)):
        bm.faces.new((c, vs[i], vs[(i + 1) % len(vs)]))
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    s = o.modifiers.new("sub", "SUBSURF")
    s.levels = s.render_levels = subd
    so = o.modifiers.new("solid", "SOLIDIFY")
    so.thickness = thickness
    so.offset = 0
    s2 = o.modifiers.new("sub2", "SUBSURF")
    s2.levels = s2.render_levels = 1
    return _finish(o, material)


def scallop(a, b, depth, n=4, inward=(0, 0, 0)):
    """Puntos de un borde festoneado entre a y b, hundido `depth` hacia `inward`."""
    out = []
    for i in range(1, n):
        t = i / n
        k = math.sin(math.pi * t) * depth
        out.append(tuple(a[j] + (b[j] - a[j]) * t + inward[j] * k for j in range(3)))
    return out
