"""
Apresentacao_Instrutor.pptx v2
- Circular instructor photo
- Tech logos via iconify API (SVG -> PDF -> PNG via svglib + pymupdf)
- Ada template palette
"""
import io, os, requests, fitz
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPDF
from PIL import Image, ImageDraw, ImageFont
from pptx import Presentation
from pptx.util import Emu, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# ── Colors ────────────────────────────────────────────────────────────────────
C_BG    = RGBColor(0x18, 0x1C, 0x23)
C_WHITE = RGBColor(0xFF, 0xFD, 0xF8)
C_BLUE  = RGBColor(0x23, 0x71, 0xFF)
C_GREEN = RGBColor(0xA6, 0xF7, 0x50)
C_DGRAY = RGBColor(0x2A, 0x2F, 0x3A)
C_DARK2 = RGBColor(0x1E, 0x23, 0x2E)

SW, SH = 9144000, 5143500

SLIDES_DIR = os.path.dirname(os.path.abspath(__file__))
LOGOS_DIR  = os.path.join(SLIDES_DIR, "logos")
os.makedirs(LOGOS_DIR, exist_ok=True)

ICONIFY = "https://api.iconify.design/{icon}.svg?width=128&height=128"

TECH_ICONS = {
    "Windows":    "logos:microsoft-windows",
    "Linux":      "logos:linux-tux",
    "Azure":      "logos:microsoft-azure",
    ".NET":       "logos:dotnet",
    "SQL Server": "devicon:microsoftsqlserver",
    "MongoDB":    "logos:mongodb-icon",
    "Selenium":   "logos:selenium",
    "Playwright": "logos:playwright",
    "n8n":        "simple-icons:n8n",
    "Postman":    "logos:postman-icon",
    "Angular":    "logos:angular-icon",
    "Vue.js":     "logos:vue",
    "React":      "logos:react",
    "Python":     "logos:python",
    "Docker":     "logos:docker-icon",
    "Kubernetes": "logos:kubernetes",
    "GitHub":     "logos:github-icon",
}

CERT_ICONS = {
    "AZ-900": "logos:microsoft-azure",
    "PSM I":  "simple-icons:scrumalliance",
}


def svg_to_pil(svg_bytes, size=128):
    """SVG bytes -> PIL RGBA Image via svglib + reportlab + pymupdf."""
    drawing = svg2rlg(io.BytesIO(svg_bytes))
    if drawing is None:
        return None
    pdf_buf = io.BytesIO()
    renderPDF.drawToFile(drawing, pdf_buf)
    pdf_buf.seek(0)
    doc = fitz.open(stream=pdf_buf, filetype="pdf")
    page = doc[0]
    scale = size / max(page.rect.width, page.rect.height)
    mat = fitz.Matrix(scale * 4, scale * 4)
    pix = page.get_pixmap(matrix=mat, alpha=True)
    img = Image.frombytes("RGBA", [pix.width, pix.height], pix.samples)
    return img.resize((size, size), Image.LANCZOS)


def make_placeholder(name, size=128, bg=(35, 113, 255)):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([4, 4, size - 5, size - 5], fill=(*bg, 210))
    initials = "".join(w[0].upper() for w in name.split()[:2])
    try:
        font = ImageFont.load_default(size=size // 3)
        bbox = draw.textbbox((0, 0), initials, font=font)
        tw = bbox[2] - bbox[0]; th = bbox[3] - bbox[1]
        draw.text(((size - tw) / 2, (size - th) / 2 - 4), initials,
                  fill=(255, 255, 255, 240), font=font)
    except Exception:
        pass
    return img


def download_logo(name, icon_id, size=128):
    safe = name.replace("/", "_").replace(".", "_").replace(" ", "_")
    path = os.path.join(LOGOS_DIR, f"{safe}.png")
    if os.path.exists(path):
        return path
    try:
        url = ICONIFY.format(icon=icon_id)
        r = requests.get(url, timeout=15)
        r.raise_for_status()
        img = svg_to_pil(r.content, size)
        if img:
            img.save(path)
            print(f"  OK  {name}")
            return path
    except Exception as e:
        print(f"  FAIL {name}: {e}")
    # Save placeholder
    ph = make_placeholder(name, size)
    ph.save(path)
    print(f"  PH  {name} (placeholder)")
    return path


def make_circular_photo(img_path, size=400):
    img = Image.open(img_path).convert("RGBA")
    w, h = img.size
    m = min(w, h)
    img = img.crop(((w - m) // 2, (h - m) // 2, (w + m) // 2, (h + m) // 2))
    img = img.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(img, mask=mask)
    return result


def add_pil_image(slide, pil_img, x, y, w, h):
    buf = io.BytesIO()
    pil_img.save(buf, format="PNG")
    buf.seek(0)
    slide.shapes.add_picture(buf, Emu(x), Emu(y), Emu(w), Emu(h))


def shape(slide, t, x, y, w, h, fill=None, line=None):
    s = slide.shapes.add_shape(t, Emu(x), Emu(y), Emu(w), Emu(h))
    if fill: s.fill.solid(); s.fill.fore_color.rgb = fill
    else:    s.fill.background()
    if line: s.line.color.rgb = line
    else:    s.line.fill.background()
    return s

def rect(slide, x, y, w, h, fill=None, line=None):
    return shape(slide, 1, x, y, w, h, fill, line)

def rrect(slide, x, y, w, h, fill=None, line=None, radius=5):
    s = shape(slide, 5, x, y, w, h, fill, line)
    from pptx.oxml.ns import qn
    pg = s.element.find('.//' + qn('a:prstGeom'))
    if pg is not None:
        av = pg.find(qn('a:avLst'))
        if av:
            for gd in av.findall(qn('a:gd')):
                if gd.get('name') == 'adj':
                    gd.set('fmla', f'val {radius * 1000}')
    return s

def oval(slide, x, y, w, h, fill=None, line=None):
    return shape(slide, 9, x, y, w, h, fill, line)

def tb(slide, x, y, w, h, text, font="Ubuntu", sz=12,
       bold=False, color=None, align=PP_ALIGN.LEFT, wrap=True):
    box = slide.shapes.add_textbox(Emu(x), Emu(y), Emu(w), Emu(h))
    tf = box.text_frame; tf.word_wrap = wrap
    p = tf.paragraphs[0]; p.alignment = align
    run = p.add_run(); run.text = text
    run.font.name = font; run.font.size = Pt(sz); run.font.bold = bold
    if color: run.font.color.rgb = color
    return box


# ── Download logos ────────────────────────────────────────────────────────────
print("Downloading logos...")
logo_paths = {}
for name, icon in {**TECH_ICONS, **CERT_ICONS}.items():
    logo_paths[name] = download_logo(name, icon)
print()

# ── Build slide ───────────────────────────────────────────────────────────────
prs = Presentation()
prs.slide_width  = Emu(SW)
prs.slide_height = Emu(SH)
slide = prs.slides.add_slide(prs.slide_layouts[6])  # blank

# BG
rect(slide, 0, 0, SW, SH, fill=C_BG)
# Left accent bar
rect(slide, 0, 0, 55000, SH, fill=C_GREEN)

# ── HEADER ────────────────────────────────────────────────────────────────────
HEADER_H = 1000000
rect(slide, 55000, 0, SW - 55000, HEADER_H, fill=C_DGRAY)

# Circular photo
PHOTO_EMU = 860000
PHOTO_PIX = 420
photo_src  = os.path.join(SLIDES_DIR, "instrutor_photo.jpg")
PHOTO_X    = 110000
PHOTO_Y    = (HEADER_H - PHOTO_EMU) // 2

if os.path.exists(photo_src):
    photo = make_circular_photo(photo_src, PHOTO_PIX)
    add_pil_image(slide, photo, PHOTO_X, PHOTO_Y, PHOTO_EMU, PHOTO_EMU)

# Green ring border (drawn behind — but pptx stacks in order, so draw first)
RING = 35000
oval(slide, PHOTO_X - RING, PHOTO_Y - RING,
     PHOTO_EMU + 2 * RING, PHOTO_EMU + 2 * RING,
     fill=None, line=C_GREEN)

TEXT_X = PHOTO_X + PHOTO_EMU + 130000
tb(slide, TEXT_X, 100000, 3600000, 400000,
   "Elton Benedito", sz=30, bold=True, color=C_WHITE)
tb(slide, TEXT_X, 490000, 4200000, 260000,
   "Instrutor  •  Desenvolvedor  •  Arquiteto Cloud",
   sz=11, color=C_GREEN)

# LinkedIn pill
LW, LH = 2400000, 185000
rrect(slide, TEXT_X, 730000, LW, LH, fill=C_BLUE, radius=50)
tb(slide, TEXT_X + 90000, 730000 + 28000, LW - 180000, LH - 56000,
   "linkedin.com/in/ejbenedito/", sz=8, color=C_WHITE)

# Course top-right
tb(slide, SW - 2600000, 80000, 2500000, 230000,
   "Orquestração Kubernetes", sz=14, bold=True, color=C_GREEN, align=PP_ALIGN.RIGHT)
tb(slide, SW - 2600000, 290000, 2500000, 190000,
   "Apresentação do Instrutor", sz=9, color=C_WHITE, align=PP_ALIGN.RIGHT)
tb(slide, SW - 750000, 780000, 690000, 210000,
   "ada.", font="Ubuntu", sz=16, bold=True, color=C_GREEN, align=PP_ALIGN.RIGHT)

# Decorative dots
for dx, dy, dr in [(SW - 320000, 180000, 55000),
                   (SW - 190000, 340000, 35000),
                   (SW - 430000, 130000, 28000)]:
    oval(slide, dx - dr, dy - dr, 2 * dr, 2 * dr, fill=C_GREEN)

# ── CONTENT ───────────────────────────────────────────────────────────────────
CY    = HEADER_H + 90000
CH    = SH - CY - 70000
MGN   = 75000
CGAP  = 65000
TOTW  = SW - 55000 - 2 * MGN

C1W = int(TOTW * 0.52)
C2W = int(TOTW * 0.23)
C3W = TOTW - C1W - C2W - 2 * CGAP
C1X = 55000 + MGN
C2X = C1X + C1W + CGAP
C3X = C2X + C2W + CGAP

HDR_H = 265000
PAD   = 75000

def section_hdr(x, y, w, title):
    rrect(slide, x, y, w, HDR_H, fill=C_BLUE, radius=3)
    tb(slide, x + 80000, y + 35000, w - 160000, HDR_H - 60000,
       title, sz=9, bold=True, color=C_WHITE)
    return y + HDR_H

# ── Col 1: Especialidades ─────────────────────────────────────────────────────
rrect(slide, C1X, CY, C1W, CH, fill=C_DGRAY, radius=3)
ty1 = section_hdr(C1X, CY, C1W, "Especialidades")

TECHS  = list(TECH_ICONS.keys())  # 17
NCOLS  = 4
NROWS  = -(-len(TECHS) // NCOLS)  # ceil

inner_w = C1W - 2 * PAD
inner_h = CH - HDR_H - 2 * PAD
GCOL = 40000; GROW = 35000
CELL_W = (inner_w - (NCOLS - 1) * GCOL) // NCOLS
CELL_H = (inner_h - (NROWS - 1) * GROW) // NROWS
LOGO_SZ_EMU = min(CELL_H - 160000, CELL_W - 60000, 360000)
LOGO_PIX = 128

for idx, tech in enumerate(TECHS):
    col = idx % NCOLS
    row = idx // NCOLS
    cx  = C1X + PAD + col * (CELL_W + GCOL)
    cy2 = ty1  + PAD + row * (CELL_H + GROW)

    rrect(slide, cx, cy2, CELL_W, CELL_H, fill=C_DARK2, radius=3)

    lpath = logo_paths.get(tech)
    if lpath and os.path.exists(lpath):
        try:
            logo_img = Image.open(lpath).convert("RGBA").resize((LOGO_PIX, LOGO_PIX), Image.LANCZOS)
            lx = cx + (CELL_W - LOGO_SZ_EMU) // 2
            ly = cy2 + 25000
            add_pil_image(slide, logo_img, lx, ly, LOGO_SZ_EMU, LOGO_SZ_EMU)
        except Exception as e:
            print(f"  render fail {tech}: {e}")

    tb(slide, cx + 10000, cy2 + LOGO_SZ_EMU + 45000,
       CELL_W - 20000, 170000, tech,
       sz=7, bold=True, color=C_WHITE, align=PP_ALIGN.CENTER)

# ── Col 2: Certificações + Hobbies ───────────────────────────────────────────
CERT_H  = int(CH * 0.46)
HOBB_H  = CH - CERT_H - CGAP
CY_CERT = CY
CY_HOBB = CY + CERT_H + CGAP

rrect(slide, C2X, CY_CERT, C2W, CERT_H, fill=C_DGRAY, radius=3)
ty_c = section_hdr(C2X, CY_CERT, C2W, "Certificações")

CERTS = list(CERT_ICONS.keys())
c_pad = 55000
c_each = (CERT_H - HDR_H - 2 * c_pad) // len(CERTS)
c_logo_sz = min(c_each - 130000, C2W - 4 * c_pad, 300000)

for i, cert in enumerate(CERTS):
    cy_ci = ty_c + c_pad + i * c_each
    lpath = logo_paths.get(cert)
    if lpath and os.path.exists(lpath):
        try:
            logo_img = Image.open(lpath).convert("RGBA").resize((96, 96), Image.LANCZOS)
            lx = C2X + (C2W - c_logo_sz) // 2
            add_pil_image(slide, logo_img, lx, cy_ci, c_logo_sz, c_logo_sz)
        except Exception:
            pass
    tb(slide, C2X + 40000, cy_ci + c_logo_sz + 15000,
       C2W - 80000, 200000, cert,
       sz=10, bold=True, color=C_WHITE, align=PP_ALIGN.CENTER)

rrect(slide, C2X, CY_HOBB, C2W, HOBB_H, fill=C_DGRAY, radius=3)
ty_h = section_hdr(C2X, CY_HOBB, C2W, "Hobbies")

HOBBIES = [("Família", "♥"), ("Esposa", "♡"), ("Netflix", "▶"), ("Video Games", "◈")]
hb_each = (HOBB_H - HDR_H - 2 * c_pad) // len(HOBBIES)
for i, (hb, ico) in enumerate(HOBBIES):
    hy = ty_h + c_pad + i * hb_each
    rrect(slide, C2X + c_pad, hy, C2W - 2 * c_pad, hb_each - 20000,
          fill=C_DARK2, radius=3)
    tb(slide, C2X + c_pad + 40000, hy + 20000,
       C2W - 2 * c_pad - 80000, hb_each - 60000,
       f"{ico}  {hb}", sz=9, color=C_WHITE)

# ── Col 3: Perguntas para a Turma ────────────────────────────────────────────
rrect(slide, C3X, CY, C3W, CH, fill=C_DGRAY, radius=3)
ty_q = section_hdr(C3X, CY, C3W, "Perguntas para a Turma")

QUESTIONS = [
    ("01", "Qual é o seu nome?"),
    ("02", "Qual é a sua experiência\ncom Kubernetes?"),
    ("03", "O que você espera\naprender neste curso?"),
]
Q_PAD = 60000
Q_EACH = (CH - HDR_H - 2 * Q_PAD - (len(QUESTIONS) - 1) * 50000) // len(QUESTIONS)

for i, (num, q) in enumerate(QUESTIONS):
    qy = ty_q + Q_PAD + i * (Q_EACH + 50000)
    rrect(slide, C3X + Q_PAD, qy, C3W - 2 * Q_PAD, Q_EACH,
          fill=C_DARK2, radius=3)
    NUM_SZ = 250000
    oval(slide, C3X + Q_PAD + 40000, qy + (Q_EACH - NUM_SZ) // 2,
         NUM_SZ, NUM_SZ, fill=C_BLUE)
    tb(slide, C3X + Q_PAD + 40000, qy + (Q_EACH - NUM_SZ) // 2 + 35000,
       NUM_SZ, NUM_SZ - 70000, num,
       sz=11, bold=True, color=C_WHITE, align=PP_ALIGN.CENTER)
    tb(slide, C3X + Q_PAD + 40000 + NUM_SZ + 55000,
       qy + 55000,
       C3W - 3 * Q_PAD - NUM_SZ - 55000, Q_EACH - 110000,
       q, sz=9, color=C_WHITE, wrap=True)

# ── Bottom bar ────────────────────────────────────────────────────────────────
rect(slide, 55000, SH - 55000, SW - 55000, 55000, fill=C_BLUE)

# ── Save ──────────────────────────────────────────────────────────────────────
out = os.path.join(SLIDES_DIR, "Apresentacao_Instrutor.pptx")
prs.save(out)
print(f"Saved: {out}")
