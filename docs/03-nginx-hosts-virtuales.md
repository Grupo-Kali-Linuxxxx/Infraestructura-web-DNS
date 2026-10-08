# Fase 3: Nginx y dos hosts virtuales

## Objetivo y archivos

Demostrar que una sola entrada HTTP distribuye solicitudes entre dos backends
según el encabezado `Host`, y verificar las cabeceras recibidas por Node.js.

| Archivo | Función |
|---|---|
| `nginx/conf.d/default.conf` | Servidor por defecto para nombres desconocidos |
| `nginx/conf.d/sitio1.conf` | `sitio1.local` hacia `app1:3000` |
| `nginx/conf.d/sitio2.conf` | `sitio2.local` hacia `app2:3000` |
| `backend/app1/server.js`, `backend/app2/server.js` | Ruta GET `/diagnostico` |
| `scripts/Test-VirtualHosts.ps1` | Comprobaciones reproducibles desde Windows |

Se conservó el archivo global `/etc/nginx/nginx.conf` de la imagen. Éste ya
incluye `/etc/nginx/conf.d/*.conf` dentro de su bloque `http`.
No se añadieron dependencias ni Express en esta fase.

## Recorrido de la solicitud

```mermaid
sequenceDiagram
    participant C as Windows / curl.exe
    participant N as Nginx :80 (publicado en 127.0.0.1:8080)
    participant A as app1:3000
    participant B as app2:3000
    C->>N: GET /diagnostico; Host sitio1.local:8080
    N->>A: Host sitio1.local + cabeceras de proxy
    A-->>N: HTTP 200; JSON APP1
    N-->>C: HTTP 200; JSON APP1
    C->>N: GET /diagnostico; Host sitio2.local:8080
    N->>B: Host sitio2.local + cabeceras de proxy
    B-->>N: HTTP 200; JSON APP2
    N-->>C: HTTP 200; JSON APP2
```

Los hosts comparten `listen 80`. `server_name` selecciona el bloque por nombre;
`proxy_pass` envía la solicitud al nombre de servicio correspondiente en Docker.
No se utiliza `localhost:3000` como upstream: dentro de Nginx, localhost
identifica al contenedor de Nginx, no a los backends.

`default_server` se declaró explícitamente en `default.conf`. Las solicitudes
a `127.0.0.1`, localhost o un nombre desconocido mantienen la respuesta simple
de diagnóstico de Nginx; no se envían a APP1 o APP2. El `server_name _` por sí
solo no convierte un bloque en predeterminado: lo hace `listen ... default_server`.
Se sustituyó el encabezado Content-Type manual por `default_type text/plain`
para evitar un Content-Type adicional en esa respuesta.

## Cabeceras y tiempos de espera

Cada `location /` conserva `proxy_pass http://app1:3000` o `http://app2:3000`
y utiliza estas directivas:

```nginx
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_connect_timeout 3s;
proxy_send_timeout 30s;
proxy_read_timeout 30s;

proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

| Directiva | Qué demuestra |
|---|---|
| `proxy_http_version 1.1` | Fija explícitamente HTTP/1.1 hacia Node.js |
| `Connection ""` | Omite la cabecera Connection en el tramo al backend |
| `Host $host` | Envía el nombre de host normalizado, sin el puerto externo |
| `X-Real-IP $remote_addr` | Envía la dirección del cliente vista por Nginx |
| `X-Forwarded-For` | Añade esa dirección al final de la cadena recibida |
| `X-Forwarded-Proto $scheme` | Envía `http`, protocolo realmente usado con Nginx |

La IP vista por Nginx puede ser la puerta de enlace Docker por la traducción
de red de Docker Desktop. No equivale necesariamente a la IP física de Windows.
`ipConexion` en el diagnóstico es la IP del socket Node.js: corresponde a Nginx.

Se probó enviar valores falsos de X-Real-IP y X-Forwarded-Proto: Nginx los
sobrescribe. X-Forwarded-For conserva valores proporcionados por el cliente y
añade su propia observación; el prefijo no es una fuente confiable de identidad.
No se ha configurado todavía `trust proxy` ni autenticación basada en estas IP.
La ruta de diagnóstico sólo devuelve campos seleccionados; no muestra cookies,
Authorization ni secretos, y usa `Cache-Control: no-store`.

El tiempo de conexión es tres segundos. Los tiempos de envío y lectura limitan
inactividad entre operaciones, no la duración total de una petición. No se
implementó WebSocket ni un pool de conexiones persistentes al upstream.

## Validar y aplicar desde PowerShell

```powershell
docker compose exec -T nginx nginx -t
```

Validar antes de recargar. Un cambio en los archivos montados no cambia los
workers activos hasta que se recarga o se reinicia Nginx. Para incorporar la
ruta de diagnóstico cuando todavía se ejecuta la versión anterior:

```powershell
docker compose build app1 app2
docker compose up -d --no-deps app1 app2
docker compose exec -T nginx nginx -t
```

**Sólo si la validación anterior termina correctamente**:

```powershell
docker compose exec -T nginx nginx -s reload
```

La recarga mantiene el proceso maestro y reemplaza workers progresivamente.
Con `proxy_pass` literal, las IP de los servicios se resuelven al cargar la
configuración. Si se recrea un backend y cambia su IP, validar y recargar
Nginx para renovar esa resolución. No se recreó Ubuntu en esta fase.

## Pruebas por nombre sin modificar Windows

Desde PowerShell, en la raíz del repositorio:

```powershell
.\scripts\Test-VirtualHosts.ps1

curl.exe --noproxy "*" -v --resolve "sitio1.local:8080:127.0.0.1" http://sitio1.local:8080/
curl.exe --noproxy "*" -v --resolve "sitio2.local:8080:127.0.0.1" http://sitio2.local:8080/
curl.exe --noproxy "*" -v --resolve "sitio1.local:8080:127.0.0.1" http://sitio1.local:8080/diagnostico
curl.exe --noproxy "*" -v --resolve "sitio2.local:8080:127.0.0.1" http://sitio2.local:8080/diagnostico
```

`--resolve` asocia nombre y puerto a 127.0.0.1 únicamente en esa ejecución de
curl; no configura DNS ni modifica el archivo hosts. `--noproxy "*"` evita
un proxy configurado en el equipo. `-v` muestra solicitud, Host y respuesta.
También funciona `curl.exe -v -H "Host: sitio1.local" http://127.0.0.1:8080/`.

El script comprueba HTTP 200, contenido de cada backend, método y ruta con
query string, versión HTTP, las cuatro cabeceras y servidor por defecto.
Una excepción significa que la prueba falló; no debe ignorarse.

## Preparar la comprobación manual en navegador

Al cierre de fase 3 no había entradas para estos nombres en
`C:\Windows\System32\drivers\etc\hosts`. Posteriormente se configuraron
ambos nombres y se verificó el acceso en Chrome usando la resolución de Windows.
El script conserva las entradas existentes, evita duplicados y guarda un
respaldo en `.local-backups/`, excluido de Git:

```powershell
.\scripts\Initialize-LocalHosts.ps1
```

Windows solicita permisos de administrador sólo si hace falta modificar hosts.
Como alternativa, editarlo con un editor ejecutado como
administrador y añadir estas líneas si no existen, sin reemplazar otras entradas:

```text
127.0.0.1 sitio1.local
127.0.0.1 sitio2.local
```

Después abrir `http://sitio1.local:8080/` y `http://sitio2.local:8080/`.
En DevTools, Network, seleccionar la petición y revisar Request URL, Host
o autoridad, Status Code y Response. Abrir también `/diagnostico` para observar
las cabeceras que recibió el backend. Capturar esas vistas para el informe.
Si el navegador tiene un proxy, excluir estos nombres de ese proxy.

## Logs y límites de esta fase

Los logs independientes existentes se conservaron:

```powershell
docker compose exec -T nginx tail -n 10 /var/log/nginx/sitio1_access.log
docker compose exec -T nginx tail -n 10 /var/log/nginx/sitio2_access.log
```

Al cierre de fase 3 faltaban `error_page` y `proxy_intercept_errors`, y las rutas
desconocidas respondían 200. Estos puntos se corrigieron posteriormente en
[fase 4](04-paginas-error.md).
Express se incorporó después en [fase 6](06-backends-express.md).
Sesiones/cookies siguen pendientes al cierre de esa fase.

## Evidencias y fuentes consultadas

- [Evidencias ejecutadas](evidencias/fase-03.md).
- Nginx. (s. f.). [How nginx processes a request](https://nginx.org/en/docs/http/request_processing.html).
- Nginx. (s. f.). [Module ngx_http_proxy_module](https://nginx.org/en/docs/http/ngx_http_proxy_module.html).
- Nginx. (s. f.). [Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html).
- curl. (s. f.). [curl man page](https://curl.se/docs/manpage.html).

Consulta de documentación: 8 de octubre de 2026.
