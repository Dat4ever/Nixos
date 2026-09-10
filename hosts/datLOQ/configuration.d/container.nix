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
    clang-tools
    nodejs
    python3
    pyright
    gopls
    opencode
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
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-dev" ];
    externalInterface = null; # masquerade on all outbound interfaces (wifi + tether)
  };

  # Workspace directory on the host, bind-mounted into the containers.
  systemd.tmpfiles.rules = [
    "d /home/dat/dev 0755 dat users - -"
  ];

  containers.dev = {
    autoStart = false; # start on demand: sudo nixos-container start dev
    privateNetwork = true; # isolated veth network, no direct LAN exposure
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
      opencode-state = {
        hostPath = "/home/dat/.local/share/opencode";
        mountPoint = "/home/dat/.local/share/opencode";
        isReadOnly = false;
      };
    };

    config = { pkgs, ... }: {
      system.stateVersion = "26.05";
      time.timeZone = "Europe/Istanbul";
      networking.useHostResolvConf = false;
      networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
      systemd.tmpfiles.rules = [
        "d /home/dat/.local 0755 dat users -"
        "d /home/dat/.local/state 0755 dat users -"
        "d /home/dat/.config 0755 dat users -"
        "d /home/dat/.cache 0755 dat users -"
      ];

      users.mutableUsers = false;
      # Intentionally passwordless sandbox (no wheel, no sshd): allow no-password login inside the container only.
      users.allowNoPasswordLogin = true;
      users.users.dat = {
        uid = 1000;
        isNormalUser = true;
        home = "/home/dat";
        initialHashedPassword = ""; # passwordless console/su inside container
      };

      environment.systemPackages = devTools;

      # No GUI services inside the sandbox.
      services.openssh.enable = false;
    };
  };

  environment.systemPackages = [ devWrapper ];
}
