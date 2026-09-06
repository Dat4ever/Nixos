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
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
      ];
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      53317
    ];
    allowedUDPPorts = [
      53317
    ];
  };
}
