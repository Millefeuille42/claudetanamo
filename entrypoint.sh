#!/usr/bin/env bash
set -euo pipefail

MY_IP=$(ip -j route show default 2>/dev/null | jq -r '.[0].prefsrc // empty' || true)

if [[ -z "$MY_IP" ]]; then
  DEFAULT_IF=$(ip -j route show default 2>/dev/null | jq -r '.[0].dev // "eth0"' || echo "eth0")
  MY_IP=$(ip -j -4 addr show dev "$DEFAULT_IF" 2>/dev/null | jq -r '.[0].addr_info[0].local // empty' || true)
fi

if [[ -d /run/claudetanamo ]]; then
  if [[ -z "$MY_IP" ]]; then
    echo "[-] Could not find the cell IP, refusing to start" >&2
    exit 1
  fi
  echo "$MY_IP" > /run/claudetanamo/guest_ip

  # don't touch the network until the host confirms the IP is jailed
  for _ in {1..300}; do
    [[ -f /run/claudetanamo/jailed ]] && break
    sleep 0.1
  done
  if [[ ! -f /run/claudetanamo/jailed ]]; then
    echo "[-] Host did not confirm the firewall, refusing to start" >&2
    exit 1
  fi
fi

git config --global --add safe.directory /workspace

if [[ -n "${CLAUDETANAMO_GIT_NAME:-}" ]]; then
  git config --global user.name "${CLAUDETANAMO_GIT_NAME}"
fi
if [[ -n "${CLAUDETANAMO_GIT_EMAIL:-}" ]]; then
  git config --global user.email "${CLAUDETANAMO_GIT_EMAIL}"
fi

SOURCE_DIR=/workspace
if [[ -d /project ]]; then
  SOURCE_DIR=/project
  git config --global --add safe.directory /project
  if git -C /workspace fetch --quiet origin &&
     git -C /workspace rev-parse --quiet --verify '@{upstream}' >/dev/null 2>&1; then
    git -C /workspace merge --quiet --ff-only '@{upstream}' ||
      echo "[!] /workspace could not be fast-forwarded to origin, continuing as is" >&2
  fi
fi

MANIFEST=""
if [[ -f "${SOURCE_DIR}/.claudetanamo/tools.nix" ]]; then
  MANIFEST="${SOURCE_DIR}/.claudetanamo/tools.nix"
elif [[ -f "${SOURCE_DIR}/shell.nix" ]]; then
  MANIFEST="${SOURCE_DIR}/shell.nix"
fi

HAS_PERMISSION_MODE=false
for arg in "$@"; do
  case "$arg" in
    --permission-mode*|--dangerously-skip-permissions)
      HAS_PERMISSION_MODE=true
      break
      ;;
  esac
done

if [[ "$HAS_PERMISSION_MODE" == false ]]; then
  set -- --permission-mode plan "$@"
fi

if [[ -n "$MANIFEST" ]]; then
  echo "[+] Activating user environment from ${MANIFEST}..."
  exec nix-shell "$MANIFEST" --run "exec claude $(printf '%q ' "$@")"
else
  exec claude "$@"
fi
