# Evidencias ejecutadas: fase 7

Fecha de sesión: 8 de octubre de 2026, según el contexto del usuario.
Todas las comprobaciones fueron de terminal; sin pruebas interactivas de navegador.

| Prueba | Resultado observado |
|---|---|
| Dependencias en ambos backends | express-session 1.19.0 y Express 5.2.1 |
| npm ci en build | 76 paquetes por aplicación; construcción correcta |
| Inicializador de entorno | .env creado con dos secretos independientes, no mostrados |
| Repetición de inicializador | .env existente preservado; hash del archivo sin cambios |
| Validación privada de valores | Longitud de ambos suficiente y valores distintos |
| git check-ignore .env | Archivo excluido |
| git check-ignore .env.example | Plantilla no excluida |
| Backend sin SESSION_SECRET | Contenedor temporal terminó con código 1 y mensaje de configuración |
| Validación Compose / Nginx | Ambas correctas; recarga realizada |
| GET /sesiones en ambos | HTTP 200, interfaz servida |
| JavaScript de ambas interfaces | Compilado con vm.Script de Node sin errores de sintaxis; no ejecutado en navegador |
| GET sesión inicial | activa false, contador 0, sin Set-Cookie |
| Incremento antes de crear | HTTP 409 |
| POST crear | HTTP 201, activa true, contador 0 |
| Atributos Set-Cookie | Nombre propio, Path=/, HttpOnly, SameSite=Lax, Expires; sin Secure ni Domain |
| Dos incrementos y consulta posterior | Contadores 1, 2; consulta recuperó 2 |
| Segundo cliente sin cookie | Sesión inactiva, contador 0 |
| Cookie alterada | No recuperó sesión activa |
| DELETE sesión | HTTP 200; datos destruidos y cookie expirada en 1970 |
| Reenvío del identificador destruido | Sesión inactiva |
| Nueva creación | Identificador diferente y contador 0 |
| Regeneración de sesión activa | Identificador diferente, contador reiniciado, anterior inválido |
| Mismo cliente con ambos hosts | Contadores independientes |
| Reinicio de cada backend | MemoryStore perdió sesiones, consultas inactivas; recuperación healthy |
| Script Test-Sessions -IncludeRestart | Cinco PASS principales; sesiones de prueba destruidas; archivos temporales eliminados |
| Scripts de fases 3, 4, 5 y 6 | Todos pasaron después de incorporar sesiones |
| npm run check en ambos | Sin errores de sintaxis |
| npm audit en ambos | found 0 vulnerabilities |
| Estado final | Cuatro servicios Up; app1, app2 y Ubuntu healthy |

Ejemplo de estado comprobado en la consulta posterior a dos incrementos:

```json
{"aplicacion":"APP1","activa":true,"contador":2}
```

APP2 pasó el mismo ciclo con su propio nombre de aplicación. No se incluyen
valores Set-Cookie, Cookie, identificadores de sesión ni contenidos de .env.
Los scripts no los imprimieron en sus resultados.

Pendientes: revisión de botones en navegador, capturas DevTools y aprobación
humana de los resultados. No se ejecutó commit ni push.
