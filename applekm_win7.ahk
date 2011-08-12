;
; AutoHotkey Version: 2.x
;

;#NoTrayIcon

; Recommended for performance and compatibility with future AutoHotkey releases.
#NoEnv

; Recommended for new scripts due to its superior speed and reliability.
SendMode Input

; Ensures a consistent starting directory.
SetWorkingDir %A_ScriptDir%

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DLL registration and readout of keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Set screen title, to set the HWND
Gui, Show, x0 y0 h0 w0, FnMapper

; Variable for the modifier key, define it here, just to be sure
fnPressed := 0
browser_back_forward_flag := 1
enableDriveEject := 0

; Set the homepath to the relevant dll file
HomePath=AutohotkeyRemoteControl.dll

; Load the dll
hModule := DllCall("LoadLibrary", "str", HomePath)

; On specific message from the dll, goto this function
OnMessage(0x00FF, "InputMsg")

; Register at the dll in order to receive events
EditUsage := 1
EditUsagePage := 12
HWND := WinExist("FnMapper")
nRC := DllCall("AutohotkeyRemoteControl\RegisterDevice", INT, EditUsage, INT, EditUsagePage, INT, HWND, "Cdecl UInt")
WinHide, FnMapper

Return

; This function is called, when a WM_INPUT-msg from a device is received
InputMsg(wParam, lParam, msg, hwnd)
{
	DeviceNr = -1
	nRC := DllCall("AutohotkeyRemoteControl\GetWM_INPUTDataType", UINT, wParam, UINT, lParam, "INT *", DeviceNr, "Cdecl UInt")
	if (errorlevel <> 0) || (nRC == 0xFFFFFFFF) {
		MsgBox GetWM_INPUTHIDData fehlgeschlagen. Errorcode: %errorlevel%
		goto cleanup
	}
	; Tooltip, %DeviceNr%
	ifequal, nRC, 2
	{
		ProcessHIDData(wParam, lParam)
	}
	else {
		MsgBox, Error - no HID data
	}
}

ProcessHIDData(wParam, lParam)
{
	; Make sure this variable retains its value outside this function
	global fnPressed
	global enableDriveEject

	DataSize = 5000
	VarSetCapacity(RawData, %DataSize%, 0)
	RawData = 1
	nHandle := DllCall("AutohotkeyRemoteControl\GetWM_INPUTHIDData", UINT, wParam, UINT, lParam, "UINT *" , DataSize, "UINT", &RawData, "Cdecl UInt")

	; Get the ID of the device
	; Use the line below to check where an event was sent from, when using this code for a new HID device
	; DeviceNumber := DllCall("AutohotkeyRemoteControl\GetNumberFromHandle", UINT, nHandle, "Cdecl UInt")

	; FirstValue := NumGet(RawData, 0, "UChar")
	KeyStatus := NumGet(RawData, 1, "UChar")

	; Filter the correct bit, so that it corresponds to the key in question
	; Add another Transform for a new key

	; Filter bit 4 (Eject key)
	Transform, EjectValue, BitAnd, 8, KeyStatus

	if (enableDriveEject = 0) {
		; Drive Eject is disabled to enable auto multiple delete keystrokes
		if (EjectValue = 8) {
			; Eject is pressed
			Send {Delete}
			; Repeat the 2nd delete after 1.00 second, then send 40 delete key per second
			SetTimer, sendDelete, 1000
		}
		else {
			; Eject is let go
			SetTimer, sendDelete, Off
		}
	}
	else {
		; Drive Eject enabled
		if (EjectValue = 8) {
			; Eject is pressed
			Send {Delete}
			; Set timeout of 1 second to distinguish delete or eject
			SetTimer, ejectDrive, 1000
		}
		else {
			; If the Eject button is let go within the second it will disable the timer and skip the ejectDrive function
			SetTimer, ejectDrive, Off
		}
	}

	; Filter bit 5 (Fn key)
	Transform, FnValue, BitAnd, 16, KeyStatus

	if (FnValue = 16) {
		; Fn is pressed
		fnPressed := 1
	}
	else {
		; Fn is released
		fnPressed := 0
	}
}

; If there was an error retrieving the HID data, cleanup
cleanup:
	DllCall("FreeLibrary", "UInt", hModule)  ; It is best to unload the DLL after using it (or before the script exits).
ExitApp

sendDelete:
	Send {Delete}
	; Send 40 delete key per second
	SetTimer, sendDelete, 25
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Eject, with a delay, Apple style
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ejectDrive:
	Drive, Eject
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Fn + Backspace = Delete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

$Backspace::
	if (fnPressed = 1) {
		Send {Delete}
	} else {
		Send {Backspace}
	}
Return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Fn modifier: Audio hotkeys, specified for Winamp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

$F1::
	if (fnPressed = 1) {
		Send {}
	} else {
		Send {F1}
	}
Return

$F2::
	if (fnPressed = 1) {
		Send {}
	} else {
		Send {F2}
	}
Return

$F3::
	if (fnPressed = 1) {
		Send {}
	} else {
		Send {F3}
	}
Return

$F4::
	if (fnPressed = 1) {
		Run taskmgr
	} else {
		Send {F4}
	}
Return

$F5::
	if (fnPressed = 1) {
		Run calc
	} else {
		Send {F5}
	}
Return

$F6::
	if (fnPressed = 1) {
		Send {PrintScreen}
	} else {
		Send {F6}
	}
Return

!$F6::
	if (fnPressed = 1) {
		Send !{PrintScreen}
	} else {
		Send !{F6}
	}
Return

$F7::
	if(fnPressed = 1) {
		; IfWinNotExist ahk_class Winamp v1.x
		; Return
		; ControlSend, ahk_parent, z  ; Previous
		Send {VKB1SC110}
	} else {
		Send {F7}
	}
Return

;
; Winamp: Pause/Unpause
;
$F8::
	if (fnPressed = 1) {
		;IfWinNotExist ahk_class Winamp v1.x
		;Return
		;ControlSend, ahk_parent, c ; Pause/Unpause
		Send {VKB3SC122} ; hotkey for HP DV2141
	} else {
		Send {F8}
	}
Return

;
; Winamp: Next
;
$F9::
	if (fnPressed = 1) {
		;IfWinNotExist ahk_class Winamp v1.x
  		;Return
		;ControlSend, ahk_parent, b ; Next
		Send {VKB0SC119}
	} else {
		Send {F9}
	}
Return

$F10::
	if (fnPressed = 1) {
		;Send {Volume_Mute} ; Mute/unmute the master volume.
		Send {VKADSC120}
	} else {
		Send {F10}
	}
Return

$F11::
	if (fnPressed = 1) {
		Send {Volume_Down} ; Lower the master volume by 1 interval (typically 5%)
	} else {
		Send {F11}
	}
Return

$F12::
	if (fnPressed = 1) {
		Send {Volume_Up}  ; Raise the master volume by 1 interval (typically 5%).
	} else {
		Send {F12}
	}
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Fn modifier: Arrow keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; Page Up
;
$UP::
	if (fnPressed = 1) {
		Send {PgUp}
	} else {
		Send {UP}
	}
Return

;
; Page Down
;
$Down::
	if (fnPressed = 1) {
		Send {PgDn}
	} else {
		Send {Down}
	}
Return

;
; Home
;
$Left::
	if (fnPressed = 1) {
		Send {Home}
	} else {
		Send {Left}
	}
Return

;
; End
;
$Right::
	if (fnPressed = 1) {
		Send {End}
	} else {
		Send {Right}
	}
Return

;
; Ctrl+Page Up
;
^$UP::
	if (fnPressed = 1) {
		Send ^{PgUp}
	} else {
		Send ^{UP}
	}
Return

;
; Ctrl+Page Down
;
^$Down::
	if (fnPressed = 1) {
		Send ^{PgDn}
	} else {
		Send ^{Down}
	}
Return

;
; Ctrl+Home
;
^$Left::
	if (fnPressed = 1) {
		Send ^{Home}
	} else {
		Send ^{Left}
	}
Return

;
; Ctrl+End
;
^$Right::
	if (fnPressed = 1) {
		Send ^{End}
	} else {
		Send ^{Right}
	}
Return

;
; Shift+Page Up
;
+$UP::
	if (fnPressed = 1) {
		Send +{PgUp}
	} else {
		Send +{UP}
	}
Return

;
; Shift+Page Down
;
+$Down::
	if (fnPressed = 1) {
		Send +{PgDn}
	} else {
		Send +{Down}
	}
Return

;
; Shift+Home
;
+$Left::
	if (fnPressed = 1) {
		Send +{Home}
	} else {
		Send +{Left}
	}
Return

;
; Shift+End
;
+$Right::
	if (fnPressed = 1) {
		Send +{End}
	} else {
		Send +{Right}
	}
Return

;
; Ctrl+Shift+Page Up
;
^+$UP::
	if (fnPressed = 1) {
		Send ^+{PgUp}
	} else {
		Send ^+{UP}
	}
Return

;
; Ctrl+Shift+Page Down
;
^+$Down::
	if (fnPressed = 1) {
		Send ^+{PgDn}
	} else {
		Send ^+{Down}
	}
Return

;
; Ctrl+Shift+Home
;
^+$Left::
	if (fnPressed = 1) {
		Send ^+{Home}
	} else {
		Send ^+{Left}
	}
Return

;
; Ctrl+Shift+End
;
^+$Right::
	if (fnPressed = 1) {
		Send ^+{End}
	} else {
		Send ^+{Right}
	}
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; MButton = Win+LButton
;
#LButton::
	Click down middle
Return

#LButton Up::
	Click up middle
Return

enable_bbf_flag:
	browser_back_forward_flag := 1
Return

;
; Broswer Back = Win+WheelLeft
; Execute at most once per second
;
#WheelLeft::
	if (browser_back_forward_flag = 1) {
		Send {Browser_Back}
		browser_back_forward_flag := 0
		SetTimer, enable_bbf_flag, 1000
	}
Return

;
; Broswer Forward = Win+WheelRight
; Execute at most once per second
;
#WheelRight::
	if (browser_back_forward_flag = 1) {
		Send {Browser_Forward}
		browser_back_forward_flag := 0
		SetTimer, enable_bbf_flag, 1000
	}
Return

;;
;; MButton = Ctrl+LButton
;;
;^LButton::
;	Click down middle
;Return
;
;^LButton Up::
;	Click up middle
;Return
;
;enable_bbf_flag:
;	browser_back_forward_flag := 1
;Return
;
;;
;; Broswer Back = Ctrl+WheelLeft
;; Execute at most once per second
;;
;^WheelLeft::
;	if (browser_back_forward_flag = 1) {
;		Send {Browser_Back}
;		browser_back_forward_flag := 0
;		SetTimer, enable_bbf_flag, 1000
;	}
;Return
;
;;
;; Broswer Forward = Ctrl+WheelRight
;; Execute at most once per second
;;
;^WheelRight::
;	if (browser_back_forward_flag = 1) {
;		Send {Browser_Forward}
;		browser_back_forward_flag := 0
;		SetTimer, enable_bbf_flag, 1000
;	}
;Return
