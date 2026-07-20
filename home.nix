{ config, pkgs, ... }: 

{
  # Home manager user
  home.username = "dat";
  home.homeDirectory = "/home/dat";
  programs.home-manager.enable = true;
  home.stateVersion = "26.05"; 
  home.pointerCursor.enable = true;
  xdg.enable = true;

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
    templates = "$HOME/Documents";
    publicShare = "$HOME/Public";
  };

  # Git settings
  programs.git = {
    enable = true;
    settings = {
      user.name = "Dat4ever";
      user.email = "nemodat8777@gmail.com";
    };
  };

  # Bash settings
  programs.bash = {
    enable = true;
    shellAliases = {
      nrsf = "sudo nixos-rebuild switch --flake .";
      ncg = "sudo nix-collect-garbage -d";
      nfu-nrsf = "nix flake update && sudo nixos-rebuild switch --flake .";
    };
    initExtra = builtins.readFile ./home-config/bashrc;
  };

  # Config files
  home.file.".config/nvim".source = ./home-config/nvim;
  home.file.".config/yazi".source = ./home-config/yazi;
  home.file.".config/kitty".source = ./home-config/kitty;
  home.file.".config/quickshell".source = ./home-config/quickshell;
  home.file.".config/rofi".source = ./home-config/rofi;

  # Desktop enviroment and its config file
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./home-config/hypr/hyprland.lua;
  };

  # GTK settings
  gtk = {
    enable = true;
  };

  # QT settings
  qt = {
    enable = true;
    platformTheme.name = "qtct";
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
    tmux                 # Terminal multiplexer
    firefox              # Web browser
    tor-browser          # Tor web browser
    vlc                  # Media player
    ouch                 # File compressor/decompressor
    mpv                  # Media player
    grim                 # Wayland screenshot utility
    slurp                # Wayland screenshot utility
    wl-clipboard         # Copy-paste for wayland desktop
    rsync                # File transfer utility
    pastel               # CLI tool to analyze colors
    jq                   # command-line JSON processor
    mediainfo            # Informations about video and audio file
    pfetch               # System information
    steamcmd             # Steam CLI tools
    localsend            # Local file sender
    libreoffice-fresh    # Office programs
    yt-dlp               # Youtube audio/video downloader
    qbittorrent          # BitTorrent client
    caligula             # lightweight TUI for disk imaging
    obs-studio           # Video screen recording
  ];
}
