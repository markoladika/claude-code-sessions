#!/usr/bin/env bash
# Machine-wide Claude Code status line.
# Format: ctx:2% | token:23k | 5h:6pm ▓▓░░░ 31% | 7d:Thu 4am 10% | Opus 4.8
#   ctx   = context-window usage %      token = current context input tokens
#   5h    = 5h-limit reset time + small usage bar + usage %
#   7d    = 7d-limit reset day/time + usage %        Model = current model
# Reads session JSON on stdin (see code.claude.com/docs/en/statusline). Needs jq.

input=$(cat)
j(){ printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

PCT=$(j '.context_window.used_percentage // 0' | cut -d. -f1)
IN=$(j '.context_window.total_input_tokens // 0')
FIVE=$(j '.rate_limits.five_hour.used_percentage // empty')
FIVE_R=$(j '.rate_limits.five_hour.resets_at // empty')
WEEK=$(j '.rate_limits.seven_day.used_percentage // empty')
WEEK_R=$(j '.rate_limits.seven_day.resets_at // empty')
MODEL=$(j '.model.display_name // empty')

case "$PCT" in ''|*[!0-9]*) PCT=0 ;; esac
case "$IN"  in ''|*[!0-9]*) IN=0 ;; esac

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'
colorfor(){ if [ "$1" -ge 90 ]; then printf '%s' "$RED"; elif [ "$1" -ge 70 ]; then printf '%s' "$YELLOW"; else printf '%s' "$GREEN"; fi; }

hum(){ if [ "$1" -ge 1000000 ]; then awk "BEGIN{printf \"%.1fM\", $1/1000000}"; else echo "$(( $1 / 1000 ))k"; fi; }
# Reset time in local time, cross-platform (BSD date -r / GNU date -d @).
fmt_hour(){ local e="$1" h ap; h=$(date -r "$e" +'%I' 2>/dev/null) || h=$(date -d "@$e" +'%I' 2>/dev/null); ap=$(date -r "$e" +'%p' 2>/dev/null) || ap=$(date -d "@$e" +'%p' 2>/dev/null); [ -z "$h" ] && return; h=${h#0}; [ -z "$h" ] && h=12; printf '%s%s' "$h" "$(printf '%s' "$ap" | tr '[:upper:]' '[:lower:]')"; }
fmt_dayhour(){ local e="$1" d t; d=$(date -r "$e" +'%a' 2>/dev/null) || d=$(date -d "@$e" +'%a' 2>/dev/null); t=$(fmt_hour "$e"); [ -z "$t" ] && return; printf '%s %s' "$d" "$t"; }
# Small 5-char usage bar (20% per block), colored by level.
bar5(){ local p="$1" f e; f=$(( p / 20 )); [ "$f" -gt 5 ] && f=5; e=$(( 5 - f )); local F E; printf -v F "%${f}s"; printf -v E "%${e}s"; printf '%s%s%s%s' "$(colorfor "$p")" "${F// /▓}" "${E// /░}" "$RESET"; }

OUT="$(colorfor "$PCT")ctx:${PCT}%${RESET} | token:$(hum "$IN")"

if [ -n "$FIVE_R" ]; then
  seg="5h:$(fmt_hour "$FIVE_R")"
  if [ -n "$FIVE" ]; then fi=$(printf '%.0f' "$FIVE"); seg="$seg $(bar5 "$fi") ${fi}%"; fi
  OUT="$OUT | $seg"
fi

if [ -n "$WEEK_R" ] || [ -n "$WEEK" ]; then
  seg="7d:"
  [ -n "$WEEK_R" ] && seg="${seg}$(fmt_dayhour "$WEEK_R") "
  [ -n "$WEEK" ] && seg="${seg}$(printf '%.0f' "$WEEK")%"
  OUT="$OUT | $seg"
fi

[ -n "$MODEL" ] && OUT="$OUT | $MODEL"
printf '%b\n' "$OUT"
