; Filters
ConstSizePacket(size) {
	return new SizeFilter(size, size)
}

BigPacket(size) {
    return new SizeFilter(size, 0)
}

FromAddr(addr) {
    return new AddressFilter(addr)
}

Not(inner) {
    return new NotFilter(inner)
}

; Conditions

Any(conditions*) {
    return new OrCondition(conditions)
}

Filtered(filter, condition) {
    return new FilteredCondition(filter, condition)
}

PacketReceived() {
    return new PacketReceivedCondition()
}

NoPacketsReceivedFor(delay) {
    return new NoPacketsReceivedForCondition(delay)
}


; Implementation Filters

class SizeFilter {
	__New(min, max) {
		this.min := min
		this.max := max
	}

	Accept(packet) {
	    log.Conditions("Size filter (min=" . this.min . ", max=" . this.max . ")")
	    if (this.max == 0) {
	        return packet.GetLen() >= this.min
	    }

		return packet.GetLen() >= this.min && packet.GetLen() <= this.max
	}
}

class AddressFilter {
    __New(addr) {
        this.addr := addr
    }

    Accept(packet) {
        log.Conditions("Address filter (addr=" . this.addr . ")")
        return this.addr.Int() == packet.GetSrcIpAddress()
    }
}

class NotFilter {
    __New(inner) {
        this.inner := inner
    }

    Accept(packet) {
        log.Conditions("Not filter")
        return !inner.Accept(packet)
    }
}

; Implementation Conditions

class FilteredCondition {
    __New(filter, subcondition) {
        this.filter := filter
        this.subcondition := subcondition
    }

    Process(packet) {
        if (this.filter.Accept(packet)) {
            log.Conditions("Filter passed")
            this.subcondition.Process(packet)
        }  else {
            log.Conditions("Filter not passed")
        }
    }

    Reset() {
        this.subcondition.Reset()
    }

    IsSet() {
        return this.subcondition.IsSet()
    }
}

class OrCondition {
    __New(conditions) {
        this.conditions := conditions
    }

    Process(packet) {
        for i, condition in this.conditions {
            log.Conditions("Processing or condition " . i)
            condition.Process(packet)
        }
    }

    Reset() {
        for i, condition in this.conditions {
            condition.Reset()
        }
    }

    IsSet() {
        for i, condition in this.conditions {
            if (condition.IsSet()) {
                log.Conditions("Condition is set: " . i)
                return True
            } else {
                log.Conditions("Condition is not set: " . i)
            }
        }
        return False
    }
}


class PacketReceivedCondition {
	__New() {
	}

	Process(packet) {
	    log.Conditions("Packet received")
        this.active := 1
	}

	Reset() {
		this.active := 0
	}

	IsSet() {
		return this.active == 1
	}
}

class NoPacketsReceivedForCondition {

	__New(delay) {
		this.delay := delay
		this.Reset()
	}

	Process(packet) {
        this.lastPacket := A_TickCount
	}

	Reset() {
		this.lastPacket := -1
	}

	IsSet() {
	    log.Conditions("lastPacket=" . this.lastPacket . " delay=" . this.delay . " tickCount=" . A_TickCount)
		return this.lastPacket != -1 && this.lastPacket + this.delay < A_TickCount
	}
}


