FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive container=docker
RUN apt-get update && apt-get install -y sudo curl nano vim iputils-ping net-tools iproute2 procps systemd systemd-sysv openssh-server && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN groupadd administradores && for u in brian charles ketfer marco adaniel; do useradd -m -s /bin/bash -G administradores "$u"; chmod 700 /home/$u; done
COPY lab-demo.service /etc/systemd/system/lab-demo.service
RUN systemctl enable lab-demo.service && systemctl mask systemd-networkd-wait-online.service
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
