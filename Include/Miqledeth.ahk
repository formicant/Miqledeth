; AHK 1.1.27.07

#InstallKeybdHook

#Include Include\MiqParser.ahk
#Include Include\LayoutData.ahk
#Include Include\LayoutList.ahk
#Include Include\KeyBuffer.ahk


class Miqledeth
{
  ; Invariable properties
  
  ; Instance parameters
  Parameters := { }
  
  ; Layout data
  LayoutData := { }
  LayoutList := { }
  
  ; Current script state
  KeyBuffer := new KeyBuffer
  ModifierState := { }
  ModifierString := ""
  ModifierPressing := ""
  CurrentLayoutName := ""
  CurrentLanguage := ""
  
  
  
  ; Constructor
  __New(parameters)
  {
    this.Parameters := parameters
  }
  
  ; Starts the input processing
  Start()
  {
    StringCaseSense On
    SendMode Input
    FileEncoding UTF-8
    
    iconPath := this.Parameters.LayoutIcons.Path
    if(iconPath)
      Menu Tray, Icon, % iconPath
    
    this.SetLockState(this.Parameters.LockState)
    
    layoutDescriptionFiles
      := this.LoadLayoutDescriptionFiles(this.Parameters.LayoutFolder)
    this.LayoutData := new LayoutData(layoutDescriptionFiles)
    
    this.ModifierState := this.LayoutData.CustomModifiers.Clone()
    this.ModifierState[this.CombiningModifier] := true
    
    this.CreateHotkeys()
    
    this.LayoutList := new LayoutList(this.Parameters.LayoutIcons, this.LayoutData.Layouts)
  }

  
  LoadLayoutDescriptionFiles(layoutFolder)
  {
    result := MiqParser.ParseFolder(layoutFolder)
    if(!result.Success)
    {
      MsgBox % result.Error.Message
      ExitApp -1
    }
    return result.Value
  }
  
  SetLockState(lockState)
  {
    SetScrollLockState % lockState.Scroll
    SetCapsLockState % lockState.Caps
    SetNumLockState % lockState.Num
  }

  
  ; Creating hotkeys
  
  CreateHotkeys()
  {
    this.CreateDefaultTransparentHotkeys()
    
    onHotkeyPreviewFunc := Func("Miqledeth.OnHotkeyPreview")
    onHotkeyFunc := Func("Miqledeth.OnHotkey")
    onMouseWheelFunc := Func("Miqledeth.OnMouseWheel")
    
    for hotkeyName, item in this.LayoutData.Hotkeys
      if(item.Variants)
      {
        onHotkeyPreview := onHotkeyPreviewFunc.Bind(this, item)
        onHotkey := item.IsMouseWheel
          ? onMouseWheelFunc.Bind(this, item)
          : onHotkeyFunc.Bind(this, item)
        
        if(item.IsTransparent)
          Hotkey If
        else
          Hotkey If, %onHotkeyPreview%
        
        Hotkey %hotkeyName%, %onHotkey%
      }
    Hotkey If
  }
  
  CreateDefaultTransparentHotkeys()
  {
    onDefaultTransparentHotkey
      := Func("Miqledeth.OnDefaultTransparentHotkey").Bind(this)
    
    Hotkey If
    for index, keyName in KeySets.GetNonModifierKeys()
    {
      hotkeyName := "~*" keyName
      if(!this.LayoutData.Hotkeys[hotkeyName])
        Hotkey %hotkeyName%, %onDefaultTransparentHotkey%
    }
  }
  
  
  ; Hotkey handlers
  
  OnDefaultTransparentHotkey()
  {
    this.ClearCommand(true)
  }
  
  OnHotkeyPreview(item)
  {
    return item.Variants[this.LayoutList.CurrentLayoutName . this.ModifierString]
      || item.Variants[this.LayoutList.CurrentLayoutName . this.LayoutData.AnyModifierString]
  }
  
  OnHotkey(item)
  {
    key := { Time: A_TickCount
      , LayoutName: this.LayoutList.CurrentLayoutName
      , ModifierString: this.ModifierString
      , Item: item }

    this.SimulateKey(key, true)
  }
  
  ; TODO: generalize
  OnMouseWheel(item)
  {
    if(this.ModifierPressing.IsVirgin)
      this.OnHotkey(item)
  }
  
  
  ; Processing and simulating keystrokes
  
  SimulateKeys(keys)
  {
    for index, key in keys
      this.SimulateKey(key, false)
  }
  
  SimulateKey(key, isReal)
  {
    action := key.Item.Variants[key.LayoutName . key.ModifierString]
    if(!action)
      action := key.Item.Variants[key.LayoutName . this.LayoutData.AnyModifierString]
    if(!isReal && !action)
    {
      action := key.Action
      if(!action)
        action := key.Item.Alternates[key.LayoutName . key.ModifierString]
      if(!action)
        action := key.Item.Alternates[key.LayoutName . this.LayoutData.AnyModifierString]
    }
    
    if(action)
    {
      command := this.Commands[action.Command]
      if(command.Register)
        this.RegisterKey(key)
      
      command.Func.Call(this, isReal, action.Arguments*)
    }
    else
      this.ClearCommand(true)
  }
  
  RegisterKey(key)
  {
    if(this.ModifierPressing)
      this.ModifierPressing.IsVirgin := false
      
    this.KeyBuffer.AddKey(key)
  }
  
  
  ; Command handlers
  
  NothingCommand(isReal)
  {
  }
  
  TextCommand(isReal, text)
  {
    this.KeyBuffer.AddText(text)
    if(isReal)
      this.SendText(text)
  }
  
  PassTextCommand(isReal, text)
  {
    this.KeyBuffer.AddText(text)
  }
  
  BackCommand(isReal, count)
  {
    this.KeyBuffer.AddBack(count)
    if(isReal)
      this.SendBack(count)
  }
  
  PassBackCommand(isReal, count)
  {
    this.KeyBuffer.AddBack(count)
  }
  
  SendCommand(isReal, keys)
  {
    this.SendKeys(keys)
    this.KeyBuffer.Clear()
  }
  
  ClearCommand(isReal)
  {
    this.KeyBuffer.Clear()
  }
  
  SubstituteCommand(isReal, initiator, layoutName := "")
  {
    substitutions := this.LayoutData.Substitutions[initiator]
    if(!this.LayoutList.CombiningMode && substitutions[0])
      substitutions := { 0: substitutions[0] }
    
    keys := this.KeyBuffer.Substitute(layoutName, substitutions)
    if(isReal)
      this.SimulateKeys(keys)
  }
  
  ModifierCommand(isReal, modifier)
  {
    this.ModifierOnCommand(isReal, modifier)
    
    if(!this.ModifierPressing)
      this.ModifierPressing := { IsVirgin: true
        , BuiltInModifiers: this.GetCurrentBuiltInModifiers() }
  }
  
  ModifierUpCommand(isReal, modifier)
  {
    if(this.ModifierPressing.IsVirgin)
    {
      item := this.LayoutData.VirginKeys[this.ModifierPressing.BuiltInModifiers]
      key := { Time: A_TickCount
        , LayoutName: this.LayoutList.CurrentLayoutName
        , ModifierString: this.ModifierString
        , Item: item }
      
      this.SimulateKey(key, true)
    }
    
    this.ModifierPressing := ""
    this.ModifierOffCommand(isReal, modifier)
  }
  
  ModifierOnCommand(isReal, modifier)
  {
    this.ModifierState[modifier] := true
    this.UpdateModifierString()
  }
  
  ModifierOffCommand(isReal, modifier)
  {
    this.ModifierState[modifier] := false
    this.UpdateModifierString()
  }
  
  ModifierToggleCommand(isReal, modifier)
  {
    this.ModifierState[modifier] := !this.ModifierState[modifier]
    this.UpdateModifierString()
  }
  
  SwitchLayoutCommand(isReal, layoutTerm)
  {
    this.LayoutList.SetCurrentLayout(layoutTerm)
    this.KeyBuffer.Clear()
  }
  
  RetypePhraseCommand(isReal, layoutTerm)
  {
    this.LayoutList.SetCurrentLayout(layoutTerm)
    keys := this.KeyBuffer.RetypePhrase(this.LayoutList.CurrentLayoutName)
    this.SimulateKeys(keys)
  }
  
  RetypeCharCommand(isReal, layoutTerm)
  {
    currentLayoutName := this.LayoutList.CurrentLayoutName
    this.LayoutList.SetCurrentLayout(layoutTerm)
    keys := this.KeyBuffer.RetypeChar(this.LayoutList.CurrentLayoutName)
    this.SimulateKeys(keys)
    this.LayoutList.SetCurrentLayout(currentLayoutName)
  }
  
  CorrectCommand(isReal, backCount, text)
  {
    this.SendBack(backCount)
    this.SendText(text)
  }
  
  CallbackCommand(isReal, callback)
  {
    keys := callback.Call()
    this.SimulateKeys(keys)
  }
    
  TimeCommand(isReal, format, utc := "")
  {
    now := utc = "UTC" ? A_NowUTC : A_Now
    FormatTime text, % now, % format
    this.TextCommand(isReal, text)
  }

  
  SendText(text)
  {
    if(text != "")
      Send % "{Blind}{Text}" text
  }
  
  SendBack(count)
  {
    Loop % count
      Send {BackSpace}
  }
  
  SendKeys(keys)
  {
    term := RegexReplace(RegexReplace(keys, "\[", "{"), "\]", "}")
    Send % term
  }
  
  
  ; Modifiers
  
  UpdateModifierString()
  {
    modifierString := ""
    for modifierName, state in this.ModifierState
      if(state && modifierName != this.CombiningModifier)
        modifierString .= " " modifierName
    this.ModifierString := modifierString
    this.LayoutList.SetCombiningMode(this.ModifierState[this.CombiningModifier])
  }
  
  GetCurrentBuiltInModifiers()
  {
    builtInModifiers := ""
    for modifierName, modifierSymbol in this.LayoutData.BuiltInModifiers
      if(GetKeyState(modifierName))
        builtInModifiers .= modifierSymbol
    return builtInModifiers
  }
  
  
  ; Constants used internally
  
  static CombiningModifier := "combining"
  
  static Commands
    := { "":            { Func: Func("Miqledeth.NothingCommand"),       Register: true  }
       , "text":        { Func: Func("Miqledeth.TextCommand"),          Register: true  }
       , "passText":    { Func: Func("Miqledeth.PassTextCommand"),      Register: true  }
       , "back":        { Func: Func("Miqledeth.BackCommand"),          Register: true  }
       , "passBack":    { Func: Func("Miqledeth.PassBackCommand"),      Register: true  }
       , "send":        { Func: Func("Miqledeth.SendCommand"),          Register: true  }
       , "clear":       { Func: Func("Miqledeth.ClearCommand"),         Register: false }
       , "sub":         { Func: Func("Miqledeth.SubstituteCommand"),    Register: true  }
       , "modifier":    { Func: Func("Miqledeth.ModifierCommand"),      Register: false }
       , "modifierUp":  { Func: Func("Miqledeth.ModifierUpCommand"),    Register: false }
       , "on":          { Func: Func("Miqledeth.ModifierOnCommand"),    Register: true  }
       , "off":         { Func: Func("Miqledeth.ModifierOffCommand"),   Register: true  }
       , "toggle":      { Func: Func("Miqledeth.ModifierToggleCommand"),Register: true  }
       , "switchLayout":{ Func: Func("Miqledeth.SwitchLayoutCommand"),  Register: true  }
       , "retypePhrase":{ Func: Func("Miqledeth.RetypePhraseCommand"),  Register: false }
       , "retypeChar":  { Func: Func("Miqledeth.RetypeCharCommand"),    Register: false }
       , "correct":     { Func: Func("Miqledeth.CorrectCommand"),       Register: false }
       , "callback":    { Func: Func("Miqledeth.CallbackCommand"),      Register: false }
       , "time":        { Func: Func("Miqledeth.TimeCommand"),          Register: true  } }
}
