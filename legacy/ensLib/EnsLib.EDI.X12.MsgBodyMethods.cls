/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsEDIX12, %systemInclude)

Class EnsLib.EDI.X12.MsgBodyMethods Extends Ens.Util.MessageBodyMethods [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

Method %GetContentType() As %String
{
	Quit "text/html"
}

Method %ShowContents(pZenOutput As %Boolean = 0)
{
	If pZenOutput {
		If (%response.ContentType="application/json") {
			Do ..WriteNoJSONFormat($this)
		} Else {
			Do ..OutputHTMLZen()
		}
	}
	Else {
		Do ..OutputHTML()
	}
}

Method %ShowContentsHead(pZenOutput As %Boolean = 0)
{
	/* Styles for EDI segment display */

	If '$g(%donotoverwritestyles) {
		&html<<LINK REL="stylesheet" TYPE="text/css" HREF="csputils.css" TITLE="Standard Style" >>
	}

	&html<
<style>

/* EDI Document Table */
TABLE.EDIDocumentTable {
		border: black solid 1px; font-size: 0.8em;
		background: #DDDDFF;
		margin-left: 10px; margin-right: 10px;
		width: 10;
	}

TD.EDIDocumentTableExpandor {
		background: #D0D0FF;
		border-bottom: gray solid 1px;
		padding: 2px;
	}

TD.EDIDocumentTableSegnum {
		background: white;
		font-weight: bold;
		text-align: right;
		border-bottom: gray solid 1px;
		padding: 2px;
	}

TD.EDIDocumentTableSegid {
		background: white;
		border-bottom: gray solid 1px;
		border-right: gray solid 1px;
		padding: 2px;
	}

TD.EDIDocumentTableSegname {
		background: #D0D0FF;
		text-align: center;
		font-weight: bold;
		border-bottom: gray solid 1px;
		padding: 2px;
	}

/* -- Segment single-row Table */
TABLE.EDISegmentsTable {
		background: white;
		font-size: 0.9em;
		border-bottom: gray solid 1px;
	}

TD.EDISegmentsTableValue {
		background: white;
		padding: 2px;
	}

TD.EDISegmentsTableSeparator {
		background: white;
		padding: 2px;
	}

TD.EDISegmentsTableEmptyfield {
		background: white;
		padding: 2px;
	}
</style>
	>
}

Method chooseDocType(Output pDocDesc) As %String
{
	Set tDocType=..DocType
	If ""'=tDocType && ##class(EnsLib.EDI.X12.Schema).ElementExists("DS:"_tDocType) {
		Set pDocDesc="X12 Document"
	} Else {
		Set tDocType=""
	}
	Quit tDocType
}

ClassMethod %DrawHTMLTable(pObj As %RegisteredObject, ByRef pID As %String) As %Status
{
	&html<<div>>
	Do pObj.%ShowContentsHead()
	Do pObj.OutputHTML()
	&html<</div><br/>X12 document object properties:>
	Quit ##class(%CSP.Util.AutoFormDynamic).DrawHTMLTable(pObj, .pID)
}

/// This method is called by the Management Portal to display a class-specific content editor
ClassMethod %DrawHTMLForm(pObj As %RegisteredObject, ByRef pID As %String, pActionURL As %String = "", ByRef pButtons As %CSP.Util.FormButton, pTarget As %String = "") As %Status
{
	&html<<br/>X12 document content:<br/>
	<div><textarea name="%XCONT" rows="20" cols="100" style="border: 1px black solid;">>
	Do pObj.OutputToDevice(pObj.Separators_$C(13,10))
	&html<</textarea></div></br>X12 document object properties:>
	Set pID("XCONT")=""
	Quit ##class(%CSP.Util.AutoFormDynamic).DrawHTMLForm(pObj, .pID, pActionURL, .pButtons, pTarget)
}

/// This method is called by the Management Portal to 
/// display a class-specific content editor.<br>
ClassMethod %ProcessSubmit(pRequest As %CSP.Request, ByRef pID As %String = "", Output pErrorMsg As %String) As %RegisteredObject
{
	#; apply %request changes to old stored object or to new object if no old ID
	Set pErrorMsg=""
	Set tOldObj=##class(%CSP.Util.AutoFormDynamic).ProcessSubmit(pRequest, .pID, .pErrorMsg, 0)
	Quit:'$IsObject(tOldObj) $$$NULLOREF
	If ""'=tOldObj.%Id() {
		Kill %objlasterror
		Set tParentId = tOldObj.ParentId ; cloning deletes ParentId - store value temporarily so it can be reset later
		Set tOldObj=tOldObj.%ConstructClone() ; clone it so as not to save changes to the original
		If '$IsObject(tOldObj) {
			Set tSC=$G(%objlasterror,$$$OK)
			Set pErrorMsg=pErrorMsg_" Failed to clone edited X12 document object"
			Set:$$$ISERR(tSC) pErrorMsg=pErrorMsg_" - Status "_$$$StatusDisplayString(tSC)
			Quit $$$NULLOREF
		}
		Set tOldObj.ParentId = tParentId
		Set tSource=tOldObj.Source_$C(13)_"; Edited copy of "_$G(pID(1))
		#; get rid of old content
		Do tOldObj.Clear()  Set tOldObj.Source=tSource
	}

	Set tData=$G(pRequest.Data("$IDXCONT",1))
	If $Case(tOldObj.Separators,"":0,$$$X12DefSeparators:0,$$$X12DefSeparators_$$$X12DefSegTerminator:0,:1) {
		Set tComponentSeparator = $$$COMSEP(tOldObj.Separators)
		Set tRepetitionSeparator = $$$REPSEP(tOldObj.Separators)
		Set tSegmentTerminator = $$$SEGTERM(tOldObj.Separators)
	}
	If $IsObject(tData) {
		Set tTempObj=..ImportFromLibraryStream(tData,.tSC,,,tRepetitionSeparator,tComponentSeparator,tSegmentTerminator)
	} Else {
		Set tTempObj=..ImportFromString(tData,.tSC,,,tRepetitionSeparator,tComponentSeparator,tSegmentTerminator)
	}
	If $$$ISERR(tSC)||'$IsObject(tTempObj) {
		If '$IsObject(tTempObj) {
			Set pErrorMsg=pErrorMsg_" Failed to import X12 document text"
			Set:$$$ISERR(tSC) pErrorMsg=pErrorMsg_" - Status "_$$$StatusDisplayString(tSC)
			Quit $$$NULLOREF
		}
		Set pErrorMsg=pErrorMsg_$$$StatusDisplayString(tSC)
	}
	Set tOldObj.Separators=tTempObj.Separators
	Set tSC=tOldObj.CopyValues(tTempObj,"()","()","set","")
	If $$$ISERR(tSC) {
		Set pErrorMsg=pErrorMsg_"Failed to update X12 document content - Status "_" "_$$$StatusDisplayString(tSC)
		Quit $$$NULLOREF
	}
	Set:$$$ISOK(tSC) tSC=tOldObj.%Save() ;  needed to prevent TempObj's segment data from dying with it.
	Quit tOldObj
}

/// This method is used to provide the Statistics Site Dimension if not already set
Method GetStatsDimension() As %String
{
	#dim tDimension As %String = $$$StatsDefaultDimension
	Try { Set tDimension = ..Name } Catch {}
	Quit tDimension
}

}
