/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Datatype.string Extends %ZEN.Datatype.string [ Deprecated, System = 4 ]
{

/// When used in a <class>%ZEN.Report.CustomAggregate</class>, 
/// any property that is marked with parameter REPORTFIELD=1 has its value passed to %val as a node.  
Parameter REPORTFIELD = 1;

Storage Default
{
<Data name="stringDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Datatype.stringD</DataLocation>
<DefaultData>stringDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Datatype.stringD</IdLocation>
<IndexLocation>^%ZEN.Report.Datatype.stringI</IndexLocation>
<StreamLocation>^%ZEN.Report.Datatype.stringS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
