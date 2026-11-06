# Arranque de HAKU

Revisión del 6 de noviembre de 2026. Alcance: apertura nativa, primer frame
Flutter, preparación del cliente y llegada a Inicio.

## Contrato del recorrido

1. Android/iOS presentan un fondo nativo del mismo color que `PaletaRutas.ink`.
   Android 12+ define también el fondo del splash del sistema, en ambos temas.
2. `main` monta `ProviderScope` y `MaterialApp` sin esperar al backend.
3. `PantallaCargaInicial` dibuja la interfaz antes de invocar `preparar` mediante
   `addPostFrameCallback`. La presentación dura al menos 5 segundos por decisión
   de producto; la preparación avanza en paralelo. El contenido es visible desde
   el primer frame y el cargador no aplica su retraso habitual de 250 ms.
4. La finalización correcta de la preparación permite una sola navegación a
   Inicio cuando se cumple también la presentación. Un error inmediato o
   asíncrono muestra un estado de error sin esperar los 5 segundos. El
   reintento vuelve a ejecutar la preparación; no navega saltándose el fallo.
5. `inicializarSupabase` comparte el intento en curso. Solo marca el cliente
   como listo cuando termina la inicialización. Si falla, intenta liberar los
   recursos parciales del SDK antes de permitir otro intento.
6. Inicio monta las pestañas al visitarlas y conserva las ya montadas.
   Su contenido solicita rutas y lugares en paralelo. Observa ambos errores
   desde el comienzo y solo publica datos cuando ambas respuestas llegan.
7. Un fallo de contenido se reintenta desde Inicio invalidando ambas fuentes;
   no requiere volver a ejecutar todo el arranque.

El fondo del splash y el recurso Lottie del cargador son locales. La animación
es una representación de la espera, no una condición para acceder a Inicio.

## Regresiones que deben evitarse

- Añadir esperas acumulativas: la presentación y el backend corren en paralelo.
- Montar consumidores de Supabase antes de completar su preparación.
- Invocar una fábrica de futuros sin capturar también sus errores síncronos.
- Aceptar una instancia parcialmente inicializada después de un fallo de Auth.
- Esperar secuencialmente futuros ya lanzados sin observar los errores de ambos.
- Navegar o actualizar el splash después de desmontarlo.
- Volver a introducir un fondo blanco nativo antes de la interfaz oscura.

Pruebas relacionadas: `test/pantalla_carga_inicial_test.dart`,
`test/inicio_hoy_origen_test.dart`, `test/cargador_haku_test.dart` y
`test/widget_test.dart`.

## Medición en dispositivo pendiente

Las pruebas de widgets verifican el orden y los estados; no miden el tiempo
real desde tocar el icono hasta recibir el primer frame o el contenido remoto.
Para comparar rendimiento, usar el mismo teléfono y una compilación `profile`
o `release`; registrar por separado primer frame, menú visible y contenido
disponible. Repetir aperturas en frío y en caliente, con/sin sesión, red lenta,
sin conexión, rotación y paso a segundo plano durante la preparación.

No hay una cifra nueva de latencia medida. La presentación original de 8,8
segundos se sustituyó por los 5 segundos solicitados. Se eliminó el retraso
adicional de 200 ms para iniciar la preparación. La transición al menú dura
500 ms y el tiempo total depende también de la preparación del backend.

## Capacidad futura

`LugarDataSourceSupabase.listarActivos` no pagina su consulta. El tamaño de esa
respuesta puede crecer con el catálogo. No se cambió por un `limit` arbitrario:
la paginación debe preservar la navegación por categorías, la búsqueda y los
puntos de Explora. Es trabajo de capacidad pendiente, no una incompatibilidad
demostrada del arranque actual.
