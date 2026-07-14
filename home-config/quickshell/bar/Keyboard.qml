import QtQuick
import Quickshell.Io
import "." 
import ".." 

Item {
  anchors.fill: parent
  property string rawLayout: "US"

  Process {
    id: readLayout
    command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"]
    running: true
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
    onRunningChanged: if (!running) running = true
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      readLayout.running = false
    }
  }

  Text {
    anchors.centerIn: parent
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    color: Colors.nord_green

    text: "  " + rawLayout
  }
}
