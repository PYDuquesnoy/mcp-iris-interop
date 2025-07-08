/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies an attribute-value pair for HTML within a class.
Class %ZEN.Report.Display.atthtml Extends att [ Deprecated, System = 4 ]
{

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	quit $$$OK
}

Storage Default
{
<Data name="atthtmlDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display.atthtmlD</DataLocation>
<DefaultData>atthtmlDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Display.atthtmlD</IdLocation>
<IndexLocation>^%ZEN.Report.Display.atthtmlI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display.atthtmlS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
