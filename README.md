# datLOQ — My NixOS Setup

My flake-based NixOS config

## Hosts

| Host   | Status | Location        |
|--------|--------|-----------------|
| datLOQ | Active | hosts/datLOQ/   |
| datSV  | WIP    | hosts/datSV/    |

## Fresh install

> [!WARNING]
> Wipes the target disk. Confirm the device in `hosts/<host>/disko.nix` with `lsblk` first.

```sh
sudo -i
nix-shell -p git
git clone https://github.com/Dat4ever/Nixos /tmp/nixos-configurations
cd /tmp/nixos-configurations
bash install.sh <HOSTNAME> (only datLOQ works right now)
```

## After install aliases

```sh
nrsf          # sudo nixos-rebuild switch --flake .#datLOQ
nfu-nrsf      # nix flake update && sudo nixos-rebuild switch --flake .#datLOQ
ncg           # sudo nix-collect-garbage -d
```
