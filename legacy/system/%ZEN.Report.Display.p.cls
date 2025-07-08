/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The content of a &lt;p&gt; tag is rendered as a paragraph of text
Class %ZEN.Report.Display.p Extends (textNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property children As list Of node(XMLPROJECTION = "NONE");

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	If ..bidiOverrideDirection'="" {
		Do XSL.WriteLine("<bdo dir='"_..bidiOverrideDirection_"'>") 
	}

	Do XSL.WriteLine("<p>") $$$stylehtml
	if ..field'="" Do XSL.WriteLine("<xsl:value-of select='"_..field_"'/>")
	If ..expression'="",..if'="" {
		X "S %cond="_..if
		X "S %value="_..expression
		if %cond {
			Do XSL.WriteLine("<![CDATA["_%value_"]]>")
		}
	}
	if ..content'=$c(0) Do XSL.WriteLine("<![CDATA["_..content_"]]>")
	Do XSL.WriteLine("</p>")
	If ..bidiOverrideDirection'="" {
		do XSL.WriteLine("</bdo>")
	}
	
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	
	d ..%BeginDrawFo(.context,.XSL,.delay)
	
	Do XSL.WriteLine("<fo:block "_$$$applyclass("p",.context)_">") 
	If 'incell $$$stylefo
	If ..bidiOverrideDirection'="" {
		do XSL.WriteLine("<fo:bidi-override direction='"_..bidiOverrideDirection_"' unicode-bidi='bidi-override'>")
	}
	if ..field'="" Do XSL.WriteLine("<xsl:value-of select='"_..field_"'/>")
	If ..expression'="",..if'="" {
		X "S %cond="_..if
		X "S %value="_..expression
		if %cond {
			Do XSL.WriteLine("<![CDATA["_%value_"]]>")
		}
	}
	if ..content'=$c(0) Do XSL.WriteLine("<![CDATA["_..content_"]]>")
	If ..bidiOverrideDirection'="" {
		do XSL.WriteLine("</fo:bidi-override>")
	}

	Do XSL.WriteLine("</fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit $$$OK
}

}
