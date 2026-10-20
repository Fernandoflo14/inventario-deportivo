# Inventario deportivo - API Gateway y microservicio

**Autor:** Andrés Fernando Zuxo Condori. **Backend asignado:** C# .NET 8.

Sistema para administrar categorías y productos de un club deportivo. El Gateway NGINX expone HTTP y Swagger; ASP.NET Core implementa el negocio y PostgreSQL conserva los datos.

## Requisitos y arranque
Docker Desktop iniciado en modo Linux, Docker Compose v2 o posterior y Git. No requiere SDK .NET ni PostgreSQL instalados en el host. Se requiere Internet durante el primer build.

Clone el repositorio desde el botón **Code > HTTPS** de su página pública y entre a la carpeta clonada. Para la copia local actual:

```powershell
Set-Location 'C:\Users\ROGSTRIX G18\Documents\Codex\2026-10-19\te-voy-a-pasar-un-trabajo\inventario-deportivo'
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\iniciar.ps1
```

El script crea `.env` con una clave aleatoria si no existe, valida Compose, construye los servicios, espera su salud y ejecuta pruebas. Con Bash o para ejecución manual:

```bash
cp .env.example .env
# Edite DB_PASSWORD en .env antes de arrancar.
docker compose up -d --build --wait
```

La forma `docker compose up` también arranca los tres servicios; el README utiliza el plugin moderno Compose, equivalente a `docker-compose up` en instalaciones antiguas.

- Swagger: http://localhost:8080/swagger
- OpenAPI: http://localhost:8080/swagger/v1/swagger.json
- Salud (comprueba conexión a BD): http://localhost:8080/health

Solo Gateway publica el puerto 8080. Backend y base de datos no publican puertos al host.

## Arquitectura y patrones
Los diagramas C4 de Contexto y Contenedores están en [docs/arquitectura.md](docs/arquitectura.md).

| Componente | Responsabilidad | Archivos |
|---|---|---|
| Gateway NGINX | Proxy inverso, CORS, logs JSON y límite por IP | `gateway/nginx.conf` |
| API ASP.NET Core 8 | Controladores REST y reglas de negocio | `backend/Controllers/` |
| DTO | Contratos separados de entidades y validaciones | `backend/Contracts/` |
| Repository | Abstracción del acceso a datos | `backend/Repositories/` |
| DI | Registro scoped por solicitud en contenedor de servicios | `backend/Program.cs` |
| EF Core + PostgreSQL 16 | Relaciones, índices únicos y persistencia | `backend/Data/` |

`IRepository<T>` ofrece operaciones comunes; `IProductRepository` agrega lectura con categoría. `InventoryDb` y los repositorios comparten el alcance de la solicitud. Las respuestas usan DTO para evitar exponer las entidades y sus referencias circulares.

## Reglas del dominio
- Nombre obligatorio; SKU alfanumérico con guiones, normalizado a mayúsculas y único.
- Precio entre 0 y 9999999.99 Bs; se almacena con dos decimales.
- Stock entero entre 0 y 1000000.
- Todo producto pertenece a una categoría existente.
- No se elimina una categoría que tenga productos: respuesta 409.
- Nombre de categoría único, sensible a mayúsculas conforme a PostgreSQL.
- Los listados devuelven un máximo de 1000 registros ordenados por ID.

## Endpoints
Todas las URLs usan la base `http://localhost:8080`.

| Método | URL | Cuerpo | Respuesta exitosa |
|---|---|---|---|
| GET | `/api/categories` | ninguno | 200, arreglo CategoryResponse |
| GET | `/api/categories/{id}` | ninguno | 200, CategoryResponse |
| POST | `/api/categories` | CategoryRequest | 201, CategoryResponse y Location |
| PUT | `/api/categories/{id}` | CategoryRequest | 204 |
| DELETE | `/api/categories/{id}` | ninguno | 204 |
| GET | `/api/products` | ninguno | 200, arreglo ProductResponse |
| GET | `/api/products/{id}` | ninguno | 200, ProductResponse |
| POST | `/api/products` | ProductRequest | 201, ProductResponse y Location |
| PUT | `/api/products/{id}` | ProductRequest | 204 |
| DELETE | `/api/products/{id}` | ninguno | 204 |

CategoryRequest: `{"name":"Balones"}`

CategoryResponse: `{"id":1,"name":"Balones"}`

ProductRequest:
```json
{"name":"Balón de fútbol","sku":"BAL-001","price":75.50,"stock":12,"categoryId":1}
```
ProductResponse:
```json
{"id":1,"name":"Balón de fútbol","sku":"BAL-001","price":75.50,"stock":12,"categoryId":1,"categoryName":"Balones"}
```

Los IDs anteriores son ejemplos: utilice los devueltos por cada POST. PUT reemplaza los campos editables completos. Errores: 400 por datos inválidos o categoría inexistente; 404 por recurso inexistente; 409 por duplicados o conflicto referencial; 429 por exceso de tráfico. Las validaciones de ASP.NET Core usan ValidationProblemDetails; los conflictos devuelven `error` y `requestId`.

## Pruebas con cURL, Swagger y Postman
Abra Swagger, expanda cada endpoint y use **Try it out**. En Postman puede importar la URL OpenAPI indicada arriba; use Body > raw > JSON.

Ejemplos para Bash (en PowerShell use Swagger o el script de pruebas para evitar diferencias de comillas de curl.exe):

```bash
curl -i http://localhost:8080/health
curl -i -H 'Content-Type: application/json' -d '{"name":"Balones"}' http://localhost:8080/api/categories
curl -i http://localhost:8080/api/categories
curl -i -H 'Content-Type: application/json' -d '{"name":"Balon","sku":"BAL-001","price":75.50,"stock":12,"categoryId":1}' http://localhost:8080/api/products
curl -i http://localhost:8080/api/products/1
curl -i -X PUT -H 'Content-Type: application/json' -d '{"name":"Balon","sku":"BAL-001","price":80,"stock":20,"categoryId":1}' http://localhost:8080/api/products/1
curl -i -X DELETE http://localhost:8080/api/products/1
curl -i -X DELETE http://localhost:8080/api/categories/1
curl -i -X OPTIONS -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: POST' http://localhost:8080/api/products
```

Para repetir la batería completa desde PowerShell:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\probar.ps1
```

El script comprueba CRUD de ambas entidades, SKU duplicado, stock negativo, categoría ocupada, CORS, request ID, persistencia tras reiniciar backend y saturación 429. Guarda salidas reales en `evidencias/`. **No se afirma que las pruebas pasaron hasta revisar esa ejecución.** Los datos de prueba usan identificadores únicos y se eliminan al terminar correctamente; si hay un fallo, podrían quedar para diagnóstico.

## Funciones transversales del Gateway
- CORS: permite orígenes localhost:8080, 127.0.0.1:8080 y localhost:5173; OPTIONS responde 204. No habilita credenciales ni orígenes arbitrarios.
- Logging: stdout JSON con fecha, método, URI, estado, tiempo, upstream y requestId. El Gateway asigna el ID, lo envía al backend y lo devuelve al cliente.
- Rate limiting: 10 solicitudes/s por IP con ráfaga de 30. El exceso responde 429. No se implementa autenticación: la rúbrica exige al menos dos funciones y se incluyen estas tres.

## Operación y persistencia
```bash
docker compose ps
docker compose logs --tail 100 gateway backend db
docker compose down
docker compose up -d --wait
```
`down` conserva el volumen nombrado. `down -v` elimina datos y no forma parte del flujo normal. Cambiar `.env` después de crear el volumen no cambia automáticamente la contraseña ya almacenada en PostgreSQL.

El esquema se crea al primer arranque mediante `EnsureCreatedAsync`, apropiado para esta versión inicial. Cambios futuros de esquema requieren migraciones: este proyecto no mezcla EnsureCreated con EF Migrations.

## Git Flow y publicación
`main` contiene la base del proyecto; `develop` integra el trabajo y las ramas `feature/backend-crud`, `feature/gateway-docker` y `feature/documentacion` conservan avances reales. **La release se finalizará después de la prueba real**, con rama `release/1.0.0`, merge a main, tag `v1.0.0` y retorno a develop.

No use solo “Upload files” de GitHub: eso perdería el grafo local. Cree en GitHub un repositorio **público vacío**, sin README, licencia ni .gitignore iniciales. Luego, usando la URL real que GitHub muestre:
```powershell
git remote add origin URL_HTTPS_REAL_DEL_REPOSITORIO
git push -u origin main
git push -u origin develop
git push origin --all
git push origin --tags
```
La URL anterior es un marcador de instrucción que debe sustituirse. La autenticación de GitHub se realiza en su equipo; no incluya tokens en archivos ni mensajes.

## Entrega Moodle
Subir enlace público al repositorio e informe PDF de 5 a 8 páginas con descripción del negocio, C4 niveles 1 y 2, endpoints y capturas reales de Swagger y Docker. La matriz de revisión se encuentra en [docs/rubrica.md](docs/rubrica.md).

## Referencias técnicas
- ASP.NET Core 8 y puerto de contenedores: https://learn.microsoft.com/en-us/dotnet/core/compatibility/containers/8.0/aspnet-port
- Proxy NGINX: https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- Límites NGINX: https://nginx.org/en/docs/http/ngx_http_limit_req_module.html
- Proveedor PostgreSQL EF Core: https://www.nuget.org/packages/Npgsql.EntityFrameworkCore.PostgreSQL/8.0.10

## Estado actual
Código y documentación preparados. Pendientes: compilar/ejecutar en Docker, revisar pruebas, obtener capturas, cerrar release, generar PDF final, publicar repositorio y entregar en Moodle. No se incluyen resultados simulados ni se garantiza una calificación sin evaluar la ejecución.
