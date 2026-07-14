{ config, lib, pkgs, ...}:

{
  stylix = {
    enable = true;
    polarity = "dark";
    image = ./config.d/WallPapers/nordAstronaut2.png;

    base16Scheme = {
      base00 = "2e3440";
      base01 = "3b4252";
      base02 = "434c5e";
      base03 = "4c566a";
      base04 = "d8dee9";
      base05 = "e5e9f0";
      base06 = "eceff4";
      base07 = "8fbcbb";
      base08 = "bf616a";
      base09 = "d08770";
      base0A = "ebcb8b";
      base0B = "a3be8c";
      base0C = "88c0d0";
      base0D = "81a1c1";      
      base0E = "b48ead";
      base0F = "5e81ac";
    };

    cursor = {
      name = "Nordzy-cursors";
      size = 32;
      package = pkgs.runCommand "Nordzy-cursors" {} ''
        mkdir -p $out/share/icons/Nordzy-cursors
        cp -r ${./config.d/Nordzy-cursors}/* $out/share/icons/Nordzy-cursors/
      '';
    };
  };
}
