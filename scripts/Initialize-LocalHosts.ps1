# Ejecutar desde PowerShell en Windows. Añade sólo los nombres del laboratorio.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$hostsPath = Join-Path $env:SystemRoot 'System32/drivers/etc/hosts'
$names = @('sitio1.local', 'sitio2.local')
$originalBytes = [IO.File]::ReadAllBytes($hostsPath)
if ($originalBytes.Length -ge 2 -and
    (($originalBytes[0] -eq 255 -and $originalBytes[1] -eq 254) -or
     ($originalBytes[0] -eq 254 -and $originalBytes[1] -eq 255))) {
    throw 'El archivo hosts tiene codificación UTF-16; revisar antes de añadir entradas.'
}
$content = [Text.Encoding]::UTF8.GetString($originalBytes)
$missingNames = [Collections.Generic.List[string]]::new()
foreach ($name in $names) {
    $present = $false
    foreach ($line in ($content -split '\r?\n')) {
        $fields = (($line -split '#', 2)[0].Trim() -split '\s+')
        if ($fields.Count -gt 1 -and $fields[1..($fields.Count - 1)] -contains $name) {
            if ($fields[0] -ne '127.0.0.1') { throw "Ya existe una asociación distinta para $name. No se modificó hosts." }
            $present = $true
        }
    }
    if (-not $present) { $missingNames.Add($name) }
}
if ($missingNames.Count -eq 0) {
    Write-Output 'PASS hosts: ambos nombres ya apuntan a 127.0.0.1; sin cambios.'
    exit 0
}
$isAdministrator = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdministrator) {
    # Windows solicita elevación para modificar este archivo protegido.
    $shellPath = (Get-Process -Id $PID).Path
    $arguments = @('-NoProfile', '-File', ('"' + $PSCommandPath + '"'))
    $elevated = Start-Process -FilePath $shellPath -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru
    if ($elevated.ExitCode -ne 0) { throw "La ejecución como administrador terminó con código $($elevated.ExitCode)." }
    Write-Output 'PASS hosts: configuración completada como administrador.'
    exit 0
}
$backupDirectory = Join-Path $projectRoot '.local-backups'
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
$backupPath = Join-Path $backupDirectory ('hosts-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N') + '.bak')
$stream = [IO.File]::Open($hostsPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Read)
try {
    $currentBytes = New-Object byte[] ([int]$stream.Length)
    $offset = 0
    while ($offset -lt $currentBytes.Length) {
        $read = $stream.Read($currentBytes, $offset, $currentBytes.Length - $offset)
        if ($read -eq 0) { throw 'No se pudo leer hosts completo.' }
        $offset += $read
    }
    if ([Convert]::ToBase64String($currentBytes) -ne [Convert]::ToBase64String($originalBytes)) {
        throw 'hosts cambió durante la preparación; repetir el comando. No se escribió.'
    }
    [IO.File]::WriteAllBytes($backupPath, $originalBytes)
    $addition = "`r`n# Infraestructura-web-DNS: acceso local al laboratorio`r`n" +
        (($missingNames | ForEach-Object { "127.0.0.1 $_" }) -join "`r`n") + "`r`n"
    $bytesToAppend = [Text.Encoding]::ASCII.GetBytes($addition)
    $stream.Position = $stream.Length
    $stream.Write($bytesToAppend, 0, $bytesToAppend.Length)
    $stream.Flush()
} finally { $stream.Dispose() }
Write-Output "PASS hosts: nombres añadidos. Copia de respaldo: $backupPath"
