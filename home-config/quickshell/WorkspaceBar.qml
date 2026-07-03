import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "."

RowLayout {
  spacing: 8

  Repeater {
    model: 5

    Column {
      spacing: 2

      property bool isActive:
      Hyprland.focusedWorkspace &&
      Hyprland.focusedWorkspace.id === (index + 1)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: index + 1
        color: parent.isActive ? Theme.cyan : Theme.foreground

        font {
          family: Theme.font
          pixelSize: 14
          weight: 600
        }
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 14
        height: 2
        radius: 1
        color: Theme.cyan
        visible: parent.isActive
      }
    }
  }
}
