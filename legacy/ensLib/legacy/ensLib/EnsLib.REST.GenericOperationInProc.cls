/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Same operation as EnsLib.REST.GenericOperation except this
/// will be run by the same process as the caller.
/// This allows a passthrough TCP session to be maintained. 
Class EnsLib.REST.GenericOperationInProc Extends EnsLib.REST.GenericOperation [ System = 4 ]
{

Parameter INVOCATION = "InProc";

/// Invoke a remote HTTP Service given a generic HTTP request
Method OnMessage(pRequest As EnsLib.HTTP.GenericMessage, Output pResponse As EnsLib.HTTP.GenericMessage) As %Status
{
	If '$G($$$EnsInProcPersist,1) Do ##class(Ens.Util.Statistics).InitStats(..%ConfigName)
	
	Set tSC=##super(pRequest,.pResponse)

	If '$G($$$EnsInProcPersist,1) && ##class(Ens.Util.Statistics).StatsStarted(..%ConfigName) {
		Do ##class(Ens.Util.Statistics).RecordStats($$$eHostTypeOperation,..%ConfigName)
	}
	
	Quit tSC
}

}
