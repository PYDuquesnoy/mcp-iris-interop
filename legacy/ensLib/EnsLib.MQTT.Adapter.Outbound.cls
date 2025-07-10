/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.MQTT.Adapter.Outbound Extends (Ens.OutboundAdapter, EnsLib.MQTT.Adapter.Common) [ System = 4 ]
{

Method OnInit() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
	
		#; Call the super class first to create a client
		Set tSC=##class(EnsLib.MQTT.Adapter.Common)$this.OnInit()
		If $$$ISERR(tSC) Quit
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Send a message
Method Send(topic As %String = "", message As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tIsConnected As %Booolean
	
	Try {
	
		#; Check for connection
		Set tSC=..Client.IsConnected(.tIsConnected)
		If $$$ISERR(tSC) Quit
		
		#; We should attempt to connect
		If 'tIsConnected Set tSC=..Connect()
		If $$$ISERR(tSC) Quit
			
		#; If topic is not specified, then pick up topic from the adapter setting
		If topic="" Set topic=..Topic
		
		#; Note timeout on client is millseconds
		Set tSC=..Client.Publish(topic,message,..Retained,..Timeout*1000)
		If $$$ISERR(tSC) Quit
		
		#; Check for a timeout
		If ..Client.TimedOut Set tSC=$$$ERROR($$$MQTTSendTimedOut) Quit
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

}
