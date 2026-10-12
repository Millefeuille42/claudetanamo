#!/usr/bin/env bash
GATEWAY="$(ip -j route show default 2>/dev/null | jq -r '.[0].gateway // "unknown"')"

# expect_blocked/expect_open <label> <command...>
expect_blocked() {
  local label="$1"; shift
  echo -n "${label} (must fail): "
  if "$@" >/dev/null 2>&1; then echo "LEAK DETECTED!"; else echo "OK (Dropped)"; fi
}
expect_open() {
  local label="$1"; shift
  echo -n "${label} (must succeed): "
  if "$@" >/dev/null 2>&1; then echo "OK (Connected)"; else echo "FAILED"; fi
}
tcp() { timeout 3 bash -c "exec 3<>/dev/tcp/$1/$2"; }

echo "=== Claudetánamo Cell Diagnostic ==="
echo "Assigned IP: $(ip -j route get 1.1.1.1 2>/dev/null | jq -r '.[0].prefsrc // "unknown"')"
echo "Host Gateway: ${GATEWAY}"
expect_blocked "Firewall RFC 1918 egress test" curl -s --connect-timeout 2 http://192.168.1.1
expect_blocked "Host Mac service test" tcp "${GATEWAY}" 5000
expect_blocked "Outbound WAN HTTP test" curl -4 -s --connect-timeout 3 -I http://example.com
expect_blocked "Direct public DNS test" tcp 1.1.1.1 53
expect_blocked "Outbound IPv6 test" curl -6 -s --connect-timeout 3 -I https://api.anthropic.com
expect_open "DNS via gateway test" getent hosts api.anthropic.com
expect_open "Outbound WAN HTTPS test" curl -s --connect-timeout 3 -I https://api.anthropic.com
