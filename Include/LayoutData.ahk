; AHK 1.1.27.07

#Include Include\Dictionary.ahk
#Include Include\MiqParser.ahk
#Include Include\KeySets.ahk


; Stores all the data from .miq files in a ready-to-use from.
class LayoutData
{
  ; Properties
  
  ; Layouts by name
  Layouts := { }
  
  ; Set of all modifiers used in the layouts except the built-in ones
  CustomModifiers := { }
  
  ; Substitutions grouped by initiator and then by condition string length
  Substitutions := { }
  
  ; Hotkey actions grouped by AHK-style hotkey name and condition
  Hotkeys := { }
  
  ; Actions for modifier keys pressed separately
  ;  grouped by built-in modifier set and condition
  VirginKeys := { }
  
  
  ; Modifier string representing any modifier set
  static AnyModifierString := " any"
  
  ; Standard and special modifiers not defined in layout descriptions
  static BuiltInModifiers
    := { "any":   "*"
       , "win":   "#"
       , "alt":   "!"
       , "ctrl":  "^" 
       , "shift": "+" }
  
  
  ; Constructor
  __New(items)
  {
    layoutDescriptions := []
    
    for index, item in items
      if(index)
      {
        ; Loading layout description
        layoutDescription := item.ToObject()
        layoutDescriptions.Push(layoutDescription)
        
        ; Collecting items
        this.CollectLayout(layoutDescription.Layout)
        this.CollectModifiers(layoutDescription.Modes)
        this.CollectSubstitutions(layoutDescription.Substitutions)
      }
    
    ; Collecting keys
    for index, layoutDescription in layoutDescriptions
      this.CollectKeys(layoutDescription.Layout
        , layoutDescription.Modes
        , layoutDescription.Keys)
  }
  
  
  ; Collecting objects from layout descriptions
  
  CollectLayout(layout)
  {
    if(layout)
    {
      layoutObject := layout.ToValueObject()
      this.Layouts[layoutObject.Name] := layoutObject
    }
  }
  
  CollectModifiers(modes)
  {
    for modeIndex, mode in modes
      if(modeIndex)
        for modifierIndex, modifier in mode
          if(modifierIndex && !this.BuiltInModifiers[modifier])
              this.CustomModifiers[modifier] := false
  }
  
  CollectSubstitutions(substitutions)
  {
    for groupIndex, substitutionGroup in substitutions
      if(groupIndex)
      {
        initiator := substitutionGroup[0]
        for index, substitution in substitutionGroup
          if(index)
          {
            condition := substitution[0]
            negativeLength := -StrLen(condition)
            if(!this.Substitutions[initiator, negativeLength])
              this.Substitutions[initiator, negativeLength] := new Dictionary
            this.Substitutions[initiator, negativeLength]["k_" condition]
              := substitution[1]
          }
      }
  }
  
  CollectKeys(layout, modes, keys)
  {
    layoutName := layout.ToValueObject().Name
    
    for keyIndex, key in keys
      if(keyIndex)
      {
        keyName := key[0]
        scanCode := KeySets.GetScanCodeByName(keyName)
        numLockVariant := KeySets.NumLockVariants[keyName]
        
        for index, value in key
          if(index && value != "")
          {
            mode := modes[index]
            pass := mode[0] == "-"
            condition := this.GetKeyCondition(mode, numLockVariant)
            keyCode := numLockVariant
              ? condition.ChangeToNumlockVariant
                ? numLockVariant
                : keyName
              : scanCode
            
            this.CollectKey(keyCode, layoutName, condition, pass, value)
          }
      }
  }
  
  CollectKey(keyCode, layoutName, condition, pass, value)
  {
    hotkeyName := condition.BuiltInModifiers . keyCode
    keys := keyCode ? this.Hotkeys : this.VirginKeys
    isMouseWheel := KeySets.MouseWheel[keyCode]
    action := { }
    
    if(IsObject(value))
    {
      action.Command := value[0]
      value[0] := ""
      action.Arguments := value
      
      if(action.Command == "modifier")
      {
        upAction := { Command: "modifierUp", Arguments: action.Arguments }
        this.AddAction(keys, hotkeyName " Up", pass, isMouseWheel, layoutName, condition.ModifierString, upAction)
      }
      else if(action.Command == "back" && pass)
        action.Command := "passBack"
    }
    else
    {
      action.Command := pass ? "passText" : "text"
      action.Arguments := [ value ]
    }
    
    this.AddAction(keys, hotkeyName, pass, isMouseWheel, layoutName, condition.ModifierString, action)
  }
  
  AddAction(keys, hotkeyName, pass, isMouseWheel, layoutName, modifierString, action)
  {
    this.AddActionPassPair(keys, hotkeyName, pass, layoutName, modifierString, action)
    
    if(!layoutName)
      for layoutName, layout in this.Layouts
        if(!keys[hotkeyName, layoutName . modifierString])
          this.AddActionPassPair(keys, hotkeyName, pass, layoutName, modifierString, action)
    
    if(pass)
      keys["~" hotkeyName].IsTransparent := true
    if(isMouseWheel)
      keys[(pass ? "~" : "") . hotkeyName].IsMouseWheel := true
  }
  
  AddActionPassPair(keys, hotkeyName, pass, layoutName, modifierString, action)
  {
    keys[(pass ? "~" : "") . hotkeyName, "Variants", layoutName . modifierString] := action
    keys[(pass ? "" : "~") . hotkeyName, "Alternates", layoutName . modifierString] := action
  }
  
  
  ; Helper methods
  
  GetKeyCondition(modifierList, isNumLockDependent)
  {
    modifierSet := { }
    for index, modifierName in modifierList
      if(index && modifierName)
        modifierSet[modifierName] := true
    
    changeToNumlockVariant := isNumLockDependent && modifierSet["shift"]
    if(isNumLockDependent)
      modifierSet["shift"] := false
    
    return { BuiltInModifiers: this.GetKeyBuiltInModifiers(modifierSet)
           , ModifierString: this.GetKeyModifierString(modifierSet)
           , ChangeToNumlockVariant: changeToNumlockVariant }
  }
  
  GetKeyBuiltInModifiers(modifierSet)
  {
    builtInModifiers := ""
    for modifierName, modifierSymbol in this.BuiltInModifiers
      if(modifierSet[modifierName])
        builtInModifiers .= modifierSymbol
    return builtInModifiers
  }
  
  GetKeyModifierString(modifierSet)
  {
    if(modifierSet["any"])
      return this.AnyModifierString
    else
    {
      modifierString := ""
      for modifierName, _ in this.CustomModifiers
        if(modifierSet[modifierName])
          modifierString .= " " modifierName
      return modifierString
    }
  }
}
