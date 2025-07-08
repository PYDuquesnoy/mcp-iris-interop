/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.JMSMessage Extends %External.Messaging.Message
{

/// JMS queue/topic name
Property destination As %String [ Required ];

/// Message type: Text or Bytes
Property type As %String [ Required ];

/// Message body for type Text
Property textBody As %String(MAXLEN = "");

/// Message body for type Bytes
Property bytesBody As %GlobalBinaryStream;

/// Message properties
Property properties As list Of %External.Messaging.JMSMessageProperty;

}
