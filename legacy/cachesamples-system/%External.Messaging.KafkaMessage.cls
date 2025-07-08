/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Kafka message
Class %External.Messaging.KafkaMessage Extends %External.Messaging.Message
{

/// Message topic
Property topic As %String(MAXLEN = 1000);

/// Message value as string
/// If the value exceeds maximum length of IRIS string, encode/decode the string from binaryValue using UTF8. 
Property value As %String(MAXLEN = "");

/// Optional message value key
Property key As %String(MAXLEN = 1000);

/// Binary message value
/// Do not set property "value" when binaryValue is used
Property binaryValue As %Stream.GlobalBinary(%JSONINCLUDE = "NONE");

}
