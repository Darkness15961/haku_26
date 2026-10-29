import assert from 'node:assert/strict'

const baseUrl = process.env.SUPABASE_LOCAL_URL ?? 'http://127.0.0.1:54321'
const cronSecret = process.env.LIMPIADOR_MEDIA_CRON_SECRET

assert.ok(
  cronSecret,
  'Define LIMPIADOR_MEDIA_CRON_SECRET para ejecutar esta prueba local.',
)

const invocar = async (secret) => {
  const headers = { 'Content-Type': 'application/json' }
  if (secret !== undefined) headers['x-haku-cron-secret'] = secret

  const response = await fetch(`${baseUrl}/functions/v1/limpiador-media`, {
    method: 'POST',
    headers,
    body: '{}',
  })
  return { status: response.status, body: await response.text() }
}

const sinSecreto = await invocar(undefined)
assert.equal(sinSecreto.status, 401, 'Una llamada sin secreto debe bloquearse.')

const secretoIncorrecto = await invocar('secreto-incorrecto')
assert.equal(
  secretoIncorrecto.status,
  401,
  'Una llamada con secreto incorrecto debe bloquearse.',
)

const secretoCorrecto = await invocar(cronSecret)
assert.equal(
  secretoCorrecto.status,
  200,
  `Una llamada autorizada con cola vacia debe responder 200: ${secretoCorrecto.body}`,
)

console.log(
  JSON.stringify({
    missingSecret: sinSecreto.status,
    wrongSecret: secretoIncorrecto.status,
    correctSecret: secretoCorrecto.status,
    serviceRoleSentByTest: false,
  }),
)
