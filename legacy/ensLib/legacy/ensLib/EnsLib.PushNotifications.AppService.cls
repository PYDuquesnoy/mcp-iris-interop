/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsPushNotificationsErrors)

/// ebXML Test Service
Class EnsLib.PushNotifications.AppService Extends Ens.BusinessService [ System = 4 ]
{

/// Target to route inbound messages to
Property Target As Ens.DataType.ConfigName;

/// Timeout for dispatch (so we don't hold up the HTTP service too long or hang up a production shutdown)
Property Timeout As %Integer [ InitialExpression = 25 ];

/// Settings
Parameter SETTINGS As %String = "Target,Timeout";

/// Authors of BusinessService implements this method to receive incoming data
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tTarget As Ens.DataType.ConfigName
		#dim tTimeout As %Integer
		
		Set tTarget = ..Target
		Set tTimeout = ..Timeout
		
		// Check for a target
		If tTarget="" {
			Set tSC = $$$EnsError($$$EnsErrTargetNotSpecified,"Target")
			Quit
		}
				
		// Now dispatch with timeout
		Set tSC = ..SendRequestSync(tTarget,pInput,.pOutput,tTimeout)
		Quit:$$$ISERR(tSC)
		
		// Done!
		
	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Dispatch the ebXML request to a business service
ClassMethod SendSync(pRequest As Ens.Request, ByRef pResponse As Ens.Response, pConfigName As Ens.DataType.ConfigName = {..%ClassName(1)}, pHint As %String = "") As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tService As Ens.BusinessService
		
		If $G($$$EnsRuntime("Name"))="" {
			Set tSC=$$$EnsError($$$EnsErrProductionNotRunning)
			Quit
		}
		
		// Construct the business service
		Set tSC = ##class(Ens.Director).CreateBusinessService(pConfigName,.tService)
		Quit:$$$ISERR(tSC)
	
		// Now, process it
		Set tSC = tService.ProcessInput(pRequest,.pResponse,pHint)
		Quit:$$$ISERR(tSC)
		
	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
