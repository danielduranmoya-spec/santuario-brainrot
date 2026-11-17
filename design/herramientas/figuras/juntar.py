"""Junta los 21 bichos (out/<id>.blend) en un solo FBX: bichos_figura.fbx."""
import glob, math, os, bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
roots = []
for path in sorted(glob.glob("" + str(__import__("pathlib").Path(__file__).parent / "out") + "/*.blend")):
    cid = os.path.basename(path)[:-6]
    with bpy.data.libraries.load(path) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
        bpy.context.scene.collection.objects.link(o)
    root = bpy.data.objects[cid]
    root.rotation_euler = (0, 0, math.pi)
    roots.append(root)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.fbx(filepath="" + str(__import__("pathlib").Path(__file__).parent / "out") + "/bichos_figura.fbx", use_selection=True, object_types={"EMPTY", "MESH"},
                         apply_scale_options="FBX_SCALE_UNITS", global_scale=10.0, mesh_smooth_type="FACE", add_leaf_bones=False)
print("juntados", len(roots), sum(len(r.children) for r in roots), "piezas")
