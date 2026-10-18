#!/usr/bin/env bash
# preparar_servidor.sh — Deja el servidor de la U.E. Horizonte listo para los próximos laboratorios.
# Uso:  sudo bash preparar_servidor.sh <tu_usuario>
# Meta: que sea IDEMPOTENTE (ejecutarlo 2 veces no rompe nada). Completa cada TODO con el comando que
# ya probaste a mano en la Parte B de la hoja de trabajo. Verifica con:  bash verificar_lab02.sh <tu_usuario>
set -euo pipefail

USUARIO="${1:-}"
if [[ $EUID -ne 0 ]]; then echo "Ejecuta con sudo: sudo bash $0 <usuario>"; exit 1; fi
if [[ -z "$USUARIO" ]]; then echo "Falta el usuario: sudo bash $0 <usuario>"; exit 1; fi

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

paso "1. Nombre del servidor y zona horaria"
hostnamectl set-hostname srv-horizonte 2>/dev/null || echo srv-horizonte > /etc/hostname
# TODO: zona horaria America/La_Paz (pista: timedatectl)

paso "2. Paquetes base"
apt-get update -qq
# TODO: instalar curl htop tree ufw unattended-upgrades (sin preguntas: -y)

paso "3. Usuario administrador con sudo"
if ! id "$USUARIO" &>/dev/null; then
  adduser --disabled-password --gecos "Administrador Horizonte" "$USUARIO"
fi
# TODO: agregar $USUARIO al grupo sudo (pista: usermod -aG ...). ¿Qué pasa si olvidas la -a?

paso "4. Grupo webadmin y carpeta del sitio"
# TODO: crear el grupo webadmin SOLO si no existe (pista: getent group ... || groupadd ...)
# TODO: agregar $USUARIO a webadmin
# TODO: crear /srv/horizonte/www y /srv/horizonte/portal con dueño root, grupo webadmin y permisos 2775
#       (pista: install -d -o root -g webadmin -m 2775 carpeta1 carpeta2 ...)
# TODO: crear /srv/horizonte/www/index.html con un HTML mínimo del colegio (solo si no existe)

paso "5. Nombres locales (hasta que tengamos DNS propio en la clase 7)"
for nombre in www.horizonte.internal portal.horizonte.internal; do
  grep -q " $nombre" /etc/hosts || echo "127.0.1.1 $nombre" >> /etc/hosts
done

paso "6. Servicio SSH habilitado y activo"
# TODO: habilitar al arranque E iniciar ya el servicio ssh con un solo comando de systemctl

paso "Resumen"
echo "Usuario: $USUARIO  →  grupos: $(id -nG "$USUARIO")"
ls -ld /srv/horizonte /srv/horizonte/www 2>/dev/null || echo "Aún no existe /srv/horizonte"
systemctl is-active ssh || true
