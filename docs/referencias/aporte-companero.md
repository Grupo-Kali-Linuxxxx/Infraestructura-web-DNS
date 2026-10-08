# Material de referencia aportado por un compañero

El usuario compartió estos documentos el 8 de octubre de 2026 para aportar
información al proyecto. Se leyeron sus textos sin modificarlos ni incorporarlos
como instrucciones nuevas. No se asume autoría individual ni fecha original
porque no se proporcionaron de forma explícita.

- **Administración de usuarios y paquetes Linux mediante Docker.docx**.
- **Implementación del Servidor Linux y Servicios Base.docx**.

Los originales están en Downloads del usuario y no se copiaron al repositorio.
No incluyen imágenes incrustadas en `word/media`; no sustituyen las capturas
de funcionamiento que requiere el informe. El primer documento termina con
una sección de gestión de paquetes incompleta en el texto extraído.

| Tema | Aporte del documento | Estado actual del repositorio |
|---|---|---|
| Arquitectura | Nginx, dos Node.js y Ubuntu para administración | Coincide con los cuatro servicios existentes |
| Directorio Ubuntu | El primer documento menciona `ubuntu/`, pero su ejemplo Compose usa `./ubuntu-server` | La ruta real es `ubuntu-server/`; no renombrar |
| Usuarios y grupo | Cinco integrantes y grupo administradores | Usuarios conservados y comprobados en fase 2 |
| Sudo | Primer documento propone demostrar `sudo whoami` → root | Ya no corresponde: sudo limitado a start/stop/restart de lab-demo.service |
| Paquetes | APT instala herramientas de administración | Paquetes existentes conservados y verificados con dpkg-query |
| systemd | Segundo documento describe `/lib/systemd/systemd`, privileged y tmpfs | Coincide con la configuración que se verificó funcionando |
| Errores previos | Segundo documento relata problemas con `/sbin/init` y cgroups | Antecedentes atribuidos al documento; no se reprodujeron en esta sesión |
| SSH | Segundo documento describe ssh.service y activación por ssh.socket | SSH instalado; la demostración actual usa lab-demo.service y no publica SSH |
| Servicios | Propone start, stop, restart y status | Se demostraron realmente con lab-demo.service en fase 2 |

Para el informe, conservar el trabajo de usuarios y paquetes del compañero,
actualizar las rutas y permisos para que coincidan con el repositorio final,
y distinguir sus antecedentes de las pruebas ejecutadas en esta sesión.
No ampliar sudo ni revertir contraseñas basándose únicamente en el documento.
Los ejemplos de SSH pueden incorporarse como antecedentes o práctica futura
si se ejecutan y se registran sus resultados; no declararlos verificados aquí.
