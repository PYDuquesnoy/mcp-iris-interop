/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized version of the member class used for time dimensions.
Class %DeepSee.Query.memberTime Extends member [ System = 3 ]
{

/// See if the given name is a member of a level.<br/>
/// If <var>pLevel</var> is supplied, only look in that level.<br/>
Method %FindMemberByName(pName As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, pLevel As %Integer = "", Output pMemberKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set pMemberKey = ""
		Set tName = $ZCVT(pName,"U")
		Set tCubeIndex = $$$DeepSeeIndex(..%cube)

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
			// JMD1052: test for member list
			Set tExists = ..%GetNodeInfo(..%cube,pDim, pHier, tLevelNo, .tFact, .tLevelClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList)
			If ('tExists || (tLevelClass="")) {
				Quit
			}

			// dispatch to level class
			// test for null marker
			Set tNullName = ..%GetNullName(..%cube,pDim,pHier,tLevelNo,.tNullCaption)
			If ($$$LOWER(tName) = $$$LOWER(tNullName)) {
				Set tName = $$$DeepSeeNullMarker
				Set tID = $$$DeepSeeNullTimeMarker
				Set tKey = $$$DeepSeeNullMarker
				Set tValue = tNullName
				Set ..%memberSpec(tLevelNo) = $LB(tValue,tID,tKey)
				Set pMemberKey = tKey
				Set pFlag = 1
			}
			ElseIf (+tHasMemberList) {
				// JMD1052: use member list
				Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDim,pHier,tLevelNo,"mbr",""),1,data)
				While (p'="") {
					Set tItemName = $LG(data,1)
					If ($$$UPPER(tItemName) = $$$UPPER(pName)) {
						Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeIndex,.tSC)
						If $$$ISERR(tSC) Quit
						Set tKey = $LG(data,2)
						Set:tKey="" tKey=tItemName
						Set tItemCaption = $classmethod(tCubeClass,"%GetLevelMemberCaption",pDim,pHier,tLevelNo,tItemName)
						Set:tItemCaption="" tItemCaption=tItemName
						Set ..%memberSpec(tLevelNo) = $LB(tItemCaption,tKey,tKey)
						Set pMemberKey = tKey
						Set pFlag = 1
						Quit
					}
					Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDim,pHier,tLevelNo,"mbr",p),1,data)
				}
			}
			Else {
				Set tTimeOffset = ..%GetTimeOffset(..%cube,pDim,pHier,tLevelNo,.tTimeFormat)
				Set tKey = $zobjclassmethod(tLevelClass,"%ValueToKey",tName,tTimeFormat,tTimeOffset)
				If (tKey '= "") {
					// normalize name
					Set tValue = $zobjclassmethod(tLevelClass,"%KeyToValue",tKey,tTimeFormat,tTimeOffset)
					Set ..%memberSpec(tLevelNo) = $LB(tValue,tKey,tKey)
					Set pMemberKey = tKey
					Set pFlag = 1
				}
			}

			If (pLevel'="") {
				Quit
			}
			If ('pFlag) {
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

/// See if the given key is a member of a level.
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
			Set tExists = ..%GetNodeInfo(..%cube,pDim, pHier, tLevelNo, .tFact, .tLevelClass, .tStarField, .tStarSort, .tRollup)
			If ('tExists || (tLevelClass="")) {
				Quit
			}

			// dispatch to level class (time function class)
			// normalize name
			Set tID = pKey
			Set tKey = pKey

			If (($$$LOWER(tKey) = $$$DeepSeeNullMarker)||($$$LOWER(tKey) = $$$DeepSeeNullTimeMarker)) {
				Set tValue = ..%GetNullName(..%cube,pDim,pHier,tLevelNo,.tNullCaption)
				Set tID = $$$DeepSeeNullTimeMarker
			}
			Else {
				Set tTimeOffset = ..%GetTimeOffset(..%cube,pDim,pHier,tLevelNo,.tTimeFormat)
				Set tValue = $zobjclassmethod(tLevelClass,"%KeyToValue",tKey,tTimeFormat,tTimeOffset)

				If ($$$UPPER($E(tKey,1,3))="NOW") {
					Set tKey = $zobjclassmethod(tLevelClass,"%ValueToKey",tValue,tTimeFormat,tTimeOffset)
					Set tID = tKey
				}
			}

			If (tValue '= "") {
				// JMD986: remove $$$LOWER
				// use lower case to avoid "1990S" problem for decades
				// Set ..%memberSpec(tLevelNo) = $LB(tValue,$$$LOWER(tID),tKey)
				Set ..%memberSpec(tLevelNo) = $LB(tValue,tID,tKey)
				Set pMemberValue = tValue
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

/// Find the set of members that match the given criteria and place them into the axis tree.
ClassMethod %GetMembers(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, pKey As %String, ByRef pNodeNo As %Integer, pRecurse As %Integer = 0, ByRef pRange As %String, ByRef pMemberList) As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD1510 no children of <null> member
		If (pRollupKey=$$$DeepSeeNullTimeMarker) {
			Quit
		}

		Set tStart = $ZH
		Set tFactSensitive = 0

#define HTOSEC(%h) $S(%h["-":%h,1:((+%h)*86400)+($P((%h),",",2)))
#define SECTOH(%sec) $S(%sec["-":%sec,1:((%sec\86400)_","_(%sec#86400)))

		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tLevelClass, .tStarField, .tStarSort, .tRollup,.tSortDir,,.tHasMemberList)
		Set tTimeOffset = ..%GetTimeOffset(pCubeName,pDimNo, pHierNo, pLevelNo,.tTimeFormat)
		
		Set tIsPartial = $S(($G(tLevelClass)'=""):($Parameter(tLevelClass,"CALENDAR")="partial"),1:0)		// DTB688 - Partial dates need particular treatment of keys

		// if true, try not to include members with no data (if possible)
		// if we do let empty members through, they will be removed later
		Set tNonEmpty = $S($IsObject($G(%axisObject))&&%axisObject.nonEmpty:1,1:0)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tHasSlicer = ($G(%slicerKey)'="")

		// test for ALL level
		If (pLevelNo = 1) {
			Set tAllName = ..%GetAllName(pCubeName,pDimNo,.tAllCaption)
			If (tAllName '= "") {
				Set tNode = $LB("mbr",1,1,pParent,tAllCaption,"",tFact,,pDimNo,pHierNo,pLevelNo,,"")
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
				Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
				Set leaf = $I(%leafCount)
				If (pRecurse '= 0) {
					// n.b. do not pass range up
					Set tSC = ..%GetMembers(pCubeName, pDimNo, pHierNo, pLevelNo + 1,"", pParent,pKey,.pNodeNo,pRecurse)
					Quit:$$$ISERR(tSC)
				}
				Quit
			}
		}

		If (tNonEmpty) {
			Set tFactSensitive = 1
		}

		// ask level class for details
		If (tExists && (tLevelClass '= "")) {
			// JMD1329
			If $classmethod(tLevelClass,"%IsA","%DeepSee.Age.AbstractLevel") {
				Set tAgeDim = 1
			}
			Else {
				Set tAgeDim = 0

				// JMD947
				Set tNoData = 0
				If ($IsObject($G(%query))) {
					Set tSC = %query.%ProcessSlicerRestrictions(.tSlicerBranches,.tNoData)
					If $$$ISERR(tSC) Quit
				}
				// JMD947.2: get information on all levels for this hierarchy
				// (this means that a day within the slicer will restrict years etc.)
				For tFLevel = 1:1:100 {
					Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, tFLevel, .tFactX, .tLevelClassX, .tStarFieldX, .tStarSortX, .tRollupX, .tSortDirX,,.tHasMemberListX,.tStarKeyFieldX)
					If ('tExists) {
						Quit
					}
					If (tFactX'="") {
						Set tLevelFact(tFLevel) = tFactX
						Set tLevelClass(tFLevel) = tLevelClassX
						Set tLevelTimeOffset(tFLevel) = ..%GetTimeOffset(pCubeName,pDimNo, pHierNo, tFLevel)
						If (tLevelClassX'="") {
							Set tLevelIndependent(tFLevel) = $classmethod(tLevelClassX,"%IsIndependent")
						}
					}
				}

				// JMD947.2: use SlicerBranches to filter set of date values
				// build a list of time segments to do this
				// any facts from *this* hierarchy can be used
				// the final list contains zero or more time segments that are
				// later ORd together.
				// The results nodes contain a start/end normalized time values
				// tSegments(n)=$lb(start,end)

				Kill tSegments
				Set tRestrictBySlicer = (tNonEmpty||+$G(%dsRestrictBySlicer))&&$D(tSlicerBranches)
				Set:$D(pRange) tRestrictBySlicer = 0
				Set:(pRollupKey'="") tRestrictBySlicer = 0

				// JMD555
				If (tRestrictBySlicer&&tNoData) {
					Quit
				}

				If (tRestrictBySlicer) {
					// tSlicerBranches(branch,mbr) = $LB(Fact,Key)

					// test if this slicer does *any* restricting
					Set tIsRestricted = 0
					Set tTestBranchNo = $O(tSlicerBranches(""))
					While(tTestBranchNo'="") {
						// Check if this OR branch restricts on any of *our* facts
						Set tIsRestrictive = 0

						// Segments for *this* OR branch
						Set tHasSegsB = 0
						Kill tSegListB
						Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,""))
						While(tTestMbrNo'="") {
							// Segments for *this* AND branch
							Set tHasSegs = 0
							Kill tSegList
							Set tTestFact = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),1)
							Set tFLevel = $O(tLevelFact(""))
							While (tFLevel'="") {
								If (('+$G(tLevelIndependent(tFLevel)))&&($G(tLevelFact(tFLevel))=tTestFact)) {
									Set tIsRestricted = 1		// there is a slicer!
									Set tIsRestrictive = 1		// this OR branch is restrictive

									// combine keys in level (apply AND and NOT as we go)
									Kill tSeg
									Set kf = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),2)
									For jk = 1:1:$L(kf,"|") {
										Set tIsNot = 0
										Set kf2 = $P(kf,"|",jk)
										If ($E(kf2)="!") {
											// not
											Set kf2 = $E(kf2,2,*)
											Set tIsNot = 1
										}
										// convert key to normalized start/end times
										Set tSC = $classmethod(tLevelClass(tFLevel),"%KeyToBaseRange",kf2,.tStartRangeX,.tEndRangeX,tLevelTimeOffset(tFLevel))
										If $$$ISERR(tSC) Quit

										// convert NOT to OR of 2 ranges
										If (tIsNot) {
											// WAL091 -- It doesn't make sense to calculate if we were
											//           dealing with a null key
											If (kf2=$$$DeepSeeNullTimeMarker) {
												Set tExcludeNullMember=1 // refer to this later to recall that we excluded
												Set tSeg($I(tSeg)) = $LB(0,1E20) // Pick up all actual time values
											}
											// - WAL091
											Else {
												Set tSeg($I(tSeg)) = $LB(0,$$$HTOSEC(tStartRangeX)-1)
												Set tSeg($I(tSeg)) = $LB($$$HTOSEC(tEndRangeX)+1,1E20)
											}
										}
										Else {
											Set tSeg($I(tSeg)) = $LB($$$HTOSEC(tStartRangeX),$$$HTOSEC(tEndRangeX))
										}
									} // next jk
									
									// fold segments into list for this AND leg
									If ('tHasSegs) {
										If $D(tSeg) {
											Merge tSegList = tSeg
											Set tHasSegs = 1
										}
									}
									Else {
										// fold all combinations of segments
										Kill tFoldedSegs
										Set sg1 = $O(tSegList(""))
										While (sg1'="") {
											Set sg2 = $O(tSeg(""))
											While (sg2'="") {
												// recompute each time!
												Set tStart1 = +$LG(tSegList(sg1),1)
												Set tEnd1 = +$LG(tSegList(sg1),2)
												Set tStart2 = +$LG(tSeg(sg2),1)
												Set tEnd2 = +$LG(tSeg(sg2),2)
												If ((tStart1>tEnd2)||(tStart2>tEnd1)) {
													// no overlap: ignore
												}
												Else {
													// intersect segments; add to output
													Set fs = $S(tStart1>tStart2:tStart1,1:tStart2)
													Set fe = $S(tEnd1<tEnd2:tEnd1,1:tEnd2)
													Set tFoldedSegs($I(tFoldedSegs)) = $LB(fs,fe)
												}
												Set sg2 = $O(tSeg(sg2))
											}
											Set sg1 = $O(tSegList(sg1))
										}
										// merge folded segs into seg list
										Kill tSegList
										Merge tSegList = tFoldedSegs
									}
								}
								// next level
								Set tFLevel = $O(tLevelFact(tFLevel))
							}

							// Intersect all segments in the SegList with the branch segments
							// fold segments into list for this OR brancg
							If ('tHasSegsB) {
								If $D(tSegList) {
									Merge tSegListB = tSegList
									Set tHasSegsB = 1
								}
							}
							Else {
								If $D(tSegList) {
									// fold all combinations of segments
									Kill tFoldedSegs
									Set sg1 = $O(tSegListB(""))
									While (sg1'="") {
										Set sg2 = $O(tSegList(""))
										While (sg2'="") {
											// recompute each time!
											Set tStart1 = +$LG(tSegListB(sg1),1)
											Set tEnd1 = +$LG(tSegListB(sg1),2)
											Set tStart2 = +$LG(tSegList(sg2),1)
											Set tEnd2 = +$LG(tSegList(sg2),2)
											If ((tStart1>tEnd2)||(tStart2>tEnd1)) {
												// no overlap: ignore
											}
											Else {
												// intersect segments; add to output
												Set fs = $S(tStart1>tStart2:tStart1,1:tStart2)
												Set fe = $S(tEnd1<tEnd2:tEnd1,1:tEnd2)
												Set tFoldedSegs($I(tFoldedSegs)) = $LB(fs,fe)
											}
											Set sg2 = $O(tSegList(sg2))
										}
										Set sg1 = $O(tSegListB(sg1))
									}
									// merge folded segs into branch seg list
									Kill tSegListB
									Merge tSegListB = tFoldedSegs
								}
							}
							Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,tTestMbrNo))
						}
						// If this branch is not restrictive then we cannot use member restriction
						If ('tIsRestrictive) {
							// abort
							Set tIsRestricted = 0
							Kill tSegments
							Kill tSegListB
							Kill tSlicerBranches
							Kill tExcludeNullMember		// DTB660 - Also clear the null exclusion
						}

						// fold branch segments into master list
						If ('$D(tSegments)) {
							// merge into final list
							Set k = $O(tSegListB(""))
							While (k'="") {
								Set tSegments($I(tSegments)) = tSegListB(k)
								Kill tSegListB(k)
								Set k = $O(tSegListB(k))
							}
						}
						Else {
							// fold all combinations of segments
							Set sg1 = $O(tSegListB(""))
							While (sg1'="") {
								Set tOverlap = 0
								Set sg2 = $O(tSegments(""))
								While ((sg2'="")&&($D(tSegListB(sg1)))) {
									Set tStart1 = +$LG(tSegListB(sg1),1)
									Set tEnd1 = +$LG(tSegListB(sg1),2)
									Set tStart2 = +$LG(tSegments(sg2),1)
									Set tEnd2 = +$LG(tSegments(sg2),2)

									If (((tStart1<=(tEnd2+1))&&((tEnd1+1)>=tStart2))||((tStart2<=(tEnd1+1))&&((tEnd2+1)>=tStart1))) {
										// overlap: combine segments
										Set $List(tSegments(sg2),1) = $S(tStart1<tStart2:tStart1,1:tStart2)
										Set $List(tSegments(sg2),2) = $S(tEnd1>tEnd2:tEnd1,1:tEnd2)
										Set tOverlap = 1
										Kill tSegList(sg1)
									}
									Set sg2 = $O(tSegments(sg2))
								}

								If ('tOverlap) {
									// no overlap found: add segment to list
									Set tSegments($I(tSegments)) = tSegListB(sg1)
									Kill tSegListB(sg1)
								}
								Set sg1 = $O(tSegListB(sg1))
							}
						}

						// next branch
						Set tTestBranchNo = $O(tSlicerBranches(tTestBranchNo))
					}
					
					// final test: check if any final segments overlap
					Set sg1 = $O(tSegments(""))
					While (sg1'="") {
						Set sg2 = $O(tSegments(sg1))
						While (sg2'="") {
							If tIsPartial {
								// DTB688 - Use non-numeric comparison operators
								Set tStart1 = $LG(tSegments(sg1),1)
								Set tEnd1 = $LG(tSegments(sg1),2)
								Set tStart2 = $LG(tSegments(sg2),1)
								Set tEnd2 = $LG(tSegments(sg2),2)
							
								If (((tEnd2]]tStart1)&&(tEnd1]]tStart2))||((tEnd1]]tStart2)&&(tEnd2]]tStart1))) {
									// overlap: combine segments
									Set $List(tSegments(sg1),1) = $S(tStart2]]tStart1:tStart1,1:tStart2)
									Set $List(tSegments(sg1),2) = $S(tEnd1]]tEnd2:tEnd1,1:tEnd2)
									Kill tSegments(sg2)
								}
							}
							Else {
								Set tStart1 = +$LG(tSegments(sg1),1)
								Set tEnd1 = +$LG(tSegments(sg1),2)
								Set tStart2 = +$LG(tSegments(sg2),1)
								Set tEnd2 = +$LG(tSegments(sg2),2)
								
								If (((tStart1<=(tEnd2+1))&&((tEnd1+1)>=tStart2))||((tStart2<=(tEnd1+1))&&((tEnd2+1)>=tStart1))) {
									// overlap: combine segments
									Set $List(tSegments(sg1),1) = $S(tStart1<tStart2:tStart1,1:tStart2)
									Set $List(tSegments(sg1),2) = $S(tEnd1>tEnd2:tEnd1,1:tEnd2)
									Kill tSegments(sg2)
								}
							}
							Set sg2 = $O(tSegments(sg2))
						}
						Set sg1 = $O(tSegments(sg1))
					}

					// If all segments have been removed, create an empty segment
					If (tIsRestricted&&('$D(tSegments))) {
						Set tSegments(0) = $LB("","")
					}
				}

				// JMD947: test for dependsOn index
				// tDependsOn(masterFactNo) = ""
				Merge tDependsOn = $$$DeepSeeMetaGLVN("cubes",tCubeIndex,"levelDepends",pDimNo,pHierNo,pLevelNo)
				If $D(tDependsOn) {
					Kill tDepMembers

					// fetch slicer branches again as we may have kill them!
					If ($IsObject($G(%query)) && ('$D(tSlicerBranches))) {
						Set tSC = %query.%ProcessSlicerRestrictions(.tSlicerBranches,.tNoData)
						If $$$ISERR(tSC) Quit
					}
					// tSlicerBranches(branch,mbr) = $LB(Fact,Key)
					Set tTestBranchNo = $O(tSlicerBranches(""))
					While(tTestBranchNo'="") {
						Set bc = 0
						Kill tDepMembersB
						Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,""))
						While(tTestMbrNo'="") {
							Set tTestFact = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),1)
							If ($D(tDependsOn(tTestFact))) {
								Set tTestId = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),2)
								// find set of fact values for this dependent level
								Set tSC = ##class(%DeepSee.Query.Engine).%FindDependentMembers(pCubeName,.tDepMembersB,tFact,tTestFact,tTestId,$I(bc))
								If $$$ISERR(tSC) Quit
							}
							If $$$ISERR(tSC) Quit
							Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,tTestMbrNo))
						}
						Merge tDepMembers = tDepMembersB
						If $$$ISERR(tSC) Quit
						Set tTestBranchNo = $O(tSlicerBranches(tTestBranchNo))
					}
				}
				If $$$ISERR(tSC) Quit
			}

			Set tStartRange = ""
			Set tEndRange = ""

			If ($D(pRange)) {
				// JMD1301: range uses keys not values
				//Set tRangeKey1 = $classmethod(tLevelClass,"%ValueToKey",$G(pRange(1)),tTimeFormat,tTimeOffset)
				//Set tRangeKey2 = $classmethod(tLevelClass,"%ValueToKey",$G(pRange(2)),tTimeFormat,tTimeOffset)
				Set tRangeKey1 = $G(pRange(1))
				Set tRangeKey2 = $G(pRange(2))

				// convert range to base type
				Set tSC = $classmethod(tLevelClass,"%KeyToBaseRange",tRangeKey1,.tStartRange,.tDummy,tTimeOffset)
				If $$$ISERR(tSC) Quit
				Set tSC = $classmethod(tLevelClass,"%KeyToBaseRange",tRangeKey2,.tDummy,.tEndRange,tTimeOffset)
				If $$$ISERR(tSC) Quit
				
			}
			If (pRollupKey '= "") {
				// restrict against higher level
				Set tExists2 = ..%GetNodeInfo(pCubeName,pDimNo, pHierNo, pLevelNo - 1, .tFact2, .tLevelClass2)
				If (tExists2 && (tLevelClass2 '= "")) {
					Set tTimeOffset2 = ..%GetTimeOffset(pCubeName,pDimNo, pHierNo, pLevelNo - 1)
					Set tSC = $classmethod(tLevelClass2,"%KeyToBaseRange",pRollupKey,.tStartRange2,.tEndRange2,tTimeOffset2)
					If $$$ISERR(tSC) Quit
				}
				Set tStartRange = $S(tStartRange="":tStartRange2,(+tStartRange>+tStartRange2):tStartRange,1:tStartRange2)
				Set tEndRange = $S(tEndRange="":tEndRange2,(+tEndRange<+tEndRange2):tEndRange,1:tEndRange2)
			}
			ElseIf ($D(%memberContext)) {
				// apply memberContext: $LB(level,key)
				// restrict against higher level
				If ($LG(%memberContext,1)>0) {
					Set tExists2 = ..%GetNodeInfo(pCubeName,pDimNo, pHierNo, $LG(%memberContext,1), .tFact2, .tLevelClass2)
					If (tExists2 && (tLevelClass2 '= "")) {
						Set tTimeOffset2 = ..%GetTimeOffset(pCubeName,pDimNo, pHierNo, $LG(%memberContext,1))
						Set tSC = $zobjclassmethod(tLevelClass2,"%KeyToBaseRange",$LG(%memberContext,2),.tStartRange2,.tEndRange2,tTimeOffset2)
						If $$$ISERR(tSC) Quit

						Set tStartRange = $S(tStartRange="":tStartRange2,(+tStartRange>+tStartRange2):tStartRange,1:tStartRange2)
						Set tEndRange = $S(tEndRange="":tEndRange2,(+tEndRange<+tEndRange2):tEndRange,1:tEndRange2)
					}
				}
			}

			Set tStartRangeH = $S(tStartRange="":"",1:$$$HTOSEC(tStartRange))
			Set tEndRangeH = $S(tEndRange="":1E20,1:$$$HTOSEC(tEndRange))

			// JMD1209: test for independent level
			// Ignore higher level segments in this case
			Set tIsIndependent = $classmethod(tLevelClass,"%IsIndependent")

			If ('$D(tSegments)||tIsIndependent) {
				// put range into tSegments structure
				Set tSegments(0) = $LB(tStartRangeH,tEndRangeH)
			}
			ElseIf ((tStartRange'="")||(tEndRange'="")) {
				// intersect additional range against segments
				Set k = $O(tSegments(""))
				While (k'="") {
					Set tStart1 = +$LG(tSegments(k),1)
					Set tEnd1 = +$LG(tSegments(k),2)
					Set tStart2 = +tStartRangeH
					Set tEnd2 = +tEndRangeH
					If ((tStart1>tEnd2)||(tStart2>tEnd1)) {
						// no overlap: remove
						Kill tSegments(k)
					}
					Else {
						// intersect segments
						Set fs = $S(tStart1>tStart2:tStart1,1:tStart2)
						Set fe = $S(tEnd1<tEnd2:tEnd1,1:tEnd2)
						Set tSegments(k) = $LB(fs,fe)
					}
					Set k = $O(tSegments(k))
				}
			}

			// Sort segments by start time
			Kill tSortedSegments
			Set k = $O(tSegments(""))
			While (k'="") {
				// DTB688 - We cannot use the + operator on partial keys
				If tIsPartial&&($LG(tSegments(k),1)'="") {
					Set tStartT = $LG(tSegments(k),1)
				}
				Else {
					Set tStartT = +$LG(tSegments(k),1)
				}
				
				Set tSortedSegments(tStartT) = tSegments(k)
				Set k = $O(tSegments(k))
			}
			Kill tSegments

			If (+tHasMemberList) {
				// use member list
				Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeIndex,.tSC)
				If $$$ISERR(tSC) Quit

				Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",""),1,data)
				While (p'="") {
					Set tItemName = $LG(data,1)
					Set tItemSpec = $LG(data,2)
					Set tItemDescription = $LG(data,4)		// DTB219

					If (tItemSpec'="") {
						Set tItem = tItemSpec
					}
					Else {
						Set tItem = tItemName
					}
					// JMD1010: find caption
					Set tItemCaption = ""
					If (tCubeClass'="") {
						Set tItemCaption = $classmethod(tCubeClass,"%GetLevelMemberCaption",pDimNo,pHierNo,pLevelNo,tItemName)
					}
					Set:tItemCaption="" tItemCaption = tItemName

					If (tItem '= "") {
						If ($E(tItem,1,2)="&[") { // key
							Set tID = $E(tItem,3,$L(tItem)-1)
						}
						Else {
							Set tID = $zobjclassmethod(tLevelClass,"%ValueToKey",tItem,tTimeFormat,tTimeOffset)
						}
						Set tNode = $LB("mbr",1,1,pParent,tItemCaption,tID,tFact,,pDimNo,pHierNo,pLevelNo,,tID)
						If tItemDescription'="" {
							// DTB219 - Insert member description
							Set $LI(tNode,23) = tItemDescription
						}
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
						Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
						Set leaf = $I(%leafCount)
						If (pRecurse > 0) {
							// n.b., do not pass range up
							Set tSC = ..%GetMembers(pCubeName,pDimNo, pHierNo, pLevelNo + 1,tID, pParent,pKey,.pNodeNo,1)
							Quit:$$$ISERR(tSC)
						}
					}
					Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",p),1,data)
				}
				Quit // done
			}

			// for each segment, find members within range
			Kill tList
			Set k = $O(tSortedSegments(""))
			While (k'="") {
				// DTB688 - Note: These are no longer always $H values! Partial dates use a ODBC-style format
				Set tStartTimeH = $LG(tSortedSegments(k),1)
				Set tEndTimeH = $LG(tSortedSegments(k),2)
				If ((tStartTimeH'="")||((tEndTimeH'=""))) {
					If tIsPartial {
						// DTB688 - Use the tranformation functions to find start and end points based on actual data
						If (+tStartTimeH<=0) {
							Do $ClassMethod(tLevelClass,"%GetNthKey",.tStartTimeH,pCubeName,tFact,"first")
							Do $ClassMethod(tLevelClass,"%KeyToBaseRange",tStartTimeH,.tStartRange)
						}
						Else {
							Set tStartRange = tStartTimeH
						}

						If (tEndTimeH=1E20) {
							Do $ClassMethod(tLevelClass,"%GetNthKey",.tEndTimeH,pCubeName,tFact,"last")
							Do $ClassMethod(tLevelClass,"%KeyToBaseRange",tEndTimeH,.x,.tEndRange)
						}
						Else {
							Set tEndRange = tEndTimeH
						}
					}
					Else {
						Set tStartRange = $S(+tStartTimeH=0:"",1:$$$SECTOH(tStartTimeH))
						Set tEndRange = $S(tEndTimeH="":"",+tEndTimeH=0:"",tEndTimeH=1E20:"",tEndTimeH["-":$$$SECTOH(tEndTimeH),1:$$$SECTOH(tEndTimeH-1))
					}
					
					Kill tList2
					If ((tStartRange="")||(tEndRange="")) {
						// dispatch directly to get all
						Set tSC = $classmethod(tLevelClass,"%GetAllMembers",.tList2,pCubeName,tFact,tStartRange,tEndRange,tTimeFormat)
						If $$$ISERR(tSC) Quit
						// + WAL091 -- If some other level in this hierarchy has excluded the null member (empty values)
						//             remove it from the list returned by %GetAllMembers
						If $G(tExcludeNullMember,0) {
							If ( $D(tList2)&&($LG(tList2(1),1)=$$$DeepSeeNullMarker) ) {		// DTB528 - Protect the $LG from an empty tList2
								Kill tList2(1)	
							}
						}
						// - WAL091
					}
					Else {
						Set tSC = $classmethod(tLevelClass,"%GetLevelMembers",.tList2,pCubeName,tFact,tStartRange,tEndRange,tTimeOffset,tTimeFormat)
						If $$$ISERR(tSC) Quit
					}
					// copy into list
					If $D(tList) {
						Set tx = $O(tList(""),-1)
						Set t2 = $O(tList2(""))
						While (t2'="") {
							Set tList($I(tx)) = tList2(t2)
							Set t2 = $O(tList2(t2))
						}
					}
					Else {
						Merge tList = tList2
					}
				}
				Set k = $O(tSortedSegments(k))
			}
			
			// sort
			Set tDirection = $Case(tSortDir,"desc":-1,"desc#":-1,:1)
			Set n = $O(tList(""),tDirection)
			Set nc=0
			
			If +$G(%dsIsSlicer)&&$D(pRange)&&('$D(tList)) {
				// DTB681 - If this is the slicer and there are no members in the index, return 1 member
				// from the requested range producing no results to make sure the slicer doesn't get 
				// converted to "no filter"
				Set tStartKey = $G(pRange(1))
				Set tStartValue = $Classmethod(tLevelClass,"%KeyToValue",tStartKey)
				Set tList(1) = $LB(tStartValue,tStartKey)
				Set n=1
				Set tNonEmpty = 0
			}
			
			While (n '= "") {
				Set tSkip = 0
				Set nc = nc + 1
				Set tID = $LG(tList(n),2)
				Set tValue = $LG(tList(n),1)

				// JMD910: test dependOn list
				If ((tID'="")&&$D(tDepMembers)) {
					Set tSkip = '$D(tDepMembers(tID))
				}

				// DP-421530 - Test the value (or %ID if no value) against the search key
				Set:($G(%dsMemberSearch)'="") tSkip = ($S((tValue'=""):tValue,1:tID) '[ %dsMemberSearch)

				If ('tSkip&&tNonEmpty) { // test intersection
					// test if there is data for this member
					If ((tFact'="")&&(tID'="")) {
						If ('##class(%DeepSee.Query.Engine).%IntersectExists(pCubeName,tFact,tID)) {		// DP-415899
							Set tSkip = 1
						}
					}
				}

				// test for duplicates
				If ('tSkip&&(tID'="")) {
					If $D(tDuplicate(tID)) {
						Set tSkip = 1
					}
					Else {
						Set tDuplicate(tID) = ""
					}
				}

				If ('tSkip) {
					Set tKey = tID
					If ($$$LOWER(tValue) = $$$DeepSeeNullMarker) {
						Set tValue = ..%GetNullName(pCubeName,pDimNo,pHierNo,pLevelNo,.tNullCaption)
						Set tKey = $$$DeepSeeNullMarker
					}

					Set tt = 1+$G(tt)
					Set tNode = $LB("mbr",1,1,pParent,tValue,tID,tFact,,pDimNo,pHierNo,pLevelNo,,tKey)
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					Set leaf = $I(%leafCount)
					If (pRecurse > 0) {
						// n.b., do not pass range up
						Set tSC = ..%GetMembers(pCubeName,pDimNo, pHierNo, pLevelNo + 1,tID, pParent,pKey,.pNodeNo,1)
						Quit:$$$ISERR(tSC)
					}
				}

				Set n = $O(tList(n),tDirection)
			}
		}

		// JMD871: if there are fact-sensitive optimizations in play, mark
		// the axis as needing a recompute
		If (tFactSensitive) {
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"recompute") = 1
		}

		// stats
		If ($D(%query)&&$D(%axisNo)) {
			Set %query.%Statistics("GetMembers "_%axisNo) = $G(%query.%Statistics("GetMembers "_%axisNo)) + ($ZH - tStart)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the nth child of the current member and place it into <var>pSet</var>.<br/>
/// Note that we ignore null values for time dimensions in this case.
ClassMethod %GetNthChild(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pParent As %Integer, Output pSet As %List, pKey As %String, pNumber As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tLevelClass, .tStarField, .tStarSort, .tRollup)
		Set tExistsC = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo+1, .tFactC, .tLevelClassC, .tStarFieldC, .tStarSortC, .tRollupC)

		Set tTimeOffset = ..%GetTimeOffset(pCubeName, pDimNo, pHierNo, pLevelNo)
		Set tTimeOffsetC = ..%GetTimeOffset(pCubeName, pDimNo, pHierNo, pLevelNo+1)

		// ask level class for details
		If (tExists && tExistsC && (tLevelClassC '= "")) {
			Set tRelation = $S(pNumber>0:"first",1:"last")
			Set tOffset = $S(pNumber>0:pNumber-1,1:-pNumber-1)

			// convert key to base type
			If (tLevelClass="") {
				// all level
				Set (tKey1,tKey2)=""
			}
			Else {
				Set tSC = $zobjclassmethod(tLevelClass,"%KeyToBaseRange",pKey,.tKey1,.tKey2,tTimeOffset)
				If $$$ISERR(tSC) Quit
			}

			// find key in new level
			Set tSC = $zobjclassmethod(tLevelClassC,"%BaseRangeToKey",.tKey,tKey1,tKey2,tTimeOffsetC)
			If $$$ISERR(tSC) Quit

			Set tSC = $zobjclassmethod(tLevelClassC,"%BaseRangeToKey",.tEndKey,tKey2,tKey2,tTimeOffsetC)
			If $$$ISERR(tSC) Quit

			Set tSC = $zobjclassmethod(tLevelClassC,"%GetRelatedKey",.tOffsetKey,pCubeName,tFactC,tKey,tRelation,tOffset,tEndKey,tTimeOffsetC)
			If $$$ISERR(tSC) Quit

			If (tOffsetKey '= "") {
				Set tValue = $zobjclassmethod(tLevelClassC,"%KeyToValue",tOffsetKey,,tTimeOffsetC)
				Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tValue,tOffsetKey,tFactC,,pDimNo,pHierNo,pLevelNo+1,,tOffsetKey)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get one member and place it into <var>pSet</var>.<br/>
/// <var>pKey</var>, is the key for the base member to return.</br>
/// <var>pRelation</var> indicates how this member is related to the base member.
/// "same","lead", "lag", etc.<br/>
/// <var>pOffset</var>, is an optional offset to apply to the relation.
/// Note that we ignore null values for time dimensions in this case.
ClassMethod %GetRelatedMember(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, Output pSet As %List, pKey As %String, pRelation As %String, pOffset As %Integer = 0, pValue As %String = "", pAllowMissing As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// JMD1510
		If (pKey=$$$DeepSeeNullTimeMarker)||($$$UPPER(pKey)="NO MEMBER") {
			// DTB166 - Add NO MEMBER test to preserve JMD1510 rules
			Quit
		}

		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tLevelClass, .tStarField, .tStarSort, .tRollup)
		Set tTimeOffset = ..%GetTimeOffset(pCubeName, pDimNo, pHierNo, pLevelNo,.tTimeFormat)

		// ask level class for details
		If (tExists && (tLevelClass '= "")) {

			// find relation
			Set tOffsetKey = ""
			If (pRelation = "same") {
				Set tOffsetKey = pKey
			}
			Else {
				Set tSC = $zobjclassmethod(tLevelClass,"%GetRelatedKey",.tOffsetKey,pCubeName,tFact,pKey,pRelation,pOffset,,tTimeOffset)
				If $$$ISERR(tSC) Quit
			}

			// JMD1510
			If (tOffsetKey'="") {
				// convert key to base type
				Set tSC = $zobjclassmethod(tLevelClass,"%KeyToBaseRange",tOffsetKey,.tKey,.tDummy,tTimeOffset)
				If $$$ISERR(tSC) Quit

				Set tSC = $zobjclassmethod(tLevelClass,"%GetLevelMembers",.tList,pCubeName,tFact,tKey,tKey,tTimeOffset,tTimeFormat)
				If $$$ISERR(tSC) Quit

				Set n = $O(tList(""))
				While (n '= "") {
					Set tID = $LG(tList(n),2)
					Set tValue = $LG(tList(n),1)
					Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tValue,tID,tFact,,pDimNo,pHierNo,pLevelNo,,tID)
					Set n = $O(tList(n))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the parent of the current member and place it into <var>pSet</var>.<br/>
ClassMethod %GetParentMember(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pParent As %Integer, Output pSet As %List, pKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pLevelNo = 1) Quit

		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tLevelClass, .tStarField, .tStarSort, .tRollup, .tSortDir)
		Set tExistsP = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo-1, .tFactP, .tLevelClassP, .tStarFieldP, .tStarSortP, .tRollupP, .tSortDirP)

		// test if parent is the ALL level
		If (pLevelNo = 2) {
			Set tAllName = ..%GetAllName(pCubeName,pDimNo,.tAllCaption)
			If (tAllName '= "") {
				Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tAllCaption,"",tFactP,,pDimNo,pHierNo,pLevelNo-1,,"")
				Quit
			}
		}

		// ask level class for details
		If (tExists && tExistsP && (tLevelClass '= "")&& (tLevelClassP '= "")) {
			Set tTimeOffset = ..%GetTimeOffset(pCubeName, pDimNo, pHierNo, pLevelNo)
			Set tTimeOffsetP = ..%GetTimeOffset(pCubeName, pDimNo, pHierNo, pLevelNo-1,.tFormatP)

			If ($$$LOWER(pKey) = $$$DeepSeeNullMarker) {
				Set tValue = ..%GetNullName(pCubeName,pDimNo,pHierNo,pLevelNo-1,.tNullCaption)
				Set tID = $$$DeepSeeNullTimeMarker
			}
			Else {
				// convert key to base type
				Set tSC = $zobjclassmethod(tLevelClass,"%KeyToBaseRange",pKey,.tKey1,.tKey2,tTimeOffset)
				If $$$ISERR(tSC) Quit

				// find parent key within range
				Set tSC = $zobjclassmethod(tLevelClassP,"%BaseRangeToKey",.tKey,tKey1,tKey2,tTimeOffsetP)
				If $$$ISERR(tSC) Quit

				Set tValue = $zobjclassmethod(tLevelClassP,"%KeyToValue",tKey,tFormatP,tTimeOffsetP)
				Set tID = tKey
			}

			Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tValue,tID,tFactP,,pDimNo,pHierNo,pLevelNo-1,,tID)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the ordinal position of this member within its parent group.
/// For convenience, also return the parent key for this member.
Method %GetMemberOffset(Output pOffset As %Integer, pKey As %String, Output pParentKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pOffset = ""
		Set tSC = ..%GetParentMember(..%cube,..%dimNumber,..%hierNumber,..%levelNumber, -1,.tSet,pKey)
		If $$$ISERR(tSC) Quit

		// get parent key
		Set pParentKey = $LG($G(tSet(1)),6)

		Set tExistsP = ..%GetNodeInfo(..%cube,..%dimNumber,..%hierNumber,..%levelNumber-1, .tFactP, .tLevelClassP, .tStarFieldP, .tStarSortP, .tRollupP)
		Set tExistsC = ..%GetNodeInfo(..%cube,..%dimNumber,..%hierNumber,..%levelNumber, .tFactC, .tLevelClassC, .tStarFieldC, .tStarSortC, .tRollupC)

		// ask level class for details
		If (tExistsC && (tLevelClassC '= "")) {
			Set tTimeOffsetP = ..%GetTimeOffset(..%cube,..%dimNumber,..%hierNumber,..%levelNumber-1)
			Set tTimeOffsetC = ..%GetTimeOffset(..%cube,..%dimNumber,..%hierNumber,..%levelNumber,.tTimeFormatC)

			// convert parent key to base type
			Set tStartRange = ""
			Set tEndRange = ""
			If (tExistsP && (tLevelClassP'="")) {
				If ($zobjclassmethod(tLevelClassP,"%IsA","%DeepSee.Time.AbstractLevel")) {
					Set tSC = $zobjclassmethod(tLevelClassP,"%KeyToBaseRange",pParentKey,.tStartRange,.tEndRange,tTimeOffsetP)
					If $$$ISERR(tSC) Quit
				}
			}

			Kill tList
			Set tSC = $zobjclassmethod(tLevelClassC,"%GetLevelMembers",.tList,..%cube,tFactC,tStartRange,tEndRange,tTimeOffsetC,tTimeFormatC)
			If $$$ISERR(tSC) Quit

			// now find *this* member in the list
			Set n = 0
			Set k = $O(tList(""))
			While (k '= "") {
				If (pKey = $LG($G(tList(k)),2)) {
					Set pOffset = n
					Quit
				}
				Set n = n + 1
				Set k = $O(tList(k))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if this member supports the given feature.
/// For example, "NOW".
ClassMethod %HasFeature(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pFeature As %String) As %Boolean
{
	If (pFeature="NOW") {
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tLevelClass)
		If (tExists) {
			Quit $zobjclassmethod(tLevelClass,"%SupportsNOW")
		}
	}
	Quit 0
}

/// Find the time level class for the given level.
Method %GetLevelClass(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, Output pLevelClass As %String) As %Status
{
	Set tSC = $$$OK
	Set pLevelClass = ""
	Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tLevelClass)
	If (tExists) {
		Set pLevelClass = tLevelClass
	}
	Quit tSC
}

/// Find the range of time between a starting and ending member.
ClassMethod %GetBaseRange(pStartMember As %DeepSee.Query.memberTime, pEndMember As %DeepSee.Query.memberTime, Output pStartTime As %Date, Output pEndTime As %Date) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tExists1 = ..%GetNodeInfo(pEndMember.%cube,pStartMember.%dimNumber,pStartMember.%hierNumber,pStartMember.%levelNumber, .tFact1, .tLevelClass1)
		If (tExists1 && (tLevelClass1 '= "")) {
			Set tTimeOffset1 = ..%GetTimeOffset(pStartMember.%cube,pStartMember.%dimNumber,pStartMember.%hierNumber,pStartMember.%levelNumber)
			Set tSC = $zobjclassmethod(tLevelClass1,"%KeyToBaseRange",pStartMember.%memberKey,.tStartRange1,.tEndRange1,tTimeOffset1)
			If $$$ISERR(tSC) Quit
		}

		Set tExists2 = ..%GetNodeInfo(pEndMember.%cube,pEndMember.%dimNumber,pEndMember.%hierNumber,pEndMember.%levelNumber, .tFact2, .tLevelClass2)
		If (tExists2 && (tLevelClass2 '= "")) {
			Set tTimeOffset2 = ..%GetTimeOffset(pEndMember.%cube,pEndMember.%dimNumber,pEndMember.%hierNumber,pEndMember.%levelNumber)
			Set tSC = $zobjclassmethod(tLevelClass2,"%KeyToBaseRange",pEndMember.%memberKey,.tStartRange2,.tEndRange2,tTimeOffset2)
			If $$$ISERR(tSC) Quit
		}

		Set pStartTime = tStartRange1
		Set pEndTime = tEndRange2
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return a set of member keys within the given time window (for %TimeWindow).
/// Return a list of $LB(levelNo,key)
Method %GetMembersInWindow(pStartTime As %Date, pEndTime As %Date, Output pMemberList) As %Status
{
#define HTOSEC(%h) (+(%h)*86400)+($P((%h),",",2))

	Set tSC = $$$OK
	Try {
		Set tExistsP = ..%GetNodeInfo(..%cube,..%dimNumber,..%hierNumber,..%levelNumber-1, .tFactP, .tLevelClassP)
		Set tExists = ..%GetNodeInfo(..%cube,..%dimNumber,..%hierNumber,..%levelNumber, .tFact, .tLevelClass)

		Set tStartSecs = $$$HTOSEC(pStartTime)
		Set tEndSecs = $$$HTOSEC(pEndTime)+86399

		// find parent level members for the range
		If (tExistsP && (tLevelClassP'="")) {
			Set tTimeOffsetP = ..%GetTimeOffset(..%cube,..%dimNumber,..%hierNumber,..%levelNumber-1,.tTimeFormatP)
			Set tSC = $zobjclassmethod(tLevelClassP,"%GetLevelMembers",.tListP,..%cube,tFactP,pStartTime,pEndTime,tTimeOffsetP,tTimeFormatP)
			If $$$ISERR(tSC) Quit

			// find set of parent members that are completely in range
			Set p = $O(tListP(""))
			While (p'="") {
				Set tSC = $zobjclassmethod(tLevelClassP,"%KeyToBaseRange",$LG(tListP(p),2),.tStartRangeP,.tEndRangeP,tTimeOffsetP)
				If $$$ISERR(tSC) Quit

				If (($$$HTOSEC(tStartRangeP)>=tStartSecs)&&(($$$HTOSEC(tEndRangeP)+86399)<=tEndSecs)) {
					Set tParentKeys($$$HTOSEC(tStartRangeP)) = $LB($LG(tListP(p),2),$$$HTOSEC(tStartRangeP),$$$HTOSEC(tEndRangeP)+86399)
				}
				Set p = $O(tListP(p))
			}
		}
		
		Kill tListP

		// find members in the range
		Set tTimeOffset = ..%GetTimeOffset(..%cube,..%dimNumber,..%hierNumber,..%levelNumber,.tTimeFormat)
		Set tSC = $zobjclassmethod(tLevelClass,"%GetLevelMembers",.tList,..%cube,tFact,pStartTime,pEndTime,tTimeOffset,tTimeFormat)
		If $$$ISERR(tSC) Quit

		// find set of members not covered by parent keys
		Set m = $O(tList(""))
		While (m'="") {
			Set tSC = $zobjclassmethod(tLevelClass,"%KeyToBaseRange",$LG(tList(m),2),.tStartRange,.tEndRange,tTimeOffset)
			If $$$ISERR(tSC) Quit

			Set tCovered = 0
			Set p = $O(tParentKeys(""))
			While (p'="") {
				Set tParentStart = $LG(tParentKeys(p),2)
				Set tParentEnd = $LG(tParentKeys(p),3)
				If (($$$HTOSEC(tStartRange)>=tParentStart)&&(($$$HTOSEC(tEndRange)+86399)<=tParentEnd)) {
					Set tCovered = 1
					Quit
				}
				Set p = $O(tParentKeys(p))
			}
			If ('tCovered) {
				Set tChildKeys($$$HTOSEC(tStartRange)) = $LG(tList(m),2)
			}
			Set m = $O(tList(m))
		}

		Kill tList

		// copy keys over (sorted by time)
		Set k = $O(tChildKeys(""))
		While (k'="") {
			Set pMemberList(k) = $LB(..%levelNumber,tChildKeys(k))
			Set k = $O(tChildKeys(k))
		}
		Set k = $O(tParentKeys(""))
		While (k'="") {
			Set pMemberList(k) = $LB(..%levelNumber-1,$LG(tParentKeys(k),1))
			Set k = $O(tParentKeys(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
