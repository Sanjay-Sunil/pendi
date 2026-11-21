# Usage: pip install fonttools && python tool/make_logo.py  (run from repo root)
# Builds the Pendi logo SVGs from Geist SemiBold glyph outlines (text converted to paths).
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import DecomposingRecordingPen

f = TTFont("assets/fonts/Geist-600.ttf")
gs = f.getGlyphSet(); cmap = f.getBestCmap(); hmtx = f["hmtx"]
TRACK = -18  # tighter than default, in font units (1000/em)

def path(name):
    p = SVGPathPen(gs); gs[name].draw(p); return p.getCommands()

def bounds(name):
    b = BoundsPen(gs); gs[name].draw(b); return b.bounds

# Locate the tittle of "i": the part of the i that lies above the dotless i.
rec = DecomposingRecordingPen(gs); gs[cmap[ord("i")]].draw(rec)
contours, cur = [], []
for op, args in rec.value:
    cur.append((op, args))
    if op in ("closePath", "endPath"): contours.append(cur); cur = []
def cb(c):
    pts = [pt for _, a in c for pt in a]; xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)
dot = max((cb(c) for c in contours), key=lambda b: b[1])
dot_cx, dot_cy = (dot[0]+dot[2])/2, (dot[1]+dot[3])/2
dot_r = (dot[2]-dot[0])/2 * 1.08

def wordmark(text_color, dot_color):
    x, parts = 0, []
    for ch in "pend":
        g = cmap[ord(ch)]
        parts.append(f'<path transform="translate({x} 0)" d="{path(g)}"/>')
        x += hmtx[g][0] + TRACK
    gi = cmap[ord("ı")]; ix = x
    parts.append(f'<path transform="translate({ix} 0)" d="{path(gi)}"/>')
    x += hmtx[gi][0]
    # pad = side bearings; vertical box from descender of p to top of dot
    top = dot_cy + dot_r; bottom = bounds("p")[1]
    pad = 40
    w = x + 2*pad; h = top - bottom + 2*pad
    body = "".join(parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.0f} {h:.0f}" role="img" aria-label="Pendi">'
            f'<g transform="translate({pad} {top+pad:.0f}) scale(1 -1)" fill="{text_color}">{body}'
            f'<circle cx="{ix+dot_cx:.1f}" cy="{dot_cy:.1f}" r="{dot_r:.1f}" fill="{dot_color}"/></g></svg>')

def icon(bg, fg, accent, size=1024, radius=230, fill=0.62):
    # Monogram: a lowercase p with the amber i-dot at its shoulder, centred as one shape.
    g = cmap[ord("p")]; xmin, ymin, xmax, ymax = bounds(g)
    dcx = xmax + dot_r * 0.35; dcy = ymax + dot_r * 1.25
    bx0, by0 = xmin, ymin
    bx1, by1 = max(xmax, dcx + dot_r), dcy + dot_r
    s = size * fill / max(bx1 - bx0, by1 - by0)
    tx = size / 2 - (bx0 + bx1) / 2 * s
    ty = size / 2 + (by0 + by1) / 2 * s  # y is flipped
    rect = f'<rect width="{size}" height="{size}" rx="{radius}" fill="{bg}"/>' if bg != "none" else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" role="img" aria-label="Pendi">{rect}'
            f'<g transform="translate({tx:.1f} {ty:.1f}) scale({s:.4f} {-s:.4f})">'
            f'<path fill="{fg}" d="{path(g)}"/><circle cx="{dcx:.1f}" cy="{dcy:.1f}" r="{dot_r:.1f}" fill="{accent}"/></g></svg>')

out = "assets/brand/"
open(out+"pendi-wordmark-dark.svg","w").write(wordmark("#EDE7DF", "#F59E0B"))
open(out+"pendi-wordmark-light.svg","w").write(wordmark("#2A2118", "#B45309"))
open(out+"pendi-icon.svg","w").write(icon("#0C0A09", "#EDE7DF", "#F59E0B"))
open(out+"pendi-icon-light.svg","w").write(icon("#F4EBE0", "#2A2118", "#B45309"))
# Android adaptive-icon foreground: transparent, glyph kept inside the 66% safe zone.
open(out+"pendi-icon-foreground.svg","w").write(icon("none", "#EDE7DF", "#F59E0B", radius=0, fill=0.42))
print("ok", round(dot_r,1))
