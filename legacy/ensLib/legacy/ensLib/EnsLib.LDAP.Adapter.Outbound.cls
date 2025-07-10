/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Ensemble LDAP Outbound Adapter that replaces deprecated EnsLib.LDAP.OutboundAdapter
Class EnsLib.LDAP.Adapter.Outbound Extends (Ens.OutboundAdapter, EnsLib.LDAP.Adapter.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Stay connected to the remote system between handling Requests until idle for this number of seconds.<br>
/// A value of -1 means maintain a connection. This is the default setting. <br>
/// Reconnection during the Stay Connection period is based on the IdleReconnectInterval
Property StayConnected As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/// How long of an idle period in seconds before disconnecting and reconnecting.<br>
/// If StayConnected is 0 or positive then this value is ignored if it is less than StayConnected value.<br>
/// This setting is intended to be used where the server has a configured user idle time or network appliances
/// close inactive connections.<br>
/// An IdleReconnectInterval of 0 means no checking of idle period for reconnection.<br>
Property IdleReconnectInterval As %Numeric(MINVAL = 0) [ InitialExpression = 0 ];

Parameter SETTINGS = "LDAPServer:Basic,Credentials:Basic:credentialsSelector,LDAPPort:Basic,LDAPSSLPort:Basic,UseSSL:Basic,ConnectWithURIScheme:Basic,UseSASLAuthentication:SASL,SASLPublicKeyFile:SASL,SASLPrivateKeyFile:SASL,BaseDN:LDAP,SearchTimeout:LDAP,SearchSizeLimit:LDAP,WindowsActiveDirectoryServer:LDAP,CredentialsUsernameIsDN:LDAP,LDAPCACertFile:LDAP,StayConnected:Connection,IdleReconnectInterval:Connection";

/// Adapter code
Method OnInit() As %Status
{
	#dim tSC As %Status = ##super()
	If $$$ISERR(tSC) Quit tSC

	#dim tConnectStatus As %Status = $$$OK

	#dim tAuthenticate As %Boolean = ($IsObject(..%CredentialsObj)&&(..%CredentialsObj.Username'=""))

	Set ..LDAPServer = $ZStrip(..LDAPServer,"<>W")

	If '..ConnectWithURIScheme {

		If $Piece(..LDAPServer," ",2) '= "" {

			$$$LOGWARNING("Connecting to multiple LDAP Servers is only supported using the URI Scheme.")
			Set ..LDAPServer = $Piece(..LDAPServer," ")

		}

	} Else {

		If $$$ISWINDOWS $$$LOGWARNING("Connecting from a Windows server using the URI Scheme is not supported. See %SYS.LDAP::Initialize() documentation.")

		/* Replace  any user entered multiple spaces & 
			append port to allow for non default. 
		*/
		Do {
			Set tLDAPServer = ..LDAPServer
			Set ..LDAPServer = $Replace(..LDAPServer,"  "," ")
		} While tLDAPServer '= ..LDAPServer

		Set ..LDAPServer = $Replace(..LDAPServer," ",(":"_$Select(..UseSSL:..LDAPSSLPort,1:..LDAPPort)_" "))
		Set ..LDAPServer = ..LDAPServer_":"_$Select(..UseSSL:..LDAPSSLPort,1:..LDAPPort)

	}

	If ..StayConnected>0 Set ..KeepaliveInterval = ..StayConnected

	If ..StayConnected<0 {

		Set ..KeepaliveInterval = ..IdleReconnectInterval
		Set tConnectStatus = ..Connect(tAuthenticate)
		/*
			If we cannot connect when we start only return an error if due to authorization error.
			Otherwise log a Warning and report further connection errors in OnKeepalive
		*/
		If $$$ISERR(tConnectStatus) {
			If '..Connected || '..Authenticated {
				Set tPortInfoIfInit = $S(..ConnectWithURIScheme:"",..UseSSL:":"_..LDAPSSLPort,1:":"_..LDAPPort)
				Set tSC =$$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tConnectStatus),"LDAP",..LDAPServer_tPortInfoIfInit_"/"_..%CredentialsObj.Username)
				If ..%LDAPSession.LastStatusCategory = $$$EnsLDAPStatusAuthorization {
				 	 Return tSC
				} Else {
					#; Log warning. Assumption being that trying to connect later might be OK.
					$$$LOGWARNING($$$StatusText(tSC))
				}
			}
		}

	} Else {

		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC)

	}

	Quit $$$OK
}

Method OnKeepalive(pUnused As %Status) As %Status
{
	#dim tConnectStatus As %Status = $$$OK
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		If ..Connected {

			If (..StayConnected>0) && ($ZH-..BusinessHost.%LastHandledTime>=..StayConnected) {
				$$$sysTRACE("Disconnecting on expiration of idle interval StayConnected="_..StayConnected)
				#;Disconnect but do not reconnect
				Do ..Disconnect()
				Quit
			} ElseIf (..IdleReconnectInterval=0) || ($ZH-..BusinessHost.%LastHandledTime<..IdleReconnectInterval) {
				#;Remain Connected
				Quit
			} Else {
				#;Disconnect and then carry on to connect
				$$$sysTRACE("Reconnecting on expiration of idle reconnect interval ="_..IdleReconnectInterval)
				Do ..Disconnect()
			}

		} ElseIf (..StayConnected>=0) {
			#;Remain disconnected
			Quit

		}

		$$$sysTRACE("Connecting in OnKeepAlive()")
		#dim tAuthenticate As %Boolean = ($IsObject(..%CredentialsObj)&&(..%CredentialsObj.Username'=""))

		Set tConnectStatus = ..Connect(tAuthenticate)
		If $$$ISERR(tConnectStatus) {
			Set tPortInfoIfInit = $S(..ConnectWithURIScheme:"",..UseSSL:":"_..LDAPSSLPort,1:":"_..LDAPPort)
			Set tSC =$$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tConnectStatus),"LDAP",..LDAPServer_tPortInfoIfInit_"/"_..%CredentialsObj.Username)
			Set ..BusinessHost.%LastReportedError=tSC
		} Else {
			If ..BusinessHost.%LastReportedError [ "ERROR <Ens>ErrOutConnect" {
				Set ..BusinessHost.%LastReportedError=""
				$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
			}
		}

	} Catch ex {
		Set tSC = $$$SystemError
	}

	/* This leads to code checking if code has been recompiled. It also leads to BusinessHost OnKeepAlive being called */
	Quit ##class(Ens.OutboundAdapter)$this.OnKeepalive(tSC)
}

}
