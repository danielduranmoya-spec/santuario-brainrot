"""Hoja de contacto: python3 hoja.py salida.png id1 id2 ... (usa out/<id>_prev.png)"""
import sys
from PIL import Image, ImageDraw, ImageFont
out, ids = sys.argv[1], sys.argv[2:]
cols = min(4, len(ids)); rows = (len(ids) + cols - 1) // cols
W = 300
sheet = Image.new("RGB", (cols * W, rows * (W + 34)), (28, 29, 43))
d = ImageDraw.Draw(sheet)
f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 17)
for i, cid in enumerate(ids):
    im = Image.open(f"out/{cid}_prev.png").convert("RGBA").resize((W, W))
    bg = Image.new("RGBA", (W, W), (52, 55, 80, 255)); bg.alpha_composite(im)
    x, y = (i % cols) * W, (i // cols) * (W + 34)
    sheet.paste(bg.convert("RGB"), (x, y)); d.text((x + 10, y + W + 6), cid, font=f, fill=(255, 255, 255))
sheet.save(out)
