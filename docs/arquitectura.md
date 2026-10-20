# Diagramas C4

## Nivel 1 - Contexto
```mermaid
flowchart TD
  admin["Administrador del club (persona)"]
  sistema["Sistema de inventario deportivo (sistema de software)"]
  admin -->|"Gestiona categorías y productos por HTTP/JSON"| sistema
```
El alcance no requiere otros sistemas externos.

## Nivel 2 - Contenedores
```mermaid
flowchart TD
  admin["Administrador del club (persona)"]
  subgraph sistema["Sistema de inventario deportivo"]
    gateway["API Gateway (NGINX): CORS, logs y límites"]
    backend["API de inventario (ASP.NET Core 8): CRUD REST"]
    db[("Base de datos (PostgreSQL 16): catálogo persistente")]
    gateway -->|"HTTP/JSON :8080"| backend
    backend -->|"SQL/TCP :5432"| db
  end
  admin -->|"HTTP :8080 / Swagger y REST"| gateway
```
Únicamente el Gateway publica puerto al host. Backend y BD usan nombres DNS de Compose en la red bridge. Un volumen nombrado conserva los datos PostgreSQL. La interfaz Swagger forma parte del backend; no es un cuarto contenedor.
