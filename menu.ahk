

global optionsKeyBaseDelay := 0
global optionsKeyDelay := 0
global optionsKeyPressDuration := 0
global optionsHomeDataCenter := 0
global optionsDefaultWorldsHwnd := []
global optionsDefaultWorldsValue := []

global settings := new CSettings()


InitializeMenu() {
	VersionText := "FastTraval v" . version,
	Menu, Tray, NoStandard
	Menu, Tray, Add, %VersionText%, NoOp
	Menu, Tray, Disable, 1&
	Menu, Tray, Add
	Menu, Tray, Add, Options, Options
	Menu, Tray, Add
	Menu, Tray, Add, Exit, Exit
}

InitializeOptionsGui() {
	Gui, Options:New, -SysMenu ToolWindow , FastTravel Options

	; Input Configuration
	Gui, Font, bold,
	Gui, Options:Add, Text,, Input Configuration
	Gui, Font,,

	Gui, Font, italic
	Gui, Options:Add, Text,, Increase these values to reduce chance that input from script will be ghosted.`nFiddle with different combinations to see which one works best for you.`nLonger delays means longer travel times.

	Gui, Font,,
	Gui, Options:Add, Text, , Delay Between Keys [ms]
	Gui, Options:Add, Edit, section Number x+10 yp-6 w50
	Gui, Options:Add, UpDown, voptionsKeyDelay Range5-1000, 5
	Gui, Font, italic
	Gui, Options:Add, Text, xm y+1, Gives game time to process each key (eg. play menu selection animation)
	Gui, Font,,
	Gui, Options:Add, Text, , Key Press Duration [ms]
	Gui, Options:Add, Edit, Number xs yp-6 w50
	Gui, Options:Add, UpDown, voptionsKeyPressDuration Range5-1000, 5
	Gui, Font, italic
	Gui, Options:Add, Text, xm y+1, Gives game more time to notice that key was pressed (can be usefull for low fps)
	Gui, Font,,
	Gui, Options:Add, Text, , Base Key Delay [ms]
	Gui, Options:Add, Edit, Number xs yp-6 w50
	Gui, Options:Add, UpDown, voptionsKeyBaseDelay Range5-1000, 5
	Gui, Font, italic
	Gui, Options:Add, Text, xm y+1, Use as last resort, similar to Delay Between Keys


	; Data Centers Configuration
	Gui, Font,,
	Gui, Font, bold,
	Gui, Options:Add, Text, xm y+20, Data Centers Configuration
	Gui, Font,,
	Gui, Options:Add, Text, , Your Home Data Center
	Gui, Options:Add, DropDownList, yp-6 xs voptionsHomeDataCenter gOptionsHomeDataCenterAction AltSubmit, % dataCenters.AllDcString()
	Gui, Options:Add, Text, xm, Default world destination in each Data Center
	for idx, dc in dataCenters.DcArray {
		ys := ""
		if (idx > 1) {
			ys := "ys"
		}
		Gui, Options:Add, Text, section %ys%, % dc.Name
		rows := dc.Worlds.Length()
		hwnd := 0
		Gui, Options:Add, ListBox, Hwndhwnd r%rows% xs AltSubmit gOptionsDefaultWorldAction, % dc.AllWorldsString()
		optionsDefaultWorldsHwnd.Push(hwnd)
		optionsDefaultWorldsValue.Push(0)
	}

	; Buttons
	Gui, Options:Add, Button, gOptionsSave xm y+10, Save
	Gui, Options:Add, Button, gOptionsCancel x+10, Cancel


}

; Tray actions
Exit() {
	ExitApp
}

Options() {
	Gui, Options:Show
	settings.CommitToGui()
}

; Options actions

OptionsSave() {
	Gui Options:Submit
	settings.CommitFromGui()
}

OptionsCancel() {
	Gui Options:Hide
}

OptionsDefaultWorldAction() {
	for idx, defaultWorld in optionsDefaultWorldsHwnd {
		GuiControlGet, value,, % defaultWorld,
		if (value > 0) {
			optionsDefaultWorldsValue[idx] := value
		}
	}
}

OptionsHomeDataCenterAction() {
	Gui Options:Submit, NoHide

	for idx, worldHwnd in optionsDefaultWorldsHwnd {
		if (idx == optionsHomeDataCenter) {
			GuiControl, Options:Disable, % worldHwnd
			GuiControl, Options:Choose, % worldHwnd, 0
		} else {
			GuiControl, Options:Enable, % worldHwnd
			GuiControl, Options:Choose, % worldHwnd, % optionsDefaultWorldsValue[idx]
		}
	}
}

class CSettings {

	__New() {
		this.Path :=  A_AppData . "\FFxivFastTravel"
		this.FileName := this.Path . "\settings.ini"

		this.HomeDc := 2
		this.DefaultWorlds := []

		this.KeyBaseDelay := 50
		this.KeyPressDuration := 200
		this.KeyDelay := 350

		this.Load()
	}

	GetDefaultWorld(index) {
		if (index <= this.DefaultWorlds.Length()) {
			return this.DefaultWorlds[index]
		} else {
			return 1
		}
	}

	_read(val, name) {
		IniRead, OutputVar, % this.FileName, General, % name, % val
		return OutputVar
	}

	Load() {
		this.KeyBaseDelay := this._read(this.KeyBaseDelay, "KeyBaseDelay")
		this.KeyPressDuration := this._read(this.KeyPressDuration, "KeyPressDuration")
		this.KeyDelay := this._read(this.KeyDelay, "KeyDelay")

		this.HomeDc := this._read(this.HomeDc, "HomeDc")

		IniRead, DefaultWorlds, % this.FileName, General, DefaultWorlds, %A_Space%
		if (DefaultWorlds == "") {
			this.DefaultWorlds := []
		} else {
			this.DefaultWorlds := StrSplit(DefaultWorlds, ",")
		}

	}

	Save() {
		if (!FileExist(this.Path)) {
			FileCreateDir, % this.Path
		}

		IniWrite, % this.KeyBaseDelay, % this.FileName, General, KeyBaseDelay
		IniWrite, % this.KeyPressDuration, % this.FileName, General, KeyPressDuration
		IniWrite, % this.KeyDelay, % this.FileName, General, KeyDelay

		IniWrite, % this.HomeDc, % this.FileName, General, HomeDc

		DefaultWorlds := ""
		for idx, world in this.DefaultWorlds {
			if (idx > 1) {
				DefaultWorlds := DefaultWorlds . ","
			}
			DefaultWorlds := DefaultWorlds . world
		}
		IniWrite, % DefaultWorlds, % this.FileName, General, DefaultWorlds
	}

	CommitFromGui() {
		this.KeyBaseDelay := optionsKeyBaseDelay
		this.KeyPressDuration := optionsKeyPressDuration
		this.KeyDelay := optionsKeyDelay

		this.HomeDc := optionsHomeDataCenter

		this.DefaultWorlds := []
		for idx, defaultWorld in optionsDefaultWorldsValue {
			this.DefaultWorlds.Push(defaultWorld)
		}

		this.Save()
	}


	CommitToGui() {
		GuiControl, Options:, optionsKeyBaseDelay, % this.KeyBaseDelay
		GuiControl, Options:, optionsKeyPressDuration, % this.KeyPressDuration
		GuiControl, Options:, optionsKeyDelay, % this.KeyDelay

		GuiControl, Options:Choose, optionsHomeDataCenter, % this.HomeDc

		for idx, defaultWorld in optionsDefaultWorldsValue {
			optionsDefaultWorldsValue[idx] := this.GetDefaultWorld(idx)
		}
		OptionsHomeDataCenterAction()

		Gui Options:Submit, NoHide
	}
}


NoOp() {
}