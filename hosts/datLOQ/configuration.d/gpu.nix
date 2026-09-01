{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Intel
      intel-media-driver
      # Nvidia (VA-API for apps running on the dGPU)
      nvidia-vaapi-driver
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = true;
    nvidiaSettings = true;
    powerManagement = {
      enable = true;
      finegrained = true; # False for sync mode
    };

    modesetting.enable = true;

    prime = {
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      #sync.enable = true;
    };
  };
}
