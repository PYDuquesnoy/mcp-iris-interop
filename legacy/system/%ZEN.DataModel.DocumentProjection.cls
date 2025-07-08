/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// Projection class used by the <class>%ZEN.DataModel.AbstractDocument</class> class.
/// This class takes care of any work that needs to happen when
/// a document interface is created (compiled) or deleted.
/// This class should be considered INTERNAL.
Class %ZEN.DataModel.DocumentProjection Extends %Projection.AbstractProjection [ Deprecated, System = 3 ]
{

ClassMethod CreateProjection(pClassName As %String, ByRef parameters As %String) As %Status
{
 	Set tSC=$$$OK
	Try {
		If ($$$comClassDefined(pClassName)) {
			Set tAbstract = +$$$comClassKeyGet(pClassName,$$$cCLASSabstract)
			If ('tAbstract && (pClassName'="%ZEN.DataModel.AbstractDocument")) {

				Set tDocName = $ClassMethod(pClassName,"%GetDocumentName")

				#; Add this to the (appropriate) index of documents
				If (tDocName'="") {
					If ($E(pClassName)="%") {
						Set ^%ISC.ZEN.Documents("docs",tDocName) = pClassName
						Set ^%ISC.ZEN.Documents("classes",pClassName) = tDocName
					}
					Else {
						Set ^ISC.ZEN.Documents("docs",tDocName) = pClassName
						Set ^ISC.ZEN.Documents("classes",pClassName) = tDocName
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
			If ('tAbstract && (pClassName'="%ZEN.DataModel.AbstractDocument")) {

				#; Remove this document from the list
				If ($E(pClassName)="%") {
					Set tDocName = $G(^%ISC.ZEN.Documents("classes",pClassName))
					Kill ^%ISC.ZEN.Documents("classes",pClassName)
					Kill:tDocName'="" ^%ISC.ZEN.Documents("docs",tDocName)
				}
				Else {
					Set tDocName = $G(^ISC.ZEN.Documents("classes",pClassName))
					Kill ^ISC.ZEN.Documents("classes",pClassName)
					Kill:tDocName'="" ^ISC.ZEN.Documents("docs",tDocName)
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
