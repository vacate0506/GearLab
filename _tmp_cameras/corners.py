from PIL import Image
from pathlib import Path
src = Path(r"D:\ai_img\新建文件夹 (2)\背面展示")
for p in sorted(src.iterdir()):
    im = Image.open(p).convert("RGB")
    w,h = im.size
    corners = [im.getpixel(xy) for xy in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]]
    # border average / variance
    px = list(im.getdata())
    print(p.name.encode('unicode_escape').decode(), im.size, corners)
