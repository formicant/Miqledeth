; AHK 1.1.27.07


; Parses .miq files returning the contents as an array
class MiqParser
{
  ParseFolder(path)
  {
    files := new MiqObject
    files[0] := path
    Loop Files, % path "\*.miq"
    {
      if((file := this.ParseFile(A_LoopFileFullPath)).Success)
        files.Push(file.Value)
      else
        return { Success: false, Value: "", Error: file.Error }
    }
    return { Success: true, Value: files }
  }
  
  ParseFile(filePath)
  {
    FileRead text, % filePath
    return this.ParseText(filePath, text)
  }
  
  ParseText(name, text)
  {
    context := { Text: text, Position: 1 }
    values := new MiqObject
    values[0] := name
    while(!(success := this.ParseEndOfFile(context).Success)
      && ((item := this.ParseMultilineObject(context)).Success
        || (item := this.ParseSingleLineObject(context)).Success))
      values.Push(item.Value)
    return { Success: success
      , Value: values
      , Error: success ? "" : this.GetErrorDetails(name, context) }
  }
  
  
  ; Parsing objects
  
  ParseMultilineObject(context)
  {
    values := new MiqObject
    name := ""
    success := false
    if(this.ParseOpeningBrace(context).Success
      && (name := this.ParseString(context)).Success
      && this.ParseLineEnd(context).Success)
    {
      values[0] := name.Value
      while(!(success := this.ParseClosingBrace(context).Success)
        && ((item := this.ParseMultilineObject(context)).Success
          || (item := this.ParseSingleLineObject(context)).Success))
        values.Push(item.Value)
      if(success)
        success := this.ParseLineEnd(context).Success
    }
    return { Success: success, Value: values }
  }
  
  ParseSingleLineObject(context)
  {
    values := new MiqObject
    if(success := (name := this.ParseString(context)).Success)
      while(!(success := this.ParseLineEnd(context).Success)
        && (item := this.ParseInlineObject(context)).Success)
        values.Push(item.Value)
    values[0] := name.Value
    return { Success: success, Value: values }
  }
  
  ParseInlineObject(context)
  {
    if((string := this.ParseString(context)).Success)
      return string
    values := new MiqObject
    if((success := this.ParseOpeningBrace(context).Success)
      && (name := this.ParseString(context)).Success)
      while(!(success := this.ParseClosingBrace(context).Success)
        && (item := this.ParseInlineObject(context)).Success)
        values.Push(item.Value)
    values[0] := name.Value
    return { Success: success, Value: values }
  }
  
  
  ; Parsing string values
  
  ParseString(context)
  {
    this.ParseWhitespace(context)
    string := ""
    if(!(success := this.ParseEmptyString(context).Success))
      while((result := this.ParseCharacters(context)).Success
        || (result := this.ParseEscapedCharacter(context)).Success
        || (result := this.ParseCodePoint(context)).Success
        || (result := this.ParseQuotedCharacters(context)).Success)
      {
        success := true
        string .= result.Value
      }
    return { Success: success, Value: string }
  }
  
  ParseEmptyString(context)
  {
    static regex := "AO)_(?=[ \t\r\n]|$)"
    if(success := RegExMatch(context.Text, regex, match, context.Position))
      context.Position++
    return { Success: success, Value: "" }
  }
  
  ParseCharacters(context)
  {
    static regex := "AO)[^_""{}% \t\r\n]+"
    if(success := RegExMatch(context.Text, regex, match, context.Position))
      context.Position += match.Len()
    return { Success: success, Value: match.Value() }
  }
  
  ParseEscapedCharacter(context)
  {
    static regex := "AO)_[_""{}%strn]"
    static escape
      := { "__": "_"
         , "_""": """"
         , "_%": "%"
         , "_{": "{"
         , "_}": "}"
         , "_s": " "
         , "_t": "`t"
         , "_r": "`r"
         , "_n": "`n" }
    if(success := RegExMatch(context.Text, regex, match, context.Position))
      context.Position += match.Len()
    return { Success: success, Value: escape[match.Value()] }
  }
  
  ParseCodePoint(context)
  {
    static regex := "AO)_([0-9A-Fa-f]+)_"
    if(success := RegExMatch(context.Text, regex, match, context.Position))
      context.Position += match.Len()
    return { Success: success, Value: success ? Chr("0x" match.Value(1)) : "" }
  }
  
  ParseQuotedCharacters(context)
  {
    static regex := "AO)""((?:""""|[^""\r\n])*)"""
    if(success := RegExMatch(context.Text, regex, match, context.Position))
      context.Position += match.Len()
    return { Success: success, Value: StrReplace(match.Value(1), """""", """") }
  }
  
  
  ; Parcing braces
  
  ParseOpeningBrace(context)
  {
    this.ParseWhitespace(context)
    if(success := Substr(context.Text, context.Position, 1) == "{")
      context.Position++
    return { Success: success }
  }
  
  ParseClosingBrace(context)
  {
    this.ParseWhitespace(context)
    if(success := Substr(context.Text, context.Position, 1) == "}")
      context.Position++
    return { Success: success }
  }
  
  
  ; Parsing whitespace
  
  ParseWhitespace(context)
  {
    static regex := "AO)[ \t]+"
    if(success := RegExMatch(context.Text, regex, match, context.Position))
      context.Position += match.Len()
    return { Success: success }
  }
  
  ParseLineEnd(context)
  ; including optional comments, empty lines, and end of file
  {
    static regex := "AO)(?:[ \t]*(?:%[^\r\n]*)?\r?(?:\n|$))+"
    if(success := RegExMatch(context.Text, regex, match, context.Position))
      context.Position += match.Len()
    return { Success: success }
  }
  
  ParseEndOfFile(context)
  {
    static regex := "AO)$"
    success := RegExMatch(context.Text, regex, match, context.Position)
    return { Success: success }
  }
  
  
  ; Processing errors
  
  GetErrorDetails(name, context)
  {
    ; Finding line and column by position
    lines := StrSplit(context.Text, "`n")
    lineIndex := 1
    startPosition := 1
    for index, line in lines
      if(startPosition + StrLen(line) >= context.Position)
      {
        lineIndex := index
        break
      }
      else
        startPosition += StrLen(line) + 1
    columnIndex := 1 + context.Position - startPosition
    
    ; Rendering line neighborhood
    static neighborLineCount := 5
    neighborhood := ""
    index := Max(1, lineIndex - neighborLineCount)
    lastNeighborLineIndex := Min(lines.Length(), lineIndex + neighborLineCount)
    while(index <= lastNeighborLineIndex)
    {
      prefix := index . (index == lineIndex ? ";  " columnIndex "  >" : "")
      line := Trim(lines[index], "`r")
      neighborhood .= prefix "`t" line "`r`n"
      index++
    }
    
    ; Composing error message
    message
      := "Miq parsing error in`r`n"
      . name "`r`nline " lineIndex ", position " columnIndex
      . ".`r`n`r`n" neighborhood
    
    return { Name: name
      , Line: lineIndex
      , Column: columnIndex
      , Neighborhood: neighborhood
      , Message: message }
  }
}


class MiqObject
{
  ToObject()
  {
    object := { }
    for index, item in this
      if(index && IsObject(item))
        object[item[0]] := item
    return object
  }
  
  ToValueObject()
  {
    object := { }
    for index, item in this
      if(index && IsObject(item))
        object[item[0]] := item[1]
    return object
  }
}
