# PowerShell 7 y Chrome instalado. No requiere WebDriver, paquetes ni archivo hosts.
param([switch]$UseSystemResolution)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path -LiteralPath $chromePath)) { throw 'No se encontró Chrome en la ruta prevista' }
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$profilePath = Join-Path $tempRoot ('infra-http-browser-' + [guid]::NewGuid().ToString('N'))
$outputPath = Join-Path $projectRoot 'screenshots'
New-Item -ItemType Directory -Path $profilePath, $outputPath -Force | Out-Null
$script:cdpId = 0
$script:requestMethods = @{}
$script:requestCookies = @{}
$script:responses = [Collections.Generic.List[object]]::new()
$cookieEvidence = [Collections.Generic.List[object]]::new()
$script:socket = $null
$chromeProcess = $null

function Save-NetworkEvent {
    param($Event)
    $parameters = $Event.params
    if ($Event.method -eq 'Network.requestWillBeSent') {
        $script:requestMethods[$parameters.requestId] = $parameters.request.method
    }
    elseif ($Event.method -eq 'Network.requestWillBeSentExtraInfo') {
        $script:requestCookies[$parameters.requestId] = $parameters.headers.ContainsKey('Cookie')
    }
    elseif ($Event.method -eq 'Network.responseReceived' -and $parameters.response.url -match '^http://sitio[12]\.local:8080/') {
        $response = $parameters.response
        $script:responses.Add([ordered]@{
            requestId = $parameters.requestId; url = $response.url; status = $response.status
            contentType = $response.headers['Content-Type']; cacheControl = $response.headers['Cache-Control']
        })
    }
}

function Send-Cdp {
    param([string]$Method, [hashtable]$Parameters = @{})
    $script:cdpId++
    $currentId = $script:cdpId
    $payload = @{ id = $currentId; method = $Method; params = $Parameters } | ConvertTo-Json -Compress -Depth 10
    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
    $timeout = [Threading.CancellationTokenSource]::new(15000)
    try {
        [void]($script:socket.SendAsync([ArraySegment[byte]]::new($bytes), [Net.WebSockets.WebSocketMessageType]::Text, $true, $timeout.Token).GetAwaiter().GetResult())
        while ($true) {
            $buffer = New-Object byte[] 65536
            $messageStream = [IO.MemoryStream]::new()
            try {
                do {
                    $received = $script:socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), $timeout.Token).GetAwaiter().GetResult()
                    if ($received.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close) { throw 'Chrome cerró la conexión de pruebas' }
                    $messageStream.Write($buffer, 0, $received.Count)
                } while (-not $received.EndOfMessage)
                $message = [Text.Encoding]::UTF8.GetString($messageStream.ToArray()) | ConvertFrom-Json -AsHashtable
            }
            finally { $messageStream.Dispose() }
            if ($message.ContainsKey('method')) { Save-NetworkEvent $message }
            if ($message.id -eq $currentId) {
                if ($message.ContainsKey('error')) { throw "CDP falló al ejecutar $Method" }
                return $message.result
            }
        }
    }
    finally { $timeout.Dispose() }
}

function Get-BrowserValue {
    param([string]$Expression)
    $result = Send-Cdp 'Runtime.evaluate' @{ expression = $Expression; returnByValue = $true }
    if ($result.ContainsKey('exceptionDetails')) { throw 'La expresión de comprobación falló en el navegador' }
    return $result.result.value
}

function Wait-BrowserCondition {
    param([string]$Expression)
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        try { if (Get-BrowserValue $Expression) { return } }
        catch { if ($attempt -eq 59) { throw } }
        Start-Sleep -Milliseconds 200
    }
    throw 'La página no alcanzó el estado esperado dentro del tiempo de prueba'
}

function Open-SessionPage {
    param([string]$HostName)
    $null = Send-Cdp 'Page.navigate' @{ url = "http://${HostName}:8080/sesiones" }
    Wait-BrowserCondition "location.hostname === '$HostName' && document.readyState === 'complete' && document.getElementById('create') && !document.getElementById('create').disabled && document.getElementById('feedback').textContent === 'Estado actualizado.'"
}

function Click-SessionButton {
    param([string]$ButtonId)
    $null = Get-BrowserValue "document.getElementById('$ButtonId').click()"
    Wait-BrowserCondition "!document.getElementById('$ButtonId').disabled"
}

function Assert-PageState {
    param([string]$Application, [string]$State, [int]$Counter)
    $snapshot = Get-BrowserValue "({app:document.getElementById('application').textContent,state:document.getElementById('state').textContent,count:Number(document.getElementById('counter').textContent),httpOnlyHidden:document.cookie === ''})"
    if ($snapshot.app -ne "Aplicación: $Application" -or $snapshot.state -ne $State -or
        $snapshot.count -ne $Counter -or -not $snapshot.httpOnlyHidden) { throw "Estado visual incorrecto de $Application" }
}

function Save-BrowserScreenshot {
    param([string]$FileName)
    $imageResult = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }
    [IO.File]::WriteAllBytes((Join-Path $outputPath $FileName), [Convert]::FromBase64String($imageResult.data))
}

try {
    $arguments = @('--headless=new', '--no-first-run', '--no-default-browser-check', '--disable-background-networking',
        '--disable-sync', '--disable-extensions', '--no-proxy-server', '--remote-debugging-port=0',
        '--remote-debugging-address=127.0.0.1', "--user-data-dir=`"$profilePath`"",
        'about:blank')
    if (-not $UseSystemResolution) {
        $arguments += '--host-resolver-rules="MAP sitio1.local 127.0.0.1, MAP sitio2.local 127.0.0.1"'
    }
    $chromeProcess = Start-Process -FilePath $chromePath -ArgumentList $arguments -WindowStyle Hidden -PassThru
    $activePortPath = Join-Path $profilePath 'DevToolsActivePort'
    for ($attempt = 0; $attempt -lt 60 -and -not (Test-Path -LiteralPath $activePortPath); $attempt++) { Start-Sleep -Milliseconds 200 }
    if (-not (Test-Path -LiteralPath $activePortPath)) { throw 'Chrome no inició su puerto de pruebas' }
    $debugPort = [int]([IO.File]::ReadAllLines($activePortPath)[0])
    $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$debugPort/json/list" -TimeoutSec 5
    $target = $targets | Where-Object type -EQ 'page' | Select-Object -First 1
    $debugUri = [uri]$target.webSocketDebuggerUrl
    if ($debugUri.Scheme -ne 'ws' -or $debugUri.Host -ne '127.0.0.1') { throw 'Destino CDP no local' }
    $script:socket = [Net.WebSockets.ClientWebSocket]::new()
    [void]($script:socket.ConnectAsync($debugUri, [Threading.CancellationToken]::None).GetAwaiter().GetResult())
    $null = Send-Cdp 'Page.enable'
    $null = Send-Cdp 'Runtime.enable'
    $null = Send-Cdp 'Network.enable'
    $null = Send-Cdp 'Network.setCacheDisabled' @{ cacheDisabled = $true }
    $null = Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 1280; height = 900; deviceScaleFactor = 1; mobile = $false }
    $browserVersion = (Send-Cdp 'Browser.getVersion').product

    foreach ($site in @(
        @{ HostName = 'sitio1.local'; Application = 'APP1'; CookieName = 'app1.sid'; Counter = 2; Image = 'app1-sesion.png' },
        @{ HostName = 'sitio2.local'; Application = 'APP2'; CookieName = 'app2.sid'; Counter = 1; Image = 'app2-sesion.png' }
    )) {
        Open-SessionPage $site.HostName
        Assert-PageState $site.Application 'Sin sesión activa' 0
        Click-SessionButton 'create'
        Assert-PageState $site.Application 'Sesión activa' 0
        for ($increment = 0; $increment -lt $site.Counter; $increment++) { Click-SessionButton 'increment' }
        Click-SessionButton 'read'
        Assert-PageState $site.Application 'Sesión activa' $site.Counter
        $cookies = (Send-Cdp 'Network.getCookies' @{ urls = @("http://$($site.HostName):8080/") }).cookies
        $cookie = @($cookies | Where-Object name -EQ $site.CookieName)
        if ($cookie.Count -ne 1 -or -not $cookie[0].httpOnly -or $cookie[0].secure -or
            $cookie[0].sameSite -ne 'Lax' -or $cookie[0].domain -ne $site.HostName) { throw 'Cookie incorrecta en Chrome' }
        $cookieEvidence.Add([ordered]@{ name = $cookie[0].name; domain = $cookie[0].domain;
            path = $cookie[0].path; httpOnly = $cookie[0].httpOnly; sameSite = $cookie[0].sameSite;
            secure = $cookie[0].secure; value = '[OMITIDO]' })
        Save-BrowserScreenshot $site.Image
        Write-Output "PASS Chrome $($site.HostName): botones, contador y cookie HttpOnly/Lax del host correcto"
    }
    Open-SessionPage 'sitio1.local'
    Assert-PageState 'APP1' 'Sesión activa' 2
    Click-SessionButton 'destroy'
    Assert-PageState 'APP1' 'Sin sesión activa' 0
    $remainingCookies = (Send-Cdp 'Network.getCookies' @{ urls = @('http://sitio1.local:8080/') }).cookies
    if (@($remainingCookies | Where-Object name -EQ 'app1.sid').Count) { throw 'Cookie no eliminada al destruir sesión' }
    Save-BrowserScreenshot 'app1-sesion-destruida.png'
    Click-SessionButton 'create'
    Assert-PageState 'APP1' 'Sesión activa' 0
    Click-SessionButton 'destroy'
    Open-SessionPage 'sitio2.local'
    Assert-PageState 'APP2' 'Sesión activa' 1
    Click-SessionButton 'destroy'
    Assert-PageState 'APP2' 'Sin sesión activa' 0
    Write-Output 'PASS Chrome: persistencia al navegar, aislamiento entre hosts, destrucción y nueva sesión desde cero'

    foreach ($page in @(
        @{ Path = '/no-existe'; Marker = 'Recurso no disponible'; Image = 'error-404.png' },
        @{ Path = '/pruebas/502'; Marker = 'Servicio temporalmente no disponible'; Image = 'error-502.png' }
    )) {
        $null = Send-Cdp 'Page.navigate' @{ url = ('http://sitio1.local:8080' + $page.Path) }
        Wait-BrowserCondition "location.pathname === '$($page.Path)' && document.readyState === 'complete' && document.querySelector('h1')?.textContent === '$($page.Marker)'"
        Save-BrowserScreenshot $page.Image
    }
    $null = Send-Cdp 'Runtime.evaluate' @{ expression = 'true' }
    $networkEvidence = @($script:responses | ForEach-Object {
        [ordered]@{ method = $script:requestMethods[$_.requestId]; url = $_.url; status = $_.status;
            contentType = $_.contentType; cacheControl = $_.cacheControl; cookieSent = [bool]$script:requestCookies[$_.requestId] }
    })
    foreach ($statusValue in 200, 201, 404, 502) {
        if (-not @($networkEvidence | Where-Object status -EQ $statusValue).Count) { throw "Falta estado $statusValue en Network de Chrome" }
    }
    $report = [ordered]@{ browser = $browserVersion; mode = 'headless, perfil temporal, CDP';
        nameResolution = $(if ($UseSystemResolution) { 'Windows, sin reglas temporales' } else { 'Reglas temporales de Chrome' });
        cookies = $cookieEvidence.ToArray(); network = $networkEvidence }
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $projectRoot 'docs/evidencias/browser-fase-08.json') -Encoding utf8
    Write-Output "PASS Chrome Network: 200/201/404/502 observados; informe sin valores de cookies; navegador $browserVersion"
}
finally {
    if ($script:socket) {
        try { $null = Send-Cdp 'Browser.close' } catch { }
        $script:socket.Dispose()
    }
    if ($chromeProcess) {
        if (-not $chromeProcess.WaitForExit(5000)) { Stop-Process -Id $chromeProcess.Id -Force -ErrorAction SilentlyContinue }
    }
    # Borrar sólo el perfil temporal que creó este script, tras comprobar su ruta.
    $resolvedProfile = [IO.Path]::GetFullPath($profilePath)
    $tempPrefix = $tempRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedProfile.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($resolvedProfile) -notmatch '^infra-http-browser-[0-9a-f]{32}$') { throw 'Ruta de perfil temporal fuera del ámbito permitido' }
    if (Test-Path -LiteralPath $resolvedProfile) { Remove-Item -LiteralPath $resolvedProfile -Recurse -Force }
}
