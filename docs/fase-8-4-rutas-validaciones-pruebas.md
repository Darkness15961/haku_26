# HAKU - Fase 8.4 Rutas: validaciones de producto

## Objetivo

Cerrar las reglas minimas de una Ruta publicable despues del pulido de ficha y
recorrido real.

## Reglas implementadas

- Nombre obligatorio.
- Resumen corto obligatorio.
- Descripcion obligatoria.
- Minimo dos Lugares.
- Lugares sin duplicados.
- Zona obligatoria, sugerida desde paradas o confirmada manualmente.
- Si existe recorrido real importado, debe previsualizarse antes de guardar.
- Si no existe recorrido real, la app pide confirmacion antes de publicar.

## Decisiones

- Publicar sin recorrido real sigue permitido para el MVP, pero queda explicito
  que sera un itinerario de paradas y no navegacion detallada.
- `transporte` y `etiquetas` siguen preservandose internamente por
  compatibilidad, pero no forman parte del flujo guiado.
- No se agrego migracion SQL en este bloque.

## Pruebas tocadas

- `test/rutas_solicitud_crear_test.dart`
  - valida minimo de paradas y duplicados con resumen/zona validos;
  - agrega prueba para resumen obligatorio;
  - agrega prueba para zona obligatoria;
  - conserva prueba de payload RPC limpio.

## Verificacion pendiente

El SDK local `dart`/`flutter` se queda bloqueado durante comandos de formato y
test en esta maquina. Antes de cerrar despliegue, ejecutar:

```bash
dart format lib/funcionalidades/rutas/pantallas/pantalla_crear_ruta.dart \
  lib/funcionalidades/rutas/dominio/modelos/solicitud_crear_ruta.dart \
  test/rutas_solicitud_crear_test.dart

flutter analyze
flutter test test/rutas_solicitud_crear_test.dart test/rutas_trazado_importado_test.dart
```
