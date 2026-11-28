from PIL import Image
import numpy as np
import cv2
from pathlib import Path

src = Path(r"D:\ai_img\新建文件夹 (2)\背面展示")
out = Path(r"D:\ai\GearLab\_tmp_cameras\tol50")
out.mkdir(exist_ok=True)
names = ["canon-eos-6d-back.png", "Fujifilm X-T50.webp", "Fujifilm GFX100 II.webp", "EOS R5 Mark II.jpg", "nikon-fe-back.png", "z5iic.png"]

def alpha_for(rgb, tol):
    h, w = rgb.shape[:2]
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]], axis=0)
    bg = np.median(border, axis=0)
    mask = np.zeros((h + 2, w + 2), np.uint8)
    flags = 4 | (255 << 8) | cv2.FLOODFILL_MASK_ONLY | cv2.FLOODFILL_FIXED_RANGE
    seeds = []
    for x in range(0, w, max(1, w // 20)):
        seeds += [(x, 0), (x, h - 1)]
    for y in range(0, h, max(1, h // 20)):
        seeds += [(0, y), (w - 1, y)]
    for x, y in seeds:
        if mask[y + 1, x + 1] != 0:
            continue
        if np.linalg.norm(rgb[y, x].astype(np.float32) - bg) > 22:
            continue
        cv2.floodFill(rgb, mask, (x, y), (0, 0, 0),
                      loDiff=(tol, tol, tol), upDiff=(tol, tol, tol), flags=flags)
    a = np.where(mask[1:-1, 1:-1] > 0, 0, 255).astype(np.uint8)
    a = cv2.GaussianBlur(a, (3, 3), 0.55)
    a[a < 8] = 0
    return a

for name in names:
    im = Image.open(src / name).convert("RGBA")
    rgba = np.array(im)
    a = alpha_for(rgba[:, :, :3].copy(), 55)
    ys, xs = np.where(a > 0)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    margin = max(6, int(max(x1-x0+1, y1-y0+1) * 0.025))
    x0=max(0,x0-margin); y0=max(0,y0-margin); x1=min(im.width-1,x1+margin); y1=min(im.height-1,y1+margin)
    rgba[:,:,3]=a
    crop=Image.fromarray(rgba[y0:y1+1,x0:x1+1], "RGBA")
    crop.save(out / (Path(name).stem + ".png"))
    print(name, crop.size)
