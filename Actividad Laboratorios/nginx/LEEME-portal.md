# Falta un archivo: `horizonte-portal.conf`

Escríbelo tú, usando `horizonte-www.conf` como modelo. Debe:

1. Escuchar en el puerto 80 (IPv4 e IPv6) con el nombre `portal.horizonte.internal`.
2. Servir `/srv/horizonte/portal` con `index.html`.
3. Tener registros propios: `horizonte-portal.access.log` (formato `horizonte`) y `horizonte-portal.error.log`.
4. `try_files $uri $uri/ =404;` y bloquear archivos ocultos.

En la clase 4 este sitio se conectará con PHP-FPM, así que mantenlo simple y ordenado.
