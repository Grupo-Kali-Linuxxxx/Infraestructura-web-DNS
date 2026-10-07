# Infraestructura Web Linux

Proyecto académico de implementación de una arquitectura
cliente-servidor utilizando Docker, Nginx y Node.js.

## Tecnologías

- Docker
- Docker Compose
- Nginx
- Node.js
- Express
- Git
- GitHub
- curl
- DevTools

## Arquitectura

La infraestructura estará compuesta por:

- Un servidor web Nginx.
- Dos hosts virtuales.
- Dos aplicaciones backend Node.js.
- Una red Docker privada.
- Proxy inverso mediante Nginx.
- Manejo de sesiones y cookies.
- Registro de peticiones mediante logs.

## Estructura

infraestructura-web-linux/
├── backend/
│   ├── app1/
│   └── app2/
├── docs/
├── nginx/
│   ├── conf.d/
│   └── errors/
├── screenshots/
├── .gitignore
├── docker-compose.yml
└── README.md