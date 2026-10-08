const express = require("express");
const session = require("express-session");
const path = require("path");

const sessionSecret = process.env.SESSION_SECRET;
if (!sessionSecret || sessionSecret.length < 32) {
    throw new Error("Configura SESSION_SECRET con al menos 32 caracteres; ejecuta scripts/Initialize-Environment.ps1.");
}
const sessionCookieName = "app1.sid";
const cookieOptions = { path: "/", httpOnly: true, sameSite: "lax", secure: false };

const PORT = Number(process.env.PORT || 3000);
if (!Number.isInteger(PORT) || PORT < 1 || PORT > 65535) {
    throw new Error("PORT debe ser un número entero entre 1 y 65535.");
}
const app = express();
app.disable("x-powered-by");
app.use(express.json({ limit: "8kb" }));
app.use((req, res, next) => {
    res.set("Cache-Control", "no-store");
    next();
});

// MemoryStore: únicamente laboratorio. Reiniciar el proceso elimina sesiones.
// HTTP local no requiere trust proxy ni cookies Secure.
app.use("/api/sesion", session({
    name: sessionCookieName,
    secret: sessionSecret,
    resave: false,
    saveUninitialized: false,
    cookie: { ...cookieOptions, maxAge: 15 * 60 * 1000 }
}));

app.get("/pruebas/502", (req, res) => {
    // Sólo para el laboratorio: provocar una respuesta incompleta al proxy.
    req.socket.destroy();
});

// Evidencia académica de las cabeceras que llegan desde el proxy inverso.
app.get("/diagnostico", (req, res) => {
    res.json({
        aplicacion: "APP1",
        metodo: req.method,
        ruta: req.url,
        versionHttp: req.httpVersion,
        host: req.headers.host,
        ipConexion: req.socket.remoteAddress,
        xRealIp: req.headers["x-real-ip"] || null,
        xForwardedFor: req.headers["x-forwarded-for"] || null,
        xForwardedProto: req.headers["x-forwarded-proto"] || null
    });
});

app.get("/", (req, res) => {
    res.type("html").send(`
        <h1>Backend App 1</h1>
        <p>Servidor Node.js funcionando correctamente.</p>
        <p>Aplicación: APP1</p>
        <p><a href="/sesiones">Demostración de sesiones y cookies</a></p>
    `);
});

app.get("/health", (req, res) => {
    res.json({ estado: "ok", aplicacion: "APP1" });
});

app.get("/sesiones", (req, res) => {
    res.sendFile(path.join(__dirname, "public", "sesiones.html"));
});

const sessionState = req => ({
    aplicacion: "APP1",
    activa: req.session.creada === true,
    contador: req.session.contador || 0
});

// Una cola por sesión para este proceso: evita guardar contadores obsoletos.
// Las colas se eliminan al terminar; MemoryStore sigue siendo sólo académico.
const sessionUpdates = new Map();
async function withSessionUpdate(req, operation) {
    const sessionId = req.sessionID;
    const previous = sessionUpdates.get(sessionId) || Promise.resolve();
    let release;
    const completed = new Promise(resolve => { release = resolve; });
    sessionUpdates.set(sessionId, completed);
    await previous;
    try {
        return await operation();
    } finally {
        release();
        if (sessionUpdates.get(sessionId) === completed) sessionUpdates.delete(sessionId);
    }
}

const sessionMethod = (req, method) => new Promise((resolve, reject) => {
    req.session[method](error => error ? reject(error) : resolve());
});

const storedSession = req => new Promise((resolve, reject) => {
    req.sessionStore.get(req.sessionID, (error, value) => error ? reject(error) : resolve(value));
});

app.get("/api/sesion", (req, res) => {
    res.json(sessionState(req));
});

app.post("/api/sesion", async (req, res) => {
    await withSessionUpdate(req, async () => {
        await sessionMethod(req, "regenerate");
        req.session.creada = true;
        req.session.contador = 0;
        await sessionMethod(req, "save");
        res.status(201).json(sessionState(req));
    });
});

app.post("/api/sesion/incrementar", async (req, res) => {
    await withSessionUpdate(req, async () => {
        // El middleware pudo cargar la sesión antes de otros incrementos.
        // Leer dentro de la cola también impide revivir una sesión destruida.
        const current = await storedSession(req);
        if (!current?.creada) {
            req.session = null;
            return res.status(409).json({ error: "Crea una sesión antes de incrementar.", aplicacion: "APP1" });
        }
        req.session.creada = current.creada;
        req.session.contador = current.contador + 1;
        await sessionMethod(req, "save");
        res.json(sessionState(req));
    });
});

app.delete("/api/sesion", async (req, res) => {
    await withSessionUpdate(req, async () => {
        await sessionMethod(req, "destroy");
        res.clearCookie(sessionCookieName, cookieOptions);
        res.json({ aplicacion: "APP1", activa: false, contador: 0 });
    });
});

app.get("/api/info", (req, res) => {
    res.json({ aplicacion: "APP1", tecnologia: "Node.js + Express", metodo: req.method });
});

app.post("/api/eco", (req, res) => {
    if (!req.is("application/json")) {
        return res.status(415).json({ error: "Utiliza Content-Type: application/json." });
    }
    if (!req.body || Array.isArray(req.body) || typeof req.body.mensaje !== "string" ||
        !req.body.mensaje.trim() || req.body.mensaje.length > 200) {
        return res.status(400).json({ error: "mensaje debe ser un texto de 1 a 200 caracteres." });
    }
    res.json({ aplicacion: "APP1", mensaje: req.body.mensaje.trim() });
});

app.all("/api/eco", (req, res) => {
    res.set("Allow", "POST").status(405).json({ error: "Esta ruta admite únicamente POST." });
});

// Demostración académica de propagación de errores asíncronos en Express 5.
app.get("/api/pruebas/error", async (req, res) => {
    throw new Error("Fallo controlado de prueba");
});

app.use((req, res) => {
    if (req.path.startsWith("/api/")) {
        return res.status(404).json({ error: "Recurso no encontrado.", aplicacion: "APP1" });
    }
    res.status(404).type("text/plain").send("Recurso no encontrado en APP1.\n");
});

app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    res.set("Cache-Control", "no-store");
    let status = 500;
    let message = "Error interno del servidor.";
    if (error.type === "entity.parse.failed") {
        status = 400;
        message = "JSON inválido.";
    } else if (error.type === "entity.too.large") {
        status = 413;
        message = "El cuerpo de la petición supera el límite de 8 KB.";
    } else if (error.type === "charset.unsupported" || error.type === "encoding.unsupported") {
        status = 415;
        message = "Codificación de la petición no admitida.";
    }
    if (status === 500) console.error("[APP1] Error interno gestionado por Express.");
    res.status(status).json({ error: message, aplicacion: "APP1" });
});

const server = app.listen(PORT, "0.0.0.0", () => {
    console.log(`Backend App 1 escuchando en el puerto ${PORT}`);
});

server.on("error", () => {
    console.error("[APP1] No se pudo iniciar el servidor.");
    process.exit(1);
});

process.on("SIGTERM", () => {
    console.log("[APP1] Cerrando servidor.");
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 8000).unref();
});
