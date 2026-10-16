"""
make_diagrams.py — Gera diagramas customizados no estilo Ada para imagens que
não puderam ser baixadas (hypervisor e pipeline CI/CD).
Paleta Ada: fundo cream, dark #181C23, azul #2371FF, verde #A6F750.
"""
import os
from PIL import Image, ImageDraw, ImageFont

IMG_DIR = r"C:\UserData\z004stze\Documents\Private\mine\ada\arquitetura-de-servicos\slides\images"

CREAM = (255, 251, 240)
DARK  = (24, 28, 35)
BLUE  = (35, 113, 255)
GREEN = (166, 247, 80)
GRAY  = (200, 205, 215)
WHITE = (255, 253, 248)


def load_font(size, bold=False):
    candidates = [
        r"C:\Windows\Fonts\Ubuntu-B.ttf" if bold else r"C:\Windows\Fonts\Ubuntu-R.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
    ]
    for c in candidates:
        if os.path.exists(c):
            return ImageFont.truetype(c, size)
    return ImageFont.load_default()


def rounded_box(draw, xy, radius, fill, outline=None, width=2):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def center_text(draw, box, text, font, fill):
    x0, y0, x1, y1 = box
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((x0 + x1 - tw) / 2, (y0 + y1 - th) / 2 - bbox[1] / 2), text, font=font, fill=fill)


# ─── Diagrama 1: Hypervisor / Virtualização ──────────────────────────────────
def make_hypervisor():
    W, H = 1100, 620
    img = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(img)
    f_title = load_font(34, bold=True)
    f_lbl   = load_font(22, bold=True)
    f_sm    = load_font(18)

    center_text(d, (0, 15, W, 65), "Arquitetura de Virtualização (Hipervisor)", f_title, DARK)

    # 3 VMs on top
    vm_w, vm_h, gap = 300, 200, 40
    total = 3 * vm_w + 2 * gap
    start_x = (W - total) // 2
    vm_y = 90
    for i in range(3):
        x = start_x + i * (vm_w + gap)
        rounded_box(d, (x, vm_y, x + vm_w, vm_y + vm_h), 14, WHITE, outline=BLUE, width=3)
        center_text(d, (x, vm_y + 12, x + vm_w, vm_y + 52), f"Máquina Virtual {i+1}", f_lbl, BLUE)
        # app
        rounded_box(d, (x + 25, vm_y + 62, x + vm_w - 25, vm_y + 108), 8, GREEN)
        center_text(d, (x + 25, vm_y + 62, x + vm_w - 25, vm_y + 108), "Aplicação", f_sm, DARK)
        # bins/libs
        rounded_box(d, (x + 25, vm_y + 116, x + vm_w - 25, vm_y + 150), 8, GRAY)
        center_text(d, (x + 25, vm_y + 116, x + vm_w - 25, vm_y + 150), "Bibliotecas", f_sm, DARK)
        # guest OS
        rounded_box(d, (x + 25, vm_y + 156, x + vm_w - 25, vm_y + 190), 8, DARK)
        center_text(d, (x + 25, vm_y + 156, x + vm_w - 25, vm_y + 190), "Sistema Operacional", f_sm, WHITE)

    # Hypervisor layer
    hy_y = vm_y + vm_h + 25
    rounded_box(d, (start_x, hy_y, start_x + total, hy_y + 60), 12, BLUE)
    center_text(d, (start_x, hy_y, start_x + total, hy_y + 60), "HIPERVISOR", f_lbl, WHITE)

    # Host OS
    ho_y = hy_y + 75
    rounded_box(d, (start_x, ho_y, start_x + total, ho_y + 55), 12, GRAY)
    center_text(d, (start_x, ho_y, start_x + total, ho_y + 55), "Sistema Operacional Host", f_lbl, DARK)

    # Hardware
    hw_y = ho_y + 70
    rounded_box(d, (start_x, hw_y, start_x + total, hw_y + 55), 12, DARK)
    center_text(d, (start_x, hw_y, start_x + total, hw_y + 55), "Infraestrutura Física (Hardware)", f_lbl, GREEN)

    img.save(os.path.join(IMG_DIR, "virtualizacao_hypervisor.png"))
    print("OK virtualizacao_hypervisor.png")


# ─── Diagrama 2: Pipeline CI/CD ──────────────────────────────────────────────
def make_pipeline():
    W, H = 1200, 420
    img = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(img)
    f_title = load_font(34, bold=True)
    f_lbl   = load_font(20, bold=True)
    f_sm    = load_font(15)

    center_text(d, (0, 20, W, 70), "Pipeline de CI/CD", f_title, DARK)

    stages = [
        ("Commit", "Git push", GREEN),
        ("Build", "Compila / Docker", BLUE),
        ("Testes", "Unit / Integração", GREEN),
        ("Staging", "Homologação", BLUE),
        ("Produção", "Deploy final", GREEN),
    ]
    n = len(stages)
    box_w, box_h = 180, 130
    gap = (W - n * box_w) // (n + 1)
    y = 150
    cx_prev = None
    for i, (title, sub, color) in enumerate(stages):
        x = gap + i * (box_w + gap)
        # arrow from previous
        if cx_prev is not None:
            d.line([(cx_prev, y + box_h // 2), (x, y + box_h // 2)], fill=DARK, width=4)
            d.polygon([(x, y + box_h // 2), (x - 14, y + box_h // 2 - 9),
                       (x - 14, y + box_h // 2 + 9)], fill=DARK)
        rounded_box(d, (x, y, x + box_w, y + box_h), 14, WHITE, outline=color, width=4)
        # number circle
        r = 26
        d.ellipse((x + box_w // 2 - r, y - r, x + box_w // 2 + r, y + r), fill=color)
        center_text(d, (x + box_w // 2 - r, y - r, x + box_w // 2 + r, y + r),
                    str(i + 1), f_lbl, DARK)
        center_text(d, (x, y + 30, x + box_w, y + 70), title, f_lbl, DARK)
        center_text(d, (x, y + 78, x + box_w, y + 112), sub, f_sm, (90, 95, 105))
        cx_prev = x + box_w

    # CI / CD brackets
    f_band = load_font(18, bold=True)
    ci_x0 = gap
    ci_x1 = gap + 3 * box_w + 2 * gap - gap // 2
    cd_x0 = ci_x1 + 10
    cd_x1 = W - gap
    band_y = y + box_h + 35
    rounded_box(d, (ci_x0, band_y, ci_x1, band_y + 40), 10, GREEN)
    center_text(d, (ci_x0, band_y, ci_x1, band_y + 40), "CI — Integração Contínua", f_band, DARK)
    rounded_box(d, (cd_x0, band_y, cd_x1, band_y + 40), 10, BLUE)
    center_text(d, (cd_x0, band_y, cd_x1, band_y + 40), "CD — Entrega Contínua", f_band, WHITE)

    img.save(os.path.join(IMG_DIR, "pipeline_cicd.png"))
    print("OK pipeline_cicd.png")


if __name__ == "__main__":
    make_hypervisor()
    make_pipeline()
    print("Diagramas gerados.")
