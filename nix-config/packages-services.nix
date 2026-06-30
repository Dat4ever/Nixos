{ config, pkgs, ... }: 

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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

  # Display manager and window manager
  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;

  # Enable the X11 windowing system
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

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
    bash               # Shell
    vim                # Text editor
    brightnessctl      # Screen brightness
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

  # Run unpatched dynamic binaries on NixOS
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    icu
    SDL2
    vulkan-loader
  ];

  # Run appimage
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };
}
