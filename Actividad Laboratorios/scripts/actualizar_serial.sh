#!/bin/bash
# Sube el serial (AAAAMMDDnn), valida la zona y la recarga.
# Uso: bash actualizar_serial.sh horizonte.internal
set -euo pipefail
 
ZONA="${1:?Uso: $0 <zona>}"
 
# Archivo de la zona, tomado de la configuración activa de BIND
ARCHIVO=$(named-checkconf -p | awk -v z="\"$ZONA\"" '
  $1=="zone" && $2==z {dentro=1}
  dentro && $1=="file" {gsub(/[";]/,"",$2); print $2; exit}')
[ -n "$ARCHIVO" ] && [ -f "$ARCHIVO" ] || { echo "No se encontró la zona $ZONA" >&2; exit 1; }
 
# 1. La zona debe ser válida antes de tocar el serial
named-checkzone "$ZONA" "$ARCHIVO" >/dev/null || { echo "La zona tiene errores" >&2; exit 1; }
 
# 2. Nuevo serial AAAAMMDDnn (nunca menor ni igual al actual)
ACTUAL=$(grep -oE '[0-9]{10}' "$ARCHIVO" | head -n1)
HOY=$(date +%Y%m%d)
if [ "${ACTUAL:0:8}" = "$HOY" ]; then NN=$((10#${ACTUAL:8:2} + 1)); else NN=1; fi
[ "$NN" -le 99 ] || { echo "Se agotaron los 99 cambios del día" >&2; exit 1; }
NUEVO=$(printf '%s%02d' "$HOY" "$NN")
[ "$NUEVO" -gt "$ACTUAL" ] || NUEVO=$((ACTUAL + 1))
 
# 3. Aplicar, validar de nuevo y recargar (si falla, restaurar)
COPIA=$(mktemp); cp -p "$ARCHIVO" "$COPIA"
sed -i "0,/$ACTUAL/s//$NUEVO/" "$ARCHIVO"
if named-checkzone "$ZONA" "$ARCHIVO"; then
  rndc reload "$ZONA"
  echo "Zona $ZONA: serial $ACTUAL -> $NUEVO (recargada)"
else
  cp -p "$COPIA" "$ARCHIVO"; echo "Validación fallida: se restauró $ARCHIVO" >&2; exit 1
fi
