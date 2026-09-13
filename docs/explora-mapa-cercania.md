# Explora — Mapa, GPS y cercanía 50 km

## Qué es

Al tocar el icono de **mapa** en Explora, el turista ve:

1. El **contorno del departamento de Cusco** (raya dorada).
2. Su **ubicación** (si el GPS / permiso lo permiten).
3. Lugares a **50 km o menos de él** (chip *Cerca 50 km*, activo por defecto cuando hay GPS).
4. Pines de lugares: el primer toque abre un **cuadrito** con el nombre; el segundo (o el chevron) entra al detalle.

## PostGIS (Supabase) — qué hace y qué no

| Pieza | Rol |
|-------|-----|
| Extensión PostGIS | Tipos geográficos en Postgres |
| `lugar.ubicacion` | Punto; se sincroniza solo desde lat/lon |
| RPC `lugares_cerca(p_lat, p_lon, p_radio_m)` | Lista ids a N metros del punto |

PostGIS **no dibuja** el mapa ni el contorno. Solo responde: “¿quiénes están cerca de este lat/lon?”.

El dibujo lo hace Flutter (`flutter_map`).

## Contorno del Cusco (sin PostGIS)

- Asset: `assets/mapas/departamento_cusco.geojson`
- Origen: polígono departamental simplificado (INEI vía peru-geojson).
- Carga: `ContornoDepartamentoCusco` → `PolygonLayer` en el mapa.

## Flujo GPS → cercanía

```
Abrir mapa
  → ServicioUbicacionMapa.obtenerActual()
  → si OK: centro = yo + ConsultaCercaLugares(lat, lon, 50000)
  → RPC lugares_cerca
  → pines + círculo de 50 km
  → si falla GPS: banner “Activar mi ubicación” / ajustes
```

Sin GPS, el chip *Cerca 50 km* no inventa un centro en la plaza: pide ubicación.

## Archivos (módulo `lugares`)

| Ruta | Responsabilidad |
|------|-----------------|
| `pantallas/pantalla_mapa_explora.dart` | UI del modo mapa (GPS, chip, errores) |
| `widgets/mapa_explora_lugares.dart` | Capas: tiles, contorno, radio, yo, pines |
| `dominio/servicio_ubicacion_mapa.dart` | Permisos + posición |
| `datos/contorno_departamento_cusco.dart` | Parseo GeoJSON → puntos |
| `proveedores/proveedor_lugares.dart` | `lugaresCercaProvider` + `ConsultaCercaLugares` |
| `datos/lugar_datasource_supabase.dart` | Cliente RPC `lugares_cerca` |

Copy: `CopyHaku.mapa*` en `lib/nucleo/recursos/copy_haku.dart`.

## Dependencias

Ya en el proyecto: `flutter_map`, `geolocator`, `latlong2`. No se añadió librería nueva.

## Prueba manual sugerida

1. Explora → icono mapa.
2. Con GPS: ver marcador “yo”, raya del Cusco, pines ≤ 50 km, círculo.
3. Tocar pin → cuadrito → otra vez → detalle.
4. FAB de ubicación: recentra en ti.
5. Apagar GPS / negar permiso: banner y diálogo a ajustes; sin inventar “cerca de Cusco plaza”.
6. Desactivar chip: todos los lugares activos.

## Auditoría / bugs corregidos (hilos Explora mapa)

| Riesgo | Corrección |
|--------|------------|
| Spinner reemplazaba todo el mapa (GPS/cerca) | Overlay semitransparente; el mapa sigue montado |
| `MapController.move` antes de listo | `onMapReady` + move seguro |
| `Flexible` en `Row(mainAxisSize: min)` en el pin | `ConstrainedBox` (evita layout crash) |
| Double push al detalle (GestureDetector + InkWell) | Toques separados: bubble / icono |
| Selección de pin huérfana al cambiar filtro | Limpia `_seleccionadoId` si el id ya no está |
| Dos GPS a la vez (banner + chip) | Epoch: ignora respuesta vieja |
| FAB recentrar con mapa no montado | Solo si el mapa está visible |
| Abrir mapa con lista aún vacía destruía el estado | Explora ya no sustituye por scaffold de carga |
