param([switch]$IncludeBackendFailure)
$ErrorActionPreference = 'Stop'

function Get-ErrorTestResponse {
    param([string]$HostName, [string]$Path)
    $responseLines = @(& curl.exe --noproxy '*' --silent --show-error --max-time 10 --include `
        --resolve "${HostName}:8080:127.0.0.1" --write-out '\n%{http_code}' "http://${HostName}:8080${Path}")
    if ($LASTEXITCODE -ne 0 -or $responseLines.Count -lt 2) {
        throw "No se pudo consultar $HostName$Path"
    }
    return @{
        Status = $responseLines[-1]
        Response = $responseLines[0..($responseLines.Count - 2)] -join "`n"
    }
}

function Assert-ErrorPage {
    param([string]$HostName, [string]$Path, [string]$Code, [string]$Marker)
    $result = Get-ErrorTestResponse -HostName $HostName -Path $Path
    if ($result.Status -ne $Code -or -not $result.Response.Contains($Marker) -or
        $result.Response -notmatch '(?im)^Content-Type: text/html' -or
        $result.Response -notmatch '(?im)^Cache-Control: no-store') {
        throw "Error en ${HostName}${Path}: esperado HTML personalizado HTTP $Code; recibido $($result.Status)"
    }
    Write-Output "PASS $HostName$Path : HTTP $Code, HTML personalizado y sin caché"
}

$sites = @(
    @{ Name = 'sitio1.local'; Service = 'app1'; Marker = 'Backend App 1' },
    @{ Name = 'sitio2.local'; Service = 'app2'; Marker = 'Backend App 2' }
)

foreach ($site in $sites) {
    Assert-ErrorPage $site.Name '/no-existe' '404' 'Recurso no disponible'
    Assert-ErrorPage $site.Name '/errors/no-existe' '404' 'Recurso no disponible'
    Assert-ErrorPage $site.Name '/errors/404.html' '404' 'Recurso no disponible'
    Assert-ErrorPage $site.Name '/errors/502.html' '404' 'Recurso no disponible'
    Assert-ErrorPage $site.Name '/pruebas/502' '502' 'Servicio temporalmente no disponible'
}
Assert-ErrorPage 'desconocido.test' '/errors/no-existe' '404' 'Recurso no disponible'

if ($IncludeBackendFailure) {
    # Esta opción causa una interrupción breve por backend. Se restaura en finally.
    Push-Location (Split-Path -Parent $PSScriptRoot)
    try {
        $runningServices = @(& docker compose ps --status running --services)
        if ($LASTEXITCODE -ne 0 -or 'app1' -notin $runningServices -or 'app2' -notin $runningServices) {
            throw 'Ambos backends deben estar activos antes de probar fallos'
        }
        foreach ($site in $sites) {
            try {
                & docker compose stop --timeout 5 $site.Service
                if ($LASTEXITCODE -ne 0) { throw "No se pudo detener $($site.Service)" }
                $outage = Get-ErrorTestResponse $site.Name '/'
                if ($outage.Status -eq '502') {
                    if (-not $outage.Response.Contains('Servicio temporalmente no disponible')) {
                        throw 'El 502 durante la parada no mostró la página personalizada'
                    }
                    Write-Output "PASS $($site.Name): parada produjo HTTP 502 personalizado"
                }
                elseif ($outage.Status -eq '504') {
                    Write-Output "PASS $($site.Name): parada produjo HTTP 504 (timeout real, sin cambiar el código)"
                }
                else { throw "Se esperaba 502 o 504 durante la parada; recibido $($outage.Status)" }
                $otherSite = $sites | Where-Object Name -NE $site.Name
                $otherResponse = Get-ErrorTestResponse $otherSite.Name '/'
                if ($otherResponse.Status -ne '200' -or -not $otherResponse.Response.Contains($otherSite.Marker)) {
                    throw 'El otro host dejó de funcionar durante la prueba'
                }
                Write-Output "PASS $($otherSite.Name): continúa HTTP 200 mientras $($site.Service) está detenido"
            }
            finally {
                & docker compose start $site.Service
                if ($LASTEXITCODE -ne 0) { throw "No se pudo restaurar $($site.Service); iniciarlo manualmente" }
                $recovered = $false
                for ($attempt = 0; $attempt -lt 10; $attempt++) {
                    $recovery = Get-ErrorTestResponse $site.Name '/'
                    if ($recovery.Status -eq '200' -and $recovery.Response.Contains($site.Marker)) {
                        $recovered = $true
                        break
                    }
                    Start-Sleep -Milliseconds 500
                }
                if (-not $recovered) { throw "No se confirmó recuperación HTTP de $($site.Service)" }
                Write-Output "PASS $($site.Name): backend restaurado, HTTP 200"
            }
        }
    }
    finally { Pop-Location }
}
else {
    Write-Output '502 probado con cierre controlado de conexión. Parada de contenedores omitida; usar -IncludeBackendFailure para incluirla.'
}
