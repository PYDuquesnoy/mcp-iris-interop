/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Projection class used by the <class>%DeepSee.CubeDefinition</class> class.
/// This class takes care of any work that needs to happen when
/// a cube definition is created (compiled) or deleted.
/// This class should be considered INTERNAL.
Class %DeepSee.CubeProjection Extends %Projection.AbstractProjection [ System = 3 ]
{

ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String) As %Status
{
 	Set tSC=$$$OK
	Try {
		If ($$$comClassDefined(pClassName)) {
			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%DeepSee.CubeDefinition")) {

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
					}
					Else {
						// DP-428865 - Register this schema with the xDBC client role
						// DP-432784 - Call the grant function which escalates privileges 
						Do GrantCubeSchemaSelect^%SYS.DeepSee(pClassName)
					}
					
					Set tRegClass = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU))
					If (tRegClass = "") {
						Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU) = pClassName
						Set $$$DeepSeeMetaGLVN("classes",pClassName) = tCubeName
					}
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
			If ('tAbstract && (pClassName'="%DeepSee.CubeDefinition")) {

				#; Remove this cube from the list of Cubes
				Set tCubeName = $G($$$DeepSeeMetaGLVN("classes",pClassName))
				Set tCubeNameU = $$$UPPER(tCubeName)

				#; make sure we are the right cube
				If ((tCubeNameU'="")&&(pClassName = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU)))) {
					#; remember current cube name and sync time (for recompile)
					If (recompile) {
						Set ^||%Cls(pClassName,"cube") = tCubeName
						Set tLastTimeStamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tCubeNameU)		// DTB838 - Use API
						If (tLastTimeStamp'="") {
							Set ^||%Cls(pClassName,"dstime") = tLastTimeStamp
						}
						
						// DTB961 - Try to preserve the previous storage definition
						Merge ^||%Cls(pClassName,"storage") = $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"storage")

						// remember current meta data
						// DTB949 - Log the prior if there is no previous error, so the prior only ever represents
						// the last *successful* compile.
						If '$D($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"compileError")) {
							Kill $$$DeepSeeMetaGLVN("prior",tCubeNameU)
							Merge $$$DeepSeeMetaGLVN("prior",tCubeNameU) = $$$DeepSeeMetaGLVN("cubes",tCubeNameU)	
						}
						Else {
							// DTB961 - There was a compile error, try to fetch the storage from the prior
							Merge ^||%Cls(pClassName,"storage") = $$$DeepSeeMetaGLVN("prior",tCubeNameU,"storage")
						}
					}

					Kill $$$DeepSeeMetaGLVN("classes",pClassName)
					Kill:tCubeNameU'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU)

					#; kill cache
					If ('recompile) {
						Set tSC = ##class(%DeepSee.Query.Engine).%CubeRemoved(tCubeName,pClassName)
						Quit:$$$ISERR(tSC)
					}
					
					// BDB267: delete iKnow domains managed by this cube if not recompiling.
					// when recompiling, this will be taken care of by
					// %DeepSee.CubeDefinition.%GetModel()
					if ('recompile) {
						set tMsrPropName = ""
						for {
							set tMsrPropName = $order($$$DeepSeeMetaGLVN("prior", tCubeNameU, "fact", "prop", tMsrPropName))
							quit:tMsrPropName=""
						
							set tMeasure = $g($$$DeepSeeMetaGLVN("prior", tCubeNameU, "fact", "prop", tMsrPropName, "msrname"))
							set tIndexType = $g($$$DeepSeeMetaGLVN("prior", tCubeNameU, "fact", "prop", tMsrPropName, "index"))
							continue:$piece(tIndexType,":",1)'="iKnow"
						
							// skip iKnow-managed domains
							continue:$piece(tIndexType,":",2)="domain"
						
							// derive domain name
							set tDomainName = $piece(tIndexType,":",3)
							set:tDomainName="" tDomainName = ##class(%iKnow.DeepSee.CubeUtils).GetDeepSeeDomainName(tCubeNameU,tMeasure)
						
							set tSC = ##class(%iKnow.DeepSee.CubeUtils).DropDomain(tDomainName)
							quit:$$$ISERR(tSC)
						}
						quit:$$$ISERR(tSC)
					}
					
					// +DTB130 - Clean up the ^DeepSee.Cubes("versionIndex")
					If ##class(%DeepSee.CubeVersion.Utils).%IsVersion(tCubeNameU,.tGenericCubeName,.tVersion) {
						If ('recompile) {
							If (##class(%DeepSee.CubeVersion.Utils).%IsActiveVersion(tCubeNameU)) {
								Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tGenericCubeName),"activeVersion")
							}
							If (##class(%DeepSee.CubeVersion.Utils).%IsPendingVersion(tCubeNameU)) {
								Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tGenericCubeName),"pendingVersion")
							}
							
							Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tGenericCubeName),tVersion)
							Kill $$$DeepSeeMetaGLVN("versionIndex","versionOf",tCubeNameU)
						}
					}
					// -DTB130
					
					// System cleanup of metadata and SQL access when the cube is being deleted
					If 'recompile {
						// DP-428865 - Revoke privileges on this schema to clean up the xDBC client role
						// DP-432784 - Call the revoke function which escalates privileges 
						Do RevokeCubeSchemaSelect^%SYS.DeepSee(pClassName)
						
						// DTB990 - Remove the "sharesIndex" entries
						Kill $$$DeepSeeMetaGLVN("sharesIndex",tCubeNameU)
						
						Kill $$$DeepSeeMetaGLVN("prior",tCubeNameU)
						Kill $$$DeepSeeMetaGLVN("classes",pClassName)

						// Remove data update timestamps when the definition is being dropped
						Kill $$$DeepSeeUpdateQueue("cubes",tCubeNameU)
					}
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
