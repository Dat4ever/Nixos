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

  # Default terminal
  xdg.configFile."xdg-terminals.list".text = "kitty.desktop\n";

  # Default applications
  # Usage: xdg-open <file> / xdg-mime query default <mime-type>
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Browser
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";

      # Images (imv; mpv fallback)
      "image/png" = [ "imv.desktop" "mpv.desktop" ];
      "image/jpeg" = [ "imv.desktop" "mpv.desktop" ];
      "image/gif" = [ "imv.desktop" "mpv.desktop" ];
      "image/webp" = [ "imv.desktop" "mpv.desktop" ];
      "image/svg+xml" = [ "imv.desktop" "mpv.desktop" ];
      "image/bmp" = [ "imv.desktop" "mpv.desktop" ];
      "image/tiff" = [ "imv.desktop" "mpv.desktop" ];

      # Video
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";

      # Audio
      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";

      # Text
      "text/plain" = "nvim.desktop";
      "application/json" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";

      # Office (LibreOffice)
      "application/msword" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/rtf" = "writer.desktop";
      "application/vnd.oasis.opendocument.text" = "writer.desktop";
      "application/vnd.ms-excel" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
      "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop";
      "text/csv" = "calc.desktop";
      "application/vnd.ms-powerpoint" = "impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";
      "application/vnd.oasis.opendocument.presentation" = "impress.desktop";

      # Torrents
      "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
      "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";

      # Archives
      "application/zip" = "yazi.desktop";
      "application/gzip" = "yazi.desktop";
      "application/x-tar" = "yazi.desktop";
      "application/x-7z-compressed" = "yazi.desktop";
      "application/x-rar-compressed" = "yazi.desktop";
      "application/vnd.rar" = "yazi.desktop";
      "application/x-bzip2" = "yazi.desktop";

      # Comic books
      "application/vnd.comicbook+zip" = "org.pwmt.zathura.desktop";
      "application/vnd.comicbook-rar" = "org.pwmt.zathura.desktop";

      # Ebooks
      "application/epub+zip" = "org.pwmt.zathura.desktop";

      # Other
      "application/xhtml+xml" = "firefox.desktop";
    };
  };
}
