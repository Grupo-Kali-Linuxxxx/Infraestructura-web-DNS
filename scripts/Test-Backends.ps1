# Pruebas HTTP reales desde Windows; no detienen servicios.
$ErrorActionPreference = 'Stop'

function Invoke-BackendRequest {
    param([string]$HostName, [string]$Path, [string]$Method = 'GET',
        [string]$Body, [string]$ContentType = 'application/json')
    $curlArguments = @('--noproxy', '*', '--silent', '--show-error', '--max-time', '10',
        '--include', '--resolve', "${HostName}:8080:127.0.0.1", '--request', $Method,
        '--write-out', '\n%{http_code}')
    $bodyFile = $null
    try {
        if ($PSBoundParameters.ContainsKey('Body')) {
            $bodyFile = Join-Path ([IO.Path]::GetTempPath()) ('infra-fase6-' + [guid]::NewGuid().ToString('N') + '.json')
            [IO.File]::WriteAllText($bodyFile, $Body, [Text.UTF8Encoding]::new($false))
            $curlArguments += @('--header', "Content-Type: $ContentType", '--data-binary', "@$bodyFile")
        }
        $curlArguments += "http://${HostName}:8080${Path}"
        $responseLines = @(& curl.exe @curlArguments)
        if ($LASTEXITCODE -ne 0 -or $responseLines.Count -lt 2) { throw "curl falló en $HostName$Path" }
        $responseParts = ($responseLines[0..($responseLines.Count - 2)] -join "`n") -split "`n`n", 2
        return @{ Status = $responseLines[-1]; Headers = $responseParts[0]; Body = $responseParts[1] }
    }
    finally { if ($bodyFile) { Remove-Item -LiteralPath $bodyFile } }
}

function Assert-JsonResponse {
    param($Response, [string]$ExpectedStatus)
    if ($Response.Status -ne $ExpectedStatus -or $Response.Headers -notmatch '(?im)^Content-Type: application/json' -or
        $Response.Headers -match '(?im)^X-Powered-By:') {
        throw "Respuesta inválida: esperado JSON HTTP $ExpectedStatus; recibido $($Response.Status)"
    }
    return ($Response.Body | ConvertFrom-Json)
}

foreach ($site in @(
    @{ Name = 'sitio1.local'; Application = 'APP1' },
    @{ Name = 'sitio2.local'; Application = 'APP2' }
)) {
    $health = Assert-JsonResponse (Invoke-BackendRequest $site.Name '/health') '200'
    if ($health.estado -ne 'ok' -or $health.aplicacion -ne $site.Application) { throw 'Health incorrecto' }
    $info = Assert-JsonResponse (Invoke-BackendRequest $site.Name '/api/info') '200'
    if ($info.aplicacion -ne $site.Application -or $info.tecnologia -ne 'Node.js + Express') { throw 'API incorrecta' }
    $echoReply = Assert-JsonResponse (Invoke-BackendRequest $site.Name '/api/eco' -Method POST -Body '{"mensaje":" hola "}') '200'
    if ($echoReply.mensaje -ne 'hola' -or $echoReply.aplicacion -ne $site.Application) { throw 'Eco incorrecto' }

    foreach ($case in @(
        @{ Body = '{'; Type = 'application/json'; Status = '400' },
        @{ Body = '{"mensaje":42}'; Type = 'application/json'; Status = '400' },
        @{ Body = '[]'; Type = 'application/json'; Status = '400' },
        @{ Body = 'hola'; Type = 'text/plain'; Status = '415' },
        @{ Body = '{"mensaje":"hola"}'; Type = 'application/json; charset=iso-8859-1'; Status = '415' },
        @{ Body = ('{"mensaje":"' + ('a' * 9000) + '"}'); Type = 'application/json'; Status = '413' }
    )) {
        $errorReply = Assert-JsonResponse (Invoke-BackendRequest $site.Name '/api/eco' -Method POST -Body $case.Body -ContentType $case.Type) $case.Status
        if (-not $errorReply.error) { throw 'Falta mensaje de error' }
    }
    $notFound = Assert-JsonResponse (Invoke-BackendRequest $site.Name '/api/no-existe') '404'
    if ($notFound.aplicacion -ne $site.Application) { throw '404 API incorrecto' }
    $methodResponse = Invoke-BackendRequest $site.Name '/api/eco'
    $null = Assert-JsonResponse $methodResponse '405'
    if ($methodResponse.Headers -notmatch '(?im)^Allow: POST$') { throw 'Falta Allow: POST' }
    $failureResponse = Invoke-BackendRequest $site.Name '/api/pruebas/error'
    $null = Assert-JsonResponse $failureResponse '500'
    if ($failureResponse.Body -match 'Fallo controlado|stack|server.js') { throw 'El error revela detalles internos' }
    $null = Assert-JsonResponse (Invoke-BackendRequest $site.Name '/health') '200'
    Write-Output "PASS $($site.Name): health, info, POST eco; errores JSON 400/404/405/413/415/500; proceso sigue activo"
}
