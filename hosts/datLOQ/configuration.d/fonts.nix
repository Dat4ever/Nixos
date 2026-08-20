{ pkgs, ... }:

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
in
{
  nixpkgs.overlays = [
    (final: prev: let
      font = mkFont final.stdenvNoCC;
    in {
      inter = font {
        pname = "inter";
        version = "4.1";
        files = [
          ../fonts/inter/Inter.ttc
          ../fonts/inter/InterVariable.ttf
          ../fonts/inter/InterVariable-Italic.ttf
        ];
      };

      geist = font {
        pname = "geist";
        version = "1.4.1";
        files = [
          ../fonts/geist/Geist.ttf
          ../fonts/geist/Geist-Italic.ttf
        ];
      };

      jetbrains-mono = font {
        pname = "jetbrains-mono-nerd-font";
        version = "3.5.0";
        files = [
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFont-Bold.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFont-BoldItalic.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFont-Italic.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFont-Regular.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Bold.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-BoldItalic.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Italic.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontMono-Regular.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Bold.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-BoldItalic.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Italic.ttf
          ../fonts/jetbrains-mono/JetBrainsMonoNerdFontPropo-Regular.ttf
        ];
      };

      noto-fonts-cjk-sans = font {
        pname = "noto-cjk-sans";
        version = "2.004";
        subdir = "opentype";
        files = [
          ../fonts/noto-cjk/NotoSansCJK-VF.otf.ttc
          ../fonts/noto-cjk/NotoSansMonoCJK-VF.otf.ttc
        ];
      };

      noto-fonts-color-emoji = font {
        pname = "noto-color-emoji";
        version = "2.051";
        files = [
          ../fonts/noto-emoji/NotoColorEmoji.ttf
        ];
      };

      nerd-fonts = prev.nerd-fonts // {
        commit-mono = font {
          pname = "commit-mono-nerd-font";
          version = "3.5.0";
          subdir = "opentype";
          files = [
            ../fonts/commit-mono/CommitMonoNerdFont-Bold.otf
            ../fonts/commit-mono/CommitMonoNerdFont-BoldItalic.otf
            ../fonts/commit-mono/CommitMonoNerdFont-Italic.otf
            ../fonts/commit-mono/CommitMonoNerdFont-Regular.otf
            ../fonts/commit-mono/CommitMonoNerdFontMono-Bold.otf
            ../fonts/commit-mono/CommitMonoNerdFontMono-BoldItalic.otf
            ../fonts/commit-mono/CommitMonoNerdFontMono-Italic.otf
            ../fonts/commit-mono/CommitMonoNerdFontMono-Regular.otf
            ../fonts/commit-mono/CommitMonoNerdFontPropo-Bold.otf
            ../fonts/commit-mono/CommitMonoNerdFontPropo-BoldItalic.otf
            ../fonts/commit-mono/CommitMonoNerdFontPropo-Italic.otf
            ../fonts/commit-mono/CommitMonoNerdFontPropo-Regular.otf
          ];
        };
      };
    })
  ];

  # Font packages (vendored locally)
  fonts.enableDefaultPackages = false;
  fonts.packages = with pkgs; [
    inter
    nerd-fonts.commit-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    geist
    jetbrains-mono
  ];
}
