/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.Service.FileService Extends EnsLib.EDI.X12.Service.Standard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

/// ConfigName(s) of the operations or processes to which reply (i.e. TA1 &amp; 997) messages should be forwarded.
Property ReplyTargetConfigNames As %String(MAXLEN = 1000);

Parameter SETTINGS = "ReplyTargetConfigNames:Acknowledgement:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Parameter OpenTimeout As %Numeric = 5;

Parameter ReadTimeout As %Numeric = 1;

Method OnInit() As %Status
{
	Set tSC=##super()  Quit:$$$ISERR(tSC) tSC
	Set (..%Parser.StartTimeout,..%Parser.ReadTimeout)=..#ReadTimeout
	If $$$XOR(""=..ReplyTargetConfigNames,"Never"=..ReplyMode) {
		If ""=..ReplyTargetConfigNames { $$$LOGWARNING("No Reply Target Config Name configured for ReplyMode '"_..ReplyMode_"'") }
		Else { $$$LOGWARNING("Reply Target ConfigName(s) '"_..ReplyTargetConfigNames_"' configured for ReplyMode '"_..ReplyMode_"'") }
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
		Set tSC1=..%Parser.ParseFramedIOStream(tIOStream,,1,,..DefRepSep,..DefCompSep,..DefSegTerm)
		Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		#; !!! Quit on fatal errors only
		Quit:$$$StatusEquals(tSC1,$$$EnsErrGeneral,$$$EnsEDIX12InvalidSegmentTerminator,$$$EnsEDIX12ISATruncated,$$$EnsEDIX12ExpectedSegment,$$$EnsEDIX12UnexpectedEOD,$$$EnsEDIX12InvalidSegmentName,$$$EnsEDIX12BadBINLength,$$$EnsEDIX12UnexpectedEODBinary)
	}
	Do ..%Parser.Reset() ; release the file
	Quit tSC
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document = {$$$NULLOREF}) As %Status
{
	#dim tSC As %Status = $$$OK
	
	Do {
		Quit:'$IsObject(pReplyDocument)
		If ""=..ReplyTargetConfigNames {
			If ""=pReplyDocument.%Id() {
				$$$sysTRACE("Reply not sent because no Reply Target Config Name is configured")
				Quit
			}
			$$$sysTRACE("Reply /"_pReplyDocument.%Id()_" not sent because no Reply Target Config Name is configured")
			#; Delete reply since not sending - this document hasn't been saved yet, but its child Group has
			Set tChild=$$$NULLOREF
			For {
				Set tChild=pReplyDocument.NextChild(tChild)  Quit:tChild=$$$NULLOREF
				Set tChildID = tChild.getId()
				Set tSC1 =##class(EnsLib.EDI.X12.Document).%DeleteId(tChildID)
				If $$$ISERR(tSC1) {
					Set tSC = $$$ADDSC(tSC,tSC1)
				}
			}

		} Else {
			Set pReplyDocument.IsMutable=0
			For iTarget=1:1:$L(..ReplyTargetConfigNames, ",") {
				Set tOneTarget=$ZStrip($P(..ReplyTargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
				Set tSC1=..SendRequestAsync(tOneTarget,pReplyDocument)
				Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
			}
		}
	} While 0
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
