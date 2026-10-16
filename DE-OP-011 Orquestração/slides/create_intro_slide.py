from pptx import Presentation
from pptx.util import Emu, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.util import Emu, Pt, Inches
import copy

# Colors from Ada template
C_BG       = RGBColor(0x18, 0x1C, 0x23)   # near-black background
C_WHITE    = RGBColor(0xFF, 0xFD, 0xF8)   # off-white text
C_BLUE     = RGBColor(0x23, 0x71, 0xFF)   # blue accent
C_GREEN    = RGBColor(0xA6, 0xF7, 0x50)   # bright green accent
C_LGRAY    = RGBColor(0xEC, 0xED, 0xF3)   # light gray (category box bg)
C_LBLUE    = RGBColor(0xC4, 0xD2, 0xF8)   # light blue
C_RED      = RGBColor(0xFF, 0x23, 0x4F)   # red accent
C_DGRAY    = RGBColor(0x2A, 0x2F, 0x3A)   # slightly lighter dark

# Slide dimensions (16:9 widescreen)
SW = 9144000  # slide width in EMU
SH = 5143500  # slide height in EMU

def rgb(r, g, b):
    return RGBColor(r, g, b)

def add_rect(slide, x, y, w, h, fill_color=None, line_color=None, line_width=None, radius=None):
    from pptx.util import Emu
    from pptx.oxml.ns import qn
    from lxml import etree

    shape = slide.shapes.add_shape(
        1,  # MSO_SHAPE_TYPE.RECTANGLE
        Emu(x), Emu(y), Emu(w), Emu(h)
    )
    fill = shape.fill
    if fill_color:
        fill.solid()
        fill.fore_color.rgb = fill_color
    else:
        fill.background()

    line = shape.line
    if line_color:
        line.color.rgb = line_color
        if line_width:
            line.width = Emu(line_width)
    else:
        line.fill.background()

    return shape

def add_rounded_rect(slide, x, y, w, h, fill_color=None, line_color=None, radius_pct=5):
    from pptx.oxml.ns import qn
    from lxml import etree

    shape = slide.shapes.add_shape(
        5,  # MSO_AUTO_SHAPE_TYPE.ROUNDED_RECTANGLE
        Emu(x), Emu(y), Emu(w), Emu(h)
    )
    # Set corner radius
    sp_el = shape.element
    prstGeom = sp_el.find('.//' + qn('a:prstGeom'))
    if prstGeom is not None:
        avLst = prstGeom.find(qn('a:avLst'))
        if avLst is not None:
            for gd in avLst.findall(qn('a:gd')):
                if gd.get('name') == 'adj':
                    gd.set('fmla', f'val {radius_pct * 1000}')

    fill = shape.fill
    if fill_color:
        fill.solid()
        fill.fore_color.rgb = fill_color
    else:
        fill.background()

    line = shape.line
    if line_color:
        line.color.rgb = line_color
    else:
        line.fill.background()

    return shape

def add_ellipse(slide, x, y, w, h, fill_color=None, line_color=None):
    shape = slide.shapes.add_shape(
        9,  # MSO_AUTO_SHAPE_TYPE.OVAL
        Emu(x), Emu(y), Emu(w), Emu(h)
    )
    if fill_color:
        shape.fill.solid()
        shape.fill.fore_color.rgb = fill_color
    else:
        shape.fill.background()

    if line_color:
        shape.line.color.rgb = line_color
    else:
        shape.line.fill.background()

    return shape

def add_textbox(slide, x, y, w, h, text, font_name="Ubuntu", font_size=12,
                bold=False, color=None, align=PP_ALIGN.LEFT, word_wrap=True):
    txBox = slide.shapes.add_textbox(Emu(x), Emu(y), Emu(w), Emu(h))
    tf = txBox.text_frame
    tf.word_wrap = word_wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.name = font_name
    run.font.size = Pt(font_size)
    run.font.bold = bold
    if color:
        run.font.color.rgb = color
    return txBox

def add_label_value(slide, x, y, w, label, value, label_size=8, value_size=10):
    """Two-line box: small label on top, value below."""
    # Label
    add_textbox(slide, x, y, w, 200000, label,
                font_size=label_size, color=C_GREEN, bold=False)
    # Value
    add_textbox(slide, x, y + 180000, w, 350000, value,
                font_size=value_size, color=C_WHITE, bold=True)

def add_section_box(slide, x, y, w, h, title, items, title_color=C_BG,
                    bg_color=C_LGRAY, item_color=C_BG, columns=1):
    """A labeled section box with bullet items."""
    # Background rounded rect
    box = add_rounded_rect(slide, x, y, w, h, fill_color=bg_color, radius_pct=3)

    # Title bar at top
    title_h = 280000
    title_box = add_rounded_rect(slide, x, y, w, title_h, fill_color=C_BLUE, radius_pct=3)

    add_textbox(slide, x + 100000, y + 40000, w - 200000, title_h - 60000, title,
                font_size=10, bold=True, color=C_WHITE, align=PP_ALIGN.LEFT)

    # Items
    pad = 120000
    item_y = y + title_h + pad
    item_h = 220000
    gap = 40000

    if columns == 1:
        for item in items:
            add_textbox(slide, x + pad, item_y, w - 2 * pad, item_h,
                        f"• {item}", font_size=9, color=item_color)
            item_y += item_h + gap
    else:
        col_w = (w - 2 * pad - gap * (columns - 1)) // columns
        for i, item in enumerate(items):
            col = i % columns
            row = i // columns
            ix = x + pad + col * (col_w + gap)
            iy = item_y + row * (item_h + gap)
            chip = add_rounded_rect(slide, ix, iy, col_w, item_h,
                                    fill_color=C_BLUE, radius_pct=50)
            add_textbox(slide, ix + 50000, iy + 30000, col_w - 100000, item_h - 60000,
                        item, font_size=8, bold=True, color=C_WHITE,
                        align=PP_ALIGN.CENTER)

# ── Build presentation ────────────────────────────────────────────────────────
prs = Presentation()
prs.slide_width  = Emu(SW)
prs.slide_height = Emu(SH)

blank_layout = prs.slide_layouts[6]  # blank
slide = prs.slides.add_slide(blank_layout)

# ── Background ────────────────────────────────────────────────────────────────
bg = add_rect(slide, 0, 0, SW, SH, fill_color=C_BG)

# ── Left accent bar (thin green) ──────────────────────────────────────────────
add_rect(slide, 0, 0, 60000, SH, fill_color=C_GREEN)

# ── Top header area ───────────────────────────────────────────────────────────
HEADER_H = 900000
add_rect(slide, 60000, 0, SW - 60000, HEADER_H, fill_color=C_DGRAY)

# Photo placeholder circle
PHOTO_R = 380000
PHOTO_X = 150000
PHOTO_Y = (HEADER_H - 2 * PHOTO_R) // 2
add_ellipse(slide, PHOTO_X, PHOTO_Y, 2 * PHOTO_R, 2 * PHOTO_R,
            fill_color=C_BLUE, line_color=C_GREEN)

# Name & role
NAME_X = PHOTO_X + 2 * PHOTO_R + 120000
add_textbox(slide, NAME_X, 130000, 3200000, 380000,
            "Elton Benedito",
            font_name="Ubuntu", font_size=28, bold=True, color=C_WHITE)

add_textbox(slide, NAME_X, 490000, 3200000, 280000,
            "Instrutor | Desenvolvedor | Arquiteto Cloud",
            font_name="Ubuntu", font_size=12, color=C_GREEN)

# LinkedIn chip
LI_X = NAME_X
LI_Y = 700000
li_chip = add_rounded_rect(slide, LI_X, LI_Y, 1800000, 160000,
                            fill_color=C_BLUE, radius_pct=50)
add_textbox(slide, LI_X + 60000, LI_Y + 20000, 1680000, 120000,
            "linkedin.com/in/ejbenedito/",
            font_size=8, color=C_WHITE)

# Course label (top right)
add_textbox(slide, SW - 2400000, 60000, 2300000, 200000,
            "Orquestração Kubernetes",
            font_size=11, bold=True, color=C_GREEN, align=PP_ALIGN.RIGHT)
add_textbox(slide, SW - 2400000, 240000, 2300000, 160000,
            "Apresentação do Instrutor",
            font_size=9, color=C_WHITE, align=PP_ALIGN.RIGHT)

# ── Ada logo text (top right corner) ─────────────────────────────────────────
add_textbox(slide, SW - 700000, 60000 + HEADER_H + 40000, 640000, 200000,
            "ada.", font_name="Ubuntu", font_size=14, bold=True, color=C_GREEN,
            align=PP_ALIGN.RIGHT)

# ── Content area layout ───────────────────────────────────────────────────────
CONTENT_Y = HEADER_H + 120000
CONTENT_H = SH - CONTENT_Y - 100000
COL_GAP   = 80000
MARGIN_L  = 100000
MARGIN_R  = 80000

# Three columns
TOTAL_W = SW - 60000 - MARGIN_L - MARGIN_R
COL_W   = (TOTAL_W - 2 * COL_GAP) // 3
COL1_X  = 60000 + MARGIN_L
COL2_X  = COL1_X + COL_W + COL_GAP
COL3_X  = COL2_X + COL_W + COL_GAP

# ── Column 1: Especialidades ──────────────────────────────────────────────────
specs = [
    "Windows", "Linux", "Azure", ".NET",
    "SQL Server", "MongoDB", "Selenium", "Playwright",
    "n8n", "Postman", "Angular", "Vue.js",
    "React", "Python", "Docker", "Kubernetes",
    "GitHub",
]
add_section_box(slide, COL1_X, CONTENT_Y, COL_W, CONTENT_H,
                "Especialidades", specs,
                bg_color=C_DGRAY, item_color=C_WHITE, columns=2)

# ── Column 2: Certificações + Hobbies ────────────────────────────────────────
CERT_H = CONTENT_H // 2 - COL_GAP // 2
HOBB_Y = CONTENT_Y + CERT_H + COL_GAP
HOBB_H = CONTENT_H - CERT_H - COL_GAP

certs = ["AZ-900", "PSM I"]
add_section_box(slide, COL2_X, CONTENT_Y, COL_W, CERT_H,
                "Certificações", certs,
                bg_color=C_DGRAY, item_color=C_WHITE, columns=1)

hobbies = ["Família", "Esposa", "Netflix", "Video Games"]
add_section_box(slide, COL2_X, HOBB_Y, COL_W, HOBB_H,
                "Hobbies", hobbies,
                bg_color=C_DGRAY, item_color=C_WHITE, columns=1)

# ── Column 3: Perguntas para a Turma ─────────────────────────────────────────
questions = [
    "Qual é o seu nome?",
    "Qual é a sua experiência com Kubernetes?",
    "O que você espera aprender neste curso?",
]
add_section_box(slide, COL3_X, CONTENT_Y, COL_W, CONTENT_H,
                "Perguntas para a Turma", questions,
                bg_color=C_DGRAY, item_color=C_WHITE, columns=1)

# ── Bottom accent bar ─────────────────────────────────────────────────────────
add_rect(slide, 60000, SH - 60000, SW - 60000, 60000, fill_color=C_BLUE)

# Small green dot decorations (like template style)
for cx, cy, r in [(SW - 300000, 200000, 60000),
                  (SW - 200000, 350000, 40000),
                  (SW - 400000, 150000, 30000)]:
    add_ellipse(slide, cx - r, cy - r, 2 * r, 2 * r, fill_color=C_GREEN)

# ── Save ──────────────────────────────────────────────────────────────────────
out_path = r"c:\UserData\z004stze\Documents\Private\mine\ada\orquestracao-k8s\slides\Apresentacao_Instrutor.pptx"
prs.save(out_path)
print(f"Saved: {out_path}")
