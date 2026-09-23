# Despliegue de la Fase 1 de Rutas

## Archivo que se despliega

La única migración nueva de esta fase es:

`supabase/migrations/20260922192604_fase_1_rutas_propiedad_valoraciones.sql`

No se modificó, renombró ni eliminó ninguna migración anterior. Tampoco se
necesita desplegar una Edge Function en esta fase.

El archivo `supabase/tests/rutas_fase_1_rls_test.sql` es una prueba pgTAP; no
forma parte del historial que aplica `db push`.

## Qué cambia

- Reutiliza `ruta` como ficha principal.
- Reutiliza `ruta_parada` para el orden de los Lugares.
- Reutiliza `ruta_guardada`, `publicacion_ruta` y `salida.ruta_id`.
- Crea únicamente la tabla nueva `ruta_valoracion`.
- Añade a `ruta` los resúmenes derivados `valoracion_promedio` y
  `cantidad_valoraciones` para evitar una consulta por cada tarjeta.
- Añade el esquema no expuesto `privado` para funciones internas de triggers.
- Permite al creador leer y modificar sus borradores, publicadas y archivadas.
- Mantiene lectura pública solo para Rutas activas y publicadas.
- Copia nombre, coordenadas y altitud desde el Lugar activo al crear una parada.
- Exige dos o más paradas, órdenes consecutivos, un inicio y un destino antes
  de publicar.
- Permite publicar directamente, sin aprobación administrativa.
- Permite una valoración de 1 a 5 por usuario y Ruta, modificable.
- Impide que el creador valore su propia Ruta.
- Conserva las relaciones existentes con Publicaciones y Salidas.

## Antes del push

1. Confirmar que el repositorio contiene la migración indicada.
2. Confirmar que no se editaron migraciones anteriores.
3. Tener un respaldo reciente del VPS según el procedimiento habitual.
4. Ejecutar el comando de `db push` que ya utiliza el proyecto, apuntando al
   Supabase del VPS.
5. Revisar que la salida mencione exactamente la migración
   `20260922192604_fase_1_rutas_propiedad_valoraciones.sql`.

La migración se detendrá con un mensaje claro si encuentra una parada histórica
sin `lugar_id`. Según el estado indicado del proyecto, Rutas y paradas están
vacías, por lo que esa precondición debería cumplirse.

## Después del push

Comprobar en Studio:

1. Existe `public.ruta_valoracion`.
2. `ruta_valoracion` tiene RLS habilitado.
3. `public.ruta` contiene `valoracion_promedio` y
   `cantidad_valoraciones`.
4. La vista `public.rutas_publicadas_lista` continúa disponible.
5. No aparece ningún error al consultar el catálogo actual de Rutas.

Conservar y enviar la salida completa del `db push`. Cuando el despliegue quede
confirmado se cerrará la Fase 1 y comenzará la Fase 2 del formulario Flutter.

## Regla posterior al despliegue

Después de aplicar esta migración en el VPS, no debe editarse. Cualquier ajuste
se realizará mediante una migración incremental posterior.
