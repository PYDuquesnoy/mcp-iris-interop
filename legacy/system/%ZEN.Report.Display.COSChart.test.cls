/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occSAX, %occXSLT)

Class %ZEN.Report.Display.COSChart.test Extends (%ZEN.Report.Display.childrenNode, %ZEN.Report.Display.tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

/// Width of the chart within the report.
Property width As %ZEN.Datatype.length [ InitialExpression = "10in" ];

/// Height of the chart within the report.
Property height As %ZEN.Datatype.length [ InitialExpression = "8in" ];

Method %DrawToXSLFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean, ByRef xmlfile As %String) As %Status
{
	Set tSC=$$$OK
	Do XSL.WriteLine("<fo:block><fo:instream-foreign-object><svg:svg x='0' y='0'>")
	Do:..width'="" XSL.WriteLine("<xsl:attribute name='width'>"_..width_"</xsl:attribute>")
	Do:..height'="" XSL.WriteLine("<xsl:attribute name='height'>"_..height_"</xsl:attribute>")
	Set chartid=100
	Do XSL.WriteLine("<svg:svg id='"_chartid_"'>")
	Do:..width'="" XSL.WriteLine("<xsl:attribute name='width'>"_..width_"</xsl:attribute>")
	Do:..height'="" XSL.WriteLine("<xsl:attribute name='height'>"_..height_"</xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='viewBox'>0 0 "_100_" "_100_"</xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='preserveAspectRatio'>"_"none"_"</xsl:attribute>")
	
	do {

		Set tSC=##class(%XML.XPATH.Document).CreateFromFile(xmlfile,.tDoc)
		if $$$ISERR(tSC) quit
		Set tSC=tDoc.EvaluateExpression("/test","Person",.tResults)
		if $$$ISERR(tSC) quit
		Set y=1
		For tI=1:1:tResults.Count()
		{
			Set tResult=tResults.GetAt(tI)
		
			if (tResult.Type=$$$XPATHDOM)
			{
				
			
				While tResult.Read() {
					do tResult.MoveToAttributeName("Age")
					Do XSL.WriteLine("<svg:text x='1' y='"_y_"' font-size='1'>")
					Set y=y+1
					Set input=tResult.Value
					Do XSL.Write(input)
					Do XSL.WriteLine("</svg:text>")

				}
			
			}
		}
	} while (0) ;
	Do XSL.WriteLine("</svg:svg>")
	Do XSL.WriteLine("</svg:svg></fo:instream-foreign-object></fo:block>")
	
	quit tSC
}

Storage Default
{
<Data name="testDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display.C2E79.testD</DataLocation>
<DefaultData>testDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Display.C2E79.testD</IdLocation>
<IndexLocation>^%ZEN.Report.Display.C2E79.testI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display.C2E79.testS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
