import QtQuick
import Quickshell.Io
import ".."

Item {
  id: keyboardWidget
  implicitWidth: textDisplay.implicitWidth
  implicitHeight: 24

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
    font.pixelSize: 13
    font.bold: true
    color: Colors.nord_magenta
    text: " " + rawLayout
  }
}
