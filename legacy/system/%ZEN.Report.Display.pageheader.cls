/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies the section of the report display that will be placed as a header
/// on every page.  The height of the region used by the page header is given
/// by the headerHeight attribute of the &lt;document&gt; tag. Note: The &lt;pageheader&gt;
/// tag MUST be placed before the &lt;body&gt; tag.<br>
/// In an HTML report, page headers are not supported, so the contents of &lt;pageheader&gt;
/// are outputted once as a report header.
Class %ZEN.Report.Display.pageheader Extends childrenNode [ Deprecated, System = 4 ]
{

Property regionName As %ZEN.Datatype.string;

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..tagChildren()
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set sc = $$$OK
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

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set sc = $$$OK
	if context("SubReport")'="" {
		Quit $$$OK
	}
	d ..tagChildren()	
	d ..%BeginDrawFo(.context,.XSL,.delay)
	;Do XSL.WriteLine("<fo:static-content flow-name='xsl-region-before'>")
	Do XSL.WriteLine("<fo:static-content flow-name='"_$Select(..regionName'="":..regionName,1:"xsl-region-before")_"'>")
	Do XSL.WriteLine("<fo:block"_$s(..width'="":" width='"_..width_"'",1:"")_">")


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
	Do XSL.WriteLine("  </fo:block>")
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
