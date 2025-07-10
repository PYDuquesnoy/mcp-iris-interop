/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Projection.Production Extends %Projection.AbstractProjection [ ClassType = "", ProcedureBlock, System = 3 ]
{

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Don't run this method on the base class
		If classname="Ens.Production" Quit
		
		If ##class(Ens.Config.Production).%ExistsId(classname) {
			Do ##class(Ens.Config.Production).%DeleteId(classname)
		}
		
		#; Find the XDATA itself
		Set tSC=##class(Ens.Util.XML.XDataEntityResolver).EntityFromXDATA(.tStream,classname,"ProductionDefinition")
		If $$$ISERR(tSC) Quit
		
		#; Create a SAX resolver for the Schema
		Set tResolver=##class(Ens.Util.XML.XDataEntityResolver).%New("Ens.Schema.Production")
 		$$$ASSERT($IsObject(tResolver))
 		
 		Set tSC=##class(Ens.Util.XML.Validator).ValidateStream(tStream,tResolver,"Schema")
 		If $$$ISERR(tSC) {	
			Set tSC=$$$ADDSC($$$ERROR($$$EnsErrInvalidProduction),tSC)
		} Else {
			Set tSC=##class(Ens.Config.Production).LoadFromClass(classname)
		}
	} while (0)
Exit
	Set ^IRIS.Temp.EnsProdConfigChange($Namespace,classname) = $$$timeUTC // Track compilation
	Set tSC2 = $$$AuditModifyProductionConfig(classname,"","Production class compiled")
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean) As %Status
{
	#; Don't run this method on the base class
	If classname="Ens.Production" Quit $$$OK
	If ##class(Ens.Config.Production).%ExistsId(classname) {
		Do ##class(Ens.Config.Production).%DeleteId(classname)
	}
	Set ^IRIS.Temp.EnsProdConfigChange($Namespace,classname) = $$$timeUTC // Track uncompilation
	Set tSC2 = $$$AuditModifyProductionConfig(classname,"","Production class deleted or uncompiled")
	Quit $$$OK
}

}
