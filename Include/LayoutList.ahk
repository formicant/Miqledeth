; AHK 1.1.27.07

#Include Include\SystemLayouts.ahk


; Manipulates the layouts
class LayoutList
{
  ; Invariable properties
  
  SystemLayouts := { }
  LayoutIconParameters := { }
  Layouts := { }
  Languages := { }
  
  
  ; Current state
  
  IsMiqledethAllowed := true
  CurrentLayoutName := ""
  CurrentLanguage := ""
  CombiningMode := true
  
  
  CurrentLayout
  {
    get
    {
      return this.Layouts[this.CurrentLayoutName]
    }
  }
  
  
  ; Constructor
  __New(layoutIconParameters, ignoredProcesses, layouts)
  {
    this.LayoutIconParameters := layoutIconParameters
    this.Layouts := layouts
    this.SystemLayouts := new SystemLayouts(ignoredProcesses)
    
    this.InitializeLanguages()
    this.SetCurrentLayoutBySystemLanguage()
    this.InitializeTimer()
  }
  
  
  ; Combines the languages from layout descriptions and system layouts
  InitializeLanguages()
  {
    systemLayoutList := this.SystemLayouts.List
    
    last := ""
    for index, systemLayout in systemLayoutList
    {
      current := systemLayout.Language
      if(!this.Languages[current])
      {
        this.Languages[current] := { }
        if(last)
        {
          this.Languages[current].Prev := last
          this.Languages[last].Next := current
        }
        last := current
      }
    }
    first := systemLayoutList[1].Language
    this.Languages[first].Prev := last
    this.Languages[last].Next := first
    
    for layoutName, layout in this.Layouts
      if(layout.Language)
      {
        if(!this.Languages[layout.Language])
          this.Languages[layout.Language] := { Prev: last, Next: first }
        this.Languages[layout.Language].Layout := layout
      }
  }
  
  ; Creates a timer to periodically check the current system layout
  ; TODO: remove the timer, monitor the layout changing events instead
  InitializeTimer()
  {
    onLayoutTimer := Func("LayoutList.SetCurrentLayoutBySystemLanguage").Bind(this)
    SetTimer % onLayoutTimer, 250
  }
  
  
  ; Setting current layout
  
  SetCurrentLayoutBySystemLanguage()
  {
    language := this.SystemLayouts.Current.Language
    if(language)
    {
      this.IsMiqledethAllowed := true
      if(language != this.CurrentLanguage)
        this.SetCurrentLayoutByLanguage(language)
    }
    else
      this.IsMiqledethAllowed := false
  }
  
  SetCurrentLayout(layoutTerm)
  {
    next := (layoutTerm == "next")
    prev := (layoutTerm == "prev")
    
    if(next || prev)
    {
      language := this.CurrentLayoutName
        ? this.CurrentLayout.Language
        : this.CurrentLanguage
      if(language)
        language := next
          ? this.Languages[language].Next
          : this.Languages[language].Prev
      else
        language := this.CurrentLanguage
      
      this.SetCurrentLayoutByLanguage(language)
    }
    else if(this.Layouts[layoutTerm])
      this.SetCurrentLayoutByName(layoutTerm)
    else if(this.Languages[layoutTerm])
      this.SetCurrentLayoutByLanguage(layoutTerm)
  }
  
  SetCurrentLayoutByName(layoutName)
  {
    layout := this.Layouts[layoutName]
    this.CurrentLayoutName := layout.Name
    if(layout.Language)
    {
      this.CurrentLanguage := layout.Language
      this.SystemLayouts.SetByLanguage(layout.Language)
    }
    this.UpdateIcon()
  }
  
  SetCurrentLayoutByLanguage(language)
  {
    this.CurrentLanguage := language
    this.CurrentLayoutName := this.Languages[language].Layout.Name
    this.SystemLayouts.SetByLanguage(language)
    this.UpdateIcon()
  }
  
  SetCombiningMode(combiningMode)
  {
    if(this.CombiningMode != combiningMode)
    {
      this.CombiningMode := combiningMode
      this.UpdateIcon()
    }
  }
  
  
  ; Changes the tray icon
  UpdateIcon()
  {
    if(this.LayoutIconParameters)
    {
      iconIndex := this.CurrentLayout.IconIndex
      if(!(iconIndex > 0 && iconIndex < this.LayoutIconParameters.IconsInARow))
        iconIndex := 0
      if(!this.CombiningMode)
        iconIndex += this.LayoutIconParameters.IconsInARow
      
      iconPath := this.LayoutIconParameters.Path
      Menu Tray, Icon, %iconPath%, % 1 + iconIndex
      Menu Tray, Tip, % this.CurrentLayout ? this.CurrentLayout.Name : this.CurrentLanguage
    }
  }
}
