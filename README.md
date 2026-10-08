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

## Informe y pruebas

- [Informe Word](docs/Informe-implementacion.docx)
- [Informe Markdown](docs/INFORME.md): explica los nueve puntos, comandos y defensa.
- [Resultados HTTP](docs/evidencias/pruebas-http.json)
- [Evidencias de ejecución](docs/evidencias)
- [Capturas y diagrama](screenshots)

Los nueve puntos cubren errores 404/50x, logs, sesiones, curl, análisis del navegador, usuarios y paquetes, systemctl, arquitectura y capturas. DevTools Protocol registra tráfico real de Chrome. El informe incluye los pasos para mostrar manualmente Network y Application en la defensa.

## Estructura

```text
backend/         Aplicaciones Node.js y páginas HTML
nginx/           Hosts virtuales, logs y páginas de error
ubuntu-server/   Usuarios, paquetes y servicio Linux
scripts/         Una prueba reproducible en PowerShell
docs/            Informe y evidencias
screenshots/     Cuatro capturas reales y el diagrama
docker-compose.yml
```

No se necesita instalar Node.js en Windows. Para detener: `docker compose stop`. Para retomar: `docker compose up -d`. Las sesiones están en memoria y se pierden al reiniciar el backend. Ubuntu privilegiado se usa para la práctica de systemd. El acceso web es HTTP local en 127.0.0.1:8080.
