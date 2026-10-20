# Inventario deportivo

Autor: Andrés Fernando Zuxo Condori.
Tecnología asignada: C# .NET 8.

## Problema
Un club deportivo necesita conocer las existencias, categorías y precios de sus materiales. Los registros dispersos dificultan identificar faltantes y mantener un catálogo consistente.

## Alcance
CRUD REST de categorías y productos. Cada producto tiene nombre, SKU único, precio en Bs, existencias y categoría. No se permiten precios ni existencias negativos, SKU duplicados, categorías inexistentes ni eliminar categorías con productos asociados. El Gateway es la única entrada HTTP publicada.

## Arquitectura
NGINX (Gateway) -> ASP.NET Core 8 (microservicio) -> PostgreSQL 16.
Gateway: CORS, logging JSON con identificador de petición y rate limiting.
Backend: controladores, DTO, repositorios e inyección de dependencias; EF Core con PostgreSQL.
Docker Compose: tres contenedores, red bridge, volumen persistente, healthchecks y dependencias condicionadas a salud.

## Criterios de aceptación
- Categorías y productos: POST 201, GET 200/404, PUT 204/400/404, DELETE 204/404/409.
- Validación: 400; duplicados o referencias bloqueadas: 409.
- Swagger accesible exclusivamente por Gateway.
- Datos conservados al recrear contenedores sin eliminar el volumen.
- Repositorio público con ramas feature, develop, release y main.
- README reproducible e informe de 5 a 8 páginas con C4 y pruebas reales.

## Estado de entrega
El código se prepara localmente. La ejecución Docker, capturas, publicación GitHub e informe final requieren verificación; no se consideran completados antes de ejecutarlos.
