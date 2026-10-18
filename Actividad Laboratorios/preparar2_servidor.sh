#!/bin/bash
USUARIO=$1

# TODO 1: Actualizar lista de paquetes e instalar htop y tree
apt update && apt install -y htop tree

# TODO 2: Habilitar e iniciar el servicio SSH
systemctl enable --now ssh

# TODO 3: Crear el grupo webadmin (idempotente)
getent group webadmin >/dev/null || groupadd webadmin

# TODO 4: Crear la carpeta con root:webadmin y permisos 2775
install -d -o root -g webadmin -m 2775 /srv/horizonte/www

# TODO 5: Crear el usuario pasado por argumento y agregarlo a sudo y webadmin
id -u "$USUARIO" >/dev/null 2>&1 || useradd -m -G sudo,webadmin "$USUARIO"

# TODO 6: Asegurar que el usuario pertenezca a los grupos sudo y webadmin si ya existía
usermod -aG sudo,webadmin "$USUARIO"

# TODO 7: Agregar entrada a /etc/hosts si no existe
grep -q "www.horizonte.internal" /etc/hosts || echo "127.0.1.1 www.horizonte.internal" >> /etc/hosts