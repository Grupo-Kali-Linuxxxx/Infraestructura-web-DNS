<?php
// public/panel.php — Notas del hijo (solo con sesión iniciada).
declare(strict_types=1);
require __DIR__ . '/../app/sesion.php';
require __DIR__ . '/../app/datos.php';

$usuario = exigir_sesion();
$notas   = NOTAS[$usuario['login']] ?? [];
$_SESSION['visitas_panel'] = ($_SESSION['visitas_panel'] ?? 0) + 1;
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Panel · Portal para padres</title>
  <link rel="stylesheet" href="/estilo.css">
</head>
<body>
  <main>
    <h1>Hola, <?= e($usuario['nombre']) ?></h1>
    <p>Estudiante: <strong><?= e($usuario['hijo']) ?></strong></p>
    <table>
      <caption>Notas del 2.º trimestre</caption>
      <thead><tr><th scope="col">Materia</th><th scope="col">Nota</th></tr></thead>
      <tbody>
      <?php foreach ($notas as $fila): ?>
        <tr><td><?= e($fila['materia']) ?></td><td><?= (int) $fila['nota'] ?></td></tr>
      <?php endforeach; ?>
      </tbody>
    </table>
    <p><small>Visitas a este panel en esta sesión: <?= (int) $_SESSION['visitas_panel'] ?></small></p>
    <form method="post" action="/salir.php">
      <input type="hidden" name="csrf" value="<?= e(token_csrf()) ?>">
      <button type="submit">Cerrar sesión</button>
    </form>
  </main>
</body>
</html>
