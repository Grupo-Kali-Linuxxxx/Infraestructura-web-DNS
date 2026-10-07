const http = require("http");

const PORT = 3000;

const server = http.createServer((req, res) => {
    res.writeHead(200, {
        "Content-Type": "text/html; charset=utf-8"
    });

    res.end(`
        <h1>Backend App 2</h1>
        <p>Servidor Node.js funcionando correctamente.</p>
        <p>Aplicación: APP2</p>
    `);
});

server.listen(PORT, "0.0.0.0", () => {
    console.log(`Backend App 2 escuchando en el puerto ${PORT}`);
});