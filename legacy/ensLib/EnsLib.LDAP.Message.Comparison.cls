/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Response class to an LDAP Compare request made by operation <CLASS>EnsLib.LDAP.Operation.Standard</CLASS>
Class EnsLib.LDAP.Message.Comparison Extends EnsLib.LDAP.Message.Status [ System = 4 ]
{

/// Indicates if the comparison requested using EnsLib.LDAP.Message.Compare was true or false<br>
Property ComparesToServer As %Boolean;

/// UTC time the comparison was made.
Property ComparisonTimeUTC As Ens.DataType.UTC;

Storage Default
{
<Data name="ComparisonDefaultData">
<Subscript>"Comparison"</Subscript>
<Value name="1">
<Value>ComparesToServer</Value>
</Value>
<Value name="2">
<Value>ComparisonTimeUTC</Value>
</Value>
</Data>
<DefaultData>ComparisonDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
