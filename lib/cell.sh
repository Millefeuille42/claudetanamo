cell_home() {
  local project_root="$1" hash
  hash="$(printf '%s' "${project_root}" | shasum -a 256 | cut -c1-12)"
  echo "${CLAUDETANAMO_HOME:-${HOME}/Library/Application Support/claudetanamo}/projects/$(basename "${project_root}")-${hash}"
}
