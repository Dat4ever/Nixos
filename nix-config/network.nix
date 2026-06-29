{ config, pkgs, ... }:

{
  # Open ports in the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };
  # Disable the firewall
  # networking.firewall.enable = false;

  # TTL setting
  networking.firewall.extraCommands = ''
    iptables -t mangle -A PREROUTING -j TTL --ttl-set 65
  '';
}
