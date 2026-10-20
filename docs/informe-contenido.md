# Inventario deportivo: arquitectura orientada a servicios

**Autor:** Andrés Fernando Zuxo Condori  
**Tecnología asignada:** C# / ASP.NET Core 8  
**Fecha:** 19 de octubre de 2026

## 1. Dominio y objetivo
El proyecto resuelve la administración de un catálogo de materiales deportivos. Un club necesita identificar los productos disponibles, sus existencias, precios y categorías. El registro manual dificulta evitar códigos duplicados, conocer cantidades y mantener consistentes las relaciones entre materiales y categorías.

El objetivo es construir una arquitectura orientada a servicios con un único punto de entrada HTTP. El API Gateway recibe las peticiones, aplica funciones transversales y las dirige al microservicio. El backend implementa las reglas del dominio y persiste los datos en PostgreSQL. Docker Compose permite reproducir el entorno con tres servicios.

El alcance comprende CRUD de categorías y productos. No incluye ventas, facturación, usuarios ni pagos. El precio es un atributo del catálogo expresado en bolivianos. Las existencias se editan como parte del producto; no se implementa un libro de movimientos de almacén.

## 2. Modelo de datos y reglas
Una categoría posee identificador y nombre único. Un producto posee identificador, nombre, SKU único, precio, stock y referencia obligatoria a una categoría. La relación es de una categoría a muchos productos.

Se rechazan nombres vacíos, SKU con caracteres no permitidos, precio negativo, stock negativo y categorías inexistentes. Los SKU se normalizan a mayúsculas. La base de datos refuerza la integridad con índices únicos, clave foránea y restricciones de valores no negativos. Se bloquea eliminar categorías asociadas a productos, evitando registros huérfanos.

Los DTO separan los contratos HTTP del modelo persistente. Los controladores validan solicitudes y coordinan las operaciones. Los repositorios encapsulan el acceso a datos; la inyección de dependencias entrega repositorios y DbContext por solicitud.

## 3. Modelo C4
Nivel 1: el administrador del club utiliza el sistema de inventario para gestionar el catálogo. No hay sistemas externos dentro del alcance.

Nivel 2: el administrador se comunica por HTTP con NGINX en el puerto público 8080. El Gateway enruta hacia ASP.NET Core 8 por HTTP interno en el puerto 8080. El backend accede a PostgreSQL 16 por SQL/TCP en el puerto 5432. Backend y base de datos no publican puertos al host. Los tres contenedores comparten una red bridge y la base utiliza un volumen nombrado.

Los diagramas fuente completos se mantienen en `docs/arquitectura.md` y se renderizarán como figuras dentro del PDF.

## 4. Gateway, patrones y despliegue
NGINX funciona como proxy inverso y único punto de entrada. Implementa CORS para orígenes locales autorizados, logs JSON centralizados y rate limiting de diez solicitudes por segundo por IP con ráfaga de treinta. Los logs incluyen método, URI, estado, duración, upstream e identificador de petición. El Gateway asigna X-Request-ID y lo propaga al backend.

El backend implementa Repository, DTO e inyección de dependencias. EF Core traduce el acceso a datos a PostgreSQL. En esta versión inicial el esquema se crea mediante EnsureCreatedAsync; cambios posteriores requieren un mecanismo de migraciones.

El Dockerfile del backend utiliza compilación multietapa, restaura dependencias antes de copiar el código y ejecuta el resultado con el usuario app. El Gateway utiliza una imagen Alpine. Compose espera la salud de PostgreSQL antes de arrancar el backend y la salud del backend antes de arrancar el Gateway. Cada componente tiene healthcheck y se utiliza una red bridge común.

## 5. Contratos REST
Base HTTP: `http://localhost:8080`.

Para cada recurso `categories` y `products` se exponen GET de colección, GET por ID, POST, PUT por ID y DELETE por ID. GET responde 200, POST responde 201 y cabecera Location, PUT y DELETE responden 204. Un recurso inexistente responde 404; los datos inválidos responden 400; los duplicados y conflictos referenciales responden 409; la saturación responde 429.

Solicitud de categoría: `{"name":"Equipamiento de entrenamiento"}`.

Solicitud de producto: `{"name":"Balón de fútbol","sku":"BAL-001","price":75.50,"stock":12,"categoryId":4}`. El ID 4 corresponde a la categoría observada en la captura del autor; en otra instalación debe utilizarse el ID devuelto al crear una categoría.

Respuesta de producto: identificador, nombre, SKU, precio, stock, categoryId y categoryName. Swagger expone las operaciones mediante el propio Gateway y el documento OpenAPI puede importarse en Postman.

## 6. Verificación y evidencias
La ejecución en Windows PowerShell completó 24 comprobaciones satisfactorias. Se verificaron salud, Swagger y OpenAPI; CRUD de ambos recursos; actualización efectiva de existencias; validaciones de nombre y stock; bloqueo de SKU duplicado y categoría ocupada; CORS e identificador de petición; persistencia después de reiniciar backend; y rate limiting.

La prueba de persistencia conservó stock 20 después del reinicio. En la ráfaga de 100 solicitudes concurrentes se observaron 68 respuestas 429. La captura de Swagger aportada por el autor muestra la creación de la categoría y Location con `/api/categories/4`. Otra captura registra el conflicto 409 al repetir un nombre existente. La captura de Docker muestra los tres servicios y logs de salud 200, incluidos registros JSON del Gateway.

Fuentes verificables: `scripts/probar.ps1`, `evidencias/resultados.json`, `evidencias/docker-logs.txt` y capturas originales. La prueba de persistencia reinicia backend; no constituye una prueba de recuperación de una base destruida.

## 7. Git Flow, reproducción y conclusiones
El desarrollo conserva ramas feature para backend, Gateway y documentación; integración mediante merges a develop; una rama de corrección para las validaciones; y una rama release/1.0.0 para preparar la entrega. El cierre incluirá merge a main y etiqueta v1.0.0. Los commits corresponden a cambios reales y se conservarán al publicar.

La ejecución se reproduce clonando el repositorio, creando .env y ejecutando Docker Compose. En Windows, `scripts/iniciar.ps1` automatiza la configuración local, construcción, arranque y pruebas. `docker compose down` conserva los datos del volumen; eliminar el volumen los destruye.

Los resultados observados respaldan el funcionamiento del CRUD, las reglas de integridad y las funciones transversales del Gateway. La solución cumple la separación entre entrada HTTP, lógica y persistencia. Las limitaciones del alcance son ausencia de autenticación, migraciones evolutivas y registro de movimientos de inventario; no se incluyen como requisitos del caso seleccionado.

## Referencias
- Microsoft Learn: contenedores ASP.NET Core 8 y puerto 8080. https://learn.microsoft.com/en-us/dotnet/core/compatibility/containers/8.0/aspnet-port
- NGINX: módulo proxy HTTP. https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- NGINX: límite de solicitudes. https://nginx.org/en/docs/http/ngx_http_limit_req_module.html
