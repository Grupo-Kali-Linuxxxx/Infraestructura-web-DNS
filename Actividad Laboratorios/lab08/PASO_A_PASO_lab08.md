# Laboratorio 8 — Paso a paso (con retos y capturas)

Todos los comandos con prompt `root@resolutor` se escriben **dentro del contenedor** (`docker compose exec resolutor bash`).
Los comandos de `docker compose ...` se escriben en PowerShell, en la carpeta `red_dns`.
Las capturas se numeran igual que las figuras de `Hoja_de_Trabajo_Laboratorio_8_APA7.docx` (ver la tabla al final).

> Regla de oro: no captures claves TSIG, tokens ni el contenido de `resolutor.key`.

---

## Paso 0. Preparar el entorno

1. Copia la carpeta `lab08` (con `unbound/`, `dns-como-codigo/`, `instalar_resolutor.sh`, `verificar_lab08.sh`) donde vive el resto de tus laboratorios.
2. Copia también al contenedor/carpeta compartida los scripts de los retos: `medir_rpz.sh` y `pipeline_dns.sh` (dentro de `lab08/`).
3. En PowerShell, en `red_dns`:
   ```
   docker compose up -d --build
   docker compose ps
   docker compose exec cliente bash /lab/lab07/verificar_lab07.sh
   ```
   Debe dar **16 de 16**. Si no, arregla el Lab 7 antes de seguir. → **Captura F1**
4. Entra al resolutor:
   ```
   docker compose exec resolutor bash
   cd /lab/lab08
   unbound -V | head -1
   ```
   → **Captura F2** (`docker compose ps` + `Version 1.19.2`).
   Si `/lab/lab08` no existe, la carpeta no está montada: copia con `docker cp lab08 <contenedor>:/lab/lab08`.

## Paso 1. Respaldar los archivos originales (importante)

Dentro del resolutor, antes de editar nada:
```
cd /lab/lab08
cp -a unbound unbound.inicio
cp -a dns-como-codigo dns-como-codigo.inicio
```
La copia `unbound.inicio` se usa luego para la captura de la Parte D (sin DoT).

## Paso 2. Completar los 10 TODO

Edita con `nano -l -u archivo` (Ctrl+O y Enter guardan, Ctrl+X sale; pega con Ctrl+Shift+V).
Todas las líneas exactas están en `LINEAS_TODO_lab08.md`.

**2.1 `unbound/horizonte-resolutor.conf`** (5 TODO)
- Busca `access-control`: reemplaza `0.0.0.0/0 allow` por las 3 líneas (`refuse` / `127.0.0.0/8 allow` / `10.10.10.0/24 allow`).
- Busca `TODO: marcar`: agrega los dos `domain-insecure`.
- Busca `TODO: quitar`: agrega `local-zone: "10.in-addr.arpa." nodefault`.
- Busca `forward-zone`: reemplaza el `1.1.1.1` simple por el bloque DoT completo (una sola sección `forward-zone`).
- Las opciones dentro de `server:` van con sangría; **no** uses llaves ni `;` (eso es BIND).
→ **Captura F5**

**2.2 `unbound/rpz.horizonte.internal`** (2 TODO)
- Debajo de `TODO: bloquear`: `*.apuestas-ejemplo.com CNAME .`
- Debajo de `TODO: redirigir`: las dos líneas de `horizonte-notas-login.com A 10.10.10.20` (base y `*.`).
- Sin punto final en el nombre de la izquierda.
→ **Captura F6**

**2.3 `dns-como-codigo/dnsconfig.js`** (3 TODO)
- `TODO: SOA`: `SOA("@", "ns1.ue-horizonte.example.", "ti.ue-horizonte.example.", 3600, 600, 1209600, 300),`
- `TODO: DMARC`: bloque `DMARC_BUILDER({ ... }),`
- `TODO: CAA`: bloque `CAA_BUILDER({ ... }),`
- Cada bloque termina con **coma** porque siguen otros elementos.
→ **Captura F7**

## Paso 3. Instalar y verificar (objetivo 17 de 17)

```
cd /lab/lab08
bash instalar_resolutor.sh          # → F8
cd dns-como-codigo
dnscontrol check                    # debe decir: No errors.
mkdir -p zonas && dnscontrol push
named-checkzone ue-horizonte.example zonas/ue-horizonte.example.zone   # termina en OK → F9
cd /lab/lab08
bash verificar_lab08.sh             # 17 de 17 → F10
```
Si algo falla:
- `$'\r': command not found` → saltos de línea de Windows: `sed -i 's/\r$//' archivo`.
- Error de sintaxis de Unbound → `unbound-checkconf` te da el número de línea.
- Error de JavaScript → revisa la coma o la comilla de la línea anterior.
- Falla DoT → revisa que el TCP 853 de salida esté permitido en tu red.
- Si `unbound-control` no conecta, usa el `-c` con la ruta de tu configuración (en la guía de Actividad 2 es `-c /opt/base8/aula.conf`).

## Paso 4. Parte A — Autoritativo vs resolutor

Desde el resolutor (después de instalar):
```
dig @10.10.10.2 www.upds.edu.bo     # REFUSED  → F3
dig @10.10.10.4 www.upds.edu.bo     # la IP    → F4
```

## Paso 5. Parte C — Experimentos

Antes de cada experimento guarda la configuración buena:
```
cd /lab/lab08
cp unbound/horizonte-resolutor.conf /tmp/resolutor.ok
```

**Experimento 1 — sin `domain-insecure`** (F11)
```
sed -i 's/^\(\s*domain-insecure:\)/#\1/' unbound/horizonte-resolutor.conf
bash instalar_resolutor.sh
unbound-control flush_bogus; unbound-control flush_zone horizonte.internal
dig @10.10.10.4 www.horizonte.internal          # SERVFAIL  (captura 1)
cp /tmp/resolutor.ok unbound/horizonte-resolutor.conf
bash instalar_resolutor.sh
dig @10.10.10.4 www.horizonte.internal          # 10.10.10.20 (captura 2)
```

**Experimento 2 — sin `nodefault`** (F12)
```
sed -i 's/^\(\s*local-zone: "10.in-addr.arpa." nodefault\)/#\1/' unbound/horizonte-resolutor.conf
bash instalar_resolutor.sh
dig @10.10.10.4 -x 10.10.10.25                  # respuesta vacía (captura 1)
cp /tmp/resolutor.ok unbound/horizonte-resolutor.conf
bash instalar_resolutor.sh
dig @10.10.10.4 -x 10.10.10.25                  # mail.horizonte.internal. (captura 2)
```

**Experimento 3 — caché** (F13): dos consultas seguidas y mira `Query time`
```
dig @10.10.10.4 www.bcb.gob.bo A
dig @10.10.10.4 www.bcb.gob.bo A
```

**Experimento 4 — DNSSEC** (F14, F15)
```
dig +dnssec @10.10.10.4 cloudflare.com          # busca "ad" en flags
dig @10.10.10.4 dnssec-failed.org               # SERVFAIL
```

**Pruebas RPZ** (F16)
```
dig @10.10.10.4 apuestas-ejemplo.com A          # NXDOMAIN
dig @10.10.10.4 juego.apuestas-ejemplo.com A    # NXDOMAIN
dig @10.10.10.4 horizonte-notas-login.com A     # 10.10.10.20
dig @10.10.10.4 rastreo.publicidad-ejemplo.net A  # NOERROR, ANSWER: 0
```
Para el registro `rpz: applied` (F17), mira los logs desde PowerShell: `docker compose logs --tail 40 resolutor`.

Al terminar, comprueba que la configuración quedó buena: `bash verificar_lab08.sh` → 17 de 17.

## Paso 6. Parte D — ¿Sale cifrado?

**Con la configuración final (F18)**
```
unbound-control flush_zone upds.edu.bo
timeout 6 tcpdump -ni eth0 -nn '(dst port 53 or dst port 853) and not dst net 10.10.10.0/24' &
dig @10.10.10.4 www.upds.edu.bo
```
Espera ~6 s a que tcpdump termine. Debe haber paquetes hacia `:853` (1.1.1.1 / 9.9.9.9) y ninguno hacia `:53`.

**Con la versión inicio (F19)**
```
cp unbound.inicio/horizonte-resolutor.conf unbound/horizonte-resolutor.conf
bash instalar_resolutor.sh
unbound-control flush_zone upds.edu.bo
timeout 6 tcpdump -ni eth0 -nn '(dst port 53 or dst port 853) and not dst net 10.10.10.0/24' &
dig @10.10.10.4 www.upds.edu.bo
```
Verás tráfico hacia el puerto 53 en texto plano. **Después restaura la configuración final:**
```
cp /tmp/resolutor.ok unbound/horizonte-resolutor.conf
bash instalar_resolutor.sh
```

## Paso 7. Parte E — DNS como código

```
cd /lab/lab08/dns-como-codigo
cp dnsconfig.js /tmp/dnsconfig.ok
grep -n IP_WEB dnsconfig.js          # ubica la variable
nano -l -u dnsconfig.js              # cambia IP_WEB de 203.0.113.20 a 203.0.113.21
dnscontrol preview                   # dos MODIFY (@ y www) → F20
cp /tmp/dnsconfig.ok dnsconfig.js    # restaura
dnscontrol check
dnscontrol preview                   # sin cambios de IP → F21
```
No ejecutes `push` con el cambio de demostración.

## Paso 8. Parte F y Reflexión

Ya están redactadas en el documento. Léelas y, si quieres, reescribe frases con tus palabras: la guía pide explicación propia.

---

## RETO 1 — DoT también para los clientes

1. **Ubica la CA de la clase 5** (`ca-colegio.pem` y `ca-colegio.key`). Si no la tienes, crea una de prueba:
   ```
   mkdir -p /etc/unbound/tls && cd /etc/unbound/tls
   openssl req -x509 -newkey rsa:2048 -nodes -keyout ca-colegio.key -out ca-colegio.pem \
     -days 365 -subj "/CN=CA del colegio"
   ```
2. **Genera y firma el certificado del resolutor** (F22):
   ```
   cd /etc/unbound/tls
   openssl genrsa -out resolutor.key 2048
   openssl req -new -key resolutor.key -subj "/CN=resolutor.horizonte.internal" -out resolutor.csr
   printf "subjectAltName=DNS:resolutor.horizonte.internal,IP:10.10.10.4\nextendedKeyUsage=serverAuth\n" > san.cnf
   openssl x509 -req -in resolutor.csr -CA ca-colegio.pem -CAkey ca-colegio.key \
     -CAcreateserial -days 365 -sha256 -extfile san.cnf -out resolutor.pem
   chmod 600 resolutor.key
   chown unbound:unbound resolutor.key resolutor.pem 2>/dev/null
   ls -l
   ```
3. **Edita `unbound/horizonte-resolutor.conf`** (no `/etc/...`, porque el instalador copia desde `unbound/`) y agrega dentro de `server:`:
   ```
   interface: 10.10.10.4@853
   tls-port: 853
   tls-service-key: "/etc/unbound/tls/resolutor.key"
   tls-service-pem: "/etc/unbound/tls/resolutor.pem"
   ```
4. Valida e instala (F23):
   ```
   unbound-checkconf unbound/horizonte-resolutor.conf
   bash instalar_resolutor.sh
   ss -tlnp | grep 853
   ```
5. **Prueba desde el cliente** (F24). El cliente necesita la CA: cópiala (`/etc/unbound/tls/ca-colegio.pem`) a una ruta que vea el cliente, por ejemplo `/lab/lab08/ca-colegio.pem`.
   ```
   apt-get install -y knot-dnsutils        # si kdig no existe
   kdig +tls @10.10.10.4 +tls-ca=/lab/lab08/ca-colegio.pem \
        +tls-hostname=resolutor.horizonte.internal www.horizonte.internal
   ```
   Debe verse el resumen TLS y la respuesta `10.10.10.20`.
6. Al terminar: `bash verificar_lab08.sh` sigue en 17/17. No subas `resolutor.key` ni `ca-colegio.key` al repositorio.

## RETO 2 — Lista pública RPZ (URLhaus)

1. Edita `unbound/horizonte-resolutor.conf` y agrega **al final del archivo**, como una sección aparte (sin sangría en `rpz:`):
   ```
   rpz:
       name: "rpz.urlhaus.abuse.ch."
       url: https://urlhaus.abuse.ch/downloads/rpz/
       zonefile: "/etc/unbound/rpz/urlhaus.rpz"
       rpz-log: yes
       rpz-log-name: "urlhaus"
   ```
2. Prepara la carpeta y valida:
   ```
   mkdir -p /etc/unbound/rpz && chown unbound:unbound /etc/unbound/rpz 2>/dev/null
   unbound-checkconf unbound/horizonte-resolutor.conf
   bash instalar_resolutor.sh
   sleep 10
   unbound-control list_auth_zones      # debe aparecer rpz.urlhaus.abuse.ch. → F25
   ```
3. Comprobación de la lista (la guía pide verificar que los dominios existen y no usar listas sin revisar): `head -20 /etc/unbound/rpz/urlhaus.rpz` y comprueba que es la lista pública de abuse.ch. Prueba la entrada de test:
   ```
   dig @10.10.10.4 testentry.rpz.urlhaus.abuse.ch A     # NXDOMAIN
   ```
4. Mide (F26):
   ```
   bash /lab/lab08/medir_rpz.sh /etc/unbound/rpz/urlhaus.rpz 20
   ```
   Anota en la **Tabla 5** del documento: dominios en la lista, tamaño de la muestra, bloqueados y el porcentaje (bloqueados ÷ muestra × 100).
5. **No visites** ningún dominio de la lista: solo consultas DNS.
6. Si el verificador falla por la nueva RPZ o por memoria, comenta la sección `rpz:` de URLhaus, reinstala y deja constancia en el informe.

## RETO 3 — Pipeline de DNSControl

1. Copia `pipeline_dns.sh` a `/lab/lab08/` y dale permiso: `chmod +x /lab/lab08/pipeline_dns.sh` (o ejecútalo con `bash`).
2. Muestra el script (F27): `cat /lab/lab08/pipeline_dns.sh`.
3. **Prueba correcta** (F28):
   ```
   bash /lab/lab08/pipeline_dns.sh --push
   ```
   Pasa los 4 pasos y termina con "Pipeline completado".
4. **Prueba con error** (F29):
   ```
   cd /lab/lab08/dns-como-codigo
   cp dnsconfig.js /tmp/dnsconfig.ok
   sed -i '0,/quarantine"/s//quarantine/' dnsconfig.js     # quita una comilla
   bash /lab/lab08/pipeline_dns.sh --push; echo "código de salida: $?"
   cp /tmp/dnsconfig.ok dnsconfig.js                        # restaura
   ```
   Debe verse `BLOQUEADO` y un código distinto de 0, sin ejecutar `push`.
5. (Opcional) Gancho de Git, solo si `lab08` está dentro de un repositorio:
   ```
   printf '#!/bin/bash\nbash lab08/pipeline_dns.sh\n' > .git/hooks/pre-push
   chmod +x .git/hooks/pre-push
   ```

---

## Armar la entrega

1. Abre `Hoja_de_Trabajo_Laboratorio_8_APA7.docx`.
2. En cada recuadro punteado: borra el texto gris, pega la captura (Win+Shift+S → Ctrl+V) y ajusta el ancho a ~16 cm (6,25 in). Deja la leyenda "Figura N" arriba.
3. Completa la **Tabla 5** (Reto 2) y, si quieres, agrega tus tiempos de `Query time` en el Experimento 3.
4. Revisa que el nombre y la fecha sean correctos.
5. Estado final antes de entregar: `bash verificar_lab08.sh` → 17/17 y `verificar_lab07.sh` → 16/16.
6. Entrega también `unbound/` y `dns-como-codigo/` completos (sin tokens ni claves) y `BITACORA_IA.md`.

## Lista de capturas

| Fig. | Qué capturar | Paso |
|---|---|---|
| 1 | `verificar_lab07.sh` 16/16 | 0 |
| 2 | `docker compose ps` + `unbound -V` | 0 |
| 3 | `dig @10.10.10.2 www.upds.edu.bo` (REFUSED) | 4 |
| 4 | `dig @10.10.10.4 www.upds.edu.bo` (IP) | 4 |
| 5 | `horizonte-resolutor.conf` completo | 2.1 |
| 6 | `rpz.horizonte.internal` completo | 2.2 |
| 7 | `dnsconfig.js` con SOA/DMARC/CAA | 2.3 |
| 8 | salida de `instalar_resolutor.sh` | 3 |
| 9 | `dnscontrol check/push` + `named-checkzone` OK | 3 |
| 10 | `verificar_lab08.sh` 17/17 | 3 |
| 11 | SERVFAIL sin `domain-insecure` y luego 10.10.10.20 | 5 |
| 12 | inversa vacía sin `nodefault` y luego `mail...` | 5 |
| 13 | dos `Query time` de `www.bcb.gob.bo` | 5 |
| 14 | `cloudflare.com` con flag `ad` | 5 |
| 15 | `dnssec-failed.org` SERVFAIL | 5 |
| 16 | las 4 consultas RPZ | 5 |
| 17 | log `rpz: applied` | 5 |
| 18 | tcpdump final (solo :853) | 6 |
| 19 | tcpdump con versión inicio (:53) | 6 |
| 20 | `dnscontrol preview` con dos MODIFY | 7 |
| 21 | `preview` tras restaurar (sin cambios) | 7 |
| 22 | certificado generado (`ls -l`) | Reto 1 |
| 23 | `unbound-checkconf` + `ss ... 853` | Reto 1 |
| 24 | `kdig +tls` con respuesta | Reto 1 |
| 25 | `list_auth_zones` con URLhaus | Reto 2 |
| 26 | salida de `medir_rpz.sh` | Reto 2 |
| 27 | `cat pipeline_dns.sh` | Reto 3 |
| 28 | pipeline correcto | Reto 3 |
| 29 | pipeline bloqueado | Reto 3 |
