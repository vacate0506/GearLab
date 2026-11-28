from PIL import Image, ImageDraw, ImageFont
import numpy as np
import cv2
from pathlib import Path

out = Path(r"D:\ai\GearLab\_tmp_cameras\processed")
ids = [p.stem for p in sorted(out.glob("*.png")) if p.name != "contact_processed.png"]
print(ids)

def candidates(path):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    rgb = a[:, :, :3].astype(np.float32)
    alpha = a[:, :, 3]
    gray = cv2.cvtColor(rgb.astype(np.uint8), cv2.COLOR_RGB2GRAY)
    # local standard deviation
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
        # Keep only reasonably centered screen areas (not a corner patch)
        cx, cy = x + ww / 2, y + hh / 2
        if cx < w * 0.10 or cx > w * 0.85 or cy < h * 0.15 or cy > h * 0.9:
            continue
        score = area * fill
        cands.append((score, x, y, ww, hh, fill, ar))
    cands.sort(reverse=True)
    return im, cands[:5]

for cid in ids:
    im, cands = candidates(out / f"{cid}.png")
    print(f"\n{cid} {im.size}")
    for c in cands:
        _, x, y, ww, hh, fill, ar = c
        print(f"  {x},{y},{ww},{hh} norm=({x/im.width:.4f},{y/im.height:.4f},{ww/im.width:.4f},{hh/im.height:.4f}) fill={fill:.2f} ar={ar:.2f}")
