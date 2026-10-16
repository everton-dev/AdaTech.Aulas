# -*- coding: utf-8 -*-
"""
build_slides.py  —  Módulo AR-NA-002 · Arquitetura de Serviços e Dados
=====================================================================
Gera 9 apresentações PPTX (uma por aula) SEGUINDO o template oficial Ada
(Ada_Template PPT.pptx): fundo cream, fontes Ubuntu, acentos azul/verde,
logo ada e barra de gradiente reutilizados do próprio template.

Estrutura de cada aula (aula tem 3h):
  1) Capa            -> layout TITLE do template (logo + gradiente nativos)
  2) Cronograma      -> RECRIADO nativamente (cards estilo everton_cronograma)
  3) Combinado       -> RECRIADO nativamente (estilo everton_combinado)
  4..N) Conteúdo     -> título azul + bullets + analogia lúdica
        + slides com IMAGENS de conteúdo copiadas dos markdowns
        + slides de código (Fira Code) e comparações

As aulas ocorrem Seg/Qua/Sex a partir de 10/08/2026 — total de 9 aulas.
A 9ª aula é "Concluir atividades do módulo e preencher rubricas".
"""

import os
import copy
from pptx import Presentation
from pptx.util import Emu, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn
from PIL import Image

# ─── paths ────────────────────────────────────────────────────────────────────
BASE      = r"C:\UserData\z004stze\Documents\Private\mine\ada\arquitetura-de-servicos\slides"
TEMPLATE  = r"C:\UserData\z004stze\Documents\Private\mine\ada\orquestracao-k8s\slides\Ada_Template PPT.pptx"
ASSETS    = os.path.join(BASE, "assets")
IMG_DIR   = os.path.join(BASE, "images")
OUT_DIR   = BASE

ADA_LOGO   = os.path.join(ASSETS, "ada_logo.png")
GRAD_H     = os.path.join(ASSETS, "gradient_h.png")   # barra horizontal verde->azul
GRAD_V     = os.path.join(ASSETS, "gradient_v.png")   # barra vertical
SWIRL      = os.path.join(ASSETS, "swirl_green.png")  # três laços verde claro

# ─── cores do template Ada (extraídas do theme1.xml) ───────────────────────────
C_CREAM = RGBColor(0xFF, 0xFB, 0xF0)   # fundo (master bg)
C_DARK  = RGBColor(0x18, 0x1C, 0x23)   # texto principal
C_BLUE  = RGBColor(0x23, 0x71, 0xFF)   # azul accent
C_GREEN = RGBColor(0xA6, 0xF7, 0x50)   # verde accent
C_GREENL= RGBColor(0xDA, 0xF9, 0xDA)   # verde claro
C_RED   = RGBColor(0xFF, 0x23, 0x4F)   # vermelho accent
C_WHITE = RGBColor(0xFF, 0xFD, 0xF8)
C_GRAY  = RGBColor(0x6A, 0x70, 0x7D)   # cinza texto secundário
C_LGRAY = RGBColor(0xEC, 0xED, 0xF3)   # cinza claro card

# ─── fontes ────────────────────────────────────────────────────────────────────
F_LIGHT  = "Ubuntu Light"
F_REG    = "Ubuntu"
F_MED    = "Ubuntu Medium"
F_CODE   = "Fira Code"

SW, SH = 9144000, 5143500   # dimensões do slide (16:9 do template)

# ─── helpers de baixo nível ─────────────────────────────────────────────────────

def _remove_all_slides(prs):
    """Remove os slides de exemplo do template SEM corromper (mantém layouts/mídia)."""
    sldIdLst = prs.slides._sldIdLst
    part = prs.part
    for sldId in list(sldIdLst):
        rId = sldId.get(qn('r:id'))
        try:
            part.drop_rel(rId)
        except Exception:
            pass
        sldIdLst.remove(sldId)


def new_prs():
    prs = Presentation(TEMPLATE)
    _remove_all_slides(prs)
    return prs


def add_slide(prs, layout_idx=3):
    """layout 3 = CUSTOM (vazio) — herda fundo cream do master."""
    return prs.slides.add_slide(prs.slide_layouts[layout_idx])


def _set_fill(shape, color):
    if color is None:
        shape.fill.background()
    else:
        shape.fill.solid()
        shape.fill.fore_color.rgb = color


def _set_line(shape, color, w=12700):
    if color is None:
        shape.line.fill.background()
    else:
        shape.line.color.rgb = color
        shape.line.width = Emu(w)


def rect(slide, x, y, w, h, fill=None, line=None, lw=12700):
    s = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Emu(x), Emu(y), Emu(w), Emu(h))
    _set_fill(s, fill); _set_line(s, line, lw)
    s.shadow.inherit = False
    return s


def rrect(slide, x, y, w, h, fill=None, line=None, radius=0.08, lw=12700):
    s = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Emu(x), Emu(y), Emu(w), Emu(h))
    _set_fill(s, fill); _set_line(s, line, lw)
    s.shadow.inherit = False
    try:
        s.adjustments[0] = radius
    except Exception:
        pass
    return s


def oval(slide, x, y, w, h, fill=None, line=None, lw=12700):
    s = slide.shapes.add_shape(MSO_SHAPE.OVAL, Emu(x), Emu(y), Emu(w), Emu(h))
    _set_fill(s, fill); _set_line(s, line, lw)
    s.shadow.inherit = False
    return s


def tb(slide, x, y, w, h, runs, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP,
       wrap=True, line_spacing=None, space_after=None):
    """runs: str OU lista de parágrafos; cada parágrafo é lista de (texto, dict).
       dict: font, sz, bold, color, italic."""
    box = slide.shapes.add_textbox(Emu(x), Emu(y), Emu(w), Emu(h))
    tf = box.text_frame
    tf.word_wrap = wrap
    tf.vertical_anchor = anchor
    tf.margin_left = 0; tf.margin_right = 0
    tf.margin_top = 0; tf.margin_bottom = 0

    if isinstance(runs, str):
        runs = [[(runs, {})]]
    elif runs and isinstance(runs[0], tuple):
        runs = [runs]

    for pi, para in enumerate(runs):
        p = tf.paragraphs[0] if pi == 0 else tf.add_paragraph()
        p.alignment = align
        if line_spacing:
            p.line_spacing = line_spacing
        if space_after is not None:
            p.space_after = Pt(space_after)
        for text, st in para:
            r = p.add_run()
            r.text = text
            r.font.name = st.get("font", F_REG)
            r.font.size = Pt(st.get("sz", 14))
            r.font.bold = st.get("bold", False)
            r.font.italic = st.get("italic", False)
            r.font.color.rgb = st.get("color", C_DARK)
    return box


def pic(slide, path, x, y, w=None, h=None):
    if w and h:
        return slide.shapes.add_picture(path, Emu(x), Emu(y), Emu(w), Emu(h))
    return slide.shapes.add_picture(path, Emu(x), Emu(y))


def pic_fit(slide, path, box_x, box_y, box_w, box_h, frame=True):
    """Insere imagem mantendo proporção, centralizada na caixa dada.
       Opcionalmente desenha uma moldura branca com borda cinza clara."""
    im = Image.open(path)
    iw, ih = im.size
    ar = iw / ih
    box_ar = box_w / box_h
    if ar > box_ar:
        w = box_w; h = int(box_w / ar)
    else:
        h = box_h; w = int(box_h * ar)
    x = box_x + (box_w - w) // 2
    y = box_y + (box_h - h) // 2
    if frame:
        pad = 60000
        rrect(slide, x - pad, y - pad, w + 2 * pad, h + 2 * pad,
              fill=C_WHITE, line=C_LGRAY, radius=0.04, lw=9525)
    return slide.shapes.add_picture(path, Emu(x), Emu(y), Emu(w), Emu(h))


# ─── elementos de marca (barra + logo + rodapé) ─────────────────────────────────

MODULE = "Arquitetura de Serviços e Dados"
PROFESSOR = "Prof.: Everton J Benedicto"


def brand_topbar(slide):
    """Barra de gradiente verde->azul no topo (reaproveita asset do template)."""
    im = Image.open(GRAD_H)
    ar = im.size[0] / im.size[1]
    h = int(SW / ar)
    pic(slide, GRAD_H, 0, 0, SW, h)
    return h


def brand_footer(slide, aula_num, aula_titulo):
    """Rodapé: linha fina + módulo + numeração."""
    y = SH - 300000
    rect(slide, 311700, y, SW - 2 * 311700, 6000, fill=C_LGRAY)
    tb(slide, 311700, y + 40000, 6000000, 220000,
       [[(f"Ada · AR-NA-002 · {MODULE}", {"font": F_REG, "sz": 8, "color": C_GRAY})]],
       anchor=MSO_ANCHOR.MIDDLE)
    tb(slide, (SW - 3000000) // 2, y + 40000, 3000000, 220000,
       [[(PROFESSOR, {"font": F_MED, "sz": 8, "color": C_DARK})]],
       align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    tb(slide, SW - 3311700, y + 40000, 3000000, 220000,
       [[(f"Aula {aula_num:02d} — {aula_titulo}", {"font": F_MED, "sz": 8, "color": C_BLUE})]],
       align=PP_ALIGN.RIGHT, anchor=MSO_ANCHOR.MIDDLE)


def content_header(slide, titulo, kicker=None):
    """Cabeçalho padrão de slide de conteúdo: título grande + barra verde."""
    top = brand_topbar(slide)
    y = top + 180000
    if kicker:
        tb(slide, 311700, y, SW - 623400, 240000,
           [[(kicker.upper(), {"font": F_MED, "sz": 11, "color": C_BLUE})]])
        y += 260000
    tb(slide, 311700, y, SW - 623400, 560000,
       [[(titulo, {"font": F_MED, "sz": 26, "color": C_DARK})]])
    # traço verde
    rect(slide, 311700, y + 560000, 900000, 55000, fill=C_GREEN)
    return y + 560000 + 130000   # retorna Y de início do conteúdo


# ─── SLIDE: CAPA ────────────────────────────────────────────────────────────────

def build_capa(prs, aula_num, aula_titulo, subtitulo, data_str):
    slide = add_slide(prs)
    brand_topbar(slide)

    # swirl decorativo grande no canto direito (bem suave)
    im = Image.open(SWIRL); ar = im.size[0] / im.size[1]
    sw_w = 3400000; sw_h = int(sw_w / ar)
    pic(slide, SWIRL, SW - sw_w + 700000, SH - sw_h + 500000, sw_w, sw_h)

    # número grande da aula
    tb(slide, 560000, 900000, 2400000, 1500000,
       [[(f"{aula_num:02d}", {"font": F_LIGHT, "sz": 130, "color": C_GREEN, "bold": True})]])

    # kicker
    tb(slide, 620000, 2350000, 6000000, 300000,
       [[("AULA " + str(aula_num).zfill(2) + "  ·  " + data_str,
          {"font": F_MED, "sz": 13, "color": C_BLUE})]])

    # título da aula
    tb(slide, 620000, 2620000, 6600000, 1200000,
       [[(aula_titulo, {"font": F_MED, "sz": 40, "color": C_DARK})]],
       line_spacing=1.0)

    # subtítulo
    tb(slide, 620000, 3720000, 6600000, 500000,
       [[(subtitulo, {"font": F_LIGHT, "sz": 16, "color": C_GRAY, "italic": True})]])

    # logo ada canto inferior direito
    im = Image.open(ADA_LOGO); ar = im.size[0] / im.size[1]
    lw = 1200000; lh = int(lw / ar)
    pic(slide, ADA_LOGO, SW - lw - 360000, SH - lh - 360000, lw, lh)

    # tag do módulo
    tag_w = 4600000
    rrect(slide, 620000, 4350000, tag_w, 300000, fill=C_DARK, radius=0.5)
    tb(slide, 620000, 4350000, tag_w, 300000,
       [[("Módulo · " + MODULE, {"font": F_REG, "sz": 10, "color": C_GREEN})]],
       align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

    # nome do professor (rodapé da capa)
    tb(slide, 620000, 4720000, tag_w, 240000,
       [[(PROFESSOR, {"font": F_MED, "sz": 11, "color": C_DARK})]],
       anchor=MSO_ANCHOR.MIDDLE)
    return slide


# ─── SLIDE: CRONOGRAMA (recriado nativamente) ───────────────────────────────────

CRONOGRAMA = [
    ("01", "Seg 10/08", "Introdução ao Módulo e Docker"),
    ("02", "Qua 12/08", "Arquitetura de Servidores"),
    ("03", "Sex 14/08", "Apache e Nginx"),
    ("04", "Seg 17/08", "Proxy Reverso e DNS"),
    ("05", "Qua 19/08", "CI/CD e Ciclo de Vida"),
    ("06", "Sex 21/08", "Cloud Computing"),
    ("07", "Seg 24/08", "Arquitetura de Dados e Data Warehouse"),
    ("08", "Qua 26/08", "Data Lake"),
    ("09", "Sex 28/08", "Concluir atividades e preencher rubricas"),
]


def build_cronograma(prs, aula_num, aula_titulo):
    slide = add_slide(prs)
    top = brand_topbar(slide)

    # título
    tb(slide, 311700, top + 150000, SW - 623400, 520000,
       [[("Cronograma das Aulas", {"font": F_MED, "sz": 26, "color": C_DARK})]])
    rect(slide, 311700, top + 660000, 900000, 55000, fill=C_GREEN)

    # grade 3x3
    grid_y = top + 850000
    cols, rows = 3, 3
    mx = 311700
    gap = 150000
    card_w = (SW - 2 * mx - (cols - 1) * gap) // cols
    avail_h = SH - grid_y - 360000
    card_h = (avail_h - (rows - 1) * gap) // rows

    for idx, (num, dia, titulo) in enumerate(CRONOGRAMA):
        r = idx // cols
        c = idx % cols
        x = mx + c * (card_w + gap)
        y = grid_y + r * (card_h + gap)

        is_current = (idx + 1) == aula_num
        if is_current:
            # card destacado
            rrect(slide, x, y, card_w, card_h, fill=C_DARK, radius=0.06)
            num_color = C_GREEN
            dia_color = C_GREEN
            tit_color = C_WHITE
            # faixinha lateral verde
            rrect(slide, x, y, 70000, card_h, fill=C_GREEN, radius=0.5)
        else:
            rrect(slide, x, y, card_w, card_h, fill=C_WHITE, line=C_LGRAY, radius=0.06, lw=9525)
            num_color = C_GREEN
            dia_color = C_BLUE
            tit_color = C_DARK

        pad = 150000
        tb(slide, x + pad, y + pad - 20000, card_w - 2 * pad, 420000,
           [[(num, {"font": F_MED, "sz": 30, "color": num_color, "bold": True})]])
        tb(slide, x + pad, y + pad + 380000, card_w - 2 * pad, 220000,
           [[(dia, {"font": F_MED, "sz": 11, "color": dia_color})]])
        tb(slide, x + pad, y + pad + 610000, card_w - 2 * pad, card_h - pad - 610000,
           [[(titulo, {"font": F_REG, "sz": 12, "color": tit_color})]],
           line_spacing=1.05)

    brand_footer(slide, aula_num, aula_titulo)
    return slide


# ─── SLIDE: COMBINADO (recriado nativamente) ────────────────────────────────────

COMBINADOS = [
    "Câmeras ligadas.",
    "Entrem no horário: início e intervalo.",
    "Participem da aula.",
    "Tirem dúvidas.",
    "Levantem a mão para tirar dúvidas.",
]


def build_combinado(prs, aula_num, aula_titulo):
    slide = add_slide(prs)
    top = brand_topbar(slide)

    # swirl decorativo à direita (bem suave)
    im = Image.open(SWIRL); ar = im.size[0] / im.size[1]
    sw_w = 3000000; sw_h = int(sw_w / ar)
    pic(slide, SWIRL, SW - sw_w + 500000, top + 400000, sw_w, sw_h)

    # kicker + título grande
    tb(slide, 311700, top + 150000, SW - 623400, 260000,
       [[("COMBINADO DA TURMA", {"font": F_MED, "sz": 13, "color": C_GREEN})]])
    tb(slide, 311700, top + 400000, SW - 623400, 700000,
       [[("Por favor!", {"font": F_MED, "sz": 46, "color": C_DARK})]])

    body_y = top + 1250000
    col_gap = 260000
    left_w = int((SW - 623400 - col_gap) * 0.38)
    right_w = (SW - 623400 - col_gap) - left_w
    left_x = 311700
    right_x = left_x + left_w + col_gap
    body_h = SH - body_y - 360000

    # ── coluna esquerda: "Bora participar!" ──
    rrect(slide, left_x, body_y, left_w, 300000, fill=C_BLUE, radius=0.12)
    tb(slide, left_x, body_y, left_w, 300000,
       [[("Bora participar!", {"font": F_MED, "sz": 13, "color": C_WHITE})]],
       align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

    card_y = body_y + 380000
    card_h = body_h - 380000
    rrect(slide, left_x, card_y, left_w, card_h, fill=C_WHITE, line=C_LGRAY, radius=0.05, lw=9525)

    tb(slide, left_x + 150000, card_y + 200000, left_w - 300000, 900000,
       [[("Câmera ligada", {"font": F_MED, "sz": 15, "color": C_DARK})],
        [("+ mão levantada", {"font": F_MED, "sz": 15, "color": C_DARK})],
        [("= aula top!", {"font": F_MED, "sz": 15, "color": C_GREEN})]],
       line_spacing=1.15)

    # botão intervalo
    btn_h = 360000
    btn_y = card_y + card_h - btn_h - 150000
    rrect(slide, left_x + 150000, btn_y, left_w - 300000, btn_h, fill=C_GREEN, radius=0.5)
    tb(slide, left_x + 150000, btn_y, left_w - 300000, btn_h,
       [[("INTERVALO · 15 min", {"font": F_MED, "sz": 12, "color": C_DARK})]],
       align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

    # ── coluna direita: lista de combinados ──
    rrect(slide, right_x, body_y, right_w, 300000, fill=C_BLUE, radius=0.10)
    tb(slide, right_x, body_y, right_w, 300000,
       [[("Combinados da nossa aula", {"font": F_MED, "sz": 13, "color": C_WHITE})]],
       align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

    list_y = body_y + 400000
    list_h = body_h - 400000
    each = list_h // len(COMBINADOS)
    for i, item in enumerate(COMBINADOS):
        iy = list_y + i * each
        cd = 240000
        oval(slide, right_x, iy + (each - cd) // 2, cd, cd, fill=C_GREEN)
        tb(slide, right_x, iy + (each - cd) // 2, cd, cd,
           [[(str(i + 1), {"font": F_MED, "sz": 13, "color": C_DARK, "bold": True})]],
           align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
        tb(slide, right_x + cd + 180000, iy, right_w - cd - 180000, each,
           [[(item, {"font": F_REG, "sz": 15, "color": C_DARK})]],
           anchor=MSO_ANCHOR.MIDDLE)

    brand_footer(slide, aula_num, aula_titulo)
    return slide


# ─── SLIDE: CONTEÚDO (bullets + analogia) ────────────────────────────────────────

def build_content(prs, aula_num, aula_titulo, titulo, bullets, analogia=None, kicker=None):
    slide = add_slide(prs)
    y = content_header(slide, titulo, kicker)

    body_h = SH - y - 360000
    ana_h = 900000 if analogia else 0
    bullets_h = body_h - ana_h - (150000 if analogia else 0)

    n = len(bullets)
    each = min(bullets_h // max(n, 1), 620000)
    for i, b in enumerate(bullets):
        by = y + i * each
        cd = 300000
        oval(slide, 311700, by + 30000, cd, cd, fill=C_BLUE)
        tb(slide, 311700, by + 30000, cd, cd,
           [[(str(i + 1), {"font": F_MED, "sz": 13, "color": C_WHITE, "bold": True})]],
           align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
        # bullet pode ser (negrito, resto) ou str
        if isinstance(b, tuple):
            head, rest = b
            runs = [[(head + " ", {"font": F_MED, "sz": 14, "color": C_DARK}),
                     (rest, {"font": F_REG, "sz": 14, "color": C_GRAY})]]
        else:
            runs = [[(b, {"font": F_REG, "sz": 14, "color": C_DARK})]]
        tb(slide, 311700 + cd + 200000, by, SW - 623400 - cd - 200000, each,
           runs, anchor=MSO_ANCHOR.MIDDLE, line_spacing=1.05)

    if analogia:
        ay = SH - 360000 - ana_h
        rrect(slide, 311700, ay, SW - 623400, ana_h, fill=C_GREENL, radius=0.06)
        rrect(slide, 311700, ay, 70000, ana_h, fill=C_GREEN, radius=0.5)
        tb(slide, 311700 + 200000, ay + 90000, SW - 623400 - 400000, 240000,
           [[("💡 ANALOGIA", {"font": F_MED, "sz": 11, "color": C_BLUE})]])
        tb(slide, 311700 + 200000, ay + 340000, SW - 623400 - 400000, ana_h - 400000,
           [[(analogia, {"font": F_REG, "sz": 13, "color": C_DARK, "italic": True})]],
           line_spacing=1.1)

    brand_footer(slide, aula_num, aula_titulo)
    return slide


# ─── SLIDE: CONTEÚDO + IMAGEM ────────────────────────────────────────────────────

def build_image_slide(prs, aula_num, aula_titulo, titulo, image_key,
                      caption=None, bullets=None, kicker=None, fonte=None):
    slide = add_slide(prs)
    y = content_header(slide, titulo, kicker)
    body_h = SH - y - 360000

    img_path = os.path.join(IMG_DIR, image_key + ".png")

    if bullets:
        # imagem à esquerda, bullets à direita
        col_gap = 300000
        img_w = int((SW - 623400 - col_gap) * 0.52)
        txt_w = (SW - 623400 - col_gap) - img_w
        pic_fit(slide, img_path, 311700, y, img_w, body_h - (260000 if fonte else 0))
        if fonte:
            tb(slide, 311700, y + body_h - 230000, img_w, 200000,
               [[("Fonte: " + fonte, {"font": F_REG, "sz": 7, "color": C_GRAY, "italic": True})]])
        tx = 311700 + img_w + col_gap
        n = len(bullets)
        each = min(body_h // max(n, 1), 640000)
        for i, b in enumerate(bullets):
            by = y + i * each
            cd = 260000
            oval(slide, tx, by + 20000, cd, cd, fill=C_GREEN)
            tb(slide, tx, by + 20000, cd, cd,
               [[(str(i + 1), {"font": F_MED, "sz": 12, "color": C_DARK, "bold": True})]],
               align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
            if isinstance(b, tuple):
                head, rest = b
                runs = [[(head + " ", {"font": F_MED, "sz": 13, "color": C_DARK}),
                         (rest, {"font": F_REG, "sz": 13, "color": C_GRAY})]]
            else:
                runs = [[(b, {"font": F_REG, "sz": 13, "color": C_DARK})]]
            tb(slide, tx + cd + 160000, by, txt_w - cd - 160000, each,
               runs, anchor=MSO_ANCHOR.MIDDLE, line_spacing=1.05)
    else:
        # imagem grande centralizada
        cap_h = 300000 if caption else 0
        fonte_h = 230000 if fonte else 0
        pic_fit(slide, img_path, 311700, y, SW - 623400, body_h - cap_h - fonte_h)
        if caption:
            tb(slide, 311700, y + body_h - cap_h - fonte_h, SW - 623400, cap_h,
               [[(caption, {"font": F_REG, "sz": 12, "color": C_GRAY, "italic": True})]],
               align=PP_ALIGN.CENTER)
        if fonte:
            tb(slide, 311700, SH - 460000, SW - 623400, 180000,
               [[("Fonte: " + fonte, {"font": F_REG, "sz": 7, "color": C_GRAY, "italic": True})]],
               align=PP_ALIGN.CENTER)

    brand_footer(slide, aula_num, aula_titulo)
    return slide


# ─── SLIDE: CÓDIGO ───────────────────────────────────────────────────────────────

def build_code(prs, aula_num, aula_titulo, titulo, intro, code_lines, kicker=None):
    slide = add_slide(prs)
    y = content_header(slide, titulo, kicker)
    body_h = SH - y - 360000

    if intro:
        tb(slide, 311700, y, SW - 623400, 320000,
           [[(intro, {"font": F_REG, "sz": 13, "color": C_GRAY})]], line_spacing=1.05)
        y += 380000
        body_h -= 380000

    # janela de código estilo terminal
    rrect(slide, 311700, y, SW - 623400, body_h, fill=C_DARK, radius=0.03)
    # barra de título do terminal
    bar_h = 260000
    rrect(slide, 311700, y, SW - 623400, bar_h, fill=RGBColor(0x2A, 0x2F, 0x3A), radius=0.03)
    for i, col in enumerate([C_RED, C_GREEN, C_BLUE]):
        oval(slide, 311700 + 150000 + i * 200000, y + 80000, 100000, 100000, fill=col)
    tb(slide, 311700, y, SW - 623400, bar_h,
       [[("bash", {"font": F_CODE, "sz": 9, "color": C_GRAY})]],
       align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

    # corpo do código
    paras = []
    for ln in code_lines:
        if ln.strip().startswith("#"):
            paras.append([(ln, {"font": F_CODE, "sz": 11, "color": C_GRAY})])
        elif ln.strip() == "":
            paras.append([(" ", {"font": F_CODE, "sz": 6, "color": C_DARK})])
        else:
            paras.append([(ln, {"font": F_CODE, "sz": 11, "color": C_GREEN})])
    tb(slide, 311700 + 200000, y + bar_h + 100000,
       SW - 623400 - 400000, body_h - bar_h - 200000,
       paras, line_spacing=1.12)

    brand_footer(slide, aula_num, aula_titulo)
    return slide


# ─── SLIDE: COMPARAÇÃO (2 colunas) ──────────────────────────────────────────────

def build_comparison(prs, aula_num, aula_titulo, titulo,
                     a_title, a_items, b_title, b_items, kicker=None):
    slide = add_slide(prs)
    y = content_header(slide, titulo, kicker)
    body_h = SH - y - 360000

    gap = 260000
    col_w = (SW - 623400 - gap) // 2
    ax = 311700
    bx = ax + col_w + gap

    for x, ct, items, accent in [(ax, a_title, a_items, C_BLUE),
                                  (bx, b_title, b_items, C_GREEN)]:
        rrect(slide, x, y, col_w, body_h, fill=C_WHITE, line=C_LGRAY, radius=0.04, lw=9525)
        # header colorido
        rrect(slide, x, y, col_w, 320000, fill=accent, radius=0.04)
        hdr_color = C_WHITE if accent == C_BLUE else C_DARK
        tb(slide, x + 150000, y, col_w - 300000, 320000,
           [[(ct, {"font": F_MED, "sz": 14, "color": hdr_color})]],
           anchor=MSO_ANCHOR.MIDDLE)
        # itens
        iy = y + 460000
        each = (body_h - 560000) // max(len(items), 1)
        for it in items:
            dot = 140000
            oval(slide, x + 150000, iy + (each - dot) // 2, dot, dot, fill=accent)
            tb(slide, x + 150000 + dot + 130000, iy,
               col_w - 300000 - dot - 130000, each,
               [[(it, {"font": F_REG, "sz": 12, "color": C_DARK})]],
               anchor=MSO_ANCHOR.MIDDLE, line_spacing=1.0)
            iy += each

    brand_footer(slide, aula_num, aula_titulo)
    return slide


# ─── SLIDE: RECAP ────────────────────────────────────────────────────────────────

def build_recap(prs, aula_num, aula_titulo, pontos):
    slide = add_slide(prs)
    y = content_header(slide, "Recapitulando a Aula", kicker="Resumo")
    body_h = SH - y - 360000
    each = min(body_h // max(len(pontos), 1), 700000)
    for i, p in enumerate(pontos):
        by = y + i * each
        h = each - 130000
        rrect(slide, 311700, by, SW - 623400, h, fill=C_LGRAY, radius=0.08)
        rrect(slide, 311700, by, 70000, h, fill=C_GREEN, radius=0.5)
        cd = 300000
        oval(slide, 311700 + 180000, by + (h - cd) // 2, cd, cd, fill=C_BLUE)
        tb(slide, 311700 + 180000, by + (h - cd) // 2, cd, cd,
           [[("✓", {"font": F_MED, "sz": 14, "color": C_WHITE, "bold": True})]],
           align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
        tb(slide, 311700 + 180000 + cd + 180000, by,
           SW - 623400 - 180000 - cd - 360000, h,
           [[(p, {"font": F_REG, "sz": 13, "color": C_DARK})]],
           anchor=MSO_ANCHOR.MIDDLE, line_spacing=1.05)
    brand_footer(slide, aula_num, aula_titulo)
    return slide


# ─── SLIDE: ENCERRAMENTO ─────────────────────────────────────────────────────────

def build_closing(prs, aula_num, aula_titulo, msg="Obrigado!"):
    slide = add_slide(prs)
    brand_topbar(slide)
    # swirl centralizado suave
    im = Image.open(SWIRL); ar = im.size[0] / im.size[1]
    sw_w = 3800000; sw_h = int(sw_w / ar)
    pic(slide, SWIRL, (SW - sw_w) // 2, (SH - sw_h) // 2 - 300000, sw_w, sw_h)
    tb(slide, 0, SH // 2 - 700000, SW, 800000,
       [[(msg, {"font": F_MED, "sz": 44, "color": C_DARK})]],
       align=PP_ALIGN.CENTER)
    tb(slide, 0, SH // 2 + 100000, SW, 400000,
       [[("Dúvidas? Levante a mão! 🙋", {"font": F_LIGHT, "sz": 16, "color": C_GRAY, "italic": True})]],
       align=PP_ALIGN.CENTER)
    # logo
    im = Image.open(ADA_LOGO); ar = im.size[0] / im.size[1]
    lw = 1000000; lh = int(lw / ar)
    pic(slide, ADA_LOGO, (SW - lw) // 2, SH - lh - 500000, lw, lh)
    # nome do professor
    tb(slide, 0, SH - 340000, SW, 240000,
       [[(PROFESSOR, {"font": F_MED, "sz": 10, "color": C_GRAY})]],
       align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    return slide


# =================================================================================
#  DEFINIÇÃO DAS 9 AULAS
# =================================================================================

AULAS = [
    # ─── AULA 1 ───────────────────────────────────────────────────────────────
    {
        "num": 1, "data": "Segunda, 10/08",
        "titulo": "Introdução ao Módulo e Docker",
        "subtitulo": "Virtualização, containers e o começo de tudo",
        "slides": [
            {"type": "content", "kicker": "Boas-vindas",
             "titulo": "O que vamos aprender neste módulo?",
             "bullets": [
                 ("Docker e containers:", "empacotar aplicações de forma consistente"),
                 ("Arquitetura de Servidores:", "como os sistemas se organizam"),
                 ("Apache, Nginx e Proxy Reverso:", "os guardiões do tráfego web"),
                 ("DNS:", "o catálogo telefônico da internet"),
                 ("CI/CD e Cloud:", "automatizar e escalar com qualidade"),
                 ("Dados:", "Arquitetura de Dados, Data Warehouse e Data Lake"),
             ],
             "analogia": "Pense neste módulo como montar uma pizzaria: cada tema é um ingrediente. No fim, você terá a pizza completa da Arquitetura de Serviços e Dados pronta para servir!"},
            {"type": "image", "kicker": "Virtualização",
             "titulo": "Máquinas Virtuais e o Hipervisor",
             "image": "virtualizacao_hypervisor",
             "bullets": [
                 ("Virtualização:", "vários ambientes isolados em um mesmo hardware"),
                 ("Hipervisor:", "camada que divide os recursos entre as VMs"),
                 ("Cada VM:", "tem seu próprio Sistema Operacional completo"),
                 ("Benefícios:", "aproveitamento do hardware, flexibilidade e isolamento"),
             ]},
            {"type": "image", "kicker": "Comparação",
             "titulo": "Virtualização vs Conteinerização",
             "image": "vm_vs_container",
             "caption": "Containers compartilham o kernel do host — mais leves que as VMs.",
             "fonte": "4linux.com.br"},
            {"type": "content", "kicker": "Docker",
             "titulo": "O que é o Docker? — Analogia do Condomínio",
             "bullets": [
                 ("Terreno (SO Host):", "a base onde tudo é construído"),
                 ("Prédio (Docker Engine):", "compartilha CPU, memória e rede"),
                 ("Apartamentos (Containers):", "cada app isolado em seu espaço"),
                 ("Planta (Dockerfile):", "a receita de como construir o container"),
                 ("Catálogo (Docker Hub):", "repositório de imagens prontas"),
             ],
             "analogia": "Apartamentos num condomínio compartilham a estrutura (água, luz, elevador), mas cada um tem cozinha e banheiro próprios. Containers fazem o mesmo: compartilham o SO, mas isolam cada aplicação."},
            {"type": "code", "kicker": "Mão na massa",
             "titulo": "Docker na Prática — Comandos Essenciais",
             "intro": "Estes são os comandos do dia a dia com Docker:",
             "code": [
                 "# Verificar a versão instalada",
                 "docker --version",
                 "",
                 "# Testar a instalação",
                 "docker run hello-world",
                 "",
                 "# Baixar uma imagem e rodar nginx na porta 8080",
                 "docker pull nginx",
                 "docker run -d -p 8080:80 --name meu-nginx nginx",
                 "",
                 "# Listar, parar e remover",
                 "docker ps",
                 "docker stop meu-nginx && docker rm meu-nginx",
             ]},
            {"type": "content", "kicker": "Qualidade",
             "titulo": "Boas Práticas com Docker",
             "bullets": [
                 ("Imagens oficiais:", "do Docker Hub — mais seguras e atualizadas"),
                 ("Imagens mínimas:", "prefira Alpine para reduzir tamanho e riscos"),
                 ("Ordene o Dockerfile:", "do que muda menos para o que muda mais"),
                 ("Isolamento de rede:", "use redes personalizadas entre serviços"),
                 ("Nunca:", "armazene senhas ou tokens dentro da imagem"),
             ],
             "analogia": "É como arrumar a mochila de viagem: na base o que usa por último (dependências fixas), no topo o que abre primeiro (seu código). Assim o Docker aproveita o cache e constrói mais rápido!"},
            {"type": "recap", "pontos": [
                "Virtualização cria VMs com SO completo; containers compartilham o kernel — mais leves e rápidos.",
                "Docker empacota a aplicação com todas as dependências, acabando com o 'funciona na minha máquina'.",
                "Comandos essenciais: pull, run, ps, stop, rm, logs.",
                "Boas práticas: imagens oficiais, Alpine e nunca segredos na imagem.",
            ]},
        ],
    },

    # ─── AULA 2 ───────────────────────────────────────────────────────────────
    {
        "num": 2, "data": "Quarta, 12/08",
        "titulo": "Arquitetura de Servidores",
        "subtitulo": "Monolítico, microserviços e o time de servidores",
        "slides": [
            {"type": "image", "kicker": "Estilos de arquitetura",
             "titulo": "Monolítico vs Microserviços",
             "image": "monolito_vs_micro",
             "bullets": [
                 ("Monolítico:", "toda a aplicação em um único bloco"),
                 ("Escala difícil:", "para crescer, escala-se o sistema inteiro"),
                 ("Microserviços:", "serviços pequenos e independentes"),
                 ("Escala individual:", "cada serviço cresce conforme sua demanda"),
             ],
             "fonte": "devnow.dev.br"},
            {"type": "content", "kicker": "Componentes",
             "titulo": "Tipos de Servidores — O Time Completo",
             "bullets": [
                 ("Servidor de Aplicação:", "executa a lógica de negócio (Tomcat, WildFly)"),
                 ("Servidor Web:", "entrega HTML, CSS e JS (Apache, Nginx)"),
                 ("Banco de Dados:", "armazena e recupera dados (PostgreSQL, MySQL)"),
                 ("Servidor Proxy:", "distribui carga e protege os servidores"),
                 ("Servidor de Cache:", "respostas rápidas da memória (Redis)"),
                 ("Servidor DNS:", "traduz nomes de domínio em IPs"),
             ],
             "analogia": "Um restaurante: o garçom (web) recebe o pedido, o chef (aplicação) cozinha, o estoque (banco) guarda os ingredientes e o caixa (proxy) organiza os pagamentos."},
            {"type": "comparison", "kicker": "Escalabilidade",
             "titulo": "Como Crescer com Inteligência",
             "a_title": "Vertical (Scale-Up)",
             "a_items": [
                 "Adicionar mais CPU/RAM ao servidor",
                 "Simples de implementar",
                 "Tem limite físico de crescimento",
                 "Ponto único de falha",
             ],
             "b_title": "Horizontal (Scale-Out)",
             "b_items": [
                 "Adicionar mais servidores ao pool",
                 "Distribui a carga entre máquinas",
                 "Flexível e tolerante a falhas",
                 "Ideal para picos (Black Friday!)",
             ]},
            {"type": "image", "kicker": "Servidores de aplicação",
             "titulo": "Exemplos: Apache Tomcat",
             "image": "tomcat_arq",
             "caption": "Arquitetura do Apache Tomcat — servidor de aplicação Java mais popular.",
             "fonte": "medium.com/@nocettimarcos"},
            {"type": "content", "kicker": "Servidores de aplicação",
             "titulo": "Servidores de Aplicação Populares",
             "bullets": [
                 ("Apache Tomcat:", "Java (Servlets/JSP), open source e leve"),
                 ("JBoss/WildFly:", "Java EE completo — EJB, transações, segurança"),
                 ("WebLogic (Oracle):", "corporativo, alta disponibilidade"),
                 ("WebSphere (IBM):", "robusto, muito usado em bancos"),
                 ("Recursos comuns:", "pool de conexões, autenticação, cache"),
             ],
             "analogia": "Se o Docker é o apartamento, o servidor de aplicação é a academia do condomínio: um espaço com equipamentos compartilhados (memória, threads, conexões) para todos os apps usarem."},
            {"type": "recap", "pontos": [
                "Monolítico é simples no início; microserviços são flexíveis, porém mais complexos.",
                "Cada tipo de servidor tem uma função específica na arquitetura.",
                "Escalabilidade vertical (mais poder) vs horizontal (mais máquinas).",
                "Servidores de aplicação gerenciam transações, segurança e pools de conexão.",
            ]},
        ],
    },

    # ─── AULA 3 ───────────────────────────────────────────────────────────────
    {
        "num": 3, "data": "Sexta, 14/08",
        "titulo": "Apache e Nginx",
        "subtitulo": "Os servidores web mais usados do planeta",
        "slides": [
            {"type": "image", "kicker": "Servidor web",
             "titulo": "Apache HTTP Server — O Veterano",
             "image": "apache_logo",
             "bullets": [
                 ("Criado em 1995:", "um dos mais populares do mundo"),
                 ("Open source:", "multiplataforma e altamente customizável"),
                 ("Modular:", "adicione PHP, Python e SSL com módulos"),
                 ("Por conexão:", "usa um processo ou thread para cada requisição"),
             ]},
            {"type": "image", "kicker": "Como funciona",
             "titulo": "O Funcionamento de um Servidor Web",
             "image": "web_server_func",
             "caption": "Recepção → Processamento → Resposta → Renderização no navegador.",
             "fonte": "informationq.com"},
            {"type": "code", "kicker": "Mão na massa",
             "titulo": "Apache com Docker",
             "intro": "Suba um Apache sem instalar nada além do Docker:",
             "code": [
                 "# Baixar a imagem oficial (httpd)",
                 "docker pull httpd",
                 "",
                 "# Rodar o Apache na porta 80",
                 "docker run -d --name meu-apache -p 80:80 httpd",
                 "",
                 "# Verificar",
                 "docker ps",
                 "",
                 "# Abra http://localhost:80  ->  'It works!'",
                 "# Desafio: altere a página inicial!",
             ]},
            {"type": "image", "kicker": "Servidor web",
             "titulo": "Nginx — O Campeão de Performance",
             "image": "nginx_logo",
             "bullets": [
                 ("Criado em 2002:", "para resolver o C10k (10 mil conexões)"),
                 ("Assíncrono:", "arquitetura baseada em eventos, usa pouca memória"),
                 ("Poucos workers:", "gerenciam milhares de conexões ao mesmo tempo"),
                 ("Versátil:", "web, proxy reverso, balanceador e cache"),
             ]},
            {"type": "image", "kicker": "Comparação",
             "titulo": "Apache vs Nginx",
             "image": "apache_vs_nginx",
             "caption": "Apache: processo por conexão. Nginx: eventos assíncronos.",
             "fonte": "insightdials.com"},
            {"type": "code", "kicker": "Mão na massa",
             "titulo": "Nginx com Docker Compose",
             "intro": "Um servidor Nginx com página customizada via Compose:",
             "code": [
                 "# docker-compose.yml",
                 "version: '3'",
                 "services:",
                 "  web:",
                 "    image: nginx:latest",
                 "    ports:",
                 '      - "8080:80"',
                 "    volumes:",
                 "      - ./html:/usr/share/nginx/html",
                 "",
                 "# docker-compose up  ->  http://localhost:8080",
             ]},
            {"type": "recap", "pontos": [
                "Apache: veterano e modular, uma thread/processo por requisição — ótimo para flexibilidade.",
                "Nginx: assíncrono por eventos — ótimo para alta concorrência e proxy reverso.",
                "Podem trabalhar juntos: Nginx na frente (proxy) + Apache/Tomcat atrás (app).",
                "Docker facilita instalar e testar qualquer servidor web.",
            ]},
        ],
    },

    # ─── AULA 4 ───────────────────────────────────────────────────────────────
    {
        "num": 4, "data": "Segunda, 17/08",
        "titulo": "Proxy Reverso e DNS",
        "subtitulo": "Intermediários inteligentes e o catálogo da internet",
        "slides": [
            {"type": "image", "kicker": "Proxy reverso",
             "titulo": "Proxy Reverso — O Segurança do Prédio",
             "image": "proxy_reverso_flow",
             "bullets": [
                 ("Fica na frente:", "recebe as requisições dos clientes"),
                 ("Esconde o backend:", "o cliente só fala com o proxy"),
                 ("Balanceia carga:", "distribui o tráfego entre servidores"),
                 ("Protege e faz cache:", "absorve ataques e acelera respostas"),
             ],
             "fonte": "cloudflare.com"},
            {"type": "code", "kicker": "Mão na massa",
             "titulo": "Proxy Reverso com Nginx",
             "intro": "Redirecionar /app para um backend na porta 3000:",
             "code": [
                 "server {",
                 "    listen 80;",
                 "    server_name www.meusite.com;",
                 "",
                 "    location /app {",
                 "        proxy_pass http://localhost:3000;",
                 "        proxy_set_header Host $host;",
                 "    }",
                 "",
                 "    upstream servidores {",
                 "        server localhost:3000;",
                 "        server localhost:3001;",
                 "    }",
                 "}",
             ]},
            {"type": "content", "kicker": "DNS",
             "titulo": "DNS — O Catálogo Telefônico da Internet",
             "bullets": [
                 ("Traduz:", "www.google.com em um endereço IP"),
                 ("Sem DNS:", "você teria que decorar o IP de cada site!"),
                 ("DNS Autoritativo:", "tem a resposta final de um domínio"),
                 ("DNS Recursivo:", "busca e guarda a resposta em cache"),
                 ("Na nuvem:", "AWS usa Route 53; Azure usa Azure DNS"),
             ],
             "analogia": "O DNS é a agenda de contatos do celular: você salva 'Pizzaria do João' em vez do número. Sem a agenda, teria que decorar todos os telefones — ou todos os IPs!"},
            {"type": "image", "kicker": "DNS",
             "titulo": "Zona de DNS e Registros",
             "image": "dns_zona",
             "caption": "Painel de configuração de registros DNS de um domínio.",
             "fonte": "ayltoninacio.com.br"},
            {"type": "content", "kicker": "DNS",
             "titulo": "Tipos de Registros DNS",
             "bullets": [
                 ("Registro A:", "aponta o domínio para um IPv4"),
                 ("Registro AAAA:", "o mesmo, mas para IPv6"),
                 ("Registro MX:", "direciona os e-mails do domínio"),
                 ("Registro CNAME:", "apelido de um domínio para outro"),
                 ("Registro TXT:", "verificação de propriedade e SPF"),
             ],
             "analogia": "Se o DNS é a agenda, os registros são os tipos de contato: A = telefone fixo, AAAA = celular novo, MX = e-mail, CNAME = apelido. Um contato pode ter vários!"},
            {"type": "recap", "pontos": [
                "Proxy reverso protege, distribui carga e faz cache — o cliente nunca acessa o servidor direto.",
                "DNS converte nomes amigáveis em endereços IP.",
                "Registros: A (IPv4), AAAA (IPv6), MX (e-mail), CNAME (apelido), TXT (verificação).",
                "Nginx é o proxy reverso mais popular — simples e de alta performance.",
            ]},
        ],
    },

    # ─── AULA 5 ───────────────────────────────────────────────────────────────
    {
        "num": 5, "data": "Quarta, 19/08",
        "titulo": "CI/CD e Ciclo de Vida das Aplicações",
        "subtitulo": "Da ideia ao deploy automatizado com qualidade",
        "slides": [
            {"type": "content", "kicker": "Integração Contínua",
             "titulo": "CI — Integração Contínua",
             "bullets": [
                 ("Commits frequentes:", "pequenas mudanças várias vezes ao dia"),
                 ("Build automático:", "cada commit compila e gera artefatos"),
                 ("Testes automáticos:", "unitários, integração e regressão"),
                 ("Feedback rápido:", "erros detectados em minutos, não em dias"),
             ],
             "analogia": "CI é como cozinhar com um sous chef ao lado: a cada ingrediente ele prova e avisa. Colocou sal demais? Você descobre na hora — não na hora de servir o prato!"},
            {"type": "content", "kicker": "Entrega Contínua",
             "titulo": "CD — Entrega e Deploy Contínuos",
             "bullets": [
                 ("Entrega Contínua:", "código sempre pronto para produção"),
                 ("Deploy Contínuo:", "o que passa nos testes vai automático"),
                 ("Ambientes:", "Dev → QA → Staging → Produção"),
                 ("Estratégias:", "Blue-Green, Canary e Feature Toggles"),
             ],
             "analogia": "CD é a linha de montagem de carros: cada peça é testada antes de seguir. No fim, o carro sai da fábrica pronto para rodar, sem revisão manual a cada parafuso!"},
            {"type": "image", "kicker": "Pipeline",
             "titulo": "O Caminho do Código — Pipeline CI/CD",
             "image": "pipeline_cicd",
             "caption": "Commit → Build → Testes → Staging → Produção.",
             },
            {"type": "content", "kicker": "Ferramentas",
             "titulo": "Ferramentas Populares de CI/CD",
             "bullets": [
                 ("Jenkins:", "open source, flexível — o clássico do mercado"),
                 ("GitLab CI/CD:", "pipeline em YAML dentro do repositório"),
                 ("GitHub Actions:", "workflows automáticos direto no GitHub"),
                 ("Azure DevOps:", "pipelines, boards e repositórios integrados"),
                 ("ArgoCD:", "especialista em Kubernetes — GitOps"),
             ],
             "analogia": "São assistentes com perfis diferentes: Jenkins é o veterano que faz tudo, GitHub Actions é o moderno integrado ao código, e ArgoCD é o especialista em Kubernetes."},
            {"type": "content", "kicker": "ALM",
             "titulo": "Ciclo de Vida das Aplicações (ALM)",
             "bullets": [
                 ("Governança:", "requisitos, planejamento e priorização"),
                 ("Desenvolvimento:", "design, código, CI e testes"),
                 ("Operações:", "monitoramento, incidentes e atualizações"),
                 ("Metodologias:", "Waterfall, Agile e DevOps"),
             ],
             "analogia": "ALM é gerir uma cidade: planejamento urbano (governança), construção das casas (desenvolvimento) e manutenção de ruas e serviços (operações). Todas as fases importam!"},
            {"type": "recap", "pontos": [
                "CI = integrar e testar com frequência para achar problemas cedo.",
                "CD = manter o código pronto para produção e automatizar o deploy.",
                "Pipeline: commit → build → testes → staging → produção.",
                "ALM cobre todo o ciclo, do requisito ao monitoramento em produção.",
            ]},
        ],
    },

    # ─── AULA 6 ───────────────────────────────────────────────────────────────
    {
        "num": 6, "data": "Sexta, 21/08",
        "titulo": "Cloud Computing",
        "subtitulo": "IaaS, PaaS, SaaS e o poder da nuvem",
        "slides": [
            {"type": "comparison", "kicker": "Modelos",
             "titulo": "On-Premises vs Cloud",
             "a_title": "On-Premises",
             "a_items": [
                 "Servidores físicos na empresa",
                 "Alto investimento inicial",
                 "Você cuida de tudo: energia, manutenção",
                 "Capacidade fixa, difícil de escalar",
             ],
             "b_title": "Cloud Computing",
             "b_items": [
                 "Servidores na internet",
                 "Pague apenas pelo que usar",
                 "O provedor cuida da infraestrutura",
                 "Escala em minutos conforme a demanda",
             ]},
            {"type": "image", "kicker": "Modelos de serviço",
             "titulo": "IaaS, PaaS e SaaS — Responsabilidades",
             "image": "cloud_models",
             "caption": "Quanto mais alto o modelo, menos você gerencia.",
             "fonte": "learn.microsoft.com"},
            {"type": "content", "kicker": "Modelos de serviço",
             "titulo": "Entendendo IaaS, PaaS e SaaS",
             "bullets": [
                 ("IaaS:", "aluga servidores, rede e storage (AWS EC2, Azure VM)"),
                 ("PaaS:", "você entrega o código; o resto é do provedor (Heroku)"),
                 ("SaaS:", "software pronto pelo browser (Gmail, Office 365)"),
                 ("FaaS:", "paga só quando a função executa (AWS Lambda)"),
             ],
             "analogia": "IaaS = comprar terreno e construir. PaaS = alugar apartamento mobiliado. SaaS = hotel: você só usa, sem preocupação. Mais conforto, menos flexibilidade!"},
            {"type": "content", "kicker": "Implantação",
             "titulo": "Modelos de Implantação",
             "bullets": [
                 ("Nuvem Pública:", "recursos compartilhados (AWS, Azure, GCP)"),
                 ("Nuvem Privada:", "uso exclusivo de uma organização"),
                 ("Nuvem Híbrida:", "combina pública e privada"),
                 ("Multi-cloud:", "dois ou mais provedores ao mesmo tempo"),
             ],
             "analogia": "Nuvem pública é o transporte coletivo (barato e eficiente). Privada é o carro particular (controle total). Híbrida é ter carro, mas pegar o ônibus quando compensa."},
            {"type": "content", "kicker": "Vantagens",
             "titulo": "Benefícios da Cloud Computing",
             "bullets": [
                 ("Agilidade:", "provisione recursos em minutos"),
                 ("Elasticidade:", "escale para cima ou para baixo sob demanda"),
                 ("Economia:", "sem grande investimento inicial (pay-as-you-go)"),
                 ("Alcance global:", "implante em data centers pelo mundo"),
                 ("Segurança:", "provedores investem bilhões em proteção"),
             ],
             "analogia": "É como ligar e desligar a luz: você paga só pelas lâmpadas acesas. A nuvem faz isso com computação — use quando precisar e pague o que consumir."},
            {"type": "recap", "pontos": [
                "On-Premises: controle total, custo alto. Cloud: flexível, paga pelo uso.",
                "IaaS = infraestrutura, PaaS = plataforma, SaaS = software.",
                "Implantação: pública (compartilhada), privada (dedicada) e híbrida.",
                "Benefícios: agilidade, elasticidade, economia e alcance global.",
            ]},
        ],
    },

    # ─── AULA 7 ───────────────────────────────────────────────────────────────
    {
        "num": 7, "data": "Segunda, 24/08",
        "titulo": "Arquitetura de Dados e Data Warehouse",
        "subtitulo": "\"Dados são o novo petróleo\" — como organizá-los?",
        "slides": [
            {"type": "content", "kicker": "Fundamentos",
             "titulo": "Arquitetura de Dados — Por que Importa?",
             "bullets": [
                 ("\"Data is the new oil\":", "dados valem como petróleo (Clive Humby)"),
                 ("Armazenamento:", "tecnologias, políticas e retenção de dados"),
                 ("Processamento:", "dimensionar pipelines e infraestrutura"),
                 ("Disponibilização:", "levar o dado a quem precisa, quando precisa"),
                 ("Visualização:", "padronizar ferramentas de BI"),
             ],
             "analogia": "Dados sem arquitetura são uma biblioteca sem catalogação: milhares de livros, mas você nunca acha o que procura. A arquitetura é o sistema que dá valor ao acervo!"},
            {"type": "image", "kicker": "Ciclo de vida",
             "titulo": "O Ciclo de Vida do Dado",
             "image": "fluxo_cartao",
             "bullets": [
                 ("Produtores:", "sistemas que geram os dados"),
                 ("Ingestão:", "coleta e entrada no ambiente analítico"),
                 ("Processamento:", "limpar, enriquecer e modelar"),
                 ("Consumidores:", "dashboards, ML, relatórios e APIs"),
             ],
             "fonte": "do autor"},
            {"type": "content", "kicker": "Data Warehouse",
             "titulo": "O que é um Data Warehouse?",
             "bullets": [
                 ("Repositório central:", "dados estruturados, históricos e integrados"),
                 ("Analítico (OLAP):", "otimizado para consultas e relatórios"),
                 ("Diferente do OLTP:", "aqui o foco é análise, não transação"),
                 ("Fonte única:", "múltiplas origens unificadas de forma confiável"),
             ],
             "analogia": "O banco transacional é o caixa do supermercado (registra cada venda). O Data Warehouse é o escritório que consolida todas as vendas de todas as lojas para o diretor decidir!"},
            {"type": "image", "kicker": "Componentes",
             "titulo": "Componentes de um Data Warehouse",
             "image": "dw_representacao",
             "caption": "Fontes → ETL → camadas Raw e Summary → Data Marts → consumidores.",
             "fonte": "do autor"},
            {"type": "content", "kicker": "Processos",
             "titulo": "ETL e OLAP vs OLTP",
             "bullets": [
                 ("Extract:", "extrair os dados das fontes de origem"),
                 ("Transform:", "limpar, padronizar e agregar"),
                 ("Load:", "carregar e persistir no Data Warehouse"),
                 ("OLTP:", "transações rápidas (o app do dia a dia)"),
                 ("OLAP:", "consultas analíticas complexas (o DW)"),
             ],
             "analogia": "ETL é fazer suco: Extrair = colher a laranja; Transformar = espremer e adoçar; Carregar = servir no copo. O resultado é muito mais útil que a laranja crua!"},
            {"type": "recap", "pontos": [
                "Arquitetura de Dados organiza armazenamento, processamento, disponibilização e visualização.",
                "Data Warehouse: repositório central OLAP para análises e decisões.",
                "ETL: Extrair → Transformar → Carregar.",
                "Data Marts são visões especializadas do DW para cada área de negócio.",
            ]},
        ],
    },

    # ─── AULA 8 ───────────────────────────────────────────────────────────────
    {
        "num": 8, "data": "Quarta, 26/08",
        "titulo": "Data Lake",
        "subtitulo": "Big Data e arquiteturas de dados modernas",
        "slides": [
            {"type": "image", "kicker": "Conceito",
             "titulo": "O que é um Data Lake?",
             "image": "datalake_conceito",
             "bullets": [
                 ("Armazena tudo:", "dados estruturados, semi e não estruturados"),
                 ("Schema-on-read:", "o esquema é definido na leitura"),
                 ("Escala petabytes:", "logs, imagens, vídeos, JSON, CSV..."),
                 ("Habilita ML:", "análise exploratória e descoberta de dados"),
             ],
             "fonte": "solvimm.com"},
            {"type": "comparison", "kicker": "Comparação",
             "titulo": "Data Warehouse vs Data Lake",
             "a_title": "Data Warehouse",
             "a_items": [
                 "Dados relacionais estruturados",
                 "Schema-on-write (antes de gravar)",
                 "Alta qualidade, já tratados",
                 "Analistas de negócio, BI",
             ],
             "b_title": "Data Lake",
             "b_items": [
                 "Todos os tipos de dados",
                 "Schema-on-read (na leitura)",
                 "Dados brutos, maior variedade",
                 "Cientistas de dados, ML",
             ]},
            {"type": "image", "kicker": "Arquitetura",
             "titulo": "Arquitetura em Camadas do Data Lake",
             "image": "datalake_camadas",
             "caption": "Raw (bruto) → Staging (trabalho) → Curated (pronto para uso).",
             "fonte": "dwbi1.wordpress.com"},
            {"type": "content", "kicker": "Atenção",
             "titulo": "Cuidado com o Data Swamp! 🐊",
             "bullets": [
                 ("Data Swamp:", "um Data Lake abandonado e sem organização"),
                 ("Causa:", "dados sem catalogação, governança ou descarte"),
                 ("Resultado:", "ninguém sabe o que existe, custo alto, valor zero"),
                 ("Prevenção:", "metadados, controle de acesso e catalogação"),
                 ("LGPD:", "dados pessoais precisam de ciclo e criptografia"),
             ],
             "analogia": "Um lago sem manutenção vira pântano: lodo, água suja e impossível de navegar. Invista em governança (o jardineiro do lago) para mantê-lo navegável e valioso!"},
            {"type": "recap", "pontos": [
                "Data Lake armazena qualquer tipo de dado em escala — bruto e flexível.",
                "DW e Data Lake se complementam; use ambos conforme a necessidade.",
                "Cuidado com o Data Swamp: governança, metadados e LGPD são essenciais.",
                "Na nuvem: AWS S3, Azure Blob Storage e Google Cloud Storage.",
            ]},
        ],
    },

    # ─── AULA 9 ───────────────────────────────────────────────────────────────
    {
        "num": 9, "data": "Sexta, 28/08",
        "titulo": "Concluir Atividades e Preencher Rubricas",
        "subtitulo": "Encerramento do módulo, revisão geral e avaliação",
        "slides": [
            {"type": "content", "kicker": "Encerramento",
             "titulo": "Objetivos da Última Aula",
             "bullets": [
                 ("Concluir atividades:", "finalizar os exercícios pendentes do módulo"),
                 ("Revisão geral:", "amarrar todos os conceitos aprendidos"),
                 ("Tirar dúvidas:", "momento aberto para perguntas finais"),
                 ("Preencher rubricas:", "avaliação de aprendizado e feedback"),
             ],
             "analogia": "É a formatura do módulo: hora de revisar tudo o que construímos, entregar os últimos trabalhos e celebrar a jornada de aprendizado!"},
            {"type": "content", "kicker": "Revisão · Parte 1",
             "titulo": "O que Aprendemos — Infraestrutura",
             "bullets": [
                 ("Docker:", "empacota apps em containers portáveis"),
                 ("Servidores:", "aplicação, web, banco, proxy e cache"),
                 ("Apache e Nginx:", "servem e processam requisições web"),
                 ("Proxy Reverso e DNS:", "roteiam e protegem o tráfego"),
             ],
             "analogia": "Sua aplicação é uma cidade: Docker são os blocos de prédios, Nginx são as avenidas e o DNS é o GPS que leva todo mundo ao endereço certo."},
            {"type": "content", "kicker": "Revisão · Parte 2",
             "titulo": "O que Aprendemos — Entrega e Dados",
             "bullets": [
                 ("CI/CD:", "automatiza testes e entregas com qualidade"),
                 ("Cloud Computing:", "IaaS, PaaS, SaaS — escale sob demanda"),
                 ("Arquitetura de Dados:", "organiza o ciclo de vida do dado"),
                 ("Data Warehouse e Data Lake:", "armazenam e disponibilizam dados"),
             ],
             "analogia": "Se a infraestrutura é a cidade, os dados são a memória dela: o Data Warehouse é o arquivo histórico organizado e o Data Lake é o grande depósito de tudo que pode virar valor."},
            {"type": "content", "kicker": "Avaliação",
             "titulo": "Como Preencher as Rubricas",
             "bullets": [
                 ("Autoavaliação:", "reflita sobre o que aprendeu no módulo"),
                 ("Critérios:", "cada rubrica avalia uma competência específica"),
                 ("Honestidade:", "avalie com sinceridade para evoluir de verdade"),
                 ("Dúvidas:", "chame o instrutor sempre que precisar"),
             ],
             "analogia": "A rubrica é como o mapa de uma trilha: mostra o quanto você já caminhou e quais trechos ainda pode explorar melhor na sua jornada."},
            {"type": "recap", "pontos": [
                "Concluímos todas as atividades e exercícios do módulo.",
                "Revisamos infraestrutura (Docker, servidores, cloud) e dados (DW, Data Lake).",
                "As rubricas registram seu aprendizado e orientam os próximos passos.",
                "Parabéns! Você concluiu o módulo Arquitetura de Serviços e Dados! 🎉",
            ]},
            {"type": "closing", "msg": "Parabéns e obrigado!"},
        ],
    },
]


# =================================================================================
#  MONTAGEM
# =================================================================================

def build_aula(aula):
    num = aula["num"]
    titulo = aula["titulo"]
    prs = new_prs()

    build_capa(prs, num, titulo, aula["subtitulo"], aula["data"])
    build_cronograma(prs, num, titulo)
    build_combinado(prs, num, titulo)

    for sd in aula["slides"]:
        t = sd["type"]
        if t == "content":
            build_content(prs, num, titulo, sd["titulo"], sd["bullets"],
                          sd.get("analogia"), sd.get("kicker"))
        elif t == "image":
            build_image_slide(prs, num, titulo, sd["titulo"], sd["image"],
                              caption=sd.get("caption"), bullets=sd.get("bullets"),
                              kicker=sd.get("kicker"), fonte=sd.get("fonte"))
        elif t == "code":
            build_code(prs, num, titulo, sd["titulo"], sd.get("intro"),
                       sd["code"], sd.get("kicker"))
        elif t == "comparison":
            build_comparison(prs, num, titulo, sd["titulo"],
                             sd["a_title"], sd["a_items"],
                             sd["b_title"], sd["b_items"], sd.get("kicker"))
        elif t == "recap":
            build_recap(prs, num, titulo, sd["pontos"])
        elif t == "closing":
            build_closing(prs, num, titulo, sd.get("msg", "Obrigado!"))

    # nome de arquivo sem acentos
    import unicodedata
    safe = "".join(c for c in unicodedata.normalize("NFKD", titulo)
                   if ord(c) < 128).replace(" ", "_").replace("/", "-")
    out = os.path.join(OUT_DIR, f"Aula_{num:02d}_{safe}.pptx")
    prs.save(out)
    print(f"Saved: Aula_{num:02d}_{safe}.pptx  ({len(prs.slides.__iter__.__self__._sldIdLst)} slides)")
    return out


if __name__ == "__main__":
    print("Gerando apresentações (template Ada)...\n")
    for aula in AULAS:
        build_aula(aula)
    print("\nConcluído! 9 aulas geradas.")
