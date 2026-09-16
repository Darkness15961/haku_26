# HAKU — Ingeniería del sistema de Mensajes

Documento técnico de la implementación de chat de comunidades, chat de
salidas y chat privado 1:1.

**Estado:** implementado sobre Supabase + Flutter/Riverpod.  
**Última fase:** chat privado contextual + hardening de seguridad y cierres.  
**Fuente de verdad:** `public.sala_chat`, `public.sala_participante` y
`public.mensaje`.

---

## 1. Objetivo y decisiones de producto

Mensajes usa una sola infraestructura para tres clases de conversación:

- **Comunidad:** sala vinculada a una comunidad.
- **Salida:** sala vinculada a una salida organizada.
- **Privado:** sala estable entre exactamente dos usuarios.

El chat privado no es un directorio global abierto. Una conversación nueva
solo puede nacer cuando ambas personas coinciden en el roster de un chat de
comunidad o salida. Una vez creada, la conversación puede reabrirse desde la
bandeja o desde un perfil general.

Se retiró el chat directo local de demostración. No se mezclan mensajes
ficticios o almacenamiento local con conversaciones remotas.

---

## 2. Modelo de datos

### `public.sala_chat`

Representa el contenedor común.

- `id bigint`: identidad de la sala.
- `tipo tipo_sala_chat`: `comunidad`, `salida` o `privado`.
- `comunidad_id bigint nullable`.
- `salida_id bigint nullable`.
- `estado boolean`.
- `fecha_creacion timestamptz`.

La restricción `chk_sala_tipo_coherente` impide combinaciones inválidas:

- comunidad exige `comunidad_id` y prohíbe `salida_id`;
- salida exige `salida_id` y prohíbe `comunidad_id`;
- privado exige ambos vínculos grupales en `NULL`.

Los índices parciales `ux_sala_chat_comunidad` y `ux_sala_chat_salida`
garantizan una sala por entidad.

### `public.sala_participante`

Es el roster efectivo del chat. No equivale necesariamente a la membresía de
la comunidad o a la inscripción de la salida.

- PK: `(sala_id, usuario_id)`.
- `fecha_ingreso`.
- `ultima_lectura`: cursor para no leídos.

La separación es intencional: alguien puede pertenecer a una comunidad o estar
confirmado en una salida, pero el administrador/organizador decide si entra al
chat. Perder la membresía válida sí provoca la baja del roster.

### `public.mensaje`

- pertenece a una `sala_id`;
- `usuario_id` identifica al autor;
- `contenido` contiene texto o payload del adjunto;
- `tipo_mensaje`: texto, imagen, audio, ubicación o sticker;
- `fecha_envio`;
- `editado_en`;
- `eliminado_en`.

El borrado es lógico. La fila permanece para conservar orden y consistencia,
pero el contenido visible se sustituye por “Mensaje eliminado”.

### `public.mensaje_reaccion`

Una reacción por usuario y mensaje:

- PK: `(mensaje_id, usuario_id)`;
- `emoji`;
- `fecha`;
- `sala_id` denormalizado mediante trigger.

`sala_id` permite aplicar RLS y filtros Realtime sin consultas recursivas.

### `public.sala_privada`

Relaciona una sala privada con su pareja:

- `sala_id` PK y FK a `sala_chat`;
- `usuario_a`, `usuario_b`;
- usuarios distintos;
- pareja ordenada y única.

La pareja se normaliza por UUID antes de insertar. Por ello A→B y B→A siempre
resuelven la misma conversación.

La tabla no se expone directamente a clientes autenticados. Se opera mediante
RPCs `SECURITY DEFINER` con validaciones explícitas.

---

## 3. Seguridad y RLS

### Regla central

`public.es_participante_sala(p_sala_id)` comprueba si `auth.uid()` pertenece al
roster. Es `SECURITY DEFINER` para evitar que la policy de
`sala_participante` vuelva a consultar la misma tabla bajo RLS y genere
recursión infinita.

Esta función gobierna:

- lectura de `sala_chat`;
- lectura e inserción de `mensaje`;
- actualización de mensajes propios;
- lectura, alta, cambio y baja de reacciones;
- lectura de participantes de una sala compartida.

Un mensaje nuevo además exige `usuario_id = auth.uid()`. Una edición o borrado
solo puede afectar mensajes del autor autenticado.

Los grants iniciales amplios fueron reducidos a privilegio mínimo:

- `authenticated` no posee `TRUNCATE`, `TRIGGER`, `REFERENCES` ni `MAINTAIN`;
- `sala_chat` y `sala_participante` son de lectura directa;
- los cambios de lectura y contenido pasan por RPC;
- `mensaje` admite SELECT/INSERT, protegido además por trigger;
- reacciones conservan solo las operaciones requeridas por su toggle;
- `public` no permite `CREATE` a roles arbitrarios.

Las policies usan `puede_usar_sala`: además del roster, exige sala activa,
comunidad activa o salida no cancelada.

### Administración del roster

- Comunidad: solo un administrador puede ejecutar el batch de altas/bajas.
- Salida: solo el organizador puede ejecutar el batch.
- Solo se agregan miembros aprobados o participantes confirmados.
- El administrador/organizador no puede eliminarse a sí mismo mediante batch.
- Salir, ser bloqueado o dejar de estar confirmado elimina el acceso al chat.
- Aprobar/confirmar no agrega automáticamente al roster: se conserva el modelo
  híbrido y la decisión explícita del responsable.

### Chat privado

`asegurar_sala_privada(otro_usuario, sala_origen)`:

1. exige sesión;
2. prohíbe hablar consigo mismo;
3. exige que el otro usuario siga activo;
4. devuelve la pareja existente si ya existe;
5. para crear, exige que ambos estén en el roster de la misma sala grupal
   activa indicada como origen;
6. crea la sala `privado`, registra la pareja y agrega exactamente a ambos;
7. usa unicidad y manejo de `unique_violation` para resolver carreras.

Desde perfiles generales se llama sin sala de origen. En ese modo solo puede
reabrir un DM existente; no crea una relación arbitraria.

### Alcance de privacidad

RLS evita que terceros lean o escriban la conversación. La implementación no
es cifrado de extremo a extremo: administradores de infraestructura con acceso
privilegiado a PostgreSQL pueden acceder a los datos.

---

## 4. Creación y apertura de chats grupales

### Comunidad

1. La UI consulta `sala_comunidad_id_si_existe`.
2. Si no existe, solo el admin ve el flujo de creación.
3. El admin elige:
   - incluir aprobados;
   - elegir manualmente.
4. La sala se crea únicamente al confirmar “Crear chat”.
5. Si se cancela o vuelve atrás, no se crea nada.
6. Un miembro no administrador solo abre si ya pertenece al roster.

Cuando el admin elige personas, creación y altas se ejecutan en una sola
transacción mediante `crear_sala_comunidad_con_participantes`. El equivalente
de salida es `crear_sala_salida_con_participantes`; un fallo revierte todo y no
deja una sala parcial.

### Salida

El flujo es equivalente, pero la autoridad es el organizador y los candidatos
son organizador + participantes confirmados.

### Existencia frente a visibilidad

Los RPCs `sala_comunidad_id_si_existe` y `sala_salida_id_si_existe` distinguen:

- la sala no existe;
- la sala existe, pero el usuario no pertenece al roster.

Esto evita interpretar una fila oculta por RLS como una sala inexistente y
crear duplicados o mostrar mensajes incorrectos.

---

## 5. Descubrimiento y creación de un chat privado

Hay dos entradas coherentes desde una sala grupal.

### Desde un mensaje

1. El usuario toca el nombre del autor.
2. No se habilita sobre mensajes propios o eliminados.
3. Se abre `PantallaPerfilParticipanteChat`.
4. El perfil consulta datos reales mínimos de `public.usuario`.
5. “Mensaje privado” llama al RPC con la sala grupal actual como origen.
6. Se abre la conversación única existente o recién creada.

### Desde la lista de participantes

1. El botón superior derecho abre el roster.
2. Un participante efectivo puede tocarse.
3. Se abre el mismo perfil básico.
4. El botón de mensaje ejecuta exactamente el mismo flujo.

En modo de administración:

- tocar un participante ya incluido abre su perfil;
- el checkbox conserva la función de alta/baja;
- un candidato que todavía está fuera del chat debe agregarse y guardarse
  antes de poder iniciar una conversación contextual;
- durante la creación del grupo, las filas solo seleccionan el roster.

### Perfil básico

Muestra exclusivamente:

- foto de perfil;
- nombres y apellidos;
- nick;
- contexto compartido;
- acción de mensaje privado.

No presenta estadísticas o publicaciones ficticias.

---

## 6. Bandeja de Mensajes

`previewsChatBandejaProvider` compone:

- comunidades del usuario;
- salidas organizadas o confirmadas;
- chats privados devueltos por `listar_chats_privados()`.

Cada preview contiene tipo, título, portada/avatar, último mensaje y no leídos.
El orden principal es la fecha del último mensaje.

Filtros disponibles:

- Todos;
- Comunidades;
- Salidas;
- Privados.

La búsqueda filtra por título. Un privado vacío sigue apareciendo después de
crearse, permitiendo que cualquiera de los dos envíe el primer mensaje.

`chatBandejaRealtimeProvider` observa cambios visibles de `mensaje` mientras la
pestaña está abierta e invalida los previews. Así, un mensaje entrante,
edición o borrado actualiza orden, texto y contador sin reabrir la pantalla.

---

## 7. Historial y sincronización

### Carga inicial y paginación

- La carga inicial trae los últimos 40 mensajes.
- La consulta ordena por `(fecha_envio DESC, id DESC)`.
- La UI los invierte para presentarlos cronológicamente.
- Al acercarse al inicio, solicita una página anterior mediante cursor
  compuesto por fecha e ID.
- El cursor compuesto evita saltos cuando dos mensajes comparten timestamp.

### Realtime

Cada conversación crea un canal filtrado por `sala_id`:

- INSERT y UPDATE de `mensaje`;
- INSERT, UPDATE y DELETE de `mensaje_reaccion`.

`REPLICA IDENTITY FULL` permite que los filtros de UPDATE dispongan de las
columnas necesarias.

Los payloads Realtime normalmente no incluyen joins. La fusión conserva el
nick y las reacciones previas cuando el evento entrante no los contiene.
Después de una reacción se recarga únicamente el mensaje afectado.

### Overlay local

Después de enviar, editar o borrar, la UI aplica un parche local para responder
de inmediato. El parche desaparece solo cuando el stream remoto cubre el mismo
contenido y timestamps. Las reacciones nunca se pisan con el overlay del
cuerpo.

---

## 8. Operaciones de mensaje

### Texto

- se recorta;
- no puede estar vacío;
- máximo 2000 caracteres;
- la identidad del autor proviene de la sesión.

### Imagen

- cámara o galería;
- calidad reducida y ancho máximo en cliente;
- bucket privado `haku-chat-privado`;
- ruta Storage: `{uid}/{salaId}/{timestamp}.{ext}`;
- la policy exige que quien sube pertenezca a la sala;
- la base guarda `chat://ruta`, no una URL pública;
- al leer se genera una URL firmada por una hora;
- si falla el INSERT del mensaje, se elimina el objeto como compensación.

Las imágenes antiguas que ya fueron guardadas en el bucket público conservan
su URL histórica; el cierre privado aplica a nuevas subidas.

### Ubicación

- valida servicio GPS;
- solicita permisos;
- diferencia denegado y denegado permanentemente;
- aplica timeout;
- valida latitud/longitud;
- serializa un payload controlado.

### Sticker

Solo acepta IDs incluidos en `PackStickersChat`. El servidor recibe el ID, no
un widget ni contenido ejecutable.

### Edición y borrado

- solo texto vivo puede editarse;
- solo el autor puede cambiarlo;
- la edición pasa por `editar_mensaje_chat`;
- borrar establece `eliminado_en`;
- el borrado pasa por `eliminar_mensaje_chat`;
- sala, autor, fecha y tipo son inmutables;
- un soft-delete no puede restaurarse;
- el trigger redacta el contenido;
- la UI muestra placeholder.

### Reacciones

- pack fijo de emojis;
- pulsar el mismo emoji elimina la reacción;
- pulsar otro la reemplaza;
- la base impide más de una reacción por usuario/mensaje.

---

## 9. No leídos

Al abrir o reanudar una conversación se actualiza
`sala_participante.ultima_lectura`. La escritura pasa por
`marcar_sala_leida`, que usa `now()` de PostgreSQL y no el reloj del teléfono.
Los mensajes recibidos mientras la sala está visible también avanzan la marca.

El conteo considera mensajes:

- de la sala;
- posteriores a `ultima_lectura`;
- escritos por otra persona;
- no eliminados.

Se usa `count(CountOption.exact)` sin descargar todas las filas. Para privados,
`listar_chats_privados()` calcula el mismo contrato dentro del RPC.

---

## 10. Manejo de errores y cierres

- Falta de sesión: se deriva al flujo de autenticación.
- Falta de roster: se informa que admin/organizador debe agregar al usuario.
- Sala aún no creada: se diferencia de falta de acceso.
- Cancelar creación: no deja sala vacía.
- Fallo de historial: no se presenta falsamente como chat vacío.
- Fallo de envío: restaura el texto en el compositor.
- Fallo de perfil: muestra estado no disponible.
- Perfil no remoto o sin relación: no abre chat local ficticio.
- Navegación atrás desde perfil o privado vuelve al punto anterior sin alterar
  la sala grupal.
- Los canales Realtime se eliminan al disponer providers/pantallas.

---

## 11. Archivos principales

Backend:

- `supabase/migrations/20260915094013_remote_schema.sql`
- `supabase/migrations/20260915120000_sala_chat_comunidad_rpc.sql`
- `supabase/migrations/20260915130000_sala_chat_rpc_salida_admin.sql`
- `supabase/migrations/20260915140000_mensaje_edit_reaccion_roster.sql`
- `supabase/migrations/20260915150000_mensaje_tipo_sticker.sql`
- `supabase/migrations/20260915160000_mensaje_replica_identity_full.sql`
- `supabase/migrations/20260915170000_sala_chat_roster_hibrido.sql`
- `supabase/migrations/20260915180000_sala_participante_rls_no_recursion.sql`
- `supabase/migrations/20260915190000_chat_crear_seed_opcional.sql`
- `supabase/migrations/20260915200000_sala_existe_sin_rls.sql`
- `supabase/migrations/20260915210000_chat_privado_uno_a_uno.sql`
- `supabase/migrations/20260915220000_chat_seguridad_cierres.sql`

Flutter:

- `chat_datasource_supabase.dart`: contrato Supabase.
- `proveedor_chat.dart`: historial, Realtime y bandeja.
- `modelo_mensaje_chat.dart`: mensajes, previews y perfil mínimo.
- `pantalla_chat_sala.dart`: conversación y entradas desde autor.
- `pantalla_gestion_participantes_chat.dart`: roster y entrada desde lista.
- `pantalla_perfil_participante_chat.dart`: perfil contextual real.
- `burbuja_mensaje_chat.dart`: presentación e interacción.
- `pantalla_comunidad.dart`: bandeja, búsqueda y filtros.

---

## 12. Verificación

Pruebas automatizadas en `test/chat_modelos_test.dart`:

- normalización del perfil y nick;
- contrato de preview privado;
- conservación de reacciones durante fusión Realtime;
- representación de adjuntos y eliminados.

Comandos:

```bash
dart analyze lib/funcionalidades/chat
flutter test test/chat_modelos_test.dart
```

Matriz manual recomendada con dos cuentas:

1. admin crea comunidad con todos;
2. admin crea comunidad eligiendo;
3. cancelar creación no genera sala;
4. miembro fuera del roster no entra;
5. organizador repite los casos para salida;
6. tocar autor abre perfil;
7. tocar participante abre el mismo perfil;
8. crear DM A→B y luego B→A devuelve la misma sala;
9. tercero sin grupo compartido no puede crear DM;
10. texto, imagen, ubicación y sticker llegan en tiempo real;
11. editar, borrar y reaccionar convergen en ambos dispositivos;
12. no leídos suben fuera del chat y vuelven a cero al abrir;
13. privado aparece y abre desde filtro Privados;
14. atrás desde privado retorna a perfil y luego al grupo.

---

## 13. Límites explícitos de esta fase

No incluidos todavía:

- cifrado de extremo a extremo;
- bloqueo o denuncia de usuarios;
- solicitudes de mensaje separadas;
- notificaciones push con la app cerrada;
- audio, aunque el enum original contempla el tipo;
- presencia en línea y “escribiendo…”;
- sincronización de seguimiento social remoto.

Estos límites no se simulan con datos locales: la UI debe permanecer honesta
hasta que exista su backend.
