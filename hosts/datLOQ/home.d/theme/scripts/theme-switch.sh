#!/usr/bin/env bash
# Live theme switcher. Reads a theme from ~/.config/themes/<name>.conf, writes the config files and live-applies to running apps: kitty colors, Hyprland border/shadow/cursor, dconf/GTK, and clean full restarts of hyprpaper and quickshell (old processes are waited out completely before the new ones start). --if-changed exits silently when theme inputs are unchanged, so the home-manager activation on rebuilds never pokes the running session for the same theme.
set -euo pipefail

IF_CHANGED=0
if [[ "${1:-}" == "--if-changed" ]]; then
  IF_CHANGED=1
  shift
fi

THEMES_DIR="$HOME/.config/themes"
TEMPLATES_DIR="$THEMES_DIR/homeconfig"
THEME_NAME="${1:-nord}"
THEME_FILE="$THEMES_DIR/$THEME_NAME.conf"

if [[ ! -f "$THEME_FILE" ]]; then
  echo "error: theme not found: $THEME_NAME ($THEME_FILE)" >&2
  echo "available themes:" >&2
  for f in "$THEMES_DIR"/*.conf; do
    [[ -f "$f" ]] && echo "  - $(basename "$f" .conf)" >&2
  done
  exit 1
fi

# shellcheck disable=SC1090
source "$THEME_FILE"

# Hash of every theme input (conf + templates) to detect no-op switches
INPUTS_HASH="$(
  {
    cat "$THEME_FILE"
    find "$TEMPLATES_DIR" -type f -print0 2>/dev/null | sort -z | xargs -0 -r cat 2>/dev/null
  } | sha256sum | cut -d' ' -f1
)"
HASH_FILE="$HOME/.local/state/theme/.applied-hash"
if [[ "$IF_CHANGED" == "1" && -f "$HASH_FILE" && "$(cat "$HASH_FILE" 2>/dev/null)" == "$INPUTS_HASH" ]]; then
  exit 0
fi

# Render a template file, substituting the __colorXX__ placeholders. Writes to a temp file and moves it into place, so a failed render never leaves a broken/partial config behind (rofi/quickshell keep working).
render() {
  local template="$1" output="$2" tmp
  local sedargs=() var
  for var in color00 color01 color02 color03 color04 color05 color06 color07 \
             color08 color09 color0A color0B color0C color0D color0E color0F; do
    sedargs+=( -e "s|__${var}__|${!var}|g" )
  done
  tmp="$(mktemp "${output}.tmp.XXXXXX")" || return 1
  if sed "${sedargs[@]}" "$template" > "$tmp"; then
    mv -f "$tmp" "$output"
  else
    rm -f "$tmp"
    return 1
  fi
}

# Fully stop processes matching a pattern
kill_wait() {
  local pat="$1"
  pkill -f "$pat" 2>/dev/null || true
  for _ in $(seq 1 50); do
    pgrep -f "$pat" >/dev/null 2>&1 || return 0
    sleep 0.1
  done
  pkill -9 -f "$pat" 2>/dev/null || true
  sleep 0.1
}

# kitty
KITTY_COLORS="$HOME/.config/kitty/colors.conf"
mkdir -p "$HOME/.config/kitty"
render "$TEMPLATES_DIR/kitty.colors.conf" "$KITTY_COLORS"

# Live-reload colors into running kitty instances
if command -v kitten >/dev/null 2>&1; then
  kitten @ set-colors --all --configured "$KITTY_COLORS" >/dev/null 2>&1 || true
fi

# rofi
ROFI_THEME="$HOME/.config/rofi/theme.rasi"
mkdir -p "$HOME/.config/rofi"
render "$TEMPLATES_DIR/rofi.theme.rasi" "$ROFI_THEME"

# quickshell
QS_COLORS="$HOME/.config/quickshell/Colors.qml"
mkdir -p "$HOME/.config/quickshell"
render "$TEMPLATES_DIR/quickshell.Colors.qml" "$QS_COLORS"

# yazi
YAZI_THEME="$HOME/.config/yazi/theme.toml"
mkdir -p "$HOME/.config/yazi"
render "$TEMPLATES_DIR/yazi.theme.toml" "$YAZI_THEME"

# yazi syntect
render "$TEMPLATES_DIR/yazi.tmTheme" "$HOME/.config/yazi/syntect.tmTheme"

# GTK
for v in 3.0 4.0; do
  d="$HOME/.config/gtk-$v"
  mkdir -p "$d"
  cat > "$d/settings.ini" <<EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-application-prefer-dark-theme=${gtk_dark:-1}
gtk-font-name=Geist 12
gtk-cursor-theme-name=${cursor_theme:-Capitaine Cursors (Nord)}
gtk-cursor-theme-size=32
EOF
done

# GTK4/libadwaita apps
if command -v dconf >/dev/null 2>&1; then
  dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" 2>/dev/null || true
  dconf write /org/gnome/desktop/interface/cursor-theme "'${cursor_theme:-Capitaine Cursors (Nord)}'" 2>/dev/null || true
  dconf write /org/gnome/desktop/interface/font-name "'Geist 12'" 2>/dev/null || true
  if [[ "${gtk_dark:-1}" == "1" ]]; then
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
  else
    dconf write /org/gnome/desktop/interface/color-scheme "'default'" 2>/dev/null || true
  fi
fi

# Qt (qt6ct / qt5ct)
for c in qt6ct qt5ct; do
  d="$HOME/.config/$c"
  mkdir -p "$d"
  cat > "$d/$c.conf" <<EOF
[Appearance]
style=kvantum
standard_dialogs=default

[Fonts]
fixed="CommitMono Nerd Font,12"
general="Geist,12"
EOF
done

# Kvantum
KV_DIR="$HOME/.config/Kvantum"
mkdir -p "$KV_DIR"
if [[ -d "$HOME/.config/kvantum-themes/$kvantum_theme" ]]; then
  chmod -R u+w "${KV_DIR:?}/$kvantum_theme" 2>/dev/null || true
  rm -rf "${KV_DIR:?}/$kvantum_theme"
  cp -r "$HOME/.config/kvantum-themes/$kvantum_theme" "$KV_DIR/$kvantum_theme"
  chmod -R u+w "$KV_DIR/$kvantum_theme"
fi
cat > "$KV_DIR/kvantum.kvconfig" <<EOF
[General]
theme=$kvantum_theme
EOF

# opencode
OPENCODE_TUI="$HOME/.config/opencode/tui.json"
mkdir -p "$HOME/.config/opencode"
cat > "$OPENCODE_TUI" <<EOF
{
  "\$schema": "https://opencode.ai/tui.json",
  "theme": "${opencode_theme:-$THEME_NAME}"
}
EOF

# btop
BTOP_CONF="$HOME/.config/btop/btop.conf"
mkdir -p "$HOME/.config/btop"
cat > "$BTOP_CONF" <<EOF
color_theme = "${btop_theme:-nord}"
theme_background = False
rounded_corners = True
proc_tree = True
graph_symbol = "braille"
proc_sorting = "cpu lazy"
EOF

# Neovim
NVIM_THEME="$HOME/.local/share/nvim/theme.lua"
mkdir -p "$HOME/.local/share/nvim"
render "$TEMPLATES_DIR/nvim.colors.lua" "$NVIM_THEME"

# firefox
FIREFOX_BASE="$HOME/.config/mozilla/firefox"
if [[ -f "$FIREFOX_BASE/profiles.ini" ]]; then
  FIREFOX_PROFILE="$(awk -F= '/^Path=/ { path=$2 } END { print path }' "$FIREFOX_BASE/profiles.ini")"
  if [[ -n "$FIREFOX_PROFILE" ]]; then
    if [[ "$FIREFOX_PROFILE" = /* ]]; then
      PROFILE_DIR="$FIREFOX_PROFILE"
    else
      PROFILE_DIR="$FIREFOX_BASE/$FIREFOX_PROFILE"
    fi
    mkdir -p "$PROFILE_DIR/chrome"
    render "$TEMPLATES_DIR/firefox.userChrome.css" "$PROFILE_DIR/chrome/userChrome.css"
    render "$TEMPLATES_DIR/firefox.userContent.css" "$PROFILE_DIR/chrome/userContent.css"
    cat > "$PROFILE_DIR/user.js" <<'EOF'
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
EOF
  fi
fi

# Wallpaper
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
fi

# Hyprland state
HYPR_STATE="$HOME/.local/state/theme/hyprland.colors"
mkdir -p "$(dirname "$HYPR_STATE")"
c00="${color00#\#}"
c03="${color03#\#}"
c07="${color07#\#}"
c0D="${color0D#\#}"
cat > "$HYPR_STATE" <<EOF
color00=$c00
color03=$c03
color07=$c07
color0D=$c0D
cursor_theme=${cursor_theme:-Capitaine Cursors (Nord)}
EOF

# Live-apply borders/shadow/cursor to the running compositor
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl eval "hl.config({general={['col.active_border']={colors={'rgba(${c0D}ee)','rgba(${c07}ee)'},angle=45}}})" >/dev/null 2>&1 || true
  hyprctl eval "hl.config({general={['col.inactive_border']='rgba(${c03}aa)'}})" >/dev/null 2>&1 || true
  hyprctl eval "hl.config({decoration={shadow={color='rgba(${c00}ee)'}}})" >/dev/null 2>&1 || true
  hyprctl setcursor "${cursor_theme:-Capitaine Cursors (Nord)}" 32 >/dev/null 2>&1 || true
fi

# Restart themed components
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  if [[ -f "$WALL" ]]; then
    kill_wait hyprpaper
    setsid nohup hyprpaper </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null || true
  fi

  kill_wait quickshell
  setsid nohup qs </dev/null >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi

# Save active theme + inputs hash
mkdir -p "$HOME/.local/state/theme"
echo "$THEME_NAME" > "$HOME/.local/state/theme/current"
printf '%s\n' "$INPUTS_HASH" > "$HASH_FILE"

echo "theme applied: $name"
