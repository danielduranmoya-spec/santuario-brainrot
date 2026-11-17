"""Uso: python3 hacer.py b_murcielago [más módulos...] -> out/<id>.json, .fbx, .blend y _prev.png"""
import importlib, sys, traceback
sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))
import fig
OUT = str(__import__("pathlib").Path(__file__).parent / "out")
def items():
    for modname in sys.argv[1:]:
        name, _, only = modname.partition(":")
        mod = importlib.import_module(name)
        for c in getattr(mod, "LOTE", [mod]):
            if not only or c.ID == only:
                yield c.ID, c
for modname, mod in items():
    try:
        fig.reset()
        mod.build()
        meta = fig.export(mod.ID, OUT, wide=getattr(mod, "WIDE", 1.9))
        fig.save_fbx(mod.ID, OUT)
        fig.preview(f"{OUT}/{mod.ID}_prev.png", mod.RARITY, yaw=getattr(mod, "YAW", -30))
        print("OK", mod.ID, len(meta), "piezas", sum(m["tris"] for m in meta), "triángulos")
    except Exception:
        print("FALLO", modname)
        traceback.print_exc()
