/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Projection class used by the <class>%DeepSee.KPI</class> class.
/// This class takes care of any work that needs to happen when
/// a KPI is created (compiled) or deleted.
/// This class should be consider INTERNAL.
Class %DeepSee.KPIProjection Extends %Projection.AbstractProjection [ System = 3 ]
{

ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		If ($$$comClassDefined(pClassName)) {
			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%DeepSee.KPI") && (pClassName'["%DeepSee.PlugIn")) {

				Set tKPIName = $zobjclassmethod(pClassName,"%GetKPIName")
				Set tKPINameU = $ZCVT(tKPIName,"U")

				#; Add this KPI to the (local) index of KPIs
				If (tKPINameU '= "") {
					Set tRegClass = $G($$$DeepSeeMetaGLVN("kpis",tKPINameU))
					If (tRegClass = "") {
						Set $$$DeepSeeMetaGLVN("kpis",tKPINameU) = pClassName
						Set $$$DeepSeeMetaGLVN("classes",pClassName) = tKPIName
					}
				}
			}
		}
	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod RemoveProjection(pClassName As %String, ByRef parameters As %String, recompile As %Boolean) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		If ($$$comClassDefined(pClassName)) {
			// JMD945: Make sure cache and index is killed for this KPI
			Kill $$$DeepSeeKPIGLVN($$$UPPER(pClassName))
			Set tCubeName = $O($$$DeepSeeKPIGLVN("-index-",""))
			While (tCubeName'="") {
				If ($D($$$DeepSeeKPIGLVN("-index-",tCubeName,$$$UPPER(pClassName)))) {
					Kill $$$DeepSeeKPIGLVN("-index-",tCubeName,$$$UPPER(pClassName))
				}
				Set tCubeName = $O($$$DeepSeeKPIGLVN("-index-",tCubeName))
			}

			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%DeepSee.KPI") && (pClassName'["%DeepSee.PlugIn")) {

				#; Remove this subject area from the list of KPIs
				Set tKPIName = $G($$$DeepSeeMetaGLVN("classes",pClassName))
				Set tKPINameU = $ZCVT(tKPIName,"U")

				#; make sure we are the right KPI
				If ((tKPINameU'="")&&(pClassName = $G($$$DeepSeeMetaGLVN("kpis",tKPINameU)))) {
					Kill $$$DeepSeeMetaGLVN("classes",pClassName)
					Kill:tKPIName'="" $$$DeepSeeMetaGLVN("kpis",tKPINameU)
				}
			}
		}
	} While(0)
Exit
  	Quit tSC
Trap
 	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
