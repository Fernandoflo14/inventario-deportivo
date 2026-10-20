param([string]$BaseUrl = 'http://localhost:8080')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force -Path evidencias | Out-Null
$results = [System.Collections.Generic.List[object]]::new()
function Check($Name, $Method, $Path, $Expected, $Body = $null, $Headers = @{}) {
    # Invoke-WebRequest compatible con Windows PowerShell 5.1 y PowerShell 7.
    $argsRequest = @{ Uri = "$BaseUrl$Path"; Method = $Method; Headers = $Headers; UseBasicParsing = $true }
    if ($null -ne $Body) {
        $argsRequest.ContentType = 'application/json'
        $argsRequest.Body = $Body | ConvertTo-Json -Depth 8 -Compress
    }
    $status = 0; $content = ''; $responseHeaders = @{}
    try {
        $r = Invoke-WebRequest @argsRequest
        $status = [int]$r.StatusCode; $content = $r.Content; $responseHeaders = $r.Headers
    } catch {
        if ($null -eq $_.Exception.Response) { throw }
        $status = [int]$_.Exception.Response.StatusCode
        $content = $_.ErrorDetails.Message
    }
    $pass = $status -eq $Expected
    $results.Add([pscustomobject]@{ name=$Name; method=$Method; path=$Path; expected=$Expected; actual=$status; passed=$pass; body=$content; timestamp=(Get-Date).ToUniversalTime().ToString('o') })
    Write-Host "$Name : esperado $Expected / recibido $status" -ForegroundColor $(if ($pass) {'Green'} else {'Red'})
    if (-not $pass) { throw "Fallo en $Name. $content" }
    # Separar peticiones normales del caso de saturacion.
    Start-Sleep -Milliseconds 150
    return [pscustomobject]@{ Content=$content; Headers=$responseHeaders }
}
try {
    $null = Check 'Salud de API y BD' GET /health 200
    $null = Check 'Swagger por Gateway' GET /swagger/index.html 200
    $null = Check 'Documento OpenAPI' GET /swagger/v1/swagger.json 200
    $unique = [Guid]::NewGuid().ToString('N').Substring(0,10)
    $cat = (Check 'Crear categoria' POST /api/categories 201 @{name="Prueba-$unique"}).Content | ConvertFrom-Json
    $null = Check 'Listar categorias' GET /api/categories 200
    $null = Check 'Consultar categoria' GET "/api/categories/$($cat.id)" 200
    $null = Check 'Editar categoria' PUT "/api/categories/$($cat.id)" 204 @{name="Material-$unique"}
    $productBody = @{name='Balon de entrenamiento';sku="BAL-$unique";price=75.50;stock=12;categoryId=$cat.id}
    $prod = (Check 'Crear producto' POST /api/products 201 $productBody).Content | ConvertFrom-Json
    $null = Check 'Listar productos' GET /api/products 200
    $null = Check 'Consultar producto' GET "/api/products/$($prod.id)" 200
    $null = Check 'Bloquear SKU duplicado' POST /api/products 409 $productBody
    $productBody.stock = -1
    $null = Check 'Rechazar stock negativo' POST /api/products 400 $productBody
    $productBody.stock = 20
    $null = Check 'Editar producto' PUT "/api/products/$($prod.id)" 204 $productBody
    $updated = (Check 'Comprobar actualizacion' GET "/api/products/$($prod.id)" 200).Content | ConvertFrom-Json
    if ($updated.stock -ne 20) { throw 'PUT no persistio el stock esperado.' }
    $null = Check 'Bloquear categoria con productos' DELETE "/api/categories/$($cat.id)" 409
    $cors = Check 'Preflight CORS' OPTIONS /api/products 204 $null @{Origin='http://localhost:5173';'Access-Control-Request-Method'='POST'}
    if ($cors.Headers['Access-Control-Allow-Origin'] -ne 'http://localhost:5173') { throw 'Falta cabecera CORS.' }
    $r = Check 'Identificador de peticion' GET /api/products 200
    if (-not $r.Headers['X-Request-ID']) { throw 'Falta X-Request-ID.' }
    docker compose restart backend
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo reiniciar el backend para probar persistencia.' }
    $ready = $false
    for ($i=0; $i -lt 40; $i++) {
        try {
            $state = Invoke-RestMethod "$BaseUrl/health"
            if ($state.status -eq 'healthy') { $ready = $true; break }
        } catch { }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) { throw 'Backend no recupero salud despues de reiniciar.' }
    $persisted = (Check 'Persistencia tras reinicio' GET "/api/products/$($prod.id)" 200).Content | ConvertFrom-Json
    if ($persisted.stock -ne 20) { throw 'La lectura tras reinicio no coincide.' }
    $null = Check 'Eliminar producto' DELETE "/api/products/$($prod.id)" 204
    $null = Check 'Producto eliminado' GET "/api/products/$($prod.id)" 404
    $null = Check 'Eliminar categoria' DELETE "/api/categories/$($cat.id)" 204
    $null = Check 'Categoria eliminada' GET "/api/categories/$($cat.id)" 404
    # Saturacion concurrente con HttpClient, sin depender de PowerShell 7.
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object System.Net.Http.HttpClient
    try {
        $tasks = @(); for ($i=0; $i -lt 100; $i++) { $tasks += $client.GetAsync("$BaseUrl/api/products") }
        $limited = 0
        foreach ($task in $tasks) { $response = $task.GetAwaiter().GetResult(); if ([int]$response.StatusCode -eq 429) { $limited++ }; $response.Dispose() }
        $results.Add([pscustomobject]@{name='Rate limiting concurrente';expected='Al menos un 429';actual=$limited;passed=($limited -gt 0);timestamp=(Get-Date).ToUniversalTime().ToString('o')})
        if ($limited -eq 0) { throw 'No se observo limitacion 429; revisar configuracion.' }
    } finally { $client.Dispose() }
    Write-Host 'Pruebas completadas. Abra Swagger y tome capturas para el informe.' -ForegroundColor Green
} finally {
    $results | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 evidencias/resultados.json
    docker compose ps --all | Out-File -Encoding utf8 evidencias/contenedores.txt
    docker compose logs --no-color --tail 300 | Out-File -Encoding utf8 evidencias/docker-logs.txt
    git log --graph --all --oneline | Out-File -Encoding utf8 evidencias/git-historial.txt
}
