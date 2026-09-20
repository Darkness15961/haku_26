-- ====================================================================
-- AUTOMATIZACIÓN DEL LIMPIADOR DE MEDIOS (pg_cron + pg_net)
-- ====================================================================

-- 1. Asegurarnos de que las extensiones necesarias estén activadas
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- (El unschedule se eliminó porque en la primera migración el job no existe y Postgres lanza error)
-- 3. Programar el Despertador
-- '0 * * * *' significa: Ejecutar en el minuto 0 de cada hora (ej: 1:00, 2:00, 3:00)
-- IMPORTANTE: Cambia "https://TU_API_SUPABASE_URL_AQUI" por la URL real de tu VPS
SELECT cron.schedule(
    'limpiador-media-cron',
    '0 * * * *',
    $$
    SELECT net.http_post(
        url := 'https://supabase.haku.best/functions/v1/limpiador-media',
        headers := '{"Content-Type": "application/json"}'::jsonb
    );
    $$
);
