#!/usr/bin/env bash
set -e

HOST="${1:-datLOQ}"

# Create hardware-configuration
nixos-generate-config --no-filesystems --dir /tmp/new-hardware
cp /tmp/new-hardware/hardware-configuration.nix /tmp/nixos-configurations/hosts/$HOST/hardware-configuration.nix
git -C /tmp/nixos-configurations add hosts/$HOST/hardware-configuration.nix

# Partition with disko
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount --yes-wipe-all-disks /tmp/nixos-configurations/hosts/$HOST/disko.nix

# Place configurations
mkdir -p /mnt/etc/nixos
cp -r /tmp/nixos-configurations/. /mnt/etc/nixos/

# Install packages
nixos-install --flake /mnt/etc/nixos#$HOST

# User password
nixos-enter --root /mnt -c 'passwd dat'

echo "Done!"
