import Quickshell
import Quickshell.Wayland
import QtQuick
import ".." 

PanelWindow {
  id: barWindow
  
  exclusiveZone: 24
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Top

  anchors {
    top: true
    left: true
    right: true
  }

  margins {
    top: 8
  }

  implicitHeight: 24

  Item {
    anchors.fill: parent
    Rectangle {
      id: leftBox
      anchors {
        top: parent.top
        left: parent.left
        leftMargin: 8
      }
      width: 110
      height: 24
      color: Colors.background
      radius: 8
      border.color: Colors.nord_dark_gray
      border.width: 1

      Loader {
        anchors.fill: parent
        source: Qt.resolvedUrl("left/Workspace.qml")
      }
    }

    Rectangle {
      id: centerBox
      anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
      }
      width: 64
      height: 24
      color: Colors.background
      radius: 8
      border.color: Colors.nord_dark_gray
      border.width: 1

      Loader {
        anchors.fill: parent
        source: Qt.resolvedUrl("center/Clock.qml")
      }
    }

    Rectangle {
      id: batteryBox
      anchors {
        top: parent.top
        right: parent.right
        rightMargin: 8
      }
      width: 80
      height: 24
      color: Colors.background
      radius: 8
      border.color: Colors.nord_dark_gray
      border.width: 1

      Loader {
        anchors.fill: parent
        source: Qt.resolvedUrl("right/Battery.qml")
      }
    }

    Rectangle {
      id: keyboardBox
      anchors {
        top: parent.top
        right: batteryBox.left
        rightMargin: 8
      }
      width: 60
      height: 24
      color: Colors.background
      radius: 8
      border.color: Colors.nord_dark_gray
      border.width: 1

      Loader {
        anchors.fill: parent
        source: Qt.resolvedUrl("right/Keyboard.qml")
      }
    }
  }
}
