/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a subscriber to a Publish / Subscribe list.
Class EnsLib.PubSub.Subscriber Extends (EnsLib.PubSub.Target, %CSP.Util.AutoForm) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Index NameIdx On (DomainName, Name) [ Unique ];

/// Subscriptions for this subscriber
Relationship Subscriptions As Subscription(XMLPROJECTION = "NONE") [ Cardinality = many, Inverse = Subscriber ];

/// Domain value used to keep this subscriber separate from others.
Property DomainName As DomainName(XMLNAME = "Domain", XMLPROJECTION = "ATTRIBUTE", XMLREFERENCE = "ID");

Method %OnNew(pResponse As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	// Make sure corresponding response is null
	Set ..%CorrespondingResponse = ""
	Quit $$$OK
}

/// Look up a subscriber object given a domain and subscriber name.
ClassMethod FindSubscriber(pDomain As %String = "", pName As %String) As Subscriber
{
	Set id = ..FindSubscriberId(pDomain,pName)
	Quit $S(id="":"",1:..%OpenId(id))
}

/// Look up a subscriber object id given a domain and subscriber name.
ClassMethod FindSubscriberId(pDomain As %String = "", pName As %String) As %String
{
	Set id = ""

	If (pDomain = "") {
		&SQL(SELECT %ID INTO :id 
			FROM Subscriber
			WHERE DomainName IS NULL AND Name = :pName)
	}
	Else {
		&SQL(SELECT %ID INTO :id 
			FROM Subscriber
			WHERE DomainName = :pDomain AND Name = :pName)
	}
	Quit id
}

/// Provide a list of subscribers.
Query Enumerate() As %SQLQuery(CONTAINID = 1)
{
	SELECT %ID,DomainName,Name,Target,Address
	FROM Subscriber
 	ORDER BY DomainName,Name
}

/// Provide a list of subscribers with domain names
Query SubscriberList() As %SQLQuery(CONTAINID = 1)
{
	SELECT %ID,
	CASE
	  WHEN DomainName IS NULL THEN Name
	  ELSE DomainName || '/' || Name
	END As Name
	FROM Subscriber
 	ORDER BY (DomainName),(Name)
}

Storage Default
{
<Data name="SubscriberDefaultData">
<Subscript>"Subscriber"</Subscript>
<Value name="1">
<Value>DomainName</Value>
</Value>
</Data>
<DefaultData>SubscriberDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
