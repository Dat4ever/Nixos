{ ... }:

{
  # Web UI: http://127.0.0.1:8384  (guiAddress below)
  services.syncthing = {
    enable = true;
    user = "dat";
    dataDir = "/home/dat/Sync";
    configDir = "/home/dat/.config/syncthing";
    guiAddress = "127.0.0.1:8384"; # Web UI never exposed to the network
    guiPasswordFile = "/home/dat/Documents/Syncthing/syncthing-gui-password";
    openDefaultPorts = false; # ports opened per-interface (22000, 21027) in networking.nix

    settings = {
      gui.user = "dat";
      devices = {
        datLOQ = {
          id = "BTNKID5-DYPWOOQ-EYT4L62-WBEDC7B-RIPCW37-EMLLMPE-KXYJUBZ-VFURUA3";
          autoAcceptFolders = false;
        };
        SM-S931B = {
          id = "3E2PRDX-EHAMHVZ-YQ3VYKY-2SEXBUB-CS37NFW-2COIZCC-GDZPNXQ-KWFWNQ5";
          autoAcceptFolders = false;
          compression = "never";
          addresses = [ "dynamic" ];
        };
      };

      options = {
        globalAnnounceEnabled = false; # Do not register on global discovery
        relaysEnabled = false; # Never route via the fallback nodes
        urAccepted = -1; # No anonymous usage reporting
      };

    # Folders
      folders = {
      # Media/Books
        "lyt8w-dk8xx" = {
          label = "Media/Books";
          path = "/home/dat/Media/Books";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 7;
          };
        };

      # Media/Games
        "v6apb-9jw20" = {
          label = "Media/Games";
          path = "/home/dat/Media/Games";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 7;
          };
        };

      # Media/Music
        "v70m6-da7g8" = {
          label = "Media/Music";
          path = "/home/dat/Media/Music";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 7;
          };
        };

      # Media/Pictures
        "9px3u-bc9m1" = {
          label = "Media/Pictures";
          path = "/home/dat/Media/Pictures";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 7;
          };
        };

      # Media/Videos
        "rmy1m-9efts" = {
          label = "Media/Videos";
          path = "/home/dat/Media/Videos";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 7;
          };
        };

      # Media/.NPublic
        "lt8ru-w2vii" = {
          label = "Media/.NPublic";
          path = "/home/dat/Media/.NPublic";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 7;
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
            cleanoutDays = 7;
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
            cleanoutDays = 7;
          };
        };

      # Projects
        "prj9c-n58zt" = {
          label = "Projects";
          path = "/home/dat/Projects";
          devices = [ "datLOQ" "SM-S931B" ];
          versioning = {
            type = "trashcan";
            fsType = "basic";
            cleanoutDays = 7;
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
        "-/home/dat/Media"
        "-/home/dat/Nixos"
        "-/home/dat/Documents"
        "-/home/dat/Projects"
      ];
    };
  };
}
