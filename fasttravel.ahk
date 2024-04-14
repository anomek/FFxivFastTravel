#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetKeyDelay 50, 200
SetMouseDelay 50, 200
CoordMode, Mouse, Screen


#Include version.ahk
#Include debuglog.ahk
#Include travellog.ahk
#Include menu.ahk
#Include pcap.ahk
#Include detection.ahk

global FFXIVWND := "FINAL FANTASY XIV"

global dataCenters := new CDataCenters(new DataCenter("Aether"
		, ["Adamantoise", "Cactuar", "Faerie", "Gilgamesh", "Jenova", "Midgardsormr", "Sargantanas", "Siren"]
		, AETHER_HOST)
	, new DataCenter("Crystal"
		, ["Balmung", "Brynhildr", "Coeurl", "Diabolos", "Goblin", "Malboro", "Mateus", "Zalera"]
		, CRYSTAL_HOST)
	, new DataCenter("Dynamis"
		, ["Halicarnassus", "Maduin", "Marilith", "Seraph"]
		, DYNAMIS_HOST)
	, new DataCenter("Primal"
		, ["Behemoth", "Excalibur", "Exodos", "Famfrit", "Hyperion", "Lamia", "Leviathan", "Ultros"]
		, PRIMAL_HOST))
	; order needs to be same as in game

global detector := CreateDetector(dataCenters.AllAreas())
global guic := new CGuiControl()

OnExit("Close")

InitializeMenu()
InitializeOptionsGui()

SetTimer, Update, 500

Update() {
	dataCenters.Update()
	guic.Update()
}

; tab into / out of ffxiv game during travel
Hotkey, Tab, TabHK
Hotkey, Tab, Off
TabHK() {
	guic.ToggleWindow()
	return
}

; datacenter travel hotkey
Hotkey, ^!+p, ShowGuiHK
Hotkey, ^!+p, Off
ShowGuiHK() {
	Gui, DcSelect:New ,-SysMenu ToolWindow -Caption +0x80880000
	Gui, DcSelect:Add, Text,, Select DC you want to travel to:
	for i, name in dataCenters.DcList() {
		if (InStr(name, "-->")) {
			Gui, DcSelect:Add, Button, Left gOnButton w150 Disabled, %name%
		} else {
			Gui, DcSelect:Add, Button, Left gOnButton w150, %name%
		}
	}
	Gui, DcSelect:Add, Text,,
	Gui, DcSelect:Add, Text,, % "Currently on:`n" . dataCenters.CurrentDc.Name
	Gui, DcSelect:Add, Button, gOnCancel, Cancel
	Gui, DcSelect:Show,,

	return
	OnButton:
		name := A_GuiControl
		Gui, DcSelect:Destroy
		WinActivate, %FFXIVWND%
		dataCenters.Travel(name)
		return
	OnCancel:
		Gui, DcSelect:Destroy
		return
}


; restart script hotkey
^!+o::
    log.UserInput("Restart script")
	BlockInput, MouseMoveOff
	SoundPlay, *64
	Reload
	return
	

SafeSend(keys*) {
    for i, key in keys {
        log.AppInput("Sending key: " . key)
		if (key == "LEFT") {
			SendToFF("^!+{Left}")
			SendToFF("{Numpad4}")
		} else if (key == "RIGHT") {
			SendToFF("^!+{Right}")
			SendToFF("{Numpad6}")
		} else if (key == "DOWN") {
			SendToFF("^!+{Down}")
			SendToFF("{Numpad2}")
		} else if (key == "UP") {
			SendToFF("^!+{Up}")
			SendToFF("{Numpad8}")
		} else {
			SendToFF(key)
		}
		Sleep, % settings.KeyDelay
	}
}

SendToFF(key) {
	ControlSend, ahk_parent, %key%, %FFXIVWND%
}


class CGuiControl {

	__New() {
		this.winActive := false
		this.inputBlocked := false
	}

	Update() {
		this.winActive := WinActive(FFXIVWND)

		startHotkeyActive := !dataCenters.Traveling && dataCenters.CurrentDc && this.winActive
		tabHotkeyActive := dataCenters.Traveling
		osdVisible := (dataCenters.CurrentDc || dataCenters.Traveling) && this.winActive
		inputShouldBeBlocked := dataCenters.Traveling && this.winActive

		Hotkey, ^!+p, % this.OnOff(startHotkeyActive)
		Hotkey, Tab, % this.OnOff(tabHotkeyActive)
		travelLog.Toggle(osdVisible)

		if (this.inputBlocked && !inputShouldBeBlocked) {
			BlockInput, MouseMoveOff
			this.inputBlocked := false
		} else if (!this.inputBlocked && inputShouldBeBlocked) {
			BlockInput, MouseMove
			MouseGetPos, MouseX, MouseY
			this.MouseX := MouseX
			this.MouseY := MouseY
			this.inputBlocked := true
		}
		; travelLog.Debug(Format("p:{1} t:{2} o:{3} i:{4}", startHotkeyActive, tabHotkeyActive, osdVisible, inputShouldBeBlocked))
	}

	OnOff(flag) {
		if (flag) {
			return "On"
		} else {
			return "Off"
		}
	}

	ToggleWindow() {
		if (this.winActive) {
			Send !{Tab}
		} else {
			BlockInput, MouseMove
			this.inputBlocked := true
			MouseMove, % this.MouseX, % this.MouseY
			WinActivate, %FFXIVWND%
		}
		Update()
	}
}

class CDataCenters {

	__New(dcArray*) {
		this.DcArray := dcArray
		for i, dc in this.DcArray {
			dc.Offset := i
		}
		this.Traveling := false
	}

	DcHome() {
		return this.DcArray[settings.HomeDc]
	}

	AllDcString() {
		dcString := ""
		for i, dc in this.DcArray {
			if (i > 1) {
				dcString := dcString . "|"
			}
			dcString := dcString . dc.Name
		}
		return dcString
	}

	AllAreas() {
		ret := []
		for i, dc in this.DcArray {
			ret.Push(dc.Area())
		}
		return ret
	}


	DcList() {
		this.Update()
		dcNames := []
		for i, dc in this.DcArray {
			dcName := dc.Name
			if (dc == this.CurrentDc) {
				dcNames.Push("--> " . dcName)
			} else {
				dcNames.Push("    " . dcName)
			}
		}
		return dcNames
	}

	Update() {
		if (!this.Traveling) {
			if (currentArea := detector.GetCurrentArea()) {
				for i, dc in this.DcArray {
					if (dc.Name == currentArea.Name) {
						this.CurrentDc := dc
					}
				}
				travelLog.On(currentArea.Name)
			} else {
				this.CurrentDc := 0
			}
		}
	}

	Travel(label) {
		SetKeyDelay, % settings.KeyBaseDelay, % settings.KeyPressDuration
		SetMouseDelay, % settings.KeyBaseDelay, % settings.KeyPressDuration

		for i, dc in this.DcArray {
			if (InStr(label, dc.Name)) {
				travelTo := dc
				break
			}
		}
		if (!travelTo) {
			MsgBox % "label not found " . label
		}

		this._InitTravel(travelTo)

		if (this.CurrentDc != this.DcHome()) {
			this.DcHome().Travel()
		}
		if (travelTo != this.DcHome()) {
			travelTo.Travel()
		}
		this._LoginAndFinalize()

	}

	_InitTravel(travelTo) {
		this.Traveling := true
		travelLog.StartTravel(this.CurrentDc.Name, travelTo.Name)
		guic.Update()
		SafeSend("{Esc}", "{Esc}")
	}

	_LoginAndFinalize() {
		SafeSend("{Numpad0}", "{Numpad0}")
		SoundPlay, *64
		travelLog.Hide()
		this.Traveling := false
		guic.Update()
	}

}

class DataCenter {

	__New(name, worlds, addr) {
		this.Name := name
		this.Worlds := worlds
		this.Addr := addr
	}

	AllWorldsString() {
		worldsString := ""
		for idx, world in this.Worlds {
			if (idx > 1) {
				worldsString := worldsString . "|"
			}
			worldsString := worldsString . world
		}
		return worldsString
	}

	Area() {
		return new CArea(this.Name, this.Addr)
	}

	Travel() {
		if (this.Offset == settings.HomeDc) {
			this._TravelHome()
		} else {
			this._TravelAway()
		}
	}

	_TravelHome() {
		this._NavigateToTravelInterfaceHome()

		travelLog.SetWaitingForSelectWorld()
		detector.WaitForEvent(Events.RETURN_HOME)

		travelLog.SetSelectingWorld()
		SafeSend("LEFT", "{Numpad0}") ; accept returning to home data center

		this._AcceptAndFinishTravel()
	}

	_TravelAway() {
		this._NavigateToTravelInterfaceAway()
		SafeSend("{Numpad0}")	; one more dialog to accept

		travelLog.SetWaitingForSelectWorld()
		detector.WaitForEvent(Events.WORLDLIST)

		travelLog.SetSelectingWorld()
		this._MoveOnDataCenterList()

		this._AcceptAndFinishTravel()
	}

	_NavigateToTravelInterfaceHome() {
		travelLog.SetNavigatingToSelectWorld()
		SafeSend("{NumpadMult}"
			   , "{NumpadPgDn}"
			   , "UP"
			   , "UP"
			   , "UP"
			   , "{Numpad0}")
	}

	_NavigateToTravelInterfaceAway() {
		travelLog.SetNavigatingToSelectWorld()
		SafeSend("{NumpadMult}"
			   , "{NumpadPgDn}"
			   , "UP"
			   , "{Numpad0}")
	}

	_AcceptAndFinishTravel() {

		travelLog.SetWaitingForTravelConfirmation()
		detector.WaitForEvent(Events.TRAVEL_INFO)

		travelLog.SetAcceptingTravel()
		SafeSend("LEFT", "{Numpad0}")

		travelLog.SetTravelingTo(this.Name)
		detector.WaitForEvent(Events.TRAVEL_COMPLETE)

		travelLog.SetConfirmingDataCenterArrival()
		SafeSend("{Numpad0}")

		travelLog.SetConnectingToDataCenter()
		detector.WaitForEvent(Events.CONNECTED_TO_DC)
	}

	_MoveOnDataCenterList() {
		offset := this.Offset - settings.HomeDc
		key := ""
		if (offset < 0) {
			key := "UP"
			offset := -offset
		} else {
			key := "DOWN"
		}
		while (offset > 0) {
		;	MsgBox, % offset
			SafeSend(key)
			offset := offset - 1
		}

		SafeSend("{Numpad0}")	; accept data center

		offset := settings.GetDefaultWorld(this.Offset) - 1
		while (offset > 0) {
			SafeSend("DOWN")
			offset := offset - 1
		}

		SafeSend("{Numpad0}", "{Numpad0}")	; accept world and next menu

	}
}

Close() {
	detector.Close()
	log.Close()
}

