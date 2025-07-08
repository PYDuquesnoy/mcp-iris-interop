/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.Client Extends %RegisteredObject [ Language = objectscript ]
{

/// Connection to a Java Gateway
Property gateway As %External.JavaGateway;

/// Remote Java messaging client object 
Property jclient As %Net.Remote.Object;

/// Connect to gateway and instantiate Java messaging client
Method Connect(jclientClass As %String, settings As %String, additionalClasspaths As %String = "") As %Status
{
	Set sc = $$$OK
	Try {
		Set ..gateway = $SYSTEM.external.getJavaGateway()
	
		// Get messaging JAR path
		Set jarDir = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_"/dev/java/lib/1.8")
		Set jarPath = ##class(%Library.File).NormalizeFilename(##class(%External.Gateway).getJarPath("intersystems-messaging"), jarDir)
		Set jarPath = ##class(%Library.File).NormalizeFilenameWithSpaces(jarPath)
		
		Do ..gateway.addToPath(jarPath)
		Do:additionalClasspaths'="" ..gateway.addToPath(additionalClasspaths)

		// Create jclient
		Set ..jclient = ##class(%Net.Remote.Object).%New(..gateway, jclientClass, settings)
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Connects to JMS using the passed in settings JSON string. <br>
ClassMethod CreateJMSClient(settings As %String, Output sc As %Status, additionalClasspaths As %String = "") As JMSClient
{
	Set client = ##class(JMSClient).%New()
	Set sc = client.Connect("com.intersystems.messaging.JMSClient", settings, additionalClasspaths)
	Quit $S($$$ISERR(sc):$$$NULLOREF, 1:client)
}

/// Connects to SNS using the passed in settings JSON string. <br>
ClassMethod CreateSNSClient(settings As %String, Output sc As %Status, additionalClasspaths As %String = "") As SNSClient
{
	Set client = ##class(SNSClient).%New()
	Set sc = client.Connect("com.intersystems.messaging.SNSClient", settings, additionalClasspaths)
	Quit $S($$$ISERR(sc):$$$NULLOREF, 1:client)
}

/// Connects to SQS using the passed in settings JSON string. <br>
ClassMethod CreateSQSClient(settings As %String, Output sc As %Status, additionalClasspaths As %String = "") As SQSClient
{
	Set client = ##class(SQSClient).%New()
	Set sc = client.Connect("com.intersystems.messaging.SQSClient", settings, additionalClasspaths)
	Quit $S($$$ISERR(sc):$$$NULLOREF, 1:client)
}

/// Connects to Kafka using the passed in settings JSON string. <br>
ClassMethod CreateKafkaClient(settings As %String, Output sc As %Status, additionalClasspaths As %String = "") As KafkaClient
{
	Set client = ##class(KafkaClient).%New()
	Set sc = client.Connect("com.intersystems.messaging.KafkaClient", settings, additionalClasspaths)
	Quit $S($$$ISERR(sc):$$$NULLOREF, 1:client)
}

/// Connects to RabbitMQ using the passed in settings JSON string. <br>
ClassMethod CreateRabbitMQClient(settings As %String, Output sc As %Status, additionalClasspaths As %String = "") As RabbitMQClient
{
	Set client = ##class(RabbitMQClient).%New()
	Set sc = client.Connect("com.intersystems.messaging.RabbitMQClient", settings, additionalClasspaths)
	Quit $S($$$ISERR(sc):$$$NULLOREF, 1:client)
}

/// Factory method to create an instance of messaging client.
/// The type of the client is dertermined by the type of the settings class.
/// Supported settings classes are SNSSettings, SQSSettings, KafkaSettings, JMSSettings and RabbitMQSettings.
/// additionalClasspaths: Additional Java class paths needed by the Java Gateway to instantiate the messaging client.
/// If there are multiple paths, pass in a %ListOfDataTypes.
ClassMethod CreateClient(settings As Settings, Output sc As %Status, additionalClasspaths As %String = "") As Client
{
	Set sc = $$$OK
	#Dim client As Client = $$$NULLOREF
	Set className = settings.%ClassName(0)
	If (className="JMSSettings") {
		Set client = ..CreateJMSClient(settings.ToJSON(), .sc, additionalClasspaths)
	}
	Elseif (className="KafkaSettings") {
		Set client = ..CreateKafkaClient(settings.ToJSON(), .sc, additionalClasspaths)
	}
	Elseif (className="RabbitMQSettings") {
		Set client = ..CreateRabbitMQClient(settings.ToJSON(), .sc, additionalClasspaths)
	}
	Elseif (className="SNSSettings") {
		Set client = ..CreateSNSClient(settings.ToJSON(), .sc, additionalClasspaths)
	}
	Elseif (className="SQSSettings") {
		Set client = ..CreateSQSClient(settings.ToJSON(), .sc, additionalClasspaths)
	}
	Quit $S($$$ISERR(sc):$$$NULLOREF, 1:client)
}

/// Applicable to all. <br>
/// Sends a message that is passed in as a parameter, which can be any %External.Messaging.___Message objects. 
Method SendMessage(message As %External.Messaging.Message) As %Status
{
	Set sc = $$$OK
	Try {
		Do ..jclient.sendMessage(message)
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Applicable to all except SNS.
/// Receives a List of Messages.
/// queueOrTopicName: Name of the queue/topic to receive messages from.
/// messages: Output list of received messages(%External.Messaging.___Message objects).
/// settings: Optional attributes in JSON string required by the underlying messaging provider to receive messages.
/// Corresponding settings classes are KafkaReceiveSettings, SQSReceiveSettings, JMSReceiveSettings and RabbitMQReceiveSettings.
Method ReceiveMessage(queueOrTopicName As %String, Output messages As %ListOfObjects, settings As %String = "") As %Status
{
	Set sc = $$$OK
	Try {
		Set messages = ..jclient.receiveMessage(queueOrTopicName, settings)
	} Catch (ex){
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Applicable to all except JMS.
/// settings: JSON string representing attributes required to create the queue/topic.
/// The settings are only required for Kafka, SQS and RabbitMQ.
/// The corresponding settings classes are KafkaTopicSettings, SQSQueueSettings and RabbitMQQueueSettings. 
Method CreateQueueOrTopic(queueOrTopicName As %String, settings As %String = "") As %Status
{
	Set sc = $$$OK
	Try {
		Do ..jclient.createQueueOrTopic(queueOrTopicName, settings)
	} Catch (ex){
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Applicable to all except JMS.
Method DeleteQueueOrTopic(queueOrTopicName As %String) As %Status
{
	Set sc = $$$OK
	Try {
		Do ..jclient.deleteQueueOrTopic(queueOrTopicName)
	} Catch (ex){
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Close connections and release resources
Method Close() As %Status
{
	Set sc = $$$OK
	Try {
		Do:(..jclient '= "") ..jclient.close()
		Do:(..gateway '= "") ..gateway.%Disconnect()
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Quit sc
}

}
