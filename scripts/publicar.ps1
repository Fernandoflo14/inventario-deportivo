param([string]$RepositoryUrl = 'https://github.com/Fernandoflo14/inventario-deportivo.git')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$pending = git status --porcelain
if ($LASTEXITCODE -ne 0 -or $pending) { throw 'Hay cambios pendientes o el repositorio no responde. Revisar antes de publicar.' }
$currentRemote = git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    git remote add origin $RepositoryUrl
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo agregar origin.' }
} elseif ($currentRemote -ne $RepositoryUrl) {
    throw "Origin apunta a otro repositorio: $currentRemote. No se modifico."
}
git push -u origin main
if ($LASTEXITCODE -ne 0) { throw 'Fallo publicacion de main. Revise URL y autenticacion GitHub. No se forzo ningun cambio.' }
git push -u origin develop
if ($LASTEXITCODE -ne 0) { throw 'Fallo publicacion de develop.' }
git push origin --all
if ($LASTEXITCODE -ne 0) { throw 'Fallo publicacion de ramas.' }
git push origin --tags
if ($LASTEXITCODE -ne 0) { throw 'Fallo publicacion de etiquetas.' }
git ls-remote --heads --tags origin
if ($LASTEXITCODE -ne 0) { throw 'No se pudo verificar las referencias remotas.' }
Write-Host 'Publicacion completada. Revise en GitHub que main muestre codigo, README e informe PDF.' -ForegroundColor Green
