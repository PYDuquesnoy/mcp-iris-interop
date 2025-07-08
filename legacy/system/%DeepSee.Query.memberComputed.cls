/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized version of the member class used for computed dimensions.
Class %DeepSee.Query.memberComputed Extends %DeepSee.Query.member [ System = 4 ]
{

/// Process the member id, name, and key information for this member.
/// Put the result into <var>pSet</var>.
Method %ProcessMembers(pParent As %Integer, Output pSet As %List) As %Status [ Internal ]
{
	// DTB721 - Check that %SQLRESTRICT is in the slicer
	If (..%dimNumber=-1)&&($G(%dsIsSlicer)'=1) {
		Set tSC = $$$ERROR($$$GeneralError,"%SQLRESTRICT may only be used in the slicer.")
		Quit tSC
	}

	// JMD1511 intercept so that we can the "recompute" flag for this axis
	If (($G(%cubeIndex)'="")&&($G(%axisKey)'="")) {
		Set $$$DeepSeeAxisGLVN(%cubeIndex,%axisKey,"recompute") = 1
	}
	Quit ##super(pParent,.pSet)
}

/// Test if <var>pName</var> is a valid member name.
Method %FindMemberByName(pName As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, pLevel As %Integer = "", Output pMemberKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set pMemberKey = ""
		Set tCubeIndex = $$$DeepSeeIndex($$$UPPER(..%cube))
		Set tItemCaption = pName

		If (pLevel '= "") {
			Set tLevelNo = pLevel
		}
		Else {
			// look up info for current Dim/Hier
			// Level should be last member of memberSpec
			Set tLevelNo = $O(..%memberSpec(""),-1)
			Set tLevelNo = tLevelNo + 1
			If (..%levelNumber > tLevelNo) {
				Set tLevelNo = ..%levelNumber
			}

			// test for ALL level
			If ((tLevelNo=1)&&(..%allName'="")) {
				If (..%allName = pName) {
					Set ..%memberSpec(tLevelNo) = $LB(pName,"","")
					Quit
				}
				Set tLevelNo = tLevelNo + 1
			}
		}

		While (pFlag = 0) {
			Set tExists = ..%GetNodeInfo(..%cube,pDim, pHier, tLevelNo, .tFact, .tDimClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList,.tStarKeyField)
			If ('tExists) {
				Quit
			}

			// dispatch to dimension class
			Set tDimObj = $zobjclassmethod(tDimClass,"%Create",..%cube,tFact,pDim,pHier,tLevelNo)
			If '$IsObject(tDimObj) {
				Set tSC = $$$ERROR($$$GeneralError,"Unable to create computed dimension object: " _ tDimClass)
				Quit
			}

			Set tBehavior = tDimObj.%GetBehavior()
			Set tFlag = 0

			// n.b., no null marker for computed dimensions
			If (+tHasMemberList) {
				Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeIndex,.tSC)
				If $$$ISERR(tSC) Quit

				// use member list
				Set n = 0
				Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDim,pHier,tLevelNo,"mbr",""),1,data)
				While (p'="") {
					Set tItemName = $LG(data,1)
					If ($$$UPPER(tItemName) = $$$UPPER(pName)) {
						If (tCubeClass'="") {
							Set tItemCaption = $classmethod(tCubeClass,"%GetLevelMemberCaption",pDim,pHier,tLevelNo,tItemName)
						}
						Set:tItemCaption="" tItemCaption = pName
						Set tKEY = $LG(data,2)
						Set tFlag = 1
						Set tSC = tDimObj.%ComputeBitset(tKEY,.tID)
						If $$$ISERR(tSC) Quit
						Quit
					}
					Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDim,pHier,tLevelNo,"mbr",p),1,data)
				}
			}

			// JMD1366: check run-time list
			If ('tFlag) {
				Set tSC = tDimObj.%FindComputedMemberByName(pName,.tFlag,.tKEY,.tID)
				If $$$ISERR(tSC) Quit
			}
			
			If (tFlag) {
				Set ..%memberSpec(tLevelNo) = $LB(tItemCaption,tID,tKEY)
 				Set pMemberKey = tKEY
				Set pFlag = 1
				Quit
			}
			If (pLevel'="") {
				Quit
			}
			// try next level
			Set tLevelNo = tLevelNo + 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the member with the given key.
Method %FindMemberByKey(pKey As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, Output pMemberValue As %String, pRecurse As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set pMemberValue = ""

		// look up info for current Dim/Hier
		// Level should be last member of memberSpec
		Set tLevelNo = $O(..%memberSpec(""),-1)
		Set tLevelNo = tLevelNo + 1
		If (..%levelNumber > tLevelNo) {
			Set tLevelNo = ..%levelNumber
		}

		// skip all level
		If ((tLevelNo=1)&&(..%allName'="")) {
			Set tLevelNo = tLevelNo + 1
		}

		Set tDone = 0
		While (tDone = 0) {
			Set tExists = ..%GetNodeInfo(..%cube,pDim, pHier, tLevelNo, .tFact, .tDimClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,,.tStarKeyField)
			If ('tExists) {
				Quit
			}

			// dispatch to dimension class
			Set tDimObj = $zobjclassmethod(tDimClass,"%Create",..%cube,tFact,pDim,pHier,tLevelNo)
			If '$IsObject(tDimObj) {
				Set tSC = $$$ERROR($$$GeneralError,"Unable to create computed dimension object: " _ tDimClass)
				Quit
			}

			Set tBehavior = tDimObj.%GetBehavior()

			Set tSC = tDimObj.%FindComputedMemberByKey(pKey,.tFlag,.tName,.tID)
			If $$$ISERR(tSC) Quit

			If (tFlag) {
				If (tBehavior="MDX") {
					// ID is an MDX expression; process it
					Set tExpr = tID
					Set tSC = ..%GetNodeForMDX(.tNode, ..%cube, 1, tName, tExpr)
					If $$$ISERR(tSC) Quit
					Set ..%dimNumber = $LG(tNode,9)
					Set ..%hierNumber = $LG(tNode,10)
					Set ..%levelNumber = $LG(tNode,11)
					Set ..%memberId = $LG(tNode,13)
					Set ..%memberKey = $LG(tNode,6)
					Set ..%memberSpec(tLevelNo) = $LB(tName,..%memberId,..%memberKey)
				}
				Else {
					Set ..%memberSpec(tLevelNo) = $LB(tName,tID,pKey)
				}
				Set pMemberValue = tName
				Set pFlag = 1
				Set tDone = 1
			}
			If ('pRecurse) {
				Set tDone = 1
			}
			ElseIf ('pFlag) {
				// try next level
				Set tLevelNo = tLevelNo + 1
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the set of members that match the given criteria and place them
/// into the axis tree.<br/>
ClassMethod %GetMembers(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, pKey As %String, ByRef pNodeNo As %Integer, pRecurse As %Integer = 0, ByRef pRange As %String, ByRef pMemberList) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tDimClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList,.tStarKeyField)
		If ('tExists) {
			// no level
			Quit
		}
		Set tCubeName = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		New %cube
		Set %cube = tCubeName

		// test for ALL level
		If (pLevelNo = 1) {
			Set tAllName = ..%GetAllName(pCubeName,pDimNo,.tAllCaption)
			If (tAllName '= "") {
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("mbr",1,1,pParent,tAllCaption,"",tFact,,pDimNo,pHierNo,pLevelNo,,"")
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)

				If (pRecurse '= 0) {
					// n.b. do not pass range up
					Set tSC = ..%GetMembers(pCubeName, pDimNo, pHierNo, pLevelNo + 1,"", pParent,pKey,.pNodeNo,pRecurse)
					If $$$ISERR(tSC) Quit
				}
				Quit
			}
		}

		// get dimension class interface
		Set tDimObj = $zobjclassmethod(tDimClass,"%Create",pCubeName,tFact,pDimNo,pHierNo,pLevelNo)
		If '$IsObject(tDimObj) {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to create computed dimension object: " _ tDimClass)
			Quit
		}
		Set tBehavior = tDimObj.%GetBehavior()

		// get set of members for this level
		Kill tMemberList

		// dispatch
		Set tSC = tDimObj.%GetPredefinedMembers(.tMemberList,tCubeIndex,pDimNo,pHierNo,pLevelNo)
		If $$$ISERR(tSC) Quit

		Set tSC = tDimObj.%GetComputedMembers(.tMemberList, pRollupKey, .pRange)
		If $$$ISERR(tSC) Quit

		// sort by name
		Set n = $O(tMemberList(""))
		While (n'="") {
			Set data = tMemberList(n)
			If (tSortDir="") {
				// unsorted 
				Set tName = "*"
			}
			ElseIf ((tSortDir="asc#")||(tSortDir="desc#")) {
				Set tName = +$LG(data,2)
			}
			Else {
				Set tName = $LG(data,2)
			}
			Set tMemberListSorted(tName,n) = data
			Set n = $O(tMemberList(n))
		}		

		Set tDir = $S(tSortDir="desc":-1,tSortDir="desc#":-1,1:1)
		Set k = $O(tMemberListSorted(""),tDir)
		While (k'="") {
			Set n = $O(tMemberListSorted(k,""),tDir)
			While (n'="") {
				Set data = $G(tMemberListSorted(k,n))
				Set tID = $LG(data,1)
				Set tName = $LG(data,2)
				Set tKEY = $LG(data,3)
				If (tBehavior = "MDX") {
					Set tExpr = tID
					If (tExpr="") {
						Set tNode = $LB("lit",1,1,pParent,tName,"Not defined")
					}
					Else {
						// process the mdx expression
						Set tSC = ..%GetNodeForMDX(.tNode, pCubeName, pParent, tName, tExpr)
						If $$$ISERR(tSC) Quit

						// plug in format, if provided
						If $LD(data,4) {
							Set $List(tNode,12) = $LG(data,4)
						}
					}
				}
				Else {
					// BITSET
					// JMD1366: if ID has not been computed, do it now
					If (tID="") {
						Set tSC = tDimObj.%ComputeBitset(tKEY,.tID)
						// swallow error here; let it show up later
						Set tSC = $$$OK
						If $$$ISERR(tSC) Quit
					}
					If ((tName'="")&&(tKEY'="")) {
						// tack name onto key so that it shows up in queries
						Set tKEY = tName _ ":" _ tKEY
					}
					Set tNode = $LB("mbr",1,1,pParent,tName,tID,tFact,,pDimNo,pHierNo,pLevelNo,,tKEY)
				}

				If $$$ISERR(tSC) Quit
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
				If (pRecurse > 0) {
					// n.b. do not pass range up
					Set tSC = ..%GetMembers(pCubeName, pDimNo, pHierNo, pLevelNo + 1,tID, pParent,pKey,.pNodeNo,pRecurse,,.pMemberList)
					Quit:$$$ISERR(tSC)
				}
				Set n = $O(tMemberListSorted(k,n),tDir)
			}
			Set k = $O(tMemberListSorted(k),tDir)
		}

		// mark the axis as needing a recompute
		// as we can't be sure that there will be the same number of members each time
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"recompute") = 1
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given an MDX expression, return an info node ($list) for the resolved expression.<br/>
ClassMethod %GetNodeForMDX(Output pNode As %List, pCubeName As %String, pParent As %Integer, pName As %String, pExpr As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pNode = ""
		New %axis
		Set tIsSlicer = +$G(%isSlicer)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		// process the mdx expression
		Set tQuery = $G(%query,##class(query).%New())
		Set tGroup = ##class(set).%New()
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMDXExpression(pExpr,tQuery,tGroup,.tNodeObj)
		If $$$ISERR(tSC)||'$IsObject(tNodeObj) {
			Set tNode = $LB("lit",1,1,pParent,pName,"Invalid: " _ pExpr)
			Set tSC = $$$OK
		}
		Else {
			Set tNode = $LB("lit",1,1,pParent,pName,"")

			// process the member spec
			Set %axis = 1
			Set tLocalNodeNo = 1
			Set tLocalKey = -$R(10000000000) // use random key to avoid conflict
			Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)

			// JMD1366: process group and not node
			Set tSC = tGroup.%PreProcess(tIsSlicer)
			If $$$ISERR(tSC) Quit

			// don't let leafCount change!
			Set tOldLeaf = $G(%leafCount)
			Set tSC = tGroup.%ProcessAxes(tCubeIndex, tLocalKey, .tLocalNodeNo,,1)
			If $$$ISERR(tSC) Quit

			Set:tOldLeaf'="" %leafCount = tOldLeaf

			// result should have one member
			Set k = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",""))
			If (k'="") {
				Set tNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",k))
				Set $List(tNode,4) = pParent
				Set $List(tNode,5) = pName
			}
			Kill $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)
			If $$$ISERR(tSC) Quit
		}
		
		Set pNode = $G(tNode)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
