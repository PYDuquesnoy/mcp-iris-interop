/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// MQ Series Message wrapper
Class EnsLib.MQSeries.Message Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Contains the message body as a string unless the body is too long, or unless the Adapter's ContentStreamClassname property was set to always use BodyStream instead
Property Body As %String(MAXLEN = "");

/// Contains the message body as a stream if property Body is empty
Property BodyStream As %RegisteredObject;

Property MessageId As %String(MAXLEN = 128);

Property Source As %String(MAXLEN = "");

Property BodySize As %Integer [ Calculated ];

Method BodySizeGet() As %Integer
{
	Quit $S($L(..Body):$L(..Body), $IsObject(..BodyStream):..BodyStream.Size, 1:0)
}

}
