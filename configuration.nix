{ config, lib, pkgs, ... }:

{
 imports =
  [
    ./nvidia.nix
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
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;


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
    geist-font
    nerd-fonts.commit-mono
    noto-fonts-color-emoji
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
    brightnessctl        # Screen brightness control
    wget                 # Web file retriever
    curl                 # URL file transfer utility
    git                  # Version control
    rsync                # System-level file sync & backups
    zip                  # .zip compression
    unzip                # .zip extraction
    unrar                # .rar extraction
    p7zip                # .7z extraction
    nixos-anywhere       # NixOS installation via SSH
  ];

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # Run unpatched dynamic binaries on NixOS
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # C / System
      stdenv.cc.cc
      glibc
      zlib
      zstd
      icu
      util-linux
      # GUI (Electron / GTK)
      glib
      gtk3
      atk
      dbus
      gsettings-desktop-schemas
      systemd
      # Font & Render
      fontconfig
      freetype
      pango
      gdk-pixbuf
      expat
      libxml2
      cairo
      # Voice & Game
      alsa-lib
      pulseaudio
      SDL
      SDL2
      libtheora
      # Graphics / OpenGL
      libdrm
      libgbm
      mesa
      libGL
      # Security & Web
      openssl
      nss
      nspr
      cups
      # Xorg
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
      libXcomposite
      libXdamage
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

  # Networking
  networking = {
    networkmanager.enable = true; # nmcli or nmtui
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 443 53317 ];
      allowedUDPPorts = [ 53317 ];
      # Extra TTL
      extraCommands = ''
        iptables -t mangle -A PREROUTING -j TTL --ttl-set 65
      '';
      extraStopCommands = ''
        iptables -t mangle -D PREROUTING -j TTL --ttl-set 65 2>/dev/null || true
      '';
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  system.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
