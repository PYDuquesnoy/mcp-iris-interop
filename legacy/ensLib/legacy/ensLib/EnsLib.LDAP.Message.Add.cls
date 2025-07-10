/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Request class to make an LDAP Add request using operation <CLASS>EnsLib.LDAP.Operation.Standard</CLASS>
Class EnsLib.LDAP.Message.Add Extends (Ens.Request, EnsLib.LDAP.Message.EntityIdentification) [ System = 4 ]
{

/// Optional separate property of comma separate list of objectClasses<br>
/// Can be specified in Attributes.
Property objectClass As %String(MAXLEN = "");

/// Attributes is an array of strings where string is:<br>
/// AttributeName=Value <br>
/// and value is single value and attribtues with multiple values are
/// are entered as separate array elements.<br>
/// The exception to this requirement is if the AttributeName is objectClass
/// in which case the value can be a comma separate list of objectClasses <br>
/// <EXAMPLE>
/// Set tRequest=##Class(EnsLib.LDAP.Message.Add).%New()
/// Set tRequest.DN = "m-oid=1.2.840.113556.1.8000.2448.2.1,ou=attributetypes, cn=intersystems, ou=schema"
/// Set tRequest.objectClass="metaAttributeType,metaTop,top"
/// Set tCount = 0
/// Set tCount = tCount+1
/// Do tRequest.Attributes.SetAt("m-oid=1.2.840.113556.1.8000.2448.2.1",tCount)
/// Set tCount = tCount+1
/// Do tRequest.Attributes.SetAt("m-name=intersystems-Namespace",tCount)
/// Set tCount = tCount+1
/// Do tRequest.Attributes.SetAt("m-description=Default namespace a user connects to",tCount)
/// Set tCount = tCount+1
/// Do tRequest.Attributes.SetAt("m-equality=caseIgnoreMatch",tCount)
/// Set tCount = tCount+1
/// Do tRequest.Attributes.SetAt("m-substr=caseIgnoreSubstringsMatch",tCount)
/// Set tCount = tCount+1
/// Do tRequest.Attributes.SetAt("m-syntax=1.3.6.1.4.1.1466.115.121.1.15",tCount)
/// Set tCount = tCount+1
/// Do tRequest.Attributes.SetAt("m-singleValue=TRUE",tCount)
/// </EXAMPLE>
Property Attributes As array Of %String(MAXLEN = "");

/// BinaryAttributes is an array of strings where string is AttributeName=Value where
/// the value needs to be set as a binary.<br>
Property BinaryAttributes As array Of %String(MAXLEN = "");

Storage Default
{
<Data name="AddDefaultData">
<Subscript>"Add"</Subscript>
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
<Value name="5">
<Value>objectClass</Value>
</Value>
</Data>
<Data name="Attributes">
<Attribute>Attributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Add.Attributes"</Subscript>
</Data>
<Data name="BinaryAttributes">
<Attribute>BinaryAttributes</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.LDAP.Message.Add.BinaryAttributes"</Subscript>
</Data>
<DefaultData>AddDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
