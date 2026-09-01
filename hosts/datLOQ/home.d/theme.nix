{ pkgs, lib, ... }:

let
  mkFont = stdenvNoCC: { pname, version, files, subdir ? "truetype" }:
    stdenvNoCC.mkDerivation {
      inherit pname version;
      dontUnpack = true;
      installPhase = ''
        mkdir -p "$out/share/fonts/${subdir}"
      '' + builtins.concatStringsSep "\n" (map (f:
        "install -Dm644 ${f} \"$out/share/fonts/${subdir}/${baseNameOf (toString f)}\""
      ) files);
    };

  font = mkFont pkgs.stdenvNoCC;

  inter = font {
    pname = "inter";
    version = "4.1";
    files = [
      ./theme/fonts/inter/Inter.ttc
      ./theme/fonts/inter/InterVariable.ttf
      ./theme/fonts/inter/InterVariable-Italic.ttf
    ];
  };

  geist = font {
    pname = "geist";
    version = "1.4.1";
    files = [
      ./theme/fonts/geist/Geist.ttf
      ./theme/fonts/geist/Geist-Italic.ttf
    ];
  };

  jetbrains-mono = font {
    pname = "jetbrains-mono-nerd-font";
    version = "3.5.0";
    files = [
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFont-Bold.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFont-BoldItalic.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFont-Italic.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFont-Regular.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Bold.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-BoldItalic.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Italic.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Regular.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Bold.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-BoldItalic.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Italic.ttf
      ./theme/fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Regular.ttf
    ];
  };

  commit-mono = font {
    pname = "commit-mono-nerd-font";
    version = "3.5.0";
    subdir = "opentype";
    files = [
      ./theme/fonts/commit-mono/CommitMonoNerdFont-Bold.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFont-BoldItalic.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFont-Italic.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFont-Regular.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontMono-Bold.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontMono-BoldItalic.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontMono-Italic.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontMono-Regular.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontPropo-Bold.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontPropo-BoldItalic.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontPropo-Italic.otf
      ./theme/fonts/commit-mono/CommitMonoNerdFontPropo-Regular.otf
    ];
  };

  noto-cjk-sans = font {
    pname = "noto-cjk-sans";
    version = "2.004";
    subdir = "opentype";
    files = [
      ./theme/fonts/noto-cjk/NotoSansCJK-VF.otf.ttc
      ./theme/fonts/noto-cjk/NotoSansMonoCJK-VF.otf.ttc
    ];
  };

  noto-color-emoji = font {
    pname = "noto-color-emoji";
    version = "2.051";
    files = [
      ./theme/fonts/noto-emoji/NotoColorEmoji.ttf
    ];
  };

  theme-switch = pkgs.writeShellApplication {
    name = "theme-switch";
    runtimeInputs = [ pkgs.jq pkgs.kitty pkgs.hyprland pkgs.hyprpaper pkgs.quickshell pkgs.procps pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.dconf ];
    excludeShellChecks = [ "SC2154" ]; # color/name/theme vars are assigned via `source`
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
    excludeShellChecks = [ "SC2154" ]; # wallpaper var is assigned via `source`
    text = builtins.readFile ./theme/scripts/theme-wallpaper.sh;
  };

  cursor-themes = pkgs.stdenvNoCC.mkDerivation {
    pname = "cursor-themes";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/share/icons"
      cp -r ${./theme/cursors/capitaine-nord} "$out/share/icons/Capitaine Cursors (Nord)"
      cp -r ${./theme/cursors/capitaine-gruvbox} "$out/share/icons/Capitaine Cursors (Gruvbox)"
    '';
  };

  gtk-qt-themes = pkgs.stdenvNoCC.mkDerivation {
    pname = "gtk-qt-themes";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/share/themes" "$out/share/Kvantum"
      cp -r ${./theme/gtk-qt/themes/Nordic} "$out/share/themes/Nordic"
      cp -r ${./theme/gtk-qt/themes/Gruvbox-Dark} "$out/share/themes/Gruvbox-Dark"
      cp -r ${./theme/gtk-qt/kvantum/Nordic} "$out/share/Kvantum/Nordic"
      cp -r ${./theme/gtk-qt/kvantum/Gruvbox-Dark-Brown} "$out/share/Kvantum/Gruvbox-Dark-Brown"
    '';
  };
in
{
  home.packages = [
    # Fonts
    inter
    geist
    jetbrains-mono
    commit-mono
    noto-cjk-sans
    noto-color-emoji
    # Theme switcher scripts
    theme-switch
    theme-rofi
    theme-wallpaper
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
    THEME_SWITCH_NO_RELOAD=1 ${theme-switch}/bin/theme-switch "$theme"
  '';
}
