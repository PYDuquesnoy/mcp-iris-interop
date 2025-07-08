/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Display.inline Extends (textNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
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

	Do XSL.Write("<inline>") $$$stylehtml
	if ..field'="" Do XSL.WriteLine("<xsl:value-of select='"_..field_"'/>")
	If ..expression'="",..if'="" {
		X "S %cond="_..if
		X "S %value="_..expression
		if %cond {
			Do XSL.Write("<![CDATA["_%value_"]]>")
		}
	}

	if ..content'=$c(0) Do XSL.Write("<![CDATA["_..content_"]]>")
	Do XSL.Write("</inline>")
	If ..bidiOverrideDirection'="" {
		do XSL.WriteLine("</bdo>")
	}
	
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	
	Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	If ..bidiOverrideDirection'="" {
		do XSL.WriteLine("<fo:block>")
		do XSL.WriteLine("<fo:bidi-override direction='"_..bidiOverrideDirection_"' unicode-bidi='bidi-override'>")
	}

	Do XSL.Write("<fo:inline "_$$$applyclass("inline",.context)_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">")
	If 'incell $$$stylefo
	if ..field'="" Do XSL.WriteLine("<xsl:value-of select='"_..field_"'/>")
	If ..expression'="",..if'="" {
		X "S %cond="_..if
		X "S %value="_..expression
		if %cond {
			Do XSL.Write("<![CDATA["_%value_"]]>")
		}
	}
	
	if ..content'=$c(0) Do XSL.Write("<![CDATA["_..content_"]]>")
	Do XSL.WriteLine("</fo:inline>")
	If ..bidiOverrideDirection'="" {
		do XSL.WriteLine("</fo:bidi-override>")
		do XSL.WriteLine("</fo:block>")
	}

	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit $$$OK
}

Storage Default
{
<Data name="inlineDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display.inlineD</DataLocation>
<DefaultData>inlineDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Display.inlineD</IdLocation>
<IndexLocation>^%ZEN.Report.Display.inlineI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display.inlineS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
