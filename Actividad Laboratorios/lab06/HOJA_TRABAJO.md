# Laboratorio 6 — Hoja de trabajo: radiografía DNS de dominios reales

Nombre: ______________________   Fecha: ___/___/2026

Trabaja en tu servidor (VM o Docker): `dig` viene en el paquete `dnsutils` (`sudo apt install -y dnsutils`).
En Docker usa siempre un resolutor explícito (`@1.1.1.1`): el resolutor interno de Docker (127.0.0.11) no responde
bien a las consultas de la raíz.

## Parte A — El viaje de una consulta
`dig +trace +nodnssec @1.1.1.1 www.upds.edu.bo`
1. ¿Cuántos saltos hubo? Anota quién respondió en cada uno (raíz, .bo, …) y cuánto tardó.
2. ¿Quién administra la zona `.bo`? ¿Y la de `upds.edu.bo`?
3. Compara los NS que da `.bo` (delegación) con los que da la zona (`dig +short upds.edu.bo NS`). ¿Coinciden?

## Parte B — Tipos de registro
| Consulta | Resultado | ¿Para qué sirve este registro? |
|---|---|---|
| `dig +short upds.edu.bo A` | | |
| `dig +short upds.edu.bo AAAA` | | |
| `dig +short upds.edu.bo MX` | | |
| `dig +short upds.edu.bo TXT` | | |
| `dig +short _dmarc.upds.edu.bo TXT` | | |
| `dig upds.edu.bo SOA +noall +answer` | | explica cada número |
| `dig +short -x 35.212.117.103` | | |
| `dig +short cloudflare.com HTTPS` | | |
| `dig +short google.com CAA` | | |

## Parte C — TTL y caché
Ejecuta dos veces, con 5 segundos de diferencia: `dig @1.1.1.1 www.upds.edu.bo A +noall +answer`
¿Qué pasó con el número de la segunda columna? ¿Qué significa? Si cambias la IP de un sitio con TTL 86400,
¿cuánto puede tardar en verse el cambio?

## Parte D — Completa `radiografia_dns.sh`
4 TODO: servidores que no responden (delegación coja), DMARC, CAA y DNSSEC.
`bash verificar_lab06.sh` → objetivo **12 de 12**.

## Parte E — Tu propio análisis
Ejecuta la radiografía sobre 2 dominios que elijas (tu banco, un periódico, una empresa donde trabajes):
tabla con el puntaje y las 3 mejoras más importantes para cada uno. (Son datos públicos: analiza con respeto,
como un consultor, no como un atacante.)

## Reflexión
¿Por qué el DNS se considera la "guía telefónica" de internet y por qué un error en él puede tumbar el sitio, el
correo y los certificados a la vez?
