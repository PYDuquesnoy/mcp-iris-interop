/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Print page for SVG output.
Class EnsPortal.SVG.SVGPrint Extends %CSP.Page [ System = 4 ]
{

Parameter CONTENTTYPE = "text/xml";

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '($system.Security.Check("%Ens_Code","READ") || $system.Security.Check("%Ens_BPL","READ")) {
		Set %response.ContentType = "text/html"
		Set %response.Status = "403 Forbidden"
		Quit 0
	}
	Quit 1
}

ClassMethod OnPage() As %Status
{
	Write "<?xml version=""1.0"" ?>",!

	Set tToken = $G(%request.Data("TOKEN",1))
	Set tTitle = $G(%request.Data("TITLE",1),"BPL Diagram")

	Set wid = 11.25
	Set hgt = wid * (11/8.5)

	Set vboxWid = 1200
	Set vboxHgt = vboxWid * (hgt/wid)

	Set vboxWid = $G(%request.Data("WIDTH",1),vboxWid)
	Set vboxHgt = $G(%request.Data("HEIGHT",1),vboxHgt)
	
	If (vboxHgt/vboxWid) < (hgt/wid) {
		Set vboxHgt = vboxWid * (hgt/wid)
	}
	
	&html<<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #(vboxWid)# #(vboxHgt)#" height="#(hgt)#in" width="#(wid)#in" preserveAspectRatio="none">>
	&html<<title>#($ZCVT(tTitle,"O","HTML"))#</title>>

	// inject styles
	Do ##class(EnsPortal.SVG.BPLCanvas).%DrawStyleSVG()

	// override some styles
	#; style
	Write "<style type=""text/css""><![CDATA[",!
	&html<

text, tspan {
	pointer-events : none;
	font-size: 17px;
	fill: #404040;
	font-family: arial;
}
.canvas {
	fill: white;
	stroke: none;
	stroke-width: 1;
}

.page {
	fill: none;
	stroke: #808080;
	stroke-width: 1;
	stroke-dasharray: 1,1,2,2,1,1;
}

>
	Write "]]></style>>"

	&html<<svg xmlns:xlink="http://www.w3.org/1999/xlink">>

	// get token for XML content
	If (tToken'="") {
		Set k = $O(^IRIS.Temp.BPLPrint($namespace,tToken,""))
		While (k'="") {
			Write $G(^IRIS.Temp.BPLPrint($namespace,tToken,k))
			Set k = $O(^IRIS.Temp.BPLPrint($namespace,tToken,k))
		}
		Kill ^IRIS.Temp.BPLPrint($namespace,tToken)
	}

	&html<</svg>>

	// page border
	&html<<rect x="0" y="0" width="100%" height="100%" class="page"/>>

	&html<</svg>>
	Quit $$$OK
}

}
