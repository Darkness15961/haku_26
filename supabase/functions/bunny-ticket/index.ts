import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type Accion = 'crear' | 'estado' | 'cancelar'

class HttpError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message)
  }
}

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

const borrarVideoBunny = async (
  libraryId: string,
  apiKey: string,
  guid: string,
) => {
  const response = await fetch(
    `https://video.bunnycdn.com/library/${libraryId}/videos/${guid}`,
    { method: 'DELETE', headers: { AccessKey: apiKey } },
  )
  return response.ok || response.status === 404
}

const estadoLocal = (status: number) => {
  // VideoModelStatus de la API consultada: 4=Finished, 5=Error,
  // 6=UploadFailed y 8=JitPlaylistsCreated.
  if (status === 5 || status === 6) return 'error'
  if (status === 4 || status === 8) return 'ready'
  return 'processing'
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'Método no permitido.' }, 405)

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const libraryId = Deno.env.get('BUNNY_LIBRARY_ID') ?? ''
    const apiKey = Deno.env.get('BUNNY_API_KEY') ?? ''
    const cdnHostname = Deno.env.get('BUNNY_CDN_HOSTNAME') ?? ''

    if (!supabaseUrl || !anonKey || !libraryId || !apiKey || !cdnHostname) {
      throw new HttpError('La integración de video no está configurada.', 503)
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new HttpError('Debes iniciar sesión.', 401)

    const clienteUsuario = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const {
      data: { user },
      error: userError,
    } = await clienteUsuario.auth.getUser()
    if (userError || !user) {
      throw new HttpError('La sesión venció. Vuelve a iniciar sesión.', 401)
    }

    const body = await req.json().catch(() => null)
    if (!body || typeof body !== 'object') {
      throw new HttpError('Solicitud de video inválida.', 400)
    }

    const accion = ((body as Record<string, unknown>).accion ?? 'crear') as Accion
    if (!['crear', 'estado', 'cancelar'].includes(accion)) {
      throw new HttpError('Acción de video inválida.', 400)
    }

    const rawId = (body as Record<string, unknown>).publicacion_id
    const publicacionId =
      typeof rawId === 'number' ? rawId : Number.parseInt(String(rawId), 10)
    if (!Number.isSafeInteger(publicacionId) || publicacionId <= 0) {
      throw new HttpError('La publicación es inválida.', 400)
    }

    // Verificación explícita de propiedad además de RLS. Una publicación
    // eliminada nunca puede recibir nuevos adjuntos.
    const { data: publicacion, error: publicacionError } = await clienteUsuario
      .from('publicacion')
      .select('id, usuario_id, estado')
      .eq('id', publicacionId)
      .maybeSingle()
    if (publicacionError || !publicacion || publicacion.estado === 'eliminado') {
      throw new HttpError('La publicación no está disponible.', 404)
    }
    const esAutor = publicacion.usuario_id === user.id
    if (accion !== 'estado' && !esAutor) {
      throw new HttpError('No puedes administrar el video de esta publicación.', 403)
    }

    const { data: multimedia, error: multimediaError } = await clienteUsuario
      .from('publicacion_multimedia')
      .select(
        'id, tipo, proveedor_video_id, url_archivo, miniatura_url, video_estado',
      )
      .eq('publicacion_id', publicacionId)
      .order('orden', { ascending: true })
      .limit(1)
      .maybeSingle()
    if (multimediaError) {
      throw new HttpError('No se pudo consultar el adjunto de la publicación.', 500)
    }

    if (accion === 'crear') {
      // MVP: una publicación admite una imagen o un video, no ambos.
      if (multimedia) {
        throw new HttpError('La publicación ya tiene un archivo adjunto.', 409)
      }

      const bunnyResponse = await fetch(
        `https://video.bunnycdn.com/library/${libraryId}/videos`,
        {
          method: 'POST',
          headers: {
            AccessKey: apiKey,
            'Content-Type': 'application/json',
            Accept: 'application/json',
          },
          body: JSON.stringify({ title: `Haku_Video_Pub_${publicacionId}` }),
        },
      )
      if (!bunnyResponse.ok) {
        console.error('Bunny create:', bunnyResponse.status, await bunnyResponse.text())
        throw new HttpError('No se pudo preparar la subida del video.', 502)
      }

      const bunnyData = await bunnyResponse.json()
      const guid =
        typeof bunnyData?.guid === 'string' ? bunnyData.guid.trim() : ''
      if (!guid) {
        throw new HttpError('El proveedor no devolvió un identificador de video.', 502)
      }

      const urlVideo = `https://${cdnHostname}/${guid}/playlist.m3u8`
      const urlMiniatura = `https://${cdnHostname}/${guid}/thumbnail.jpg`
      const { error: dbError } = await clienteUsuario
        .from('publicacion_multimedia')
        .insert({
          publicacion_id: publicacionId,
          proveedor_video_id: guid,
          url_archivo: urlVideo,
          miniatura_url: urlMiniatura,
          tipo: 'video',
          orden: 1,
          video_estado: 'pending',
        })

      if (dbError) {
        const compensado = await borrarVideoBunny(libraryId, apiKey, guid)
        if (!compensado) console.error('Video Bunny huérfano:', guid)
        console.error('publicacion_multimedia insert:', dbError)
        throw new HttpError('No se pudo asociar el video a la publicación.', 409)
      }

      const expiration = Math.floor(Date.now() / 1000) + 2 * 60 * 60
      const bytes = new TextEncoder().encode(
        `${libraryId}${apiKey}${expiration}${guid}`,
      )
      const digest = await crypto.subtle.digest('SHA-256', bytes)
      const signature = Array.from(new Uint8Array(digest))
        .map((value) => value.toString(16).padStart(2, '0'))
        .join('')

      return json({
        library_id: libraryId,
        guid,
        signature,
        expiration,
        url_video: urlVideo,
        miniatura_url: urlMiniatura,
      })
    }

    if (!multimedia || multimedia.tipo !== 'video' || !multimedia.proveedor_video_id) {
      throw new HttpError('La publicación no tiene un video asociado.', 404)
    }

    const guid = String(multimedia.proveedor_video_id)

    if (accion === 'cancelar') {
      // Primero ocultamos la referencia. Si Bunny no responde, solo queda un
      // objeto huérfano recuperable, nunca una publicación apuntando a un 404.
      const { error: deleteError } = await clienteUsuario
        .from('publicacion_multimedia')
        .delete()
        .eq('id', multimedia.id)
      if (deleteError) {
        throw new HttpError('No se pudo cancelar el video.', 500)
      }
      const eliminado = await borrarVideoBunny(libraryId, apiKey, guid)
      if (!eliminado) console.error('No se pudo limpiar video Bunny:', guid)
      return json({ cancelado: true, limpieza_completa: eliminado })
    }

    const bunnyResponse = await fetch(
      `https://video.bunnycdn.com/library/${libraryId}/videos/${guid}`,
      { headers: { AccessKey: apiKey, Accept: 'application/json' } },
    )
    if (!bunnyResponse.ok) {
      console.error('Bunny status:', bunnyResponse.status, await bunnyResponse.text())
      throw new HttpError('No se pudo consultar el procesamiento del video.', 502)
    }

    const bunnyData = await bunnyResponse.json()
    const status = Number(bunnyData?.status)
    const videoEstado = estadoLocal(status)

    // El celular no decide cuándo un video está listo. La Edge Function
    // contrasta el estado directamente con Bunny y actualiza con service role.
    if (!serviceRoleKey) {
      throw new HttpError('Falta la credencial interna para sincronizar el video.', 503)
    }
    const clienteAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { error: updateError } = await clienteAdmin
      .from('publicacion_multimedia')
      .update({ video_estado: videoEstado })
      .eq('id', multimedia.id)
      .eq('proveedor_video_id', guid)
    if (updateError) {
      console.error('publicacion_multimedia update:', updateError)
      throw new HttpError('No se pudo sincronizar el estado del video.', 500)
    }

    return json({
      guid,
      estado: videoEstado,
      estado_bunny: status,
      url_video: multimedia.url_archivo,
      miniatura_url: multimedia.miniatura_url,
    })
  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500
    const message =
      error instanceof HttpError
        ? error.message
        : 'No se pudo completar la operación de video.'
    console.error(error)
    return json({ error: message }, status)
  }
})