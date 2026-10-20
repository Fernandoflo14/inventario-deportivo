# Verificación funcional de la versión 1.0.0

La ejecución realizada por el autor el 19 de octubre de 2026 en Windows PowerShell completó 24 comprobaciones con resultado satisfactorio, según `evidencias/resultados.json`. Los servicios se construyeron con Docker Compose y el backend compiló para net8.0.

| Grupo | Evidencia observada |
|---|---|
| Salud y documentación | /health, Swagger y OpenAPI respondieron 200 |
| Categorías | Crear 201; listar/consultar 200; editar/eliminar 204; consulta posterior 404 |
| Productos | Crear 201; listar/consultar 200; editar/eliminar 204; consulta posterior 404 |
| Validaciones | Categoría vacía y stock negativo respondieron 400 |
| Integridad | SKU duplicado y categoría con productos respondieron 409 |
| CORS | Preflight 204 con origen autorizado comprobado |
| Trazabilidad | Cabecera X-Request-ID presente |
| Persistencia | Producto consultado después de reiniciar backend conservó stock 20 |
| Rate limiting | 68 respuestas 429 en una ráfaga de 100 solicitudes concurrentes |

La captura de arranque enviada por el autor muestra los tres servicios saludables. El estado guardado al terminar las pruebas muestra backend `health: starting`, porque se reinició durante la prueba de persistencia; la consulta de salud posterior ya había respondido 200. Para el PDF se debe capturar un `docker compose ps` actualizado después de completar el intervalo del healthcheck.

## Límites de esta verificación
- La prueba de persistencia reinicia backend; no elimina ni recrea PostgreSQL ni su volumen.
- La compilación mostró una advertencia CS9107 sobre la captura de DbContext en el repositorio derivado. No impidió compilar ni ejecutar las pruebas.
- Se incorporaron las capturas originales de Swagger (201, categoría ID 4) y Docker al PDF de siete páginas. Faltan verificación de la publicación remota y entrega Moodle.
- Esta verificación documenta resultados observados; no representa una calificación asignada por el docente.
