/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.SQSClient Extends Client
{

/// Create a queue
Method CreateQueue(queueName As %String, settings As SQSQueueSettings) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..jclient.createQueue(queueName, settings.ToJSON())
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Delete a queue
Method DeleteQueue(queueName As %String) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..jclient.deleteQueue(queueName)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Delete message from queue
Method DeleteMessage(queueName As %String, receiptHandle As %String) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.deleteMessage(queueName, receiptHandle)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

}
