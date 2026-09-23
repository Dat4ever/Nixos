{ pkgs, lib, ... }:

let
  mkFont = { pname, version, files, subdir ? "truetype" }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      dontUnpack = true;
      installPhase = ''
        mkdir -p "$out/share/fonts/${subdir}"
      '' + builtins.concatStringsSep "\n" (map (f:
        "install -Dm644 ${f} \"$out/share/fonts/${subdir}/${baseNameOf (toString f)}\""
      ) files);
    };

  inter = mkFont {
    pname = "inter";
    version = "4.1";
    files = [
      ../../../extras/fonts/inter/Inter.ttc
      ../../../extras/fonts/inter/InterVariable.ttf
      ../../../extras/fonts/inter/InterVariable-Italic.ttf
    ];
  };

  geist = mkFont {
    pname = "geist";
    version = "1.4.1";
    files = [
      ../../../extras/fonts/geist/Geist.ttf
      ../../../extras/fonts/geist/Geist-Italic.ttf
    ];
  };

  jetbrains-mono = mkFont {
    pname = "jetbrains-mono-nerd-font";
    version = "3.5.0";
    files = [
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFont-Bold.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFont-BoldItalic.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFont-Italic.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFont-Regular.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Bold.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-BoldItalic.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Italic.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Regular.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Bold.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-BoldItalic.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Italic.ttf
      ../../../extras/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Regular.ttf
    ];
  };

  commit-mono = mkFont {
    pname = "commit-mono-nerd-font";
    version = "3.5.0";
    subdir = "opentype";
    files = [
      ../../../extras/fonts/commit-mono/CommitMonoNerdFont-Bold.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFont-BoldItalic.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFont-Italic.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFont-Regular.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontMono-Bold.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontMono-BoldItalic.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontMono-Italic.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontMono-Regular.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontPropo-Bold.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontPropo-BoldItalic.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontPropo-Italic.otf
      ../../../extras/fonts/commit-mono/CommitMonoNerdFontPropo-Regular.otf
    ];
  };

  noto-cjk-sans = mkFont {
    pname = "noto-cjk-sans";
    version = "2.004";
    subdir = "opentype";
    files = [
      ../../../extras/fonts/noto-cjk/NotoSansCJK-VF.otf.ttc
      ../../../extras/fonts/noto-cjk/NotoSansMonoCJK-VF.otf.ttc
    ];
  };

  noto-color-emoji = mkFont {
    pname = "noto-color-emoji";
    version = "2.051";
    files = [
      ../../../extras/fonts/noto-emoji/NotoColorEmoji.ttf
    ];
  };

  theme-switch = pkgs.writeShellApplication {
    name = "theme-switch";
    runtimeInputs = [ pkgs.jq pkgs.kitty pkgs.hyprland pkgs.hyprpaper pkgs.quickshell pkgs.util-linux pkgs.procps pkgs.coreutils pkgs.findutils pkgs.gnused pkgs.gawk pkgs.dconf ];
    excludeShellChecks = [ "SC2154" ];
    text = builtins.readFile ./theme/scripts/theme-switch.sh;
  };

  theme-rofi = pkgs.writeShellApplication {
    name = "theme-rofi";
    runtimeInputs = [ pkgs.rofi ];
    text = builtins.readFile ./theme/scripts/theme-rofi.sh;
  };

  theme-wallpaper = pkgs.writeShellApplication {
    name = "theme-wallpaper";
    runtimeInputs = [ pkgs.hyprland pkgs.hyprpaper pkgs.procps pkgs.coreutils pkgs.jq ];
    excludeShellChecks = [ "SC2154" ];
    text = builtins.readFile ./theme/scripts/theme-wallpaper.sh;
  };

  cursor-themes = pkgs.stdenvNoCC.mkDerivation {
    pname = "cursor-themes";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/share/icons"
      cp -r ${../../../extras/cursors/capitaine-nord} "$out/share/icons/Capitaine Cursors (Nord)"
      cp -r ${../../../extras/cursors/capitaine-gruvbox} "$out/share/icons/Capitaine Cursors (Gruvbox)"
      cp -r ${../../../extras/cursors/phinger-everforest} "$out/share/icons/Phinger Cursors (Everforest)"
    '';
  };

  gtk-qt-themes = pkgs.stdenvNoCC.mkDerivation {
    pname = "gtk-qt-themes";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/share/themes" "$out/share/Kvantum"
      cp -r ${../../../extras/gtk/Squared-nord} "$out/share/themes/Squared-nord"
      cp -r ${../../../extras/gtk/Gruvbox-Dark} "$out/share/themes/Gruvbox-Dark"
      cp -r ${../../../extras/gtk/Everforest} "$out/share/themes/Everforest"
      cp -r ${../../../extras/kvantum/Nordic} "$out/share/Kvantum/Nordic"
      cp -r ${../../../extras/kvantum/Gruvbox-Dark-Brown} "$out/share/Kvantum/Gruvbox-Dark-Brown"
      cp -r ${../../../extras/kvantum/Everforest} "$out/share/Kvantum/Everforest"
    '';
  };
in
{
  home.packages = [
    # Theme switcher scripts
    theme-switch
    theme-rofi
    theme-wallpaper
    # Fonts
    inter
    geist
    jetbrains-mono
    commit-mono
    noto-cjk-sans
    noto-color-emoji
    # GTK/Kvantum themes
    gtk-qt-themes
    # Cursor themes
    cursor-themes
  ];

  # Fontconfig
  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <alias binding="strong">
        <family>monospace</family>
        <prefer><family>CommitMono Nerd Font</family></prefer>
      </alias>
      <alias binding="strong">
        <family>sans-serif</family>
        <prefer><family>Geist</family></prefer>
      </alias>
      <alias binding="strong">
        <family>sans</family>
        <prefer><family>Geist</family></prefer>
      </alias>
      <alias binding="strong">
        <family>serif</family>
        <prefer><family>Geist</family></prefer>
      </alias>
    </fontconfig>
  '';

  # Apply the current (or default) theme after every activation
  home.activation.applyTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    theme="nord"
    if [[ -f "$HOME/.local/state/theme/current" ]]; then
      theme="$(${pkgs.coreutils}/bin/cat "$HOME/.local/state/theme/current")"
    fi
    ${theme-switch}/bin/theme-switch --if-changed "$theme"
  '';
}
