pragma Singleton
import QtQuick

QtObject {
  readonly property color color_black: "#2e3440"       
  readonly property color color_dark_gray: "#3b4252"   
  readonly property color color_gray: "#4c566a"        
  readonly property color color_light_gray: "#d8dee9"  
  readonly property color color_white: "#e5e9f0"       
  readonly property color color_bright_white: "#eceff4"
  readonly property color color_red: "#bf616a"         
  readonly property color color_green: "#a3be8c"       
  readonly property color color_yellow: "#ebcb8b"      
  readonly property color color_blue: "#81a1c1"        
  readonly property color color_cyan: "#88c0d0"        
  readonly property color color_bright_cyan: "#8fbcbb" 
  readonly property color color_magenta: "#b48ead"     
  readonly property color background: color_dark_gray
  readonly property color foreground: color_light_gray
  readonly property color selection_background: color_cyan
  readonly property color active_tab_background: color_blue
  readonly property color inactive_tab_background: color_dark_gray

  readonly property string fontName: "CommitMono Nerd Font Propo"
}
