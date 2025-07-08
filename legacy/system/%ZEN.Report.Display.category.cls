/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Category is the base class for &lt;header&gt;, &lt;body&gt;, and &lt;footer&gt;. It
/// simply renders its children.
Class %ZEN.Report.Display.category Extends childrenNode [ Abstract, Deprecated, System = 4 ]
{

Property foStyle As %ZEN.Datatype.string;

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set sc = $$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	Set sc = $$$OK
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Do XSL.WriteLine("<fo:block"_$s(..foStyle'="":" "_..foStyle,1:"")_">")
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	Do XSL.WriteLine("</fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
