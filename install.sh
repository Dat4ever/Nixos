#!/usr/bin/env bash
set -e

# Create hardware-configuration
nixos-generate-config --no-filesystems --dir /tmp/new-hardware
cp /tmp/new-hardware/hardware-configuration.nix /tmp/nixos-configurations/hardware-configuration.nix
git add hardware-configuration.nix

# Partition with disko
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount --yes-wipe-all-disks ./disko.nix

# Place configurations
mkdir -p /mnt/etc/nixos
cp -r /tmp/nixos-configurations/. /mnt/etc/nixos/

# Install packages
nixos-install --flake /mnt/etc/nixos#datLOQ

# User password
nixos-enter --root /mnt -c 'passwd dat'

echo "Done!"
