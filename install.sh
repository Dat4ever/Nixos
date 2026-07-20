#!/usr/bin/env bash
set -e

echo "1."
git clone https://github.com/Dat4ever/Nixos /tmp/dotfiles
cd /tmp/dotfiles

echo "2."
nixos-generate-config --no-filesystems --dir /tmp/new-hardware
cp /tmp/new-hardware/hardware-configuration.nix /tmp/dotfiles/hardware-configuration.nix
git add hardware-configuration.nix

echo "3."
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode zap_create_mount ./disko.nix

echo "4."
mkdir -p /mnt/etc/nixos
cp -r /tmp/dotfiles/* /mnt/etc/nixos/

echo "5."
nixos-install --flake /mnt/etc/nixos#datLOQ

echo "Done!"
