{ ... }:

{
  home.username = "dat";
  home.homeDirectory = "/home/dat";
  programs.home-manager.enable = true;
  home.stateVersion = "26.05"; # State version (This is not system version. This is just backwards syntax and settings compability.)
}
