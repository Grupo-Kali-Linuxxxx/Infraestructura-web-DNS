$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force docs/evidencias | Out-Null
$results = [System.Collections.Generic.List[object]]::new()
function Request($site, $path, $method='GET', $jar='') {
    $argsCurl = @('--silent','--show-error','--noproxy','*','--resolve',"${site}:8080:127.0.0.1",'-X',$method,'-w',"`n%{http_code}")
    if ($jar) { $argsCurl += @('-b',$jar,'-c',$jar) }
    $raw = & curl.exe @argsCurl "http://${site}:8080$path"
    if ($LASTEXITCODE) { throw "curl falló: $site $path" }
    $lines = $raw -join "`n"
    $split = $lines.LastIndexOf("`n")
    return @{status=[int]$lines.Substring($split+1);body=$lines.Substring(0,$split)}
}
function Check($name,$ok) {
    $results.Add(@{prueba=$name;resultado=$(if($ok){'PASS'}else{'FAIL'})})
    if (!$ok) {throw "FAIL: $name"}
    Write-Host "PASS: $name"
}
try {
  foreach($n in 1,2) {
    $site="sitio$n.local"; $jar=Join-Path ([IO.Path]::GetTempPath()) "web-lab-$n.cookies"
    try {
      $r=Request $site '/health'; Check "$site health" ($r.status -eq 200 -and $r.body.Contains("App $n"))
      $r=Request $site '/no-existe'; Check "$site 404 personalizado" ($r.status -eq 404 -and $r.body.Contains('Recurso no encontrado'))
      foreach($code in 500,502) {
        $r=Request $site "/pruebas/$code"; Check "$site $code personalizado" ($r.status -eq $code -and $r.body.Contains('Servicio temporalmente no disponible'))
      }
      $r=Request $site '/api/sesion' 'GET' $jar; Check "$site sin sesión" (!(($r.body | ConvertFrom-Json).activa))
      $r=Request $site '/api/sesion' 'POST' $jar; Check "$site crear" ($r.status -eq 201)
      $r=Request $site '/api/sesion/incrementar' 'POST' $jar; Check "$site incrementar" (($r.body | ConvertFrom-Json).contador -eq 1)
      $r=Request $site '/api/sesion' 'GET' $jar; Check "$site persistencia" (($r.body | ConvertFrom-Json).contador -eq 1)
      $r=Request $site '/api/sesion' 'DELETE' $jar; Check "$site destruir" (!(($r.body | ConvertFrom-Json).activa))
      $r=Request $site '/api/sesion/incrementar' 'POST' $jar; Check "$site rechaza sesión inexistente" ($r.status -eq 409)
    } finally { if(Test-Path $jar){Remove-Item -LiteralPath $jar} }
  }
} finally {
  $results | ConvertTo-Json | Set-Content -Encoding utf8 docs/evidencias/pruebas-http.json
}
