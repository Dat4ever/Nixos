{ pkgs, lib, ... }:

{
  # Web UI: http://127.0.0.1:8384  (localhost only, guiAddress below)
  services.syncthing = {
    enable = true;
    user = "dat";
    dataDir = "/home/dat/Sync";
    configDir = "/home/dat/.config/syncthing";
    guiAddress = "127.0.0.1:8384"; # Web UI never exposed to the network
    # Ports are NOT blanket-allowed: 22000/tcp+udp & 21027/udp are opened by extraInputRules below, restricted to private (RFC1918) source networks.
    openDefaultPorts = false;

    settings = {
      devices = {
        datLOQ = {
          id = "H4O7YKO-VQPLG6L-KY2LB6C-GKDRDLX-2JQPYWG-ZBRPDZW-BUFZGCX-XHVRKQH";
          autoAcceptFolders = false;
        };
        SM-S931B = {
          id = "54VRHOV-SLQUKNU-FE6R25E-O2I2HCJ-DXMUQ3X-EKX3JJE-QITCH6Z-YD4PZA5";
          autoAcceptFolders = false;
          compression = "never";
          addresses = [ "dynamic" ];
        };
      };

      options = {
        # Discovery only on the local network; no public internet announcements.
        globalAnnounceEnabled = false; # Do not register on global discovery
        relaysEnabled = false; # Never route via the fallback nodes
        urAccepted = -1; # No anonymous usage reporting
      };

      folders = {
        "6bomy-bttr9" = {
          label = "Pictures";
          path = "/home/dat/Pictures";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 15;
          };
        };
        "fy3wp-4vwhm" = {
          label = "Public";
          path = "/home/dat/Public";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 15;
          };
        };
        "mqvdh-hpv4q" = {
          label = "Nixos";
          path = "/home/dat/Nixos";
          devices = [ "datLOQ" "SM-S931B" ];
          ignorePerms = false;
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 15;
          };
        };
        "traon-rqxlb" = {
          label = "Music";
          path = "/home/dat/Music";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 15;
          };
        };
        "ui76t-kkwm3" = {
          label = "Videos";
          path = "/home/dat/Videos";
          devices = [ "datLOQ" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 15;
          };
        };
        "x5sgm-xpwfv" = {
          label = "Documents";
          path = "/home/dat/Documents";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 15;
          };
        };
      };
    };
  };

  # systemd sandbox around the syncthing daemon:
  # read-only "/" except explicitly listed Sync folders, config and state. "-": prefix = ignore paths that do not exist yet (avoids 226/NAMESPACE).
  systemd.services.syncthing = {
    serviceConfig = {
      ProtectSystem = "strict";
      ReadWritePaths = [
        "-/home/dat/Sync"
        "-/home/dat/.config/syncthing"
        "-/home/dat/.local/state/syncthing"
        # Synced folders (keep in sync with the "folders" block above)
        "-/home/dat/Pictures"
        "-/home/dat/Public"
        "-/home/dat/Nixos"
        "-/home/dat/Music"
        "-/home/dat/Videos"
        "-/home/dat/Documents"
      ];
    };
  };

  # Only private (RFC1918) sources may reach the syncthing sync ports. Blocks untrusted/public Wi-Fi peers; local discovery still works at home.
  networking.firewall.extraInputRules = ''
    ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } tcp dport 22000 accept
    ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } udp dport 22000 accept
    ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } udp dport 21027 accept
  '';
}
