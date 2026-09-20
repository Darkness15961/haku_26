# Arquitectura de Limpieza de Medios (Patrón Outbox)
**Fecha de Implementación:** Septiembre 2026
**Módulo:** Gestión Multimedia de Publicaciones (S3 & BunnyStream)

Este documento detalla la arquitectura implementada para solucionar el problema de los "medios huérfanos" (archivos que ocupaban espacio en los servidores S3 o BunnyCDN a pesar de que el usuario ya había borrado la publicación original o reemplazado el video/foto).

---

## 1. El Problema Original
Cuando un usuario eliminaba una publicación (Soft-Delete) o editaba su publicación reemplazando una foto por un video nuevo, el registro en la base de datos se borraba o actualizaba, pero el archivo físico de varios Megabytes se quedaba almacenado para siempre en el servidor. 
No se podía borrar de forma sincrónica desde la app móvil porque:
1. Si fallaba la conexión del usuario, el archivo quedaba huérfano.
2. La Edge Function `bunny_ticket` bloqueaba subidas si la publicación ya tenía un adjunto.

---

## 2. La Solución: El Patrón "Outbox"
Implementamos un patrón asíncrono compuesto por 4 capas que funcionan de forma completamente autónoma, garantizando que todo archivo descartado sea eliminado físicamente del servidor sin importar si la app del usuario se cierra o pierde internet.

### Capa 1: La Cola de Basura (Base de Datos)
Se creó la tabla `cola_limpieza_media`. Esta tabla **no tiene llaves foráneas** (está aislada a propósito). 
Su objetivo es actuar como un "Cesto de Basura". Solo guarda:
- `url_archivo` (o el ID del video).
- `proveedor` (`s3` para fotos, `bunny` para videos).
- `intentos` (para reintentar si falla).

### Capa 2: Los Triggers de Captura (Postgres)
Se implementaron dos Triggers en Postgres que actúan como "Detectores de basura":

1. **`trg_publicacion_multimedia_outbox`:**
   - **Evento:** `AFTER DELETE ON publicacion_multimedia`
   - **Acción:** Cada vez que una fila multimedia es borrada, toma el `url_archivo` y lo mete a la `cola_limpieza_media`.

2. **`trg_publicacion_soft_delete_media`:**
   - **Evento:** `AFTER UPDATE ON publicacion`
   - **Acción:** Si el `estado` de una publicación cambia a `'eliminado'`, hace un `DELETE` sobre sus filas en `publicacion_multimedia`. (Al hacer este DELETE, se dispara automáticamente el primer trigger en cascada, enviando todo a la basura).

### Capa 3: El Trabajador Asíncrono (Edge Function)
Se creó la Edge Function `limpiador-media`.
- Lee las filas de la `cola_limpieza_media` (máximo 50 por lote para no saturar APIs).
- Según el `proveedor`, se conecta a Supabase Storage (S3) o a BunnyCDN a través de su API y ejecuta un borrado físico (`HTTP DELETE`).
- Si el borrado es exitoso (o si el proveedor devuelve un 404 porque ya no existe), borra la fila de la cola.
- Si falla por problemas de conexión, incrementa los `intentos` para probar más tarde.

### Capa 4: El Despertador (PG Cron)
Se configuró una tarea programada usando las extensiones `pg_cron` y `pg_net` de Supabase.
- **Job:** `limpiador-media-cron`
- **Frecuencia:** Cada 1 hora.
- **Acción:** Realiza una petición `HTTP POST` interna hacia la Edge Function `limpiador-media` para despertarla y obligarla a limpiar la cola.

---

## 3. Implementación en Flutter (App Móvil)
Para conectar la app a esta nueva arquitectura sin tocar la Edge Function original (`bunny_ticket`), se actualizó `pantalla_editar_publicacion.dart`.

### Lógica de Reemplazo
Cuando el usuario edita una publicación para cambiar un video:
1. Flutter ejecuta el borrado (`eliminarImagenActual: true`) del video anterior en la base de datos.
2. Esto dispara los Triggers, que mandan el video viejo al basurero (`cola_limpieza_media`).
3. Posteriormente, Flutter llama a `bunny_ticket` para subir el nuevo video. Como la base de datos ya está vacía de multimedia para ese post, `bunny_ticket` aprueba la subida sin problemas.

### Corrección Crítica (Bug de Mantenimiento de Media)
Se parcheó una vulnerabilidad crítica: Si el usuario editaba solo el texto y mantenía el video intacto, se configuró para que el guardado mande `nuevaImagenUrl: null` y `eliminarImagenActual: false`. Así, se evita que Flutter intente sobrescribir la fila multimedia vieja por error, garantizando la integridad del ID de BunnyCDN.

---

## Conclusión
La limpieza de medios es ahora un proceso 100% resiliente y en segundo plano. La app es más rápida ya que no tiene que esperar a borrar archivos en la nube antes de avanzar, delegando esa responsabilidad a los servidores de Supabase de manera diferida.
