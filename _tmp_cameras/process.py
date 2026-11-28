from PIL import Image, ImageDraw, ImageFont, ImageOps
import numpy as np
import cv2
from pathlib import Path

src = Path(r"D:\ai_img\新建文件夹 (2)\背面展示")
out = Path(r"D:\ai\GearLab\_tmp_cameras\processed")
out.mkdir(parents=True, exist_ok=True)

# Canonical order + metadata. ids are filenames used in the app.
items = [
    ("canon-eos-6d", "canon-eos-6d-back.png", "CANON", "EOS 6D", "Canon EOS 6D"),
    ("canon-eos-r5-mark-ii", "EOS R5 Mark II.jpg", "CANON", "EOS R5 Mark II", "Canon EOS R5 Mark II"),
    ("canon-eos-r6-v", "EOS R6 V.jpg", "CANON", "EOS R6 V", "Canon EOS R6 V"),
    ("canon-eos-r8-mark-ii", "EOS R8 Mark II.jpg", "CANON", "EOS R8 Mark II", "Canon EOS R8 Mark II"),
    ("canon-eos-r5", "佳能r5.jpg", "CANON", "EOS R5", "Canon EOS R5"),
    ("canon-eos-r6-mark-iii", "佳能r6iii.jpg", "CANON", "EOS R6 Mark III", "Canon EOS R6 Mark III"),
    ("canon-eos-r8", "佳能r8.jpg", "CANON", "EOS R8", "Canon EOS R8"),
    ("fujifilm-gfx100-ii", "Fujifilm GFX100 II.webp", "FUJIFILM", "GFX100 II", "Fujifilm GFX100 II"),
    ("fujifilm-gfx100rf", "Fujifilm GFX100RF.webp", "FUJIFILM", "GFX100RF", "Fujifilm GFX100RF"),
    ("fujifilm-x-e5", "Fujifilm X-E5.webp", "FUJIFILM", "X-E5", "Fujifilm X-E5"),
    ("fujifilm-x-h2", "Fujifilm X-H2.webp", "FUJIFILM", "X-H2", "Fujifilm X-H2"),
    ("fujifilm-x-h2s", "Fujifilm X-H2S.webp", "FUJIFILM", "X-H2S", "Fujifilm X-H2S"),
    ("fujifilm-x-s10", "Fujifilm X-S10.webp", "FUJIFILM", "X-S10", "Fujifilm X-S10"),
    ("fujifilm-x-s20", "Fujifilm X-S20.webp", "FUJIFILM", "X-S20", "Fujifilm X-S20"),
    ("fujifilm-x-t30-iii", "Fujifilm X-T30 III.webp", "FUJIFILM", "X-T30 III", "Fujifilm X-T30 III"),
    ("fujifilm-x-t5", "Fujifilm X-T5.webp", "FUJIFILM", "X-T5", "Fujifilm X-T5"),
    ("fujifilm-x-t50", "Fujifilm X-T50.webp", "FUJIFILM", "X-T50", "Fujifilm X-T50"),
    ("nikon-fe", "nikon-fe-back.png", "NIKON", "FE", "Nikon FE"),
    ("nikon-z5ii", "z5iic.png", "NIKON", "Z5II", "Nikon Z5II"),
    ("nikon-z50ii", "尼康z50ii.png", "NIKON", "Z50II", "Nikon Z50II"),
    ("nikon-zf", "尼康zf.png", "NIKON", "Zf", "Nikon Zf"),
    ("nikon-zfc", "尼康zfc.png", "NIKON", "Zfc", "Nikon Zfc"),
    ("lumix-s5ii", "panasonic-lumix-s5ii-back.png", "LUMIX", "S5II", "Lumix S5II"),
    ("sony-a7-iv", "sony-a7m4-back.png", "SONY", "α7 IV", "Sony α7 IV"),
    ("sony-zv-e10", "sony-zv-e10-back.png", "SONY", "ZV-E10", "Sony ZV-E10"),
]

def background_alpha(rgb, tol=26):
    h, w = rgb.shape[:2]
    # Estimate the paper color from the outer border. Only light border pixels
    # become seeds, so a camera that touches an edge is never eaten.
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]], axis=0)
    bg = np.median(border, axis=0)
    seed_ok = np.linalg.norm(border.astype(np.float32) - bg, axis=1) < 18
    if seed_ok.mean() < 0.25:
        bg = np.array([255.0, 255.0, 255.0])
    mask = np.zeros((h + 2, w + 2), np.uint8)
    flags = 4 | (255 << 8) | cv2.FLOODFILL_MASK_ONLY | cv2.FLOODFILL_FIXED_RANGE
    seeds = []
    for x in range(0, w, max(1, w // 20)):
        seeds.extend([(x, 0), (x, h - 1)])
    for y in range(0, h, max(1, h // 20)):
        seeds.extend([(0, y), (w - 1, y)])
    for x, y in seeds:
        if mask[y + 1, x + 1] != 0:
            continue
        if np.linalg.norm(rgb[y, x].astype(np.float32) - bg) > 22:
            continue
        cv2.floodFill(rgb, mask, (x, y), (0, 0, 0),
                      loDiff=(tol, tol, tol), upDiff=(tol, tol, tol),
                      flags=flags)
    bg_mask = mask[1:-1, 1:-1] > 0
    alpha = np.where(bg_mask, 0, 255).astype(np.uint8)
    # Slight feather for anti-aliased product edges.
    alpha = cv2.GaussianBlur(alpha, (3, 3), 0.55)
    alpha[alpha < 8] = 0
    return alpha

for cid, filename, brand, model, display in items:
    p = src / filename
    im = Image.open(p).convert("RGBA")
    rgba = np.array(im)
    alpha = rgba[:, :, 3]
    if alpha.min() > 250:
        alpha = background_alpha(rgba[:, :, :3].copy(), 55)
    else:
        # Preserve the supplied transparency, but clean faint fringes.
        alpha = alpha.copy()
        alpha[alpha < 8] = 0
    ys, xs = np.where(alpha > 0)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    margin = max(6, int(round(max(x1 - x0 + 1, y1 - y0 + 1) * 0.025)))
    x0 = max(0, x0 - margin); y0 = max(0, y0 - margin)
    x1 = min(im.width - 1, x1 + margin); y1 = min(im.height - 1, y1 + margin)
    rgba[:, :, 3] = alpha
    crop = Image.fromarray(rgba[y0:y1 + 1, x0:x1 + 1], "RGBA")
    crop.save(out / f"{cid}.png", optimize=True)
    print(f"{cid}\t{crop.width}x{crop.height}\taspect={crop.width/crop.height:.4f}\tfrom={filename}")

# Dark contact sheet with 10% grid to aid screen calibration.
thumbs = []
for cid, *_ in items:
    p = out / f"{cid}.png"
    im = Image.open(p).convert("RGBA")
    bg = Image.new("RGBA", im.size, (32, 35, 38, 255))
    bg.alpha_composite(im)
    sheet = bg.convert("RGB")
    d = ImageDraw.Draw(sheet)
    for f in (0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9):
        d.line([(int(sheet.width * f), 0), (int(sheet.width * f), sheet.height)], fill=(0, 140, 255), width=max(1, sheet.width // 700))
        d.line([(0, int(sheet.height * f)), (sheet.width, int(sheet.height * f))], fill=(0, 140, 255), width=max(1, sheet.width // 700))
    sheet.thumbnail((480, 360), Image.LANCZOS)
    thumbs.append((cid, sheet.copy()))

cols = 4
tw, th = 500, 400
rows = (len(thumbs) + cols - 1) // cols
cs = Image.new("RGB", (cols * tw, rows * th), (20, 22, 24))
d = ImageDraw.Draw(cs)
try:
    font = ImageFont.truetype("arial.ttf", 17)
except Exception:
    font = ImageFont.load_default()
for i, (cid, im) in enumerate(thumbs):
    x = (i % cols) * tw + (tw - im.width) // 2
    y = (i // cols) * th + 8
    cs.paste(im, (x, y))
    d.text(((i % cols) * tw + 10, (i // cols) * th + th - 26), cid, fill=(255, 255, 255), font=font)
cs.save(out / "contact_processed.png")
print(out / "contact_processed.png")
