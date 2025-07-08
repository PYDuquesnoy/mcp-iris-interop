/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized version of the member class used for data dimensions.
Class %DeepSee.Query.memberData Extends %DeepSee.Query.member [ System = 3 ]
{

/// See if there is a member with the given name within the specified
/// dimension,hierarchy, and/or level.<br/>
/// If <var>pLevel</var> is supplied, only look in that level.<br/>
/// Set <var>pFlag</var> true if a member is found.<br/>
/// On return, fills in memberSpec<br/>
/// 	memberSpec(level) = $LB(name,key)<br/>
/// 	<br/>
/// memberSpec(0) = $LB("All Time")<br/>
/// memberSpec(1) = $LB(2006,2006)<br/>
/// memberSpec(2) = $LB("Quarter 1", "Q1 2006")<br/>
/// memberSpec(3) = $LB("January","Jan 2006")<br/>
/// 
Method %FindMemberByName(pName As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, pLevel As %Integer = "", Output pMemberKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
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
			Set tExists = ..%GetNodeInfo(..%cube,pDim, pHier, tLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList,.tStarKeyField)

			If ('tExists) {
				Quit
			}
			If (tStarKeyField="") {
				Set tStarKeyField = "%ID"
			}
			If (tStarField="") {
				Set tStarField = "%ID"
			}
			
			Set tStarTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
			If (tStarTable = "") {
				Set tSC = $$$ERROR($$$GeneralError,"%FindMemberByName: Dimension table missing or not found: '" _ tStarClass _ "'")
				Quit
			}

			// test for null marker
			Set tName = pName
			Set tIsNull = 0
			Set tNullName = ..%GetNullName(..%cube,pDim,pHier,tLevelNo,.tNullCaption)
			If ($$$UPPER(tName) = $$$UPPER(tNullName)) {
				Set tName = $$$DeepSeeNullMarker
				Set tIsNull = 1
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
						Set tID = ""
						// find ID for this key
						Set tSQL = "SELECT TOP 1 %ID FROM " _ tStarTable _ " WHERE " _ tStarKeyField _ "=?"
						Set tRS = ##class(%ResultSet).%New()
						Set tSC = tRS.Prepare(tSQL)
						If $$$ISERR(tSC) Quit

						Set tSC = tRS.Execute(tKey)
						If $$$ISERR(tSC) Quit

						While (tRS.Next()) {
							Set tID = tRS.GetData(1)
						}

						Set tItemCaption = $classmethod(tCubeClass,"%GetLevelMemberCaption",pDim,pHier,tLevelNo,tItemName)
						Set:tItemCaption="" tItemCaption=tItemName
						Set ..%memberSpec(tLevelNo) = $LB(tItemCaption,tID,tKey)
						Set pMemberKey = tID
						Set pFlag = 1
						Quit
					}
					Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDim,pHier,tLevelNo,"mbr",p),1,data)
				}
				If (pFlag) Quit
			}

			If (tIsNull && (tStarKeyField'="%ID")) {
				Set tSQL = "SELECT TOP 1 %ID,"_tStarKeyField_" MKEY,"_tStarField_" FROM " _ tStarTable _ " WHERE " _ tStarKeyField _ "=?"
			}
			Else {
				Set tSQL = "SELECT TOP 1 %ID,"_tStarKeyField_" MKEY,"_tStarField_" FROM " _ tStarTable _ " WHERE " _ tStarField _ "=?"
			}

			// If there is a rollup & we have information about the higher level,
			// then restrict by it
			If (tRollup'="") {
				Set rl = $O(tRollTest(""))
				While (rl '= "") {
					Set $LI(tRollTest(rl),1) = tRollup_"->"_$LG(tRollTest(rl),1)
					Set rl = $O(tRollTest(rl))
				}
				Set tRollKey = $LG($G(..%memberSpec(tLevelNo-1)),2)
				If (tRollKey '= "") {
					Set tRollTest(tLevelNo) = $LB(tRollup, tRollKey)
				}
				Set rl = $O(tRollTest(""))
				While (rl '= "") {
					Set tSQL = tSQL _ " AND " _ $LG(tRollTest(rl),1) _ "= '"_$LG(tRollTest(rl),2)_"'"
					Set rl = $O(tRollTest(rl))
				}
			}

			// if no sort defined, sort by display value
			If (tStarSort="") {
				Set tOrderBy = tStarField
			}
			Else {
				Set tOrderBy = ""
				For p = 1:1:$L(tStarSort,",") {
					Set s = $P(tStarSort,",",p)
					Set d = $P(tSortDir,",",p)
					Set tOrderBy = tOrderBy _ $S(tOrderBy="":"",1:",") _ s _ $S(d="desc":" desc",d="desc#":" desc",1:"")
				}
			}

			If (tOrderBy '= "") {
				Set tSQL = tSQL _ " ORDER BY " _ tOrderBy
			}

			// $$$DSWRITELN("%FindMemberByName: "_tSQL)
			Set tCubeIndex = $$$DeepSeeIndex(..%cube)
			Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",..%cube,tSQL,"%FindMemberByName")

			Set tRS = ##class(%ResultSet).%New()
			Set tSC = tRS.Prepare(tSQL)
			If $$$ISERR(tSC) Quit

			// Write "[",tName,"]",!

			Set tSC = tRS.Execute(tName)
			If $$$ISERR(tSC) Quit

			Set tFound = 0
			While (tRS.Next()) {
				Set tFound = 1
				Set tID = tRS.GetData(1)
				Set tKey = tRS.GetData(2)
				Set tValue = tRS.GetData(3)
				If (($$$LOWER(tKey) = $$$DeepSeeNullMarker)||($$$LOWER(tValue) = $$$DeepSeeNullMarker)) {
					Set tValue = tNullName
				}
				Set ..%memberSpec(tLevelNo) = $LB(tValue,tID,tKey)
				Set pMemberKey = tID
				Set pFlag = 1
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
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Find the member with the given key.
Method %FindMemberByKey(pKey As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, Output pMemberValue As %String, pRecurse As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
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
			Set tExists = ..%GetNodeInfo(..%cube,pDim, pHier, tLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,,.tStarKeyField)
			If ('tExists) {
				Quit
			}
			If (tStarKeyField="") {
				Set tStarKeyField = "%ID"
			}
			If (tStarField="") {
				Set tStarField = "%ID"
			}
			Set tStarTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
			If (tStarTable = "") {
				Set tSC = $$$ERROR($$$GeneralError,"%FindMemberByKey: Dimension table missing or not found: '" _ tStarClass _ "'")
				Quit
			}

			Set tSQL = "SELECT %ID,"_tStarField_" FROM " _ tStarTable _ " WHERE "_tStarKeyField_" =?"

			// No need for rollup test or order by

			// $$$DSWRITELN("%FindMemberByKey: "_tSQL)
			Set tCubeIndex = $$$DeepSeeIndex(..%cube)
			Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",..%cube,tSQL,"%FindMemberByKey")

			Set tRS = ##class(%ResultSet).%New()
			Set tSC = tRS.Prepare(tSQL)
			If $$$ISERR(tSC) Quit

			Set tSC = tRS.Execute(pKey)
			If $$$ISERR(tSC) Quit

			Set tFound = 0
			While (tRS.Next()) {
				Set tFound = 1
				Set tID = tRS.GetData(1)
				Set tValue = tRS.GetData(2)

				If ((tValue="")||($$$LOWER(tValue) = $$$DeepSeeNullMarker)) {
					Set tValue = ..%GetNullName(..%cube,pDim,pHier,tLevelNo,.tNullCaption)
				}
				Set ..%memberSpec(tLevelNo) = $LB(tValue,tID,pKey)
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
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Get members and place them into <var>pSet</var>.<br/>
ClassMethod %GetMembers(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, pKey As %String, ByRef pNodeNo As %Integer, pRecurse As %Integer = 0, ByRef pRange As %String, ByRef pMemberList) As %Status
{
	// n.b. This is a class method so that it can be
	// called by utilities outside the context of a query.
	Set tSC = $$$OK
	Try {
		Set tStart = $ZH
		Set tFlag = $zu(115,8,0)
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList,.tStarKeyField)
		If ('tExists) {
			// no level
			Quit
		}
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tFactSensitive = 0
		
		// n.b. we *could* check for <null> pRollupKey to make <null>.children fail
		// this would require a query against the dimension table to check for null

		// if true, try not to include members with no data (if possible)
		// if we do let empty members through, they will be removed later
		Set tNonEmpty = $S($IsObject($G(%axisObject))&&%axisObject.nonEmpty:1,1:0) || +$G(%reduce)		// DTB758 - Check %reduce
		Set tUseRestrictAlgorithm = 1
		Set tHasSlicer = ($G(%slicerKey)'="")
		Set tUseSlicerIndex = 0		// Default to using the original %Intersect algorithm

		// DP-421530 - Some pre-conditions are incompatible with and prohibit the %FIND approach. Evaluate the availability of this option.
		Set tSupportsSlicerIndex = 0			// Default to %FIND unavailable
		Set tSlicerIndexExists = $$$dsSlicerIndexExists(tCubeIndex,$S($G(%slicerKey)'="":%slicerKey,1:0))		// Note the presence of a slicer index that can be used to limit the member fetch

		Set tIsList = +$LG($G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDimNo,pHierNo,pLevelNo)),16)
		If (tIsList) {
			// List behavior between members disrupts the %FIND behavior and cannot be assumed NON EMPTY
			Set tNonEmpty = 0
			Set tSupportsSlicerIndex = 0
		}
		ElseIf (tHasMemberList) {
			// A custom member list is expected to be short, default to %Intersect
			Set tSupportsSlicerIndex = 0
		}
		ElseIf ($$$DeepSeeOptimizerGetFlag($$$memberFind) && tNonEmpty && tSlicerIndexExists && (tStarClass'="")) {
			// 
			Set tSupportsSlicerIndex = 1
		}

		// DP-425943 - Make a recommendation for %FIND versus %Intersect based on data characteristics
		If tSupportsSlicerIndex {
			Set tCubeChunkCount = $$$DeepSeeActiveChunk(tCubeIndex)
			Set tCacheSlot = 1

			// NB: The exact member count can take noticeable time for very large cubes
			Set tTargetMbrCount = $$$DeepSeeFastMbrCount(tStarClass)
			Set tSlicerTermCount = +$G($$$DeepSeeAxisGLVN(tCubeIndex,%slicerKey,"termCount"))
			Set tFactCount = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeIndex,.tSC)
			If $$$ISERR(tSC) Quit

			Set tCacheSlot = ""
			Set tChunk = ""
			Set tSlicerChunkCount = 0
			Set tSlicerBitCount = 0

			// Slicer bit counting
			For {
				Set tCacheSlot = $O($$$DeepSeeMaskGLVN(tCubeIndex,"slicer",tCacheSlot))
				Quit:(tCacheSlot="")

				For {
					Set tChunk = $O($$$DeepSeeMaskGLVN(tCubeIndex,"slicer",tCacheSlot,$G(%slicerKey,0),tChunk),1,bits)
					Quit:(tChunk="")

					// - for every bitcount that returns nonzero, accumulate that
					// - when complete, average the count/chunk using bitCount/chunkCount
					If (bits'="") {
						$$$dsBitCount(bits,1,tChunkCount)
						Do:tChunkCount $I(tSlicerChunkCount),$I(tSlicerBitCount,tChunkCount)
					}
				}
			}

			// DP-421530 - Make the decision regarding the expected advantage of choosing the %FIND algorithm ove rthe default %Intersect
			If $$$DeepSeeOptimizerGetFlag($$$memberFind)=1 {
				// If the user requests %FIND always be used, turn it on here.
				Set tUseSlicerIndex = 1
			}
			ElseIf ((5*$G(%dsMaxMembers)) < tTargetMbrCount) {
				// Small dimensions on the order of the max list requested should not take long to work through the entire list if need be
				// and it's likely not worth engaging %FIND
				If (tSlicerBitCount < $$$DeepSeeBitsPerChunk) {
					// %FIND excels at reducing the target table when the local slicer selection is sparse
					Set tUseSlicerIndex = 1
				}
				ElseIf (tSlicerTermCount > tCubeChunkCount) {
					// The slicer definition contains a significantly large number of terms that need to be worked through,
					// crossing N^2 complexity.
					Set tUseSlicerIndex = 1
				}
			}					
		}

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
					Quit:$$$ISERR(tSC)
				}
				Quit
			}
		}

		If (tStarKeyField="") {
			Set tStarKeyField = "%ID"
		}

		// JMD1475 is there a description?
		Set tDescProp = $zobjclassmethod(tStarClass,"%GetParameter","DESCRIPTIONPROPERTY")

		// JMD947
		Set tNoData = 0
		If ($IsObject($G(%query))) {
			Set tSC = %query.%ProcessSlicerRestrictions(.tSlicerBranches,.tNoData)
			If $$$ISERR(tSC) Quit
		}
		
		// DTB599 - In some contexts do not reduce the restriction, just clean it
		If '+$G(%reduce) {
			// DTB567
			Set tSC = ##class(%DeepSee.Query.Engine).%ReduceOrsInSlicer(.tSlicerBranches,tCubeIndex)
		}
		Else {
			Set tSC = ##class(%DeepSee.Query.Engine).%CleanBranchesForSlicer(.tSlicerBranches,tCubeIndex)
		}
		If $$$ISERR(tSC) Quit

		// JMD947.2: get information on all levels above this one
		Set tLevelFact(pLevelNo) = tFact
		Set tLevelKeyField(pLevelNo) = tStarKeyField
		Set tLevelRollup(pLevelNo) = tRollup
		For tFLevel = pLevelNo-1:-1:1 {
			Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, tFLevel, .tFactX, .tStarClassX, .tStarFieldX, .tStarSortX, .tRollupX, .tSortDirX,,.tHasMemberListX,.tStarKeyFieldX)
			If ('tExists) {
				Quit
			}
			If (tFactX'="") {
				Set tLevelFact(tFLevel) = tFactX
				Set tLevelKeyField(tFLevel) = tLevelRollup(tFLevel+1)_"->"_$S(tStarKeyFieldX="":"%ID",1:tStarKeyFieldX)
				Set:tRollupX'="" tLevelRollup(tFLevel) = tLevelRollup(tFLevel+1) _ "->" _ tRollupX
			}
		}

		// JMD1235: also get facts for any levels below this one
		Set tMaxLevel = pLevelNo
		For tFLevel2 = pLevelNo+1:1:999 {
			Set tExists2 = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, tFLevel2, .tFactX2)
			If ('tExists2) {
				Quit
			}
			If (tFactX2'="") {
				Set tMaxLevel = tFLevel2
				Set tLevelFact(tFLevel2) = tFactX2
			}
		}
		
		// JMD947.2: use SlicerBranches to create WHERE clause on star table
		// any facts from *this* hierarchy can be used
		Set tFILTER = ""
		Set tRestrictBySlicer = tNonEmpty||+$G(%dsRestrictBySlicer)

		// JMD955
		If (tRestrictBySlicer && tNoData) {
			Quit
		}
		
		If (tRestrictBySlicer) {
			// tSlicerBranches(branch,mbr) = $LB(Fact,Key)

			// count branches
			Set tBranchCount = 0
			Set tTestBranchNo = $O(tSlicerBranches(""))
			While(tTestBranchNo'="") {
				Set tBranchCount = tBranchCount + 1
				Set tTestBranchNo = $O(tSlicerBranches(tTestBranchNo))
			}

			Set tTestBranchNo = $O(tSlicerBranches(""))
			Set tOrBranchCount = 0
			While(tTestBranchNo'="") {
				Set tBFILTER = ""
				Set tOrBranchCount = tOrBranchCount+1		// DTB756
				// PFS027 - tIsRestrictive should be evaluated per OR branch instead of per item
				Set tIsRestrictive = 0
				Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,""))
				While(tTestMbrNo'="") {
					// Check if this OR branch restricts on any of *our* facts
					Set tTestFact = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),1)
					Set tTestKey = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),2)
					// JMD1235
					// find any slicer facts from *lower* levels in our same dimension
					// and replace them with a parent key
					Set tHasLowerLevelNot = 0
					Kill tReplacedKeys
					For tFLevel = pLevelNo+1:1:tMaxLevel {
						If (($G(tLevelFact(tFLevel))=tTestFact)&&(tTestKey'="NO MEMBER")) {
							// find parent fact at *our* level
							// deal with OR/NOT directives
							Set tTestKey2 = tTestKey
							Set kf = tTestKey2
							For jk = 1:1:$L(kf,"|") {
								Set tIsNot = 0
								Set kf2 = $P(kf,"|",jk)
								If ($E(kf2)="!") {
									// not
									Set kf2 = $E(kf2,2,*)
									Set tIsNot = 1
								}
								Set tFLevel2 = tFLevel
								While (tFLevel2>pLevelNo) {
									Kill tSet
									Set tSC = ..%GetParentMember(pCubeName, pDimNo, pHierNo, tFLevel2, 0, .tSet, kf2)
									If $$$ISERR(tSC) Quit
									Set tFLevel2=tFLevel2-1

									// use the id
									Set tk2 = $LG($G(tSet(1)),6)
									If ((tk2="")||(tk2="NO MEMBER")) {
										Set kf2 = ""
										Quit
									}
									Set kf2 = tk2
								}

								If (kf2'="") {
									// JMD1246: If there is a NOT, then do not apply restriction
									If (tIsNot) {
										Set tHasLowerLevelNot = 1
										Kill tReplacedKeys
										Quit
									}
									Else {
										Set tReplacedKeys(kf2) = ""
									}
								}
							}
							Quit
						}
					}
					If $$$ISERR(tSC) Quit

					If ($D(tReplacedKeys)) {
						// Use replacement keys
						Set tTestFact = tLevelFact(pLevelNo)
						Set tTestKey = ""
						Set k = $O(tReplacedKeys(""))
						While (k'="") {
							Set tTestKey = tTestKey _ $S(tTestKey="":"",1:"|") _ k
							Set k = $O(tReplacedKeys(k))
						}
					}
					// convert slicer restrictions to conditions
					If ('tHasLowerLevelNot) {
						Set tAndBranchCount = 0
						For tFLevel = pLevelNo:-1:1 {
							If ($G(tLevelFact(tFLevel))=tTestFact) {
								Set tFactSensitive = 1
								Set tIsRestrictive = 1
								Set tAndBranchCount = tAndBranchCount+1		// DTB756

								// AND keys in level
								Set tLFILTER = ""
								Set op = "="
								Set cnct = "AND"
								// Set kf = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),2)
								Set kf = tTestKey
								For jk = 1:1:$L(kf,"|") {
									Set kf2 = $P(kf,"|",jk)
									If ($E(kf2)="!") {
										// not
										Set kf2 = $E(kf2,2,*)
										Set op = "<>"
									}
									// DTB752 - Wrap each set of OR terms in ()
									Set tLFILTER = $S(($L(kf,"|")>1)&&(jk=1):"(",1:"") _ 
												tLFILTER_ $S(tLFILTER="":"",1:" "_cnct_" ") _"("_$S(tFLevel=pLevelNo:"%ID",1:tLevelRollup(tFLevel+1))_" "_op_" '"_$$$iscEscapeSQL(kf2)_"')" _ 
												$S(($L(kf,"|")>1)&&(jk=$L(kf,"|")):")",1:"")
									Set cnct = "OR"
								}
								If (tLFILTER'="") {
									// AND levels
									Set tBFILTER = tBFILTER _ $S(tBFILTER="":"",1:" AND ") _ tLFILTER
								}
							}
						}
						Set:(tAndBranchCount>1) tBFILTER = $$$dsAddParens(tBFILTER)		// DTB756 - Add parens if more than one AND operand
					}
					Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,tTestMbrNo))
				}
				// JSL4440 - move this code out of inner loop because we are interested in OR conditions not AND conditions
				// If this branch is not restrictive then we cannot use member restriction
				// branches are ORd together, so if one branch has no restrictions, then
				// we cannot restrict by another branch
				If ('tIsRestrictive && (tBranchCount>1)) { // JSL4440 - if we remove this, then able to restrict
					Set tBFILTER = ""
				}

				// OR branches
				Set:tBFILTER'="" tFILTER = tFILTER _ $S(tFILTER="":"",1:" OR ") _ $$$dsAddParens(tBFILTER)		// DTB756 - Add parens using macro

				Set tTestBranchNo = $O(tSlicerBranches(tTestBranchNo))
			}
			
			Set:(tOrBranchCount>1) tFILTER = $$$dsAddParens(tFILTER)		// DTB756 - Add parens if more than one OR operand
		}

		// If there is a member context, add it to the restrictions
		// this is set by CROSSJOIN of 2 sets from same hierarchy
		Set tMCFILTER = ""
		If ($D(%memberContext)) {
			Set tMCLevel = $LG(%memberContext,1)
			If (tMCLevel<pLevelNo) {
				Set tMCKey = $LG(%memberContext,2)
				Set tFactSensitive = 1

				// build WHERE clause for member context
				Set tMKeyField = tStarKeyField
				Set tMRollupField = tRollup

				For tFLevel = pLevelNo:-1:1 {
					If (tFLevel = tMCLevel) {
						If (tMKeyField'="") {
							Set tMCFILTER = "("_tMKeyField_" = '"_$$$iscEscapeSQL(tMCKey)_"')"
						}
						Quit
					}
					If (tRollup="") {
						Quit
					}
					// get field names for next level
					Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, tFLevel-1, .tFactX, .tStarClassX, .tStarFieldX, .tStarSortX, .tRollupX, .tSortDirX,,.tHasMemberListX,.tStarKeyFieldX)
					If ('tExists) {
						Quit
					}
					Set tMKeyField = tMRollupField
					Set tMRollupField = tMRollupField _ "->" _ tRollupX
				}
			}
		}

		// JMD947: test for dependsOn index
		// tDependsOn(masterFactNo) = ""
		Merge tDependsOn = $$$DeepSeeMetaGLVN("cubes",tCubeIndex,"levelDepends",pDimNo,pHierNo,pLevelNo)
		If $D(tDependsOn) {
			// DTB644 - Count number of dependsOn terms
			Set tDependsOnCount = 0
			Set tDepLevel = $O(tDependsOn(""))
			While tDepLevel {
				Set x = $I(tDependsOnCount)
				Set tDepLevel = $O(tDependsOn(tDepLevel))
			}

			Kill tDepMembers

			// fetch slicer branches again as we may have killed them!
			If ($IsObject($G(%query)) && ('$D(tSlicerBranches))) {
				Set tSC = %query.%ProcessSlicerRestrictions(.tSlicerBranches,.tNoData)
				If $$$ISERR(tSC) Quit
			}
			
			// DTB599 - In some contexts do not reduce the restriction, just clean it
			If '+$G(%reduce) {
				// DTB567
				Set tSC = ##class(%DeepSee.Query.Engine).%ReduceOrsInSlicer(.tSlicerBranches,tCubeIndex)
			}
			Else {
				Set tSC = ##class(%DeepSee.Query.Engine).%CleanBranchesForSlicer(.tSlicerBranches,tCubeIndex)
			}
			If $$$ISERR(tSC) Quit
			
			If $D(tSlicerBranches)&&(tDependsOnCount>1) {
				// DTB644 - Complex dependsOn relationships require more complete analysis. Keep track of this
				// for computation later.
				Set tHasSlicer = 1
				
				Set %slicerKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"axis",0))
			}

			// + WAL099
			//
			//   Slicer branches have: fact no, member key
			//
			//   Turn the not list into an include list
			//   Sorry large dimensions but I don't think there's another way
			Set tTestBranchNo = $O(tSlicerBranches(""))
			Set tAttemptDependent = 0		// DTB599 - Track attempts to collect dependent members
			While(tTestBranchNo'="") {
				Set bc = 0
				Kill tDepMembersB
				Kill tNotList // WAL099
				Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,""))
				While(tTestMbrNo'="") {
					Set tTestFact = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),1)
					If ($D(tDependsOn(tTestFact))) {
						Set tTestId = $LG(tSlicerBranches(tTestBranchNo,tTestMbrNo),2)
						// find set of fact values for this dependent level
						// + WAL099 -- skip if not, accumulate not list and handle below
						Set tNot=0
						If ($E(tTestId,1)="!") {
							// accumulate a not list to process later
							Set tNotList(tTestFact,$E(tTestId,2,*)) = ""	
							Set tNot=1
						}
						If ('tNot)&&($E(tTestId)'="@") {
							// DTB599 - Look for dependent members only if they are local
							Set tAttemptDependent = 1
							Set tSC = ##class(%DeepSee.Query.Engine).%FindDependentMembers(pCubeName,.tDepMembersB,tFact,tTestFact,tTestId,$I(bc))
							If $$$ISERR(tSC) Quit
						}
						// - WAL099
					}
					If $$$ISERR(tSC) Quit
					Set tTestMbrNo = $O(tSlicerBranches(tTestBranchNo,tTestMbrNo))
				}
				// + WAL099 -- handle the not list here
				If $D(tNotList) {
					// bc is always 1 in this case because multiple conditions need to be OR'ed
					Set bc = 1
					// Handle one fact from the branch at a time
					Set tTestFact = $O(tNotList(""))
					While (tTestFact'="") {
						Set tFactItem = $O($$$DeepSeeIndexGLVN($$$DeepSeeIndex(tCubeIndex),tTestFact,""))
						While (tFactItem'="") {
							Set tAllMembers(tTestFact,tFactItem) = ""
							Set tFactItem = $O($$$DeepSeeIndexGLVN($$$DeepSeeIndex(tCubeIndex),tTestFact,tFactItem))	
						}
						// remove the members excluded by not
						Set tNotMember = $O(tNotList(tTestFact,""))
						While (tNotMember'="") {
							Kill tAllMembers(tTestFact,tNotMember)
							Set tNotMember = $O(tNotList(tTestFact,tNotMember))	
						}
						Set tTestId = $O(tAllMembers(tTestFact,""))
						While (tTestId'="") {
							Set tAttemptDependent = 1		// DTB599
							Set tSC = ##class(%DeepSee.Query.Engine).%FindDependentMembers(pCubeName,.tDepMembersB,tFact,tTestFact,tTestId,bc)
							Merge tCollectDepMembersB = tDepMembersB
							If $$$ISERR(tSC) Quit
							Set tTestId = $O(tAllMembers(tTestFact,tTestId))
						}
						Set tTestFact = $O(tNotList(tTestFact))
					}
					Merge tDepMembersB = tCollectDepMembersB
				}
				// - WAL099 -- end not list handling
				Merge tDepMembers = tDepMembersB
				If $$$ISERR(tSC) Quit
				Set tTestBranchNo = $O(tSlicerBranches(tTestBranchNo))
			}
			
			If '$D(tDepMembers)&&$D(tSlicerBranches)&&tAttemptDependent {
				// DTB599 - The attempted dependencies prove there are no possible members.
				// Signal the member accumulation that this is the case.
				Set tDepMembers=0
			}
		}
		If $$$ISERR(tSC) Quit
		// - WAL099

		Set tStart = $zh
		// query against star table
		If (tExists && (tStarClass '= "")) {
			Set tHasValue = 0

			// DP-421530 - Construct a query that can use SQL %FIND against a pre-built slicer
			If tUseSlicerIndex {
				Set tFactTable = ##class(%DeepSee.Utils).%GetCubeFactTable(tCubeIndex)
				If (tFactTable = "") {
					Set tSC = $$$ERROR($$$GeneralError,"%GetMembers: Table missing or not found: '" _ tCubeIndex _ "'")
					Quit
				}

				Set tMaxMembers = $G(%dsMaxMembers)
				Set tLimit = $S(tMaxMembers="":"",1:" TOP "_tMaxMembers)		// DTB637 - Use the "null" operator for subquery support
				Set tHasRangeLimits = ((+$G(%dsStartMbr))&&+$G(%dsEndMbr))		// DTB637 - Single flag

				// Assemble the base SELECT <fields> FROM <factTable>. The <fields> in this case are joins to the columns
				// in the Star table all referenced from the same tStarTabID
				Set tFSQL = "SELECT DISTINCT"_tLimit_" "_tStarKeyField_"->%ID,%EXACT("_tStarKeyField_"->"_tStarKeyField_") MKEY"
				Set tWHERE = ""
				If (tStarField'="") {
					Set tHasValue = 1
					Set tFSQL = tFSQL _ ",%EXACT(" _ tStarKeyField_"->"_tStarField_")"
				}
			
				// In this context there are two components to any WHERE clause:
				//  1 - The %FIND SQLproc which is the primary index based on the entire slicer
				//  2 - A user supplied search key in %dsMemberSearch
				Set tWHERE = " %ID %FIND %DeepSee_Query_Find.slicerFind($listbuild('"_tCubeIndex_"','"_%slicerKey_"'))"

				// Search code from below
				If ($G(%dsMemberSearch)'="") {
					If (tStarField'="") {
						Set tSClause = "UPPER("_tStarKeyField_"->"_tStarField _ ") [ '"_$$$iscEscapeSQL(%dsMemberSearch)_"'"
					}
					Else {
						Set tSClause = tStarKeyField_"->"_"%ID" _ " [ '"_$$$iscEscapeSQL(%dsMemberSearch)_"'"
					}
					If (tDescProp'="") {
						Set tSClause = $$$dsAddParens(tSClause) _ " OR (UPPER(" _ tStarKeyField_"->"_tDescProp _ ") [ '"_$$$iscEscapeSQL(%dsMemberSearch)_"')"
					}
					
					Set tWHERE = tWHERE _ " AND " _ $$$dsAddParens(tSClause)
				}

				// DP-424293 - Additionally restrict using rollup field if defined
				If ((pRollupKey'="")&&(tRollup'="")) {
					Set tWHERE = tWHERE _ $S((tWHERE'=""):" AND ",1:"") _ tRollup _ " = '"_$$$iscEscapeSQL(pRollupKey)_"'"
				}

				// if no sort defined, sort by display value
				If (tStarSort="") {
					Set tOrderBy = tStarKeyField_"->"_tStarField
					Set:(tSortDir="desc")||(tSortDir="desc#") tOrderBy = tOrderBy _ " desc"
				}
				Else {
					Set tOrderBy = ""
					For p = 1:1:$L(tStarSort,",") {
						Set s = $P(tStarSort,",",p)
						Set d = $P(tSortDir,",",p)
						Set tOrderBy = tOrderBy _ $S(tOrderBy="":"",1:",") _  tStarKeyField_"->"_s _ $S(d="desc":" desc",d="desc#":" desc",1:"")
					}
				}

				// Assemble the full query
				Set tFSQL = tFSQL _ " FROM %PARALLEL " _ tFactTable
			
				// Add the completed WHERE clause to the query
				If (tWHERE '= "") {
					Set tFSQL = tFSQL _ " WHERE " _ tWHERE
				}

				// set up and add order by on the StarTable's keys
				If (tOrderBy '= "") {		// DTB637 - Revert conditional
					Set tFSQL = tFSQL _ " ORDER BY " _ tOrderBy
				}

				Set tSQLTime = $ZH
				Set tStatement = ##class(%SQL.Statement).%New()

				Set tSC = tStatement.%Prepare(tFSQL)
				Quit:$$$ISERR(tSC)
				
				Set tRS = tStatement.%Execute()
				Set tSQLTime = $ZH - tSQLTime
			}
			Else {
				Set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
				If (tTable = "") {
					Set tSC = $$$ERROR($$$GeneralError,"%GetMembers: Table missing or not found: '" _ tStarClass _ "'")
					Quit
				}

				// no limit on members
				// JMD1193: unless in context
				Set tHasRangeLimits = ((+$G(%dsStartMbr))&&+$G(%dsEndMbr))		// DTB637 - Single flag
				
				Set tSQL = "SELECT %ID,"_tStarKeyField_" MKEY"
				Set tWHERE = ""
				If (tStarField'="") {
					Set tHasValue = 1
					Set tSQL = tSQL _ "," _ tStarField
				}
				// JMD1475
				If (tDescProp'="") {
					Set tSQL = tSQL _ "," _ tDescProp_ " DESCRIPTION"
				}
				Set tSQL = tSQL _ " FROM " _ tTable
				
				// restrict using rollup field
				If ((pRollupKey'="")&&(tRollup'="")) {
					Set tWHERE = tRollup _ " = '"_$$$iscEscapeSQL(pRollupKey)_"'"
				}

				If ($D(pRange)) {
					If ($G(pRange(1))]]$G(pRange(2))) {
						Set tArg1 = $G(pRange(2))
						Set tArg2 = $G(pRange(1))
					}
					Else {
						Set tArg1 = $G(pRange(1))
						Set tArg2 = $G(pRange(2))
					}
					Set tArg1 = $Replace(tArg1,"'","''")
					Set tArg2 = $Replace(tArg2,"'","''")

					Set tValueField = $S(tStarField'="":tStarField,1:"%ID")
					Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ tValueField _ " BETWEEN '" _ $$$iscEscapeSQL(tArg1) _ "' AND '" _ $$$iscEscapeSQL(tArg2) _ "'"
				}

				// add filter restriction
				If (tFILTER'="") {
					Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ tFILTER

					// don't use both algorithms
					Set tUseRestrictAlgorithm = 0
				}
				
				// add member context restriction
				If (tMCFILTER'="") {
					Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ tMCFILTER

					// don't use both algorithms
					Set tUseRestrictAlgorithm = 0
				}
				
				If (+tHasMemberList) {
					// use member list
					Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeIndex,.tSC)
					If $$$ISERR(tSC) Quit

					Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",pCubeName,"Apply memberList","%GetMembers")
					// list items using default order
					If (tStarField="") {
						Set tStarField = "%ID"
					}
					Set tSQLD = tSQL _ " WHERE " _ tStarField _ "= ?"
					If (tWHERE '= "") {
						// JMD1042: add ()
						Set tSQLD = tSQLD _ " AND (" _ tWHERE _ ")"
					}
					Set tStatement = ##class(%SQL.Statement).%New()
					Set tSC = tStatement.%Prepare(tSQLD)
					Quit:$$$ISERR(tSC)

					//Set tRS = tStatement.%Execute()

					Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",""),1,data)
					While (p'="") {
						Set tItemName = $LG(data,1)
						Set tItemSpec = $LG(data,2)
						Set tItemDescription = $LG(data,4)		// DTB219

						If (tItemSpec'="") {
							// !!! test if spec is a key !!!
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
							Set tRS = tStatement.%Execute(tItem)
							//Quit:$$$ISERR(tSC)

							If (tRS.%Next()) {
								Set tID = tRS.%GetData(1)
								Set tKEY = tRS.%GetData(2)

								// JMD1285 add test
								Set tSkip = 0
								If (tNonEmpty) { // test intersection
									// test if there is data for this member
									If ((tFact'="")&&(tID'="")) {
										If ('##class(%DeepSee.Query.Engine).%IntersectExists(pCubeName,tFact,tID)) {		// DP-415899
											Set tSkip = 1
										}
									}
								}

								If 'tSkip {
									Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("mbr",1,1,pParent,tItemCaption,tID,tFact,,pDimNo,pHierNo,pLevelNo,,tKEY)
									If tItemDescription'="" {
										// DTB219 - Insert member description
										Set $LI($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pNodeNo),23) = tItemDescription
									}
									Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
									Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
									Set leaf = $I(%leafCount)
								}
								If (pRecurse > 0) {
									// n.b. do not pass range up
									Set tSC = ..%GetMembers(pCubeName, pDimNo, pHierNo, pLevelNo + 1,tID, pParent,pKey,.pNodeNo,pRecurse,,.pMemberList)
									Quit:$$$ISERR(tSC)
								}
							}
							Do tRS.%Close()
						}
						Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",p),1,data)
					}
					Quit // done
				}

				// if no sort defined, sort by display value
				If (tStarSort="") {
					Set tOrderBy = tStarField
					Set:(tSortDir="desc")||(tSortDir="desc#") tOrderBy = tOrderBy _ " desc"
				}
				Else {
					Set tOrderBy = ""
					For p = 1:1:$L(tStarSort,",") {
						Set s = $P(tStarSort,",",p)
						Set d = $P(tSortDir,",",p)
						Set tOrderBy = tOrderBy _ $S(tOrderBy="":"",1:",") _ s _ $S(d="desc":" desc",d="desc#":" desc",1:"")
					}
				}

				// Use special restriction algorithm for large dimensions
				If (tUseRestrictAlgorithm && tNonEmpty && tHasSlicer) {
					Set tSUBQUERY = ""
					Set tFactSensitive = 1
					If $D(pMemberList(pLevelNo)) {
						// reuse prior calculation
						Set tSUBQUERY = pMemberList(pLevelNo)
					}

					If (tSUBQUERY '= "") {
						// remember tSUBQUERY
						Set pMemberList(pLevelNo) = tSUBQUERY
						If (tWHERE '= "") {
							Set tWHERE = tWHERE _ " AND " _ tSUBQUERY
						}
						Else {
							Set tWHERE = tSUBQUERY
						}
					}
				}

				// JMD1283
				If ($G(%dsMemberSearch)'="") {
					If (tStarField'="") {
						Set tSClause = "UPPER("_tStarField _ ") [ '"_$$$iscEscapeSQL(%dsMemberSearch)_"'"
					}
					Else {
						Set tSClause = "%ID" _ " [ '"_$$$iscEscapeSQL(%dsMemberSearch)_"'"
					}
					If (tDescProp'="") {
						Set tSClause = $$$dsAddParens(tSClause) _ " OR (UPPER(" _ tDescProp _ ") [ '"_$$$iscEscapeSQL(%dsMemberSearch)_"')"
					}
					If (tWHERE '= "") {
						Set tWHERE = tWHERE _ " AND " _ $$$dsAddParens(tSClause)
					}
					Else {
						Set tWHERE = tSClause
					}
				}

				If (tWHERE '= "") {
					Set tSQL = tSQL _ " WHERE " _ tWHERE
				}

				// tack on order by
				If (tOrderBy '= "") {		// DTB637 - Revert conditional
					Set tSQL = tSQL _ " ORDER BY " _ tOrderBy
				}

				// JMD1193: check for start/end mbr#
				If tHasRangeLimits {
					Set tSQL = "SELECT * FROM ("_tSQL_") WHERE %vid BETWEEN "_%dsStartMbr_" AND "_%dsEndMbr
				}

				// $$$DSWRITELN("%GetMembers: "_tSQL)
				Set tSQLTime = $ZH
				Set tStatement = ##class(%SQL.Statement).%New()

				Set tSC = tStatement.%Prepare(tSQL)
				Quit:$$$ISERR(tSC)
				Set tRS = tStatement.%Execute()

				Set tSQLTime = $ZH - tSQLTime
				// JMD889--do not log this time-- it breaks automated tests!
				Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",pCubeName,tSQL,"%GetMembers",)
			}


			// Transfer contents of the SQL resultset to the axis global
			Set nc = 0
			While (tRS.%Next()) {
				Set tSkip = 0
				Set nc = nc + 1
				Set tID = tRS.%GetData(1)
				Set tKEY = tRS.%GetData(2)
				Set tDesc = $S(tDescProp="":"",tHasValue:tRS.%GetData(4),1:tRS.%GetData(3))
				//Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"reduced") = 1		// DP-421530 - Mark that this went through a reduction algorithm already

				// JMD910: test dependOn list
				If ((tID'="")&&$D(tDepMembers)) {
					Set tSkip = '$D(tDepMembers(tID))
				}

				If ('tSkip&&tNonEmpty&&'tUseSlicerIndex) { // test intersection
					// test if there is data for this member
					// DP-415899 - If there is no slicer, just use the SQL result without trimming
					If ((tFact'="")&&(tID'=""))&&tHasSlicer&&('##class(%DeepSee.Query.Engine).%IntersectExists(pCubeName,tFact,tID)) {
						Set tSkip = 1
					}
				}
				If ('tSkip) {
					Set tValue = $S(tHasValue:tRS.%GetData(3),1:tID)
					If (($$$LOWER(tKEY)=$$$DeepSeeNullMarker)||($$$LOWER(tValue)=$$$DeepSeeNullMarker)) {
						Set tValue = ..%GetNullName(pCubeName,pDimNo,pHierNo,pLevelNo,.tNullCaption)
					}
					Set tNode = $LB("mbr",1,1,pParent,tValue,tID,tFact,,pDimNo,pHierNo,pLevelNo,,tKEY)
					// JMD1475
					Set:tDesc'="" $List(tNode,23) = tDesc
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = tNode
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
					Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
					Set leaf = $I(%leafCount)
					If (pRecurse > 0) {
						// n.b. do not pass range up
						Set tSC = ..%GetMembers(pCubeName, pDimNo, pHierNo, pLevelNo + 1,tID, pParent,pKey,.pNodeNo,1,,.pMemberList)
						Quit:$$$ISERR(tSC)
					}

					// Quit once the requested %dsMaxMembers is reached. Test once more for a next result to decide if the list
					// is being truncated
					If (+$G(%dsMaxMembers) && (pNodeNo>%dsMaxMembers)) {
						Set:(tRS.%Next()) $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"truncated") = 1
						Quit
					}
				}
			}
		}
		// stats
		If ($D(%query)&&$D(%axisNo)) {
			Set %query.%Statistics("GetMembers "_%axisNo) = $G(%query.%Statistics("GetMembers "_%axisNo)) + ($ZH - tStart)
		}

		// JMD871: if there are fact-sensitive optimizations in play, mark
		// the axis as needing a recompute
		If (tFactSensitive) {
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"recompute") = 1
		}
	}		
	Catch(ex) {
		$$$DSWRITE("GetMembers: "_ $ZE)
		Set tSC = ex.AsStatus()
	}
	
	Set tFlag = $zu(115,8,tFlag)
	
	Quit tSC
}

/// Get one member and place it into <var>pSet</var>.<br/>
/// <var>pKey</var>, is the key for the base member to return.</br>
/// <var>pRelation</var> indicates how this member is related to the base member.
/// "same","lead", "lag", etc.<br/>
/// <var>pOffset</var>, is an optional offset to apply to the relation.
ClassMethod %GetRelatedMember(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, Output pSet As %List, pKey As %String = "", pRelation As %String, pOffset As %Integer = 0, pValue As %String = "", pAllowMissing As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	If pAllowMissing&&($G(pValue)="") {
		// DTB165 - pValue is required to find a member related to a fictitious endpoint
		Set tSC = $$$ERROR($$$GeneralError,"%GetRelatedMember: pValue must be supplied if pAllowMissing=1")
	}
	
	Try {
		Set tFlag = $zu(115,8,0)
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,,.tStarKeyField)

		// construct query against dimension table
		If (tExists && (tStarClass '= "")) {
			Set tHasValue = 0
			Set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
			If (tTable = "") {
				Set tSC = $$$ERROR($$$GeneralError,"%GetRelatedMember: Dimension table missing or not found: '" _ tStarClass _ "'")
				Quit
			}

			If (tStarKeyField="") {
				Set tStarKeyField = "%ID"
			}

			Set tSQL = "%ID,"_tStarKeyField_" MKEY"
			Set tWHERE = ""
			If (tStarField'="") {
				Set tHasValue = 1
				Set tSQL = tSQL _ ", " _ tStarField
			}
			Set tSQL = tSQL _ " FROM " _ tTable

			// find relation
			Set tDir = "asc"
			Set tOffset = $S(pOffset="":1,1:pOffset)
			If (pRelation = "lead") {
			}
			ElseIf (pRelation = "lag") {
				Set tDir = "desc"
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Unsupported relation in %GetRelatedMember: " _ pRelation)
				Quit
			}

			Set tSQL = "SELECT"_ " " _ tSQL 

			// find rollup key for base member
			// restrict using rollup field
			If ((pRollupKey'="")&&(tRollup'="")) {
				Set tWHERE = tRollup _ " = '"_$$$iscEscapeSQL(pRollupKey)_"'"
			}
			// +DTB165
			If ((pAllowMissing)&&tHasValue&&(pValue'="")) {
				// DTB165 - Cannot rely on the ID in this case. Select for only the members in the direction of the 
				// offset.
				If (pRelation="lead") {
					Set tWHERE = tWHERE _ $S((tWHERE'=""):" AND ",1:"") _ tStarField _ " > '" _ pValue _ "'"
				}
				ElseIf (pRelation="lag") {
					Set tWHERE = tWHERE _ $S((tWHERE'=""):" AND ",1:"") _ tStarField _ " < '" _ pValue _ "'"
				}
			}
			// -DTB165

			If (tWHERE '= "") {
				Set tSQL = tSQL _ " WHERE " _ tWHERE
			}

			Set tORDER = ""

			// if no sort defined, sort by display value
			If (tStarSort="") {
				Set tOrderBy = tStarField _ $S(tDir="desc":" DESC",tDir="desc#":" DESC",1:"")
			}
			Else {
				Set tOrderBy = ""
				For p = 1:1:$L(tStarSort,",") {
					Set s = $P(tStarSort,",",p)
					Set d = $P(tSortDir,",",p)
					Set tOrderBy = tOrderBy _ $S(tOrderBy="":"",1:",") _ s _ $S(d="desc":" DESC",d="desc#":" DESC",1:"")
				}
			}

			Set tORDER = tOrderBy

			// walk up higher levels to get additional ordering information
			Set tSort = ""
			For n = pLevelNo-1:-1:1 {
				Set tLOR = ""
				Set tExistsN = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, n, .tFactN, .tStarClassN, .tStarFieldN, .tStarSortN, .tRollupN, .tSortDirN)

				If (tStarClassN) {
					// get prior rollup field name
					If (tRollup'="") {
						// pull out last part(s) of rollup name
						Set t = $P(tRollup,".",2,$L(tRollup,"."))
						Set tLOR = $Replace(t,".","->")
					}
					// !!!
					Set tStarSortN = $S(tStarSortN="":tStarFieldN,1:tStarSortN)
					Set tLOR = tLOR _ "->"_tStarSortN
					If ((tDir = "asc") && ($E(tSortDirN,1,4) = "desc") || ($E(tDir,1,4) = "desc") && ($E(tSortDirN,1,4) '= "desc")) {
						Set tLOR = tLOR _ " DESC"
					}
					Set tORDER = tLOR _ "," _ tORDER
					Set tRollup = tRollupN
				}
			}

			If (tORDER '= "") {
				Set tSQL = tSQL _ " ORDER BY " _ tORDER
			}

			// $$$DSWRITELN("%GetRelatedMembers: "_tSQL)
			Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
			Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",pCubeName,tSQL,"%GetRelatedMembers")

			Set tRS = ##class(%ResultSet).%New()
			Set tSC = tRS.Prepare(tSQL)
			Quit:$$$ISERR(tSC)

			Set tSC = tRS.Execute()
			Quit:$$$ISERR(tSC)

			// loop over result and pluck out the one record we want
			Set tCount = 0
			Set tFound = 0
			While (tRS.Next()) {
				Set tID = tRS.GetData(1)
				Set tValue = $S(tHasValue:tRS.GetData(3),1:tID)
				If (pAllowMissing) {
					// DTB165 - Cannot rely on the ID since it might not exist in this case.
					// Still look for the null marker and reject it
					If ($$$LOWER(tValue)=$$$DeepSeeNullMarker) {
						Quit
					}
					Set tCount = 1		// The first entry is offset=1 thanks to the SQL WHERE clause
					Set tFound = 1
				}
				ElseIf (tID = pKey)||(tValue = pValue) {
					// JMD1510 check for <null> record
					If ($$$LOWER(tValue)=$$$DeepSeeNullMarker) {
						Quit
					}
					Else {
						Set tFound = 1 // start counting
					}
				}

				If (tFound) {
					If (tCount = tOffset) {
						Set tKEY = tRS.GetData(2)
						If ($$$LOWER(tValue)=$$$DeepSeeNullMarker) {
							Set tValue = ..%GetNullName(pCubeName,pDimNo,pHierNo,pLevelNo,.tNullCaption)
						}
						Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tValue,tID,tFact,,pDimNo,pHierNo,pLevelNo,,tKEY)
						Quit
					}
					Else {
						Set tCount = tCount + 1
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Get the parent of the current member and place it into <var>pSet</var>.<br/>
ClassMethod %GetParentMember(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pParent As %Integer, Output pSet As %List, pKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,,.tStarKeyField)
		Set tExistsP = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo-1, .tFactP, .tStarClassP, .tStarFieldP, .tStarSortP, .tRollupP, .tSortDirP,,,.tStarKeyFieldP)

		// test if parent is the ALL level
		If (pLevelNo = 2) {
			Set tAllName = ..%GetAllName(pCubeName,pDimNo,.tAllCaption)
			If (tAllName '= "") {
				Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tAllCaption,"",tFactP,,pDimNo,pHierNo,pLevelNo-1,,"")
				Quit
			}
		}

		// query against star table
		If (tExists && tExistsP && (tStarClass '= "") && (tRollup'="")) {
			Set tHasValue = 0
			Set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
			If (tTable = "") {
				Set tSC = $$$ERROR($$$GeneralError,"%GetParentMember: Dimension table missing or not found: '" _ tStarClass _ "'")
				Quit
			}
			
			Set tWHERE = "%ID = '"_pKey_"'"

			If (tStarKeyFieldP="") {
				Set tStarKeyFieldP = "%ID"
			}

			Set tSQL = "SELECT "_tRollup_"->%ID,"_tRollup_"->"_tStarKeyFieldP_" MKEY"

			If (tStarFieldP'="") {
				Set tHasValue = 1
				Set tSQL = tSQL _ ", " _tRollup_"->"_ tStarFieldP
			}
			Set tSQL = tSQL _ " FROM " _ tTable

			If (tWHERE '= "") {
				Set tSQL = tSQL _ " WHERE " _ tWHERE
			}

			//$$$DSWRITELN("%GetParentMember: "_tSQL)
			Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
			Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",pCubeName,tSQL,"%GetParentMember")

			Set tRS = ##class(%ResultSet).%New()
			Set tSC = tRS.Prepare(tSQL)
			Quit:$$$ISERR(tSC)

			Set tSC = tRS.Execute()
			Quit:$$$ISERR(tSC)

			While (tRS.Next()) {
				Set tID = tRS.GetData(1)
				Set tKEY = tRS.GetData(2)
				Set tValue = $S(tHasValue:tRS.GetData(3),1:tID)
				If ($$$LOWER(tValue)=$$$DeepSeeNullMarker) {
					Set tValue = ..%GetNullName(pCubeName,pDimNo,pHierNo,pLevelNo-1,.tNullCaption)
				}
				Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tValue,tID,tFactP,,pDimNo,pHierNo,pLevelNo-1,,tKEY)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Get the nth child of the current member and place it into <var>pSet</var>.<br/>
ClassMethod %GetNthChild(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pParent As %Integer, Output pSet As %List, pKey As %String, pNumber As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,,.tStarKeyField)
		Set tExistsC = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo+1, .tFactC, .tStarClassC, .tStarFieldC, .tStarSortC, .tRollupC, .tSortDirC,,,.tStarKeyFieldC)

		// query against star table
		If (tExists && tExistsC && (tStarClassC '= "")) {
			Set tHasValue = 0
			Set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClassC)
			If (tTable = "") {
				Set tSC = $$$ERROR($$$GeneralError,"%GetNthChild: Dimension table missing or not found: '" _ tStarClassC _ "'")
				Quit
			}

			Set tTop = $S(pNumber>0:pNumber,1:-pNumber)
			Set:tRollupC'="" tWHERE = tRollupC _ " = '"_pKey_"'"
			If (tStarKeyFieldC="") {
				Set tStarKeyFieldC = "%ID"
			}
			Set tSQL = "SELECT TOP "_tTop_" %ID,"_tStarKeyFieldC_" MKEY"

			If (tStarFieldC'="") {
				Set tHasValue = 1
				Set tSQL = tSQL _ ", "_ tStarFieldC
			}
			Set tSQL = tSQL _ " FROM " _ tTable

			If ($G(tWHERE) '= "") {
				Set tSQL = tSQL _ " WHERE " _ tWHERE
			}

			// if no sort defined, sort by display value
			If (tStarSortC="") {
				Set tOrderBy = tStarFieldC
				Set:(pNumber<0) tOrderBy = tOrderBy _ " desc" // flip
			}
			Else {
				Set tOrderBy = ""
				For p = 1:1:$L(tStarSortC,",") {
					Set s = $P(tStarSortC,",",p)
					Set d = $P(tSortDirC,",",p)
					Set:(pNumber<0) d = $S(d="desc":"",d="desc#":"",1:"desc") // flip
					Set tOrderBy = tOrderBy _ $S(tOrderBy="":"",1:",") _ s _ $S(d="desc":" desc",d="desc#":" desc",1:"")
				}
			}

			If (tOrderBy '= "") {
				Set tSQL = tSQL _ " ORDER BY " _ tOrderBy
			}

			// $$$DSWRITELN("%GetNthChild: "_tSQL)
			Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
			Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",pCubeName,tSQL,"%GetNthChild")

			Set tRS = ##class(%ResultSet).%New()
			Set tSC = tRS.Prepare(tSQL)
			Quit:$$$ISERR(tSC)

			Set tSC = tRS.Execute()
			Quit:$$$ISERR(tSC)

			Set n = 0
			Set tCount = $S(pNumber<0:-pNumber,1:pNumber)
			While (tRS.Next()&&(n<tCount)) {
				Set tID = tRS.GetData(1)
				Set tKEY = tRS.GetData(2)
				Set n = n + 1
				If (n = tCount) {
					Set tValue = $S(tHasValue:tRS.GetData(3),1:tID)
					If ($$$LOWER(tValue)=$$$DeepSeeNullMarker) {
						Set tValue = ..%GetNullName(pCubeName,pDimNo,pHierNo,pLevelNo,.tNullCaption)
					}
					Set pSet($I(pSet)) = $LB("mbr",1,1,pParent,tValue,tID,tFactC,,pDimNo,pHierNo,pLevelNo+1,,tKEY)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Lookup the value of the given dimension property.
ClassMethod %GetPropertyValue(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pProperty As %String, pParent As %Integer, Output pSet As %List, pKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
		Set tExists = ..%GetNodeInfo(pCubeName, pDimNo, pHierNo, pLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir)

		// query against star table
		If (tExists) {
			Set tPropInfo = $G($$$DeepSeeMetaGLVN("cubes",pCubeName,"mbr#",pDimNo,pHierNo,pLevelNo,"prop",$$$UPPER(pProperty)))
			If (tPropInfo = "") {
				Set tSC = ##super(pCubeName,pDimNo,pHierNo,pLevelNo,pProperty,pParent,.pSet,pKey)
			}
			Else {
				Set tPropName = $LG(tPropInfo,3)
				Set tHasValue = 0
				Set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
				If (tTable = "") {
					Set tSC = $$$ERROR($$$GeneralError,"%GetPropertyValue Dimension table missing or not found: '" _ tStarClass _ "'")
					Quit
				}

				// JMD741
				// use method
				Set tValue = $classmethod(tStarClass,"%GetDimensionProperty",tPropName,pKey,.tFormat,.tType)
				// JMD988 Override format for strings
				If (tType="%Library.String")||(tType="%String") {		// DTB491 - Include %String as a possible type
					Set tFormat = "%string%"
				}
				Set pSet($I(pSet)) = $LB("lit",1,1,pParent,"",tValue)

				// JMD909
				Set:tFormat'="" $List(pSet(pSet),12) = tFormat
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Return the ordinal position of this member within its parent group.
/// For convenience, also return the parent key for this member.
Method %GetMemberOffset(Output pOffset As %Integer, pKey As %String, Output pParentKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
		Set pOffset = ""
		Set tSC = ..%GetParentMember(..%cube,..%dimNumber,..%hierNumber,..%levelNumber, -1,.tSet,pKey)
		If $$$ISERR(tSC) Quit

		// get parent key
		Set pParentKey = $LG($G(tSet(1)),6)

		Set tExistsC = ..%GetNodeInfo(..%cube,..%dimNumber,..%hierNumber,..%levelNumber, .tFactC, .tStarClassC, .tStarFieldC, .tStarSortC, .tRollupC, .tSortDirC)

		// query against star table
		If (tExistsC && (tStarClassC '= "")) {
			Set tHasValue = 0
			Set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClassC)
			If (tTable = "") {
				Set tSC = $$$ERROR($$$GeneralError,"%GetNthChild: Dimension table missing or not found: '" _ tStarClassC _ "'")
				Quit
			}
			
			Set tWHERE = ""
			If ((tRollupC'="") && (pParentKey '= "")) {
				Set tWHERE = tRollupC _ " = '"_pParentKey_"'"
			}
			Set tSQL = "SELECT %ID"

			If (tStarFieldC'="") {
				//Set tHasValue = 1
				//Set tSQL = tSQL _ ", "_ tStarFieldC // we don't need this!
			}
			Set tSQL = tSQL _ " FROM " _ tTable

			If (tWHERE '= "") {
				Set tSQL = tSQL _ " WHERE " _ tWHERE
			}

			// if no sort defined, sort by display value
			If (tStarSortC="") {
				Set tOrderBy = tStarFieldC
			}
			Else {
				Set tOrderBy = ""
				For p = 1:1:$L(tStarSortC,",") {
					Set s = $P(tStarSortC,",",p)
					Set d = $P(tSortDirC,",",p)
					Set tOrderBy = tOrderBy _ $S(tOrderBy="":"",1:",") _ s _ $S(d="desc":" desc",d="desc#":" desc",1:"")
				}
			}

			If (tOrderBy '= "") {
				Set tSQL = tSQL _ " ORDER BY " _ tOrderBy
			}

			//$$$DSWRITELN("%%GetMemberOffset: "_tSQL)
			Set tCubeIndex = $$$DeepSeeIndex(..%cube)
			Set:($IsObject($G(%query))&&(%query.%QueryKey'="")) $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("dim",..%cube,tSQL,"%GetMemberOffset")

			Set tRS = ##class(%ResultSet).%New()
			Set tSC = tRS.Prepare(tSQL)
			Quit:$$$ISERR(tSC)

			Set tSC = tRS.Execute()
			Quit:$$$ISERR(tSC)

			Set n = 0
			While (tRS.Next()) {
				Set tID = tRS.GetData(1)
				If (pKey = tID) {
					Set pOffset = n
					Quit
				}
				Set n = n + 1 // offset is 0-based
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

}
