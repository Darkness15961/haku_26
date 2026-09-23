# Preflight de Rutas en el VPS

**Objetivo:** obtener el estado real desplegado antes de crear la primera
migración incremental del MVP de Rutas.

El historial local contiene varias migraciones remotas que cambiaron la vista,
los permisos y el contador de paradas en momentos distintos. Por eso no se debe
suponer que el VPS coincide exactamente con el último archivo del repositorio.

## Garantía de seguridad

[`preflight_rutas_vps.sql`](../supabase/diagnostics/preflight_rutas_vps.sql) es
de **solo lectura**. Consulta los catálogos de PostgreSQL y devuelve una única
celda JSON. No contiene `CREATE`, `ALTER`, `DROP`, `INSERT`, `UPDATE`, `DELETE`,
`GRANT`, `REVOKE` ni llamadas a funciones de negocio.

No se debe ejecutar todavía ninguna migración nueva.

## Cómo ejecutarlo

1. Abrir Supabase Studio del VPS.
2. Entrar a **SQL Editor** con el rol propietario de la base de datos o un rol
   que pueda consultar los catálogos de PostgreSQL.
3. Abrir y copiar completo el archivo
   `supabase/diagnostics/preflight_rutas_vps.sql`.
4. Ejecutar todo el archivo una sola vez.
5. El resultado tendrá una columna llamada `diagnostico_rutas` y una fila.
6. Descargar el resultado como CSV/JSON o copiar el contenido completo de esa
   celda. Si Studio lo recorta visualmente, usar la opción de descarga.
7. Guardar el resultado fuera de `supabase/migrations/` y entregarlo para la
   comparación. Puede adjuntarse como archivo; no hace falta pegarlo en varios
   mensajes.

## Qué recopila

- versión de PostgreSQL y extensiones relevantes, incluido PostGIS;
- existencia y tipo de las tablas/vistas relacionadas con Rutas;
- columnas, valores predeterminados y tipos geográficos;
- constraints, claves foráneas e índices;
- claves foráneas que aparentemente carecen de índice;
- triggers y funciones relacionadas con Rutas;
- RLS, policies y permisos de `anon`, `authenticated` y `service_role`;
- definición y opciones de la vista pública;
- conteos aproximados, sin leer el contenido personal de las filas.

## Resultado necesario para continuar

La fase 1 comenzará cuando esté disponible el JSON completo. Con él se podrá
preparar una **migración nueva** que:

- parta del estado real del VPS;
- no modifique ningún archivo histórico;
- aplique propiedad, publicación directa y valoraciones sin abrir permisos
  accidentales;
- incluya precondiciones y verificaciones posteriores al despliegue.

Si la consulta devuelve un error, enviar el mensaje exacto y la línea señalada.
No corregir directamente objetos del VPS para hacer que el diagnóstico pase.
