/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <Class>bookmarkTitle</Class>
/// The bookmarkTitle formatting object is used to identify, in human readable form, an access point.<br/>
/// The children of the bookmarkTitle when rendered are the human readable form
Class %ZEN.Report.Display.bookmarkTitle Extends childrenNode [ Deprecated ]
{

/// This internal method generates the xsl-fo of the children of bookmarkTitle
Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.Write("<fo:bookmark-title>")
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
	Do XSL.WriteLine("</fo:bookmark-title>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
