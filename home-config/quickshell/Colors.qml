pragma Singleton
import QtQuick

QtObject {
  readonly property color nord_black: "#2e3440"       
  readonly property color nord_dark_gray: "#3b4252"   
  readonly property color nord_gray: "#4c566a"        
  readonly property color nord_light_gray: "#d8dee9"  
  readonly property color nord_white: "#e5e9f0"       
  readonly property color nord_bright_white: "#eceff4"
  readonly property color nord_red: "#bf616a"         
  readonly property color nord_green: "#a3be8c"       
  readonly property color nord_yellow: "#ebcb8b"      
  readonly property color nord_blue: "#81a1c1"        
  readonly property color nord_cyan: "#88c0d0"        
  readonly property color nord_bright_cyan: "#8fbcbb" 
  readonly property color nord_magenta: "#b48ead"     
  readonly property color background: nord_black
  readonly property color foreground: nord_light_gray
  readonly property color selection_background: nord_cyan
  readonly property color active_tab_background: nord_blue
  readonly property color inactive_tab_background: nord_dark_gray

  readonly property string fontName: "JetBrainsMono Nerd Font"
}
