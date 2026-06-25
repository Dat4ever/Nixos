{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # General settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; # Enable Nix Flakes
  nixpkgs.config.allowUnfree = true;                               # Allow unfree packages
  nix.settings.auto-optimise-store = true;                         # Symlinks same store files
  programs.nix-ld.enable = true;                                   # NixOS /lib to /nix/store

  # System settings
  networking.hostName = "datLOQ";                # Hostname
  time.timeZone = "Europe/Istanbul";             # Time zone
  console.keyMap = "trq";                        # Set the default keyboard layout for the TTY

  # Font
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

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
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # Weekly garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Enable sound.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth settings
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Nvidia
  boot.initrd.kernelModules = [ "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    NVD_BACKEND = "direct";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    open = true;
    nvidiaSettings = true;
    modesetting.enable = true;
    prime = { 
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";
      #sync = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  # Run appimage
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Enable the X11 windowing system
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

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

  # Stylix
  stylix = {
    enable = true;
    polarity = "dark";
    image = ./config/etc/nordNixMinimal.jpg;
    base16Scheme = {
      base00 = "2e3440";
      base01 = "3b4252";
      base02 = "434c5e";
      base03 = "4c566a";
      base04 = "d8dee9";
      base05 = "e5e9f0";
      base06 = "eceff4";
      base07 = "8fbcbb";
      base08 = "bf616a";
      base09 = "d08770";
      base0A = "ebcb8b";
      base0B = "a3be8c";
      base0C = "88c0d0";
      base0D = "81a1c1";
      base0E = "b48ead";
      base0F = "5e81ac";
  };

  # Display manager and window manager
  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;

  # Services
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
    bash               # Shell
    vim                # Text editor
    wget               # Tool for retrieving files from webpages
    curl               # Tool for transferring files with URL syntax
    git                # Distributed version control system
    nil                # Nix language
    nixpkgs-fmt        # Nix package formatting tool
    gcc                # Gnu compiler collection
    solaar             # Logitech device manager
    zip                # File compressor
    unzip              # File decompressor
  ];

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
