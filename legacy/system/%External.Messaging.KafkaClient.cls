/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.KafkaClient Extends Client
{

/// Applicable to Kafka. <br>
/// Updates the Consumer Configurations using the passed in JSON string. <br> 
/// Only pass in configuratiton properties that are applicable to the Kafka Consumer.
/// For possible consumer configuration properties, please refer to https://kafka.apache.org/documentation/#consumerconfigs.
/// Sample settings: "{\"key.deserializer\":\"org.apache.kafka.common.serialization.StringDeserializer\"}"
Method UpdateConsumerConfig(consumerConfig As %String) As %Status
{
	Set sc = $$$OK
	Try {
		Do ..jclient.updateConsumerConfig(consumerConfig)
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Quit sc
}

/// Applicable to Kafka. <br>
/// Updates the Producer Configurations using the passed in JSON string. <br> 
/// Only pass in configuratiton properties that are applicable to the Kafka Producer.
/// For possible producer configuration properties, please refer to https://kafka.apache.org/documentation/#producerconfigs.
/// Sample settings: "{\"key.serializer\":\"org.apache.kafka.common.serialization.StringSerializer\"}"
Method UpdateProducerConfig(producerConfig As %String) As %Status
{
	Set sc = $$$OK
    try {
        Do ..jclient.updateProducerConfig(producerConfig)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Applicable to Kafka. <br>
/// Updates the Admin Client Configurations using the passed in JSON string. <br> 
/// Only pass in configuratiton properties that are applicable to the Kafka's Admin Client.
/// For possilbe admin client configuration properties, please refer to https://kafka.apache.org/documentation/#adminclientconfigs.
Method UpdateAdminConfig(adminConfig As %String) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.updateAdminConfig(adminConfig)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Applicable to Kafka. <br>
/// Create a Kafka Topic with the name <br> 
Method CreateTopic(topicName As %String, numberOfPartitions As %Integer, replicationFactor As %TinyInt) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.createTopic(topicName, numberOfPartitions, replicationFactor)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

/// Delete a Kafka Topic with the name <br> 
Method DeleteTopic(topicName As %String) As %Status
{
	Set sc = $$$OK
    Try {
        Do ..jclient.deleteTopic(topicName)
    } Catch (ex) {
        Set sc = ex.AsStatus()
    }
	Quit sc
}

}
