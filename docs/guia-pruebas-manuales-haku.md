# HAKU — Guía de pruebas manuales y casos de uso

**Versión:** 2026-09-16  
**Alcance:** autenticación, navegación, Explora, Lugares, Rutas, Publicaciones,
Comunidades, Salidas y Mensajes.  
**Objetivo:** comprobar cada hilo funcional de inicio a fin sin adivinar qué
está implementado ni confundir una función futura con un error.

Esta es la fuente operativa para el tester. Los documentos `fase-*.md`
conservan contexto histórico y algunas secciones antiguas no describen el
estado final completo.

---

## 1. Cómo usar esta guía

Cada caso tiene un identificador estable. Al ejecutarlo:

1. cambia `[ ]` por `[x]`;
2. reemplaza `PENDIENTE` por `OK`, `FALLO` o `BLOQUEADO`;
3. anota el dispositivo, cuenta y evidencia;
4. si falla, registra el primer paso donde se desvía del resultado esperado;
5. adjunta captura, video o texto exacto del error.

Formato recomendado:

```text
Resultado: FALLO
Cuenta: B
Dispositivo: Android 13
Paso: 3
Esperado: abre el detalle
Observado: queda cargando
Evidencia: captura-023.png
```

Un caso `BLOQUEADO` significa que faltan datos, permisos, infraestructura o
una migración. No equivale automáticamente a un bug de Flutter.

---

## 2. Puerta obligatoria antes de probar

No iniciar las pruebas integrales hasta confirmar estas migraciones:

- [ ] `20260916060000_chat_no_leidos_desde_ingreso.sql`
  - evita contar como no leídos mensajes anteriores al ingreso al chat;
- [ ] `20260916070000_chat_reactivar_salas.sql`
  - permite al responsable reactivar una sala inactiva sin crear duplicados;
- [ ] `20260916080000_salidas_resumen_filtrado.sql`
  - habilita el nuevo RPC de listados generales y filtrados de Salidas.
- [ ] `20260916090000_nickname_publico_unico.sql`
  - normaliza y protege la unicidad global de los nicknames;
- [ ] `20260917010000_privacidad_publicaciones_comunidad.sql`
  - impide que contenido de comunidades privadas aparezca en el feed público;
- [ ] `20260917020000_salidas_listado_indices.sql`
  - añade índices y evita contar todo el historial al filtrar Salidas.
- [ ] `20260917030000_handle_new_user_nickname_seguro.sql`
  - aplica de forma append-only el manejo concurrente seguro de nicknames OAuth.

Si `160800` no está aplicada, la versión actual de Flutter puede mostrar error
al listar Salidas porque ya utiliza el contrato RPC nuevo. Si `160900` no está
aplicada, registro y configuración fallarán al consultar
`nickname_disponible`.

Preflight técnico:

- [ ] La app instala y abre sin pantalla roja.
- [ ] Existe conexión al servidor de HAKU.
- [ ] Las tablas de Realtime requeridas están publicadas.
- [ ] La hora y zona horaria del dispositivo son correctas.
- [ ] Cámara, galería, ubicación e Internet pueden probarse.
- [ ] Se conservaron logs de Flutter durante la sesión.

**Resultado del preflight:** `PENDIENTE`  
**Notas:**

---

## 3. Cuentas y datos necesarios

Preparar como mínimo:

- **Cuenta A:** creador/admin de una comunidad y organizador de una salida.
- **Cuenta B:** miembro aprobado y participante confirmado.
- **Cuenta C:** usuario externo sin membresía ni inscripción.
- **Cuenta D:** usuario pendiente, rechazado o bloqueado.
- Una cuenta creada por correo y contraseña.
- Una cuenta que use Google.
- Una comunidad pública.
- Una comunidad privada.
- Una salida pública con cupos.
- Una salida pública llena.
- Una salida vinculada a comunidad.
- Una ruta publicada con paradas y recorrido.
- Una ruta publicada con paradas pero sin `LineString`.
- Una ruta sin coordenadas disponibles, si existe en catálogo QA.
- Un lugar activo con fotografía.
- Dos dispositivos o dos sesiones simultáneas para Realtime.

Registrar los IDs o nombres usados:

```text
Cuenta A:
Cuenta B:
Cuenta C:
Cuenta D:
Comunidad pública:
Comunidad privada:
Salida pública:
Salida llena:
Ruta con recorrido:
Ruta sin recorrido:
Lugar:
```

---

## 4. Resumen de lo implementado

Actualmente sí está implementado:

- registro e inicio de sesión por correo;
- inicio de sesión nativo con Google;
- restauración y cierre de sesión;
- navegación principal con carga diferida de pestañas;
- catálogo remoto de Lugares y mapa de Explora;
- creación de Lugares;
- lectura de Rutas publicadas, detalle, paradas y mapa;
- creación de Publicaciones con fotografía;
- vinculación de publicaciones con Lugar, Ruta o Comunidad;
- creación y membresía de Comunidades públicas y privadas;
- solicitudes de ingreso y administración básica;
- creación, listado e inscripción de Salidas;
- Salidas vinculadas a Lugar, Ruta o Comunidad;
- chats de Comunidad, Salida y privados contextuales;
- texto, imagen, ubicación, stickers, edición, borrado lógico y reacciones;
- bandeja unificada, búsqueda, filtros y no leídos;
- Realtime, reconciliación y recuperación básica de conexión.

No está implementado todavía:

- editor móvil o panel administrativo de Rutas;
- edición, archivado o moderación de Rutas desde la app;
- edición, transferencia de propiedad o borrado de Comunidades;
- edición o cancelación de Salidas desde su detalle;
- check-in remoto;
- likes y comentarios de Publicaciones;
- video remoto en Publicaciones;
- eliminación de Publicaciones desde la tarjeta del feed;
- audio en chat;
- bloqueo o denuncia de usuarios;
- presencia, “escribiendo…” o última conexión;
- notificaciones push con la app cerrada;
- cifrado de extremo a extremo;
- geocodificación automática pin → distrito;
- edición de Lugares;
- SMTP productivo garantizado para recuperación de contraseña;
- persistencia remota de favoritos de Rutas.

Estos límites deben registrarse como `NO IMPLEMENTADO`, no como fallo.

---

## 5. Navegación principal y sesión

### NAV-01 — Apertura como invitado

- [ ] Ejecutado
  - Pasos: cerrar sesión, cerrar completamente la app y volver a abrir.
  - Esperado: Inicio carga; Explora y Comunidad se pueden consultar; las
    acciones protegidas solicitan iniciar sesión.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### NAV-02 — Carga diferida de pestañas

- [ ] Ejecutado
  - Pasos: abrir la app y observar red/logs; no tocar Explora, Comunidad ni
    Perfil durante cinco segundos.
  - Esperado: no se disparan anticipadamente todos los listados; cada sección
    carga cuando se abre por primera vez.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### NAV-03 — Conservación del estado

- [ ] Ejecutado
  - Pasos: hacer scroll o aplicar un filtro en Explora; cambiar a Comunidad;
    volver a Explora.
  - Esperado: la pestaña ya montada conserva razonablemente su estado y no
    vuelve al inicio sin motivo.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### NAV-04 — Portrait y landscape

- [ ] Ejecutado
  - Pasos: navegar por Inicio, Explora, Comunidad y Perfil; rotar el teléfono.
  - Esperado: barra/riel de navegación correcto; sin overflow, controles
    cortados, contenido duplicado ni reinicio de pantalla.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### NAV-05 — Botón central

- [ ] Ejecutado
  - Pasos: tocar el botón central sin sesión y después con sesión.
  - Esperado: sin sesión abre el gate de autenticación; con sesión abre Nueva
    publicación.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### NAV-06 — Restauración de sesión

- [ ] Ejecutado
  - Pasos: iniciar sesión, cerrar la app desde recientes y abrirla de nuevo.
  - Esperado: conserva la sesión válida y no solicita login por una carrera
    durante la hidratación inicial.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### NAV-07 — Cierre de sesión

- [ ] Ejecutado
  - Pasos: cerrar sesión desde Configuración e intentar publicar, crear,
    unirse, inscribirse o chatear.
  - Esperado: se limpia la identidad anterior y todas las acciones protegidas
    vuelven a exigir autenticación.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 6. Autenticación

### AUTH-01 — Registro válido por correo

- [ ] Ejecutado
  - Pasos: completar nombres, apellidos, nick, correo nuevo, nacionalidad y
    contraseñas iguales.
  - Esperado: crea una sola cuenta, crea/hidrata su perfil y entra a la app.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### AUTH-02 — Validaciones de registro

- [ ] Ejecutado
  - Pasos: probar campos vacíos, correo inválido, nickname menor de 3 o mayor
    de 30, bordes con `_`, espacios/tildes/símbolos, nombre reservado,
    contraseña menor de 6 y contraseñas distintas.
  - Esperado: cada caso se detiene antes de enviar y muestra una explicación
    comprensible; las mayúsculas se convierten a minúsculas.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### AUTH-03 — Correo duplicado

- [ ] Ejecutado
  - Pasos: intentar registrar un correo existente.
  - Esperado: no crea una segunda identidad; ofrece volver al login o recuperar
    acceso.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### AUTH-04 — Login por correo

- [ ] Ejecutado
  - Pasos: probar credenciales válidas y luego contraseña incorrecta.
  - Esperado: la válida inicia sesión; la inválida no filtra información
    técnica ni deja la pantalla bloqueada.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### AUTH-05 — Login con Google

- [ ] Ejecutado
  - Pasos: entrar con Google, cancelar el selector y repetir completando.
  - Esperado: cancelar vuelve de forma segura; completar crea o reutiliza la
    identidad correcta y carga el perfil.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### AUTH-06 — Mismo correo en Google y contraseña

- [ ] Ejecutado
  - Pasos: usar el mismo correo con ambos métodos según el orden permitido.
  - Esperado: no aparecen dos perfiles independientes para una persona.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### AUTH-07 — Catálogo de nacionalidades

- [ ] Ejecutado
  - Pasos: abrir selector, buscar, limpiar búsqueda y simular error de red.
  - Esperado: loading, resultados, vacío y reintento son distinguibles.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### AUTH-08 — Recuperación de contraseña

- [ ] Ejecutado
  - Pasos: ingresar correo inválido y válido.
  - Esperado: valida formato. Si SMTP aún no está contratado/configurado, el
    envío puede quedar bloqueado y debe informarse con claridad.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 7. Explora y Lugares

### EXP-01 — Listado remoto

- [ ] Ejecutado
  - Pasos: abrir Explora y entrar a una provincia con lugares.
  - Esperado: muestra únicamente lugares activos remotos; no mezcla contenido
    de demostración cuando el servidor está configurado.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-02 — Provincia vacía

- [ ] Ejecutado
  - Pasos: abrir una provincia sin lugares.
  - Esperado: estado vacío honesto, sin spinner infinito ni lugares de otra
    provincia.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-03 — Error y reintento

- [ ] Ejecutado
  - Pasos: abrir Explora sin red, restaurar red y tocar Reintentar.
  - Esperado: diferencia error de lista vacía y recupera contenido.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-04 — Filtros

- [ ] Ejecutado
  - Pasos: combinar distrito, temática y actividad; probar una combinación sin
    resultados y limpiar.
  - Esperado: solo aparecen coincidencias; limpiar restaura el catálogo.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-05 — Detalle de Lugar

- [ ] Ejecutado
  - Pasos: abrir una tarjeta y volver.
  - Esperado: muestra foto, ubicación y ficha correctas; volver conserva el
    contexto previo.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-06 — Lugar eliminado o inaccesible

- [ ] Ejecutado
  - Pasos: intentar abrir un ID inexistente o desactivado.
  - Esperado: muestra “no encontrado/no disponible”; no usa datos de otro
    lugar ni produce crash.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-07 — Mapa y pines

- [ ] Ejecutado
  - Pasos: abrir mapa, desplazarlo y tocar varios pines.
  - Esperado: los pines corresponden a lugares reales y abren su detalle.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-08 — Cercanía con GPS

- [ ] Ejecutado
  - Pasos: permitir ubicación y activar “Cerca”.
  - Esperado: consulta un radio aproximado de 50 km y no devuelve todo el
    catálogo como si fuera cercano.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-09 — GPS no disponible

- [ ] Ejecutado
  - Pasos: probar servicio apagado, permiso denegado, denegado permanente y
    timeout.
  - Esperado: cada situación tiene salida clara; el mapa sigue siendo usable.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-10 — Crear Lugar

- [ ] Ejecutado
  - Pasos: con sesión, crear lugar con nombre, provincia/distrito, temática,
    coordenadas y opcionalmente foto.
  - Esperado: valida obligatorios, crea una sola fila y aparece en su provincia.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-11 — Coordenadas inválidas

- [ ] Ejecutado
  - Pasos: intentar latitud fuera de `-90..90`, longitud fuera de `-180..180`
    y punto `0,0`.
  - Esperado: no permite publicar una ubicación inválida o sospechosa.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### EXP-12 — Fallo durante creación

- [ ] Ejecutado
  - Pasos: interrumpir red durante foto, creación o guardado de categorías.
  - Esperado: no aparece un lugar parcialmente visible; el mensaje permite
    comprender si se puede reintentar.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 8. Rutas

### RUT-01 — Categorías del catálogo

- [ ] Ejecutado
  - Pasos: abrir Explora → Rutas y alternar Recomendadas, Cultura y Naturaleza.
  - Esperado: Recomendadas muestra el catálogo general; los otros tabs filtran
    correctamente; no existe “Populares” mientras no haya métrica real.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-02 — Loading, error y vacío

- [ ] Ejecutado
  - Pasos: probar red lenta, sin red y categoría sin resultados.
  - Esperado: loading, error con Reintentar y vacío son estados diferentes.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-03 — Detalle bajo demanda

- [ ] Ejecutado
  - Pasos: abrir una Ruta y observar que llega ficha completa.
  - Esperado: título/resumen aparecen rápido; detalle, paradas y recorrido se
    completan sin duplicar contenido.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-04 — Fallo del detalle

- [ ] Ejecutado
  - Pasos: cortar red después de cargar listado y abrir una Ruta.
  - Esperado: conserva el resumen disponible, informa que no actualizó y ofrece
    Reintentar.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-05 — Mapa con recorrido

- [ ] Ejecutado
  - Pasos: abrir una Ruta con `LineString`.
  - Esperado: dibuja el recorrido real, centra todos los puntos y enumera
    paradas.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-06 — Paradas sin recorrido

- [ ] Ejecutado
  - Pasos: abrir una Ruta con paradas pero sin `LineString`.
  - Esperado: muestra marcadores, pero no inventa una línea uniéndolos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-07 — Ruta sin ubicación

- [ ] Ejecutado
  - Pasos: abrir una Ruta sin paradas ni recorrido.
  - Esperado: muestra “recorrido no disponible”; no intenta acceder al primer
    punto de una lista vacía.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-08 — Selección y copia de ubicación

- [ ] Ejecutado
  - Pasos: tocar distintas paradas y usar Copiar ubicación.
  - Esperado: resalta la parada correcta y copia sus coordenadas.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-09 — Requisitos y advertencias

- [ ] Ejecutado
  - Pasos: abrir una ruta que tenga ambos campos.
  - Esperado: “Antes de ir” y “Ten en cuenta” aparecen separados y legibles.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-10 — Acciones flotantes

- [ ] Ejecutado
  - Pasos: abrir/cerrar el menú y ejecutar Compartir, Publicar experiencia,
    Mapa y Salidas.
  - Esperado: cada acción tiene texto visible, una sola interpretación y vuelve
    al contexto correcto.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-11 — Favorito

- [ ] Ejecutado
  - Pasos: guardar/quitar favorito, cambiar de pestaña y reiniciar app.
  - Esperado actual: requiere sesión y persiste localmente en el dispositivo.
    No se espera sincronización entre cuentas o dispositivos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-12 — Ruta despublicada

- [ ] Ejecutado
  - Pasos: seleccionar una Ruta para una Salida y despublicarla antes de
    confirmar.
  - Esperado: conserva visualmente la selección para informar el problema, pero
    no permite crear la Salida con una Ruta ya no publicada.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### RUT-13 — Rendimiento de catálogo

- [ ] Ejecutado
  - Pasos: probar con aproximadamente 50 Rutas y abrir varias fichas.
  - Esperado: listado fluido, imágenes contenidas en caché y detalle sin
    consultas por cada tarjeta.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 9. Publicaciones

### PUB-01 — Crear desde botón central

- [ ] Ejecutado
  - Pasos: iniciar sesión, tocar botón central, elegir foto, descripción y
    destino; Publicar.
  - Esperado: crea una sola publicación y navega a Comunidad → Para ti.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-02 — Foto obligatoria en UI principal

- [ ] Ejecutado
  - Pasos: intentar avanzar/publicar sin foto.
  - Esperado: solicita una imagen; video remoto no aparece como opción activa.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-03 — Descripción y longitud

- [ ] Ejecutado
  - Pasos: publicar texto normal, vacío si la UI lo permite, y más de 4000
    caracteres.
  - Esperado: respeta el límite y no envía contenido inválido.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-04 — Publicar desde Lugar

- [ ] Ejecutado
  - Pasos: desde una ficha de Lugar tocar Publicar experiencia.
  - Esperado: el destino correcto aparece precargado; al terminar vuelve al
    detalle anterior y el recuerdo/experiencia aparece tras actualizar.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-05 — Publicar desde Ruta

- [ ] Ejecutado
  - Pasos: desde Ruta tocar Publicar experiencia.
  - Esperado: la Ruta queda visible y bloqueada como destino; no se reemplaza
    accidentalmente por un Lugar; la descripción inicia vacía.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-06 — Etiquetar Comunidad

- [ ] Ejecutado
  - Pasos: abrir Más opciones y elegir comunidad.
  - Esperado: solo ofrece comunidades donde la cuenta tiene acceso válido.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-07 — Compensación de imagen

- [ ] Ejecutado
  - Pasos: provocar fallo de creación después de subir la foto.
  - Esperado: no queda publicación parcial y la imagen recién subida se elimina
    del Storage.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-08 — Feed remoto

- [ ] Ejecutado
  - Pasos: abrir Para ti con datos, vacío, red lenta y sin red.
  - Esperado: tarjetas reales; loading, error con reintento y vacío honestos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### PUB-09 — Enlaces de tarjeta

- [ ] Ejecutado
  - Pasos: abrir Lugar o Comunidad desde una publicación que los tenga.
  - Esperado: navega al detalle correcto y volver conserva el feed.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 10. Comunidades

### COM-01 — Crear Comunidad pública

- [ ] Ejecutado
  - Pasos: con Cuenta A crear nombre, tipo Pública, descripción y foto
    opcionales.
  - Esperado: comunidad y miembro administrador nacen en una sola operación;
    abre detalle como administrador.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-02 — Crear Comunidad privada

- [ ] Ejecutado
  - Pasos: repetir el caso anterior seleccionando Privada.
  - Esperado: la ficha explica que solo personas aprobadas acceden.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-03 — Validación y fallo de creación

- [ ] Ejecutado
  - Pasos: probar nombre vacío y cortar red tras subir portada.
  - Esperado: no crea entidad parcial; si la creación falla, elimina la portada
    subida como compensación.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-04 — Unirse a Comunidad pública

- [ ] Ejecutado
  - Pasos: Cuenta C abre una pública y toca Unirme.
  - Esperado: queda aprobada inmediatamente; aumenta conteo y puede ver
    contenido reservado permitido.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-05 — Solicitar ingreso a privada

- [ ] Ejecutado
  - Pasos: Cuenta C abre una privada accesible por enlace/listado permitido y
    toca Unirme.
  - Esperado: estado Pendiente; no obtiene miembros reservados ni chat.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-06 — Cancelar solicitud

- [ ] Ejecutado
  - Pasos: con solicitud pendiente tocar Cancelar solicitud.
  - Esperado: pide confirmación y elimina/cancela el estado pendiente.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-07 — Aprobar solicitud

- [ ] Ejecutado
  - Pasos: Cuenta A abre Solicitudes y aprueba a Cuenta C.
  - Esperado: C pasa a Miembro; aparece en lista y obtiene permisos de
    membresía, pero no necesariamente entra automáticamente al roster del chat.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-08 — Rechazar solicitud

- [ ] Ejecutado
  - Pasos: Cuenta A rechaza una solicitud.
  - Esperado: pide confirmación; desaparece de pendientes; el usuario no
    obtiene acceso. Un rechazado puede volver a solicitar.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-09 — Usuario bloqueado

- [ ] Ejecutado
  - Pasos: intentar reingresar con estado bloqueado.
  - Esperado: el backend lo rechaza y la UI no lo muestra como miembro.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-10 — Salir de Comunidad

- [ ] Ejecutado
  - Pasos: Cuenta B toca Salir de la comunidad.
  - Esperado: pide confirmación; pierde membresía y acceso al chat. Si era
    privada, vuelve atrás porque ya no puede ver el detalle.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-11 — Creador no puede salir

- [ ] Ejecutado
  - Pasos: Cuenta A abre su comunidad.
  - Esperado: no aparece una acción inválida de salida; muestra que administra
    la comunidad.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-12 — Privacidad por ID

- [ ] Ejecutado
  - Pasos: Cuenta C intenta abrir directamente el ID de una privada sin acceso.
  - Esperado: no obtiene miembros, solicitudes, chat ni datos reservados.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### COM-13 — Estados de miembros y solicitudes

- [ ] Ejecutado
  - Pasos: simular loading, error y lista vacía en ambas secciones.
  - Esperado: error no se presenta como “no hay miembros”; existe Reintentar.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 11. Salidas

### SAL-01 — Crear Salida pública

- [ ] Ejecutado
  - Pasos: Cuenta A elige nombre, Lugar, fecha/hora futura, cupos y mínimo.
  - Esperado: crea Salida y confirma al organizador atómicamente; abre detalle.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-02 — Crear desde Ruta

- [ ] Ejecutado
  - Pasos: Ruta → Ver u organizar salidas → Crear salida.
  - Esperado: Ruta llega preseleccionada; Lugar de encuentro y fecha siguen
    siendo decisiones propias de la Salida.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-03 — Crear para Comunidad

- [ ] Ejecutado
  - Pasos: activar Salida de comunidad y seleccionar una comunidad válida.
  - Esperado: solo ofrece comunidades donde la cuenta es miembro aprobado o
    admin; la Salida queda restringida a esa comunidad.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-04 — Validaciones de formulario

- [ ] Ejecutado
  - Pasos: título vacío, Lugar ausente, fecha pasada, cupos cero, mínimo cero y
    mínimo mayor a cupos.
  - Esperado: impide guardar y explica el campo incorrecto.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-05 — Catálogos no disponibles

- [ ] Ejecutado
  - Pasos: cortar red al cargar Lugares, Rutas o Comunidades; restaurar y
    reintentar.
  - Esperado: error no se confunde con catálogo vacío y la selección previa no
    se pierde silenciosamente.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-06 — Listado general

- [ ] Ejecutado
  - Pasos: abrir Comunidad → Salidas.
  - Esperado: usa resumen liviano; muestra conteos correctos sin descargar
    todos los IDs de participantes.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-07 — Listados filtrados

- [ ] Ejecutado
  - Pasos: abrir Salidas desde Lugar, Ruta y Comunidad.
  - Esperado: cada lista contiene solo su relación; un ID inválido no devuelve
    accidentalmente el listado global.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-08 — Visibilidad pública y de Comunidad

- [ ] Ejecutado
  - Pasos: comparar Cuentas B y C.
  - Esperado: ambas ven Salidas públicas activas; solo miembros aprobados/admin
    ven las restringidas a Comunidad.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-09 — Inscribirse

- [ ] Ejecutado
  - Pasos: Cuenta B abre una programada con cupos y toca Inscribirme.
  - Esperado: queda Confirmado una sola vez y aumenta el conteo.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-10 — Cancelar y reinscribirse

- [ ] Ejecutado
  - Pasos: cancelar con confirmación y luego volver a inscribirse.
  - Esperado: reutiliza la participación existente; no falla por clave
    duplicada; conteo baja y vuelve a subir.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-11 — Cupo concurrente

- [ ] Ejecutado
  - Pasos: dejar un cupo y confirmar simultáneamente desde B y C.
  - Esperado: solo una inscripción termina confirmada; nunca excede cupos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-12 — Salida llena

- [ ] Ejecutado
  - Pasos: Cuenta C abre una Salida llena.
  - Esperado: muestra Sin cupos y no ofrece una inscripción imposible.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-13 — Organizador

- [ ] Ejecutado
  - Pasos: Cuenta A abre su propia Salida.
  - Esperado: muestra “Organizas esta salida”; no ofrece cancelar su propia
    inscripción.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-14 — Estados de Salida

- [ ] Ejecutado
  - Pasos: abrir programada, en curso, finalizada y cancelada.
  - Esperado: etiquetas legibles; inscripción solo disponible en programada.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### SAL-15 — Enlaces del detalle

- [ ] Ejecutado
  - Pasos: abrir Lugar, Ruta y Comunidad asociados.
  - Esperado: cada enlace lleva a la entidad correcta y volver conserva la
    Salida.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 12. Chat de Comunidad y Salida

### CHAT-01 — Crear chat de Comunidad con todos

- [ ] Ejecutado
  - Pasos: admin abre chat inexistente, elige incluir aprobados y confirma.
  - Esperado: crea una sola sala y agrega únicamente miembros aprobados.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-02 — Crear chat de Comunidad selectivo

- [ ] Ejecutado
  - Pasos: elegir manualmente participantes.
  - Esperado: solo seleccionados entran; creación y roster son atómicos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-03 — Cancelar creación

- [ ] Ejecutado
  - Pasos: iniciar creación y volver sin confirmar.
  - Esperado: no queda sala vacía ni preview fantasma.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-04 — Crear chat de Salida

- [ ] Ejecutado
  - Pasos: organizador repite creación total y selectiva.
  - Esperado: candidatos limitados a organizador y confirmados.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-05 — Miembro sin roster

- [ ] Ejecutado
  - Pasos: miembro aprobado/confirmado, pero no agregado al chat, intenta
    abrirlo.
  - Esperado: no entra; recibe explicación para solicitar acceso al
    admin/organizador.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-06 — Gestionar roster

- [ ] Ejecutado
  - Pasos: responsable agrega y retira participantes.
  - Esperado: solo candidatos válidos; responsable no puede retirarse; quitar
    del chat no quita membresía ni inscripción.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-07 — Pérdida de elegibilidad

- [ ] Ejecutado
  - Pasos: con chat abierto, sacar a B de Comunidad o cancelar su participación.
  - Esperado: se revoca su roster; deja de leer/enviar y desaparece de la
    bandeja como máximo tras la reconciliación.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-08 — Reactivar sala

- [ ] Ejecutado
  - Pasos: desactivar una sala QA de entidad aún activa; abrir como responsable.
  - Esperado: admin/organizador la reactiva y repuebla; miembro común no puede
    reactivarla; no se crea una segunda sala.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-09 — Historial inicial y paginación

- [ ] Ejecutado
  - Pasos: usar chat con más de 40 mensajes y desplazarse al inicio.
  - Esperado: carga últimos 40 y luego páginas anteriores sin duplicados,
    huecos ni reordenamientos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-10 — Mensaje durante carga inicial

- [ ] Ejecutado
  - Pasos: B envía justo mientras A abre el chat.
  - Esperado: el mensaje no se pierde entre historial y suscripción Realtime.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-11 — Texto

- [ ] Ejecutado
  - Pasos: enviar texto normal, espacios, vacío y más de 2000 caracteres.
  - Esperado: recorta espacios; impide vacío/exceso; mensaje válido aparece una
    vez en ambos dispositivos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-12 — Imagen privada

- [ ] Ejecutado
  - Pasos: enviar desde cámara y galería; abrir en el otro dispositivo.
  - Esperado: carga con URL firmada; un tercero sin sala no puede leerla; fallo
    de mensaje elimina la subida nueva.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-13 — Ubicación

- [ ] Ejecutado
  - Pasos: permitir GPS y enviar; repetir con permisos denegados/timeout.
  - Esperado: ubicación válida se muestra; errores no bloquean el compositor.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-14 — Sticker

- [ ] Ejecutado
  - Pasos: enviar varios stickers.
  - Esperado: solo acepta IDs del pack y se renderizan igual en ambos equipos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-15 — Editar mensaje

- [ ] Ejecutado
  - Pasos: autor edita texto propio; otro usuario intenta editarlo.
  - Esperado: solo autor y solo texto vivo; cambio converge por Realtime.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-16 — Eliminar mensaje

- [ ] Ejecutado
  - Pasos: autor elimina y otro intenta eliminar.
  - Esperado: borrado lógico, placeholder “Mensaje eliminado”, sin
    restauración ni cambio de autor/fecha.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-17 — Reacciones

- [ ] Ejecutado
  - Pasos: reaccionar, tocar el mismo emoji y cambiar a otro.
  - Esperado: mismo emoji elimina; otro reemplaza; máximo una reacción por
    usuario y mensaje.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### CHAT-18 — Caída y recuperación de Realtime

- [ ] Ejecutado
  - Pasos: abrir chat, cortar red, enviar desde el segundo equipo, restaurar.
  - Esperado: informa interrupción, reintenta y reconcilia historial sin perder
    mensajes.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 13. Chat privado contextual

### DM-01 — Abrir perfil desde mensaje

- [ ] Ejecutado
  - Pasos: tocar el nombre de otra persona en un chat grupal.
  - Esperado: abre perfil básico real con foto, nombre, nick, contexto y
    Mensaje privado.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-02 — Abrir perfil desde participantes

- [ ] Ejecutado
  - Pasos: abrir roster y tocar participante ya incluido.
  - Esperado: abre el mismo perfil contextual.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-03 — Crear conversación privada

- [ ] Ejecutado
  - Pasos: A inicia mensaje privado a B desde sala compartida.
  - Esperado: crea exactamente una sala entre ambos y abre el chat.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-04 — Idempotencia A→B y B→A

- [ ] Ejecutado
  - Pasos: B intenta iniciar conversación con A desde el mismo contexto.
  - Esperado: abre la sala existente; no crea duplicado.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-05 — Autochat prohibido

- [ ] Ejecutado
  - Pasos: intentar abrir mensaje privado sobre el propio usuario.
  - Esperado: la acción no aparece o el backend la rechaza sin crear sala.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-06 — Usuario fuera del roster

- [ ] Ejecutado
  - Pasos: intentar DM con candidato que aún no está agregado al chat.
  - Esperado: debe agregarse y guardarse primero; no se crea relación privada.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-07 — Sin contexto compartido

- [ ] Ejecutado
  - Pasos: Cuenta C intenta crear DM con B sin compartir roster.
  - Esperado: rechazado por autorización.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-08 — Perfil general

- [ ] Ejecutado
  - Pasos: desde perfil general intentar escribir a alguien.
  - Esperado: solo reabre un DM ya existente; no crea uno arbitrario.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-09 — Privado vacío en bandeja

- [ ] Ejecutado
  - Pasos: crear DM y volver antes de enviar.
  - Esperado: aparece en filtro Privados y cualquiera puede enviar el primero.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### DM-10 — Navegación de regreso

- [ ] Ejecutado
  - Pasos: grupo → perfil → privado → atrás → atrás.
  - Esperado: vuelve a perfil y después al grupo sin duplicar pantallas.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 14. Bandeja y no leídos

### BAN-01 — Tipos y filtros

- [ ] Ejecutado
  - Pasos: probar Todos, Comunidades, Salidas y Privados.
  - Esperado: cada preview aparece en el filtro correcto.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### BAN-02 — Búsqueda

- [ ] Ejecutado
  - Pasos: buscar por título existente, parcial y ausente.
  - Esperado: filtra sin alterar los datos; vacío explica que no hubo
    coincidencias.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### BAN-03 — Último mensaje

- [ ] Ejecutado
  - Pasos: enviar, editar y eliminar el último mensaje.
  - Esperado: preview se actualiza y ordena por actividad reciente.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### BAN-04 — Conteo de no leídos

- [ ] Ejecutado
  - Pasos: con A fuera del chat, B envía tres mensajes; A abre la bandeja y
    después la conversación.
  - Esperado: badge muestra 3 y vuelve a 0 al abrir/marcar leído.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### BAN-05 — Ingreso tardío

- [ ] Ejecutado
  - Pasos: crear historial, agregar después a Cuenta C y abrir su bandeja.
  - Esperado: mensajes anteriores a `fecha_ingreso` no cuentan como no leídos.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### BAN-06 — Actualización Realtime

- [ ] Ejecutado
  - Pasos: mantener bandeja de A abierta y enviar desde B.
  - Esperado: preview, orden y no leídos cambian sin reabrir pestaña.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### BAN-07 — Expulsión con bandeja abierta

- [ ] Ejecutado
  - Pasos: mantener bandeja de B abierta y retirarlo del roster desde A.
  - Esperado: desaparece por Realtime o, como máximo, en la reconciliación de
    30 segundos; no puede volver a abrir.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 15. Pruebas transversales de errores y rendimiento

### X-01 — Doble toque

- [ ] Ejecutado
  - Pasos: tocar rápidamente dos veces Crear, Publicar, Unirme, Inscribirme y
    Enviar.
  - Esperado: una sola operación; sin filas, pantallas o mensajes duplicados.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### X-02 — Volver durante una operación

- [ ] Ejecutado
  - Pasos: iniciar subida/creación y presionar atrás.
  - Esperado: no usa un `BuildContext` destruido, no muestra pantalla roja y el
    resultado queda consistente.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### X-03 — Cambio de cuenta

- [ ] Ejecutado
  - Pasos: cargar datos con A, cerrar sesión y entrar con C.
  - Esperado: no conserva membresías, chats, solicitudes ni permisos de A.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### X-04 — Red lenta

- [ ] Ejecutado
  - Pasos: limitar red y recorrer listados/detalles.
  - Esperado: indicadores acotados, sin parpadeos permanentes ni múltiples
    peticiones equivalentes.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### X-05 — Red interrumpida

- [ ] Ejecutado
  - Pasos: cortar y restaurar red en cada flujo principal.
  - Esperado: mensaje humano, opción de reintento y ausencia de datos parciales.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### X-06 — Responsive

- [ ] Ejecutado
  - Pasos: probar teléfono pequeño, teléfono grande y landscape.
  - Esperado: textos legibles, contenido centrado en pantallas anchas, sin
    botones fuera del área segura ni tarjetas deformadas.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### X-07 — Rendimiento esperado

- [ ] Ejecutado
  - Pasos: medir apertura de Comunidad, Salidas, Rutas y bandeja con pocos
    registros y luego con volumen QA.
  - Esperado: pocos registros deben cargar casi inmediatamente; no aparecen
    consultas por cada tarjeta o roster completo en listados.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

### X-08 — Acceso directo no autorizado

- [ ] Ejecutado
  - Pasos: intentar IDs de Comunidad, Salida, sala y publicación con Cuenta C.
  - Esperado: RLS/RPC impide datos reservados aunque Flutter no oculte el botón.
  - Resultado: `PENDIENTE`
  - Evidencia/notas:

---

## 16. Comportamientos actuales que requieren decisión de producto

No son necesariamente bugs, pero deben evaluarse durante el tester:

- Las coordenadas exactas y el punto de encuentro de Salidas públicas siguen el
  contrato público actual. Antes de producción se debe decidir si solo los
  inscritos verán la ubicación exacta.
- Favoritos de Rutas son locales; no se sincronizan.
- El botón superior de compartir Ruta puede ser menos funcional que la acción
  del menú que copia información.
- El catálogo de Rutas tiene límite fijo y todavía no pagina.
- Las tarjetas de Publicación no muestran una acción visible para abrir la Ruta
  asociada.
- El datasource permite borrado lógico de Publicación propia, pero el feed no
  ofrece la acción.
- Crear Lugar sube la portada antes del alta; debe revisarse la compensación de
  Storage ante fallo.
- Ser miembro/inscrito no implica entrar automáticamente al chat; el modelo
  actual exige roster explícito del responsable.
- Un moderador no equivale automáticamente a administrador.

Registrar decisiones:

```text
1.
2.
3.
```

---

## 17. Mejoras futuras sugeridas

### Prioridad alta

- Definir privacidad del punto exacto de encuentro.
- Añadir pruebas automatizadas de contrato para RPC de chat y Salidas.
- Añadir edición/cancelación segura de Salidas.
- Añadir compensación verificable de Storage al crear Lugar.
- Incorporar observabilidad de tiempos, errores y reconexiones Realtime.
- Crear panel administrativo para gestionar Lugares y Rutas.

### Prioridad media

- Paginación remota de Rutas, Publicaciones y listados grandes.
- Favoritos de Rutas sincronizados por usuario.
- Gestión de Publicaciones propias: editar/eliminar.
- Enlace visible Ruta ↔ Publicación.
- Notificaciones push para mensajes y cambios de Salida.
- Bloqueo, denuncia y moderación de usuarios/contenido.
- Edición de Comunidad y transferencia de propiedad.

### Prioridad posterior

- Presencia y “escribiendo…”.
- Audio en chat.
- Video en Publicaciones.
- Likes y comentarios.
- Check-in GPS con modelo propio.
- Geocodificación automática del distrito.
- Cifrado de extremo a extremo si el producto lo exige.
- Soporte y validación completa para iOS.

---

## 18. Criterio final para cerrar el tester

El corte puede considerarse aprobado cuando:

- [ ] las migraciones requeridas están aplicadas;
- [ ] no hay casos críticos con `FALLO`;
- [ ] autenticación y cambio de cuenta no filtran estado;
- [ ] RLS rechaza accesos directos no autorizados;
- [ ] creación de Comunidad, Salida y Publicación no deja datos parciales;
- [ ] los cupos resisten inscripción concurrente;
- [ ] historial y Realtime no pierden ni duplican mensajes;
- [ ] no leídos respetan la fecha de ingreso;
- [ ] expulsión o pérdida de membresía revoca chat;
- [ ] los listados no confunden error con vacío;
- [ ] no existen crashes, pantallas rojas ni navegación con contexto destruido;
- [ ] portrait y landscape son utilizables;
- [ ] todo fallo reproducible tiene evidencia y caso asociado.

Resumen del ciclo:

```text
Casos OK:
Casos con FALLO:
Casos BLOQUEADOS:
Casos NO IMPLEMENTADOS:
Fecha:
Tester:
Versión APK:
Conclusión:
```

