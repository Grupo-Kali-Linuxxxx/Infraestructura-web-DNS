# Infraestructura Web Linux

Proyecto académico de implementación de una arquitectura
cliente-servidor utilizando Docker, Nginx y Node.js.

Consulta la [guía completa del trabajo realizado](docs/GUIA-COMPLETA.md):
arquitectura, instalación, configuraciones, comandos, pruebas y correcciones.

## Inicio rápido desde PowerShell

```powershell
.\scripts\Initialize-Environment.ps1
docker compose config -q
docker compose up -d --build
```

El primer comando crea secretos locales en `.env` sin mostrarlos y conserva
un archivo existente. No subir `.env` ni archivos de cookies al repositorio.
Para el navegador, ejecutar `.\scripts\Initialize-LocalHosts.ps1` o seguir la
[guía de hosts](docs/03-nginx-hosts-virtuales.md). El script conserva las entradas
existentes y guarda un respaldo; requiere elevación si modifica el archivo de Windows.

## Tecnologías

- Docker
- Docker Compose
- Nginx
- Node.js
- Express
- Git
- GitHub
- curl
- DevTools

## Arquitectura

La infraestructura está compuesta por:

- Un servidor web Nginx.
- Dos hosts virtuales.
- Dos aplicaciones backend Node.js.
- Una red Docker privada.
- Proxy inverso mediante Nginx.
- Manejo de sesiones y cookies.
- Registro de peticiones mediante logs.

## Estructura

```text
Infraestructura-web-DNS/
├── backend/
│   ├── app1/
│   └── app2/
├── docs/
├── nginx/
│   ├── conf.d/
│   └── errors/
├── screenshots/
├── scripts/
├── ubuntu-server/
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md
```

## Avance verificado: fase 2

Docker y los cuatro contenedores están funcionando. Ubuntu ejecuta systemd
como PID 1 y el servicio académico `lab-demo.service`. Los cinco usuarios
tienen contraseñas bloqueadas, directorios privados y sudo limitado al control
de esa unidad. Nginx publica únicamente `127.0.0.1:8080`.

- [Guía de Docker, Ubuntu, usuarios, red y systemctl](docs/02-docker-ubuntu.md).
- [Evidencias de pruebas ejecutadas](docs/evidencias/fase-02.md).
- [Bitácora de inteligencia artificial](docs/bitacora-ia.md).

Los hosts actuales son `sitio1.local` y `sitio2.local`. Las capturas de páginas
se incorporaron en fase 8 dentro de `screenshots/`. El informe técnico sigue pendiente.

## Avance verificado: fase 3

Los dos hosts virtuales y las cabeceras del proxy están comprobados. Cada
backend dispone de `GET /diagnostico` para mostrar los datos de esa petición.
La configuración se validó con `nginx -t` antes de recargar Nginx.

- [Guía de Nginx y hosts virtuales](docs/03-nginx-hosts-virtuales.md).
- [Evidencias ejecutadas de fase 3](docs/evidencias/fase-03.md).

Prueba reproducible desde PowerShell, sin modificar el archivo hosts de Windows:

```powershell
.\scripts\Test-VirtualHosts.ps1
```

El acceso por nombre se comprobó en Chrome con resolución temporal en fase 8.
Para navegar manualmente y capturar paneles DevTools, seguir la guía de hosts.
Los errores personalizados corresponden a fase 4.

## Avance verificado: fase 4

Ambos hosts sirven páginas HTML propias para 404 y 502. Las rutas inexistentes
de Node.js devuelven 404 real y Nginx sustituye el cuerpo por la página
personalizada. `/pruebas/502` cierra deliberadamente la conexión del backend
para demostrar un 502 generado por Nginx sin detener el proceso.

- [Guía de páginas de error](docs/04-paginas-error.md).
- [Evidencias ejecutadas de fase 4](docs/evidencias/fase-04.md).
- [Comparación con el aporte del compañero](docs/referencias/aporte-companero.md).

Desde PowerShell:

```powershell
.\scripts\Test-ErrorPages.ps1
```

La opción `-IncludeBackendFailure` añade paradas controladas y restauración
de los backends. En este equipo esas paradas produjeron 504 por timeout;
ese código se conserva. La fase 8 incorpora capturas reales de las páginas de error.

## Avance verificado: fase 5

Cada host registra IP, fecha, método, ruta, estado y datos del upstream.
Access logs y error logs se conservan por sitio y también se envían a Docker.

- [Guía de logs y comandos de consulta](docs/05-logs-nginx.md).
- [Evidencias ejecutadas de fase 5](docs/evidencias/fase-05.md).

Desde PowerShell:

```powershell
.\scripts\Test-NginxLogs.ps1
docker compose logs --tail 20 nginx
```

Los archivos internos no tienen volumen persistente ni rotación; la guía
explica cómo conservar extractos antes de recrear el contenedor.

## Avance verificado: fase 6

Ambos backends utilizan Express, dependencias bloqueadas mediante npm ci y
ejecución como usuario node. Incluyen /health, /api/info y POST /api/eco, con
validación de JSON y manejo controlado de errores. Nginx conserva las
respuestas JSON de /api/ y las páginas HTML de error fuera de esa ubicación.

- [Guía de backends Express](docs/06-backends-express.md).
- [Evidencias ejecutadas de fase 6](docs/evidencias/fase-06.md).

Desde PowerShell:

```powershell
.\scripts\Test-Backends.ps1
docker compose ps -a
```

Las pruebas de fases anteriores siguen pasando. Las sesiones y cookies
se incorporaron después en fase 7.

## Avance verificado: fase 7

Ambos sitios incluyen `/sesiones` y una API para crear, consultar, incrementar
y destruir sesiones. Sus cookies son HttpOnly y SameSite Lax, con secretos
independientes del entorno. Se usa HTTP local y MemoryStore exclusivamente
para demostrar el concepto; los datos se pierden al reiniciar el backend.

- [Guía de sesiones, cookies y DevTools](docs/07-sesiones-cookies.md).
- [Evidencias ejecutadas de fase 7](docs/evidencias/fase-07.md).

Desde PowerShell:

```powershell
.\scripts\Test-Sessions.ps1
```

La opción `-IncludeRestart` demuestra además la pérdida de sesiones al
reiniciar. La API y el HTML se comprobaron por HTTP en fase 7; los botones y
las capturas reales se verificaron después en Chrome durante fase 8.

## Avance verificado: fase 8

Se ejecutaron 22 peticiones curl -v y pruebas reales en Chrome mediante
DevTools Protocol. Se comprobaron los dos hosts, proxy, cabeceras, sesiones,
cookies y errores 404/502. Todas las suites anteriores siguen pasando.

- [Guía de HTTP, curl y DevTools](docs/08-pruebas-http-devtools.md).
- [Resultados y evidencias de fase 8](docs/evidencias/fase-08.md).
- [Extractos curl con cookies omitidas](docs/evidencias/curl-fase-08.md).
- [Capturas reales de funcionamiento](screenshots/README.md).

Desde PowerShell 7, con Docker activo y Chrome instalado:

```powershell
.\scripts\Export-HttpEvidence.ps1
.\scripts\Test-Browser.ps1 -UseSystemResolution
```

El navegador de prueba usa un perfil temporal. Por defecto resuelve los nombres
dentro de Chrome; -UseSystemResolution utiliza hosts de Windows, ya configurado
y comprobado en este equipo. El usuario confirmó manualmente el ciclo de sesiones
y su aislamiento entre sitios. Quedan pendientes la inspección manual de atributos
de cookies y errores, y guardar las capturas de paneles DevTools en el repositorio.
La documentación restante, el informe y la presentación quedaron a cargo de otra
persona. La guía y las evidencias se incluyen junto con el código del repositorio.

## Correcciones tras la auditoría

Ambos backends ordenan las modificaciones por sesión y leen el contador actualizado
antes de incrementar. Los montajes de configuración y páginas Nginx son de sólo
lectura dentro del contenedor. La regresión de concurrencia se ejecuta con:

```powershell
.\scripts\Test-SessionConcurrency.ps1
```

Los resultados de la corrección están en las [evidencias de auditoría](docs/evidencias/correcciones-auditoria.md).
