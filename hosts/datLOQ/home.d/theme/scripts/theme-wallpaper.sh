#!/usr/bin/env bash
# Set the wallpaper from the current theme (used at session startup).
set -euo pipefail

THEMES_DIR="$HOME/.config/themes"
THEME_NAME="$(cat "$HOME/.local/state/theme/current" 2>/dev/null || echo nord)"
THEME_FILE="$THEMES_DIR/$THEME_NAME.conf"
[[ -f "$THEME_FILE" ]] || THEME_FILE="$THEMES_DIR/nord.conf"

# shellcheck disable=SC1090
source "$THEME_FILE"

WALL="$HOME/.config/wallpapers/$wallpaper"
if [[ -f "$WALL" ]]; then
  HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
  mkdir -p "$HOME/.config/hypr"
  monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name // empty' 2>/dev/null || true)"
  monitor="${monitor:-eDP-1}"
  cat > "$HYPRPAPER_CONF" <<EOF
splash = false
wallpaper {
    monitor = $monitor
    path = $WALL
}
EOF
  pkill -f hyprpaper 2>/dev/null || true
  sleep 0.3
  nohup hyprpaper >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi
