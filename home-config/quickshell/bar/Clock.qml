import QtQuick
import "."
import ".." 

Item {
  anchors.fill: parent

  property bool showDate: false

  Text {
    id: clockText
    anchors.centerIn: parent
    color: Colors.nord_blue
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    text: showDate ? Qt.formatDateTime(new Date(), "dd MMM") : Qt.formatDateTime(new Date(), "HH:mm")
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      if (!showDate) {
        clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
      }
    }
  }

  Timer {
    id: returnToClockTimer
    interval: 4000
    running: false
    repeat: false
    onTriggered: {
      showDate = false
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      showDate = !showDate
      
      if (showDate) {
        clockText.text = Qt.formatDateTime(new Date(), "dd MMM")
        returnToClockTimer.restart()
      } else {
        returnToClockTimer.stop()
      }
    }
  }
}
