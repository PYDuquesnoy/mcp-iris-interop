/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.RabbitMQClient Extends Client
{

/// Creates an exchange with a name, type, and its attributes
Method CreateExchange(exchangeName As %String, exchangeType As %String, durable As %Boolean, autoDelete As %Boolean) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.createExchange(exchangeName, exchangeType, durable, autoDelete)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Delete an exchange with the name
Method DeleteExchange(exchangeName As %String) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.deleteExchange(exchangeName)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Create a queue
Method CreateQueue(queueName As %String, durable As %Boolean, exclusive As %Boolean, autoDetect As %Boolean) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..jclient.createQueue(queueName, durable, exclusive, autoDetect)
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

/// Binds a queue to an exchange with the given bindingKeys, formatted as a comma-separated list.<br> 
/// If there is a comma in a binding key, escape it using the backslash character: '\,'.
/// Backslash characters can be escaped using another backslash character: '\\'.
/// Do not include a space after the comma, or the space will be included in the binding key.<br><br>
/// For example, if you wanted to bind the queue to the exchange with keys:
/// <ul>
/// <li>keynumber1</li>
/// <li>key,number,2</li>
/// <li>key\number\3</li>
/// </ul>
/// Then the contents of the bindingKeys argument would be: <br><br>
/// keynumber1,key\,number\,2,key\\number\\3
Method BindQueue(queueName As %String, exchangeName As %String, bindingKeys As %String) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.bindQueue(queueName, exchangeName, bindingKeys)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Test if the current connection is open
Method IsConnectionOpen() As %Boolean
{
    Quit ..jclient.isConnectionOpen()
}

/// Close the current connection and channel
Method CloseConnection() As %Status
{
    Set sc = $$$OK
    Try {
        Do ..jclient.close()
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Create and set a new broker connection, picking the first available address from the addresses.
/// Future reconnection attempts will pick a random accessible address from the provided list.
/// Called for connection failover
/// addresses  - array of strings of form "host[:port],..."
Method CreateNewConnection(addresses As %String)
{
    Set sc = $$$OK
    Try {
        Do ..jclient.createNewConnection(addresses)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

}
