/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// get - issue an HttpRequest to get XML data to insert into a ZEN Report
/// Report Definition
Class %ZEN.Report.get Extends reportNode [ Deprecated, System = 4 ]
{

/// host where data located
Property host As %ZEN.Datatype.string;

/// port where data located
Property port As %ZEN.Datatype.string;

/// url where data located
Property url As %ZEN.Datatype.uri;

Storage Default
{
<Data name="getDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>url</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.getD</DataLocation>
<DefaultData>getDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.getD</IdLocation>
<IndexLocation>^%ZEN.Report.getI</IndexLocation>
<StreamLocation>^%ZEN.Report.getS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
