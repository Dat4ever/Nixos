# datLOQ — My NixOS Setup

Flake-based NixOS config (Hyprland + QuickShell + Stylix Nord + Home Manager + disko).

## Hosts

| Host   | Status | Location        |
|--------|--------|-----------------|
| datLOQ | Active | hosts/datLOQ/   |
| datSV  | WIP    | hosts/datSV/    |

## Build (existing install)

```sh
sudo nixos-rebuild switch --flake .#datLOQ
# veya: nrsf-l
```

## Fresh install

> [!WARNING]
> Wipes the target disk. Confirm the device in `hosts/<host>/disko.nix` with `lsblk` first.

```sh
sudo -i
nix-shell -p git
git clone https://github.com/Dat4ever/Nixos /tmp/nixos-configurations
cd /tmp/nixos-configurations
bash install.sh datLOQ
```

## Updating an existing install

```sh
nrsf-l          # sudo nixos-rebuild switch --flake .#datLOQ
nfu-nrsf-l      # nix flake update && sudo nixos-rebuild switch --flake .#datLOQ
```
