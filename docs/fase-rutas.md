# HAKU — Ingeniería del dominio Rutas

## Decisión de producto

- Un **Lugar** es un punto geográfico.
- Una **Ruta** es un itinerario ordenado, versionado y con ficha técnica.
- Una **Salida** coordina personas, fecha y punto de encuentro; puede enlazar una
  Ruta publicada mediante `salida.ruta_id`.
- La app móvil no publica ni edita Rutas. En esta fase HAKU carga el catálogo
  oficial fuera de la app y lo marca como `publicado`.

## Modelo remoto

La migración `20260916010000_rutas_dominio_remoto.sql` amplía, sin reemplazar,
las tablas `ruta` y `ruta_parada` existentes.

### `ruta`

Incluye:

- identidad estable: `id bigint` para relaciones y `slug` para enlaces;
- ficha: nombre, resumen, descripción, foto, tipo y zona;
- dificultad, distancia, duración, días, altitudes y desnivel;
- meses recomendados, acceso, transporte, requisitos y advertencias;
- `version`, `publicada_en` y `estado_editorial`;
- `trazado geography(LineString,4326)` opcional.

Los estados reservados son:

`borrador → propuesta → en_revision → publicado`

También existen `rechazado` y `archivado`. Solo `publicado` es visible para la
app.

### `ruta_parada`

Cada nodo posee orden único dentro de la Ruta, nombre, tipo, coordenadas,
altitud e instrucciones. Puede enlazar opcionalmente un Lugar publicado.

Las paradas son nodos narrativos. El `LineString` es el recorrido geográfico
real. Si no hay `LineString`, el mapa muestra marcadores y no une las paradas
con una línea falsa.

## Lectura móvil

- `rutas_publicadas_lista`: vista liviana, sin geometría ni colección de
  paradas.
- `ruta_publicada_detalle(bigint)`: carga bajo demanda la ficha completa,
  paradas ordenadas y trazado GeoJSON.
- `rutasPublicadasProvider`: caché compartida por Explora, Inicio y creación de
  Salida.
- `rutaDetalleProvider`: hidrata el detalle únicamente al abrir la Ruta.
- «Recomendadas» es la entrada general al catálogo; Cultura y Naturaleza son
  filtros. No se muestra «Populares» hasta existir una métrica remota real.

Cuando Supabase está configurado, remoto es la única fuente de verdad. El
catálogo local permanece exclusivamente para ejecutar una demo sin backend;
no se mezcla con filas remotas ni rellena un catálogo remoto vacío.

En modo debug se registran tiempos:

```text
[rendimiento] rutas.listado 123 ms
[rendimiento] rutas.detalle 87 ms
```

## Integraciones

### Salidas

La creación permite seleccionar una Ruta publicada opcional. El Lugar de
encuentro, sus coordenadas y la hora siguen siendo propios de la Salida. RLS
impide insertar o actualizar una Salida con una Ruta no publicada.

`crear_salida_con_organizador()` crea la Salida y confirma al organizador en
una sola transacción. El detalle muestra un enlace a la Ruta y la ficha permite
listar u organizar las Salidas asociadas.

### Publicaciones

`publicacion_ruta` relaciona una publicación con una Ruta publicada. Solo el
autor puede crear o eliminar esa etiqueta y se reutilizan las reglas de
visibilidad de la publicación.

`crear_publicacion_completa()` guarda publicación, imagen y relaciones en una
transacción. Si el RPC falla después de subir el archivo, Flutter elimina el
objeto de Storage. Las experiencias y recuerdos se consultan por Ruta, sin
depender del límite global del feed.

## Seguridad

- `anon` y `authenticated` solo tienen `SELECT` sobre Rutas publicadas.
- No hay policies móviles de `INSERT`, `UPDATE` o `DELETE` para `ruta` ni
  `ruta_parada`.
- `service_role` conserva el canal operativo para carga oficial.
- El detalle usa `SECURITY INVOKER`: no evita RLS.
- Las constraints validan slug, estados, métricas, meses, tipos de parada y
  geometría mínima. Coordenadas inválidas se rechazan para nuevas paradas y el
  cliente descarta defensivamente filas históricas inválidas.

Las migraciones `20260916040000_creaciones_atomicas.sql` y
`20260916050000_integridad_listados_rutas.sql` cierran atomicidad, membresía
aprobada, PK compuesta de `publicacion_ruta` y validación de coordenadas.

## Contrato de moderación futura

El panel administrativo no forma parte de esta fase. Cuando se construya:

1. el usuario crea una `propuesta`, nunca una Ruta pública;
2. reglas automáticas e IA detectan duplicados, geometría inválida,
   incoherencias de altitud y texto riesgoso;
3. la IA propone normalizaciones, pero no cambia el estado a `publicado`;
4. una persona de HAKU aprueba o rechaza;
5. cada publicación incrementa `version` y conserva auditoría de autor,
   revisor, fecha y motivo.

Antes de habilitar propuestas se deben agregar tablas de revisión/auditoría,
un rol administrativo verificable en backend y RPCs atómicas. No se debe
otorgar escritura directa sobre `ruta` a clientes públicos.

## Verificación

1. Aplicar migraciones en orden cronológico.
2. Confirmar que una Ruta `borrador` no aparece para `anon` ni
   `authenticated`.
3. Confirmar que una Ruta `publicado` aparece en Explora.
4. Abrir detalle y verificar orden de paradas.
5. Verificar que sin `trazado` no se dibuja una polilínea.
6. Crear una Salida vinculada y abrir la Ruta desde su detalle.
7. Etiquetar una publicación con la Ruta.
8. Ejecutar `flutter test` y `dart analyze`.
