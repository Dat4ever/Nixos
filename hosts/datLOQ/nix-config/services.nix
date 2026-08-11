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

  # Other services
  security.polkit.enable = true;        # Enable polkit
  services.udisks2.enable = true;       # Enable Udisks service
  services.openssh.enable = true;       # Enable the OpenSSH service
  services.printing.enable = true;      # Enable CUPS sevice for printing
  services.fwupd.enable = true;         # Enable linux firmware updater
}
