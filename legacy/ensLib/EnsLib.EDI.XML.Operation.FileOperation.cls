/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// BusinessOperation class for writing XML messages to a file.  Works with XML messages of type EnsLib.EDI.XML.Document.
Class EnsLib.EDI.XML.Operation.FileOperation Extends EnsLib.EDI.XML.Operation.Standard [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

Parameter INVOCATION = "Queue";

/// Name of file to output the document(s) to. May include timestamp specifiers. The %f specifier if present will be 
/// replaced with the name of the document's original source stream. (stripped of characters illegal in filenames).<p>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q%!+(_a)", Required ];

Parameter SETTINGS As %String = "Filename";

Method OnMessage(pRequest As EnsLib.EDI.XML.Document, Output pResponse As EnsLib.EDI.XML.Document) As %Status
{
	Set tSC=..validateAndIndex(pRequest)  Quit:$$$ISERR(tSC) tSC

	Set tFilename=..Adapter.CreateTimestamp(##class(%File).GetFilename($P(pRequest.Source,$C(13))),..Filename)
	Set tFormat=$S(""'=..Format:..Format, 1:pRequest.Format)
	Set tForce=("!"=$E(..Adapter.Charset))
	Set tCharset=$S(tForce:$E(..Adapter.Charset,2,*),1:..Adapter.Charset)
	If "@"=$E(tCharset) { Set tTable=$E(tCharset,2,*) }
	Else { Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(tCharset) }
	Set:(tTable'="UTF8"||tForce)&&(tFormat'["C(") tFormat=tFormat_"C("_..Adapter.Charset_")"
	Set:tForce tCharset=..Adapter.Charset, ..Adapter.Charset="" ; temporarily suppress charset because XML.Document will force it
	Set tSC=..Adapter.PutStream(tFilename,pRequest,tFormat)  Quit:$$$ISERR(tSC) tSC
	Set:tForce ..Adapter.Charset=tCharset ; restore old value
	$$$sysTRACE("After "_$S(..Adapter.Overwrite:"storing",1:"appending")_" XML document "_pRequest_"/"_pRequest.%Id()_" to file "_tFilename)
	Quit tSC
}

}
