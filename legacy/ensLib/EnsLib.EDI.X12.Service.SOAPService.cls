/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.Service.SOAPService Extends (EnsLib.SOAP.Service, EnsLib.EDI.X12.Service.Standard) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.SOAP.InboundAdapter";

Parameter NAMESPACE = "http://tempuri.org";

Parameter SERVICENAME = "X12Service";

Parameter SETTINGS = "-Framing";

Property DummyLibStreamIn As %Stream.GlobalCharacter;

Property IOStreamIn As %IO.MetaCharacterStream;

Property LibStreamReply As %Stream.GlobalCharacter;

Property IOStreamReply As %IO.MetaCharacterStream;

/// End-Segment marker character(s)
Property SegTerminator As %String [ InitialExpression = {$C(13,10)} ];

/* Override with SOAP.Service version, not X12 Standard version */
/// initialize Business Host object
Method %OnNew(pConfigName As %String) As %Status
{
	#; %cspServer instantiates us without a config name. We need to defer initialization.
	Quit:""=$G(pConfigName) $$$OK
	Quit ##class(Ens.BusinessService)$this.%OnNew(.pConfigName)
}

Method OnInit() As %Status
{
	Set tSC=##class(EnsLib.EDI.X12.Service.Standard)$this.OnInit()  Quit:$$$ISERR(tSC) tSC

	Set ..IOStreamIn=##class(%IO.MetaCharacterStream).%New()
	Set ..LibStreamReply=##class(%GlobalCharacterStream).%New()
	Set ..IOStreamReply=##class(%IO.MetaCharacterStream).%New(..LibStreamReply)
	Set ..IOStreamReply.Name="SOAPReplyStream"
	Quit $$$OK
}

Method Send(Input As %Stream.GlobalCharacter) As %Stream.GlobalCharacter [ WebMethod ]
{
	Set tSC=..ProcessInput(Input,.tStreamOut)  Do:$$$ISERR(tSC) ..ReturnMethodStatusFault(tSC)
	Quit tStreamOut
}

Method OnProcessInput(pStreamIn As %CharacterStream, Output pStreamOut As %CharacterStream) As %Status
{
	Set tSC=$$$OK  Do pStreamIn.Rewind()
	$$$sysTRACE("Got SOAP Stream "_pStreamIn_"("_pStreamIn.Size_")")
	Do ..IOStreamIn.BindInput(pStreamIn, .tSC)  Quit:$$$ISERR(tSC) tSC
	Set tSC = ..IOStreamIn.BindOutput(pStreamIn)  Quit:$$$ISERR(tSC) tSC
	Set ..IOStreamIn.Name=..%ConfigName_"_SOAPStream"

	
	Do ..%Parser.Reset()
	Do ..LibStreamReply.Clear(), ..IOStreamReply.Rewind(.tSC1)  Quit:$$$ISERR(tSC1) $$$ADDSC(tSC,tSC1)
	While '..IOStreamIn.AtEnd { ; Loop over docs in the stream
		Set tSC1=..%Parser.ParseFramedIOStream(..IOStreamIn,,1,,..DefRepSep,..DefCompSep,..DefSegTerm)
		Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		#; !!! Quit on fatal errors only
		Quit:$$$StatusEquals(tSC1,$$$EnsErrGeneral,$$$EnsEDIX12InvalidSegmentTerminator,$$$EnsEDIX12ISATruncated,$$$EnsEDIX12ExpectedSegment,$$$EnsEDIX12UnexpectedEOD,$$$EnsEDIX12InvalidSegmentName,$$$EnsEDIX12BadBINLength,$$$EnsEDIX12UnexpectedEODBinary)
	}
	Do ..IOStreamIn.BindInput(..DummyLibStreamIn, .tSC)  Quit:$$$ISERR(tSC) tSC
	Set tSC = ..IOStreamIn.BindOutput(..DummyLibStreamIn)  Quit:$$$ISERR(tSC) tSC
	Do ..%Parser.Reset() ; release the file
	Set pStreamOut=..LibStreamReply
	Quit tSC
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document = {$$$NULLOREF}) As %Status
{
	Quit:'$IsObject(pReplyDocument) ..LibStreamReply.Write(pReplyDocument)
	Set pReplyDocument.IsMutable=0

	Set:$Case(..%outFraming,"uninitialized":1,"xxf":1,:0) ..%outFraming=..%Parser.%outFraming
 	Set tSC=..OutputFramedToIOStream(..IOStreamReply,pReplyDocument,,1,..IOLogEntry)
	If $$$ISERR(tSC) {
		Set:$IsObject(..IOLogEntry) ..IOLogEntry.Annotation = $S(""=..IOLogEntry.Annotation:"",1:..IOLogEntry.Annotation_" | ")_"after SOAP WriteX12 error on "_..Adapter.IOAddr
	} Else {
		Set:$IsObject(..IOLogEntry) ..IOLogEntry.Annotation = $S(""=..IOLogEntry.Annotation:"",1:..IOLogEntry.Annotation_" | ")_"after SOAP WriteX12 on "_..Adapter.IOAddr
	}
	Quit tSC
}

/// Return the segment terminator string that the Parser and the OutputTo...() methods will use.
Method GetSegmentTerminator() As %String
{
	Quit ..SegTerminator
}

}
