#!/usr/bin/env bash
# instalar_portal.sh — PHP-FPM + portal para padres + API de eco detrás de Nginx.  Uso: sudo bash instalar_portal.sh
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }

# 1. PHP 8.3 con FPM (Ubuntu 24.04). php-cli sirve para probar desde la terminal.
dpkg -s php8.3-fpm &>/dev/null || { apt-get update -qq; apt-get install -y -qq php8.3-fpm php8.3-cli; }
systemctl enable --now php8.3-fpm >/dev/null 2>&1

# 2. Código del portal: public/ (visible) y app/ (privado)
rm -rf /srv/horizonte/portal/index.html
install -d -o root -g webadmin -m 2775 /srv/horizonte/portal/public /srv/horizonte/portal/app
cp -r portal/public/. /srv/horizonte/portal/public/
cp -r portal/app/.    /srv/horizonte/portal/app/
chgrp -R webadmin /srv/horizonte/portal
find /srv/horizonte/portal -type d -exec chmod 2775 {} +
find /srv/horizonte/portal -type f -exec chmod 664 {} +

# 3. API de eco como servicio de systemd (usuario sin privilegios www-data)
install -d /opt/horizonte
install -m 644 api/servidor_eco.py /opt/horizonte/servidor_eco.py
install -m 644 systemd/horizonte-eco.service /etc/systemd/system/horizonte-eco.service
systemctl daemon-reload
if ! { systemctl enable horizonte-eco >/dev/null 2>&1 && systemctl restart horizonte-eco; }; then
  echo "⚠️  horizonte-eco no inició: revisa systemd/horizonte-eco.service y 'journalctl -u horizonte-eco'"
fi

# 4. Nginx: nueva configuración del portal, probar y recargar
install -m 644 nginx/horizonte-portal.conf /etc/nginx/sites-available/horizonte-portal.conf
ln -sf /etc/nginx/sites-available/horizonte-portal.conf /etc/nginx/sites-enabled/horizonte-portal.conf
nginx -t
systemctl reload nginx
sleep 1                               # reload es asíncrono: damos un segundo a los procesos nuevos
echo "Listo: http://portal.horizonte.internal  (usuario de prueba: mamani.rosa)"
