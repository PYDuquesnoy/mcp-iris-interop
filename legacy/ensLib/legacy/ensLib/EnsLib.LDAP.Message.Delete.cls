/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Request class to make an LDAP Delete request using operation <CLASS>EnsLib.LDAP.Operation.Standard</CLASS>
Class EnsLib.LDAP.Message.Delete Extends (Ens.Request, EnsLib.LDAP.Message.EntityIdentification) [ System = 4 ]
{

Storage Default
{
<Data name="DeleteDefaultData">
<Subscript>"Delete"</Subscript>
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
<DefaultData>DeleteDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
