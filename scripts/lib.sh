#!/usr/bin/env bash
# shellcheck disable=SC2034  # variables are used by the scripts that source this file
# Shared helpers for gemkeeper hooks. Pure bash + coreutils, no jq/python needed.

# Read the hook's JSON payload from stdin once, flattened to one line.
gk_read_input() {
  GK_INPUT="$(cat | tr -d '\n\r')"
}

# Extract a simple top-level string field from the payload: gk_field source
gk_field() {
  printf '%s' "$GK_INPUT" \
    | sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

gk_init() {
  gk_read_input
  GK_SESSION="$(gk_field session_id)"
  GK_SESSION="${GK_SESSION:-default}"
  GK_SESSION="${GK_SESSION//[^A-Za-z0-9_-]/_}"

  local cwd
  cwd="$(gk_field cwd)"
  GK_PROJECT="${CLAUDE_PROJECT_DIR:-${cwd:-$PWD}}"
  GK_LEDGER="${GEMKEEPER_LEDGER:-$GK_PROJECT/.gemkeeper/ledger.md}"

  # Plugin option (set via /plugin config) wins, then env var, then default.
  GK_NUDGE_EVERY="${CLAUDE_PLUGIN_OPTION_NUDGE_EVERY:-${GEMKEEPER_NUDGE_EVERY:-6}}"
  GK_WARN_TOKENS="${CLAUDE_PLUGIN_OPTION_WARN_TOKENS:-${GEMKEEPER_WARN_TOKENS:-100000}}"
  GK_MAX_LINES="${GEMKEEPER_MAX_INJECT_LINES:-250}"

  GK_STATE_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.gemkeeper}/state"
  mkdir -p "$GK_STATE_DIR" 2>/dev/null || true
  GK_STATE="$GK_STATE_DIR/$GK_SESSION"
}

# Numbers only; anything else falls back to the given default.
gk_int() {
  case "$1" in ''|*[!0-9]*) printf '%s' "$2" ;; *) printf '%s' "$1" ;; esac
}

# Current context size in tokens, from the last main-thread API usage record in
# the transcript. Falls back to a byte-based estimate since the last compaction.
gk_context_tokens() {
  local t
  t="$(gk_field transcript_path)"
  t="${t/#\~/$HOME}"
  [ -n "$t" ] && [ -f "$t" ] || { echo 0; return; }

  local line
  line="$(grep '"usage"' "$t" 2>/dev/null | grep -v '"isSidechain":true' | tail -n 1)"
  if [ -n "$line" ]; then
    local a b c
    a="$(printf '%s' "$line" | grep -o '"input_tokens":[0-9]*' | tail -n 1 | grep -o '[0-9]*$')"
    b="$(printf '%s' "$line" | grep -o '"cache_creation_input_tokens":[0-9]*' | tail -n 1 | grep -o '[0-9]*$')"
    c="$(printf '%s' "$line" | grep -o '"cache_read_input_tokens":[0-9]*' | tail -n 1 | grep -o '[0-9]*$')"
    echo $(( ${a:-0} + ${b:-0} + ${c:-0} ))
    return
  fi

  # Fallback: bytes after the last compact boundary, divided by 5 (rough; JSONL has overhead).
  local start bytes
  start="$(grep -n 'compact_boundary' "$t" 2>/dev/null | tail -n 1 | cut -d: -f1)"
  if [ -n "$start" ]; then
    bytes="$(tail -n +"$start" "$t" | wc -c)"
  else
    bytes="$(wc -c < "$t")"
  fi
  echo $(( bytes / 5 ))
}

# The user's prompt from a UserPromptSubmit payload (JSON escapes left in; fine for keyword checks).
gk_prompt() {
  printf '%s' "$GK_INPUT" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"//p' | head -c 20000
}

# Words that usually mark a gem: rules, reasons, dead ends, gotchas (English + German).
GK_GEM_RE='(^|[^[:alpha:]])(never|always|must|mustn.t|don.t|do not|not allowed|forbidden|no new|policy|because|the reason|tried|didn.t work|doesn.t work|did not work|won.t work|failed|broke|turns out|turned out|dead end|outdated|flaky|heads.up|gotcha|workaround|quirk|careful|beware|decided|decision|port [0-9]+|nie|niemals|immer|weil|darf nicht|versucht|funktioniert nicht|achtung|vorsicht|entschieden|stellt sich heraus)([^[:alpha:]]|$)'

gk_looks_like_gem() {
  gk_prompt | grep -Eiq "$GK_GEM_RE"
}

# Checksum of the ledger, to tell whether it changed during a turn.
gk_ledger_sum() {
  if [ -f "$GK_LEDGER" ]; then cksum < "$GK_LEDGER" | cut -d' ' -f1; else echo none; fi
}

# Read / set one key in the per-session state file.
gk_state_get() {
  [ -f "$GK_STATE" ] && sed -n "s/^$1=//p" "$GK_STATE" | head -n 1
}
gk_state_set() {
  local tmp="$GK_STATE.tmp"
  { [ -f "$GK_STATE" ] && grep -v "^$1=" "$GK_STATE"; printf '%s=%s\n' "$1" "$2"; } > "$tmp" 2>/dev/null \
    && mv -f "$tmp" "$GK_STATE"
}

# Tidy up state files from old sessions (best effort, quiet).
gk_gc() {
  find "$GK_STATE_DIR" -type f -mtime +7 -delete 2>/dev/null || true
}
