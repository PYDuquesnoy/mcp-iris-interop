/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies an attribute-value pair within a class.
Class %ZEN.Report.Display.att Extends node [ Deprecated, System = 4 ]
{

/// The name of the attribute.
Property name As %ZEN.Datatype.name [ Required ];

/// The value of the attribute.  Cannot be specified along with expression
Property value As %ZEN.Datatype.string;

/// expression that will be evaluated and put in output, cannot be specified along with value
Property expression As %ZEN.Datatype.string;

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)	
	Do XSL.Write("<xsl:attribute name='"_..name_"'>")
	if ..expression="" {
		Do XSL.Write(..value)
	} else {
		X "S %value="_..expression
		Do XSL.Write(%value)
	}
	Do XSL.Write("</xsl:attribute>")
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	if ..expression="" {
		Set %value=..value
	} else {
		X "S %value="_..expression
	}
	Do XSL.Write(..name_":"_%value_";")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit $$$OK
}

}
