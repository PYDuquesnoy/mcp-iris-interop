/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.MQTT.Adapter.Inbound Extends (Ens.InboundAdapter, EnsLib.MQTT.Adapter.Common)
{

/// Will throttle by adapter timeout
Parameter SETTINGS = ",-CallInterval,BrokerRetryInterval";

/// Interval to Retry Connecting to the MQTT Broker
Property BrokerRetryInterval As %Numeric(MINVAL = 0.1) [ InitialExpression = 5 ];

/// Property 
Method OnInit() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
	
		#; Call the super class first to create a client
		Set tSC=##class(EnsLib.MQTT.Adapter.Common)$this.OnInit()
		If $$$ISERR(tSC) Quit 
		
		Set ..CallInterval=..BrokerRetryInterval
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

Method OnTask() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#; The topic will be utf8 encoded
	#dim tTopic As %String
	
	#; The message will be utf8 encoded
	#dim tString As %String
	
	#dim tMessage As EnsLib.MQTT.Message
	#dim tIsConnected As %Booolean
	
	Try {
	
		#; Check for connection
		Set tSC=..Client.IsConnected(.tIsConnected)
		If $$$ISERR(tSC) Quit
		
		#; We should attempt to connect until success
		If 'tIsConnected {
		
			#; Now connect
			Set tSC=..Connect()
			If $$$ISERR(tSC) {
			
				$$$LOGSTATUS(tSC)
				
				Set ..Status=$$$Text("Disconnected, Will Retry Connect")
				
				#; Couldn't connect, wait for next call interval to prevent racing
				Set tSC=$$$OK,..BusinessHost.%WaitForNextCallInterval=1
				
				$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"Error")
			
				Quit
			}
			
			#; Now connected
			Set ..Status="Connected"
			
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
			
			#; Finally subscribe to the topic of interest
			Set tSC=..Client.Subscribe(..Topic)
			If $$$ISERR(tSC) Quit
			
			Set ..Status="Subscribed"
		} 
		
		#; Attempt to receive a message (timeout expressed in milliseconds)
		Set tSC=..Client.Receive(.tTopic,.tString,..Timeout*1000)
		If $$$ISERR(tSC) Quit
		
		#; Need to be responsive, let the timeout of the Receive (below) throttle the connection
		Set ..BusinessHost.%WaitForNextCallInterval=0
		
		#; Check for a timeout
		If ..Client.TimedOut Quit
		
		#; Create a string container for the message
		Set tMessage=##class(EnsLib.MQTT.Message).%New(tTopic,tString)
		
		#; Call the business host
		Set tSC=..BusinessHost.ProcessInput(tMessage)
		If $$$ISERR(tSC) Quit
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	If $$$ISERR(tSC) Set ..BusinessHost.%WaitForNextCallInterval=1
	
	Quit tSC
}

}
