/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <Class> bookmarkTree </Class>
/// The bookmarkTree formatting object is used to hold a list of access points within the document such as a table of contents, a list of figures or tables, etc. Each access point is represented by a bookmark.
/// <Example>
/// <bookmarkTree>
///    <bookmarkGroup group="FilmCategory">
///     ...
///    </bookmarkGroup>
///    <bookmarkGroup group="Theatres">
///     ...
///    </bookmarkGroup>
///  </bookmarkTree>
///  </Example>
Class %ZEN.Report.Display.bookmarkTree Extends childrenNode [ Deprecated, Inheritance = right, PropertyClass = %ZEN.Report.Display.displayParameters, System = 4 ]
{

/// <Method>%DrawToXSLFO</Method> used by internals.
/// All children of the bookmarkTree element are generated.
Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	Set sc=$$$OK
	Do XSL.WriteLine("<fo:bookmark-tree>")
	d ..%BeginDrawFo(.context,.XSL,.delay)
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set:child.tag="bookmarkGroup" sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	d ..%EndDrawFo(.context,.XSL,.delay)
	Do XSL.WriteLine("</fo:bookmark-tree>")
	Quit sc
}

}
