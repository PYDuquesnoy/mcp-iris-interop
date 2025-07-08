/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies the section of the report display that will be placed as a "end" sidebar
/// on every page.  The length of the region used by the page sidebar is given
/// by the endSidebarLength attribute of the &lt;document&gt; tag.  N.B.: The &lt;pageendsidebar&gt;
/// region MUST be defined before the &lt;body&gt; region.<br>
/// In an HTML report, page sidebars are ignored.
Class %ZEN.Report.Display.pageendsidebar Extends childrenNode [ Deprecated, System = 4 ]
{

Property regionName As %ZEN.Datatype.string;

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	// HTML reports do not support page footers
	Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set sc = $$$OK
	if context("SubReport")'="" {
		Quit $$$OK
	}

	d ..tagChildren()		
	d ..%BeginDrawFo(.context,.XSL,.delay)
	;Do XSL.WriteLine("<fo:static-content flow-name='xsl-region-end'>")
	Do XSL.WriteLine("<fo:static-content flow-name='"_$Select(..regionName'="":..regionName,1:"xsl-region-end")_"'>")
	Do XSL.WriteLine("<fo:block"_$s(..width'="":" width='"_..width_"'",1:"")_">")
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set:child.class="" child.class=..class
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	Do XSL.WriteLine("</fo:block>")
	Do XSL.WriteLine("</fo:static-content>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

Method %DrawPageToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, masterName As %String = "main") As %Status
{
	Quit $$$OK
}

Method %DrawStyleToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Quit $$$OK
}

}
