/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Base class for adapters that communicate with external applications
Class Ens.Adapter Extends (%RegisteredObject, Ens.Settings) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Property BusinessHost As Ens.Host;

/// Frequency with which to wake up and call OnKeepalive() method
/// (not supported for InProc Operations)
Property KeepaliveInterval As %Numeric [ InitialExpression = 0 ];

/* (Override with a subclass if the Adapter needs extended credentials) *
 * (Add this to SETTINGS string for the subclass if it uses credentials) */
/// This is the ID name of the set of credentials values to be used to access the external system
Property Credentials As %String;

/// This is the credentials object containing the values to be used to access the datasouce
Property %CredentialsObj As Ens.Config.Credentials;

/// Flag whether we have already warned about the class being recompiled
Property %WarnedLatest As %Boolean [ InitialExpression = 0, Transient ];

/// ID of External Service Registry entry<br>
/// Leave blank if you are not using the external registry<br>
/// This will be used to find values to be applied to the Adapter and Host settings<br>
Property RegistryID As %String(MAXLEN = 260);

Method CredentialsSet(pInVal As %String) As %Status
{
	#; (Re)Set the Credentials object; do it always because we never know if the source row fields might have been updated
	#; make sure to instantiate even if re-setting to the InitialExpression string
	Set ..%CredentialsObj=$$$NULLOREF

	Set tClassname=$zobjmethod($this,"%ClassName",1) ; call subclass
	Set tClass = $$$comMemberKeyGet(tClassname,$$$cCLASSproperty,"%CredentialsObj",$$$cPROPtype)
	If ""'=tClass {
		Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tObj,tClassname,tClass,pInVal)
		If $$$ISOK(tSC) { Set ..%CredentialsObj=tObj }
		ElseIf '$$$StatusEquals(tSC,$$$EnsErrNoCallerCredentials) {
			$$$LOGSTATUS(tSC)
		}
	}
	Set i%Credentials=pInVal
	Quit $$$OK
}

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	Quit $$$OK
}

/// This user callback method is called just before %OnClose()
Method OnTearDown() As %Status
{
	Quit $$$OK
}

/// This method is called from the Host.OnTask() method. It will be called within KeepaliveInterval of the last return from OnTask() or OnKeepalive().
Method OnKeepalive(pStatus As %Status = {$$$OK}) As %Status
{
	If '..BusinessHost.%WarnedLatest&&'..BusinessHost.%ClassIsLatestVersion() {
		$$$LOGWARNING("Host Class "_$classname(..BusinessHost)_" has been recompiled; continuing to run using code from previous version")
		Set ..BusinessHost.%WarnedLatest=1
	}
	If '..%WarnedLatest&&'..%ClassIsLatestVersion() {
		$$$LOGWARNING("Adapter Class "_$classname()_" has been recompiled; continuing to run using code from previous version")
		Set ..%WarnedLatest=1
	}
	Quit ..BusinessHost.OnKeepalive(pStatus)
}

/// Clear runtime data for a config item. This is normally used to store
/// adapter error status for input files, and is cleared automatically
/// each time the item restarts.
ClassMethod ClearRuntimeAppData(pConfigName As %String)
{
	Kill $$$EnsRuntimeAppData(pConfigName)
}

/// Clear static data for a config item. This is normally used to store
/// already-processed status for input files, and other persistent values related
/// to adapters, such as the %LastId for the SQL Inbound Adapter.
ClassMethod ClearStaticAppData(pConfigName As %String)
{
	Kill $$$EnsStaticAppData(pConfigName)
}

/// Clear both static and runtime App Data
ClassMethod ClearAllAppData(pConfigName As %String)
{
	Do ..ClearRuntimeAppData(pConfigName)
	Do ..ClearStaticAppData(pConfigName)
}

}
