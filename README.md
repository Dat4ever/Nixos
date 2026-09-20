# datLOQ — My NixOS Setup

Flake-based NixOS + Home Manager configuration for my daily-driver laptop
(datLOQ): Hyprland (Lua config), a Quickshell status bar, Kitty/Neovim/Yazi/Rofi,
a custom live theme switcher, and Syncthing sharing with my phone.

## Hosts

| Host   | Status | Location        | Notes                                                                  |
|--------|--------|-----------------|------------------------------------------------------------------------|
| datLOQ | Active | `hosts/datLOQ/` | Daily driver (Lenovo LOQ, Intel + NVIDIA hybrid).                      |
| datSV  | WIP    | `hosts/datSV/`  | Gitignored on purpose; flake output commented out until it is tracked. |

## Fresh install

> [!WARNING]
> Step 1 WIPES the target disk. Confirm the device in
> `hosts/datLOQ/disko.nix` with `lsblk` first.

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

```sh
mkdir -p /mnt/etc/nixos
cp -r . /mnt/etc/nixos/

nixos-install --flake /mnt/etc/nixos#datLOQ
nixos-enter --root /mnt -c 'passwd dat'

reboot
```

`git add` before installing matters: flakes can only see files tracked by
git.

After the first boot I keep working in `~/Nixos` and expose it as `/etc/nixos`
via a symlink, so rebuilds always use the current checkout:

```sh
sudo rm -rf /etc/nixos                  # the install-time copy
sudo ln -s /home/dat/Nixos /etc/nixos

# if the repo was copied/moved as root (e.g. out of /mnt/etc/nixos),
# fix ownership and permissions (`X` keeps the exec bit on scripts)
sudo chown -R dat:users /home/dat/Nixos
sudo chmod -R u=rwX,go=rX /home/dat/Nixos

nrsf                                    # -> flake /etc/nixos#datLOQ
```

## Aliases

Aliases target `/etc/nixos`, which is a symlink to this repo (see above), so
they work from any directory.

| Alias | Command |
|-------|---------|
| `nrsf` | `sudo nixos-rebuild switch --flake /etc/nixos#datLOQ` |
| `nfu-nrsf` | `nix flake update && sudo nixos-rebuild switch --flake /etc/nixos#datLOQ` |
| `ncg` | `sudo nix-collect-garbage -d` |
| `start-tor` / `stop-tor` | `sudo systemctl start` / `stop tor-transparent` |
