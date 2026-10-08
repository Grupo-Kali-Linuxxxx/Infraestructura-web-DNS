param(
    [ValidateSet('brian', 'charles', 'ketfer', 'marco', 'adaniel')]
    [string]$Usuario = 'adaniel'
)

# nobody no tiene privilegios para omitir la autenticación de su.
& docker exec -it --user nobody ubuntu-server su - $Usuario
if ($LASTEXITCODE -ne 0) {
    Write-Error 'No se pudo iniciar sesión. Comprueba la contraseña y que Ubuntu esté activo.'
    exit $LASTEXITCODE
}
