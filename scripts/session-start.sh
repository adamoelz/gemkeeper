#!/usr/bin/env bash
# SessionStart hook: re-inject the ledger after startup, /clear, compaction or resume.
# Plain stdout from a SessionStart hook is added to Claude's context.
set -u
. "$(dirname "$0")/lib.sh"
gk_init
gk_gc

source_kind="$(gk_field source)"

# New context window → reset the per-session counters.
case "$source_kind" in
  startup|clear|compact) rm -f "$GK_STATE" ;;
esac

if [ ! -s "$GK_LEDGER" ]; then
  if [ "$source_kind" = "startup" ] || [ "$source_kind" = "clear" ]; then
    echo "[gemkeeper] Active in this project. Use the gems skill to capture mission-critical facts (rules, decisions + reasons, dead ends, next step) to .gemkeeper/ledger.md as they come up."
  fi
  exit 0
fi

case "$source_kind" in
  compact)
    echo "[gemkeeper] The context was just compacted. The ledger below was written before compaction with full context."
    echo "Where it conflicts with the compaction summary about rules, decisions or dead ends, the ledger wins. Continue the current task. Don't restart it."
    ;;
  resume)
    echo "[gemkeeper] Current ledger for this project (it may have changed since this conversation was last active):"
    ;;
  *)
    echo "[gemkeeper] Ledger from earlier session(s) of this project. Follow the gems skill's Resume mode:"
    echo "verify '## Now' against git, then reply in at most three lines (mission, where we are, next step) unless the user already gave you a task."
    ;;
esac

echo "--- .gemkeeper/ledger.md ---"
total="$(wc -l < "$GK_LEDGER")"
max="$(gk_int "$GK_MAX_LINES" 250)"
head -n "$max" "$GK_LEDGER"
if [ "$total" -gt "$max" ]; then
  echo "[gemkeeper] Ledger truncated at $max of $total lines. It is too long: prune it during the next sweep."
fi
echo "--- end ledger ---"
exit 0
