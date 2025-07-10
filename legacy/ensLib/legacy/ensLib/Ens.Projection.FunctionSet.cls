/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %Integration.Context)

Class Ens.Projection.FunctionSet Extends %Projection.AbstractProjection [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String) As %Status
{
	Quit ..notifyChange()
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String) As %Status
{
	Quit ..notifyChange()
}

ClassMethod notifyChange() As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim e As %Exception.AbstractException
	Try {
		#; Needs to be a central db for an instance
		#; Must be r/w even in mirror failover
		Set $$$interopFunctionSetsRoot = $ZH
	} Catch e { Set tSC = e.AsStatus()}
	Quit tSC
}

}
