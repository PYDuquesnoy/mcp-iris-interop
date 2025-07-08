/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.MQRecv">Using MQ</a>.</p>
/// The 
/// <b>MQRecv</b> class is used to get a message from a queue.&nbsp;
/// <br>
Class %Net.MQRecv Extends %Net.abstractMQ [ System = 3 ]
{

/// MQ type
Property qtype As %Integer [ InitialExpression = 0, Internal ];

/// Message Selection Options: Message Id
Property SelectMessageId As %String;

/// Message Selection Options: Correlation Id
Property SelectCorrelationId As %String;

/// The <b>%Get</b> method reads from the queue specified in the %Init call.&nbsp;
/// The method takes one argument, the timeout in milliseconds.&nbsp; The timeout
/// refers to the time required to contact the server.&nbsp; <b>%Get</b> is
/// non-blocking (returns immediately whether or not there is a message on
/// the queue).
/// <p>If&nbsp; <b>%Get</b> gives a return code of 0, there was a failure or
/// timeout.&nbsp; The return string is empty.&nbsp; If&nbsp; <b>%Get</b> returns
/// 1, the call was successful.&nbsp; The return string is empty or contains
/// a message depending on what the queue contained.
/// <br>
Method %Get(ByRef Message As %String, timeout As %Integer = 0) As %Boolean
{
 If (..mDesc = -1) {
	 w "Invalid Q",!
	Quit 0
 }
 
 //set the message descriptor GET options
 s rc = $ZF(-5, ..mDllid, ..MQMsgDescSetID, ..mDesc, ..CharSetId, ..SelectMessageId, ..SelectCorrelationId, ..ReplyQMgrName, ..ReplyQName, ..ApplIdentityData, ..PutApplType)
 // get the message
 set Message=$ZF(-5, ..mDllid, ..MQGetID, ..mDesc, timeout, ..Syncpoint)

 if (Message '= "") {
	//update the message options
	s ..MessageId = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#MessageId)
	s ..CorrelationId = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#CorrelationId)
	s ..ReplyQMgrName = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#ReplyQMgrName)
	s ..ReplyQName = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#ReplyQName)
	s ..ApplIdentityData = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#ApplIdentityData)
	//get the integer portions
	s data = $ZF(-5, ..mDllid, ..MQMsgDescIID, ..mDesc, 1, 2)
	s ..CharSetId = $p(data,",",1)
	s ..PutApplType = $p(data,",",2)
	Q $$$OK
 }
 QUIT 0
}

/// Identical to <b>%Get</b> except the queue message, if any, is returned in a file character stream object.
/// <p>Data is read from the queue into a memory buffer, and the entire message written to the file
/// of the character stream object.
/// <br>
Method %GetStream(stream As %Stream, timeout As %Integer = 0) As %Boolean
{
 If (..mDesc = -1) {
	w "Invalid Q",!
	Quit 0
 }
 s file = stream.FilenameGet()	
 If file="" {
	w "Stream not initialized",!
	Q 0
 }
 //set the message descriptor GET options
 s rc = $ZF(-5, ..mDllid, ..MQMsgDescSetID, ..mDesc, ..CharSetId, ..SelectMessageId, ..SelectCorrelationId, ..ReplyQMgrName, ..ReplyQName, ..ApplIdentityData, ..PutApplType)
 // get the message
 s result = $ZF(-5, ..mDllid, ..MQGetStreamID, ..mDesc, timeout, ..Syncpoint, file)
 // now update the stream object
 Set sc=stream.LinkToFile(file)
 if result {
	//update the message options
	s ..MessageId = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#MessageId)
	s ..CorrelationId = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#CorrelationId)
	s ..ReplyQMgrName = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#ReplyQMgrName)
	s ..ReplyQName = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#ReplyQName)
	s ..ApplIdentityData = $ZF(-5, ..mDllid, ..MQMsgDescID, ..mDesc, ..#ApplIdentityData)
	//get the integer portions
	s data = $ZF(-5, ..mDllid, ..MQMsgDescIID, ..mDesc, 1, 2)
	s ..CharSetId = $p(data,",",1)
	s ..PutApplType = $p(data,",",2)
	Q $$$OK
 }
 QUIT 0
}

}
