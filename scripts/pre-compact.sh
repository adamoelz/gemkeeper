#!/usr/bin/env bash
# PreCompact hook: steer the compaction summary. The ledger is re-injected right after
# compaction by the SessionStart hook, so the summary shouldn't spend space repeating it.
# Recent Claude Code versions append this hook's stdout to the compaction instructions;
# older versions ignore it, which is harmless. Keep it short.
set -u
. "$(dirname "$0")/lib.sh"
gk_init

[ -s "$GK_LEDGER" ] || exit 0

echo "The file .gemkeeper/ledger.md (mission, rules, decisions, dead ends, next step) is re-injected automatically after compaction. Don't duplicate its contents. Spend the summary on in-flight work the ledger doesn't cover: exact file paths being edited, uncommitted changes, the last error message verbatim, and what the user asked for most recently."
exit 0
