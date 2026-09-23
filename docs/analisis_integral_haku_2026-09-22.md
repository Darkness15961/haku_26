# Análisis integral del proyecto HAKU

**Fecha del análisis:** 22 de septiembre de 2026  
**Repositorio analizado:** `Haku produccion/Haku`  
**Rama observada:** `main`, commit `638b024` (`UPDATE: MAPA V2`)  
**Alcance:** frontend Flutter actual, frontend conservado en `Fronnent antiguo`, backend Supabase versionado, assets, plataformas, pruebas, documentación e historial Git local.

---

## 1. Resumen ejecutivo

HAKU ya no es un prototipo pequeño. Es una aplicación Flutter de turismo, descubrimiento cultural y coordinación social centrada en Cusco, con un backend Supabase considerable: autenticación, perfiles, lugares georreferenciados, comunidades, salidas, publicaciones multimedia, favoritos, “me gusta”, rutas, chats grupales y privados, Realtime, Storage, PostGIS, funciones RPC y dos Edge Functions.

La conclusión principal sobre el diseño es más favorable de lo que parecía inicialmente:

- El frontend actual **no reemplazó por completo** el frontend antiguo.
- De los 157 archivos Dart del frontend antiguo, **91 permanecen idénticos**, 63 se modificaron y solo 3 dejaron de existir en su ubicación original.
- El sistema visual central —paleta oro/piedra/negro, tipografías, fondos, portada de Inicio, tarjetas culturales, islas de provincias y gran parte de Rutas— continúa presente.
- El deterioro de coherencia visual se concentra principalmente en pantallas nuevas o muy reescritas: administración, formularios remotos, chat, mapas, publicaciones remotas y algunas partes del perfil y comunidad.
- En varios casos el cambio no fue puramente estético: se hizo para conectar datos reales, manejar carga/error, incorporar permisos, resolver responsive, soportar Realtime o sustituir simulaciones locales.

Por tanto, **no recomiendo restaurar en bloque `Fronnent antiguo` sobre `lib`**. Eso eliminaría gran parte del backend integrado y reintroduciría flujos simulados. La estrategia correcta es conservar la lógica y contratos actuales, declarar el frontend antiguo como referencia visual y reconciliar pantalla por pantalla mediante un sistema de diseño explícito.

En ingeniería, la base es ambiciosa y muestra buenas decisiones —RLS, RPC atómicas, soft delete, control de cupos, `security_invoker` en vistas, separación por funcionalidades, Riverpod y fuentes remotas—, pero también acumula deuda importante:

- coexistencia prolongada entre datos locales de demostración y datos remotos;
- archivos monolíticos de más de 1.000 líneas;
- duplicación muy alta entre crear y editar publicación;
- migraciones remotas y manuales que se contradicen entre sí;
- configuración local de Supabase incompleta;
- cobertura automatizada insuficiente para la complejidad de RLS y Realtime;
- preparación de release Android/iOS todavía incompleta;
- documentación principal desactualizada;
- dos hallazgos de seguridad del backend que requieren verificación prioritaria.

### Veredicto global

| Área | Evaluación | Lectura corta |
|---|---:|---|
| Visión de producto | Alta | La propuesta es clara y diferenciada: explorar, conectar, salir y compartir alrededor de Cusco. |
| Backend funcional | Media-alta | Hay mucha funcionalidad real y reglas de negocio valiosas, pero falta validación integral del estado desplegado. |
| Arquitectura Flutter | Media | La organización por funcionalidades ayuda, aunque hay capas parciales, módulos monolíticos y dos fuentes de verdad. |
| Coherencia visual | Media-alta en legado, media en pantallas nuevas | La identidad no se perdió; se diluyó en expansiones recientes. |
| Seguridad | Media, con revisión urgente | La intención de RLS es buena, pero dos flujos privilegiados requieren corrección o confirmación. |
| Pruebas | Baja-media | Existen 35 pruebas automatizadas, casi todas unitarias; faltan integración, RLS, Realtime, navegación y golden tests. |
| Preparación para tiendas | Baja | Android aún usa identificador de ejemplo y firma debug; iOS/OAuth y Web no están cerrados. |
| Mantenibilidad | Media-baja | Hay 28 archivos de más de 500 líneas y 8 de más de 1.000 líneas. |

---

## 2. Qué se analizó y qué no se puede afirmar todavía

### Evidencia revisada

- 227 archivos Dart actuales, aproximadamente **47.534 líneas**.
- 157 archivos Dart en `Fronnent antiguo`, aproximadamente **26.062 líneas**.
- 81 migraciones SQL, aproximadamente **10.284 líneas**.
- 2 Edge Functions en TypeScript/Deno.
- 7 archivos de prueba con 34 `test()` y 1 `testWidgets()`.
- 19 documentos técnicos existentes.
- 58 assets visuales/geográficos relevantes, aproximadamente **24,21 MB**.
- Historial Git, ramas locales/remotas y cambios sin confirmar.
- Las capturas `flutter_01.png` y `flutter_02.png` como referencias visuales auxiliares.

### Límites del análisis

Este documento describe con precisión el **estado versionado en el repositorio**. No demuestra por sí solo que el VPS de Supabase tenga exactamente las mismas migraciones, permisos, funciones o secretos desplegados.

No se realizó una conexión de lectura al proyecto Supabase remoto ni se ejecutaron consultas contra la base viva. Por ello, los hallazgos SQL se expresan como el resultado efectivo que tendría una instalación construida en orden desde estas migraciones, salvo que el servidor tenga cambios manuales o `ALTER DEFAULT PRIVILEGES` no versionados.

La ejecución actual de `flutter analyze`, `dart analyze` y la consulta de versión de Flutter quedó bloqueada sin salida hasta agotar el tiempo de espera. El mismo bloqueo ocurrió invocando directamente el ejecutable Dart del SDK. Esto apunta al entorno local del SDK, no prueba un fallo de HAKU. Existe un `analyze_output.txt` anterior que muestra únicamente 11 avisos informativos por `const` innecesario, pero ese archivo no sustituye un análisis fresco del estado actual.

---

## 3. Estado del repositorio y riesgo de respaldo

### Git observado

- Rama activa: `main`.
- `main` local está **9 commits por delante** de `origin/main`.
- Hay dos archivos modificados sin commit:
  - `lib/funcionalidades/lugares/widgets/mapa_explora_lugares.dart`;
  - `lib/funcionalidades/perfil_usuario/pantallas/pantalla_perfil_usuario.dart`.
- Existe la rama remota `origin/visual-oro-piedra-minimal`.
- `Fronnent antiguo` está versionado y contiene 157 archivos rastreados; no es una carpeta accidental sin respaldo.

### Implicación

Antes de una reconciliación visual conviene crear un punto de restauración y subir los nueve commits que solo existen localmente. El mayor riesgo inmediato no es perder el frontend antiguo —está versionado— sino perder trabajo reciente que todavía no existe en el remoto o mezclarlo con una restauración masiva.

### Recomendación de control

1. Confirmar los dos cambios locales actuales en un commit descriptivo.
2. Subir `main` o crear una rama de respaldo remoto.
3. Crear una rama dedicada, por ejemplo `reconciliacion-diseno`.
4. No copiar carpetas completas desde `Fronnent antiguo`.
5. Recuperar componentes visuales mediante diffs pequeños y verificables.

---

## 4. Qué producto representa HAKU

HAKU combina cuatro dominios que normalmente aparecen separados:

1. **Descubrimiento territorial:** lugares, provincias, distritos, categorías, mapas, GPS y cercanía.
2. **Contenido cultural:** rutas editoriales, experiencias, fotografías y video.
3. **Organización social:** comunidades públicas/privadas, membresías y salidas con cupos.
4. **Comunicación:** bandeja unificada, chats de comunidad, salida y conversaciones privadas contextuales.

El flujo de producto que emerge del código es:

```text
Descubrir un lugar o una ruta
        ↓
Guardar / valorar / publicar una experiencia
        ↓
Encontrar o crear una comunidad
        ↓
Organizar o inscribirse en una salida
        ↓
Coordinar por chat y compartir contenido
```

Ese circuito es la mayor fortaleza del proyecto. HAKU no es solo una guía turística ni solo una red social: intenta convertir descubrimiento cultural en actividad compartida.

---

## 5. Stack y arquitectura general

### Frontend

| Elemento | Implementación observada |
|---|---|
| Framework | Flutter / Dart, SDK declarado `^3.9.2` |
| Estado | Riverpod 2.6.1 |
| Backend cliente | `supabase_flutter` 2.17.2 |
| Mapas | `flutter_map` y `maplibre_gl` coexistiendo |
| Geografía | `latlong2`, `geolocator`, GeoJSON local |
| Multimedia | `image_picker`, `video_player`, `cached_network_image` |
| Login Google | `google_sign_in` |
| Persistencia local | `shared_preferences` con documento/semilla legacy |
| UI | Material 3 con tema oscuro y sistema visual propio parcial |

### Backend

| Elemento | Implementación observada |
|---|---|
| Plataforma | Supabase self-hosted |
| Base | PostgreSQL 17 configurado localmente |
| Geodatos | PostGIS / tipo `geography` y RPC de cercanía |
| Auth | Email/contraseña y Google ID token |
| Datos | PostgREST, RLS, vistas y RPC |
| Realtime | Cambios PostgreSQL para mensajes y bandeja |
| Archivos públicos | Bucket principal de medios |
| Archivos privados | Bucket de chat con URLs firmadas |
| Video | Bunny Stream mediante Edge Function |
| Limpieza | Patrón outbox, Edge Function y `pg_cron`/`pg_net` |

### Forma arquitectónica del frontend

La estructura es “feature-first”:

```text
lib/
├── main.dart
├── funcionalidades/
│   ├── autenticacion/
│   ├── carga_inicial/
│   ├── chat/
│   ├── comunidad/
│   ├── favoritos/
│   ├── inicio/
│   ├── lugares/
│   ├── perfil_usuario/
│   ├── publicaciones/
│   └── rutas/
└── nucleo/
    ├── almacenamiento/
    ├── datos/
    ├── demo/
    ├── metricas/
    ├── navegacion/
    ├── recursos/
    ├── responsive/
    ├── supabase/
    └── widgets/
```

La intención de separar `datos`, `dominio`, `pantallas`, `proveedores` y `widgets` es correcta. Sin embargo, no todos los módulos cumplen la misma profundidad: algunos conservan repositorios y servicios que ya no son la ruta principal; otros acceden directamente a Supabase desde el datasource o incluso desde widgets auxiliares.

No es una Clean Architecture estricta. Es una arquitectura pragmática por funcionalidades con capas parciales.

---

## 6. Análisis del frontend actual por módulo

### 6.1 Carga inicial y shell

`main.dart` inicializa Supabase, instala `ProviderScope`, aplica el tema oscuro y monta `PantallaCargaInicial` antes de `PantallaInicio`.

Fortalezas:

- arranque asíncrono correcto antes de `runApp`;
- manejo de excepción de inicialización;
- tema central consistente;
- transiciones por plataforma;
- envoltorio responsive global;
- navegación principal con pestañas montadas de forma diferida;
- conservación de estado mediante `IndexedStack`;
- barra inferior en vertical y riel lateral en horizontal;
- control del botón Atrás;
- contador real de no leídos conectado a Realtime.

Riesgos:

- si Supabase falla al iniciar, la aplicación continúa; varios providers devuelven listas vacías. El usuario puede interpretar “no hay contenido” cuando en realidad el backend no está disponible;
- no existe una pantalla global de degradación o diagnóstico de conexión;
- la navegación se gestiona con `Navigator` y estados manuales, sin rutas declarativas ni deep-linking integral;
- el shell conoce detalles de chat, auth, publicación y navegación de tabs, aumentando acoplamiento.

### 6.2 Inicio

Inicio mantiene la estructura visual antigua casi intacta:

- encabezado editorial;
- acceso a mensajes;
- buscador;
- acceso a mapa;
- portada cultural;
- carruseles temáticos;
- tarjeta de descubrimientos comunitarios;
- experiencias especiales.

El cambio principal es de datos: rutas y lugares se alimentan de Supabase cuando está listo, y del catálogo local únicamente como fallback controlado.

Puntos positivos:

- no se inventan métricas remotas cuando el backend no las provee;
- se evita duplicar tarjetas e imágenes entre secciones;
- el layout usa escalado y espacios responsive;
- los no leídos ya no son datos demo.

Deuda:

- Inicio todavía importa y observa `almacenFeedProvider` para partes legacy;
- la búsqueda usa catálogos locales de lugares, rutas y perfiles, por lo que no representa necesariamente el universo remoto;
- clips, comentarios y seguimiento de exploradores continúan siendo mayormente locales;
- la lógica editorial y de transformación ocupa demasiado espacio dentro de la pantalla.

### 6.3 Explora / Lugares

Es uno de los módulos con mayor evolución. Incluye:

- catálogo remoto de lugares activos;
- provincias/distritos/categorías;
- vista de “islas” por provincia;
- mapa real;
- GPS;
- filtro de cercanía;
- selección manual de coordenadas;
- alta de lugar con foto;
- detalle y experiencias asociadas;
- navegación entre modo islas, mapa y rutas.

Fortalezas:

- separación razonable entre modelos territoriales, datasource, provider y UI;
- validación defensiva de coordenadas;
- PostGIS para búsquedas cercanas;
- carga/error/vacío explícitos;
- no se mezcla el catálogo local con el remoto como fuente principal de Explora;
- GeoJSON del contorno de Cusco local para evitar dependencia innecesaria;
- pruebas unitarias para coordenadas, provincia, categorías y mapeo remoto.

Riesgos:

- `pantalla_registrar_lugar.dart` supera 1.000 líneas;
- `pantalla_mapa_explora.dart` y `mapa_explora_lugares.dart` son complejos y mezclan UX, permisos, geometría y motor de mapa;
- hay dos librerías de mapa en el proyecto, elevando peso y complejidad;
- todavía hay dependencias locales para provincias, métricas y experiencias;
- la subida de portada ocurre antes de completar el alta; hay compensación parcial, pero el flujo merece una prueba de fallo real;
- el datasource remoto y la UI asumen IDs numéricos expresados como `String`, una convención útil pero frágil si no se centraliza.

### 6.4 Rutas

El dominio Rutas conserva gran parte del frontend antiguo e incorpora datos remotos:

- listado de rutas publicadas;
- detalle editorial;
- paradas ordenadas;
- trazado GeoJSON;
- mapa de ruta;
- guardado remoto;
- asociación con publicaciones y salidas.

Fortalezas:

- diseño editorial fuerte y coherente;
- vista `security_invoker` para el listado;
- RPC de detalle que evita hidratar indiscriminadamente todos los nodos;
- modelo defensivo que descarta coordenadas inválidas;
- pruebas unitarias del mapeo remoto;
- distinción honesta entre una ruta sin trazado y una ruta con geometría.

Deuda:

- catálogo local y datasource remoto siguen coexistiendo;
- el listado remoto usa límite fijo y no pagina;
- parte de las métricas y experiencias de ruta aún provienen del almacén local;
- existe una contradicción de migraciones que vuelve a introducir un `JOIN + GROUP BY` para contar paradas; se detalla en la sección de backend;
- no hay editor/moderación de rutas dentro de la app, lo cual puede ser una decisión de producto válida, pero exige un proceso administrativo externo.

### 6.5 Comunidades

Es el módulo más grande: aproximadamente **10.826 líneas Dart** repartidas en 35 archivos.

Capacidades observadas:

- listar comunidades públicas y privadas visibles;
- crear comunidades;
- incluir miembros al crear;
- solicitud para privadas y unión directa a públicas;
- administración de solicitudes;
- edición y eliminación;
- roles y estados de membresía;
- salidas generales y asociadas a comunidad;
- configuración y cierre de inscripciones;
- publicaciones comunitarias;
- acceso a chats.

Fortalezas:

- operaciones críticas encapsuladas en RPC atómicas;
- manejo de estados de carga/error/vacío;
- separación entre modelos locales y remotos explícita en nombres;
- reglas de cupos y membresía en base de datos, no solo en Flutter;
- vistas de administración relativamente completas.

Deuda:

- la pantalla principal supera 1.100 líneas;
- la pantalla de detalle supera 800 líneas;
- todavía se mezclan comunidades y salidas locales para caminos legacy;
- `pantalla_crear_salida.dart` local y `pantalla_crear_salida_remota.dart` conviven, aumentando el riesgo de abrir el flujo equivocado;
- hay pantallas de utilidad con un lenguaje Material genérico que no siempre usa los componentes editoriales del diseño inicial;
- la definición de qué parte de una comunidad privada es descubrible cambió en migraciones recientes y debe quedar documentada como decisión de producto.

### 6.6 Publicaciones

La antigua `pantalla_publicaciones.dart` fue sustituida por:

- `pantalla_crear_publicacion.dart`;
- `pantalla_editar_publicacion.dart`;
- tarjetas remotas;
- datasource Supabase;
- soporte de imagen y video;
- asociaciones a lugar, ruta, comunidad y salida;
- privacidad, edición, soft delete, me gusta y guardado.

Este cambio es funcionalmente importante, pero introduce uno de los mayores problemas de mantenibilidad:

- crear: aproximadamente 1.391 líneas físicas;
- editar: aproximadamente 1.487 líneas físicas;
- similitud aproximada por líneas únicas: **81,8 %**.

La UI actual sí reutiliza paleta, tipografía, fondos y línea inca. El problema no es una pérdida total de diseño, sino la duplicación. Cualquier ajuste visual deberá repetirse en dos archivos enormes y es fácil que ambos flujos diverjan.

Recomendación: extraer un `FormularioPublicacionHaku` compartido con un modo `crear/editar`, selectores reutilizables y un controlador de estado independiente.

### 6.7 Chat

El chat actual reemplazó el chat directo simulado del frontend antiguo por un sistema remoto mucho más completo:

- bandeja unificada;
- conversaciones de comunidad, salida y privado;
- roster explícito;
- texto, imagen privada, ubicación y stickers;
- edición y soft delete;
- reacciones;
- paginación de historial;
- no leídos;
- Realtime y reconciliación;
- perfiles contextuales y creación segura de DM.

Fortalezas:

- lógica de seguridad principalmente server-side;
- bucket privado y URLs firmadas;
- RPC para crear/reutilizar salas;
- prevención de DM arbitrario mediante contexto compartido;
- overlay local para reducir duplicados entre historial y Realtime;
- pruebas de fusión de mensajes y contenido eliminado.

Deuda:

- `pantalla_chat_sala.dart`: aproximadamente 1.451 líneas físicas;
- `chat_datasource_supabase.dart`: aproximadamente 1.187 líneas físicas;
- la pantalla mezcla presentación, paginación, media, geolocalización, edición, reacciones y creación de sala;
- no hay pruebas automatizadas de reconexión, paginación, orden, duplicados ni pérdida de membresía;
- no hay notificaciones push;
- audio figura en el modelo de base, pero no está implementado;
- el diseño es consistente en color y tipografía, aunque más utilitario y menos editorial que Inicio/Rutas.

### 6.8 Favoritos e interacciones

El repositorio ya contiene tablas remotas para:

- lugares guardados;
- rutas guardadas;
- publicaciones guardadas;
- me gusta de publicaciones.

Esto hace que el documento antiguo `docs/analysis_results.md` esté desactualizado cuando afirma que likes no existen o que los favoritos son exclusivamente locales.

Sin embargo, el frontend aún conserva favoritos y likes locales para partes legacy —clips, comentarios, seguimiento y algunas rutas usadas por pantallas antiguas—. La migración funcional está incompleta, no ausente.

Observación de implementación: los providers de guardados remotos instancian datasources directamente y no comprueban `supabaseListo` antes de consultar. Además, filtran del resultado los elementos creados por el propio usuario; si esto es una regla de producto, debe explicitarse, y si no, produce una sorpresa de UX.

### 6.9 Perfil

El perfil actual combina:

- datos reales de sesión;
- edición de perfil, correo, clave, nacionalidad y avatar;
- publicaciones, lugares y salidas del usuario;
- insignias;
- guardados;
- perfil ajeno y navegación contextual.

Fortalezas:

- el perfil ya no usa nombres ficticios como fallback principal;
- las fuentes remotas se consultan de manera aislada para que una no derribe toda la pantalla;
- se incorporó responsive horizontal;
- se mantienen fondos, serif, oro y tarjetas con textura.

Problemas observados:

- `pantalla_perfil_usuario.dart` supera 1.100 líneas;
- cuatro textos visibles tienen mojibake: `CerÃ¡mica`, `MontaÃ±ista`, `FotÃ³grafo` y `CartÃ³grafo`;
- las insignias se calculan parcialmente con reglas locales muy simples;
- las rutas propias se muestran honestamente como cero porque el backend no expone un flujo de autoría para usuarios normales;
- hay un cambio local sin commit que vuelve a aplicar `FondosDetalleHaku.tarjeta` a la sección de insignias, lo cual va en la dirección de recuperar identidad visual.

---

## 7. Comparación detallada con `Fronnent antiguo`

### 7.1 Resultado cuantitativo

| Módulo | Archivos antiguos | Archivos actuales | Idénticos | Modificados | Solo antiguos | Solo actuales |
|---|---:|---:|---:|---:|---:|---:|
| Autenticación | 15 | 25 | 9 | 6 | 0 | 10 |
| Carga inicial | 4 | 4 | 4 | 0 | 0 | 0 |
| Chat | 0 | 12 | 0 | 0 | 0 | 12 |
| Comunidad | 11 | 35 | 3 | 8 | 0 | 24 |
| Favoritos | 11 | 12 | 10 | 1 | 0 | 1 |
| Inicio | 34 | 34 | 22 | 11 | 1 | 1 |
| Lugares | 20 | 32 | 6 | 14 | 0 | 12 |
| Perfil | 18 | 20 | 11 | 7 | 0 | 2 |
| Publicaciones | 3 | 3 | 0 | 1 | 2 | 2 |
| Rutas | 29 | 31 | 19 | 10 | 0 | 2 |
| Núcleo y `main.dart` | 12 | 19 | 7 | 5 | 0 | 7 |
| Total | 157 | 227 | 91 | 63 | 3 | 73 |

Los tres archivos que solo quedan en el frontend antiguo son:

- `funcionalidades/publicaciones/pantallas/pantalla_publicaciones.dart`;
- `funcionalidades/publicaciones/datos/catalogo_publicacion_demo.dart`;
- `funcionalidades/inicio/pantallas/pantalla_chat_directo.dart`.

No fueron eliminados sin reemplazo: publicaciones se dividió en crear/editar y chat directo se sustituyó por el módulo remoto unificado.

### 7.2 Componentes visuales que sobrevivieron exactamente

Entre otros, son idénticos entre antiguo y actual:

- `estilos_rutas.dart`: paleta y tipografías;
- `portada_inicio_cultura.dart`;
- `fondo_suave_seccion.dart`;
- `decoracion_detalle_fondo.dart`;
- `mapa_islas_provincias.dart`;
- `isla_provincia.dart`;
- múltiples widgets de Rutas, Inicio, Favoritos y Perfil.

Esto demuestra que la identidad visual no desapareció del código.

### 7.3 Qué sí cambió y por qué

| Zona | Cambio actual | Motivo funcional | Riesgo visual |
|---|---|---|---|
| Shell | carga diferida, riel lateral, back handling, no leídos reales | estabilidad, responsive y Realtime | Bajo |
| Inicio | fuentes remotas, métricas honestas, padding responsive | datos reales | Bajo; estructura casi idéntica |
| Explora | estados remotos, mapa real, GPS, alta de lugar | integración territorial | Medio; UI más técnica |
| Comunidad | reescritura para RLS, membresías, salidas y administración | producto real | Alto; gran superficie nueva |
| Publicar | reemplazo del flujo demo por alta/edición remota | persistencia, media y etiquetas | Medio; conserva tokens pero duplica layout |
| Chat | módulo completamente nuevo | comunicación real | Alto; no existía equivalente completo |
| Perfil | datos remotos y responsive | identidad real del usuario | Medio; composición cambió |
| Rutas | datasource remoto, detalle y guardados | catálogo productivo | Bajo-medio |

### 7.4 Diagnóstico del lenguaje visual

La identidad codificada es:

- negro cálido, no negro puro;
- oro Cusco mate como acento;
- piedra/plomo para texto y bordes;
- títulos serif con `Crimson Pro`;
- interfaz redondeada con `Quicksand`;
- logo manuscrito con `Caveat`;
- fondos textiles/fotográficos;
- líneas y símbolos incas;
- tarjetas editoriales de imagen dominante.

En el frontend actual se registran aproximadamente 1.958 usos de `PaletaRutas` y 752 de `TipografiaHaku`. Las pantallas nuevas usan estas bases con frecuencia. La pérdida de control no está principalmente en colores o tipografía, sino en la **composición**:

- más `AppBar`, `ListTile`, diálogos y formularios estándar;
- menos jerarquía editorial en pantallas operativas;
- ornamentos aplicados de manera irregular;
- radios, espaciados, alturas y estilos de botones definidos localmente;
- varias pantallas construyen sus propios campos, chips y encabezados;
- no existe un catálogo central de componentes con reglas de uso.

### 7.5 Lectura de las capturas raíz

`flutter_01.png` muestra una dirección clara y muy distintiva:

- fondo claro ilustrado;
- mosaicos de fotografía cultural;
- acentos terracota, azul y tierra;
- jerarquía editorial fuerte;
- barra inferior curva con acción central.

`flutter_02.png` muestra la otra cara del lenguaje:

- detalle inmersivo oscuro;
- fotografía a sangre;
- serif prominente;
- oro mate;
- fichas técnicas compactas;
- galería y experiencias.

El código antiguo conservado ya usa en gran medida la variante oscura oro/piedra. Por tanto, las capturas y `Fronnent antiguo` no son necesariamente una única etapa idéntica del diseño. Antes de rediseñar conviene declarar cuál es la fuente de verdad:

1. carpeta antigua;
2. capturas raíz;
3. rama `visual-oro-piedra-minimal`;
4. o una síntesis aprobada de las tres.

### 7.6 Recomendación de reconciliación visual

No restaurar pantallas enteras. Crear primero:

- `TemaHaku` con colores, tipografía y elevaciones;
- `EspaciadoHaku` y radios semánticos;
- `EncabezadoHaku`;
- `CampoHaku`;
- `BotonPrimarioHaku` y `BotonSecundarioHaku`;
- `TarjetaHaku` con variantes editorial, funcional y peligrosa;
- `SheetHaku` y `DialogoHaku`;
- `EstadoCargaHaku`, `EstadoVacioHaku` y `EstadoErrorHaku`;
- reglas para uso de textura/ornamento según densidad.

Después migrar en este orden:

1. Perfil y Comunidad, porque concentran la percepción de pérdida visual.
2. Crear/editar publicación, extrayendo primero el formulario compartido.
3. Crear/editar comunidad y salida.
4. Chat y gestión de participantes.
5. Mapas y utilidades.

Inicio y Rutas deberían tocarse al final y solo con cambios pequeños: son las áreas donde más se conserva la intención anterior.

---

## 8. Backend Supabase

### 8.1 Inventario de datos

Las migraciones crean o registran 33 tablas de `public`, agrupables así:

| Dominio | Tablas |
|---|---|
| Identidad | `usuario`, `nacionalidad` |
| Territorio | `departamento`, `provincia`, `distrito`, `categoria` |
| Lugares | `lugar`, `lugar_categoria`, `lugar_guardado` |
| Rutas | `ruta`, `ruta_parada`, `ruta_guardada` |
| Comunidades | `comunidad`, `comunidad_miembro`, `comunidad_mensaje` |
| Salidas | `salida`, `salida_participante` |
| Publicaciones | `publicacion`, `publicacion_multimedia`, `publicacion_lugar`, `publicacion_ruta`, `publicacion_salida`, `publicacion_etiqueta_comunidad`, `publicacion_usuario_etiqueta`, `publicacion_me_gusta`, `publicacion_guardada` |
| Chat | `sala_chat`, `sala_participante`, `sala_privada`, `mensaje`, `mensaje_reaccion` |
| Operación | `cola_limpieza_media` |
| Residuo | `tabla_de_prueba` |

La estructura relacional es rica y, en general, mejor que serializar relaciones en JSON. Se usan tablas puente para categorías, etiquetas, guardados, likes y asociaciones de publicaciones.

### 8.2 Reglas de negocio valiosas en base de datos

- creación automática de perfil tras Auth;
- nickname normalizado y único;
- sincronización de coordenadas PostGIS;
- cercanía por radio;
- membresías con rol y estado;
- cupos de salida protegidos con bloqueo `FOR UPDATE`;
- creación atómica de comunidad, salida y publicación;
- salas únicas por comunidad/salida;
- DM uno a uno idempotente;
- roster explícito;
- no leídos por cursor temporal;
- mensajes editables/eliminables solo mediante RPC;
- protección de columnas de identidad del mensaje;
- reacciones deduplicadas;
- privacidad derivada para publicaciones etiquetadas a comunidades privadas;
- soft delete de publicaciones;
- outbox para limpieza de medios.

Mover estas reglas al servidor fue una buena decisión. La app no debería depender de esconder botones para garantizar seguridad.

### 8.3 RLS y permisos

La intención de seguridad es seria:

- RLS se habilita en tablas expuestas;
- los inserts comprueban `auth.uid()`;
- los updates importantes usan `USING` y `WITH CHECK`;
- se corrigió la autoescalada de membresía;
- helpers evitan recursión RLS;
- el chat comprueba roster y estado del contexto;
- el bucket privado deriva acceso desde la sala;
- las vistas de rutas usan `security_invoker`;
- varios RPC revocan `PUBLIC` y conceden roles concretos.

No obstante, el gran número de `SECURITY DEFINER` —más de cien apariciones contando redefiniciones históricas— exige disciplina. La mayoría tiene comprobaciones de usuario, pero las funciones viven en `public`, se redefinen varias veces y no siempre restauran permisos después de un `DROP FUNCTION`.

### 8.4 Hallazgo crítico: resumen de salidas

La migración final `20260921020858_salida_configuracion_inscripcion.sql` hace lo siguiente:

1. elimina las versiones anteriores de `listar_salidas_resumen`;
2. la recrea como `SECURITY DEFINER`;
3. no contiene una condición equivalente a la RLS de visibilidad de salidas;
4. devuelve, entre otros datos, comunidad, fecha y coordenadas de punto de encuentro;
5. no vuelve a ejecutar `REVOKE ALL ... FROM PUBLIC` ni el `GRANT` explícito que sí existía en migraciones anteriores.

PostgreSQL concede por defecto ejecución de funciones nuevas a `PUBLIC`, salvo que el servidor tenga privilegios por defecto modificados. Al ser `SECURITY DEFINER`, la función puede evitar RLS. En una instalación construida solo con estas migraciones, una llamada anónima podría listar salidas recientes no canceladas, incluidas salidas restringidas a comunidad.

**Severidad:** crítica antes de producción.  
**Qué verificar en vivo:** `proacl`, propietario, `prosecdef`, definición efectiva y resultado como `anon`.  
**Corrección conceptual:** filtrar dentro del RPC con las mismas reglas de `salida_select_visibles`, revocar `PUBLIC` después de cada recreación y conceder únicamente los roles necesarios. Si el punto exacto de encuentro es sensible, no devolverlo en el listado público.

### 8.5 Hallazgo alto: Edge Function `limpiador-media`

La función:

- acepta cualquier `POST`;
- no valida JWT, secreto de cron ni identidad dentro del código;
- crea un cliente con `SUPABASE_SERVICE_ROLE_KEY`;
- procesa hasta 50 elementos de la cola y borra objetos reales.

El cron versionado llama a la función sin cabecera `Authorization`.

Esto produce dos posibles estados:

- si la plataforma exige JWT, el cron probablemente recibe 401 y la limpieza no funciona;
- si se desplegó con verificación JWT desactivada, cualquier tercero que conozca la URL puede activar repetidamente un trabajador privilegiado.

El cuerpo no permite elegir archivos arbitrarios, por lo que no es una eliminación directa controlada por el atacante. Aun así, permite abuso, concurrencia innecesaria y consumo de recursos.

Recomendación: protegerla con un secreto específico de cron o una verificación de firma/cabecera, documentar `verify_jwt`, limitar concurrencia y registrar observabilidad. El cron debe enviar la autenticación correspondiente sin almacenar secretos en SQL plano si puede evitarse.

### 8.6 Migraciones contradictorias

`20260919062931_optimizacion_rutas_publicadas.sql`:

- añade `ruta.cantidad_paradas`;
- crea trigger de mantenimiento;
- simplifica la vista evitando `JOIN + GROUP BY`.

Después, `20260919075516_remote_schema.sql`:

- elimina el trigger;
- elimina la función;
- elimina la columna;
- recrea la vista con `LEFT JOIN`, `count()` y `GROUP BY`.

Por orden de migración, la optimización queda deshecha en instalaciones nuevas. Esto también sugiere deriva entre el esquema remoto y las migraciones manuales.

Los archivos `remote_schema.sql` son útiles como fotografía, pero mezclarlos con migraciones de intención manual puede revertir trabajo. Se necesita decidir si el flujo es imperativo limpio o snapshots generados, y revisar cada `db pull` antes de confirmarlo.

### 8.7 Migraciones y datos de QA

`20260915020000_seed_comunidades_qa.sql` crea comunidades de prueba y las atribuye al primer usuario real de `public.usuario` si existe.

En desarrollo es útil. En producción puede:

- crear contenido no solicitado;
- atribuirlo a una persona real;
- afectar privacidad y métricas;
- hacer que un reset o despliegue nuevo no sea neutral.

Los seeds QA deberían estar en `supabase/seed.sql` o en un script explícito de entorno, no en la cadena de migraciones productivas.

### 8.8 Configuración local incompleta

`supabase/config.toml` declara:

```toml
[db.seed]
enabled = true
sql_paths = ["./seed.sql"]
```

pero `supabase/seed.sql` no existe. Un `supabase db reset` limpio puede fallar al llegar al seed o, como mínimo, no reproducir el escenario esperado.

Además:

- `additional_redirect_urls` local no contiene el deep link móvil usado por la app;
- la configuración local no representa necesariamente Google OAuth del VPS;
- `auto_expose_new_tables` queda en su valor por defecto;
- las restricciones de red local permiten todas las redes, adecuado para desarrollo pero no una referencia de producción.

### 8.9 Edge Function de Bunny

`bunny-ticket` está mejor protegida:

- exige `Authorization`;
- valida el usuario con `getUser()`;
- comprueba propiedad de la publicación;
- usa service role solo para sincronizar el estado confirmado por Bunny;
- compensa la creación remota si falla el insert;
- limita acciones y valida `publicacion_id`.

Mejoras pendientes:

- el import `@supabase/supabase-js@2` no está fijado a una versión exacta;
- CORS acepta cualquier origen;
- la observabilidad depende de `console.error`;
- falta una prueba automatizada del contrato con Bunny y fallos de compensación.

### 8.10 Otras observaciones de seguridad

- La anon key está incluida en Flutter como fallback. Una anon/publishable key es pública por naturaleza; el riesgo no es que pueda leerse, sino cualquier RLS débil detrás de ella. Aun así, el fallback acopla builds a producción y dificulta rotación/entornos.
- No se encontró una `service_role` literal en el cliente Flutter.
- La policy antigua de Storage usaba `auth.role()`, pero una migración posterior la reemplaza por `TO authenticated` y prefijo de UID.
- El bucket principal es de lectura pública. Esto es compatible con avatares/publicaciones públicas, pero no debe alojar contenido que se pretenda privado.
- Algunas funciones trigger `SECURITY DEFINER` del outbox no fijan `search_path` ni revocan ejecución explícitamente. Deben endurecerse aunque normalmente se invoquen como triggers.
- Hay grants excesivos sobre la vista `rutas_publicadas_lista` (`INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, etc.). `security_invoker`, RLS y privilegios de tablas base pueden impedir efectos, pero el principio de menor privilegio recomienda conceder solo `SELECT`.
- `tabla_de_prueba` permanece en el esquema y debería eliminarse mediante una migración revisada si no cumple ninguna función.

---

## 9. Calidad, mantenibilidad y rendimiento

### 9.1 Tamaño y concentración

| Métrica | Resultado |
|---|---:|
| Archivos Dart actuales | 227 |
| Archivos de más de 500 líneas | 28 |
| Archivos de más de 1.000 líneas | 8 |
| Módulo Dart más grande | Comunidad, ~10.826 líneas |
| Archivo de UI más grande | Crear/editar publicación y chat, ~1.300–1.500 líneas |
| Datasource más grande | Chat Supabase, ~1.187 líneas físicas |

Los archivos grandes no son un problema solo estético. Dificultan:

- pruebas aisladas;
- revisión de seguridad;
- reutilización de diseño;
- resolución de conflictos Git;
- consistencia entre estados carga/error/vacío;
- correcciones sin regresiones.

### 9.2 Doble fuente de verdad

El proyecto mantiene un documento local completo con:

- perfiles demo;
- publicaciones;
- clips;
- comunidades;
- salidas;
- mensajes directos;
- likes y favoritos;
- comentarios;
- seguimiento.

Al mismo tiempo, los dominios principales ya existen en Supabase. Algunas pantallas seleccionan remoto si `supabaseListo`; otras siguen consumiendo partes locales aun con Supabase disponible.

Consecuencias:

- un usuario puede ver una entidad en una pantalla y no en otra;
- IDs demo como `yo`, slugs y IDs numéricos requieren defensas dispersas;
- métricas locales y remotas tienen significado distinto;
- cambiar de cuenta puede dejar estado local no asociado al usuario remoto;
- es difícil saber qué funcionalidad está realmente terminada.

Recomendación: crear una matriz de fuente de verdad por caso de uso y retirar el modo local de producción. Si se desea una demo, activarla mediante flavor/flag explícito y repositorios intercambiables, no por fallos de inicialización.

### 9.3 Manejo de errores

Hay buenas prácticas locales:

- `try/catch` en operaciones remotas;
- estados Riverpod de carga/error;
- compensaciones de Storage;
- mensajes humanos;
- no confundir siempre error con vacío.

Pero también hay silencios peligrosos:

- `aportacionesPerfilProvider` captura errores de cada fuente con `catch (_) {}` y muestra datos parciales sin indicar degradación;
- el fallo global de Supabase deja la app activa con contenido vacío;
- gran parte de la telemetría es `debugPrint` o `print`;
- no existe un servicio central de errores ni observabilidad;
- la guía manual contempla muchos fallos, pero no hay evidencia de ejecución registrada.

### 9.4 Rendimiento

Mejoras ya presentes:

- carga diferida de tabs;
- providers que conservan valor durante reload;
- listados resumidos;
- índices parciales para participantes confirmados y mensajes vivos;
- batch RPC para rosters;
- paginación de mensajes;
- cache de imágenes;
- control del número máximo de filas API.

Riesgos:

- vista de rutas revirtió a agregación por `JOIN + GROUP BY`;
- varios listados usan límites fijos sin cursor;
- feed, publicaciones y rutas necesitan paginación consistente;
- las RLS complejas invocan helpers por fila; hay índices, pero debe confirmarse con `EXPLAIN (ANALYZE, BUFFERS)` sobre volumen real;
- `listar_comunidades_resumen` cuenta miembros con subconsulta correlacionada;
- assets raster pesan aproximadamente 22,74 MB sin contar compresión final;
- `fondoHaku.png` pesa aproximadamente 7,3 MB y otros dos fondos superan 2,6 y 3,9 MB;
- dos motores de mapas elevan tamaño, tiempos de compilación y superficie de bugs.

### 9.5 Dependencias y actualizaciones

`pubspec.lock` está versionado, lo cual es correcto. Las versiones principales están fijadas por restricciones compatibles, pero varias dependencias ya mostraban versiones nuevas en el análisis previo. No recomiendo actualizar todo en bloque; primero deben existir pruebas de regresión.

Las Edge Functions importan Supabase JS desde CDN con `@2`, no una versión exacta. Debe fijarse una versión concreta y mantener el lock/config de Deno.

---

## 10. Pruebas y verificación

### 10.1 Cobertura existente

Existen pruebas para:

- normalización y validación de nickname;
- mapeo de lugar y categorías;
- coordenadas y resolución de provincia;
- parseo del contorno de Cusco;
- modelo remoto de rutas y GeoJSON;
- mapeo de multimedia de publicación;
- métricas locales/remotas;
- modelos y fusión de mensajes;
- smoke widget de carga inicial.

Son pruebas útiles de dominio y mapeo defensivo.

### 10.2 Brechas críticas

No hay pruebas automatizadas visibles para:

- políticas RLS como `anon`, usuario A, usuario B y service role;
- RPC atómicas;
- privacidad de comunidades y salidas;
- concurrencia de cupos;
- creación y revocación de roster;
- paginación y reconciliación Realtime;
- bucket privado de chat;
- compensación de Storage;
- Edge Functions;
- autenticación real;
- navegación completa;
- cambio de cuenta;
- diseño responsive;
- golden tests del frontend antiguo frente al actual;
- accesibilidad.

### 10.3 Guía manual

`docs/guia-pruebas-manuales-haku.md` es extensa y valiosa. Incluye escenarios realistas de navegación, auth, comunidad, salidas, chat, bandeja, errores, permisos y rendimiento.

El problema es que los casos están marcados como pendientes. La guía es un plan de QA, no evidencia de QA ejecutado.

### 10.4 Resultado de ejecución en esta auditoría

- `flutter analyze`: tiempo agotado sin salida actual.
- `flutter --version`: mismo bloqueo.
- `dart analyze`: mismo bloqueo, incluso con el ejecutable directo.
- `flutter test`: no se ejecutó porque depende del mismo SDK bloqueado.
- `analyze_output.txt`: evidencia anterior de 11 avisos informativos por `const`, no verificación actual.

Acción recomendada: reparar primero el SDK Flutter local o ejecutar CI en un entorno limpio y reproducible. No conviene modificar código para “arreglar” un fallo que todavía no ha producido diagnóstico.

---

## 11. Preparación por plataforma

### Android

Correcto:

- permisos de internet, cámara, ubicación y media;
- deep link `hakuapp://login-callback`;
- actividad `singleTop`;
- soporte de back invocation.

Bloqueadores de release:

- `applicationId = "com.example.haku"`;
- etiqueta de aplicación en minúscula `haku`;
- build release firmado con la clave debug;
- iconografía/splash parecen parcialmente genéricos;
- falta una configuración de firma productiva y manejo seguro de `key.properties`.

### iOS

Correcto:

- descripciones de ubicación, cámara, galería y micrófono.

Pendiente:

- no se observó `CFBundleURLTypes` para `hakuapp`;
- Google iOS Client ID está vacío en Flutter;
- debe verificarse `GoogleService-Info.plist` o la configuración equivalente;
- el propio código/documentación reconoce iOS como incompleto.

### Web

- `index.html` todavía usa descripción, título e identidad genéricos de Flutter;
- no se ve estrategia específica de OAuth web;
- MapLibre, permisos, cámara y video deben probarse por navegador;
- el producto parece móvil primero; Web no debería declararse listo solo porque Flutter generó la carpeta.

### Escritorio

Existen carpetas Linux, macOS y Windows generadas, pero no hay evidencia de que los flujos de GPS, Google Sign-In, cámara, mapas y deep links estén adaptados. Deben considerarse scaffolding, no plataformas soportadas.

---

## 12. Documentación

### Fortalezas

Los documentos de fases son inusualmente detallados. Registran decisiones, riesgos, contratos y criterios de cierre para:

- autenticación;
- Explora;
- comunidades;
- chat;
- rutas;
- interacciones;
- publicaciones;
- limpieza de medios;
- optimización;
- pruebas manuales.

Esto preserva contexto importante frente a cambios realizados por modelos distintos.

### Problemas

- `README.md` sigue siendo el README genérico de Flutter.
- `docs/analysis_results.md` quedó atrás respecto a likes, guardados, Edge Functions y cantidad de migraciones.
- algunos documentos dicen “completo” cuando las pruebas manuales siguen pendientes.
- la configuración real de producción y la local se describen a veces como si fueran equivalentes.
- no hay un documento único de decisiones de producto visuales.
- no existe un ADR que declare la fuente de verdad entre local y remoto.

### Documentos nuevos recomendados

1. `README.md` real: propósito, requisitos, entornos, comandos y arquitectura.
2. `docs/arquitectura.md`: frontend, backend y límites de módulos.
3. `docs/sistema-diseno-haku.md`: tokens, componentes, capturas aprobadas y reglas.
4. `docs/fuentes-de-verdad.md`: qué dominio es local/remoto y plan de retiro.
5. `docs/seguridad-supabase.md`: matriz RLS/RPC/buckets.
6. `docs/release.md`: Android/iOS, secretos, firma y checklist.
7. ADR sobre privacidad del punto exacto de encuentro.

---

## 13. Hallazgos priorizados

### P0 — Revisar antes de exponer producción

| Hallazgo | Evidencia | Impacto |
|---|---|---|
| RPC final de salidas `SECURITY DEFINER` sin filtro de visibilidad ni restauración explícita de permisos | `20260921020858_salida_configuracion_inscripcion.sql` | Posible exposición de salidas restringidas y coordenadas mediante Data API |
| Trabajador `limpiador-media` sin autenticación propia | Edge Function + cron sin Authorization | O el cron no funciona o existe un endpoint privilegiado activable públicamente |

### P1 — Alta prioridad

| Hallazgo | Impacto |
|---|---|
| `main` local 9 commits por delante y 2 archivos sin commit | Riesgo de pérdida o mezcla accidental durante restauración visual |
| QA seed dentro de migraciones productivas | Contenido de prueba atribuido al primer usuario real |
| Optimización de rutas revertida por snapshot posterior | Rendimiento y deriva de esquema |
| Dos fuentes de verdad activas | Inconsistencias funcionales y fugas de estado entre cuentas |
| Sin pruebas RLS/RPC/Realtime | Riesgos de privacidad y regresión no detectados |
| Android con ID de ejemplo y firma debug | Bloquea publicación segura |
| iOS OAuth/deep link incompleto | Login/recuperación no confiables en iOS |
| `supabase/seed.sql` ausente | Entorno local no reproducible |
| Archivos de UI y datos >1.000 líneas | Alto costo de cambio y regresión |

### P2 — Prioridad media

| Hallazgo | Impacto |
|---|---|
| Crear/editar publicación con 81,8 % de similitud | Bugs duplicados e inconsistencia visual |
| Mojibake en cuatro insignias | Defecto visible de calidad |
| README genérico y análisis previo obsoleto | Incorporación y operación confusas |
| Imports Deno no fijados exactamente | Riesgo de cambios de dependencia |
| Grants excesivos sobre vista de rutas | Superficie de permisos innecesaria |
| `tabla_de_prueba` y migraciones vacías/residuales | Ruido y ambigüedad del esquema |
| Assets raster pesados | Tamaño de app y memoria |
| Falta de observabilidad central | Diagnóstico difícil en producción |
| Navegación manual dispersa | Deep links y pruebas más difíciles |

### P3 — Evolución

- notificaciones push;
- moderación, denuncia y bloqueo;
- panel administrativo de lugares/rutas;
- presencia y escritura en chat;
- geocodificación automática;
- accesibilidad y localización;
- edición/cancelación completa de salidas;
- estrategia formal Web/escritorio;
- cifrado extremo a extremo solo si el modelo de riesgo lo exige.

---

## 14. Hoja de ruta recomendada

### Fase 0 — Congelar y hacer reproducible

Objetivo: poder cambiar sin perder trabajo ni discutir contra un estado móvil.

- respaldar los nueve commits locales;
- confirmar los dos cambios sin commit;
- reparar Flutter SDK o ejecutar CI limpio;
- conseguir `flutter analyze` y `flutter test` verdes;
- crear `supabase/seed.sql` o desactivar el seed;
- documentar migraciones aplicadas en el VPS;
- exportar definición efectiva de funciones, policies y grants;
- tomar capturas actuales de todas las pantallas clave.

### Fase 1 — Seguridad y consistencia de backend

- corregir y probar `listar_salidas_resumen`;
- proteger `limpiador-media`;
- sacar seed QA de migraciones productivas;
- corregir grants excesivos;
- fijar `search_path` y permisos de todas las funciones privilegiadas;
- decidir qué hacer con snapshots `remote_schema`;
- ejecutar advisors y pruebas RLS por rol;
- decidir privacidad de coordenadas exactas.

### Fase 2 — Contrato visual

- elegir referencias aprobadas;
- capturar tokens actuales;
- crear catálogo de componentes;
- producir golden tests para Inicio, Explora, Comunidad, Perfil, detalle de lugar/ruta y publicación;
- definir qué pantallas deben ser editoriales y cuáles operativas.

### Fase 3 — Reconciliación sin perder lógica

- perfil;
- comunidad y detalle;
- formularios de comunidad/salida;
- publicación compartida crear/editar;
- chat;
- mapas/utilidades.

Cada cambio debe conservar providers, datasources, modelos y RPC actuales salvo que exista un bug funcional demostrado.

### Fase 4 — Retirar legacy

- crear flavor demo explícito si se necesita;
- eliminar fallbacks locales de producción;
- migrar búsqueda, comentarios, clips y seguimiento o marcarlos fuera de alcance;
- retirar `EsquemaHaku`, semillas y modelos que ya no tengan consumidores;
- evitar que un fallo de Supabase active silenciosamente datos demo.

### Fase 5 — Release

- application ID definitivo;
- firma Android release;
- iconos y splash finales;
- iOS URL scheme y Google Client ID;
- SMTP y recuperación real;
- política de privacidad;
- observabilidad;
- pruebas en dispositivos reales;
- ejecución y firma de la guía manual;
- build reproducible y rollback.

---

## 15. Arquitectura objetivo sugerida

```text
UI / páginas
  └─ componentes HAKU compartidos
      └─ controladores/notifiers por caso de uso
          └─ repositorios (interfaces)
              ├─ implementación Supabase de producción
              └─ implementación demo solo en flavor demo
                  └─ cliente Supabase / Storage / Realtime
```

Reglas prácticas:

- ninguna pantalla de más de 500–700 líneas;
- ningún datasource concentra chat, media, roster y bandeja a la vez;
- crear y editar comparten el mismo formulario;
- el UI no instancia datasources directamente;
- toda fuente remota diferencia carga, vacío, error y datos parciales;
- demo nunca se activa porque producción falló;
- los permisos se prueban desde base, no solo desde widgets;
- un componente visual nuevo debe entrar primero al catálogo HAKU.

---

## 16. Qué conservar especialmente

No todo necesita rehacerse. Conviene proteger:

- `PaletaRutas` y `TipografiaHaku` como semilla del sistema visual;
- portada y carruseles de Inicio;
- fondos y decoración de Rutas;
- islas de provincias;
- estructura relacional de publicaciones;
- lógica server-side de cupos;
- creación atómica de entidades;
- modelo de chat con roster y DM contextual;
- bucket privado del chat;
- mapeos defensivos de modelos;
- guía de pruebas manuales;
- carpeta de frontend antiguo y rama visual como archivo histórico.

---

## 17. Qué no conviene hacer

- No sustituir `lib` por `Fronnent antiguo`.
- No eliminar migraciones ya aplicadas para “ordenarlas”.
- No usar service role en Flutter.
- No resolver permisos agregando `SECURITY DEFINER` sin auditoría.
- No convertir cada pantalla nueva en un estilo distinto.
- No actualizar todas las dependencias antes de tener pruebas.
- No declarar “completo” un módulo solo porque su UI existe.
- No mezclar datos demo con datos de una cuenta real.
- No usar el primer usuario real como propietario de seeds QA.
- No publicar Android con `com.example.haku` ni firma debug.

---

## 18. Siguiente acción concreta recomendada

El mejor siguiente bloque no es un rediseño masivo. Es un **corte de seguridad y control de versión**:

1. respaldar el estado Git local;
2. confirmar en la base desplegada la definición y permisos de `listar_salidas_resumen`;
3. confirmar cómo está desplegada y autenticada `limpiador-media`;
4. reparar el entorno Flutter y ejecutar pruebas;
5. elaborar una pantalla de comparación visual por módulo;
6. empezar la reconciliación por Perfil, porque ya existe un cambio local orientado a recuperar textura y porque concentra un defecto visible de codificación.

Con ese orden se protege lo más valioso del proyecto: el backend y las reglas de negocio ya construidas, mientras se recupera el control del diseño de forma verificable.

---

## 19. Índice de archivos clave

### Entrada y sistema visual

- [`lib/main.dart`](../lib/main.dart)
- [`lib/funcionalidades/rutas/widgets/estilos_rutas.dart`](../lib/funcionalidades/rutas/widgets/estilos_rutas.dart)
- [`lib/funcionalidades/rutas/widgets/decoracion_detalle_fondo.dart`](../lib/funcionalidades/rutas/widgets/decoracion_detalle_fondo.dart)
- [`lib/nucleo/responsive/espacio_haku.dart`](../lib/nucleo/responsive/espacio_haku.dart)

### Shell e Inicio

- [`lib/funcionalidades/inicio/pantallas/pantalla_inicio.dart`](../lib/funcionalidades/inicio/pantallas/pantalla_inicio.dart)
- [`lib/funcionalidades/inicio/pantallas/pantalla_feed_inicio.dart`](../lib/funcionalidades/inicio/pantallas/pantalla_feed_inicio.dart)
- [`lib/funcionalidades/inicio/widgets/portada_inicio_cultura.dart`](../lib/funcionalidades/inicio/widgets/portada_inicio_cultura.dart)

### Datos remotos

- [`lib/nucleo/supabase/config_supabase.dart`](../lib/nucleo/supabase/config_supabase.dart)
- [`lib/funcionalidades/lugares/datos/lugar_datasource_supabase.dart`](../lib/funcionalidades/lugares/datos/lugar_datasource_supabase.dart)
- [`lib/funcionalidades/comunidad/datos/comunidad_datasource_supabase.dart`](../lib/funcionalidades/comunidad/datos/comunidad_datasource_supabase.dart)
- [`lib/funcionalidades/comunidad/datos/salida_datasource_supabase.dart`](../lib/funcionalidades/comunidad/datos/salida_datasource_supabase.dart)
- [`lib/funcionalidades/comunidad/datos/publicacion_datasource_supabase.dart`](../lib/funcionalidades/comunidad/datos/publicacion_datasource_supabase.dart)
- [`lib/funcionalidades/chat/datos/chat_datasource_supabase.dart`](../lib/funcionalidades/chat/datos/chat_datasource_supabase.dart)

### Backend y seguridad

- [`supabase/config.toml`](../supabase/config.toml)
- [`supabase/migrations/20260921020858_salida_configuracion_inscripcion.sql`](../supabase/migrations/20260921020858_salida_configuracion_inscripcion.sql)
- [`supabase/migrations/20260919062931_optimizacion_rutas_publicadas.sql`](../supabase/migrations/20260919062931_optimizacion_rutas_publicadas.sql)
- [`supabase/migrations/20260919075516_remote_schema.sql`](../supabase/migrations/20260919075516_remote_schema.sql)
- [`supabase/functions/bunny-ticket/index.ts`](../supabase/functions/bunny-ticket/index.ts)
- [`supabase/functions/limpiador-media/index.ts`](../supabase/functions/limpiador-media/index.ts)

### Referencias históricas

- [`Fronnent antiguo/main.dart`](../Fronnent%20antiguo/main.dart)
- [`Fronnent antiguo/funcionalidades/publicaciones/pantallas/pantalla_publicaciones.dart`](../Fronnent%20antiguo/funcionalidades/publicaciones/pantallas/pantalla_publicaciones.dart)
- [`docs/guia-pruebas-manuales-haku.md`](guia-pruebas-manuales-haku.md)

---

## 20. Conclusión final

HAKU tiene una base de producto valiosa y bastante más madura de lo que su README sugiere. La integración con Supabase añadió complejidad real y, en gran parte, necesaria. El frontend antiguo no debe verse como “la versión buena que hay que volver a poner”, sino como un archivo de intención visual del que todavía vive una parte sustancial dentro del frontend actual.

La mejor recuperación de control consiste en:

- asegurar backend y migraciones;
- separar definitivamente demo y producción;
- convertir la identidad existente en un sistema de diseño obligatorio;
- refactorizar los monolitos antes de seguir añadiendo pantallas;
- comparar visualmente con golden tests;
- cerrar release y QA con evidencia.

El proyecto no necesita empezar de cero. Necesita consolidación, límites arquitectónicos y una autoridad visual única.
