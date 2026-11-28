from PIL import Image, ImageDraw, ImageFont
import json
from pathlib import Path

root = Path(r"D:\ai\GearLab\_tmp_cameras")
assets = Path(r"D:\ai\GearLab\flutter_app\assets\cameras")
photo = Image.open(r"D:\ai\GearLab\_shots\test-photo.jpg").convert("RGB")
cal = json.loads((root / "calibration.json").read_text(encoding="utf-8"))
items = [t for t in cal["templates"] if t["id"] != "nikon-z5ii"]
items.append({"id": "nikon-z30", "brand": "NIKON", "model": "Z30", "width": 678, "height": 400, "screen": [55, 105, 405, 262]})
items.sort(key=lambda t: t["id"])

def cover(im, box):
    x, y, w, h = box
    scale = max(w / im.width, h / im.height)
    nw, nh = max(1, round(im.width * scale)), max(1, round(im.height * scale))
    resized = im.resize((nw, nh), Image.LANCZOS)
    left = (nw - w) // 2
    top = (nh - h) // 2
    return resized.crop((left, top, left + w, top + h))

thumbs = []
for t in items:
    cam = Image.open(assets / f"{t['id']}.png").convert("RGBA")
    x, y, w, h = t["screen"]
    bg = Image.new("RGBA", cam.size, (38, 41, 45, 255))
    bg.alpha_composite(cam)
    bg.paste(cover(photo, (x, y, w, h)), (x, y))
    d = ImageDraw.Draw(bg)
    d.rectangle([x, y, x + w, y + h], outline=(0, 255, 120), width=2)
    bg.thumbnail((640, 480), Image.LANCZOS)
    thumbs.append((t["id"], bg.copy()))

cols = 4
tw, th = 660, 530
rows = (len(thumbs) + cols - 1) // cols
sheet = Image.new("RGB", (cols * tw, rows * th), (20, 22, 24))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arial.ttf", 17)
except Exception:
    font = ImageFont.load_default()
for i, (cid, im) in enumerate(thumbs):
    x = (i % cols) * tw + (tw - im.width) // 2
    y = (i // cols) * th + 8
    sheet.paste(im.convert("RGB"), (x, y))
    d.text(((i % cols) * tw + 10, (i // cols) * th + th - 26), cid, fill=(255, 255, 255), font=font)
out = root / "overlay_contact.png"
sheet.save(out)
print(out, sheet.size)
