# Laboratorio 8 — Hoja de trabajo: el resolutor del colegio (Unbound) y el DNS como código

Nombre: ______________________   Fecha: ___/___/2026

Usa la red `red_dns` del Laboratorio 7 (ns1 y ns2 ya configurados, `verificar_lab07.sh` en 16/16).
Entra al resolutor: `docker compose exec resolutor bash` (tu carpeta: `/lab/lab08`).

## Parte A — Autoritativo vs resolutor
1. `dig @10.10.10.2 www.upds.edu.bo` y `dig @10.10.10.4 www.upds.edu.bo` (después de instalar): ¿qué responde cada uno?
2. ¿Por qué el colegio necesita LOS DOS tipos de servidor?

## Parte B — Completa la configuración (10 TODO)
| Archivo | TODO | Qué aprendes |
|---|---|---|
| `unbound/horizonte-resolutor.conf` | 5 | control de acceso, zonas privadas y DNSSEC, inversas privadas, DoT |
| `unbound/rpz.horizonte.internal` | 2 | bloquear subdominios, redirigir phishing |
| `dns-como-codigo/dnsconfig.js` | 3 | SOA, DMARC y CAA como código |

`bash /lab/lab08/instalar_resolutor.sh` · en `dns-como-codigo/`: `mkdir -p zonas && dnscontrol push`
`bash /lab/lab08/verificar_lab08.sh` → objetivo **17 de 17**.

## Parte C — Experimentos (anota lo que pasa y por qué)
1. **Sin `domain-insecure`**: ¿qué devuelve `dig @10.10.10.4 www.horizonte.internal`? ¿Por qué DNSSEC lo rechaza?
2. **Sin `local-zone: "10.in-addr.arpa." nodefault`**: ¿qué pasa con `dig @10.10.10.4 -x 10.10.10.25`?
3. **Caché**: consulta dos veces un dominio nuevo (por ejemplo `www.bcb.gob.bo`) y compara los `Query time`.
4. **DNSSEC**: `dig +dnssec @10.10.10.4 cloudflare.com` (busca `ad`) y `dig @10.10.10.4 dnssec-failed.org`.

## Parte D — ¿Sale cifrado?
En el resolutor:
```
unbound-control flush_zone upds.edu.bo
timeout 6 tcpdump -ni eth0 -nn '(dst port 53 or dst port 853) and not dst net 10.10.10.0/24' &
dig @10.10.10.4 www.upds.edu.bo
```
¿Hacia qué puerto y a qué IP salen las consultas? Repite con la versión inicio (sin DoT) y compara.

## Parte E — La zona pública como código
1. Cambia `IP_WEB` en `dnsconfig.js` y ejecuta `dnscontrol preview`: copia el diff. ¿Por qué es mejor que editar el
   archivo de zona a mano?
2. ¿Qué habría que cambiar en `creds.json` para publicar la zona en un proveedor real (Cloudflare)?

## Parte F — Comparación (investiga y completa)
| Tema | BIND/Unbound en Linux (este curso) | DNS de Windows Server / Active Directory | DNS gestionado (Cloudflare, NIC.bo) |
|---|---|---|---|
| Dónde se guardan las zonas | | | |
| Cómo se replican | | | |
| Filtrado (RPZ / directivas) | | | |
| Costo y quién lo mantiene | | | |

## Reflexión
¿Qué ventajas de privacidad y seguridad gana el colegio con su propio resolutor frente a usar el DNS del proveedor?
