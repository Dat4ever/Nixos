{ config, pkgs, ... }: {

  # Home manager user
  home.username = "dat";
  home.homeDirectory = "/home/dat";
  programs.home-manager.enable = true;

  # Xdg user dirs
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

  # Xdg dirs locations
    download = "$HOME/Downloads";
    documents = "$HOME/Documents";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    music = "$HOME/Music";
    desktop = "$HOME/Desktop";
    templates = "$HOME/Public/Templates";
    publicShare = "$HOME/Public";
  };

  # Git settings
  programs.git = {
    enable = true;
      settings.user = {
        name = "Dat4ever";
        email = "nemodat8777@gmail.com";
    };
  };

  # Bash settings
  programs.bash = {
    enable = true;
    shellAliases = {
      nrsf = "sudo nixos-rebuild switch --flake .#datLOQ";
      ncg = "sudo nix-collect-garbage -d";
    };
    initExtra = builtins.readFile ./config/bashrc;
  };

  # Config files
  home.file.".config/nvim".source = ./config/nvim;
  home.file.".config/yazi".source = ./config/yazi;
  home.file.".config/kitty".source = ./config/kitty;
  home.file.".config/quickshell".source = ./config/quickshell;
  home.file.".config/rofi".source = ./config/rofi;
  home.file.".config/hypr/colors.lua".source = ./config/hypr/colors.lua;
  home.file.".config/etc".source = ./config/etc;

  # Desktop enviroment and its config file
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./config/hypr/hyprland.lua;
  };

  # Home Packages
  home.packages = with pkgs; [
    hyprland             # Dynamic tiling Wayland compositor
    hyprcursor           # Hyprland cursor library
    hyprpolkitagent      # Policy kit agent for hyprland
    kitty                # Terminal
    yazi                 # File manager
    quickshell           # Desktop shell toolkit
    rofi                 # Application launcher
    networkmanagerapplet # NetworkManager control applet
    blueman              # Bluetooth manager
    pavucontrol          # Volume control
    pulseaudio           # PulseAudio Volume Control
    neovim               # Text editor
    tree-sitter          # Parser generator tool
    firefox              # Web browser
    tor-browser          # Tor web browser
    vlc                  # Media player
    ouch                 # File compressor/decompressor
    mpv                  # Medıa player
    grim                 # Wayland screenshot utility
    slurp                # Wayland screenshot utility
    wl-clipboard         # Copy-paste for wayland desktop
    rsync                # File transfer utiity
    mediainfo            # Informations about video and audio file
    pfetch               # System information
    heroic               # GOG, Epic, and Amazon game launcher
    steamcmd             # Steam CLI tools
    osu-lazer-bin        # OSU game
    localsend            # Local file sender
    libreoffice-fresh    # Office programs
    yt-dlp               # Youtube audio/video downloader
    qbittorrent          # BitTorrent client
    caligula             # lightweight TUI for disk imaging
    obs-studio           # Video screen recording
  ];

  # GTK settings
  gtk = {
    enable = true;
  };

  # QT settings
  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  home.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
