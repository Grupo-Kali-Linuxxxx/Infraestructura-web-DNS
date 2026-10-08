# Evidencias ejecutadas: fase 4

Fecha de sesión: 8 de octubre de 2026, según contexto del usuario.
Los mensajes de Nginx mostrados abajo llevan fecha UTC.

| Prueba | Resultado observado |
|---|---|
| `nginx -t` previo a recarga | Configuración válida |
| Construcción app1 y app2 | Correcta |
| `nginx -s reload` | Señal enviada correctamente |
| `/no-existe` en ambos hosts | HTTP 404, HTML personalizado, Cache-Control no-store |
| `/errors/no-existe` en ambos hosts | 404 generado por Nginx, HTML personalizado |
| Acceso directo `/errors/404.html` y `/errors/502.html` | HTTP 404 personalizado; ubicaciones internas protegidas |
| Host desconocido `/errors/no-existe` | HTTP 404 personalizado en servidor predeterminado |
| `/pruebas/502` en ambos hosts | HTTP 502 real por cierre anticipado de conexión, HTML personalizado |
| Parada app1 | Host 1 devolvió HTTP 504; host 2 continuó HTTP 200 |
| Restauración app1 | Host 1 recuperó HTTP 200 |
| Parada app2 | Host 2 devolvió HTTP 504; host 1 continuó HTTP 200 |
| Restauración app2 | Host 2 recuperó HTTP 200 |
| Script fase 4 con `-IncludeBackendFailure` | Terminó sin excepciones |
| Script fase 3 después de las pruebas | Cinco mensajes PASS |
| Consulta directa a ambos backends `/no-existe` | HTTP/1.1 404 Not Found y texto Recurso no encontrado en APP1/APP2 |
| `node --check server.js` en ambos | Sin errores de sintaxis |
| Estado final | Cuatro servicios Up; Ubuntu healthy |

Extractos de los logs reales:

```text
"GET /pruebas/502 HTTP/1.1" 502 1648
upstream prematurely closed connection while reading response header from upstream

"GET / HTTP/1.1" 504 167
upstream timed out (110: Operation timed out) while connecting to upstream

connect() failed (111: Connection refused) while connecting to upstream
```

Los errores de comunicación provocados por las pruebas son esperados; no se
borraron los logs. La página 404 tenía 1605 bytes y la 502 1648 bytes en estas
respuestas, con contenido HTML y código de estado conservado.

## Fallos investigados y correcciones

1. El script inicial tenía una interpolación PowerShell con `:` inmediatamente
   después de una variable. Se corrigió usando `${HostName}${Path}`; esa
   ejecución falló antes de detener ningún backend.
2. La primera prueba de parada suponía un 502, pero recibió 504. El bloque
   finally restauró app1. Se leyeron access/error logs y se confirmó timeout
   de conexión. No se ocultó el fallo ni se cambió el código HTTP.
3. Se añadió `/pruebas/502` como mecanismo académico explícito de cierre de
   conexión. Se reconstruyeron los backends, se validó y recargó Nginx, y se
   volvió a ejecutar toda la prueba. Los 502 personalizados fueron verificados
   en ambos sitios; las paradas se registraron como 504 y se verificó recuperación.

## Pendientes

No se ejecutó una revisión visual en navegador ni se tomaron capturas DevTools.
Las páginas tienen CSS propio, pero su aspecto debe revisarse manualmente
siguiendo la guía. 504 no tiene página personalizada en esta implementación.
La aceptación humana está pendiente. No se ejecutó commit ni push.
