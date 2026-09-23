{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true; # Allow unfree packages

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    # System essentials
    bash 								  # Shell
    git 								  # Version control
    kitty 								# Terminal
    brightnessctl         # Screen brightness control

    # System-level CLI utilities
    wget 									# Web file retriever
    curl 									# URL file transfer utility
    rsync 								# System-level file sync & backups
    nixos-anywhere        # NixOS installation via SSH
    jq 										# Command-line JSON processor
    libnotify 					  # notify-send
    zip 									# .zip compression
    unzip 								# .zip extraction
    unrar 								# .rar extraction
    p7zip 								# .7z extraction

    # Custom packages
    (callPackage ../../../extras/pkgs/olta {})  # Olta Web UI — local video/audio downloader (rofi -drun entry)
  ];
}
