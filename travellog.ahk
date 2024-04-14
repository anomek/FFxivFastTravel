

global travelLog := new CTravelLog()

global travelText
global statusText
global debugText
global helpText

class CTravelLog {

	__New() {
		color := "000000"
		Gui, TravelLog:New, LastFound ToolWindow AlwaysOnTop Disabled -SysMenu Owner -Caption
		Gui, TravelLog:Color, %color%
		Gui, TravelLog:Font, s16 cWhite

		Gui, Add, Text, , Data Center travel
		Gui, Add, Text, y+1 vtravelText, Aether -> Crystal XXXXX

		Gui, TravelLog:Font, s12
		Gui, TravelLog:Add, Text, vstatusText wrap xs r1, Clicking through and waiting for something ab

		Gui, TravelLog:Font, s8
		Gui, TravelLog:Add, Text, vHelpText r2, XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	    ;Gui, TravelLog:Add, Button, Default w80, OK

		; Gui, TravelLog:Add, Text, vdebugText, XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

		Gui, TravelLog:Show, NoActivate x10 y10
	}

	Debug(var) {
		FormatTime, time,, hh:mm:ss
		GuiControl TravelLog:Text, debugText, % time . " " . var
	}

	SetNavigatingToSelectWorld() {
	    log.Travel("Navigating to select world")
		GuiControl, TravelLog:Text, statusText, Navigating to Select World menu
	}

	SetWaitingForSelectWorld() {
	    log.Travel("Waiting for select world")
		GuiControl, TravelLog:Text, statusText, Waiting for Select World menu
	}

	SetSelectingWorld() {
	    log.Travel("Selecting world")
		GuiControl, TravelLog:Text, statusText, Selecting destination
	}

	SetWaitingForTravelConfirmation() {
	    log.Travel("Waiting for travel confirmation")
		GuiControl, TravelLog:Text, statusText, Waiting for travel confirmation menu
	}

	SetAcceptingTravel() {
	    log.Travel("Accepting travel")
		GuiControl, TravelLog:Text, statusText, Confirming the travel
	}

	SetTravelingTo(dest) {
	    log.Travel("Traveling to " . dest)
		GuiControl, TravelLog:Text, statusText, Traveling to %dest%
	}

	SetConfirmingDataCenterArrival() {
	    log.Travel("Confirming data center arrival")
		GuiControl, TravelLog:Text, statusText, Confirming Data Center arrival
	}

	SetConnectingToDataCenter() {
	    log.Travel("Connecting to data center")
		GuiControl, TravelLog:Text, statusText, Connecting to Data Center
	}

	On(dc) {
		GuiControl TravelLog:Text, travelText, % "On " . dc
		GuiControl, TravelLog:Text, statusText,
		GuiControl TravelLog:Text, helpText, Press CTRL + SHIFT + ALT + P`nto start travel
	}

	StartTravel(from, to) {
	    log.Travel("Start travel from " . from . " to " . to)
		GuiControl, TravelLog:Text, travelText, % from . " -> " . to
		GuiControl, TravelLog:Text, helpText, Press CTRL + SHIFT + ALT + O`nto return mouse control and stop travel
		Gui, TravelLog:Show, NoActivate x10 y10
	}

	Show() {
		Gui, TravelLog:Show, NoActivate x10 y10
	}

	Hide() {
		Gui, TravelLog:Hide
	}

	Toggle(flag) {
		if (flag) {
			this.Show()
		} else {
			this.Hide()
		}
	}
}
