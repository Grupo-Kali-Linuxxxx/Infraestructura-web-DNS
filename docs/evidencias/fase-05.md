# Evidencias ejecutadas: fase 5

Fecha de sesión: 8 de octubre de 2026, según el contexto del usuario.
Las líneas reales de logs están en UTC.

| Comprobación | Resultado |
|---|---|
| Inspección inicial | Archivos por sitio presentes; logs globales enlazados a stdout/stderr |
| `nginx -t` tras modificar | Sintaxis correcta y validación satisfactoria |
| `nginx -s reload` | Señal enviada correctamente |
| Script Test-NginxLogs.ps1 | Tres mensajes PASS, sin excepciones |
| Access log sitio 1 | GET 200, 404 y 502 con IP, fecha, host, ruta y upstream |
| Access log sitio 2 | GET 200, 404 y 502 con los mismos campos |
| Error log de cada sitio | Cierre prematuro del upstream correspondiente a /pruebas/502 |
| `docker compose logs` | Las seis peticiones y los errores de ambos hosts encontrados |
| Estado final | Cuatro servicios Up, Ubuntu healthy |

Identificador real de ejecución:
`fase5-ffd77d9f8c2945db95f13c3ddaf04453`.

Una línea real de sitio 1:

```text
time=2026-10-08T05:53:17+00:00 client=172.18.0.1 host=sitio1.local method=GET request="GET /no-existe?prueba=fase5-ffd77d9f8c2945db95f13c3ddaf04453 HTTP/1.1" status=404 bytes=1605 upstream="172.18.0.2:3000" upstream_status="404" duration=0.002
```

Una línea real de sitio 2:

```text
time=2026-10-08T05:53:17+00:00 client=172.18.0.1 host=sitio2.local method=GET request="GET /pruebas/502?prueba=fase5-ffd77d9f8c2945db95f13c3ddaf04453 HTTP/1.1" status=502 bytes=1648 upstream="172.18.0.4:3000" upstream_status="502" duration=0.002
```

El script encontró el texto `upstream prematurely closed connection` en los
error logs y en la salida Docker, correlacionándolo con el identificador
de esta ejecución y con cada nombre de servidor.

La primera ejecución detectó una interpolación inválida de PowerShell en un
mensaje del script. Se corrigió delimitando la variable, se validó con el
parser de PowerShell y la ejecución posterior terminó correctamente.

No se truncaron archivos ni se reiniciaron contenedores. No se implementó
persistencia o rotación de logs internos. La revisión humana y capturas de
terminal están pendientes. No se ejecutó commit ni push.
