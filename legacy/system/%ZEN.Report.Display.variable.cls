/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <Class>variable</Class> has contents that define an XSL variable
Class %ZEN.Report.Display.variable Extends (childrenNode, tableOutput) [ Deprecated ]
{

/// <Property>name</Property> names the variable
Property name As %ZEN.Datatype.string;

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE");

/// <Method>%DrawToXSLFO</Method> emits an XSL variable instruction and invokes %DrawToXSLFO on all the variable's children
Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.Write("<xsl:variable name='"_..name_"'>")
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
	Do XSL.WriteLine("</xsl:variable>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
