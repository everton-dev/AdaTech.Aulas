"""
download_images.py — Baixa todas as imagens de conteúdo dos markdowns do módulo
Arquitetura de Serviços e Dados, converte para PNG e salva em ./images/
Gera um images_map.py com o dicionário {chave: caminho_local}.
"""
import os
import io
import re
import glob
import requests
from PIL import Image

MD_DIR = r"C:\UserData\z004stze\Documents\Private\mine\ada\.github\Modulos\AR-Arquitetura-de-software\AR-NA-002-Arquitetura_de_serviços_e_dados\2-Material_do_aluno"
OUT_DIR = r"C:\UserData\z004stze\Documents\Private\mine\ada\arquitetura-de-servicos\slides"
IMG_DIR = os.path.join(OUT_DIR, "images")
os.makedirs(IMG_DIR, exist_ok=True)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
    "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
    "Referer": "https://www.google.com/",
}

# Mapeamento: chave semântica -> URL. Chaves usadas depois no build.
IMAGES = {
    # Docker (aula 1)
    "virtualizacao_hypervisor": "https://www.qnapbrasil.com.br/manager/assets/7JK7RXrL/userfiles/blog-images/o_que_e_virtualizacao/hypervisor-post-o-que-e-virtualizacao-qnapbrasil.jpg",
    "vm_vs_container": "https://4linux.com.br/wp-content/uploads/2021/08/imagem-1024x594.png",
    # Arquitetura de servidores (aula 2)
    "monolito_vs_micro": "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEjwuhr9MfJUWD9Lg0kHaRXOrz5wmduR8myf4kZ-EMqkULGZc0DgGwolVi9VnBtUJHwXWnd2ncmgqLLpdmfz9P2T9dOBCoQK2tQpBX3_t0KGYqqkWUSHptPeCoeoy-_bXAV67R818Z2rOijJ/w601-h290/0_gdL3utU1qjKIGz3K.jpg",
    "tomcat_arq": "https://miro.medium.com/v2/resize:fit:720/format:webp/1*wlk1Hb2ZSviLDheQblYYyA.png",
    "wildfly_logo": "https://bgasparotto.com/wp-content/uploads/2015/02/wildfly-logo.png",
    "weblogic_logo": "https://webhostinggeeks.com/blog/wp-content/uploads/2023/06/Oracle-WebLogic-Server-optimized.png",
    "websphere": "https://miro.medium.com/v2/resize:fit:640/format:webp/0*S5SbI4SR9_37IywT",
    # Apache / Nginx (aula 3)
    "apache_logo": "https://upload.wikimedia.org/wikipedia/commons/1/10/Apache_HTTP_server_logo_%282019-present%29.svg",
    "nginx_logo": "https://miro.medium.com/v2/resize:fit:720/format:webp/0*mjG1YdoT7xPcnznN.jpg",
    "iis_logo": "https://webhostinggeeks.com/blog/wp-content/uploads/2023/05/Microsoft_IIS.png",
    "web_server_func": "https://informationq.com/wp-content/uploads/2017/12/What-is-a-Web-Server.jpg",
    "apache_vs_nginx": "https://blog.insightdials.com/wp-content/uploads/2023/04/AvsN.png",
    # Proxy reverso / DNS (aula 4)
    "proxy_reverso_flow": "https://cf-assets.www.cloudflare.com/slt3lc6tev37/3msJRtqxDysQslvrKvEf8x/f7f54c9a2cad3e4586f58e8e0e305389/reverse_proxy_flow.png",
    "dns_painel": "https://www.hostinger.com.br/tutoriais/wp-content/uploads/sites/12/2023/05/hpanel-domains-dnsnameservers-main-pt.webp",
    "dns_zona": "https://ayltoninacio.com.br/img/p/173c2w850.jpg",
    # CI/CD (aula 5)
    "pipeline_cicd": "https://lh5.googleusercontent.com/LmEAt7G-ARV2_piyKJYX0y4ySvzXW-x_BwatO6zADe1kmlYjZ18DGiW_xcJhG8pbM9E3mhyeoHZhuRzlVQ-ZW_W3MmDJXDJcJ9-9VVRoMzegXt8rTfJxICznGnWyUkbkmAS-zVKd-yAoKs34iAohA_Ve5hOMw4zghmUmrbKBjcyCZ7bN3a83kpev",
    # Cloud (aula 6)
    "cloud_models": "https://learn.microsoft.com/pt-br/azure/cloud-adoption-framework/strategy/media/monitoring-strategy/cloud-models.png",
    # Arquitetura de dados (aula 7)
    "fluxo_cartao": "https://s3-sa-east-1.amazonaws.com/lcpi/0f9a156b-d022-4d8a-b9f0-184c08eebad7.png",
    "produtores_secundario": "https://s3-sa-east-1.amazonaws.com/lcpi/31d850b1-5299-4252-baf9-d328a4c55416.png",
    "dw_representacao": "https://s3-sa-east-1.amazonaws.com/lcpi/b36d6f26-e568-416d-8eb9-f052597c63f3.png",
    "dw_metadados": "https://s3-sa-east-1.amazonaws.com/lcpi/6156a413-f3d3-409b-9695-b75cfd4738c2.png",
    "datamart_vendas": "https://s3-sa-east-1.amazonaws.com/lcpi/af5cabfc-78dc-4ff1-b07f-7bf58fb1de76.png",
    # Data lake (aula 8)
    "datalake_conceito": "https://s3-sa-east-1.amazonaws.com/lcpi/ae0a0894-73bb-4d70-a20e-7c19aac4f12a.png",
    "datalake_camadas": "https://s3-sa-east-1.amazonaws.com/lcpi/5888b668-37ae-47c3-85d2-5c4c121571b3.jpg",
}


def download_one(key, url):
    dst = os.path.join(IMG_DIR, f"{key}.png")
    if os.path.exists(dst):
        print(f"  SKIP (exists) {key}")
        return dst
    try:
        r = requests.get(url, headers=HEADERS, timeout=30)
        r.raise_for_status()
        data = r.content
        # SVG -> render not available; skip to placeholder handling
        if url.lower().endswith(".svg") or data[:5] == b"<?xml" or data[:4] == b"<svg":
            print(f"  SVG (needs manual)  {key}")
            return None
        img = Image.open(io.BytesIO(data))
        # convert to RGB/RGBA safe PNG
        if img.mode in ("P", "LA"):
            img = img.convert("RGBA")
        elif img.mode == "CMYK":
            img = img.convert("RGB")
        img.save(dst, format="PNG")
        print(f"  OK   {key}  ({img.size[0]}x{img.size[1]})")
        return dst
    except Exception as e:
        print(f"  FAIL {key}: {e}")
        return None


def main():
    print("Downloading content images...")
    result = {}
    for key, url in IMAGES.items():
        path = download_one(key, url)
        if path:
            result[key] = path

    # write map file
    map_path = os.path.join(OUT_DIR, "images_map.py")
    with open(map_path, "w", encoding="utf-8") as f:
        f.write("# auto-generated by download_images.py\n")
        f.write("IMAGES = {\n")
        for k, v in result.items():
            f.write(f"    {k!r}: r{v!r},\n")
        f.write("}\n")
    print(f"\nDownloaded {len(result)}/{len(IMAGES)} images.")
    print(f"Map written to {map_path}")
    missing = set(IMAGES) - set(result)
    if missing:
        print("MISSING:", missing)


if __name__ == "__main__":
    main()
