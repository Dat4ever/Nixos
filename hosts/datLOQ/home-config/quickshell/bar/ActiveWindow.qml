import QtQuick
import Quickshell.Io
import ".."

Item {
  id: activeWindowWidget
  implicitWidth: textDisplay.implicitWidth
  implicitHeight: 24

  property string windowClass: ""
  property string windowTitle: ""
  property string displayText: "Desktop"

  Process {
    id: readActiveWindow
    command: ["sh", "-c", "hyprctl activewindow -j"]
    running: false

    stdout: StdioCollector {
      onTextChanged: {
        var output = text.trim();
        if (output.length === 0 || output === "no active window found" || output.indexOf("Couldn't") !== -1) {
          activeWindowWidget.windowClass = "";
          activeWindowWidget.windowTitle = "";
          activeWindowWidget.displayText = "Desktop";
          return;
        }

        try {
          var data = JSON.parse(output);
          activeWindowWidget.windowClass = data.initialClass || data.class || "";
          activeWindowWidget.windowTitle = data.title || "";

          if (activeWindowWidget.windowClass.length > 0) {
            var cls = activeWindowWidget.windowClass;
            var icon = "";
            switch (cls.toLowerCase()) {
              case "kitty":           icon = ""; break;
              case "firefox":         icon = "󰈹"; break;
              case "steam":           icon = "󰓓"; break;
              case "mpv":             icon = "󰝚"; break;
              case "vlc":             icon = "󰕼"; break;
              case "rofi":            icon = "󰀻"; break;
              case "pokerogue":       icon = "󰐝"; break;
              case "osu!":            icon = ""; break;
              default:                icon = "󰓩"; break;
            }

            var rawTitle = activeWindowWidget.windowTitle;
            if (rawTitle.length > 38) {
              rawTitle = rawTitle.substring(0, 35) + "...";
            }
            activeWindowWidget.displayText = icon + " " + (rawTitle.length > 0 ? rawTitle : cls);
          } else {
            activeWindowWidget.displayText = "Desktop";
          }
        } catch (e) {
          activeWindowWidget.displayText = "Desktop";
        }
      }
    }
  }

  Timer {
    interval: 800
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!readActiveWindow.running) {
        readActiveWindow.running = true;
      }
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    text: activeWindowWidget.displayText
    color: Colors.nord_cyan
    font.family: Colors.fontName
    font.pixelSize: 13
    font.bold: true

    Behavior on text {
      SequentialAnimation {
        NumberAnimation { target: textDisplay; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InOutQuad }
        PropertyAction { target: textDisplay; property: "text" }
        NumberAnimation { target: textDisplay; property: "opacity"; to: 1; duration: 120; easing.type: Easing.InOutQuad }
      }
    }
  }
}
