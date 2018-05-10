; AHK 1.1.27.07


; Defines keyboard key sets
class KeySets
{
  ; Returns the list of all non-modifier keys and mouse buttons
  GetNonModifierKeys()
  {
    keys := [ ]
    for keyName, _ in this.SpecialKeys
      keys.Push(this.GetScanCodeByLayoutName(keyName))
    for keyName, scancode in this.CharacterKeys
      keys.Push(scancode)
    for keyName, _ in this.MouseButtons
      keys.Push(keyName)
    return keys
  }
  
  ; Returns the scancode of a key by its layout-independent name,
  ;   leaves mouse buttons and mouse wheel as is
  GetScanCodeByName(keyName)
  {
    if(keyName != "")
    {
      if(this.MouseButtons[keyName] || this.MouseWheel[keyName])
        return keyName
      else
      {
        scancode := this.CharacterKeys[keyName]
        return scancode
          ? scancode
          : this.GetScanCodeByLayoutName(keyName)
      }
    }
    else
      return ""
  }
  
  
  ; Returns the scancode of a key by its layout-dependent name
  GetScanCodeByLayoutName(keyName)
  {
    return Format("sc{:03X}", GetKeySC(keyName))
  }
  
  
  ; Layout-independent scancodes of character keys
  static CharacterKeys
    := {"``": "sc029"
       , "1": "sc002"
       , "2": "sc003"
       , "3": "sc004"
       , "4": "sc005"
       , "5": "sc006"
       , "6": "sc007"
       , "7": "sc008"
       , "8": "sc009"
       , "9": "sc00A"
       , "0": "sc00B"
       , "-": "sc00C"
       , "=": "sc00D"
       
       , "Q": "sc010"
       , "W": "sc011"
       , "E": "sc012"
       , "R": "sc013"
       , "T": "sc014"
       , "Y": "sc015"
       , "U": "sc016"
       , "I": "sc017"
       , "O": "sc018"
       , "P": "sc019"
       , "[": "sc01A"
       , "]": "sc01B"
       , "\": "sc02B"
       
       , "A": "sc01E"
       , "S": "sc01F"
       , "D": "sc020"
       , "F": "sc021"
       , "G": "sc022"
       , "H": "sc023"
       , "J": "sc024"
       , "K": "sc025"
       , "L": "sc026"
       , ";": "sc027"
       , "'": "sc028"
       
       , "Z": "sc02C"
       , "X": "sc02D"
       , "C": "sc02E"
       , "V": "sc02F"
       , "B": "sc030"
       , "N": "sc031"
       , "M": "sc032"
       , ",": "sc033"
       , ".": "sc034"
       , "/": "sc035" }
  
  ; NumLock on/off correspondence
  static NumLockVariants
    := { "NumpadDot": "NumpadDel"
       , "Numpad0": "NumpadIns"
       , "Numpad1": "NumpadEnd"
       , "Numpad2": "NumpadDown"
       , "Numpad3": "NumpadPgDn"
       , "Numpad4": "NumpadLeft"
       , "Numpad5": "NumpadClear"
       , "Numpad6": "NumpadRight"
       , "Numpad7": "NumpadHome"
       , "Numpad8": "NumpadUp"
       , "Numpad9": "NumpadPgUp" }
  
  ; The set of modifier keys
  static ModifierKeys
    := { "LShift": true
       , "RShift": true
       , "LCtrl": true
       , "RCtrl": true
       , "LAlt": true
       , "RAlt": true
       , "LWin": true
       , "RWin": true }
  
  ; The set of non-character non-modifier keys
  static SpecialKeys
    := { "ScrollLock": true
       , "CapsLock": true
       , "NumLock": true
       
       , "Space": true
       , "Tab": true
       , "Enter": true
       , "NumpadEnter": true
       , "Escape": true
       , "Backspace": true
       
       , "Delete": true
       , "Insert": true
       , "Home": true
       , "End": true
       , "PgUp": true
       , "PgDn": true
       , "Up": true
       , "Down": true
       , "Left": true
       , "Right": true
       
       , "F1": true
       , "F2": true
       , "F3": true
       , "F4": true
       , "F5": true
       , "F6": true
       , "F7": true
       , "F8": true
       , "F9": true
       , "F10": true
       , "F11": true
       , "F12": true
       
       , "AppsKey": true
       , "PrintScreen": true
       , "Pause": true
       
       , "Help": true
       , "Sleep": true
       
       , "Browser_Back": true
       , "Browser_Forward": true
       , "Browser_Refresh": true
       , "Browser_Stop": true
       , "Browser_Search": true
       , "Browser_Favorites": true
       , "Browser_Home": true
       , "Volume_Mute": true
       , "Volume_Down": true
       , "Volume_Up": true
       , "Media_Next": true
       , "Media_Prev": true
       , "Media_Stop": true
       , "Media_Play_Pause": true
       , "Launch_Mail": true
       , "Launch_Media": true
       , "Launch_App1": true
       , "Launch_App2": true }
  
  ; The set of mouse buttons
  static MouseButtons
    := { "LButton": true
       , "RButton": true
       , "MButton": true
       , "XButton1": true
       , "XButton2": true }
  
  ; The set of mouse wheel directions
  static MouseWheel
    := { "WheelUp": true
       , "WheelDown": true
       , "WheelLeft": true
       , "WheelRight": true }
}
