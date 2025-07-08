/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a calculated member within an MDX query.
Class %DeepSee.Query.calculatedMember Extends set [ System = 3 ]
{

/// Name of the dimension this calculated member is associated with.
Property parentDimension As %DeepSee.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Name of this calculated member.
Property memberName As %DeepSee.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Original name of this calculated member (in its original case).
Property originalName As %DeepSee.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "none");

/// Full name of quality measure (if appropriate) with catalog and set information.
Property qmsrName As %DeepSee.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "none");

/// This specifies where this calculated member was defined.
Property origin As %DeepSee.Datatype.string(MAXLEN = 50, VALUELIST = ",query,cube,session", XMLPROJECTION = "none") [ InitialExpression = "query", Internal ];

/// Solve order to apply to this member.
Property solveOrder As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Format string to apply to this member.
Property formatString As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Set true when the definition of this calculated member has been resolved into a query graph
/// and added to the children of this node.
Property isResolved As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// Original definition of this member.
Property definition As %DeepSee.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "none");

/// Convert this node to its text representation.
/// Note, this is assumed to be called from the context of an axis or slicer
/// so it returns the name of the calculated member itself and not its definition.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK

	If (+$G(%dsMakeKey) && (..children.Count()>0)) {
		// If we are creating the query key, then use the resolved value
		Quit ..children.GetAt(1).%ToString()
	}
	// JMD1406
	If ($$$UPPER(..parentDimension)="%QUALITYMEASURE") {
		Quit "["_..parentDimension_"].["_..qmsrName_"]"
	}
	
	// DTB724 - Case is preserved in the originalName, use this if it is defined
	Set tMemberName = ..memberName
	Set tOriginalName = ..originalName
	If (tOriginalName'="") {
		Set pSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tOriginalName,.tInfo)
		If $$$ISERR(pSC) Quit ""
		
		Set tMemberName = tInfo(1)
	}

	Quit "["_..parentDimension_"].["_$$$dsEscapeIdent(tMemberName)_"]"
}

/// Return type of this node.
Method %GetType() As %String
{
	If ($$$UPPER(..parentDimension) = "MEASURES") {
		Quit $$$dstMeasure
	}
	Quit $$$dstMember
}

/// Execute and build the axes output for this set.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tIsOrset = 0		// DTB248
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		
		// calc member should only have one child!
		Set tSetNode = pParent
		Set pNewNodeNo = pNodeNo

		Set tChild = ..children.GetAt(1)
		If ($IsObject(tChild)) {
			Set tSC = tChild.%PreProcess()
			If $$$ISERR(tSC) Quit

			Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo,.tNewNodeNo,pParent,pVisible)
			If $$$ISERR(tSC) Quit
		}
		
		// +DTB248 - Special handling if the child is an %OR. Find the first node in or
		// and see if it is an orset
		Set tTestNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNewNodeNo))
		If (tChild.%IsA("%DeepSee.Query.setFunction") && (tChild.function="%OR") && (tTestNode'="")) {
			Set tTestParent = $LG(tTestNode,4)
			While (tTestParent>pParent) {
				Set tTestNodeNo = tTestParent
				Set tTestNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tTestNodeNo))
				Set tTestParent = $LG(tTestNode,4)
			}

			Set tIsOrset = ("orset" = $LG(tTestNode,1))
		}
		// -DTB248
		
		// apply member name to first child node
		If ($G(tNewNodeNo) '= "") {
			// JMD:887 only add node to parent if not already there !!!
			// + WAL033 -- if this node already has a parent or doesn't exist, don't add it to
			// the parent node, since this can cause errors or infinite loops 
			Set tSkip=0
			Set tIsSet=0    // WAL066
			Set tNewNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNewNodeNo))
			If (tNewNode="") {
				Set tSkip=1
			}
			Else {
				// + WAL066 -- if this node is not a measure, expression, or aggregate and if it has multiple
				//             children, don't rename
				Set tNewNodeType = $LG(tNewNode,1)
				If (($$$UPPER(..parentDimension)'="MEASURES") && (tNewNodeType'="exp") && (tNewNodeType'="agg")) {
					Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNewNodeNo,"ch",""))
					If (tChild'="") {
						Set tMoreChildren = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNewNodeNo,"ch",tChild))
						If (tMoreChildren'="") {
							Set tIsSet = 1		
						}
					}
				}
				// - WAL066
				Set tNewNodeParent = $LG(tNewNode,4)
				If (tNewNodeParent'=pParent) {
					Set tSkip=1
				}
			}
			If ('tSkip) {
				If '$D($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",tNewNodeNo)) {
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",tNewNodeNo) = ""
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",tNewNodeNo) = ""
					Set leaf = $I(%leafCount)
				}
			}
			// - WAL033
			Set pNewNodeNo = tNewNodeNo

			Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCube,.tSC)
			If $$$ISERR(tSC) Quit

			Set tCubeIndex = $$$DeepSeeIndex(pCube)
			Set tName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(..originalName)
			// lookup display name
			Set tDName = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER(..parentDimension),$$$UPPER(tName))
			If (tDName '= "") {
				Set tName = tDName
			}
			// JMD:887 find bottom visible node; change it's name (tuple case)
			// + WAL033 -- don't bother renaming the node if we're skipping it
			If ('tSkip)||(tIsOrset) {
				Set tBottomNodeNo = tNewNodeNo
				While (tBottomNodeNo'="") {
					If ($LG($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tBottomNodeNo),2)) {
						Set:('tIsSet) $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tBottomNodeNo),5) = tName  // + WAL066 -- if 'tIsSet
						Set:..formatString'="" $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tBottomNodeNo),12) = ..formatString
						Set:..solveOrder'=0 $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tBottomNodeNo),15) = ..solveOrder
						Quit
					}
					Set tBottomNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tBottomNodeNo,"ch",""))
				}
			}
			// - WAL033
			
			// +DTB400 - A chained aggregate needs to get relabeled as well.
			// Look for the aggregate root node, check its visibility, and
			// relabel if visible. Set other attributes as well
			Set tAggParent = $LG($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNewNodeNo),24)
			If (tAggParent'="") {
				If ($LG($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggParent),4)=pParent) {
					Set:('tIsSet) $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggParent),5) = tName  // + WAL066 -- if 'tIsSet
					Set:..formatString'="" $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggParent),12) = ..formatString
					Set:..solveOrder'=0 $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggParent),15) = ..solveOrder
				}
			}
			// -DTB400
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
