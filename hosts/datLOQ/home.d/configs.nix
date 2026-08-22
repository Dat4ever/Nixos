{ pkgs, ... }:

{
  # Bash configuration  
  programs.bash = {
    enable = true;
    shellAliases = {
      nrsf = "sudo nixos-rebuild switch --flake .#datLOQ";
      ncg = "sudo nix-collect-garbage -d";
      nfu-nrsf = "nix flake update && sudo nixos-rebuild switch --flake .#datLOQ";
      start-tor = "sudo systemctl start tor-transparent";
      stop-tor = "sudo systemctl stop tor-transparent";
     };
    initExtra = builtins.readFile ./dotconfig/bashrc; 
  };

  # Yazi configuration
  home.file.".config/yazi/yazi.toml".source = ./dotconfig/yazi/yazi.toml;
  home.file.".config/yazi/keymap.toml".source = ./dotconfig/yazi/keymap.toml;
  home.file.".config/yazi/theme.toml".source = ./dotconfig/yazi/theme.toml;
  home.file.".config/yazi/init.lua".source = ./dotconfig/yazi/init.lua;

  stylix.targets.yazi.enable = false;

  programs.yazi = {
    enable = true;
    plugins = {
      git = pkgs.yaziPlugins.git;      # git.yazi
      mount = pkgs.yaziPlugins.mount;  # mount.yazi
      chmod = pkgs.yaziPlugins.chmod;  # chmod.yazi
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = "Dat4ever";
      user.email = "dat4ever87@gmail.com";
    };
  };

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = builtins.readFile ./dotconfig/hypr/hyprland.lua;
  };

  # Btop configuration
  programs.btop = {
    enable = true;
    extraConfig = builtins.readFile ./dotconfig/btop/btop.conf;
  };

  # Obs configuration
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs # Wayland obs screen capture
    ];
  };

  # Direnv configuration
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # Other Configuration files
  home.file.".config/nvim".source = ./dotconfig/nvim;
  home.file.".config/kitty".source = ./dotconfig/kitty;
  home.file.".config/quickshell".source = ./dotconfig/quickshell;
  home.file.".config/rofi".source = ./dotconfig/rofi;
  home.file.".config/opencode/tui.json".source = ./dotconfig/opencode/tui.json;

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
