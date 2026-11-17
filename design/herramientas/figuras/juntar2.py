"""Junta los 21 bichos v2 (out2/<id>.blend) en un FBX con las texturas dentro: bichos_figura.fbx."""
import glob, os, math, bpy
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out2")
bpy.ops.wm.read_factory_settings(use_empty=True)
for path in sorted(glob.glob(f"{OUT}/*.blend")):
    cid = os.path.basename(path)[:-6]
    with bpy.data.libraries.load(path) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
        if o.type in ("MESH", "EMPTY"):
            bpy.context.scene.collection.objects.link(o)
    bpy.data.objects[cid].rotation_euler = (0, 0, math.pi)
os.makedirs(f"{OUT}/jpg", exist_ok=True)
bpy.context.scene.render.image_settings.quality = 88
for img in list(bpy.data.images):
    if img.size[0] == 0:
        continue
    if img.packed_file:
        img.unpack(method="USE_ORIGINAL")
    path = f"{OUT}/jpg/{img.name.replace('.png', '')}.jpg"
    img.filepath_raw = path
    img.file_format = "JPEG"
    img.save()
    img.pack()
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.fbx(filepath=f"{OUT}/bichos_figura.fbx", use_selection=True, object_types={"EMPTY", "MESH"},
                         apply_scale_options="FBX_SCALE_UNITS", global_scale=10.0, mesh_smooth_type="FACE", add_leaf_bones=False,
                         path_mode="COPY", embed_textures=True)
print("juntados", len([o for o in bpy.data.objects if o.type == "EMPTY"]), "bichos")
