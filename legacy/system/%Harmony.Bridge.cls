/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

Class %Harmony.Bridge
{

Parameter OUTBOUNDSEMAPHORE = "harmonyoutbound";

Parameter TCPTIMEOUT = 12;

ClassMethod connect(config As %Library.DynamicObject = {
		{
			"namespace":"USER",
			"host":"127.0.0.1",
			"inbound-port": 55556,
			"outbound-port":55557,
			"inbound-addresses":["harmony.bridge.inbound"],
			"outbound-addresses":["harmony.bridge.outbound"],
			"ping-interval":10
		}
})
{
		// inbound and outbound is from the perspective of Harmony-Vertx, inbound means messages from ISC-IRIS going to Harmony-Vertx.
		// Similarly, inbound-addresses refers to addresses allowed for messages sent from ISC-IRIS to Harmony-Vertx.
	try {
		if $isObject(config) {
			set configArg = config.%ToJSON()
		} else {
			set configArg = config
		}
		if (config.namespace = "") || ($$$UPPER(config.namespace) = $$$UPPER($namespace)) {
			set namespace = $namespace 
		} else {
			set namespace = config.namespace
		}
		do ..logMessage("connect()","starting connect in namespace '"_namespace_"', config() = '"_configArg_"'")
		set success = 0
		job ##class(%Harmony.Bridge).inbound(configArg):namespace:10
		if '$test {
			do ..logMessage("connect()","inbound job failed to start")
		}
		job ##class(%Harmony.Bridge).outbound(configArg):namespace:10
		if '$test {
			do ..logMessage("connect()","outbound job failed to start")
		}
	} catch exception {
		do ..logException("connect()",exception)
		use 0
		write !,"Exception encountered while attempting to connect to Harmony Bridge: "_exception.AsSQLMessage()
	}
}

ClassMethod disconnect()
{
	if $get(^IRIS.TempHarmonyBridge($namespace,"outbound")) = "connected" {
			// Shutdown the outgoing bridge
		set semaphore = $system.Semaphore.%New()
		if semaphore.Open(..#OUTBOUNDSEMAPHORE_($namespace)) {
			do semaphore.Delete()
		}
		set outboundPID = $get(^IRIS.TempHarmonyBridge($namespace,"outbound","pid"))
		kill ^IRIS.TempHarmonyBridge($namespace,"outbound","pid")
		set ^IRIS.TempHarmonyBridge($namespace,"outbound") = "disconnected"
	} else {
		do ..logMessage("disconnect()","oubound bridge not connected in namespace '"_$namespace_"', no action taken.")
	}
	if $get(^IRIS.TempHarmonyBridge($namespace,"inbound")) = "connected" {
			// send external interrupt to shutdown LRS876
			// and the inbound bridge
		
		set inboundPID = $get(^IRIS.TempHarmonyBridge($namespace,"inbound","pid"))
		do $System.Util.SendInterrupt(inboundPID)
		kill ^IRIS.TempHarmonyBridge($namespace,"inbound","pid")
		set ^IRIS.TempHarmonyBridge($namespace,"inbound") = "disconnected"
	} else {
		do ..logMessage("disconnect()","inbound bridge not connected in namespace '"_$namespace_"', no action taken.")
	}
}

ClassMethod outbound(configArg As %Library.String(MAXLEN=""))
{
	try {
		lock +^IRIS.TempHarmonyBridge($namespace,"outbound"):0
		if $test {
			if $extract($get(^IRIS.TempHarmonyBridge($namespace,"outbound")),1,7) = "connect" {
				lock -^IRIS.TempHarmonyBridge($namespace,"outbound")
				$$$ThrowStatus($$$ERROR($$$GeneralError,"outbound bridge already connected or is connecting to another job, aborting!"))
			}
			kill ^IRIS.TempHarmonyBridge($namespace,"outbound")
			set ^IRIS.TempHarmonyBridge($namespace,"outbound") = "connecting"
			lock -^IRIS.TempHarmonyBridge($namespace,"outbound")
		} else {
			do ..logMessage("outbound()","could not lock bridge status global, ^IRIS.TempHarmonyBridge(""outbound""), aborting, check system lock tables.")
			return
		}
		try {
			if '$isObject(configArg) {
				set config = ##class(%Library.DynamicObject).%FromJSON(configArg)
			} else {
				set config = configArg
			}
			set host = config.host
			set port = config."inbound-port"
			set device = "|TCP|" _ port
			set pingInterval = config."ping-interval"
			set ^IRIS.TempHarmonyBridge($namespace,"outbound") = "connected"
			set ^IRIS.TempHarmonyBridge($namespace,"outbound","port") = port
			set ^IRIS.TempHarmonyBridge($namespace,"outbound","pid") = $job
			set ^IRIS.TempHarmonyBridge($namespace,"outbound","connect-time") = $zts
			do $system.Util.SetInterruptEnable(1)
			open device:(host:port:"AdS"::::5):..#TCPTIMEOUT
		} catch exception {
			try { close device } catch {}
			throw exception
		}
		try {
			use device:(::"A-dS"::32767:32767)
			set iterator = config."inbound-addresses".%GetIterator()
			do ..logMessage("outbound()","outbound bridge connected")
			while iterator.%GetNext(.ptr,.address) {
				write ..encodeMessage({"type":"register","address":(address)}),*-3
				do ..logMessage("outbound()","registering bridged address '"_address_"'")
			}
			set semaphore = ..getOutboundSemaphore()
			set lastSent = ""
			for {
				if semaphore.Decrement(1,pingInterval) {
					set messageId = $Order(^ISC.Harmony.OutboundQueue(lastSent),1,message)
					if messageId {
						write message,*-3
						set lastSent = messageId
					}
				} else {
					// send a ping
					// and clean out the trash - kill up to 200 messages from the global
					// should we also check to see if there is an odd incoming message?
					if $order(^ISC.Harmony.OutboundQueue(""),1,firstId) > lastSent {
						set endId = firstId + 200
						if endId > lastSent {
							set endId = lastSent
						}
						for messageId = firstId:1:lastId {
							kill ^ISC.Harmony.OutboundQueue(messageId)
						}
						do ..logMessage("outbound()","Purged messages "_firstId_"-"_lastId_" from the Outbound queue")
					}
				}
			}
			read response:1
		} catch exception {
			if '$find("<OBJECT DISPATCH><EXTERNAL INTERRUPT>",exception.Name) {
				do ..logException("outbound()",exception)
			}
		}
		try {
			set iterator = config."inbound-addresses".%GetIterator()
			while iterator.%GetNext(.ptr,.address) {
				write ..encodeMessage({"type":"unregister","address":(address)}),*-3
				do ..logMessage("outbound()","unregistering bridged address '"_address_"'")
			}
			write *-2
		} catch {}
		close device
		lock +^IRIS.TempHarmonyBridge($namespace,"outbound"):0
		if $test {
			set ^IRIS.TempHarmonyBridge($namespace,"outbound") = "disconnected"
			lock -^IRIS.TempHarmonyBridge($namespace,"outbound")
			do ..logMessage("outbound()","outbound bridge disconnected")
		} else {
			do ..logMessage("outbound()","could not lock bridge status global, ^IRIS.TempHarmonyBridge(<namespace>,""outbound""), check system lock tables.")
		}
	} catch outer {
		do ..logException("outbound()",outer)
	}
	return
}

ClassMethod inbound(configArg As %Library.String(MAXLEN=""))
{
	try {
		lock +^IRIS.TempHarmonyBridge($namespace,"inbound"):10
		if $test {
			if $extract($get(^IRIS.TempHarmonyBridge($namespace,"inbound")),1,7) = "connect" {
				lock -^IRIS.TempHarmonyBridge($namespace,"inbound")
				$$$ThrowStatus($$$ERROR($$$GeneralError,"inbound bridge already connected or is connecting to another job, aborting!"))
			}
			kill ^IRIS.TempHarmonyBridge($namespace,"inbound")
			set ^IRIS.TempHarmonyBridge($namespace,"inbound") = "connecting"
			lock -^IRIS.TempHarmonyBridge($namespace,"inbound")
		} else {
			do ..logMessage("inbound()","could not lock bridge status global, ^IRIS.TempHarmonyBridge(<namespace>,""inbound""), aborting, check system lock tables.")
			return
		}
		try {
			if '$isObject(configArg) {
				set config = ##class(%Library.DynamicObject).%FromJSON(configArg)
			} else {
				set config = configArg
			}
			set host = config.host
			set port = config."outbound-port"
			set device = "|TCP|" _ port
			set pingInterval = config."ping-interval"
			set ^IRIS.TempHarmonyBridge($namespace,"inbound") = "connected"
			set ^IRIS.TempHarmonyBridge($namespace,"inbound","port") = port
			set ^IRIS.TempHarmonyBridge($namespace,"inbound","pid") = $job
			set ^IRIS.TempHarmonyBridge($namespace,"inbound","connect-time") = $zts
			do $system.Util.SetInterruptEnable(1)
			open device:(host:port:"AdS"::::5):..#TCPTIMEOUT
		} catch exception {
			try { close device } catch {}
			throw exception
		}
		try {
			use device:(::"A-dS"::32767:32767)
			set iterator = config."outbound-addresses".%GetIterator()
			do ..logMessage("inbound()","inbound bridge connected")
			while iterator.%GetNext(.ptr,.address) {
				write ..encodeMessage({"type":"register","address":(address)}),*-3
				do ..logMessage("inbound()","registering bridged address '"_address_"'")
			}
			try {
				for counter = 1:1 {
					read response:10
					if $test {
						do ..queueInboundMessage(response)
					} else {
						// probably send a ping?
					}
				}
			} catch exception {
				if exception.Name '= "<EXTERNAL INTERRUPT>" {
					do ..logException("inbound()",exception)
				}
			}
			try {
				set iterator = config."outbound-addresses".%GetIterator()
				do ..logMessage("inbound()","inbound bridge connected")
				while iterator.%GetNext(.ptr,.address) {
					write ..encodeMessage({"type":"unregister","address":(address)}),*-3
					do ..logMessage("inbound()","unregistering bridged address '"_address_"'")
				}
				write *-2
			} catch {}
		} catch {}
		close device
		lock +^IRIS.TempHarmonyBridge($namespace,"outbound"):10
		if $test {
			set ^IRIS.TempHarmonyBridge($namespace,"inbound") = "disconnected"
			lock -^IRIS.TempHarmonyBridge($namespace,"inbound")
		do ..logMessage("inbound()","inbound bridge disconnected")
		} else {
			do ..logMessage("inbound()","could not lock bridge status global, ^IRIS.TempHarmonyBridge(<namespace>,""inbound""), check system lock tables.")
		}
	} catch outer {
		do ..logException("inbound()",outer)
	}
	return
}

ClassMethod queueInboundMessage(message As %Library.String(MAXLEN=""))
{
	set queue= $increment(^ISC.Harmony.InboundQueue)
	set ^ISC.Harmony.InboundQueue(queue) = message
}

ClassMethod encodeMessage(message As %Library.DynamicAbstractObject) As %Library.String(MAXLEN="")
{
	set jsonString = message.%ToJSON()
	return $nconvert($length(jsonString),"U4",1) _ jsonString
}

ClassMethod getOutboundSemaphore() As %SYSTEM.Semaphore
{
	set semaphore = $system.Semaphore.%New()
	if 'semaphore.Open(..#OUTBOUNDSEMAPHORE_($namespace)) {
		do semaphore.Create(..#OUTBOUNDSEMAPHORE_($namespace))
			// Check for queued messages and add them to the semaphore list
		if $data(^ISC.Harmony.OutboundQueue,queued) {
			do semaphore.Increment(queued)
		}
	}
	return semaphore
}

ClassMethod logException(location As %String(MAXLEN=""), exception As %Exception.AbstractException)
{
	set sqlcode = exception.AsSQLCODE()
	set message = exception.AsSQLMessage()
	do ..logMessage(location,"SQLCODE: "_sqlcode_", "_message)
}

ClassMethod logMessage(location As %String(MAXLEN=""), message As %String(MAXLEN=3000))
{
	set ^ISC.Harmony.Log($increment(^ISC.Harmony.Log)) = $zdt($zts,3)_" "_$namespace_":"_location_": "_message
}

}
