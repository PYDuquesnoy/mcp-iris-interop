/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %SYS.OAuth2.Registration class contains the client side methods to support OpenID Connect
/// Discovery and Dynamic Client Registration.
Class %SYS.OAuth2.Registration Extends %RegisteredObject [ System = 4 ]
{

/// The Discover method uses the OpenID Connect Discovery protocol to obtain the server metadata
/// for a client.  The Discover method saves the server metadata in an existing or new OAuth2.ServerDefinition
/// instance for the specified issuerEndpoint.
ClassMethod Discover(issuerEndpoint As %String, sslConfiguration As %String, Output server As OAuth2.ServerDefinition) As %Status
{
	If '$system.Security.Check($$$AdminOAuth2ClientResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminOAuth2ClientResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	Set sc=$$$OK
	Set transaction=0
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Registration:Discover]","issuerEndpoint="_issuerEndpoint)

		Set sc=##class(OAuth2.ServerDefinition).GetServerMetadata(issuerEndpoint,$get(sslConfiguration),.metadata)

		If $$$ISOK(sc) {
			Set server=##class(OAuth2.ServerDefinition).OpenByIssuer(issuerEndpoint)
			If '$isobject(server) {
				Set server = ##class(OAuth2.ServerDefinition).%New()
			}
			Set server.IssuerEndpoint=issuerEndpoint
			Set server.SSLConfiguration=sslConfiguration
			Set server.IsDiscovery=1
		
			Tstart
			Set transaction=1
			If $isobject(server.Metadata) {
				Do ##class(OAuth2.Server.Metadata).%DeleteId(server.Metadata.%Id())
			}
			Set server.Metadata = metadata
			If metadata."jwks_uri"'="" {
				Do server.RefreshJWKS(1,,.sc)
				$$$ThrowOnError(sc)
			}

			Tcommit
			Set transaction=0
		}
	} Catch ex {
		If transaction {
			Trollback 1
			Set transaction=0
		}
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Registration:Discover]",0,sc)
	
	Quit sc
}

/// The RegisterClient method uses the OpenID Connect Dynamic Registration protocol to register the client
/// specified by applicationName.
/// The RegisterClient method saves the response properties and response client metadata in the OAuth2.Client instance.
ClassMethod RegisterClient(applicationName As %String) As %Status
{
	If '$system.Security.Check($$$AdminOAuth2ClientResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminOAuth2ClientResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Registration:RegisterClient]","applicationName="_applicationName)

		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		
		// is the client already registered? 
		If client.Metadata."registration_client_uri" '= "" {
			Set sc=$$$ERROR($$$OAuth2ClientAlreadyRegistered, applicationName)
		}
		Set sc=client.RegisterClient()
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Registration:RegisterClient]",0,sc)
	
	Quit sc
}

/// The ReadClient method uses the OpenID Connect Dynamic Registration protocol to read the client metadata
/// of a dynamically registered client.
/// The ReadClient method saves the response properties and response client metadata in the OAuth2.Client instance.
ClassMethod ReadClient(applicationName As %String) As %Status
{
	If '$system.Security.Check($$$AdminOAuth2ClientResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminOAuth2ClientResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Registration:ReadClient]","applicationName="_applicationName)

		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		
		Set sc=client.ReadClient()
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Registration:ReadClient]",0,sc)
	
	Quit sc
}

/// The UpdateClient method uses the Dynamic Client Registration protocol (RFC 7592) to uptate the client metadata
/// of a dynamically registered client on the server.
/// The UpdateClient method saves the updated response properties and response client metadata in the OAuth2.Client instance.
ClassMethod UpdateClient(applicationName As %String) As %Status
{
	If '$system.Security.Check($$$AdminOAuth2ClientResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminOAuth2ClientResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Registration:UpdateClient]","applicationName="_applicationName)

		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		
		Set sc=client.UpdateClient()
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Registration:UpdateClient]",0,sc)
	
	Quit sc
}

/// The DeleteClientRegistration method uses the Dynamic Client Registration protocol (RFC 7592) to delete the client metadata
/// of a dynamically registered client. The local OAuth2.Client instance is unchanged.
ClassMethod DeleteClientRegistration(applicationName As %String) As %Status
{
	If '$system.Security.Check($$$AdminOAuth2ClientResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminOAuth2ClientResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"OAuth2","[%SYS.OAuth2.Registration:DeleteClientRegistration]","applicationName="_applicationName)

		Set client=##class(OAuth2.Client).Open(applicationName,.sc)
		If client="" Quit
		
		Set sc=client.DeleteClientRegistration()
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISERR(sc) Do ##class(%OAuth2.Utils).LogError("[%SYS.OAuth2.Registration:DeleteClientRegistration]",0,sc)
	
	Quit sc
}

}
