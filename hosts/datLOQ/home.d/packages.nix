{ pkgs, ... }:

{
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
    # Terminal & Development Tools & language servers
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
    libreoffice-fresh 		# Office suite
    qbittorrent 					# Torrent client
    localsend 						# Local network file sharing
    # CLI / TUI Utilities
    jq 										# Command-line JSON processor
    udiskie               # Automounter for removable media
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
    exiftool              # EXIF meta information reader
    binwalk               # Firmware Analysis Tool
    bluetui 							# Bluetooth TUI
    wiremix 							# PipeWire TUI mixer
    opencode 							# AI terminal coding agent
    claude-code 					# TUI agentic coding tool
    imv                   # Command line image viewer
  ];
}
