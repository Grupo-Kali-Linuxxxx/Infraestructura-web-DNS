# Evidencias ejecutadas — fase 8

Fecha de contexto: 2026-10-08. No se atribuye aceptación humana de resultados.

| Comprobación ejecutada | Resultado |
|---|---|
| Export-HttpEvidence.ps1 | 22 peticiones curl -v; todos los estados esperados |
| Chrome 154.0.8037.97, headless y CDP | Botones y sesiones comprobados en los dos hosts |
| APP1 y APP2 | Contadores 2 y 1; independientes al navegar entre hosts |
| Cookies | Host propio, HttpOnly, SameSite Lax; inaccesibles por document.cookie |
| Destrucción y recreación desde interfaz | Cookie eliminada, sesión inactiva y nueva sesión desde 0 |
| Network por CDP | 23 respuestas; estados 200/201/404/502 presentes |
| Páginas 404 y 502 en Chrome | Títulos esperados y capturas reales guardadas |
| Test-VirtualHosts.ps1 | Hosts, backend y cabeceras correctos |
| Test-ErrorPages.ps1 | HTML y códigos correctos en ambos hosts y ubicaciones internas protegidas |
| Test-NginxLogs.ps1 | Accesos 200/404/502 y causa del 502 presentes en archivos y Docker |
| Test-Backends.ps1 | API y errores 400/404/405/413/415/500 correctos |
| Test-Sessions.ps1 | Persistencia, aislamiento, firma, destrucción y regeneración correctos |
| nginx -t | syntax is ok; test is successful |
| docker compose ps -a | Cuatro servicios activos; APP1, APP2 y Ubuntu healthy |

Los scripts de regresión se ejecutaron sin las opciones de detener/reiniciar
servicios. El 502 se produjo mediante el endpoint de prueba de cierre de
conexión. Las cookies de prueba se destruyeron y se eliminaron los temporales.

## Artefactos

- [Extractos reales de curl -v](curl-fase-08.md), con valores de cookies omitidos.
- [Registro Network y metadatos Cookies de Chrome](browser-fase-08.json).
- [APP1 activa, contador 2](../../screenshots/app1-sesion.png).
- [APP2 activa, contador 1](../../screenshots/app2-sesion.png).
- [APP1 después de destruir la sesión](../../screenshots/app1-sesion-destruida.png).
- [Página 404](../../screenshots/error-404.png).
- [Página 502](../../screenshots/error-502.png).

Las imágenes muestran páginas renderizadas a 1280 × 900. No son capturas
de los paneles DevTools ni incluyen barra de dirección. El JSON proviene de
eventos Network y consultas Cookies reales mediante CDP, no de datos simulados.

## Corrección durante la prueba

La primera ejecución del script de navegador falló porque resultados de
operaciones asíncronas .NET se mezclaban con la respuesta CDP. Se descartaron
explícitamente esos retornos con `[void]` y se repitió la prueba completa:
los cuatro grupos PASS terminaron correctamente y se generaron las evidencias.

## Pendientes al cierre original de fase 8

Revisión humana, capturas manuales de los paneles Network/Headers y
Application/Cookies, y aceptación de la fase. No se modificó hosts de Windows.
No se preparó todavía el informe APA ni la presentación; corresponden a
fases posteriores. No se realizó commit ni push.

## Comprobaciones posteriores

Se configuraron los dos nombres en hosts de Windows con respaldo y sin cambiar
entradas anteriores; curl sin --resolve y Chrome con -UseSystemResolution
comprobaron el acceso normal. El usuario aportó capturas de Network con 201/200
y confirmó persistencia, destrucción, recreación e independencia de sesiones.
La inspección manual de atributos de cookies y errores, y la conservación de
las capturas de paneles en el repositorio, siguen pendientes. El informe APA
y la presentación quedaron a cargo de otra persona por indicación del usuario.
