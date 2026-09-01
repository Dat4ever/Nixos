# datLOQ — My NixOS Setup

My flake-based NixOS config

## Hosts

| Host   | Status | Location        |
|--------|--------|-----------------|
| datLOQ | Active | hosts/datLOQ/   |
| datSV  | WIP    | hosts/datSV/    |

## Fresh install

> [!WARNING]
> The partitioning step below WIPES the target disk. Confirm the device in
> `hosts/<host>/disko.nix` with `lsblk` first.

Boot the NixOS minimal ISO, then:

```sh
sudo -i
nix-shell -p git
git clone https://github.com/Dat4ever/Nixos /tmp/nixos-configurations
cd /tmp/nixos-configurations
```

### 1) Partition & mount (one time — destroys the disk)

```sh
nix run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks hosts/datLOQ/disko.nix
```

(Alternatively `bash install.sh datLOQ --format` does the same after a typed
confirmation.)

### 2) Install

```sh
bash install.sh datLOQ    # only datLOQ works right now
```

The installer checks that `/mnt` is mounted, generates hardware-configuration,
and runs nixos-install. It never touches the disk on its own.

> [!NOTE]
> `datfetch` is a local flake input. If its project folder is not present on
> the machine running the installer, it is removed from the flake and the
> binary is not installed.

### 3) Reboot

Both the root password (asked by nixos-install) and the `dat` user password
(asked at the end of the installer) are set during installation.

## After install aliases

```sh
nrsf          # sudo nixos-rebuild switch --flake .#datLOQ
nfu-nrsf      # nix flake update && sudo nixos-rebuild switch --flake .#datLOQ
ncg           # sudo nix-collect-garbage -d
```
