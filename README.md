# datLOQ — My NixOS Setup

My flake-based NixOS configuration: Hyprland (Lua config) + Quickshell bar, Stylix theming (Nord), Home Manager, and disko for declarative disk partitioning.

## Quick install (fresh machine)

> [!WARNING]
> This **wipes the target disk**. `disko.nix` targets `/dev/nvme0n1` — before running anything, boot the ISO, run `lsblk`, and confirm that's the right device. If it's not, edit `disko.nix` first (on the ISO, or push a fix to the repo beforehand).

Boot a NixOS minimal ISO on the target machine, make sure it has network access, then run:

```sh
sudo -i
git clone https://github.com/Dat4ever/Nixos /tmp/nixos-configurations
cd /tmp/nixos-configurations
bash install.sh
```

`install.sh` does the rest end-to-end:

1. generates `hardware-configuration.nix` for this machine
2. partitions/formats the disk per `disko.nix` and mounts it under `/mnt`
3. copies this repo to `/mnt/etc/nixos`
4. runs `nixos-install` (prompts for the root password)
5. sets the `dat` user's password on the newly installed system

Reboot once it finishes.

## Updating an existing install

```sh
nrsf          # sudo nixos-rebuild switch --flake .
nfu-nrsf      # nix flake update && sudo nixos-rebuild switch --flake .
```
