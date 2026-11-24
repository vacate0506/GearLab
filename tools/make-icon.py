from PIL import Image, ImageDraw
import math

S = 1024
img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
# rounded square with subtle vertical gradient
grad = Image.new('RGB', (1, S))
top = (255, 112, 66)
bot = (236, 67, 27)
for y in range(S):
    t = y / (S - 1)
    grad.putpixel((0, y), (int(top[0] + (bot[0] - top[0]) * t),
                           int(top[1] + (bot[1] - top[1]) * t),
                           int(top[2] + (bot[2] - top[2]) * t)))
grad = grad.resize((S, S))
mask = Image.new('L', (S, S), 0)
md = ImageDraw.Draw(mask)
md.rounded_rectangle((24, 24, S - 24, S - 24), radius=218, fill=255)
img.paste(grad, (0, 0), mask)

d = ImageDraw.Draw(img)
cx, cy = S / 2, S / 2
R = 300
# dark ring / blades
blade_color = (20, 16, 14, 255)
line_w = 44
for i in range(6):
    a0 = math.radians(90 + i * 60 + 11)
    a1 = math.radians(90 + i * 60 + 57)
    p0 = (cx + math.cos(a0) * R, cy + math.sin(a0) * R)
    p1 = (cx + math.cos(a1) * R, cy + math.sin(a1) * R)
    d.line([p0, p1], fill=blade_color, width=line_w)
    # inner straight blade edge
    ir = 108
    q0 = (cx + math.cos(a0) * ir, cy + math.sin(a0) * ir)
    q1 = (cx + math.cos(a1) * ir, cy + math.sin(a1) * ir)
    d.line([q0, q1], fill=blade_color, width=line_w)

# center lens
d.ellipse((cx - 165, cy - 165, cx + 165, cy + 165), fill=(20, 16, 14, 255))
d.ellipse((cx - 126, cy - 126, cx + 126, cy + 126), fill=(255, 246, 235, 255))
d.ellipse((cx - 72, cy - 72, cx + 72, cy + 72), fill=(18, 14, 12, 255))
d.ellipse((cx - 33, cy - 33, cx + 33, cy + 33), fill=(255, 92, 46, 255))
# small specular
d.ellipse((cx - 118, cy - 102, cx - 74, cy - 58), fill=(255, 255, 255, 105))

img.save(r'D:\ai\GearLab\assets\app-512.png')
sizes = [256, 128, 64, 48, 32, 24, 16]
img.save(r'D:\ai\GearLab\assets\app.ico', sizes=[(s, s) for s in sizes])
print('icon saved')
