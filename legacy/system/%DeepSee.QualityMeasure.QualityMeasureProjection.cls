/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Projection class used by the <class>%DeepSee.QualityMeasure.QualityMeasure</class> class.
/// This class takes care of any work that needs to happen when
/// a quality measure is created (compiled) or deleted.
/// This class should be consider INTERNAL.
Class %DeepSee.QualityMeasure.QualityMeasureProjection Extends %Projection.AbstractProjection [ System = 3 ]
{

ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String) As %Status
{
 	Set $ZT="Trap",tSC=$$$OK
	Do {
		If ($$$comClassDefined(pClassName)) {
			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%DeepSee.QualityMeasure.QualityMeasure")) {

				Set tQMSRName = $zobjclassmethod(pClassName,"%GetQualityMeasureName")
				Set tQMSRNameU = $ZCVT(tQMSRName,"U")

				#; Add this item to the (local) index of QualityMeasures
				If (tQMSRNameU '= "") {
					Set tRegClass = $G($$$DeepSeeQMsrGLVN("qmsrNames",tQMSRNameU))
					If (tRegClass = "") {
						Set $$$DeepSeeQMsrGLVN("qmsrNames",tQMSRNameU) = pClassName
						Set $$$DeepSeeQMsrGLVN("qmsrClasses",pClassName) = tQMSRName

						#; additional info
						Set tSubjectArea = $$$UPPER($classmethod(pClassName,"%GetSubjectArea"))

						Set $$$DeepSeeQMsrGLVN("qmsrNames",tQMSRNameU,"cube") = tSubjectArea

						#; we *could* have a csv list of cubes
						For p=1:1:$L(tSubjectArea,",") {
							Set tCube = $$$UPPER($P(tSubjectArea,",",p))
							Set:tCube'="" $$$DeepSeeQMsrGLVN("cubes",tCube,tQMSRNameU) = ""
						}
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
			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%DeepSee.QualityMeasure.QualityMeasure")) {

				#; Remove this item from the list of QualityMeasures
				Set tQMSRName = $G($$$DeepSeeQMsrGLVN("qmsrClasses",pClassName))
				Set tQMSRNameU = $ZCVT(tQMSRName,"U")

				#; make sure we are the right qmeasure
				If ((tQMSRNameU'="")&&(pClassName = $G($$$DeepSeeQMsrGLVN("qmsrNames",tQMSRNameU)))) {
					Set tSubjectArea = $G($$$DeepSeeQMsrGLVN("qmsrNames",tQMSRNameU,"cube"))
					For p=1:1:$L(tSubjectArea,",") {
						Set tCube = $$$UPPER($P(tSubjectArea,",",p))
						Kill:tCube'="" $$$DeepSeeQMsrGLVN("cubes",tCube,tQMSRNameU)
					}

					Kill $$$DeepSeeQMsrGLVN("qmsrClasses",pClassName)
					Kill $$$DeepSeeQMsrGLVN("qmsrNames",tQMSRNameU)
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
