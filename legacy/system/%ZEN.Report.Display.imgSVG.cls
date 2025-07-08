/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used to display svg code on a Report
Class %ZEN.Report.Display.imgSVG Extends (%ZEN.Report.Display.childrenNode, %ZEN.Report.Display.tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property svgSrc As %ZEN.Datatype.string;

/// Specifies the height of the image.
Property height As %ZEN.Datatype.length;

/// Specifies the width of the image.
Property width As %ZEN.Datatype.length;

/// Specifies the height of the image.
Property contentHeight As %ZEN.Datatype.length;

/// Specifies the width of the image.
Property contentWidth As %ZEN.Datatype.length;

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property children As list Of %ZEN.Report.Display.node(XMLPROJECTION = "NONE");

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
     d ..%BeginDrawHtml(.context,.XSL,.delay)
	 Do XSL.WriteLine("<div>")
	 Do XSL.WriteLine("<xsl:value-of select='"_..svgSrc_"' disable-output-escaping='yes'/>")
	 Do XSL.WriteLine("</div>")
     d ..%EndDrawHtml(.context,.XSL,.delay)	
	 Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Do XSL.WriteLine("<fo:instream-foreign-object>")
	Do XSL.WriteLine("<xsl:value-of select='"_..svgSrc_"' disable-output-escaping='yes'/>")
	Do XSL.WriteLine("</fo:instream-foreign-object>")
	d ..%EndDrawFo(.context,.XSL,.delay)		 
	Quit $$$OK
}

}
