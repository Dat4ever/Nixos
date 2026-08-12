{ pkgs, ... }:

{
  networking.hostName = "datLOQ";                  # Hostname
  networking.networkmanager.enable = true;         # networkmanager (nmcli and nmtui)
  networking.networkmanager.wifi.backend = "iwd";  # Use iwd as WiFi backend (default is "wpa_supplicant". "iwd" is alternative)

  # iwd CLI tool (iwctl)
  environment.systemPackages = with pkgs; [
    iwd
  ];

  # DNS via systemd-resolved (prevents NetworkManager/DHCP from overriding)
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ];

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 443 53317 ];
    allowedUDPPorts = [ 53317 ];
  };
}
