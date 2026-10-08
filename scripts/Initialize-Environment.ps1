# Crea secretos únicamente si .env no existe; nunca los imprime.
$ErrorActionPreference = 'Stop'
$environmentPath = Join-Path (Split-Path -Parent $PSScriptRoot) '.env'
if (Test-Path -LiteralPath $environmentPath) {
    Write-Output '.env ya existe; no se sobrescribieron sus valores.'
    return
}
$randomSource = [Security.Cryptography.RandomNumberGenerator]::Create()
try {
    $values = foreach ($variableName in 'APP1_SESSION_SECRET', 'APP2_SESSION_SECRET') {
        $randomBytes = New-Object byte[] 32
        $randomSource.GetBytes($randomBytes)
        $variableName + '=' + [Convert]::ToBase64String($randomBytes)
    }
    # CreateNew evita sobrescribir un archivo creado mientras se generaban valores.
    $environmentStream = [IO.File]::Open($environmentPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
    $environmentWriter = [IO.StreamWriter]::new($environmentStream, [Text.UTF8Encoding]::new($false))
    try { foreach ($value in $values) { $environmentWriter.WriteLine($value) } }
    finally { $environmentWriter.Dispose() }
}
finally { $randomSource.Dispose() }
Write-Output '.env creado con dos secretos independientes; sus valores no se muestran.'
