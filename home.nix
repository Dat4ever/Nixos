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
    initExtra = builtins.readFile ./home-dotconfig/bashrc;
  };

  # Config files
  home.file.".config/nvim".source = ./home-dotconfig/nvim;
  home.file.".config/yazi".source = ./home-dotconfig/yazi;
  home.file.".config/kitty".source = ./home-dotconfig/kitty;
  home.file.".config/quickshell".source = ./home-dotconfig/quickshell;
  home.file.".config/rofi".source = ./home-dotconfig/rofi;
  home.file.".config/hypr/colors.lua".source = ./home-dotconfig/hypr/colors.lua;

  # Desktop enviroment and its config file
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./home-dotconfig/hypr/hyprland.lua;
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

  # Stylix
  stylix = {
    enable = true;
    polarity = "dark";
    image = ./home-dotconfig/WallPaper/nordAstronaut2.png;

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

    cursor = {
      name = "Nordzy-cursors";
      size = 32;
      package = pkgs.runCommand "nordzy-cursors-config" {} ''
        mkdir -p $out/share/icons/Nordzy-cursors
        cp -r ${./config/etc/Nordzy-cursors}/* $out/share/icons/Nordzy-cursors/
      '';
    };
  };

  home.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
