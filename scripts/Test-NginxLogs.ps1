# Ejecutar desde PowerShell; requiere acceso al Engine. No detiene servicios.
$ErrorActionPreference = 'Stop'
$testMarker = 'fase5-' + [guid]::NewGuid().ToString('N')
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    foreach ($siteNumber in 1, 2) {
        $siteName = "sitio${siteNumber}.local"
        foreach ($case in @(
            @{ Path = '/'; Status = '200' },
            @{ Path = '/no-existe'; Status = '404' },
            @{ Path = '/pruebas/502'; Status = '502' }
        )) {
            $requestPath = $case.Path + '?prueba=' + $testMarker
            $responseLines = @(& curl.exe --noproxy '*' --silent --show-error --max-time 10 `
                --resolve "${siteName}:8080:127.0.0.1" --write-out '\n%{http_code}' "http://${siteName}:8080${requestPath}")
            if ($LASTEXITCODE -ne 0 -or $responseLines[-1] -ne $case.Status) {
                throw "Respuesta HTTP inesperada en $siteName$requestPath"
            }
        }
        $accessLines = @(& docker compose exec -T nginx tail -n 30 "/var/log/nginx/sitio${siteNumber}_access.log")
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer access log' }
        $newLines = @($accessLines | Where-Object { $_.Contains($testMarker) })
        if ($newLines.Count -ne 3) { throw "Se esperaban tres peticiones nuevas en el log de $siteName" }
        foreach ($statusValue in '200', '404', '502') {
            $matching = @($newLines | Where-Object { $_ -match " status=$statusValue " })
            if ($matching.Count -ne 1 -or $matching[0] -notmatch '^time=\S+ client=\S+ host=\S+ method=GET request="GET /' -or
                $matching[0] -notmatch "host=$([regex]::Escape($siteName)) " -or
                $matching[0] -notmatch ' upstream="[^" ]+" upstream_status="[^" ]+" duration=[0-9.]+$') {
                throw "Campos o estado incorrectos en access log de $siteName"
            }
        }
        $errorLines = @(& docker compose exec -T nginx tail -n 20 "/var/log/nginx/sitio${siteNumber}_error.log")
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer error log' }
        $matchingErrors = @($errorLines | Where-Object { $_.Contains($testMarker) -and $_.Contains('upstream prematurely closed connection') })
        if ($matchingErrors.Count -lt 1) { throw "No se encontró el error de comunicación de $siteName" }
        Write-Output "PASS ${siteName}: access log 200/404/502 con campos completos; error log con causa del 502"
        $newLines | ForEach-Object { Write-Output $_ }
    }
    $dockerLines = @(& docker compose logs --no-color --since 2m --tail 200 nginx 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron leer logs Docker' }
    foreach ($siteName in 'sitio1.local', 'sitio2.local') {
        foreach ($statusValue in '200', '404', '502') {
            if (-not @($dockerLines | Where-Object {
                $_.ToString().Contains($testMarker) -and $_.ToString().Contains("host=$siteName ") -and
                $_.ToString().Contains("status=$statusValue ")
            }).Count) { throw "Falta HTTP $statusValue de $siteName en logs Docker" }
        }
        if (-not @($dockerLines | Where-Object {
            $_.ToString().Contains($testMarker) -and $_.ToString().Contains("server: $siteName,") -and
            $_.ToString().Contains('upstream prematurely closed connection')
        }).Count) { throw "Falta el error de $siteName en stderr Docker" }
    }
    Write-Output 'PASS Docker: peticiones 200/404/502 y errores de ambos hosts visibles'
    Write-Output "Identificador de esta ejecución: $testMarker"
}
finally { Pop-Location }
