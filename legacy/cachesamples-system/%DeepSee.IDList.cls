/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This table is used to hold lists of IDs when a DeepSee query needs to restrict
/// the member of a given dimension.
Class %DeepSee.IDList Extends %Persistent [ System = 3 ]
{

Index ID On (cubeName, queryKey, factNo, memberId) [ IdKey ];

/// Name of the cube that populated this record.
Property cubeName As %String(MAXLEN = 255);

/// Key for the query that populated this record.
Property queryKey As %String(MAXLEN = 255);

/// Fact number of the dimension.
Property factNo As %Integer;

/// Id in the member table.
Property memberId As %Integer;

Storage Default
{
<Data name="IDListDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^DeepSee.IDList</DataLocation>
<DefaultData>IDListDefaultData</DefaultData>
<IdLocation>^DeepSee.IDList</IdLocation>
<IndexLocation>^DeepSee.IDListI</IndexLocation>
<StreamLocation>^DeepSee.IDListS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
