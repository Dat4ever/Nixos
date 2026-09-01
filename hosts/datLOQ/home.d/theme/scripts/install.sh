#!/usr/bin/env bash
# Portable theme system installer. On NixOS, home-manager handles this automatically (theme.nix), so this script is mainly for other disros.
set -euo pipefail

# Resolve the repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

THEME_DIR="$REPO_ROOT"
WALLPAPER_DIR="$THEME_DIR/wallpapers"
FONTS_DIR="$THEME_DIR/fonts"
CURSORS_DIR="$THEME_DIR/cursors"
GTKQT_DIR="$THEME_DIR/gtk-qt"
SCRIPTS_DIR="$THEME_DIR/scripts"

echo "installing theme system from $THEME_DIR"

# Symlink themes + wallpapers
mkdir -p "$HOME/.config"
ln -sfn "$THEME_DIR" "$HOME/.config/themes"
ln -sfn "$WALLPAPER_DIR" "$HOME/.config/wallpapers"

# Symlink scripts
mkdir -p "$HOME/.local/bin"
for f in "$SCRIPTS_DIR"/*.sh; do
  name="$(basename "$f" .sh)"
  ln -sfn "$f" "$HOME/.local/bin/$name"
  chmod +x "$f"
done

# Install fonts
mkdir -p "$HOME/.local/share/fonts"
for font_sub in "$FONTS_DIR"/*/; do
  font_name="$(basename "$font_sub")"
  target="$HOME/.local/share/fonts/$font_name"
  rm -rf "$target"
  cp -r "$font_sub" "$target"
done
chmod -R u+w "$HOME/.local/share/fonts/" 2>/dev/null || true
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$HOME/.local/share/fonts/" >/dev/null 2>&1 || true
fi

# Install cursor themes
mkdir -p "$HOME/.local/share/icons"
for cursor_sub in "$CURSORS_DIR"/*/; do
  cursor_name="$(basename "$cursor_sub")"
  target="$HOME/.local/share/icons/$cursor_name"
  chmod -R u+w "$target" 2>/dev/null || true
  rm -rf "$target"
  cp -r "$cursor_sub" "$target"
  chmod -R u+w "$target"
done

# Install GTK themes
mkdir -p "$HOME/.local/share/themes"
for theme_sub in "$GTKQT_DIR/themes"/*/; do
  theme_name="$(basename "$theme_sub")"
  target="$HOME/.local/share/themes/$theme_name"
  chmod -R u+w "$target" 2>/dev/null || true
  rm -rf "$target"
  cp -r "$theme_sub" "$target"
  chmod -R u+w "$target"
done

# Install Kvantum themes
mkdir -p "$HOME/.local/share/Kvantum"
for kv_sub in "$GTKQT_DIR/kvantum"/*/; do
  kv_name="$(basename "$kv_sub")"
  target="$HOME/.local/share/Kvantum/$kv_name"
  chmod -R u+w "$target" 2>/dev/null || true
  rm -rf "$target"
  cp -r "$kv_sub" "$target"
  chmod -R u+w "$target"
done

# Apply current theme
if command -v theme-switch >/dev/null 2>&1; then
  theme="$(cat "$HOME/.local/state/theme/current" 2>/dev/null || echo nord)"
  theme-switch "$theme"
else
  "$HOME/.local/bin/theme-switch" "$(cat "$HOME/.local/state/theme/current" 2>/dev/null || echo nord)"
fi

echo ""
echo "theme system installed from $THEME_DIR"
echo "switch themes with: theme-switch nord | theme-switch gruvbox"
