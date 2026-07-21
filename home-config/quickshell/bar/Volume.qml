import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
  id: volumeWidget
  implicitWidth: textDisplay.implicitWidth + 20
  implicitHeight: 24
  radius: 12
  border.width: 2
  border.color: Colors.nord_green
  color: Colors.nord_dark_gray

  property int volLevel: 0
  property bool isMuted: false

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!volCheck.running) {
        volCheck.running = true
      }
    }
  }

  Process {
    id: volCheck
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false

    stdout: StdioCollector {
      onTextChanged: {
        var output = text.trim();
        var muted = output.indexOf("[MUTED]") !== -1;
        var match = output.match(/Volume:\s+([0-9.]+)/);

        volumeWidget.isMuted = muted;
        if (match && match[1]) {
          volumeWidget.volLevel = Math.round(parseFloat(match[1]) * 100);
        }
      }
    }
  }

  Process {
    id: volControl
    running: false
  }

  function changeVolume(step) {
    if (volControl.running) return;
    volControl.command = ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", step];
    volControl.running = true;
    volCheck.running = true;
  }

  function toggleMute() {
    if (volControl.running) return;
    volControl.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
    volControl.running = true;
    volCheck.running = true;
  }

  Process {
    id: launchMixer
    command: ["pavucontrol"]
    running: false
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        volumeWidget.toggleMute();
      } else if (mouse.button === Qt.RightButton) {
        launchMixer.running = true;
      }
    }

    onWheel: wheel => {
      if (wheel.angleDelta.y > 0) {
        volumeWidget.changeVolume("5%+");
      } else if (wheel.angleDelta.y < 0) {
        volumeWidget.changeVolume("5%-");
      }
    }
  }

  Text {
    id: textDisplay
    anchors.centerIn: parent
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    color: Colors.nord_green

    text: {
      if (volumeWidget.isMuted) {
        return "󰝟  Muted";
      }

      var icon = "󰕿";
      if (volumeWidget.volLevel > 66) {
        icon = "󰕾";
      } else if (volumeWidget.volLevel > 33) {
        icon = "󰖀";
      }

      return icon + " " + volumeWidget.volLevel + "%";
    }
  }
}
