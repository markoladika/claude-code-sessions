#!/bin/bash
# claude-code-sessions installer — adds the claude() session wrapper + helpers to your shell rc.
#   claude <name>      resume the saved session of that name if it exists, else start NEW
#   claude ls          list this project's saved sessions
#   claude rm <name>   delete a saved session (so `claude <name>` starts fresh)
#   bypass-permissions available as a Shift+Tab toggle on interactive launches
#   real subcommands (mcp/config/...) pass through untouched
#
# Targets ~/.zshrc by default. Pass a path to target another rc (e.g. ~/.bashrc):
#   bash setup_claude_wrapper.sh ~/.bashrc
# Idempotent (replaces any prior block); backs up the rc first.
# Requires: python3 (and jq for the status line). Relocatable — runs from wherever it lives.

set -e
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CC="$KIT_DIR/cc-sessions.py"
RC="${1:-$HOME/.zshrc}"
[ -f "$RC" ] || touch "$RC"
cp "$RC" "$RC.bak.$(date +%Y%m%d%H%M%S)"

# Remove any prior block — old single-marker style...
if grep -q "# claude-session-namer" "$RC"; then
  awk '/# claude-session-namer/{s=1} s&&/^}/{s=0;next} !s' "$RC" > "$RC.t" && mv "$RC.t" "$RC"
fi
# ...and sentinel styles (previous cc-wrapper/cc-kit, current cc-sessions).
for S in cc-wrapper cc-kit cc-sessions; do
  if grep -q "# >>> $S >>>" "$RC"; then
    awk -v a="# >>> $S >>>" -v b="# <<< $S <<<" '$0~a{s=1} !s{print} $0~b{s=0}' "$RC" > "$RC.t" && mv "$RC.t" "$RC"
  fi
done

# Path line (expanded), then functions (literal).
cat >> "$RC" <<EOF1

# >>> cc-sessions >>>
_CCK="$CC"
EOF1
cat >> "$RC" <<'EOF2'
claude() {
  case "$1" in
    ls) shift; python3 "$_CCK" list "$@" ;;
    rm) shift; python3 "$_CCK" delete "$@" ;;
    mcp|config|agents|plugin|plugins|auth|doctor|update|upgrade|install|migrate-installer|setup-token|project|ultrareview|auto-mode|help|version)
      command claude "$@" ;;
    ""|-*)
      command claude --allow-dangerously-skip-permissions "$@" ;;
    *)
      local _n="$1"; shift
      local _sid; _sid="$(python3 "$_CCK" resolve "$_n" 2>/dev/null)"
      if [ -n "$_sid" ]; then
        echo "↻ resuming '$_n' ($_sid)"
        command claude --allow-dangerously-skip-permissions -r "$_sid" "$@"
      else
        command claude --allow-dangerously-skip-permissions --name "$_n" "$@"
      fi ;;
  esac
}
# <<< cc-sessions <<<
EOF2

echo "[done] claude-code-sessions installed to $RC (backup saved alongside)."
echo "Run:  source $RC"
echo "  claude <name> -> resume-or-new | claude ls -> list | claude rm <name> -> delete"
