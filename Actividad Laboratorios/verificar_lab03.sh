#!/usr/bin/env bash
# verificar_lab03.sh — Comprueba los sitios de Nginx del Laboratorio 3 (ejecutar en el servidor).
ok=0; total=0
revisar() {
  local desc="$1"; shift; total=$((total + 1))
  if "$@" &>/dev/null; then echo "✅ $desc"; ok=$((ok + 1)); else echo "❌ $desc"; fi
}
codigo()   { curl -s -o /dev/null -w '%{http_code}' -H "Host: $1" "http://127.0.0.1$2"; }
cuerpo()   { curl -s -H "Host: $1" "http://127.0.0.1$2"; }
cabecera() { curl -sI -H "Host: $1" "http://127.0.0.1$2" | tr -d '\r' | grep -i "^$3:"; }

www_contiene()    { cuerpo www.horizonte.internal "$1" | grep -q "$2"; }
portal_contiene() { cuerpo portal.horizonte.internal / | grep -q "Portal para padres"; }
redirige_a_www()  { cabecera horizonte.internal /x Location | grep -q "www.horizonte.internal/x"; }
error_404_propio(){ [[ "$(codigo www.horizonte.internal /no-existe)" == 404 ]] && www_contiene /no-existe "Esta página no existe"; }
css_con_cache()   { cabecera www.horizonte.internal /css/estilo.css Cache-Control | grep -q "max-age=604800"; }
rechaza_intruso() { ! curl -s -o /dev/null -H "Host: intruso.com" http://127.0.0.1/; }
log_con_tiempo()  { tail -1 /var/log/nginx/horizonte-www.access.log | grep -Eq '"www.horizonte.internal" .* [0-9]+\.[0-9]{3} '; }

revisar "Nginx instalado y activo"                        systemctl is-active nginx
revisar "Sintaxis correcta (nginx -t)"                    nginx -t
revisar "Sitio default deshabilitado"                     test ! -e /etc/nginx/sites-enabled/default
revisar "www responde 200"                                test "$(codigo www.horizonte.internal /)" = 200
revisar "www muestra el nombre del colegio"               www_contiene / "Unidad Educativa Horizonte"
revisar "portal responde con su propia página"            portal_contiene
revisar "horizonte.internal redirige (301) a www"         redirige_a_www
revisar "Página 404 propia del colegio"                   error_404_propio
revisar "Circulares con listado automático"               www_contiene /circulares/ "circular-012"
revisar "CSS con caché de 7 días (max-age=604800)"        css_con_cache
revisar "Archivos ocultos bloqueados (403)"               test "$(codigo www.horizonte.internal /.env)" = 403
revisar "Nombre desconocido: conexión cerrada (444)"      rechaza_intruso
revisar "Registro propio de www con tiempo de respuesta"  log_con_tiempo
revisar "Contenido con grupo webadmin"                    test "$(stat -c %G /srv/horizonte/www/index.html)" = webadmin
echo "Resultado: $ok de $total comprobaciones"
[[ $ok -eq $total ]]
