# Evidencias ejecutadas: fase 6

Fecha de sesión: 8 de octubre de 2026, según contexto del usuario.
No se realizaron capturas de navegador en esta fase.

| Comprobación | Resultado observado |
|---|---|
| Generación package-lock de app1/app2 | Completada usando Node en Docker, sin instalación local en Windows |
| npm ci durante build | Ambos árboles instalados; 68 paquetes por aplicación |
| npm ls --omit=dev --depth=0 | Express 5.2.1 en ambas aplicaciones |
| node --version | v22.23.3 en la imagen de app1 |
| id en ambos backends | uid=1000(node), gid=1000(node) |
| Validación Compose y nginx -t | Correctas |
| Espera de healthchecks | Ambos backends healthy |
| Test-Backends.ps1 | Dos PASS, uno por aplicación |
| GET /health y /api/info | HTTP 200, JSON de la aplicación correspondiente |
| POST /api/eco con mensaje válido | HTTP 200; texto devuelto con espacios extremos retirados |
| JSON mal formado, mensaje numérico, cuerpo array | HTTP 400, JSON de error |
| Content-Type text/plain | HTTP 415, JSON de error |
| Charset JSON iso-8859-1 | HTTP 415, JSON de error |
| Cuerpo JSON de aproximadamente 9 KB | HTTP 413, JSON de error |
| GET /api/eco | HTTP 405, JSON y Allow: POST |
| /api/no-existe mediante Nginx | HTTP 404 JSON, conservado por el proxy |
| /api/pruebas/error | HTTP 500, sin stack ni detalle de la excepción en respuesta |
| /health después del error 500 | HTTP 200; proceso sigue activo |
| Test-VirtualHosts.ps1 | Cinco PASS; hosts y cabeceras conservados |
| Test-ErrorPages.ps1 | 404/502 HTML e internal pasan; sin paradas de contenedores |
| Test-NginxLogs.ps1 | Tres PASS; archivos y salida Docker conservados |
| npm run check en ambos | Sin errores de sintaxis |
| npm audit en ambos | found 0 vulnerabilities, código de salida 0 |
| Reinicio controlado de app1/app2 | Logs Cerrando servidor y nuevo arranque; ambos healthy |
| /health por Nginx después de reinicio | JSON estado ok de APP1 y APP2 |

Respuestas reales después del reinicio:

```json
{"estado":"ok","aplicacion":"APP1"}
```

```json
{"estado":"ok","aplicacion":"APP2"}
```

Los logs de las demostraciones de 500 mostraron:

```text
[APP1] Error interno gestionado por Express.
[APP2] Error interno gestionado por Express.
```

No se imprimieron los detalles de la excepción al cliente. La prueba de
reinicio registró `[APP1] Cerrando servidor.` y `[APP2] Cerrando servidor.`
antes de los mensajes de nuevo arranque.

Pendientes: sesiones/cookies, revisión humana, capturas DevTools y entregables
finales. No se ejecutó commit ni push.
