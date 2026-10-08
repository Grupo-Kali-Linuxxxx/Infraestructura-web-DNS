# Fase 4: páginas de error personalizadas

## Implementación

Se añadieron `nginx/errors/404.html` y `502.html`, con HTML y CSS autónomos,
sin dependencias externas. La página 404 usa azul y explica que el recurso
solicitado no está disponible; la 502 usa tonos ámbar y explica el problema
temporal de comunicación con el backend. Ambas permiten volver al inicio
del mismo host y se adaptan a pantallas pequeñas.

La configuración común está en `nginx/conf.d/snippets/errors.conf`, incluida
dentro de los tres bloques `server`. El include global `conf.d/*.conf` no
carga directamente los archivos de esa subcarpeta.

```nginx
error_page 404 /errors/404.html;
error_page 502 /errors/502.html;

location = /errors/404.html {
    internal;
    root /usr/share/nginx/html;
    charset utf-8;
    add_header Cache-Control "no-store" always;
}
```

Existe una ubicación equivalente para 502. El montaje de `nginx/errors` en
Compose ya existía y no fue necesario modificarlo. Los archivos HTML se
sirven desde Nginx: no dependen de que Node.js esté disponible.

`error_page` realiza una redirección interna, sin enviar al navegador una
redirección 302 ni cambiar el estado original por 200. `internal` impide usar
las páginas de error como recursos públicos normales. Pedir directamente
`/errors/502.html` produce 404; **no** sirve para demostrar un error 502.
`location ^~ /errors/` reserva las demás rutas de ese prefijo a Nginx y
devuelve 404, evitando que se envíen al backend.

## Errores del backend y del proxy

Se añadió `proxy_intercept_errors on` en el `location /` de ambos hosts.
Esto permite que Nginx sustituya el cuerpo de las respuestas 404 que genera
Node.js por el HTML configurado. Sin esa directiva el cuerpo del backend
normalmente llegaría al cliente. Se conservan los códigos de estado.

En ambos backends, las rutas distintas de `/` y de las rutas académicas
definidas devuelven ahora 404 real con texto plano. Antes respondían 200
a cualquier dirección. La prueba directa a `app1:3000/no-existe` permite
comparar el texto del backend con el HTML que entrega Nginx para la misma ruta.

La ruta académica `GET /pruebas/502` cierra deliberadamente el socket de Node.js
antes de enviar cabeceras. Nginx recibe una conexión sin respuesta HTTP válida,
genera un 502 real y sirve la página personalizada. La ruta no detiene el
proceso; el inicio sigue funcionando. Es una demostración controlada de fallo
de comunicación, **no** una caída espontánea del sistema. No debe mantenerse
como funcionalidad de una aplicación de producción.

Una petición directa al backend a esa ruta no devuelve un HTTP 502: al no
haber proxy, el cliente ve una conexión cerrada. El 502 lo genera Nginx.

En fase 4 la intercepción se aplicaba también a futuras respuestas 404 de APIs.
En [fase 6](06-backends-express.md) se añadió una ubicación /api/ con
`proxy_intercept_errors off` para conservar sus errores JSON. El resto
mantiene las páginas HTML personalizadas.

## Diferencia observada entre 502 y 504

Durante la prueba de parada del contenedor se obtuvo HTTP 504 y el error
`upstream timed out ... while connecting to upstream`. El destino no respondió
antes del límite de conexión de tres segundos. No se cambió ese estado a 502.
Durante un rechazo de conexión también se observó un 502.

Por eso no se afirma que detener un contenedor genere siempre 502. El script
de prueba exige el 502 personalizado en `/pruebas/502` y admite 502 o 504
durante una parada de contenedor, mostrando el código real. Sólo se personalizan
404 y 502 en esta fase; 504 conserva el tratamiento predeterminado.

## Validación y pruebas desde PowerShell

Después de modificar archivos Nginx, validar y sólo recargar si la validación
termina correctamente:

```powershell
docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload
```

Los cambios Node.js requieren reconstruir y recrear sus contenedores:

```powershell
docker compose build app1 app2
docker compose up -d --no-deps app1 app2
```

Después validar y recargar Nginx para actualizar la resolución de upstreams.
No es necesario recrear Ubuntu ni ejecutar `docker compose down`.

Prueba cotidiana, sin parar contenedores:

```powershell
.\scripts\Test-ErrorPages.ps1
.\scripts\Test-VirtualHosts.ps1
```

Prueba adicional que detiene brevemente cada backend por turno y comprueba
que el otro sitio funciona y que el detenido se recupera:

```powershell
.\scripts\Test-ErrorPages.ps1 -IncludeBackendFailure
```

La opción requiere acceso al Engine y usa `finally` para restaurar los servicios
incluso ante una excepción. Una interrupción forzada de PowerShell o Docker
puede impedir ejecutar ese bloque; en tal caso usar `docker compose start app1 app2`
y comprobar ambos sitios. Al ejecutar la opción, no usar el servicio para
otras demostraciones simultáneas.

Comprobaciones detalladas:

```powershell
curl.exe --noproxy "*" -v --resolve "sitio1.local:8080:127.0.0.1" http://sitio1.local:8080/no-existe
curl.exe --noproxy "*" -v --resolve "sitio2.local:8080:127.0.0.1" http://sitio2.local:8080/no-existe
curl.exe --noproxy "*" -v --resolve "sitio1.local:8080:127.0.0.1" http://sitio1.local:8080/pruebas/502
curl.exe --noproxy "*" -v --resolve "sitio2.local:8080:127.0.0.1" http://sitio2.local:8080/pruebas/502
docker compose exec -T ubuntu-server curl -i http://app1:3000/no-existe
docker compose exec -T ubuntu-server curl -i http://app2:3000/no-existe
docker compose exec -T nginx tail -n 10 /var/log/nginx/sitio1_error.log
docker compose exec -T nginx tail -n 10 /var/log/nginx/sitio2_error.log
```

No usar `curl --fail` si se pretende leer el cuerpo de un error HTTP;
curl puede terminar correctamente al recibir HTTP 404/502, por lo que el
script verifica explícitamente código, contenido HTML y cabeceras.

## Comprobación manual del diseño

Con los nombres configurados en Windows según la guía de fase 3, abrir en
el navegador `/no-existe` y `/pruebas/502` de ambos sitios. Revisar el diseño,
el botón de inicio y, en DevTools Network, los estados 404 y 502. Capturar
la página y el panel Network para el informe. Al cierre de fase 4 las pruebas
eran de terminal. La [fase 8](08-pruebas-http-devtools.md) incorpora capturas
reales de ambas páginas en sitio1.local y estados HTTP observados mediante
CDP. La revisión humana y las capturas manuales del panel siguen pendientes.

## Fuentes y evidencias

- [Evidencias de la fase 4](evidencias/fase-04.md).
- [Comparación con los documentos del compañero](referencias/aporte-companero.md).
- Nginx. (s. f.). [Module ngx_http_proxy_module: proxy_intercept_errors](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_intercept_errors).
- Nginx. (s. f.). [Module ngx_http_core_module: error_page e internal](https://nginx.org/en/docs/http/ngx_http_core_module.html#error_page).

Consulta de las fuentes: 8 de octubre de 2026.
