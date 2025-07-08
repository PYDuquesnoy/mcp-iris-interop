/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <Class>valueof</Class> maps directly to "&lt;xsl:value-of select='"_..select_"'/>"
Class %ZEN.Report.Display.valueof Extends (childrenNode, tableOutput) [ Deprecated ]
{

/// <Property>select</Property> is equal to the string that will provide the value
Property select As %ZEN.Datatype.string;

/// <Method>%DrawToXSLFO</Method> emits an xsl:value-of instruction
Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	do XSL.WriteLine("<xsl:value-of select='"_..select_"'/>")
	d ..%EndDrawFo(.context,.XSL,.delay)		 
	Quit $$$OK
}

}
