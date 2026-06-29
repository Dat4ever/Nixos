{ config, pkgs, ... }: 


{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Display manager and window manager
  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;

  # Other services
  security.polkit.enable = true;        # Enable polkit
  services.libinput.enable = true;      # Enable touchpad support
  services.udisks2.enable = true;       # Enable Udisks service
  services.openssh.enable = true;       # Enable the OpenSSH service
  services.printing.enable = true;      # Enable CUPS sevice for printing

  # List of packages containing udev rules
  services.udev.packages = with pkgs; [ 
    solaar       # Logitech device manager
  ];

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    bash               # Shell
    vim                # Text editor
    brightnessctl      # Screen brightness
    wget               # Tool for retrieving files from webpages
    curl               # Tool for transferring files with URL syntax
    git                # Distributed version control system
    nil                # Nix language
    nixpkgs-fmt        # Nix package formatting tool
    gcc                # Gnu compiler collection
    solaar             # Logitech device manager
    zip                # File compressor
    unzip              # File decompressor
  ];

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are started in user sessions
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
