import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
  id: networkWidget
  implicitWidth: textDisplay.implicitWidth + 20
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_cyan
  color: Colors.nord_dark_gray

  property string netStatus: "Checking..."
  property string netIcon: "󰤅"

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!netCheck.running) {
        netCheck.running = true
      }
    }
  }

  Process {
    id: netCheck
    command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
    running: false

    stdout: StdioCollector {
      onTextChanged: {
        var lines = text.trim().split("\n");
        var hasEthernet = false;
        var hasWifi = false;

        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(":");
          var type = parts[0];
          var state = parts[1];

          if (state === "connected") {
            if (type === "ethernet") {
              hasEthernet = true;
            } else if (type === "wifi") {
              hasWifi = true;
            }
          }
        }

        if (hasEthernet) {
          networkWidget.netStatus = "Wired";
          networkWidget.netIcon = "󰲟";
        } else if (hasWifi) {
          networkWidget.netStatus = "Online";
          networkWidget.netIcon = "󰤨";
        } else {
          networkWidget.netStatus = "Offline";
          networkWidget.netIcon = "󰤮";
        }
      }
    }
  }

  Process {
    id: launchNmtui
    command: ["kitty", "-e", "nmtui"]
    running: false
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      launchNmtui.running = true
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    text: networkWidget.netIcon + "  " + networkWidget.netStatus
    color: Colors.nord_cyan
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
  }
}
