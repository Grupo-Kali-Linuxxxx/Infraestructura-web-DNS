<?php
// public/entrar.php — Valida el formulario y crea la sesión.
declare(strict_types=1);
require __DIR__ . '/../app/sesion.php';
require __DIR__ . '/../app/datos.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit('Método no permitido');
}

iniciar_sesion();
if (!hash_equals($_SESSION['csrf'] ?? '', $_POST['csrf'] ?? '')) {
    http_response_code(403);                                  // formulario que no salió de nuestro sitio
    exit('Solicitud no válida');
}

$usuario = trim((string) ($_POST['usuario'] ?? ''));
$clave   = (string) ($_POST['clave'] ?? '');
$padre   = PADRES[$usuario] ?? null;

if ($padre === null || !password_verify($clave, $padre['hash'])) {
    error_log("portal: acceso fallido para '$usuario' desde {$_SERVER['REMOTE_ADDR']}");
    header('Location: /?error=1', true, 303);
    exit;
}

// TODO: al iniciar sesión, pedir a PHP un ID de sesión NUEVO y borrar el anterior (¿por qué? fijación de sesión)
$_SESSION['usuario'] = ['login' => $usuario, 'nombre' => $padre['nombre'], 'hijo' => $padre['hijo']];
header('Location: /panel.php', true, 303);
