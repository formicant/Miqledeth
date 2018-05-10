; AHK 1.1.27.07

#SingleInstance force
#Persistent
#NoEnv
#Warn

SetWorkingDir %A_ScriptDir%

#Include Include\Miqledeth.ahk

new Miqledeth({ LayoutFolder: "Layouts"
    , LayoutIcons: { Path: "Icons\Icons.dll", IconsInARow: 5 }
    , LockState: { Scroll: "AlwaysOff", Caps: "AlwaysOff", Num: "AlwaysOn" } })
  .Start()
