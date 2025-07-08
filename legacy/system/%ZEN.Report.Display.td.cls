/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.td Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property group As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)


	Set sc=$$$OK
	Do XSL.WriteLine("<fo:table-cell>") $$$stylefo
	Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='number-rows-spanned'>"_..rowspan_"</xsl:attribute>")
	Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='number-columns-spanned'>"_..colspan_"</xsl:attribute>")

	Do XSL.WriteLine("<fo:block>") ;$$$stylefo
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption" Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 


	Do XSL.WriteLine("</fo:block>")
	Do XSL.WriteLine("</fo:table-cell>") 
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set sc=$$$OK
	Do XSL.WriteLine("<td>") $$$stylehtml
	Do:..rowspan'="" XSL.WriteLine("  <xsl:attribute name='rowspan'>"_..rowspan_"</xsl:attribute>")
	Do:..colspan'="" XSL.WriteLine("  <xsl:attribute name='colspan'>"_..colspan_"</xsl:attribute>")
 	Set sc=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption" Set sc = child.%DrawToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
 	Do XSL.WriteLine("</td>") 
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

Storage Default
{
<Data name="tdDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display.tdD</DataLocation>
<DefaultData>tdDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Display.tdD</IdLocation>
<IndexLocation>^%ZEN.Report.Display.tdI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display.tdS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
