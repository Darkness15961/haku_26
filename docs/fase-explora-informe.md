# Informe de fase — Explora (lugares + territorio)

**Proyecto:** HAKU  
**Sector:** Explora (islas de provincias de Cusco → lugares)  
**Backend:** Supabase self-host (`supabase.haku.best`)  
**App:** Flutter  

Este documento cuenta **todo lo que se hizo en esta fase**, desde que se entregó el trabajo de base de datos para subirlo al servidor hasta el cierre de mapa y cercanía.  
Está escrito para leerse de punta a punta: qué problema había, qué se decidió, qué se construyó y qué quedó pendiente a propósito.

Documentos hermanos (más técnicos / de checklist):

- `docs/fase-explora.md` — checklist vivo por bloques  
- `docs/fase-explora-bd.md` — notas cortas de migraciones  

---

## 1. De dónde partimos

Antes de esta fase, la app tenía **dos mundos**:

1. **Autenticación y perfil** ya hablaban con Supabase (usuarios reales, Google, foto de perfil, etc.).
2. **Explora / lugares** seguían viviendo en datos **locales** del teléfono (catálogo demo, ids tipo `machu_picchu`, usuario demo `'yo'`). Las islas de provincia se veían bien en pantalla, pero los lugares no eran los de la base real.

En el servidor ya existía (o se acababa de traer) un esquema de producto con tablas como `lugar`, `provincia`, `distrito`, PostGIS, etc. Eso se materializó en la migración:

- `supabase/migrations/20260912220617_remote_schema.sql`

Ese archivo es el “retrato” del dominio en BD. **No era suficiente solo** para que Explora funcionara bien: faltaba alinear códigos de provincia con el frontend, seed de Cusco, reglas de seguridad (quién lee / quién escribe) y columnas de ficha que la UI necesitaba.

**Objetivo de la fase:** que las islas de Explora **lean y escriban** lugares reales en Supabase, sin meter todavía Comunidad, Salidas ni Publicaciones remotas.

---

## 2. Cómo se trabajó (método)

Se avanzó **por bloques**, en orden, sin mezclar otros sectores:

| Bloque | Nombre | Idea en una frase |
|--------|--------|-------------------|
| **0** | Pulido BD | Dejar la base lista (territorio, seed, permisos, ficha) |
| **A** | Lectura remota | Mostrar en la app lo que hay en el servidor |
| **B** | Alta de lugar | Crear lugares reales (con sesión y foto) |
| **C** | Mapa / cercanía | Ver pines en mapa y buscar “cerca de un punto” |

Reglas que se respetaron:

- Migraciones ya subidas **no se editan**; si hace falta algo, **migración nueva** + `db push` (túnel SSH a la BD).
- En Flutter se usa el cliente oficial de Supabase (sin HTTP inventado a mano).
- Todo lugar nuevo lleva el usuario de la sesión (`auth.uid()`), no el id demo.
- Entrada de navegación = **provincia** (islas). Distrito = opcional. Varias categorías por lugar.
- Geocoding automático (soltar pin → adivinar distrito) = **fuera** de esta fase.

Tú aplicaste los `db push` cuando correspondía. En particular quedaron aplicadas:

1. `20260912230000_explora_lugar_pulido.sql` (Bloque 0)  
2. `20260912240000_explora_lugares_cerca.sql` (Bloque C — cercanía)

---

## 3. Decisiones de producto / modelo (cerradas)

Estas decisiones se tomaron al inicio y guiaron todo el desarrollo:

| Tema | Decisión |
|------|----------|
| Alcance geográfico | Solo **Cusco** en el MVP |
| Provincias | Las **13** del frontend; cada una con un `codigo` estable (`urubamba`, `la_convencion`, …) igual al id de assets |
| Distrito | **Opcional** al crear; la provincia es obligatoria |
| Coordenadas | Son la verdad espacial; el distrito es etiqueta / filtro |
| Categorías | Tabla `categoria` con tipo `lugar` + tabla puente `lugar_categoria` (un lugar puede tener varias) |
| Calificación / “nivel de exploración” / distancia fija | **No** se metieron como columnas fijas de `lugar` en esta fase |
| Foto | URL en `lugar.foto_portada`, subida al bucket que ya usaba el perfil |

---

## 4. Bloque 0 — Pulido de base de datos

### Qué problema resolvía

El esquema remoto traía tablas, pero Explora necesitaba:

- Poder listar por **provincia** de forma fiable (códigos alineados a la app).
- Distrito **nullable** (no forzar distrito el día 1).
- Campos de ficha: dificultad, tiempo estimado, acceso.
- Datos iniciales: Cusco, 13 provincias, distritos, 8 categorías.
- Reglas: cualquiera puede **ver** catálogo y lugares activos; solo el dueño **crea/edita** los suyos.

### Qué se entregó para subir

Archivo principal:

- `supabase/migrations/20260912230000_explora_lugar_pulido.sql`

Contenido, en lenguaje de producto:

1. **Lugar**  
   - Provincia obligatoria.  
   - Distrito opcional.  
   - Ficha: dificultad, tiempo estimado, acceso.

2. **Códigos geo**  
   - Provincias (y distritos) con códigos que coinciden con los assets / islas del frontend.

3. **Semilla (seed)**  
   - Departamento Cusco.  
   - 13 provincias.  
   - Distritos por provincia.  
   - 8 categorías de lugar (naturaleza, cultura, gastronomía, aventura, caminata, fotografía, misterioso, mágico).

4. **Permisos (RLS)**  
   - Lectura pública del catálogo (provincias, distritos, categorías).  
   - Lectura de lugares activos (y los propios aunque estén inactivos).  
   - Escritura solo autenticado y como dueño del lugar.  
   - Categorías del lugar: mismas reglas de visibilidad / dueño.

5. **Checks de integridad**  
   - Por ejemplo: si hay distrito, debe pertenecer a la misma provincia del lugar.

### Estado

Hecho y **aplicado en el VPS** (`db push`).  
Verificación prevista en Studio: Cusco, 13 provincias con código, distritos, 8 categorías, columnas nuevas en `lugar`.

---

## 5. Bloque A — Lectura remota (la app empieza a mostrar lo real)

### Qué problema resolvía

Aunque la BD estuviera bien, Explora seguía pintando el catálogo local. Había que **conectar** sin mezclar demo + remoto a escondidas: si una provincia no tiene lugares, se muestra vacío claro (con CTA), no un invento silencioso.

### Qué se construyó en Flutter

**Datos (capa servidor)**

- `lib/funcionalidades/lugares/datos/territorio_datasource_supabase.dart`  
  Provincias de Cusco, distritos por provincia, categorías tipo lugar.

- `lib/funcionalidades/lugares/datos/lugar_datasource_supabase.dart`  
  Listar lugares activos, filtrar por provincia (código), obtener uno por id.  
  Incluye join de provincia, distrito y categorías.

**Modelos**

- `modelo_territorio.dart` — filas remotas de provincia / distrito / categoría.  
- `modelo_lugar.dart` — ampliado: códigos e ids de provincia/distrito, varias categorías, flag `remoto`, factory desde fila remota.

**Proveedores (Riverpod)**

- Provincias remotas, categorías remotas, distritos por provincia.  
- `lugaresRemotosProvider` = **fuente de verdad** del listado Explora.  
- Detalle por id (`lugarDetalleProvider`).  
- Invalidación al cambiar datos (`notificarLugaresCambiaron`).

**UI**

- Islas / sheet de provincia: leen la lista remota.  
- Filtros ligeros: distrito y categoría, sin saturar la primera vista.  
- Detalle y “sorpresa” cargan el lugar remoto.  
- Provincias sin filas → vacío honesto + invitación a registrar.

### Assets locales

Los SVG/PNG de islas **siguen locales** (`provincias_datasource_local.dart`).  
Solo el **contenido de lugares** pasó a remoto. Eso es a propósito: el mapa de islas es presentación; los datos son del servidor.

### Estado

Hecho. Criterio de cierre: entrar a una provincia y ver lugares del VPS (o vacío claro); detalle sin crash.

---

## 6. Bloque B — Alta de lugar (escribir en el servidor)

### Qué problema resolvía

El formulario “Agregar lugar” guardaba en el almacén local del teléfono. Había que publicarlo de verdad: sesión obligatoria, provincia de la isla, categorías reales, foto al storage, y que después aparezca en la lista remota.

### Qué se construyó

**Servicio de escritura** (mismo datasource de lugares):

- Crear fila en `lugar` con `usuario_id` = usuario logueado.  
- Insertar filas en `lugar_categoria`.  
- Subir foto a Storage en ruta tipo `{uid}/lugares/portada_….jpg` (mismo bucket que el perfil: `haku-storage-produccion-2026`).  
- Guardar la URL pública en `foto_portada`.

**Formulario** (`pantalla_registrar_lugar.dart`):

Wizard de 5 pasos, alineado a la BD:

1. Nombre, foto opcional, provincia precargada desde la isla, distrito opcional.  
2. Tipos (multi-select desde categorías remotas).  
3. Acceso.  
4. Dificultad (se traduce al enum de BD: fácil / moderado / exigente).  
5. Experiencia + tiempo estimado opcional → **Publicar**.

Comportamiento de producto:

- Gate de sesión (`asegurarSesion`) antes de abrir el flujo.  
- Mensajes de error entendibles (sesión, permisos, datos incompletos, foto).  
- Tras publicar: refresco de la lista remota; el lugar debe verse en su provincia.  
- Coordenadas: por defecto centro de Cusco (hasta que el mapa/pin de ubicación sea otra etapa).

### Estado

Hecho en código Flutter.  
Criterio de cierre: usuario logueado crea un lugar y aparece en su provincia (tras refrescar la lista remota).

---

## 7. Bloque C — Mapa y cercanía

### Qué problema resolvía

Había un widget de mapa con pines, pero no estaba cableado al modo Explora ni a datos remotos. Además se quería una consulta de “lugares cerca de un punto” usando PostGIS (la columna `ubicacion` ya se sincroniza desde lat/lon en el esquema remoto).

### Etapa 1 — Pines remotos

- Se activó el modo **Mapa** en Explora (`ModoExplora.mapa`), con botón en la barra.  
- `MapaExploraLugares` pinta pines desde latitud/longitud de la lista remota.  
- Tocando un pin se abre el detalle.

### Etapa 2 — Cercanía (PostGIS)

Migración nueva (también entregada para push):

- `supabase/migrations/20260912240000_explora_lugares_cerca.sql`

Define la función `lugares_cerca(lat, lon, radio_en_metros)`:

- Busca lugares activos cuya ubicación esté dentro del radio.  
- Devuelve distancia; la app ordena y muestra.  
- En la UI: chip **«Cerca 50 km»** (centro aproximado plaza de Cusco).

**Aplazado a propósito:** sugerir distrito al soltar un pin (geocoding). Quedó anotado como fase aparte.

### Estado

Hecho en código + migración **aplicada** en el VPS.

---

## 8. Mapa de archivos tocados (referencia rápida)

| Pieza | Dónde |
|-------|--------|
| Checklist de fase | `docs/fase-explora.md` |
| Notas BD | `docs/fase-explora-bd.md` |
| Este informe | `docs/fase-explora-informe.md` |
| Schema remoto inicial | `supabase/migrations/20260912220617_remote_schema.sql` |
| Pulido Explora + seed + RLS | `supabase/migrations/20260912230000_explora_lugar_pulido.sql` |
| RPC cercanía | `supabase/migrations/20260912240000_explora_lugares_cerca.sql` |
| Territorio remoto | `lib/funcionalidades/lugares/datos/territorio_datasource_supabase.dart` |
| Lugares remoto (leer/crear/foto/cerca) | `lib/funcionalidades/lugares/datos/lugar_datasource_supabase.dart` |
| Islas / assets | `lib/funcionalidades/lugares/datos/provincias_datasource_local.dart` |
| Proveedores | `lib/funcionalidades/lugares/proveedores/proveedor_lugares.dart` |
| Modo Explora (islas / mapa / rutas) | `lib/funcionalidades/lugares/proveedores/proveedor_explora_ui.dart` |
| Pantalla Explora | `lib/funcionalidades/lugares/pantallas/pantalla_explora_lugares.dart` |
| Registrar | `lib/funcionalidades/lugares/pantallas/pantalla_registrar_lugar.dart` |
| Detalle / sorpresa | pantallas homónimas en `…/lugares/pantallas/` |
| Mapa de pines | `lib/funcionalidades/lugares/widgets/mapa_explora_lugares.dart` |
| Sheet provincia + filtros | `lib/funcionalidades/lugares/widgets/sheet_provincia_lugares.dart` |

---

## 9. Qué se dejó fuera (a propósito)

No forma parte del cierre de esta fase:

- Cablear Comunidad, Salidas, Rutas o Publicaciones al remoto.  
- Obligar distrito al crear.  
- Geocoding / ubigeo automático.  
- Likes, favoritos o valoraciones en BD.  
- Mezclar el id demo `'yo'` con UUID real en inserts de Explora.  
- Editar migraciones ya pusheadas.  
- Selector fino de pin al registrar (coords siguen con default Cusco).

---

## 10. Revisión forense al cierre (honestidad de ingeniería)

Se hizo una revisión al detalle al terminar C. Conclusión:

**La fase Explora 0→C está cerrada en el alcance que se acordó.**  
**No** significa que *toda la app* ya viva solo de lugares remotos, ni que no queden riesgos.

### Hallazgos importantes (para no autoengañarse)

1. **Alta no atómica**  
   Primero se inserta el lugar y después las categorías. Si el segundo paso falla, puede quedar un lugar “a medias” y un reintento puede duplicar.

2. **Doble mundo con Publicaciones / feed**  
   Crear un lugar desde el flujo de **publicar** aún puede ir al almacén **local**. Explora solo lista el remoto → ese lugar no aparece en islas/mapa.  
   El alta “de verdad” de esta fase es el de **Agregar lugar** en Explora.

3. **Detalle con ids viejos**  
   Otras pantallas (búsqueda, favoritos, salidas, semilla del feed) todavía usan ids demo tipo `machu_picchu`. El detalle Explora espera ids numéricos del servidor → puede mostrar “Lugar no encontrado” si se abre desde esos flujos.

4. **Pines apilados**  
   Lugares nuevos con las mismas coords por defecto se ven uno encima de otro en el mapa.

5. **Métricas de “nuevo / hueco”**  
   Al mapear desde remoto se marca todo como “nuevo”, lo que puede inflar contadores de la UI de islas.

6. **Cercanía**  
   El chip usa un centro fijo (Cusco), no GPS ni el centro actual del mapa.

Nada de lo anterior invalida el trabajo de la fase; son **siguientes remiendos** o **fases vecinas**.

---

## 11. Cómo probar lo entregado (guía corta)

1. App con sesión y Supabase arriba.  
2. **Explora → islas:** provincias; sheet con lugares del servidor o vacío + registrar.  
3. Filtros distrito / categoría en el sheet.  
4. Abrir detalle de un lugar remoto.  
5. **Agregar lugar** desde una isla: completar wizard, opcional foto, publicar → debe listarse en esa provincia.  
6. Icono **mapa:** pines; chip **Cerca 50 km** (requiere la migración de cercanía, ya aplicada).  
7. No esperar aún que Publicaciones / búsqueda / favoritos se comporten como Explora remoto.

---

## 12. Resumen ejecutivo

| Pregunta | Respuesta |
|----------|-----------|
| ¿Se entregó BD para subir? | Sí: pulido Explora + luego RPC cercanía |
| ¿Se subió al servidor? | Sí (ambos `db push` hechos) |
| ¿La app lee lugares reales en Explora? | Sí |
| ¿Se pueden crear lugares reales desde Explora? | Sí (con sesión + foto opcional) |
| ¿Hay mapa con pines remotos y cercanía? | Sí |
| ¿Quedó geocoding? | No; aplazado |
| ¿Toda la app es remota en lugares? | No; otros módulos siguen locales / mixtos |
| ¿La fase Explora (alcance acordado) está cerrada? | Sí, con deuda conocida documentada arriba |

---

## 13. Línea de tiempo (orden real de trabajo)

1. Traer / alinear schema remoto de producto (`20260912220617_remote_schema.sql`).  
2. Acordar modelo Explora (provincia obligatoria, distrito opcional, categorías N:N, sin geocoding aún).  
3. **Bloque 0:** migración de pulido + seed + RLS → push.  
4. Documentar fase (`fase-explora.md` / `fase-explora-bd.md`).  
5. **Bloque A:** datasources + providers + UI lectura + filtros.  
6. **Bloque B:** crear lugar + foto Storage + formulario.  
7. **Bloque C:** modo mapa + RPC cercanía → push.  
8. Revisión forense y este informe.

---

*Última actualización del informe: cierre de Bloque C + revisión forense (fase Explora).*
