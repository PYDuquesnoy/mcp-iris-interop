/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Request class to make an LDAP Modify request using operation <CLASS>EnsLib.LDAP.Operation.Standard</CLASS><br>
/// The properties allow adding, replacing or deleting attributes <br>
/// For example to add a uniqueMember:<br>
/// <EXAMPLE>
/// Set tRequest=##Class(EnsLib.LDAP.Message.Modify).%New()
/// Set tRequest.DN="cn=Administrators,ou=groups,ou=system"
/// Do tRequest.AddAttributes.SetAt("uniqueMember=uid=James,ou=Engineers,dc=SamplePerson,dc=local",1)
/// </EXAMPLE></br>
/// To delete a specific Attribute/Value pair specify the value<br>
/// To delete all attributes of specific name leave the value blank<br>
/// For example to remove an attribute/value pair: <br>
/// <EXAMPLE>
/// Set tRequest=##Class(EnsLib.LDAP.Message.Modify).%New()
/// Set tRequest.DN="cn=Administrators,ou=groups,ou=system"
/// 	 Do tRequest.DeleteAttributes.SetAt("uniqueMember=uid=James,ou=Engineers,dc=SamplePerson,dc=local",1)
/// </EXAMPLE>
Class EnsLib.LDAP.Message.Modify Extends (Ens.Request, EnsLib.LDAP.Message.EntityIdentification) [ System = 4 ]
{

/// Array of non Binary Attributes/Value pairs  to add.
Property AddAttributes As array Of %String(MAXLEN = "");

/// Array of Binary Attributes to add.
Property AddBinaryAttributes As array Of %String(MAXLEN = "");

/// Array of non Binary Attributes/Value pairs to replace.
Property ReplaceAttributes As array Of %String(MAXLEN = "");

/// Array of Binary Attributes/Value pairs to replace.
Property ReplaceBinaryAttributes As array Of %String(MAXLEN = "");

/// Array of Attributes/Value pairs to delete.
Property DeleteAttributes As array Of %String(MAXLEN = "");

Property DeleteBinaryAttributes As array Of %String(MAXLEN = "");

Storage Default
{
<Data name="AddAttributes">
<Attribute>AddAttributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Modify.AddAttributes"</Subscript>
</Data>
<Data name="AddBinaryAttributes">
<Attribute>AddBinaryAttributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Modify.AddBinaryAttributes"</Subscript>
</Data>
<Data name="DeleteAttributes">
<Attribute>DeleteAttributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Modify.DeleteAttributes"</Subscript>
</Data>
<Data name="DeleteBinaryAttributes">
<Attribute>DeleteBinaryAttributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Modify.DeleteBinaryAttributes"</Subscript>
</Data>
<Data name="ModifyDefaultData">
<Subscript>"Modify"</Subscript>
<Value name="1">
<Value>DN</Value>
</Value>
<Value name="2">
<Value>RDN</Value>
</Value>
<Value name="3">
<Value>Parent</Value>
</Value>
<Value name="4">
<Value>Base</Value>
</Value>
</Data>
<Data name="ReplaceAttributes">
<Attribute>ReplaceAttributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Modify.ReplaceAttributes"</Subscript>
</Data>
<Data name="ReplaceBinaryAttributes">
<Attribute>ReplaceBinaryAttributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Modify.ReplaceBinaryAttributes"</Subscript>
</Data>
<DefaultData>ModifyDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
