{ config, pkgs, ... }:

{
  boot.initrd.kernelModules = [ "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    NVD_BACKEND = "direct";

  __NV_PRIME_RENDER_OFFLOAD = "1";
  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  __VK_LAYER_NV_optimus = "NVIDIA_only";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = true;
    nvidiaSettings = true;
    modesetting.enable = true;
    prime = { 
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";
      #sync = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };
}
