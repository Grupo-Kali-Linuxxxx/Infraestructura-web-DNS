FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    sudo \
    curl \
    nano \
    vim \
    iputils-ping \
    net-tools \
    iproute2 \
    procps \
    systemd \
    openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Crear grupo de administradores
RUN groupadd administradores

# Crear usuarios
RUN useradd -m -s /bin/bash brian && \
    useradd -m -s /bin/bash charles && \
    useradd -m -s /bin/bash ketfer && \
    useradd -m -s /bin/bash marco && \
    useradd -m -s /bin/bash adaniel

# Sin contraseñas incrustadas: acceso al laboratorio mediante docker compose exec.
RUN for usuario in brian charles ketfer marco adaniel; do \
        passwd -l "$usuario" && chmod 700 "/home/$usuario"; \
    done

# Agregar todos los usuarios al grupo administradores
RUN usermod -aG administradores brian && \
    usermod -aG administradores charles && \
    usermod -aG administradores ketfer && \
    usermod -aG administradores marco && \
    usermod -aG administradores adaniel

# Delegar únicamente el control del servicio académico; no dar sudo irrestricto.
COPY administradores.sudoers /etc/sudoers.d/administradores
RUN chmod 440 /etc/sudoers.d/administradores && visudo -cf /etc/sudoers.d/administradores

COPY lab-demo.sh /usr/local/bin/lab-demo
COPY lab-demo.service /etc/systemd/system/lab-demo.service
# Normalizar CRLF al construir desde Windows.
RUN sed -i 's/\r$//' /usr/local/bin/lab-demo /etc/systemd/system/lab-demo.service && \
    chmod 755 /usr/local/bin/lab-demo && \
    chmod 644 /etc/systemd/system/lab-demo.service && \
    systemctl enable lab-demo.service

WORKDIR /home

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
