# Ejecutar desde PowerShell en Windows. No requiere modificar el archivo hosts.
$ErrorActionPreference = 'Stop'

function Get-LocalResponse {
    param([string]$HostName, [string]$Path = '/', [string[]]$ExtraHeaders = @())
    $curlArguments = @('--noproxy', '*', '--silent', '--show-error', '--max-time', '10',
        '--resolve', "${HostName}:8080:127.0.0.1", '--write-out', '\n%{http_code}')
    foreach ($headerValue in $ExtraHeaders) {
        $curlArguments += @('--header', $headerValue)
    }
    $curlArguments += "http://${HostName}:8080${Path}"
    $outputLines = @(& curl.exe @curlArguments)
    if ($LASTEXITCODE -ne 0) { throw "curl falló para $HostName$Path" }
    if ($outputLines.Count -lt 2 -or $outputLines[-1] -ne '200') {
        throw "Se esperaba HTTP 200 para $HostName$Path; respuesta: $outputLines"
    }
    return ($outputLines[0..($outputLines.Count - 2)] -join "`n")
}

foreach ($site in @(
    @{ Name = 'sitio1.local'; Application = 'APP1'; Marker = 'Backend App 1' },
    @{ Name = 'sitio2.local'; Application = 'APP2'; Marker = 'Backend App 2' }
)) {
    $page = Get-LocalResponse -HostName $site.Name
    if (-not $page.Contains($site.Marker)) { throw "Backend incorrecto para $($site.Name)" }

    $diagnostic = Get-LocalResponse -HostName $site.Name -Path '/diagnostico?prueba=fase3' |
        ConvertFrom-Json
    if ($diagnostic.aplicacion -ne $site.Application -or $diagnostic.host -ne $site.Name) {
        throw "Enrutamiento o Host incorrectos para $($site.Name)"
    }
    if ($diagnostic.metodo -ne 'GET' -or $diagnostic.versionHttp -ne '1.1' -or
        $diagnostic.ruta -ne '/diagnostico?prueba=fase3') {
        throw 'El proxy no conservó método/ruta o la versión HTTP esperada'
    }
    if (-not $diagnostic.xRealIp -or $diagnostic.xForwardedProto -ne 'http' -or
        $diagnostic.xForwardedFor -ne $diagnostic.xRealIp) {
        throw 'Faltan cabeceras del proxy o sus valores son incorrectos'
    }
    if ($diagnostic.ipConexion -eq $diagnostic.xRealIp) {
        throw 'Se esperaba una conexión desde Nginx distinta del cliente externo'
    }

    $spoofed = Get-LocalResponse -HostName $site.Name -Path '/diagnostico' -ExtraHeaders @(
        'X-Real-IP: 203.0.113.7', 'X-Forwarded-Proto: https', 'X-Forwarded-For: 203.0.113.7'
    ) | ConvertFrom-Json
    if ($spoofed.xRealIp -ne $diagnostic.xRealIp -or $spoofed.xForwardedProto -ne 'http' -or
        $spoofed.xForwardedFor -ne "203.0.113.7, $($diagnostic.xRealIp)") {
        throw 'Comportamiento inesperado de las cabeceras enviadas por el cliente'
    }
    Write-Output "PASS $($site.Name): HTTP 200, $($site.Application), ruta y cabeceras correctas"
    Write-Output "PASS $($site.Name): IP/protocolo sobrescritos; X-Forwarded-For conserva prefijo no confiable"
}

$defaultPage = Get-LocalResponse -HostName 'desconocido.test'
if (-not $defaultPage.Contains('Nginx funcionando correctamente')) {
    throw 'El host desconocido no llegó al servidor por defecto'
}
Write-Output 'PASS host desconocido: responde el servidor por defecto, sin backend'
