/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Individual Result entries class used by /// a <CLASS>EnsLib.LDAP.Message.Results</CLASS>
Class EnsLib.LDAP.Message.Result Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Distinguished Name for the result
Property DN As %String(MAXLEN = "");

Relationship Attributes As EnsLib.LDAP.Message.Attribute [ Cardinality = children, Inverse = Result ];

Relationship Results As EnsLib.LDAP.Message.Results [ Cardinality = parent, Inverse = Results ];

Index ResultsIndex On Results;

Storage Default
{
<Data name="ResultDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DN</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("EnsLib.LDAP.Message.Results.Results")</DataLocation>
<DefaultData>ResultDefaultData</DefaultData>
<IdLocation>^EnsLib.LDAP.Message.ResultsC("Results")</IdLocation>
<IndexLocation>^EnsLib.LDAP.Message.ResultI</IndexLocation>
<StreamLocation>^EnsLib.LDAP.Message.ResultS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
