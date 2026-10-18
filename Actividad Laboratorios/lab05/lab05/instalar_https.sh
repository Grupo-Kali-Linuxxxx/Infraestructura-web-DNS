#!/usr/bin/env bash
# instalar_https.sh — CA propia, certificado, HTTPS y cabeceras de seguridad.  Uso: sudo bash instalar_https.sh
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }

# 1. CA y certificado (solo si no existe o vence en menos de 30 días)
if [[ ! -f /etc/nginx/tls/horizonte.crt ]] || ! openssl x509 -checkend $((30*86400)) -noout -in /etc/nginx/tls/horizonte.crt; then
  bash tls/crear_ca_y_certificado.sh
fi

# 2. Configuración de Nginx
install -d /etc/nginx/snippets
install -m 644 nginx/snippets/horizonte-tls.conf nginx/snippets/horizonte-cabeceras.conf /etc/nginx/snippets/
install -m 644 nginx/seguridad-global.conf /etc/nginx/conf.d/
install -m 644 nginx/00-rechazar-desconocidos.conf nginx/horizonte-www.conf nginx/horizonte-portal.conf /etc/nginx/sites-available/
for sitio in 00-rechazar-desconocidos horizonte-www horizonte-portal; do
  ln -sf "/etc/nginx/sites-available/$sitio.conf" "/etc/nginx/sites-enabled/$sitio.conf"
done

# 3. El servidor confía en su propia CA (para probar con curl sin --cacert)
install -m 644 /etc/horizonte-ca/ca.crt /usr/local/share/ca-certificates/horizonte-ca.crt
update-ca-certificates >/dev/null

# 4. Firewall: si ufw está activo, abrir 443 (la clase 14 lo configura completo)
if ufw status 2>/dev/null | grep -q "Status: active"; then ufw allow 443/tcp >/dev/null; fi

nginx -t
systemctl reload nginx
sleep 1
echo "Listo: https://www.horizonte.internal y https://portal.horizonte.internal"
echo "Instala en tu PC la CA: https://www.horizonte.internal/horizonte-ca.crt (o /etc/horizonte-ca/ca.crt)"
