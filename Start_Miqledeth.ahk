; AHK 1.1.27.07

#SingleInstance force
#Persistent
#NoEnv

; Enable for debugging:
; #Warn

; Disable for debugging:
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
ListLines Off
Process, Priority, , A
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
; ^

SetWorkingDir %A_ScriptDir%

#Include Include\Miqledeth.ahk

new Miqledeth({ LayoutFolder: "Layouts"
    , LayoutIcons: { Path: "Icons\Icons.dll", IconsInARow: 6 }
    , LockState: { Scroll: "AlwaysOff", Caps: "AlwaysOff", Num: "AlwaysOn" }
    , IgnoredProcesses: ["mstsc.exe", "vmware.exe"] })
  .Start()
