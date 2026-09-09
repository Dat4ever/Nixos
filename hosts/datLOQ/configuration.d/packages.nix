{ pkgs, ... }:

{
  # Vendored packages (extras/pkgs) as an overlay: pkgs.datfetch, pkgs.<packagename>...
  nixpkgs.overlays = [ (import ../../../extras/pkgs) ];

  # Disable default font packages
  fonts.enableDefaultPackages = false;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    # Desktop (Wayland / Hyprland)
    hyprpaper 						# Wallpaper manager
    hyprland-qtutils 			# Hyprland utility apps (hyprland-run, hyprland-dialog, share picker)
    quickshell	 					# Desktop shell toolkit
    rofi 									# Application launcher
    grim 									# Screenshot tool
    slurp 								# Screen region selector
    wl-clipboard 					# Clipboard manager
    playerctl 						# Media player control (media keys)
    nwg-look 							# GTK settings GUI (wlroots)
    brightnessctl        # Screen brightness control
    xdg-terminal-exec 			# Terminal launcher for Terminal=true desktop entries (yazi reveal, nvim.desktop...)
    (zathura.override { plugins = [ zathuraPkgs.zathura_pdf_mupdf zathuraPkgs.zathura_cb ]; })  # PDF, EPUB via mupdf; CBZ via cb plugin
    imv 								# Image viewer

    # Terminal & Development Tools & language servers
    bash 								# Shell
    vim 								# Text editor
    git 								# Version control
    kitty 								# Terminal
    neovim 							# Text editor
    tmux 								# Terminal multiplexer
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
    vlc 									# Media player
    mpv 									# Lightweight media player
    libreoffice-stable    # Office programs
    qbittorrent 					# Torrent client
    localsend 						# Local network file sharing
    famistudio            # NES Music Editor (run FamiStudio in terminal)
    prismlauncher         # Minecraft launcher

    # CLI / TUI Utilities
    wget 									# Web file retriever
    curl 									# URL file transfer utility
    rsync 								# System-level file sync & backups
    nixos-anywhere       # NixOS installation via SSH
    datfetch 						# datfetch (extras/pkgs overlay)
    jq 										# Command-line JSON processor
    udiskie               # Automounter for removable media
    zip 									# .zip compression
    unzip 								# .zip extraction
    unrar 								# .rar extraction
    p7zip 								# .7z extraction
    libnotify 					  # notify-send
    pastel 								# Color analysis CLI tool
    pokeget-rs 						# Pokemon sprites in terminal
    steamcmd 							# Steam command-line client
    yt-dlp 								# Media downloader
    caligula 							# TUI disk imager
    exiftool              # EXIF meta information reader
    binwalk               # Firmware Analysis Tool
    bluetui 							# Bluetooth TUI
    wiremix 							# PipeWire TUI mixer
    btop                  # Resource monitor
    opencode 							# AI terminal coding agent
  ];
}
