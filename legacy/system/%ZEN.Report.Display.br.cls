/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Display.br Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	Set sc=$$$OK
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	Do XSL.WriteLine("<br/>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	Set sc=$$$OK
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Do XSL.WriteLine("<fo:block> </fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

Storage Default
{
<Data name="brDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display.brD</DataLocation>
<DefaultData>brDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Display.brD</IdLocation>
<IndexLocation>^%ZEN.Report.Display.brI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display.brS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
