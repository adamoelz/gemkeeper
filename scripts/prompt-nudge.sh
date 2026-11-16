#!/usr/bin/env bash
# UserPromptSubmit hook: tiny periodic checkpoint nudges, plus one warning when the
# context gets heavy. Plain stdout from UserPromptSubmit is added to Claude's context.
set -u
. "$(dirname "$0")/lib.sh"
gk_init

every="$(gk_int "$GK_NUDGE_EVERY" 6)"
warn="$(gk_int "$GK_WARN_TOKENS" 100000)"

count=0
last_warn=0
if [ -f "$GK_STATE" ]; then
  count="$(sed -n 's/^count=//p' "$GK_STATE" | head -n 1)"
  last_warn="$(sed -n 's/^last_warn=//p' "$GK_STATE" | head -n 1)"
fi
count="$(gk_int "$count" 0)"
last_warn="$(gk_int "$last_warn" 0)"
count=$(( count + 1 ))

tokens=0
[ "$warn" -gt 0 ] && tokens="$(gk_context_tokens)"

# The context shrank (compaction, /clear) → re-arm the warning.
if [ "$last_warn" -gt 0 ] && [ "$tokens" -lt $(( last_warn / 2 )) ]; then
  last_warn=0
fi

message=""
pending=0
if [ "$warn" -gt 0 ] && [ "$tokens" -ge "$warn" ] \
   && { [ "$last_warn" -eq 0 ] || [ "$tokens" -ge $(( last_warn + last_warn / 4 )) ]; }; then
  k=$(( tokens / 1000 ))
  message="[gemkeeper] Context is at ~${k}k tokens. Before you answer, run a gems sweep (update .gemkeeper/ledger.md, rewrite '## Now'). Then handle the request and end your reply with one line telling the user it is safe to /clear."
  last_warn="$tokens"
elif gk_looks_like_gem; then
  message="[gemkeeper] gem check: this message likely states a rule, a decision and its reason, a dead end or a non-obvious fact. If something in it passes the ledger test and is not in .gemkeeper/ledger.md yet, add it first (one small edit, keep the reason, mark it (user)), then do the task."
  pending=1
elif [ "$every" -gt 0 ] && [ $(( count % every )) -eq 0 ]; then
  message="[gemkeeper] checkpoint: if anything since the last checkpoint passes the ledger test (a fresh session would get it wrong without it), save it to .gemkeeper/ledger.md in one small edit, then continue. If nothing qualifies, do nothing and don't mention it."
fi

# pending + ledger_sum let the Stop hook check whether a likely gem was actually saved this turn.
printf 'count=%s\nlast_warn=%s\npending=%s\nledger_sum=%s\n' "$count" "$last_warn" "$pending" "$(gk_ledger_sum)" \
  > "$GK_STATE" 2>/dev/null || true
[ -n "$message" ] && echo "$message"
exit 0
