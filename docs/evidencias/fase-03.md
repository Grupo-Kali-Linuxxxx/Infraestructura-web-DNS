# Evidencias ejecutadas: fase 3

Fecha de sesión: 8 de octubre de 2026, según el contexto del usuario.
Las salidas de Nginx llevan fechas UTC. Se usaron pruebas reales de terminal,
sin sustituirlas por capturas de navegador.

| Prueba | Resultado observado |
|---|---|
| Configuración activa inicial, `nginx -T` | Dos hosts y upstreams correctos; configuración global no modificada |
| `nginx -t` antes de aplicar | Correcto |
| Construcción app1 y app2 | Ambas imágenes construidas correctamente |
| Validación posterior y `nginx -s reload` | Correctas; señal de recarga enviada |
| Script `Test-VirtualHosts.ps1` | Cinco mensajes PASS, sin excepciones |
| GET `/` de sitio1.local | HTTP 200, Backend App 1 |
| GET `/` de sitio2.local | HTTP 200, Backend App 2 |
| GET `/diagnostico?prueba=fase3` de ambos | Query string y método conservados, HTTP/1.1 hacia backend |
| GET `/diagnostico` usando URL por nombre y `--resolve` | Ambos HTTP/1.1 200 OK, Content-Type application/json, Cache-Control no-store |
| Cabeceras del proxy | Host correcto, X-Real-IP presente, X-Forwarded-For con IP observada, X-Forwarded-Proto http |
| Cabeceras IP/protocolo falsas enviadas por cliente | X-Real-IP y X-Forwarded-Proto sobrescritos |
| X-Forwarded-For enviado por cliente | Prefijo conservado, IP vista por Nginx añadida al final |
| Host desconocido | HTTP 200, respuesta de diagnóstico de Nginx; no backend |
| `node --check server.js` en ambos backends | Código de salida 0 |
| Logs por host | Solicitudes de las pruebas presentes con HTTP 200 |
| Estado final y Compose | Cuatro contenedores Up, Ubuntu healthy; Compose válido |

Respuesta real de APP1:

```json
{
  "aplicacion": "APP1",
  "metodo": "GET",
  "ruta": "/diagnostico",
  "versionHttp": "1.1",
  "host": "sitio1.local",
  "ipConexion": "172.18.0.5",
  "xRealIp": "172.18.0.1",
  "xForwardedFor": "172.18.0.1",
  "xForwardedProto": "http"
}
```

APP2 devolvió los mismos valores de red observados, con `aplicacion: APP2`
y `host: sitio2.local`. Las IP son evidencia de esta ejecución, no valores
fijos para configurar.

En las peticiones curl por URL, el cliente envió `Host: sitio1.local:8080`
o `sitio2.local:8080`; el backend recibió el nombre sin puerto por `$host`.
La conexión TCP del backend provenía de Nginx, distinta de la dirección
de cliente que Nginx incorporó a las cabeceras.

No se modificó el archivo hosts de Windows, no se verificó DNS local por nombre
sin `--resolve` y no se tomaron capturas DevTools. Estas acciones manuales están
pendientes y se explican en la guía. Tampoco se implementaron errores 404/502,
Express ni sesiones en esta fase. No se ejecutó commit ni push.
