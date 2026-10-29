#!/usr/bin/env bash
set -Eeuo pipefail

readonly root="$1"
readonly stage="$2"
readonly function_name='limpiador-media'
readonly function_url='https://supabase.haku.best/functions/v1/limpiador-media'
readonly override_file='docker-compose.functions-secret.yml'
readonly secret_file='.env.functions'

cd "${root}"

if [[ ! -f docker-compose.yml || ! -f "${stage}/index.ts" ]]; then
  echo 'Preflight falló: compose o función preparada no disponibles.' >&2
  exit 1
fi

for service in db functions; do
  if ! docker compose config --services | grep -Fxq "${service}"; then
    echo "Preflight falló: servicio ${service} no existe en Docker Compose." >&2
    exit 1
  fi
done

db_container="$(docker compose ps -q db)"
if [[ -z "${db_container}" ]]; then
  echo 'Preflight falló: el contenedor db no está activo.' >&2
  exit 1
fi

applied_count="$(
  docker exec "${db_container}" psql -X -A -t -U postgres -d postgres \
    -c "SELECT count(*) FROM supabase_migrations.schema_migrations WHERE version IN ('20261029032630', '20261029033614');"
)"
if [[ "${applied_count}" != '2' ]]; then
  echo 'Preflight falló: las dos migraciones de seguridad no están aplicadas.' >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="${root}/backups/${function_name}-${timestamp}"
mkdir -p "${backup_dir}"

had_function=false
had_secret_file=false
had_override=false
had_env=false

if [[ -d "volumes/functions/${function_name}" ]]; then
  mv "volumes/functions/${function_name}" "${backup_dir}/function"
  had_function=true
fi
if [[ -f "${secret_file}" ]]; then
  cp -a "${secret_file}" "${backup_dir}/${secret_file}"
  had_secret_file=true
fi
if [[ -f "${override_file}" ]]; then
  cp -a "${override_file}" "${backup_dir}/${override_file}"
  had_override=true
fi
if [[ -f .env ]]; then
  cp -a .env "${backup_dir}/.env"
  had_env=true
fi

rollback() {
  status=$?
  trap - ERR
  echo 'El despliegue falló; restaurando la función y configuración anteriores.' >&2

  if [[ -d "volumes/functions/${function_name}" ]]; then
    mv "volumes/functions/${function_name}" "${backup_dir}/failed-function" || true
  fi
  if [[ "${had_function}" == true && -d "${backup_dir}/function" ]]; then
    mv "${backup_dir}/function" "volumes/functions/${function_name}" || true
  fi

  if [[ "${had_secret_file}" == true ]]; then
    cp -a "${backup_dir}/${secret_file}" "${secret_file}" || true
  else
    rm -f -- "${secret_file}"
  fi
  if [[ "${had_override}" == true ]]; then
    cp -a "${backup_dir}/${override_file}" "${override_file}" || true
  else
    rm -f -- "${override_file}"
  fi
  if [[ "${had_env}" == true ]]; then
    cp -a "${backup_dir}/.env" .env || true
  fi

  docker compose up -d --force-recreate functions >/dev/null 2>&1 || true
  exit "${status}"
}
trap rollback ERR

mv "${stage}" "volumes/functions/${function_name}"

cron_secret="$(openssl rand -hex 32)"
umask 077
secret_tmp="$(mktemp)"
if [[ -f "${secret_file}" ]]; then
  grep -v '^LIMPIADOR_MEDIA_CRON_SECRET=' "${secret_file}" > "${secret_tmp}" || true
fi
printf 'LIMPIADOR_MEDIA_CRON_SECRET=%s\n' "${cron_secret}" >> "${secret_tmp}"
mv "${secret_tmp}" "${secret_file}"
chmod 600 "${secret_file}"

cat > "${override_file}" <<'YAML'
services:
  functions:
    env_file:
      - .env.functions
YAML

if grep -q '^COMPOSE_FILE=' .env; then
  current_compose="$(sed -n 's/^COMPOSE_FILE=//p' .env | tail -n 1)"
  if [[ ":${current_compose}:" != *":${override_file}:"* ]]; then
    escaped_override="${override_file//\//\\/}"
    sed -i "s|^COMPOSE_FILE=.*|&:${escaped_override}|" .env
  fi
else
  printf '\nCOMPOSE_FILE=docker-compose.yml:%s\n' "${override_file}" >> .env
fi

docker compose up -d --force-recreate functions

functions_container="$(docker compose ps -q functions)"
if [[ -z "${functions_container}" ]]; then
  echo 'Functions no creó un contenedor.' >&2
  false
fi

healthy=false
for _ in $(seq 1 30); do
  state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${functions_container}")"
  if [[ "${state}" == 'healthy' || "${state}" == 'running' ]]; then
    healthy=true
    break
  fi
  sleep 2
done
if [[ "${healthy}" != true ]]; then
  docker compose logs --tail 80 functions >&2
  echo 'Functions no quedó saludable.' >&2
  false
fi

unauthorized_status="$(
  curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "${function_url}" \
    -H 'Content-Type: application/json' \
    --data '{}'
)"
if [[ "${unauthorized_status}" != '401' ]]; then
  echo "Verificación falló: POST sin secreto respondió ${unauthorized_status}, se esperaba 401." >&2
  false
fi

{
  printf "\\set cron_secret '%s'\n" "${cron_secret}"
  cat <<'SQL'
BEGIN;
SELECT vault.update_secret(id, new_secret := :'cron_secret')
FROM vault.secrets
WHERE name = 'limpiador_media_cron_secret';
SELECT vault.create_secret(
  :'cron_secret',
  'limpiador_media_cron_secret',
  'Secreto dedicado del cron limpiador-media'
)
WHERE NOT EXISTS (
  SELECT 1 FROM vault.secrets
  WHERE name = 'limpiador_media_cron_secret'
);
SELECT vault.update_secret(
  id,
  new_secret := 'https://supabase.haku.best/functions/v1/limpiador-media'
)
FROM vault.secrets
WHERE name = 'limpiador_media_function_url';
SELECT vault.create_secret(
  'https://supabase.haku.best/functions/v1/limpiador-media',
  'limpiador_media_function_url',
  'URL de la Edge Function limpiador-media'
)
WHERE NOT EXISTS (
  SELECT 1 FROM vault.secrets
  WHERE name = 'limpiador_media_function_url'
);
COMMIT;
SQL
} | docker exec -i "${db_container}" \
      psql -X -v ON_ERROR_STOP=1 -U postgres -d postgres >/dev/null

trap - ERR
echo "DEPLOY_OK ${function_name}"
echo "BACKUP ${backup_dir}"
echo 'VERIFY unauthorized=401 functions=healthy vault=configured'

