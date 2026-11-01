#!/usr/bin/env bash
# Check whether this Mac can run grok-bot-voice announce.
set -euo pipefail

VOICE="${GROKBOT_TTS_VOICE:-zh-CN-YunxiNeural}"
DIR="${GROKBOT_TTS_DIR:-$HOME/.grokbot-tts}"
ok=0
fail=0

check() {
  local name="$1" status="$2" detail="$3"
  if [[ "$status" == "ok" ]]; then
    echo "OK   $name — $detail"
    ok=$((ok+1))
  else
    echo "FAIL $name — $detail"
    fail=$((fail+1))
  fi
}

uname_s="$(uname -s 2>/dev/null || echo unknown)"
if [[ "$uname_s" == "Darwin" ]]; then
  check "os" ok "macOS ($uname_s)"
else
  check "os" fail "need macOS for afplay/say; got $uname_s"
fi

if command -v edge-tts >/dev/null 2>&1; then
  check "edge-tts" ok "$(command -v edge-tts)"
else
  check "edge-tts" fail "missing; install with: python3 -m pip install --user edge-tts"
fi

if command -v afplay >/dev/null 2>&1; then
  check "afplay" ok "$(command -v afplay)"
else
  check "afplay" fail "missing (macOS only)"
fi

if command -v say >/dev/null 2>&1; then
  check "say" ok "fallback available ($(command -v say))"
else
  check "say" fail "no system say fallback"
fi

mkdir -p "$DIR" 2>/dev/null && check "dir" ok "$DIR" || check "dir" fail "cannot create $DIR"

echo "voice default: $VOICE (override with GROKBOT_TTS_VOICE)"
echo "summary: $ok ok, $fail fail"
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
exit 0
