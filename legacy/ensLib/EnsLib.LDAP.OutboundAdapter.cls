/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated.
/// For new development use EnsLib.LDAP.Adapter.Outbound
Class EnsLib.LDAP.OutboundAdapter Extends Ens.OutboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

Property LDAPServer As %String;

Property LDAPPort As %Integer [ InitialExpression = 389 ];

/// This is the ID name of the set of credentials values to be used to access the LDAP server.<p>
/// The Username defined in your Credentials item may be either a fully qualified
/// username, e.g. 'CUser@subdomain.mydomain.com', or an LDAP RDN (Relatively Distinguished Name) path to the
/// user identity in the LDAP directory, e.g. 'CN=Carl User,OU=Users,OU=My Division,DC=subdomain,DC=mydomain,DC=com'
Property Credentials As %String;

/// Use SSL to connect to the LDAP server
Property UseSSL As %Boolean [ InitialExpression = 0 ];

/// Distinguished Name to use a a base for operations on the directory such as searches, updates and deletes.
Property DN As %String(MAXLEN = 1000);

/// If non-zero, stay connected to the remote system between handling Requests until idle for this number of seconds. A value of -1 means never disconnect.
Property StayConnected As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/// Number of seconds to wait on each connection attempt
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// Number of seconds to wait on each Search attempt
Property SearchTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// List of properties can be set as settings in the configuration file
/// format is a comma separated list of property names
Parameter SETTINGS = "LDAPServer:Basic,LDAPPort:Basic,UseSSL,DN,Credentials:Basic:credentialsSelector,StayConnected,ConnectTimeout,SearchTimeout";

/// This holds the LDAP Session connection
Property %Session As %Net.LDAP.Client.Session;

/// True if currently connected to LDAP server
Property Connected As %Boolean [ InitialExpression = 0 ];

Method ConnectedSet(pValue As %Boolean) As %Status
{
	Set i%Connected=pValue
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,pValue_"|"_$$$timeUTC_"|"_..LDAPServer_":"_..LDAPPort)
	Quit $$$OK
}

Method OnInit() As %Status
{
	#; Create an instance of the LDAP Session object
	Do ..%SessionNewObject()  $$$ASSERT($IsObject(..%Session))
	Set tSC=##super() Quit:$$$ISERR(tSC) tSC
	Set:..StayConnected>0 ..KeepaliveInterval=..StayConnected
	If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
	Quit $$$OK
}

Method LDAPServerSet(val As %String) As %Status
{
	Set tConnected=..Connected
	Do:tConnected ..Disconnect()
	Set i%LDAPServer=val
	if tConnected Do ..Connect(..ConnectTimeout) // not using ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

Method LDAPPortSet(val As %Integer) As %Status
{
	Set tConnected=..Connected
	Do:tConnected ..Disconnect()
	Set i%LDAPPort=val
	if tConnected Do ..Connect(..ConnectTimeout) // not using ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

Method UseSSLSet(val As %Boolean) As %Status
{
	Set tConnected=..Connected
	Do:tConnected ..Disconnect()
	Set i%UseSSL=val
	if tConnected Do ..Connect(..ConnectTimeout) // not using ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

/// Connect to the data source
Method Connect(pTimeout As %Numeric = 30) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		If ..Connected { Do ..TestConnection() Quit:..Connected }
		If '$IsObject(..%CredentialsObj) Do ..CredentialsSet(..Credentials) If '$IsObject(..%CredentialsObj) { Set tSC=$$$EnsError($$$EnsErrNoCredentials,..Credentials) Quit }
		$$$sysTRACE("Connecting to LDAP Server '"_..LDAPServer_":"_..LDAPPort_"' / "_..Credentials_" with timeout="_pTimeout)
		Set t0=$zh, tSC=..%Session.Connect(..LDAPServer,..LDAPPort,..%CredentialsObj.Username,..%CredentialsObj.Password, ..UseSSL)	
		If $$$ISERR(tSC) {
			Set tSC=$S((-1'=pTimeout)&&($zh>=(t0+pTimeout)):
						$$$ADDSC($$$ERROR($$$EnsErrOutConnectExpired,pTimeout,"LDAP","'"_..LDAPServer_":"_..LDAPPort_"'/'"_..Credentials_"'"),tSC)
						, 1: $$$ERROR($$$EnsErrOutConnectFailed,$$$StatusDisplayString(tSC),"LDAP","'"_..LDAPServer_":"_..LDAPPort_"'/'"_..Credentials_"'"))
			Quit
		}
		#; Success
		Set ..Connected=1
		If ..BusinessHost.%LastReportedError [ "ERROR <Ens>ErrOutConnect" {
			Set ..BusinessHost.%LastReportedError=""
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Set tSC =$$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),"LDAP",..LDAPServer_":"_..LDAPPort_"/"_..Credentials)
	Goto Exit
}

/// Disconnect from the datasource
Method Disconnect(pFinal As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Quit:'..Connected
		$$$sysTRACE("Disconnecting from "_..LDAPServer_":"_..LDAPPort)
		Set ..%Session=$$$NULLOREF
		Set ..Connected=0
		If 'pFinal Do ..%SessionNewObject()  $$$ASSERT($IsObject(..%Session))
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Method AddNewEntry(pObjectClass As %String, pCN As %String, pBase As %String, pProps...) As %Status
{
	Quit ..AddNewEntryParmArray(.pObjectClass,pCN,.pBase,.pProps)
}

Method AddNewEntryParmArray(pObjectClass As %String, pCN As %String, pBase As %String = {..DN}, ByRef pProps = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tSC=..Connect(..ConnectTimeout) if $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed) ..BusinessHost.Retry=1 Quit
		Set tList=..%Session.GetPropList()
		Set tSC=tList.Insert("objectclass",pObjectClass)  Quit:$$$ISERR(tSC)
		If pCN["=" {
			Set tSC=tList.Insert($P(pCN,"="),$P(pCN,"=",2))  Quit:$$$ISERR(tSC)
		} Else {
			Set tSC=tList.Insert("cn",pCN)  Quit:$$$ISERR(tSC)
		}
		For i=1:1:pProps {
			Set k=$P(pProps(i),"="), v=$P(pProps(i),"=",2,$L(pProps(i),"="))
			Set tSC=tList.Insert(k,v)  Quit:$$$ISERR(tSC)
		}
		Quit:$$$ISERR(tSC)
		Set tSC=..%Session.AddNewEntry($S("cn="=$E($ZCVT(pCN,"L"),1,3):"",1:"cn=")_pCN_$S(""=pBase:"",1:","_pBase),tList)
	} While 0
Exit
	Do:'..StayConnected||($$$ISERR(tSC)&&..isNetErr($$$StatusText(tSC))) ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

/// pScope: 0=search base, 1=search one level,  2=search subtree
/// pFilter: the search criteria <a href=http://www.ietf.org/rfc/rfc2254.txt>(see RFC2254).</a>
/// pAttrs: comma-separated list of attributes to return per found entry.
Method Search(Output pEntries As %Net.LDAP.Client.Entries, pScope As %Net.LDAP.Client.Search.Scope = 2, pFilter As %String = "", pAttrs As %String = "", pMaxItems As %Integer = 250, pBase As %String = {..DN}) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, pEntries=$$$NULLOREF
	Do {
		Set tSC=..Connect(..ConnectTimeout)  If $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed) ..BusinessHost.Retry=1 Quit
		Set ..%Session.MaxItems=pMaxItems
		Set tStringList=..%Session.GetStringList()
		For i=1:1:$L(pAttrs,",") { Set tAttr=$P(pAttrs,",",i)  Continue:""=tAttr
			Do tStringList.Insert(tAttr)
		}
		Set pEntries=..%Session.Search(pBase, pScope, pFilter, tStringList, 1000*..SearchTimeout)
		If '$IsObject(pEntries) {
			Set tSC=pEntries,pEntries=$$$NULLOREF
		}
	} While 0
Exit
	
	Do:'..StayConnected||($$$ISERR(tSC)&&..isNetErr($$$StatusText(tSC))) ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Method GetEntryEditObj(Output pEditObj As %Net.LDAP.Client.EditEntry, pCN As %String, pBase As %String = {..DN}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,pEditObj=$$$NULLOREF
	Do {
		Set tSC=..Connect(..ConnectTimeout) if $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed) ..BusinessHost.Retry = 1 Quit
		Set pEditObj=..%Session.EditEntry($S("cn="=$E($ZCVT(pCN,"L"),1,3):"",1:"cn=")_pCN_$S(""=pBase:"",1:","_pBase))
	} While 0
Exit
	Do:$$$ISERR(tSC)&&..isNetErr($$$StatusText(tSC)) ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Method DeleteEntry(pCN As %String, pBase As %String = {..DN}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tSC=..Connect(..ConnectTimeout) if $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed) ..BusinessHost.Retry=1 Quit
		Set tSC=..%Session.DeleteEntry($S("cn="=$E($ZCVT(pCN,"L"),1,3):"",1:"cn=")_pCN_$S(""=pBase:"",1:","_pBase))
	} While 0
Exit
	Do:'..StayConnected||($$$ISERR(tSC)&&..isNetErr($$$StatusText(tSC))) ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Method RenameEntry(pCN As %String, pNewRDN As %String, pNewParent As %String = "", pDeleteOld As %Boolean = 1, pBase As %String = {..DN}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tSC=..Connect(..ConnectTimeout) if $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed) ..BusinessHost.Retry = 1 Quit
		Set tSC=..%Session.RenameEntry($S("cn="=$E($ZCVT(pCN,"L"),1,3):"",1:"cn=")_pCN_$S(""=pBase:"",1:","_pBase), .pNewRDN, pNewParent, pDeleteOld)
	} While 0
Exit
	Do:'..StayConnected||($$$ISERR(tSC)&&..isNetErr($$$StatusText(tSC))) ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Method TestConnection()
{
	Quit:'..Connected
	Set $ZT="Trap"
	Do {
		#; $$$sysTRACE("Testing Connection to "_..LDAPServer_":"_..LDAPPort_"/"_..Credentials)
		Set tSC = $$$OK //!!!..%Session.LDAPRelAttr(7)
	} while (0)
Exit
	if $$$ISERR(tSC) {
		Do ..Disconnect()
		$$$LOGSTATUS($$$ERROR($$$EnsErrOutConnectionLost,"LDAP", ..LDAPServer_":"_..LDAPPort_"/"_..Credentials, $S($$$ISOK(tSC):"",1:$$$StatusDisplayString(tSC))))
	}
	Quit
Trap
 	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Method OnTearDown() As %Status
{
	Do ..Disconnect(1)
	Quit $$$OK
}

/// Decide whether an error code returned from the driver represents
///  a disconnection implying the need to re-connect.
/// Override this method in a subclass if you encounter errors with another server
///  that ought to be in this list.
/// Also please ask the InterSystems IRIS developers to add your new codes to the base version.
ClassMethod isNetErr(tErrorText) As %Boolean
{
	Set tTxt=$ZCVT(tErrorText,"L")
	Set is=tTxt["ldap error(81)" ; Server Down
		 ||(tTxt["ldap error(52)") ; Unavailable
	If is { $$$sysTRACE("Assuming network disconnect error based on: "_tErrorText) }
	Else {  $$$catTRACE("protocol","NOT assuming network disconnect error based on: "_tErrorText) }
	Quit is
}

Method OnKeepalive(pUnused As %Status) As %Status
{
	If ..Connected && (..StayConnected>0) && ($ZH-..BusinessHost.%LastHandledTime>=..StayConnected) {
		$$$sysTRACE("Disconnecting on expiration of idle interval StayConnected="_..StayConnected)
		Do ..Disconnect()
	}
	Quit ##super($$$OK)
}

}
