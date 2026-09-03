{
  description = "Datfetch — my C system information fetch tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "datfetch";
            version = "0.1.0";
            src = nixpkgs.lib.cleanSource ./. ;
            nativeBuildInputs = [ ];
            buildInputs = [ ];
            buildPhase = ''
              runHook preBuild
              make
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              install -Dm755 datfetch $out/bin/datfetch
              runHook postInstall
            '';
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              gcc
              gdb
              valgrind
            ];
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/datfetch";
        };
      });
    };
}
