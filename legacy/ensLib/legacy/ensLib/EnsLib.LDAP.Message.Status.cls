/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// LDAP Status infomration returned by <CLASS>EnsLib.LDAP.Operation.Standard</CLASS>
Class EnsLib.LDAP.Message.Status Extends Ens.Response [ System = 4 ]
{

/// LDAP Status return code.
Property LastStatusCode As %Integer;

/// LDAP Status return code as Text
Property LastStatusText As %String(MAXLEN = "");

/// Categorization of LastStatusCode
Property LastStatusCategory As Ens.DataType.LDAP.StatusCategory;

/// %SYS.LDAP Method
Property LastCall As %String;

/// Used to record the generated  status
Property LastGeneratedStatus As %Status [ InitialExpression = {$$$OK} ];

/// This holds the pointer to the request message object.
/// It will be deleted when the request is purged.<br>
/// Not set for Comparison since Comparison already contains request details <br>
Property Request As Ens.Request(XMLCHOICELIST = "EnsLib.LDAP.Message.Search, EnsLib.LDAP.Message.Add,EnsLib.LDAP.Message.Modify,EnsLib.LDAP.Message.Delete,EnsLib.LDAP.Message.Rename,EnsLib.LDAP.Message.Compare", XMLTYPECONSTRAINT = "CHOICE");

Storage Default
{
<Data name="StatusDefaultData">
<Subscript>"Status"</Subscript>
<Value name="1">
<Value>LastStatusCode</Value>
</Value>
<Value name="2">
<Value>LastStatusText</Value>
</Value>
<Value name="3">
<Value>LastStatusCategory</Value>
</Value>
<Value name="4">
<Value>LastCall</Value>
</Value>
<Value name="5">
<Value>LastGeneratedStatus</Value>
</Value>
<Value name="6">
<Value>Request</Value>
</Value>
</Data>
<DefaultData>StatusDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
