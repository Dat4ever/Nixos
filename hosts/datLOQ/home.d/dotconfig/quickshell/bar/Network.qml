import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
  id: networkWidget
  implicitWidth: textDisplay.implicitWidth
  implicitHeight: 24

  property string netStatus: "Checking..."
  property string netIcon: "󰤅"

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!netCheck.running) {
        netCheck.running = true;
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
    text: networkWidget.netIcon + " " + networkWidget.netStatus
    color: Colors.color_cyan
    font.family: Colors.fontName
    font.pixelSize: 13
    font.bold: true
  }

  Rectangle {
    id: accentLine
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: parent.width
    height: 2
    radius: 1
    color: Colors.color_cyan
  }
}
