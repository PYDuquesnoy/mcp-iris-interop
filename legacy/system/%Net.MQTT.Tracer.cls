/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %Net.MQTT)

/// This class allows tracing to performed of the calls made within the paho-c library. One instantiates an instance
/// of the tracer and attaches an instance of %Net.MQTT.Logger by setting the Logger property. The Tracer class then
/// delegates log requests to the Logger class. If you don't provide a Logger instance then the default implementation
/// uses this class (which is itself a logger) to perform the logging with a default implementation that just writes to the console.
Class %Net.MQTT.Tracer Extends %Net.MQTT.Logger
{

/// Logger delegate, initially is self
Property Logger As %Net.MQTT.Logger [ InitialExpression = {$this} ];

/// This is the trace level required
Property TraceLevel As %Integer [ InitialExpression = {$$$MQTTCLIENTTRACEFATAL} ];

/// Start tracing
Method Start() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
	
		#; Call the library entry point
		Set tRetval=$ZF(-6,$$$IrisMQTTLibrary,$$$ClientSetTraceObject,"",$listbuild($$$objOrefToInt($this)))
        
        #; Test for error condition
        If $List(tRetval,1)'=0 Set tSC=..DecodeError(tRetval) Quit
       
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Stop tracing
Method Stop() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		#; Call the library entry point
		Set tRetval=$ZF(-6,$$$IrisMQTTLibrary,$$$ClientSetTraceObject,"",$listbuild($$$objOrefToInt($$$NULLOREF)))
        
        #; Test for error condition
        If $List(tRetval,1)'=0 Set tSC=..DecodeError(tRetval) Quit
       
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Set the trace level (see %Net.MQTT.inc for appropriate values)
Method TraceLevelSet(level As %Integer) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
	
		If level<$$$MQTTCLIENTTRACEMAXIMUM {
			Set tSC=$$$ERROR($$$MQTTParameterMustBe,"level",$$$Text("legal trace level value")) Quit
		}
		
		If level>$$$MQTTCLIENTTRACEFATAL {
			Set tSC=$$$ERROR($$$MQTTParameterMustBe,"level",$$$Text("legal trace level value")) Quit
		}
		
		#; Call the library entry point
		Set tRetval=$ZF(-6,$$$IrisMQTTLibrary,$$$ClientSetTraceLevel,"",$listbuild(level))
        
        #; Test for error condition
        If $List(tRetval,1)'=0 Set tSC=..DecodeError(tRetval) Quit
        
        #; Set the property too
        Set i%TraceLevel=level
       
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

/// Error Text Domain
Parameter DOMAIN = "%ObjectErrors";

/// Property setter, attach a delegate
Method LoggerSet(logger As %Net.MQTT.Logger) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		#; Must be an instance of %Net.MQTT.Logger
		If 'logger.%Extends("%Net.MQTT.Logger") {
			Set tSC=$$$ERROR($$$MQTTParameterMustBe,"logger",$$$Text("subclass of %Net.MQTT.Logger")) Quit
		}
		
		Set i%Logger=logger
       
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Private, Decode an error reported by the library and form status
Method DecodeError(list As %String) As %Status [ Private ]
{
	Set tType=$List(list,2),tCode=$List(list,3),tMsgTxt=$List(list,4)
	If tType=$$$ErrorTypeNone {
		Set tTypeTxt=$$$Text("None")
	} elseif tType=$$$ErrorTypeApp {
		Set tTypeTxt=$$$Text("MQTT Client")
	} elseif tType=$$$ErrorTypeCallin {
		Set tTypeTxt=$$$Text("IRIS Callin")
	} elseif tType=$$$ErrorTypeMQTT {
		Set tTypeTxt=$$$Text("MQTT Library")
	} elseif tType=$$$ErrorTypeUnknown {
		Set tTypeTxt="Unknown Error Type"
	} else {
		Set tTypeTxt=$$$Text("Unexpected")
	}
	
	Quit $$$ERROR($$$MQTTCLIENT,tCode,tTypeTxt,tMsgTxt)
}

/// Dispatch to delegate (could be $this)
Method Trace(level As %Integer, message As %String) [ Final, Internal ]
{
	Do $method(i%Logger,"Log",level,message)
}

/// Minimal implementation, normally would delegate
Method Log(level As %Integer, message As %String)
{
	Write level," ",message,!
}

Method %OnNew() As %Status
{
	#; Set the initial trace level
	Quit ..TraceLevelSet(i%TraceLevel)
}

}
