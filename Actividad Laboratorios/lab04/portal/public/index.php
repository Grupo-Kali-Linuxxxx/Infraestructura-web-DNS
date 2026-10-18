<?php
// public/index.php — Inicio de sesión del portal para padres.
declare(strict_types=1);
require __DIR__ . '/../app/sesion.php';

if (usuario_actual() !== null) {
    header('Location: /panel.php', true, 302);
    exit;
}
$error = isset($_GET['error']);
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Portal para padres · U.E. Horizonte</title>
  <link rel="stylesheet" href="/estilo.css">
</head>
<body>
  <main>
    <h1>Portal para padres</h1>
    <?php if ($error): ?>
      <p class="error" role="alert">Usuario o contraseña incorrectos.</p>
    <?php endif; ?>
    <form method="post" action="/entrar.php">
      <input type="hidden" name="csrf" value="<?= e(token_csrf()) ?>">
      <label for="usuario">Usuario</label>
      <input id="usuario" name="usuario" autocomplete="username" required>
      <label for="clave">Contraseña</label>
      <input id="clave" name="clave" type="password" autocomplete="current-password" required>
      <button type="submit">Entrar</button>
    </form>
    <p><small>Servido por PHP <?= e(PHP_VERSION) ?> (PHP-FPM) detrás de Nginx.</small></p>
  </main>
</body>
</html>
