{ ... }:

{
  # Web UI: http://127.0.0.1:8384
  services.syncthing = {
    enable = true;
    user = "dat";
    dataDir = "/home/dat/Sync";
    configDir = "/home/dat/.config/syncthing";
    openDefaultPorts = true;            # 22000/tcp+udp, 21027/udp (local discovery)
  };
}
