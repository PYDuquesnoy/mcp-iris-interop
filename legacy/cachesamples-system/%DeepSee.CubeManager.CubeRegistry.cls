/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class keeps track of how each cube is to be used in production. 
/// Properties of this class are accessed by various tasks to determine 
/// when a given cube should be built or synched.<br>
Class %DeepSee.CubeManager.CubeRegistry Extends (%Persistent, %ZEN.DataModel.Adaptor) [ System = 4 ]
{

/// This is the ALL CAPS cube name, to match DeepSee metadata.
Property CubeKey As %DeepSee.Datatype.entityName [ Required ];

/// Cubes can be grouped together in user-defined management groups. 
/// By default each cube belongs to its own group.
Property MgmtGroup As %DeepSee.Datatype.entityName;

/// This is the build order for this cube within the group. For cube
/// relationship networks this is calculated automatically. This can be set for
/// independent cubes within a group.
Property NaturalBuildOrder As %Integer;

/// This determines when the current <var>MgmtGroup</var> will be built in
/// relation to other defined groups. This is entirely configurable by the user. 
Property CustomBuildOrder As %Integer;

/// Plan for how the cube is to be managed by the build/synch tasks.
Property UpdatePlan As %DeepSee.Datatype.entityName(DISPLAYLIST = ",Manual,Build Only,Build and Synch,Synch Only", VALUELIST = ",Manual,Build,BuildSynch,Synch");

/// <var>Disabled</var> = 1 will block all automatic updates while leaving the 
/// cube visible in the registry.
Property Disabled As %Boolean;

/// Indicates how often the cube is to be built, in units of
/// <var>BuidTimeUnit</var> 
Property BuildFrequency As %Integer;

/// Base unit of time for cube builds. 
Property BuildTimeUnit As %DeepSee.Datatype.entityName(DISPLAYLIST = ",Day,Week,Month", VALUELIST = ",Day,Week,Month");

/// Indicates how often the cube is to be synched, in units of
/// <var>SynchTimeUnit</var>
Property SynchFrequency As %Integer;

/// Base unit of time for cube synchs.
Property SynchTimeUnit As %DeepSee.Datatype.entityName(DISPLAYLIST = ",Minute,Hour,Day", VALUELIST = ",Minute,Hour,Day");

/// The cube key must be unique within DeepSee, so we will reinforce that here. 
Index CubeKeyIndex On CubeKey [ IdKey, Unique ];

Storage Default
{
<Data name="CubeRegistryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>MgmtGroup</Value>
</Value>
<Value name="3">
<Value>NaturalBuildOrder</Value>
</Value>
<Value name="4">
<Value>CustomBuildOrder</Value>
</Value>
<Value name="5">
<Value>UpdatePlan</Value>
</Value>
<Value name="6">
<Value>Disabled</Value>
</Value>
<Value name="7">
<Value>BuildTime</Value>
</Value>
<Value name="8">
<Value>BuildDays</Value>
</Value>
<Value name="9">
<Value>BuildFrequency</Value>
</Value>
<Value name="10">
<Value>BuildTimeUnit</Value>
</Value>
<Value name="11">
<Value>SynchFrequency</Value>
</Value>
<Value name="12">
<Value>SynchTimeUnit</Value>
</Value>
</Data>
<DataLocation>^DeepSee.CubeManager.CubeRegistr</DataLocation>
<DefaultData>CubeRegistryDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^DeepSee.CubeManager.CubeRegistr</IdLocation>
<IndexLocation>^DeepSee.CubeManager.CubeRegI</IndexLocation>
<StreamLocation>^DeepSee.CubeManager.CubeRegS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
