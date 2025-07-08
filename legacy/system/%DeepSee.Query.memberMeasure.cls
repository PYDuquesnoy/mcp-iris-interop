/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized version of the member class used for measures.
Class %DeepSee.Query.memberMeasure Extends %DeepSee.Query.member [ System = 4 ]
{

/// Test if <var>pName</var> is a valid measure name.
Method %FindMemberByName(pName As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, pLevel As %Integer = "", Output pMemberKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set pMemberKey = ""
		Set tName = $$$UPPER(pName)

		Set tNode = $G($$$DeepSeeMetaGLVN("cubes",..%cube,"mbrs","MEASURES",tName))
		If (tNode = "") {
			Quit
		}
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",..%cube,"mbr#",$LG(tNode,1),$LG(tNode,2),$LG(tNode,3)))
		If (tInfo = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No information found for measure: " _ pName)
			Quit
		}

		Set ..%name = $LG(tInfo,3)
		Set ..%aggregate = $LG(tInfo,7,"SUM")
		Set ..%hierNumber = $LG(tNode,2)
		Set ..%levelNumber = $LG(tNode,3)
		Set pFlag = 1
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the state of this member using the current meta data node.
Method %ApplyState(pType As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%type = pType
		// other values should already be applied
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Process the member name and key information for this tuple.
/// Put the result into <var>pSet</var>.
Method %ProcessMembers(pParent As %Integer, Output pSet As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tExists = ..%GetNodeInfo(..%cube,..%dimNumber, ..%hierNumber, ..%levelNumber, .tFact,,,.tMsrType,.tScale,,.tFormat)
		If (tExists) {
			// !process name of internal measures!
			Set tName = ..%name
			Set tCountName = ##class(%DeepSee.Utils).%GetCountName(..%cube,.tSC)
			If $$$ISERR(tSC) Quit

			If ($$$UPPER(tName) = $$$UPPER(tCountName)) {
				Set tName = ##class(%DeepSee.Utils).%GetCountCaption(..%cube,.tSC)
				If $$$ISERR(tSC) Quit
			}
			// lookup display name for measure
			Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(..%cube,.tSC)
			If $$$ISERR(tSC) Quit
			Set tMsrCaption = $zobjclassmethod(tClassName,"%GetMemberCaption","MEASURES",$$$UPPER(tName))
			Set:tMsrCaption="" tMsrCaption = tName
			
			Set pSet(1) = $LB("msr",1,1,+pParent,tMsrCaption,..%memberId,tFact,..%aggregate,..%dimNumber,..%hierNumber,..%levelNumber)
			// default formats
			If (tFormat="") {
				If (tMsrType = "date") {
					// JMD1009
					Set tFormat = "%date%"
				}
			}
			Set:tFormat'="" $List(pSet(1),12) = tFormat
			Set:tScale'="" $List(pSet(1),13) = tScale
			// JMD1382 use 17
			Set:tMsrType="boolean" $List(pSet(1),17) = "B"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the set of members that match the given criteria and place them
/// into the axis tree.<br/>
/// In this case, return all measures for the current cube.
ClassMethod %GetMembers(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, pKey As %String, ByRef pNodeNo As %Integer, pRecurse As %Integer = 0, ByRef pRange As %String, ByRef pMemberList) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCubeName = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		// Get list of measures from our cube
		// these are listed under dimension 0
		Set tMbrNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",0,0))
		While (tMbrNo '= "") {
			Set tNode = $$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",0,tMbrNo,0)
			Set tType = $LG(tNode,1)
			Set tMsrName = $LG(tNode,3)
			Set tMsrNo = $LG(tNode,5)
			Set tAgg = $LG(tNode,7)
			Set tMsrType = $LG(tNode,8)
			Set tHidden = $LG(tNode,11)
			Set tFormat = $LG(tNode,12)
			Set tScale = $LG(tNode,9)
			If ('tHidden && (tType="m")) {
				// lookup display name for measure
				Set tMsrCaption = $zobjclassmethod(tClassName,"%GetMemberCaption","MEASURES",$$$UPPER(tMsrName))
				Set:tMsrCaption="" tMsrCaption = tMsrName

				Set tMsrNode = $LB("msr",1,1,pParent,tMsrCaption,"",tMsrNo,tAgg,pDimNo,tMbrNo,pLevelNo)
				Set:tFormat'="" $List(tMsrNode,12) = tFormat
				Set:tScale'="" $List(tMsrNode,13) = tScale
				// JMD1382: move to node 17
				Set:tMsrType="boolean" $List(tMsrNode,17) = "B"
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tMsrNode
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
			}
			Set tMbrNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",0,tMbrNo))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
