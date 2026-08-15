#!/bin/sh
# Hugging Face wrapper: ensure secret + port, then run upstream SearXNG entrypoint.
set -eu

SETTINGS="${SEARXNG_SETTINGS_PATH:-/etc/searxng/settings.yml}"

# Prefer Space secret SEARXNG_SECRET when provided.
if [ -n "${SEARXNG_SECRET:-}" ] && [ -f "$SETTINGS" ] && [ -w "$SETTINGS" ]; then
  tmp="$(mktemp)"
  awk -v key="$SEARXNG_SECRET" '
    /^[[:space:]]*secret_key:/ {
      print "  secret_key: \"" key "\""
      next
    }
    { print }
  ' "$SETTINGS" >"$tmp" && cat "$tmp" >"$SETTINGS" && rm -f "$tmp"
fi

# Always bind Granian to HF's expected port.
export GRANIAN_HOST="${GRANIAN_HOST:-0.0.0.0}"
export GRANIAN_PORT="${GRANIAN_PORT:-7860}"
export GRANIAN_INTERFACE="${GRANIAN_INTERFACE:-wsgi}"
export GRANIAN_WEBSOCKETS="${GRANIAN_WEBSOCKETS:-false}"

# Best-effort keep-alive: ping local app (+ public Space URL when known) every N seconds
# so HF idle detection may treat the Space as active. Does not revive a slept Space.
KEEP_ALIVE_INTERVAL="${KEEP_ALIVE_INTERVAL:-120}"
_keep_alive() {
  # Wait for Granian to come up before first hit.
  sleep 30
  while true; do
    if command -v curl >/dev/null 2>&1; then
      curl -fsS --max-time 10 "http://127.0.0.1:${GRANIAN_PORT}/" >/dev/null 2>&1 || true
      if [ -n "${SEARXNG_BASE_URL:-}" ]; then
        curl -fsS --max-time 15 "${SEARXNG_BASE_URL%/}/" >/dev/null 2>&1 || true
      elif [ -n "${SPACE_HOST:-}" ]; then
        curl -fsS --max-time 15 "https://${SPACE_HOST}/" >/dev/null 2>&1 || true
      fi
    elif command -v wget >/dev/null 2>&1; then
      wget -q -T 10 -O /dev/null "http://127.0.0.1:${GRANIAN_PORT}/" >/dev/null 2>&1 || true
      if [ -n "${SEARXNG_BASE_URL:-}" ]; then
        wget -q -T 15 -O /dev/null "${SEARXNG_BASE_URL%/}/" >/dev/null 2>&1 || true
      elif [ -n "${SPACE_HOST:-}" ]; then
        wget -q -T 15 -O /dev/null "https://${SPACE_HOST}/" >/dev/null 2>&1 || true
      fi
    fi
    sleep "$KEEP_ALIVE_INTERVAL"
  done
}
_keep_alive &
KEEP_ALIVE_PID=$!
# Detach so exec below does not tear down the loop.
if command -v disown >/dev/null 2>&1; then
  disown "$KEEP_ALIVE_PID" 2>/dev/null || true
fi

UPSTREAM="/usr/local/searxng/entrypoint.sh"
if [ -x "$UPSTREAM" ]; then
  exec "$UPSTREAM" "$@"
fi

# Fallback if upstream layout changes: run Granian from the SearXNG venv.
cd /usr/local/searxng
if [ -x ./.venv/bin/granian ]; then
  exec ./.venv/bin/granian \
    --interface wsgi \
    --host "$GRANIAN_HOST" \
    --port "$GRANIAN_PORT" \
    searx.webapp:app
fi
if [ -x ./.venv/bin/python ]; then
  export PYTHONPATH="/usr/local/searxng${PYTHONPATH:+:$PYTHONPATH}"
  exec ./.venv/bin/python -m granian \
    --interface wsgi \
    --host "$GRANIAN_HOST" \
    --port "$GRANIAN_PORT" \
    searx.webapp:app
fi

echo "searxng: upstream entrypoint missing and granian not found" >&2
ls -la /usr/local/searxng 2>&1 || true
ls -la /usr/local/searxng/.venv/bin 2>&1 || true
exit 1
