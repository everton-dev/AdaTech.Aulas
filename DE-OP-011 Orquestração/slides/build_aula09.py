# -*- coding: utf-8 -*-
"""
Aula_09_Helm_e_ArgoCD.pptx
Gera a apresentacao da Aula 09 seguindo a identidade visual da Ada
(mesmo padrao das Aulas 01-08): slide-titulo escuro + slides de conteudo
creme, barra superior em gradiente, logo ada no rodape, fontes Ubuntu/Lato.
"""
import os
from pptx import Presentation
from pptx.util import Emu, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn

# ── Paleta ─────────────────────────────────────────────────────────────────────
C_BG    = RGBColor(0x18, 0x1C, 0x23)   # fundo escuro (capa)
C_CREAM = RGBColor(0xFF, 0xFB, 0xF0)   # fundo dos slides de conteudo
C_GREEN = RGBColor(0x50, 0xE5, 0x50)   # verde Ada
C_BLUE  = RGBColor(0x23, 0x71, 0xFF)   # azul
C_WHITE = RGBColor(0xFF, 0xFD, 0xF8)
C_DARK  = RGBColor(0x18, 0x1C, 0x23)   # texto sobre creme
C_GRAY  = RGBColor(0x5A, 0x5E, 0x66)   # rodape
C_CARD  = RGBColor(0xFF, 0xFF, 0xFF)   # cartoes claros
C_CARDD = RGBColor(0x2A, 0x2F, 0x3A)   # cartoes escuros
C_INK   = RGBColor(0x3A, 0x40, 0x4A)   # texto secundario

# Paleta do bloco de codigo (tema escuro estilo VS Code)
CODE_BG      = RGBColor(0x1E, 0x23, 0x2E)
CODE_BAR     = RGBColor(0x2A, 0x30, 0x3D)
CODE_DEF     = RGBColor(0xD4, 0xD8, 0xE0)   # texto padrao
CODE_COMMENT = RGBColor(0x7C, 0xA8, 0x6A)   # comentarios (verde)
CODE_KEY     = RGBColor(0x8C, 0xC8, 0xFF)   # chaves YAML (azul claro)
CODE_STR     = RGBColor(0xE0, 0xA1, 0x7A)   # strings (laranja)
CODE_NUM     = RGBColor(0xB5, 0xCE, 0xA8)   # numeros / booleanos (verde claro)
CODE_TPL     = RGBColor(0xE5, 0xC0, 0x7B)   # templates Helm {{ }} (amarelo)
CODE_PUNC    = RGBColor(0x9A, 0xA0, 0xAA)   # pontuacao / glyphs
CODE_FONT    = "Consolas"

# EMUs
IN = 914400
SW, SH = 9144000, 5143500  # 10 x 5.625 in (16:9)

DIR    = os.path.dirname(os.path.abspath(__file__))
IMG    = os.path.join(DIR, "images")
TOPBAR = os.path.join(IMG, "_topbar.png")
ADA    = os.path.join(IMG, "_ada_logo.png")
SWIRL  = os.path.join(IMG, "_swirl_green.png")
DIAG   = os.path.join(IMG, "helm_argocd.png")
LOGOS  = os.path.join(DIR, "logos")
L_HELM = os.path.join(LOGOS, "Helm.png")
L_ARGO = os.path.join(LOGOS, "ArgoCD.png")
L_GIT  = os.path.join(LOGOS, "Git.png")
L_K8S  = os.path.join(LOGOS, "Kubernetes.png")

FOOTER = "Ada • DE-OP-011 Orquestração • Kubernetes  |  Aula 09  |  Everton J Benedicto"

# ── Helpers ─────────────────────────────────────────────────────────────────────

def inch(v):
    return int(v * IN)


def set_bg(slide, color):
    xml = (
        '<p:bg xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" '
        'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        '<p:bgPr><a:solidFill><a:srgbClr val="%02X%02X%02X"/></a:solidFill>'
        '<a:effectLst/></p:bgPr></p:bg>' % (color[0], color[1], color[2])
    )
    from lxml import etree
    bg = etree.fromstring(xml)
    csld = slide._element.find(qn('p:cSld'))
    csld.insert(0, bg)


def shape(slide, kind, x, y, w, h, fill=None, line=None, line_w=None):
    s = slide.shapes.add_shape(kind, inch(x), inch(y), inch(w), inch(h))
    if fill is not None:
        s.fill.solid(); s.fill.fore_color.rgb = fill
    else:
        s.fill.background()
    if line is not None:
        s.line.color.rgb = line
        if line_w:
            s.line.width = Pt(line_w)
    else:
        s.line.fill.background()
    s.shadow.inherit = False
    return s


def rect(slide, x, y, w, h, fill=None, line=None, line_w=None):
    return shape(slide, MSO_SHAPE.RECTANGLE, x, y, w, h, fill, line, line_w)


def rrect(slide, x, y, w, h, fill=None, line=None, line_w=None, radius=0.08):
    s = shape(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, y, w, h, fill, line, line_w)
    try:
        s.adjustments[0] = radius
    except Exception:
        pass
    return s


def oval(slide, x, y, w, h, fill=None, line=None, line_w=None):
    return shape(slide, MSO_SHAPE.OVAL, x, y, w, h, fill, line, line_w)


def chevron(slide, x, y, w, h, fill):
    return shape(slide, MSO_SHAPE.CHEVRON, x, y, w, h, fill)


def txt(slide, x, y, w, h, runs, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP,
        space_after=4, line_spacing=None, wrap=True):
    """runs: list of paragraphs; each paragraph is list of (text, font, size, bold, color) tuples."""
    box = slide.shapes.add_textbox(inch(x), inch(y), inch(w), inch(h))
    tf = box.text_frame
    tf.word_wrap = wrap
    tf.vertical_anchor = anchor
    tf.margin_left = 0; tf.margin_right = 0
    tf.margin_top = 0; tf.margin_bottom = 0
    for i, para in enumerate(runs):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        p.space_after = Pt(space_after)
        p.space_before = Pt(0)
        if line_spacing:
            p.line_spacing = line_spacing
        for (t, font, size, bold, color) in para:
            r = p.add_run(); r.text = t
            r.font.name = font; r.font.size = Pt(size); r.font.bold = bold
            r.font.color.rgb = color
    return box


def R(t, font="Lato", size=15, bold=False, color=C_DARK):
    return (t, font, size, bold, color)


def pic(slide, path, x, y, w=None, h=None):
    kw = {}
    if w: kw['width'] = inch(w)
    if h: kw['height'] = inch(h)
    return slide.shapes.add_picture(path, inch(x), inch(y), **kw)


def blank(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def content_base(prs, title, footer=True, bar_full=True):
    """Slide de conteudo padrao: fundo creme, barra topo, titulo, underline verde, logo."""
    s = blank(prs)
    set_bg(s, C_CREAM)
    # barra superior em gradiente
    if bar_full:
        pic(s, TOPBAR, 0, 0, w=10.0, h=0.13)
    # titulo
    txt(s, 0.40, 0.28, 9.20, 0.75, [[R(title, "Ubuntu", 23, True, C_DARK)]],
        anchor=MSO_ANCHOR.MIDDLE)
    # underline verde
    rect(s, 0.42, 1.02, 0.70, 0.05, fill=C_GREEN)
    # rodape
    if footer:
        txt(s, 0.35, 5.28, 8.20, 0.23, [[R(FOOTER, "Lato", 7.5, False, C_GRAY)]])
        pic(s, ADA, 8.85, 5.00, w=0.95, h=0.59)
    return s


# ── Code block (tema escuro estilo VS Code, com realce de YAML) ──────────────────
import re

_TPL_RE = re.compile(r"(\{\{.*?\}\})")


def _yaml_segments(line):
    """Divide uma linha YAML em segmentos coloridos -> lista de (texto, cor)."""
    out = []
    # comentario de linha inteira ou apos codigo
    # primeiro, separa comentario (fora de aspas simples/duplas)
    comment = None
    in_s = in_d = False
    for i, ch in enumerate(line):
        if ch == "'" and not in_d:
            in_s = not in_s
        elif ch == '"' and not in_s:
            in_d = not in_d
        elif ch == "#" and not in_s and not in_d:
            comment = line[i:]
            line = line[:i]
            break

    stripped = line.lstrip()
    indent = line[:len(line) - len(stripped)]
    if indent:
        out.append((indent, CODE_DEF))

    def emit_value(val):
        # colore templates Helm, strings, numeros/bool dentro do valor
        parts = _TPL_RE.split(val)
        for part in parts:
            if not part:
                continue
            if part.startswith("{{"):
                out.append((part, CODE_TPL))
            elif re.match(r'^\s*".*"\s*$|^\s*\'.*\'\s*$', part):
                out.append((part, CODE_STR))
            elif re.match(r"^\s*(true|false|\d+(\.\d+)?)\s*$", part):
                out.append((part, CODE_NUM))
            else:
                # pode conter aspas parciais
                if '"' in part or "'" in part:
                    out.append((part, CODE_STR))
                else:
                    out.append((part, CODE_DEF))

    if stripped.startswith("- "):
        out.append(("- ", CODE_PUNC))
        rest = stripped[2:]
        m = re.match(r"^([A-Za-z0-9_.\-/]+):(\s*)(.*)$", rest)
        if m:
            out.append((m.group(1), CODE_KEY))
            out.append((":" + m.group(2), CODE_PUNC))
            emit_value(m.group(3))
        else:
            emit_value(rest)
    else:
        m = re.match(r"^([A-Za-z0-9_.\-/]+):(\s*)(.*)$", stripped)
        if m:
            out.append((m.group(1), CODE_KEY))
            out.append((":" + m.group(2), CODE_PUNC))
            emit_value(m.group(3))
        else:
            emit_value(stripped)

    if comment is not None:
        out.append((comment, CODE_COMMENT))
    if not out:
        out.append((" ", CODE_DEF))
    return out


def code_block(slide, x, y, w, h, code, title="", fsz=10.5, lang="yaml", line_spacing=1.02):
    """Desenha um bloco de codigo com barra de titulo estilo editor."""
    bar_h = 0.28
    rrect(slide, x, y, w, h, fill=CODE_BG, radius=0.045)
    # barra de titulo
    bar = rrect(slide, x, y, w, bar_h, fill=CODE_BAR, radius=0.045)
    # tres bolinhas (semaforo)
    dot_y = y + bar_h / 2 - 0.035
    for i, col in enumerate([RGBColor(0xFF,0x5F,0x56), RGBColor(0xFF,0xBD,0x2E), RGBColor(0x27,0xC9,0x3F)]):
        oval(slide, x + 0.14 + i * 0.16, dot_y, 0.07, 0.07, fill=col)
    if title:
        txt(slide, x + 0.62, y, w - 1.0, bar_h,
            [[R(title, CODE_FONT, 9, False, RGBColor(0xB9,0xBE,0xC7))]],
            anchor=MSO_ANCHOR.MIDDLE)
    # corpo
    lines = code.split("\n")
    paras = [_yaml_segments(ln) if lang == "yaml" else [(ln or " ", CODE_DEF)] for ln in lines]
    runs = [[(t, CODE_FONT, fsz, False, c) for (t, c) in seg] for seg in paras]
    box = slide.shapes.add_textbox(inch(x + 0.18), inch(y + bar_h + 0.06),
                                   inch(w - 0.34), inch(h - bar_h - 0.12))
    tf = box.text_frame
    tf.word_wrap = False
    tf.margin_left = 0; tf.margin_right = 0; tf.margin_top = 0; tf.margin_bottom = 0
    for i, seg in enumerate(runs):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = PP_ALIGN.LEFT
        p.space_after = Pt(0); p.space_before = Pt(0)
        p.line_spacing = line_spacing
        for (t, font, size, bold, color) in seg:
            r = p.add_run(); r.text = t
            r.font.name = font; r.font.size = Pt(size); r.font.bold = bold
            r.font.color.rgb = color
    return box


# ════════════════════════════════════════════════════════════════════════════════
prs = Presentation()
prs.slide_width  = Emu(SW)
prs.slide_height = Emu(SH)

# ── SLIDE 1 · CAPA ──────────────────────────────────────────────────────────────
s = blank(prs)
set_bg(s, C_BG)
# marca d'agua verde (swirl) no canto direito
pic(s, SWIRL, 6.30, 1.05, w=4.20, h=2.60)
# barras topo e base
pic(s, TOPBAR, 0, 0, w=10.0, h=0.16)
pic(s, TOPBAR, 0, 5.46, w=10.0, h=0.16)
# barra vertical verde
rect(s, 0.60, 1.78, 0.16, 1.85, fill=C_GREEN)
# titulo
txt(s, 0.95, 1.55, 7.60, 1.30,
    [[R("Helm e ArgoCD", "Ubuntu", 40, True, C_WHITE)]],
    anchor=MSO_ANCHOR.TOP)
txt(s, 0.95, 2.55, 7.80, 0.90,
    [[R("Guia simples e didático para iniciantes", "Lato", 17, False, C_GREEN)]])
txt(s, 0.97, 3.20, 7.80, 0.70,
    [[R("Empacotando e implantando aplicações no Kubernetes "
        "com GitOps", "Lato", 12, False, RGBColor(0xC9, 0xCD, 0xD4))]])
# rodape capa
txt(s, 0.95, 4.75, 8.00, 0.50,
    [[R("Ada • DE-OP-011 Orquestração • Kubernetes  |  Aula 09",
        "Lato", 11, False, C_WHITE)]])
pic(s, ADA, 8.70, 4.55, w=0.95, h=0.59)

# ── SLIDE 2 · OBJETIVOS ──────────────────────────────────────────────────────────
s = content_base(prs, "Objetivos de hoje")
objetivos = [
    "Entender por que gerenciar YAML “na mão” não escala",
    "Conhecer o Helm como gerenciador de pacotes do Kubernetes",
    "Dominar os conceitos de Chart, Templates/Values e Releases",
    "Compreender o que é GitOps e o papel do ArgoCD",
    "Ver como o ArgoCD sincroniza o cluster com o repositorio Git",
    "Entender como Helm e ArgoCD se complementam no fluxo de deploy",
]
paras = []
for o in objetivos:
    paras.append([R("✓  ", "Lato", 15, True, C_GREEN), R(o, "Lato", 15, False, C_DARK)])
txt(s, 0.55, 1.30, 9.00, 3.80, paras, space_after=11, line_spacing=1.0)

# ── SLIDE 3 · O PROBLEMA ─────────────────────────────────────────────────────────
s = content_base(prs, "O problema: YAML “na mão” não escala")
txt(s, 0.55, 1.25, 9.00, 0.80,
    [[R("Uma aplicação no Kubernetes precisa de vários arquivos YAML "
        "(Deployment, Service, ConfigMap, Ingress...).", "Lato", 15, False, C_DARK)]],
    line_spacing=1.05)
dores = [
    ("Duplicidade", "Os mesmos valores repetidos em dezenas de arquivos separados."),
    ("Erros manuais", "Editar YAML à mão em cada ambiente é propenso a falhas."),
    ("Sem histórico", "Difícil saber o que mudou e voltar atrás quando algo quebra."),
    ("Configuration Drift", "O cluster “ao vivo” fica diferente do que está versionado."),
]
cw, gap = 4.35, 0.30
x0, y0 = 0.55, 2.15
for i, (t, d) in enumerate(dores):
    cx = x0 + (i % 2) * (cw + gap)
    cy = y0 + (i // 2) * (1.25 + 0.22)
    rrect(s, cx, cy, cw, 1.25, fill=C_CARD, line=RGBColor(0xE3,0xE0,0xD5), line_w=0.75, radius=0.10)
    rect(s, cx, cy + 0.16, 0.09, 0.93, fill=C_BLUE)
    txt(s, cx + 0.28, cy + 0.16, cw - 0.45, 0.40, [[R(t, "Ubuntu", 13, True, C_DARK)]])
    txt(s, cx + 0.28, cy + 0.58, cw - 0.45, 0.60, [[R(d, "Lato", 11, False, C_INK)]],
        line_spacing=1.0)

# ── SLIDE 4 · FLUXO INTEGRADO ────────────────────────────────────────────────────
s = content_base(prs, "Fluxo de trabalho integrado")
txt(s, 0.55, 1.20, 9.00, 0.45,
    [[R("Do empacotamento à aplicação rodando no cluster — em quatro etapas:",
        "Lato", 14, False, C_INK)]])
etapas = [
    ("1", "HELM", "Empacota os\narquivos YAML", C_BLUE),
    ("2", "GIT", "Guarda o código e\nas configurações", C_DARK),
    ("3", "ARGOCD", "Detecta e\nsincroniza", C_GREEN),
    ("4", "KUBERNETES", "Recebe a app\natualizada", C_BLUE),
]
bw, bh = 1.95, 1.55
bgap = 0.28
total = 4 * bw + 3 * bgap
bx0 = (10.0 - total) / 2
by = 2.35
for i, (n, tit, desc, col) in enumerate(etapas):
    cx = bx0 + i * (bw + bgap)
    card = rrect(s, cx, by, bw, bh, fill=C_CARD, line=col, line_w=1.5, radius=0.09)
    # badge numero
    oval(s, cx + bw/2 - 0.22, by - 0.22, 0.44, 0.44, fill=col)
    tcol = C_DARK if col == C_GREEN else C_WHITE
    txt(s, cx + bw/2 - 0.22, by - 0.17, 0.44, 0.36, [[R(n, "Ubuntu", 15, True, tcol)]],
        align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    txt(s, cx + 0.10, by + 0.34, bw - 0.20, 0.40, [[R(tit, "Ubuntu", 15, True, col)]],
        align=PP_ALIGN.CENTER)
    dparas = [[R(line, "Lato", 10.5, False, C_INK)] for line in desc.split("\n")]
    txt(s, cx + 0.12, by + 0.78, bw - 0.24, 0.65, dparas,
        align=PP_ALIGN.CENTER, space_after=1, line_spacing=1.0)
    # seta
    if i < 3:
        ax = cx + bw + 0.01
        chevron(s, ax, by + bh/2 - 0.14, bgap - 0.02, 0.28, fill=C_GREEN)

# ── SLIDE 5 · O QUE E O HELM ─────────────────────────────────────────────────────
s = content_base(prs, "1. O que é o Helm?")
txt(s, 0.55, 1.20, 9.00, 0.45,
    [[R("O gerenciador de pacotes do Kubernetes", "Ubuntu", 15, True, C_BLUE)]])
txt(s, 0.55, 1.72, 5.35, 2.30,
    [
        [R("Pense no Helm como uma ", "Lato", 14, False, C_DARK),
         R("“App Store”", "Lato", 14, True, C_DARK),
         R(" do Kubernetes.", "Lato", 14, False, C_DARK)],
        [R("Ele funciona como o ", "Lato", 14, False, C_DARK),
         R("apt", "Lato", 14, True, C_BLUE), R(" no Linux, o ", "Lato", 14, False, C_DARK),
         R("pip", "Lato", 14, True, C_BLUE), R(" no Python ou o ", "Lato", 14, False, C_DARK),
         R("npm", "Lato", 14, True, C_BLUE), R(" no Node.js.", "Lato", 14, False, C_DARK)],
        [R("Em vez de gerenciar dezenas de arquivos soltos, o Helm agrupa "
           "tudo em um único pacote: o ", "Lato", 14, False, C_DARK),
         R("Helm Chart", "Lato", 14, True, C_GREEN), R(".", "Lato", 14, False, C_DARK)],
    ], space_after=9, line_spacing=1.05)
# caixa analogia
ax, ay, aw, ah = 6.15, 1.72, 3.35, 2.75
rrect(s, ax, ay, aw, ah, fill=RGBColor(0xEF,0xFA,0xEB), line=C_GREEN, line_w=1.25, radius=0.08)
txt(s, ax + 0.22, ay + 0.18, aw - 0.44, 0.40,
    [[R("\U0001F4A1 Analogia", "Ubuntu", 13, True, C_DARK)]])
txt(s, ax + 0.22, ay + 0.62, aw - 0.44, ah - 0.80,
    [
        [R("O Helm é como uma ", "Lato", 12, False, C_INK),
         R("receita de bolo adaptável", "Lato", 12, True, C_DARK),
         R(".", "Lato", 12, False, C_INK)],
        [R("A estrutura já está pronta; você muda apenas a quantidade de "
           "açúcar ou o sabor do recheio no arquivo de valores — sem "
           "reescrever o modo de preparo.", "Lato", 12, False, C_INK)],
    ], space_after=8, line_spacing=1.08)

# ── SLIDE 6 · CONCEITOS-CHAVE DO HELM ────────────────────────────────────────────
s = content_base(prs, "Conceitos-chave do Helm")
conceitos = [
    ("Helm Chart", "Uma coleção de arquivos de configuração pré-montados "
     "do Kubernetes. Use charts prontos da comunidade ou crie os seus.", C_BLUE),
    ("Templates & Values", "Em vez de dados fixos, o Helm usa variáveis. "
     "Você ajusta senhas, portas ou memória no arquivo values.yaml "
     "sem mexer no código principal.", C_GREEN),
    ("Releases", "Cada instalação ou alteração gera um histórico de "
     "versões. Se algo der errado, um único comando faz o rollback "
     "para a versão anterior.", C_BLUE),
]
y = 1.35
for i, (t, d, col) in enumerate(conceitos):
    ch = 1.10
    cy = y + i * (ch + 0.18)
    rrect(s, 0.55, cy, 8.90, ch, fill=C_CARD, line=RGBColor(0xE3,0xE0,0xD5), line_w=0.75, radius=0.07)
    rect(s, 0.55, cy, 0.11, ch, fill=col)
    oval(s, 0.85, cy + ch/2 - 0.28, 0.56, 0.56, fill=col)
    tcol = C_DARK if col == C_GREEN else C_WHITE
    txt(s, 0.85, cy + ch/2 - 0.24, 0.56, 0.48, [[R(str(i+1), "Ubuntu", 20, True, tcol)]],
        align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    txt(s, 1.62, cy + 0.16, 7.70, 0.40, [[R(t, "Ubuntu", 15, True, C_DARK)]])
    txt(s, 1.62, cy + 0.56, 7.70, 0.50, [[R(d, "Lato", 12, False, C_INK)]], line_spacing=1.0)

# ── SLIDE 7 · O QUE E O ARGOCD ───────────────────────────────────────────────────
s = content_base(prs, "2. O que é o ArgoCD?")
txt(s, 0.55, 1.20, 9.00, 0.45,
    [[R("A automação de implantação com GitOps", "Ubuntu", 15, True, C_BLUE)]])
txt(s, 0.55, 1.72, 5.35, 2.60,
    [
        [R("Enquanto o Helm ", "Lato", 14, False, C_DARK),
         R("empacota", "Lato", 14, True, C_DARK),
         R(" a aplicação, o ArgoCD ", "Lato", 14, False, C_DARK),
         R("automatiza", "Lato", 14, True, C_DARK),
         R(" a forma como ela é publicada no cluster.", "Lato", 14, False, C_DARK)],
        [R("GitOps", "Lato", 14, True, C_GREEN),
         R(" é usar um repositório Git como a ", "Lato", 14, False, C_DARK),
         R("única fonte da verdade", "Lato", 14, True, C_DARK),
         R(". Mudou o Git → o cluster é atualizado automaticamente.",
           "Lato", 14, False, C_DARK)],
        [R("Isso elimina o ", "Lato", 14, False, C_DARK),
         R("Configuration Drift", "Lato", 14, True, C_BLUE),
         R(": o cluster nunca fica diferente do que está versionado.",
           "Lato", 14, False, C_DARK)],
    ], space_after=9, line_spacing=1.05)
# caixa analogia
ax, ay, aw, ah = 6.15, 1.72, 3.35, 2.75
rrect(s, ax, ay, aw, ah, fill=RGBColor(0xEF,0xFA,0xEB), line=C_GREEN, line_w=1.25, radius=0.08)
txt(s, ax + 0.22, ay + 0.18, aw - 0.44, 0.40,
    [[R("\U0001F4A1 Analogia", "Ubuntu", 13, True, C_DARK)]])
txt(s, ax + 0.22, ay + 0.62, aw - 0.44, ah - 0.80,
    [
        [R("O ArgoCD é como o ", "Lato", 12, False, C_INK),
         R("piloto automático", "Lato", 12, True, C_DARK),
         R(" de um avião.", "Lato", 12, False, C_INK)],
        [R("Ele confere o mapa planejado (", "Lato", 12, False, C_INK),
         R("Git", "Lato", 12, True, C_GREEN),
         R(") e ajusta o manche (", "Lato", 12, False, C_INK),
         R("Kubernetes", "Lato", 12, True, C_BLUE),
         R(") continuamente, garantindo que a rota real seja igual à planejada.",
           "Lato", 12, False, C_INK)],
    ], space_after=8, line_spacing=1.08)

# ── SLIDE 8 · COMO O ARGOCD FUNCIONA ─────────────────────────────────────────────
s = content_base(prs, "Como o ArgoCD funciona")
passos = [
    ("Monitora o Git", "Fica vigiando o repositório continuamente, "
     "observando o estado desejado da aplicação.", "\U0001F441"),
    ("Detecta diferenças", "Ao mudar um arquivo no Git, percebe que o "
     "cluster está desatualizado (Out of Sync).", "⚠"),
    ("Sincroniza sozinho", "Puxa a nova versão do Git e atualiza o "
     "Kubernetes sem intervenção manual.", "\U0001F504"),
]
bw, bh = 2.85, 2.55
gap = (10.0 - 1.10 - 3 * bw) / 2
x0 = 0.55
by = 1.55
for i, (t, d, ico) in enumerate(passos):
    cx = x0 + i * (bw + gap)
    rrect(s, cx, by, bw, bh, fill=C_CARD, line=RGBColor(0xE3,0xE0,0xD5), line_w=0.75, radius=0.07)
    rect(s, cx, by, bw, 0.14, fill=C_GREEN if i == 2 else C_BLUE)
    oval(s, cx + bw/2 - 0.42, by + 0.34, 0.84, 0.84, fill=RGBColor(0xEF,0xF3,0xFF))
    txt(s, cx + bw/2 - 0.42, by + 0.40, 0.84, 0.72, [[R(ico, "Segoe UI Emoji", 26, False, C_BLUE)]],
        align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    txt(s, cx + 0.20, by + 1.35, bw - 0.40, 0.45,
        [[R("%d. %s" % (i+1, t), "Ubuntu", 14, True, C_DARK)]], align=PP_ALIGN.CENTER)
    txt(s, cx + 0.24, by + 1.82, bw - 0.48, 0.65, [[R(d, "Lato", 11.5, False, C_INK)]],
        align=PP_ALIGN.CENTER, line_spacing=1.05)
    if i < 2:
        chevron(s, cx + bw + 0.02, by + bh/2 - 0.13, gap - 0.04, 0.26, fill=C_GREEN)

# ── SLIDE 9 · TRABALHANDO JUNTOS (com diagrama) ─────────────────────────────────
s = content_base(prs, "3. Como Helm e ArgoCD trabalham juntos")
txt(s, 0.55, 1.18, 9.00, 0.70,
    [
        [R("O Helm ", "Lato", 13, True, C_BLUE),
         R("organiza e cria o pacote flexível; o ", "Lato", 13, False, C_DARK),
         R("ArgoCD ", "Lato", 13, True, C_GREEN),
         R("lê esse pacote no Git e mantém o Kubernetes sempre atualizado.",
           "Lato", 13, False, C_DARK)],
    ], line_spacing=1.05)
# diagrama centralizado (mantendo proporcao 815x376)
dw = 6.95
dh = dw * 376 / 815
dx = (10.0 - dw) / 2
dy = 1.78
pic(s, DIAG, dx, dy, w=dw, h=dh)
txt(s, 0.55, dy + dh + 0.05, 9.00, 0.30,
    [[R("Fonte da imagem: fluxo GitOps — Source Code → CI → Registry / "
        "Deployment Repo → ArgoCD → Kubernetes", "Lato", 9, False, C_GRAY)]],
    align=PP_ALIGN.CENTER)

# ── SLIDE 10 · TABELA COMPARATIVA ────────────────────────────────────────────────
s = content_base(prs, "Helm x ArgoCD: papéis que se completam")
# cabecalho
cols = [("", 2.05, C_DARK), ("Helm", 3.55, C_BLUE), ("ArgoCD", 3.30, C_GREEN)]
rows = [
    ("Objetivo principal", "Gerenciar e parametrizar\npacotes da aplicação",
     "Implantação contínua e\nsincronização GitOps"),
    ("Analogia didática", "O livro de receitas\nempacotado",
     "O robô cozinheiro que\nsegue a receita"),
    ("Atua principalmente", "Antes do deploy\n(empacotamento)",
     "Durante e após o deploy\n(sincronização contínua)"),
]
tx = 0.55
ty = 1.35
rh = 0.92
hh = 0.52
# header row
xoff = tx
for name, cwid, col in cols:
    if name:
        rrect(s, xoff, ty, cwid - 0.08, hh, fill=col, radius=0.10)
        tcol = C_DARK if col == C_GREEN else C_WHITE
        txt(s, xoff, ty, cwid - 0.08, hh, [[R(name, "Ubuntu", 15, True, tcol)]],
            align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    xoff += cwid
# data rows
for ri, (label, helm, argo) in enumerate(rows):
    ry = ty + hh + 0.12 + ri * (rh + 0.10)
    xoff = tx
    vals = [label, helm, argo]
    for ci, (name, cwid, col) in enumerate(cols):
        cell = rrect(s, xoff, ry, cwid - 0.08, rh, fill=C_CARD,
                     line=RGBColor(0xE3,0xE0,0xD5), line_w=0.75, radius=0.06)
        if ci == 0:
            rect(s, xoff, ry, 0.09, rh, fill=C_GREEN)
            txt(s, xoff + 0.22, ry, cwid - 0.35, rh,
                [[R(vals[ci], "Ubuntu", 12, True, C_DARK)]],
                anchor=MSO_ANCHOR.MIDDLE, line_spacing=1.0)
        else:
            dparas = [[R(line, "Lato", 12, False, C_INK)] for line in vals[ci].split("\n")]
            txt(s, xoff + 0.18, ry, cwid - 0.34, rh, dparas,
                anchor=MSO_ANCHOR.MIDDLE, align=PP_ALIGN.CENTER,
                space_after=1, line_spacing=1.0)
        xoff += cwid

# ════════════════════════════════════════════════════════════════════════════════
#  BLOCO DE EXEMPLOS PRATICOS
# ════════════════════════════════════════════════════════════════════════════════

# ── SLIDE 11 · MAOS A OBRA (divisor / intro dos exemplos) ────────────────────────
s = blank(prs)
set_bg(s, C_BG)
pic(s, SWIRL, 6.30, 1.05, w=4.20, h=2.60)
pic(s, TOPBAR, 0, 0, w=10.0, h=0.16)
pic(s, TOPBAR, 0, 5.46, w=10.0, h=0.16)
rect(s, 0.60, 1.55, 0.16, 2.55, fill=C_GREEN)
txt(s, 0.95, 1.35, 7.30, 0.55, [[R("MÃOS À OBRA", "Lato", 13, True, C_GREEN)]])
txt(s, 0.95, 1.78, 7.60, 1.05,
    [[R("Exemplo prático", "Ubuntu", 36, True, C_WHITE)]])
txt(s, 0.97, 2.78, 7.40, 1.35,
    [
        [R("Vamos estruturar um repositório GitOps de verdade:",
           "Lato", 14, False, RGBColor(0xC9,0xCD,0xD4))],
        [R("• o ", "Lato", 13.5, False, RGBColor(0xC9,0xCD,0xD4)),
         R("Chart do Helm", "Lato", 13.5, True, C_GREEN),
         R("  (a receita da aplicação)", "Lato", 13.5, False, RGBColor(0xC9,0xCD,0xD4))],
        [R("• o ", "Lato", 13.5, False, RGBColor(0xC9,0xCD,0xD4)),
         R("Application do ArgoCD", "Lato", 13.5, True, C_GREEN),
         R("  (o piloto automático)", "Lato", 13.5, False, RGBColor(0xC9,0xCD,0xD4))],
    ], space_after=8, line_spacing=1.1)
pic(s, L_HELM, 8.15, 4.05, w=0.78, h=0.78)
pic(s, L_ARGO, 9.05, 4.02, w=0.82, h=0.82)

# ── SLIDE 12 · ESTRUTURA DO REPOSITORIO (arvore) ─────────────────────────────────
s = content_base(prs, "1. Organizando a estrutura no Git")
txt(s, 0.55, 1.18, 9.00, 0.55,
    [[R("Boa prática GitOps: separe os ", "Lato", 13, False, C_DARK),
      R("Charts do Helm", "Lato", 13, True, C_BLUE),
      R(" das ", "Lato", 13, False, C_DARK),
      R("configurações do ArgoCD", "Lato", 13, True, C_GREEN),
      R(".", "Lato", 13, False, C_DARK)]], line_spacing=1.0)

# arvore de diretorios como code block
tree = (
    "meu-projeto-gitops/\n"
    "│\n"
    "├── helm/                       # A \"receita\" da aplicação\n"
    "│   └── minha-app/\n"
    "│       ├── Chart.yaml          # Metadados do Chart (nome, versão)\n"
    "│       ├── values.yaml         # Valores padrão da aplicação\n"
    "│       └── templates/          # Modelos de arquivos Kubernetes\n"
    "│           ├── deployment.yaml # Como a aplicação vai rodar\n"
    "│           └── service.yaml    # Como é exposta na rede\n"
    "│\n"
    "└── argocd/                     # O \"piloto automático\"\n"
    "    └── application.yaml        # O que o ArgoCD deve sincronizar"
)
# render tree with custom coloring (glyphs cinza, pastas azul, comentarios verde)
def _tree_segments(line):
    out = []
    m = re.match(r"^([│├└─\s]*)(.*)$", line)
    prefix, rest = m.group(1), m.group(2)
    if prefix:
        out.append((prefix, CODE_PUNC))
    comment = None
    if "#" in rest:
        idx = rest.index("#")
        comment = rest[idx:]
        rest = rest[:idx]
    if rest:
        col = CODE_KEY if rest.rstrip().endswith("/") else CODE_DEF
        out.append((rest, col))
    if comment:
        out.append((comment, CODE_COMMENT))
    if not out:
        out.append((" ", CODE_DEF))
    return out

tx0, ty0, tw0, th0 = 0.85, 1.80, 8.30, 3.15
rrect(s, tx0, ty0, tw0, th0, fill=CODE_BG, radius=0.04)
bar_h = 0.28
rrect(s, tx0, ty0, tw0, bar_h, fill=CODE_BAR, radius=0.04)
for i, col in enumerate([RGBColor(0xFF,0x5F,0x56), RGBColor(0xFF,0xBD,0x2E), RGBColor(0x27,0xC9,0x3F)]):
    oval(s, tx0 + 0.14 + i * 0.16, ty0 + bar_h/2 - 0.035, 0.07, 0.07, fill=col)
txt(s, tx0 + 0.62, ty0, tw0 - 1.0, bar_h,
    [[R("estrutura do repositório", CODE_FONT, 9, False, RGBColor(0xB9,0xBE,0xC7))]],
    anchor=MSO_ANCHOR.MIDDLE)
tbox = s.shapes.add_textbox(inch(tx0 + 0.20), inch(ty0 + bar_h + 0.08),
                            inch(tw0 - 0.36), inch(th0 - bar_h - 0.14))
tf = tbox.text_frame; tf.word_wrap = False
tf.margin_left = 0; tf.margin_right = 0; tf.margin_top = 0; tf.margin_bottom = 0
for i, ln in enumerate(tree.split("\n")):
    p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
    p.space_after = Pt(0); p.space_before = Pt(0); p.line_spacing = 1.0
    for (t, c) in _tree_segments(ln):
        r = p.add_run(); r.text = t
        r.font.name = CODE_FONT; r.font.size = Pt(10.5); r.font.color.rgb = c

# ── SLIDE 13 · HELM: Chart.yaml + values.yaml ───────────────────────────────────
s = content_base(prs, "2. Arquivos do Helm — Chart & Values")
pic(s, L_HELM, 8.60, 0.30, w=0.62, h=0.62)
txt(s, 0.55, 1.16, 9.00, 0.40,
    [[R("O Helm junta os ", "Lato", 12.5, False, C_DARK),
      R("templates", "Lato", 12.5, True, C_BLUE),
      R(" com as variáveis do ", "Lato", 12.5, False, C_DARK),
      R("values.yaml", "Lato", 12.5, True, C_GREEN),
      R(" para gerar o YAML final.", "Lato", 12.5, False, C_DARK)]])

chart_yaml = (
    "apiVersion: v2\n"
    "name: minha-app\n"
    "description: Chart Helm de exemplo\n"
    "type: application\n"
    "version: 1.0.0       # Versão do pacote\n"
    "appVersion: \"2.0.0\"  # Versão da app"
)
values_yaml = (
    "replicaCount: 2      # cópias (pods)\n"
    "\n"
    "image:\n"
    "  repository: nginx\n"
    "  tag: \"1.25\"\n"
    "  pullPolicy: IfNotPresent\n"
    "\n"
    "service:\n"
    "  type: ClusterIP\n"
    "  port: 80"
)
code_block(s, 0.55, 1.62, 4.35, 3.35, chart_yaml, title="Chart.yaml", fsz=11)
code_block(s, 5.10, 1.62, 4.35, 3.35, values_yaml, title="values.yaml", fsz=11)
txt(s, 0.55, 1.62 + 3.35 + 0.01, 4.35, 0.22,
    [[R("A certidão de nascimento do pacote", "Lato", 9.5, False, C_GRAY)]],
    align=PP_ALIGN.CENTER)
txt(s, 5.10, 1.62 + 3.35 + 0.01, 4.35, 0.22,
    [[R("As variáveis que os alunos podem alterar", "Lato", 9.5, False, C_GRAY)]],
    align=PP_ALIGN.CENTER)

# ── SLIDE 14 · HELM: templates (deployment + service) ────────────────────────────
s = content_base(prs, "2. Arquivos do Helm — Templates")
pic(s, L_HELM, 8.60, 0.30, w=0.62, h=0.62)
txt(s, 0.55, 1.16, 9.00, 0.40,
    [[R("Os templates usam as variáveis via ", "Lato", 12.5, False, C_DARK),
      R("{{ .Values ... }}", CODE_FONT, 12, True, RGBColor(0xB8,0x8A,0x2E)),
      R(" — nada é fixo no código.", "Lato", 12.5, False, C_DARK)]])

deployment_yaml = (
    "apiVersion: apps/v1\n"
    "kind: Deployment\n"
    "metadata:\n"
    "  name: {{ .Release.Name }}-deployment\n"
    "spec:\n"
    "  replicas: {{ .Values.replicaCount }}\n"
    "  selector:\n"
    "    matchLabels:\n"
    "      app: {{ .Release.Name }}\n"
    "  template:\n"
    "    metadata:\n"
    "      labels:\n"
    "        app: {{ .Release.Name }}\n"
    "    spec:\n"
    "      containers:\n"
    "        - name: {{ .Chart.Name }}\n"
    "          image: \"{{ .Values.image.repository }}:{{ .Values.image.tag }}\"\n"
    "          ports:\n"
    "            - containerPort: {{ .Values.service.port }}"
)
service_yaml = (
    "apiVersion: v1\n"
    "kind: Service\n"
    "metadata:\n"
    "  name: {{ .Release.Name }}-service\n"
    "spec:\n"
    "  type: {{ .Values.service.type }}\n"
    "  ports:\n"
    "    - port: {{ .Values.service.port }}\n"
    "      targetPort: {{ .Values.service.port }}\n"
    "  selector:\n"
    "    app: {{ .Release.Name }}"
)
code_block(s, 0.55, 1.62, 5.15, 3.42, deployment_yaml,
           title="templates/deployment.yaml", fsz=8.4, line_spacing=1.02)
code_block(s, 5.90, 1.62, 3.55, 3.42, service_yaml,
           title="templates/service.yaml", fsz=9, line_spacing=1.02)

# ── SLIDE 15 · ARGOCD: application.yaml ──────────────────────────────────────────
s = content_base(prs, "3. Arquivo do ArgoCD — a mágica do GitOps")
pic(s, L_ARGO, 8.55, 0.28, w=0.66, h=0.66)
txt(s, 0.55, 1.16, 5.55, 0.40,
    [[R("O ", "Lato", 12.5, False, C_DARK),
      R("Application", "Lato", 12.5, True, C_GREEN),
      R(" diz ao ArgoCD qual repositório vigiar.", "Lato", 12.5, False, C_DARK)]])

application_yaml = (
    "apiVersion: argoproj.io/v1alpha1\n"
    "kind: Application\n"
    "metadata:\n"
    "  name: minha-app-argocd\n"
    "  namespace: argocd\n"
    "spec:\n"
    "  project: default\n"
    "  source:                # 1. FONTE (Git)\n"
    "    repoURL: 'https://github.com/voce/gitops.git'\n"
    "    targetRevision: HEAD\n"
    "    path: 'helm/minha-app'\n"
    "    helm:\n"
    "      valueFiles: [values.yaml]\n"
    "  destination:           # 2. DESTINO (K8s)\n"
    "    server: 'https://kubernetes.default.svc'\n"
    "    namespace: producao\n"
    "  syncPolicy:            # 3. AUTOMAÇÃO\n"
    "    automated:\n"
    "      prune: true        # apaga o que sai do Git\n"
    "      selfHeal: true     # corrige alterações manuais"
)
code_block(s, 0.55, 1.62, 5.85, 3.42, application_yaml, title="argocd/application.yaml", fsz=8.8, line_spacing=1.0)

# painel lateral: 3 blocos explicativos
px = 6.60
blocks = [
    ("1", "FONTE", "Onde está o código no Git: URL, branch e o caminho do Chart.", C_BLUE),
    ("2", "DESTINO", "Em qual cluster e namespace instalar a aplicação.", C_DARK),
    ("3", "AUTOMAÇÃO", "prune + selfHeal = o cluster segue o Git, sempre.", C_GREEN),
]
by = 1.62
for i, (n, t, d, col) in enumerate(blocks):
    bh = 1.05
    cy = by + i * (bh + 0.13)
    rrect(s, px, cy, 2.85, bh, fill=C_CARD, line=RGBColor(0xE3,0xE0,0xD5), line_w=0.75, radius=0.08)
    oval(s, px + 0.16, cy + 0.16, 0.40, 0.40, fill=col)
    tcol = C_DARK if col == C_GREEN else C_WHITE
    txt(s, px + 0.16, cy + 0.19, 0.40, 0.34, [[R(n, "Ubuntu", 13, True, tcol)]],
        align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    txt(s, px + 0.68, cy + 0.14, 2.05, 0.34, [[R(t, "Ubuntu", 12, True, col if col != C_DARK else C_DARK)]])
    txt(s, px + 0.20, cy + 0.52, 2.50, 0.48, [[R(d, "Lato", 10, False, C_INK)]], line_spacing=0.98)

# ── SLIDE 16 · DICA PARA A AULA (demo em 3 passos) ───────────────────────────────
s = content_base(prs, "Dica para a aula: veja o GitOps em ação")
txt(s, 0.55, 1.18, 9.00, 0.45,
    [[R("Uma demonstração de 30 segundos que fixa todo o conceito:",
        "Lato", 14, False, C_INK)]])

demo = [
    ("Helm", "Altere\nreplicaCount: 2 → 5\nno values.yaml", L_HELM,
     "no values.yaml", C_BLUE),
    ("Git", "git commit\n+ git push\npara o GitHub", L_GIT,
     "envie ao repositório", C_DARK),
    ("ArgoCD", "Detecta a mudança e\ncria os novos pods\nautomaticamente", L_ARGO,
     "sincroniza sozinho", C_GREEN),
]
bw, bh = 2.75, 2.75
gap = (10.0 - 1.10 - 3 * bw) / 2
x0 = 0.55
by = 1.85
for i, (tit, steps, logo, cap, col) in enumerate(demo):
    cx = x0 + i * (bw + gap)
    rrect(s, cx, by, bw, bh, fill=C_CARD, line=RGBColor(0xE3,0xE0,0xD5), line_w=0.75, radius=0.07)
    rect(s, cx, by, bw, 0.14, fill=col)
    # badge passo
    oval(s, cx + 0.20, by + 0.30, 0.46, 0.46, fill=col)
    tcol = C_DARK if col == C_GREEN else C_WHITE
    txt(s, cx + 0.20, by + 0.33, 0.46, 0.40, [[R(str(i+1), "Ubuntu", 16, True, tcol)]],
        align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
    pic(s, logo, cx + bw - 0.90, by + 0.30, w=0.55, h=0.55)
    txt(s, cx + 0.22, by + 0.92, bw - 0.44, 0.40, [[R(tit, "Ubuntu", 15, True, col if col != C_DARK else C_DARK)]])
    sparas = [[R(line, "Lato", 11, False, C_INK)] for line in steps.split("\n")]
    txt(s, cx + 0.24, by + 1.34, bw - 0.48, 1.25, sparas, space_after=2, line_spacing=1.05)
    if i < 2:
        chevron(s, cx + bw + 0.02, by + bh/2 - 0.13, gap - 0.04, 0.26, fill=C_GREEN)


# ── SLIDE 17 · RESUMO ────────────────────────────────────────────────────────────
s = content_base(prs, "Resumo da aula")
resumo = [
    ("Helm", "Empacota a aplicação em Charts reutilizáveis e "
     "parametrizáveis, com histórico de versões e rollback.", C_BLUE),
    ("GitOps", "Usa o Git como única fonte da verdade — o estado desejado "
     "do cluster vive versionado no repositório.", C_DARK),
    ("ArgoCD", "Sincroniza o cluster com o Git de forma contínua e "
     "automática, eliminando o Configuration Drift.", C_GREEN),
    ("Juntos", "Helm cria o pacote flexível; ArgoCD garante que o "
     "Kubernetes reflita sempre o que está no Git.", C_BLUE),
]
cw, gap = 4.35, 0.30
x0, y0 = 0.55, 1.35
for i, (t, d, col) in enumerate(resumo):
    cx = x0 + (i % 2) * (cw + gap)
    cy = y0 + (i // 2) * (1.55 + 0.22)
    rrect(s, cx, cy, cw, 1.55, fill=C_CARD, line=RGBColor(0xE3,0xE0,0xD5), line_w=0.75, radius=0.08)
    rect(s, cx, cy, cw, 0.13, fill=col)
    txt(s, cx + 0.28, cy + 0.26, cw - 0.50, 0.45, [[R(t, "Ubuntu", 15, True, col if col != C_DARK else C_DARK)]])
    txt(s, cx + 0.28, cy + 0.72, cw - 0.50, 0.75, [[R(d, "Lato", 12, False, C_INK)]],
        line_spacing=1.05)

# ── SLIDE 12 · ENCERRAMENTO ──────────────────────────────────────────────────────
s = blank(prs)
set_bg(s, C_BG)
pic(s, SWIRL, 6.30, 1.05, w=4.20, h=2.60)
pic(s, TOPBAR, 0, 0, w=10.0, h=0.16)
pic(s, TOPBAR, 0, 5.46, w=10.0, h=0.16)
rect(s, 0.60, 1.95, 0.16, 1.45, fill=C_GREEN)
txt(s, 0.95, 1.80, 7.60, 1.10, [[R("Perguntas?", "Ubuntu", 38, True, C_WHITE)]])
txt(s, 0.97, 2.85, 7.80, 0.70,
    [[R("Helm empacota • GitOps versiona • ArgoCD sincroniza",
        "Lato", 15, False, C_GREEN)]])
txt(s, 0.95, 4.75, 8.00, 0.50,
    [[R("Ada • DE-OP-011 Orquestração • Kubernetes  |  Aula 09  |  "
        "Obrigado!", "Lato", 11, False, C_WHITE)]])
pic(s, ADA, 8.70, 4.55, w=0.95, h=0.59)

# ── Salvar ───────────────────────────────────────────────────────────────────────
out = os.path.join(DIR, "Aula_09_Helm_e_ArgoCD.pptx")
prs.save(out)
print("Saved:", out, "| slides:", len(prs.slides.__iter__.__self__._sldIdLst))
