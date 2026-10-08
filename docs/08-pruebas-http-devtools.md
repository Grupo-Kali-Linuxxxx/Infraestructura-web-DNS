# Fase 8 — Análisis HTTP con curl y DevTools

Las pruebas se ejecutan desde PowerShell 7, con los servicios Docker activos.
Se conserva la arquitectura existente; esta fase agrega pruebas y evidencias.

## Repetir el análisis con curl

```powershell
.\scripts\Export-HttpEvidence.ps1
curl.exe -v --noproxy "*" --resolve sitio1.local:8080:127.0.0.1 http://sitio1.local:8080/diagnostico
curl.exe -v --noproxy "*" --resolve sitio2.local:8080:127.0.0.1 http://sitio2.local:8080/diagnostico
```

`--resolve` conecta el nombre indicado a 127.0.0.1 para esta ejecución.
Conserva el Host de la URL, sin modificar el archivo hosts de Windows. Esto
demuestra selección del host virtual, pero no demuestra un servidor DNS propio.
`--noproxy` evita que un proxy del entorno intercepte estas solicitudes locales.

En la salida verbose, `>` indica datos enviados y `<` datos recibidos; `*`
describe conexión y diagnósticos de curl. `Host` permite a Nginx seleccionar
el sitio. `Server` identifica el servidor frontal, `Content-Type` describe
el cuerpo y `Cache-Control: no-store` evita almacenarlo en caché.
El script guarda sólo cabeceras seleccionadas, códigos y cuerpos JSON o títulos
HTML en [curl-fase-08.md](evidencias/curl-fase-08.md). Los valores de cookies
se omiten antes de escribir el informe y los archivos temporales se eliminan.

| Petición, en ambos hosts | Estado | Qué demuestra |
|---|---|---|
| GET / | 200 | APP1 o APP2 según el nombre solicitado |
| GET /diagnostico | 200 | Backend seleccionado y cabeceras recibidas del proxy |
| GET /no-existe | 404 | Página HTML personalizada conservando estado de error |
| GET /pruebas/502 | 502 | Nginx responde ante cierre intencional del upstream |
| GET /api/no-existe | 404 | API conserva JSON en vez de sustituirlo por HTML |
| GET /api/sesion, inicialmente | 200 | Sesión inactiva, contador 0 |
| POST /api/sesion | 201 | Crea sesión y envía Set-Cookie |
| POST /api/sesion/incrementar | 200 | Cookie reenviada y contador 1 |
| GET /api/sesion, después | 200 | Contador conservado entre peticiones |
| DELETE /api/sesion | 200 | Destruye sesión y expira cookie |
| GET /api/sesion, al final | 200 | Vuelve al estado inactivo |

El exportador usa un cookie jar temporal para conservar y reenviar las cookies.
Consultar una sesión inicial no crea una cookie. Set-Cookie establece el dato
en el cliente; Cookie lo devuelve al servidor en solicitudes posteriores.
Las respuestas JSON muestran el contador, sin exponer el identificador.

En `/diagnostico`, `ipConexion` es el extremo inmediato conectado al backend
(Nginx), mientras que `X-Real-IP` refleja el cliente visto por Nginx.
Las IP de Docker pueden variar: no deben fijarse como constantes. La respuesta
de cada backend, las cabeceras y los logs con upstream comprueban el proxy.
El prefijo de X-Forwarded-For puede provenir del cliente y no debe confiarse
sin una política explícita de proxies.

## Navegador real y protocolo DevTools

```powershell
.\scripts\Test-Browser.ps1
```

Requiere Chrome instalado; el script no instala herramientas. Inicia Chrome
headless con un perfil temporal y, por defecto, resolución de los dos nombres
sólo para ese proceso. Con hosts de Windows ya configurado, comprobar el acceso
normal usando `.\scripts\Test-Browser.ps1 -UseSystemResolution`.
Hace clic en los botones reales, consulta Network y Cookies
mediante Chrome DevTools Protocol (CDP), captura las páginas y cierra su
navegador. No utiliza el perfil personal ni modifica hosts de Windows.

Se verificaron creación, incrementos, consulta, persistencia al navegar,
aislamiento entre hosts, destrucción y creación desde cero. APP1 llegó a 2
y APP2 a 1. `document.cookie` quedó vacío porque las cookies son HttpOnly.
Se comprobó dominio propio, Path=/ y SameSite=Lax. Secure está desactivado
porque el laboratorio usa HTTP. Las sesiones siguen almacenadas en memoria
y no constituyen una configuración de producción.

[browser-fase-08.json](evidencias/browser-fase-08.json) contiene 23 respuestas
observadas en esta ejecución: 16 de estado 200, 3 de 201, 3 de 404 y 1 de 502.
Sólo incluye método, URL, estado, Content-Type, Cache-Control y un booleano
que indica si se envió Cookie. Los metadatos de cookies tienen su valor omitido.
Una de las respuestas 404 corresponde al favicon inexistente; no es un fallo
de carga de la interfaz. Las capturas son de páginas, no de paneles F12.

## Revisión manual de los paneles DevTools

Configurar los nombres siguiendo la [guía de fase 3](03-nginx-hosts-virtuales.md).
Abrir `http://sitio1.local:8080/sesiones` y DevTools con F12:

1. En Network, activar Preserve log y Disable cache. Crear, incrementar,
   consultar y destruir una sesión. Revisar métodos, rutas y estados.
2. Seleccionar POST /api/sesion: Headers mostrará 201 y Set-Cookie; Response
   mostrará activa=true y contador=0. Las siguientes solicitudes enviarán Cookie.
3. En Application → Storage → Cookies, comprobar app1.sid, host, Path,
   HttpOnly, SameSite, expiración y Secure. Ocultar el valor al capturar el panel.
4. Abrir sitio2.local: usa app2.sid y su propio contador. Volver a sitio1.local
   conserva su contador hasta destruir la sesión o expirar/reiniciar el backend.
5. Abrir /no-existe y /pruebas/502; comprobar 404 y 502 en Network y HTML
   personalizado en pantalla. Repetir en el segundo host.

El usuario confirmó manualmente el ciclo de sesiones y su aislamiento entre
hosts, y aportó capturas de Network con creación 201 e incrementos 200. Quedan
pendientes conservar esas capturas en el repositorio y completar la inspección
manual de Application/Cookies y de los errores en Network. Las observaciones
automatizadas por CDP sí comprobaron atributos de cookies y estados 404/502.

## Logs y comprobaciones complementarias

```powershell
.\scripts\Test-VirtualHosts.ps1
.\scripts\Test-ErrorPages.ps1
.\scripts\Test-NginxLogs.ps1
.\scripts\Test-Backends.ps1
.\scripts\Test-Sessions.ps1
.\scripts\Test-SessionConcurrency.ps1
docker compose exec -T nginx nginx -t
docker compose ps -a
```

Test-NginxLogs genera peticiones identificables y comprueba host, método,
ruta, estado, IP, fecha y upstream en los archivos y en Docker. El access log
registra 200/404/502; el error log explica el cierre del upstream que causa 502.
Estas pruebas no requieren detener contenedores. Las opciones de parada y
reinicio de fases anteriores son demostraciones adicionales, ya documentadas.

## Fuentes oficiales

- [curl: manual de opciones](https://curl.se/docs/manpage.html).
- [Chrome DevTools: Network](https://developer.chrome.com/docs/devtools/network/reference).
- [Chrome DevTools: Cookies](https://developer.chrome.com/docs/devtools/application/cookies).
- [Chrome: ejecución headless](https://developer.chrome.com/docs/automation-and-testing/headless).
- [Chrome DevTools Protocol: Network](https://chromedevtools.github.io/devtools-protocol/tot/Network/).

Fuentes consultadas durante esta fase; fecha de contexto del trabajo: 8 de
octubre de 2026. Las evidencias curl conservan la hora UTC de ejecución.
