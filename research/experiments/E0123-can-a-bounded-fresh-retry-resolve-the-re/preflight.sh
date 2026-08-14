#!/usr/bin/env bash
set -euo pipefail

health_url="${E0123_HEALTH_URL:-http://10.77.0.10:8080/health}"
server_bin="${E0123_SERVER_BIN:-/home/ert/.local/llama.cpp-upstream-main-885c5bbe/bin/llama-server}"
expected_commit="${E0123_LLAMA_COMMIT:-885c5bbe8e04dc78db25beb911a2715312ad7b54}"

[[ -x "${server_bin}" ]] || {
    printf 'missing executable: %s\n' "${server_bin}" >&2
    exit 1
}

health_file="$(mktemp)"
trap 'rm -f "${health_file}"' EXIT
http_code="$(curl --max-time 5 --silent --show-error --output "${health_file}" \
    --write-out '%{http_code}' "${health_url}")"
if [[ "${http_code}" != 200 ]]; then
    printf 'health check failed: HTTP %s: %s\n' "${http_code}" "$(cat "${health_file}")" >&2
    exit 1
fi
python3 - "${health_file}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    payload = json.load(stream)
if payload.get("status") != "ok":
    raise SystemExit(f"health status is not ok: {payload!r}")
PY

version="$(${server_bin} --version 2>&1)"
printf '%s\n' "${version}"
grep -F "commit ${expected_commit:0:8}" <<<"${version}" >/dev/null || {
    printf 'llama.cpp commit mismatch; expected prefix %s\n' "${expected_commit:0:8}" >&2
    exit 1
}
printf 'E0123 preflight: ok\n'
