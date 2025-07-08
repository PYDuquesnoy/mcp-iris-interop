/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This tag renders a linebreak onto the page.
Class %ZEN.Report.Display.line Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// If a horizontal rule is being drawn, this specifies the thickness of the rule.
Property thickness As %ZEN.Datatype.length [ InitialExpression = "1px" ];

/// Possible values are "empty", "solid", and "dashed".  An pattern of "empty" specifies
/// a linebreak. The "solid" and "dashed" options also result in a line break, but also
/// add a horizontal rule of the given pattern.
Property pattern As %ZEN.Datatype.string(VALUELIST = ",empty,solid,dashed");

/// If a horizontal rule is being drawn, this specifies the color of the rule.
Property color As %ZEN.Datatype.color;

/// If a horizontal rule is being drawn, this specifies the length of the rule.
Property length As %ZEN.Datatype.length;

/// Possible values are "left", "right", and "center". If a horizontal rule is 
/// being drawn, this specifies the alignment of the rule within the page.
Property align As %ZEN.Datatype.align [ InitialExpression = "left" ];

/// Specifies the number of linebreaks to draw. This is exactly the same as repeating
/// the &lt;line .../&gt; tag.
Property count As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// Specifies the line-height styling property for the line.
Property lineHeight As %ZEN.Datatype.length [ InitialExpression = "-1" ];

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	If ..pattern="empty" {
		For i=1:1:..count {  Do XSL.WriteLine("<br/>") }
		d ..%EndDrawHtml(.context,.XSL,.delay)	
		Quit $$$OK
	}
	
	If ..align="left" {
		Set align="text-align:left;margin:auto auto auto 0;"
	} ElseIf ..align="right" {
		Set align="text-align:right;margin:auto 0 auto auto;"
	} Else {
		Set align="margin:auto;"
	}
	
	//if no length given, do full line
	If ..length="" {
		For i=1:1:..count { Do XSL.WriteLine("<hr style='"_align_"line-height:"_..lineHeight_";  border-top:"_..thickness_" "_..pattern_" "_..color_";'/>") }
	} Else {
		For i=1:1:..count { Do XSL.WriteLine("<hr style='"_align_"line-height:"_..lineHeight_"; width:"_..length_";border-top:"_..thickness_" "_..pattern_" "_..color_";'/>") }
	}
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	If ..pattern="empty" {
		if ..lineHeight=-1 {
			For i=1:1:..count { Do XSL.WriteLine("<fo:block><fo:leader leader-pattern='space' rule-thickness='"_..thickness_"'/></fo:block>") }
		} else {
			For i=1:1:..count { Do XSL.WriteLine("<fo:block line-height='"_..lineHeight_"'><fo:leader leader-pattern='space'  rule-thickness='"_..thickness_"'/></fo:block>") }
		}
		d ..%EndDrawFo(.context,.XSL,.delay)	
		Quit $$$OK
	}
	
	Set pattern=$case(..pattern,"solid":"rule","dashed":"dots",:"rule")
	Set length=$case(..length,"":"100%",:..length)
	
	For i=1:1:..count {
		Do XSL.WriteLine("<fo:block line-height='"_$s(..lineHeight=-1:"125%",1:..lineHeight)_"' text-align='"_..align_"'><fo:leader leader-length='"_length_"' leader-pattern='"_pattern_"'>")
		Do:..color'="" XSL.WriteLine("<xsl:attribute name='color'>"_..color_"</xsl:attribute>")
		Do:..thickness'="" XSL.WriteLine("<xsl:attribute name='rule-thickness'>"_..thickness_"</xsl:attribute>")
		Do XSL.WriteLine("</fo:leader></fo:block>")
	}
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit $$$OK
}

}
