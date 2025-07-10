/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Basic Print Service
Class EnsLib.Printing.PrintService Extends Ens.BusinessService [ System = 4 ]
{

/// Target to send print requests to
Property Target As Ens.DataType.ConfigName;

/// Settings
Parameter SETTINGS As %String = "Target";

/// Authors of BusinessService implements this method to receive incoming data
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		
		// Check for a target
		If ..Target="" {
			Set tSC = $$$EnsError($$$EnsErrTargetNotSpecified,"Target")
		}
				
		// Now dispatch with timeout
		Set tSC = ..SendRequestSync(..Target,pInput,.pOutput)
		
	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Dispatch the printing request to a business service
ClassMethod SubmitPrintRequest(pRequest As EnsLib.Printing.PrintRequest, pServiceName As %String = {$classname()}) As %Status
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
		Set tSC = ##class(Ens.Director).CreateBusinessService(pServiceName,.tService)
		Quit:$$$ISERR(tSC)
	
		// Now, process it
		Set tSC = tService.ProcessInput(pRequest)
		Quit:$$$ISERR(tSC)
		
	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
