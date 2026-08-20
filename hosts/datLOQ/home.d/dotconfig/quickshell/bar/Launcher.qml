import QtQuick
import Quickshell.Io
import ".."

Item {
  id: launcherWidget
  implicitWidth: textDisplay.implicitWidth
  implicitHeight: 24

  Process {
    id: launchRofi
    command: ["rofi", "-show", "drun"]
    running: false
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      launchRofi.running = true;
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    text: "󰀻"
    color: Colors.color_cyan
    font.family: Colors.fontName
    font.pixelSize: 16
    font.bold: true
  }
}
