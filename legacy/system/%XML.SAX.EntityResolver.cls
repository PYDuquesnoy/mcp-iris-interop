/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.SAX.EntityResolver">Customizing How the SAX Parser Is Used</a>.</p>
/// This class enables the SAX parser to resolve external entities. The parser will call the 
/// resolveEntity method passing the URI/URL of the external entity,expecting a
/// new stream object to be returned. This class provides a default implementation;
/// you may wish to provide your own subclass with specialized semantics. The entity must be
/// returned as an instance of %BinaryStream (or one of its subclasses) wrapped  in an instance of 
/// %XML.SAX.StreamAdapter. If the entity cannot be resolved, then $$$NULLOREF should be returned to 
/// indicate to the SAX parser that the entity cannot be resolved).
/// 
/// <p>If you want the EntityResolver to be able to resolve urls prefixed by https then you MUST
/// set the SSLConfiguration property to the name of a valid SSLConfiguration that is appropriate
/// for the servers to which the urls resolve.</p>
Class %XML.SAX.EntityResolver Extends %Library.RegisteredObject [ System = 3 ]
{

///  The amount of time to wait for a response from the web server before
///  assuming that the web server is not responding.
///  If not specified, the %Net.HttpRequest default is used.
Property Timeout As %Integer;

/// The name of the activated TLS/SSL configuration to use for https requests.
Property SSLConfiguration As %String;

Method resolveEntity(publicID As %Library.String, systemID As %Library.String) As %Library.Integer
{
 Set $ZT="Trap",tSC=$$$OK,tStream=$$$NULLOREF
 
 #dim tHttpRequest As %Net.HttpRequest
 
 do {
	 
	#; Pick out public or system entity id	
 	If systemID]"" {
	 	Set tId=systemID
 	} else  {
	 	Set tId=publicID
	}
	 	
	#; Parse the Id into it's tComponents
	Do ##Class(%Net.URLParser).Parse(tId,.tComponents)

	#; Extract the scheme
	Set tScheme=$ZConvert($Get(tComponents("scheme")),"L")
	
 	If tScheme="http"||(tScheme="https") {
		
		#; Do an http request and assign the response stream
		Set tHttpRequest=##class(%Net.HttpRequest).%New() 
		If '$IsObject(tHttpRequest) Set tSC=%objlasterror Quit
		
		#; Need to set raw mode to preserve character set
		Set tHttpRequest.ReadRawMode=1
			
		#; If https, copy across the SSLConfiguration
		If tScheme="https" {
			Set tHttpRequest.Https=1
		}
		Set tHttpRequest.SSLConfiguration=..SSLConfiguration
		
		If ..Timeout'="" Set tHttpRequest.Timeout=..Timeout
		Set tHttpRequest.Server=tComponents("host")
		If $Get(tComponents("port"))]"" {
			Set tHttpRequest.Port=tComponents("port")	
		}			
		
		Set tRequest=tComponents("path")
		If ($Get(tComponents("path"))'="") {
			Set tRequest=tRequest_"?"_tComponents("query")
		}
		
		Set tSC=tHttpRequest.Get(tRequest)
		If '$$$ISERR(tSC) Set tStream=tHttpRequest.HttpResponse.Data
		
	} elseif (tScheme="file") {
		
		#; Open the file and assign the binary stream
		Set tFile=##class(%FileBinaryStream).%New() 
		If '$IsObject(tFile) Set tSC=%objlasterror Quit
		
		Set tSC=tFile.LinkToFile($zconvert(tComponents("netloc"),"I","URL")) 
		If '$$$ISERR(tSC) Set tStream=tFile	
		
	} else {
		
		#; Assume the Id is a file name, open and assign the binary stream
		Set tFile=##class(%FileBinaryStream).%New() 
		If '$IsObject(tFile) Set tSC=%objlasterror Quit
		
		Set tSC=tFile.LinkToFile($zconvert(tId,"I","URL")) 
		If '$$$ISERR(tSC) Set tStream=tFile	
	}
 } 	while (0)
Exit
	If tStream'=$$$NULLOREF {
		
		#; Create a Stream Adapter
 		Set tStream=##class(%XML.SAX.StreamAdapter).%New(tStream)
 		If '$IsObject(tStream) Set tSC=%objlasterror
 		
	}
 	Quit tStream
Trap
	Set $ZT="",tStream=$$$NULLOREF,tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
