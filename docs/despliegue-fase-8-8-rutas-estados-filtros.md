# Fase 8.8 - Rutas: estados de usuario y filtros

## Decisiones de producto

- `Borrador`: privado, editable, publicable y eliminable.
- `Publicada`: visible en Explora, editable y desactivable.
- `Archivada`: valor interno existente. En UI se muestra como `Desactivada`.
- `Desactivada`: oculta al publico, restaurable a borrador o eliminable.

No se cambia el valor de base de datos `archivado` para evitar romper datos y
funciones existentes.

## Cambios de base de datos

Nueva migracion:

```text
supabase/migrations/20260923165116_fase_8_8_rutas_estados_filtros_usuario.sql
```

Agrega:

- `public.publicar_ruta_propia(bigint)`
- `public.restaurar_ruta_propia(bigint)`
- `public.eliminar_ruta_propia(bigint)`
- policy `ruta_delete_propietario` limitada a `borrador` y `archivado`
- grant `DELETE` sobre `public.ruta` para `authenticated`

`eliminar_ruta_propia` no elimina Rutas publicadas. Si una Ruta esta enlazada a
publicaciones o salidas, la base la bloquea y se debe mantener desactivada.

## Cambios de UI

- Mis Rutas ahora muestra `Borradores`, `Publicadas` y `Desactivadas`.
- Borrador: editar, publicar, eliminar.
- Publicada: ver, editar, desactivar.
- Desactivada: restaurar, editar, eliminar.
- Explora Rutas cambia tabs fijos por filtros combinables:
  `Enfoque`, `Tipo`, `Nivel` y `Zona`.

## Aplicacion

```bash
supabase db push
```

Despues reiniciar la app Flutter para tomar los nuevos RPCs y textos.

## Verificacion rapida en Supabase

Si al restaurar/publicar/eliminar aparece `schema cache`, ejecuta:

```text
supabase/diagnostics/rutas_estados_filtros_8_8_check.sql
```

Debe devolver las tres funciones nuevas con `authenticated_execute = true`.
Si no aparecen, la migracion 8.8 no esta aplicada en el remoto. Si aparecen,
la ultima consulta solicita `reload schema` a PostgREST.
