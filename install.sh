#!/usr/bin/env bash
# Standalone install (without the plugin system).
#   ./install.sh           → installs the skill + hook scripts, prints the hooks config
#   ./install.sh --hooks   → also merges the hooks into ~/.claude/settings.json (needs jq, makes a backup)
# Prefer the plugin install from the README if your Claude Code supports /plugin.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILL_DST="$CLAUDE_DIR/skills/gems"
HOOK_DST="$CLAUDE_DIR/gemkeeper"
SETTINGS="$CLAUDE_DIR/settings.json"

mkdir -p "$SKILL_DST" "$HOOK_DST/scripts"
cp -R "$SRC/skills/gems/." "$SKILL_DST/"
cp "$SRC"/scripts/*.sh "$HOOK_DST/scripts/"
chmod +x "$HOOK_DST"/scripts/*.sh
echo "✓ Skill installed to $SKILL_DST (use it as /gems)"
echo "✓ Hook scripts installed to $HOOK_DST/scripts"

HOOKS_JSON="$(sed "s|\${CLAUDE_PLUGIN_ROOT}|$HOOK_DST|g" "$SRC/hooks/hooks.json")"

if [ "${1:-}" = "--hooks" ]; then
  command -v jq >/dev/null || { echo "jq is required for --hooks. Add the config below by hand."; echo "$HOOKS_JSON"; exit 1; }
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
  tmp="$(mktemp)"
  # Append our matcher groups to any existing ones per event (doesn't remove yours).
  jq --argjson add "$HOOKS_JSON" '
    .hooks = ((.hooks // {}) as $h
      | reduce ($add.hooks | to_entries[]) as $e ($h;
          .[$e.key] = (((.[$e.key] // []) | map(select((tostring | test("gemkeeper/scripts")) | not))) + $e.value)))
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "✓ Hooks merged into $SETTINGS (backup saved next to it)"
else
  echo
  echo "To enable automatic re-injection and checkpoints, add this to $SETTINGS"
  echo "(or rerun with --hooks to merge it automatically):"
  echo
  echo "$HOOKS_JSON"
fi
echo
echo "Restart Claude Code to activate."
