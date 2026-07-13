{ pkgs, ... }: 

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
    gcc                  # GNU c compiler
    gnumake              # C language tool 'make'
    rustc                # Rust tools
    cargo                # Rust package manager
    nixfmt               # Nix formatting tool
    devenv               # Development enviroment for Nix
    solaar               # Logitech device manager
    nodejs               # Framework for the V8 JavaScript engine
    bash-language-server # Bash LSP
    nil                  # Nix LSP
    pyright              # Python LSP
    marksman             # markdown LSP
  ];

  programs.direnv.enable = true;   # Direnv Program

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
}
