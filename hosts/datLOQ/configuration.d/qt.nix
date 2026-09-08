{ pkgs, ... }:

{
  # Qt theming: theme-switch writes the qt5ct/qt6ct + Kvantum configs (runtime); the platform theme plugin, style engine and env come from here.
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qt5ct";
  environment.profileRelativeSessionVariables = {
    QT_PLUGIN_PATH = [ "/qt-6/plugins" "/qt-5/plugins" ];
    QML2_IMPORT_PATH = [ "/qt-6/qml" "/qt-5/qml" ];
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.qt5ct                   # Qt5 platform theme plugin
    qt6Packages.qt6ct                  # Qt6 platform theme plugin
    libsForQt5.qtstyleplugin-kvantum   # Kvantum style engine (Qt5)
    qt6Packages.qtstyleplugin-kvantum  # Kvantum style engine (Qt6)
  ];
}
