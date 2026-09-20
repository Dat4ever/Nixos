{ ... }:

{
  networking.hostName = "datLOQ";   # Hostname
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant"; # Use iwd or wpa_supplicant.
    dns = "systemd-resolved";        # Let systemd-resolved handle DNS.
  };

  networking.nftables.enable = true;
  networking.enableIPv6 = false;
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
      ];

      FallbackDNS = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };
  };

  # Firewall
  # Ports: SSH (22), LocalSend (53317), Syncthing(21027,22000)
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    interfaces = {
      # Wifi
      wlp8s0.allowedTCPPorts = [ 22 53317 22000 ];
      wlp8s0.allowedUDPPorts = [ 53317 21027 22000 ];
      # Ethernet
      enp7s0.allowedTCPPorts = [ 22 ];
      enp7s0.allowedUDPPorts = [ ];
      # USB Tether
      enp0s20f0u3.allowedTCPPorts = [ 22 53317 22000 ];
      enp0s20f0u3.allowedUDPPorts = [ 53317 21027 22000 ];
    };
  };
}
