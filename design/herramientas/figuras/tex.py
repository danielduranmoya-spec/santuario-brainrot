"""Materiales con detalle (degradado, pelo en relieve, oclusión) y horneado a texturas para Roblox
(color + normales), de modo que lo que se ve en la vista previa es lo que se verá en el juego."""
import bpy

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).parent / "base"))
import lib


def _ramp(nt, stops):
    r = nt.nodes.new("ShaderNodeValToRGB")
    r.color_ramp.elements[0].position, r.color_ramp.elements[0].color = stops[0][0], [lib.srgb(c) for c in stops[0][1]] + [1]
    r.color_ramp.elements[1].position, r.color_ramp.elements[1].color = stops[-1][0], [lib.srgb(c) for c in stops[-1][1]] + [1]
    for pos, col in stops[1:-1]:
        e = r.color_ramp.elements.new(pos)
        e.color = [lib.srgb(c) for c in col] + [1]
    return r


def furry(name, back, belly, mid=None, fur=0.5, fur_scale=60.0, rough=0.6, ao=True, flow=(1.0, 0.3, 1.0), spots=None):
    """Pelaje/piel de figura: oscuro arriba, claro en la barriga (según hacia dónde mira la superficie),
    mechones en relieve que fluyen hacia atrás y sombras suaves en los huecos."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    N, L = nt.nodes, nt.links
    b = N["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough
    b.inputs["Coat Weight"].default_value = 0.1
    geo = N.new("ShaderNodeNewGeometry")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Normal"], sep.inputs[0])
    ramp = _ramp(nt, [(0.25, belly), (0.5, mid or tuple((a + c) / 2 for a, c in zip(back, belly))), (0.72, back)])
    fac = N.new("ShaderNodeMapRange")
    fac.inputs["From Min"].default_value = -1
    fac.inputs["From Max"].default_value = 1
    L.new(sep.outputs["Z"], fac.inputs["Value"])
    # variación suave de color
    tc = N.new("ShaderNodeTexCoord")
    nz = N.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 6
    L.new(tc.outputs["Object"], nz.inputs["Vector"])
    add = N.new("ShaderNodeMath")
    add.operation = "ADD"
    sub = N.new("ShaderNodeMath")
    sub.operation = "MULTIPLY_ADD"
    sub.inputs[1].default_value = 0.12
    sub.inputs[2].default_value = -0.06
    L.new(nz.outputs["Fac"], sub.inputs[0])
    L.new(fac.outputs["Result"], add.inputs[0])
    L.new(sub.outputs[0], add.inputs[1])
    L.new(add.outputs[0], ramp.inputs["Fac"])
    color = ramp.outputs["Color"]
    if spots:
        vor = N.new("ShaderNodeTexVoronoi")
        vor.inputs["Scale"].default_value = spots[1]
        L.new(tc.outputs["Object"], vor.inputs["Vector"])
        sr = N.new("ShaderNodeValToRGB")
        sr.color_ramp.elements[0].position = 0.18
        sr.color_ramp.elements[0].color = (1, 1, 1, 1)
        sr.color_ramp.elements[1].position = 0.24
        sr.color_ramp.elements[1].color = (0, 0, 0, 1)
        L.new(vor.outputs["Distance"], sr.inputs["Fac"])
        mx = N.new("ShaderNodeMix")
        mx.data_type = "RGBA"
        L.new(sr.outputs["Color"], mx.inputs["Factor"])
        L.new(color, mx.inputs[6])
        mx.inputs[7].default_value = [lib.srgb(c) for c in spots[0]] + [1]
        color = mx.outputs[2]
    if ao:
        aon = N.new("ShaderNodeAmbientOcclusion")
        aon.inputs["Distance"].default_value = 0.15
        mul = N.new("ShaderNodeMix")
        mul.data_type = "RGBA"
        mul.blend_type = "MULTIPLY"
        mul.inputs["Factor"].default_value = 0.55
        L.new(color, mul.inputs[6])
        L.new(aon.outputs["Color"], mul.inputs[7])
        # la oclusión se mezcla hacia blanco donde no hay huecos
        color = mul.outputs[2]
        aon_in = aon.inputs["Color"]
        aon_in.default_value = (1, 1, 1, 1)
    L.new(color, b.inputs["Base Color"])
    if fur:
        mp = N.new("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = flow
        L.new(tc.outputs["Object"], mp.inputs["Vector"])
        fz = N.new("ShaderNodeTexNoise")
        fz.inputs["Scale"].default_value = fur_scale
        fz.inputs["Detail"].default_value = 4
        fz.inputs["Distortion"].default_value = 1.2
        L.new(mp.outputs["Vector"], fz.inputs["Vector"])
        bump = N.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = fur
        bump.inputs["Distance"].default_value = 0.01
        L.new(fz.outputs["Fac"], bump.inputs["Height"])
        L.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def bake(obj, res=512, margin=6):
    """Hornea el color (con la oclusión) y las normales del material de `obj` a dos imágenes y
    deja un material simple que solo usa esas texturas (lo mismo que verá Roblox)."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    src = obj.active_material
    imgs = {}
    for kind in ("color", "normal"):
        img = bpy.data.images.new(f"{obj.name}_{kind}", res, res, alpha=False)
        img.colorspace_settings.name = "sRGB" if kind == "color" else "Non-Color"
        node = src.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = img
        src.node_tree.nodes.active = node
        if kind == "color":
            scene.cycles.bake_type = "DIFFUSE"
            scene.render.bake.use_pass_direct = False
            scene.render.bake.use_pass_indirect = False
            scene.render.bake.use_pass_color = True
        else:
            scene.cycles.bake_type = "NORMAL"
        scene.render.bake.margin = margin
        bpy.ops.object.bake(type=scene.cycles.bake_type)
        src.node_tree.nodes.remove(node)
        imgs[kind] = img
    # material final
    m = bpy.data.materials.new(obj.name + "_tex")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = src.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value
    t1 = nt.nodes.new("ShaderNodeTexImage")
    t1.image = imgs["color"]
    nt.links.new(t1.outputs["Color"], b.inputs["Base Color"])
    t2 = nt.nodes.new("ShaderNodeTexImage")
    t2.image = imgs["normal"]
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(t2.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    obj.data.materials.clear()
    obj.data.materials.append(m)
    return imgs


def sculpt(name, material, shapes=(), limbs=(), voxel=0.016, smooth=22):
    """Escultura de una pieza: elipsoides (centro, radios, giro) + extremidades (lista de puntos con
    radio cada uno: [(x, y, z, r), ...]) fundidas con un remallado de vóxeles y bien suavizadas."""
    import math as _m
    from mathutils import Vector as _V
    objs = []
    for s in shapes:
        co, radii = s[0], s[1]
        rot = s[2] if len(s) > 2 else (0, 0, 0)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1, location=co)
        o = bpy.context.active_object
        o.scale = radii
        o.rotation_euler = [_m.radians(a) for a in rot]
        objs.append(o)
    for pts in limbs:
        cd = bpy.data.curves.new("ext", "CURVE")
        cd.dimensions = "3D"
        cd.bevel_depth = 1.0
        cd.bevel_resolution = 6
        cd.use_fill_caps = True
        sp = cd.splines.new("NURBS")
        sp.points.add(len(pts) - 1)
        for i, (x, y, z, r) in enumerate(pts):
            sp.points[i].co = (x, y, z, 1)
            sp.points[i].radius = r
        sp.order_u = min(4, len(pts))
        sp.use_endpoint_u = True
        sp.resolution_u = 16
        o = bpy.data.objects.new("ext", cd)
        bpy.context.scene.collection.objects.link(o)
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.convert(target="MESH")
        objs.append(bpy.context.active_object)
        # extremos redondeados
        for (x, y, z, r) in (pts[0], pts[-1]):
            bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=r, location=(x, y, z))
            objs.append(bpy.context.active_object)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    r = obj.modifiers.new("remesh", "REMESH")
    r.mode = "VOXEL"
    r.voxel_size = voxel
    bpy.ops.object.modifier_apply(modifier="remesh")
    sm = obj.modifiers.new("smooth", "LAPLACIANSMOOTH")
    sm.iterations = smooth
    sm.lambda_factor = 0.8
    sm.use_volume_preserve = True
    bpy.ops.object.modifier_apply(modifier="smooth")
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def veined(name, base, vein, scale=1.3, width=0.02, distort=0.35, bump=0.4, rough=0.45):
    """Superficie oscura con venas/grietas de color vivo (quedan pintadas en la textura horneada)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    N, L = nt.nodes, nt.links
    b = N["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough
    tc = N.new("ShaderNodeTexCoord")
    dn = N.new("ShaderNodeTexNoise")
    dn.inputs["Scale"].default_value = scale * 1.5
    mix = N.new("ShaderNodeMix")
    mix.data_type = "VECTOR"
    mix.inputs["Factor"].default_value = distort
    L.new(tc.outputs["Object"], dn.inputs["Vector"])
    L.new(tc.outputs["Object"], mix.inputs[4])
    L.new(dn.outputs["Color"], mix.inputs[5])
    vor = N.new("ShaderNodeTexVoronoi")
    vor.feature = "DISTANCE_TO_EDGE"
    vor.inputs["Scale"].default_value = scale
    L.new(mix.outputs[1], vor.inputs["Vector"])
    ramp = N.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = [lib.srgb(c) for c in vein] + [1]
    ramp.color_ramp.elements[1].position = width
    ramp.color_ramp.elements[1].color = [lib.srgb(c) for c in base] + [1]
    L.new(vor.outputs["Distance"], ramp.inputs["Fac"])
    L.new(ramp.outputs["Color"], b.inputs["Base Color"])
    if bump:
        bn = N.new("ShaderNodeBump")
        bn.inputs["Strength"].default_value = bump
        L.new(vor.outputs["Distance"], bn.inputs["Height"])
        L.new(bn.outputs["Normal"], b.inputs["Normal"])
    return m
