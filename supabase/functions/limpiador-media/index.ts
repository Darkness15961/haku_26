import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Este es el bucket donde están almacenadas las fotos de Haku
const BUCKET_MEDIA = 'haku-storage-produccion-2026'

Deno.serve(async (req) => {
  // Aseguramos que solo puedan invocar esta función con el método POST
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    // Variables de Entorno Proporcionadas por Supabase y tu VPS
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const libraryId = Deno.env.get('BUNNY_LIBRARY_ID') ?? ''
    const apiKey = Deno.env.get('BUNNY_API_KEY') ?? ''

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('Variables de Supabase no configuradas')
    }

    // Usamos el Service Role Key para poder borrar desde Storage saltando RLS,
    // y poder leer/escribir en la tabla cola_limpieza_media libremente.
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })

    // =========================================================
    // 1. LEER LA COLA
    // Tomamos hasta 50 elementos para no saturar el tiempo de ejecución (timeout)
    // =========================================================
    const { data: cola, error: selectError } = await supabaseAdmin
      .from('cola_limpieza_media')
      .select('id, url_archivo, proveedor, intentos')
      .order('fecha_creacion', { ascending: true })
      .limit(50)

    if (selectError) {
      throw selectError
    }

    if (!cola || cola.length === 0) {
      return new Response(JSON.stringify({ mensaje: 'No hay elementos para limpiar' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const eliminadosIds: number[] = []
    const fallidos: { id: number; error: any }[] = []

    // =========================================================
    // 2. PROCESAR CADA ELEMENTO (S3 o BUNNY)
    // =========================================================
    for (const item of cola) {
      try {
        if (item.proveedor === 's3') {
          // Extraer la ruta real dentro del bucket a partir de la URL pública.
          // Ejemplo: https://xxx.supabase.co/storage/v1/object/public/bucket_name/ruta/archivo.jpg -> ruta/archivo.jpg
          const publicUrlFragment = `/storage/v1/object/public/${BUCKET_MEDIA}/`
          if (item.url_archivo.includes(publicUrlFragment)) {
            const path = item.url_archivo.split(publicUrlFragment)[1]
            if (path) {
              const { error } = await supabaseAdmin.storage
                .from(BUCKET_MEDIA)
                .remove([path])
              
              if (error) {
                console.error(`Error borrando ${path} de S3:`, error)
                throw new Error(error.message)
              }
            }
          } else {
             // Si la URL no coincide con nuestro bucket, lo marcamos para descartar
             console.warn("URL desconocida, se ignorará: ", item.url_archivo)
          }
          
        } else if (item.proveedor === 'bunny') {
          // Para bunny, item.url_archivo contiene directamente el Video ID (GUID)
          if (!libraryId || !apiKey) {
             console.error("Faltan credenciales de BunnyStream para borrar")
             throw new Error('Faltan credenciales Bunny')
          }
          
          const guid = item.url_archivo
          const bunnyResponse = await fetch(
            `https://video.bunnycdn.com/library/${libraryId}/videos/${guid}`,
            { method: 'DELETE', headers: { AccessKey: apiKey } },
          )
          
          // Consideramos ok o 404 (ya fue borrado manualmente o no existe) como éxito
          if (!bunnyResponse.ok && bunnyResponse.status !== 404) {
            const text = await bunnyResponse.text()
            console.error(`Error borrando video Bunny ${guid}:`, text)
            throw new Error(`Bunny API error: ${bunnyResponse.status}`)
          }
        }

        // Si llegó hasta aquí sin lanzar error, significa que lo borró con éxito
        eliminadosIds.push(item.id)

      } catch (err: any) {
        fallidos.push({ id: item.id, error: err.message })
      }
    }

    // =========================================================
    // 3. LIMPIAR LA COLA (Eliminar los exitosos)
    // =========================================================
    if (eliminadosIds.length > 0) {
      const { error: deleteError } = await supabaseAdmin
        .from('cola_limpieza_media')
        .delete()
        .in('id', eliminadosIds)

      if (deleteError) {
        console.error('Error al borrar los registros completados de la cola:', deleteError)
      }
    }

    // =========================================================
    // 4. ACTUALIZAR LOS QUE FALLARON (Sumar intentos)
    // =========================================================
    for (const f of fallidos) {
       // Si un archivo falla porque Bunny o S3 cayeron momentáneamente, sumamos un intento.
       // Al próximo barrido del pg_cron lo volverá a intentar.
       const target = cola.find(c => c.id === f.id)
       if (target) {
         await supabaseAdmin
           .from('cola_limpieza_media')
           .update({ intentos: target.intentos + 1 })
           .eq('id', f.id)
           .catch(() => null)
       }
    }

    return new Response(
      JSON.stringify({
        procesados: cola.length,
        eliminados: eliminadosIds.length,
        fallidos: fallidos.length,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    console.error('Error catastrófico en limpiador-media:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
