/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a tuple within a query.<br/>
/// A tuple specifies a specific set of facts within the cube.<br/>
/// This corresponds to the (A,B,C) construct in MDX.<br/>
Class %DeepSee.Query.tuple Extends set [ System = 3 ]
{

/// Return type of this node.
Method %GetType() As %String
{
	Quit $$$dstMember
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Set tText = ""
	Set tCount = ..children.Count()
	If (tCount>0) {
		Set tText = tText_"("
		For n = 1:1:tCount {
			Set tChild = ..children.GetAt(n)
			Set tText = tText _ $S(n>1:",",1:"") _ tChild.%ToString(.pSC)
			If $$$ISERR(pSC) Quit
		}
		Set tText = tText_")"
	}
	Quit tText
}

/// Process axes for this set.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Do $I(%SetOpDepth(pKey))		// DP-424589

		// JMD1455 check for tuple(expr); simplify
		// DP-424589 - check for tuple(mbr) and simplify
		Set tChildCount = ..children.Count()
		If (tChildCount=1) {
			Set tChild = ..children.GetAt(1)
			If tChild.%IsA("%DeepSee.Query.expression") || tChild.%IsA("%DeepSee.Query.memberSpec") {
				// Do not add a tuple node to the axis, skip straight to processing the child.
				Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo, .pNewNodeNo, pParent, pVisible)
				Quit
			}
		}
		
		// add node to axis tree
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("tuple",0,0,pParent,,+$G(%SetOpDepth(pKey)),$classname()_":"_$$$dsCurrentMethod)		// DP-424589 - Add depth to new tuple
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set tTupleNode = pNodeNo
		Set tSetNode = pNodeNo
		Set pNewNodeNo = pNodeNo

		// list children
		Kill tChildren
		For n=1:1:tChildCount {
			Set tChild = ..children.GetAt(n)
			If (tChild.%IsA("%DeepSee.Query.expression")) {
				Set tSC = $$$ERROR($$$GeneralError,"Tuple must not contain an expression: " _ ..%ToString())
				Quit
			}
			Set tChildren(n) = tChild
		}
		If $$$ISERR(tSC) Quit
		
		// tuple swap: push cmbrs to bottom of tuple!
		If (1) {
			For a=1:1:tChildCount-1 {
				If (tChildren(a).%IsA("%DeepSee.Query.memberFunction")&&($$$UPPER(tChildren(a).function)="CURRENTMEMBER")) {
					If ('(tChildren(a+1).%IsA("%DeepSee.Query.memberFunction"))||($$$UPPER(tChildren(a+1).function)'="CURRENTMEMBER")) {
						// swap
						Set x = tChildren(a+1)
						Set tChildren(a+1) = tChildren(a)
						Set tChildren(a) = x
					}
				}
			}
		}

		// process children
		// Make each child a child of its prior sibling
		// No child of tuple can be a set
		Set tLastWasOR = 0
		Set tLastWasTuple = 0		// DTB871
		For n=1:1:tChildCount {
			// only last child should have its visible and compute flags set
			Set tChildrenVisible = pVisible && (n=tChildCount)
			Set tChild = tChildren(n)
			Set tType = tChild.%GetType()
			
			If tChild.%IsA("%DeepSee.Query.setFunction")&&(tChild.function="%CUBE") {
				// DTB333 - In compound cubes, members could be wrapped in the special %CUBE function which handles
				// references to shared dimensions
				Set tType = tChild.children.GetAt(2).%GetType()
			}
			
			If (tType = $$$dstSet) {
				Set tSC = $$$ERROR($$$GeneralError,"Tuple must not contain a set: " _ ..%ToString())
				Quit
			}
			// JMD1453 insert a "tuple" node to mark the end of the "orset"
			If (tLastWasOR) {
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("tuple",0,0,tSetNode,,+$G(%SetOpDepth(pKey)),$$$dsCurrentMethod)		// DP-424589 - Add depth to new tuple
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode,"ch",+pNodeNo) = ""
				Set pNewNodeNo = pNodeNo
				Set tSetNode = pNodeNo
			}
			If (tLastWasTuple) {
				// DTB871 - Reset the positioning for adding the next member behind a nested tuple
				Set pNewNodeNo = pNodeNo
				Set tSetNode = pNodeNo
			}
			
			Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, tSetNode, tChildrenVisible)
			If $$$ISERR(tSC) Quit
			If '+$G(tNewNodeNo) {
				// DTB742 - Child processing returned without tNewNodeNo getting set. Protect the next execution
				// of the loop from a <SUBSCRIPT> error.
				Set tNewNodeNo = pNodeNo
			}
			Set tSetNode = tNewNodeNo

			// JMD1453 check for %OR within tuple
			Set tLastWasOR = 0
			If (tChild.%IsA("%DeepSee.Query.setFunction")&&(tChild.function="%OR")) {
				If tChild.children.GetAt(1).%IsA("%DeepSee.Query.set")&&(tChild.children.GetAt(1).children.Count()>1) {
					// DTB695 - A %OR with only one child does not need special treatment
					Set tLastWasOR = 1
				}
				ElseIf tChild.children.GetAt(1).%IsA("%DeepSee.Query.set")&&tChild.children.GetAt(1).children.GetAt(1).%IsA("%DeepSee.Query.tuple") {
					// DTB695 (2) - If the %OR set's content is a tuple, keep the %OR behavior!
					Set tLastWasOR = 1
				}
			}
			
			Set tLastWasTuple = 0
			If ( $LG($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tSetNode),1)="tuple") || (tChild.%IsA("%DeepSee.Query.tuple")) {
				// DTB871 - Check the content of the last tuple member. This might have been a calculated member that inserted a nested tuple into the first member position, for example.
				Set tLastWasTuple = 1
			}
		}
		If $$$ISERR(tSC) Quit

		// force compute flag to 0 for all but the last child
		Set tChildNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tTupleNode,"ch",""))
		While (tChildNode'="") {
			// next child
			Set tNextChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNode,"ch",""))
			If (tNextChild'="") {
				// set compute flag to 0
				Set $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNode),3)=0

				// JMD762: force visible to false
				Set $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tChildNode),2)=0

				// JMD792: remove node from "all" list
				If $D($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"all",tChildNode)) {
					Set %leafCount = %leafCount - 1
					Kill $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"all",tChildNode)
				}
			}
			Set tChildNode = tNextChild
		}

		Do $I(%SetOpDepth(pKey),-1)		// DP-424589
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
