<?php
// app/datos.php — Datos de ejemplo (en Tecnología Web II vendrán de una base de datos con PDO).
declare(strict_types=1);

// Contraseñas guardadas con password_hash (bcrypt), NUNCA en texto plano.
// Usuario de prueba: mamani.rosa / Horizonte2026
const PADRES = [
    'mamani.rosa' => [
        'nombre' => 'Rosa Mamani',
        'hash'   => '$2y$10$f2XF0dshC.eMrnbYfEj99eWl6Lc1LeNf7FsEJIKX7SPH60IbIBK1C',
        'hijo'   => 'Lucas Mamani — 5.º de secundaria',
    ],
];

const NOTAS = [
    'mamani.rosa' => [
        ['materia' => 'Matemáticas',   'nota' => 78],
        ['materia' => 'Física',        'nota' => 85],
        ['materia' => 'Lenguaje',      'nota' => 91],
        ['materia' => 'Computación',   'nota' => 98],
    ],
];
