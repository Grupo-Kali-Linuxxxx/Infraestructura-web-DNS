<?php
// public/salir.php — Cierra la sesión en el servidor y borra la cookie del navegador.
declare(strict_types=1);
require __DIR__ . '/../app/sesion.php';

iniciar_sesion();
if ($_SERVER['REQUEST_METHOD'] === 'POST' && hash_equals($_SESSION['csrf'] ?? '', $_POST['csrf'] ?? '')) {
    $_SESSION = [];
    $p = session_get_cookie_params();
    setcookie(session_name(), '', [
        'expires' => time() - 3600, 'path' => $p['path'],
        'secure' => $p['secure'], 'httponly' => $p['httponly'], 'samesite' => $p['samesite'],
    ]);
    session_destroy();
}
header('Location: /', true, 303);
