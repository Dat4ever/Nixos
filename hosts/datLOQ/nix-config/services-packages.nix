{ pkgs, ... }:

{
  # Enable sound.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Touchpad support
  services.libinput.enable = true;

  # Display manager and window manager
  services.displayManager.ly.enable = true;
  programs.hyprland.enable = true;

  # Other services
  security.polkit.enable = true;        # Enable polkit
  services.udisks2.enable = true;       # Enable Udisks service
  services.openssh.enable = true;       # Enable the OpenSSH service
  services.printing.enable = true;      # Enable CUPS sevice for printing
  services.fwupd.enable = true;         # Enable linux firmware updater

  # Udev rules packages
  services.udev.packages = with pkgs; [
    solaar       # Logitech device manager
  ];

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
