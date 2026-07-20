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
      top: 8
    }

    implicitHeight: 24
    Workspace {
      anchors {
        verticalCenter: parent.verticalCenter
        left: parent.left
        leftMargin: 12
      }
    }

    Item {
      anchors.centerIn: parent
      width: centralClock.width
      height: parent.height

      Clock {
        id: centralClock
        anchors.centerIn: parent
      }
    }

    Row {
      anchors {
        verticalCenter: parent.verticalCenter
        right: parent.right
        rightMargin: 12
      }
      spacing: 8

      Network {}
      Keyboard {}
      Battery {}
    }
  }
}
