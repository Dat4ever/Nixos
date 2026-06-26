import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
  Variants {
    matrix: [ Quickshell.screens ]
  }

  WlrWindow {
    id: window
    anchors.top: true
    anchors.left: true
    anchors.right: true
    exclusionMode: WlrWindow.Exclusive
        
    Rectangle {
      color: "transparent" 
      implicitHeight: 26
      width: parent.width

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20

        RowLayout {
          spacing: 8
                    
          Repeater {
            model: 5
                        
            Rectangle {
              readonly property int wsId: index + 1
              readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId

              implicitWidth: isActive ? 16 : 6
              implicitHeight: 6
              radius: 3
                            
              color: isActive ? "#cdd6f4" : "#45475a"

              Behavior on implicitWidth {
                NumberAnimation { duration: 150 }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace", wsId.toString())
              }
            }
          }
        }

          Item { Layout.fillWidth: true }

          Text {
            id: clockText
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: "#a6e3a1"
            font.pixelSize: 11
            font.weight: Font.Medium
                    
            Timer {
              interval: 1000
              running: true
              repeat: true
              onTriggered: clockText.text = Qt.formatDateTime(new Date(), "hh:mm")
            }
          }
      }
    }
  }
}
