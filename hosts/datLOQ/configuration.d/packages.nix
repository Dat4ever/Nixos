{ pkgs, inputs, ... }:

{
  # Font packages
  fonts.enableDefaultPackages = false;
  fonts.packages = with pkgs; [
    inter
    nerd-fonts.commit-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

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
    inputs.datfetch.packages.${pkgs.system}.default # datfetch from flake
  ];

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };
}
