{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    glib                      # gsettings binary
    gsettings-desktop-schemas # GLib schemas (GTK theme backend)
    libsForQt5.qt5ct                   # Qt5 platform theme plugin
    qt6Packages.qt6ct                  # Qt6 platform theme plugin
    libsForQt5.qtstyleplugin-kvantum   # Kvantum style engine (Qt5)
    qt6Packages.qtstyleplugin-kvantum  # Kvantum style engine (Qt6)
  ];

  # Link gsettings schemas into system profile (GLib looks in glib-2.0/schemas/)
  environment.pathsToLink = [ "/share/gsettings-schemas" "/share/glib-2.0" ];
  environment.extraSetup = ''
    # Collect ALL schema XML files from every package into one directory
    mkdir -p "$out/share/glib-2.0/schemas"
    for schema_dir in "$out"/share/gsettings-schemas/*/; do
      if [ -d "$schema_dir/glib-2.0/schemas" ]; then
        for f in "$schema_dir/glib-2.0/schemas/"*.xml; do
          cp "$f" "$out/share/glib-2.0/schemas/$(basename "$f")" 2>/dev/null || true
        done
      fi
    done
    # Compile ALL schemas into a single gschemas.compiled
    ${pkgs.glib}/bin/glib-compile-schemas "$out/share/glib-2.0/schemas/" 2>/dev/null || true
  '';

  # Qt settings
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qt5ct";
  environment.profileRelativeSessionVariables = {
    QT_PLUGIN_PATH = [ "/qt-6/plugins" "/qt-5/plugins" ];
    QML2_IMPORT_PATH = [ "/qt-6/qml" "/qt-5/qml" ];
  };
}
