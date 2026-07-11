import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Hyprland
import "." 

PanelWindow {
  exclusive: false
  
  anchors {
    top: true
    left: true
  }

  margins {
    top: 8
    left: 8
  }

  implicitWidth: 110 
  implicitHeight: 24
  color: "transparent" 

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    radius: 8
    border.color: Colors.nord_dark_gray
    border.width: 1

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
            if (isActive) return Colors.nord_blue;       
            if (wsData) return Colors.nord_light_gray;   
            return Colors.nord_dark_gray;               
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
}
