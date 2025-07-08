/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This tag introduces a page break into PDF reports.<br>
/// In HTML reports, the page break
/// will be honored by a printer, but on-screen it is only drawn as a dashed line.
Class %ZEN.Report.Display.pagebreak Extends node [ Deprecated, System = 4 ]
{

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Do XSL.WriteLine("<div style='page-break-after:always;margin-top:2em;margin-bottom:2em;border-bottom:1px dashed black'>")
	Do XSL.WriteLine("<br style='height:0; line-height:0'/>")
	Do XSL.WriteLine("</div>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Do XSL.WriteLine("<fo:block break-after='page'/>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit $$$OK
}

}
