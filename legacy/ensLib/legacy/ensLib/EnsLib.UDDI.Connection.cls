/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// Represents a connection to a UDDI server
Class EnsLib.UDDI.Connection Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is the instance of the URLResolution Policy used to determine the inquiry,publication and security endpoints
Property URLResolutionPolicy As %ObjectHandle;

Property CustodyURL As %String [ ReadOnly ];

/// Accessof for the CustodyURL property
Method CustodyURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..URLResolutionPolicy.CustodyURL
}

Property PublicationURL As %String [ ReadOnly ];

/// Accessor for the PublicationURL property
Method PublicationURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..URLResolutionPolicy.PublicationURL
}

Property SubscriptionURL As %String [ ReadOnly ];

/// Accessor for the SubscriptionURL property
Method SubscriptionURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..URLResolutionPolicy.SubscriptionURL
}

Property InquiryURL As %String [ ReadOnly ];

/// Accessof for the InquiryURL property
Method InquiryURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..URLResolutionPolicy.InquiryURL
}

Property SecurityURL As %String [ ReadOnly ];

/// Accessor for the SecurityURL property
Method SecurityURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..URLResolutionPolicy.SecurityURL
}

Property AdminURL As %String [ ReadOnly ];

/// Accessor for the AdminURL property
Method AdminURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..URLResolutionPolicy.AdminURL
}

Property ReplicationURL As %String [ ReadOnly ];

/// Accessor for the ReplicationURL property
Method ReplicationURLGet() As %String
{
	#; Delegate to the URL resolution policy
	Quit ..URLResolutionPolicy.ReplicationUR
}

/// This is the authentication token needed for publishing
Property AuthInfo As %String;

/// This contains the user name to be used for this connection. It is only used if the AuthenticationMode property 
/// contains UddiAuthentication and ignored for all other values of the AuthenticationMode property. This property 
/// is only used for publishing operations and is not used for inquiry operations.
Property UserName As %String;

/// This contains the password to be used for this connection. It is only used if the AuthenticationMode property 
/// contains UddiAuthentication and ignored for all other values of the AuthenticationMode property. This property 
/// is only used for publishing operations and is not used for inquiry operations.
Property Password As %String;

Method AcquireAuthorization(pUserName As %String, pPassword As %String) As %Status
{
	#dim tSC As %Status
	#dim tAuthInfo As %String
	#dim tClient As EnsLib.UDDI.PublishSoap
	#dim tGetToken As EnsLib.UDDI.GetAuthToken
	
	$$$PROLOGUE
		 
	Set ..UserName=pUserName,..Password=pPassword
	
	#; Create a the web client instance
	$$$NEW(tClient,"EnsLib.UDDI.UDDISecuritySoapBinding")
	
	#; Set the location
	Set tClient.Location=..SecurityURL

	#; Want to retrieve an Authentication Token
	$$$NEW(tGetToken,"EnsLib.UDDI.GetAuthToken")
	
	#; Send the request to the Server
	Set tSC=tGetToken.Send(##this,.tAuthInfo)
	If $$$ISERR(tSC) Quit
	
	#; Success, cache the authorization token
	Set ..AuthInfo=tAuthInfo
		 
	$$$EPILOGUE
}

Method DiscardAuthorization() As %Status
{
	#dim tSC As %Status
	#dim tClient As EnsLib.UDDI.PublishSoap
	#dim tDiscardToken As EnsLib.UDDI.DiscardAuthToken
	
	$$$PROLOGUE 
		
	If ..AuthInfo'="" {
		
		#; Create a the web client instance
		$$$NEW(tClient,"EnsLib.UDDI.UDDISecuritySoapBinding")
		
		#; Set the location
		Set tClient.Location=..PublicationURL

		#; Want to retrieve an Authentication Token
		$$$NEW(tDiscardToken,"EnsLib.UDDI.DiscardAuthToken")
		
		#; Send the request to the Server
		Set tSC=tDiscardToken.Send(##this) 
		If $$$ISERR(tSC) Quit
	
		#; Nullify the Authentication token	
		Set ..AuthInfo=""
	}
		 
	$$$EPILOGUE
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	Quit ..DiscardAuthorization()
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
	Set ..URLResolutionPolicy=initvalue
	Quit $$$OK
}

}
