/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syLDAP, Ensemble, EnsLDAP)

/// Ensemble wrapper class for %SYS.LDAP methods to allow creating
/// a single session instance and used by <CLASS>EnsLib.LDAP.Adapter.Common</CLASS>
Class EnsLib.LDAP.Client.Session Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/* Handle properties */
/// This holds handle to the current LDAP Session
Property %Session As %Integer [ Transient ];

/// This holds handle to the current results of the latest invocation of <method>Search</method>
Property %Results As %Integer [ Transient ];

/// Indicates if have come to end of the results
Property %ResultsAtEnd As %Boolean;

/// This holds handle to the current result of <property>%Results</property>
Property %Result As %Integer [ Transient ];

/// This holds handle to the current attribute of <property>%Result</property>
Property %Attribute As %Integer [ Transient ];

/// Indicates if have come to end of the Attributes
Property %AttributesAtEnd As %Boolean [ Transient ];

/// This holds the handle to Page searches - only applies to Windows
Property %Page As %Integer [ Transient ];

/// This holds the current PageSize requested - only applies to Windows
Property %PageSize As %Integer [ Transient ];

/// Number of seconds to wait on each Page Search attempt - only applies to Windows
Property %PageSearchTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

/// Indicates if have come to end of the Paged search
Property %PagesAtEnd As %Boolean [ Transient ];

/// Current user bound as. Either as DN or 'domain\username'
Property %CurrentUser As %String(MAXLEN = "") [ Transient ];

Property %CurrentDN As %String(MAXLEN = "") [ Transient ];

/* Status properties */
/// Has TLS/SSL started
Property %startedSSL As %Boolean [ InitialExpression = 0, Transient ];

/* Error Handling */
/// LDAP Status return code.
Property LastStatusCode As %Integer;

/// LDAP Status return code as Text
Property LastStatusText As %String;

/// Categorization of non success LastStatusCode
Property LastStatusCategory As %Integer;

/// %SYS.LDAP Method
Property LastCall As %String;

/// Used to record the generated  status
Property LastGeneratedStatus As %Status;

Method %OnNew() As %Status [ Private, ServerOnly = 1 ]
{
	#; Populate map of OpenLDAP errors to Ensemble LDAP Status information
	Do ##class(EnsLib.LDAP.Util.General).initializeEnsLDAPStatusMap()

	Quit $$$OK
}

/// Get the LDAP Error if pLDAPStatus is not defined <br>
/// Uses pLDAPStatus and pLastCall string to create an error status<br>
Method GetLDAPError(pLastCall As %String = "", pExtraText As %String = "", ByRef pLDAPStatus As %Integer) As %Status
{
	#dim tSC As %Status = $$$OK

	Try {

		#;Clean in case catch error
		Set ..LastCall = ""
		Set ..LastStatusCode = ""
		Set ..LastStatusText = ""
		Set ..LastStatusCategory = $$$EnsLDAPStatusUnknown
		Set ..LastGeneratedStatus = ""

		#;Populate
		Set ..LastCall = pLastCall

		If '$Data(pLDAPStatus) Set pLDAPStatus = ..ldapGetError()
		Set ..LastStatusCode = pLDAPStatus

		Set ..LastStatusText = ..ldapErr2String(pLDAPStatus)

		If (pLDAPStatus '= $$$LDAPSUCCESS) {

			#; Look for information from LDAP Diagnostic Message since synchronous call
			#dim tDiagnosticInformation
			#dim tSCDiagnostic = ..ldapGetOption($$$LDAPOPTERRORSTRING,.tDiagnosticInformation)
			If ($Get(tDiagnosticInformation)'="") && ($Get(tDiagnosticInformation)'="0") Set ..LastStatusText = ..LastStatusText_" / "_tDiagnosticInformation
			If $$$ISERR(tSCDiagnostic) Set tSC = $$$ADDSC(tSCDiagnostic,tSC)

			#dim tCategory
			Set tSC = ##class(EnsLib.LDAP.Util.General).GenerateEnsLDAPStatus(pLastCall,pExtraText,..LastStatusText,pLDAPStatus,.tCategory)
			Set ..LastStatusCategory = tCategory

		} Else {

			Set ..LastStatusCategory = $$$EnsLDAPStatusSuccess

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Set ..LastGeneratedStatus = tSC

	If $$$ISERR(tSC) {

		$$$sysTRACE("Error identified "_$$$StatusDisplayString(tSC))

	}

	Quit tSC
}

/* LDAP wrapper utilities */
Method ClearHandles()
{
	Set ..%Session=0
	Do ..ClearResults()
	Do ..ClearPages()
}

Method ClearResults()
{
	Set ..%Results = 0
	Set ..%Result = 0
	Set ..%Attribute = 0
	Set ..%CurrentDN = ""
}

Method ClearPages()
{
	Set ..%Page = 0
	Set ..%PageSize = ""
	Set ..%PagesAtEnd = 0
	Set ..%PageSearchTimeout = 0
}

/*
  %SYS.LDAP method wrappers for:
*/
/// Retrieve the last error code returned by an LDAP call for a specific session.<br>
Method ldapGetError() As %Integer
{
	Return ##Class(%SYS.LDAP).GetError(..%Session)
}

/// Converts a numeric LDAP error code into a string that describes the error.<br>
Method ldapErr2String(pErrorStatus As %Integer) As %String
{
	Return ##class(%SYS.LDAP).Err2String(pErrorStatus)
}

/// Initialize a connection to a LDAP server.<br>
Method ldapInit(pLDAPServer As %String, pLDAPPort As %String, pLDAPSSLPort As %String, pUseSSL As %Boolean = 0, pServerIsWindowsAD As %Boolean = 0) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	#dim tPort As %Integer

	Set ..%startedSSL = 0

	/*
		We cannot do a windows client to Unix LDAP server on LDAP port and then call startTLSs.
		Note that the windows client must have the certificate installed already.
	*/

	Try {

		If $$$ISWINDOWS && pUseSSL && 'pServerIsWindowsAD {

			Set tPort = pLDAPSSLPort
			#;Optimistic set. Will set to 0 if fail.
			Set ..%startedSSL = 1

		} Else {

			Set tPort = pLDAPPort

		}

		$$$sysTRACE("Issuing LDAP Init to Port "_tPort)
		Set ..%Session = ##Class(%SYS.LDAP).Init(pLDAPServer, pLDAPPort)

		If (..%Session = 0) {

			Set ..%startedSSL = 0
			Set tSC = ..GetLDAPError("Init","Port="_tPort)

		} Else {

			$$$sysTRACE("Issued Init to: "_pLDAPServer_":"_tPort_". %Session handle is "_..%Session)

		}

	} Catch {

		Set ..%startedSSL = 0
		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Initialize a direct connection to an LDAP server
/// using ldap: or ldaps:<br>
/// Supported on Unix servers only. <br>
Method ldapInitialize(pLDAPServers As %String, pUseSSL As %Boolean = 0) As %Status
{
	If $$$ISWINDOWS Return $$$EnsError($$$EnsLDAPErrURISchemeNotSupported)

	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer
	#; Will load SSL cert separately
	Set ..%startedSSL = 0

	Try {
		#dim tURLProtocol = "ldap"
		If pUseSSL Set tURLProtocol = tURLProtocol _ "s"

		#dim tLDAPHostNames As %String = ""
		#dim i,tLDSession As %Integer

		For i=1:1:$L(pLDAPServers," ") Set tLDAPHostNames=tLDAPHostNames _ tURLProtocol _ "://"_$p(pLDAPServers," ",i)_" "

		Set tLDAPHostNames=$E(tLDAPHostNames,1,*-1)

		$$$sysTRACE("Issuing LDAP Initialize to URL " _ tLDAPHostNames)
		Set tLDAPStatus = ##Class(%SYS.LDAP).Initialize( .tLDSession, tLDAPHostNames)

		Set ..%Session = tLDSession

		If (..%Session = 0) {

			Set tSC = ..GetLDAPError("Initialize","Hosts =" _ tLDAPHostNames,tLDAPStatus)

		} Else {

			$$$sysTRACE("Issued Initialize to: " _ tLDAPHostNames _". %Session handle is "_..%Session)

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Establish a connection to an LDAP server.<br><br>
/// Used to force connection from a Windows Client.
Method ldapConnect(pTimeout As %Integer = 0) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP Connect with timeout "_pTimeout)

		Set tLDAPStatus=##Class(%SYS.LDAP).Connect(..%Session, pTimeout)
		Set tSC = ..GetLDAPError("Connect",,tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Set options for an LDAP session.<br>
Method ldapSetOption(pOption As %String, pInValue As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP SetOption "_$ZH(pOption))

		Set tLDAPStatus = ##Class(%SYS.LDAP).SetOption(..%Session,pOption,pInValue)
		Set tSC = ..GetLDAPError("SetOption",$ZH(pOption),tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Get options for an LDAP session.<br>
Method ldapGetOption(pOption As %String, Output pOutValue As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP GetOption "_$ZH(pOption))
		Kill pOutValue
		Set tLDAPStatus = ##Class(%SYS.LDAP).GetOption(..%Session,pOption,.pOutValue)

		#; Avoid circular calls from GetLDAPError if LDAP_OPT_DIAGNOSTIC_MESSAGE
		If pOption'=$$$LDAPOPTERRORSTRING {

			Set tSC = ..GetLDAPError("GetOption",$ZH(pOption),tLDAPStatus)

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Start using TLS encryption on an active LDAP session.<br>
Method ldapStartTLSs() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP StartTLs")

		Set tLDAPStatus=##Class(%SYS.LDAP).StartTLSs(..%Session)
		Set tSC = ..GetLDAPError("StartTLSs",,tLDAPStatus)

		If $$$ISOK(tSC) {
			$$$sysTRACE("SSL Started")
			Set ..%startedSSL = 1
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Stop using TLS encryption on an active LDAP session.<br>
Method ldapStopTLSs() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		If '$$$ISWINDOWS Quit

		$$$sysTRACE("Issuing LDAP StopTLs")

		Set tLDAPStatus=##Class(%SYS.LDAP).StopTLSs(..%Session)
		Set tSC = ..GetLDAPError("StopTLSs",,tLDAPStatus)

		If $$$ISOK(tSC) {
			$$$sysTRACE("SSL Stopped")
			Set ..%startedSSL = 1
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Authenticate a client to a server, using a plaintext password.<br>
Method ldapSimpleBinds(pDN As %String, pPassword As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP SimpleBinds")

		Set tLDAPStatus = ##Class(%SYS.LDAP).SimpleBinds(..%Session, pDN, pPassword)

		Set tSC = ..GetLDAPError("SimpleBinds",,tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	If $$$ISOK(tSC) Set ..%CurrentUser = pDN

	Quit tSC
}

/// Authenticate a Windows client to a Windows Active Directory LDAP Server.<br>
Method ldapBinds(pDomainUsername As %String, pDomain As %String, pPassword As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP Binds")

		Set tLDAPStatus = ##Class(%SYS.LDAP).Binds(..%Session,"",$LB(pDomainUsername, pDomain, pPassword),$$$LDAPAUTHNEGOTIATE)

		Set tSC = ..GetLDAPError("Binds",,tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	If $$$ISOK(tSC) Set ..%CurrentUser = pDomain_"\"_pDomainUsername

	Quit tSC
}

/// Authenticate a client to a server, using a SASL EXTERNAL mechanism.<br>
Method ldapSASLBinds(ByRef pServerCredentials As %String = "") As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP SASLBinds")

		Set tLDAPStatus = ##Class(%SYS.LDAP).SASLBinds(..%Session,"","EXTERNAL","","","",.pServerCredentials)

		Set tSC = ..GetLDAPError("SASLBinds",,tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	If $$$ISOK(tSC) Set ..%CurrentUser = "SASLEXTERNAL"

	Quit tSC
}

/// End an LDAP session and frees its resources.<br>
Method ldapUnBinds() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {
		If (..%Session '> 0) Quit

		#; Up to caller to call ldapMsgFree before. This is handled if using Disconnect() method in Common.
		$$$sysTRACE("Issuing LDAP UnBinds")
		Set tLDAPStatus = ##Class(%SYS.LDAP).UnBinds(..%Session)

		Set tSC = ..GetLDAPError("UnBinds",,tLDAPStatus)
		If $$$ISOK(tSC) {

			Do ..ClearHandles()
			Set ..%CurrentUser = ""

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Free the results of the last LDAP SearchExts method call.<br>
Method ldapMsgFree() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		If (..%Results '> 0) {
			$$$sysTRACE("No prior results so not issuing LDAP MsgFree")
			Quit
		}

		$$$sysTRACE("Issuing LDAP MsgFree")

		Set tLDAPStatus = ##Class(%SYS.LDAP).MsgFree(..%Results)
		Set tSC = ..GetLDAPError("MsgFree",,tLDAPStatus)
		If $$$ISOK(tSC) Do ..ClearResults()

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Search the LDAP directory and return a requested set of attributes for each entry.<br>
/// Use the same default of 0 for SearchTimeout and SizeLimit<br>
Method ldapSearchExts(pBase, pScope, pFilter, pAttrs, pAttributesOnly = 0, pSearchTimeout As %Integer = 0, pSizeLimit As %Integer = 0) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tSC1 As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP SearchExts (Base/Scope/Filter/SearchTimeout/SizeLimit:"_pBase_" / "_pScope_" / "_pFilter_" / "_pSearchTimeout_" / "_pSizeLimit_" )")

		#; Up to the caller to call ldapMsgFree but if not called reuse ..%Results (it will be 0 if ldapMsgFree called)
		#dim tResults As %Integer = ..%Results
		Set tLDAPStatus = ##Class(%SYS.LDAP).SearchExts(..%Session,pBase,pScope,pFilter,pAttrs,pAttributesOnly,"","",.pSearchTimeout,.pSizeLimit,.tResults)
		Set tSC = ..GetLDAPError("SearchExts",,tLDAPStatus)

		If $$$ISERR(tSC) {
			#; Free any existing Results
			Set tSC1 = ..ldapMsgFree()
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC,tSC1)
			Quit
		}

		Set ..%Results = tResults

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Search the LDAP directory using a paged search and return a requested set of attributes for each entry.<br>
Method ldapSearchInitPage(pBase, pScope, pFilter, pAttrs, pAttributesOnly = 0, pSearchTimeout = 0, pPageSize = 0) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tSC1 As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP SearchInitPage")

		/* Need to clear out page results */
		Do ..ClearResults()
		Do ..ClearPages()

		#dim tPage As %Integer = 0

		Set tPage = ##Class(%SYS.LDAP).SearchInitPage(..%Session,pBase,pScope,pFilter,pAttrs,pAttributesOnly,"","",pSearchTimeout,pPageSize,"")
		Set tSC = ..GetLDAPError("SearchInitPage",,.tLDAPStatus)

		If $$$ISERR(tSC) {
			Set tSC1 = ..ldapSearchAbandonPage()
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC,tSC1)
			Quit
		}

		Set ..%Page = tPage
		Set ..%PageSize = pPageSize
		Set ..%PageSearchTimeout = pSearchTimeout

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Search the LDAP directory using a pages search and return a requested set of attributes for each entry.<br>
/// The page search timeout and page size specified when issuing SearchInitPage are used if none passed in.<br>
Method ldapGetNextPages(pSearchTimeout = {..%PageSearchTimeout}, pPageSize = {..%PageSize}) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tSC1 As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP GetNextPages")

		#dim tTotalCount /* Not used since could always be 0 */
		#dim tResults

		Set tLDAPStatus = ##Class(%SYS.LDAP).GetNextPages(..%Session,..%Page,pSearchTimeout,pPageSize,.tTotalCount,.tResults)

		Set tSC = ..GetLDAPError("GetNextPages",,tLDAPStatus)
		If $$$ISOK(tSC) {

			Set ..%Results = tResults
			Set ..%PagesAtEnd = 0

		} Else {

			If tLDAPStatus = 94 {
				#; 94 means no more pages. Need to set to $$$OK
				Set tSC = $$$OK
			}

			Set tSC1 = ..ldapSearchAbandonPage()
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC,tSC1)
			Set ..%PagesAtEnd = 1
			Set ..%PageSize = ""
			Set ..%Page = 0

		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Free the page pointer returned by the ldapSearchInitPage
Method ldapSearchAbandonPage() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		#; Free any existing Results
		Set tSC = ..ldapMsgFree()
		If $$$ISERR(tSC) Quit

		If ..%Page > 0 {
			$$$sysTRACE("Issuing LDAP SearchAbandonPage")
			Set tLDAPStatus = ##Class(%SYS.LDAP).SearchAbandonPage(..%Session, ..%Page)
			Set tSC = ..GetLDAPError("SearchAbandonPage",,tLDAPStatus)
			Set ..%Page = 0
			Set ..%PageSize = ""
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Count the number of entries in current results<br>
Method ldapCountEntries(Output pTotal As %Integer) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP CountEntries")

		Set pTotal = ##Class(%SYS.LDAP).CountEntries(..%Session, ..%Results)
		If pTotal = -1 Set tSC = ..GetLDAPError("CountEntries",,.tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Return a pointer to the first entry of current results.<br>
Method ldapFirstEntry() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP FirstEntry")

		Set ..%Result = ##Class(%SYS.LDAP).FirstEntry(..%Session, ..%Results)

		If ..%Result = 0 {
			#;If no entry exists in the result set then tSC will be OK otherwise an error will be returned
			Set tSC = ..GetLDAPError("FirstEntry",, .tLDAPStatus)
			If $$$ISOK(tSC) Set ..%ResultsAtEnd = 1
		} Else {
			Set ..%ResultsAtEnd = 0
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Return the next entry of current results.<br>
Method ldapNextEntry() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP NextEntry")

		Set ..%Result = ##Class(%SYS.LDAP).NextEntry(..%Session, ..%Results)

		If ..%Result = 0 {
			#;If no entry exists in the result set then tSC will be OK otherwise an error will be returned
			Set tSC = ..GetLDAPError("NextEntry",, .tLDAPStatus)
			If $$$ISOK(tSC) Set ..%ResultsAtEnd = 1
		} Else {
			Set ..%ResultsAtEnd = 0
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Return the first attribute of the current Entry.<br>
Method ldapFirstAttribute(Output pAttributeName As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	#dim tAttributePointer As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP FirstAttribute")

		Set pAttributeName = ##Class(%SYS.LDAP).FirstAttribute(..%Session, ..%Result, .tAttributePointer)

		If pAttributeName = "" {
			#;If no attribute exists in the result set then tSC will be OK otherwise an error will be returned
			Set tSC = ..GetLDAPError("FirstAttribute",, .tLDAPStatus)
			If $$$ISOK(tSC) {
				Set ..%AttributesAtEnd = 1
				Set ..%Attribute = 0
			}
		} Else {
			Set ..%AttributesAtEnd = 0
			Set ..%Attribute = tAttributePointer
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Return the next attribute of the current Entry.<br>
Method ldapNextAttribute(Output pAttributeName As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	#dim tAttributePointer As %Integer = ..%Attribute

	Try {

		$$$sysTRACE("Issuing LDAP NextAttribute")

		Set pAttributeName = ##Class(%SYS.LDAP).NextAttribute(..%Session, ..%Result, .tAttributePointer)

		If pAttributeName = "" {
			#;If no more attributes exist in the result set then tSC will be OK otherwise an error will be returned
			Set tSC = ..GetLDAPError("NextAttribute",, .tLDAPStatus)
			If $$$ISOK(tSC) {
				Set ..%AttributesAtEnd = 1
				Set ..%Attribute = 0
			}
		} Else {
			Set ..%AttributesAtEnd = 0
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Retrieve the distinguished name for current entry.<br>
Method ldapGetDN(Output pDN As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		Set pDN = ""

		$$$sysTRACE("Issuing LDAP GetDN")

		Set pDN = ##Class(%SYS.LDAP).GetDN(..%Session, ..%Result)

		If pDN = "" {
			Set tSC = ..GetLDAPError("GetDN",, .tLDAPStatus)
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Return string values for current attribute.<br>
Method ldapGetValues(pAttributeName As %String, Output pValue As %List) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		Set pValue = ""

		$$$sysTRACE("Issuing LDAP GetValues for "_pAttributeName)

		Set pValue = ##Class(%SYS.LDAP).GetValues(..%Session, ..%Result, pAttributeName)

		If pValue = "" {
			Set tSC = ..GetLDAPError("GetValues",, .tLDAPStatus)
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Return binary value for current attribute.<br>
Method ldapGetValuesLen(pAttributeName As %String, Output pValue As %List) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		Set pValue = ""

		$$$sysTRACE("Issuing LDAP GetValuesLen for "_pAttributeName)

		Set pValue = ##Class(%SYS.LDAP).GetValuesLen(..%Session, ..%Result, pAttributeName)

		If pValue = "" {
			Set tSC = ..GetLDAPError("GetValuesLen",, .tLDAPStatus)
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Add an entry to the LDAP directory tree.<br>
Method ldapAddExts(pDN As %String, pAttributeChanges As %List) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP AddExts for "_pDN)

		Set tLDAPStatus = ##Class(%SYS.LDAP).AddExts(..%Session, pDN, pAttributeChanges)
		Set tSC = ..GetLDAPError("AddExts", "Entry '" _ pDN _ "'",tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Modify an entry in the directory tree.<br>
Method ldapModifyExts(pDN As %String, pAttributeChanges As %List) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP ModifyExts")

		Set tLDAPStatus = ##Class(%SYS.LDAP).ModifyExts(..%Session, pDN, pAttributeChanges)
		Set tSC = ..GetLDAPError("ModifyExts","Entry '" _ pDN _ "'",tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Delete an entry in the directory tree.<br>
Method ldapDeleteExts(pDNtoDelete As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP DeleteExts  for "_pDNtoDelete)

		Set tLDAPStatus = ##Class(%SYS.LDAP).DeleteExts(..%Session, pDNtoDelete)
		Set tSC = ..GetLDAPError("DeleteExts","Entry '" _ pDNtoDelete _ "'",tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Rename the distinguished name of an entry in the directory.<br>
Method ldapRenameExts(pDNtoRename As %String, pNewRDN As %String, pNewParent As %String = "", pDeleteOldDN As %Boolean = 1) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP RenameExts Entry '" _ pDNtoRename _ "' to Parent:'"_pNewParent_"' or New RDN '"_pNewRDN_"' with Delete old flag of "_pDeleteOldDN)

		Set tLDAPStatus = ##Class(%SYS.LDAP).RenameExts(..%Session, pDNtoRename,pNewRDN,pNewParent,pDeleteOldDN,"","")
		Set tSC = ..GetLDAPError("RenameExts","Entry '" _ pDNtoRename _ "' to Parent:'"_pNewParent_"' or New RDN '"_pNewRDN_"' with Delete old flag of "_pDeleteOldDN,tLDAPStatus)

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

/// Determine if an attribute, for a given entry, holds a known value.<br>
Method ldapCompareExts(pDN As %String, pAttribute As %String, pData As %String, Output pComparison As %Boolean) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tLDAPStatus As %Integer

	Try {

		$$$sysTRACE("Issuing LDAP CompareExts for "_pDN_" / "_pAttribute)

		Set tLDAPStatus = ##Class(%SYS.LDAP).CompareExts(..%Session, pDN, pAttribute, pData)
		If (tLDAPStatus = $$$LDAPCOMPARETRUE) {
			Set pComparison = 1
		} ElseIf (tLDAPStatus = $$$LDAPCOMPAREFALSE) {
			Set pComparison = 0
		} Else {
			Set tSC = ..GetLDAPError("CompareExts","Entry '" _ pDN _ "' Attribute '"_pAttribute_"'",tLDAPStatus)
			Set pComparison = ""
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	Quit tSC
}

}
