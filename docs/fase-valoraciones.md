# HAKU — Fase Valoraciones (Rutas y Lugares)

Documento vivo. Objetivo: Implementar un sistema de calificación de 1 a 5 estrellas para las Rutas y Lugares, permitiendo a la comunidad valorar la calidad de las experiencias turísticas y mostrando un promedio global.

---

## Principios de Diseño

| Entidad | Funcionalidad | Motivo |
|---------|---------------|--------|
| **Rutas y Lugares** | Valoración (1 a 5 estrellas) | Permite medir la calidad y popularidad de los destinos de manera cuantitativa. Ayuda a otros usuarios a tomar decisiones. |
| **Promedio Global** | Visualización en UI | Mostrar un promedio preciso (ej. 4.5) junto a la cantidad total de reseñas (ej. (128)) da confianza al usuario. |
| **Acceso Abierto** | Cualquier usuario puede valorar | Como plataforma orientada a la comunidad y la interacción, las rutas y lugares son de dominio público. Permitimos valoraciones abiertas para incentivar la participación y compartir el conocimiento territorial. (A futuro podríamos añadir una etiqueta de "Explorador verificado" basada en geolocalización o check-ins). |

---

## BLOQUE 1: Base de Datos y Lógica (Backend)

### Etapa 1.1: Migración de Base de Datos
- [ ] Crear migración para las tablas `lugar_valoracion` y `ruta_valoracion`.
- [ ] Campos mínimos: `id`, `lugar_id` / `ruta_id`, `usuario_id`, `puntuacion` (smallint, 1 a 5), `fecha_creacion`.
- [ ] Habilitar **RLS** (Row Level Security):
  - Lectura pública.
  - Inserción/Actualización permitida solo para el propio usuario (cada usuario solo puede tener una valoración activa por entidad, `ON CONFLICT` hace un upsert).
- [ ] Crear funciones (RPC) o triggers para recalcular el **promedio** (`calificacion_promedio`) y el **conteo total** (`cantidad_resenas`) en las tablas principales o vistas, asegurando una lectura rápida sin castigar el rendimiento.

### Etapa 1.2: Modelos (Dart)
- [ ] Asegurarse de que `ModeloLugar` y `ModeloRuta` tengan las propiedades `calificacion` (double) y `cantidadResenas` (int). (Actualmente los modelos ya tienen estas variables, solo hay que poblarlas correctamente desde la BD).
- [ ] Añadir una propiedad `miValoracion` (int?) para saber si el usuario actual ya valoró (de 1 a 5) y reflejarlo en la interfaz de forma optimista.

### Etapa 1.3: DataSources (Supabase)
- [ ] Crear métodos `valorarLugar(String lugarId, int estrellas)` y `valorarRuta(String rutaId, int estrellas)`.
- [ ] Modificar las consultas de lectura (`_selectFicha` y `rutas_publicadas_lista`) para traer el campo de "mi_valoracion" (usando un RPC o Computed Field) y los promedios actualizados.

---

## BLOQUE 2: Interfaz de Usuario (UI)

### Etapa 2.1: Componente Estrellas Interactivas
- [ ] Crear un widget reutilizable `SelectorEstrellas` que permita elegir de 1 a 5 estrellas con retroalimentación háptica y animaciones suaves.
- [ ] Crear un widget de solo lectura `VisualizadorEstrellas` para mostrar el promedio fraccional (ej. estrellas a la mitad si es 4.5).

### Etapa 2.2: Pantallas de Detalle
- [ ] Integrar el `VisualizadorEstrellas` en la cabecera o fila de métricas de `PantallaDetalleRuta` y `PantallaDetalleLugar`.
- [ ] Integrar el `SelectorEstrellas` en una sección "Califica este lugar/ruta" o a través de un modal/bottom sheet cuando el usuario decida calificar.
- [ ] Implementar **Optimistic UI**: Al tocar las estrellas, la UI se actualiza inmediatamente mostrando la nueva calificación del usuario, mientras la petición va al servidor de fondo.
