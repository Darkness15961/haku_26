#!/usr/bin/env bash
set -euo pipefail

# Una migración histórica de PostGIS fue aplicada en producción por el rol
# propietario supabase_admin. El CLI local reproduce las migraciones como
# postgres, que no puede alterar spatial_ref_sys. Se mantiene el archivo
# histórico intacto y se reproduce esa única versión con su propietario real.
readonly previous_version='20260924160000'
readonly owner_version='20260924170000'
readonly owner_migration='supabase/migrations/20260924170000_spatial_ref_sys_rls.sql'

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
cd "${repo_root}"

project_id="$(sed -n 's/^project_id = "\(.*\)"/\1/p' supabase/config.toml | head -n 1)"
if [[ -z "${project_id}" ]]; then
  echo 'No se encontró project_id en supabase/config.toml.' >&2
  exit 1
fi

db_container="supabase_db_${project_id}"
if ! docker inspect "${db_container}" >/dev/null 2>&1; then
  echo "No está disponible el contenedor local ${db_container}." >&2
  exit 1
fi

supabase db reset --local --no-seed --version "${previous_version}"

docker exec -i "${db_container}" \
  psql -v ON_ERROR_STOP=1 -U supabase_admin -d postgres \
  < "${owner_migration}"

# La reparación es exclusivamente del historial local recién recreado. Nunca
# se ejecuta con --db-url ni --linked.
supabase migration repair --local --status applied "${owner_version}"
supabase migration up --local
