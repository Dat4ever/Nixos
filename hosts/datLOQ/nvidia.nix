{ config, pkgs, lib, ... }:

{
  hardware.graphics.extraPackages = lib.mkAfter (with pkgs; [
    nvidia-vaapi-driver
    libva-vdpau-driver
    libvdpau-va-gl
  ]);

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.sessionVariables = {
    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

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
