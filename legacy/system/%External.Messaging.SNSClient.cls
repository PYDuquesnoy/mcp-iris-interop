/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.SNSClient Extends Client
{

/// Applicable to SNS. <br>
/// Creates a SNS Topic with the name <br> 
/// Output topicARN of created topic
Method CreateTopic(topicName As %String, Output topicARN As %String) As %Status
{
	Set sc = $$$OK
    Try {
        Set topicARN = ..jclient.createTopic(topicName)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Delete topic with topicARN
Method DeleteTopic(topicARN As %String) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.deleteTopic(topicARN)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

}
