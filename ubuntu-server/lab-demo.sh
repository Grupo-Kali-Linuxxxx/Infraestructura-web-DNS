#!/bin/sh
set -eu
trap 'exit 0' TERM INT
echo "Servicio académico iniciado como $(id -un)."
while :; do
    echo "$(date -u +%FT%TZ) lab-demo activo"
    sleep 10 &
    wait "$!"
done
