/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a member function within a DeepSee query.<br/>
/// A "member" function is a function that is syntactically part of a member:
/// member.FUNC or member.FUNC(a)<br/>
/// These are sometimes referred to as operators within MDX.
Class %DeepSee.Query.memberFunction Extends function [ System = 3 ]
{

/// Used to indicate which class of functions this class supports.
Parameter FUNCTIONCLASS = "mbr";

/// Member object that provides the member API for the member
/// returned by this function, if any.
/// This is created during the axis-processing phase.
Property %member As %DeepSee.Query.member(XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this contains additional functions to apply to the current
/// member once it is resolved.
Property %cmbrQualifier As %String(MAXLEN = 1000, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this contains any MDX that wraps the current member.
Property %cmbrWrapper As %String(MAXLEN = 1000, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this is used to output a marker value for this node
/// when %ToString is called.
Property %cmbrMarker As %String(MAXLEN = 50, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this is the function used to aggregate children of the 
/// currentMember reference, if any.
Property %cmbrAgg As %String(MAXLEN = 50, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this is the name of the measure used to aggregate children of the 
/// currentMember reference, if any.
Property %cmbrMeasure As %String(MAXLEN = 255, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this a literal value to apply to children of the currentMember
/// reference, if any.
Property %cmbrLiteral As %String(MAXLEN = 2000, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this is the label used for the current member.
Property %cmbrLabel As %String(MAXLEN = 250, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this is the format used for the current member.
Property %cmbrFormat As %String(MAXLEN = 250, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this is the relationship part of the member spec, if applicable.
/// E.g., "[Doctors]".
Property %cmbrRelSpec As %String(MAXLEN = 2000, XMLPROJECTION = "none") [ Internal ];

/// For CurrentMember functions, this is the original request string for use in generating keys.
Property %cmbrKeyText As %String(XMLPROJECTION = "none") [ Internal ];

/// Return the member provider object associated with this node.
Method %GetMemberProvider() As %DeepSee.Query.member
{
	Quit ..%member
}

/// Test if function metadata is in the DeepSeeFunctionGLVN global.
/// If not, put it there.
ClassMethod %BuildFunctionMetaData() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tClass = ..#FUNCTIONCLASS
		Set tVersion = ..%GetFunctionVersionNo()

		If (+$G($$$DeepSeeFunctionGLVN(tClass))'=tVersion) {
			Kill $$$DeepSeeFunctionGLVN(tClass)
			Set $$$DeepSeeFunctionGLVN(tClass) = tVersion

			// (class,function[,memberType]) = $LB(implemented,return,$LB(argtypes),$LB(argdesc))
			// in this case, first arg is type of "member" this function operates on:
			// e.g. MEMBER.FUNC(a1,a2) -->  $LB(mbrtype,a1type,a2type)

			// argtype is $$$dstSet etc.
			// argdesc describes the argument:
			// 0: optional, 1: required, N:repeating, 
			// M: first argument is the member the function applies to
			// possible flag values are encoded in the argdesc: 1:F1,F2,F3

			// return the all level and members of first level
			// this is used by the Analyzer
			Set $$$DeepSeeFunctionGLVN(tClass,"%TOPMEMBERS") = $LB(1,$$$dstSet,$LB($$$dstDimension),$LB("M"))

			Set $$$DeepSeeFunctionGLVN(tClass,"MEMBERS") = $LB(1,$$$dstSet,$LB($$$dstDimension),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"DEFAULTMEMBER") = $LB(0,$$$dstMember,$LB($$$dstDimension),$LB("M"))

			Set $$$DeepSeeFunctionGLVN(tClass,"ALLMEMBERS") = $LB(1,$$$dstSet,$LB($$$dstDimension),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"CHILDREN") = $LB(1,$$$dstSet,$LB($$$dstMember),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"SIBLINGS") = $LB(1,$$$dstSet,$LB($$$dstMember),$LB("M"))

			// return children OR if this is the bottom level, return the invoking member
			Set $$$DeepSeeFunctionGLVN(tClass,"%CHILDRENORSELF") = $LB(1,$$$dstSet,$LB($$$dstMember),$LB("M"))

			Set $$$DeepSeeFunctionGLVN(tClass,"PARENT") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))

			// %ALLMEMBER (disabled)
			Set $$$DeepSeeFunctionGLVN(tClass,"%ALLMEMBER") = $LB(0,$$$dstMember,$LB($$$dstMember),$LB("M"))

			// %ALL
			Set $$$DeepSeeFunctionGLVN(tClass,"%ALL") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))

			// %NOT
			Set $$$DeepSeeFunctionGLVN(tClass,"%NOT") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))

			Set $$$DeepSeeFunctionGLVN(tClass,"CURRENTMEMBER") = $LB(1,$$$dstMember,$LB($$$dstDimension),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"PREVMEMBER") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"NEXTMEMBER") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"LAG") = $LB(1,$$$dstMember,$LB($$$dstMember,$$$dstInteger),$LB("M",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"LEAD") = $LB(1,$$$dstMember,$LB($$$dstMember,$$$dstInteger),$LB("M",0))
			Set $$$DeepSeeFunctionGLVN(tClass,"FIRSTSIBLING") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"LASTSIBLING") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))

			Set $$$DeepSeeFunctionGLVN(tClass,"FIRSTCHILD") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"LASTCHILD") = $LB(1,$$$dstMember,$LB($$$dstMember),$LB("M"))

			Set $$$DeepSeeFunctionGLVN(tClass,"PROPERTIES") = $LB(1,$$$dstString,$LB($$$dstMember,$$$dstString,$$$dstString),$LB("M",1,0))

			// functions to change default aggregate for measures
			Set $$$DeepSeeFunctionGLVN(tClass,"COUNT") = $LB(1,$$$dstMeasure,$LB($$$dstMeasure),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"SUM") = $LB(1,$$$dstMeasure,$LB($$$dstMeasure),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"MIN") = $LB(1,$$$dstMeasure,$LB($$$dstMeasure),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"MAX") = $LB(1,$$$dstMeasure,$LB($$$dstMeasure),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"AVG") = $LB(1,$$$dstMeasure,$LB($$$dstMeasure),$LB("M"))
			Set $$$DeepSeeFunctionGLVN(tClass,"NULL") = $LB(1,$$$dstMeasure,$LB($$$dstMeasure),$LB("M"))

			// internal functions
			Set $$$DeepSeeFunctionGLVN(tClass,"%RANK") = $LB(1,$$$dstValue,$LB($$$dstMember,$$$dstInteger),$LB("M",1))
		}
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
	If (..%cmbrWrapper'="") {
		// this is a current member
		Set tText = ..%cmbrWrapper

		// include more info when making a query key
		If (+$G(%dsMakeKey)) {
			// While making the key, do not use replaced internal index references, use the saved
			// original text instead.
			Set tText = $S(..%cmbrKeyText'="":..%cmbrKeyText,1:..%cmbrWrapper)
			Set tDetails = ..%cmbrAgg _ "("_ ..%cmbrMeasure _ $S(..%cmbrLiteral'="":",",1:"") _ ..%cmbrLiteral _")"		// DP-402439 - This is for cache entry readability
			Set:tDetails'="()" tText = tText _ "/**" _ tDetails _ "**/"
		}
		Quit tText
	}

	Set tFunction = $$$UPPER(..function)
	If (..%cmbrMarker'="") {
		// Current member with marker only
		Set tText = ..%cmbrMarker
	}
	Else {
		Set tFirstChild = ..children.GetAt(1)
		Set tText = tFirstChild.%ToString() _ "." _ tFunction
		Set tChildCount = ..children.Count()
		If (tChildCount > 1) {
			Set tText = tText _ "("
			For n=2:1:tChildCount {
				Set tText = tText _ $S(n>2:",",1:"") _ ..children.GetAt(n).%ToString(.pSC)
				If $$$ISERR(pSC) Quit
			}
			Set tText = tText _ ")"
		}
	}

	If ((tFunction = "CURRENTMEMBER")&&(..%cmbrQualifier'="")) {
		Set tText = tText _ "." _ $$$UPPER(..%cmbrQualifier)
	}

	Quit tText
}

/// Execute the pre-processing logic for this node.
Method %PreProcess(pIsSlicer As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		// process our children
		Set tSC = ##super(pIsSlicer)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute and build the axes output for this axis.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pNewNodeNo = pParent
		Set tMemberNode = ""
		Set tFunction = $$$UPPER(..function)
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tExists = ..%GetFunctionInfo(tFunction,.tIsImplemented,.tArgCount,.tReturns,.tArgs,.tArgDesc)
		If ('tExists) {
			Set tSC = $$$ERROR($$$GeneralError,"Function does not exist: "_tFunction)
			Quit
		}
		If ('tIsImplemented) {
			Set tSC = $$$ERROR($$$GeneralError,"Function is not implemented: "_tFunction)
			Quit
		}

		// test for nested functions: member.func.func
		Set tChild = ..children.GetAt(1)
		Set tMember = ""

		If ($IsObject(tChild) && tChild.%IsA("%DeepSee.Query.memberFunction")) {
			// process child function first
			Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo, .tNewNodeNo, pParent)
			If $$$ISERR(tSC) Quit

			// get member provider for child
			Set tMember = tChild.%GetMemberProvider()

			If ('$IsObject(tMember)) {
				// Nested function can only be applied to functions returning members
				// this means that nextmember.func will fail if nextmember fails.
				Set tSC = $$$ERROR($$$GeneralError,"Member function must be applied to a member or function returning a member: " _ tFunction)
				Quit
			}
			// delete member node
			Set tSC = ..%DeleteNode(tCubeIndex,pKey,%axis,tNewNodeNo)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tFunction'="CURRENTMEMBER") {
			// Get member provider
			// MemberSpec is the first child of this node
			Set tMemberSpec = tChild
			If ('$IsObject(tMemberSpec)) {
				// should never happen!
				Set tSC = $$$ERROR($$$GeneralError,"No memberSpec object found for member function: " _ tFunction)
				Quit
			}
			// Now get memberProvider from memberSpec
			// (could be a spec or a namedSet or calculatedMember!)
			Set tMember = tMemberSpec.%GetMemberProvider()
			If ('$IsObject(tMember)) {
				// should never happen!
				Set tSC = $$$ERROR($$$GeneralError,"No member provider object found for member function: " _ tFunction)
				Quit
			}
			// Test if this provider supports *this* function
			If ('tMember.%SupportsFunction(tFunction,.tMsg)) {
				Set tSC = $$$ERROR($$$GeneralError,tMsg)
				Quit
			}
		}

		Set tParent = pParent
		If (tReturns = $$$dstSet) {
			// add set node to axis tree
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,pParent,,$G(%SetOpDepth(pKey)),$classname()_":"_$$$dsCurrentMethod)		// DP-424589 - Include SetOpDepth
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
			Set pNewNodeNo = pNodeNo
			Set tParent = pNodeNo
		}

		If ($IsObject(tMember)) {
			// Member type must match first argument type
			Set tMbrType = tMember.%GetType()

			// treat various dim types as dimension
			Set tMbrType = $Case(tMbrType,$$$dstHierarchy:"D",$$$dstLevel:"D",:tMbrType)
			Set tArgType = $LG(tArgs,1)

			If (tMbrType '= tArgType) {
				Set tSC = $$$ERROR($$$GeneralError,"Function used in wrong context: " _ ..%ToString() _ " -- Expected: "_ ..%TypeFlagToString(tArgType) _ ", Got: " _ ..%TypeFlagToString(tMbrType))
				Quit
			}

			// Get additional arguments for function; check types
			For n=2:1:..children.Count() {
				Set tFuncArgs(n-1) = ..children.GetAt(n)
				Set tArgType = $LG(tArgs,n)
				Set tFuncArgType = tFuncArgs(n-1).%GetType()
				If ((tArgType'="")&&(tFuncArgType'=tArgType)) {
					Set tSC = $$$ERROR($$$GeneralError,"Wrong type of argument supplied to function: " _ ..function _ "(" _ tFuncArgs(n-1).%ToString() _ ")   Expected: "_ ..%TypeFlagToString(tArgType) _ ", Got: " _ ..%TypeFlagToString(tFuncArgType))
					Quit
				}
			}
			If $$$ISERR(tSC) Quit
		}

		// dispatch to appropriate method
		Set tFunction = $$$UPPER(..function)
		Set tSC = $Case(tFunction,
			"CURRENTMEMBER":..FXCurrentMember(pCube,tParent,.tSet),
			"ALLMEMBERS":..FXMembers(pCube,pKey,.pNodeNo,tParent,tMember,1),
			"MEMBERS":..FXMembers(pCube,pKey,.pNodeNo,tParent,tMember),
			"%TOPMEMBERS":..FXMembers(pCube,pKey,.pNodeNo,tParent,tMember,0,1),
			"NEXTMEMBER":..FXNextMember(pCube,tParent,tMember,.tSet),
			"PREVMEMBER":..FXPrevMember(pCube,tParent,tMember,.tSet),
			"FIRSTSIBLING":..FXFirstSibling(pCube,tParent,tMember,.tSet),
			"LASTSIBLING":..FXLastSibling(pCube,tParent,tMember,.tSet),
			"CHILDREN":..FXChildren(pCube,pKey,.pNodeNo,tParent,tMember),
			"SIBLINGS":..FXSiblings(pCube,pKey,.pNodeNo,tParent,tMember),
			"%CHILDRENORSELF":..FXChildren(pCube,pKey,.pNodeNo,tParent,tMember,1),
			"FIRSTCHILD":..FXFirstChild(pCube,tParent,tMember,.tSet),
			"LASTCHILD":..FXLastChild(pCube,tParent,tMember,.tSet),
			"LEAD":..FXLead(pCube,tParent,tMember,.tSet,.tFuncArgs),
			"LAG":..FXLag(pCube,tParent,tMember,.tSet,.tFuncArgs),
			"PARENT":..FXParent(pCube,tParent,tMember,.tSet),
			"%ALLMEMBER":..FXAllMember(pCube,tParent,tMember,.tSet),
			"%ALL":..FXAll(pCube,tParent,tMember,.tSet),
			"%NOT":..FXNot(pCube,tParent,tMember,.tSet),
			"PROPERTIES":..FXProperties(pCube,tParent,tMember,.tSet,.tFuncArgs),
			"COUNT":..FXChangeAggregate(pCube,tParent,tMember,.tSet,"COUNT"),
			"SUM":..FXChangeAggregate(pCube,tParent,tMember,.tSet,"SUM"),
			"MIN":..FXChangeAggregate(pCube,tParent,tMember,.tSet,"MIN"),
			"MAX":..FXChangeAggregate(pCube,tParent,tMember,.tSet,"MAX"),
			"AVG":..FXChangeAggregate(pCube,tParent,tMember,.tSet,"AVG"),
			"NULL":..FXChangeAggregate(pCube,tParent,tMember,.tSet,"NULL"),
			"%RANK":..FXRank(pCube,tParent,tMember,.tSet,.tFuncArgs),
			:$$$ERROR($$$GeneralError,"memberFunction: Unknown MEMBER function: " _ ..function))
		If $$$ISERR(tSC) Quit

		// n.b.,
		// we use a local variable to hold the members; this imposes
		// a limit on the number of members (most likely about 50-100K) within a dimension. Future plans
		// to automatically promote local variables to private globals will remove
		// this limit.
		// Actually, we gave on waiting for this and use a global for functions that
		// return large sets

		// if defined, add members of tSet to the Axis
		Set tCmbrNodeNo = pNodeNo

		// JMD1510.2 return *something* to prevent other problems
		// (only for functions that we expect to set tSet)
		If ((tFunction="FIRSTCHILD")||(tFunction="LASTCHILD")||
			(tFunction="FIRSTSIBLING")||(tFunction="LASTSIBLING")||
			(tFunction="NEXTMEMBER")||(tFunction="PREVMEMBER")||
			(tFunction="LEAD")||(tFunction="LAG")
			) {
			If '$D(tSet) {
				Set tSet($I(tSet)) = $lb("lit",1,1,1,"","")
				Set tReturns = $$$dstString
			}
		}

		Set n = $O(tSet(""))
		While (n '= "") {
			// tSet = $LB(type,visible,calc,parent,value,key,fact,agg)
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tSet(n)
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tParent,"ch",pNodeNo) = ""

			// is this a cmbr?
			If ($LG(tSet(n),1)="cmbr") {
				Set tCmbrNodeNo = pNodeNo
				Set tIsCmbr = 1
			}
			// only add to all if visible !!!
			If (+$LG(tSet(n),2)) {
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
			}
			If (tMemberNode="") {
				Set tMemberNode = pNodeNo
			}

			If (tParent = pParent) {
				Set pNewNodeNo = pNodeNo
			}

			// n.b, there should be no child nodes to process
			Set n = $O(tSet(n))
		}
		If $$$ISERR(tSC) Quit

		
		If (tFunction="CURRENTMEMBER") {
			// For currentMember we note that this axis contains a cmbr
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"cmbr",tCmbrNodeNo) = ""
		}

		Set ..%member = ""
		If ((tFunction'="CURRENTMEMBER")&& (tReturns = $$$dstMember) && (tMemberNode'="")) {
			// create a member provider in case anyone wants 
			// to access the member we are returning
			Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tMemberNode))
			Set tNodeType = $LG(tNodeInfo,1)
			Set tNodeValue = $LG(tNodeInfo,5)
			Set tNodeId = $LG(tNodeInfo,6)
			Set tNodeKey = $LG(tNodeInfo,13)
			Set tDimNo = +$LG(tNodeInfo,9)
			Set tHierNo = +$LG(tNodeInfo,10)
			Set tLevelNo = +$LG(tNodeInfo,11)

			If ((tNodeType '= "mbr")&&(tNodeType '= "cmbr")) {
				Set tSC = $$$ERROR($$$GeneralError,"Internal error within memberFunction: " _ tFunction)
				Quit
			}

			Set tHierInfo = $G($$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",tDimNo,tHierNo,0))
			Set tHMbrType = $LG(tHierInfo,1)
			If (tHMbrType = "r") {
				// this is a relationship:
				// we must be a currentMember on a related cube
				Set tMemberClass = "%DeepSee.Query.memberRelationship"
			}
			Else {
				Set tMbrClass = $LG(tHierInfo,6)
				Set tMemberClass = $S(tMbrClass="":"%DeepSee.Query.memberData",1:tMbrClass)
			}

			Set tReturnMember = ##class(%DeepSee.Query.member).%CreateMember(tMemberClass,.tSC,pCube,$this,tDimNo,tHierNo)
			If $$$ISERR(tSC) Quit

			// Make sure memberSpec within memberProvider is accurate
			Merge tReturnMember.%memberSpec = tMember.%memberSpec
			Set tReturnMember.%memberSpec(tLevelNo) = $LB(tNodeValue,tNodeId,tNodeKey)

			Set tSC = tReturnMember.%ApplyState($$$dstMember)
			If $$$ISERR(tSC) Quit

			Do tReturnMember.%SetLevelNo(tLevelNo)
			Set ..%member = tReturnMember
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Execute the CurrentMember function on the given member and place results into <var>pSet</var>.<br/>
Method FXCurrentMember(pCube As %String, pParent As %Integer, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// note: A call to currentMember should include dimension AND hierarchy for best results

		// determine if this node is visible
		Set tVisible = 1

		// JMD909 - pick up format
		Set tFormat = ..%cmbrFormat

		Set tRelSpec = ..%cmbrRelSpec

		// this was set by query.%RewriteForCurrentMember
		Set:..%cmbrAgg="" ..%cmbrAgg = "SUM"

		// turn off marker
		Set ..%cmbrMarker = ""

		Set tLiteral = ..%cmbrLiteral

		// special case
		If ($$$UPPER(..%cmbrAgg)="PERCENTILE") {
			Set tOpFlag = "PERCENTILE"
			Set tOpFlagValue = tLiteral
			Set:tOpFlagValue="" tOpFlagValue=50
			Set tLiteral = ""
		}
		ElseIf ($$$UPPER(..%cmbrAgg)="PERCENTILERANK") {
			Set tOpFlag = "VALUE"
			Set tOpFlagValue = tLiteral
			Set tLiteral = ""
		}


		// wrapper,measure, and qualifier, and relspec are passed along for later processing
		// %ProcessOneCurrentMember will look at this node and copy its info to the cmbrMap
		Set tMeasure = ""
		Set tMeasureName = ..%cmbrMeasure
		If (tMeasureName'="") {
			Set tCubeIndex = $$$DeepSeeIndex(pCube)
			Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbrs","MEASURES",$$$UPPER(tMeasureName)))
			Set tMsrNo = +$LG(tInfo,2)
			If (tMsrNo>0) {
				Set tMsrInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",0,tMsrNo,0))
				Set tMeasure = $LG(tMsrInfo,5)	// "M1" etc.
				Set tMsrScale = +$LG(tMsrInfo,9) 	// slot 19
				Set tMsrType = $LG(tMsrInfo,8)		// slot 20
				Set tMsrAgg = $LG(tMsrInfo,7,"SUM")	
			}
		}
		
		Set pSet($I(pSet)) = $LB("cmbr",tVisible,1,pParent,..%cmbrLabel,..%cmbrQualifier,tOpFlag,tOpFlagValue,-100,-1,-1,tFormat,,,tMeasure,..%cmbrAgg,..%cmbrWrapper,tRelSpec,$G(tMsrScale),$G(tMsrType),$G(tLiteral))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Execute the Members function on the given member and place results into the axis global.<br/>
/// This will return all members of the current node.<br/>
/// The work of getting the members is delegated to the member object <var>pMember</var>.
/// If <var>pIncludeCalc</var> is true, return calculated members as well.
Method FXMembers(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pMember As %DeepSee.Query.member, pIncludeCalc As %Boolean = 0, pTopMembers As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Find type of member
		Set tType = pMember.%GetType()

		// dispatch to member class
		Set tRecurse = $Case(tType,$$$dstDimension:1,$$$dstHierarchy:1,:0)
		If (pTopMembers) {
			Set tRecurse = -1
		}
		// tMemberList is used to remember IN clauses amongst members
		Set tSC = pMember.%GetMembers(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber,"", pParent,pKey,.pNodeNo,tRecurse,,.tMemberList)
		If $$$ISERR(tSC) Quit

		If (pIncludeCalc) {
			// find all calculated members of this dimension
			Set tInfoD = $G($$$DeepSeeMetaGLVN("cubes",%cube,"mbr#",pMember.%dimNumber,0,0))
			Set tDimName = $LG(tInfoD,2)
			Set tSC = %query.%GetCalculatedMembers(tDimName,.tList)

			Set tName = $O(tList(""))
			While (tName '= "") {
				Kill tMbrSpec
				Set tMbrSpec($I(tMbrSpec)) = tDimName
				Set tMbrSpec($I(tMbrSpec)) = tName
				If (%query.%LookupCalculatedMember(.tMbrSpec,tMbrSpec,.tCalcMbr,.tSC)) {
					Set tSC = tCalcMbr.%ProcessAxes(pCube, pKey, .pNodeNo, .tNewNodeNo, pParent, 1)
				}
				If $$$ISERR(tSC) Quit
				Set tName = $O(tList(tName))
			}

			// see if there are any session-created members
			If $IsObject($G($$$DeepSeeSession)) {
				Set tCubeIndex = $$$DeepSeeIndex(pCube)
				Set tSessionId = $$$DeepSeeSession.%GetSessionId()
				Set k = $O($$$DeepSeeSessionGLVN(tSessionId,tCubeIndex,"calcMbrs",""))
				While (k'="") {
					Set tInfo = $G($$$DeepSeeSessionGLVN(tSessionId,tCubeIndex,"calcMbrs",k))
					If ($$$UPPER($LG(tInfo,1))="MEASURES") {
						Set tName = $LG(tInfo,2)
						Kill tMbrSpec
						Set tMbrSpec($I(tMbrSpec)) = "MEASURES"
						Set tMbrSpec($I(tMbrSpec)) = tName
						If (%query.%LookupCalculatedMember(.tMbrSpec,tMbrSpec,.tCalcMbr,.tSC)) {
							Set tSC = tCalcMbr.%ProcessAxes(pCube, pKey, .pNodeNo, .tNewNodeNo, pParent, 1)
						}
						If $$$ISERR(tSC) Quit
					}
					Set k = $O($$$DeepSeeSessionGLVN(tSessionId,tCubeIndex,"calcMbrs",k))
				}
			}
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Execute the Children function on the given member and place results into <var>pSet</var>.<br/>
/// This will return all children of the current member node.<br/>
/// The work of getting the members is delegated to the member object <var>pMember</var>.
Method FXChildren(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pMember As %DeepSee.Query.member, pReturnSelf As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pReturnSelf) {
			// If we are the bottom-most level, return ourselves
			Set tExists = ##class(member).%GetNodeInfo(pCube,pMember.%dimNumber,pMember.%hierNumber,pMember.%levelNumber+1)
			If ('tExists) {
				Set tExists = ##class(member).%GetNodeInfo(pCube,pMember.%dimNumber,pMember.%hierNumber,pMember.%levelNumber,.tFact)
				Set tCubeIndex = $$$DeepSeeIndex(pCube)
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("mbr",1,1,pParent,pMember.%name,pMember.%memberId,tFact,,pMember.%dimNumber,pMember.%hierNumber,pMember.%levelNumber,,"")
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
				Quit
			}
		}
		Set tLevelNo = pMember.%levelNumber + 1
		Set tRollupKey = $LG($G(pMember.%memberSpec(tLevelNo-1)),2)
		Set tSC = pMember.%GetMembers(pCube,pMember.%dimNumber,pMember.%hierNumber,tLevelNo,tRollupKey,pParent,pKey,.pNodeNo)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute the Siblings function on the given member and place results into <var>pSet</var>.<br/>
/// This will return all siblings of the current member node.<br/>
/// The work of getting the members is delegated to the member object <var>pMember</var>.
Method FXSiblings(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, pParent As %Integer, pMember As %DeepSee.Query.member) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Get our parent
		Set tSC = ..FXParent(pCube, pParent, pMember, .tSet)
		If $$$ISERR(tSC) Quit
		If '$D(tSet(1)) Quit

		// Now get parent's children
		Set tSC = ..FXChildren(pCube, pKey, .pNodeNo, pParent, pMember)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute the FirstChild function on the given member and place results into <var>pSet</var>.<br/>
/// This will return the first child of the current member node.<br/>
/// The work of getting the members is delegated to the member object <var>pMember</var>.
Method FXFirstChild(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)
		Set tSC = pMember.%GetNthChild(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber, pParent,.pSet,tKey,1)
		If $$$ISERR(tSC) Quit
		Set tNodeValue = $LG($G(pSet(1)),5)
		Set tNodeId = $LG($G(pSet(1)),6)
		Set tNodeKey = $LG($G(pSet(1)),13)
		Set pMember.%levelNumber = pMember.%levelNumber + 1
		Set pMember.%memberSpec(pMember.%levelNumber) = $LB(tNodeValue,tNodeId,tNodeKey)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute the LastChild function on the given member and place results into <var>pSet</var>.<br/>
/// This will return the last child of the current member node.<br/>
/// The work of getting the members is delegated to the member object <var>pMember</var>.
Method FXLastChild(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)
		Set tSC = pMember.%GetNthChild(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber, pParent,.pSet,tKey,-1)
		If $$$ISERR(tSC) Quit

		Set tNodeValue = $LG($G(pSet(1)),5)
		Set tNodeId = $LG($G(pSet(1)),6)
		Set tNodeKey = $LG($G(pSet(1)),13)
		Set pMember.%levelNumber = pMember.%levelNumber + 1
		Set pMember.%memberSpec(pMember.%levelNumber) = $LB(tNodeValue,tNodeId,tNodeKey)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute Parent function on the given member and place results into <var>pSet</var>.<br/>
Method FXParent(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pMember.%levelNumber>1) {
			Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)
			Set tSC = pMember.%GetParentMember(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber, pParent,.pSet,tKey)
			If $$$ISERR(tSC) Quit

			Set tNodeValue = $LG($G(pSet(1)),5)
			Set tNodeId = $LG($G(pSet(1)),6)
			Set tNodeKey = $LG($G(pSet(1)),13)
			Set pMember.%levelNumber = pMember.%levelNumber - 1
			Set pMember.%memberSpec(pMember.%levelNumber) = $LB(tNodeValue,tNodeId,tNodeKey)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute %AllMember function on the given member and place results into <var>pSet</var>.<br/>
/// This finds the All member for the current dimension (if present).
Method FXAllMember(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Test if dimension has an all level
		If (pMember.%levelNumber>1) {
			Set tKey = ""
			Set tSC = pMember.%GetParentMember(pCube,pMember.%dimNumber, pMember.%hierNumber, 2, pParent,.pSet,tKey)
			If $$$ISERR(tSC) Quit

			Set tNodeValue = $LG($G(pSet(1)),5)
			Set tNodeId = $LG($G(pSet(1)),6)
			Set tNodeKey = $LG($G(pSet(1)),13)
			Set pMember.%levelNumber = 1
			Set pMember.%memberSpec(pMember.%levelNumber) = $LB(tNodeValue,tNodeId,tNodeKey)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute the special %All function on the given member and place results into <var>pSet</var>.<br/>
/// This cause all references to this level along other rows and columns to be ignored.
/// The slicer is still applied.
Method FXAll(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// we should have one child which is the member to modify
		Set tChild = ..children.GetAt(1)

		// get member provider for child
		Set tMember = tChild.%GetMemberProvider()

		Set tSC = tMember.%ProcessMembers(pParent,.pSet)
		If $$$ISERR(tSC) Quit
		
		// get list of all facts related to the current dimension
		// these become the "ignore" list (do not apply an restrictions from these)
		Set tFactList = ""
		Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",pMember.%dimNumber,pMember.%hierNumber,""),1,tInfo)
		While (tLevel '= "") {
			Set tFactList = tFactList _ $S(tFactList="":"",1:",") _ $LG(tInfo,5)
			Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",pMember.%dimNumber,pMember.%hierNumber,tLevel),1,tInfo)
		}

		// add fact list to node: slot 20
		Set $List(pSet(1),20) = tFactList
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute the special %NOT function on the given member and place results into <var>pSet</var>.<br/>
/// This adds a negation marker to the key for given member.
Method FXNot(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// we should have one child which is the member to modify
		Set tChild = ..children.GetAt(1)

		// get member provider for child
		Set tMember = tChild.%GetMemberProvider()

		Set tSC = tMember.%ProcessMembers(pParent,.pSet)
		If $$$ISERR(tSC) Quit

		// Change ID (6); leave key (13) alone.
		Set tID = $LG($G(pSet(1)),6)
		Set:(tID'="") $List(pSet(1),6) = "!"_tID

		// change label to "NOT " member
		Set tName = $LG($G(pSet(1)),5)
		If (tName'="") {
			Set $List(pSet(1),5) = $$$FormatText($$$Text("Not %1","%DeepSee"),tName)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute FirstSibling function on the given member and place results into <var>pSet</var>.<br/>
Method FXFirstSibling(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Get our parent
		Set tSC = ..FXParent(pCube, pParent, pMember, .tSet)
		If $$$ISERR(tSC) Quit
		If '$D(tSet(1)) Quit

		// Now get parent's first child
		Set tSC = ..FXFirstChild(pCube, pParent, pMember, .pSet)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute LastSibling function on the given member and place results into <var>pSet</var>.<br/>
Method FXLastSibling(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Get our parent
		Set tSC = ..FXParent(pCube, pParent, pMember, .tSet)
		If $$$ISERR(tSC) Quit
		If '$D(tSet(1)) Quit

		// Now get parent's last child
		Set tSC = ..FXLastChild(pCube, pParent, pMember, .pSet)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute PrevMember function on the given member and place results into <var>pSet</var>.<br/>
Method FXPrevMember(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)

		// find our rollup key, if any, so we can restrict by it
		Set tSC = pMember.%GetRollupKey(pMember.%levelNumber,tKey,.tRollupKey)
		If $$$ISERR(tSC) Quit

		Set tSC = pMember.%GetRelatedMember(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber,tRollupKey, pParent,.pSet,tKey,"lag",1)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute NextMember function on the given member and place results into <var>pSet</var>.<br/>
Method FXNextMember(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)

		// find our rollup key, if any, so we can restrict by it
		Set tSC = pMember.%GetRollupKey(pMember.%levelNumber,tKey,.tRollupKey)
		If $$$ISERR(tSC) Quit
		Set tSC = pMember.%GetRelatedMember(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber,tRollupKey, pParent,.pSet,tKey,"lead",1)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute Lag function on the given member and place results into <var>pSet</var>.<br/>
Method FXLag(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List, ByRef pArgs As %DeepSee.Query.node) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tOffset = 0
		If $IsObject($G(pArgs(1))) {
			Set tOffset = pArgs(1).%GetValue()
		}
		If (tOffset < 0) {
			Set tSC = $$$ERROR($$$GeneralError,"Argument to LAG must be non-negative")
			Quit
		}

		Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)

		// find our rollup key, if any, so we can restrict by it
		Set tSC = pMember.%GetRollupKey(pMember.%levelNumber,tKey,.tRollupKey)
		If $$$ISERR(tSC) Quit

		Set tSC = pMember.%GetRelatedMember(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber,tRollupKey, pParent,.pSet,tKey,"lag",tOffset)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute Lead function on the given member and place results into <var>pSet</var>.<br/>
/// <var>pArgs</var> contains the array of arguments for this function.
Method FXLead(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List, ByRef pArgs As %DeepSee.Query.node) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tOffset = 0
		If $IsObject($G(pArgs(1))) {
			Set tOffset = pArgs(1).%GetValue()
		}
		If (tOffset < 0) {
			Set tSC = $$$ERROR($$$GeneralError,"Argument to LEAD must be non-negative")
			Quit
		}

		Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)

		// find our rollup key, if any, so we can restrict by it
		Set tSC = pMember.%GetRollupKey(pMember.%levelNumber,tKey,.tRollupKey)
		If $$$ISERR(tSC) Quit

		Set tSC = pMember.%GetRelatedMember(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber,tRollupKey,pParent,.pSet,tKey,"lead",tOffset)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute Properties function on the given member and place results into <var>pSet</var>.<br/>
/// <var>pArgs</var> contains the array of arguments for this function.
Method FXProperties(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List, ByRef pArgs As %DeepSee.Query.node) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tPropName = ""
		If $IsObject($G(pArgs(1))) {
			Set tPropName = pArgs(1).%GetValue()
		}

		If (tPropName = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing property name for PROPERTIES function")
			Quit
		}

		// JMD1373: check for Default Value
		If $IsObject($G(pArgs(2))) {
			Set tDefValue = pArgs(2).%GetValue()
		}

		// check for INTRINSIC properties
		Set tPropNameU = $$$UPPER(tPropName)

		// get spec and info for current member (used by many cases)
		Set tSpec = $G(pMember.%memberSpec(pMember.%levelNumber))
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",pMember.%dimNumber,pMember.%hierNumber,pMember.%levelNumber))

		// JMD: this list has to match the one in Engine.%ProcessOneCurrentMember
		If (tPropNameU = "ID") {
			Set tValue = $LG(tSpec,2)
		}
		ElseIf (tPropNameU = "KEY") {
			Set tValue = $LG(tSpec,3)
		}
		ElseIf (tPropNameU = "NAME") {
			Set tValue = $LG(tSpec,1)
		}
		ElseIf (tPropNameU = "MEMBER_NAME") {
			Set tValue = $LG(tSpec,1)
		}
		ElseIf (tPropNameU = "CAPTION") {
			Set tValue = $LG(tSpec,1)
		}
		ElseIf (tPropNameU = "CUBE_NAME") {
			Set tValue = pCube
		}
		ElseIf (tPropNameU = "LEVEL_NUMBER") {
			Set tValue = pMember.%levelNumber
		}
		ElseIf (tPropNameU = "LEVEL") {
			// find name of this level
			If (tInfo '= "") {
				Set tValue = $$$UPPER($LG(tInfo,4))
			}
		}
		ElseIf (tPropNameU = "HIERARCHY") {
			// find name of this hierarchy
			If (tInfo '= "") {
				Set tValue = $$$UPPER($LG(tInfo,3))
			}
		}
		ElseIf (tPropNameU = "DIMENSION") {
			// find name of this dimension
			If (tInfo '= "") {
				Set tValue = $$$UPPER($LG(tInfo,2))
			}
		}
		ElseIf (tPropNameU = "LEVEL_CAPTION") {
			// find caption of this level
			If (tInfo '= "") {
				Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCube,.tSC)
				If $$$ISERR(tSC) Quit
				Set tValue = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER($LG(tInfo,2)),$$$UPPER($LG(tInfo,3)),$$$UPPER($LG(tInfo,4)))
			}
		}
		ElseIf (tPropNameU = "DIMENSION_CAPTION") {
			// find dimension caption for this member
			If (tInfo '= "") {
				Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCube,.tSC)
				If $$$ISERR(tSC) Quit
				Set tValue = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER($LG(tInfo,2)))
			}
		}
		ElseIf (tPropNameU = "HIERARCHY_CAPTION") {
			// find hierarchy caption for this member
			If (tInfo '= "") {
				Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCube,.tSC)
				If $$$ISERR(tSC) Quit
				Set tValue = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER($LG(tInfo,2)),$$$UPPER($LG(tInfo,3)))
			}
		}

		If $D(tValue) {
			// force non-empty value
			// JMD1373
			Set tEmpty = $G(tDefValue," ")
			Set pSet($I(pSet)) = $LB("lit",1,1,pParent,tPropName,$S($G(tValue)="":tEmpty,1:tValue))
		}
		Else {
			// dispatch to member
			Set tKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)
			Set tSC = pMember.%GetPropertyValue(pCube,pMember.%dimNumber, pMember.%hierNumber, pMember.%levelNumber,tPropName, pParent,.pSet,tKey)
			If $$$ISERR(tSC) Quit

			// JMD909 add caption
			If $D(pSet(1)) {
				// JMD1373: test for default value
				Set t = $LG(pSet(1),6)
				If ($D(tDefValue)&&(t="@NOPROPERTY")) {
					Set $List(pSet(1),6) = tDefValue
				}
				Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCube,.tSC)
				If $$$ISERR(tSC) Quit
				Set tCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER($LG(tInfo,2)),$$$UPPER($LG(tInfo,3)),$$$UPPER($LG(tInfo,4)),tPropNameU)
				Set $List(pSet(1),5) = tCaption
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Change the default aggregate to <var>pAggregate</var> on the current measure and place results into <var>pSet</var>.<br/>
Method FXChangeAggregate(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List, pAggregate As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// we should have one child which is the measure to modify
		Set tChild = ..children.GetAt(1)

		// get member provider for child
		Set tMember = tChild.%GetMemberProvider()

		Set tSC = tMember.%ProcessMembers(pParent,.pSet)
		If $$$ISERR(tSC) Quit

		// apply new aggregate
		Set $List(pSet(1),8) = pAggregate
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute the internal function %RANK on the given member and place results into <var>pSet</var>.<br/>
/// <var>pArgs</var> contains the array of arguments for this function.<br/>
/// This function is used when a RANK operation had to be run on a resolved CurrentMember.
Method FXRank(pCube As %String, pParent As %Integer, pMember As %DeepSee.Query.member, Output pSet As %List, ByRef pArgs As %DeepSee.Query.node) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tQueryKey = ""
		If $IsObject($G(pArgs(1))) {
			Set tQueryKey = pArgs(1).%GetValue()
		}
		If (tQueryKey = "") {
			Set tSC = $$$ERROR($$$GeneralError,"%RANK missing query key")
			Quit
		}

 		// Lookup fact number from meta data
		Set tTupleFact = ""
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",pMember.%dimNumber,pMember.%hierNumber,pMember.%levelNumber))
		If (tInfo '= "") {
			Set tTupleFact = $LG(tInfo,5)
		}
		Set tTupleName = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),1)
		Set tTupleKey = $LG($G(pMember.%memberSpec(pMember.%levelNumber)),2)
		Set tCode = tTupleFact_":"_tTupleKey

		// Use SubQuery results to find the ranking of the given tuple.
		// Get array of values from subquery indexed by internal tuple (fact/key...)
		Set tSC = ##class(%DeepSee.Query.Engine).%GetAxisValues(.tIndex,$$$UPPER(pCube),tQueryKey,,1)
		If $$$ISERR(tSC) Quit

		// find tuple in result set
		Set tFound = 0
		Set tRank = $O(^||DeepSee.Temp(tIndex,""))
		While (tRank '= "") {
			Set k = $O(^||DeepSee.Temp(tIndex,tRank,""))
			While (k '= "") {
				If (tCode = k) {
					Set tFound = 1
					Quit
				}
				Set k = $O(^||DeepSee.Temp(tIndex,tRank,k))
			}
			If tFound Quit
			Set tRank = $O(^||DeepSee.Temp(tIndex,tRank))
		}

		// delete temp data
		Kill ^||DeepSee.Temp(tIndex)

		// deal with complex tuples?

		// Paste answer into tuple node
		Set pSet($I(pSet)) = $LB("lit",1,1,pParent,tTupleName,tRank)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
