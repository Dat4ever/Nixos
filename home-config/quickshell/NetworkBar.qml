import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Io

Item {
  id: networkRoot
  
  implicitWidth: 16
  implicitHeight: 16

  Process {
    id: networkGuiProc
    command: ["kitty", "-e", "nmtui"]
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    
    text: (Networking.connected || Networking.connectivity === Networking.Full) ? "󰛳 " : "󰅛 "
    color: Theme.blue
    
    font.family: Theme.font
    font.pixelSize: 16
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    
    onClicked: {
      networkGuiProc.startDetached()
    }
  }
}
