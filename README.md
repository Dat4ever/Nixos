# datLOQ — My NixOS Setup

A flake-based NixOS configuration: Hyprland (Lua config) + Quickshell bar, Stylix theming (Nord), Home Manager, and disko for declarative disk partitioning.

## Stack

| Layer         | Tool                              |
| ------------- | ---------------------------------- |
| Window manager| [Hyprland](https://hyprland.org) |
| Bar / shell   | [Quickshell](https://quickshell.org) |
| Theming       | [Stylix](https://github.com/nix-community/stylix) (Nord palette) |
| Dotfiles      | [Home Manager](https://github.com/nix-community/home-manager) |
| Disk layout   | [disko](https://github.com/nix-community/disko) |
| File manager  | [yazi](https://yazi-rs.github.io) |

## Quick install (fresh machine)

> [!WARNING]
> This **wipes the target disk**. `disko.nix` targets `/dev/nvme0n1` — before running anything, boot the ISO, run `lsblk`, and confirm that's the right device. If it's not, edit `disko.nix` first (on the ISO, or push a fix to the repo beforehand).

Boot a NixOS minimal ISO on the target machine, make sure it has network access, then run:

```sh
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

## Layout

```
.
├── configuration.nix       # system config
├── hardware-configuration.nix
├── disko.nix                # disk layout
├── nvidia.nix                # GPU config
├── stylix.nix                # theme
├── home.nix                  # home-manager entry point
├── home-config/              # dotfiles sourced by home.nix
│   ├── hypr/                 # Hyprland (Lua config)
│   ├── quickshell/            # bar/shell (QML)
│   ├── nvim/, kitty/, rofi/, btop/, yazi/, bashrc
├── install.sh                 # fresh-install script (see above)
└── flake.nix
```
