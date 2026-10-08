FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive container=docker
# Certificados para descargar paquetes por HTTPS desde el primer paso.
COPY --from=node:22-alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update && \
    apt-get install -y \
        ca-certificates sudo curl nano vim iputils-ping net-tools iproute2 procps \
        systemd systemd-sysv openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Usuarios y grupo de la implementación del compañero.
# No se incluyen contraseñas comunes dentro de la imagen.
RUN groupadd administradores && \
    for usuario in brian charles ketfer marco adaniel; do \
        useradd -m -s /bin/bash -G administradores "$usuario"; \
        chmod 700 /home/$usuario; \
    done

# Administración con sudo dentro del contenedor de laboratorio.
COPY administradores.sudoers /etc/sudoers.d/administradores
RUN chmod 440 /etc/sudoers.d/administradores && \
    visudo -cf /etc/sudoers.d/administradores

COPY lab-demo.service /etc/systemd/system/lab-demo.service
RUN systemctl enable lab-demo.service && systemctl mask systemd-networkd-wait-online.service
WORKDIR /home
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
