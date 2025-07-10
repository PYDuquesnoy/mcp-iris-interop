/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.Operation.FileOperation Extends EnsLib.EDI.X12.Operation.BatchStandard [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

/* override default value */
/// Name of file to output the document(s) to. <br/>
/// Consists of literal characters and zero or more format codes. A format code is preceded by a
/// percent sign (%); characters that are not part of a format code are output unchanged.<br/>
/// The %f or %F specifier if present will be replaced with the name of the document's original source stream (stripped of characters illegal in filenames).<p/>
/// Timestamp format codes are documented in the method <var>FormatDateTime()</var> in class <class>Ens.Util.Time</class> <br/>.
/// The additional format code '+' is supported to guarantee filename uniqueness by incrementing a counter string.
/// This additional code is supported in the following forms, where nn is an alphanumeric counter string of 0 or more characters: <br/>
///  <ul>
///  <li>%+(nn) -  Increment <var>nn</var> until the generated filename does not exist in the target directory specified by <var>pDirectory</var> </li>
///  <li>%#+(nn) - Increment <var>nn</var> omitting leading non-significant 0/a characters </li>
///  <li>%!+(nn) - Only use <var>nn</var> if the base filename already exists </li>
///  <li>%#!+(nn) or %!#+(nn) - Omit <var>nn</var> if the filename without it does not exist already, otherwise use <var>nn</var> but omit leading non-significant 0/a characters within it </li>
///  <li>%$+(nn) - increment <var>nn</var> without testing for existence of the resulting filename; then re-increment while the resulting filename exists </li>
///  <li>%#$+(nn) or %$#+(nn) - increment <var>nn</var> regardless without testing for existence, omitting leading non-significant 0/a characters </li>
/// <br/>
/// Thus the '#' character means to output only the rightmost significant (non-zero,non- a/A) alphanumeric characters, the '!' means to only use <var>nn</var> if needed to
/// create a unique local filename, and '$' means to increment <var>nn</var> for each call regardless of the local filesystem.
/// The '$' form can be used to generate a series of filenames on a local or remote filesystem. This form relies on a counter variable in $$$EnsStaticAppData("Ens.Util.File:CreateTimestamp").
/// <br/>
/// The counter string <var>nn</var> may also contain non-alphanumeric characters. If these are present they are output unchanged as literal characters.
/// To ensure a unique filename, first the filename including string <var>nn</var> is checked for existence, and if that already exists the string is incremented in its rightmost alphanumeric character first.
/// Digits are incremented in the range 0-9, and alphabetic characters are incremented in the ranges a-z and A-Z. If the entire range represented by nn is exhausted, additional digits/letters will be prepended as needed.</li>
/// </ul>
/// For example, the string %F_%Q_%!#+(.a1) means the the document's original source stream is used with a timestamp appended, and if a file like that already exists then .1 is
/// further appended, and if that also exists already then .2 is appended, and so on, up to .9, then to .a1, then up to .z9, and beyond that to .az1 and so on.
/// Only one '%+' format code is supported. <br/>
/// The timestamp string used always reflects the current time, converted to the timezone specified using the %K format code.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q%!+(_a)", Required ];

Method outputDocument(pFilename As %String, pDocument As EnsLib.EDI.X12.Document, pSeparators As %String, pDoFraming As %Integer) As %Status
{
	#; No Attachments - write it out directly
	If 'pDocument.Attachments.Next() {
		Set tSC = ..Adapter.open(pFilename)  Quit:$$$ISERR(tSC) tSC
		Try {
			Use ..Adapter.Device  Set tSC=..OutputFramedToDevice(pDocument,pSeparators,0,..IOLogEntry,.pDoFraming)  Use ..Adapter.OldIO
		} Catch ex {
			Set tSC1=ex.AsStatus(), tSC=$$$ADDSC(tSC,tSC1)
		}
		Set tSC1=..Adapter.close()
		Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		Quit tSC
	}
	#; Has attachments - must go out as MIME
	Set tStream=##class(%FileCharacterStream).%New()
	Set tSC=pDocument.OutputToLibraryStream(tStream,pSeparators)
	Set tX12Part=##class(%Net.MIMEPart).%New(tStream)
	Set tMIME=##class(%Net.MIMEPart).%New()
	Set tSC=tMIME.Parts.Insert(tX12Part) Quit:$$$ISERR(tSC) tSC

	Set k=""  For { Set tAttachment=pDocument.Attachments.GetNext(.k)  Quit:""=k
		Set tAttachmentPart=##class(%Net.MIMEPart).%New(tAttachment.Stream)
		Set tAttachmentPart.ContentType=tAttachmentPart.ContentType_"; filename="""_##class(%File).GetFilename(tAttachment.Filename)_""""
		Set tSC=tMIME.Parts.Insert(tAttachmentPart) Quit:$$$ISERR(tSC)
	}
	Quit:$$$ISERR(tSC) tSC
	
	$$$TRACE("Writing interchange "_pDocument_"/"_pDocument.%Id()_" as MIME to file "_pFilename)
	Quit ..Adapter.PutMIME(pFilename,tMIME,0)
}

Method outputSegment(pFilename As %String, pSegObj As EnsLib.EDI.X12.Segment, pSeparators As %String, pCount As %Integer = 0) As %Status
{
	If ((pCount > 0) && $Case(pSegObj.Name,"GE":1,"IEA":1,:0)) {
		Set pSegObj=pSegObj.%ConstructClone()
		Do pSegObj.SetValueAt(pCount,1)
	}
	Quit ..Adapter.PutStream(pFilename,pSegObj,pSeparators)
}

Method fileExists(pFilename As %String, ByRef pStatus As %Status = {$$$OK}) As %Boolean
{
	Quit ..Adapter.Exists(pFilename)
}

}
