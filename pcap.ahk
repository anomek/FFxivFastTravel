
global errbuff
VarSetCapacity(errbuff, 512)

class CPacket {
	__New(header, data) {
		this.header := header
		this.data := data
	}

	GetLen() {
		return NumGet(this.header+0, 12, "UInt")
	}

	GetSrcIpAddress() {
		; 14 is the size of assumed eth packet
		return NumGet(this.data+0, 14+12, "UInt")
	}
}

class CPcap {
	__New(pcapif) {
		this.pcapif := pcapif
		this.pcap := pcap_open(pcapif.name)
		pcap_setnonblock(this.pcap)
	}

	set_filter(filter) {
		pcap_setfilter(this.pcap, filter)
	}

	next() {
		return pcap_next(this.pcap)
	}

	close() {
		pcap_close(this.pcap)
	}
}

class CPcaps {
	__New(pcaps) {
		this.pcaps := pcaps
		this.next_i := 0
	}

	set_filter(filter) {
		for i, pcap in this.pcaps {
			pcap.set_filter(filter)
		}
	}

	next() {
		for i, pcap in this.pcaps {
			if (i >= this.next_i) {
				n := pcap.next()
				if (n != 0) {
					this.next_i := i
					return n
				}
			}
		}
		this.next_i := 0
		return 0
	}

	close() {
		for i, pcap in this.pcaps {
			pcap.close()
		}
	}
}


; int pcap_init(unsigned int opts, char *errbuf);
pcap_init() {
	hModule:= DllCall("LoadLibrary", "Str", A_WinDir . "\System32\Npcap\wpcap.dll", "Ptr")
	if (ErrorLevel || !hModule) {
		MsgBox % A_WinDir . "\System32\Npcap\wpcap.dll"
		if (A_LastError == 126) {
			MsgBox Cannot find npcap library. Download and install npcap from https://npcap.com
			ExitApp
		}
		MsgBox % "Can't load library pcap. A_LastError: " . A_LastError . " ErrorLevel: " . ErrorLevel
		return false
	}

	result := DllCall("wpcap.dll\pcap_init"
			, "UInt", 0
			, "Str", errbuff
			, "Int")
	if (result := 0 || ErrorLevel) {
		LogError("pcap_init", result, errbuff)
	}
	return true
}

; int pcap_findalldevs_ex(char *source, struct pcap_rmtauth *auth, pcap_if_t **alldevs, char * errbuf)
; void pcap_freealldevs(pcap_if_t *alldevsp)
pcap_findalldevs() {
	alldevsp := 0
	result := DllCall("wpcap.dll\pcap_findalldevs_ex"
			,"AStr", "rpcap://"	; char *source
			,"Ptr", 0			; struct pcap_rmtauth *auth
			,"Ptr*", alldevsp	; pcap_if_t **alldevsp
			,"Str", errbuff		; char *errbuf
			,"Int")				; int
	if (result == 0) {
		ret := new pcap_if(alldevsp)

		DllCall("wpcap.dll\pcap_freealldevs"
			, "Ptr", alldevsp) 	; pcap_if_t *alldevsp
		if (ErrorLevel != 0) {
			LogError("pcap_freealldevs", 0, errbuff)
		}
		return ret
	} else {
		LogError("pcap_findalldevs_ex", result, errbuff)
		return 0
	}
}

; int pcap_compile (pcap_t *p, struct bpf_program *fp, char *str, int optimize, bpf_u_int32 netmask)
; int pcap_setfilter (pcap_t *p, struct bpf_program *fp)
; void pcap_freecode(struct bpf_program *fp);
pcap_setfilter(pcap, filter) {
	VarSetCapacity(fp, (A_PtrSize*2), 0)
	result := DllCall("wpcap.dll\pcap_compile"
			, "Ptr", pcap		; pcap_t *p
			, "Ptr", &fp		; struct bpf_program *fp
			, "AStr", filter	; char *str
			, "Int", 0			; int optimize
			, "UInt", 0xffffffff ; bpf_u_int32 netmask
			, "Int")			; int

	if (result != 0) {
		LogError("pcap_compile", result, pcap)
		return
	}

	result := DllCall("wpcap.dll\pcap_setfilter"
			, "Ptr", pcap		; pcap_t *p
			, "Ptr", &fp		; struct bpf_program *fp
			, "Int")			; int
	if (result != 0) {
		LogError("pcap_setfilter", result, pcap)
	}


	DllCall("wpcap.dll\pcap_freecode"
			, "Ptr", &fp)		; struct bpf_program *fp
	if (ErrorLevel != 0) {
		LogError("pcap_freecode", 0, errbuff)
	}

}

; char* pcap_geterr(pcap_t *p)
pcap_geterr(pcap) {
	result := DllCall("wpcap.dll\pcap_geterr"
		, "Ptr", pcap		; pcap_t *p
		, "AStr")			; char*

	if (ErrorLevel != 0) {
		LogError("pcap_geterr", result, errbuff)
	} else {
		return result
	}
}

; pcap_t* pcap_open(const char *source, int snaplen, int flags, int read_timeout, struct pcap_rmtauth *auth, char *errbuf)
pcap_open(source) {
	result := DllCall("wpcap.dll\pcap_open"
		, "AStr", source	; const char *source
		, "Int", 100		; int snaplen
		, "Int", 0			; int flags
		, "Int", 1			; int read_timeout
		, "Ptr", 0			; struct pcap_rmtauth *auth
		, "Str", errbuff	; char *errbuf
		, "Ptr")			; pcap_t*
	if (!result) {
		LogError("pcap_open", result, errbuff)
	} else {
		return result
	}
}

; void pcap_close(pcap_t *p);
pcap_close(pcap) {
	DllCall("wpcap.dll\pcap_close"
		, "Ptr", pcap)		; pcap_t *p

	if (ErrorLevel != 0) {
		LogError("pcap_geterr", 0, errbuff)
	}
}

;int pcap_next_ex(pcap_t *p, struct pcap_pkthdr **pkt_header, const u_char **pkt_data);
pcap_next(pcap) {
	header := 0
	data := 0
	result := DllCall("wpcap.dll\pcap_next_ex"
		, "Ptr", pcap		; pcap_t *p
		, "Ptr*", header 	; pcap_pkthdr **pkt_header
		, "Ptr*", data		; const u_char **pkt_data
		, "Int")			; int

	if (result == 0) {
		return 0
	} else if (result := 1) {
		return new CPacket(header, data)
	} else {
		LogError("pcap_next_ex", result, pcap)
	}
}

; int pcap_setnonblock(pcap_t *p, int nonblock, char *errbuf)
pcap_setnonblock(pcap) {
	result := DllCall("wpcap.dll\pcap_setnonblock"
		, "Ptr", pcap		; pcap_t *p
		, "Int", 1			; int nonblock
		, "Str", errbuff	; char *errbuf
		, "Int")			; int
	if (result != 0) {
		LogError("pcap_setnonblock", result, errbuff)
	}
}

LogError(funcName, result, pcapOrErrBuff) {
	errLvl := ErrorLevel
	lastError := A_LastError
	if (pcapOrErrBuff == 0) {
		errstr := ""
	} if (pcapOrErrBuff == errbuff) {
		errstr := StrGet(errbuff, "CP0")
	} else {
		errstr := pcap_geterr(pcapOrErrBuff)
	}
	MsgBox % "Error during DllCall. Method " . funcName . " returned " . result . ". ErrorLevel: " . errLvl . ". A_LastError: " . lastError . ". " . errstr
}

; struct pcap_if {
;     struct pcap_if *next;
;     char *name;
;     char *description;
;     struct pcap_addr *addresses;
;     u_int flags;
; };
class pcap_if {

	__New(pcap_if_ptr) {
		this.pcap_if_ptr := pcap_if_ptr
		pnext := NumGet(pcap_if_ptr + 0, 0, "Ptr")
		if (pnext != 0) {
			this.next := new pcap_if(pnext)
		} else {
			this.next := 0
		}
		pname := NumGet(pcap_if_ptr + 0, A_PtrSize, "Ptr")
		this.name := StrGet(pname, "CP0")
		pdescription := NumGet(pcap_if_ptr + 0, A_PtrSize*2, "Ptr")
		this.description := StrGet(pdescription, "CP0")
		this.paddresses := NumGet(pcap_if_ptr + 0, A_PtrSize*3, "Ptr")
		this.flags := NumGet(pcap_if_ptr + 0, A_PtrSize*4, "UInt")
	}

	open() {
		return new CPcap(this)
	}

	open_all() {
		all := []
		iterator := this
		debugstr := ""
		while(iterator != 0) {
			pcap := iterator.open()
			all.Push(pcap)
			iterator := iterator.next
		}
		return new CPcaps(all)
	}
}