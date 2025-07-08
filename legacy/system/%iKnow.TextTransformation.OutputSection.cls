/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a section identified when executing a TT model.
Class %iKnow.TextTransformation.OutputSection Extends %SerialObject [ Deprecated, System = 4 ]
{

Property Header As %String(MAXLEN = 1000);

Property Text As %String(MAXLEN = "");

Property Location As OutputLocation;

Property KeyValues As list Of OutputKeyValue [ Internal ];

Index HeaderIdx On Header;

Method AddKeyValue(pKeyValue As OutputKeyValue) As %Status
{
	do ..KeyValues.Insert(pKeyValue)
	quit $$$OK
}

Method GetKeyValueCount() As %Integer
{
	quit ..KeyValues.Count()
}

Method GetKeyValueAt(pPosition As %Integer) As OutputKeyValue
{
	quit ..KeyValues.GetAt(pPosition)
}

Storage Default
{
<Data name="OutputSectionState">
<Value name="1">
<Value>Header</Value>
</Value>
<Value name="2">
<Value>Text</Value>
</Value>
<Value name="3">
<Value>Location</Value>
</Value>
<Value name="4">
<Value>KeyValues</Value>
</Value>
</Data>
<State>OutputSectionState</State>
<StreamLocation>^%iKnow.TextT16EC.OutputSectionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
