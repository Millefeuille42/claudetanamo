#!/usr/bin/env bash
echo "=== Claudetánamo Cell Diagnostic ==="
echo "Assigned IP: $(ip -j route show default 2>/dev/null | jq -r '.[0].prefsrc // "unknown"')"
echo "Host Gateway: $(ip -j route show default 2>/dev/null | jq -r '.[0].gateway // "unknown"')"
echo -n "Firewall RFC 1918 egress test (must fail): "
if curl -s --connect-timeout 2 http://192.168.1.1 >/dev/null 2>&1; then
  echo "LEAK DETECTED!"
else
  echo "OK (Dropped)"
fi
echo -n "Outbound WAN HTTPS test (must succeed): "
if curl -s --connect-timeout 3 -I https://api.anthropic.com >/dev/null 2>&1; then
  echo "OK (Connected)"
else
  echo "FAILED"
fi
