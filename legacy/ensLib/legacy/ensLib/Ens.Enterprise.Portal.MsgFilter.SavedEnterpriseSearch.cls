/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.MsgFilter.SavedEnterpriseSearch Extends (%Persistent, EnsPortal.MsgFilter.SavedSearchBase) [ System = 4 ]
{

Parameter XMLTYPE = "EnterpriseSavedSearch";

Index Name On Name [ IdKey ];

/// Reference to the Filter object used to construct the eventual query.
Property Filter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter;

/// Callback to update %TimeModified and %ModifiedBy.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set i%%TimeModified = $$$timeUTC
	Set i%%ModifiedBy = $username
	Quit $$$OK
}

/// Update %TimeModified and %ModifiedBy for SQL modifications.
Trigger OnUpdate [ Event = INSERT/UPDATE ]
{
	Set {%TimeModified*N} = $$$timeUTC
	Set {%ModifiedBy*N} = $username
}

Storage Default
{
<Data name="SavedEnterpriseSearchDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%CreatedBy</Value>
</Value>
<Value name="3">
<Value>%TimeCreated</Value>
</Value>
<Value name="4">
<Value>%TimeModified</Value>
</Value>
<Value name="5">
<Value>%ModifiedBy</Value>
</Value>
<Value name="6">
<Value>Filter</Value>
</Value>
</Data>
<DataLocation>^Ens.Enterprise.SavedSearchD</DataLocation>
<DefaultData>SavedEnterpriseSearchDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Enterprise.SavedSearchD</IdLocation>
<IndexLocation>^Ens.Enterprise.SavedSearchI</IndexLocation>
<StreamLocation>^Ens.Enterprise.SavedSearchS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
