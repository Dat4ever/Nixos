import QtQuick
import Quickshell.Hyprland
import "."

Text {
  text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
  color: Theme.blue
  
  elide: Text.ElideRight 
  maximumLineCount: 1

  font {
    family: Theme.font
    pixelSize: 13
    weight: 500
  }
}

