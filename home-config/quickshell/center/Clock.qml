import Quickshell
import Quickshell.Wayland
import QtQuick
import "." 

PanelWindow {
  id: clockWindow
  exclusive: false // Çakışmaları ve aşağı kaymayı engeller

  anchors {
    top: true
    left: true // Matematiksel konumlandırma için sola yaslıyoruz
  }

  // Ekranın tam ortasını bulup, kutunun yarısını çıkararak kusursuz merkezleme yapar
  // Quickshell'in bağlı olduğu aktif monitörün genişliğini otomatik çeker
  property int calculatedLeft: screen ? ((screen.width - 90) / 2) : 0

  margins {
    top: 8
    left: clockWindow.calculatedLeft
  }

  implicitWidth: 90  
  implicitHeight: 24
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    radius: 8
    border.color: Colors.nord_dark_gray
    border.width: 1

    Text {
      id: clockText
      anchors.centerIn: parent
      color: Colors.nord_white
      font.family: Colors.fontName
      font.pixelSize: 11
      font.bold: true

      Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
      }
    }
  }
}
