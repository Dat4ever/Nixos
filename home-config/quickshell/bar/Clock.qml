import QtQuick
import ".."

Rectangle {
  id: clockWidget

  width: implicitWidth
  height: implicitHeight
  radius: 12
  border.width: 2
  border.color: Colors.nord_blue
  color: Colors.nord_dark_gray

  state: "time"
  Behavior on implicitWidth {
    NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
  }

  Text {
    id: timeText
    anchors.centerIn: parent
    color: Colors.nord_blue
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    visible: clockWidget.state === "time"
    text: Qt.formatDateTime(new Date(), "HH:mm")

    Timer {
      interval: 1000
      running: clockWidget.state === "time"
      repeat: true
      onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
    }
  }

  Text {
    id: dateText
    anchors.centerIn: parent
    color: Colors.nord_blue
    font.family: Colors.fontName
    font.pixelSize: 12
    font.bold: true
    visible: clockWidget.state === "date"
    text: Qt.formatDateTime(new Date(), "dd MMM")
  }

  Timer {
    id: autoReturnTimer
    interval: 4000
    running: false
    repeat: false
    onTriggered: clockWidget.state = "time"
  }

  states: [
    State {
      name: "time"
      PropertyChanges { target: clockWidget; implicitWidth: timeText.implicitWidth + 16 }
      PropertyChanges { target: clockWidget; implicitHeight: 24 }
    },
    State {
      name: "date"
      PropertyChanges { target: clockWidget; implicitWidth: dateText.implicitWidth + 16 }
      PropertyChanges { target: clockWidget; implicitHeight: 24 }
    }
  ]

  MouseArea {
    anchors.fill: parent
    z: 99
    cursorShape: Qt.PointingHandCursor
    
    onClicked: {
      if (clockWidget.state === "time") {
        dateText.text = Qt.formatDateTime(new Date(), "dd MMM")
        clockWidget.state = "date"
        autoReturnTimer.restart()
      } else {
        clockWidget.state = "time"
        autoReturnTimer.stop()
      }
    }
  }
}
