import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: bluetoothRoot
  
  implicitWidth: 16
  implicitHeight: 16

  Process {
    id: bluetoothGuiProc
    command: ["blueman-manager"]
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    
    text: "󰂯"
    color: Theme.blue
    
    font.family: Theme.font
    font.pixelSize: 16
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    
    onClicked: {
      bluetoothGuiProc.running = true
    }
  }
}
