# Evidencia real de curl -v — fase 8

Valores de Cookie y Set-Cookie omitidos. Sólo se exportan cabeceras seleccionadas; los diagnósticos internos de curl no se publican.

Ejecutado UTC: 2026-10-08 06:25:46Z

## GET http://sitio1.local:8080/

```text
> GET / HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: text/html; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
Cuerpo HTML: Backend App 1
```

## GET http://sitio1.local:8080/diagnostico

```text
> GET /diagnostico HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP1","metodo":"GET","ruta":"/diagnostico","versionHttp":"1.1","host":"sitio1.local","ipConexion":"172.18.0.5","xRealIp":"172.18.0.1","xForwardedFor":"172.18.0.1","xForwardedProto":"http"}
```

## GET http://sitio1.local:8080/no-existe

```text
> GET /no-existe HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 404 Not Found
< Server: nginx/1.31.6
< Content-Type: text/html; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=404
Cuerpo HTML: Recurso no disponible
```

## GET http://sitio1.local:8080/pruebas/502

```text
> GET /pruebas/502 HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 502 Bad Gateway
< Server: nginx/1.31.6
< Content-Type: text/html; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=502
Cuerpo HTML: Servicio temporalmente no disponible
```

## GET http://sitio1.local:8080/api/no-existe

```text
> GET /api/no-existe HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 404 Not Found
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=404
{"error":"Recurso no encontrado.","aplicacion":"APP1"}
```

## GET http://sitio1.local:8080/api/sesion

```text
> GET /api/sesion HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP1","activa":false,"contador":0}
```

## POST http://sitio1.local:8080/api/sesion

```text
> POST /api/sesion HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 201 Created
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
< Set-Cookie: app1.sid=[OMITIDO]; Path=/; Expires=Thu, 08 Oct 2026 06:40:47 GMT; HttpOnly; SameSite=Lax
HTTP_STATUS=201
{"aplicacion":"APP1","activa":true,"contador":0}
```

## POST http://sitio1.local:8080/api/sesion/incrementar

```text
> POST /api/sesion/incrementar HTTP/1.1
> Host: sitio1.local:8080
> Cookie: [OMITIDO]
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
< Set-Cookie: app1.sid=[OMITIDO]; Path=/; Expires=Thu, 08 Oct 2026 06:40:47 GMT; HttpOnly; SameSite=Lax
HTTP_STATUS=200
{"aplicacion":"APP1","activa":true,"contador":1}
```

## GET http://sitio1.local:8080/api/sesion

```text
> GET /api/sesion HTTP/1.1
> Host: sitio1.local:8080
> Cookie: [OMITIDO]
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP1","activa":true,"contador":1}
```

## DELETE http://sitio1.local:8080/api/sesion

```text
> DELETE /api/sesion HTTP/1.1
> Host: sitio1.local:8080
> Cookie: [OMITIDO]
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
< Set-Cookie: app1.sid=[OMITIDO]; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Lax
HTTP_STATUS=200
{"aplicacion":"APP1","activa":false,"contador":0}
```

## GET http://sitio1.local:8080/api/sesion

```text
> GET /api/sesion HTTP/1.1
> Host: sitio1.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP1","activa":false,"contador":0}
```

## GET http://sitio2.local:8080/

```text
> GET / HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: text/html; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
Cuerpo HTML: Backend App 2
```

## GET http://sitio2.local:8080/diagnostico

```text
> GET /diagnostico HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP2","metodo":"GET","ruta":"/diagnostico","versionHttp":"1.1","host":"sitio2.local","ipConexion":"172.18.0.5","xRealIp":"172.18.0.1","xForwardedFor":"172.18.0.1","xForwardedProto":"http"}
```

## GET http://sitio2.local:8080/no-existe

```text
> GET /no-existe HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 404 Not Found
< Server: nginx/1.31.6
< Content-Type: text/html; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=404
Cuerpo HTML: Recurso no disponible
```

## GET http://sitio2.local:8080/pruebas/502

```text
> GET /pruebas/502 HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 502 Bad Gateway
< Server: nginx/1.31.6
< Content-Type: text/html; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=502
Cuerpo HTML: Servicio temporalmente no disponible
```

## GET http://sitio2.local:8080/api/no-existe

```text
> GET /api/no-existe HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 404 Not Found
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=404
{"error":"Recurso no encontrado.","aplicacion":"APP2"}
```

## GET http://sitio2.local:8080/api/sesion

```text
> GET /api/sesion HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP2","activa":false,"contador":0}
```

## POST http://sitio2.local:8080/api/sesion

```text
> POST /api/sesion HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 201 Created
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
< Set-Cookie: app2.sid=[OMITIDO]; Path=/; Expires=Thu, 08 Oct 2026 06:40:47 GMT; HttpOnly; SameSite=Lax
HTTP_STATUS=201
{"aplicacion":"APP2","activa":true,"contador":0}
```

## POST http://sitio2.local:8080/api/sesion/incrementar

```text
> POST /api/sesion/incrementar HTTP/1.1
> Host: sitio2.local:8080
> Cookie: [OMITIDO]
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
< Set-Cookie: app2.sid=[OMITIDO]; Path=/; Expires=Thu, 08 Oct 2026 06:40:47 GMT; HttpOnly; SameSite=Lax
HTTP_STATUS=200
{"aplicacion":"APP2","activa":true,"contador":1}
```

## GET http://sitio2.local:8080/api/sesion

```text
> GET /api/sesion HTTP/1.1
> Host: sitio2.local:8080
> Cookie: [OMITIDO]
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP2","activa":true,"contador":1}
```

## DELETE http://sitio2.local:8080/api/sesion

```text
> DELETE /api/sesion HTTP/1.1
> Host: sitio2.local:8080
> Cookie: [OMITIDO]
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
< Set-Cookie: app2.sid=[OMITIDO]; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Lax
HTTP_STATUS=200
{"aplicacion":"APP2","activa":false,"contador":0}
```

## GET http://sitio2.local:8080/api/sesion

```text
> GET /api/sesion HTTP/1.1
> Host: sitio2.local:8080
< HTTP/1.1 200 OK
< Server: nginx/1.31.6
< Content-Type: application/json; charset=utf-8
< Cache-Control: no-store
HTTP_STATUS=200
{"aplicacion":"APP2","activa":false,"contador":0}
```
