/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// A helper class for the implementation of delegates.
Class Ens.AbstractDelegate Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Initializes an instance of a delegate	
ClassMethod InitializeDelegate(pDelegateClass As Ens.DataType.Class, pRequiredType As Ens.DataType.Class, pHost As %RegisteredObject, ByRef pSC As %Status) As Ens.AbstractDelegate
{
	#dim tDelegate As Ens.AbstractDelegate
	
	Set pSC=$$$OK,tDelegate=$$$NULLOREF,$ZT="ItsATrap"
	Do {	
		// Construct the delegate (if specified)
		If pDelegateClass'="" {
		
			// Validate the routing delegate class type
			If pRequiredType'="",'$$IsDerivedFrom^%occLibrary(pDelegateClass,pRequiredType) {
				Set tSC=$$$ERROR($$$EnsErrClassNotDerived,pDelegateClass,pRequiredType)
				Quit
			}
		
			Set tDelegate = $ZOBJCLASSMETHOD(pDelegateClass,"%New",pHost)
			If '$IsObject(tDelegate) Set tSC=%objlasterror Quit
			
			// Done.
		}
	} While (0)
Exit
	Quit tDelegate
ItsATrap
	Set $ZT="",pSC=$$$EnsSystemError,tDelegate=$$$NULLOREF
	Goto Exit
}

/// TODO: Override this for custom initialization.  Note that the pSender parameter will be the "owner" of the delegate
Method %OnNew(pSender As %RegisteredObject) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit $$$OK
}

///  TODO: Add delegate methods in a subclass ...

}
