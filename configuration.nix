{ config, lib, pkgs, ... }:

{
 imports =
  [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./packages-services.nix
    ./stylix.nix
    ./disko.nix
  ];

  # General settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; # Enable Nix Flakes
  nix.settings.auto-optimise-store = true;                         # Symlinks same store files
  programs.nix-ld.enable = true;                                   # NixOS /lib to /nix/store

  # System settings
  networking.hostName = "datLOQ";                # Hostname
  time.timeZone = "Europe/Istanbul";             # Time zone

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dat = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "disk" ];
  };

  # Zram settings
  #zramSwap = {
    #enable = true;
    #algorithm = "zstd";
    #memoryPercent = 25;
  #};

  # Weekly garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Systemd service to configure TTY keyboard repeat rate and delay
  console.keyMap = "trq";                                 # Set the default keyboard layout for the TTY
  systemd.services.tty-kbdrate = {
    description = "Set TTY keyboard rate and delay";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kbd}/bin/kbdrate -d 256 -r 32"; # -d is delay (ms), -r is rate (characters/second)
      RemainAfterExit = true;
    };
  };

  # Fonts 
  fonts.packages = with pkgs; [
    (pkgs.stdenv.mkDerivation {
      pname = "jetbrains-mono-config";
      version = "1.0";
      src = ./config.d/JetBrainsMono; 
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp -r $src/*.{ttf,otf} $out/share/fonts/truetype/
      '';
    })
  ];

  # Open ports in the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 443 53317 ];
    allowedUDPPorts = [ 53317 ];
  };
  # Disable the firewall
  # networking.firewall.enable = false;

  # TTL setting
  networking.firewall.extraCommands = ''
    iptables -t mangle -A PREROUTING -j TTL --ttl-set 65
  '';

  system.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
