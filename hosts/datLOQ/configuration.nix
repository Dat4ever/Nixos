{ ... }:

{
  imports =
  [
    ./configuration.d/general.nix
    ./configuration.d/gpu.nix
    ./configuration.d/networking.nix
    ./configuration.d/tor.nix
    ./configuration.d/nixld-appimage.nix
    ./configuration.d/gtk-schemas.nix
    ./configuration.d/qt.nix
    ./configuration.d/packages.nix
    ./configuration.d/services.nix
    ./configuration.d/syncthing.nix
  ];
}
