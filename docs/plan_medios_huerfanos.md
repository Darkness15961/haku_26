# Plan Arquitectónico: Gestión Integral de Medios (S3 y BunnyStream)

Este documento detalla la solución escalable y definitiva para prevenir que
fotos y videos eliminados sigan ocupando espacio y generando costos en Supabase
Storage (S3) y BunnyStream.

El enfoque está adaptado 100% a la realidad de tu infraestructura (VPS
Self-Hosted), garantizando que las tareas de backend (Edge Functions) funcionen
bajo tus condiciones manuales de despliegue.

---

## 🛠️ Lo que ya tenemos avanzado (Checks previos)

- [x] **UI de Edición:** `PantallaEditarPublicacion` creada con precarga de
      datos (texto, imagen, comunidad, lugar) y el espacio listo para el video.
- [x] **Flujo en Flutter (Eliminar):** La app ya ejecuta un _Soft-Delete_
      (`estado = 'eliminado'`) sobre la tabla `publicacion`.
- [x] **Flujo en Flutter (Actualizar):** La app ya gestiona la actualización en
      BD, borrando e insertando nuevos registros en la tabla
      `publicacion_multimedia` si el usuario reemplaza una foto.
- [x] **Botón en UI:** Agregada la opción "Editar publicación" en los 3
      puntitos.

---

## 🏗️ Arquitectura de la Solución (Bandeja de Salida / Outbox)

Como las APIs de S3 y BunnyStream requieren peticiones HTTP, y la aplicación
móvil puede perder conexión o fallar, **sacaremos por completo la
responsabilidad de borrar archivos desde Flutter**. Todo se manejará a través de
una tabla especial llamada **Cola de Limpieza** y una **Edge Function Única**
que actuará como limpiador maestro.

### 🟥 BLOQUE 1: ELIMINAR PUBLICACIÓN (Borrado Total)

**Objetivo:** Si se elimina toda la publicación (pasa a `estado = 'eliminado'`),
TODOS sus archivos multimedia deben enviarse a la papelera.

- [x] **1.1. Trigger SQL (Detector de Eliminación):** Crear un disparador en
      Postgres que "escuche" las actualizaciones en la tabla `publicacion`.
- [x] **1.2. Mover a la Cola:** Cuando el trigger detecte que `estado` pasó a
      `'eliminado'`, extraerá todas las filas vinculadas en
      `publicacion_multimedia` (URLs de fotos y IDs de videos) y las insertará
      automáticamente en la tabla `cola_limpieza_media`.
- [x] **1.3. Desvincular de BD:** El trigger borrará lógicamente o físicamente
      las filas de `publicacion_multimedia` para mantener la base de datos
      limpia.

### 🟦 BLOQUE 2: ACTUALIZAR PUBLICACIÓN (Reemplazo de Archivos)

**Objetivo:** Si el usuario edita la publicación y cambia o quita su foto/video,
ESE único archivo viejo debe mandarse a la papelera.

- [x] **2.1. Trigger SQL (Detector de Reemplazo):** Crear un disparador en
      Postgres directamente sobre la tabla `publicacion_multimedia` que
      reaccione al evento `AFTER DELETE`.
- [x] **2.2. Mover a la Cola Automáticamente:** Como Flutter ya elimina la fila
      vieja cuando el usuario sube una nueva foto, este trigger atrapará
      mágicamente esa fila eliminada (`OLD.url`) y la meterá en la
      `cola_limpieza_media`.

### ⚙️ BLOQUE 3: EL LIMPIADOR MAESTRO (Edge Function Única)

**Objetivo:** La Edge Function leerá la cola y ejecutará el borrado físico
usando peticiones HTTP hacia las APIs de almacenamiento. Usaremos una sola
función para evitar doble coste o choque de procesos.

- [x] **3.1. Escritura de `limpiador-media`:** Te proporcionaré el código fuente
      TypeScript de la Edge Function.
- [x] **3.2. Lógica Interna:** La función leerá hasta 50 URLs de la
      `cola_limpieza_media`. Si identifica un dominio de S3, usará Supabase
      Admin para borrarlo de Storage. Si identifica un ID de Bunny, hará un
      `fetch` hacia su API. Al terminar con éxito, borrará los ítems de la tabla
      cola.
- [x] **3.3. [ACCIÓN TUYA] Subida Manual al VPS:** Tomarás el código de
      `limpiador-media` y lo subirás a tu servidor VPS utilizando el **mismo
      método manual que usaste para activar `bunny_ticket`**.
- [x] **3.4. [ACCIÓN TUYA] Configurar Credenciales:** Añadirás la API Key de
      BunnyStream en el archivo de entorno (`.env`) de tu contenedor de Edge
      Functions.

### ⏱️ BLOQUE 4: AUTOMATIZACIÓN (El Despertador `pg_cron`)

**Objetivo:** El limpiador debe ejecutarse solo sin que nosotros lo llamemos.
Dado que es un VPS, programaremos la base de datos para que invoque la Edge
Function.

- [x] **4.1. Preparación del Script SQL:** Escribiré un pequeño script usando
      `pg_cron` y `pg_net` (extensiones de Supabase).
- [x] **4.2. Funcionamiento:** Este script le dirá a la base de datos: _"Cada 1
      hora, haz una petición HTTP POST local hacia tu propia Edge Function
      `limpiador-media` para despertarla"_.
- [x] **4.3. [ACCIÓN TUYA] Ejecución:** Antes de hacer el `supabase db push`,
      edita la migración y coloca tu URL.
