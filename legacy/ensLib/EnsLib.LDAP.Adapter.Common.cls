/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syLDAP, EnsLDAP)

/// Ensemble base class for LDAP Adapter <CLASS>EnsLib.LDAP.Adapter.Outbound</CLASS>
Class EnsLib.LDAP.Adapter.Common Extends Ens.Adapter [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/* Properties that could be exposed as Settings */
/// Address of LDAP Server <br>
/// When connecting using <property>ConnectWithURIScheme</property> 
/// Multiple hosts can be specified separated by a space.
Property LDAPServer As %String(MAXLEN = "") [ InitialExpression = "127.0.0.1" ];

/// LDAP non SSL Port <br>
Property LDAPPort As %Integer [ InitialExpression = 389 ];

/// LDAP SSL Port. Used if Windows client connecting to OpenLDAP
Property LDAPSSLPort As %Integer [ InitialExpression = 636 ];

/// For a windows client, the certificate file should be loaded into the windows
/// certificate registry. For a unix client, we need to specify where the file in PEM-format is.
Property LDAPCACertFile As %String(MAXLEN = 1000);

/// Use External SASL Authentication. This will ensure start TLS is also used
Property UseSASLAuthentication As %Boolean [ InitialExpression = 0 ];

/// For SASL Authentication the Public Key File location when Unix or VMS Server
Property SASLPublicKeyFile As %String(MAXLEN = 1000);

/// For SASL Authentication the Private Key File location when Unix or VMS Server
Property SASLPrivateKeyFile As %String(MAXLEN = 1000);

/// Enable this by setting to true if the LDAP Server is a Windows Active Directory LDAP Server <br>
/// The default is false.
Property WindowsActiveDirectoryServer As %Boolean [ InitialExpression = 0 ];

/// This is the ID name of the set of credentials values to be used to access the LDAP server.<p>
/// The Username defined in your Credentials item may be either a fully qualified
/// username, e.g. 'CUser@subdomain.mydomain.com', or an LDAP RDN (Relatively Distinguished Name) path to the
/// user identity in the LDAP directory, e.g. 'CN=Carl User,OU=Users,OU=My Division,DC=subdomain,DC=mydomain,DC=com'
Property Credentials As %String;

/// If the Username in the Credentials object is a Windows domain\username then set this to false <br>
/// The default is true which indicates the Username in the Credentials object is the Distinguished Name of the user.<br>
Property CredentialsUsernameIsDN As %Boolean [ InitialExpression = 1 ];

/// Number of seconds to wait on each Search attempt
Property SearchTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// A limit on the number of entries to return from the search.
/// A value of zero means no limit. If you set this to some value, and the number of
/// results returned by the search is more than this, then the search may return
/// a size limit exceeded error. Note that the number of entries able to be returned
/// is also controlled by a parameter on the LDAP server. If the search returns more than this
/// limit, then a size limit exceeded error will also be returned.
Property SearchSizeLimit As %Numeric(MINVAL = 0) [ InitialExpression = 250 ];

/// Holds pointer to current credentials object used for bind calls.
Property %CurrentCredentialsObject As Ens.Config.Credentials [ InitialExpression = {$$$NULLOREF} ];

/// Multidimensional property to hold Server Credentials from SASLBinds call
Property %SASLServerCredentials [ MultiDimensional ];

/// Set to true to use SSL/TLS connection
/// Make sure you have a valid certificate file loaded to make this work.
/// When using/testing for the first time in your own environment, it is best to set this parameter
/// to 0 so that any connection issues can be differentiated from SSL/certificate issues.
Property UseSSL As %Boolean [ InitialExpression = 0 ];

/// Distinguished Name to use a a base for operations on the directory such as searches, updates and deletes.
Property BaseDN As %String(MAXLEN = 1000);

/// True if currently connected to LDAP server
Property Connected As %Boolean [ InitialExpression = 0, Transient ];

/// True if currently Authenticated to the LDAP server using binds
Property Authenticated As %Boolean [ InitialExpression = 0, Transient ];

/// This is used to identify if a connection was reset <br>
/// For example the LDAP Server was restarted in between requests or an idle connection was closed. <br>
/// Its value is determined in <method>HaveConnected</method>.<br>
/// It is used in methods <method>Search</method>,<method>SearchWithPages</method>,
/// <method>AddLDAPEntry</method>,<method>DeleteLDAPEntry</method>,<method>RenameLDAPEntry</method>,
/// <method>CompareLDAPEntryAttributeValue</method> to check for a stale connection and
/// allow for a silent reconnect. <br>
Property ThoughtToBeConnected As %Boolean [ InitialExpression = 0, Transient ];

/// This holds the LDAP Client session object.<br>
/// This object is the entry point to the primary LDAP methods offered by <class>%SYS.LDAP</class><br>
Property %LDAPSession As EnsLib.LDAP.Client.Session;

/// On Unix Servers it is possible to connect using the LDAP URI
/// scheme of ldap:// or ldaps:// <br>
/// Enable this to use the <class>%SYS.LDAP</class> method Initialize <br>
Property ConnectWithURIScheme As %Boolean [ InitialExpression = 0 ];

Method OnInit() As %Status
{
	#; Create an instance of the LDAP Session object
	Do ..%LDAPSessionNewObject()  $$$ASSERT($IsObject(..%LDAPSession))

	Quit ##super()
}

/* Over Written Property Set/Get methods */
Method ConnectedSet(pValue As %Boolean) As %Status
{
	Set i%Connected=pValue
	Set tPortInfoIfInit = $S(..ConnectWithURIScheme:"",..%LDAPSession.%startedSSL:":"_..LDAPSSLPort,1:":"_..LDAPPort)
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,pValue_"|"_$$$timeUTC_"|"_..LDAPServer_tPortInfoIfInit)
	#; Clear flags and handles if not connected
	If pValue=0 {

		Do ..%LDAPSession.ClearHandles()
		Set ..Authenticated = 0
		Set ..ThoughtToBeConnected = 0

	}

	Quit $$$OK
}

/* Connection Methods */
/// Connects to the LDAP Server by calling
/// InitializeConnection and call Authenticate.<br>
/// If already Connected and need to change binding call Authenticate directly.<br>
/// Connection and Authentication can be managed using <method>HaveConnected</method>
Method Connect(pAuthenticate As %Boolean = 1, pBindAsUser As Ens.Config.Credentials = {$$$NULLOREF}) As %Status
{
	#Dim tSC As %Status = $$$OK

	Try {

		$$$sysTRACE("Connect called with authenticate = "_pAuthenticate_" and current connected/authenticated state = "_..Connected_"/"_..Authenticated)
		If ..Connected {

			#; If need to change authentication (binding) either Disconnect or use HaveConnected()
			If ('pAuthenticate || ..Authenticated) Quit

		} Else {

			Set tSC = ..InitializeConnection()
			If $$$ISERR(tSC) Quit

		}

		#; Attempt to Bind as anonymous
		#dim tNoCredentials = (..%CredentialsObj = $$$NULLOREF)||($IsObject(..%CredentialsObj)&&(..%CredentialsObj.Username=""))
		If 'pAuthenticate  || tNoCredentials {

			Set pBindAsUser = ##class(Ens.Config.Credentials).%New()

		}

		Set tSC = ..Authenticate(pBindAsUser)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Inits the connection if not already connected
/// Starts TLS if <property>UseSSL</property> is true
/// or  <property>UseSASLAuthentication</property> is true.<br>
/// Called from within  <method>Connect</method>
Method InitializeConnection() As %Status
{
	#Dim tSC As %Status = $$$OK

	Try {

		If ..Connected Quit

		Set ..%LDAPSession.%startedSSL = 0

		
		If ..ConnectWithURIScheme {

			$$$sysTRACE("Initializing Connection to LDAP Server(s) '"_..LDAPServer_"' / "_..%CredentialsObj.Username)
			Set tSC = ..%LDAPSession.ldapInitialize(..LDAPServer, ..UseSSL )
			If $$$ISERR(tSC) Quit

		} Else {

			$$$sysTRACE("Initializing Connection to LDAP Server '"_..LDAPServer_":"_..LDAPPort_"' / "_..%CredentialsObj.Username)
			Set tSC = ..%LDAPSession.ldapInit(..LDAPServer, ..LDAPPort,..LDAPSSLPort,..UseSSL,..WindowsActiveDirectoryServer )
			If $$$ISERR(tSC) Quit

		}

		#;Start TLS if specified and we did not connect to SSL port in ldapInit()
		If (..UseSSL || ..UseSASLAuthentication)  && '..%LDAPSession.%startedSSL {

			If '$$$ISWINDOWS {
				If (..LDAPCACertFile = "") || '##class(%File).Exists(..LDAPCACertFile)  {
					Set tSC = $$$EnsError($$$EnsErrGeneral,..LDAPCACertFile)
					Quit
				}

				Set tSC = ..%LDAPSession.ldapSetOption($$$LDAPOPTXTLSCACERTFILE,..LDAPCACertFile)
				If $$$ISERR(tSC) Quit

			}

			If '..ConnectWithURIScheme {

				Set tSC = ..%LDAPSession.ldapStartTLSs()
				If $$$ISERR(tSC) Quit

			}

		}

	} Catch {

		Set tSC = $$$SystemError
		#; Exit method
		Return tSC
	}

	If $$$ISERR(tSC)  {

		If $$$ISERR(tSC) Set tSC = $$$ERROR($$$EnsErrOutConnectFailed,$$$StatusText(tSC),"LDAP","'"_..LDAPServer_":"_..LDAPPort_"'/'"_..%CredentialsObj.Username_"'")

	} Else {

		Set ..Connected=1

		If ..BusinessHost.%LastReportedError [ "ERROR <Ens>ErrOutConnect" {
			Set ..BusinessHost.%LastReportedError=""
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
		}

	}

	Quit tSC
}

/// Authenticate via Binds/SimpleBinds/SASLBinds. <br>
/// If we pass in a pBindAsUser <class>Ens.Config.Credentials</class> object
/// then bind as that if different from current bind user.<br>
/// If pBaindAsUser is an empty instantiated <class>Ens.Config.Credentials</class> object
/// (Username and Password are blank) then we bind as anonymous.<br>
/// We do not allow empty password and non empty Username as this can lead to
/// misleading anonymous successful bind.<br>
/// This method uses <property>WindowsActiveDirectoryServer</property> and
/// <property>CredentialsUsernameIsDN</property><br>
Method Authenticate(pBindAsUser As Ens.Config.Credentials = {$$$NULLOREF}) As %Status
{
	#Dim tSC As %Status = $$$OK

	Try {

		If (pBindAsUser=$$$NULLOREF) && '$IsObject(..%CredentialsObj) && '..UseSASLAuthentication {
			Do ..CredentialsSet(..Credentials)
			If '$IsObject(..%CredentialsObj)  Return $$$EnsError($$$EnsErrNoCredentials,..Credentials)
		}

		#;Unauthenticated Bind
		If $IsObject(pBindAsUser) && (pBindAsUser.Password = "") {

			Set tSC = ..SimpleBinds(pBindAsUser)

		} ElseIf ..UseSASLAuthentication {

			Set tSC = ..SASLBinds()

		} ElseIf $$$ISWINDOWS && ..WindowsActiveDirectoryServer && '..CredentialsUsernameIsDN {

			Set tSC = ..Binds(pBindAsUser)

		} Else {

			Set tSC = ..SimpleBinds(pBindAsUser)

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Binds to the LDAP Server using either passed in pBindAsUser or current ..%CredentialsObj<br>
/// We do not allow empty password and non empty Username as this can lead to
/// misleading anonymous successful bind<br>
Method Binds(pBindAsUser As Ens.Config.Credentials = {$$$NULLOREF}) As %Status
{
	#dim tSC As %Status = $$$OK

	#dim tDomain As %String
	#dim tDomainUsername As %String

	#dim tCredentialsObject As Ens.Config.Credentials
	Set ..%CurrentCredentialsObject = $$$NULLOREF

	If $IsObject(pBindAsUser) {
		Set tCredentialsObject = pBindAsUser
	} Else {
		Set tCredentialsObject = ..%CredentialsObj
	}

	Set ..Authenticated = 0

	#;Check if Password empty and Username specified.
	If (tCredentialsObject.Password="") &&(tCredentialsObject.Username'="") {
		Quit $$$ERROR($$$EnsLDAPErrGeneral,"Binds","Password cannot be empty","","")
	}

	#;Credentials username expected in format Domain\Username or Username@Domain

	If tCredentialsObject.Username["@" {
		Set tDomain  = $Piece(tCredentialsObject.Username,"@")
		Set tDomainUsername = $Piece(tCredentialsObject.Username,"@",2)
	} Else {
		Set tDomain  = $Piece(tCredentialsObject.Username,"\")
		Set tDomainUsername = $Piece(tCredentialsObject.Username,"\",2)
	}
	#; No domain specified
	If tDomainUsername = "" Set tDomainUsername = tDomain, tDomain = ""

	Set tSC = ..%LDAPSession.ldapBinds(tDomainUsername, tDomain, tCredentialsObject.Password)

	If $$$ISOK(tSC) {
		Set ..Authenticated = 1
		Set ..%CurrentCredentialsObject = tCredentialsObject
	}

	Quit tSC
}

/// SimpleBinds to the LDAP Server using either passed in pBindAsUser or current ..%CredentialsObj
/// We do not allow empty password and non empty Username as this can lead to
/// misleading anonymous successful bind.<br>
Method SimpleBinds(pBindAsUser As Ens.Config.Credentials = {$$$NULLOREF}) As %Status
{
	#dim tSC As %Status = $$$OK

	#dim tCredentialsObject As Ens.Config.Credentials
	Set ..%CurrentCredentialsObject = $$$NULLOREF

	If $IsObject(pBindAsUser) {
		Set tCredentialsObject = pBindAsUser
	} Else {
		Set tCredentialsObject = ..%CredentialsObj
	}

	Set ..Authenticated = 0

	#;Check if Password empty and Username specified.
	If (tCredentialsObject.Password="") &&(tCredentialsObject.Username'="") {
		Quit $$$ERROR($$$EnsLDAPErrGeneral,"SimpleBinds","Password cannot be empty","","")
	}

	#;Credentials username expected in DN format

	Set tSC = ..%LDAPSession.ldapSimpleBinds(tCredentialsObject.Username,tCredentialsObject.Password)

	If $$$ISOK(tSC) {
		#; If Username is "" then anonymous
		If tCredentialsObject.Username '= "" Set ..Authenticated = 1
		Set ..%CurrentCredentialsObject = tCredentialsObject
	}

	Quit tSC
}

/// SASLBinds to the LDAP Server.
Method SASLBinds(pSASLPublicKeyFile As %String = {..SASLPublicKeyFile}, pSASLPrivateKeyFile As %String = {..SASLPrivateKeyFile}) As %Status
{
	#dim tSC As %Status = $$$OK

	Set ..Authenticated = 0
	Kill ..%SASLServerCredentials

	If $$$ISUNIX || $$$ISVMS {

		Set tSC = ..%LDAPSession.ldapSetOption($$$LDAPOPTXTLSCERTFILE,pSASLPublicKeyFile)
		If $$$ISERR(tSC) Quit tSC

		Set tSC = ..%LDAPSession.ldapSetOption($$$LDAPOPTXTLSKEYFILE,pSASLPrivateKeyFile)
		If $$$ISERR(tSC) Quit tSC

	}

	#dim tServerCredentials As %String

	Set tSC = ..%LDAPSession.ldapSASLBinds(.tServerCredentials)

	If $$$ISOK(tSC) {

		Merge ..%SASLServerCredentials = tServerCredentials
		Set ..Authenticated = 1

	}

	Quit tSC
}

/// Disconnect from the LDAP Server and clean up. <br>
Method Disconnect() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tSC1 As %Status = $$$OK
	#Dim ex As %Exception.AbstractException

	Try {

		Quit:'..Connected
		$$$sysTRACE("Disconnecting from "_..LDAPServer_":"_..LDAPPort)

		If ($$$ISWINDOWS) && (..%LDAPSession.%Page > 0) {
			#;Clean up paged search: ldaMsgFree is called at start of abandon page
			Set tSC = ..%LDAPSession.ldapSearchAbandonPage()
		} Else {
			Set tSC = ..%LDAPSession.ldapMsgFree()
		}

		If $$$ISWINDOWS && ..%LDAPSession.%startedSSL {
			Set tSC1 = ..%LDAPSession.ldapStopTLSs()
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC1,tSC)
		}

		If '$$$ISWINDOWS && ..%LDAPSession.%startedSSL {
			Set tSC1 = ..%LDAPSession.ldapSetOption($$$LDAPOPTXTLSNEWCTX,0)
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC1,tSC)
		}

		Set tSC1 = ..%LDAPSession.ldapUnBinds()
		If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC1,tSC)

		#; Authenticated & ThoughtToBeConnected value will be cleared in ConnectedSet()
		Set ..Connected = 0

		Set ..%CurrentCredentialsObject = $$$NULLOREF

		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC)

	} Catch  ex {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Returns true if Connected and Authentication status is same as requested.<br>
/// On entry this method will try to connect if not connected using the requested authentication<br>
/// If connected it attempts to change the authentication of the connection to that requested if different from current authentication.<br>
/// It is intended to be called by LDAP operation methods that require connection and are the first (or only)
/// method in a series of related LDAP operation calls <br>
Method HaveConnected(Output pStatus As %Status, pAuthenticate As %Boolean = 1, pBindAsUser As Ens.Config.Credentials = {..%CurrentCredentialsObject}) As %Boolean
{
	Set pStatus = $$$OK
	#dim tDisconnectStatus As %Status = $$$OK

	/*	Assume already connected.
		This is use because ConnectionIsValid() only checks if
		LDAP Session is valid. We do not do a 'ping' to the LDAP server.
		Such a 'ping' might be a simple search but we would need to do
		each call so we wait until we have an Unavailable error and check
		'ThoughtToBeConnected' in those methods that call HaveConnected()
	*/
	Set ..ThoughtToBeConnected = 1

	If ..Connected && '..ConnectionIsValid() {

		Set tDisconnectStatus = ..Disconnect()
	}

	If '..Connected {

		Set ..ThoughtToBeConnected = 0

		Set pStatus = ..Connect(pAuthenticate,pBindAsUser)
		#; If we received an error then add in any disconnect status error we might have to help.
		If $$$ISERR(pStatus) Set pStatus = $$$ADDSC(tDisconnectStatus,pStatus)

		Return (..Connected && (pAuthenticate=..Authenticated))

	} ElseIf ..Authenticated  && pAuthenticate {

		If (pBindAsUser = ..%CurrentCredentialsObject) Return $$$OK

	} ElseIf ..Authenticated  && 'pAuthenticate {

			#; Switch to Anonymous
			Set pBindAsUser = ##class(Ens.Config.Credentials).%New()

	}

	#; We were already connected but need to change bound user
	Set pStatus = ..Authenticate(pBindAsUser)

	#; If we received an error then add in any disconnect status error we might have to help.
	If $$$ISERR(pStatus) Set pStatus = $$$ADDSC(tDisconnectStatus,pStatus)

	Quit (..Connected && (pAuthenticate=..Authenticated))
}

/// Used to test if really connected.<br>
/// Rather than try a 'ping' call each time we are using
/// the ThoughtToBeConnected property.<br>
Method ConnectionIsValid() As %Boolean
{
	If '..SessionHandleIsValid() Quit 0
	Quit 1
}

Method SessionHandleIsValid() As %Boolean
{
	#; 20488 is "No such session handle."
	Return (##class(%SYS.LDAP).GetError(..%LDAPSession.%Session) '= 20488)
}

/* LDAP Search Functionality */
/// Searches LDAP Server after connection test.<br>
/// Call <method>CreateResultsArray</method> to retrieve results.<br><br>
/// Output pCountOfEntries - result of ldapCountEntries after search if pCountResults is true<br>
/// pScope: 0=search base, 1=search one level,  2=search subtree. The default is sub tree <br>
/// pFilter: the search criteria <a href=http://www.ietf.org/rfc/rfc2254.txt>(see RFC2254).</a> <br>
/// pAttrs: list of attributes to return per found entry. <br>
/// pAttributesOnly  default is no <br>
/// pSearchTimeout default to <property>SearchTimeout</property> <br>
/// pMaxItems default to <property>SearchSizeLimit <br>
/// pBase default is the <property>BaseDN</property> <br>
/// pCountResults Default is true <br>
/// pAuthenticate - if true (default) use Credentials else use anonymous
Method Search(Output pCountOfEntries As %Integer = -1, pScope As %Integer = {$$$LDAPSCOPESUBTREE}, pFilter As %String = "", pAttrs As %List = "", pAttributesOnly As %Boolean = 0, pSearchTimeout = {..SearchTimeout}, pMaxItems As %Integer = {..SearchSizeLimit}, pBase As %String = {..BaseDN}, pCountResults As %Boolean = 1, pAuthenticate As %Boolean = 1) As %Status
{

	#dim tSC As %Status = $$$OK
	#dim tSC1 As %Status = $$$OK

	Try {

		Quit:'..HaveConnected(.tSC,pAuthenticate)

		#; Free any existing Results
		Set tSC = ..%LDAPSession.ldapMsgFree()
		If $$$ISERR(tSC) Quit

		#dim tScope As %Integer = $Case(pScope,0:$$$LDAPSCOPEBASE,1:$$$LDAPSCOPEONELEVEL,:$$$LDAPSCOPESUBTREE)

		#dim tRetryLDAPOperation As %Boolean = 1
		Do {

			Set tSC = ..%LDAPSession.ldapSearchExts(pBase,tScope,pFilter,pAttrs,pAttributesOnly,pSearchTimeout,pMaxItems)

			#; We will only do the reconnect attempt once since Disconnect sets ThoughtToBeConnected to 0
			If $$$ISERR(tSC) &&
				(..%LDAPSession.LastStatusCategory=$$$EnsLDAPStatusUnavailable) &&
				..ThoughtToBeConnected {

					$$$sysTRACE("Detected change in existing connection. Reconnecting and Retrying once.")

					#; Disconnect, then reconnect and try again.
					Do ..Disconnect()
					Quit:'..HaveConnected(.tSC,pAuthenticate)

			} Else {

				Set tRetryLDAPOperation = 0
			}

		} While tRetryLDAPOperation

		If $$$ISOK(tSC) && pCountResults {
			Set tSC = ..%LDAPSession.ldapCountEntries(.pCountOfEntries)
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// SearchWithPages only valid on a Windows instance<br>
/// Call <method>CreateResultsArray</method> to retrieve results.<br><br>
/// Method to call ldapSearchInitPage after checking connected and cleans outstanding page search if there is one <br>
/// pScope: 0=search base, 1=search one level,  2=search subtree. The default is sub tree <br>
/// pFilter: the search criteria <a href=http://www.ietf.org/rfc/rfc2254.txt>(see RFC2254).</a> <br>
/// pAttrs: list of attributes to return per found entry. <br>
/// pAttributesOnly  default is no <br>
/// pSearchTimeout default to <property>SearchTimeout</property> <br>
/// pPageSize - if specified a paged search will be initiated if supported by the platform  (Windows only)<br>
/// pBase default is the <property>BaseDN</property> <br>
/// pCountResults Default is true <br>
/// pAuthenticate - if true (default) use Credentials else use anonymous
Method SearchWithPages(pScope As %Integer = {$$$LDAPSCOPESUBTREE}, pFilter As %String = "", pAttrs As %List = "", pAttributesOnly As %Boolean = 0, pSearchTimeout As %Integer = {..SearchTimeout}, pPageSize As %Integer = 100, pBase As %String = {..BaseDN}, pAuthenticate As %Boolean = 1) As %Status
{

	#dim tSC As %Status = $$$OK

	Try {

		Quit:'..HaveConnected(.tSC,pAuthenticate)

		#; Free any existing Results
		Set tSC = ..%LDAPSession.ldapSearchAbandonPage()
		If $$$ISERR(tSC) Quit

		#dim tScope As %Integer = $Case(pScope,0:$$$LDAPSCOPEBASE,1:$$$LDAPSCOPEONELEVEL,:$$$LDAPSCOPESUBTREE)

		#dim tRetryLDAPOperation As %Boolean = 1
		Do {

			Set tSC = ..%LDAPSession.ldapSearchInitPage(pBase,tScope,pFilter,pAttrs,pAttributesOnly,pSearchTimeout,pPageSize)

			#; We will only do the reconnect attempt once since Disconnect sets ThoughtToBeConnected to 0
			If $$$ISERR(tSC) &&
				(..%LDAPSession.LastStatusCategory=$$$EnsLDAPStatusUnavailable) &&
				..ThoughtToBeConnected {

					$$$sysTRACE("Detected change in existing connection. Reconnecting and Retrying once.")

					#; Disconnect, then reconnect and try again.
					Do ..Disconnect()
					Quit:'..HaveConnected(.tSC,pAuthenticate)

			} Else {

				Set tRetryLDAPOperation = 0
			}

		} While tRetryLDAPOperation

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Method to call ldapCountEntries for current Results
Method CountResults(Output pTotal As %Integer) As %Status
{
	If '..Connected || '..%LDAPSession.%Results Quit $$$ERROR($$$GeneralError,"No Results to count")

	Quit ..%LDAPSession.ldapCountEntries(.pTotal)
}

/// Gets the first entry and populate <property>%CurrentDN</property> of the result.
/// If status returns is OK and %CurrentDN is empty then no results.
Method FirstEntryDN() As %Status
{
	#dim tSC As %Status = $$$OK

	#dim tDN As %String = ""

	Try {

		Set ..%LDAPSession.%CurrentDN = ""

		Set tSC = ..%LDAPSession.ldapFirstEntry()

		If $$$ISOK(tSC) && ('..%LDAPSession.%ResultsAtEnd) {
			Set tSC = ..%LDAPSession.ldapGetDN(.tDN)
			If $$$ISOK(tSC) Set ..%LDAPSession.%CurrentDN = tDN
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Return values for specified pAttributeName.<br>
/// By specifying pAttributeIsBinary as false (the default) a string ldapGetValues will be called<br>
/// By specifying pAttributeIsBinary as true a binary ldapGetValuesLen will be called<br>
/// The default is not binary<br>
Method GetValues(pAttributeName As %String, Output pAttributeValues As %List, pAttributeIsBinary As %Boolean = 0) As %Status
{
	#dim tSC As %Status = $$$OK

	Try {

		If pAttributeIsBinary {

			Set tSC = ..%LDAPSession.ldapGetValuesLen(pAttributeName,.pAttributeValues)

		} Else {

			Set tSC = ..%LDAPSession.ldapGetValues(pAttributeName,.pAttributeValues)

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Gets the Next entry and populate DN of the result.
/// If status returns is OK and DN is empty then no more.
Method NextEntryDN() As %Status
{
	#dim tSC As %Status = $$$OK

	#dim tDN As %String = ""

	Try {

		Set ..%LDAPSession.%CurrentDN = ""
		Set tSC = ..%LDAPSession.ldapNextEntry()

		If $$$ISOK(tSC) && ('..%LDAPSession.%ResultsAtEnd) {
			Set tSC = ..%LDAPSession.ldapGetDN(.tDN)
			If $$$ISOK(tSC) Set ..%LDAPSession.%CurrentDN = tDN
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/* LDAP Update Functionality */
/// Adds a new entry to an LDAP Server after connection test.<br><br>
/// See <method>AddNewEntryParmArray</method> and <method>AddNewEntry</method>
/// which will generate the correct $LIST formats and then call this method.<br><br><br>
/// Comments concerning this method's parameters are taken from <class>%SYS.LDAP</class>
/// method AddExts. <br>
/// Add an entry to the LDAP directory tree.<br><br>
/// Parameters:<br><br>
/// pDN - String that contains the distinguished name of the entry
/// to add. <br><br>
/// pAttributeChanges - $list formatted with attributes to add to the new entry.<br>
/// Each element in the list is a separate attribute to be added to the new entry.<br>
/// Attribute=$lb(op,type,vals)<br>
/// op - For create, set to 0. However, if the vals parameter is to be treated
/// as binary, then pass in 128 for this parameter.<br>
/// type - Name of the attribute. Example="Telephone". <br>
/// vals - $list of the values to assign to the attribute. If this is a single entry
/// attribute, then $lb(Value), Example=$lb("617-621-0600"). If a multi-value entry, then
/// $lb(Value1,Value2,...,Valuen). If the data is to be treated as binary (e.g. jpeg file),
/// then make sure that 128 is passed for the op.<br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Examples:<br><br>
/// s Attr1=$lb(0,"displayName",$lb(Jim Nilson))<br>
/// s Attr2=$lb(0,"telephoneNumber",$lb("617-621-0600")<br>
/// s Attr3=$lb(0,"objectClass",$lb("top","person","organizationalPerson","user")<br>
/// s Attr4=$lb(128,"Picture",$lb(Jpegbitstring))<br>
/// s Attributes=$lb(Attr1,Attr2,Attr3,Attr4)<br>
/// ; Note the special character identifier "\" which is needed before the "," in the name<br>
/// s DN="CN=Nilson\, Jim,OU=Users,OU=England,DC=iscinternal,DC=com"<br>
Method AddLDAPEntry(pDN As %String = "", pAttributeChanges As %List) As %Status
{

	#dim tSC As %Status =$$$OK
	#dim tSC1 As %Status = $$$OK

	Try {

		Quit:'..HaveConnected(.tSC)

		#dim tRetryLDAPOperation As %Boolean = 1
		Do {

			Set tSC = ..%LDAPSession.ldapAddExts(pDN, pAttributeChanges)

			#; We will only do the reconnect attempt once since Disconnect sets ThoughtToBeConnected to 0
			If $$$ISERR(tSC) &&
				(..%LDAPSession.LastStatusCategory=$$$EnsLDAPStatusUnavailable) &&
				..ThoughtToBeConnected {

					$$$sysTRACE("Detected change in existing connection. Reconnecting and Retrying once.")

					#; Disconnect, then reconnect and try again.
					Do ..Disconnect()
					Quit:'..HaveConnected(.tSC)

			} Else {

				Set tRetryLDAPOperation = 0
			}

		} While tRetryLDAPOperation

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Modify LDAP Entry with distinguished name of pDN after connection test.<br><br>
/// See <method>ModifyEntryParmArray</method> and <method>ModifyEntry</method>
/// which will generate the correct $LIST formats and then call this method.<br><br><br>
/// Comments concerning this method's parameters are taken from <class>%SYS.LDAP</class>
/// method ModifyExts. <br>
/// pAttributesChanges is a$list formatted with attributes to modify in the new entry.<br><br>
/// Each element in the list is a separate attribute to be modified in the new entry.<br>
/// Attribute=$lb(op,type,vals)<br>
/// op - Operation to be performed as follows:<br>
/// 0 - Add - The given values are added to the entry, creating the attribute if necessary.<br>
/// 1 - Delete - The given values are deleted from the entry, removing the attribute if no values remain. If the entire
/// attribute is to be deleted, the mod_values field should be set to NULL ($lb("")).<br>
/// 2 - Replace - The attribute will have the listed values after the modification, having been created if necessary. If set
/// to null, then the attribute is deleted.<br>
/// 128 - This value should be combined (ORed) with the Add/Delete/Replace value if the data to
/// be inserted is Binary (e.g. jpeg file.)<br>
/// type - Name of the attribute. Example="Telephone". <br>
/// vals - $list of the values to assign to the attribute. If this is a single entry
/// attribute, then $lb(Value), Example=$lb("617-621-0600"). If a multi-value entry, then
/// $lb(Value1,Value2,...,Valuen). <br><br>
/// ServerControls - Ignored, pass as "".<br><br>
/// ClientControls - Ignored, pass as "".<br><br>
/// Return Values:<br><br>
/// If the function succeeds, $$$LDAPSUCCESS is returned.<br>
/// If the function fails, an error code is returned.<br><br>
/// Examples:<br><br>
/// s Attr1=$lb(0,"displayName",$lb(Jim Nilson))<br>
/// s Attr2=$lb(0,"telephoneNumber",$lb("617-621-0600")<br>
/// ; Replace the Objectclass attribute<br>
/// s Attr3=$lb(2,"objectClass",$lb("top","person","organizationalPerson","user")<br>
/// ;Replace Binary value for a jpeg photo<br>
/// s Attr4=$lb(130,"Photo",$lb(jpegphoto))<br>
/// ; Delete Address2 attribute<br>
/// a Attr5=$lb(1,"Address2","")<br>
/// s Attributes=$lb(Attr1,Attr2,Attr3,Attr4,Attr5) <br>
/// s DN="CN=Nilson\, Jim,OU=Users,OU=England,DC=iscinternal,DC=com"<br>
/// Note:<br>
/// Changing a password on a Windows Active Directory LDAP server.<br>
/// The user must first be created before the
/// password change can take place, and the password change must take place over an
/// encrypted channel. The password is contained in the unicodePwd attribute, and must
/// be formatted in a specific way. When initially creating the user, the unicodePwd
/// attribute must not be specified, or the creation of the user will fail.<br>
/// To format the password, a leading and trailing double quote must be added to it.
/// Then it must be converted to unicode.
/// Then when passed into the modify function, it must be passed in as a binary value,
/// with the "Replace" operation. It must be the only operation contained in the modify call;
/// No other attribute can be changed at the same time.<br><br>
/// s password="NewPassword"<br>
/// s ChangePassword=$zcvt(""""_password_"""","o","UnicodeLittle")<br>
/// s Attr1=$lb(130,"unicodePwd",$lb(ChangePassword))<br>
/// s Attributes=$lb(Attr1)<br>
/// Note: In order to change a password, the user must have binded to the LDAP server
/// with an account which has administrator privilege on the system. The password
/// which is set must also pass any length or pattern requirements imposed by the
/// security system on the LDAP server.<br><br>
/// Changing your own password on a Windows Active Directory LDAP server is similar to above,
/// except that you need to bind to the LDAP server using your own username, and must also
/// pass in the old password with the delete attribute. These must also be the only
/// two attributes passed in the modify method.<br><br>
/// s oldpassword="OldPassword"<br>
/// s password="NewPassword"<br>
/// s ChangeOldPassword=$zcvt(""""_oldpassword_"""","o","UnicodeLittle")<br>
/// s ChangeNewPassword=$zcvt(""""_password_"""","o","UnicodeLittle")<br>
/// s Attr1=$lb(128,"unicodePwd",$lb(ChangeOldPassword))<br>
/// s Attr2=$lb(129,"unicodePwd",$lb(ChangePassword))<br>
/// s Attributes=$lb(Attr1,Attr2)<br>
Method ModifyLDAPEntry(pDN As %String = "", pAttributeChanges As %List) As %Status
{

	#dim tSC As %Status =$$$OK
	#dim tSC1 As %Status = $$$OK

	Try {

		Quit:'..HaveConnected(.tSC)

		#dim tRetryLDAPOperation As %Boolean = 1
		Do {

			Set tSC = ..%LDAPSession.ldapModifyExts(pDN, pAttributeChanges)

			#; We will only do the reconnect attempt once since Disconnect sets ThoughtToBeConnected to 0
			If $$$ISERR(tSC) &&
				(..%LDAPSession.LastStatusCategory=$$$EnsLDAPStatusUnavailable) &&
				..ThoughtToBeConnected {

					$$$sysTRACE("Detected change in existing connection. Reconnecting and Retrying once.")

					#; Disconnect, then reconnect and try again.
					Do ..Disconnect()
					Quit:'..HaveConnected(.tSC)

			} Else {

				Set tRetryLDAPOperation = 0
			}

		} While tRetryLDAPOperation

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Delete an Entry on an LDAP server with Distinguished name of pDN after connection test.<br>
Method DeleteLDAPEntry(pDN As %String = "") As %Status
{
	#dim tSC As %Status =$$$OK

	Try {

		If pDN  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required DN for Delete Entry needed")
			Quit
		}

		Quit:'..HaveConnected(.tSC)

		#dim tRetryLDAPOperation As %Boolean = 1
		Do {

			Set tSC = ..%LDAPSession.ldapDeleteExts(pDN)

			#; We will only do the reconnect attempt once since Disconnect sets ThoughtToBeConnected to 0
			If $$$ISERR(tSC) &&
				(..%LDAPSession.LastStatusCategory=$$$EnsLDAPStatusUnavailable) &&
				..ThoughtToBeConnected {

					$$$sysTRACE("Detected change in existing connection. Reconnecting and Retrying once.")

					#; Disconnect, then reconnect and try again.
					Do ..Disconnect()
					Quit:'..HaveConnected(.tSC)

			} Else {

				Set tRetryLDAPOperation = 0
			}

		} While tRetryLDAPOperation

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Delete current LDAP Entry
Method DeleteCurrentLDAPEntry() As %Status
{
	#dim tSC As %Status =$$$OK

	Try {

		#; Check have a current result.
		If ..%LDAPSession.%CurrentDN = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required Current DN needed")
		} Else {
			Set tSC = ..%LDAPSession.ldapDeleteExts(..%LDAPSession.%CurrentDN)
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Rename or move an entry using a new relative distinguished name or a new parent.<br>
/// Specify new parent if not using relative to existing.<br>
/// pRDN is the relative distinguished name or the distinguished name to rename/move<br>
/// pNewRDN is the new relative distinguished name.<br>
/// pNewParent is an optional new parent to move the item to<br>
/// pDeleteOld indicates if the entry that is being renamed or moved is to be deleted<br>
/// pBase is the base to apply to pRDN. If not specified it defaults to the setting BaseDN<br>
/// pEscapeNew will Escape non empty values of pNewRDN and pNewParent. The default is True.<br>
Method RenameLDAPEntry(pRDN As %String, pNewRDN As %String = "", pNewParent As %String = "", pDeleteOld As %Boolean = 1, pBase As %String = {..BaseDN}, pEscapeNew As %Boolean = 1) As %Status
{
	#dim tSC As %Status =$$$OK

	Try {

		Quit:'..HaveConnected(.tSC)

		#dim tDNtoRename As %String = ##class(EnsLib.LDAP.Util.General).GenerateDNFromRDNandParent(pRDN,pBase,0)

		If (pNewRDN="") && (pNewParent="") {

			Set tSC = $$$ERROR($$$GeneralError,"Required New RDN or New Parent for Rename")

		} Else {

			#; If pNewRDN not specified use existing - pRDN might have been passed in as a DN so take first ,
			#dim tNewRDN As %String = pNewRDN
			If (tNewRDN = "") {
				#;pRDN might be a DN
				Set tNewRDN = ##class(EnsLib.LDAP.Util.General).ExtractRDNFromDN(pRDN)
			} ElseIf pEscapeNew {
				Set tNewRDN = ##class(EnsLib.LDAP.Util.General).EscapeDN(tNewRDN)
			}

			#dim tNewParent As %String = pNewParent
			If (tNewParent'="") && pEscapeNew {
				Set tNewParent = ##class(EnsLib.LDAP.Util.General).EscapeDN(tNewParent)
			}

			#dim tRetryLDAPOperation As %Boolean = 1
			Do {

				Set tSC = ..%LDAPSession.ldapRenameExts(tDNtoRename, tNewRDN, tNewParent, pDeleteOld)

				#; We will only do the reconnect attempt once since Disconnect sets ThoughtToBeConnected to 0
				If $$$ISERR(tSC) &&
					(..%LDAPSession.LastStatusCategory=$$$EnsLDAPStatusUnavailable) &&
					..ThoughtToBeConnected {

						$$$sysTRACE("Detected change in existing connection. Reconnecting and Retrying once.")

						#; Disconnect, then reconnect and try again.
						Do ..Disconnect()
						Quit:'..HaveConnected(.tSC)

				} Else {

					Set tRetryLDAPOperation = 0
				}

			} While tRetryLDAPOperation

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Rename current entry using a Relative new entry value (pNewRDN) <br>
/// pNewParent is an optional new parent to move the item to<br>
/// pDeleteOld indicates if the entry that is being renamed or moved is to be deleted<br>
/// pEscapeNew will Escape non empty values of pNewRDN and pNewParent. The default is True.<br>
Method RenameCurrentLDAPEntry(pNewRDN As %String, pNewParent As %String = "", pDeleteOld As %Boolean = 1, pEscapeNew As %Boolean = 1) As %Status
{
	#dim tSC As %Status =$$$OK

	Try {

		#; Check have a current result.
		If ..%LDAPSession.%CurrentDN = "" {

			Set tSC = $$$ERROR($$$GeneralError,"Required Current DN needed for Rename")

		} ElseIf (pNewRDN="") && (pNewParent="") {

			Set tSC = $$$ERROR($$$GeneralError,"Required New RDN or New Parent for Rename")

		} Else {

			#; If pNewRDN not specified use existing take first , of current DN
			#dim tNewRDN As %String = pNewRDN
			If (tNewRDN = "") {
				Set tNewRDN = ##class(EnsLib.LDAP.Util.General).ExtractRDNFromDN(..%LDAPSession.%CurrentDN)
			} ElseIf pEscapeNew {
				Set tNewRDN = ##class(EnsLib.LDAP.Util.General).EscapeDN(tNewRDN)
			}

			#dim tNewParent As %String = pNewParent
			If (tNewParent'="") && pEscapeNew {
				Set tNewParent = ##class(EnsLib.LDAP.Util.General).EscapeDN(tNewParent)
			}

			Set tSC = ..%LDAPSession.ldapRenameExts(..%LDAPSession.%CurrentDN, tNewRDN, tNewParent, pDeleteOld)

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Compares the value of Attribute with name pAttribute on the server for a Distinguish name pCN
/// with the value provided in pData<br>
/// pConvertBinaryData is a boolean to indicate if the value is binary<br>
Method CompareLDAPEntryAttributeValue(pCN As %String, pBase As %String = {..BaseDN}, pAttribute As %String, pData As %String, Output pComparison As %Boolean, pConvertBinaryData As %Boolean = 0) As %Status
{
	#dim tSC As %Status =$$$OK

	Try {

		If pCN  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required Common Name  or DN for Compare Entry Attributes needed")
			Quit
		}

		Quit:'..HaveConnected(.tSC)

		#dim tDNtoCompare As %String = ##class(EnsLib.LDAP.Util.General).GenerateDNFromRDNandParent(pCN,pBase,0)

		#dim tRetryLDAPOperation As %Boolean = 1
		Do {

			Set tSC = ..%LDAPSession.ldapCompareExts(tDNtoCompare, pAttribute, $Select((pConvertBinaryData||(pData="")):$LB(pData),1:pData), .pComparison)

			#; We will only do the reconnect attempt once since Disconnect sets ThoughtToBeConnected to 0
			If $$$ISERR(tSC) &&
				(..%LDAPSession.LastStatusCategory=$$$EnsLDAPStatusUnavailable) &&
				..ThoughtToBeConnected {

					$$$sysTRACE("Detected change in existing connection. Reconnecting and Retrying once.")

					#; Disconnect, then reconnect and try again.
					Do ..Disconnect()
					Quit:'..HaveConnected(.tSC)

			} Else {

				Set tRetryLDAPOperation = 0
			}

		} While tRetryLDAPOperation

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Compares the value of Attribute with name pAttribute on the server
/// with the value provided in pData<br>
/// pAttribute is the name of the attribute. <br>
/// pConvertBinaryData is a boolean to indicate if the value is binary<br>
Method CompareCurrentLDAPEntryAttributeValue(pAttribute As %String, pData As %String, Output pComparison As %Boolean, pConvertBinaryData As %Boolean = 0) As %Status
{
	#dim tSC As %Status =$$$OK

	Try {

		#; Check have a current result.
		If ..%LDAPSession.%CurrentDN = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required Current DN needed")
		} Else {
			Set tSC = ..%LDAPSession.ldapCompareExts(..%LDAPSession.%CurrentDN, pAttribute, $Select((pConvertBinaryData||(pData="")):$LB(pData),1:pData), .pComparison)
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

// Parameters are:<br>

/// Add a new entry to the LDAP server. This method will generated the correct list structures
/// before it calls  <method>AddLDAPEntry</method><br><br>
/// To specify binary attributes use <method>AddNewEntryParmArray</method><br><br>
/// pObjectClass - The LDAP objectclass of the item to be added (example: "person") <br>
/// pRDN - The LDAP Relative Distinguished Name of the item to be added <br>
/// example: "John Smith" or "cn=John Smith or ""ou=people". If no naming attribute is given cn will be used.<br>
/// pBase - The LDAP DN (distinguished name) for the part of the LDAP tree that the new item will be created under.
/// If not specified then the value of <PROPERTY>BaseDN</PROPERTY> is used.<br>
/// Note: this part of the tree must already exist on the LDAP server <br>
/// pAttributes - One or more strings defining attribute values for the item being added.
/// <EXAMPLE>
/// Set tSC=..Adapter.AddNewEntry("person","John Smith","ou=people,dc=example,dc=com","sn=Smith","office=103B","mail=john.smith@example.org")
///  /*
///  This will add a new person object with a DN of:
///   cn=John Smith,ou=people,dc=example,dc=com
/// 
///  And the following attributes:
///   SN (surname): Smith
///   Office: 103B
///   Mail: john.smith@example.org
///  */
/// </EXAMPLE>
Method AddNewEntry(pObjectClass As %String = "", pRDN As %String = "", pBase As %String = {..BaseDN}, pAttributes...) As %Status
{
	If pRDN  = "" {
		Quit $$$ERROR($$$GeneralError,"Required Relative Distinguished Name (pRDN) for Add Entry needed")
	}

	Quit ..AddNewEntryParmArray(pObjectClass,pRDN,pBase,.pAttributes)
}

/// Add a new entry to the LDAP server. This method will generated the correct list structures
/// before it calls  <method>AddLDAPEntry</method><br><br>
/// Same parameters as <METHOD>AddNewEntry</METHOD> except last parameter is an array of attributes<br>
/// pAttributesArray is a numbered array where the values are "attributeName=value".<br>
/// pAttributesArray top node is set to the number in the array. <br>
/// pObjectClass is an optional list comma list of Object Classes<br>
/// To indicate if an Attribute is Binary set the subscript "IsBinary" to 1 e.g pAttributesArray(AttributeNumber,"IsBinary")=1
/// <EXAMPLE>
/// Set pAttributesArray=4
/// Set pAttributesArray(1)="sn=Smith"
/// Set pAttributesArray(2)="office=103B"
/// Set pAttributesArray(3)="mail=john.smith@example.org"
/// Set pAttributesArray(4)="jpegPhoto="_tBinaryData
/// Set pAttributesArray(4,"IsBinary") = 1
/// Set tSC=..Adapter.AddNewEntryParmArray("person","John Smith","ou=people,dc=example,dc=com",.pAttributesArray)
///  /*
///  This will add a new person object with a DN of:
///   cn=John Smith,ou=people,dc=example,dc=com
/// 
///  And the following attributes:
///   SN (surname): Smith
///   Office: 103B
///   Mail: john.smith@example.org
///   jpegPhoto: binary data of tBinaryData
///  */
/// </EXAMPLE>
Method AddNewEntryParmArray(pObjectClass As %String = "", pRDN As %String = "", pBase As %String = {..BaseDN}, ByRef pAttributesArray = 0) As %Status
{

	#dim tSC As %Status =$$$OK

	#dim tAttributeList As %List = ""

	Try {

		If pRDN  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required Relative Distinguished Name (pRDN) for Add Entry needed")
			Quit
		}

		#; Initialize Attribute List with objectclass
		If pObjectClass '="" {
			Set tAttributeList = tAttributeList_$LB($LB(0,"objectclass",$ListFromString(pObjectClass,",")))
		}

		#; Add in attributes
		Set tAttributeList = tAttributeList _ ..convertAttribArrayToList(.pAttributesArray)

		#dim tNewDNtoAdd As %String = ##class(EnsLib.LDAP.Util.General).GenerateDNFromRDNandParent(pRDN,pBase,0)

		Set tSC = ..AddLDAPEntry(tNewDNtoAdd,tAttributeList)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Add non binary Attributes to an existing entry. This method will generated the correct list structures
/// before it calls  <method>ModifyLDAPEntry</method>
/// To Add binary as well as non binary or to Delete or Replace attributes use
/// <method>ModifyEntryParmArray<method> <br><br>
/// Parameters are:<br>
/// pObjectClass - The LDAP objectclass of the item to be added (example: "person") <br>
/// pRDN - The LDAP Relative Distinguished Name of the item to be added <br>
/// example: "John Smith" or "cn=John Smith or ""ou=people". If no naming attribute is given cn will be used.<br>
/// pBase - The LDAP DN (distinguished name) for the part of the LDAP tree that the new item will be created under.
/// If not specified then the value of <PROPERTY>BaseDN</PROPERTY> is used.<br>
/// Note: this part of the tree must already exist on the LDAP server <br>
/// pRDN can also be a DN and pBase specified as ""<br>
/// pAttributes - One or more strings defining attribute values for the item being modified.
/// <EXAMPLE>
/// Set tSC=..Adapter.ModifyEntry("person","John Smith","ou=people,dc=example,dc=com","mail=john.smith@example.org")
///  /*
///  This will add to a DN of:
///   cn=John Smith,ou=people,dc=example,dc=com
/// 
///  attribute
///   Mail: john.smith@example.org
///  */
/// </EXAMPLE>
Method ModifyEntry(pRDN As %String = "", pBase As %String = {..BaseDN}, pAttributes...) As %Status
{
	If pRDN  = "" {
		Quit $$$ERROR($$$GeneralError,"Required Relative Distinguished Name (pRDN) for Modify Entry needed")
	}

	Quit ..ModifyEntryParmArray(pRDN,pBase,.pAttributes)
}

/// Add, Delete, Replace Attributes from a specified DN and
/// also specify if an attribute value is Binary. .This method will generated the correct list structures
/// before it calls  <method>ModifyLDAPEntry</method>
/// Same parameters as <METHOD>ModifyEntry</METHOD> except last parameter (pAttributesArray)
/// is a numbered array with values
/// using "attribute name=attribute value". Top level pAttributesArray is set to the number in the array. <br>
/// Second level subscripts of pAttributesArray can be "Delete","Replace" or "IsBinary" the
/// pObjectClass is a comma list of Object Classes
/// Using this method to indicate if the Attribute is Binary by setting pAttributesArray(AttributeNumber,"IsBinary")=1 <br>
/// The default is to Add non binary. <br>
/// <EXAMPLE>
/// /*
/// 		pAttributesArray=3
/// 		pAttributesArray(1)="mail=john.smith@example.org"
/// 		pAttributesArray(2)=""office=1C"
/// 		pAttributesArray(2,"Replace")=1
/// 		pAttributesArray(3)="jpegPhoto="_tBinaryData
/// 		pAttributesArray(3,"IsBinary") = 1
/// */
/// </EXAMPLE>
Method ModifyEntryParmArray(pRDN As %String = "", pBase As %String = {..BaseDN}, ByRef pAttributesArray = 0) As %Status
{

	#dim tSC As %Status =$$$OK

	Try {

		If pRDN  = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required Relative Distinguished Name (pRDN) for Modify Entry needed")
			Quit
		}

		#; Generate attribute lists
		#dim tAttributeList As %List = ..convertAttribArrayToList(.pAttributesArray)

		#dim tDNtoModify As %String = ##class(EnsLib.LDAP.Util.General).GenerateDNFromRDNandParent(pRDN,pBase,0)

		Set tSC = ..ModifyLDAPEntry(tDNtoModify,tAttributeList)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Similar to ModifyEntry except the modification is made to current DN object
Method ModifyCurrent(pAttributes...) As %Status
{
	Quit ..ModifyCurrentParmArray(.pAttributes)
}

/// Similar to ModifyEntryParmArray except the modification is made to current DN object
Method ModifyCurrentParmArray(ByRef pAttributesArray = 0) As %Status
{

	#dim tSC As %Status =$$$OK

	#dim tAttributeList As %List = ""

	Try {

		#; Check have a current result.
		If ..%LDAPSession.%CurrentDN = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Required Current DN needed")
		} Else {
			Set tAttributeList = tAttributeList _ ..convertAttribArrayToList(.pAttributesArray)
			Set tSC = ..ModifyLDAPEntry(..%LDAPSession.%CurrentDN,tAttributeList)
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// / Return an array with information on last call and store the passed in pStatus as the "InternalStatus" subscript <br>
/// The subscripts are: LastStatusText, LastStatusCode, LastStatusCategory, LastCall, InternalErrorStatus<br>
Method CreateStatusArray(pStatus As %Status, Output pStatusArray As %String)
{
	Kill pStatusArray

	Set pStatusArray("LastStatusText") = ..%LDAPSession.LastStatusText
	Set pStatusArray("LastStatusCode") = ..%LDAPSession.LastStatusCode
	Set pStatusArray("LastStatusCategory") = ..%LDAPSession.LastStatusCategory
	Set pStatusArray("LastCall") = ..%LDAPSession.LastCall
	Set pStatusArray("LastGeneratedStatus") = pStatus

	Quit
}

/// Create an array of data from the current %Results or %Page handle.<br>
/// pBinaryAttributes is an optional comma separated list of Attribute names that require binary retrieval<br>
/// Format of the pResultsArray is: <br>
/// pResultsArray = Number of Results <br>
/// pResultsArray(Result Number)=Distinguished Name<br>
/// pResultsArray(Result Number ,Attribute Name)=Number of attribute values <br>
/// pResultsArray(Result Number ,Attribute Name,Attribute Number)=Value <br>
/// If an error then pResultsArray will be a StatusArray
Method CreateResultsArray(Output pResultsArray As %String, pBinaryAttributes As %String = "") As %Status
{
	#dim tSC As %Status =$$$OK

	#dim tSingleLoop = '..%LDAPSession.%Page

	#dim tListOfBinaryAttributes = $ListFromString(pBinaryAttributes)
	#dim tAttributeIsBinary as %Boolean = 0

	Try {

		#dim tResultNumber, tAttributeValueNumber As %Integer = 0
		#dim tAttributeName, tAttributeValue, tAttributeValues As %String

		While ('..%LDAPSession.%PagesAtEnd && (..%LDAPSession.%Page>0))||(tSingleLoop) {

			If tSingleLoop {

				Set tSingleLoop = 0

			} Else {

				Set tSC = ..%LDAPSession.ldapGetNextPages()
				If $$$ISERR(tSC) || ..%LDAPSession.%PagesAtEnd Quit

			}

			Set tSC = ..FirstEntryDN()

			If $$$ISERR(tSC) {
				Do ..CreateStatusArray(tSC, .pResultsArray)
				Quit
			}

			While (..%LDAPSession.%CurrentDN '= "") {

				Set tResultNumber = tResultNumber + 1

				Set pResultsArray(tResultNumber) = ..%LDAPSession.%CurrentDN

				Set tSC = ..%LDAPSession.ldapFirstAttribute(.tAttributeName)

				If $$$ISERR(tSC) {
					Do ..CreateStatusArray(tSC, .pResultsArray)
					Quit
				}

				While ('..%LDAPSession.%AttributesAtEnd) {

					Set tAttributeIsBinary = ''$ListFind(tListOfBinaryAttributes,tAttributeName)

					Set tSC = ..GetValues(tAttributeName,.tAttributeValues,tAttributeIsBinary)

					If $$$ISERR(tSC) {
						Do ..CreateStatusArray(tSC, .pResultsArray)
						Quit
					}

					For tAttributeValueNumber=1:1:$LL(tAttributeValues) {

						Set pResultsArray(tResultNumber,tAttributeName,tAttributeValueNumber) = $LI(tAttributeValues,tAttributeValueNumber)

					}

					Set pResultsArray(tResultNumber,tAttributeName) = tAttributeValueNumber

					Set tSC = ..%LDAPSession.ldapNextAttribute(.tAttributeName)

					If $$$ISERR(tSC) {
						Do ..CreateStatusArray(tSC, .pResultsArray)
						Quit
					}

				}
				/* Any errors getting attributes quit try/catch */
				If $$$ISERR(tSC) Quit

				/* Get next Entry if there is one*/
				If ..%LDAPSession.%ResultsAtEnd Quit

				Set tSC = ..NextEntryDN()

				If $$$ISERR(tSC) {
					Do ..CreateStatusArray(tSC, .pResultsArray)
					Quit
				}

			}

			/* Any errors getting attributes quit try/catch */
			If $$$ISERR(tSC) Quit

		}

		Set pResultsArray = tResultNumber

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Helper method to Convert a numbered array to a list structure for %SYS.LDAP method calls.<br>
/// 2nd level subscript can be "Delete", or "Replace" if not Add operation. Also optional "IsBinary"
/// Default operation is Add. <br>
Method convertAttribArrayToList(ByRef pAttributesArray) As %List [ Internal ]
{
	#;Temp holder for each list structure
	#dim tOneListData As %String = ""

	#dim tAttributeNumber As %Integer

	#;Pairs from pAttributesArray
	#dim tAttributeName As %String
	#dim tAttributeValue As %String

	/*
			 0 - Add - The given values are added to the entry, creating the attribute if necessary.<br>
			 1 - Delete - The given values are deleted from the entry, removing the attribute if no values remain. If the entire
			 attribute is to be deleted, the mod_values field should be set to NULL ($lb("")).<br>
			 2 - Replace - The attribute will have the listed values after the modification, having been created if necessary. If set
			 to null, then the attribute is deleted.<br>
			 128 - This value should be combined (ORed) with the Add/Delete/Replace value if the data is BINARY
	*/
	#dim tOperation As %Integer = 0

	#dim tAttributeList As %List = ""
	#dim tAttributeValueAsList As %List = ""

	For tAttributeNumber=1:1:$Get(pAttributesArray,0) {
		Set tAttributeName=$Piece(pAttributesArray(tAttributeNumber),"=")
		Set tAttributeValue=$Piece(pAttributesArray(tAttributeNumber),"=",2,*)

		If $Data(pAttributesArray(tAttributeNumber,"Delete"))#2 {
			Set tOperation = 1
		} ElseIf $Data(pAttributesArray(tAttributeNumber,"Replace"))#2 {
			Set tOperation = 2
		} Else {
			#;Default to Add
			Set tOperation = 0
		}

		If tAttributeName = "objectClass" {

			Set tAttributeValueAsList = $ListFromString(tAttributeValue)

		} Else {

			Set tAttributeValueAsList = $ListBuild(tAttributeValue)

		}

		If $Get(pAttributesArray(tAttributeNumber,"IsBinary"),0) {

			Set tOperation = tOperation + 128
			Set tOneListData = $ListBuild(tOperation,tAttributeName,tAttributeValueAsList)

		} Else {

			Set tOneListData = $ListBuild(tOperation,tAttributeName,tAttributeValueAsList)

		}

		Set tAttributeList = tAttributeList _ $ListBuild(tOneListData)
	}

	Return tAttributeList
}

/*
 	Call Backs

 		OnTearDown

 */
/// Ensure Disconnect
Method OnTearDown() As %Status
{
	Do ..Disconnect()
	Quit $$$OK
}

}
