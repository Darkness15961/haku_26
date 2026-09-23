# HAKU — Plan de ejecución del MVP de Rutas

**Estado:** contrato funcional aprobado para iniciar implementación  
**Fecha:** 2026-09-22  
**Estrategia:** una fase activa a la vez, con verificación antes de avanzar  
**Despliegue de Supabase/VPS:** lo realiza el propietario del proyecto

## 1. Objetivo

Construir el módulo de Rutas como un itinerario ordenado de Lugares existentes,
creado y publicado directamente por un usuario autenticado. La Ruta será visible
para la comunidad desde su publicación, podrá recibir valoraciones de 1 a 5 y
solo su creador podrá modificarla durante el MVP.

El futuro panel web administrativo será una capa de moderación posterior. No
será una puerta de aprobación previa: servirá para inspeccionar, corregir,
inactivar, archivar o eliminar contenido abusivo cuando esa fase se implemente.

## 2. Contrato funcional

### 2.1 Entidades

- **Lugar:** punto geográfico existente en HAKU.
- **Ruta:** itinerario ordenado formado por dos o más Lugares.
- **Parada:** posición de un Lugar dentro de una Ruta.
- **Trazado:** recorrido geográfico real y validado; nunca se obtiene uniendo
  nodos con líneas rectas.
- **Salida:** actividad con fecha, organizador, participantes y punto de
  encuentro propio; puede enlazar opcionalmente una Ruta.
- **Valoración:** puntuación de 1 a 5 emitida por un usuario autenticado.

### 2.2 Publicación

1. El usuario autenticado inicia una Ruta como borrador.
2. Completa la información mínima.
3. Selecciona al menos dos Lugares.
4. Ordena inicio, paradas y destino.
5. Previsualiza el resultado.
6. Pulsa **Publicar**.
7. La Ruta se vuelve visible inmediatamente; no requiere aprobación previa.

### 2.3 Propiedad y edición

- `usuario_creador_id` se obtiene de la sesión; el cliente no puede elegirlo.
- Solo el creador puede leer sus borradores.
- Solo el creador puede crear, ordenar o eliminar paradas de su Ruta.
- Solo el creador puede modificar o archivar su Ruta.
- Ningún usuario puede editar una Ruta ajena aunque manipule el ID en la API.
- Una Ruta publicada puede ser mejorada por su creador y los cambios son
  públicos en el MVP.
- Cada actualización incrementará la versión y actualizará `updated_at`.
- El historial completo de revisiones de una Ruta publicada queda fuera del
  MVP. Esta limitación debe permanecer documentada porque una edición cambia la
  Ruta usada por futuras consultas y Salidas asociadas.

### 2.4 Valoraciones

- Solo usuarios autenticados pueden valorar.
- La puntuación válida es un entero entre 1 y 5.
- Existe una sola valoración por usuario y Ruta.
- El usuario puede cambiar su valoración; no crea una segunda fila.
- El creador no podrá valorar su propia Ruta.
- La media y cantidad se calculan con datos reales.
- Una valoración baja no despublica automáticamente una Ruta.
- Las valoraciones ayudan a la comunidad a juzgar calidad, pero no sustituyen
  la moderación de contenido ofensivo.

### 2.5 Moderación futura

El panel web administrativo queda fuera del MVP. Cuando se implemente podrá:

- listar Rutas nuevas, editadas o reportadas;
- inspeccionar autor, contenido, Lugares y trazado;
- modificar una Ruta;
- inactivarla o archivarla;
- eliminarla definitivamente solo cuando sea seguro;
- registrar motivo, administrador y fecha;
- suspender usuarios en una fase posterior.

La operación normal de moderación será **inactivar o archivar**, no borrar
físicamente. El borrado definitivo puede romper referencias de Salidas,
Publicaciones, guardados o valoraciones y requerirá una política explícita.

## 3. Decisiones de simplicidad

- No se crearán muchas tablas pequeñas para atributos escalares.
- `ruta` conserva su ficha general y el `LineString` opcional.
- `ruta_parada` conserva los nodos ordenados.
- Se añadirá únicamente la tabla justificada `ruta_valoracion`.
- En el MVP, cada parada se elige desde Lugares existentes; no se dibujan nodos
  libres ni coordenadas manuales.
- El backend toma las coordenadas del Lugar seleccionado; el usuario no duplica
  esa información.
- Una Ruta puede publicarse inicialmente con nodos ordenados y sin trazado real,
  pero la interfaz debe decir que el recorrido detallado aún no está disponible.
- El primer catálogo de lanzamiento debe procurar tener trazados reales para
  evitar una experiencia incompleta.

## 4. Flujo de interfaz

### 4.1 Crear Ruta

El formulario se divide en cuatro pasos breves:

1. **Identidad:** nombre, resumen, descripción y fotografía.
2. **Itinerario:** buscar Lugares, agregarlos y reordenarlos.
3. **Ficha:** tipo, dificultad y recomendaciones mínimas.
4. **Vista previa:** mapa, paradas y botón Publicar.

No se mostrarán de entrada todos los campos técnicos disponibles en la tabla.
Distancia, duración, altitud, acceso avanzado y trazado se completarán o
calcularán cuando exista información confiable.

### 4.2 Mis Rutas

- Borradores.
- Publicadas.
- Archivadas por el creador.
- Acción Editar solo cuando el usuario sea propietario.
- La interfaz no confiará únicamente en ocultar botones: RLS hará cumplir la
  propiedad en la base de datos.

### 4.3 Explora → Rutas

- Solo muestra Rutas activas y publicadas.
- Tarjetas con fotografía, título, tipo, dificultad, número de Lugares,
  distancia si está verificada, promedio y cantidad de valoraciones.
- No se mostrarán métricas inventadas ni datos del catálogo demo cuando
  Supabase esté configurado.

### 4.4 Detalle y mapa

- Diseño visual basado en `Fronnent antiguo`: tinta, carbón, oro, piedra,
  fotografía protagonista, separadores incas y tipografía editorial.
- Botón **Ver recorrido** visible, no escondido únicamente en el menú flotante.
- Itinerario vertical numerado y enlace al detalle de cada Lugar.
- MapLibre como motor único.
- OpenFreeMap como proveedor inicial configurable.
- Marcadores sin línea si no existe `LineString` validado.

## 5. Forma de ejecución

Solo puede existir una fase `EN CURSO`. No se inicia la siguiente hasta cerrar
las pruebas y el despliegue necesario de la actual.

Cada fase se considera terminada únicamente cuando cumple:

- [ ] contrato revisado;
- [ ] implementación local terminada;
- [ ] pruebas automáticas pertinentes terminadas;
- [ ] revisión de seguridad/RLS terminada;
- [ ] archivos SQL nuevos entregados;
- [ ] propietario aplicó los cambios en el VPS;
- [ ] pruebas remotas o manuales terminadas;
- [ ] resultado y limitaciones documentados.

## 6. Fases

### Fase 0 — Preflight y contrato — COMPLETADA

- [x] Diferenciar Lugar, Ruta y Salida.
- [x] Definir publicación directa sin aprobación.
- [x] Definir edición exclusiva del creador.
- [x] Definir valoración comunitaria de 1 a 5.
- [x] Posponer el panel administrativo.
- [x] Definir disciplina de migraciones incrementales.
- [x] Crear diagnóstico SQL de solo lectura para el VPS.
- [x] Aceptar las migraciones como fuente de verdad por decisión del propietario.
- [x] Reconstruir localmente todo el historial de migraciones sin errores.
- [x] Congelar el contrato SQL de la Fase 1.

**Entregables de preflight:**

- [`preflight_rutas_vps.sql`](../supabase/diagnostics/preflight_rutas_vps.sql)
- [`Guía de ejecución en el VPS`](preflight-rutas-vps.md)

**Puerta de salida:** conocer tablas, columnas, constraints, funciones, vistas,
policies, grants e índices realmente desplegados para Rutas.

### Fase 1 — Dominio remoto, propiedad y valoraciones — EN ESPERA DE DESPLIEGUE

- [x] Crear una migración nueva; no editar migraciones anteriores.
- [x] Consolidar policies de `ruta` para creador y lectura pública.
- [x] Consolidar policies de `ruta_parada` basadas en el propietario de Ruta.
- [x] Impedir cambio de `usuario_creador_id`.
- [x] Validar mínimo dos paradas antes de publicar.
- [x] Validar orden único y Lugares activos.
- [x] Crear `ruta_valoracion` con PK `(ruta_id, usuario_id)`.
- [x] Crear índices de claves foráneas y columnas usadas por RLS.
- [x] Aplicar CHECK de puntuación entre 1 y 5.
- [x] Impedir que el creador valore su propia Ruta.
- [x] Exponer promedio y cantidad sin N+1.
- [x] Mantener vistas como `security_invoker`.
- [x] Limitar grants al mínimo necesario.
- [x] Crear pruebas SQL para propietario, tercero y anónimo.
- [x] Reconstruir localmente todo el historial con la migración nueva.
- [x] Ejecutar 22 pruebas pgTAP de seguridad y comportamiento.
- [x] Ejecutar lint sobre las funciones nuevas y advisors de Rutas.
- [ ] Propietario aplica la migración en el VPS.
- [ ] Verificar la migración aplicada en el VPS.

**Entregables de la Fase 1:**

- [`Migración incremental`](../supabase/migrations/20260922192604_fase_1_rutas_propiedad_valoraciones.sql)
- [`Pruebas RLS y de dominio`](../supabase/tests/rutas_fase_1_rls_test.sql)
- [`Guía de despliegue`](despliegue-fase-1-rutas.md)

**Puerta de salida:** la base impide modificar una Ruta ajena aunque se llame
directamente a la Data API.

### Fase 2 — Crear Ruta desde Flutter

- [ ] Añadir modelos de escritura separados de los modelos de lectura.
- [ ] Implementar datasource y repositorio reales.
- [ ] Construir formulario en cuatro pasos.
- [ ] Buscar y seleccionar Lugares activos.
- [ ] Reordenar nodos sin editar coordenadas.
- [ ] Guardar borrador de forma atómica.
- [ ] Publicar de forma atómica.
- [ ] Recuperar correctamente errores parciales de Storage.
- [ ] Añadir pruebas de validación del formulario.

**Puerta de salida:** un usuario autenticado crea y publica una Ruta de al menos
dos Lugares sin filas huérfanas ni escrituras parciales.

### Fase 3 — Mis Rutas y edición del propietario

- [ ] Listar borradores, publicadas y archivadas del usuario.
- [ ] Abrir y editar una Ruta propia.
- [ ] Agregar, retirar y reordenar paradas.
- [ ] Incrementar versión y actualizar fecha.
- [ ] Archivar una Ruta propia.
- [ ] Ocultar acciones para terceros.
- [ ] Probar manipulación directa de IDs contra RLS.
- [ ] Documentar que no existe historial de revisiones en el MVP.

**Puerta de salida:** el propietario edita; cualquier tercero recibe cero filas
afectadas o un error seguro.

### Fase 4 — Catálogo público y diseño

- [ ] Recuperar el lenguaje visual del frontend antiguo.
- [ ] Definir filtros respaldados por datos reales.
- [ ] Mostrar estados de carga, error y catálogo vacío.
- [ ] Eliminar métricas simuladas.
- [ ] Mostrar promedio y número real de valoraciones.
- [ ] Crear acción para valorar y cambiar valoración.
- [ ] Mostrar autor y última actualización.
- [ ] Hacer visible el acceso al recorrido.

**Puerta de salida:** el catálogo remoto funciona sin datos locales encubriendo
errores de Supabase.

### Fase 5 — Unificación cartográfica

- [ ] Usar MapLibre en Explora, selección y detalle de Ruta.
- [ ] Centralizar la URL del estilo OpenFreeMap.
- [ ] Retirar el endpoint raster directo de CARTO.
- [ ] Dibujar paradas mediante GeoJSON.
- [ ] Dibujar únicamente trazados reales.
- [ ] Ajustar cámara a todos los nodos.
- [ ] Mostrar ubicación actual de forma opcional.
- [ ] Conservar atribución visible.
- [ ] Probar Android e iOS reales.

**Puerta de salida:** todos los mapas del flujo de Rutas usan la misma pila y no
dibujan caminos falsos.

### Fase 6 — Trazado validado

- [ ] Importar GPX o GeoJSON validado.
- [ ] Convertirlo y guardar `geography(LineString, 4326)`.
- [ ] Calcular distancia desde el trazado.
- [ ] Limitar geometrías excesivas para el cliente móvil.
- [ ] Evaluar Valhalla con caminos urbanos y rurales de Cusco.
- [ ] Generar un trazado candidato entre nodos.
- [ ] Exigir previsualización antes de guardar.
- [ ] Mantener GPX como alternativa cuando OpenStreetMap sea incompleto.

**Puerta de salida:** el trazado mostrado corresponde a un recorrido posible y
no a una línea recta entre Lugares.

### Fase 7 — Integraciones y salida

- [ ] Vincular opcionalmente una Ruta al crear una Salida.
- [ ] Mantener el punto de encuentro independiente.
- [ ] Vincular Publicaciones y experiencias.
- [ ] Verificar Rutas guardadas.
- [ ] Probar Ruta despublicada o archivada.
- [ ] Probar edición con Salidas ya asociadas y documentar limitación.
- [ ] Medir catálogo con al menos 50 Rutas.
- [ ] Ejecutar pruebas Flutter/Dart disponibles.
- [ ] Completar pruebas manuales en dispositivos.
- [ ] Preparar checklist de despliegue y reversión mediante migración posterior.

**Puerta de salida:** el MVP está listo para lanzamiento controlado.

## 7. Fuera del MVP

- Panel web administrativo.
- Aprobación previa de Rutas.
- Reportes y suspensión de usuarios.
- Historial completo y revisiones paralelas de una Ruta publicada.
- Edición de Lugares.
- Navegación giro a giro.
- Seguimiento GPS continuo o compartido.
- Alertas por desviación del recorrido.
- Mapas y Rutas offline.
- Descarga de mapas.
- Tramos con distintos medios de transporte.
- Recomendaciones automáticas o personalizadas.

## 8. Disciplina de migraciones y VPS

- Ninguna migración existente se modifica, renombra o elimina.
- Cada cambio de base de datos se agrega como una migración nueva.
- El nombre/fecha se generará con la CLI disponible antes de escribir SQL.
- Una corrección posterior se entrega como otra migración; no se reescribe la
  ya aplicada.
- El propietario aplica las migraciones al Supabase alojado en el VPS.
- Antes de cada despliegue se entregan precondiciones, SQL, verificación y
  posibles efectos.
- No se incluirá `service_role` en Flutter ni en una futura web pública.
- Toda tabla expuesta tendrá RLS y grants explícitos.
- Las vistas públicas usarán `security_invoker`.
- Toda policy de propietario comparará con `(select auth.uid())` y tendrá
  índices sobre las columnas consultadas.

## 9. Riesgos aceptados en el MVP

1. Una Ruta ofensiva puede quedar pública hasta que exista moderación. Se
   reduce el riesgo exigiendo autenticación, autor visible, estructura mínima y
   datos válidos, pero no se elimina.
2. Las valoraciones reflejan calidad percibida; no detectan por sí solas abuso,
   difamación o contenido peligroso.
3. Una edición del propietario afecta inmediatamente la Ruta pública y puede
   cambiar lo que ven Salidas asociadas. El historial de revisiones será una
   evolución posterior.
4. Una Ruta sin `LineString` ofrece un itinerario de Lugares, no navegación.
5. La calidad del trazado automático dependerá de la cobertura de OpenStreetMap.

## 10. Registro de decisiones

| Fecha | Decisión | Estado |
|---|---|---|
| 2026-09-22 | Usuario autenticado puede crear Rutas | Aprobada |
| 2026-09-22 | Publicación inmediata, sin aprobación administrativa | Aprobada |
| 2026-09-22 | Solo el creador modifica durante el MVP | Aprobada |
| 2026-09-22 | Valoración comunitaria de 1 a 5 | Aprobada |
| 2026-09-22 | Panel web administrativo posterior al MVP | Aprobada |
| 2026-09-22 | Migraciones antiguas son inmutables | Aprobada |
| 2026-09-22 | Ejecución fase por fase con puertas de salida | Aprobada |
