from PIL import Image, ImageDraw, ImageFont
import numpy as np
import cv2
from pathlib import Path

root = Path("D:/ai_img")
matches = [p for p in root.glob("**/*z30*.png") if p.is_file()]
print("matches", matches)
src = matches[0]
out = Path(r"D:\ai\GearLab\_tmp_cameras\processed")
out.mkdir(parents=True, exist_ok=True)

def background_alpha(rgb, tol=55):
    h, w = rgb.shape[:2]
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]], axis=0)
    bg = np.median(border, axis=0)
    mask = np.zeros((h + 2, w + 2), np.uint8)
    flags = 4 | (255 << 8) | cv2.FLOODFILL_MASK_ONLY | cv2.FLOODFILL_FIXED_RANGE
    for x in range(0, w, max(1, w // 20)):
        for x0, y0 in ((x, 0), (x, h - 1)):
            if mask[y0 + 1, x0 + 1] != 0:
                continue
            if np.linalg.norm(rgb[y0, x0].astype(np.float32) - bg) > 22:
                continue
            cv2.floodFill(rgb, mask, (x0, y0), (0, 0, 0),
                          loDiff=(tol, tol, tol), upDiff=(tol, tol, tol), flags=flags)
    for y in range(0, h, max(1, h // 20)):
        for x0, y0 in ((0, y), (w - 1, y)):
            if mask[y0 + 1, x0 + 1] != 0:
                continue
            if np.linalg.norm(rgb[y0, x0].astype(np.float32) - bg) > 22:
                continue
            cv2.floodFill(rgb, mask, (x0, y0), (0, 0, 0),
                          loDiff=(tol, tol, tol), upDiff=(tol, tol, tol), flags=flags)
    bg_mask = mask[1:-1, 1:-1] > 0
    alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
    alpha = cv2.GaussianBlur(alpha, (3, 3), 0.55)
    alpha[alpha < 8] = 0
    return alpha

im = Image.open(src).convert("RGBA")
rgba = np.array(im)
alpha = rgba[:, :, 3]
if alpha.min() > 250:
    alpha = background_alpha(rgba[:, :, :3].copy(), 55)
else:
    alpha = alpha.copy()
    alpha[alpha < 8] = 0
ys, xs = np.where(alpha > 0)
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
margin = max(6, int(round(max(x1 - x0 + 1, y1 - y0 + 1) * 0.025)))
x0 = max(0, x0 - margin); y0 = max(0, y0 - margin)
x1 = min(im.width - 1, x1 + margin); y1 = min(im.height - 1, y1 + margin)
rgba[:, :, 3] = alpha
crop = Image.fromarray(rgba[y0:y1 + 1, x0:x1 + 1], "RGBA")
crop.save(out / "nikon-z30.png", optimize=True)
print("saved", crop.size, "alpha", int((alpha > 0).sum()))

# grid
bg = Image.new("RGBA", crop.size, (32, 35, 38, 255))
bg.alpha_composite(crop)
d = ImageDraw.Draw(bg)
for x in range(0, crop.width, 50):
    d.line([(x, 0), (x, crop.height)], fill=(255, 70, 70) if x % 100 == 0 else (80, 80, 80), width=1)
    if x % 100 == 0:
        d.text((x + 2, 2), str(x), fill=(255, 220, 0), font=ImageFont.load_default())
for y in range(0, crop.height, 50):
    d.line([(0, y), (crop.width, y)], fill=(255, 70, 70) if y % 100 == 0 else (80, 80, 80), width=1)
    if y % 100 == 0:
        d.text((2, y + 1), str(y), fill=(255, 220, 0), font=ImageFont.load_default())
bg.convert("RGB").save(out / "grid-nikon-z30.png")
