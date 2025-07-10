/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Define a PubSub subscription DomainName; This is used to maintain separate lists of subscriptions.
Class EnsLib.PubSub.DomainName Extends (%Persistent, %XML.Adaptor, %CSP.Util.AutoForm) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter XMLIGNORENULL = 1;

Parameter XMLNAME = "Domain";

Index NameIDX On Name [ IdKey ];

/// Name of this domain
Property Name As %String(MAXLEN = 100, XMLPROJECTION = "ATTRIBUTE");

/// Description of this domain
Property Description As %String(MAXLEN = 500, XMLPROJECTION = "ATTRIBUTE");

Query Enumerate() As %SQLQuery(CONTAINID = 1)
{
	SELECT ID,Name,Description
	FROM DomainName
 	ORDER BY Name
}

/// This callback is called when this form is submitted.
/// <var>pID</var> is the ID value associated with the form.
/// The default implementation will perform a Save if the AutoForm is a persistent object.<BR>
/// <var>pSubmit</var> is the name of the submit button (i.e., $AUTOFORM_SAVE).
Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status
{
	If ((pSubmit = "$AUTOFORM_DELETE") || (pSubmit = "$AUTOFORM_SAVE")) && '$system.Security.Check("%Ens_PubSub","WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	If (pSubmit = "$AUTOFORM_DELETE") {
		// delete this domain as well as related subscribers and subscriptions
		Set id = ..%Id()
		Set tSC = ##class(Utils).DeleteDomain(id)
		Quit $$$OK
	}

	If (pSubmit = "$AUTOFORM_SAVE") {
		// save this object
		Quit ..%Save()
	}
	
	Quit $$$OK
}

Storage Default
{
<Data name="DomainNameDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^EnsLib.PubSub.DomainNameD</DataLocation>
<DefaultData>DomainNameDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^EnsLib.PubSub.DomainNameD</IdLocation>
<IndexLocation>^EnsLib.PubSub.DomainNameI</IndexLocation>
<StreamLocation>^EnsLib.PubSub.DomainNameS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
