import QtQuick
import Quickshell.Hyprland
import "."
import ".."

Rectangle {
  id: workspaceWidget
  
  implicitWidth: internalRow.implicitWidth + 16 
  implicitHeight: 24
  radius: 12
  color: Colors.nord_dark_gray
  border.width: 2
  border.color: Colors.nord_cyan

  Row {
    id: internalRow
    anchors.centerIn: parent 
    spacing: 8

    Repeater {
      model: 5 

      Rectangle {
        id: wsDot
        readonly property int wsId: index + 1
        readonly property var wsData: Hyprland.workspaces.values.find(ws => ws.id === wsId)
        readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId

        width: isActive ? 22 : 8
        height: 8
        radius: 4 

        color: {
          if (isActive) return Colors.nord_cyan;
          if (wsData) return Colors.nord_white;
          return Colors.nord_gray;
        }

        Behavior on width {
          NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
        Behavior on color {
          ColorAnimation { duration: 150 }
        }

        MouseArea {
          anchors.fill: parent
          z: 1
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (wsDot.wsData) {
              wsDot.wsData.activate();
            } else {
              Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })");
            }
          }
        }
      }
    }
  }
}
