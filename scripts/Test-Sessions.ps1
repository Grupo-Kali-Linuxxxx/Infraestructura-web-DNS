param([switch]$IncludeRestart)
$ErrorActionPreference = 'Stop'
$cookieFiles = @()

function Invoke-SessionRequest {
    param([string]$HostName, [string]$Path = '/api/sesion', [string]$Method = 'GET',
        [string]$Jar, [string]$CookieOverride)
    $curlArguments = @('--noproxy', '*', '--silent', '--show-error', '--max-time', '10',
        '--include', '--resolve', "${HostName}:8080:127.0.0.1", '--request', $Method,
        '--cookie', $Jar, '--cookie-jar', $Jar, '--write-out', '\n%{http_code}')
    if ($CookieOverride) { $curlArguments += @('--header', "Cookie: $CookieOverride") }
    $curlArguments += "http://${HostName}:8080${Path}"
    $responseLines = @(& curl.exe @curlArguments)
    if ($LASTEXITCODE -ne 0 -or $responseLines.Count -lt 2) { throw "curl falló en $HostName$Path" }
    $parts = ($responseLines[0..($responseLines.Count - 2)] -join "`n") -split "`n`n", 2
    return @{ Status = $responseLines[-1]; Headers = $parts[0]; Body = $parts[1] }
}

function Assert-SessionState {
    param($Response, [string]$Application, [bool]$Active, [int]$Counter, [string]$Status = '200')
    if ($Response.Status -ne $Status -or $Response.Headers -notmatch '(?im)^Content-Type: application/json') {
        throw "Respuesta de sesión inválida; esperado JSON HTTP $Status"
    }
    $state = $Response.Body | ConvertFrom-Json
    if ($state.aplicacion -ne $Application -or $state.activa -ne $Active -or $state.contador -ne $Counter) {
        throw "Estado de sesión incorrecto para $Application"
    }
}

function Get-SessionCookie {
    param($Response, [string]$CookieName)
    $cookieLine = @($Response.Headers -split "`n" | Where-Object { $_ -match ('(?i)^Set-Cookie: ' + [regex]::Escape($CookieName) + '=') })
    if ($cookieLine.Count -ne 1 -or $cookieLine[0] -notmatch '(?i); HttpOnly' -or
        $cookieLine[0] -notmatch '(?i); SameSite=Lax' -or $cookieLine[0] -notmatch '(?i); Path=/' -or
        $cookieLine[0] -notmatch '(?i); Expires=' -or $cookieLine[0] -match '(?i); Secure|; Domain=') {
        throw 'Cookie de sesión sin los atributos esperados para HTTP local'
    }
    return (($cookieLine[0] -replace '(?i)^Set-Cookie:\s*', '').Split(';')[0])
}

$sites = @(
    @{ Name = 'sitio1.local'; Application = 'APP1'; Cookie = 'app1.sid'; Service = 'app1' },
    @{ Name = 'sitio2.local'; Application = 'APP2'; Cookie = 'app2.sid'; Service = 'app2' }
)
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    foreach ($clientName in 'principal', 'independiente') {
        $filePath = Join-Path ([IO.Path]::GetTempPath()) ('infra-sesion-' + $clientName + '-' + [guid]::NewGuid().ToString('N') + '.cookies')
        [IO.File]::WriteAllText($filePath, '', [Text.UTF8Encoding]::new($false))
        $cookieFiles += $filePath
    }
    $mainJar = $cookieFiles[0]
    $independentJar = $cookieFiles[1]
    foreach ($site in $sites) {
        $page = Invoke-SessionRequest $site.Name '/sesiones' -Jar $mainJar
        if ($page.Status -ne '200' -or -not $page.Body.Contains('Crear sesión')) { throw 'No se sirve la interfaz de sesiones' }
        $initial = Invoke-SessionRequest $site.Name -Jar $mainJar
        Assert-SessionState $initial $site.Application $false 0
        if ($initial.Headers -match '(?im)^Set-Cookie:') { throw 'Consultar sin sesión no debe crear cookie' }
        $earlyIncrement = Invoke-SessionRequest $site.Name '/api/sesion/incrementar' 'POST' -Jar $mainJar
        if ($earlyIncrement.Status -ne '409') { throw 'Incrementar sin sesión debe devolver 409' }
        $created = Invoke-SessionRequest $site.Name -Method POST -Jar $mainJar
        Assert-SessionState $created $site.Application $true 0 '201'
        $oldCookie = Get-SessionCookie $created $site.Cookie
        foreach ($counterValue in 1, 2) {
            Assert-SessionState (Invoke-SessionRequest $site.Name '/api/sesion/incrementar' 'POST' -Jar $mainJar) $site.Application $true $counterValue
        }
        Assert-SessionState (Invoke-SessionRequest $site.Name -Jar $mainJar) $site.Application $true 2
        Assert-SessionState (Invoke-SessionRequest $site.Name -Jar $independentJar) $site.Application $false 0
        Assert-SessionState (Invoke-SessionRequest $site.Name -Jar $independentJar -CookieOverride ($oldCookie + 'x')) $site.Application $false 0

        $deleted = Invoke-SessionRequest $site.Name -Method DELETE -Jar $mainJar
        Assert-SessionState $deleted $site.Application $false 0
        if ($deleted.Headers -notmatch ('(?im)^Set-Cookie: ' + [regex]::Escape($site.Cookie) + '=;') -or
            $deleted.Headers -notmatch 'Expires=Thu, 01 Jan 1970') { throw 'La destrucción debe expirar la cookie' }
        Assert-SessionState (Invoke-SessionRequest $site.Name -Jar $mainJar) $site.Application $false 0
        Assert-SessionState (Invoke-SessionRequest $site.Name -Jar $independentJar -CookieOverride $oldCookie) $site.Application $false 0

        $newSession = Invoke-SessionRequest $site.Name -Method POST -Jar $mainJar
        Assert-SessionState $newSession $site.Application $true 0 '201'
        $secondCookie = Get-SessionCookie $newSession $site.Cookie
        if ($oldCookie -eq $secondCookie) { throw 'La nueva sesión debe tener otro identificador' }
        Assert-SessionState (Invoke-SessionRequest $site.Name '/api/sesion/incrementar' 'POST' -Jar $mainJar) $site.Application $true 1
        $regenerated = Invoke-SessionRequest $site.Name -Method POST -Jar $mainJar
        Assert-SessionState $regenerated $site.Application $true 0 '201'
        if ((Get-SessionCookie $regenerated $site.Cookie) -eq $secondCookie) { throw 'Crear de nuevo debe regenerar la sesión' }
        Assert-SessionState (Invoke-SessionRequest $site.Name -Jar $independentJar -CookieOverride $secondCookie) $site.Application $false 0
        Write-Output "PASS $($site.Name): cookie protegida, contador persistente, aislamiento de cliente, firma, destrucción y regeneración"
    }
    Assert-SessionState (Invoke-SessionRequest 'sitio1.local' '/api/sesion/incrementar' 'POST' -Jar $mainJar) 'APP1' $true 1
    Assert-SessionState (Invoke-SessionRequest 'sitio2.local' -Jar $mainJar) 'APP2' $true 0
    Assert-SessionState (Invoke-SessionRequest 'sitio2.local' '/api/sesion/incrementar' 'POST' -Jar $mainJar) 'APP2' $true 1
    Assert-SessionState (Invoke-SessionRequest 'sitio1.local' -Jar $mainJar) 'APP1' $true 1
    Write-Output 'PASS aislamiento: ambos hosts mantienen contadores independientes en el mismo cliente'

    if ($IncludeRestart) {
        foreach ($site in $sites) {
            & docker compose restart $site.Service
            if ($LASTEXITCODE -ne 0) { throw 'No se pudo reiniciar el backend' }
            & docker compose up -d --no-deps --wait --wait-timeout 60 $site.Service
            if ($LASTEXITCODE -ne 0) { throw 'El backend no recuperó su estado saludable' }
            Assert-SessionState (Invoke-SessionRequest $site.Name -Jar $mainJar) $site.Application $false 0
            Write-Output "PASS $($site.Name): reinicio elimina sesiones de MemoryStore; backend saludable"
        }
    }
    foreach ($site in $sites) {
        Assert-SessionState (Invoke-SessionRequest $site.Name -Method DELETE -Jar $mainJar) $site.Application $false 0
    }
    Write-Output 'Cookies e identificadores no se muestran; las sesiones de prueba se destruyeron.'
}
finally {
    foreach ($cookieFile in $cookieFiles) { Remove-Item -LiteralPath $cookieFile -ErrorAction SilentlyContinue }
    Pop-Location
}
