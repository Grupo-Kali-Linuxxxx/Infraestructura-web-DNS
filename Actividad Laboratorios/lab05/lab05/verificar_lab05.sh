#!/usr/bin/env bash
# verificar_lab05.sh — Comprueba HTTPS, certificado y cabeceras de seguridad (Laboratorio 5). Ejecutar en el servidor.
ok=0; total=0
revisar() {
  local desc="$1"; shift; total=$((total + 1))
  if "$@" &>/dev/null; then echo "✅ $desc"; ok=$((ok + 1)); else echo "❌ $desc"; fi
}
# --resolve: "www.horizonte.internal" → 127.0.0.1, conservando el nombre (SNI) para el certificado
R="--resolve www.horizonte.internal:443:127.0.0.1 --resolve portal.horizonte.internal:443:127.0.0.1 --resolve horizonte.internal:443:127.0.0.1 --resolve www.horizonte.internal:80:127.0.0.1"
WWW=https://www.horizonte.internal
POR=https://portal.horizonte.internal
CRT=/etc/nginx/tls/horizonte.crt

cab()  { curl -sI $R "$1" | tr -d '\r'; }
tiene(){ cab "$1" | grep -qi "^$2"; }

http_a_https()   { cab http://www.horizonte.internal/x | grep -q '^Location: https://www.horizonte.internal/x'; }
https_confiable(){ [[ "$(curl -s $R -o /dev/null -w '%{http_code}' $WWW/)" == 200 ]]; }
san_completo()   { local s; s=$(openssl x509 -in $CRT -noout -ext subjectAltName); for n in www.horizonte.internal horizonte.internal portal.horizonte.internal; do grep -q "DNS:$n" <<<"$s" || return 1; done; }
emisor_ca()      { openssl x509 -in $CRT -noout -issuer | grep -q 'Horizonte CA'; }
vigencia_90()    { local ini fin; ini=$(date -d "$(openssl x509 -in $CRT -noout -startdate | cut -d= -f2)" +%s); fin=$(date -d "$(openssl x509 -in $CRT -noout -enddate | cut -d= -f2)" +%s); (( (fin-ini)/86400 <= 90 )); }
tls13()          { echo | openssl s_client -connect 127.0.0.1:443 -servername www.horizonte.internal 2>/dev/null | grep -q 'TLSv1.3'; }
sin_tls11()      { echo | openssl s_client -connect 127.0.0.1:443 -servername www.horizonte.internal -tls1_1 -cipher 'DEFAULT@SECLEVEL=0' 2>&1 | grep -q 'alert protocol version'; }  # SECLEVEL=0: que sea el SERVIDOR quien rechace
http2()          { [[ "$(curl -s $R --http2 -o /dev/null -w '%{http_version}' $WWW/)" == 2 ]]; }
sin_version()    { cab $WWW/ | grep -qx 'server: nginx' || cab $WWW/ | grep -qx 'Server: nginx'; }
apex_a_www()     { cab https://horizonte.internal/y | grep -qi '^Location: https://www.horizonte.internal/y'; }
circ_con_hsts()  { tiene $WWW/circulares/ 'strict-transport-security' && tiene $WWW/circulares/ 'x-robots-tag'; }
cookie_secure()  { cab $POR/ | grep -i '^set-cookie: HORIZONTESESSID' | grep -qi 'secure'; }
login_https()    { local J; J=$(mktemp); local t; t=$(curl -s $R -c "$J" -b "$J" $POR/ | grep -o '[a-f0-9]\{32\}' | head -1); curl -s $R -c "$J" -b "$J" -o /dev/null -d "csrf=$t&usuario=mamani.rosa&clave=Horizonte2026" $POR/entrar.php; curl -s $R -b "$J" $POR/panel.php | grep -q 'Computación'; local r=$?; rm -f "$J"; return $r; }
sni_rechazado()  { ! echo | openssl s_client -connect 127.0.0.1:443 -servername intruso.com 2>/dev/null | grep -q 'BEGIN CERTIFICATE\|Server certificate'; }
ca_descargable() { tiene $WWW/horizonte-ca.crt 'content-type: application/x-x509-ca-cert'; }
api_https()      { curl -s $R $POR/api/eco | grep -q '"X-Forwarded-Proto": "https"'; }

revisar "nginx -t correcto"                                     nginx -t
revisar "http:// redirige (301) a https://"                     http_a_https
revisar "https://www responde 200 con certificado confiable"   https_confiable
revisar "Certificado con los 3 nombres (subjectAltName)"        san_completo
revisar "Emitido por la CA del colegio"                         emisor_ca
revisar "Vigencia del certificado ≤ 90 días"                    vigencia_90
revisar "Negocia TLS 1.3"                                       tls13
revisar "Rechaza TLS 1.1"                                       sin_tls11
revisar "HTTP/2 activo"                                         http2
revisar "Cabecera Server sin versión"                           sin_version
revisar "HSTS presente"                                         tiene $WWW/ 'strict-transport-security: max-age='
revisar "Content-Security-Policy presente"                      tiene $WWW/ 'content-security-policy:'
revisar "X-Content-Type-Options y X-Frame-Options"               bash -c "curl -sI $R $WWW/ | grep -qi 'x-content-type-options: nosniff' && curl -sI $R $WWW/ | grep -qi 'x-frame-options: deny'"
revisar "/circulares/ conserva las cabeceras (herencia)"        circ_con_hsts
revisar "https://horizonte.internal → https://www"              apex_a_www
revisar "Cookie de sesión del portal con Secure"                cookie_secure
revisar "Inicio de sesión del portal por HTTPS"                 login_https
revisar "API recibe X-Forwarded-Proto: https"                   api_https
revisar "Nombre desconocido: saludo TLS rechazado"              sni_rechazado
revisar "CA pública descargable para las PCs"                   ca_descargable
echo "Resultado: $ok de $total comprobaciones"
[[ $ok -eq $total ]]
