/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines an axis within a DeepSee query.
Class %DeepSee.Query.axis Extends group [ System = 3 ]
{

/// Query that this axis belongs to.
Relationship query As %DeepSee.Query.query(XMLPROJECTION = "none") [ Cardinality = one, Inverse = axes ];

/// Collection of subqueries associated with this axis.
Property subqueries As list Of %DeepSee.ResultSet(XMLPROJECTION = "NONE");

/// If true, then empty tuples (e.g. complete rows or columns) are removed
/// from the results of the query.<br/>
/// This is equivalent to the MDX "NON EMPTY" key word.
Property nonEmpty As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Reference to the context where this object is used in the overall query structure
Property context As %String(VALUELIST = "axis,filter,filterAxis", XMLPROJECTION = "none") [ InitialExpression = "axis" ];

/// List of facts this axis depends on.
Property %dependencies As %String [ Internal, MultiDimensional ];

/// List of current member markers along this axis.
Property %cmbrIndex As %String [ Internal, MultiDimensional ];

/// Copy of the original string used to produce this axis object
Property %originalSpec As %String;

/// Once calculated the axis key is stabilized for this particular object.
Property %AxisKey As %String;

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Set tText = ""
	
	Set tCount = ..children.Count()
	If (tCount = 0) {
		Quit tText
	}

	// DP-424293 - For a filterAxis, quit with a null string by default. If the base cube query is requested,
	// return this as an explicit filter clause.
	Quit:(..context="filterAxis")&&'$G(%baseCubeQuery) tText

	If (..nonEmpty) {
		Set tText = tText _ "" _ "NON EMPTY "
	}

	// axis should never have more than one child
	If (tCount>1) {
		Set tText = tText _ "{"
	}

	For n = 1:1:tCount {
		Set tChild = ..children.GetAt(n)
		Set tText = tText _ $S(n>1:",",1:"") _ tChild.%ToString(.pSC)
		If $$$ISERR(pSC) Quit
	}

	If (tCount>1) {
		Set tText = tText_"}"
	}

	Quit tText
}

/// Execute and build the axes output for this axis.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Do $I(%SetOpDepth(pKey))		// DP-424589

		Set tCubeIndex = $$$DeepSeeIndex(pCube)

		Do:$G(%dstrace) ##class(%DeepSee.Utils).%WriteToLog("Trace",$$$dsCurrentMethod _ ":" _ tCubeIndex _ ":" _ $CLASSNAME() _ ":" _ ..%ToString())
		
		// process and save cmbr index, if any
		If $D(..%cmbrIndex) {
			Set k = $O(..%cmbrIndex(""))
			While (k'="") {
				Set tSpec = ..%cmbrIndex(k)
				Set tInfo = ""

				// parse spec; test for relations
				Kill tSpecInfo
				Set tRelSpec = ""
				Set tFCube = pCube
				Set tFCubeIndex = tCubeIndex
				Set tFSpec = tSpec
				While (1) {
					Kill tSpecInfo2
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tFCube,tFSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo2,.tCalcMbrs)
					If $$$ISERR(tSC) Quit
					If (tRelationName="") {
						Merge tSpecInfo = tSpecInfo2
						Quit
					}

					Set tRelSpec = tRelSpec _ $S(tRelSpec'="":".",1:"") _ "[" _ tSpecInfo2(1) _ "]"
					Set tFCube = ##class(%DeepSee.Utils).%GetRelatedCube(tFCube,tRelationName)
					Set tFCubeIndex = $$$DeepSeeIndex(tFCube)
					Set tFSpec = tRelationSpec
				}
				If $$$ISERR(tSC) Quit

				Set tDimName = $$$UPPER($G(tSpecInfo(1)))
				Set tHierName = $$$UPPER($G(tSpecInfo(2)))
				Set tLevelName = $$$UPPER($G(tSpecInfo(3)))

				If (tLevelName'="") {
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tFCubeIndex,"mbrs",tDimName,tHierName,tLevelName))
					If ((tInfo="")&&(tHierName'="")) {
						// fall back
						Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tFCubeIndex,"mbrs",tDimName,tHierName))
					}
				}
				ElseIf (tHierName'="") {
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tFCubeIndex,"mbrs",tDimName,tHierName))
					If ((tInfo="")&&(tDimName'="")) {
						// fall back
						Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tFCubeIndex,"mbrs",tDimName))
					}
				}
				ElseIf (tDimName'="") {
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tFCubeIndex,"mbrs",tDimName))
				}
				If (tInfo'="") {
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"cmbrIndex",k) = $LB($$$UPPER(tSpec),+$LG(tInfo,1),+$LG(tInfo,2),+$LG(tInfo,3),$$$UPPER(tRelSpec))
				}
				Set k = $O(..%cmbrIndex(k))
			}
		}

		Set tChildCount = ..children.Count()
		For n=1:1:tChildCount {
			Set tChild = ..children.GetAt(n)
			Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, pParent)
			If $$$ISERR(tSC) Quit
			Set:n=1 pNewNodeNo = tNewNodeNo
		}
		If $$$ISERR(tSC) Quit
		
		// DTB400 - Once the axis is processed, extract the complex aggregate
		Set tSC = ..%CopyComplexAggregate(pCube,pKey)
		If $$$ISERR(tSC) Quit

		// DP-421810 - After all processing is complete, convert all sets that are direct children of a slicer to orsets
		// There is an exception if the axis contains a measure, in this case the OSET processing cannot handle the presence
		// of a measure and so cannot be applied. This should be rare in newer versions but is a needed consideration for
		// legacy queries
		If ($$$dsAxisNodeTypeGet($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1))="slicer")&&'##class(%DeepSee.Query.query).%HasMeasure($this) {
			Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"ch",""))

			Set tMultiLeaf = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"all",""))'=$O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"all",""),-1)
			
			While (tNodeNo'="") {
				Set tNode = $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNodeNo)
				If ($$$dsAxisNodeTypeGet(tNode)="set") {
					Set tMultiKids = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNodeNo,"ch",""))'=$O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNodeNo,"ch",""),-1)

					If tMultiLeaf||tMultiKids {
						Set tNodeTemp = tNodeNo
						Set tNodeParentNo = $$$dsAxisNodeParentGet(tNode)
						Set tSC = ##class(%DeepSee.Query.setFunction).%New().ORSET(pCube,tCubeIndex,pKey,.tNodeTemp,.tNodeTemp,tNodeParentNo,tNodeNo)
						If $$$ISERR(tSC) Quit
					}
				}
	
				Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"ch",tNodeNo))
			}
		}

		Do $I(%SetOpDepth(pKey),-1)		// DP-424589

		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"termCount") = ..%CountTerms(tCubeIndex,pKey)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Review the contents of an axis and count the number of terms within it that will translate into bit operations. This performs a blind count
/// and ignores chain/child structures so it can be called at any stage of axis construction.
Method %CountTerms(pCubeIndex As %String, pAxisKey As %String, Output pStatus As %Status) As %Integer
{
	// Method added by DP-425943
	Set pStatus = $$$OK
	Set tTermCount = 0
	
	Try {
		Set tNodeNo = 0
		For {
			Set tNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",tNodeNo),1,tNode)
			Quit:(tNodeNo="")

			// Log the presence of any nodes that will require a bit operation to resolve. This does not consider operational context, it is
			// a raw count of terms present in the axis. 
			If ($$$dsAxisNodeTypeGet(tNode)="mbr") {
				Set tKey = $$$dsAxisNodeKeyGet(tNode)
				Do $I(tTermCount,$S(tKey="":0,1:$L(tKey,"|")))
			}
		}
	}	
	Catch ex {
		Set pStatus = ex.AsStatus()
	}

	Quit tTermCount
}

/// Incates whether or not this axis is a placeholder %SEARCH axis.
Method %IsSearch(Output pSC As %Status) As %Boolean [ Internal ]
{
	// Method added by DTB141
	Set pSC = $$$OK
	Set tIsSearch = 0
	Try {
		Set tChild = ..children.GetAt(1)
		If '($IsObject(tChild)&&tChild.%IsA("%DeepSee.Query.memberSpec")) {
			Quit
		}
		
		Set tSpec = tChild.spec
		Do ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tSpec,.tInfo)
		
		If ($$$UPPER(tInfo(1))="%SEARCH") {
			Set tIsSearch = 1
		}
	}
	Catch ex {
		Set pSC = ex.AsStatus()
	}
	Quit tIsSearch
}

/// If the axis contains a complex aggregate, copy it and set it aside in a special<br> 
/// ^DeepSee.Cache.Axis(cubeKey,axisKey,"agg")<br> 
/// node. A complex aggregate is marked by the presence of $LI(node,24).
ClassMethod %CopyComplexAggregate(pCube As %String, pKey As %String) As %Status [ Internal ]
{
	// Method added by DTB400
	Set tSC = $$$OK
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Set tNodeNo = ""
	Try {
		Set tAllNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"all",""),-1)
		While (tAllNodeNo'="") {
			// Look up from the all node for a complex aggregate
			Set tAggNodeNo = ""
			
			Set tNodeNo = tAllNodeNo
			While tNodeNo'="" {
				// Walk up
				Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tNodeNo))
				
				If tNodeNo=$LG(tNodeInfo,24) {
					Set tAggNodeNo = tNodeNo
					Quit
				}
				Else {
					Set tNodeNo = $LG(tNodeInfo,4)
				}
			}

			// Walk down the aggregate chain since the "all" node may be the top node number.
			// Copy the elements of a complex aggregate chain into the special "cellAgg" node.
			While tAggNodeNo'="" {
				Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggNodeNo))
				
				If $LG(tNodeInfo,24)'="" {		
					Merge $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"cellAgg",tAllNodeNo,tAggNodeNo) = $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggNodeNo)
				}
				
				If $D($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggNodeNo,"ch")) {
					Set tAggNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tAggNodeNo,"ch",""))
				}
				Else {
					Set tAggNodeNo = "" 
				}
			}

			Set tAllNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",1,"all",tAllNodeNo),-1)
		}

	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
