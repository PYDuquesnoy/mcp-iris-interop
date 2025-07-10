/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.XML.Service.TCPFramed Extends (EnsLib.EDI.XML.Service.Standard, EnsLib.TCP.Framed.PassthroughService) [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.TCP.FramedInboundAdapter";

/// Control of Reply handling; options: <br/>
/// - Never : Do not send back any ACK <br/>
/// - Immediate : Send back AckOK or AckNotOK characters reply message immediately upon receipt of the inbound message <br/>
/// - Application : If message passes validation, wait for reply from target config item and forward it back when it arrives <br/>
Property ReplyMode As %String(DISPLAYLIST = ",Never,Immediate,Application", VALUELIST = ",Never,Immed,App") [ InitialExpression = "Immed" ];

/// Format options to apply if we need to output an XML VDoc object as a Stream
Property %VDocFormat As %String;

Parameter SETTINGS = "SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.XML.Service.Standard},ReplyMode,DocSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.EDI.XML.Service.Standard},Validation,-SendAcknowledgement,-SyncCall,-SyncCallTimeout";

Method OnProcessInput(pInput As %Stream.Object, pOutput As %RegisteredObject) As %Status
{
	Set tSC=$$$OK, pOutput = $$$NULLOREF
	$$$sysTRACE("creating document from XML stream")
	Set tDocIn=##class(EnsLib.EDI.XML.Document).%New(pInput)
	If tDocIn="" Quit %objlasterror
	$$$ASSERT($$$IsdefObject(tDocIn) && tDocIn.%IsA("EnsLib.EDI.XML.Document"))
	$$$sysTRACE("Got Document "_tDocIn_" / "_tDocIn.%Id())
	#; get accepted doc, resolve DocType
	Set tSCVal=..resolveAndIndex(tDocIn)
	Set tResponse=$$$NULLOREF
	If $$$ISOK(tSC)&&$$$ISOK(tSCVal)&&(""'=..TargetConfigNames) {
		Set tDocIn.IsMutable=0
		If $Case(..ReplyMode,"Never":1,"Immed":1,:0) {
			$$$SyncCommitSet(tSyncCommit)
			For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
				$$$sysTRACE("Sending XML document "_tDocIn_"/"_tDocIn.%Id()_" from "_tDocIn.Source_" to '"_tOneTarget_"'")
				Set tSC1=..SendRequestAsync(tOneTarget,tDocIn)
				Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
			}
			$$$SyncCommitClear(tSyncCommit)
			If $$$ISOK(tSC) $$$sysTRACE("After async forwarding document "_tDocIn_"/"_tDocIn.%Id())
			If ..ReplyMode'="Never" {
				Set pOutput=..reportReply(tDocIn,,.tSC)
			}
		} Else { ;  Application reply mode
			If 1'=$L(..TargetConfigNames, ",") $$$LOGWARNING("More than one target config name specified for synchronous forwarding: "_..TargetConfigNames)
			$$$sysTRACE("Sending "_tDocIn_"/"_tDocIn.%Id()_" from "_tDocIn.Source_" to '"_..TargetConfigNames_"'")
			Set tSC=..SendRequestSync(..TargetConfigNames,tDocIn,.tResponse) Quit:$$$ISERR(tSC) tSC
			If '$IsObject(tResponse) { ; no reply message
				$$$sysTRACE("Not returning reply because SendRequestSync() of "_tDocIn_"/"_tDocIn.%Id()_" returned with no response object and status: "_$$$StatusDisplayString(tSC))
			} Else { 
				$$$sysTRACE("Returning reply document "_tResponse.%Id()_" ("_tResponse.Name_") received from document "_tDocIn.%Id()_" forwarded to "_..TargetConfigNames)
			}
		}
	} Else { ; not forwarding due to error or no target
		If $Case(..ReplyMode,"Never":0,:1) {
			If $$$ISOK(tSC)&&$$$ISOK(tSCVal) {
			$$$SyncCommitSet(tSyncCommit)
				Set tDocIn.IsMutable=0, tSC=tDocIn.%Save() ; save the document because we're going to reply to it.
			$$$SyncCommitClear(tSyncCommit)
				If $$$ISERR(tSC) {
					$$$LOGERROR("Failed to save document "_tDocIn_" / "_tDocIn.%Id()_" : "_$$$StatusDisplayString(tSC))
				}
			}
			$$$sysTRACE("Returning reply but not forwarding document "_tDocIn_"/"_tDocIn.%Id()_$S($$$ISERR(tSC):" status "_$$$StatusDisplayString(tSC),1:""))
			Set tSC=$$$ADDSC(tSC,tSCVal)
			Set pOutput=..reportReply(tDocIn,,.tSC)
		} Else {
			$$$sysTRACE("Not returning reply for document "_tDocIn_"/"_tDocIn.%Id()_"; ReplyMode="_..ReplyMode_$S($$$ISERR(tSC):" status "_$$$StatusDisplayString(tSC),1:""))
		}
	}
	If $IsObject(tResponse) {
		Set pOutput=..reportReply(tDocIn,tResponse,.tSC)
	}
	Quit tSC
}

Method reportReply(pOriginalDoc As EnsLib.EDI.Document, pReplyCode As %String = "", ByRef pSC As %Status) As EnsLib.EDI.Document
{
	If $IsObject(pReplyCode) {
		Set tReplyDoc=pReplyCode, pSC=$$$OK
		$$$sysTRACE("Reporting reply document "_tReplyDoc_" for document "_pOriginalDoc_$S('$IsObject(pOriginalDoc):"",1:" / "_pOriginalDoc.%Id()))
	} Else {Set tReplyDoc=""}
	If ""'=..SearchTableClass && $IsObject(tReplyDoc) && ..#IndexReplies {
		Set tSCStore=$classmethod(..SearchTableClass,"IndexDoc",tReplyDoc)
		If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for reply document "_tReplyDoc_" / "_tReplyDoc.%Id()_" with DocType='"_tReplyDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
	}
	Quit:((""=tReplyDoc)&&(..ReplyMode'="Immed")) $$$NULLOREF
	If (..ReplyMode="Immed") Quit ##Class(%IO.StringStream).%New($S($$$ISOK(pSC):..AckOKAsChars,1:..AckNotOKAsChars))
	Set tReplyDocStream=##class(%Stream.GlobalBinary).%New()
	Set pSC = tReplyDoc.OutputToLibraryStream(.tReplyDocStream,..%VDocFormat)
	Quit:pSC tReplyDocStream
	Quit ""
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("ReplyTargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	Set tSC = $$$OK
	Try {
		Set:""=..ReplyMode ..ReplyMode="Never"
		Set:(..ReplyMode="Never") ..SendAcknowledgement = 0
		#; No need to convert if not sending back an acknowledgement
		Quit:'..SendAcknowledgement
		#; Convert ACK/NACK settings to characters
		Set ..AckOKAsChars = ..Adapter.AsciiOrHexAsChars(..AckOK)
		Set ..AckNotOKAsChars = ..Adapter.AsciiOrHexAsChars(..AckNotOK)
	} Catch { Set tSC = $$$SystemError}
	Quit tSC
}

}
