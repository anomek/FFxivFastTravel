; global GLOBAL_HOST := new IpAddr(124, 150, 157, 190)
global GLOBAL_HOST := new IpAddr(119, 252, 36, 135)

global AETHER_HOST := new IpAddr(204, 2, 29, 6)
global CRYSTAL_HOST := new IpAddr(204, 2, 29, 8)
global DYNAMIS_HOST := new IpAddr(204, 2, 29, 9)
global PRIMAL_HOST := new IpAddr(204, 2, 29, 7)

global MAX_KEEP_ALIVE_DELAY = 30*1000

#Include  detectionconditions.ahk

CreateDetector(areas) {
	static detector
	detector := new CDetector(areas)
	SetTimer, PcapDispatch, 500
	return detector

	PcapDispatch:
	detector.Dispatch()
	return
}

class IpAddr {

	__New(a, b, c, d) {
		this.addr := [a, b, c, d]
	}

	Str() {
		str := ""
		for i, part in this.addr {
			if (str != "") {
				str := str . "."
			}
			str := str . part
		}
		return str
	}

	Int() {
		val := 0
		for i, part in this.addr {
			val := val + (part << ((i-1)*8))
		}
		return val
	}

}

IpAddrFromInt(val) {
    return new IpAddr(val & 0xff, (val >> 8) & 0xff, (val >> 16) & 0xff, (val >> 24))
}


class CArea {

	__New(name, addr) {
		this.Name := name
		this.Addr := addr
		this.LastSeen := 0
	}

	Update() {
		this.LastSeen := A_TickCount
	}
}

class Events {

    static DUMMY := 5
	static TRAVEL_COMPLETE := 0 
	static TRAVEL_INFO := 1
	static WORLDLIST := 2
	static RETURN_HOME := 2
	static CONNECTED_TO_DC := 4

	__New() {
		this.PacketProcessors := {(Events.DUMMY): PacketReceived()
		    , (Events.TRAVEL_COMPLETE): Any(Filtered(ConstSizePacket(365), PacketReceived())
		                                    , Filtered(FromAddr(GLOBAL_HOST), NoPacketsReceivedFor(7000))
		                                    , Filtered(Not(FromAddr(GLOBAL_HOST)), PacketReceived()))
			, (Events.TRAVEL_INFO):     Filtered(ConstSizePacket(342), PacketReceived())
;			, (Events.WORLDLIST): 
			, (Events.RETURN_HOME):     Filtered(BigPacket(1000), PacketReceived())
			, (Events.CONNECTED_TO_DC): Filtered(BigPacket(1500), NoPacketsReceivedFor(3000)) }
		this.processor := 0
	}
	
	Process(packet) {
	    log.Packet("Received packet (addr=" . IpAddrFromInt(packet.GetSrcIpAddress()).Str()  . ", size=" . packet.GetLen() . ")")
	    if (this.processor != 0) {
            log.Conditions("Processin packet: " . this.processorEvent)
	        this.processor.Process(packet)
	    }
	}
	
	WaitFor(event) {
	    log.Travel("Waiting for event " . event)
		this.processor := this.PacketProcessors[event]
		this.processorEvent := event
		this.processor.Reset()
		while(!this.processor.IsSet()) {
			Sleep, 1000
		}
		this.processor := 0
	}

	debug() {
		str := "L:" . this.PacketProcessors.Length()
		for index, processor in this.PacketProcessors {
			str := str . "[" . index . ":" . processor.IsSet() . "]"
		}
		return str
	}
}

class CDetector {

	__New(areas) {
		this.areas := areas
		filter := "src host " . GLOBAL_HOST.Str()
		for i, area in this.areas {
			filter := filter . " or src host " . area.Addr.Str()
		}

		pcap_init()
		this.pcaps := pcap_findalldevs().open_all()
		this.pcaps.set_filter(filter)
		this.Events := new Events()
	}

	Dispatch() {
		start := A_TickCount
		i := 0
		while ((packet := this.pcaps.next()) != 0) {
			this.Apply(packet)
			i++
		}

		time := (A_TickCount - start) / 1000
	;	travelLog.Debug("Dispatch " . time . "s items: " . i)
	}
	
	WaitForEvent(event) {
		this.events.WaitFor(event)
	}

	Apply(packet) {
		; travelLog.Debug("Packet " . packet.GetLen())
		this.events.Process(packet)
		
		for i, area in this.areas {
			addr := packet.GetSrcIpAddress()
			if (addr == area.Addr.Int()) {
				area.Update()
				travelLog.Debug("On " . area.Name)
			}
		}
	}

	GetCurrentArea() {
		lastSeen := 0

		for i, area in this.areas {
			if (!lastSeen || lastSeen.LastSeen < area.LastSeen) {
				lastSeen := area
			}
		}

		if (lastSeen.LastSeen > A_TickCount - MAX_KEEP_ALIVE_DELAY) {
			return lastSeen
		}
	}

	Close() {
		this.pcaps.Close()
	}
}
