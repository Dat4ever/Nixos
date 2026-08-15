{ pkgs, lib, ... }:

{
  networking.hostName = "datLOQ";                  # Hostname
  networking.networkmanager.enable = true;         # networkmanager (nmcli and nmtui)
  networking.nftables.enable = true;               # nftables instead of iptables
  networking.networkmanager.wifi.backend = "iwd";  # Use iwd as WiFi backend (default is "wpa_supplicant". "iwd" is alternative)

  environment.systemPackages = with pkgs; [
    iwd        # Wireless CLI daemon
    torsocks   # Tor CLI tool
    nyx        # Tor TUI monitor
  ];

  # DNS via systemd-resolved
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ];

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 443 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  # Tor settings
  services.tor = {
    enable = true;
    client = {
      enable = true;
      transparentProxy.enable = true; # Port 9040
      dns.enable = true;              # Port 9053
    };
    settings = {
      ControlPort = 9051;
      CookieAuthentication = true;
      CookieAuthFileGroupReadable = true;
      CookieAuthFile = "/run/tor/control.authcookie";
    };
  };

  users.users.dat.extraGroups = [ "tor" ];

  # Toggle: systemctl start/stop tor-transparent (or start-tor/stop-tor)
  systemd.services.tor-transparent = {
    description = "Toggle transparent Tor routing";
    after = [ "tor.service" ];
    requires = [ "tor.service" ];
    wantedBy = lib.mkForce [ ];
    path = [ pkgs.nftables ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      nft -f - <<'EOF'
      table inet tor
      delete table inet tor

      table inet tor {
        chain nat-output {
          type nat hook output priority -100; policy accept;
          meta skuid tor return
          oifname "lo" return
          udp dport 53 redirect to :9053
          tcp dport 53 redirect to :9053
          ip daddr { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } return
          ip protocol tcp redirect to :9040
        }

        chain filter-output {
          type filter hook output priority 0; policy drop;
          meta skuid tor accept
          oifname "lo" accept
          udp dport { 67, 68 } accept
          ip daddr { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } accept
          icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit } accept
          counter reject with icmpx type admin-prohibited
        }
      }
      EOF
    '';
    preStop = ''
      nft delete table inet tor 2>/dev/null || true
    '';
  };
}
