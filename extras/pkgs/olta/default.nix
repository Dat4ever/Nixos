{
  lib,
  stdenv,
  makeWrapper,
  makeDesktopItem,
  yt-dlp,
  ffmpeg,
}: let
  # Desktop entry so "olta Web UI" shows up in rofi -drun / app launchers.
  desktopItem = makeDesktopItem {
    name = "olta";
    desktopName = "Olta Web UI";
    comment = "Minimal video/audio downloader (local web app)";
    exec = "olta";
    terminal = false;
    categories = ["Network" "AudioVideo"];
    icon = "multimedia-video-player";
  };
in
  stdenv.mkDerivation {
    pname = "olta";
    version = "unstable";

    src = ./src;

    nativeBuildInputs = [makeWrapper];

    buildPhase = ''
      make
    '';

    installPhase = ''
      # The server resolves frontend assets relative to its working
      # directory (FRONTEND_DIR "frontend"), so install them next to the
      # binary and chdir the wrapper into $out/share/olta.
      install -Dm755 olta $out/bin/.olta-unwrapped
      mkdir -p $out/share/olta
      cp -r frontend $out/share/olta/frontend

      # Runtime tools on PATH for GUI-launched sessions (rofi -> exec has a
      # minimal PATH); belt and suspenders for olta's own tool resolution.
      makeWrapper $out/bin/.olta-unwrapped $out/bin/olta \
        --chdir $out/share/olta \
        --prefix PATH : ${lib.makeBinPath [yt-dlp ffmpeg]}

      # Merge the desktop entry (share/applications).
      cp -r ${desktopItem}/share/. $out/share/
    '';

    meta = with lib; {
      description = "Minimal video/audio downloader — local web UI in C";
      platforms = platforms.linux;
      mainProgram = "olta";
    };
  }
