# Usa Node instalado en Docker; no instala paquetes en Windows.
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Test-SessionConcurrency.js') -Raw |
        & docker compose exec -T app1 node
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas de concurrencia de sesiones.' }
} finally { Pop-Location }
