# datLOQ — My NixOS Setup

My flake-based NixOS config

## Hosts

| Host   | Status | Location        |
|--------|--------|-----------------|
| datLOQ | Active | hosts/datLOQ/   |
| datSV  | WIP    | hosts/datSV/    |

## Fresh install

> [!WARNING]
> Step 1 WIPES the target disk. Confirm the device in
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
lsblk    # confirm the target device first!

nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks hosts/datLOQ/disko.nix

findmnt /mnt    # must show the mounted root
```

### 2) Generate hardware-configuration

```sh
nixos-generate-config --no-filesystems --dir /tmp/new-hardware
cp /tmp/new-hardware/hardware-configuration.nix hosts/datLOQ/
git add hosts/datLOQ/hardware-configuration.nix
```

### 3) Install

`datfetch` lives in-repo at `./datfetch`, so the flake works out of the box.

```sh
mkdir -p /mnt/etc/nixos
cp -r . /mnt/etc/nixos/

nixos-install --flake /mnt/etc/nixos#datLOQ    # also asks for the root password
nixos-enter --root /mnt -c 'passwd dat'

reboot
```

`git add` before installing matters: flakes can only see files tracked by
git. After the first boot, rebuild from `/etc/nixos` (`nrsf`).

## After install aliases

```sh
nrsf          # sudo nixos-rebuild switch --flake .#datLOQ
nfu-nrsf      # nix flake update && sudo nixos-rebuild switch --flake .#datLOQ
ncg           # sudo nix-collect-garbage -d
```
