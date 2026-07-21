import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
  id: batteryWidget
  implicitWidth: textDisplay.implicitWidth + 20
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_yellow
  color: Colors.nord_dark_gray

  property string batteryPercent: "100"
  property string batteryStatus: "Discharging"

  property bool showBrightness: false
  property string brightnessPercent: "100"

  Process {
    id: readCapacity
    command: ["cat", "/sys/class/power_supply/BAT1/capacity"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        var cleanData = data.toString().replace(/[\r\n\s]+/g, "");
        if (cleanData.length > 0) batteryPercent = cleanData;
      }
    }
  }

  Process {
    id: readStatus
    command: ["cat", "/sys/class/power_supply/BAT1/status"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        var cleanData = data.toString().replace(/[\r\n\s]+/g, "");
        if (cleanData.length > 0) batteryStatus = cleanData;
      }
    }
  }

  Process {
    id: readBrightness
    command: ["sh", "-c", "echo $(($(brightnessctl g) * 100 / $(brightnessctl m)))"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        var cleanData = data.toString().replace(/[\r\n\s]+/g, "");
        if (cleanData.length > 0) brightnessPercent = cleanData;
      }
    }
  }

  Process {
    id: brightnessControl
    running: false
  }

  function changeBrightness(step) {
    if (brightnessControl.running) return;
    brightnessControl.command = ["brightnessctl", "set", step];
    brightnessControl.running = true;
    
    readBrightness.running = true;
  }

  Timer {
    id: brightnessDisplayTimer
    interval: 2000
    repeat: false
    onTriggered: {
      batteryWidget.showBrightness = false
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      readCapacity.running = true
      readStatus.running = true
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      readBrightness.running = true;
      batteryWidget.showBrightness = true;
      brightnessDisplayTimer.restart();
    }
    
    onWheel: wheel => {
      if (wheel.angleDelta.y > 0) {
        batteryWidget.changeBrightness("+5%");
      } else if (wheel.angleDelta.y < 0) {
        batteryWidget.changeBrightness("5%-");
      }
      batteryWidget.showBrightness = true;
      brightnessDisplayTimer.restart();
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    color: Colors.nord_yellow

    text: {
      if (batteryWidget.showBrightness) {
        return "󰃠 " + batteryWidget.brightnessPercent + "%";
      }

      var icon = " ";
      var pct = parseInt(batteryPercent) || 0;
      if (pct <= 20) icon = " ";
      else if (pct <= 40) icon = " ";
      else if (pct <= 60) icon = " ";
      else if (pct <= 80) icon = " ";
      var isPlugged = (batteryStatus !== "Discharging");
      var chargingState = isPlugged ? " 󱐋" : "";
      return icon + " " + batteryPercent + "%" + chargingState;
    }
  }
}
