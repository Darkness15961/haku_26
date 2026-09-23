# HAKU - Fase 7 Rutas: integraciones y salida

## Estado local

La implementacion local de la Fase 7 queda cerrada para el alcance
Flutter/Supabase que no requiere credenciales remotas. La puerta de pruebas
automaticas queda pendiente porque el toolchain `dart`/`flutter` local se
quedo bloqueado durante `dart format` y `flutter --version`.

No se agrega migracion nueva: las relaciones necesarias ya existen en el
historial aplicado del proyecto:

- `salida.ruta_id` para vincular una Salida a una Ruta.
- `publicacion_ruta` para experiencias asociadas a Rutas.
- `ruta_guardada` para guardados de usuario.
- RPC `crear_salida_con_organizador` con parametro `p_ruta_id`.
- RPC/listado `listar_salidas_resumen` con filtro `p_ruta_id`.

## Comportamiento confirmado

- Crear Salida permite elegir una Ruta publicada de forma opcional.
- El punto de encuentro sigue siendo independiente de la Ruta.
- Si la Ruta deja de estar publicada o no carga en catalogo, el formulario no
  permite guardar una nueva Salida con esa Ruta cuando el catalogo remoto esta
  disponible.
- El listado de Salidas puede filtrarse por Ruta.
- El detalle de Salida muestra acceso a la Ruta vinculada cuando esta sigue
  visible para el cliente.
- Las tarjetas de Salida muestran la Ruta vinculada para no esconder la
  relacion hasta el detalle.
- Publicaciones y experiencias ya usan `publicacion_ruta` y se consultan por
  Ruta desde el detalle.
- Rutas guardadas usan `ruta_guardada` y se resuelven sin depender solo de la
  primera pagina del catalogo.

## Verificacion local

- Se agregaron pruebas puras en `test/salida_ruta_integracion_test.dart` para
  validar el parseo de Salida con Ruta, Salida con Ruta no embebida y
  Publicacion con Ruta/Salida.
- `dart format` no pudo completarse porque el proceso `dart` no devolvio
  control.
- `flutter --version` y `flutter --no-version-check --version` tampoco
  devolvieron control dentro del timeout.
- Se cerraron los daemons Dart/Flutter generados por los intentos fallidos.

## Limitacion MVP

Una Salida asociada siempre apunta al registro actual de la Ruta. Si el creador
edita una Ruta publicada, las Salidas existentes veran la version actualizada.
El MVP no guarda instantaneas historicas de la Ruta por cada Salida.

La configuracion de Salida no cambia la Ruta asociada. Si mas adelante se
necesita editar ese vinculo, debe agregarse una decision de producto y una
migracion/RPC especifica para auditar el cambio.

## Checklist remoto/manual

1. Crear al menos una Ruta publicada en Supabase remoto.
2. Crear una Salida publica vinculandola a esa Ruta.
3. Confirmar que el punto de encuentro elegido no cambia al seleccionar Ruta.
4. Abrir el listado de Salidas desde el detalle de Ruta.
5. Abrir el detalle de Salida y entrar a la Ruta vinculada.
6. Archivar o despublicar una Ruta de prueba y verificar que ya no pueda
   seleccionarse en una nueva Salida.
7. Verificar que una Salida antigua con Ruta no publicada no rompe el detalle.
8. Crear una publicacion/experiencia etiquetada con Ruta y validar que aparece
   en el detalle.
9. Guardar y quitar una Ruta desde usuario autenticado.
10. Medir el catalogo remoto con al menos 50 Rutas publicadas.

## Reversion

Como esta fase no agrega SQL nuevo, la reversion principal es de app:

1. Revertir el commit Flutter de Fase 7.
2. Volver a compilar y publicar la app anterior.
3. No ejecutar rollback de base salvo que una migracion posterior cambie el
   contrato de `salida.ruta_id`, `publicacion_ruta` o `ruta_guardada`.
