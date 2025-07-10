/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.MQTT.Message Extends Ens.StringContainer
{

/// This contains the topic to which the MQTT message pertains
Property Topic As %String;

Method %OnNew(pTopic As %String = "", pMessage As %String = "") As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tMessage As EnsLib.MQTT.Message
	
	Try {
		Set tSC=##super(pMessage)
		If $$$ISERR(tSC) Quit
		
		Set ..Topic=pTopic
	} Catch (e) {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

Storage Default
{
<Data name="MessageDefaultData">
<Subscript>"Message"</Subscript>
<Value name="1">
<Value>Topic</Value>
</Value>
</Data>
<DefaultData>MessageDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
