#!/usr/bin/env bash
set -e

echo "1. Get configurations from github"
git clone https://github.com/Dat4ever/Nixos /tmp/nixos-configurations
cd /tmp/nixos-configurations

echo "2. Create hardware-configuration"
nixos-generate-config --no-filesystems --dir /tmp/new-hardware
cp /tmp/new-hardware/hardware-configuration.nix /tmp/nixos-configurations/hardware-configuration.nix
git add hardware-configuration.nix

echo "3. Partition with disko "
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode zap_create_mount ./disko.nix

echo "4. Place configurations"
mkdir -p /mnt/etc/nixos
cp -r /tmp/nixos-configurations/* /mnt/etc/nixos/

echo "5. install packages"
nixos-install --flake /mnt/etc/nixos#datLOQ

echo "6. password"
passwd dat

echo "Done!"
