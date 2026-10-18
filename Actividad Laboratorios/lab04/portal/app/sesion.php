<?php
// app/sesion.php — Sesión segura del portal (fuera de la carpeta pública: Nginx nunca la sirve).
declare(strict_types=1);

function iniciar_sesion(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }
    session_name('HORIZONTESESSID');              // no delatar que es PHP (PHPSESSID)
    session_set_cookie_params([
        'lifetime' => 0,                            // hasta cerrar el navegador
        'path'     => '/',
        'secure'   => ($_SERVER['HTTPS'] ?? '') === 'on',   // en la clase 5 (HTTPS) pasa a true
        // TODO: 'httponly' => … (¿puede JavaScript leer la cookie?)
        // TODO: 'samesite' => … (¿viaja en un POST que viene de otro sitio?)
    ]);
    ini_set('session.use_strict_mode', '1');        // rechaza IDs de sesión inventados
    session_start();
}

function usuario_actual(): ?array
{
    iniciar_sesion();
    return $_SESSION['usuario'] ?? null;
}

function exigir_sesion(): array
{
    $usuario = usuario_actual();
    if ($usuario === null) {
        header('Location: /', true, 302);
        exit;
    }
    return $usuario;
}

function token_csrf(): string
{
    iniciar_sesion();
    $_SESSION['csrf'] ??= bin2hex(random_bytes(16));
    return $_SESSION['csrf'];
}

function e(string $texto): string
{
    return htmlspecialchars($texto, ENT_QUOTES, 'UTF-8');   // evita XSS al mostrar datos
}
