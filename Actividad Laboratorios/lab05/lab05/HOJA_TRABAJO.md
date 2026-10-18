# Laboratorio 5 — Hoja de trabajo: HTTPS con una CA propia y cabeceras de seguridad

Nombre: ______________________   Fecha: ___/___/2026   Entorno: [ ] VirtualBox  [ ] Docker

## Parte A — Antes: ¿qué ve un espía en HTTP?
1. En el servidor: `sudo tcpdump -i lo -A -s0 'tcp port 80' | grep -iE 'usuario|clave'`
2. En otra terminal inicia sesión en el portal por http (con curl, como en `verificar_lab04.sh`).
   ¿Qué aparece en tcpdump? ¿Qué podría hacer alguien conectado al mismo Wi-Fi del colegio?

## Parte B — Tu autoridad certificadora (CA)
Completa los TODO de `tls/crear_ca_y_certificado.sh` y ejecútalo: `sudo bash tls/crear_ca_y_certificado.sh`.
1. `openssl x509 -in /etc/horizonte-ca/ca.crt -noout -subject -dates` → ¿cuánto dura la CA?
2. `openssl x509 -in /etc/horizonte-ca/servidor.crt -noout -issuer -dates -ext subjectAltName` → ¿cuánto dura el
   certificado del servidor? ¿Qué nombres cubre?
3. ¿Por qué `ca.key` nunca sale del servidor y `ca.crt` sí se reparte?
4. ¿Por qué no podemos usar Let's Encrypt para `www.horizonte.internal`?

## Parte C — Nginx con HTTPS y cabeceras
Completa los TODO de `nginx/` (snippets, www, portal, 00-rechazar, seguridad-global) y ejecuta
`sudo bash instalar_https.sh` y `bash verificar_lab05.sh` → objetivo **20 de 20**.

¿Por qué ahora `verificar_lab03.sh` y `verificar_lab04.sh` fallan? (pista: ¿qué responde http:// ahora?)

## Parte D — Inspecciona la conexión
| Comando | ¿Qué observas? |
|---|---|
| `echo \| openssl s_client -connect 127.0.0.1:443 -servername www.horizonte.internal` | versión TLS, cifrado, cadena, verificación |
| lo mismo con `-tls1_1` | |
| lo mismo con `-servername intruso.com` | |
| `curl -sI --resolve www.horizonte.internal:443:127.0.0.1 https://www.horizonte.internal/` | versión HTTP, cabeceras de seguridad |

## Parte E — Desde tu PC
1. Descarga `http://www.horizonte.internal/horizonte-ca.crt` (VM) o cópiala del servidor (Docker).
2. Instálala como "Entidad de certificación raíz de confianza" (Windows: doble clic → Instalar certificado →
   Usuario actual → Colocar en: Entidades de certificación raíz de confianza). Firefox tiene su propio almacén.
3. Abre `https://www.horizonte.internal` (Docker: `:8443`). Captura el candado y el detalle del certificado.
4. Revisa las cabeceras de seguridad en DevTools > Red y compáralas con upds.edu.bo (clase 1).
5. Al terminar el curso, **desinstala** la CA de tu PC: ¿por qué es importante?

## Reflexión
¿Qué protege HTTPS y qué NO protege (por ejemplo, contra una contraseña débil o un servidor mal configurado)?
