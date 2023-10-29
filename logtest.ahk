

+!^o::
	Reload


+!^p::
	Gui, New, ToolWindow AlwaysOnTop Disabled -SysMenu Owner
	Gui, Add, Text,, Logs
	Gui, Show, NoActivate x10 y10 w1300 h400


	file := FileOpen("C:\Users\lukas\AppData\Roaming\Advanced Combat Tracker\FFXIVLogs\Network_26700_20221109.log", "r")
	while (file.ReadLine()) {

	}


	Loop{

		Sleep 1000
		if (line := file.ReadLine()) {
			Gui, Add, Text,, %line%
		;	Gui, Show, NoActivate x10 y10 w1300 h400
		}
	}