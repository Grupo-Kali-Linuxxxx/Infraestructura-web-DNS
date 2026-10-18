#!/bin/bash
# medir_rpz.sh - Cuenta los dominios de la lista RPZ cargada y comprueba una muestra.
# Uso: bash medir_rpz.sh [archivo_zona] [tamaño_muestra]
ZONEFILE="${1:-/etc/unbound/rpz/urlhaus.rpz}"
MUESTRA="${2:-20}"
SUFIJO='.rpz.urlhaus.abuse.ch.'

# Dominios bloqueados: líneas "<dominio> ... CNAME ." (relativas o absolutas)
LISTA=$(awk '$0 !~ /^[;$@]/ && $0 ~ /CNAME[ \t]+\.([ \t;]|$)/ {print $1}' "$ZONEFILE" \
  | sed -e "s/${SUFIJO//./\\.}\$//" -e 's/\.$//' | grep -v '^testentry' | sort -u)
TOTAL=$(printf '%s\n' "$LISTA" | grep -c .)
echo "Zonas RPZ activas:"; unbound-control list_auth_zones
echo "Dominios en la lista: $TOTAL"

BLOQ=0; N=0
for d in $(printf '%s\n' "$LISTA" | shuf -n "$MUESTRA"); do
  N=$((N+1))
  ST=$(dig +time=3 +tries=1 @10.10.10.4 "$d" A | awk '/status:/ {gsub(",","",$6); print $6}')
  [ "$ST" = "NXDOMAIN" ] && BLOQ=$((BLOQ+1))
  echo "  $d -> ${ST:-sin respuesta}"
done
echo "Muestra: $N dominios; bloqueados (NXDOMAIN): $BLOQ"
