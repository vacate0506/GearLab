from PIL import Image
import numpy as np
import json
from pathlib import Path

root = Path(r"D:\ai\GearLab\_tmp_cameras")
out = root / "processed"
cal_path = root / "calibration.json"
cal = json.loads(cal_path.read_text(encoding="utf-8"))

by_id = {t["id"]: t for t in cal["templates"]}
for p in sorted(out.glob("*.png")):
    if p.name.startswith(("grid-", "contact", "candidates")):
        continue
    cid = p.stem
    im = np.array(Image.open(p).convert("RGBA"))
    a = im[:, :, 3]
    g = im[:, :, :3].mean(2)
    h, w = a.shape
    counts = ((g < 80) & (a > 128)).sum(1)
    rows = np.where(counts > max(8, w * 0.02))[0]
    if not len(rows):
        continue
    last_dark = int(rows.max())
    ys = np.where(a.max(1) > 0)[0]
    alpha_bottom = int(ys.max())
    shadow = int(((a > 0) & (np.arange(h)[:, None] > last_dark + 1)).sum())
    if alpha_bottom > last_dark + 4 and shadow > 200:
        cut = min(h - 1, last_dark + 2)
        im = im[: cut + 1].copy()
        im[:, :, 3] = np.where(np.arange(cut + 1)[:, None] > last_dark, 0, im[:, :, 3]).astype(np.uint8)
        Image.fromarray(im, "RGBA").save(p, optimize=True)
        print(f"cropped {cid}: {w}x{h} -> {w}x{cut + 1}, removed {shadow} shadow px")
        if cid in by_id:
            by_id[cid]["height"] = cut + 1

# Correct the X-S10 screen after the grid check; its lower edge was inside the bezel.
if "fujifilm-x-s10" in by_id:
    by_id["fujifilm-x-s10"]["screen"] = [164, 305, 482, 278]

# Add Z30 to the canonical calibration.
z30 = {
    "id": "nikon-z30",
    "file": "尼康z30.png",
    "brand": "NIKON",
    "model": "Z30",
    "display": "Nikon Z30",
    "width": 678,
    "height": 400,
    "screen": [55, 105, 405, 262],
}
if "nikon-z30" not in by_id:
    cal["templates"].append(z30)
    by_id["nikon-z30"] = z30

cal["templates"] = [by_id[t["id"]] for t in cal["templates"]]
cal_path.write_text(json.dumps(cal, ensure_ascii=False, indent=2), encoding="utf-8")
print("updated", cal_path)
