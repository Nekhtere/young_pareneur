"""Ekstrak logo dari index.html (.lg) lalu gabungkan jadi satu strip JPG.

Hasil: assets/logo-strip.jpg (~52 KB, lebih ringan dari PNG ~163 KB).
Cara pakai: upload gambar ini ke host publik (mis. Supabase Storage bucket public),
lalu isi Script Property LOGO_URL di Apps Script dengan URL https gambar tersebut.
"""
import base64
import io
import re
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
html = (root / "index.html").read_text(encoding="utf-8")

start = html.index('<div class="lg">')
end = html.index('</section>', start)
section = html[start:end]

encoded = re.findall(r'src="data:image/jpeg;base64,([^"]+)"', section)
if not encoded:
    raise SystemExit("Tidak ada logo base64 yang ditemukan di .lg")

imgs = []
for item in encoded:
    imgs.append(Image.open(io.BytesIO(base64.b64decode(item))).convert("RGBA"))

print("Logo ditemukan:", len(imgs), [im.size for im in imgs])

height = 130
padding = 24
gap = 18
scaled = []
for im in imgs:
    w = max(1, round(im.width * height / im.height))
    scaled.append(im.resize((w, height), Image.LANCZOS))

width = padding * 2 + sum(im.width for im in scaled) + gap * (len(scaled) - 1)
strip = Image.new("RGBA", (width, height + padding * 2), (255, 255, 255, 255))
x = padding
for im in scaled:
    strip.alpha_composite(im, (x, padding))
    x += im.width + gap

out = root / "assets" / "logo-strip.jpg"
out.parent.mkdir(parents=True, exist_ok=True)
strip.convert("RGB").save(out, "JPEG", quality=92, optimize=True)
print("Tersimpan:", out, strip.size, round(out.stat().st_size / 1024, 1), "KB")
