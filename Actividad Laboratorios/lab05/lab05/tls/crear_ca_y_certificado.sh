#!/usr/bin/env bash
# crear_ca_y_certificado.sh — Autoridad certificadora (CA) propia del colegio + certificado del servidor.
# ¿Por qué una CA propia? Los dominios .internal NO pueden tener certificados públicos (Let's Encrypt solo emite
# para dominios que existen en internet). Las empresas usan una CA interna y la instalan en sus equipos.
# Uso:  sudo bash crear_ca_y_certificado.sh        (idempotente: la CA se crea una sola vez)
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }

DIR=/etc/horizonte-ca
install -d -m 700 "$DIR"
cd "$DIR"

# 1. La CA: clave privada (ECDSA P-256) + certificado raíz válido 5 años. Se crea UNA vez y se guarda bajo llave.
if [[ ! -f ca.key ]]; then
  openssl ecparam -name prime256v1 -genkey -noout -out ca.key
  chmod 600 ca.key
  openssl req -x509 -new -key ca.key -sha256 -days 1825 -out ca.crt \
    -subj "/C=BO/ST=Santa Cruz/O=Unidad Educativa Horizonte/CN=Horizonte CA Raiz 2026" \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"
fi

# 2. El servidor: clave + solicitud (CSR) con TODOS los nombres en subjectAltName (el CN ya no cuenta)
openssl ecparam -name prime256v1 -genkey -noout -out servidor.key
chmod 600 servidor.key
openssl req -new -key servidor.key -out servidor.csr \
  -subj "/C=BO/O=Unidad Educativa Horizonte/CN=www.horizonte.internal"

cat > servidor.ext <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=DNS:www.horizonte.internal
# TODO (línea de arriba): agregar horizonte.internal y portal.horizonte.internal separados por comas (DNS:...)
EOF

# 3. La CA firma el certificado del servidor.
# TODO: ¿3650 días (10 años)? Los certificados modernos duran 90 días o menos. Corrígelo.
openssl x509 -req -in servidor.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 3650 -sha256 -extfile servidor.ext -out servidor.crt

# 4. Nginx necesita el certificado del servidor + el de la CA (cadena completa)
cat servidor.crt ca.crt > servidor-cadena.crt
install -d /etc/nginx/tls
install -m 644 servidor-cadena.crt /etc/nginx/tls/horizonte.crt
install -m 600 servidor.key        /etc/nginx/tls/horizonte.key

# 5. Copia pública de la CA para instalarla en las PCs (NUNCA se reparte ca.key)
install -m 644 ca.crt /srv/horizonte/www/horizonte-ca.crt

openssl x509 -in servidor.crt -noout -subject -issuer -dates -ext subjectAltName
