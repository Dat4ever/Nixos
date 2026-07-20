import QtQuick
import Quickshell.Io
import ".."

Rectangle {
  id: keyboardWidget
  implicitWidth: textDisplay.implicitWidth + 16
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_green
  color: Colors.nord_dark_gray

  property string rawLayout: "US"

  Process {
    id: readLayout
    command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        var cleanData = data.toString().replace(/[\r\n\s]+/g, "").toUpperCase();
        if (cleanData.length > 0) {
          if (cleanData.indexOf("TURKISH") !== -1 || cleanData === "TR") {
            rawLayout = "TRQ";
          } else {
            rawLayout = "US";
          }
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      readLayout.running = true
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    color: Colors.nord_green
    text: "  " + rawLayout
  }
}
