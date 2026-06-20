{ config, pkgs, ... }: {

  # Home manager user
  home.username = "dat";
  home.homeDirectory = "/home/dat";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;

  # Git settings
  programs.git = {
    enable = true;
      settings.user = {
        name = "Dat4ever";
        email = "nemodat8777@gmail.com";
      };  
    };

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
    templates = "$HOME/Documents/Templates";
    publicShare = "$HOME/Public";
  };

  # Config files
  home.file.".bashrc".source = ./bashrc;
  home.file.".config/nvim".source = ./config/nvim;
  home.file.".config/yazi".source = ./config/yazi;
  home.file.".config/kitty".source = ./config/kitty;
  home.file.".config/quickshell".source = ./config/quickshell;

  # Desktop enviroment
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./config/hypr/hyprland.lua;
  };

  # Home Packages
  home.packages = with pkgs; [
    networkmanagerapplet # NetworkManager control applet
    blueman              # Bluetooth manager
    hyprpolkitagent      # Policy kit agent for hyprland
    yazi                 # File manager
    kitty                # Terminal
    quickshell           # Desktop shell toolkit
    dunst                # Notification daemon
    rofi                 # Application launcher
    awww                 # Wallpaper daemon for wayland
    neovim               # Text editor
    firefox              # Web browser
    grim                 # Wayland screenshot utility
    slurp                # Wayland screenshot utility
    wl-clipboard         # Copy-paste for wayland desktop
    rsync                # File transfer utiity
    zip                  # File compressor
    unzip                # File decompressor
    vlc                  # Media player
    heroic               # GOG, Epic, and Amazon game launcher
    steamcmd             # Steam CLI tools
    osu-lazer-bin        # OSU game
  ];
}
