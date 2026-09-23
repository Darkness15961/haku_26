# HAKU - Fase 8.2/8.3 Rutas: ficha guiada y recorrido real

## Objetivo

Reducir friccion al crear una Ruta sin cambiar todavia el contrato SQL.

## Cambios de UX

- `Zona` deja de ser un campo libre principal:
  - se calcula desde las paradas cuando es posible;
  - se muestra sombreada como dato sugerido;
  - permite editar manualmente con un boton pequeno `Editar`;
  - permite volver a la zona sugerida.
- `Acceso` deja de ser texto libre:
  - ahora usa opciones predefinidas;
  - conserva valores antiguos si una Ruta editada ya tenia texto personalizado.
- `Requisitos` pasa a chips seleccionables con opcion de agregar otro valor.
- `Advertencias` pasa a chips seleccionables con opcion de agregar otro valor.
- `Transporte` ya no se muestra en Crear Ruta.
- `Etiquetas` ya no se muestra en Crear Ruta porque pertenece mejor a
  Publicaciones/experiencias.
- El bloque de trazado cambia lenguaje tecnico por `Recorrido real`.
- El dialogo de recorrido explica que se puede pegar GPX o GeoJSON y que la
  Ruta puede publicarse solo con paradas.
- La vista previa advierte cuando no existe recorrido real.

## Compatibilidad

No se elimina ninguna columna ni parametro RPC. `transporte` y `etiquetas` se
siguen preservando internamente al editar una Ruta existente, pero no se
ofrecen como campos nuevos del formulario.

## Verificacion pendiente

`dart format` quedo bloqueado localmente durante esta fase. Se cerraron los
procesos generados por el intento. Antes de push/despliegue conviene ejecutar:

```bash
dart format lib/funcionalidades/rutas/pantallas/pantalla_crear_ruta.dart
flutter analyze
flutter test test/rutas_solicitud_crear_test.dart test/rutas_trazado_importado_test.dart
```
