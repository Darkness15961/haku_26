# Fase 3 de Rutas - Mis Rutas y edicion

## Alcance implementado

- Listado de Rutas propias separadas por borrador, publicadas y archivadas.
- Edicion de ficha y paradas por el propietario.
- Reordenamiento, agregado y retiro de paradas desde Lugares activos.
- Archivado por el propietario.
- Escrituras atomicas mediante RPC para evitar filas parciales.

## Limitacion del MVP

La edicion de una Ruta publicada actualiza la ficha vigente. No se guarda un
historial de revisiones paralelo ni una version navegable anterior.

Si una Salida o Publicacion ya apunta a esa Ruta, seguira apuntando al mismo
`ruta.id` y por tanto vera la version actual. Un historial completo debe quedar
para una fase posterior con una tabla de revisiones y reglas explicitas de
lectura.

## Despliegue requerido

La Fase 3 agrega la migracion:

`supabase/migrations/20260923023142_fase_3_mis_rutas_edicion_propietario.sql`

Debe aplicarse en el VPS antes de usar Mis Rutas y la edicion en Flutter.
