#!/usr/bin/env bash
# Rofi-based theme picker. Lists themes and applies the selected one.
set -euo pipefail

THEMES_DIR="$HOME/.config/themes"

list=""
for f in "$THEMES_DIR"/*.conf; do
  [[ -f "$f" ]] || continue
  name="$(grep -m1 '^name=' "$f" | sed -E 's/^name="(.*)"$/\1/')"
  list+="$name\n"
done

choice="$(printf '%b' "$list" | rofi -dmenu -i -p 'Theme' -no-custom 2>/dev/null)"
[[ -z "$choice" ]] && exit 0

for f in "$THEMES_DIR"/*.conf; do
  [[ -f "$f" ]] || continue
  name="$(grep -m1 '^name=' "$f" | sed -E 's/^name="(.*)"$/\1/')"
  if [[ "$name" == "$choice" ]]; then
    theme-switch "$(basename "$f" .conf)"
    exit 0
  fi
done
