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

# Establecer contraseñas
RUN echo "brian:admin123" | chpasswd && \
    echo "charles:admin123" | chpasswd && \
    echo "ketfer:admin123" | chpasswd && \
    echo "marco:admin123" | chpasswd && \
    echo "adaniel:admin123" | chpasswd

# Agregar todos los usuarios al grupo administradores
RUN usermod -aG administradores brian && \
    usermod -aG administradores charles && \
    usermod -aG administradores ketfer && \
    usermod -aG administradores marco && \
    usermod -aG administradores adaniel

# Dar permisos administrativos mediante sudo
RUN echo "%administradores ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/administradores && \
    chmod 440 /etc/sudoers.d/administradores

WORKDIR /home

CMD ["/bin/bash"]