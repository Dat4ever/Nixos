#!/usr/bin/env bash
# NixOS installer for this flake.
#
# By default this script NEVER touches the disk: partition & mount first
# with the disko step from the README (or pass --format to have this
# script do it after a typed confirmation).
#
# Usage:
#   bash install.sh [HOST]            # install to the already-mounted /mnt
#   bash install.sh [HOST] --format   # ALSO wipe/format/mount via disko
set -euo pipefail

# ---------------------------------------------------------------- helpers
log()  { printf '\033[1;36m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf '\033[0;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

CURRENT_STEP="init"
trap 'printf "\033[0;31mFAILED\033[0m in step: %s (line %s)\n" "$CURRENT_STEP" "${BASH_LINENO[0]:-?}" >&2; printf "Check disk state with: lsblk\n" >&2' ERR

# ---------------------------------------------------------------- args
HOST="datLOQ"
FORMAT=0
for arg in "$@"; do
  case "$arg" in
    --format) FORMAT=1 ;;
    -h|--help) echo "usage: install.sh [HOST] [--format]"; exit 0 ;;
    *) HOST="$arg" ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------- preflight
CURRENT_STEP="preflight"
[ "$(id -u)" -eq 0 ] || die "run as root (sudo -i)"
[ -f "$REPO_DIR/hosts/$HOST/configuration.nix" ] || die "host '$HOST' not found in $REPO_DIR/hosts/"
[ -f "$REPO_DIR/hosts/$HOST/disko.nix" ] || die "disko.nix not found for host '$HOST'"

curl -sfI -m 10 https://github.com >/dev/null || die "no network access (nix needs it to fetch disko and store paths)"

# ---------------------------------------------------------------- format (opt-in)
if [ "$FORMAT" -eq 1 ]; then
  CURRENT_STEP="disko"
  DEVICE="$(grep -oP '^\s*device\s*=\s*"\K[^"]+' "$REPO_DIR/hosts/$HOST/disko.nix" | head -1)"
  [ -n "$DEVICE" ] || die "could not find the target device in hosts/$HOST/disko.nix"
  [ -b "$DEVICE" ] || die "target device $DEVICE does not exist on this machine"
  log "Disko will DESTROY ALL DATA on: $DEVICE"
  lsblk
  printf 'Type "yes" to wipe %s: ' "$DEVICE"
  read -r ANSWER
  [ "$ANSWER" = "yes" ] || die "aborted"
  nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode destroy,format,mount --yes-wipe-all-disks \
    "$REPO_DIR/hosts/$HOST/disko.nix"
fi

CURRENT_STEP="mount check"
findmnt /mnt >/dev/null || die "/mnt is not mounted. Partition & mount the disks first (see README), or re-run with --format"

# ---------------------------------------------------------------- datfetch
# The datfetch flake input points to a local path that does not exist on a
# fresh installer (e.g. live ISO). When the project is present, bundle a copy
# into the repo and switch the input to a relative path. Otherwise drop the
# input and its usage so the flake still evaluates.
CURRENT_STEP="datfetch"
DATFETCH_SRC="${DATFETCH_DIR:-/home/dat/Documents/projects/Datfetch}"
if [ -d "$DATFETCH_SRC" ]; then
  info "Datfetch found at $DATFETCH_SRC - bundling into repo"
  rm -rf "$REPO_DIR/datfetch"
  cp -r "$DATFETCH_SRC" "$REPO_DIR/datfetch"
  rm -rf "$REPO_DIR/datfetch/.git"
  sed -i 's|path:/home/dat/Documents/projects/Datfetch|path:./datfetch|' "$REPO_DIR/flake.nix"
  git -C "$REPO_DIR" add datfetch flake.nix
else
  info "Datfetch not found - removing flake input (binary will not be installed)"
  sed -i '/# Datfetch (local)/,/^    };/d' "$REPO_DIR/flake.nix"
  grep -rl 'inputs\.datfetch\.packages' "$REPO_DIR/hosts/$HOST" | xargs -r sed -i '/inputs\.datfetch\.packages/d'
  git -C "$REPO_DIR" add flake.nix
  git -C "$REPO_DIR" add "hosts/$HOST"
fi

# ---------------------------------------------------------------- hardware
CURRENT_STEP="hardware-configuration"
log "Generating hardware-configuration"
nixos-generate-config --no-filesystems --dir /tmp/new-hardware
cp /tmp/new-hardware/hardware-configuration.nix "$REPO_DIR/hosts/$HOST/hardware-configuration.nix"
git -C "$REPO_DIR" add "hosts/$HOST/hardware-configuration.nix"

# ---------------------------------------------------------------- copy
CURRENT_STEP="copy config to /mnt"
rm -rf /mnt/etc/nixos
mkdir -p /mnt/etc/nixos
cp -r "$REPO_DIR/." /mnt/etc/nixos/

# ---------------------------------------------------------------- install
CURRENT_STEP="nixos-install"
log "Installing NixOS (this can take a while)"
nixos-install --flake /mnt/etc/nixos#$HOST

# ---------------------------------------------------------------- passwords
CURRENT_STEP="user password"
nixos-enter --root /mnt -c 'passwd dat'

log "Done! Reboot into $HOST whenever you are ready."
