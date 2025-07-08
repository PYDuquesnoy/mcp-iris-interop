/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Display.tfoot Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property group As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)


	Set sc=$$$OK
	Do XSL.WriteLine("<fo:table-footer>") $$$stylefo
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption",child.tag'="summary",child.tag'="thead",child.tag'="tfoot" Set sc = child.%DrawToXSLFO(.context,.XSL,.delay,incell)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 


	Do XSL.WriteLine("</fo:table-footer>")
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set sc=$$$OK
	Do XSL.WriteLine("<tfoot>") $$$stylehtml

 	Set sc=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption",child.tag'="caption",child.tag'="summary",child.tag'="thead",child.tag'="tfoot" Set sc = child.%DrawToHTML(.context,.XSL,.delay,incell)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 	Do XSL.WriteLine("</tfoot>") 
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

}
