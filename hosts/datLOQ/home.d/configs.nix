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
  home.file.".config/yazi/init.lua".source = ./dotconfig/yazi/init.lua;
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

  # Polkit authentication agent
  services.hyprpolkitagent.enable = true;

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
  home.file.".config/nvim".source = ./dotconfig/nvim; # Neovim editor config
  home.file.".config/kitty/kitty.conf".source = ./dotconfig/kitty/kitty.conf; # Kitty terminal config
  home.file.".config/rofi/config.rasi".source = ./dotconfig/rofi/config.rasi; # Rofi launcher config
  home.file.".config/quickshell/shell.qml".source = ./dotconfig/quickshell/shell.qml;                     # Quickshell bar main shell
  home.file.".config/quickshell/Notifications.qml".source = ./dotconfig/quickshell/Notifications.qml;     # Notification daemon (themed popup)
  home.file.".config/quickshell/bar/Base.qml".source = ./dotconfig/quickshell/bar/Base.qml;               # Bar window + layout
  home.file.".config/quickshell/bar/widgets/ActiveWindow.qml".source = ./dotconfig/quickshell/bar/widgets/ActiveWindow.qml; # Bar widget: active window
  home.file.".config/quickshell/bar/widgets/Battery.qml".source = ./dotconfig/quickshell/bar/widgets/Battery.qml; # Bar widget: battery + brightness
  home.file.".config/quickshell/bar/widgets/Bluetooth.qml".source = ./dotconfig/quickshell/bar/widgets/Bluetooth.qml; # Bar widget: bluetooth
  home.file.".config/quickshell/bar/widgets/Clock.qml".source = ./dotconfig/quickshell/bar/widgets/Clock.qml; # Bar widget: clock
  home.file.".config/quickshell/bar/widgets/Keyboard.qml".source = ./dotconfig/quickshell/bar/widgets/Keyboard.qml; # Bar widget: keyboard layout
  home.file.".config/quickshell/bar/widgets/Launcher.qml".source = ./dotconfig/quickshell/bar/widgets/Launcher.qml; # Bar widget: app launcher
  home.file.".config/quickshell/bar/widgets/Network.qml".source = ./dotconfig/quickshell/bar/widgets/Network.qml; # Bar widget: network status
  home.file.".config/quickshell/bar/widgets/Power.qml".source = ./dotconfig/quickshell/bar/widgets/Power.qml; # Bar widget: power menu
  home.file.".config/quickshell/bar/widgets/Separator.qml".source = ./dotconfig/quickshell/bar/widgets/Separator.qml; # Bar widget: separator
  home.file.".config/quickshell/bar/widgets/Volume.qml".source = ./dotconfig/quickshell/bar/widgets/Volume.qml; # Bar widget: volume
  home.file.".config/quickshell/bar/widgets/Workspace.qml".source = ./dotconfig/quickshell/bar/widgets/Workspace.qml; # Bar widget: workspaces
  home.file.".config/themes".source = ./theme; # Theme definitions
  home.file.".config/wallpapers".source = ../../../extras/wallpapers; # Wallpapers
  home.file.".config/kvantum-themes".source = ../../../extras/kvantum; # Kvantum themes

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
