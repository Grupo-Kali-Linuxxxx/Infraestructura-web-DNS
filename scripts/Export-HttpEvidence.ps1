$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$report = [Collections.Generic.List[string]]::new()
$report.Add('# Evidencia real de curl -v — fase 8')
$report.Add('')
$report.Add('Valores de Cookie y Set-Cookie omitidos. Sólo se exportan cabeceras seleccionadas; los diagnósticos internos de curl no se publican.')
$report.Add('')
$report.Add('Ejecutado UTC: ' + [DateTime]::UtcNow.ToString('u'))
$bodyPath = Join-Path ([IO.Path]::GetTempPath()) ('infra-http-body-' + [guid]::NewGuid().ToString('N'))
$jarPath = Join-Path ([IO.Path]::GetTempPath()) ('infra-http-cookies-' + [guid]::NewGuid().ToString('N'))
function Test-VerboseRequest {
    param([string]$Site, [string]$Route, [string]$Method, [int]$Expected, [switch]$Cookies)
    $url = "http://${Site}:8080$Route"
    $arguments = @('--verbose', '--silent', '--show-error', '--noproxy', '*', '--max-time', '10',
        '--resolve', "${Site}:8080:127.0.0.1", '--request', $Method, '--output', $bodyPath,
        '--write-out', 'HTTP_STATUS=%{http_code}', $url)
    if ($Cookies) { $arguments += @('--cookie', $jarPath, '--cookie-jar', $jarPath) }
    $trace = @(& curl.exe @arguments 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) { throw "curl falló para $Method $url" }
    $status = @($trace | Where-Object { $_ -match '^HTTP_STATUS=\d{3}$' })
    if ($status.Count -ne 1 -or $status[0] -ne "HTTP_STATUS=$Expected") { throw "Estado HTTP inesperado para $Method $url" }
    $report.Add('')
    $report.Add("## $Method $url")
    $report.Add('')
    $report.Add('```text')
    foreach ($line in $trace) {
        if ($line -match '^> Cookie:') { $report.Add('> Cookie: [OMITIDO]') }
        elseif ($line -match '^< Set-Cookie:') { $report.Add(($line -replace '(Set-Cookie:\s*[^=;]+)=([^;]*)', '$1=[OMITIDO]')) }
        elseif ($line -match '^> (GET |POST |DELETE |Host:|Content-Type:)' -or
                $line -match '^< (HTTP/|Server:|Content-Type:|Cache-Control:)' -or
                $line -match '^HTTP_STATUS=') { $report.Add($line) }
    }
    $body = Get-Content -LiteralPath $bodyPath -Raw
    if ($body.TrimStart().StartsWith('{')) {
        $null = $body | ConvertFrom-Json
        $report.Add($body.Trim())
    } else {
        $heading = [regex]::Match($body, '(?is)<h1[^>]*>(.*?)</h1>')
        $report.Add('Cuerpo HTML: ' + ($heading.Groups[1].Value -replace '<[^>]+>', '').Trim())
    }
    $report.Add('```')
    Write-Output "PASS curl -v: $Method $url => $Expected"
}
try {
    foreach ($site in 'sitio1.local', 'sitio2.local') {
        foreach ($case in @(
            @{ Route = '/'; Status = 200 }, @{ Route = '/diagnostico'; Status = 200 },
            @{ Route = '/no-existe'; Status = 404 }, @{ Route = '/pruebas/502'; Status = 502 },
            @{ Route = '/api/no-existe'; Status = 404 }
        )) { Test-VerboseRequest $site $case.Route 'GET' $case.Status }
        Test-VerboseRequest $site '/api/sesion' 'GET' 200 -Cookies
        Test-VerboseRequest $site '/api/sesion' 'POST' 201 -Cookies
        Test-VerboseRequest $site '/api/sesion/incrementar' 'POST' 200 -Cookies
        Test-VerboseRequest $site '/api/sesion' 'GET' 200 -Cookies
        Test-VerboseRequest $site '/api/sesion' 'DELETE' 200 -Cookies
        Test-VerboseRequest $site '/api/sesion' 'GET' 200 -Cookies
    }
    $report | Set-Content -LiteralPath (Join-Path $projectRoot 'docs/evidencias/curl-fase-08.md') -Encoding utf8
} finally {
    foreach ($ownedFile in @($bodyPath, $jarPath)) {
        if (Test-Path -LiteralPath $ownedFile) { Remove-Item -LiteralPath $ownedFile -Force }
    }
}
