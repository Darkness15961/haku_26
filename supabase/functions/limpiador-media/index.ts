import { createClient } from '@supabase/supabase-js'

// Este es el bucket donde están almacenadas las fotos de Haku
const BUCKET_MEDIA = 'haku-storage-produccion-2026'

const respuestaJson = (body: Record<string, unknown>, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })

const mensajeError = (error: unknown) =>
  error instanceof Error ? error.message : String(error)

const secretoValido = async (recibido: string, esperado: string) => {
  if (!recibido || !esperado) return false

  const encoder = new TextEncoder()
  const [hashRecibido, hashEsperado] = await Promise.all([
    crypto.subtle.digest('SHA-256', encoder.encode(recibido)),
    crypto.subtle.digest('SHA-256', encoder.encode(esperado)),
  ])
  const a = new Uint8Array(hashRecibido)
  const b = new Uint8Array(hashEsperado)
  let diferencia = 0
  for (let i = 0; i < a.length; i += 1) diferencia |= a[i] ^ b[i]
  return diferencia === 0
}

Deno.serve(async (req) => {
  // Aseguramos que solo puedan invocar esta función con el método POST
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const cronSecret = Deno.env.get('LIMPIADOR_MEDIA_CRON_SECRET') ?? ''
    const secretRecibido = req.headers.get('x-haku-cron-secret') ?? ''
    if (!(await secretoValido(secretRecibido, cronSecret))) {
      return respuestaJson({ error: 'No autorizado' }, 401)
    }

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
      return respuestaJson({ mensaje: 'No hay elementos para limpiar' }, 200)
    }

    const eliminadosIds: number[] = []
    const fallidos: { id: number; error: string }[] = []

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

      } catch (error: unknown) {
        fallidos.push({ id: item.id, error: mensajeError(error) })
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
         const { error: updateIntentosError } = await supabaseAdmin
           .from('cola_limpieza_media')
           .update({ intentos: target.intentos + 1 })
           .eq('id', f.id)

         if (updateIntentosError) {
           console.error(
             `No se pudo incrementar intentos para cola ${f.id}:`,
             updateIntentosError,
           )
         }
       }
    }

    return respuestaJson(
      {
        procesados: cola.length,
        eliminados: eliminadosIds.length,
        fallidos: fallidos.length,
      },
      200,
    )

  } catch (error: unknown) {
    console.error('Error catastrófico en limpiador-media:', error)
    return respuestaJson({ error: mensajeError(error) }, 500)
  }
})
