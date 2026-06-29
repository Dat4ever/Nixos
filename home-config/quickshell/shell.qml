import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "."

ShellRoot {
  PanelWindow {
    id: panel

    anchors {
      top: true
      left: true
      right: true
    }

    margins {
      top: 10
      left: 12
      right: 12
    }

    implicitHeight: 32
    color: "transparent"

    Rectangle {
      anchors.fill: parent

      color: Theme.background
      radius: 8

      border {
        width: 2
        color: Theme.blue
      }

      RowLayout {
        anchors {
          left: parent.left
          leftMargin: 16
          verticalCenter: parent.verticalCenter
        }

        spacing: 8

        Repeater {
          model: 5

          Text {
            property bool isActive:
              Hyprland.focusedWorkspace &&
              Hyprland.focusedWorkspace.id === (index + 1)

            text: index + 1
            color: isActive ? Theme.cyan : Theme.foreground

            font {
              family: Theme.font
              pixelSize: 14
              weight: 600
            }
          }
        }
      }

      Text {
        anchors.centerIn: parent

        text: Qt.formatDateTime(clock.date, "hh:mm")
        color: Theme.foreground

        font {
          family: Theme.font
          pixelSize: 14
          weight: 600
          letterSpacing: -1
        }
      }
    }

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }
  }
}
