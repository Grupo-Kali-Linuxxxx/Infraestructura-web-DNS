# Laboratorio 8 — Líneas para reemplazar los TODO

## unbound/horizonte-resolutor.conf (dentro de server:)
```
access-control: 0.0.0.0/0 refuse
access-control: 127.0.0.0/8 allow
access-control: 10.10.10.0/24 allow

domain-insecure: "horizonte.internal"
domain-insecure: "10.10.10.in-addr.arpa"

local-zone: "10.in-addr.arpa." nodefault
```
Reemplazar el forward-zone simple (una sola sección forward-zone):
```
forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 9.9.9.9@853#dns.quad9.net
```

## unbound/rpz.horizonte.internal
```
*.apuestas-ejemplo.com        CNAME .
horizonte-notas-login.com     A 10.10.10.20
*.horizonte-notas-login.com   A 10.10.10.20
```

## dns-como-codigo/dnsconfig.js
```
SOA("@", "ns1.ue-horizonte.example.",
        "ti.ue-horizonte.example.", 3600, 600, 1209600, 300),

DMARC_BUILDER({
    policy: "quarantine",
    rua: ["mailto:dmarc@ue-horizonte.example"]
}),

CAA_BUILDER({
    label: "@",
    iodef: "mailto:ti@ue-horizonte.example",
    issue: ["letsencrypt.org"],
    issuewild: "none"
}),
```

## Orden de ejecución
```
bash /lab/lab08/instalar_resolutor.sh
cd /lab/lab08/dns-como-codigo && mkdir -p zonas && dnscontrol push
bash /lab/lab08/verificar_lab08.sh
```
Retos 2 y 3: copiar medir_rpz.sh y pipeline_dns.sh a /lab/lab08/.
