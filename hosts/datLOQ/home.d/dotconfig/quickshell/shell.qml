import Quickshell
import Quickshell.Wayland
import QtQuick
import "."
import "./bar"

ShellRoot {
  PanelWindow {
    id: mainBar
    exclusiveZone: 24
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrLayershell.None
    anchors {
      top: true
      left: true
      right: true
    }

    margins {
      top: 0
      left: 0
      right: 0
    }

    implicitHeight: 24

    Rectangle {
      id: barBackground
      anchors.fill: parent
      radius: 0
      color: Colors.color_dark_gray

      Item {
        id: leftCluster
        anchors {
          verticalCenter: parent.verticalCenter
          left: parent.left
          leftMargin: 16
        }
        height: parent.height
        width: rowL.implicitWidth

        Row {
          id: rowL
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0

          Launcher {}
          Separator {}
          Workspace {}
          Separator {}
          ActiveWindow {}
        }
      }

      Item {
        id: centerCluster
        anchors.centerIn: parent
        height: parent.height
        width: centralClock.width

        Clock {
          id: centralClock
          anchors.centerIn: parent
        }
      }

      Item {
        id: rightCluster
        anchors {
          verticalCenter: parent.verticalCenter
          right: parent.right
          rightMargin: 16
        }
        height: parent.height
        width: rowR.implicitWidth

        Row {
          id: rowR
          anchors.verticalCenter: parent.verticalCenter
          spacing: 0

          Keyboard {}
          Separator {}
          Bluetooth {}
          Separator {}
          Network {}
          Separator {}
          Volume {}
          Separator {}
          Battery {}
          Separator {}
          Power {}
        }
      }
    }
  }
}
