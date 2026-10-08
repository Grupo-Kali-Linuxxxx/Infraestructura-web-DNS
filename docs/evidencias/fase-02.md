# Evidencias ejecutadas: fase 2

Fecha de la sesión: 8 de octubre de 2026 (contexto del usuario, America/La_Paz).
Las marcas de tiempo de las salidas del contenedor están en UTC.
Esta evidencia resume salidas reales de terminal; no contiene capturas de navegador.

| Comprobación | Resultado observado |
|---|---|
| `docker version` | Cliente y Engine 29.8.2; servidor Linux accesible |
| `docker compose version` | v5.5.1 |
| `docker compose config -q` | Código de salida 0 |
| Construcción de Ubuntu | Finalizó correctamente |
| `docker compose ps -a` | Cuatro servicios Up; Ubuntu healthy |
| Puerto Nginx | `127.0.0.1:8080->80/tcp` |
| `/etc/os-release` | Ubuntu 24.04.5 LTS |
| `ps -p 1 -o comm=` | systemd |
| `systemctl is-system-running` | running |
| `systemctl --failed` | 0 unidades fallidas |
| `systemctl is-enabled lab-demo.service` | enabled |
| `systemctl status lab-demo.service` | active (running) |
| `systemd-analyze verify` de la unidad | Código de salida 0, sin diagnósticos |
| `visudo -c` | Archivos sudoers parsed OK |
| `id` de los cinco usuarios | Todos existen y pertenecen a administradores |
| `passwd -S` de los cinco usuarios | Todos con estado L |
| `stat` de los cinco homes | 700, propietario y grupo personal correctos |
| Acceso de ketfer al home de charles | Lectura rechazada |
| `ip -brief addr`, `ip route` | eth0 activa y puerta de enlace presentes |
| `getent hosts app1 app2 nginx` | Los tres nombres resuelven |
| HTTP directo a app1 y app2 desde Ubuntu | HTML APP1 y APP2; curl --fail terminó correctamente |
| HTTP por Nginx desde Ubuntu | Cada Host devolvió su backend |
| Parada por ketfer con sudo limitado | Servicio dejó de estar activo |
| Inicio por ketfer con sudo limitado | Servicio activo |
| Reinicio por ketfer con sudo limitado | Servicio activo |
| `sudo -n /usr/bin/id` por ketfer | Rechazado; resultado negativo esperado |
| `journalctl -u lab-demo.service` | Inicio, parada, reinicio y actividad como ketfer |
| `nginx -t` | Sintaxis correcta y validación satisfactoria |
| curl.exe sitio1.local desde Windows | HTTP/1.1 200 OK, Backend App 1 |
| curl.exe sitio2.local desde Windows | HTTP/1.1 200 OK, Backend App 2 |

Extracto real de la comprobación automatizada bajo ketfer:

```text
ketfer
DETENCION_VERIFICADA
INICIO_VERIFICADO
REINICIO_VERIFICADO
SUDO_NO_AUTORIZADO_RECHAZADO
HOME_AJENO_PROTEGIDO
```

Las herramientas instaladas se comprobaron con `dpkg-query -W`:
sudo, curl, nano, vim, iputils-ping, net-tools, iproute2, procps, systemd y
openssh-server. No se agregaron paquetes a los existentes.

Durante la primera construcción systemd advirtió que la unidad tenía permiso
de ejecución heredado del contexto Windows. Se añadió `chmod 644` al Dockerfile,
se reconstruyó y la advertencia desapareció. La versión final fue la probada.

Pendiente fuera de esta fase: errores 404/502, Express, sesiones/cookies,
DevTools, capturas, informe y defensa. La aceptación humana de estos resultados
está pendiente. No se ejecutó commit, push ni limpieza de imágenes o historial.
