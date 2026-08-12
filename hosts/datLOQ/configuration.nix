{ ... }:

{
  imports =
   [
    ./configuration.d/general.nix
    ./configuration.d/gpu.nix
    ./configuration.d/networking.nix
    ./configuration.d/nixld-appimage.nix
    ./configuration.d/services.nix
    ./configuration.d/packages.nix
   ];
}
