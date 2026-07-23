{ config, lib, pkgs, ... }:

{
 imports =
  [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./stylix.nix
    ./disko.nix
  ];

  # General settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; # Enable Nix Flakes
  nix.settings.auto-optimise-store = true;                         # Symlinks same store files
  nixpkgs.config.allowUnfree = true;                               # Allow unfree packages

  # System settings
  networking.hostName = "datLOQ";                # Hostname
  time.timeZone = "Europe/Istanbul";             # Time zone

  # System language
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "tr_TR.UTF-8/UTF-8"
    ];
  };

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

  # Weekly garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Systemd service to configure TTY keyboard repeat rate and delay
  console.keyMap = "trq"; # Set the default keyboard layout for the TTY
  systemd.services.tty-kbdrate = {
    description = "Set TTY keyboard rate and delay";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kbd}/bin/kbdrate -d 256 -r 32"; # -d is delay (ms), -r is rate (characters/second)
      RemainAfterExit = true;
    };
  };

  # Font packages 
  fonts.enableDefaultPackages = false;
  fonts.packages = with pkgs; [
    roboto
    roboto-serif
    nerd-fonts.roboto-mono
    nerd-fonts.jetbrains-mono
    openmoji-color
  ];
  
  # Hardware
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  # Enable sound.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Display manager and window manager
  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;

  # Other services
  security.polkit.enable = true;        # Enable polkit
  services.libinput.enable = true;      # Enable touchpad support
  services.udisks2.enable = true;       # Enable Udisks service
  services.openssh.enable = true;       # Enable the OpenSSH service
  services.printing.enable = true;      # Enable CUPS sevice for printing

  # List of packages containing udev rules
  services.udev.packages = with pkgs; [ 
    solaar       # Logitech device manager
  ];

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    bash                 # Shell
    vim                  # Text editor
    brightnessctl        # Screen brightness
    wget                 # Tool for retrieving files from webpages
    curl                 # Tool for transferring files with URL syntax
    git                  # Distributed version control system
    zip                  # File compressor
    unzip                # File decompressor
    bluetui              # Bluetooth tui
    nixos-anywhere       # Install nixos everywhere via ssh
    gcc                  # GNU c compiler
    gnumake              # C language tool 'make'
    rustc                # Rust tools
    cargo                # Rust package manager
    nixfmt               # Nix formatting tool
    devenv               # Development enviroment for Nix
    nodejs               # Framework for the V8 JavaScript engine
  ];

  programs.direnv.enable = true;   # Direnv Program

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # Run unpatched dynamic binaries on NixOS
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      icu
      zlib
      glibc
      libGL
      openssl
      libxkbcommon
      libX11
      libXcursor
      libXext
      libXfixes
      libXi
      libXrandr
      libXrender
      libXScrnSaver
      libxcb
      alsa-lib
      pulseaudio
      libtheora
      SDL
      SDL2
      glib
      gtk3
      gsettings-desktop-schemas
    ];
  };

  # Run Appimage
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.icu ]; 
    };
  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Open ports in the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 443 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  # Nameservers
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Extra TTL
  networking.firewall.extraCommands = ''
    iptables -t mangle -A PREROUTING -j TTL --ttl-set 65
  '';

  system.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
