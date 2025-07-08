/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Projection class used by the <class>%DeepSee.SubjectArea</class> class.
/// This class takes care of any work that needs to happen when
/// a subject area is created (compiled) or deleted.
/// This class should be consider INTERNAL.
Class %DeepSee.SubjectAreaProjection Extends %Projection.AbstractProjection [ System = 3 ]
{

ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String) As %Status
{
 	Set tSC=$$$OK
	Try {
		If ($$$comClassDefined(pClassName)) {
			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%DeepSee.SubjectArea")) {
				Set tCubeName = $zobjclassmethod(pClassName,"%GetCubeName")
				If (tCubeName="")&&$D(^||%Cls(pClassName,"oldCubeName"),tOldCubeName) {
					// DTB949 - Try to preserve the old cube name if the %GetCubeName method didn't compile
					// or could not return a value for any reason
 					Set tCubeName = tOldCubeName
				}
				Set tCubeNameU = $$$UPPER(tCubeName)

				#; Add this cube to the (local) index of Cubes
				If (tCubeNameU '= "") {
					If $D(^||%Cls(pClassName,"error"),tCompileError) {
						// DTB949 - Log a compile error in the metadata
						Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"compileError") = tCompileError
						If ($G(^||%Cls(pClassName,"oldBaseCube"))'="") {
							Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"baseCube") = $G(^||%Cls(pClassName,"oldBaseCube"))
						}
					}
					
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU) = pClassName
					Set $$$DeepSeeMetaGLVN("classes",pClassName) = tCubeName
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod RemoveProjection(pClassName As %String, ByRef parameters As %String, recompile As %Boolean) As %Status
{
 	Set tSC=$$$OK
	Try {
		If ($$$comClassDefined(pClassName)) {
			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%DeepSee.SubjectArea")) {
				#; Remove this subject area from the list of Cubes
				Set tCubeName = $G($$$DeepSeeMetaGLVN("classes",pClassName))
				Set tCubeNameU = $$$UPPER(tCubeName)

				#; make sure we are the right subject area
				If ((tCubeNameU'="")&&(pClassName = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU)))) {
					If recompile {
						Set ^||%Cls(pClassName,"cube") = tCubeName		// DTB949
						Set ^||%Cls(pClassName,"baseCube") = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"baseCube"))
					}
					Kill $$$DeepSeeMetaGLVN("classes",pClassName)
					Kill:tCubeName'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
