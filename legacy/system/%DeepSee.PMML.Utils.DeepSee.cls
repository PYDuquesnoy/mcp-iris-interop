/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.PMML.Utils.DeepSee [ System = 4 ]
{

ClassMethod GetFactPropertyForSpec(pCubeName As %String, pSpec As %String, pAsSQL As %Boolean = 0, Output pExpression As %String) As %Status [ Internal ]
{
	set tSC = $$$OK, pExpression = ""
	try {
		set tDimNo = 0, tHierNo = 0, tLevelNo = 0
		set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCubeName, pSpec, .tDimNo, .tHierNo, .tLevelNo)
		quit:$$$ISERR(tSC)
		
		set tCubeName = $$$DeepSeeIndex(pCubeName)
		set tLevelInfo = $$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",tDimNo,tHierNo,tLevelNo)
		if $li(tLevelInfo,1)="m" {
			set tColName = $$$DeepSeeMetaGLVN("cubes",tCubeName,"msr#",$li(tLevelInfo,5))
			set pExpression = tColName
		} else {
			set tColName = $li(tLevelInfo,7) // TODO: verify, check time dims
			set pExpression = tColName_"."_tColName
		}
		
		set:pAsSQL pExpression = $replace(pExpression,".","->")
				
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod RunModelForListing(pCubeName As %String, pSourceObjectId As %Integer, pDefinitionClass As %String, pModelName As %String = "", pFeature As %String = "predictedValue") As %String [ SqlProc ]
{
	set tSC = $$$OK, tResult = ""
	try {
		set tBaseCube = $$$DeepSeeIndex(pCubeName)
		set tFactId = $o($$$DeepSeeIndexGLVN(tBaseCube, "%sourceId", pSourceObjectId, ""))
		
		// translate NULL values passed in from SQL
		set pModelName = $case(pModelName, $c(0):"", :pModelName)
		
		set tModelClass = $classmethod(pDefinitionClass, "%GetModelClassName", pModelName)
		
		set tModel = $classmethod(tModelClass, "%New")
		set tSC = tModel.%ExecuteModelDeepSee(tFactId, .tOutput)
		quit:$$$ISERR(tSC)
		
		set tResult = tOutput.%GetFeatureValue(pFeature)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:tResult)
}

}
