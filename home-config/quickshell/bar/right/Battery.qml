import QtQuick
import Quickshell.Io
import "../.." 

Item {
  anchors.fill: parent

  property string batteryPercent: "100"
  property string batteryStatus: "Discharging"

  Process {
    id: readCapacity
    command: ["cat", "/sys/class/power_supply/BAT1/capacity"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        var cleanData = data.toString().replace(/[\r\n\s]+/g, "");
        if (cleanData.length > 0) {
          batteryPercent = cleanData;
        }
      }
    }
    onRunningChanged: if (!running) running = true
  }

  Process {
    id: readStatus
    command: ["cat", "/sys/class/power_supply/BAT1/status"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        var cleanData = data.toString().replace(/[\r\n\s]+/g, "");
        if (cleanData.length > 0) {
          batteryStatus = cleanData;
        }
      }
    }
    onRunningChanged: if (!running) running = true
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: {
      readCapacity.running = false
      readStatus.running = false
    }
  }

  Text {
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
