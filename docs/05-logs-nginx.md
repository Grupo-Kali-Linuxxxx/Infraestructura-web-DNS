# Fase 5: logs de Nginx

## Qué registra cada log

| Registro | Función | Ejemplo observado |
|---|---|---|
| Access log | Registra las peticiones atendidas, incluidas respuestas exitosas y errores HTTP | GET /no-existe, estado 404 |
| Error log | Explica problemas operativos o de comunicación según su gravedad | upstream prematurely closed connection, asociado al 502 |

Una respuesta 404 no implica necesariamente un mensaje en el error log.
Por ejemplo, el backend puede responder 404 normalmente sin que haya un fallo
de comunicación. La petición sí queda en el access log.

## Configuración implementada

`nginx/conf.d/00-logging.conf` define un formato dentro del contexto `http`
incluido por la configuración global existente. El nombre empieza con `00-`
para cargar la definición antes de los archivos de los hosts.

```nginx
log_format infraestructura 'time=$time_iso8601 client=$remote_addr host=$host '
    'method=$request_method request="$request" status=$status bytes=$body_bytes_sent '
    'upstream="$upstream_addr" upstream_status="$upstream_status" duration=$request_time';
```

Cada host escribe en su propio archivo y en los canales que consulta Docker:

```nginx
access_log /var/log/nginx/sitio1_access.log infraestructura;
access_log /dev/stdout infraestructura;
error_log /var/log/nginx/sitio1_error.log warn;
error_log /dev/stderr warn;
```

Sitio 2 usa archivos con prefijo `sitio2_`. Se conserva el logging global y
del servidor predeterminado de la imagen. Los logs de éste pueden tener otro
formato. Cada petición de un sitio se escribe una vez por destino; las dos
copias son intencionales. El formato personalizable corresponde al access log;
el error log conserva el formato propio de Nginx.

El nivel `warn` incluye advertencias y errores de mayor gravedad. No se
habilitó debug ni se instaló ningún sistema adicional de monitoreo.

## Lectura de una línea

Ejemplo real, abreviado quitando el identificador de prueba:

```text
time=2026-10-08T05:53:17+00:00 client=172.18.0.1 host=sitio1.local method=GET request="GET /no-existe HTTP/1.1" status=404 bytes=1605 upstream="172.18.0.2:3000" upstream_status="404" duration=0.002
```

| Campo | Interpretación |
|---|---|
| time | Fecha/hora ISO 8601, con zona; el contenedor registra UTC |
| client | IP que observa Nginx; puede ser la puerta de enlace Docker |
| host | Host virtual seleccionado por nombre |
| method | Método HTTP |
| request | Petición original con ruta, query string y versión HTTP |
| status | Código final entregado al cliente |
| bytes | Bytes del cuerpo enviado, sin contar cabeceras |
| upstream | Dirección del backend utilizado |
| upstream_status | Estado asociado al intento upstream |
| duration | Tiempo de procesamiento en segundos |

Para una respuesta local de Nginx sin upstream, esos campos pueden tener `-`.
`upstream_status=502` también puede representar un fallo de conexión que Nginx
detectó; no demuestra que Node.js haya emitido una respuesta HTTP 502.
Las IP mostradas son dinámicas y no deben copiarse a la configuración.

No se registran cookies, Authorization ni cuerpos de peticiones en este formato.
La URL y sus parámetros sí se registran: no introducir contraseñas o secretos
en las URLs de las prácticas.

## Consultar desde PowerShell

Últimas líneas por host, ejecutando `tail` Linux dentro del contenedor:

```powershell
docker compose exec -T nginx tail -n 20 /var/log/nginx/sitio1_access.log
docker compose exec -T nginx tail -n 20 /var/log/nginx/sitio1_error.log
docker compose exec -T nginx tail -n 20 /var/log/nginx/sitio2_access.log
docker compose exec -T nginx tail -n 20 /var/log/nginx/sitio2_error.log
```

Registros recibidos por Docker desde stdout/stderr:

```powershell
docker compose logs --tail 40 nginx
docker compose logs --since 5m --timestamps nginx
docker logs --tail 40 web-nginx
```

`--timestamps` añade la marca de tiempo de Docker además de la que ya aparece
en la línea de Nginx. Los registros de los hosts ya no están limitados a sus
archivos internos.

Filtrar desde PowerShell:

```powershell
docker compose logs --since 5m nginx | Select-String 'host=sitio1.local'
docker compose logs --since 5m nginx | Select-String 'status=404|status=502'
docker compose logs --since 5m nginx | Select-String 'upstream prematurely closed'
```

Seguir nuevas líneas en tiempo real:

```powershell
docker compose logs -f --tail 10 nginx
docker compose exec -T nginx tail -f /var/log/nginx/sitio1_access.log
```

Ejecutar uno por terminal. Terminar con Ctrl+C detiene el seguimiento, no Nginx.

## Consultar desde una shell Linux del contenedor

Desde PowerShell abrir:

```powershell
docker compose exec nginx sh
```

Dentro de esa shell Linux:

```sh
tail -n 20 /var/log/nginx/sitio1_access.log
tail -n 20 /var/log/nginx/sitio1_error.log
exit
```

## Generar y verificar registros

Desde PowerShell en la raíz del repositorio:

```powershell
.\scripts\Test-NginxLogs.ps1
```

El script envía GET que producen 200, 404 y 502 en cada host, usando
`--resolve` y un identificador único en la query string. Después verifica:

- Las tres peticiones nuevas en el access log de cada sitio.
- IP, fecha, host, método, ruta, código, backend y duración.
- La causa del 502 en cada error log.
- Las peticiones y los errores también en `docker compose logs`.

No detiene contenedores. El 502 se provoca mediante la ruta académica de
cierre controlado de conexión implementada en fase 4.

## Conservación de evidencias

Los archivos existentes no se borraron. Por eso las líneas anteriores a esta
fase mantienen el formato combined y las nuevas utilizan infraestructura.
No se montó un volumen para `/var/log/nginx`: los archivos viven en la capa
del contenedor y se pierden al recrearlo. Antes de hacerlo se pueden copiar:

```powershell
New-Item -ItemType Directory -Force .\logs
docker compose cp nginx:/var/log/nginx/sitio1_access.log ./logs/sitio1_access.log
docker compose cp nginx:/var/log/nginx/sitio1_error.log ./logs/sitio1_error.log
docker compose cp nginx:/var/log/nginx/sitio2_access.log ./logs/sitio2_access.log
docker compose cp nginx:/var/log/nginx/sitio2_error.log ./logs/sitio2_error.log
```

`.gitignore` ya excluye `*.log`. Para el informe usar extractos revisados como
los de [evidencias](evidencias/fase-05.md), no subir automáticamente logs completos.
Los logs Docker pertenecen al contenedor y su disponibilidad depende del driver
y la retención configurados en el Engine; no se prometió persistencia histórica.
No se configuró rotación de los archivos internos: esta solución sirve para
una práctica breve, no para almacenamiento indefinido en producción.

## Fuentes oficiales consultadas

- Nginx. (s. f.). [Module ngx_http_log_module](https://nginx.org/en/docs/http/ngx_http_log_module.html).
- Nginx. (s. f.). [Core functionality: error_log](https://nginx.org/en/docs/ngx_core_module.html#error_log).
- Docker. (s. f.). [View container logs](https://docs.docker.com/engine/logging/).

Consulta: 8 de octubre de 2026.
