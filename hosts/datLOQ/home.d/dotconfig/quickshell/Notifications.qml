import Quickshell
import Quickshell.Services.Notifications as Notifs
import QtQuick
import "."

PanelWindow {
  id: popup
  anchors { top: true; right: true }
  margins { right: 16; top: 16 }
  exclusiveZone: -1
  color: "transparent"
  implicitWidth: 360
  implicitHeight: column.implicitHeight + 24
  visible: repeater.count > 0

  Notifs.NotificationServer {
    id: server
    keepOnReload: false
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true

    onNotification: notification => {
      notification.tracked = true;
    }
  }

  Column {
    id: column
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 12
    spacing: 10

    Repeater {
      id: repeater
      model: server.trackedNotifications

      delegate: Rectangle {
        id: card
        required property var modelData
        readonly property var notif: modelData
        readonly property bool isCritical: notif.urgency === Notifs.NotificationUrgency.Critical

        width: parent.width
        height: layout.implicitHeight + 20
        color: Colors.colorbackground2
        radius: 4
        border.width: 1
        border.color: isCritical ? Colors.colorred : Colors.coloraccent

        Column {
          id: layout
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 10
          spacing: 4

          Text {
            width: parent.width
            text: card.notif.appName
            color: Colors.colormuted
            font.family: Colors.fontName
            font.pixelSize: 11
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: card.notif.summary
            color: Colors.colorforeground1
            font.family: Colors.fontName
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.Wrap
          }

          Text {
            width: parent.width
            visible: card.notif.body !== ""
            text: card.notif.body
            color: Colors.colorforeground2
            font.family: Colors.fontName
            font.pixelSize: 12
            wrapMode: Text.Wrap
          }

          // Action buttons (text style)
          Row {
            spacing: 10
            Repeater {
              model: card.notif.actions

              delegate: Text {
                id: actionBtn
                required property var modelData
                text: modelData.text
                color: Colors.colorbrightcyan
                font.family: Colors.fontName
                font.pixelSize: 12
                font.underline: true

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: actionBtn.modelData.invoke()
                }
              }
            }
          }
        }

        // Click anywhere on the card to dismiss
        MouseArea {
          anchors.fill: parent
          z: -1
          onClicked: card.notif.dismiss()
        }

        // Auto-expire: app-provided timeout, or a fallback; critical stays longer
        Timer {
          running: true
          interval: card.notif.expireTimeout > 0
            ? card.notif.expireTimeout
            : (card.isCritical ? 15000 : 5000)
          onTriggered: card.notif.expire()
        }
      }
    }
  }
}
