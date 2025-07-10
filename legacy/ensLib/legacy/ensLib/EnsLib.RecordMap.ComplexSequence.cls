/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.RecordMap.ComplexSequence Extends (EnsLib.RecordMap.ComplexChild, EnsLib.RecordMap.ComplexParent) [ Abstract, NoExtent, PropertyClass = EnsLib.RecordMap.ComplexBatchPropertyParameters, System = 4 ]
{

Method PutSequence(pIOStream As %IO.DeviceStream) As %Status
{
	Quit $$$NotImplemented
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tID = $$$oidPrimary(oid)
	Quit ..DeleteRecords(tID)
}

Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	If '$get(%EnsRecordMap("StrictValidation")) Quit $$$OK
	Quit ..ValidateObject()
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	Quit ..UpdateReferences()
}

}
