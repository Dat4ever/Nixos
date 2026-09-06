{
  xdg.enable = true;
  dconf.enable = true;

  # Xdg user dirs
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    # Xdg dirs locations
    download = "$HOME/Downloads";
    documents = "$HOME/Documents";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    music = "$HOME/Music";
    desktop = "$HOME/Desktop";
    templates = "$HOME/Downloads";
    publicShare = "$HOME/Public";
  };

  # QT settings
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };
}
