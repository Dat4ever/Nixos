{ config, pkgs, ... }: 

{
  fonts.packages = with pkgs; [
    (pkgs.stdenv.mkDerivation {
      pname = "jetbrains-mono-config";
      version = "1.0";
    
      src = ./etc/JetBrainsMono; 

      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp -r $src/*.{ttf,otf} $out/share/fonts/truetype/
      '';
    })
  ];
}
