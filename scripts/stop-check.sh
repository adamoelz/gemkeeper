#!/usr/bin/env bash
# Stop hook: safety net for the gem check. If the user's last message looked like it held a gem
# and the ledger did not change during the turn, ask Claude once to capture it before stopping.
# Never blocks twice in a row, and never when the turn had no gem marker.
set -u
. "$(dirname "$0")/lib.sh"
gk_init

[ "$(gk_state_get pending)" = "1" ] || exit 0
gk_state_set pending 0

# Already continuing because of this hook → let it stop.
printf '%s' "$GK_INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

[ "$(gk_state_get ledger_sum)" != "$(gk_ledger_sum)" ] && exit 0

echo '{"decision":"block","reason":"[gemkeeper] The user'"'"'s last message looked like it held a rule, a decision and its reason, a dead end or a non-obvious fact, and .gemkeeper/ledger.md did not change this turn. If something in it passes the ledger test, add it now in one small edit. If nothing qualifies, stop without comment."}'
exit 0
