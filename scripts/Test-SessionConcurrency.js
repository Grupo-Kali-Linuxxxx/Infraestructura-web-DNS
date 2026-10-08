// Ejecutado con Node del contenedor: pruebas HTTP, sin dependencias adicionales.
const assert = require("node:assert/strict");
const http = require("node:http");
const net = require("node:net");

function request(site, route, method = "GET", cookie, proxy = false) {
    return new Promise((resolve, reject) => {
        const req = http.request({
            hostname: proxy ? "nginx" : site.service,
            port: proxy ? 80 : 3000,
            path: route, method, agent: false,
            headers: { Host: site.host, ...(cookie ? { Cookie: cookie } : {}) }
        }, res => {
            let body = "";
            res.on("data", chunk => { body += chunk; });
            res.on("end", () => {
                try {
                    resolve({ status: res.statusCode, body: JSON.parse(body),
                        cookie: res.headers["set-cookie"]?.[0]?.split(";")[0] });
                } catch { reject(new Error("Respuesta de prueba sin JSON")); }
            });
            res.on("error", reject);
        });
        req.setTimeout(10000, () => req.destroy(new Error("Timeout HTTP de prueba")));
        req.on("error", reject);
        req.end();
    });
}

// Enviar todas las solicitudes en un bloque obliga a manejar sesiones cargadas
// antes de que terminen otras operaciones; revela el fallo incluso si es raro.
function pipeline(site, cookie, operations) {
    return new Promise((resolve, reject) => {
        let raw = "";
        const socket = net.createConnection({ host: site.service, port: 3000 }, () => {
            socket.write(operations.map((operation, index) =>
                `${operation.method} ${operation.route} HTTP/1.1\r\n` +
                `Host: ${site.host}\r\nCookie: ${cookie}\r\nContent-Length: 0\r\n` +
                `Connection: ${index === operations.length - 1 ? "close" : "keep-alive"}\r\n\r\n`
            ).join(""));
        });
        socket.setTimeout(10000, () => socket.destroy(new Error("Timeout de pipeline")));
        socket.on("data", chunk => { raw += chunk.toString(); });
        socket.on("error", reject);
        socket.on("end", () => resolve({
            statuses: [...raw.matchAll(/HTTP\/1\.1 (\d{3}) /g)].map(match => Number(match[1])),
            counters: [...raw.matchAll(/"contador":(\d+)/g)].map(match => Number(match[1])),
            cookies: [...raw.matchAll(/^Set-Cookie: ([^;\r\n]+)/gim)].map(match => match[1])
        }));
    });
}

const increment = { method: "POST", route: "/api/sesion/incrementar" };
async function testSite(site) {
    const cookies = new Set();
    async function create() {
        const created = await request(site, "/api/sesion", "POST");
        assert.equal(created.status, 201, "Crear debe responder 201");
        assert.ok(created.cookie, "Falta cookie de prueba");
        cookies.add(created.cookie);
        return created.cookie;
    }
    try {
        let cookie = await create();
        const burst = await pipeline(site, cookie, Array.from({ length: 40 }, () => increment));
        assert.equal(burst.statuses.length, 40, "Faltan respuestas del pipeline");
        assert.ok(burst.statuses.every(status => status === 200), "Incremento sin estado 200");
        assert.equal((await request(site, "/api/sesion", "GET", cookie)).body.contador, 40,
            "Se perdieron incrementos del pipeline");
        assert.deepEqual([...burst.counters].sort((a, b) => a - b),
            Array.from({ length: 40 }, (_, index) => index + 1), "Contadores repetidos en pipeline");
        console.log(`PASS ${site.host}: 40 incrementos en pipeline, contador 40 y respuestas 1..40`);

        cookie = await create();
        const replies = await Promise.all(Array.from({ length: 40 }, () =>
            request(site, increment.route, increment.method, cookie, true)));
        assert.ok(replies.every(reply => reply.status === 200), "Incremento por proxy sin estado 200");
        assert.equal((await request(site, "/api/sesion", "GET", cookie, true)).body.contador, 40,
            "Se perdieron incrementos por proxy");
        assert.deepEqual(replies.map(reply => reply.body.contador).sort((a, b) => a - b),
            Array.from({ length: 40 }, (_, index) => index + 1), "Contadores repetidos por proxy");
        console.log(`PASS ${site.host}: 40 incrementos simultaneos por Nginx, contador 40`);

        cookie = await create();
        const deleted = await pipeline(site, cookie, [
            { method: "DELETE", route: "/api/sesion" },
            ...Array.from({ length: 10 }, () => increment)
        ]);
        assert.deepEqual(deleted.statuses, [200, ...Array(10).fill(409)],
            "Incrementos pendientes deben rechazar la sesion destruida");
        assert.equal((await request(site, "/api/sesion", "GET", cookie)).body.activa, false,
            "La sesion destruida reaparecio");
        console.log(`PASS ${site.host}: destruir no permite que incrementos pendientes revivan la sesion`);

        cookie = await create();
        const regenerated = await pipeline(site, cookie, [
            { method: "POST", route: "/api/sesion" },
            ...Array.from({ length: 10 }, () => increment)
        ]);
        regenerated.cookies.forEach(value => cookies.add(value));
        assert.deepEqual(regenerated.statuses, [201, ...Array(10).fill(409)],
            "Incrementos con cookie anterior deben fallar tras regenerar");
        assert.equal((await request(site, "/api/sesion", "GET", cookie)).body.activa, false,
            "La sesion anterior reaparecio");
        assert.ok(regenerated.cookies[0], "Falta cookie regenerada");
        const state = await request(site, "/api/sesion", "GET", regenerated.cookies[0]);
        assert.equal(state.body.activa, true, "La nueva sesion debe seguir activa");
        assert.equal(state.body.contador, 0, "La nueva sesion debe comenzar en cero");
        console.log(`PASS ${site.host}: regenerar invalida incrementos pendientes de la sesion anterior`);
    } finally {
        for (const cookie of cookies) {
            const deleted = await request(site, "/api/sesion", "DELETE", cookie);
            assert.equal(deleted.status, 200, "No se pudo limpiar una sesion de prueba");
        }
    }
}

(async () => {
    let failures = 0;
    for (const site of [
        { service: "app1", host: "sitio1.local" },
        { service: "app2", host: "sitio2.local" }
    ]) {
        try { await testSite(site); }
        catch (error) { failures++; console.error(`FAIL ${site.host}: ${error.message}`); }
    }
    if (failures) process.exitCode = 1;
    else console.log("PASS limpieza: sesiones de prueba destruidas; cookies no publicadas");
})().catch(() => { console.error("Fallo inesperado de la prueba"); process.exitCode = 1; });
