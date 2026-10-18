#!/usr/bin/env bash
# verificar_lab04.sh — Comprueba el portal PHP detrás de Nginx (Laboratorio 4). Ejecutar en el servidor.
# Simula a un padre de familia con curl: entra, ve sus notas y cierra sesión.
ok=0; total=0
revisar() {
  local desc="$1"; shift; total=$((total + 1))
  if "$@" &>/dev/null; then echo "✅ $desc"; ok=$((ok + 1)); else echo "❌ $desc"; fi
}
URL=http://127.0.0.1
H="Host: portal.horizonte.internal"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
J="$TMP/galletas.txt"

pedir()        { curl -s -H "$H" -b "$J" -c "$J" "$@"; }
codigo()       { curl -s -o /dev/null -w '%{http_code}' -H "$H" "$URL$1"; }
token()        { pedir "$URL/" | grep -o 'name="csrf" value="[a-f0-9]*"' | grep -o '[a-f0-9]\{32\}'; }
entrar()       { local t; t=$(token); pedir -o /dev/null -w '%{redirect_url}' -d "csrf=$t&usuario=mamani.rosa&clave=$1" "$URL/entrar.php"; }

php_ejecuta()     { pedir "$URL/" | grep -q 'Servido por PHP 8'; }
no_codigo_fuente(){ ! pedir "$URL/index.php" | grep -q '<?php'; }
cookie_segura()   { curl -s -D - -o /dev/null -H "$H" "$URL/" | tr -d '\r' | grep -i '^set-cookie: HORIZONTESESSID=' | grep -qi 'httponly' ; }
cookie_samesite() { curl -s -D - -o /dev/null -H "$H" "$URL/" | tr -d '\r' | grep -i '^set-cookie: HORIZONTESESSID=' | grep -qi 'samesite=lax'; }
clave_mala()      { rm -f "$J"; entrar "incorrecta" | grep -q 'error=1'; }
panel_protegido() { rm -f "$J"; curl -s -D - -o /dev/null -H "$H" "$URL/panel.php" | tr -d '\r' | grep -q '^Location: /$'; }
login_correcto()  { rm -f "$J"; entrar "Horizonte2026" | grep -q '/panel.php'; }
ve_notas()        { pedir "$URL/panel.php" | grep -q 'Computación'; }
id_regenerado()   { rm -f "$J"; pedir -o /dev/null "$URL/"; local a b; a=$(grep HORIZONTESESSID "$J" | awk '{print $7}'); entrar "Horizonte2026" >/dev/null; b=$(grep HORIZONTESESSID "$J" | awk '{print $7}'); [[ -n $a && -n $b && $a != "$b" ]]; }
csrf_exigido()    { rm -f "$J"; pedir -o /dev/null "$URL/"; [[ "$(pedir -o /dev/null -w '%{http_code}' -d 'csrf=falso&usuario=mamani.rosa&clave=Horizonte2026' "$URL/entrar.php")" == 403 ]]; }
salir_cierra()    { login_correcto && local t; t=$(pedir "$URL/panel.php" | grep -o '[a-f0-9]\{32\}' | head -1); pedir -o /dev/null -d "csrf=$t" "$URL/salir.php"; [[ "$(pedir -o /dev/null -w '%{http_code}' "$URL/panel.php")" == 302 ]]; }
api_proxy()       { curl -s -H "$H" "$URL/api/eco" | grep -q '"X-Forwarded-For"'; }

revisar "PHP-FPM 8.3 activo"                              systemctl is-active php8.3-fpm
revisar "Servicio horizonte-eco activo y habilitado"      bash -c 'systemctl is-active horizonte-eco && systemctl is-enabled horizonte-eco'
revisar "nginx -t correcto"                               nginx -t
revisar "PHP se ejecuta (no se descarga)"                 php_ejecuta
revisar "El código fuente .php nunca se muestra"          no_codigo_fuente
revisar "app/ no es accesible desde la web (404)"         test "$(codigo /app/datos.php)" = 404
revisar "Cookie de sesión HORIZONTESESSID con HttpOnly"   cookie_segura
revisar "Cookie de sesión con SameSite=Lax"               cookie_samesite
revisar "Contraseña incorrecta → vuelve con error"        clave_mala
revisar "Panel sin sesión → redirige al inicio (302)"     panel_protegido
revisar "Contraseña correcta → entra al panel"            login_correcto
revisar "El panel muestra las notas del hijo"             ve_notas
revisar "ID de sesión nuevo al iniciar sesión"            id_regenerado
revisar "Formulario sin token CSRF válido → 403"          csrf_exigido
revisar "Cerrar sesión la invalida"                       salir_cierra
revisar "API por proxy inverso con X-Forwarded-For"       api_proxy
echo "Resultado: $ok de $total comprobaciones"
[[ $ok -eq $total ]]
