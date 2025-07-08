/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a member specification within a DeepSee query.<br/>
/// A member specification defines a specific member from a dimension
/// such as "[Product]", "[Product].[Name]", or "[Location}.[Boston]".<br/>
/// A set of members may be grouped within a single tuple or a single member
/// may exist stand-alone.<br/>
/// Every memberSpec has a corresponding <class>member</class> object
/// that implements any operations needed to be run against the member,
/// such as getting a list of dimension members for a given member.<br/>
Class %DeepSee.Query.memberSpec Extends group [ System = 3 ]
{

/// Specification string for this member.
/// This is text from the query.
Property spec As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Member object that provides the member API for this member.
/// This is created during the pre-processing phase.
Property %member As %DeepSee.Query.member(XMLPROJECTION = "none");

/// This array holds our member spec *after* it has been resolved.
Property %resolvedSpec As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// This array holds a list of which items in the resolved list are quoted.
Property %resolvedQuoted As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Resolved member keys, if any.
Property %memberKeys As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Break our spec into it constituent parts.<br/>
/// If the spec contains named parameters, resolve them.<br/>
/// We do this as soon as we are first asked for our value and then
/// we hold onto the resolved value.
Method %ResolveValue() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tSpec = ..spec
		Do {
			Set tResolved = 1
			Kill tInfo,tQuoted,tMemberKey

			// Parse/validate spec
			// If there are named parameters, resolve them until there are none remaining
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tSpec, .tInfo,.tQuoted,.tMemberKey)
			If $$$ISERR(tSC) Quit

			// look for NOW reference: replace with key value
			If $D(%cube) {
				Set k = $O(tInfo(""))
				While (k'="") {
					If ((k>1)&&($$$UPPER($E($G(tInfo(k)),1,3))="NOW")) {
						// see if we are in a time dimension
						Set tNode = ""
						Set tDimName = $$$UPPER($G(tInfo(1)))
						If (k > 3) {
							Set tHierName = $$$UPPER($G(tInfo(2)))
							Set tLevelName = $$$UPPER($G(tInfo(3)))
							Set tNode = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",tDimName,tHierName,tLevelName))
						}
						ElseIf (k > 2) {
							// test if 2nd piece is a hier or level name
							Set tHierName = $$$UPPER($G(tInfo(2)))
							If $D($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",tDimName,tHierName)) {
								Set tLevelName = ""
								Set tNode = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",tDimName,tHierName))
							}
							Else {
								Set tLevelName = $$$UPPER($G(tInfo(2)))
								Set tHierName = $O($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",tDimName,""))
								Set tHierName = $$$UPPER(tHierName)
								Set tNode = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",tDimName,tHierName,tLevelName))
							}
						}
						Else {
							Set tHierName = ""
							Set tLevelName = ""
							Set tNode = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",tDimName))
						}

						If (tNode '= "") {
							Set tDimNo = +$LG(tNode,1)
							Set tHierNo = +$LG(tNode,2)
							Set tLevelNo = +$LG(tNode,3)
							Set:tHierNo=0 tHierNo = 1
							Set:tLevelNo=0 tLevelNo = 1

							Set tNodeInfo = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,tHierNo,tLevelNo))
							If ($LG(tNodeInfo,1)="all") {
								Set tLevelNo = tLevelNo + 1
								Set tNodeInfo = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,tHierNo,tLevelNo))
							}
							Set tNodeInfo = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,tHierNo,tLevelNo))
							Set tNodeInfoH = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,tHierNo,0))

							Set tLevelClass = $LG(tNodeInfo,6)
							If (($LG(tNodeInfoH,6)="%DeepSee.Query.memberTime")&&(tLevelClass'="")) {
								// replace NOW with time value
								Set tFormat = $LG(tNodeInfo,14)
								Set tTimeOffset = $LG(tNodeInfo,15)
								Set tInfo(k) = $classmethod(tLevelClass,"%ValueToKey",tInfo(k),tFormat,tTimeOffset)
								Set tMemberKey(k) = 1
							}
						}
						Quit
					}
					Set k = $O(tInfo(k))
				}
			}

			Set tRSpec = ""
			Set k = $O(tInfo(""))
			Set tInSearch=0
			While (k'="") {
				Set tNamedParm = 0
				If ('$G(tQuoted(k))&&($E(tInfo(k))="@")&&$IsObject($G(%query))) {		// DTB776 - Make sure the query object exists!
					Set tSC = %query.%ResolveNamedParm($E(tInfo(k),2,*),.tText)
					If $$$ISERR(tSC) Quit
					Set tNamedParm = 1
					Set tResolved = 0
					Set tInfo(k) = tText
				}
				// JMD1017: if the relationship is a range, don't add extra .
				If (tInfo(k)=":") {
 					Set tRSpec = tRSpec _ tInfo(k)
				}
				ElseIf tNamedParm&&($E(tInfo(k))="&") {    
					// DTB087 - named parameter contained a key. Append it and re-resolve
					Set tRSpec = tRSpec _ $S((tRSpec="")||($E(tRSpec,$L(tRSpec))=":"):"",1:".") _ tInfo(k)
				}
				Else {
					// JMD1020: don't change case of member key
					If ($$$UPPER(tInfo(k))="%SEARCH") {		// DTB087
						Set tInSearch=1
					}
					
					// DTB085 - save a spec that is executable MDX
					If (+$G(tMemberKey(k))) {
						If tInSearch {
							// DTB087 - A %Search spec uses nested [], and should not have these closing brackets escaped
							Set tRSpec = tRSpec _ $S((tRSpec="")||($E(tRSpec,$L(tRSpec))=":"):"",1:".") _ "&" _ $S(tQuoted(k):"["_tInfo(k)_"]",1:tInfo(k))
						}
						Else {
							Set tRSpec = tRSpec _ $S((tRSpec="")||($E(tRSpec,$L(tRSpec))=":"):"",1:".") _ "&" _ $S(tQuoted(k):"["_$$$dsEscapeIdent(tInfo(k))_"]",1:$$$dsEscapeIdent(tInfo(k)))
						}
					}
					Else {
	 					Set tRSpec = tRSpec _ $S((tRSpec="")||($E(tRSpec,$L(tRSpec))=":"):"",1:".") _ $S(tQuoted(k):"["_$$$dsEscapeIdent($$$UPPER(tInfo(k)))_"]",1:$$$dsEscapeIdent($$$UPPER(tInfo(k))))
					}
				}
				Set k = $O(tInfo(k))
			}
			If $$$ISERR(tSC) Quit
			
			If ('tResolved) {
				Set tSpec = tRSpec
			}
		} While ('tResolved)
		If $$$ISERR(tSC) Quit

		// remember these for later
		Kill ..%resolvedSpec
		Merge ..%resolvedSpec = tInfo
		Kill ..%resolvedQuoted
		Merge ..%resolvedQuoted = tQuoted
		Kill ..%memberKeys
		Merge ..%memberKeys = tMemberKey
		Set ..spec = tRSpec
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	If '$D(..%resolvedSpec)&&'$D(%dsQueryPrepare) {
		Set pSC = ..%ResolveValue()
	}
	Set tText = ..spec
	Quit tText
}

/// Return type of this node.
Method %GetType() As %String
{
	Set tMember = ..%GetMemberProvider()
	If ($IsObject(tMember)) {
		If (tMember.%IsA("%DeepSee.Query.memberMeasure")) {
			Quit $$$dstMeasure
		}
		ElseIf (tMember.%name="") {
			// note: dimension name by itself resolved to All Member!
			Quit $$$dstLevel
		}
	}
	Quit $$$dstMember
}

/// Return the member provider object associated with this node.
Method %GetMemberProvider() As %DeepSee.Query.member
{
	Quit ..%member
}

/// Execute the pre-processing logic for this node.
Method %PreProcess(pIsSlicer As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If '$D(..%resolvedSpec) {
			Set tSC = ..%ResolveValue()
			If $$$ISERR(tSC) Quit
		}

		If (..spec = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Empty member specification (possibly relationship with no dimension name)")
			Quit
		}

		Set tSpec = ..spec
		Merge tInfo = ..%resolvedSpec
		Merge tQuoted = ..%resolvedQuoted
		Merge tMemberKey = ..%memberKeys

		// Now resolve the member names against the cube
		Set tSC = ..%SpecToMember(.tInfo,.tQuoted,.tMemberKey,.tMember)
		If $$$ISERR(tSC) Quit

		If ('$IsObject(tMember)) {
			Set tSC = $$$ERROR($$$GeneralError,"No member provider object defined for memberSpec: "_tSpec)
			Quit
		}
		Set ..%member = tMember

		// Process any children this member may have
		Set tSC = ##super(pIsSlicer)
		Quit:$$$ISERR(tSC)
	}	
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute and build the axes output for this tuple.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pNewNodeNo = ""
		// Get members, add to axes tree
		If '$IsObject(..%member) {
			Set tSC = $$$ERROR($$$GeneralError,"No member object found for tuple: "_..spec)
			Quit	
		}
		Set tSC = ..%member.%ProcessMembers(pParent,.tSet)
		If $$$ISERR(tSC) Quit

		Set tIsRelationship = ..%member.%IsA("%DeepSee.Query.memberRelationship")

		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tChildCount = ..children.Count()
		
		Do:$G(%dstrace) ##class(%DeepSee.Utils).%WriteToLog("Trace",$$$dsCurrentMethod _ ":" _ tCubeIndex _ ":" _ $CLASSNAME() _ ":" _ ..%ToString())		// DTB TODO

		// DP-424589 - Relationship members which have the top node as the parent need to insert a set node
		If tIsRelationship&&($$$dsAxisNodeTypeGet($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent))="slicer") && ($O(tSet(""),-1)>1) {
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,,,+$G(%SetOpDepth(pKey)),$classname()_":"_$$$dsCurrentMethod)
			Set pParent = pNodeNo
		}

		// if defined, add members of tSet to the Axis
		Set n = $O(tSet(""))
		While (n '= "") {
			// tSet = $LB(type,visible,calc,parent,value,key,fact,agg,dim,hier,level)

			If ('pVisible) {
				Set $$$dsAxisNodeVisible(tSet(n)) = 0
			}

			// decorate node with dimension info
			If ('$$$IsDeepSeeNullAxisNode(tSet(n))) {		// DTB807 - Ignore nodes that are literal null
				Set $$$dsAxisNodeDim(tSet(n)) = ..%member.%dimNumber
				Set $$$dsAxisNodeHier(tSet(n)) = ..%member.%hierNumber
				Set $$$dsAxisNodeLevel(tSet(n)) = ..%member.%levelNumber
			}

			// the bottom-most member should always be calculated
			// upper members, should not be
			// (unless there are expressions involved: (A.A,B.B+100) )
			Set tCalc = 0
			If (tChildCount > 0) {
				Set $$$dsAxisNodeVisible(tSet(n)) = 0
				Set tCalc = $$$dsAxisNodeComputeGet(tSet(n))
			}
			Else {
				Set tType = $$$dsAxisNodeTypeGet(tSet(n))
				If ('pVisible) {
					// children of expressions need to be calculated
					// special case: treat IIF as an expression
					If ($IsObject(..parent)&&((..parent.%GetType() = $$$dstExpression) ||
						(..parent.%IsA("%DeepSee.Query.setFunction") && ($$$UPPER(..parent.function)="IIF")))) {
						Set tCalc = 1
						Set $$$dsAxisNodeVisible(tSet(n)) = 1
					}
				}
				Else {
					Set tCalc = 1
					Set $$$dsAxisNodeVisible(tSet(n)) = 1
				}
			}

			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tSet(n)
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
			If (pVisible || tCalc) {
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
			}
			Set:pNewNodeNo="" pNewNodeNo = pNodeNo

			// if this member has children, process them
			For k=1:1:tChildCount {
				Set tChild = ..children.GetAt(k)
				Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, pNodeNo, pVisible)
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit

			Set n = $O(tSet(n))
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Process the filter output for this tuple
Method %ProcessFilter(ByRef pFilterTree As %List, pCube As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pNewNodeNo = ""

		// get member info
		// !!! named parms
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..spec, .tInfo,.tQuoted,.tMemberKey)
		Quit:$$$ISERR(tSC)
		
		Set tSC = ..%SpecToMember(.tInfo,.tQuoted,.tMemberKey,.tMember)
		If $$$ISERR(tSC) Quit

		// Get members, add to filter tree
		If '$IsObject(tMember) {
			Set tSC = $$$ERROR($$$GeneralError,"No member object found for %Filter term: "_..spec)
			Quit	
		}

		// Get fact for dimension		
		Set tExists = tMember.%GetNodeInfo(pCube,tMember.%dimNumber,tMember.%hierNumber,tMember.%levelNumber, .tFact)
		If (tExists) {
			Set tType = $Case(tMember.%GetType(),"MX":"msr",:"mbr")
			Set pFilterTree($I(pNodeNo)) = $LB(tType,tFact,tMember.%dimNumber,tMember.%hierNumber,tMember.%levelNumber)
			Set pFilterTree(pParent,"ch",pNodeNo) = ""
			Set pFilterTree(pNodeNo,"mbr") = tMember	// hold onto member provider
		}

		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse the given member spec and create a member API object from it.<br/>
/// A member spec is of the form "A.B.C"; it is passed via the array <var>pSpec</var>:
/// pSpec(1)=A, etc.<br/>
/// The array <var>pQuoted</var> indicates whether a part of the spec is a quoted identifier (and thus cannot be a function).<br/>
/// The array <var>pMemberKey</var> indicates whether a part of the spec is member key (e.g., &2007).<br/>
/// On return <var>pMember</var> contains the member provider object that can be used to process the member.<br/>
/// We assume that if the spec contained a function it was already removed before this point.
Method %SpecToMember(ByRef pSpec, ByRef pQuoted, ByRef pMemberKey, Output pMember As %DeepSee.Query.member) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Try {
		Set pMember = ""
		Set (tDim,tHier,tLevel,tAllName) = ""
		Set (tDimNo,tHierNo,tLevelNo) = ""
		Set tCalculatedMember = 0
		Set tType = $$$dstUnknown
		Set tLevelNo = 1
		Set tIsMeasure = 0
		Set tState = 0
		Set tLastIter = ""
		Set tIter = $O(pSpec(""))
		Set:tIter'="" tOrigSpec = $G(pSpec(tIter)) // for error message
		Set tMemberClass = "%DeepSee.Query.memberData" 	// default
		While (tIter '= "") {
			Set tText = pSpec(tIter)
			Set tIsQuoted = +$G(pQuoted(tIter))
			Set tIsMemberKey = +$G(pMemberKey(tIter))

			//$$$DSWRITELN("S2M >> "_tState_":"_tText_"  t:"_tType)
			If (tState = 0) {
				// looking for a dimension
				Set tNode = $S(tIsMemberKey:"",1:$G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tText))))
				If (tNode '= "") {
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",$LG(tNode,1),$LG(tNode,2),$LG(tNode,3)))
					Set tDim = $LG(tInfo,2)
					Set tNodeType = $LG(tInfo,1)
					Set tDimNo = $LG(tNode,1)
					If (tNodeType = "d") {
						Set tType = $$$dstDimension
						Set tAllName = $LG(tInfo,4)
						If ($$$UPPER(tText) = "MEASURES") {
							Set tHierNo = 0
							Set tState = 5
							Set tMemberClass = "%DeepSee.Query.memberMeasure"
							Set pMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,tHierNo,tAllName)
							If $$$ISERR(tSC) Quit
						}
						Else {
							Set tState = 1
						}
					}
					ElseIf (tNodeType = "h") {
						Set tType = $$$dstHierarchy
						Set tState = 1
						Set tHier = $LG(tInfo,3)
						Set tHierNo = $LG(tNode,2)
						Set tInfoD = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",$LG(tNode,1),0,0))
						Set tAllName = $LG(tInfoD,4)
						Set tMbrClass = $LG(tInfo,6)
						Set:tMbrClass'="" tMemberClass = tMbrClass
					}
					ElseIf ((tNodeType = "l")||(tNodeType = "all")) {
						// level
						Set tType = $$$dstLevel
						Set:(tNodeType = "all") tType = $$$dstMember
						Set tState = 1
						Set tHier = $LG(tInfo,3)
						Set tHierNo = $LG(tNode,2)
						Set tLevel = $LG(tInfo,4)
						Set tLevelNo = $LG(tNode,3)
						Set tInfoD = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",$LG(tNode,1),0,0))
						Set tAllName = $LG(tInfoD,4)
						// Pull member class from hierarchy node
						Set tInfoH = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",$LG(tNode,1),$LG(tNode,2),0))
						Set tMbrClass = $LG(tInfoH,6)
						Set:tMbrClass'="" tMemberClass = tMbrClass
					}
					ElseIf (tNodeType = "r") { // relationship
						Set tType = $$$dstDimension
						Set tAllName = $LG(tInfo,4)
						Set tHierNo = 0
						Set tMemberClass = "%DeepSee.Query.memberRelationship"
						Set pMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,tHierNo,tAllName)
						If $$$ISERR(tSC) Quit

						// spec, related cube, cardinality, inverse, isStored
						Set tSC = pMember.%ApplyRelationInfo(.pSpec, $LG(tInfo,6),$LG(tInfo,7),$LG(tInfo,8),$LG(tInfo,9),.pMemberKey)
						If $$$ISERR(tSC) Quit

						Set tSC = pMember.%ApplyState(tType)
						Set %query.%hasRelations = 1		// DTB086 - mark that the query contains relationships
						Quit // done
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,"Internal Error: Unknown node type encountered: " _ tNodeType)
						Quit
					}
				}
				Else {
					// check for calculated member
					Kill tCMemberList
					Set tSC = %query.%GetCalculatedMembers(tText,.tCMemberList)
					If $$$ISERR(tSC) Quit

					If $D(tCMemberList) {
						Set tCalculatedMember = 1

						Set tDim = tText
						Set tDimNo = -1		// fake dimension number
						Set tHierNo = 0
						Set tHier = "Calculated"	// anything other than ""
						Set tType = $$$dstDimension
						Set tAllName = ""
						Set tState = 2

						Set tMemberClass = "%DeepSee.Query.memberCalculated"
						Set pMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,tHierNo,tAllName)
						If $$$ISERR(tSC) Quit
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,"Dimension "_tText_" not found in cube " _ $G(%cube))
						Quit
					}
				}
			}
			ElseIf (tState = 1) {
				// test for hierarchy name
				// + WAL050 -- check to see if this is the all member
				Set tNode = $S(tIsMemberKey&&(tText'=tAllName):"",1:$G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),$$$UPPER(tText))))
				// - WAL050
				If (tNode '= "") {
					// Test for hierarchy name
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",$LG(tNode,1),$LG(tNode,2),$LG(tNode,3)))
					Set tNodeType = $LG(tInfo,1)
					If (tNodeType = "h") {
						Set tType = $$$dstHierarchy
						Set tState = 2
						Set tHier = $LG(tInfo,3)
						Set tHierNo = $LG(tNode,2)
						Set tMbrClass = $LG(tInfo,6)
						Set:tMbrClass'="" tMemberClass = tMbrClass
					}
					ElseIf ((tNodeType = "l")||(tNodeType = "all")) {
						Set tType = $$$dstHierarchy
						Set:(tNodeType = "all") tType = $$$dstMember
						Set tState = 2
						Set tHier = $LG(tInfo,3)
						Set tHierNo = $LG(tNode,2)
						Set tLevel = $LG(tInfo,4)
						Set tLevelNo = $LG(tNode,3)
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,"Internal Error: Unexpected node type: " _ tText _ ":" _ tNodeType)
						Quit
					}
				}
				Else {
					// try again as a level
					Set tState = 2
					Set tIter = tLastIter
				}
			}
			ElseIf (tState = 2) {
				// test for level name
 				// if we don't have a hierarchy, see if we can find one
				If (tHier = "") {
					Set tHier = $O($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),""))
					While (tHier '= "") {
						If (tHier '= "ATTRIBUTES") {
							Set tNode = $S(tIsMemberKey:"",1:$G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),$$$UPPER(tHier),$$$UPPER(tText))))
							If (tNode '= "") {
								Set tType = $$$dstLevel
								Set tHierNo = $LG(tNode,2)
								Quit
							}
						}
						Set tHier = $O($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),tHier))
					}
					If ((tHier = "")||(tNode = "")) {
						// try again, looking for a member name
						Set tState = 3
						Set tIter = tLastIter
					}
				}
				Else {
					Set tNode = $S(tIsMemberKey:"",1:$G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),$$$UPPER(tHier),$$$UPPER(tText))))
				}
				If (tHier '= "") {
					// create member class using hierarchy info
					// create member API object
					If '$IsObject(pMember) {
						Set tInfoD = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,0,0))
						Set tAllName = $LG(tInfoD,4)
						// get member provider from first hierarchy
						Set tInfoH = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,1,0))
						Set tMbrClass = $LG(tInfoH,6)
						Set:tMbrClass'="" tMemberClass = tMbrClass
						Set pMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,tHierNo,tAllName)
						If $$$ISERR(tSC) Quit
					}

					If (tNode '= "") {
						Set tType = $$$dstLevel
						// found a level name: adjust to this level
						Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",$LG(tNode,1),$LG(tNode,2),$LG(tNode,3)))
						Set tNodeType = $LG(tInfo,1)
						If ((tNodeType = "l")||(tNodeType = "all")) {
							Set:(tNodeType = "all") tType = $$$dstMember
							Set tLevel = $LG(tInfo,4)
							Set tLevelNo = $LG(tNode,3)
							Do pMember.%SetLevelNo(tLevelNo)
						}
						Else {
							Set tSC = $$$ERROR($$$GeneralError,"Unexpected member type (2): " _ tText)
							Quit
						}
					}
					Else {
						// try again, looking for a member name
						Set tState = 3
						Set tIter = tLastIter
					}
				}
			}
			ElseIf (tState = 3) {
				// gather member names/keys
				Set tIsMember = 0
				// if we don't have a hierarchy, check each one
				If (tHier = "") {
					Set tInfoD = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,0,0))
					Set tAllName = $LG(tInfoD,4)

					// get member provider from first hierarchy
					Set tInfoH = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,1,0))
					Set tMbrClass = $LG(tInfoH,6)
					Set:tMbrClass'="" tMemberClass = tMbrClass
					Set tHier = $O($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),""))
					While (tHier '= "") {
						If (tHier '= "ATTRIBUTES") {
							Set tNode = $S(tIsMemberKey:"",1:$G($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),$$$UPPER(tHier))))
							If (tNode '= "") {
								Set h = $LG(tNode,2)
								// create member API object
								Set tMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,h,tAllName)
								If $$$ISERR(tSC) Quit

								If (tIsMemberKey) {
									Set tSC = tMember.%FindMemberByKey(tText,tDimNo,h,.tIsMember)
									If $$$ISERR(tSC) Quit
								}
								Else {
									Set tSC = tMember.%FindMemberByName(tText,tDimNo,h,.tIsMember)
									If $$$ISERR(tSC) Quit
								}
								If (tIsMember) {
									// found a member
									Set tHierNo = h
									Set pMember = tMember
									Quit
								}
							}
						}
						Set tHier = $O($$$DeepSeeMetaGLVN("cubes",%cube,"mbrs",$$$UPPER(tDim),tHier))
					}
				}
				Else {
					// JMD1393 if we know what level we are on, limit search to that level
					Set tSearchLevelNo = ""
					If (tType=$$$dstLevel) {
						Set tSearchLevelNo = tLevelNo
					}
					If (tIsMemberKey) {
						Set tSC = pMember.%FindMemberByKey(tText,tDimNo,tHierNo,.tIsMember,,(tSearchLevelNo=""))
						If $$$ISERR(tSC) Quit
					}
					Else {
						Set tSC = pMember.%FindMemberByName(tText,tDimNo,tHierNo,.tIsMember,tSearchLevelNo)
						If $$$ISERR(tSC) Quit
					}
				}

				If (tIsMember) {
					Set tType = $$$dstMember
					// test for member at next level
					Set tLevelNo = tLevelNo + 1
				}
				Else {
					// no member found: make up a dummy
					If (tHierNo="") {
						Set tSC = $$$ERROR($$$GeneralError,"Cube member not found: " _ tText)
						Quit
					}

					// JMD1119 if we *know* what level does not have the member, use it
					If (tLevel'="") {
						Set pMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,tHierNo,$G(tAllName))
						If $$$ISERR(tSC) Quit

						Set tType = $$$dstMember
						Set pMember.%memberSpec(tLevelNo) = $LB($$$Text("No Member","%DeepSee"),"NO MEMBER","NO MEMBER")
					}
					Else {
						// otherwise, find lowest level
						Set tLowLevel = $O($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,tHierNo,""),-1)
						If (tLowLevel '= "") {
							Set pMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,tHierNo,$G(tAllName))
							If $$$ISERR(tSC) Quit

							Set tType = $$$dstMember
							Set pMember.%memberSpec(tLowLevel) = $LB($$$Text("No Member","%DeepSee"),"NO MEMBER","NO MEMBER")
						}
						Else {
							Set tSC = $$$ERROR($$$GeneralError,"Cube member not found: " _ tText)
							Quit
						}
					}
				}
			}
			ElseIf (tState = 5) { // [Measures].
				// get measure name
				// See if this is a member name
				Set tSC = pMember.%FindMemberByName(tText,tDimNo,tHierNo,.tIsMeasure)
				If $$$ISERR(tSC) Quit

				If (tIsMeasure) {
					Set tType = $$$dstMeasure
					Set tState = 6
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Measure not found: " _ %cube _ ":" _ tText)
					Quit
				}
			}
			ElseIf (tState = 6) { // [Measures].[M].
				Set tSC = $$$ERROR($$$GeneralError,"Identifier following measure name: " _ ..%member.%name _ "." _ tText)
				Quit
			}
			Set tLastIter = tIter
			Set tIter = $O(pSpec(tIter))
		}
		If $$$ISERR(tSC) Quit

		If (tDimNo = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No dimension specified: " _ $G(tOrigSpec))
			Quit
		}
		If (tHierNo = "") {
			// Use the "all" level for this dimension, if present
			Set tHierNo = 1
			// pickup member class from 1st hierarchy
			Set tInfoH = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",tDimNo,tHierNo,0))
			Set tMbrClass = $LG(tInfoH,6)
			Set:tMbrClass'="" tMemberClass = tMbrClass
		}
		If '$IsObject(pMember) {
			// create a member: if none
			Set pMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,%cube,$this,tDimNo,tHierNo,tAllName)
			If $$$ISERR(tSC) Quit
		}

		Set tSC = pMember.%ApplyState(tType)
		If $$$ISERR(tSC) Quit

		// if all level, set up member spec
		If ((pMember.%levelNumber=1)&&(tAllName'="")) {
			Set pMember.%memberSpec(1) = $LB(tAllName,"","")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Given a member spec, create a memberSpec object that can be used to access
/// members. 
ClassMethod %ConstructMemberSpec(pSpec As %String, Output pMemberSpec As %DeepSee.Query.memberSpec) As %Status [ Internal ]
{
	Set pMemberSpec = ""
	Set tSC = $$$OK
	Try {
		Set pMemberSpec = ..%New()
		Set pMemberSpec.spec = pSpec

		// get member info
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pMemberSpec.spec, .tInfo,.tQuoted,.tMemberKey)
		Quit:$$$ISERR(tSC)

		Set tSC = pMemberSpec.%SpecToMember(.tInfo,.tQuoted,.tMemberKey,.tMember)
		If $$$ISERR(tSC) Quit

		If ('$IsObject(tMember)) {
			Set tSC = $$$ERROR($$$GeneralError,"No member provider object defined for memberSpec: "_pMemberSpec.spec)
			Quit
		}
		Set pMemberSpec.%member = tMember
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Retrieve the display names for the level and member of a memberSpec object.
/// This is used for converting a logical node in a query object to values suitable for use in the 
/// user interface.
Method %GetMemberDisplayValues(pCubeName As %String = "", Output pLevelName = "", Output pMemberName = "") As %Status [ Internal ]
{
	// Method added by DTB115
	Set tSC = $$$OK
	Try {
		If pCubeName="" {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name must be supplied in %GetMemberDisplayValues")
			Quit 
		}
		
		If '$D(..%resolvedSpec) {
			Set tSC = ..%ResolveValue()
		}
		If $$$ISERR(tSC) Quit

		If ##class(%DeepSee.Utils).%IsRelationship(pCubeName,..%resolvedSpec(1)) {
			// +DTB195 - Recurse to get at the display values at the end of the relationship chain
			Set tRelCube = ##class(%DeepSee.Utils).%GetRelatedCube(pCubeName,..%resolvedSpec(1))
			Set tNewText = ""
			Set tSpecIdx = $O(..%resolvedSpec(1),1,tSpecElement)
			While tSpecIdx'="" {
				Set tNewText = tNewText _ $S($L(tNewText):".",1:"") _ $S($G(..%memberKeys(tSpecIdx),0):"&",1:"") _ "[" _ $$$dsEscapeIdent(tSpecElement) _ "]"
				Set tSpecIdx = $O(..%resolvedSpec(tSpecIdx),1,tSpecElement)
			}
			
			// Build a new MDX expression to parse for the new member spec
			// N.B. - Using ..%ConstructMemberSpec() here causes trouble due to possible lack of environment variables!
			Set tMDX = "SELECT " _ tNewText _ " ON 0 FROM [" _ $$$dsEscapeIdent(tRelCube) _ "]"		// DTB195 - Quote the cube name to protect it in the parsing
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMDX(tMDX,.tQuery)
			If $$$ISERR(tSC) Quit
			
			Set tNewSpec = tQuery.axes.GetAt(1).children.GetAt(1)
			
			Set tSC = tNewSpec.%GetMemberDisplayValues(tRelCube,.pLevelName,.pMemberName)
			If $$$ISERR(tSC) Quit
		}
		Else {
			// Retrieve the caption for the current level
			Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(pCubeName,..%resolvedSpec(1),..%resolvedSpec(2),..%resolvedSpec(3),.pLevelName)
			If $$$ISERR(tSC) Quit

			// Convert the member key to the member name
			Set tLevelSpec = "[" _ $$$dsEscapeIdent(..%resolvedSpec(1)) _ "].[" _ $$$dsEscapeIdent(..%resolvedSpec(2))  _ "].[" _ $$$dsEscapeIdent(..%resolvedSpec(3)) _ "]"
			Set tSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(pCubeName,tLevelSpec,..%resolvedSpec(4),.pMemberName)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test this node to make sure all data referenced by the spec is enabled in this cube.
Method %IsEnabled(pCube As %String = "", Output pStatus As %Status = {$$$OK}, Output pReason As %String = "") As %Boolean
{
	// Method added by DTB908
	Set tReturn = 0
	
	Try {
		Set tReturn = ##class(%DeepSee.Utils).%IsFactEnabled(pCube,..spec,.pStatus,,.tInProgress)
		
		If 'tReturn {
			// DTB913 - Return the current spec as the failure reason
			Set pReason = $LB(pCube,..spec,$G(tInProgress,0))
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

}
