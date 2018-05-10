; AHK 1.1.27.07


; Stores the last keystrokes and characters
class KeyBuffer
{
  ; Current state
  
  Keys := [ ]
  
  GetLastKey()
  {
    return this.Keys[this.Keys.MaxIndex()]
  }
  
  GetText()
  {
    text := ""
    for index, key in this.Keys
    {
      if(key.BackCount)
        text := Substr(text, 1, StrLen(text) - key.BackCount)
      text .= key.Text
    }
    return text
  }
  
  
  ; Clears all the information stored before
  Clear()
  {
    this.Keys := [ ]
  }
  
  ; Stores a keystroke
  AddKey(key)
  {
    this.Keys.Push(key)
  }
  
  ; Stores a text character or a string of characters
  AddText(text)
  {
    this.GetLastKey().Text := text
  }
  
  ; Removes the given number of last characters from the stored text
  AddBack(count)
  {
    this.GetLastKey().BackCount := count
  }
  
  
  ; Returns the sequence of stored keys in the given layout
  RetypePhrase(layoutName)
  {
    backCount := StrLen(this.GetText())
    keys := this.RetypeKeysInLayout(layoutName)
    keys.Push(this.GetCallbackKey(this.RetypePhraseCallbackFunc.Bind(this, backCount)))
    return keys
  }
  
  RetypeKeysInLayout(layoutName)
  {
    keys := [ ]
    for index, key in this.Keys
    {
      key.Text := ""
      key.BackCount := ""
      key.LayoutName := layoutName
      keys.Push(key)
    }
    this.Clear()
    return keys
  }
  
  RetypePhraseCallbackFunc := Func("KeyBuffer.RetypePhraseCallback")
  RetypePhraseCallback(backCount)
  {
    return [ this.GetCorrectKey(backCount, this.GetText()) ]
  }
  
  ; Returns the last stored character key in the given layout
  RetypeChar(layoutName)
  {
    length := 0
    key := ""
    keyIndex := this.Keys.MaxIndex()
    while(keyIndex > 0)
    {
      key := this.Keys.Pop()
      length += StrLen(key.Text) - (key.Back ? key.Back : 0)
      if(length > 0)
        break
      keyIndex--
    }
    if(keyIndex)
    {
      key.LayoutName := layoutName
      return [ key, this.GetCallbackKey(this.RetypeCharCallbackFunc.Bind(this, length)) ]
    }
    else
      return [ ]
  }
  
  RetypeCharCallbackFunc := Func("KeyBuffer.RetypeCharCallback")
  RetypeCharCallback(backCount)
  {
    return [ this.GetCorrectKey(backCount, this.GetLastKey().Text) ]
  }
  
  
  ; Tries applying a substitution from the given list to the stored text
  Substitute(layoutName, substitutions)
  {
    if(!layoutName || this.GetLastKey().LayoutName == layoutName)
      return this.SubstituteInCurrentLayout(substitutions)
    else
      return this.SubstituteInLayout(layoutName, substitutions)
  }
  
  SubstituteInCurrentLayout(substitutions)
  {
    text := this.GetText()
    textLength := StrLen(text)
    
    for negativeLength, substitutionDictionary in substitutions
      if(-negativeLength <= textLength)
      {
        restLength := textLength + negativeLength
        substitution := substitutionDictionary["k_" SubStr(text, restLength + 1)]
        if(substitution)
        {
          this.AddBack(-negativeLength)
          this.AddText(substitution)
          return [ this.GetCorrectKey(-negativeLength, substitution) ]
        }
      }
    
    return [ ]
  }
  
  SubstituteInLayout(layoutName, substitutions)
  {
    oldKeys := []
    for index, key in this.Keys
      oldKeys[index] := key.Clone()
    
    keys := this.RetypeKeysInLayout(layoutName)
    keys.Push(this.GetCallbackKey(this.SubstituteInLayoutCallbackFunc.Bind(this, oldKeys, substitutions)))
    return keys
  }
  
  SubstituteInLayoutCallbackFunc := Func("KeyBuffer.SubstituteInLayoutCallback")
  SubstituteInLayoutCallback(oldKeys, substitutions)
  {
    substitution := this.GetLastKey()
    length := 0
    backCount := 0
    keyIndex := this.Keys.MaxIndex() - 1
    while(keyIndex > 0)
    {
      key := this.Keys[keyIndex]
      oldKey := oldKeys[keyIndex]
      length += StrLen(key.Text) - (key.BackCount ? key.BackCount : 0)
      backCount += StrLen(oldKey.Text) - (oldKey.BackCount ? oldKey.BackCount : 0)
      if(length == substitution.BackCount)
        break
      keyIndex--
    }
    
    this.Keys := oldKeys
    this.Keys[this.Keys.MaxIndex()] := substitution
    return keyIndex
      ? [ this.GetCorrectKey(backCount, substitution.Text) ]
      : [ ]
  }
  
  
  GetCorrectKey(backCount, text)
  {
    return { Time: A_TickCount, Action: { Command: "correct", Arguments: [ backCount, text ] } }
  }
  
  GetCallbackKey(callback)
  {
    return { Time: A_TickCount, Action: { Command: "callback", Arguments: [ callback ] } }
  }
}
