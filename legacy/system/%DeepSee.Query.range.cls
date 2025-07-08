/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a range within a DeepSee query.<br/>
/// A range is set defined by a starting and ending member.
/// It corresponds to the A:B syntax within MDX.
Class %DeepSee.Query.range Extends node [ System = 3 ]
{

/// Starting member for this range.
/// This can be a <class>memberSpec</class> or a <class>memberFunction</class>.
Property startMember As %DeepSee.Query.node;

/// Ending member for this range.
/// This can be a <class>memberSpec</class> or a <class>memberFunction</class>.
Property endMember As %DeepSee.Query.node;

/// Member object that provides the member API for the range.
/// This is created during the pre-processing phase.
Property %member As %DeepSee.Query.member(XMLPROJECTION = "none");

/// Return type of this node.
Method %GetType() As %String
{
	Quit $$$dstSet
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set tText = ..startMember.%ToString(.pSC) _ ":" _ ..endMember.%ToString(.pSC)
	Quit tText
}

/// Execute the pre-processing logic for this node.
Method %PreProcess(pIsSlicer As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Quit:..%PreProcessed

		If '$IsObject(..startMember) {
			Set tSC = $$$ERROR($$$GeneralError,"Range node with no start member!")
			Quit
		}
		If '$IsObject(..endMember) {
			Set tSC = $$$ERROR($$$GeneralError,"Range node with no end member!")
			Quit
		}

		Set tSC = ..startMember.%PreProcess(pIsSlicer)
		If $$$ISERR(tSC) Quit

		Set tSC = ..endMember.%PreProcess(pIsSlicer)
		If $$$ISERR(tSC) Quit

		// find member providers for start and end
		Set tStartOffset = 0
		Set tEndOffset = 0

		// Start Member
		If (..startMember.%IsA("%DeepSee.Query.memberSpec")) {
			// DP-421962 - Check if the field's ODBC type is numeric or non-numeric. This will determine the type of comparison - sorts after (]]) vs follows (]).
			// Use the source type recorded in the cube metadata if available
			If (('..startMember.%member.%IsA("%DeepSee.Query.memberTime"))) {
				Set tExists = ..startMember.%member.%GetNodeInfo(..startMember.%member.%cube, ..startMember.%member.%dimNumber, ..startMember.%member.%hierNumber, ..startMember.%member.%levelNumber, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList,.tStarKeyField)

				Set tStarFieldType = $G($$$DeepSeeMetaGLVN("cubes",$$$DeepSeeIndex(..startMember.%member.%cube),"fact","prop",tStarKeyField,"sourceType"))
				If $D($$$DeepSeeMetaGLVN("cubes",$$$DeepSeeIndex(..startMember.%member.%cube),"fact","prop",tStarKeyField,"sourceType"),tStarFieldType) {
					Set tLevelTypeIsNumeric = ( ("DECIMAL"=tStarFieldType) ||
									("DOUBLE"=tStarFieldType) ||
									("FLOAT"=tStarFieldType) ||
									("INTEGER"=tStarFieldType) ||
									("NUMERIC"=tStarFieldType) )
				} 
				Else {
					Set tTableName = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
					set tName = $$IntQualifiedName^%apiSQL(tTableName)
					set tExtentname = $$$GetExtentNameFromIQN(tName)
					set tFieldInfo = $$$EXTSQLCOLsqlinfo($$$rEXT,tExtentname,tStarField)
					Set tLevelType = $$$SQLLocColxDBCType(tFieldInfo)
					Set tLevelTypeIsNumeric = (tLevelType="BIGINT") || (tLevelType="NUMERIC") ||(tLevelType="DOUBLE") ||(tLevelType="INTEGER") ||(tLevelType="SMALLINT") ||(tLevelType="TINYINT")
				}
				
				Set x = $O(..startMember.%resolvedSpec(""),-1,s1)
				Set x = $O(..endMember.%resolvedSpec(""),-1,s2)
				If (tLevelTypeIsNumeric){ 
					If (s1 '= "0") Set s1=$ZStrip(s1,"<","0") //remove leading zeroes to avoid incorrect sorts-after comparison
					If (s2 '= "0") Set s2=$ZStrip(s2,"<","0")
					If (s1 ]] s2){ //Using the "sorts-after" operator to compare numbers
						Set tTempMember = ..startMember
						Set ..startMember = ..endMember
						Set ..endMember = tTempMember
					}
				}
				Else{
					If ($$$UPPER(s1) ] $$$UPPER(s2)){ //using the "follows" operator to compare strings
						Set tTempMember = ..startMember
						Set ..startMember = ..endMember
						Set ..endMember = tTempMember
					}
				}
			}

			// DP-421962 - Attempt to find a suitable replacement for the startMember if it is currently NO MEMBER
			Set tStartMember = ..startMember.%GetMemberProvider()
			If (tStartMember.%memberKey="NO MEMBER") {
				// Try to find a new spec using real members as endpoints
				Set (spec,tStartKey) = ""
				Set partNo = $O(..startMember.%resolvedSpec(""),-1,part)
				While (partNo'="") {
					If (tStartKey="") {
						Set tStartKey = part
					}
					Else {
						Set spec = "[" _ part _ "]" _ $S($L(spec):".",1:"") _ spec
					}
					Set partNo = $O(..startMember.%resolvedSpec(partNo),-1,part)
				}

				// We've reached the bad key. Find the closest relevant key to complete a good spec.
				Set tCubeIndex = tStartMember.%cube
				Set tStartDim = tStartMember.%dimNumber
				Set tStartHier = tStartMember.%hierNumber
				Set tStartLevel = tStartMember.%levelNumber
				Set tSC = tStartMember.%GetRelatedMember(tCubeIndex,tStartDim,tStartHier,tStartLevel,"",0,.tStartSet,"","lead",1,tStartKey,1)
				If $$$ISERR(tSC) Quit

				If $D(tStartSet) {
					// If there is a start member that exists, create a new memberSpec object
					Set spec = spec _ ".&[" _ $LG(tStartSet(1),13) _ "]"
					Set tSC = ##class(%DeepSee.Query.memberSpec).%ConstructMemberSpec(spec,.tNewStartSpec)
					If $$$ISERR(tSC) Quit
				}
			}
		}
		ElseIf (..startMember.%IsA("%DeepSee.Query.memberFunction")) {
			Set tStartOffset = $Case($$$UPPER(..startMember.function),"FIRSTCHILD":1,"LASTCHILD":1,"PARENT":-1,:0)
			// look until we find an actual member!
			// track if we are going up or down levels!
			Set tChild = ..startMember.children.GetAt(1)
			While (tChild.%IsA("%DeepSee.Query.memberFunction")) {
				Set tStartOffset = tStartOffset + $Case($$$UPPER(tChild.function),"FIRSTCHILD":1,"LASTCHILD":1,"PARENT":-1,:0)
				Set tChild = tChild.children.GetAt(1)
			}
			Set tStartMember = tChild.%GetMemberProvider()
		}
		If '$IsObject($G(tStartMember)) {
			Set tSC = $$$ERROR($$$GeneralError,"Start of range is of wrong type")
			Quit
		}

		// End Member
		If (..endMember.%IsA("%DeepSee.Query.memberSpec")) {
			Set tEndMember = ..endMember.%GetMemberProvider()
			// DP-421962 - Attempt to find a suitable replcement for the endMember if it is currently NO MEMBER
			If (tEndMember.%memberKey="NO MEMBER") {
				// Try to find a new spec using real members as endpoints
				Set (spec,tEndKey) = ""
				Set partNo = $O(..endMember.%resolvedSpec(""),-1,part)
				While (partNo'="") {
					If (tEndKey="") {
						Set tEndKey = part
						Set tKeyNo = partNo
					}
					Else {
						Set spec = "[" _ part _ "]" _ $S($L(spec):".",1:"") _ spec
					}
					Set partNo = $O(..endMember.%resolvedSpec(partNo),-1,part)
				}

				// We've reached the bad key. Find the closest relevant key to complete a good spec.
				Set tCubeIndex = tEndMember.%cube
				Set tEndDim = tEndMember.%dimNumber
				Set tEndHier = tEndMember.%hierNumber
				Set tEndLevel = tEndMember.%levelNumber

				Set tSC = tEndMember.%GetRelatedMember(tCubeIndex,tEndDim,tEndHier,tEndLevel,"",0,.tEndSet,"","lag",1,tEndKey,1)
				If $$$ISERR(tSC) Quit

				If $D(tEndSet) {
					// If there is an end member that exists, create a new memberSpec object
					Set spec = spec _ ".&[" _ $LG(tEndSet(1),13) _ "]"
					Set tSC = ##class(%DeepSee.Query.memberSpec).%ConstructMemberSpec(spec,.tNewEndSpec)
					If $$$ISERR(tSC) Quit
				}
			}
		}
		ElseIf (..endMember.%IsA("%DeepSee.Query.memberFunction")) {
			Set tEndOffset = $Case($$$UPPER(..endMember.function),"FIRSTCHILD":1,"LASTCHILD":1,"PARENT":-1,:0)
			Set tChild = ..endMember.children.GetAt(1)
			While (tChild.%IsA("%DeepSee.Query.memberFunction")) {
				Set tEndOffset = tEndOffset + $Case($$$UPPER(tChild.function),"FIRSTCHILD":1,"LASTCHILD":1,"PARENT":-1,:0)
				Set tChild = tChild.children.GetAt(1)
			}
			Set tEndMember = tChild.%GetMemberProvider()
		}
		If '$IsObject($G(tEndMember)) {
			Set tSC = $$$ERROR($$$GeneralError,"End of range is of wrong type")
			Quit
		}
		If ((tStartMember.%dimNumber '= tEndMember.%dimNumber) ||
			(tStartMember.%hierNumber '= tEndMember.%hierNumber) ||
			((tStartMember.%levelNumber+tStartOffset) '= (tEndMember.%levelNumber+tEndOffset))) {
			Set tSC = $$$ERROR($$$GeneralError,"Both parts of range expression must refer to same dimension and level.")
			Quit
		}
		// JMD1324: ignore this error
		/*
		If ((tStartMember.%memberId = "") || (tEndMember.%memberId = "")) {
			Set tSC = $$$ERROR($$$GeneralError,"Both parts of range expression must refer to specific members.")
			Quit
		}
		*/

		// + DP-421962
		// Test any related member information to finalize the startNode and endNode
		If ($D(tStartSet)&&$D(tEndSet)) {
			// Two nonexistent members. Make sure there was actually something between them by swapping directions
			// and comparing the new endpoints with the original. If the sets are reverse images of each other, 
			// there is nothing in between the two original values
			Set tSC = ..startMember.%member.%GetRelatedMember(tCubeIndex,tStartDim,tStartHier,tStartLevel,"",0,.tStartSet,"","lag",1,tStartKey,1)
			If $$$ISERR(tSC) Quit
			Set tSC = ..endMember.%member.%GetRelatedMember(tCubeIndex,tEndDim,tEndHier,tEndLevel,"",0,.tEndSet,"","lead",1,tEndKey,1)
			If $$$ISERR(tSC) Quit
			
			If '($D(tStartSet(2)) && $D(tEndSet(2)) && (tStartSet(1)=tEndSet(2)) && (tStartSet(2)=tEndSet(1)) ) {
				// The endpoints are valid, pass them along
				Do tNewStartSpec.%PreProcess()
				Set ..startMember = tNewStartSpec
				Set tStartMember = tNewStartSpec.%member
				
				Do tNewEndSpec.%PreProcess()
				Set ..endMember = tNewEndSpec
				Set tEndMember = tNewEndSpec.%member
			}
			Else {
				// Do nothing: both endpoints are already set to NO MEMBER.
			}
		}
		Else {
			If $D(tStartSet) {
				// Replace NO MEMBER start node with next node
				Do tNewStartSpec.%PreProcess()
				Set ..startMember = tNewStartSpec
				Set tStartMember = tNewStartSpec.%member
			}
			If $D(tEndSet) {
				// Replace NO MEMBER end node with previous node
				Do tNewEndSpec.%PreProcess()
				Set ..endMember = tNewEndSpec
				Set tEndMember = tNewEndSpec.%member
			}
		}
		// - DP-421962
		
		// Use member object from start member for subsequent work
		Set ..%member = tStartMember
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set:$$$ISOK(tSC) ..%PreProcessed = 1
	
	Quit tSC
}

/// Execute and build the axes output for this set.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set isOriginalStartNodeNoMember=0, isOriginalEndNodeNoMember=0
		
		//APV029 - If the value of the start member's spec is greater than the value of the end member's spec, swap the start and end members
		If ( ($IsObject(..startMember)) && (..startMember.%IsA("%DeepSee.Query.memberSpec"))&& ($IsObject(..endMember))  && (..endMember.%IsA("%DeepSee.Query.memberSpec") ) && ( ('..startMember.%member.%IsA("%DeepSee.Query.memberTime"))||( '..endMember.%member.%IsA("%DeepSee.Query.memberTime")) ) ) {
			Set tSC1 = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..startMember.spec, .tInfo1,,.tMemberKey1)
			Set tSC2 = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..endMember.spec, .tInfo2,,.tMemberKey2)			
			If ('$$$ISERR(tSC1) && '$$$ISERR(tSC2)){
				Set tIndex1=$O(tInfo1(""),-1)
				Set tIndex2=$O(tInfo2(""),-1)
				//fetch the value corresponding to this key. This assumes that if keys are passed in, they will correspond to valid values
				If ( $G(tMemberKey1(tIndex1))=1 ){ 
					Set s1= ..startMember.%GetMemberProvider().%name
				}
				Else{
					Set s1 = tInfo1(tIndex1)
				}
				
				If ( $G(tMemberKey2(tIndex2))=1 ){
					Set s2= ..endMember.%GetMemberProvider().%name
				}
				Else{
					Set s2 = tInfo2(tIndex2)
				}
				If ( '($$$UPPER(s1)="NO MEMBER") && '($$$UPPER(s2)="NO MEMBER")){ 
					// N.B: Ideally preprocessing removes any need for this to happen 
					Set tExists = ..%member.%GetNodeInfo(..%member.%cube, ..%member.%dimNumber, ..%member.%hierNumber, ..%member.%levelNumber, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList,.tStarKeyField)
					
					//Check if the field's ODBC type is numeric or non-numeric. This will determine the type of comparison - sorts after (]]) vs follows (])
					Set tTableName = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
					set tName = $$IntQualifiedName^%apiSQL(tTableName)
					set tExtentname = $$$GetExtentNameFromIQN(tName)
					set tFieldInfo = $$$EXTSQLCOLsqlinfo($$$rEXT,tExtentname,tStarField)
					Set tLevelType = $$$SQLLocColxDBCType(tFieldInfo)
					Set tLevelTypeIsNumeric = (tLevelType="BIGINT") || (tLevelType="NUMERIC") ||(tLevelType="DOUBLE") ||(tLevelType="INTEGER") ||(tLevelType="SMALLINT") ||(tLevelType="TINYINT")

					
					// DP-421962 - Use the source type recorded in the cube metadata to determine the collation for sorting
					Set tStarFieldType = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tStarKeyField,"sourceType"))
					Set tLevelTypeIsNumeric = ( ("DECIMAL"=tStarFieldType) ||
										("DOUBLE"=tStarFieldType) ||
										("FLOAT"=tStarFieldType) ||
										("INTEGER"=tStarFieldType) ||
										("NUMERIC"=tStarFieldType) )
					

					If (tLevelTypeIsNumeric){ 
						If (s1 '= "0") Set s1=$ZStrip(s1,"<","0") //remove leading zeroes to avoid incorrect sorts-after comparison
						If (s2 '= "0") Set s2=$ZStrip(s2,"<","0")
						//The $$$UPPER has been added to satisfy the test "SELECT NON EMPTY [ColorD].[H1].[Favorite Color].Members ON 1 FROM [PATIENTS] %FILTER %OR([COLORD].[H1].[FAVORITE COLOR].&[a]:&[Z])" in //DeepSee/TestPatientsSelective/Test1Tests/MDXQueries/TestRange
						If ($$$UPPER(s1) ]] $$$UPPER(s2)){ //Using the "sorts-after" operator to compare numbers
							Set tTempMember = ..startMember
							Set ..startMember = ..endMember
							Set ..endMember = tTempMember
						}
					}
					Else{
						If ($$$UPPER(s1) ] $$$UPPER(s2)){ //using the "follows" operator to compare strings
							Set tTempMember = ..startMember
							Set ..startMember = ..endMember
							Set ..endMember = tTempMember
						}
					}
				}
			}
		}
		// create a set to hold the range members
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,pParent)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set tSetNode = pNodeNo
		Set pNewNodeNo = pNodeNo

		// process start and end members of range
		Set tSC = ..startMember.%ProcessAxes(pCube,pKey,.pNodeNo,.tStartNodeNo,tSetNode,pVisible)
		If $$$ISERR(tSC) Quit

		Set tSC = ..endMember.%ProcessAxes(pCube,pKey,.pNodeNo,.tEndNodeNo,tSetNode,pVisible)
		If $$$ISERR(tSC) Quit

		// now replace child nodes with range of nodes
		Set tStartNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tStartNodeNo))
		Set tEndNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",tEndNodeNo))

		Set tStartNodeType = $LG(tStartNode,1)
		Set tEndNodeType = $LG(tEndNode,1)
		Set tStartVal = $LG(tStartNode,5)
		Set tEndVal = $LG(tEndNode,5)
		Set tStartKey = $LG(tStartNode,6)
		Set tEndKey = $LG(tEndNode,6)
		Set tStartDim = $LG(tStartNode,9)
		Set tStartHier = $LG(tStartNode,10)
		Set tStartLevel = $LG(tStartNode,11)
		Set tEndDim = $LG(tEndNode,9)
		Set tEndHier = $LG(tEndNode,10)
		Set tEndLevel = $LG(tEndNode,11)

		If ((tStartNodeType'="mbr")||(tEndNodeType'="mbr")) {
			Set tSC = $$$ERROR($$$GeneralError,"Both parts of a range must be members")
			Quit
		}

		// make sure both ends of range are at same level
		If ((tStartDim'=tEndDim)||(tStartHier'=tEndHier)||(tStartLevel'=tEndLevel)) {
			Set tSC = $$$ERROR($$$GeneralError,"Both parts of a range must be from the same dimension and level")
			Quit
		}

		// JMD1301: test for time dimension
		Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tStartDim,tStartHier,tStartLevel))
		Set tTimeClass = $LG(tLevelInfo,6)

		// JMD1301: for time dimensions use keys not values
		If (tTimeClass [ "%DeepSee.") {
			Set tRange(1) = tStartKey
			Set tRange(2) = tEndKey
		}
		Else {
			// use values for data so that sort order is preserved
			Set tRange(1) = tStartVal
			Set tRange(2) = tEndVal
		}

		// find rollup key to restrict by
		//Set tSC = ..%member.%GetRollupKey(..%member.%levelNumber,..%member.%memberId,.tRollupKey)
		//If $$$ISERR(tSC) Quit

		// Do not use rollup key for range
		Set tRollupKey = ""

		Set tMember = ..%member
		//APV029 - Call %GetMembers only if both range endpoints are not "NO MEMBER"
		If ( ($$$UPPER(tRange(1))'="NO MEMBER") && ($$$UPPER(tRange(2))'="NO MEMBER")){
			Set tSC = tMember.%GetMembers(tMember.%cube,tMember.%dimNumber,tMember.%hierNumber,tStartLevel,tRollupKey,tSetNode,pKey,.pNodeNo,0,.tRange)
			If $$$ISERR(tSC) Quit
		}
		// Delete original start/end nodes
		If ('isOriginalStartNodeNoMember || 'isOriginalEndNodeNoMember){ //APV029 - Delete the nodes only if one or both of the original nodes was not a 'NO MEMBER' node
			Set tSC = ..%DeleteNode(tCubeIndex,pKey,%axis,tStartNodeNo)
			If $$$ISERR(tSC) Quit
			Set tSC = ..%DeleteNode(tCubeIndex,pKey,%axis,tEndNodeNo)
			If $$$ISERR(tSC) Quit
		}
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
