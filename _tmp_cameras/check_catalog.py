import re
from pathlib import Path

s = Path(r"D:\ai\GearLab\flutter_app\lib\catalog.dart").read_text(encoding="utf-8")
ids = re.findall(r"id: '([^']+)'", s)
assets = re.findall(r"asset: '([^']+)'", s)
root = Path(r"D:\ai\GearLab\flutter_app")
missing = [a for a in assets if not (root / a).exists()]
print("ids", len(ids), "unique", len(set(ids)), "assets", len(assets), "missing", missing)
