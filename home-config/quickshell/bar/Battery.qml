import QtQuick
import Quickshell.Io
import ".."

Rectangle {
  id: batteryWidget
  implicitWidth: textDisplay.implicitWidth + 16
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_yellow
  color: Colors.nord_dark_gray

  property string batteryPercent: "100"
  property string batteryStatus: "Discharging"

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

  Text {
    id: textDisplay
    anchors.centerIn: parent
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    color: Colors.nord_yellow

    text: {
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
