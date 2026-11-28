import re
from pathlib import Path

path = Path(r"D:\ai\GearLab\flutter_app\lib\catalog.dart")
text = path.read_text(encoding="utf-8")
open_marker = "static const List<CameraTemplate> all = <CameraTemplate>["
start = text.index(open_marker) + len(open_marker)
end = text.index("\n  ];", start)
body = text[start:end]
body = "\n".join(line for line in body.splitlines() if not line.strip().startswith("//"))
blocks = re.findall(r"    CameraTemplate\(.*?\n    \),", body, re.S)
assert len(blocks) == 36, len(blocks)

by_brand = {}
for block in blocks:
    brand = re.search(r"brand: '([^']+)'", block).group(1)
    by_brand.setdefault(brand, []).append(block)

z5c = """    CameraTemplate(
      id: 'nikon-z5ii-c',
      asset: 'assets/cameras/nikon-z5ii-c.png',
      brand: 'NIKON',
      model: 'Z5II C',
      displayName: 'Nikon Z5II C',
      aspect: 686 / 410,
      screen: Rect.fromLTWH(85 / 686, 122 / 410, 385 / 686, 258 / 410),
    ),"""
nikon = by_brand["NIKON"]
idx = next(i for i, b in enumerate(nikon) if "id: 'nikon-z5ii'" in b)
nikon.insert(idx + 1, z5c)

order = ["RICOH", "FUJIFILM", "NIKON", "SONY", "LUMIX", "CANON"]
out = []
for brand in order:
    out.append(f"    // {brand}")
    out.extend(by_brand[brand])
    out.append("")
new_body = "\n".join(out).rstrip() + "\n"
new_text = text[:start] + "\n" + new_body + text[end + 1:]
path.write_text(new_text, encoding="utf-8")
print("blocks", sum(len(by_brand[b]) for b in order), "brands", {b: len(by_brand[b]) for b in order})
