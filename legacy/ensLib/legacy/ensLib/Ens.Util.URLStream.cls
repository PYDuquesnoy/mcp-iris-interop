/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Return a Stream given a URL
Class Ens.Util.URLStream Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod GetURLStream(pURL, Output pStream As %CharacterStream, pProxyServer As %String = "", pProxyPort As %String = "", pProxyHTTPS As %Boolean = 0) As %Status
{
	Set tSC=$$$OK

	#; Parse the URL into its components
	Do ##Class(%Net.URLParser).Parse(pURL,.components)
	
	#; Initialize the stream
	Set pStream=$$$NULLOREF
	
	#; Extract the scheme
	Set tScheme=$ZConvert($Get(components("scheme")),"L")
	If ((tScheme="http")||(tScheme="https")) {
		
		Set tRequest=##Class(%Net.HttpRequest).%New()  $$$ASSERT($IsObject(tRequest))

		Set tRequest.Server=components("host")
		If $Get(components("port"))]"" {
			Set tPort=components("port")	
 			Set tRequest.Port=tPort
		}
		Set tReq=components("path")
		If ($Get(components("query"))'="") {
 			Set tReq=tReq_"?"_components("query")
		}
		Set tRequest.ProxyServer = pProxyServer, tRequest.ProxyPort=pProxyPort, tRequest.ProxyHTTPS=pProxyHTTPS
		#; Do the request
		Set tSC=tRequest.Get(tReq) If $$$ISERR(tSC) Quit tSC
 		Set pStream=tRequest.HttpResponse.Data

	} elseif tScheme="file" {
		Set tFname=$E(pURL,9,$L(pURL)) // skip "file:///"

		#; Check for file existence
		If '##Class(%File).Exists(tFname) {
			Set tSC=$$$ERROR($$$FileDoesNotExist,tFname) Quit tSC
		}
		Set pStream=##Class(%FileCharacterStream).%New() $$$ASSERT($IsObject(pStream))
		Set tSC=pStream.LinkToFile(tFname)
		
	} elseif tScheme="xdata" {
	
		#; The 'netloc' contains the class and xdata member name
		Set tNetloc=components("netloc")
		
		#; If its XDATA, retrieve the XSL definition from the specified class and XDATA block
		Set tSC=##class(Ens.Util.XML.XDataEntityResolver).EntityFromXDATA(.pStream,$Piece(tNetloc,":",1),$Piece(tNetloc,":",2))
		
	} else {
 		Set tSC=$$$EnsError($$$EnsErrNoWebProtocol,tScheme)
	}
	Quit tSC
}

}
