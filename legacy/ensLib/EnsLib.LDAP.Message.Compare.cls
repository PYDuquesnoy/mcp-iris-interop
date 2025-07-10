/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Request class to make an LDAP Compare request using operation <CLASS>EnsLib.LDAP.Operation.Standard</CLASS> <br>
/// To compare the mail value of "cn=anon,dc=test,dc=com" with 'anon@test.com': <br>
/// <EXAMPLE>
/// Set tRequest=##Class(EnsLib.LDAP.Message.Compare).%New()
/// Set tRequest.DN = "cn=anon,dc=test,dc=com"
/// Set tRequest.AttributeName = "mail"
/// Set tRequest.AttributeValue = "anon@test.com
/// </EXAMPLE> <br>
/// The operation returns the comparison result in <CLASS>EnsLib.LDAP.Message.Comparison</CLASS>
Class EnsLib.LDAP.Message.Compare Extends (Ens.Request, EnsLib.LDAP.Message.EntityIdentification) [ System = 4 ]
{

Parameter RESPONSECLASSNAME = "EnsLib.LDAP.Message.Comparison";

Property AttributeName As %String(MAXLEN = "");

Property AttributeValue As %String(MAXLEN = "");

Property AttributeIsBinary As %Boolean [ InitialExpression = 0 ];

Storage Default
{
<Data name="CompareDefaultData">
<Subscript>"Compare"</Subscript>
<Value name="1">
<Value>DN</Value>
</Value>
<Value name="2">
<Value>AttributeName</Value>
</Value>
<Value name="3">
<Value>AttributeValue</Value>
</Value>
<Value name="4">
<Value>AttributeIsBinary</Value>
</Value>
<Value name="5">
<Value>Base</Value>
</Value>
<Value name="6">
<Value>Parent</Value>
</Value>
<Value name="7">
<Value>RDN</Value>
</Value>
</Data>
<DefaultData>CompareDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
