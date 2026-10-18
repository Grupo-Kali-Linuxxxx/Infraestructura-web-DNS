# -*- coding: utf-8 -*-
"""
servidor_eco.py — Servidor HTTP de práctica de la Unidad Educativa Horizonte (Tecnología Web I, Laboratorios 1 y 4).
En el Laboratorio 4 corre como servicio (horizonte-eco) detrás de Nginx: http://portal.horizonte.internal/api/eco
Solo usa la biblioteca estándar de Python: no hay que instalar nada.

    python servidor_eco.py            (escucha en http://127.0.0.1:8080)

Rutas para explorar con curl -v y con las DevTools del navegador:
    GET  /            página de inicio (HTML)
    GET  /eco         devuelve en JSON lo que el servidor recibió (método, ruta, cabeceras)
    POST /eco         además devuelve el cuerpo que enviaste
    GET  /cookie      te entrega una cookie 'visitas' y cuenta tus visitas
    GET  /antiguo     redirección permanente (301) a /
    GET  /privado     acceso prohibido (403)
    GET  /lento       responde después de 2 segundos (mira el tiempo en la pestaña Red)
    cualquier otra    no encontrado (404)
"""
import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from http.cookies import SimpleCookie

PUERTO = int(os.environ.get("PUERTO_ECO", "8080"))  # en el Lab 4 lo fija el servicio de systemd (8081)

PAGINA = """<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><title>Unidad Educativa Horizonte</title></head>
<body><h1>Unidad Educativa Horizonte</h1>
<p>Servidor de práctica de Tecnología Web I. Prueba estas rutas:</p>
<ul><li><a href="/eco">/eco</a></li><li><a href="/cookie">/cookie</a></li><li><a href="/antiguo">/antiguo</a></li>
<li><a href="/privado">/privado</a></li><li><a href="/lento">/lento</a></li><li><a href="/no-existe">/no-existe</a></li></ul>
</body></html>"""


class Manejador(BaseHTTPRequestHandler):
    server_version = "HorizonteEco/1.0"
    protocol_version = "HTTP/1.1"  # por defecto Python responde HTTP/1.0 (sin conexiones persistentes)

    def _responder(self, codigo, cuerpo, tipo="text/html; charset=utf-8", extra=None):
        datos = cuerpo.encode("utf-8")
        self.send_response(codigo)
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(datos)))
        for nombre, valor in (extra or []):
            self.send_header(nombre, valor)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(datos)

    def _eco(self, cuerpo=None):
        info = {"metodo": self.command, "ruta": self.path, "version_http": self.request_version,
                "cliente": self.client_address[0], "cabeceras": dict(self.headers.items())}
        if cuerpo is not None:
            info["cuerpo"] = cuerpo
        return json.dumps(info, ensure_ascii=False, indent=2)

    def do_GET(self):
        if self.path == "/":
            self._responder(200, PAGINA)
        elif self.path == "/eco":
            self._responder(200, self._eco(), "application/json; charset=utf-8")
        elif self.path == "/cookie":
            galleta = SimpleCookie(self.headers.get("Cookie", ""))
            visitas = int(galleta["visitas"].value) + 1 if "visitas" in galleta else 1
            self._responder(200, f"<p>Visitas registradas con tu cookie: {visitas}</p>",
                            extra=[("Set-Cookie", f"visitas={visitas}; Path=/; HttpOnly; SameSite=Lax; Max-Age=3600")])
        elif self.path == "/antiguo":
            self._responder(301, "<p>Nos mudamos a /</p>", extra=[("Location", "/")])
        elif self.path == "/privado":
            self._responder(403, "<p>403 · Solo el personal autorizado del colegio.</p>")
        elif self.path == "/lento":
            time.sleep(2)
            self._responder(200, "<p>Respuesta después de 2 segundos.</p>")
        else:
            self._responder(404, "<p>404 · Esta página no existe en el servidor del colegio.</p>")

    def do_HEAD(self):
        self.do_GET()

    def do_POST(self):
        largo = int(self.headers.get("Content-Length", 0))
        cuerpo = self.rfile.read(largo).decode("utf-8", "replace")
        if self.path == "/eco":
            self._responder(201, self._eco(cuerpo), "application/json; charset=utf-8")
        else:
            self._responder(405, "<p>405 · Método no permitido en esta ruta.</p>", extra=[("Allow", "GET, HEAD")])

    def log_message(self, formato, *args):
        # Registro estilo servidor web: IP, fecha, petición y código
        print(f"{self.client_address[0]} [{self.log_date_time_string()}] {formato % args}")


if __name__ == "__main__":
    print(f"Servidor de la U.E. Horizonte en http://127.0.0.1:{PUERTO}  (Ctrl+C para detener)")
    ThreadingHTTPServer(("127.0.0.1", PUERTO), Manejador).serve_forever()
