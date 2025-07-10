/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.XML.Service.FileService Extends EnsLib.EDI.XML.Service.Standard [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

/// ConfigName(s) of the operations or processes to which reply messages should be forwarded.
Property ReplyTargetConfigNames As %String(MAXLEN = 1000);

Parameter SETTINGS = "ReplyTargetConfigNames::selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Method OnProcessInput(pInput As %Stream.Object, pOutput As %RegisteredObject) As %Status
{
	Set tSC=$$$OK
	If pInput.%Extends("%FileBinaryStream") {
		$$$sysTRACE("creating document from XML file "_pInput.Filename)
		Set tDocIn=##class(EnsLib.EDI.XML.Document).%New(pInput.Filename)
	} Else {
		$$$sysTRACE("creating document from XML file stream "_pInput.Filename_" with TranslateTable='"_pInput.TranslateTable_"'")
		Set tDocIn=##class(EnsLib.EDI.XML.Document).%New(pInput)
	}
	if tDocIn="" Quit %objlasterror
	Quit ..standardOnProcessInput(tDocIn)
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document = {$$$NULLOREF}) As %Status
{
	If ""=..ReplyTargetConfigNames {
		$$$sysTRACE("Reply "_$S($IsObject(pReplyDocument):"/"_pReplyDocument.%Id(),1:"")_" not sent because no Reply Target Config Name is configured")
		Quit $$$OK
	}
	Set pReplyDocument.IsMutable=0
	Set tSC=$$$OK  For iTarget=1:1:$L(..ReplyTargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..ReplyTargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
		Set tSC1=..SendRequestAsync(tOneTarget,pReplyDocument) Quit:$$$ISERR(tSC)
		Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	}
	Quit tSC
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("ReplyTargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

}
