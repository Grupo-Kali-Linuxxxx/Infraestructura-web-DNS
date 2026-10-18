# Laboratorio 9 — Hoja de trabajo: vistas (split-horizon), DNSSEC y monitoreo

Nombre: ______________________   Fecha: ___/___/2026

Usa `red_dns` actualizada (con la red `internet` y el nodo `externo`): `docker compose up -d`. Si ns1 se recreó,
vuelve a ejecutar `bash /lab/lab07/instalar_ns1.sh` en ns1 antes de empezar.

## Parte A — El problema
Desde el nodo **externo** (simula internet): `dig @172.30.0.2 www.horizonte.internal` y
`dig @172.30.0.2 horizonte.internal AXFR`. ¿Qué información interna ve alguien de fuera? ¿Por qué es un riesgo?

## Parte B — Vistas
Completa los TODO de `ns1/named.conf`, `ns1/named.conf.local` y `ns1/named.conf.options`.
1. Ejecuta `bash /lab/lab09/instalar_vistas_dnssec.sh` con `named.conf` tal como viene. Copia el error. ¿Por qué ocurre?
2. Tabla (el mismo nombre, dos respuestas):

| Consulta | Desde el cliente (10.10.10.50) | Desde externo (172.30.0.100) |
|---|---|---|
| `www.ue-horizonte.example` | | |
| `intranet.ue-horizonte.example` | | |
| `www.horizonte.internal` | | |

## Parte C — DNSSEC con dnssec-policy
1. Sin `inline-signing yes;`, ¿qué dice `named-checkconf`? ¿Qué hace `inline-signing`?
2. `ls /var/lib/bind/claves /var/lib/bind/externa`: ¿qué archivos generó BIND?
3. `dig +dnssec @172.30.0.2 www.ue-horizonte.example`: explica los campos del RRSIG (algoritmo, vencimiento, etiqueta de clave).
4. `delv @172.30.0.2 -a /lab/lab09/compartido/ancla-ue-horizonte.conf +root=ue-horizonte.example www.ue-horizonte.example`
   → ¿qué significa "fully validated"? Repite con `noexiste.ue-horizonte.example`: ¿cómo se "firma" algo que no existe?
5. Cambia una letra de la clave en una copia del ancla y repite: ¿qué pasa? ¿Qué demuestra?
6. Abre `compartido/DS-ue-horizonte.example.txt`: ¿a quién se entrega y para qué? ¿Qué dice `rndc dnssec -status
   ue-horizonte.example in externa` sobre el DS?

## Parte D — Monitoreo
Completa el TODO de `vigilar_dns.sh` (días hasta que venzan las firmas) y ejecútalo.
`bash /lab/lab09/verificar_lab09.sh` → objetivo **16 de 16**.
¿Qué pasaría con el dominio si BIND se detiene 3 semanas (firmas de 14 días)?

## Reflexión
¿Qué protege DNSSEC que HTTPS no protege? ¿Y por qué muchos dominios aún no lo usan?
