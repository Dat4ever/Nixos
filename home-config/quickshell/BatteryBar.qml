import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "."

RowLayout {
  spacing: 6
    
  property int capacity: 100

  Process {
    id: getBattery
    command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        capacity = parseInt(text.trim()) || 100
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: getBattery.running = true
  }

  Text {
    text: {
      if (capacity >= 80) return " "
      if (capacity >= 60) return " "
      if (capacity >= 40) return " "
      if (capacity >= 20) return " "
    return " "
    }
    color: capacity <= 20 ? Theme.red : Theme.yellow
      font { 
        family: Theme.font
        pixelSize: 16 
      }
    }

  Text {
    text: capacity + "%"
    color: capacity <= 20 ? Theme.red : Theme.yellow
    font { 
      family: Theme.font
      pixelSize: 14
      weight: 600 
    }
  }
}
