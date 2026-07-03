import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "."

RowLayout {
  id: languageWidget
  spacing: 6

  property string currentLayout: "us"

  Text {
    text: " "
    color: Theme.green
    font {
      family: Theme.font
      pixelSize: 16
    }
  }

  Text {
    text: languageWidget.currentLayout
    color: Theme.green
    font {
      family: Theme.font
      pixelSize: 14
      weight: 600
    }
  }

  Process {
    id: keyboardProcess
    command: [
      "sh",
      "-c",
      "hyprctl devices -j | jq -r '.keyboards[] | select(.main==true) | .active_keymap'"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        let txt = text.trim().toLowerCase()
        if (txt.includes("english"))
          languageWidget.currentLayout = "us"
        else if (txt.includes("turkish"))
          languageWidget.currentLayout = "trq"
        else
          languageWidget.currentLayout = txt
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: keyboardProcess.running = true
  }
}
