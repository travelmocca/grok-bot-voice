#!/usr/bin/env bash
# Grok Bot task-done voice announce: synthesize + play on macOS.
# Usage: announce.sh <<'TEXT'
#   滴滴滴。我已经完成了……
# TEXT
# Or: announce.sh - <<'TEXT' ... TEXT
# Or (less preferred): announce.sh "one short sentence"
set -euo pipefail

VOICE="${GROKBOT_TTS_VOICE:-zh-CN-YunxiNeural}"
DIR="${GROKBOT_TTS_DIR:-$HOME/.grokbot-tts}"
TIMEOUT_SEC="${GROKBOT_TTS_TIMEOUT:-45}"
SAY_VOICE="${GROKBOT_TTS_SAY_VOICE:-Tingting}"
SAY_RATE="${GROKBOT_TTS_SAY_RATE:-180}"

mkdir -p "$DIR"

if [[ $# -gt 0 && "$1" != "-" ]]; then
  TEXT="$*"
else
  TEXT="$(cat)"
fi

TEXT="$(printf '%s' "$TEXT" | tr '\n' ' ' | sed 's/[[:space:]]\{1,\}/ /g; s/^ //; s/ $//')"
if [[ -z "$TEXT" ]]; then
  echo "announce.sh: empty text" >&2
  exit 2
fi

OUT="$(mktemp "$DIR/announce.XXXXXX.mp3")"
cleanup() { rm -f "$OUT" 2>/dev/null || true; }
trap cleanup EXIT

run_edge() {
  if ! command -v edge-tts >/dev/null 2>&1; then
    return 127
  fi
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_SEC" edge-tts --voice "$VOICE" --text "$TEXT" --write-media "$OUT"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$TIMEOUT_SEC" edge-tts --voice "$VOICE" --text "$TEXT" --write-media "$OUT"
  else
    edge-tts --voice "$VOICE" --text "$TEXT" --write-media "$OUT"
  fi
}

if run_edge && [[ -s "$OUT" ]] && command -v afplay >/dev/null 2>&1; then
  afplay "$OUT"
  exit 0
fi

# Fallback: system say (macOS)
if command -v say >/dev/null 2>&1; then
  say -v "$SAY_VOICE" -r "$SAY_RATE" -- "$TEXT" || say -- "$TEXT"
  exit 0
fi

echo "announce.sh: edge-tts/afplay and say all unavailable" >&2
exit 1
