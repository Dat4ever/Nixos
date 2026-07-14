import QtQuick
import Quickshell.Hyprland
import "."
import ".."

Item {
  anchors.fill: parent

  Row {
    anchors.centerIn: parent
    spacing: 8

    Repeater {
      model: 5 

      Rectangle {
        readonly property int wsId: index + 1
        readonly property var wsData: Hyprland.workspaces.values.find(ws => ws.id === wsId)
        readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId

        implicitWidth: isActive ? 22 : 8
        implicitHeight: 8
        radius: 4 

        color: {
          if (isActive) return Colors.nord_cyan;
          if (wsData) return Colors.nord_white;
          return Colors.nord_gray;
        }

        Behavior on implicitWidth {
          NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
        Behavior on color {
          ColorAnimation { duration: 150 }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
          }
        }
      }
    }
  }
}
