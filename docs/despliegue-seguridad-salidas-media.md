# Despliegue seguro de salidas y limpieza de medios

Este procedimiento lleva al Supabase self-hosted los cambios validados de forma
local. No autoriza por sí solo un despliegue y no contiene valores secretos.

## Estado validado localmente

- PostgreSQL local reconstruido desde cero con 93 migraciones incrementales.
- 36 aserciones pgTAP aprobadas, incluidas las identidades `anon`, usuario A,
  usuario B y propietario.
- La Edge Function rechaza solicitudes sin secreto o con secreto incorrecto y
  acepta el secreto dedicado: `401 / 401 / 200`.
- Ningún cliente de prueba conoce ni envía `SUPABASE_SERVICE_ROLE_KEY`.
- El cron obtiene URL y secreto desde Vault; no contiene la URL de producción ni
  una clave `service_role` en su comando.

En esta máquina, el Supabase local usa el puerto de base de datos `54332`. El
puerto `54322` está ocupado por un túnel SSH hacia el VPS y no debe emplearse
para pruebas locales ni cerrarse como parte de este procedimiento.

## Archivos que se despliegan

1. `supabase/functions/limpiador-media/index.ts`
2. `supabase/migrations/20261029032630_seguridad_salidas_y_cron_media.sql`
3. `supabase/migrations/20261029033614_endurecer_helpers_media.sql`

Las migraciones ya aplicadas nunca se editan. Cualquier ajuste posterior debe
ser otra migración incremental.

## Preflight de solo lectura en el VPS

1. Identificar el contenedor PostgreSQL y el contenedor de Edge Runtime del
   `docker compose` real. No asumir sus nombres a partir del entorno local.
2. Crear un backup lógico o snapshot recuperable y verificar que terminó bien.
3. Comparar `supabase_migrations.schema_migrations` contra los nombres locales.
   El servidor debe contener el mismo prefijo histórico; si hay divergencia, se
   detiene el despliegue y se reconcilia antes de aplicar SQL.
4. Ejecutar, dentro de una transacción `READ ONLY`, los scripts:

   - `supabase/diagnostics/auditoria_integral_vps.sql`
   - `supabase/diagnostics/auditoria_cron_vps.sql`
   - `supabase/diagnostics/auditoria_buckets_vps.sql`

5. Guardar la salida sin JWT, contraseñas, secretos de Vault ni claves de API.

## Preparación de secretos

Generar un secreto aleatorio largo para el cron. El mismo valor debe existir en
dos lugares, sin almacenarlo en Git ni escribirlo en logs:

- Edge Runtime: `LIMPIADOR_MEDIA_CRON_SECRET`.
- Vault: secreto con nombre `limpiador_media_cron_secret`.

Vault también debe contener `limpiador_media_function_url`, cuyo valor es la URL
interna o pública correcta de `/functions/v1/limpiador-media` para ese entorno.
Antes de crear nombres duplicados, consultar `vault.secrets` y usar la operación
de actualización disponible en la versión instalada. No usar
`SUPABASE_SERVICE_ROLE_KEY` como secreto del cron.

## Orden de despliegue

1. Configurar `LIMPIADOR_MEDIA_CRON_SECRET` en el entorno del contenedor de Edge
   Runtime y recrear solamente el servicio necesario según el compose del VPS.
2. Desplegar la nueva versión de `limpiador-media`. Confirmar que el secreto está
   presente sin imprimir su valor.
3. Configurar en Vault la URL y el mismo secreto dedicado.
4. Aplicar primero la migración `20261029032630...` y después
   `20261029033614...`, con `ON_ERROR_STOP` y registrando únicamente resultados
   no sensibles.
5. Confirmar que ambas versiones quedaron registradas en
   `supabase_migrations.schema_migrations` conforme al mecanismo de migración
   usado por el servidor.

Este orden puede producir temporalmente respuestas `401` del cron antiguo, pero
no abre una ventana anónima ni expone privilegios administrativos.

## Verificación posterior

Ejecutar `supabase/diagnostics/verificar_seguridad_salidas_media.sql`. La salida
esperada es:

- `listar_salidas_resumen`: `SECURITY DEFINER`, `search_path` vacío, sin
  `EXECUTE` para `PUBLIC`, con acceso para `anon` y `authenticated`.
- Los dos helpers de medios: `search_path` vacío y sin ejecución para
  `PUBLIC`, `anon` o `authenticated`.
- Un solo `limpiador-media-cron` activo, horario, leyendo URL y secreto de Vault.
- `contiene_service_role = false` y
  `contiene_url_produccion_hardcodeada = false`.

Se puede probar en producción un POST sin secreto y otro con un valor incorrecto:
ambos deben responder `401` y no procesan la cola. El POST con el secreto real sí
puede eliminar medios encolados; se ejecuta únicamente en una ventana controlada
y después de revisar la cola. Las pruebas completas de identidades se conservan
en local o staging, no creando usuarios de prueba en producción.

## Reversión segura

Si aparece una incidencia operativa:

1. Ejecutar `supabase/rollback/20261029032630_seguridad_salidas_y_cron_media.sql`.
   El script desactiva el cron y revoca el RPC afectado: falla cerrado.
2. Mantener la Edge Function protegida y conservar el secreto. No restaurar el
   endpoint anónimo anterior.
3. Verificar que no existe el cron activo y que el RPC ya no es ejecutable por
   `PUBLIC`, `anon` ni `authenticated`.
4. Diagnosticar y preparar una migración correctiva nueva. No borrar ni modificar
   las migraciones ya registradas.
5. Restaurar el backup completo solo ante corrupción o incompatibilidad de
   esquema, dentro de una ventana de mantenimiento aprobada.

La segunda migración solo endurece funciones trigger y no requiere una reversión
normal. Reabrir su `search_path` o sus grants recrearía el riesgo corregido.
