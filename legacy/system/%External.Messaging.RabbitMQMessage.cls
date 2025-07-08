/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// RabbitMQ message content and properties
Class %External.Messaging.RabbitMQMessage Extends %External.Messaging.Message
{

/// The exchange to which this message should be published
Property exchange As %String(MAXLEN = 100);

/// The routing key to publish with this message
Property routingKey As %String(MAXLEN = 100);

/// The content of the message, stored in a binary stream. 
/// Content should be encoded in the preferred scheme before
/// writing to the stream, and decoded after reading if necessary.<br><br>
/// For example, to encode using UTF-8, then call
/// $ZCONVERT(text, "O", "UTF8") and write the result to this stream.
Property encodedContent As %Stream.GlobalBinary(%JSONINCLUDE = "NONE");

/// Message content type
Property contentType As %String(MAXLEN = 100);

/// Message content encoding
/// Only "UTF-8" is supported
Property contentEncoding As %String(MAXLEN = 100);

/// This will be converted to a map from String to Object in Java,
/// and attached to the message as the "headers" property
Property headers As array Of %String(MAXLEN = "");

/// 2 indicates persistent, and 1 indicates transient
Property deliveryMode As %Integer(MAXVAL = 2, MINVAL = 1);

/// Message priority
Property priority As %Integer;

/// Message correlation Id
Property correlationId As %String(MAXLEN = 1000);

/// Message reply to
Property replyTo As %String(MAXLEN = 100);

/// Message expriation
Property expiration As %String(MAXLEN = 100);

/// Message Id
Property messageId As %String(MAXLEN = 1000);

/// Message timestamp
Property timestamp As %TimeStamp;

/// Message type
Property type As %String(MAXLEN = 100);

/// Message user Id
Property userId As %String(MAXLEN = 1000);

/// Message app Id
Property appId As %String(MAXLEN = 1000);

/// Cluster Id
Property clusterId As %String(MAXLEN = 1000);

/// Set binary content
Method SetContent(content As %Binary)
{
    Do ..encodedContent.Write(content)
}

/// Encode string content as UTF-8
Method SetEncodedContent(content As %String)
{
    Set ..contentEncoding = "UTF-8"
    Do ..encodedContent.Write($ZCONVERT(content, "O", "UTF8"))
}

}
