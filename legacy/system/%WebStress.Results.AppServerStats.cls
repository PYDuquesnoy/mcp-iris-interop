/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Results.AppServerStats Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Property RunID As %Integer;

Property TestID As %String(TRUNCATE = 1);

Property AppServer As %String(TRUNCATE = 1);

Property Line As %Integer;

Property StatsDate As %Date;

Property StatsTime As %Time;

Property LUConsumed As %Integer;

Property LUAvailable As %Integer;

Property CSPSessions As %Integer;

Property GlobRefs As %Integer;

Property PhysicalReads As %Integer;

Property PhysicalWrites As %Integer;

Property Ratio As %Numeric(SCALE = 2);

Property GlobalSetsKills As %Integer;

Property Seizes As %Integer;

Property SeizesRatio As %Numeric(SCALE = 2);

Property RSeizes As %Integer;

Property RSeizesRatio As %Numeric(SCALE = 2);

Property WDQSize As %String(TRUNCATE = 1);

Property WDWake As %String(TRUNCATE = 1);

Index Main On (TestID, RunID, AppServer, Line) [ IdKey, PrimaryKey, Unique ];

Query GetData(testID As %String, runID As %String) As %SQLQuery
{
SELECT AppServer,CSPSessions,GlobalSetsKills,GlobRefs,Line,LUAvailable,LUConsumed,PhysicalReads,PhysicalWrites,Ratio,RSeizes,RSeizesRatio,Seizes,SeizesRatio,StatsDate,StatsTime,WDQSize,WDWake FROM AppServerStats
 WHERE (TestID = :testID AND RunID = :runID)
}

Storage Default
{
<Data name="AppServerStatsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>CSPSessions</Value>
</Value>
<Value name="3">
<Value>GlobRefs</Value>
</Value>
<Value name="4">
<Value>GlobalSetsKills</Value>
</Value>
<Value name="5">
<Value>LUAvailable</Value>
</Value>
<Value name="6">
<Value>LUConsumed</Value>
</Value>
<Value name="7">
<Value>PhysicalReads</Value>
</Value>
<Value name="8">
<Value>PhysicalWrites</Value>
</Value>
<Value name="9">
<Value>RSeizes</Value>
</Value>
<Value name="10">
<Value>RSeizesRatio</Value>
</Value>
<Value name="11">
<Value>Ratio</Value>
</Value>
<Value name="12">
<Value>Seizes</Value>
</Value>
<Value name="13">
<Value>SeizesRatio</Value>
</Value>
<Value name="14">
<Value>StatsDate</Value>
</Value>
<Value name="15">
<Value>StatsTime</Value>
</Value>
<Value name="16">
<Value>WDQSize</Value>
</Value>
<Value name="17">
<Value>WDWake</Value>
</Value>
</Data>
<DataLocation>^WebStress.Results.AppStatsD</DataLocation>
<DefaultData>AppServerStatsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Results.AppStatsD</IdLocation>
<IndexLocation>^WebStress.Results.AppStatsI</IndexLocation>
<StreamLocation>^WebStress.Results.AppStatsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
