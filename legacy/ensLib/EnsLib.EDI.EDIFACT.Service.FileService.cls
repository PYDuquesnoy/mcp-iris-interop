/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.EDIFACT.Service.FileService Extends EnsLib.EDI.EDIFACT.Service.Standard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

/// ConfigName(s) of the operations or processes to which reply messages should be forwarded.
Property ReplyTargetConfigNames As %String(MAXLEN = 1000);

Parameter SETTINGS = "ReplyTargetConfigNames::selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Parameter OpenTimeout As %Numeric = 5;

Parameter ReadTimeout As %Numeric = 1;

Method OnInit() As %Status
{
	Set tSC=##super()  Quit:$$$ISERR(tSC) tSC
	Set (..%Parser.StartTimeout,..%Parser.ReadTimeout)=..#ReadTimeout
	If $$$XOR(""=..ReplyTargetConfigNames,"Never"=..%ApplicationReplyMode) {
		If ""=..ReplyTargetConfigNames { $$$LOGWARNING("No Reply Target Config Name configured for ApplicationReplyMode '"_..%ApplicationReplyMode_"'") }
		Else { $$$LOGWARNING("Reply Target ConfigName(s) '"_..ReplyTargetConfigNames_"' configured for ApplicationReplyMode '"_..%ApplicationReplyMode_"'") }
	}
	Quit $$$OK
}

Method OnProcessInput(pFileStream As %CharacterStream, Output pOutput As %RegisteredObject) As %Status
{
	Set tInputFilename=$tr(pFileStream.Filename,"/","\"), tInputFilename=$p(tInputFilename,"\",$l(tInputFilename,"\")) 
	$$$sysTRACE("Got File "_tInputFilename)
	
	Set tIOStream=##class(%IO.FileStream).%New()  $$$ASSERT($IsObject(tIOStream))
	Do tIOStream.Open(pFileStream.Filename,,..#OpenTimeout,,.tSC)  Quit:$$$ISERR(tSC) tSC

	Do ..%Parser.Reset()

	While 'tIOStream.AtEnd { ; Loop over docs in the file
		Set tSC1=..%Parser.ParseIOStream(tIOStream)
		Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		 // Quit on fatal errors only
		Quit:$$$StatusEquals(tSC1,$$$EnsErrGeneral,$$$EnsEDIEDIFACTInvalidSegmentTerminator,$$$EnsEDIEDIFACTExpectedSegment,$$$EnsEDIEDIFACTUnexpectedEOD,$$$EnsEDIEDIFACTInvalidSegmentName,$$$EnsEDIEDIFACTBadBINLength,$$$EnsEDIEDIFACTUnexpectedEODBinary)
	}
	Do ..%Parser.Reset() ; release the file
	Quit tSC
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
