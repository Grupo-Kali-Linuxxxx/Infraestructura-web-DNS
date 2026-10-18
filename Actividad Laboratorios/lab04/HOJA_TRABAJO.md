# Laboratorio 4 — Hoja de trabajo: el portal para padres (PHP-FPM y proxy inverso detrás de Nginx)

Nombre: ______________________   Fecha: ___/___/2026   Entorno: [ ] VirtualBox  [ ] Docker

Usuario de prueba del portal: `mamani.rosa` · contraseña `Horizonte2026`.

## Parte A — El peligro de una configuración a medias (hazlo PRIMERO)
1. `sudo bash instalar_portal.sh` con los archivos tal como vienen (con TODO).
2. `curl -i -H "Host: portal.horizonte.internal" http://127.0.0.1/app/datos.php`
   ¿Qué `Content-Type` devuelve? ¿Qué ves en el cuerpo? ¿Qué podría hacer un atacante con eso?
3. `bash verificar_lab04.sh` → ____ de 16.

## Parte B — Completa la configuración (10 TODO en total)
| Archivo | TODO | Qué aprendes |
|---|---|---|
| `nginx/horizonte-portal.conf` | 4 | root en public/, FastCGI, proxy inverso, página 502 |
| `portal/app/sesion.php` | 2 | cookie HttpOnly y SameSite |
| `portal/public/entrar.php` | 1 | regenerar el ID de sesión |
| `systemd/horizonte-eco.service` | 3 | usuario sin privilegios, ExecStart, reinicio automático |

Después de cada cambio: `sudo bash instalar_portal.sh` y `bash verificar_lab04.sh` → objetivo **16 de 16**.

## Parte C — Sesiones por dentro
1. Entra al portal desde el navegador de tu PC. DevTools > Application > Cookies: anota nombre, valor (primeros 6
   caracteres), HttpOnly, SameSite.
2. En el servidor: `sudo ls -l /var/lib/php/sessions` y `sudo cat` del archivo `sess_<tu ID>`. ¿Qué guarda?
   ¿Dónde está tu nombre: en la cookie o en el servidor?
3. Cierra sesión y repite: ¿qué pasó con el archivo?

## Parte D — FastCGI y proxy inverso
1. `curl -H "Host: portal.horizonte.internal" -H "X-Forwarded-For: 203.0.113.9" http://127.0.0.1/api/eco`
   ¿Qué valor tiene `cliente` y qué valores `X-Forwarded-For` y `X-Real-IP`? ¿Quién agregó cada uno?
2. `ps -o user,pid,cmd -C php-fpm8.3` y `ls -l /run/php/`: ¿qué usuario ejecuta PHP? ¿Qué es el `.sock`?

## Parte E — Provoca un 502 Bad Gateway
1. `sudo systemctl stop php8.3-fpm` → abre el portal. ¿Qué ve el padre? ¿Qué código devuelve?
2. `sudo tail -1 /var/log/nginx/horizonte-portal.error.log` → copia el mensaje.
3. `sudo systemctl start php8.3-fpm`. Repite con `horizonte-eco` y `/api/eco`.
4. Entra con una contraseña incorrecta y busca `acceso fallido` en el error.log del portal.

## Reflexión
¿Qué diferencia hay entre FastCGI (PHP-FPM) y un proxy inverso HTTP (la API)? ¿Por qué el código de la aplicación
debe estar fuera de la carpeta pública?
