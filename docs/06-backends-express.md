# Fase 6: backends Node.js y Express

## Alcance

Se incorporó Express en los dos backends existentes. Se mantuvieron los
servicios app1/app2, el puerto interno 3000, los hosts sitio1.local/sitio2.local,
las páginas iniciales y las demostraciones de cabeceras y error 502.
Al cerrar fase 6 no se habían implementado sesiones ni cookies; se añadieron
posteriormente en [fase 7](07-sesiones-cookies.md).

Versiones ejecutadas en esta sesión: Node.js 22.23.3 y Express 5.2.1.
Cada package.json admite Express `^5.1.0`; su package-lock.json fija el árbol
resuelto, incluida la versión 5.2.1 que efectivamente se instaló.

## Archivos

| Archivo | Cambio |
|---|---|
| backend/app1/server.js y backend/app2/server.js | Rutas Express, validación, errores y cierre del servidor |
| package.json de cada backend | Dependencia Express y comandos start/check |
| package-lock.json de cada backend | Versiones e integridad del árbol de dependencias |
| Dockerfile de cada backend | npm ci, NODE_ENV production y ejecución como node |
| .dockerignore de cada backend | Excluye node_modules y variables locales del contexto |
| docker-compose.yml | Healthchecks de backends y dependencias saludables para Nginx |
| nginx/conf.d/snippets/proxy-headers.conf | Cabeceras y tiempos de espera compartidos |
| sitio1.conf y sitio2.conf | Ubicación /api/ que conserva respuestas JSON |
| scripts/Test-Backends.ps1 | Pruebas HTTP con casos válidos e inválidos |

## Rutas de cada aplicación

| Método | Ruta | Respuesta |
|---|---|---|
| GET | / | HTML original que identifica APP1 o APP2 |
| GET | /health | JSON estado ok y aplicación; estado 200 |
| GET | /diagnostico | Datos seleccionados de petición y cabeceras del proxy |
| GET | /api/info | JSON aplicación y tecnología |
| POST | /api/eco | JSON con mensaje validado |
| GET | /api/pruebas/error | Error asíncrono controlado; JSON 500 |
| GET | /pruebas/502 | Cierra la conexión deliberadamente; Nginx genera 502 |
| Otros métodos | /api/eco | JSON 405 con Allow: POST |
| Ruta desconocida | /api/... | JSON 404 |
| Ruta desconocida | Fuera de /api/ | Texto 404 desde Node; HTML personalizado mediante Nginx |

Express procesa las rutas y middleware en orden. Se declaran rutas antes
del manejador de 404, y el middleware de errores tiene cuatro argumentos
`(error, req, res, next)` al final. Las rutas de fallos son exclusivamente
académicas; no corresponden a fallos espontáneos ni deben quedar habilitadas
como funciones de una aplicación de producción.

## Entrada y errores

`express.json` limita el cuerpo JSON a 8 KB. `/api/eco` exige un objeto con
`mensaje` de tipo texto, no vacío y de hasta 200 caracteres. No escribe en
archivos ni base de datos: devuelve el mensaje con espacios extremos retirados.

| Situación probada | Estado |
|---|---|
| JSON válido con mensaje correcto | 200 |
| JSON mal formado | 400 |
| mensaje numérico o cuerpo array | 400 |
| Tipo de contenido distinto de application/json | 415 |
| Charset JSON no admitido | 415 |
| Cuerpo superior a 8 KB | 413 |
| GET a ruta que exige POST | 405 |
| Ruta API inexistente | 404 |
| Error asíncrono controlado | 500 |

Las respuestas de error no muestran stack traces ni mensajes internos de
excepciones. Los 500 registran un mensaje acotado en los logs del backend.
El servidor se mantiene activo después de la demostración de error.
Se deshabilitó X-Powered-By y se usa Cache-Control no-store para estas respuestas.

No se habilitó trust proxy: estas rutas sólo muestran las cabeceras recibidas,
sin confiar en ellas para autenticación o cookies seguras. Su configuración
se evaluará al implementar sesiones en fase 7.

## Integración con Nginx

Los hosts comparten las directivas de cabeceras mediante el nuevo snippet.
La ubicación `location ^~ /api/` usa el mismo backend y
`proxy_intercept_errors off`, para que un 404 de la API siga siendo JSON.
El resto de las rutas conserva la intercepción y los HTML 404/502 de fase 4.

Para esta API no se declaran páginas personalizadas 400/405/413/415/500 en
Nginx; se reciben los cuerpos JSON del backend. Los errores de infraestructura
generados por Nginx pueden seguir usando las páginas HTML del servidor.

## Construcción reproducible desde PowerShell

No es necesario instalar Node.js en Windows. Docker utiliza los package-lock
incluidos y ejecuta `npm ci --omit=dev --ignore-scripts --no-audit --no-fund`.

Desde fase 7 ejecutar primero `.\scripts\Initialize-Environment.ps1` para
disponer de los secretos locales antes de utilizar Compose.
La instalación no modifica los archivos de bloqueo. Si cambia una dependencia,
actualizar el lock explícitamente y volver a comprobarlo.

```powershell
docker compose config -q
docker compose build app1 app2
docker compose up -d --no-deps --wait --wait-timeout 60 app1 app2
docker compose exec -T nginx nginx -t
```

Sólo después de una validación Nginx correcta:

```powershell
docker compose exec -T nginx nginx -s reload
docker compose ps -a
```

La recarga renueva la resolución de nombres de upstreams tras recrear backends.
Se mantuvo el contenedor Nginx para conservar sus logs y no se recreó Ubuntu.
En un arranque desde cero, `depends_on` espera que los dos backends estén
saludables antes de iniciar Nginx. Esto no es un supervisor de fallos durante
la ejecución: no se afirma que reinicie automáticamente un servicio unhealthy.

Los healthchecks consultan `/health` con el módulo HTTP de Node, sin instalar
curl dentro de Alpine. El chequeo comprueba HTTP 200, no todas las rutas de API.
El puerto del healthcheck es 3000, acorde al puerto utilizado en Compose.
`PORT` permite configurar el arranque manual y se valida entre 1 y 65535;
si se cambia en Docker, adaptar también healthcheck y proxy.

El proceso corre como uid/gid 1000, usuario node. Al recibir SIGTERM deja de
aceptar conexiones y cierra el servidor, con límite de ocho segundos antes
de forzar salida. El reinicio de ambos backends se comprobó en esta fase.

## Pruebas y diagnóstico desde PowerShell

```powershell
.\scripts\Test-Backends.ps1
.\scripts\Test-VirtualHosts.ps1
.\scripts\Test-ErrorPages.ps1
.\scripts\Test-NginxLogs.ps1

docker compose exec -T app1 npm run check
docker compose exec -T app2 npm run check
docker compose exec -T app1 npm ls --omit=dev --depth=0
docker compose exec -T app2 npm ls --omit=dev --depth=0
docker compose logs --tail 20 app1 app2
```

Pruebas manuales con curl y nombres locales:

```powershell
curl.exe --noproxy "*" -v --resolve "sitio1.local:8080:127.0.0.1" http://sitio1.local:8080/health
curl.exe --noproxy "*" -v --resolve "sitio2.local:8080:127.0.0.1" http://sitio2.local:8080/api/info
curl.exe --noproxy "*" -v --resolve "sitio1.local:8080:127.0.0.1" -H "Content-Type: application/json" --data-binary "@docs/ejemplos/eco.json" http://sitio1.local:8080/api/eco
curl.exe --noproxy "*" -v --resolve "sitio1.local:8080:127.0.0.1" http://sitio1.local:8080/api/no-existe
```

El archivo JSON evita problemas de comillas en argumentos nativos de PowerShell.
El script de pruebas usa archivos temporales para los cuerpos y los elimina
al terminar. No instala librerías de pruebas ni detiene servicios.

Se ejecutó `npm audit --omit=dev --audit-level=high` en ambos backends:
informó cero vulnerabilidades conocidas. Ese resultado corresponde al árbol
y a la base de avisos consultados en esta sesión; no garantiza ausencia de
todos los defectos posibles ni se reemplaza la revisión del código.

## Fuentes y evidencias

- [Evidencias ejecutadas de fase 6](evidencias/fase-06.md).
- Express. (s. f.). [Installing](https://expressjs.com/en/starter/installing/).
- Express. (s. f.). [Error Handling](https://expressjs.com/en/guide/error-handling/).
- Express. (s. f.). [Upgrade to Express v5](https://expressjs.com/en/guide/migrating-5/).
- npm. (s. f.). [npm ci](https://docs.npmjs.com/cli/v11/commands/npm-ci/).

Consulta: 8 de octubre de 2026.
