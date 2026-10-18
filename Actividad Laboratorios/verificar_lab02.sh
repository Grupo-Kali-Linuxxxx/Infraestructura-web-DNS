#!/usr/bin/env bash
# verificar_lab02.sh — Comprueba el estado del servidor al terminar el Laboratorio 2.
# Uso:  bash verificar_lab02.sh <tu_usuario>
USUARIO="${1:-$USER}"
ok=0; total=0
revisar() {  # revisar "descripción" comando...
  local desc="$1"; shift; total=$((total + 1))
  if "$@" &>/dev/null; then echo "✅ $desc"; ok=$((ok + 1)); else echo "❌ $desc"; fi
}
revisar "Ubuntu 24.04 LTS"                          grep -q 'VERSION_ID="24.04"' /etc/os-release
revisar "Nombre del servidor = srv-horizonte"       test "$(hostname)" = srv-horizonte
revisar "Zona horaria America/La_Paz"               bash -c 'readlink -f /etc/localtime | grep -q La_Paz'
revisar "Existe el usuario $USUARIO"                id "$USUARIO"
revisar "$USUARIO pertenece a sudo"                 bash -c "id -nG $USUARIO | grep -qw sudo"
revisar "$USUARIO pertenece a webadmin"             bash -c "id -nG $USUARIO | grep -qw webadmin"
revisar "/srv/horizonte/www es del grupo webadmin"  bash -c 'test "$(stat -c %G /srv/horizonte/www)" = webadmin'
revisar "/srv/horizonte/www tiene setgid (2775)"    bash -c 'test "$(stat -c %a /srv/horizonte/www)" = 2775'
revisar "index.html de prueba existe"               test -f /srv/horizonte/www/index.html
revisar "www.horizonte.internal resuelve (hosts)"   getent hosts www.horizonte.internal
revisar "Paquetes curl, htop, tree instalados"      dpkg -s curl htop tree
revisar "Servicio ssh activo"                       systemctl is-active ssh
revisar "Servicio ssh habilitado al arranque"       systemctl is-enabled ssh
revisar "Puerto 22 escuchando"                      bash -c 'ss -tln | grep -q ":22 "'
echo "Resultado: $ok de $total comprobaciones"
[[ $ok -eq $total ]]
