from PIL import Image
import numpy as np
from pathlib import Path
out = Path(r"D:\ai\GearLab\_tmp_cameras\processed")
for name in ["fujifilm-x-s10", "fujifilm-x-h2", "fujifilm-gfx100rf", "nikon-z5ii", "sony-a7-iv"]:
    im = Image.open(out / f"{name}.png").convert("RGBA")
    a = np.array(im)
    rgb = a[:, :, :3].astype(int)
    alpha = a[:, :, 3]
    lum = rgb.mean(axis=2)
    mask = (alpha > 20) & (lum > 190)
    ys, xs = np.where(mask)
    print(name, im.size, "bright opaque pixels", len(xs))
    if len(xs):
        # show most common colors (quantized)
        colors = (rgb[ys, xs] // 8 * 8)
        u, c = np.unique(colors, axis=0, return_counts=True)
        idx = np.argsort(c)[-8:][::-1]
        print("  top", [(u[i].tolist(), int(c[i])) for i in idx])
        print("  bbox", xs.min(), xs.max(), ys.min(), ys.max())
