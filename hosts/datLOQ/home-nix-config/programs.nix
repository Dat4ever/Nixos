{ pkgs, lib, ... }:

{
  # Bash settings
  programs.bash = {
    enable = true;
    shellAliases = {
      nrsf = "sudo nixos-rebuild switch --flake .#datLOQ";
      ncg = "sudo nix-collect-garbage -d";
      nfu-nrsf = "nix flake update && sudo nixos-rebuild switch --flake .#datLOQ";
    };
    initExtra = builtins.readFile ../home-config/bashrc;
  };

  # Git settings
  programs.git = {
    enable = true;
    settings = {
      user.name = "Dat4ever";
      user.email = "dat4ever87@gmail.com";
    };
  };

  # Desktop enviroment and its config file
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ../home-config/hypr/hyprland.lua;
  };

  # Btop settings
  programs.btop = {
    enable = true;
    extraConfig = builtins.readFile ../home-config/btop/btop.conf;
  };

  # Obs studio
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs # Wayland obs screen capture
    ];
  };

  # Config files
  home.file.".config/nvim".source = ../home-config/nvim;
  home.file.".config/kitty".source = ../home-config/kitty;
  home.file.".config/quickshell".source = ../home-config/quickshell;
  home.file.".config/rofi".source = ../home-config/rofi;
  home.file.".config/yazi/yazi.toml".source = ../home-config/yazi/yazi.toml;
  home.file.".config/yazi/keymap.toml".source = ../home-config/yazi/keymap.toml;
  home.file.".config/yazi/init.lua".source = ../home-config/yazi/init.lua;
  home.activation.yaziPkgInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -Dm644 ${../home-config/yazi/package.toml} "$HOME/.config/yazi/package.toml"
  '';

  # Treesitter parsers for the languages configured in nvim config
  home.file.".local/share/nvim/site/parser/vim.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-vim}/parser";
  home.file.".local/share/nvim/site/parser/lua.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-lua}/parser";
  home.file.".local/share/nvim/site/parser/rust.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-rust}/parser";
  home.file.".local/share/nvim/site/parser/c.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-c}/parser";
  home.file.".local/share/nvim/site/parser/cpp.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-cpp}/parser";
  home.file.".local/share/nvim/site/parser/objc.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-objc}/parser";
  home.file.".local/share/nvim/site/parser/nix.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-nix}/parser";
  home.file.".local/share/nvim/site/parser/bash.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-bash}/parser";
  home.file.".local/share/nvim/site/parser/python.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-python}/parser";
  home.file.".local/share/nvim/site/parser/go.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-go}/parser";
  home.file.".local/share/nvim/site/parser/java.so".source = "${pkgs.tree-sitter-grammars.tree-sitter-java}/parser";
}
