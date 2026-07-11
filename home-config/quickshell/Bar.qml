import Quickshell
import Quickshell.Wayland
import QtQuick
import "./left"
import "./center"
import "./right"

Item {
  id: barRoot

  Component {
    id: islandTemplate

    PanelWindow {
      id: win
      exclusionMode: ExclusionMode.None
      color: "transparent"
      implicitHeight: 24

      default property alias content: rect.data
      property alias islandWidth: win.implicitWidth
      property alias islandMargins: win.margins

      Rectangle {
        id: rect
        anchors.fill: parent
        color: Colors.background
        radius: 8
        border.color: Colors.nord_dark_gray
        border.width: 1
      }
    }
  }

  Loader {
    id: leftLoader
    sourceComponent: islandTemplate
    onLoaded: {
      item.anchors.top = true
      item.anchors.left = true
      item.islandMargins.top = 8
      item.islandMargins.left = 8
      item.islandWidth = 110
      
      var component = Qt.createComponent("left/Workspace.qml")
      if (component.status === Component.Ready) {
        component.createObject(item)
      }
    }
  }

  Loader {
    id: centerLoader
    sourceComponent: islandTemplate
    onLoaded: {
      item.anchors.top = true
      item.anchors.left = true
      item.islandMargins.top = 8
      
      var calcLeft = screen ? ((screen.width - 90) / 2) : 0
      item.islandMargins.left = calcLeft
      item.islandWidth = 90

      var component = Qt.createComponent("center/Clock.qml")
      if (component.status === Component.Ready) {
        component.createObject(item)
      }
    }
  }

  Loader {
    id: rightLoader
    sourceComponent: islandTemplate
    onLoaded: {
      item.anchors.top = true
      item.anchors.right = true
      item.islandMargins.top = 8
      item.islandMargins.right = 8
      item.islandWidth = 90

      var component = Qt.createComponent("right/Status.qml")
      if (component.status === Component.Ready) {
        component.createObject(item)
      }
    }
  }
}
