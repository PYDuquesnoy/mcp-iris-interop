/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.JMSClient Extends Client
{

/// Create a JMS queue 
Method CreateQueue(queueName As %String) As %Status
{
   Set sc = $$$OK
	Try {
		Do ..jclient.createQueue(queueName)
	} Catch (ex){
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Create a JMS topic
Method CreateTopic(topicName As %String) As %Status
{
   Set sc = $$$OK
	Try {
		Do ..jclient.createTopic(topicName)
	} Catch (ex){
		Set sc = ex.AsStatus()
	}
	Quit sc
}

}
