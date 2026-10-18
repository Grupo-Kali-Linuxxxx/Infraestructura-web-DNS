#!/bin/bash
# Pipeline de validación para DNSControl
set -euo pipefail

DIR="${DIR:-/lab/lab08/dns-como-codigo}"
ZONA="ue-horizonte.example"

cd "$DIR"
mkdir -p zonas

bloqueado() {
    echo "BLOQUEADO: $*" >&2
    exit 1
}

echo "[1/4] dnscontrol check"
dnscontrol check || bloqueado "dnsconfig.js tiene errores"

echo "[2/4] dnscontrol preview"
if ! dnscontrol preview 2>&1 | tee /tmp/preview_dns.txt; then
    bloqueado "preview falló"
fi

echo "[3/4] named-checkzone"
named-checkzone "$ZONA" "zonas/$ZONA.zone" \
    || bloqueado "la zona generada no es válida"

if [[ "${1:-}" != "--push" ]]; then
    echo "Validación correcta. No se aplicó ningún cambio (use --push)."
    exit 0
fi

echo "[4/4] dnscontrol push"
dnscontrol push || bloqueado "push falló"

echo "Pipeline completado: validaciones correctas y push finalizado."
