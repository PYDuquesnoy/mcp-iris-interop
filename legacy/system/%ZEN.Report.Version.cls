/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Version Extends %Persistent [ Deprecated, System = 4 ]
{

ClassMethod getVersion() As %String
{
	quit 100
}

Storage Default
{
<Data name="VersionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.VersionD</DataLocation>
<DefaultData>VersionDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%ZEN.Report.VersionD</IdLocation>
<IndexLocation>^%ZEN.Report.VersionI</IndexLocation>
<StreamLocation>^%ZEN.Report.VersionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
