/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Include generated XSLT from another report in this report
Class %ZEN.Report.Display.callsvg Extends (node, tableOutput) [ Deprecated, Inheritance = right, LegacyInstanceContext, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property children As list Of node(XMLPROJECTION = "NONE");

/// Name of method that returns an XML stream to include
Property method As %ZEN.Datatype.string;

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	Set sc=$$$OK
	Do XSL.WriteLine("<div>")
	Set SVG=$zobjmethod(%report,..method)
	Do SVG.Rewind()
	Do XSL.CopyFrom(SVG)
	Do XSL.WriteLine("</div>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	Do XSL.WriteLine("<fo:block><fo:instream-foreign-object>")
	Set SVG=$zobjmethod(%report,..method)
	Do SVG.Rewind()
	Do XSL.CopyFrom(SVG)
	Do XSL.WriteLine("</fo:instream-foreign-object></fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	quit sc
}

}
