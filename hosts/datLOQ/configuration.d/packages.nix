{ pkgs, ... }:

{
  # Vendored packages (extras/pkgs) as an overlay: pkgs.datfetch, pkgs.<packagename>...
  nixpkgs.overlays = [ (import ../../../extras/pkgs) ];

  # Disable default font packages
  fonts.enableDefaultPackages = false;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    bash                 # Shell
    vim                  # Text editor
    brightnessctl        # Screen brightness control
    wget                 # Web file retriever
    curl                 # URL file transfer utility
    git                  # Version control
    rsync                # System-level file sync & backups
    nixos-anywhere       # NixOS installation via SSH
    datfetch             # datfetch (extras/pkgs overlay)
  ];
}
