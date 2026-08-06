{ config, pkgs, lib, ... }:

{
  # Home manager user
  home.username = "dat";
  home.homeDirectory = "/home/dat";
  programs.home-manager.enable = true;
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
      user.email = "dat4ever87@gmail.com";
    };
  };

  # Bash settings
  programs.bash = {
    enable = true;
    shellAliases = {
      nrsf = "sudo nixos-rebuild switch --flake .#datLOQ";
      ncg = "sudo nix-collect-garbage -d";
      nfu-nrsf = "nix flake update && sudo nixos-rebuild switch --flake .#datLOQ";
    };
    initExtra = builtins.readFile ./home-config/bashrc;
  };

  # Btop settings
  programs.btop = {
    enable = true;
    extraConfig = builtins.readFile ./home-config/btop/btop.conf;
  };

  # Config files
  home.file.".config/nvim".source = ./home-config/nvim;
  home.file.".config/kitty".source = ./home-config/kitty;
  home.file.".config/quickshell".source = ./home-config/quickshell;
  home.file.".config/rofi".source = ./home-config/rofi;
  home.file.".config/yazi/yazi.toml".source = ./home-config/yazi/yazi.toml;
  home.file.".config/yazi/keymap.toml".source = ./home-config/yazi/keymap.toml;
  home.file.".config/yazi/init.lua".source = ./home-config/yazi/init.lua;
  home.activation.yaziPkgInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -Dm644 ${./home-config/yazi/package.toml} "$HOME/.config/yazi/package.toml"
  '';

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
    # Wayland / Hyprland Desktop Environment
    hyprland 							# Wayland compositor
    hyprpaper 						# Wallpaper manager
    hyprcursor 						# Hyprland cursor library
    hyprpolkitagent 			# Authentication agent
    quickshell	 					# Desktop shell toolkit
    rofi 									# Application launcher
    # Wayland Utilities
    grim 									# Screenshot tool
    slurp 								# Screen region selector
    wl-clipboard 					# Clipboard manager
    # Terminal & Development Tools & language servers & debuggers
    kitty 								# Terminal
    neovim 								# Text editor
    tmux 									# Terminal multiplexer
    tree-sitter 					# Parsing tool
    ripgrep 							# Fast grep
    gcc 									# C/C++ compiler
    gnumake 							# C Build automation tool
    rustc 								# Rust compiler
    cargo 								# Rust package manager
    vim-language-server   # Vim LSP 'vimls'
    lua-language-server 	# Lua LSP 'lua_ls'
    rust-analyzer         # Rust LSP 'rust_analyzer'
    clang-tools           # C/C++ LSP 'clangd'
    nixd                  # Nix LSP 'nixd'
    bash-language-server  # Bash LSP 'bashls'
    pyright               # Python LSP 'pyright'
    gopls                 # Go LSP 'gopls'
    jdt-language-server   # Java LSP 'jdtls'
    # GUI Applications
    firefox 							# Web browser
    tor-browser 					# Privacy-focused browser
    vlc 									# Media player
    mpv 									# Lightweight media player
    obs-studio 						# Screen recorder & streaming
    libreoffice-fresh 		# Office suite
    qbittorrent 					# Torrent client
    localsend 						# Local network file sharing
    # CLI / TUI Utilities
    yazi 									# Terminal file manager
    jq 										# Command-line JSON processor
    mediainfo 						# Media file metadata viewer
    ouch 									# Archive compressor/decompressor
    zip 									# .zip compression
    unzip 								# .zip extraction
    unrar 								# .rar extraction
    p7zip 								# .7z extraction
    pastel 								# Color analysis CLI tool
    pfetch 								# System info fetcher
    pokeget-rs 						# Pokemon sprites in terminal
    steamcmd 							# Steam command-line client
    yt-dlp 								# Media downloader
    caligula 							# TUI disk imager
    bluetui 							# Bluetooth TUI
    wiremix 							# PipeWire TUI mixer
    opencode 							# AI terminal coding agent
    claude-code 					# TUI agentic coding tool
  ];

  home.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
