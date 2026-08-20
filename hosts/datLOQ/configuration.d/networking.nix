{ pkgs, lib, ... }:

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

  # Packages
  environment.systemPackages = with pkgs; [
    iwd        # Wireless CLI daemon
    torsocks   # Wrap commands to route them through Tor SOCKS
    nyx        # Tor TUI monitor
  ];

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      443
      53317
    ];
    allowedUDPPorts = [
      53317
    ];
  };

  # Tor
  services.tor = {
    enable = true;
    client = {
      enable = true;
      transparentProxy.enable = true; # TransPort 127.0.0.1:9040
      dns.enable = true;              # DNSPort  127.0.0.1:9053
    };

    settings = {
      VirtualAddrNetworkIPv4 = "100.64.0.0/10";
      ControlPort = 9051;
      CookieAuthentication = true;
      CookieAuthFile = "/run/tor/control.authcookie";
      CookieAuthFileGroupReadable = true;
    };
  };

  # Allow the local user to use the Tor control socket / nyx.
  users.users.dat.extraGroups = [ "tor" ];

  # Transparent Tor routing (nftables)
  # Tor OFF:  normal NetworkManager -> Internet
  # Tor ON:   normal outbound traffic -> Tor

  # Toggle with:
  # systemctl start tor-transparent   (start-tor alias)
  # systemctl stop  tor-transparent   (stop-tor alias)

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
