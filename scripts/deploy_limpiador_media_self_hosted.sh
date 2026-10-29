#!/usr/bin/env bash
set -Eeuo pipefail

readonly remote_host="${HAKU_VPS_SSH:-jhon@62.171.150.75}"
readonly remote_root="${HAKU_VPS_SUPABASE_DIR:-/opt/supabase/docker}"
readonly function_source='supabase/functions/limpiador-media'

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
cd "${repo_root}"

if [[ ! -f "${function_source}/index.ts" ]]; then
  echo "No existe ${function_source}/index.ts." >&2
  exit 1
fi

local_package="$(mktemp --suffix=.tar.gz)"
remote_package="/tmp/haku-limpiador-media-$(date +%s)-${RANDOM}.tar.gz"
cleanup() { rm -f -- "${local_package}"; }
trap cleanup EXIT

tar -czf "${local_package}" \
  scripts/deploy_limpiador_media_remote.sh \
  "${function_source}"

echo 'Subiendo paquete temporal; ingresa la contraseña SSH cuando se solicite.'
scp -o StrictHostKeyChecking=accept-new \
  "${local_package}" "${remote_host}:${remote_package}"

remote_command="$(cat <<EOF
set -Eeuo pipefail
archive='${remote_package}'
package=\$(mktemp -d /tmp/haku-limpiador-media.XXXXXX)
cleanup() { rm -rf -- "\${package}" "\${archive}"; }
trap cleanup EXIT
tar -xzf "\${archive}" -C "\${package}"
sudo bash "\${package}/scripts/deploy_limpiador_media_remote.sh" \
  '${remote_root}' \
  "\${package}/supabase/functions/limpiador-media"
EOF
)"

echo 'Desplegando con permisos administrativos; ingresa las contraseñas solicitadas.'
ssh -tt -o StrictHostKeyChecking=accept-new \
  "${remote_host}" "${remote_command}"
