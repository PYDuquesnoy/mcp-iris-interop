/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsebXMLErrors)

/// An abstract service to handle ebXML requests
Class EnsLib.ebXML.Service.AbstractService Extends EnsLib.ebXML.Service.AbstractServiceDelegate [ Abstract, System = 4 ]
{

/// Name of a class that implements the EnsLib.ebXML.Operation.AbstractOperationDelegate interface that we can call to do routing
Property ServiceDelegateClass As Ens.DataType.Class(EXTENDS = "EnsLib.ebXML.Service.AbstractServiceDelegate");

Property ServiceDelegate As EnsLib.ebXML.Service.AbstractServiceDelegate [ InitialExpression = {$this} ];

Parameter SERVICEDELEGATE As %String = "EnsLib.ebXML.Service.AbstractServiceDelegate";

/// Target to route inbound ebXML messages to
/// To route based on header properties, use something like:
///   MHS-${Headers(MessageHeader).To.PartyId(1).content}
Property DefaultTarget As Ens.DataType.ConfigNameTemplate;

/// Timeout for dispatch (so we don't hold up the HTTP service too long or hang up a production shutdown)
Property Timeout As %Integer [ InitialExpression = 25 ];

/// Settings
Parameter SETTINGS As %String = "DefaultTarget,Timeout,ServiceDelegateClass";

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		// Construct the delegate (if specified)
		If ..ServiceDelegateClass'="" {
			Set ..ServiceDelegate = ##class(Ens.AbstractDelegate).InitializeDelegate(..ServiceDelegateClass,..#SERVICEDELEGATE,$this,.tSC)
			Quit:$$$ISERR(tSC)
		} Else {
			// We implement our own delegate providing a default implementation
			Set ..ServiceDelegate = $this
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Authors of BusinessService implements this method to receive incoming data
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tTarget As Ens.DataType.ConfigName
		#dim tTimeout As %Integer
		
		Set tTarget = ..DefaultTargetReplaceWithObjectProperties(..DefaultTarget,pInput)
		Set tTimeout = ..Timeout
		
		// Invoke the delegate to allow for per-message customization
		Set tSC = ..ServiceDelegate.RouteMessageToTargetProcessWithTimeout($this, pInput, pHint, .tTarget, .tTimeout)
		Quit:$$$ISERR(tSC)
		
		// Check for a target
		If tTarget="" {
			Set tSC = $$$EnsError($$$EnsErrTargetNotSpecified,"DefaultTarget")
			Quit
		}
				
		// Now dispatch with timeout
		Set tSC = ..SendRequestSync(tTarget,pInput,.pOutput,tTimeout)
		Quit:$$$ISERR(tSC)
		
		#dim tSynthesizedError As %Status = $$$OK
		
		// Allow processing of the response before returning it to the remote MHS
		Set tSC = ..ServiceDelegate.ProcessResponseToRemoteMHS($this, pInput, .pOutput, .tSynthesizedError)
		Quit:$$$ISERR(tSC)

		// Synthesize an error if appropriate
		If '$$$ISOK(tSynthesizedError) Set tSC = tSynthesizedError
		
		// Done!
		
	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Dispatch the ebXML request to a business service
ClassMethod dispatchToBusinessService(pConfigName As Ens.DataType.ConfigName, pRequest As EnsLib.ebXML.Message, pHint As %String, ByRef pResponse As EnsLib.ebXML.Message) As %Status [ Private ]
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

Method RouteMessageToTargetProcessWithTimeout(pSender As %RegisteredObject, ByRef pMessage As EnsLib.ebXML.Message, pHint As %String, ByRef pTarget As %String, ByRef pTimeout As %Integer) As %Status
{
	Quit $$$OK
}

Method ProcessResponseToRemoteMHS(pSender As %RegisteredObject, pRequest As EnsLib.ebXML.Message, ByRef pResponse As EnsLib.ebXML.Message, ByRef pStatus As %Status) As %Status
{
	Quit $$$OK
}

}
