#!/usr/bin/env bash
set -euo pipefail

MY_IP=$(ip -j route show default 2>/dev/null | jq -r '.[0].prefsrc // empty' || true)

if [[ -z "$MY_IP" ]]; then
  DEFAULT_IF=$(ip -j route show default 2>/dev/null | jq -r '.[0].dev // "eth0"' || echo "eth0")
  MY_IP=$(ip -j -4 addr show dev "$DEFAULT_IF" 2>/dev/null | jq -r '.[0].addr_info[0].local // empty' || true)
fi

if [[ -d /run/claudetanamo && -n "$MY_IP" ]]; then
  echo "$MY_IP" > /run/claudetanamo/guest_ip
fi

sleep 0.1

git config --global --add safe.directory /workspace

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

exec claude "$@"
