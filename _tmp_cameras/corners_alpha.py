from PIL import Image
from pathlib import Path
src = Path(r"D:\ai_img\新建文件夹 (2)\背面展示")
for p in sorted(src.iterdir()):
    im = Image.open(p).convert("RGBA")
    w,h = im.size
    corners = [im.getpixel(xy) for xy in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]]
    if corners[0][3] != 255:
        print(p.name.encode('unicode_escape').decode(), im.size, corners)
