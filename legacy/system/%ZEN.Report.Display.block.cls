/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.block Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	Set sc=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	Do XSL.WriteLine("<span>") 
	If 'incell $$$stylehtml
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if (child.tag'="caption"),(child.tag'="summary") Set sc = child.%DrawToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	Do XSL.WriteLine("</span>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0, ByRef ignoreId = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.WriteLine("<fo:inline"_$$$applyclass("block",.context)_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">")
	If 'incell $$$stylefo
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		// JSL3818 - fix problem reported by Julie Bolinsky
		// set incell=0 (the default) so that block and things below it will inherit style from block and their style will not be ignored by tableOutput
		if (child.tag'="caption"),(child.tag'="summary") Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	Do XSL.WriteLine("</fo:inline>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
