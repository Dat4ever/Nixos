import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
  id: networkWidget
  implicitWidth: textDisplay.implicitWidth + 16 
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_cyan
  color: Colors.nord_dark_gray

  property string netStatus: "Checking..."
  property string netIcon: "   "

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      netCheck.running = false
      netCheck.running = true
    }
  }

  Process {
    id: netCheck
    command: ["nmcli", "-t", "-f", "CONNECTIVITY", "g"]
    running: false
    onRunningChanged: {
      if (!running) {
        var output = stdout.text.trim();
        if (output && output.includes("full")) {
          networkWidget.netStatus = "Online";
          networkWidget.netIcon = "   ";
        } else if (output && output.includes("limited")) {
          networkWidget.netStatus = "No Internet";
          networkWidget.netIcon = "   ";
        } else {
          networkWidget.netStatus = "Offline";
          networkWidget.netIcon = "   ";
        }
      }
    }
    stdout: StdioCollector {}
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent 
    text: networkWidget.netIcon + " " + networkWidget.netStatus
    color: Colors.nord_cyan
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
  }
}
