{ ... }:

{
  imports =
   [
    ./nixos-config/general.nix
    ./nixos-config/gpu.nix
    ./nixos-config/networking.nix
    ./nixos-config/nixld-appimage.nix
    ./nixos-config/services.nix
    ./nixos-config/packages.nix
   ];
}
