global GLOBAL_HOST := new IpAddr(124, 150, 157, 190)

global AETHER_HOST := new IpAddr(204, 2, 29, 6)
global CRYSTAL_HOST := new IpAddr(204, 2, 29, 8)
global DYNAMIS_HOST := new IpAddr(204, 2, 29, 9)
global PRIMAL_HOST := new IpAddr(204, 2, 29, 7)

global MAX_KEEP_ALIVE_DELAY = 30*1000


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

	static TRAVEL_COMPLETE := 0 
	static TRAVEL_INFO := 1
	static WORLDLIST := 2
	static RETURN_HOME := 2
	static CONNECTED_TO_DC := 4

	__New() {
		this.PacketProcessors := {(Events.TRAVEL_COMPLETE): ConstSizePacket(365)
			, (Events.TRAVEL_INFO): ConstSizePacket(342)
;			, (Events.WORLDLIST): 
			, (Events.RETURN_HOME): new RangeSizePacket(607, 680)
			, (Events.CONNECTED_TO_DC): new DelayAfterLastPacket(3000, new BigPacket(1500)) }
	}
	
	Process(packet) {
		for index, processor in this.PacketProcessors {
			processor.Process(packet)
		}
	}
	
	WaitFor(event) {
		processor := this.PacketProcessors[event]
		processor.Reset()
		while(!processor.IsSet()) {
			Sleep, 1000
		}
	}

	debug() {
		str := "L:" . this.PacketProcessors.Length()
		for index, processor in this.PacketProcessors {
			str := str . "[" . index . ":" . processor.IsSet() . "]"
		}
		return str
	}
}

ConstSizePacket(size) {
	return new RangeSizePacket(size, size)
}


class RangeSizePacket {
	__New(min, max) {
		this.min := min
		this.max := max
	}
	
	Process(packet) {
		if (packet.GetLen() >= this.min && packet.GetLen() <= this.max) {
			this.active := 1
		}
	}
	
	Reset() {
		this.active := 0
	}
	
	IsSet() {
		return this.active == 1
	}
}


class ConstSizePacket {
	__New(size) {
		this.size := size
	}

	Process(packet) {
		if (packet.GetLen() == this.size) {
			this.active := 1
		}
	}
	
	Reset() {
		this.active := 0
	}
	
	IsSet() {
		return this.active == 1
	}
}

class BigPacket {

	__New(minSize) {
		this.minSize := minSize
	}
	
	Process(packet) {
		if (packet.GetLen() >= this.minSize) {
			this.active := 1
		}
	}
	
	Reset() {
		this.active := 0
	}
	
	IsSet() {
		return this.active == 1
	}
}

class DelayAfterLastPacket {

	__New(delay, other) {
		this.other := other
		this.delay := delay
		this.lastPacket := -1
	}
	
	Process(packet) {
		this.other.Reset()
		this.other.Process(packet)
		if (this.other.IsSet()) {
			this.lastPacket := A_TickCount
		}
	}
	
	Reset() {
		this.lastPacket := -1
	}
	
	IsSet() {
		return this.lastPacket != -1 && this.lastPacket + this.delay < A_TickCount
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
				travelLog.Debug("On " + area.Name)
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
