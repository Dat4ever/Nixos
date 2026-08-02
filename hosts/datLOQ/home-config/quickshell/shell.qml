import Quickshell
import Quickshell.Wayland
import QtQuick
import "."
import "./bar"

ShellRoot {
  PanelWindow {
    id: mainBar
    exclusiveZone: 32
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
      left: 8
      right: 8
    }

    implicitHeight: 28

    Rectangle {
      id: barBackground
      anchors.fill: parent
      radius: 16
      color: Colors.nord_dark_gray
      border.width: 2
      border.color: Colors.nord_blue

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

          Text {
            text: "│"
            color: Colors.nord_gray
            font.family: Colors.fontName
            font.pixelSize: 14
            leftPadding: 12
            rightPadding: 12
          }

          Workspace {}

          Text {
            text: "│"
            color: Colors.nord_gray
            font.family: Colors.fontName
            font.pixelSize: 14
            leftPadding: 12
            rightPadding: 12
          }

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
          Text { text: "│"; color: Colors.nord_gray; font.family: Colors.fontName; font.pixelSize: 14; leftPadding: 10; rightPadding: 10 }
          Bluetooth {}
          Text { text: "│"; color: Colors.nord_gray; font.family: Colors.fontName; font.pixelSize: 14; leftPadding: 10; rightPadding: 10 }
          Network {}
          Text { text: "│"; color: Colors.nord_gray; font.family: Colors.fontName; font.pixelSize: 14; leftPadding: 10; rightPadding: 10 }
          Volume {}
          Text { text: "│"; color: Colors.nord_gray; font.family: Colors.fontName; font.pixelSize: 14; leftPadding: 10; rightPadding: 10 }
          Battery {}
          Text { text: "│"; color: Colors.nord_gray; font.family: Colors.fontName; font.pixelSize: 14; leftPadding: 10; rightPadding: 10 }
          Power {}
        }
      }
    }
  }
}
