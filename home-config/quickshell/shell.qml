import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "."

ShellRoot {
  id: root

  property string keyboardLayout: "us"

  Process {
    id: keyboardProcess
    command: [
      "sh",
      "-c",
      "hyprctl devices -j | jq -r '.keyboards[] | select(.main==true) | .active_keymap'"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        let txt = text.trim().toLowerCase()

        if (txt.includes("english"))
          root.keyboardLayout = "us"
        else if (txt.includes("turkish"))
          root.keyboardLayout = "trq"
        else
          root.keyboardLayout = txt
      }
    }
  }

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

      Text {
        anchors {
          right: parent.right
          rightMargin: 16
          verticalCenter: parent.verticalCenter
        }

        text: root.keyboardLayout
        color: Theme.foreground

        font {
          family: Theme.font
          pixelSize: 14
          weight: 600
        }
      }
    }

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    Timer {
      interval: 1000
      running: true
      repeat: true

      onTriggered: {
        keyboardProcess.running = true
      }
    }
  }
}
