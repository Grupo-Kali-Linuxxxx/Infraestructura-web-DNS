# Laboratorio 3 — Hoja de trabajo: Nginx con dos sitios para el colegio

Nombre: ______________________   Fecha: ___/___/2026   Entorno: [ ] VirtualBox  [ ] Docker

## Parte A — Nginx a mano (antes de usar el script)
1. `sudo apt install -y nginx` · `systemctl status nginx` · `nginx -v` → versión: ________
2. `curl -I http://127.0.0.1/` → ¿qué página responde y qué dice la cabecera `Server`?
3. Recorre `/etc/nginx/`: ¿para qué sirven `nginx.conf`, `sites-available/`, `sites-enabled/` y `conf.d/`?
4. ¿Por qué los sitios se "activan" con un enlace simbólico y no copiando el archivo?

## Parte B — Completa la configuración
- `nginx/horizonte-www.conf`: 5 TODO.
- `nginx/00-rechazar-desconocidos.conf`: 1 TODO.
- `nginx/horizonte-portal.conf`: escríbelo completo (lee `nginx/LEEME-portal.md`).

Luego: `sudo bash instalar_sitios.sh` y `bash verificar_lab03.sh` → ____ de 14.

## Parte C — El poder de la cabecera Host
| Comando (en el servidor) | Código | ¿Qué sitio respondió? |
|---|---|---|
| `curl -I -H "Host: www.horizonte.internal" http://127.0.0.1/` | | |
| `curl -I -H "Host: portal.horizonte.internal" http://127.0.0.1/` | | |
| `curl -I -H "Host: horizonte.internal" http://127.0.0.1/inscripciones` | | |
| `curl -v -H "Host: intruso.com" http://127.0.0.1/` | | |
| `curl -I -H "Host: www.horizonte.internal" http://127.0.0.1/no-existe` | | |
| `curl -I -H "Host: www.horizonte.internal" http://127.0.0.1/css/estilo.css` | | |

Explica: una sola IP y un solo Nginx, ¿cómo sabe qué sitio entregar?

## Parte D — Desde el navegador de tu PC
Edita el archivo hosts de tu PC (como administrador):
- Windows: `C:\Windows\System32\drivers\etc\hosts` · Linux/macOS: `/etc/hosts`
- VM: `192.168.56.10  www.horizonte.internal portal.horizonte.internal horizonte.internal`
- Docker: `127.0.0.1  www.horizonte.internal portal.horizonte.internal horizonte.internal` y usa el puerto `:8080`

Abre los dos sitios, una circular y una página inexistente. Captura cada una.

## Parte E — Registros y errores provocados
1. `sudo tail -f /var/log/nginx/horizonte-www.access.log` mientras navegas: explica los campos de una línea.
2. Quita un `;` de `listen 80;` en el portal y ejecuta `sudo nginx -t`. Copia el mensaje. Restaura.
3. Quita el `;` de `index index.html;` y ejecuta `nginx -t`. ¿Falla? ¿Por qué es peligroso?

## Reflexión
¿Por qué siempre `nginx -t` antes de `reload`? ¿Qué diferencia hay entre `reload` y `restart`?
