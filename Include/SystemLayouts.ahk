; AHK 1.1.27.07

; 
class SystemLayouts
{
  static SISO639LANGNAME := 0x0059 ; ISO abbreviated language name, eg "en"
  static WM_INPUTLANGCHANGEREQUEST := 0x0050
  static GW_OWNER := 4
  
  List := [ ]
  Dictionary := { }
  IgnoredProcesses := [ ]
  
  Current
  {
    get
    {
      hkl := this.GetCurrentHkl()
      if(hkl)
        return this.GetLayoutByHkl(hkl)
      else
        return { Hkl: 0 }
    }
  }
  
  SetByIndex(index)
  {
    layout := this.List[index]
    if(layout)
      this.SetCurrentHkl(layout.Hkl)
  }
  
  SetByLanguage(language)
  {
    for index, layout in this.List
      if(layout.Language == language)
      {
        this.SetCurrentHkl(layout.Hkl)
        break
      }
  }
  
  UpdateList()
  {
    this.List := [ ]
    
    size := DllCall("GetKeyboardLayoutList", "Int", 0, "Ptr", 0)
    VarSetCapacity(buffer, A_PtrSize * size)
    size := DllCall("GetKeyboardLayoutList", "Int", size, "Str", buffer)
    
    loop % size
    {
      hkl := NumGet(buffer, A_PtrSize * (A_Index - 1), "Ptr")
      this.List[A_Index] := this.GetLayoutByHkl(hkl)
    }
  }
  
  ; Constructor
  __New(ignoredProcesses)
  {
    this.IgnoredProcesses := ignoredProcesses
    this.UpdateList()
  }
  
  GetCurrentHkl()
  {
    WinGet activeWinProcess, ProcessName, A
    
    for i, ignoredProcess in this.IgnoredProcesses
      if(activeWinProcess == ignoredProcess)
        return 0
    
    activeWindow := WinExist("A")
    windowThread := DllCall("GetWindowThreadProcessId", "Ptr", activeWindow, "Ptr", 0)
    threadHkl := DllCall("GetKeyboardLayout", "Ptr", windowThread)
    return threadHkl
  }
  
  SetCurrentHkl(hkl)
  {
    activeWindow := WinExist("A")
    PostMessage this.WM_INPUTLANGCHANGEREQUEST, "", hkl, , % "ahk_id" activeWindow
  }
  
  GetLayoutByHkl(hkl)
  {
    layout := this.Dictionary[hkl]
    if(!layout)
    {
      lcid := hkl & 0xFFFF
      lcType := this.SISO639LANGNAME
      size := DllCall("GetLocaleInfo", "UInt", lcid, "UInt", lcType, "Ptr", 0, "UInt", 0)
      VarSetCapacity(buffer, 2 * size)
      DllCall("GetLocaleInfo", "UInt", lcid, "UInt", lcType, "Str", buffer, "UInt", size)
      
      layout := { Hkl: hkl, Language: buffer }
      this.Dictionary[hkl] := layout
    }
    return layout
  }
}
