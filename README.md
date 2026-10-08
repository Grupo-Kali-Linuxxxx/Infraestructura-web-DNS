# Laboratorio web con Docker

Dos hosts virtuales en Nginx, dos backends Node.js con sesiones y un contenedor Ubuntu para usuarios, paquetes y systemctl.

## Iniciar

Desde PowerShell en esta carpeta:

```powershell
docker desktop start
docker compose up -d --build
.\scripts\Test-Project.ps1
```

Abrir [Sitio 1](http://sitio1.local:8080/) y [Sitio 2](http://sitio2.local:8080/). El archivo hosts debe contener `127.0.0.1 sitio1.local sitio2.local`. En este equipo ya está configurado.

## Pruebas y capturas

- [Pruebas HTTP](scripts/Test-Project.ps1): dos sitios, errores y sesiones.
- [Pruebas Linux](scripts/Test-Linux.ps1): usuarios, paquetes, sudo y systemctl.
- [Capturas y diagrama](screenshots)

Las pruebas muestran resultados en pantalla y no crean la carpeta `docs`.
Para guardar los resultados HTTP en un archivo elegido, usar
`.\scripts\Test-Project.ps1 -OutputPath "$env:TEMP\pruebas-http.json"`.

## Estructura

```text
backend/         Aplicaciones Node.js y páginas HTML
nginx/           Hosts virtuales, logs y páginas de error
ubuntu-server/   Usuarios, paquetes y servicio Linux
scripts/         Pruebas reproducibles en PowerShell
screenshots/     Cuatro capturas reales y el diagrama
docker-compose.yml
```

No se necesita instalar Node.js en Windows. Para detener: `docker compose stop`. Para retomar: `docker compose up -d`. Las sesiones están en memoria y se pierden al reiniciar el backend. Ubuntu privilegiado se usa para la práctica de systemd. El acceso web es HTTP local en 127.0.0.1:8080.

## Integración del trabajo del grupo

Se integró `main` del [repositorio del grupo](https://github.com/Grupo-Kali-Linuxxxx/Infraestructura-web-DNS),
hasta el commit `f5c3926`, con la implementación local. Se conservan los cinco
usuarios y el grupo `administradores` del compañero, sus paquetes Linux, sudo,
el hostname y el arranque de systemd. Las páginas, sesiones y configuraciones
de Nginx pertenecen a la implementación local y siguen funcionando juntas.

`ubuntu-server/Dockerfile` se conserva exactamente como está en `main` del
compañero. `Dockerfile.local` conserva los mismos usuarios, contraseñas y
grupo, agrega la descarga por HTTPS y el servicio de la práctica, y configura
sudo para exigir contraseña por petición del usuario.
Compose utiliza este archivo para construir Ubuntu en este equipo.

## Entrar y cambiar de usuario con contraseña

Desde PowerShell, entrar como adaniel:

```powershell
.\scripts\Enter-Ubuntu.ps1 -Usuario adaniel
```

El script ejecuta `docker exec -it --user nobody ubuntu-server su - adaniel`.
Se empieza como una cuenta sin privilegios para que se solicite la contraseña.
Escribir `admin123` y pulsar Enter. La contraseña no muestra caracteres al escribir.

Dentro de Ubuntu, comprobar identidad, navegar y cambiar de usuario:

```bash
whoami
id
pwd
ls
cd ~
su - brian
whoami
sudo systemctl status lab-demo.service --no-pager
```

Usuarios: `brian`, `charles`, `ketfer`, `marco` y `adaniel`. La contraseña
configurada por el compañero es `admin123` para los cinco. `su - brian` pide
la contraseña de brian. `sudo` pide la del usuario actual cada vez.
Después de entrar como adaniel y cambiar a brian, `exit` regresa a adaniel
y otro `exit` sale del contenedor. Para entrar directamente como otro usuario,
usar `.\scripts\Enter-Ubuntu.ps1 -Usuario marco`, por ejemplo.

El acceso administrativo de Docker como root o con `--user` puede omitir
autenticación Linux. Por eso, para demostrar contraseñas se usa el script
anterior. Esta configuración no puede limitar a quien controla Docker.

```powershell
.\scripts\Test-Linux.ps1
docker compose exec -T ubuntu-server systemctl status ssh --no-pager
docker compose exec -T ubuntu-server journalctl -u lab-demo.service -n 5 --no-pager
```

Ubuntu descarga paquetes por HTTPS con certificados verificados. No publica
SSH en Windows. Los puertos 3000 permanecen dentro de la red Docker.

## Comprobar HTTP y logs

```powershell
curl.exe -v --noproxy "*" http://sitio1.local:8080/diagnostico
docker compose exec -T nginx tail -n 10 /var/log/nginx/sitio1_access.log
docker compose exec -T nginx tail -n 10 /var/log/nginx/sitio1_error.log
```

Errores: `/no-existe` devuelve 404, `/pruebas/500` devuelve 500 y
`/pruebas/502` devuelve 502. Los errores del servidor comparten la página 50x.
En Chrome, F12 y Network muestran método y estado. Application y Cookies
permiten revisar `app1.sid` o `app2.sid`, HttpOnly y SameSite.
