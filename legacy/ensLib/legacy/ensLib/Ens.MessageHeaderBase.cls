/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator %occInclude

Class Ens.MessageHeaderBase Extends Ens.Util.BitmapPurge [ Abstract, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Specifies if it is request or response
Property Type As Ens.DataType.MessageType;

/// Priority of the message
Property Priority As Ens.DataType.MessagePriority;

/// Invocation type of the message - Queue or InProc
Property Invocation As Ens.DataType.MessageInvocation [ InitialExpression = {$$$eMessageInvocationQueue} ];

/// Time the message was created
Property TimeCreated As Ens.DataType.UTC;

/// Last time the message status changed
Property TimeProcessed As Ens.DataType.UTC;

/// Integer code denoting the current status of processing of this message
Property Status As Ens.DataType.MessageStatus [ InitialExpression = {$$$eMessageStatusCreated} ];

/// Does ErrorStatus contain an error status?
Property IsError As %Boolean [ InitialExpression = 0 ];

/// Error status if IsError is set to true
Property ErrorStatus As %Status [ InitialExpression = {$$$OK} ];

/// Id of the corresponding request or response
Property CorrespondingMessageId As %Integer;

/// Id of the original request that launched the current session. Used for tracing messages
Property SessionId As %Integer;

/// Config name of the business host that created this message or that this message is responding to
Property SourceConfigName As %String(MAXLEN = 128);

/// Config name of the business host this message is sent to
Property TargetConfigName As %String(MAXLEN = 128);

/// The business type of the source
Property SourceBusinessType As Ens.DataType.MessageBusinessType [ InitialExpression = 0 ];

/// The business type of the target
Property TargetBusinessType As Ens.DataType.MessageBusinessType [ InitialExpression = 0 ];

/// Id of the business process that sent this message or that 
Property BusinessProcessId As %Integer;

/// Queue name to which this message should be sent
Property TargetQueueName As %String(MAXLEN = 128);

/// Queue name where responses to this message should be sent
Property ReturnQueueName As %String(MAXLEN = 128);

/// The ClassName of the message body
Property MessageBodyClassName As %String(MAXLEN = 220);

/// Id of the message body
Property MessageBodyId As %String(COLLATION = "EXACT", MAXLEN = "");

/// Description of the message
Property Description As %String(MAXLEN = "");

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// Identifier of a multi-server session that this message's session is part of
Property SuperSession As %String(MAXLEN = 300);

/// Message original, resent, or MsgBank resent
Property Resent As %String(VALUELIST = ",,r,b");

}
