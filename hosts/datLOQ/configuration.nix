{ config, lib, pkgs, ... }:

{
  imports =
   [
    ./nix-config/gpu.nix
    ./nix-config/networking.nix
    ./nix-config/nixld-appimage.nix
    ./nix-config/services.nix
    ./nix-config/packages.nix
   ];

  time.timeZone = "Europe/Istanbul";                               # Time zone
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; # Enable Nix Flakes
  nix.settings.auto-optimise-store = true;                         # Symlinks same store files
  nixpkgs.config.allowUnfree = true;                               # Allow unfree packages
  system.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)

  # Systemd-boot EFI boot loader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  # User account.
  users.users.dat = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "disk" ];
  };

  # System language
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "tr_TR.UTF-8/UTF-8"
    ];
  };

  # Weekly garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # TTY keyboard layout
  console.keyMap = "trq";

  # Systemd service to configure TTY keyboard repeat rate and delay
  systemd.services.tty-kbdrate = {
    description = "Set TTY keyboard rate and delay";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kbd}/bin/kbdrate -d 256 -r 32"; # -d is delay (ms), -r is rate (characters/second)
      RemainAfterExit = true;
    };
  };
}
