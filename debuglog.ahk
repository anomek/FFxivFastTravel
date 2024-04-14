global log = new CDebugLog()

class CDebugLog {

    __New() {
        FormatTime, time,, yyyy-MM-dd
        this.Folder := A_AppData . "\FFxivFastTravel\logs"
		if (!FileExist(this.Folder)) {
			FileCreateDir, % this.Folder
		}
        this.File := FileOpen(this.Folder . "\debuglog-" . time . ".log", "a")
        this.Global("Application started, ver: " . version)
    }

    GetFolder() {
        return this.Folder
    }

    Packet(text) {
        this._Log("PACKET", text)
    }

    Conditions(text) {
        this._Log("CONDITIONS", text)
    }

    AppInput(text) {
        this._Log("APP_INPUT", text)
    }

    UserInput(text) {
        this._Log("USER_INPUT", text)
    }

    Settings(text) {
        this._Log("SETTINGS", text)
    }

    Travel(text) {
        this._Log("TRAVEL", text)
    }

    Global(text) {
        this._Log("GLOBAL", text)
    }

    _Log(type, text) {
        FormatTime, time,, yyyy-MM-dd HH:mm:ss
        this.File.WriteLine(time . "`t" . type . "`t" . text)
        temp := this.File.__Handle
    }

    Close() {
        this.Global("Application Exists")
        this.File.Close()
    }
}