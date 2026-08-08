{ pkgs, ... }:

let
  commonLibraries = with pkgs; [
    # C / System
    stdenv.cc.cc
    glibc
    zlib
    zstd
    icu
    util-linux
    fuse
    # GUI (Electron / GTK / Wayland)
    glib
    gtk3
    atk
    dbus
    gsettings-desktop-schemas
    systemd
    wayland
    # Font & Render
    fontconfig
    freetype
    pango
    gdk-pixbuf
    expat
    libxml2
    cairo
    # Voice & Game / Audio
    alsa-lib
    pulseaudio
    libpulseaudio
    SDL
    SDL2
    libtheora
    # Graphics / OpenGL / Vulkan
    libdrm
    libgbm
    mesa
    libGL
    vulkan-loader
    # Security & Web
    openssl
    nss
    nspr
    cups
    # Xorg
    libxkbcommon
    libX11
    libXcursor
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXScrnSaver
    libxcb
    libXcomposite
    libXdamage
  ];
in

{
  # Run unpatched dynamic binaries on NixOS
  programs.nix-ld = {
    enable = true;
    libraries = commonLibraries;
  };

  # Run AppImage on NixOS
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: commonLibraries;
    };
  };
}
