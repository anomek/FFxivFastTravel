;@Ahk2Exe-AddResource images/aether10.png, #1
;@Ahk2Exe-AddResource images/aether15.png, #2
;@Ahk2Exe-AddResource images/crystal10.png, #3
;@Ahk2Exe-AddResource images/crystal15.png, #4
;@Ahk2Exe-AddResource images/dynamis10.png, #5
;@Ahk2Exe-AddResource images/dynamis15.png, #6
;@Ahk2Exe-AddResource images/ok10.png, #7
;@Ahk2Exe-AddResource images/ok15.png, #8
;@Ahk2Exe-AddResource images/ox10.png, #9
;@Ahk2Exe-AddResource images/ox15.png, #10
;@Ahk2Exe-AddResource images/primal10.png, #11
;@Ahk2Exe-AddResource images/primal15.png, #12
;@Ahk2Exe-AddResource images/proceed10.png, #13
;@Ahk2Exe-AddResource images/proceed15.png, #14
;@Ahk2Exe-AddResource images/selectdatacenter10.png, #15
;@Ahk2Exe-AddResource images/selectdatacenter15.png, #16
;@Ahk2Exe-AddResource images/traveled10.png, #17
;@Ahk2Exe-AddResource images/traveled15.png, #18


global scales := [10, 15]

imagePrototypes := [new ImageProto("aether", 1)
		, new ImageProto("crystal", 3)
		, new ImageProto("dynamis", 5)
		, new ImageProto("ok", 7)
        , new ImageProto("ox", 9)
		, new ImageProto("primal", 11)
		, new ImageProto("proceed", 13)
		, new ImageProto("selectdatacenter", 15)
		, new ImageProto("traveled", 17)]

if A_IsCompiled {
	global images := new CompiledImages(ImagePrototypes)
} else {
	global images := new ScriptImages(ImagePrototypes)
}


class ImageProto {

	__New(name, index) {
			this.Name := name
			this.Index := index
	}

	_Path(scale) {
		return "images/" . this.Name . scale . ".png"
	}

	LoadFromFile(scale) {
		return LoadPicture(this._Path(scale))
	}

	LoadFromResource(hModule, offset) {
		return LoadImageFromDll(hModule, this.Index + offset)
	}
}

class ImagesBase {

	__Get(key) {
		return this.Get(key)
	}

	Get(key) {
		return this.Imgs[key]
	}
}

class ScriptImages extends ImagesBase {
	__New(prototypes) {
		this.Imgs := []
		for i, proto in prototypes {
			for j, scale in scales {
				this.Imgs[proto.Name . scale] := proto.LoadFromFile(scale)
			}
		}
	}
}

class CompiledImages extends ImagesBase {

	__New(prototypes) {
		this.Imgs := []
	    GdiStartup()
		hModule := DllCall("GetModuleHandle", "Str", A_ScriptFullPath, "Ptr")
		;hModule := DllCall("LoadLibrary", "Str", "fasttravel.exe", "Ptr")
		for i, proto in prototypes {
			for j, scale in Scales {
				this.Imgs[proto.Name . scale] := proto.LoadFromResource(hModule, j - 1)
			}
		}
	}
}


GdiStartup() {
	VarSetCapacity(si, 16, 0), si := Chr(1)
	pToken := 0
	DllCall("gdiplus\GdiplusStartup", "uint*", pToken, "uint", &si, "uint", 0)
}

LoadImageFromDll(hModule, index) {
	hResourceInfo := DllCall("FindResource", "Ptr", hModule, "Int", index, "Int", 10, "Ptr")
	size := DllCall("SizeofResource", "Ptr", hModule, "Ptr", hResourceInfo, "UInt")
	hResource := DllCall("LoadResource", "Ptr", hModule, "Ptr", hResourceInfo, "Ptr")
	pBytes := DllCall("LockResource", "Ptr", hResource, "Ptr")
	stream := DllCall("Shlwapi\SHCreateMemStream", "Ptr", pBytes, "UInt", size, "Ptr")
	pBitmap := 0
	result := DllCall("gdiplus\GdipCreateBitmapFromStream", "Ptr", stream, "Ptr*", pBitmap, "Int")
	hBitmap := 0
	result := DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "Int", 0, "Int")
	return hBitmap
}