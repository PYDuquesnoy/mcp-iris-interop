/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This adapter is for connecting to IBM WebSphere MQ.
Class EnsLib.MQSeries.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.MQSeries.CommonAdapter) [ ClassType = "", ProcedureBlock, System = 4 ]
{

Property %Queue As %Net.MQSend [ Internal ];

Method OnInit() As %Status
{
	Return ##class(EnsLib.MQSeries.CommonAdapter)$this.OnInit()
}

/// Sends an MQ Series message.  Note that pBody can be either a simple datatype (string) or a character stream
Method SendMessage(pBody As %String, pMsgId As %String = "") As %Status
{
	Set tSC=$$$OK
	try {
		If ..%initQueueNeeded {
			Set ..%Queue = $$$NULLOREF
			Set tSC = ..InitQueue()
			If $$$ISERR(tSC) Quit	;this will lead to an alert if alert on error is true
			Set ..%initQueueNeeded = 0
		}
		Set tSource=$S($IsObject(pBody)&&pBody.%Extends("%AbstractStream"):$G(pBody.Attributes("Source"),$G(pBody.Attributes("Filename"))),1:"")
		$$$catTRACE("protocol","Sending MQ Series Message with length="_$S($IsObject(pBody):pBody.Size,1:$L(pBody))_" and MsgId='"_pMsgId_"'"_$S(""'=tSource:" from source '"_tSource_"'",1:""))
		Set tOK=..%Queue.%SetMsgId(pMsgId)
		If tOK {
			If '$IsObject(pBody) {
				If $L(pBody)<32768 {
					Set tOK=..%Queue.%Put(pBody)
				} Else {
					Do ..%tempStream.Clear()
					Set tSC=..%tempStream.Write(pBody)  Quit:$$$ISERR(tSC)
					Set tOK=..%Queue.%PutStream(..%tempStream)
					Do ..%tempStream.Clear() ; clean up
				}
			} Else {
				If pBody.%Extends("%Library.FileStreamAdaptor") || pBody.%Extends("%Stream.FileBinary") {
					Set tOK=..%Queue.%PutStream(pBody)
				} ElseIf pBody.%Extends("%IO.I.Stream") {
					Do ..%tempStream.Clear()
					Do pBody.CopyReplaceArray(..%tempStream,,,,,,,,.tSC)  Quit:$$$ISERR(tSC)
					Set tOK=..%Queue.%PutStream(..%tempStream)
					Do ..%tempStream.Clear() ; clean up
				} Else {
					Do ..%tempStream.Clear()
					Set tSC=..%tempStream.CopyFrom(pBody)  Quit:$$$ISERR(tSC)
					Set tOK=..%Queue.%PutStream(..%tempStream)
					Do ..%tempStream.Clear() ; clean up
				}
			}
		}
		If 'tOK {
			Set tError=..%Queue.%GetLastError()
			Set tSC=$$$ERROR($$$EnsErrGeneral,"MQSend %Put(length "_$L(pBody)_") failed: "_$S(""=tError:"no error text",1:tError))
		}
	} catch {
		Set tSC=$$$SystemError
	}
	If $$$ISERR(tSC) {
		Set ..%initQueueNeeded = 1
		Set ..BusinessHost.Retry = 1
	}
	Quit tSC
}

Method OnTearDown() As %Status
{
	Return ##class(EnsLib.MQSeries.CommonAdapter)$this.OnTearDown()
}

}
