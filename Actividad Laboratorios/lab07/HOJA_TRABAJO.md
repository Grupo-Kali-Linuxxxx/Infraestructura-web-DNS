# Laboratorio 7 — Hoja de trabajo: el DNS autoritativo del colegio con BIND9

Nombre: ______________________   Fecha: ___/___/2026

## Preparación: la red DNS del laboratorio
Pon la carpeta `red_dns/` junto a tus carpetas `lab07/`, `lab08/`… y ejecuta:
```
cd red_dns
docker compose up -d --build          # ns1 10.10.10.2 · ns2 10.10.10.3 · resolutor 10.10.10.4 · cliente 10.10.10.50
docker compose exec ns1 bash          # dentro: tu carpeta está en /lab/lab07
```
(Con VirtualBox: instala Docker en tu VM Ubuntu y haz lo mismo; o crea 2 VMs con IPs fijas y adapta las IPs.)

## Parte A — Completa las zonas (ns1)
- `ns1/db.horizonte.internal`: 3 TODO (CNAME de portal; MX, A de mail y SPF; CAA).
- `ns1/db.10.10.10`: 1 TODO (PTR de www y de mail).
1. ¿Por qué los nombres de la derecha en la zona inversa llevan punto final?
2. ¿Qué pasa si escribes `mail.horizonte.internal` sin punto en el MX? Pruébalo con `named-checkzone` en una copia.

## Parte B — Configuración de BIND (ns1 y ns2)
- `ns1/named.conf.options`: 2 TODO (recursión y versión).
- `ns1/named.conf.local`: 2 TODO (transferencia solo con TSIG y NOTIFY a ns2).
- `ns2/named.conf.local`: 2 TODO (firmar con TSIG hacia ns1 y la zona inversa secundaria).

Instala: en ns1 `bash /lab/lab07/instalar_ns1.sh`; en ns2 `bash /lab/lab07/instalar_ns2.sh`.
Verifica desde el cliente: `docker compose exec cliente bash /lab/lab07/verificar_lab07.sh` → **16 de 16**.

## Parte C — Consultas desde el cliente
| Comando | Resultado | ¿Qué demuestra? |
|---|---|---|
| `dig @10.10.10.2 www.horizonte.internal` (mira `flags`) | | |
| `dig @10.10.10.3 portal.horizonte.internal` | | |
| `dig @10.10.10.2 -x 10.10.10.25 +short` | | |
| `dig @10.10.10.2 google.com` | | |
| `dig @10.10.10.2 horizonte.internal AXFR` | | |
| `dig -k /lab/lab07/compartido/transferencia.key @10.10.10.2 horizonte.internal AXFR` | | |
| `dig @10.10.10.2 CH TXT version.bind +short` | | |

## Parte D — NOTIFY y el serial
1. En ns1 agrega `biblioteca IN A 10.10.10.80`, **sube el serial** y `rndc reload horizonte.internal`.
   ¿Cuánto tarda en aparecer en ns2? Copia las líneas de `journalctl -u named` de ns2 que lo muestran.
2. Agrega `cafeteria IN A 10.10.10.81` **sin** subir el serial y recarga. Consulta en ns1 y en ns2. ¿Qué pasó?
3. ¿Qué pasaría si bajas el serial (por ejemplo, al restaurar un respaldo viejo)?

## Reflexión
Si ns1 se apaga, ¿qué pasa con el DNS del colegio? ¿Y si se apaga durante 3 semanas?
