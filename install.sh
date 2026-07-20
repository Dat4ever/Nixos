#!/usr/bin/env bash
set -e

# Get configurations from github
git clone https://github.com/Dat4ever/Nixos /tmp/nixos-configurations
cd /tmp/nixos-configurations

# Create hardware-configuration
nixos-generate-config --no-filesystems --dir /tmp/new-hardware
cp /tmp/new-hardware/hardware-configuration.nix /tmp/nixos-configurations/hardware-configuration.nix
git add hardware-configuration.nix

# Partition with disko
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode zap_create_mount ./disko.nix

# Place configurations
mkdir -p /mnt/etc/nixos
cp -r /tmp/nixos-configurations/* /mnt/etc/nixos/

# Install packages
nixos-install --flake /mnt/etc/nixos#datLOQ

# User password
passwd dat

echo "Done!"
