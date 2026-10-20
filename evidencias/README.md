# Evidencias reales

La ejecución verificada completó 24 pruebas satisfactorias. Se incluyen resultados.json y docker-logs.txt; las capturas originales se encuentran en docs/capturas y dentro del informe PDF. Para reproducirlas, ejecute scripts/iniciar.ps1. El script guarda resultados JSON, estado Docker, logs y grafo Git. Una salida fallida NO es evidencia de cumplimiento.

Evidencias recomendadas para una demostración adicional:
1. Docker Desktop con los tres servicios saludables.
2. Swagger: POST de categoria y producto con 201 y JSON.
3. Swagger: GET y PUT, mostrando datos actualizados.
4. Swagger: DELETE 204 y GET posterior 404.
5. Logs de Gateway con metodo, estado, requestId y upstream.
6. Historial Git con ramas y merges.

Las capturas deben obtenerse de la ejecucion real. No se incluyen imagenes ni resultados simulados. Los archivos generados se excluyen de Git para evitar publicar datos accidentales; seleccione y revise las evidencias antes de incorporarlas al informe.
