$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Linux($Command) {
    $result = & docker compose exec -T ubuntu-server sh -c $Command
    if ($LASTEXITCODE -ne 0) { throw "Falló la comprobación Linux: $Command" }
    return ($result -join "`n").Trim()
}

if ((Linux 'ps -p 1 -o comm=') -ne 'systemd') { throw 'PID 1 no es systemd' }
Write-Host 'PASS: systemd como PID 1'

foreach ($user in 'brian','charles','ketfer','marco','adaniel') {
    $groups = Linux "id -nG $user"
    if ('administradores' -notin ($groups -split ' ')) { throw "Grupo incorrecto: $user" }
    Write-Host "PASS: usuario $user en administradores"
}

Linux 'dpkg-query -W sudo curl nano vim iputils-ping net-tools iproute2 procps systemd openssh-server' | Out-Null
Write-Host 'PASS: paquetes Linux instalados'

$noPassword = & docker compose exec -T --user ketfer ubuntu-server sudo -n -k id -u 2>$null
if ($LASTEXITCODE -eq 0) { throw 'sudo permitió administrar sin contraseña' }
Write-Host 'PASS: sudo exige contraseña'

$sudoUser = & docker compose exec -T --user ketfer ubuntu-server sh -c "printf '%s\n' 'admin123' | sudo -S -k id -u"
if ($LASTEXITCODE -ne 0 -or "$sudoUser".Trim() -ne '0') { throw 'sudo de ketfer no funciona' }
Write-Host 'PASS: administración con sudo y contraseña como ketfer'

$invalidLogin = & docker compose exec -T --user nobody ubuntu-server sh -c "printf '%s\n' 'incorrecta' | su - adaniel -c whoami" 2>$null
if ($LASTEXITCODE -eq 0) { throw 'su aceptó una contraseña incorrecta' }
Write-Host 'PASS: su rechaza una contraseña incorrecta'

$initialLogin = & docker compose exec -T --user nobody ubuntu-server sh -c "printf '%s\n' 'admin123' | su - adaniel -c whoami"
if ($LASTEXITCODE -ne 0 -or "$initialLogin".Trim() -ne 'adaniel') {
    throw 'Falló la entrada con contraseña desde nobody'
}
Write-Host 'PASS: entrada con contraseña desde nobody'

# Probar el cambio desde una cuenta normal usando la contraseña del compañero.
$loginUser = & docker compose exec -T --user brian ubuntu-server sh -c "printf '%s\n' 'admin123' | su - adaniel -c whoami"
if ($LASTEXITCODE -ne 0 -or "$loginUser".Trim() -ne 'adaniel') {
    throw 'No se pudo cambiar de brian a adaniel con la contraseña configurada'
}
Write-Host 'PASS: cambio de usuario con contraseña mediante su'

# Restaurar el servicio incluso si una comprobación de parada falla.
try {
    Linux 'systemctl stop lab-demo.service' | Out-Null
    if ((Linux 'systemctl show lab-demo.service -p ActiveState --value') -ne 'inactive') {
        throw 'El servicio no se detuvo'
    }
    Write-Host 'PASS: systemctl stop'
    Linux 'systemctl start lab-demo.service' | Out-Null
    if ((Linux 'systemctl is-active lab-demo.service') -ne 'active') { throw 'El servicio no arrancó' }
    Write-Host 'PASS: systemctl start'
    Linux 'systemctl restart lab-demo.service' | Out-Null
    if ((Linux 'systemctl is-active lab-demo.service') -ne 'active') { throw 'El servicio no reinició' }
    Write-Host 'PASS: systemctl restart'
} finally {
    Linux 'systemctl start lab-demo.service' | Out-Null
}

Linux 'getent hosts app1 app2 nginx' | Out-Null
Linux 'curl --fail --silent http://app1:3000/health' | Out-Null
Linux 'curl --fail --silent http://app2:3000/health' | Out-Null
Write-Host 'PASS: red Docker y acceso a ambos backends desde Ubuntu'
