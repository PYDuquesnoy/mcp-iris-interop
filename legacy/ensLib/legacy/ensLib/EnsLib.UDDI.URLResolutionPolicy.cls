/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a policy for URL resolution. UDDI version 3 uses offers its services at 3 (possibly) different
/// configurable URLs. There is a URL for each of Inquiry, Publish and Security. This class implements a policy for resolving
/// the particular URLs. In the default implementaton, the strategy used is to append a string to a base url to determine
/// the url of the required service. Users requiring a differnt policy should subclass this class and encode their own strategy
/// by implementing the accessors for the Inquire, Publish and Security URL properties
Class EnsLib.UDDI.URLResolutionPolicy Extends %RegisteredObject [ System = 4 ]
{

/// This is the initialization string. For this implementation its the base URL of the server
Property InitializationString As %String;

Property CustodyURL As %String [ ReadOnly ];

/// Accessof for the CustodyURL property
Method CustodyURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..InitializationString_"/custody"
}

Property PublicationURL As %String [ ReadOnly ];

/// Accessor for the PublicationURL property
Method PublicationURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..InitializationString_"/publication"
}

Property SubscriptionURL As %String [ ReadOnly ];

/// Accessor for the SubscriptionURL property
Method SubscriptionURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..InitializationString_"/subscription"
}

Property InquiryURL As %String [ ReadOnly ];

/// Accessof for the InquiryURL property
Method InquiryURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..InitializationString_"/inquiry"
}

Property SecurityURL As %String [ ReadOnly ];

/// Accessor for the SecurityURL property
Method SecurityURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..InitializationString_"/security"
}

Property AdminURL As %String [ ReadOnly ];

/// Accessor for the AdminURL property
Method AdminURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..InitializationString_"/admin"
}

Property ReplicationURL As %String [ ReadOnly ];

/// Accessor for the ReplicationURL property
Method ReplicationURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..InitializationString_"/replication"
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..InitializationString=initvalue
	Quit $$$OK
}

}
