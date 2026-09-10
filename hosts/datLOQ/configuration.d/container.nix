{ pkgs, lib, ... }:

let
  # Dev toolset that lives *inside* the sandbox container. Keep it in sync with what opencode agents are likely to need.
  devTools = with pkgs; [
    bash
    git
    vim
    neovim
    tmux
    ripgrep
    jq
    gcc
    gnumake
    rustc
    cargo
    rust-analyzer
    clang-tools # C/C++ toolchain + clangd
    nodejs
    python3
    pyright
    gopls

    # The AI agent itself
    opencode

    # Small utilities
    curl
    wget
    zip
    unzip
  ];

  # Host-side helper: drop into the sandbox as user "dat".
  devWrapper = pkgs.writeShellScriptBin "dev" ''
    exec sudo machinectl shell dat@dev "$@"
  '';
in

{
  boot.enableContainers = true;

  # Give sandbox containers internet access via NAT on their veth interfaces.
  # NOTE: the nftables backend does not understand iptables-style wildcards
  # ("ve-+"); name the interfaces explicitly instead.
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-dev" "ve-qbt" ];
    externalInterface = null; # masquerade on every outbound interface
  };

  # Inbound ports for the always-on service containers (see below).
  networking.firewall.allowedTCPPorts = [ 6881 ];
  networking.firewall.allowedUDPPorts = [ 6881 ];

  # Workspace directory on the host, bind-mounted into the containers.
  systemd.tmpfiles.rules = [
    "d /home/dat/dev 0755 dat users - -"
  ];

  containers.dev = {
    autoStart = false; # start on demand: sudo nixos-container start dev
    privateNetwork = true; # isolated veth network, no direct LAN exposure
    # systemd 261 needs --network-veth explicitly (plain --private-network
    # no longer creates the veth pair); also networkd is not the host
    # resolver, so give every container a static link address.
    extraFlags = [ "--network-veth" ];
    hostAddress = "10.231.136.1";
    localAddress = "10.231.136.2";

    bindMounts = {
      # Only the workspace is visible from inside the container.
      workspace = {
        hostPath = "/home/dat/dev";
        mountPoint = "/home/dat/dev";
        isReadOnly = false;
      };
      # opencode state dir (auth.json + repos/storage in container).
      # Readonly nspawn bind creates a root-owned parent dir, which
      # breaks opencode's mkdir; bind the *folder* rw instead.
      opencode-state = {
        hostPath = "/home/dat/.local/share/opencode";
        mountPoint = "/home/dat/.local/share/opencode";
        isReadOnly = false;
      };
    };

    config = { pkgs, ... }: {
      system.stateVersion = "26.05";
      time.timeZone = "Europe/Istanbul";

      # systemd-resolved stub (127.0.0.53) is unreachable from a private
      # netns; use plain upstream DNS inside containers.
      networking.useHostResolvConf = false;
      networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

      # nspawn creates bind-mount parents (e.g. ~/.local) as root, which
      # blocks opencode from creating XDG state/cache dirs at login.
      systemd.tmpfiles.rules = [
        "d /home/dat/.local 0755 dat users -"
        "d /home/dat/.local/state 0755 dat users -"
        "d /home/dat/.config 0755 dat users -"
        "d /home/dat/.cache 0755 dat users -"
      ];

      users.mutableUsers = false;
      users.users.dat = {
        uid = 1000;
        isNormalUser = true;
        home = "/home/dat";
        initialHashedPassword = ""; # passwordless console/su inside container
        extraGroups = [ "wheel" ];
      };
      # Passwordless root fallback for maintenance inside the sandbox.
      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = devTools;

      # No GUI services inside the sandbox.
      services.openssh.enable = false;
    };
  };

  # Torrent client container (qBittorrent web UI, headless).
  containers.qbt = {
    autoStart = true;
    privateNetwork = true;
    extraFlags = [ "--network-veth" ];
    hostAddress = "10.231.136.5";
    localAddress = "10.231.136.6";
    forwardPorts = [
      { protocol = "tcp"; hostPort = 8080; containerPort = 8080; }
      { protocol = "tcp"; hostPort = 6881; containerPort = 6881; }
      { protocol = "udp"; hostPort = 6881; containerPort = 6881; }
    ];

    bindMounts = {
      downloads = {
        hostPath = "/home/dat/Downloads";
        mountPoint = "/var/lib/downloads";
        isReadOnly = false;
      };
    };

    config = { ... }: {
      system.stateVersion = "26.05";
      time.timeZone = "Europe/Istanbul";

      networking.useHostResolvConf = false;
      networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

      services.qbittorrent = {
        enable = true;
        openFirewall = true; # let LAN/loopback (via host proxy) reach the UI
        webuiPort = 8080;
        torrentingPort = 6881;
        profileDir = "/var/lib/qBittorrent";
        serverConfig = {
          LegalNotice.Accepted = true;
          Session.SavePath = "/var/lib/downloads";
          Preferences.WebUI = {
            Username = "dat";
            Password_PBKDF2 = "@ByteArray(mUWnyT9u3f3pR6wlc3WUOg==:hlc6t6dALrQHV0xNkk9KDgEhhOYMWy1cY6jdI9tCuwHVwNSLe7U1alkO8pvtQSm6pWV1J+DrykNKF2lPT9RqPw==)";
            # allow Host: 127.0.0.1:18080 through the socat proxy
            HostHeaderValidation = false;
          };
        };
      };

      # Peer UDP traffic (NixOS firewall defaults to allow-none here too).
      networking.firewall.allowedTCPPorts = [ 6881 ];
      networking.firewall.allowedUDPPorts = [ 6881 ];
    };
  };

  environment.systemPackages = [ devWrapper ];

  # nspawn --port forwards only inbound LAN traffic, not host loopback.
  # Bridge localhost:18080 -> qBt WebUI (10.231.136.6:8080) so that local
  # browsing works (nspawn --port cannot loop back).
  systemd.services.qbt-webui-proxy = {
    description = "localhost proxy to qBittorrent WebUI container";
    wants = [ "container@qbt.service" ];
    after = [ "container@qbt.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:18080,bind=127.0.0.1,fork,reuseaddr TCP:10.231.136.6:8080";
      Restart = "always";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };
}
