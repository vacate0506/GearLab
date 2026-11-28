import json
from pathlib import Path

cal = json.loads(Path(r"D:\ai\GearLab\_tmp_cameras\calibration.json").read_text(encoding="utf-8"))
templates = [t for t in cal["templates"] if t["id"] != "nikon-z5ii"]
order = ["CANON", "FUJIFILM", "NIKON", "SONY", "LUMIX"]
templates.sort(key=lambda t: (order.index(t["brand"]) if t["brand"] in order else 99, t["model"]))
lines = []
last = None
for t in templates:
    if t["brand"] != last:
        lines.append(f"    // {t['brand']}")
        last = t["brand"]
    w, h = t["width"], t["height"]
    x, y, sw, sh = t["screen"]
    lines.append("    CameraTemplate(")
    lines.append(f"      id: '{t['id']}',")
    lines.append(f"      asset: 'assets/cameras/{t['id']}.png',")
    lines.append(f"      brand: '{t['brand']}',")
    model = t["model"].replace("'", "\\'")
    lines.append(f"      model: '{model}',")
    display = t["display"].replace("'", "\\'")
    lines.append(f"      displayName: '{display}',")
    lines.append(f"      aspect: {w} / {h},")
    lines.append(f"      screen: Rect.fromLTWH({x / w:.6f}, {y / h:.6f}, {sw / w:.6f}, {sh / h:.6f}),")
    lines.append("    ),")
text = "\n".join(lines)
Path(r"D:\ai\GearLab\_tmp_cameras\catalog_entries.txt").write_text(text, encoding="utf-8")
print(len(templates))
for t in templates:
    if t["id"] in {"fujifilm-gfx100rf", "fujifilm-x-e5", "fujifilm-x-h2", "fujifilm-x-h2s", "fujifilm-x-s10", "fujifilm-x-t30-iii", "fujifilm-x-t5", "nikon-z30"}:
        print(t["id"], t["width"], t["height"], t["screen"])
