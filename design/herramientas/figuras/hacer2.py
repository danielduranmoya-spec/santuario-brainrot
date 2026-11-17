"""python3 hacer2.py v2_lote1[:id] ... -> out2/<id>.json/.blend/tex, _prev.png y _comp.png (antes/después)"""
import importlib, sys, traceback
sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))
import fig2
from PIL import Image, ImageDraw, ImageFont
OUT = str(__import__("pathlib").Path(__file__).parent / "out2")

def comparison(cid, title):
    def card(p):
        im = Image.open(p).convert("RGBA").resize((520, 520)); bg = Image.new("RGBA", im.size, (52, 55, 80, 255)); bg.alpha_composite(im); return bg.convert("RGB")
    s = Image.new("RGB", (1080, 600), (28, 29, 43)); d = ImageDraw.Draw(s)
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
    s.paste(card(f"{OUT}/../antes/{cid}_prev.png"), (20, 64)); s.paste(card(f"{OUT}/{cid}_prev.png"), (540, 64))
    d.text((20, 18), "Antes", font=f, fill=(200, 200, 210)); d.text((540, 18), "Ahora · " + title, font=f, fill=(255, 200, 120))
    s.save(f"{OUT}/{cid}_comp.png")

for arg in sys.argv[1:]:
    name, _, only = arg.partition(":")
    mod = importlib.import_module(name)
    for c in mod.LOTE:
        if only and c.ID != only:
            continue
        try:
            fig2.reset(); c.build()
            meta = fig2.export(c.ID, OUT, wide=getattr(c, "WIDE", 1.9))
            fig2.save(c.ID, OUT)
            fig2.preview(f"{OUT}/{c.ID}_prev.png", c.RARITY, yaw=getattr(c, "YAW", -32))
            comparison(c.ID, c.TITLE)
            print("OK", c.ID, len(meta), "piezas", sum(m["tris"] for m in meta), "tri")
        except Exception:
            print("FALLO", c.ID); traceback.print_exc()
