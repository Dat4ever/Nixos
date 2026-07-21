import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
  id: powerWidget
  implicitWidth: textDisplay.implicitWidth + 20
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_red
  color: Colors.nord_dark_gray

  Process {
    id: confirmLogout
    command: [
      "sh", "-c", 
      "echo -e 'Yes\\nNo' | rofi -dmenu -i -p 'Logout?' -theme-str 'window { width: 15%; } listview { lines: 2; } entry { enabled: false; }'"
    ]
    running: false

    stdout: StdioCollector {
      onTextChanged: {
        var choice = text.trim();
        if (choice.indexOf("Yes") !== -1) {
          hyprExit.running = true;
        }
      }
    }
  }

  Process {
    id: hyprExit
    command: ["sh", "-c", "loginctl terminate-session $XDG_SESSION_ID"]
    running: false
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      confirmLogout.running = true;
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    text: "󰐥"
    color: Colors.nord_red
    font.family: Colors.fontName
    font.pixelSize: 14
    font.bold: true
  }
}
