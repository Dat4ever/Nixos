# datLOQ — My NixOS Setup

My flake-based NixOS configuration: Hyprland (Lua config) + Quickshell bar, Stylix theming (Nord), Home Manager, and disko for declarative disk partitioning.

## Hosts

| Host   | Description                          | Location                |
|--------|--------------------------------------|-------------------------|
| datLOQ | Laptop (Intel + NVIDIA, Hyprland)   | `hosts/datLOQ/`         |
| datSV  | Minimal placeholder for another box  | `hosts/datSV/`          |

Each host is fully self-contained under `hosts/<name>/` (its own `configuration.nix`, `hardware-configuration.nix`, `disko.nix`, `home.nix`, and dotfiles). Only `flake.nix`, `flake.lock`, `install.sh`, and this README live at the repo root.

## Building a host

```sh
# datLOQ (this laptop)
sudo nixos-rebuild switch --flake .#datLOQ
# or, from inside datLOQ:  nrsf-l

# datSV
sudo nixos-rebuild switch --flake .#datSV
# or, from inside datSV:   nrsf-s
```

## Quick install (fresh machine)

> [!WARNING]
> This **wipes the target disk**. `disko.nix` targets `/dev/nvme0n1` — before running anything, boot the ISO, run `lsblk`, and confirm that's the right device. If it's not, edit `hosts/<host>/disko.nix` first (on the ISO, or push a fix to the repo beforehand).

Boot a NixOS minimal ISO on the target machine, make sure it has network access, then run:

```sh
sudo -i
git clone https://github.com/Dat4ever/Nixos /tmp/nixos-configurations
cd /tmp/nixos-configurations
bash install.sh <host>   # e.g.  bash install.sh datLOQ
```

`install.sh` does the rest end-to-end:

1. generates `hardware-configuration.nix` for this machine into `hosts/<host>/`
2. partitions/formats the disk per `hosts/<host>/disko.nix` and mounts it under `/mnt`
3. copies this repo to `/mnt/etc/nixos`
4. runs `nixos-install --flake /mnt/etc/nixos#<host>` (prompts for the root password)
5. sets the `dat` user's password on the newly installed system

Reboot once it finishes.

## Updating an existing install

```sh
nrsf-l          # sudo nixos-rebuild switch --flake .#datLOQ   (on datLOQ)
nrsf-s          # sudo nixos-rebuild switch --flake .#datSV   (on datSV)
nfu-nrsf-l      # nix flake update && sudo nixos-rebuild switch --flake .#datLOQ
nfu-nrsf-s      # nix flake update && sudo nixos-rebuild switch --flake .#datSV
```
