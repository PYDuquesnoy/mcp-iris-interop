/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is an internal detail of the implemetation of the BPL Compiler.
Class Ens.BPL.Counter Extends %RegisteredObject [ ProcedureBlock, System = 3 ]
{

/// This defines the prefix
Property Prefix As %String;

/// This holds the index of the next state
Property Index As %Integer [ InitialExpression = 0, Private ];

/// This method gets the current count
Method Current() As %String
{
	Quit ..Prefix_..Index
}

/// This method gets the next count
Method Next() As %String
{
	Set ..Index=..Index+1
	Quit ..Current()
}

/// This method initializes the object on construction
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..Prefix=$Get(initvalue)
	Quit $$$OK
}

/// Readonly access to numeric index
Method IndexGet() As %Integer
{
	Quit i%Index
}

Storage Default
{
<Data name="CounterDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Index</Value>
</Value>
<Value name="3">
<Value>Prefix</Value>
</Value>
</Data>
<DataLocation>^Ens.BPL.CounterD</DataLocation>
<DefaultData>CounterDefaultData</DefaultData>
<IdLocation>^Ens.BPL.CounterD</IdLocation>
<IndexLocation>^Ens.BPL.CounterI</IndexLocation>
<StreamLocation>^Ens.BPL.CounterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
