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

  # Udev rules packages
  services.udev.packages = with pkgs; [
    solaar       # Logitech device manager
  ];

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };

  # Podman (docker-compatible container runtime)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # Openssh (port opened per-interface in networking.nix, not globally)
  services.openssh.enable = true;
  services.openssh.openFirewall = false;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };

  # Other services
  security.polkit = {
    enable = true;               # Enable polkit
    enablePkexecWrapper = true;  # setuid pkexec (root GUI apps)
  };
  services.udisks2.enable = true;       # Enable Udisks service
  services.printing.enable = true;      # Enable CUPS sevice for printing
  services.fwupd.enable = true;         # Enable linux firmware updater
  services.flatpak.enable = true;       # Enable Flatpak
}
