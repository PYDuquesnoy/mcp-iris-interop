/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Display.tr Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property group As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)


	Set sc=$$$OK
	Do XSL.WriteLine("<fo:table-row"_$$$applyclass("tr",.context)_">") $$$stylefo
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption" Set sc = child.%DrawToXSLFO(.context,.XSL,.delay,incell)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 


	Do XSL.WriteLine("</fo:table-row>")
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set sc=$$$OK
	Do XSL.WriteLine("<tr>") $$$stylehtml

 	Set sc=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption" Set sc = child.%DrawToHTML(.context,.XSL,.delay,incell)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 	Do XSL.WriteLine("</tr>") 
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

/// This method outputs the stylesheet that converts the input xml to the xml with Excel annotations
/// report, table and item should override this method.  Nested tables not supported.
Method %DrawToAnnotatedXML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Set tSC=$$$OK
	Do XSL.WriteLine("<xsl:element name='row'>")
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=##this
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption" Set sc = child.%DrawToAnnotatedXML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
		
	}
	Do XSL.WriteLine("</xsl:element>")
	Quit tSC
}

}
