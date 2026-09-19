# HAKU — Fase Interacciones (Me Gustas y Guardados)

Documento vivo. Objetivo: Implementar el sistema de interacciones adecuado para cada entidad de Haku, asegurando alto rendimiento y una experiencia de usuario lógica. Comenzaremos exclusivamente con los "Me gusta" para las **Publicaciones**.

---

## Principios de Diseño

| Entidad | Interacción Correcta | Motivo |
|---------|----------------------|--------|
| **Publicaciones** | Corazón (Me gusta) | Reacción rápida, fomenta la interacción social en el feed. |
| **Rutas y Lugares**| Guardados (Bookmarks) + Estrellas | Utilidad y planificación personal. Un usuario guarda una montaña para visitarla el fin de semana. |
| **Comunidades** | Unirse / Salir | Es un estado de pertenencia. |
| **Salidas** | Asistiré / Me interesa | Gestión de asistencia a un evento. |

---

## BLOQUE 1: "Me Gusta" en Publicaciones (Fase Actual)

### Etapa 1.1: Base de Datos (Migración)
- [x] Crear nueva migración: `supabase migration new publicacion_me_gusta`.
- [x] Crear tabla `publicacion_me_gusta` con claves foráneas (`ON DELETE CASCADE`) y clave primaria compuesta.
- [x] Habilitar RLS (Row Level Security).
- [x] Crear políticas de Lectura, Inserción y Borrado.
- [ ] Aplicar a la BD remota: `supabase db push`.

### Etapa 1.2: Modelo de Dominio (Dart)
- [x] Añadir a `ModeloPublicacionRemota` los campos `cantidadMeGusta` (int) y `leDiMeGusta` (bool).
- [x] Actualizar la función de parseo `desdeFilaRemota`.

### Etapa 1.3: Adaptación del Backend en la App
- [x] Modificar el string de consulta `_selectFeed` en `PublicacionDataSourceSupabase` para recuperar la cantidad de likes (usando `.count()`) y si el usuario actual le ha dado like.
- [x] Agregar métodos `darMeGusta(String publicacionId)` y `quitarMeGusta(String publicacionId)` en el DataSource y Repositorio.

### Etapa 1.4: Interfaz de Usuario (UI)
- [x] Modificar `TarjetaPublicacionRemota` para incluir el botón de "Me gusta" (ícono de corazón vacío/relleno) y el contador.
- [x] Implementar **Optimistic UI**: Al tocar el botón, la interfaz se actualiza inmediatamente sin esperar al servidor.
- [x] Añadir retroalimentación táctil (háptica) sutil al dar like.

---

## BLOQUE 2: "Guardados" Persistentes (Favoritos)

### Etapa 2.1: Base de Datos (Migración)
- [x] Crear migración con tablas `lugar_guardado`, `ruta_guardada` y `publicacion_guardada`.
- [x] Habilitar RLS y políticas de total privacidad (cada usuario solo ve sus guardados).
- [x] Crear funciones computadas (`lugar_guardado_por_mi`, `ruta_guardada_por_mi`, `publicacion_guardada_por_mi`) para resolver el problema N+1.
- [x] Aplicar a la BD remota: `supabase db push`.

### Etapa 2.2: Capa de Datos (Modelos y DataSources)
- [x] Añadir propiedad `guardadoPorMi` a `ModeloRuta`, `ModeloLugar` y `ModeloPublicacionRemota`.
- [x] Crear métodos de mutación (`guardarX`, `quitarGuardadoX`) en los respectivos DataSources de Supabase.
- [x] Modificar consultas de lectura (Feed y Detalles) para incluir el campo computado.
- [x] Crear métodos de listado (`listarRutasGuardadas`, `listarLugaresGuardados`, `listarPublicacionesGuardadas`).

### Etapa 2.3: Capa UI (Favoritos y Detalles)
- [x] Implementar Optimistic UI (con fallback) en el botón de guardar de `PantallaDetalleRuta` y `PantallaDetalleLugar`.
- [x] Crear componente `_BotonGuardarPub` con Optimistic UI para `TarjetaPublicacionRemota`.
- [x] Crear proveedores remotos (`rutasGuardadasRemotasProvider`, etc.).
- [x] Refactorizar `PantallaFavoritos` para que lea directamente desde Supabase en la nube, reemplazando la simulación local.

---

## BLOQUE 3: Refinamiento de Guardados (Privacidad y Reglas de Negocio)

### Etapa 3.1: Restricción de Botones (UI)
- [x] Modificar `TarjetaPublicacionRemota`: Ocultar el botón de Guardar si el autor de la publicación es el usuario activo.
- [x] Modificar `PantallaDetalleRuta`: Ocultar el icono de Guardar si el autor de la ruta es el usuario activo.
- [x] Modificar `PantallaDetalleLugar`: Ocultar el icono de Guardar si el autor del lugar es el usuario activo.

### Etapa 3.2: Filtrado en Proveedores (Estado)
- [x] Modificar `proveedores_guardados_remotos.dart`: Asegurar que las listas (Rutas, Lugares, Publicaciones) omitan automáticamente cualquier elemento cuyo `usuario_id` coincida con el usuario activo.
