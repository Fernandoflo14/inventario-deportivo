$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (-not (Test-Path .env)) {
    $localPassword = [Guid]::NewGuid().ToString('N')
    Set-Content -LiteralPath .env -Value "DB_PASSWORD=$localPassword" -Encoding ascii
}
docker info --format '{{.ServerVersion}}'
if ($LASTEXITCODE -ne 0) { throw 'Docker no responde. Abra Docker Desktop y ejecute este script en su PowerShell.' }
docker compose config --quiet
if ($LASTEXITCODE -ne 0) { throw 'La configuracion Compose es invalida.' }
docker compose up -d --build --wait --wait-timeout 300
if ($LASTEXITCODE -ne 0) {
    docker compose logs --tail 100
    throw 'No arrancaron todos los servicios. Envie la salida para revisar el error.'
}
Write-Host 'Sistema disponible: http://localhost:8080/swagger' -ForegroundColor Green
& "$PSScriptRoot/probar.ps1"
