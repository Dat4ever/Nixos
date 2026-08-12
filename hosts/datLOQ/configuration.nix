{ ... }:

{
  imports =
   [
    ./os-nixconfig/general.nix
    ./os-nixconfig/gpu.nix
    ./os-nixconfig/networking.nix
    ./os-nixconfig/nixld-appimage.nix
    ./os-nixconfig/services.nix
    ./os-nixconfig/packages.nix
   ];
}
