from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
out = Path(r"D:\ai\GearLab\_tmp_cameras\processed")
ids = ["fujifilm-gfx100-ii", "fujifilm-x-h2", "fujifilm-x-h2s", "fujifilm-x-t5", "nikon-fe", "canon-eos-r6-v", "sony-zv-e10"]
for cid in ids:
    im = Image.open(out / f"{cid}.png").convert("RGBA")
    bg = Image.new("RGBA", im.size, (32, 35, 38, 255))
    bg.alpha_composite(im)
    d = ImageDraw.Draw(bg)
    step = 50
    for x in range(0, im.width, step):
        color = (255, 70, 70) if x % 100 == 0 else (80, 80, 80)
        d.line([(x, 0), (x, im.height)], fill=color, width=1)
        if x % 100 == 0:
            d.text((x + 2, 2), str(x), fill=(255, 220, 0), font=ImageFont.load_default())
    for y in range(0, im.height, step):
        color = (255, 70, 70) if y % 100 == 0 else (80, 80, 80)
        d.line([(0, y), (im.width, y)], fill=color, width=1)
        if y % 100 == 0:
            d.text((2, y + 1), str(y), fill=(255, 220, 0), font=ImageFont.load_default())
    bg.convert("RGB").save(out / f"grid-{cid}.png")
    print(cid, im.size)
