/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %Net.MQTT

Class EnsLib.MQTT.Adapter.Common Extends (Ens.Adapter, %Net.MQTT.Logger) [ Abstract, System = 4 ]
{

/// Domain for $$$Text()
Parameter DOMAIN = "EnsMQTT";

/// Configurable settings
Parameter SETTINGS = "CleanSession:MQTT,ClientID:MQTT,ConnectTimeout:MQTT,CredentialsName:MQTT:credentialsSelector,KeepAlive:MQTT,LWTTopic:MQTT,LWTMessage:MQTT,QOS:MQTT,Retained:MQTT,SSLConfigName:MQTT:sslConfigSelector,Timeout:MQTT,Topic:MQTT,Trace:MQTT,TraceLevel:MQTT,Url:MQTT";

// --------------------------------------------------------------------------------------------

// Properties influenced by Settings

// --------------------------------------------------------------------------------------------

/// This determines if the session to the broker will use a clean session.
Property CleanSession As %Boolean [ InitialExpression = 1 ];

/// This is the string which identifies this client to the broker. It must be ascii encoded.<p>
/// For compatibility the recommended length of this identifier is 23 characters or less but note that certain server implementations permit more.<p>
/// If not specified the client will create a unique id in the form '73BDD334-83D4-11EA-8229'.
Property ClientID As %String(MAXLEN = "");

/// This is the connect timeout. Connecting to a busy server may take some time and this timeout can be used 
/// to avoid a premature connection failure.
Property ConnectTimeout As %Integer [ InitialExpression = 30 ];

/// This is the ID name of the set of credentials values to be used to access the MQTT broker.
/// The Username and password defined in your Credentials item must be ascii encoded. Not required
/// if the broker is insecured.
Property CredentialsName As %String;

/// The client will send keepalive messages to the broker according to the specified interval.
Property KeepAlive As %Integer [ InitialExpression = {$$$KeepAliveInterval} ];

/// This the LWT (Last Will And Testament) Topic. If specified must be ascii encoded.
/// If the client disconnects due to an network error, the LWTMessage will be delivered
/// to subscribers to the LWTTopic.
Property LWTTopic As %String;

/// This is the LWT (Last Will And Testament) message. If specified must be ascii encoded.
Property LWTMessage As %String;

/// This determines the quality of service required, $$$QOSWaitForDelivery or $$$QOSFireAndForget
Property QOS As %Integer [ InitialExpression = {$$$QOSFireAndForget} ];

/// This is the flag that indicates to the broker whether the message should be retained
/// by the broker
Property Retained As %Boolean [ InitialExpression = 0 ];

/// This is the ID name of the SSL configuration that you wish to be used to communicate with the broker.
/// Only used if in fact SSL communication is required.
Property SSLConfigName As %String;

/// This is the timeout expressed in seconds to wait to send (with ack ) or receive a message
Property Timeout As %Numeric(MINVAL = 0.1) [ InitialExpression = 1 ];

/// This is the topic name of the topic to which you wish to publish or subscribe.
/// The topic must be ascii encoded
Property Topic As %String;

/// This enables or disables the MQTT tracing facility
Property Trace As %Boolean [ InitialExpression = 0 ];

/// This is the trace level for the MQTT library. Set this to log the required detail of trace information
/// See %Net.MQTT.inc for legal values
Property TraceLevel As %Integer [ InitialExpression = {$$$MQTTCLIENTTRACEFATAL} ];

/// This is the url of the broker to which you wish to communicate. The scheme is either 'tcp' or 'ssl' followed by the<p>
/// domain name and port delimited by a ':', for example, 'tcp://BIGBADAPPLE.local:1883'. Typically ssl enabled end points<p> 
/// are configured with a port of 8883 but this is not mandatory. The url must be ascii encoded.
Property Url As %String(MAXLEN = "");

// --------------------------------------------------------------------------------------------

// Private Properties

// --------------------------------------------------------------------------------------------

/// This is the instance of the MQTT client that is used to communicate with the broker.
Property Client As %Net.MQTT.Client [ Internal ];

/// This is the instance of the Tracer which calls the Logger to record trace information
Property Tracer As %Net.MQTT.Tracer [ Internal ];

/// This is the internal status of the adapter
Property Status As %String [ InitialExpression = "Created" ];

// --------------------------------------------------------------------------------------------

// Private implementation 

// --------------------------------------------------------------------------------------------

Method OnInit() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try { 
		#; Create an instance of the Tracer
		Kill %objlasterror
		Set ..Tracer=##class(%Net.MQTT.Tracer).%New()
		If '$IsObject(..Tracer) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass)) Quit
		
		#; Start logger if required
		If ..Trace {
		
			#; Attach the tracer to this object for logging
			Set ..Tracer.Logger = $this
			
			#; Set the level
			Set ..Tracer.TraceLevel = ..TraceLevel
			
			#; Start the trace
			Set tSC=..Tracer.Start()
			If $$$ISERR(tSC) Quit	
		}
		
		#; Create an instance of the MQTT client, configuring as required
		Kill %objlasterror
		Set ..Client=##class(%Net.MQTT.Client).%New(..Url,..ClientID,..QOS,..KeepAlive,..LWTTopic,..LWTMessage)
		If '$IsObject(..Client) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Net.MQTT.Client")) Quit
	
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

Method Connect() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tUsername,tPassword As %String = ""
	
	Try {
		If ..CredentialsName'="" {
		
			#; Try and open the named credentials object
			Set tCredentials=##class(Ens.Config.Credentials).%OpenId(..CredentialsName,,.tSC)
			If $$$ISERR(tSC) Quit
			
			#; Fill in the details
			Set tUsername=tCredentials.Username,tPassword=tCredentials.Password
		}
		
		#; Connect passing the configuration name as necessary
		Set tSC=..Client.Connect(tUsername,tPassword,..CleanSession,..ConnectTimeout,..SSLConfigName)
		If $$$ISERR(tSC) Quit
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Simply log the value
Method Log(level As %Integer, message As %String)
{
	$$$LOGINFO("MQTT: "_level_" "_message)
}

/// Setter override for status value
Method StatusSet(value) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
	
		If i%Status=value Quit
		
		Set i%Status=value
		
		$$$LOGINFO(value)
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

}
