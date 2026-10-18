#!/usr/bin/env bash
# instalar_sitios.sh — Instala Nginx y publica los dos sitios del colegio.  Uso: sudo bash instalar_sitios.sh
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }

for f in nginx/horizonte-www.conf nginx/horizonte-portal.conf nginx/00-rechazar-desconocidos.conf; do
  [[ -f $f ]] || { echo "Falta $f (lee nginx/LEEME-portal.md)"; exit 1; }
done

dpkg -s nginx &>/dev/null || { apt-get update -qq; apt-get install -y -qq nginx; }

# 1. Contenido (conserva dueño root:webadmin y el setgid del Laboratorio 2)
install -d -o root -g webadmin -m 2775 /srv/horizonte/www /srv/horizonte/portal
cp -r sitio/www/. /srv/horizonte/www/
cp -r sitio/portal/. /srv/horizonte/portal/
chgrp -R webadmin /srv/horizonte
find /srv/horizonte -type d -exec chmod 2775 {} +      # carpetas: equipo escribe, Nginx entra
find /srv/horizonte -type f -exec chmod 664 {} +       # archivos: equipo edita, Nginx lee (sin x)

# 2. Configuración: sites-available + enlace en sites-enabled
cp nginx/horizonte-log.conf /etc/nginx/conf.d/
cp nginx/00-rechazar-desconocidos.conf nginx/horizonte-www.conf nginx/horizonte-portal.conf /etc/nginx/sites-available/
rm -f /etc/nginx/sites-enabled/default
for sitio in 00-rechazar-desconocidos horizonte-www horizonte-portal; do
  ln -sf "/etc/nginx/sites-available/$sitio.conf" "/etc/nginx/sites-enabled/$sitio.conf"
done

# 3. Probar ANTES de recargar: si la sintaxis falla, el sitio actual sigue funcionando
nginx -t
systemctl enable nginx >/dev/null 2>&1
systemctl reload nginx 2>/dev/null || systemctl restart nginx
echo "Listo: http://www.horizonte.internal y http://portal.horizonte.internal"
