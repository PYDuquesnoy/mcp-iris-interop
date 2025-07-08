/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The contents of a &lt;write&gt; node are directly outputted to the stylesheet.
/// This is often used in conjunction with the &lt;html&gt; and &lt;fo&gt; tags.
Class %ZEN.Report.Display.barcodeOptions Extends contentNode [ Deprecated, System = 4 ]
{

Property XMLEscape As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Method %DrawToHTML(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean, ByRef xmlfile As %String) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	If ..XMLEscape {
		Do XSL.WriteLine("<![CDATA[ "_..content_" ]]>")
	} Else {
		Do XSL.WriteLine(..content)
	}
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit $$$OK
}

}
