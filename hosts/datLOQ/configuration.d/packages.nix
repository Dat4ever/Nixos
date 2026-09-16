{ pkgs, ... }:

{
  # Vendored packages (extras/pkgs) as an overlay: pkgs.datfetch, pkgs.<packagename>...
  nixpkgs.overlays = [ (import ../../../extras/pkgs) ];

  # Disable default font packages
  fonts.enableDefaultPackages = false;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    # System essentials
    bash 								  # Shell
    git 								  # Version control
    kitty 								# Terminal
    brightnessctl         # Screen brightness control

    # System-level CLI utilities
    datfetch 						  # datfetch (extras/pkgs overlay)
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
  ];
}
