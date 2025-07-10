/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Individual Attribute class children of  /// a <CLASS>EnsLib.LDAP.Message.Result</CLASS>
Class EnsLib.LDAP.Message.Attribute Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Relationship Result As EnsLib.LDAP.Message.Result [ Cardinality = parent, Inverse = Attributes ];

Index ResultIndex On Result;

/// Attribute Name
Property Name As %String(MAXLEN = "");

/// Attribute Value
Property Value As %String(MAXLEN = "");

Storage Default
{
<Data name="AttributeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Value</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Attributes")</DataLocation>
<DefaultData>AttributeDefaultData</DefaultData>
<IdLocation>^EnsLib.LDAP.Message.ResultC("Attributes")</IdLocation>
<IndexLocation>^EnsLib.LDAP.Message.AttributeI</IndexLocation>
<StreamLocation>^EnsLib.LDAP.Message.AttributeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
