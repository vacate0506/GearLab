from PIL import Image, ImageDraw, ImageFont
import numpy as np
import cv2
from pathlib import Path

out = Path(r"D:\ai\GearLab\_tmp_cameras\processed")
ids = [p.stem for p in sorted(out.glob("*.png")) if p.name != "contact_processed.png"]

def candidates(path):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    rgb = a[:, :, :3].astype(np.float32)
    alpha = a[:, :, 3]
    gray = cv2.cvtColor(rgb.astype(np.uint8), cv2.COLOR_RGB2GRAY)
    mean = cv2.boxFilter(gray.astype(np.float32), -1, (9, 9))
    sq = cv2.boxFilter((gray.astype(np.float32)) ** 2, -1, (9, 9))
    std = np.sqrt(np.maximum(0, sq - mean * mean))
    mask = ((gray < 120) & (std < 8) & (alpha > 200)).astype(np.uint8) * 255
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    n, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    h, w = gray.shape
    cands = []
    for i in range(1, n):
        x, y, ww, hh, area = stats[i]
        if area < w * h * 0.015 or ww < 40 or hh < 30:
            continue
        if ww > w * 0.85 or hh > h * 0.85:
            continue
        ar = ww / hh
        if not (1.15 <= ar <= 2.2):
            continue
        fill = area / (ww * hh)
        if fill < 0.55:
            continue
        cx, cy = x + ww / 2, y + hh / 2
        if cx < w * 0.10 or cx > w * 0.85 or cy < h * 0.15 or cy > h * 0.9:
            continue
        score = area * fill
        cands.append((score, x, y, ww, hh, fill, ar))
    cands.sort(reverse=True)
    return im, cands[:4]

thumbs = []
for cid in ids:
    im, cands = candidates(out / f"{cid}.png")
    bg = Image.new("RGBA", im.size, (32, 35, 38, 255))
    bg.alpha_composite(im)
    sheet = bg.convert("RGB")
    d = ImageDraw.Draw(sheet)
    colors = [(255, 45, 45), (255, 210, 0), (0, 255, 120), (0, 200, 255)]
    for i, (_, x, y, ww, hh, fill, ar) in enumerate(cands):
        d.rectangle([x, y, x + ww, y + hh], outline=colors[i], width=max(2, im.width // 300))
        d.text((x + 4, max(0, y - 18)), f"{i+1}", fill=colors[i], font=ImageFont.load_default())
    sheet.thumbnail((700, 500), Image.LANCZOS)
    thumbs.append((cid, sheet.copy(), len(cands)))

cols = 3
tw, th = 720, 560
rows = (len(thumbs) + cols - 1) // cols
cs = Image.new("RGB", (cols * tw, rows * th), (20, 22, 24))
d = ImageDraw.Draw(cs)
try:
    font = ImageFont.truetype("arial.ttf", 18)
except Exception:
    font = ImageFont.load_default()
for i, (cid, im, n) in enumerate(thumbs):
    x = (i % cols) * tw + (tw - im.width) // 2
    y = (i // cols) * th + 6
    cs.paste(im, (x, y))
    d.text(((i % cols) * tw + 10, (i // cols) * th + th - 26), f"{cid}  ({n} candidates)", fill=(255, 255, 255), font=font)
cs.save(out / "candidates.png")
print(out / "candidates.png", cs.size)
