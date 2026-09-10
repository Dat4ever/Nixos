{ ... }:

{
  # Web UI: http://127.0.0.1:8384  (guiAddress below)
  services.syncthing = {
    enable = true;
    user = "dat";
    dataDir = "/home/dat/Sync";
    configDir = "/home/dat/.config/syncthing";
    guiAddress = "127.0.0.1:8384"; # Web UI never exposed to the network
    openDefaultPorts = false; # ports opened per-interface (22000, 21027) in networking.nix

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

    # Folders
      folders = {
      # Pictures
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

      # Public
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

      # Nixos
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

      # Music
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

      # Videos
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

      # Documents
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
}
