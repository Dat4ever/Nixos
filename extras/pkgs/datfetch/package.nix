{
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "datfetch";
  version = "0.1.0";
  # Source only: keep build artifacts (*.o, binary) out of the store input
  src = let
    datfetchSrc = lib.cleanSource ./.;
  in
    lib.cleanSourceWith {
      src = datfetchSrc;
      filter = path: type:
        type == "directory"
        || !(lib.hasSuffix ".o" path)
        && baseNameOf path != "datfetch";
    };

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

  meta = {
    description = "Datfetch — C system information fetch tool";
    mainProgram = "datfetch";
    platforms = lib.platforms.linux;
  };
}
