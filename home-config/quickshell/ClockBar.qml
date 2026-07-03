import QtQuick
import Quickshell
import "."

Text {
  text: Qt.formatDateTime(clock.date, "hh:mm")
  color: Theme.foreground

  font {
    family: Theme.font
    pixelSize: 16
    weight: 600
    letterSpacing: -1
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
