"""Exporta a postura da cadeia (por projeto) do Dependency-Track para CSV + KPIs.

Uso:
  DT_URL=http://localhost:8081 DT_TOKEN=<api-key> python consulta_dt.py [saida.csv]
Requer: requests  (pip install requests)
"""
import csv
import os
import sys
from datetime import datetime, timezone

import requests

DT_URL = os.environ["DT_URL"].rstrip("/")
HEADERS = {"X-Api-Key": os.environ["DT_TOKEN"]}
OUT = sys.argv[1] if len(sys.argv) > 1 else "postura_cadeia.csv"


def get(path):
    r = requests.get(f"{DT_URL}{path}", headers=HEADERS, timeout=30)
    r.raise_for_status()
    return r.json()


projetos = get("/api/v1/project?pageSize=500")
linhas = []
for p in projetos:
    m = get(f"/api/v1/metrics/project/{p['uuid']}/current") or {}
    linhas.append({
        "projeto": p["name"],
        "versao": p.get("version", ""),
        "componentes": m.get("components", 0),
        "vulns_criticas": m.get("critical", 0),
        "vulns_altas": m.get("high", 0),
        "violacoes_policy": m.get("policyViolationsTotal", 0),
        "ultimo_import_sbom": datetime.fromtimestamp(p["lastBomImport"] / 1000, timezone.utc).isoformat()
        if p.get("lastBomImport") else "n/d",
    })

with open(OUT, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(linhas[0].keys()) if linhas else ["projeto"])
    w.writeheader()
    w.writerows(linhas)

total = len(linhas)
com_sbom = sum(1 for l in linhas if l["ultimo_import_sbom"] != "n/d")
sem_critica = sum(1 for l in linhas if l["vulns_criticas"] == 0)
print(f"projetos: {total}")
print(f"KPI cobertura de SBOM:        {com_sbom}/{total}")
print(f"KPI projetos sem CVE critica: {sem_critica}/{total}")
print(f"KPI violacoes de policy:      {sum(l['violacoes_policy'] for l in linhas)}")
print(f"CSV: {OUT}")
