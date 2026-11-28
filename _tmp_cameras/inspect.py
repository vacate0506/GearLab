from PIL import Image, ImageDraw, ImageFont, ImageOps
from pathlib import Path

src = Path(r"D:\ai_img\新建文件夹 (2)\背面展示")
out = Path(r"D:\ai\GearLab\_tmp_cameras")
out.mkdir(exist_ok=True)
files = sorted([p for p in src.iterdir() if p.is_file()])
print("count", len(files))
for p in files:
    im = Image.open(p)
    alpha = im.convert("RGBA").getchannel("A")
    a = alpha.getextrema()
    n_trans = sum(1 for v in alpha.getdata() if v < 250)
    print(f"{p.name}\t{im.size[0]}x{im.size[1]}\t{im.mode}\talpha={a}\ttransparent={n_trans/ (im.size[0]*im.size[1]):.3f}")

# contact sheet
thumb_w, thumb_h = 360, 260
cols = 5
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * thumb_w, rows * (thumb_h + 34)), "white")
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arial.ttf", 16)
except Exception:
    font = ImageFont.load_default()
for i, p in enumerate(files):
    im = Image.open(p).convert("RGBA")
    # checker-ish light gray background so transparency is visible
    bg = Image.new("RGBA", im.size, (235, 235, 235, 255))
    bg.alpha_composite(im)
    im = bg.convert("RGB")
    im.thumbnail((thumb_w - 20, thumb_h - 10), Image.LANCZOS)
    x = (i % cols) * thumb_w + (thumb_w - im.width) // 2
    y = (i // cols) * (thumb_h + 34) + 5
    sheet.paste(im, (x, y))
    d.rectangle([(i % cols) * thumb_w, (i // cols) * (thumb_h + 34) + thumb_h, (i % cols + 1) * thumb_w, (i // cols + 1) * (thumb_h + 34)], fill="white")
    d.text(((i % cols) * thumb_w + 8, (i // cols) * (thumb_h + 34) + thumb_h + 6), p.name, fill="black", font=font)
sheet.save(out / "contact.png")
print(out / "contact.png")
