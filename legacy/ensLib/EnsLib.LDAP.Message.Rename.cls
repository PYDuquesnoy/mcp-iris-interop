/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Request class to make an LDAP Rename request using operation <CLASS>EnsLib.LDAP.Operation.Standard</CLASS><br>
/// For example to move an RDN to a new parent: <br>
/// <EXAMPLE>
/// Set tRequest=##Class(EnsLib.LDAP.Message.Rename).%New()
/// Set tRequest.RDN="uid=Joe"
/// Set tRequest.Parent = "ou=QD Engineers,dc=SamplePerson,dc=local"
/// Set tRequest.NewParent = "ou=Engineers,dc=SamplePerson,dc=local"
/// Set tRequest.DeleteOldRDN = 1
/// <EXAMPLE> <br>
/// For example to rename an RDN: <br>
/// <EXAMPLE>
/// Set tRequest=##Class(EnsLib.LDAP.Message.Rename).%New()
/// Set tRequest.RDN="uid=Joe"
/// Set tRequest.NewRDN="uid=Joey"
/// Set tRequest.Parent = "ou=QD Engineers,dc=SamplePerson,dc=local"
/// Set tRequest.DeleteOldRDN = 1
/// <EXAMPLE>
Class EnsLib.LDAP.Message.Rename Extends (Ens.Request, EnsLib.LDAP.Message.EntityIdentification) [ System = 4 ]
{

/// New RDN. If left empty then NewParent will be applied to existing RDN
Property NewRDN As %String(MAXLEN = "");

/// Optional New Parent.
Property NewParent As %String(MAXLEN = "");

/// Delete old RDN after rename. Default is delete.
Property DeleteOldRDN As %Boolean [ InitialExpression = 1 ];

Storage Default
{
<Data name="RenameDefaultData">
<Subscript>"Rename"</Subscript>
<Value name="1">
<Value>DN</Value>
</Value>
<Value name="2">
<Value>NewParent</Value>
</Value>
<Value name="3">
<Value>DeleteOldRDN</Value>
</Value>
<Value name="4">
<Value>Base</Value>
</Value>
<Value name="5">
<Value>NewRDN</Value>
</Value>
<Value name="6">
<Value>Parent</Value>
</Value>
<Value name="7">
<Value>RDN</Value>
</Value>
</Data>
<DefaultData>RenameDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
