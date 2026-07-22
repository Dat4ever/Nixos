import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
  id: bluetoothWidget
  implicitWidth: textDisplay.implicitWidth + 20
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_blue
  color: Colors.nord_dark_gray

  property string btStatus: "Checking..."
  property string btIcon: "󰂯"
  property bool isPowered: false

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!btCheck.running) {
        btCheck.running = true
      }
    }
  }

  Process {
    id: btCheck
    command: ["bluetoothctl", "show"]
    running: false

    stdout: StdioCollector {
      onTextChanged: {
        var output = text.trim();
        if (output.indexOf("Powered: yes") !== -1) {
          bluetoothWidget.isPowered = true;
          btConnectedCheck.running = true;
        } else {
          bluetoothWidget.isPowered = false;
          bluetoothWidget.btStatus = "Off";
          bluetoothWidget.btIcon = "󰂲";
        }
      }
    }
  }

  Process {
    id: btConnectedCheck
    command: ["bluetoothctl", "info"]
    running: false

    stdout: StdioCollector {
      onTextChanged: {
        var output = text.trim();
        if (output.indexOf("Missing device address") === -1 && output.length > 0) {
          bluetoothWidget.btStatus = "Connected";
          bluetoothWidget.btIcon = "󰂱";
        } else {
          bluetoothWidget.btStatus = "On";
          bluetoothWidget.btIcon = "󰂯";
        }
      }
    }
  }

  Process {
    id: launchBt
    command: ["kitty", "-e", "bluetui"]
    running: false
  }

  Process {
    id: toggleBt
    running: false
  }

  function togglePower() {
    if (toggleBt.running) return;
    var nextState = bluetoothWidget.isPowered ? "off" : "on";
    toggleBt.command = ["bluetoothctl", "power", nextState];
    toggleBt.running = true;
    btCheck.running = true;
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        launchBt.running = true;
      } else if (mouse.button === Qt.RightButton) {
        bluetoothWidget.togglePower();
      }
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    text: bluetoothWidget.btIcon + " " + bluetoothWidget.btStatus
    color: Colors.nord_blue
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
  }
}
