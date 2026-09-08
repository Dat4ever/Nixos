import Quickshell
import "."
import "./bar"

ShellRoot {
  Notifications { }   // System-wide notification daemon (themed popup, bottom-right)
  Base { }  // Status bar (window + layout: bar/Base.qml, widgets: bar/)
}
