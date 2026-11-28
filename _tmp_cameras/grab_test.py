import cv2, numpy as np
from PIL import Image
from pathlib import Path

root = Path("D:/ai_img")
files = []
for p in root.rglob("*"):
    if p.is_file() and p.name in ("Fujifilm X-S10.webp", "Fujifilm X-T50.webp"):
        files.append(p)
print(files)
for p in files:
    im = cv2.imdecode(np.fromfile(str(p), dtype=np.uint8), cv2.IMREAD_COLOR)
    h, w = im.shape[:2]
    mask = np.full((h, w), 2, np.uint8)
    m = max(8, int(min(w, h) * 0.02))
    mask[m:h-m, m:w-m] = 3
    bg = np.zeros((1, 65), np.float64)
    fg = np.zeros((1, 65), np.float64)
    cv2.grabCut(im, mask, None, bg, fg, 5, cv2.GC_INIT_WITH_MASK)
    a = np.where((mask == 0) | (mask == 2), 0, 255).astype(np.uint8)
    ys, xs = np.where(a > 0)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    crop = Image.fromarray(cv2.cvtColor(im, cv2.COLOR_BGR2RGB)).convert("RGBA")
    crop.putalpha(Image.fromarray(a))
    crop = crop.crop(box)
    out = Path(r"D:\ai_GearLab_tmp") / (p.stem + "-grab.png")
    out.parent.mkdir(parents=True, exist_ok=True)
    crop.save(out)
    print(p.name, crop.size, out)
