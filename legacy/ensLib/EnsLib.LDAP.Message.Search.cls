/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Generic Ensemble Search class
Class EnsLib.LDAP.Message.Search Extends Ens.Request [ System = 4 ]
{

/// Search Base
Property SearchBase As %String(MAXLEN = "");

/// Search Filter
Property Filter As %String(MAXLEN = "");

/// Comma separated list of Attributes to return. If empty then all attributes.
Property AttributesToReturn As %String(MAXLEN = "");

/// Comma separate list of attributes in search that require Binary retrieval. Optional.
Property BinaryAttributes As %String(MAXLEN = "");

/// Only return Attribute names. Default is false
Property AttributesOnly As %Boolean [ InitialExpression = 0 ];

/// Scope of search. Default is 0/base
Property Scope As Ens.DataType.LDAP.Scope [ InitialExpression = 0 ];

/// Search time out default. If "" then the adapter will set the value
Property SearchTimeout As %Integer;

/// Search results Size Limit. If not set the adapter will set the value
Property SearchSizeLimit As %Integer;

/// Ensure process authenticates before searching. Default is to authenticate.
/// Set to "" if leave to adapter
Property Authenticate As %Boolean [ InitialExpression = 1 ];

/// Indicate if should ignore no such object in DIT
Property IgnoreObjectNotInDIT As %Boolean [ InitialExpression = 1 ];

/// Set this property to specify page size for paged searches.
Property PageSize As %Integer;

Storage Default
{
<Data name="SearchDefaultData">
<Subscript>"Search"</Subscript>
<Value name="1">
<Value>SearchBase</Value>
</Value>
<Value name="2">
<Value>Filter</Value>
</Value>
<Value name="3">
<Value>AttributesToReturn</Value>
</Value>
<Value name="4">
<Value>BinaryAttributes</Value>
</Value>
<Value name="5">
<Value>AttributesOnly</Value>
</Value>
<Value name="6">
<Value>Scope</Value>
</Value>
<Value name="7">
<Value>SearchTimeout</Value>
</Value>
<Value name="8">
<Value>SearchSizeLimit</Value>
</Value>
<Value name="9">
<Value>Authenticate</Value>
</Value>
<Value name="10">
<Value>IgnoreObjectNotInDIT</Value>
</Value>
<Value name="11">
<Value>PageSize</Value>
</Value>
</Data>
<DefaultData>SearchDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
