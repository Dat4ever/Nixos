import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "." as Local

ShellRoot {
  id: root

  PanelWindow {
    id: bar
    WlrLayershell.namespace: "quickshell-bar"
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
      id: barContainer
      anchors.fill: parent
      color: Theme.background
      radius: 8

      border {
        width: 2
        color: Theme.blue
      }

      Local.ClockBar {
        anchors.centerIn: parent
        z: 1
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        RowLayout {
          spacing: 16
          Layout.fillWidth: true 
          Layout.maximumWidth: (parent.width / 2) - 80 

          Local.WorkspaceBar {
            Layout.alignment: Qt.AlignVCenter
          }
          
          Local.TitleBar {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Item {
          Layout.fillWidth: true
        }

        RowLayout {
          spacing: 16
          Layout.alignment: Qt.AlignVCenter

          RowLayout {
            spacing: 8
            Local.BluetoothBar {
              Layout.alignment: Qt.AlignVCenter
            }
          
            Local.NetworkBar {
              Layout.alignment: Qt.AlignVCenter
            }
          }
          Local.LanguageBar {
            Layout.alignment: Qt.AlignVCenter
          }
          
          Local.BatteryBar {
            Layout.alignment: Qt.AlignVCenter
          }
        }
      }
    }
  }
}
