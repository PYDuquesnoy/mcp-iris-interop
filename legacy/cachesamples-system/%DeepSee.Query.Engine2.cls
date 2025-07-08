/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// Contains additional logic for calculating the results of a DeepSee query.
Class %DeepSee.Query.Engine2 Extends %RegisteredObject [ System = 3 ]
{

/// Compute the values of cells within the result cube.<br/>
/// <var>pCube</var> is the name of the cube.<br/>
/// <var>pKey</var> is the query key.<br/>
/// <var>pBucketNo</var> is the logical bucket number to execute.<br/>
/// <var>pSlotNo</var> is the physical bucket slot number containing the results.<br/>
/// <var>pSection</var>, if defined, specifies, by axis, which sections of the result to calculate:<br/>
/// pSection(axis) = $LB(startNode,endNode)<br/>
/// <var>pTrace</var> is a debugging flag.<br/>
/// <var>pStats</var> is an array of statistics.<br/>
ClassMethod %ExecuteForBucket(pCube As %String, pKey As %String, pBucketNo As %Integer, pSlotNo As %Integer, ByRef pSections As %List, pTrace As %Boolean = 0, ByRef pStats) As %Status [ Internal ]
{
	// DTB971 - Add caching macros for the local functions
	// DTB981 - Add CallCombineSpecs and protect spec subscripts with $$$dsMakeSafeSubscript
#define CallExists(%exists,%spec,%meas,%type)	$$$dsRuntimeCacheRead $$$dsLimitRuntimeCacheSize $$$dsMakeSafeSubscript(%spec,success,safeSub) If success {S:'$D($$$dsRuntimeCache($LB("E",%meas,%type),safeSub),%exists)||'$G(%exists) (%exists,$$$dsRuntimeCache($LB("E",%meas,%type),safeSub))=$$Exists(%spec,%meas,%type),x=$I(%cacheStats("set")),x=$I(%cacheStats("read"),-1)} Else {Set %exists=$$Exists(%spec,%meas,%type)}
#define CallCheckCellCache(%fresh,%addr) $$$dsRuntimeCacheRead $$$dsLimitRuntimeCacheSize $$$dsSafeRef($$$dsRuntimeCache($LB("C",%addr)),%fresh,isSafe) If (isSafe && '$D($$$dsRuntimeCache($LB("C",%addr)))) {S (%fresh,$$$dsRuntimeCache($LB("C",%addr)))=$$CheckCellCache(%addr),x=$I(%cacheStats("set")),x=$I(%cacheStats("read"),-1) }
#define CallSpecToAddr(%spec,%addr)				$$$dsRuntimeCacheRead $$$dsLimitRuntimeCacheSize $$$dsMakeSafeSubscript(%spec,success,safeSub) If success {S:'$d($$$dsRuntimeCache($LB("S",safeSub)),%addr) (%addr,$$$dsRuntimeCache($LB("S",safeSub)))=$$SpecToAddr(%spec),x=$I(%cacheStats("set")),x=$I(%cacheStats("read"),-1)} Else {Set %addr=$$SpecToAddr(%spec)}		// DTB980
#define CallCombineSpecs(%specOut,%factCount,%spec1,%spec2)			$$$dsRuntimeCacheRead $$$dsLimitRuntimeCacheSize $$$dsMakeSafeSubscript(%spec1,success1,safeSub1) $$$dsMakeSafeSubscript(%spec2,success2,safeSub2) If (success1&&success2) {S:'($d($$$dsRuntimeCache(safeSub1,safeSub2),%specOut)||$d($$$dsRuntimeCache(safeSub2,safeSub1),%specOut)) (%specOut,$$$dsRuntimeCache(safeSub1,safeSub2))=..%CombineSpecs(%factCount,%spec1,%spec2),x=$I(%cacheStats("set")),x=$I(%cacheStats("read"),-1)} Else {S %specOut=..%CombineSpecs(%factCount,%spec1,%spec2)}
#define CallCombineSpecsRelOnly(%specOut,%factCount,%spec1,%spec2)			$$$dsRuntimeCacheRead $$$dsLimitRuntimeCacheSize $$$dsMakeSafeSubscript(%spec1,success1,safeSub1) $$$dsMakeSafeSubscript(%spec2,success2,safeSub2) If (success1&&success2) {S:'($d($$$dsRuntimeCache(safeSub1,safeSub2),%specOut)||$d($$$dsRuntimeCache(safeSub2,safeSub1),%specOut)) (%specOut,$$$dsRuntimeCache(safeSub1,safeSub2))=..%CombineSpecs(%factCount,%spec1,%spec2,1),x=$I(%cacheStats("set")),x=$I(%cacheStats("read"),-1)} Else {S %specOut=..%CombineSpecs(%factCount,%spec1,%spec2,1)}


	Set tSC = $$$OK 
	Try {
		New $$$dsRuntimeCache		// DTB981
		// DTB968 - Note logging and start local timer
		$$$dsSetLogging
		$$$dsStartTimer
		
		Set pCube = $$$UPPER(pCube)
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tUseCache = (pBucketNo>0)	// no cache for active chunk

		// test for showplan, bitset, or drillthrough query
		Set tShowPlan = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"showPlan"))
		Set tQueryType = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"queryType"))
		Set tIsBitSet = (tQueryType = "%BITSET")
		Set tIsDrillThru = (tQueryType = "DRILLTHROUGH")

		// find set of relations for this cube (if any)
		// these will be processed using a join index
		Set tHasRelations = 0
		Set r = $O($$$DeepSeeMetaGLVN("cubes",pCube,"rel#",""))
		While (r'="") {
			Set tAxisNo = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"axis",""),1,tAxisKey)
			While (tAxisNo'="") {
				If $D($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"fact",r)) {
					// DP-423012 - Once use of a relationship is confirmed in any axis, note its presence in the query and move on
					Set tHasRelations = 1
					Set tRelation(r) = ""
					Quit
				}
				Set tAxisNo = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"axis",tAxisNo),1,tAxisKey)
			}
			Set r = $O($$$DeepSeeMetaGLVN("cubes",pCube,"rel#",r))
		}

		// test for default measure
		Set tDefAgg = ""
		Set tDefMsr = ""
		Set tDefMsrType = ""
		Set tDefScale = 0
		Set tMsrName = $G($$$DeepSeeMetaGLVN("cubes",pCube,"defmsr"))
		If (tMsrName '= "") {
			Set tNode = $G($$$DeepSeeMetaGLVN("cubes",pCube,"mbrs","MEASURES",$$$UPPER(tMsrName)))
			If (tNode '= "") {
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",pCube,"mbr#",$LG(tNode,1),$LG(tNode,2),$LG(tNode,3)))
				Set tDefMsr = $LG(tInfo,5)
				Set tDefMsrType = $LG(tInfo,8)
				Set tDefAgg = $LG(tInfo,7,"SUM")
				Set tDefScale = +$LG(tInfo,9)
			}
		}

		Set tChunksPerBucket = $$$DeepSeeChunksPerBucket(pCube)

		// set up section ranges
		// pSection(axis) = $LG(start,end)
		Set a = $O(pSections(""))
		While (a '= "") {
			Set tSect = pSections(a)
			If (tSect '= "") {
				Set tSectionStart(a) = $LG(tSect,1)
				Set tSectionEnd(a) = $LG(tSect,2) // start of next section
			}
			Set a = $O(pSections(a))
		}

		// get start/end bitmap chunk for this bucket
		If (pBucketNo = -1) {
			// active chunk
			Set tStartChunk = pSlotNo
			Set tEndChunk = tStartChunk
			Set tResultSlot = -1
		}
		Else {
			// make sure we don't process the active chunk
			// we assume this is always at the *end* of a bucket
			Set tActiveChunk = +$G($$$DeepSeeActiveChunk(tCubeIndex))
			Set tStartChunk = ((pBucketNo-1)*tChunksPerBucket)+1
			Set tEndChunk = tStartChunk + tChunksPerBucket - 1

			If ((tActiveChunk >= tStartChunk)&&(tActiveChunk <= tEndChunk)) {
				Set tEndChunk = tActiveChunk - 1
			}

			Set tResultSlot = pSlotNo
		}
		If (tEndChunk < tStartChunk) Quit

		// number of fact properties in cube
		Set tFactCount = $G($$$DeepSeeMetaGLVN("cubes",pCube,"factCount"))
		// JMD1453
		If (tFactCount="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube must be recompiled")
			Quit
		}

		// construct base spec
		// this is a $List with "" defined for each fact
		// plus an initial reserved slot
		Set tBaseSpec = $LB("")
		For n = 1:1:tFactCount {
			Set tBaseSpec = tBaseSpec _ $LB("")
		}

		// determine order in which to visit facts
		Set tFactOrder = $G($$$DeepSeeMetaGLVN("cubes",pCube,"factOrder"))
		If (tFactOrder="") {
			Set tFactOrder = $LB("")
			For n = 1:1:tFactCount {
				Set tFactOrder = tFactOrder _ $LB(tFactCount-n)
			}
		}
				
		// + DTB986 - Load the "axes" information of all relevent axes into memory to avoid repeated
		// global references
		Set tSizeInfo = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"size"))
		For a = 1:1:$LL(tSizeInfo) {
			Set tTempAxisKey = $LG($LG(tSizeInfo,a),2)
			// DP-410644 - Always load in the root node of the axis. This includes the "all" branch and will
			// always be used to direct more targeted operations.
			Merge tAxisNodes(tTempAxisKey,1) = $$$DeepSeeAxisGLVN(tCubeIndex,tTempAxisKey,"axes",1)
		}
		// - DTB986

		// get set of extent indices for each bitmap chunk
		Set (tExtent,tSlotNo) = pSlotNo		// DP-421810 - Note the result slot these chunks are being assigned to in the cache 
		For tChunk = tStartChunk:1:tEndChunk {
			If ($D($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk),data)) {
				$$$dsBitFind(data,1,tTempBit)		// DTB970
				If (tTempBit>0) {
					Set tExtent(tChunk) = data
				}
			}
		}

		// initialize context and stacks
		Set tContext = ""

		// Find axes
		Set tTotalAxisCount = ..%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		If (tTotalAxisCount = 0) {
			// no axes:
			// result is simply the fact count (or default measure) for this bucket
			If (tIsBitSet) {
				// compute bitset and save it in the result cache
				Set tChunk = $O(tExtent(""))
				While (tChunk '= "") {
					Set tMask = $$Mask(tBaseSpec,tChunk,.tFactMask)
					Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tChunk) = tMask
					Set tChunk = $O(tExtent(tChunk))
				}
				Quit
			}
			ElseIf (tIsDrillThru) {
				Set tValue = tBaseSpec
				Quit
			}
			ElseIf (tDefMsr = "") {
				Set tValue = $$Count(tBaseSpec,"",tDefMsrType)
			}
			Else {
				If (tDefAgg = "COUNT") {
					Set tValue = $$Count(tBaseSpec,tDefMsr,tDefMsrType)
				}
				ElseIf (tDefAgg = "SUM") {
					Set tValue = $$Sum(tBaseSpec,tDefMsr,tDefScale)
				}
				ElseIf ($P(tDefAgg,":",1) = "MIN") {
					Set tValue = $$Min(tBaseSpec,tDefMsr,tDefScale)
					Set tValue = $LB(tDefAgg,tValue)
				}
				ElseIf ($P(tDefAgg,":",1) = "MAX") {
					Set tValue = $$Max(tBaseSpec,tDefMsr,tDefScale)
					Set tValue = $LB(tDefAgg,tValue)
				}
				ElseIf ($P(tDefAgg,":",1) = "AVG") {
					Set tCount = $$Count(tBaseSpec,tDefMsr,tDefMsrType)
					Set tSum = $$Sum(tBaseSpec,tDefMsr,tDefScale)
					Set tValue = $LB(tDefAgg,tCount,tSum)	// agg format
				}
				ElseIf ($P(tDefAgg,":",1) = "NULL") {
					Set tValue = ""
				}
			}
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot) = tValue
			Quit
		}

		// build list ordered by size of axis
		Set tSlicerSize = 0
		Set tSlicerAxis = ""
		Set tSlicerKey = ""
		For ra=1:1:tTotalAxisCount {
			If (tAxisType(ra) = "slicer") {
				// slicer is always first in the list
				Set tAxisList(-999999,ra) = tAxisKey(ra)
				Set tSlicerKey = tAxisKey(ra)
				Set tSlicerSize = tAxisSize(ra)
				Set tSlicerAxis = ra
			}
			ElseIf (tAxisType(ra) = "axis") {
				Set tAxisList(-tAxisSize(ra),ra) = tAxisKey(ra)
			}
		}

		// Apply the slicer to the current extent for this bucket before proceeding. It is assumed this method is going to remove any chunk entries
		// that have all facts ruled out by the slicer.
		If (tSlicerKey'="") {
			Set tSC = ..%ApplySlicerMask(pCube, tSlicerKey,.tExtent,tHasRelations,.tRelation)
			If $$$ISERR(tSC) Quit
		}

		// see if there are currentMember substitutions in play
		If ($D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap"))) {
			Set tHasCMBR = 1
		}
		Else {
			Set tHasCMBR = 0
		}

		Kill tAxisKey  // this gets rebuilt

		// initialize axis info (using size ordered list)
		// first pass, build axis indices
		Set tAxisCount = 0
		Set s = $O(tAxisList(""))
		While (s'="") {
			Set ra = $O(tAxisList(s,""))
			While (ra'="") {
				Set tAxisCount = tAxisCount + 1
				Set tOrigAxisNo = ra
				Set tRealAxisNo(tAxisCount) = ra
				Set tSortedAxisNo(ra) = tAxisCount // reverse index
				Set tAxisRoot(tAxisCount) = 1
				Set tAxisKey(tAxisCount) = tAxisList(s,ra)
				// DP-410644 - The "all" branch is specifically loaded into tAxisNodes at the outset so 
				// does not need to be tested for existence here
				Set tStartNode(tAxisCount) = $S(($G(tSectionStart(tOrigAxisNo))=""):$O(tAxisNodes(tAxisKey(tAxisCount),tAxisRoot(tAxisCount),"all","")),1:tSectionStart(tOrigAxisNo))		// DTB986 - Use local axis reference
				Set tEndNode(tAxisCount) = $G(tSectionEnd(tOrigAxisNo))
				Set tNodeNo(tAxisCount) = tStartNode(tAxisCount)

				// JMD1319: if true, then axis has a NON EMPTY clause
				// used for DISTINCT COUNT
				// DP-410644 - This top axis node will already already be loaded since tAxisRoot(tAxisCount) = 1
				Set tAxisNonEmpty(tAxisCount) = $LG(tAxisNodes(tAxisKey(tAxisCount),tAxisRoot(tAxisCount)),5)		// DTB986 - Use local axis reference

				Set ra = $O(tAxisList(s,ra))
			}
			Set s = $O(tAxisList(s))
		}

		// second pass, do the rest
		Set tAxisCount = 0
		Set s = $O(tAxisList(""))
		While (s'="") {
			Set ra = $O(tAxisList(s,""))
			While (ra'="") {
				Set tAxisCount = tAxisCount + 1
				Set tOrigAxisNo = ra
				If (tNodeNo(tAxisCount)="") {
					// no members for axis: ignore
				}
				Else {
					Do SetContext(tAxisCount)
				}
				Set ra = $O(tAxisList(s,ra))
			}
			If $$$ISERR(tSC) Quit
			Set s = $O(tAxisList(s))
		}
		If $$$ISERR(tSC) Quit

		// if slicer has one node, then do not
		// add an additional results subscript
		If (tSlicerSize = 1) {
			Set tRealAxisCount = tAxisCount - 1
		}
		Else {
			Set tRealAxisCount = tAxisCount
		}

		// JMD948
		/*
		If (tIsBitSet && (tRealAxisCount>1)) {
			Set tSC = $$$ERROR($$$GeneralError,"BITSET Query must have one axis or less.")
			Quit
		}
		*/

		// general loop over all axes
		Set tDone = 0
		While ('tDone) {
			Kill tNodeNums
			Set tHasExpression = 0
			Set tCellCalc = 1
			Set tCellMsr = tDefMsr
			Set tCellMsrType = tDefMsrType
			Set tCellAgg = tDefAgg
			Set tDistinctAxis = ""			// non-"" if this cell has a %DISTINCT calc
			Set tCellScale = tDefScale
			Set tCellSpec = tBaseSpec
			Set tSlicerSpec = tBaseSpec		// track separately
			Set tHasSkip = 0

			// find cell context from axes context
			// visit axes in order of solve_order
			// followed by real axis order (reversed to pick up axis 0 last)
			Kill tSO
			For a=1:1:tAxisCount {
				// JMD1503
				Set tSO(+$G(tSolveOrder(a)),tRealAxisNo(a)) = a
			}

			Set ak1 = $O(tSO(""))
			While (ak1'="") {
				// JMD1497 visit in reverse order
				Set rxa = $O(tSO(ak1,""),-1,a)
				While (rxa'="") {
					// cell address in original axis order
					Set tNodeNums(rxa) = +tNodeNo(a)

					Set tCellCalc = tCellCalc && $G(tCalc(a))
					If (tCellCalc) {
						Set tAxisSpec = $G(tSpec(a))
						If (rxa=tSlicerAxis) {
							// fold in later
							Set tSlicerSpec = tAxisSpec
						}
						Else {
							Set:$D(tSkipFacts(a)) tHasSkip = 1

							// JMD1453
							$$$CallCombineSpecs(tCellSpec,tFactCount,tCellSpec,tAxisSpec)		// DTB981
						}
						If ($G(tMeasure(a))'="") {
							Set tCellMsr = tMeasure(a)
						}
						If ($G(tMeasureType(a))'="") {
							Set tCellMsrType = tMeasureType(a)
						}
						If ($G(tMsrScale(a))'="") {
							Set tCellScale = tMsrScale(a)
						}
						If ($G(tAgg(a))'="") {
							Set tCellAgg = tAgg(a)
						}
						If ($G(tDistinct(a))'="") {
							Set tDistinctAxis = a
						}
						If ($G(tLiteral(a))'="") { // JSL4407
							Set tHasExpression = 1
						}
						If ($D(tExpression(a))) {
							Set tHasExpression = 1
						}
					}
					// next axis
					Set rxa = $O(tSO(ak1,rxa),-1,a)
				}
				Set ak1 = $O(tSO(ak1))
			}

			// now remove everything referenced in the skip facts set
			If (tHasSkip) {
				For a=1:1:tAxisCount {
					// cell address in original axis order
					Set tNodeNums(tRealAxisNo(a)) = +tNodeNo(a)
					Set tCellCalc = tCellCalc && $G(tCalc(a))
					If (tCellCalc) {
						Set tAxisSpec = $G(tSpec(a))
						If (tRealAxisNo(a)'=tSlicerAxis) {
							For f = 1:1:tFactCount {
								If $D(tSkipFacts(a,f)) {
									Set $List(tCellSpec,f+1) = tSkipFacts(a,f)
								}
							}
						}
					}
				}
			}

			// currentMember handling
			// See if we need to overlay substitutions due to currentMember
			Set tCMListNodeNo = ""
			Kill tCMList,tCMData,tCMBRInfo
			If (tHasCMBR) {
				// See if there is an overlay in the cmbr map - this is always a 3d structure!
				// This section works to establish the fact-wise versus cell-wise distinction in the 
				// implied subtable that can be created by the currentmember in the variables:
				//  tCellMsr: The per-fact measure being used to assign an intermediate cell value
				//  tCellAgg: The per-fact measure aggregate acting on each intermediate cell
				//  tCMBRMsr: The measure imposed by the CMBR aggregating function
				//  tCMBRAgg: The aggregate operating on intermediate cells of the CMBR 
				Set tCMBRInfo = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tNodeNums(1)),+$G(tNodeNums(2)),+$G(tNodeNums(3))))
				If (tCMBRInfo'="") {
					Set tCMBRType = $LG(tCMBRInfo,1)
					If (tCMBRType="mbr") {
						// use one value as cell spec
						Set tCMBRNodeNo = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tNodeNums(1)),+$G(tNodeNums(2)),+$G(tNodeNums(3)),""))
						Set tCellSpec = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tNodeNums(1)),+$G(tNodeNums(2)),+$G(tNodeNums(3)),tCMBRNodeNo))
						// JMD1488
						Set tCMBRAggInfo = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tNodeNums(1)),+$G(tNodeNums(2)),+$G(tNodeNums(3)),tCMBRNodeNo,"agg"))
						Set tCMBRAgg = $LG(tCMBRInfo,16)
						// If there is a measure in the cmbr info, set that as the default for the cells.
						// Make sure to use scale and type as well
						Set tCMBRMsr = $LG(tCMBRInfo,15)
						If (tCMBRMsr'="") {
							Set tCellMsr = tCMBRMsr
							Set tCellScale = $LG(tCMBRInfo,19)
							Set tCellMsrType = $LG(tCMBRInfo,20)
						}
						If (tCMBRAggInfo'="") {
							// DP-402998 - Directly set the instructions for the cell operations
							// if the currentmember's "agg" node is defined.
							Set tCellAgg = $LG(tCMBRAggInfo,1)
							Set tCellMsr = $LG(tCMBRAggInfo,2)
							Set tCellScale = $LG(tCMBRAggInfo,3)
							Set tCellMsrType = $LG(tCMBRAggInfo,4)
						}
						
						// DP-402998 - If there has not been a set of the cell aggregate, set it now.
						// The default is COUNT if no measure is defined for providing the aggregate values.
						// If a measure is defined but no aggregate is specified, SUM is assumed.
						Set:($G(tCellAgg)="") tCellAgg = $S(tCellMsr="":"COUNT",1:"SUM")
					}
					ElseIf (tCMBRType="agg") {
						Set tCMBRAgg = $LG(tCMBRInfo,16)
						If ((tCMBRAgg'="%MDX")&&(tCMBRAgg'="%KPI")) {
							// get set of children
							Merge tCMList = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tNodeNums(1)),+$G(tNodeNums(2)),+$G(tNodeNums(3)))
							// if there is a measure in the cmbr info, use it
							// JMD1488 look for cell specific measure/agg info
							Set tCMBRAggInfo = ""
							Set kx = $O(tCMList(""))
							If (kx'="") {
								Set tCMBRAggInfo = $G(tCMList(kx,"agg"))
							}
							
							Set tCMBRMsr = $LG(tCMBRInfo,15)
							If (tCMBRMsr'="") {
								Set tCellMsr = tCMBRMsr
								Set tCellScale = $LG(tCMBRInfo,19)
								Set tCellMsrType = $LG(tCMBRInfo,20)
							}
							If (tCMBRAggInfo'="") {
								// DP-402998 - Directly set the instructions for the cell operations
								// if the currentmember's "agg" node is defined.
								Set tCellAgg = $LG(tCMBRAggInfo,1)
								Set tCellMsr = $LG(tCMBRAggInfo,2)
								Set tCellScale = $LG(tCMBRAggInfo,3)
								Set tCellMsrType = $LG(tCMBRAggInfo,4)
							}
							
							// DP-402998 - If there has not been a set of the cell aggregate, set it now.
							// The default is COUNT if no measure is defined for providing the aggregate values.
							// If a measure is defined but no aggregate is specified, SUM is assumed.
							Set:($G(tCellAgg)="") tCellAgg = $S(tCellMsr="":"COUNT",1:"SUM")

						}
						// we don't need a cellspec; it comes from each item in CMList
						Set tCellSpec = tBaseSpec
					}
					Else {
						Set tCellSpec = tBaseSpec
						Set tHasExpression = 1
					}

					// if there are nodes above the cmbr node, fold in their spec
					// DTB062 - use the axis mapping to determine which sorted axis 
					// will contain the parent spec
					If (+$LG(tCMBRInfo,4)>1) {
						Set tCMBRAxisInfo = $LG(tCMBRInfo,23)		
						Set a = tSortedAxisNo($LG(tCMBRAxisInfo,1))
						Set tCMBaseSpec = $G(tStackSpec(a,tLevel(a)-1))
						If (tCMBaseSpec'="") { 
							// JMD1453
							$$$CallCombineSpecs(tCellSpec,tFactCount,tCellSpec,tCMBaseSpec)		// DTB981
						}
					}
				}
			}					
			
			// JMD1403: check for cell override due to relationship
			// DTB971 - Do an initial check for "relMap" at all and use two-argument 
			//   $Data()=1 to eliminate a global ref
			If $D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"relMap"))&&
				($D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"relMap",+$G(tNodeNums(1),1),+$G(tNodeNums(2),1),+$G(tNodeNums(3),1)),tRelMapSpec)=1) {
				// DTB225 - Gather the information stored in the relMap and then combine it with the contextual information collected thus far
				$$$CallCombineSpecs(tCellSpec,tFactCount,tCellSpec,tRelMapSpec)		// DTB981
			}

			// fold in slicer, if present
			// JMD1453
			// JMD1501 test against base spec as well
			If (tSlicerSpec'="")&&(tSlicerSpec'=tBaseSpec)&&tHasRelations {
				// DP-421810 - Local slicers are folded into the extent, related cube slicer specs still need to be folded in 
				// DP-424589 - Only fold in the specs corresponding to relationships to preserve the lookup keys in the JoinIndex
				$$$CallCombineSpecsRelOnly(tCellSpec,tFactCount,tCellSpec,tSlicerSpec)		// DTB981
			}


			// N.B. - Convenient debugging output that can be uncommmented to dump to the shell
			//Write ">>>>>>",tNodeNo(1),",",$G(tNodeNo(2)),",",$G(tNodeNo(3))," ",tCellMsr,!
			//Write ?10,"slice:",?30,$ListToString(tSlicerSpec,":"),!
			//Write ?10,$ListToString(tCellSpec,":")
			//Write "  ",tCellCalc," ",tHasExpression,!
			
			Set tValue = ""
			If ($D(tCMList)) {
				// The CMList is the current branch of the "cmbrMap". This section works through the 
				// virtual cells that are used to calculate the final currentmember value.
				Set cc = $O(tCMList(""),1,tCMSpec)
				While (cc'="") {
					// combine CMSpec with current cell spec
					// JMD1453.2 Move to inside loop
					Set tCMCellSpec = tCellSpec

					// JMD1453
					$$$CallCombineSpecs(tCMCellSpec,tFactCount,tCMCellSpec,tCMSpec)		// DTB981
					Set tValue = ""
					Set:tCellAgg="" tCellAgg="COUNT"
					If (tIsBitSet) {
						// !!!
					}
					ElseIf (tCellMsr="") {
						// no measure in context; count cells
						// actual aggregation occurs in consolidation phase
						If (tCellAgg = "NULL") {
							Set tValue = ""
						}
						Else {
							Set tValue = $$Count(tCMCellSpec,"","")
						}
					}
					Else {
						// measure in current member context; evaluate
						If (tCellAgg = "COUNT") {
							Set tValue = $$Count(tCMCellSpec,tCellMsr,tCellMsrType)
						}
						ElseIf (tCellAgg = "SUM") {
							Set tValue = $$Sum(tCMCellSpec,tCellMsr,tCellScale)
						}
						// JMD1488 add more cases
						ElseIf (tCellAgg = "MIN") {
							Set tValue = $$Min(tCMCellSpec,tCellMsr,tCellScale)
							Set tValue = $LB(tCellAgg,tValue)
						}
						ElseIf (tCellAgg = "MAX") {
							Set tValue = $$Max(tCMCellSpec,tCellMsr,tCellScale)
							Set tValue = $LB(tCellAgg,tValue)
						}
						ElseIf (tCellAgg = "AVG") {
							Set tAvgCount = $$Count(tCMCellSpec,tCellMsr,tCellScale)
							Set tAvgSum = $$Sum(tCMCellSpec,tCellMsr,tCellScale)
							Set tValue = $LB(tCellAgg,tAvgCount,tAvgSum)	// agg format
						}
						ElseIf (tCellAgg = "NULL") {
							Set tValue = ""
						}
						Else {
							Set tValue = $$Sum(tCMCellSpec,tCellMsr,tCellScale)
						}
					}

					// JMD852: special handling for drillthrough: set spec *if* there are values
					If (tIsDrillThru && (tValue'="")) {
						Set tValue = tCellSpec
					}

					// store the result
					Set tCMData(cc) = tValue
					Set tValue = ""

					// next spec
					Set cc = $O(tCMList(cc),1,tCMSpec)
				}
				// Put marker into value for this cell
				// we will replace during consolidation
				Set tValue = "N.A."

			} // cmlist
			ElseIf (tCellCalc && 'tHasExpression) {
				Set:tCellAgg="" tCellAgg="COUNT"
				If (tIsBitSet) {
					// compute bitset and save it in the result cache
					Set n = 0
					Set k = $O(tNodeNums(""))
					While (k'="") {
						Set tAddr($I(n)) = tNodeNums(k)
						Set k = $O(tNodeNums(k))
					}
					Set tChunk = $O(tExtent(""))
					While (tChunk '= "") {
						Set tMask = $$Mask(tCellSpec,tChunk,.tFactMask)

						// only 1 axis in answer
						// JMD948: if we are called again, union with prior results
						If ($G(tAddr(1))'="") {
							Set tPrio = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1),tChunk))
							If (tPrio'="") {
								$$$dsBitAorBIntoA(tMask,tPrio)		// DTB970
							}
							Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1),tChunk) = tMask
						}

						// next chunk
						Set tChunk = $O(tExtent(tChunk))
					}
				}
				ElseIf (tDistinctAxis'="") {
					// if we are the active bucket, then compute the distinct values
					If (pBucketNo = -1) {
						// see if we are excluding empty values
						// DP-410644 - Targeted on-demand load
						Set:'$D(tAxisNodes(tAxisKey(tDistinctAxis),tNodeNo(tDistinctAxis)),tDNode) (tDNode,tAxisNodes(tAxisKey(tDistinctAxis),tNodeNo(tDistinctAxis))) = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tNodeNo(tDistinctAxis)))
						Set tDExclude = ($LG(tDNode,7)="EXCLUDEEMPTY")

						// we have to loop over the set members here
						// do this recursively as we could be from a crossjoin
						// JMD1319: see if any of the *other* axes are NON EMPTY
						// if so, then the default count will be "" instead of 0
						Set tDCount = 0
						Set ka = $O(tNodeNo(""))
						While (ka'="") {
							If ((ka'=tDistinctAxis)&&(+$G(tAxisNonEmpty(ka)))) {
								Set tDCount = ""
								Quit
							}
							Set ka = $O(tNodeNo(ka))
						}

						Set tDLevel = 1
						Set tDSpec(tDLevel) = tCellSpec
						Set tDParent(tDLevel) = tNodeNo(tDistinctAxis)
						
						// DP-410644 - Check if the node and "ch" children are loaded
						Merge:'$D(tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel))) tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel)) = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tDParent(tDLevel))
						
						Set tDNodeNo(tDLevel) = $O(tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel),"ch",""))		// DTB986 - Use local axis reference
						While (tDNodeNo(tDLevel)'="") {
							// are there children?
							// DP-410644 - Check if the node and "ch" children are loaded
							Merge:'$D(tAxisNodes(tAxisKey(tDistinctAxis),tDNodeNo(tDLevel))) tAxisNodes(tAxisKey(tDistinctAxis),tDNodeNo(tDLevel)) = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tDNodeNo(tDLevel))
							While $D(tAxisNodes(tAxisKey(tDistinctAxis),tDNodeNo(tDLevel),"ch")) {		// DTB986 - Use local axis reference
								// build spec
								If (tDExclude) {
									Set tDNode = $G(tAxisNodes(tAxisKey(tDistinctAxis),tDNodeNo(tDLevel)))		// DTB986 - Use local axis reference
									Set tDKey = $LG(tDNode,6)
									Set tDFact = $LG(tDNode,7)
									// directly replace fact in spec
									If ((tDFact'="")&&(tDKey'="")) {
										// JMD1453.2

										// DTB980 - Skip the function call if possible
										If ( ($LL(tDSpec(tDLevel))/(tFactCount+1))=1 ) {
											// Since the %SetFactIntoSpec will be using force=1, only need to test ORCount=1
											Set $List(tDSpec(tDLevel),tDFact+1) = tDKey
										}
										Else {
											Set tDSpec(tDLevel) = ..%SetFactIntoSpec(tFactCount,tDSpec(tDLevel),tDFact,tDKey,1)
										}
									}
								}
								Set tDLevel = tDLevel + 1
								Set tDParent(tDLevel) = tDNodeNo(tDLevel-1)
								Set tDSpec(tDLevel) = tDSpec(tDLevel-1)
								
								// DP-410644 - Check if the node and "ch" children are loaded
								Merge:'$D(tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel))) tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel)) = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tDParent(tDLevel))
								Set tDNodeNo(tDLevel) = $O(tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel),"ch",""))		// DTB986 - Use local axis reference
							}

							If ('tDExclude) {
								Set tDCount = tDCount + 1
							}
							Else {
								// DP-410644 - Targeted on-demand load
								Set:'$D(tAxisNodes(tAxisKey(tDistinctAxis),tDNodeNo(tDLevel)),tDNode) (tDNode,tAxisNodes(tAxisKey(tDistinctAxis),tDNodeNo(tDLevel))) = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tDNodeNo(tDLevel)))
								Set tDKey = $LG(tDNode,6)
								Set tDFact = $LG(tDNode,7)
								If ((tDFact'="")&&(tDKey'="")) {
									// directly replace fact in spec
									// JMD1453.2
									// DTB980 - We might know here that we don't actually need the processing in this method.
									// Test the inputs first to see if that is the case.
									If ( ($LL(tDSpec(tDLevel))/(tFactCount+1))=1 ) {
										// Since the %SetFactIntoSpec will be using force=1, only need to test ORCount=1
										Set $List(tDSpec(tDLevel),tDFact+1) = tDKey
									}
									Else {
										Set tDSpec(tDLevel) = ..%SetFactIntoSpec(tFactCount,tDSpec(tDLevel),tDFact,tDKey,1)
									}
								}
								
								// JMD1050: combine spec with orginal spec and test
								// JMD1453.4 we still need to combine in order to zero out
								// competing keys (COUNT (ASIA) WHERE EUROPE)
								$$$CallCombineSpecs(tTestSpec,tFactCount,tCellSpec,tDSpec(tDLevel))		// DTB981
								$$$CallExists(tExists,tTestSpec,tCellMsr,tCellMsrType)		// DTB971
								Set:tExists tDCount = tDCount + 1
							}

							// next
							// DP-410644 - Check if the node and "ch" children are loaded
							Merge:'$D(tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel))) tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel)) = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tDParent(tDLevel))
							Set tDNodeNo(tDLevel) = $O(tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel),"ch",tDNodeNo(tDLevel)))		// DTB986 - Use local axis reference
							While ((tDLevel>1)&&(tDNodeNo(tDLevel)="")) {
								Set tDLevel = tDLevel - 1
								Set tDNodeNo(tDLevel) = $O(tAxisNodes(tAxisKey(tDistinctAxis),tDParent(tDLevel),"ch",tDNodeNo(tDLevel)))		// DTB986 - Use local axis reference
							}
						}
						Set tValue = tDCount
					}
				}
				ElseIf (tCellMsr="") {
					// no measure in context; count cells
					If ((tCellAgg = "MIN")||(tCellAgg = "MAX")||(tCellAgg = "AVG")) {
						Set tValue = 1
					}
					ElseIf (tCellAgg = "NULL") {
						Set tValue = ""
					}
					Else {
						Set tValue = $$Count(tCellSpec,"","")
					}
				}
				Else {
					// measure in context; evaluate
					If (tCellAgg = "COUNT") {
						Set tValue = $$Count(tCellSpec,tCellMsr,tCellMsrType)
					}
					ElseIf (tCellAgg = "SUM") {
						Set tValue = $$Sum(tCellSpec,tCellMsr,tCellScale)
					}
					ElseIf ($P(tCellAgg,":",1) = "MIN") {
						Set tValue = $$Min(tCellSpec,tCellMsr,tCellScale)
						Set tValue = $LB(tCellAgg,tValue)
					}
					ElseIf ($P(tCellAgg,":",1) = "MAX") {
						Set tValue = $$Max(tCellSpec,tCellMsr,tCellScale)
						Set tValue = $LB(tCellAgg,tValue)
					}
					ElseIf ($P(tCellAgg,":",1) = "AVG") {
						Set tAvgCount = $$Count(tCellSpec,tCellMsr,tCellMsrType)
						Set tAvgSum = $$Sum(tCellSpec,tCellMsr,tCellScale)
						Set tValue = $LB(tCellAgg,tAvgCount,tAvgSum)	// agg format
					}
					ElseIf ($P(tCellAgg,":",1) = "NULL") {
						Set tValue = ""
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,"Unknown aggregate in ExecuteForBucket: " _ tCellAgg)
						Quit
					}
				}			

				// JMD852: special handling for drillthrough: set spec *if* there are values
				If (tIsDrillThru && (tValue'="")) {
					If (tSlicerSpec'="") {
						// DP-421810 - Since the drillthrough is returning the cell context spec as the cell value at this stage, it needs to have the complete
						// combination of all avialable specs. 
						$$$CallCombineSpecs(tCellSpec,tFactCount,tCellSpec,tSlicerSpec)
					}
					Set tValue = tCellSpec
				}
			} // calculated

			If (tValue'="") {
				// store value: construct address from node #s
				Kill tAddr
				Set n = 0
				Set k = $O(tNodeNums(""))
				While (k'="") {
					Set tAddr($I(n)) = tNodeNums(k)
					Set k = $O(tNodeNums(k))
				}
				
				// DTB400 - Resolve agg address
				Set tSC = ##class(%DeepSee.Query.Engine).%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,tAxisCount)
				If $$$ISERR(tSC) Quit
				
				// write value to cache
				Goto $Case(tRealAxisCount,0:DIM0,1:DIM1,2:DIM2,3:DIM3,:DIMERR)
DIM0
				Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot) = tValue
				Merge:$D(tCMData) $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,"ch") = tCMData
				Goto POSTDIM
DIM1
				Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1)) = tValue
				Merge:$D(tCMData) $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1),"ch") = tCMData
				Goto POSTDIM
DIM2
				Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1),tAddr(2)) = tValue
				Merge:$D(tCMData) $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1),tAddr(2),"ch") = tCMData
				Goto POSTDIM
DIM3
				Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1),tAddr(2),tAddr(3)) = tValue
				Merge:$D(tCMData) $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tResultSlot,tAddr(1),tAddr(2),tAddr(3),"ch") = tCMData
				Goto POSTDIM
DIMERR
				Set tSC = $$$ERROR($$$GeneralError,"Too many dimensions in query: " _ (tAxisCount))
				Quit
POSTDIM
			}

			// find next cell intersection
			Set tAxis = tAxisCount
			If (tAxis=0) {
				Set tDone = 1
			}
			While ('tDone) {
				// DP-410644 - The "all" branch is specifically loaded at the outset so does not need to be tested here
				Set tNodeNo(tAxis) = $O(tAxisNodes(tAxisKey(tAxis),tAxisRoot(tAxis),"all",tNodeNo(tAxis)))		// DTB986 - Use local axis reference
				If ((tNodeNo(tAxis)'="") && (tNodeNo(tAxis)'=tEndNode(tAxis))) {
					Do SetContext(tAxis)
					Quit
				}
				// try previous axis
				If ((tAxis > 1) && (tStartNode(tAxis)'="")) {
					Set tNodeNo(tAxis) = tStartNode(tAxis)
					// reset context
					Do SetContext(tAxis)
					Set tAxis = tAxis - 1
				}
				Else {
					Set tDone = 1
					Quit
				}
 			}
		}	// While ('tDone)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	$$$dsStopTimer		// DTB968

	// DP-421585 - Log some information about the state of the runtime cache as of the completion of
	// this computation 
	If $$$dsLoggingOn(2) {
		Set sub = $O($$$dsRuntimeCache(""),1,nodeData) 
		Set tCacheNodes=0
		
		While (sub'="") {		// Accumulate data about the %cache nodes
			If sub'="context" {
				// Ignore the "context" part of the caceh in this count
				Set tTotalNodeSize = $G(tTotalNodeSize) + $L($Name($$$dsRuntimeCache(sub)))+$L(nodeData)
				Do $I(tCacheNodes)
			}

			Set sub = $O($$$dsRuntimeCache(sub),1,nodeData) 
		}

		Set newSampleCount = $I($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"samples"))

		// Record a running average of per-bucket cache statistics 
		If $G(tCacheNodes) {
			Set currAvg = $G(tTotalNodeSize)/tCacheNodes
			Do:$G(currAvg) $I($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"size","avg node size"),(currAvg-$G($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"size","avg node size")))/newSampleCount)
			Do $I($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"size","avg node count"),(tCacheNodes-$G($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"size","avg node count")))/newSampleCount)
		}

		Do $I($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"context","set"),$G(%cacheStats("context","set")))
		Do $I($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"context","read"),$G(%cacheStats("context","read")))
		Do $I($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"call","read"),$G(%cacheStats("read")))
		Do $I($$$dsLoggingGlobal("cache",$$$dsCurrentMethod,"call","set"),$G(%cacheStats("set")))
	}

	Quit tSC

	// set context for the given node
SetContext(tAxis)
	Kill tExpression(tAxis)
	Kill tLiteral(tAxis)
	Kill tSolveOrder(tAxis)
	
	// DP-410644 - Targeted on-demand load
	Merge:'$D(tAxisNodes(tAxisKey(tAxis),tNodeNo(tAxis))) tAxisNodes(tAxisKey(tAxis),tNodeNo(tAxis)) = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis))
	Set tNode = $G(tAxisNodes(tAxisKey(tAxis),tNodeNo(tAxis)))		// DTB986 - Use local axis reference	
	Set tType = $LG(tNode,1)
	Set tSpec(tAxis) = tBaseSpec
	Set tCalc(tAxis) = +$LG(tNode,3)
	
	// DTB986 - If this node has been visited, look it up and skip the work.
	// This cache cannot be used when a CURRENTMEMBER is in play.
	Set tRunTimeCacheKey = $LB("SetContext",tAxis,tAxisKey(tAxis),tNodeNo(tAxis))
	If $G($$$dsRuntimeCache(tRunTimeCacheKey))&&'tHasCMBR {
		Do $I(%cacheStats("context","read"))		// DP-421585 - Count cached context use
		Set tAgg(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"agg")
		Set tDistinct(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"distinct")
		Merge tExpression(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"expr")
		Set tLevel(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"level")
		Set tLiteral(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"lit")
		Set tMeasure(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"msr")
		Set tMeasureType(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"msrType")
		Set tMsrScale(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"msrScale")
		Set tSkipFacts(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"skip")
		Set tSolveOrder(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"solve")
		Set tSpec(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"spec")
		Set tSubstSpec(tAxis) = $$$dsRuntimeCache(tRunTimeCacheKey,"subSpec")
		
		Quit
	}
	
	
	// ==== Start calculation work if there was no lookup to re-use
	// JMD1453: check for "orset";
	Set tInOR = 0
	Set tInORtuple = 0		// "ortuple": tuple as leg of OR

	// list of "orsets", by OR and branch within OR
	Set tORSetNo = 0
	Kill tORList

	// build chain of nodes back up to the top
	Kill tChain,tChainNode
	Set tLevelCount = 1
	Set tChain(tLevelCount) = tNodeNo(tAxis)
	Set tChainNode(tLevelCount) = tNode

	Set tParentNo = $LG(tNode,4)
	While (tParentNo '= "") {
		Set tLevelCount = tLevelCount + 1
		Set tChain(tLevelCount) = tParentNo
		
		// DP-410644 - Check for this single node and load if necessary
		Set:'$D(tAxisNodes(tAxisKey(tAxis),tParentNo),tParentNode) (tParentNode,tAxisNodes(tAxisKey(tAxis),tParentNo)) = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tParentNo))
		
		Set tChainNode(tLevelCount) = tParentNode
		Set tNewParentNo = $LG(tParentNode,4)
		If (tParentNo = tNewParentNo) {
			// cycle: should not happen
			Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Internal error: Cycle detected in axis"))
		}
		Set tParentNo = tNewParentNo
	}

	// build stacks of node info from top down
	Kill tSkipSet
	Set tLevel = 0
	For nn = tLevelCount:-1:1 {
		Set tLevel = tLevel + 1
		Set tLevel(tAxis) = tLevel		// DTB971 - Maintain this set as before, but use the tLevel variable in this context

		Set tSNode = tChainNode(nn)
		Set tSType = $LG(tSNode,1)
		Set tKey = $LG(tSNode,6)
		Set tFact = $LG(tSNode,7)

		Set tStackSpec(tAxis,tLevel) = $G(tStackSpec(tAxis,tLevel-1),tBaseSpec)

		Set sf = $LG(tSNode,20)
		If (sf'="") {
			For sx = 1:1:$L(sf,",") {
				Set fno = $P(sf,",",sx)
				// use key for current fact, if present
				Set tSkipSet(fno) = $S(tFact=fno:tKey,1:"")
			}
		}

		// JMD735: init stack vars
		Set tStackMeasure(tAxis,tLevel) = ""
		Set tStackMeasureType(tAxis,tLevel) = ""
		Set tStackAgg(tAxis,tLevel) = ""
		Set tStackScale(tAxis,tLevel) = ""
		Set tStackDistinct(tAxis,tLevel) = ""

		// test for %DISTINCT
		If (tSType = "agg") {
			If ($LG(tSNode,6)="%DISTINCT") {
				Set tStackDistinct(tAxis,tLevel) = 1
			}
		}

		If (tSType = "exp") {
			Set:+$LG(tSNode,15) tSolveOrder(tAxis)=+$LG(tSNode,15)
		}
		ElseIf (tSType = "lit") {
			Set:+$LG(tSNode,15) tSolveOrder(tAxis)=+$LG(tSNode,15)
		}
		ElseIf (tSType = "msr") {
			Set:+$LG(tSNode,15) tSolveOrder(tAxis)=+$LG(tSNode,15)
			Set tStackMeasure(tAxis,tLevel) = tFact
			// JMD1382 use 17
			Set tStackMeasureType(tAxis,tLevel) = $LG(tSNode,17)
			Set tStackAgg(tAxis,tLevel) = $LG(tSNode,8)
			Set tStackScale(tAxis,tLevel) = $LG(tSNode,13)
		}
		ElseIf (tSType = "orset") {
			// JMD1453 start accumulating an "orset"
			Set tORSetNo = tORSetNo + 1
			Set tInOR = 1
			Set tInORtuple = 0
		}
		ElseIf (tSType = "ortuple") {
			// JMD1453 start accumulating an "ortuple"
			Set tInORtuple = 1
			// advance to next or branch
			If ($D(tORList(tORSetNo))) {
				Set ox = $I(tORList(tORSetNo))
			}
		}
		ElseIf (tSType = "tuple") {
			// JMD1453 stop accumulating "orset"
			Set tInOR = 0
			Set tInORtuple = 0
			
			// WAL028 - Inherit measure context for tuple
			Set tStackMeasure(tAxis,tLevel) = $G(tStackMeasure(tAxis,tLevel-1))
			Set tStackMeasureType(tAxis,tLevel) = $G(tStackMeasureType(tAxis,tLevel-1))
			Set tStackAgg(tAxis,tLevel) = $G(tStackAgg(tAxis,tLevel-1))
			Set tStackScale(tAxis,tLevel) = $G(tStackScale(tAxis,tLevel-1))
			Set:$G(tStackDistinct(tAxis,tLevel))="" tStackDistinct(tAxis,tLevel) = $G(tStackDistinct(tAxis,tLevel-1))

		}
		Else {
			// inherit current measure, agg
			Set tStackMeasure(tAxis,tLevel) = $G(tStackMeasure(tAxis,tLevel-1))
			Set tStackMeasureType(tAxis,tLevel) = $G(tStackMeasureType(tAxis,tLevel-1))
			Set tStackAgg(tAxis,tLevel) = $G(tStackAgg(tAxis,tLevel-1))
			Set tStackScale(tAxis,tLevel) = $G(tStackScale(tAxis,tLevel-1))
			Set:$G(tStackDistinct(tAxis,tLevel))="" tStackDistinct(tAxis,tLevel) = $G(tStackDistinct(tAxis,tLevel-1))

			// set spec for this level
			If (tSType'="cmbr") {
				If ((tFact'="")&&(tKey'="")) {
					If (tInOR) {
						If (tInORtuple) {
							// JMD1453: add to current ortuple
							Set ox = $G(tORList(tORSetNo))
							Set:ox="" ox = $I(tORList(tORSetNo))
							
							// DTB980 - We might know here that we don't actually need the processing in this method.
							// Test the inputs first to see if that is the case.
							Set tTempSpec = tStackSpec(tAxis,tLevel)
							If ( ($LL(tTempSpec)/(tFactCount+1))=1 ) && 
								( $LG(tTempSpec,tFact+1)="" ) {
								Set $List(tTempSpec,tFact+1) = tKey
							}
							Else {
								Set tTempSpec = ..%SetFactIntoSpec(tFactCount,tTempSpec,tFact,tKey)
							}
							
							$$$CallCombineSpecs(tORList(tORSetNo,ox),tFactCount,$G(tORList(tORSetNo,ox)),tTempSpec)		// DTB981
						}
						Else {
							// JMD1453: accumulate OR spec
							Set ox = $I(tORList(tORSetNo))
							
							// DTB980 - We might know here that we don't actually need the processing in this method.
							// Test the inputs first to see if that is the case.
							Set tTempSpec = tStackSpec(tAxis,tLevel)
							If ( ($LL(tTempSpec)/(tFactCount+1))=1 ) && 
								( $LG(tTempSpec,tFact+1)="" ) {
								Set $List(tTempSpec,tFact+1) = tKey
							}
							Else {
								Set tTempSpec = ..%SetFactIntoSpec(tFactCount,tTempSpec,tFact,tKey)
							}
							
							Set tORList(tORSetNo,ox) = tTempSpec
						}
					}
					Else {
						// DTB980 - We might know here that we don't actually need the processing in this method.
						// Test the inputs first to see if that is the case.
						Set tTempSpec = tStackSpec(tAxis,tLevel)
						If ( ($LL(tTempSpec)/(tFactCount+1))=1 ) && 
							( $LG(tTempSpec,tFact+1)="" ) {
							Set $List(tTempSpec,tFact+1) = tKey
						}
						Else {
							Set tTempSpec = ..%SetFactIntoSpec(tFactCount,tTempSpec,tFact,tKey)
						}
						
						Set tStackSpec(tAxis,tLevel) = tTempSpec
					}
				}
			}
		}

		Set tMeasure(tAxis) = $G(tStackMeasure(tAxis,tLevel))
		Set tMeasureType(tAxis) = $G(tStackMeasureType(tAxis,tLevel))
		Set tAgg(tAxis) = $G(tStackAgg(tAxis,tLevel))
		Set tDistinct(tAxis) = $G(tStackDistinct(tAxis,tLevel))
		Set tMsrScale(tAxis) = $G(tStackScale(tAxis,tLevel))
		Set tSpec(tAxis) = $G(tStackSpec(tAxis,tLevel))
		Set tSubstSpec(tAxis) = $G(tSubstStackSpec(tAxis,tLevel))
		
		// JMD1453: fold in OR sets
		Set oc = $O(tORList(""))
		While (oc'="") {
			Set tORSpec = ""
			Set ox = $O(tORList(oc,""))
			While (ox'="") {
				Set tORSpec = tORSpec _ $G(tORList(oc,ox))
				Set ox = $O(tORList(oc,ox))
			}
			If (tORSpec'="") {
				$$$CallCombineSpecs(tSpec(tAxis),tFactCount,tSpec(tAxis),tORSpec)		// DTB981
			}
			Set oc = $O(tORList(oc))
		}

		Kill tSkipFacts(tAxis)
		// JMD: test before merge
		Merge:$D(tSkipSet) tSkipFacts(tAxis) = tSkipSet
		If (tType = "exp") {
			Set tExpression(tAxis) = ""
		}
		ElseIf (tType = "lit") {
			Set tLiteral(tAxis) = $LG(tNode,6)
		}
	} // For nn
	
	
	// ==== Store The Return Settings
	Set $$$dsRuntimeCache(tRunTimeCacheKey) = 1
	
	Do $I(%cacheStats("context","set"))		// DP-421585 - Count cached context sets
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"agg") = $G(tAgg(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"distinct") = $G(tDistinct(tAxis))
	Merge $$$dsRuntimeCache(tRunTimeCacheKey,"expr") = tExpression(tAxis)
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"level") = $G(tLevel(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"lit") = $G(tLiteral(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"msr") = $G(tMeasure(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"msrType") = $G(tMeasureType(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"msrScale") = $G(tMsrScale(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"skip") = $G(tSkipFacts(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"solve") = $G(tSolveOrder(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"spec") = $G(tSpec(tAxis))
	Set $$$dsRuntimeCache(tRunTimeCacheKey,"subSpec") = $G(tSubstSpec(tAxis))
	
	Quit
	
	// + WAL296 -- function added
	//             avoiding method call since this is a performance intensive area
	//             of the engine
CheckCellCache(tAddr)
	// Check the addr (against pKey, the query key)
	Set tFresh = 1
	Quit:((tAddr="")||(tAddr'["@")) tFresh

	// DP-418010 - If there are related queries in the address, test each of the subqueries to see if this
	// cell cache address is up to date. This starts by walking the subquery array and compares to the supplied address.
	Merge:'$D(tSubQueries) tSubQueries = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"subquery")
	
	Set tSubQueryCube = $O(tSubQueries(""))
	While ((tSubQueryCube'="")&&tFresh) {
		Set tSubQueryKey = $O(tSubQueries(tSubQueryCube,""))
		While ((tSubQueryKey'="")&&tFresh) {
			// Check to see if this subQuery is in the cell cache address at all. If it is check the timestamps.
			Set pos = 0
			For k = 1:1:($L(tAddr,"@"_tSubQueryKey)-1) {
				// DP-418010 - Test all instances of the current subquery in the cell cache address itself for up-to-date
				// If any are stale, then the whole address is stale.
				Quit:'tFresh
			
				Set pos = $Find(tAddr,tSubQueryKey,pos)
				Set tSubQCellAddr = "@"_tSubQueryKey_$P($P($E(tAddr,pos,*),":",1),"*",1)

				Set:'$D(tCubeTime(tSubQueryCube)) tCubeTime(tSubQueryCube) = ##class(%DeepSee.Utils).%GetCubeDSTime(tSubQueryCube)
				Set tFresh = '(tCubeTime(tSubQueryCube)>$P(tSubQCellAddr,"-",4))
			}

			Set tSubQueryKey = $O(tSubQueries(tSubQueryCube,tSubQueryKey))
		}

		Set tSubQueryCube = $O(tSubQueries(tSubQueryCube))
	}
	
	Quit tFresh
	// - WAL296

	// convert spec to a cache address
	Set tSpec =""
SpecToAddr(tSpec)
	// JMD918: correct call to %CanonizeAddr
	For px=1:1:$LL(tSpec) {
		Set:$LG(tSpec,px)["&" $List(tSpec,px) = ..%CanonizeAddr($LG(tSpec,px))
	}
	// remove trailing :
	// DP-423012 - This spec is likely reduced to contain only the position context information. Always tag it with a prepended
	//   slicerKey to differentiate between identical visual contexts with differing slicers.
	Set tCacheAddr = $G(tSlicerKey,0) _ ":" _$ZSTRIP($ListToString(tSpec,":"),">",":")
	
	// JMD1169
	Quit $S(($L(tCacheAddr)+$L(tCubeIndex))>480:"",1:tCacheAddr)

	// Get bit mask for the given spec
Mask(tSpec,tChunk,tFactMask)
	If (tShowPlan) {
		Set tFactMask = ""
	}

	// Calculate the caching slot based on the chunk if it wasn't supplied with the incoming pExtent array
	If ($G(tSlotNo)="") {
		// If the cache slot hasn't been supplied, do the work to determine it from the current update state
		Set tBucket = ((tChunk-1)\$$$DeepSeeChunksPerBucket(tCubeIndex))+1
		Set tSlotNo = $G($$$DeepSeeBucketsGLVN(tCubeIndex,"active",tBucket),tBucket)
	}

	// DP-421810 - Check to see if this cell mask has been calculated with the extent limited by this specific slicer
	$$$dsSafeRefCheckData($$$DeepSeeMaskGLVN(tCubeIndex,"cell",tSlotNo,$G(tSlicerKey,0),tChunk,tSpec),tMask,tIsSafe,tHasData)
	If tIsSafe&&tHasData {
		$$$dsGloCacheRead("cell")
		Quit tMask
	}

	// JMD1453 the spec may contain multiple OR specs, each tFactCount+1 long
	Set tOrCount = $LL(tSpec)/(tFactCount+1)
	Set tOrMask = "" 
	For oc = 1:1:tOrCount {
		set tMask = $G(tExtent(tChunk))
		set:(tMask = "") tMask = $G($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk)) //the cube's entire extent is used by Exists for JMD836'S COUNT optimizations
		For fc = 1:1:tFactCount {
			// translate fc to fact #
			Set f = $LG(tFactOrder,fc+1)
			Set tOrOffset = (oc-1)*(tFactCount+1)

			// JMD879: test for missing f
			Set k = $S(f="":"",1:$LG(tSpec,f+1+tOrOffset))
			If (k'="") {
				If (tShowPlan) {
					Set $List(tFactMask,f) = 1
				}
				If (tHasRelations && $D(tRelation(f)) && ($E(k)="@")) { // this is a relation
					// JMD1501 normalize key code so that it matches join index
					Set kcode = ..%CanonizeRelationKey(k)

					// JMD1017
					Set khash = $S($L(kcode)<100:kcode,1:$ZCRC(kcode,7))	// DTB055 - use the canonized kcode
					$$$dsBitAandBIntoA(tMask,$$$DeepSeeJoinGLVN(tCubeIndex,f,khash,tChunk))		// DTB970
				}
				Else {
					For j = 1:1:$L(k,"&") {
						Set k2 = $P(k,"&",j)
						If (k2'="") {
							Kill tTest
							If (k2["|") {
								// OR
								// DTB984 - The mask for this OR can be accumulated in one pass as long as
								// the incoming mask is preserved throughout the loop over "|" pieces. This gets
								// accumulated in the tTempOrMask and replaces the incoming tMask when the loop is complete.
								Set tTempOrMask=""
								For j2 = 1:1:$L(k2,"|") {
									Set k3 = $P(k2,"|",j2)
									If (k3'="") {
										If ($E(k3)="!") {
											// strip off marker and negate index
											Set k3 = $E(k3,2,*)
											$$$dsBitLogicArbitraryList(tTempOrMask|(tMask&~$$$DeepSeeIndexGLVN(tCubeIndex,f,k3,tChunk)),tTempOrMask,"BitAND,BitOR")
										}
										Else {
											$$$dsBitLogicArbitraryList(tTempOrMask|(tMask&$$$DeepSeeIndexGLVN(tCubeIndex,f,k3,tChunk)),tTempOrMask,"BitAND,BitOR")
										}
									}
								}
								
								Set tMask = tTempOrMask		// DTB984
							}
							Else {
								// test for NOT (!)
								If ($E(k2)="!") {
									// strip off marker and negate index
									Set k2 = $E(k2,2,*)
									$$$dsBitAandNotBIntoA(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,f,k2,tChunk))		// DTB970
								}
								Else {
									$$$dsBitAandBIntoA(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,f,k2,tChunk))		// DTB970
								}
							}
						}
					}
				}
				// DTB984 - Move the quit condition so that it always examines the result of processing this fact 
				$$$dsBitFind(tMask,1,tTempBit)
				Quit:'tTempBit
			}
		}
		If (tOrCount>1) {
			$$$dsBitAorBIntoA(tOrMask,tMask)		// DTB970
		}
	} // oc

	If (tOrCount>1) {
		$$$dsBitNormalize(tOrMask,tMask)		// DTB970
	}
	$$$dsBitCount(tMask,1,tTempBitCount)		// DTB970
	Set:tTempBitCount=0 tMask=""
	
	// DP-421810 - Cache the final cell mask accounting for the extent limited by a specific slicer
	If (tChunk'=$$$DeepSeeActiveChunk(tCubeIndex)) && tSlotNo {
		$$$dsSafeRef($$$DeepSeeMaskGLVN(tCubeIndex,"cell",tSlotNo,$G(tSlicerKey,0),tChunk,tSpec),tVal,tIsSafe) 
		If tIsSafe {
			$$$dsGloCacheSet("cell")
			Set $$$DeepSeeMaskGLVN(tCubeIndex,"cell",tSlotNo,$G(tSlicerKey,0),tChunk,tSpec) = tMask
		}
	}

	Quit tMask

	// Basic Aggregates
	Set tSpec = ""
	Set tMeasure = "" // if supplied, this is the current measure
	Set tMeasureType = ""
Count(tSpec,tMeasure,tMeasureType)
	Set tAddr = ""
	If tUseCache {
		$$$CallSpecToAddr(tSpec,tAddr)		// DTB980
	}

	Set:(tMeasure'="") tMeasureNo = +$E(tMeasure,2,*) // WAL298
	// WAL296 -- can check related cube cache from the addr here
	//           although I am worried about performance ramifications of 
	//           doing too much work in this specific call
	// 			 Skipping the if else block below means not using the cell cache
	//           We don't need to do this if no relationships, so perhaps add that
	//           check as an optimization
	$$$CallCheckCellCache(tFreshCellCache,tAddr)		// DTB971
	// - WAL296
	If (tFreshCellCache && tUseCache) {
		If (tMeasure'="") {
			Set tMeasureNo = +$E(tMeasure,2,*)
			// DTB401 - Test reference with macro
			// DTB971 - Use dsSafeRefCheckData to reference the global only once.
			$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),val,tIsSafe,tHasData)				
			If (tIsSafe && tHasData) {
				If $LD(val,$$$DeepSeeAggCOUNT) {
					Set x=$I(pStats($$$dsqStatCache))
					Quit $LG(val,$$$DeepSeeAggCOUNT)
				}
			}
		}
		Else {
			// DTB401 - Test reference with macro
			// DTB971 - Use dsSafeRefCheckData to reference the global only once.
			$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr),val,tIsSafe,tHasData)
			If (tIsSafe && tHasData) {
				Set x=$I(pStats($$$dsqStatCache))
				Quit val
			}
		}
	}
	Set x=$I(pStats($$$dsqStatCompute))

	// calculate count from indices
	If (tMeasure'="") {
		// compute count including measure index
		Set tCount = ""
		Set tChunk = $O(tExtent(""))
		While (tChunk '= "") {
			Set tMask = $$Mask(tSpec,tChunk,.tFactMask)
			$$$dsBitFind(tMask,1,tTempBit)		// DTB970
			If (tTempBit) {
				If (tMeasureType = "B") { // boolean: look at "true" index
					// DTB970 - Use macros
					$$$dsBitAandB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,1,tChunk),tTempBits)
					$$$dsBitCount(tTempBits,1,c)
				}
				Else {
					// DTB970 - Use macros
					$$$dsBitAandNotB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,"N",tChunk),tTempBits)
					$$$dsBitCount(tTempBits,1,c)
				}
				Set:c>0 tCount = tCount + c
			}
			Set tChunk = $O(tExtent(tChunk))
		}
	}
	Else {
		Set tCount = ""
		Set tChunk = $O(tExtent(""))
		While (tChunk '= "") {
			Set tMask = $$Mask(tSpec,tChunk,.tFactMask)
			$$$dsBitCount(tMask,1,c)		// DTB970
			Set:c>0 tCount = tCount + c
			Set tChunk = $O(tExtent(tChunk))
		}
	}

	If (tShowPlan) {
		// remember which indices were needed
		If (tMeasure'="") {
			Set tFactMask = $G(tFactMask)
			Set:tFactMask="" tFactMask = 0 	// no dimensions
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"keys",tFactMask,tMeasure) = ""
		}
		ElseIf ($G(tFactMask)'="") {
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"keys",tFactMask) = ""
		}
	}

	// store value in cell cache
	If (tMeasure'="") {
		// DTB401 - Test reference with macro
		$$$dsSafeRef($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),tVal,tIsSafe)
		Set:tIsSafe $List($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),$$$DeepSeeAggCOUNT) = tCount
	}
	Else {
		// DTB401 - Test reference with macro
		$$$dsSafeRef($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr),tVal,tIsSafe)
		Set:tIsSafe $$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr) = tCount
	}
	Quit tCount

	Set tSpec="",tMeasure=""

	// test if *any* value exists for the given spec
Exists(tSpec,tMeasure,tMeasureType)
	// we are only called for the active slot, so test slot 1
	
	$$$CallSpecToAddr(tSpec,tAddr)		// DTB980
	
	Set:(tMeasure'="") tMeasureNo = +$E(tMeasure,2,*) // WAL298
	
	// WAL296 -- Exists check cell cache
	$$$CallCheckCellCache(tFreshCellCache,tAddr)		// DTB971
	If (tFreshCellCache && tUseCache) {
		If (tMeasure'="") {
			Set tMeasureNo = +$E(tMeasure,2,*)
			// DTB401 - Test reference with macro
			// DTB971 - Use dsSafeRefCheckData to reference the global only once.
			$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,1,tAddr,tMeasureNo),val,tIsSafe,tHasData)				
			If (tIsSafe && tHasData) {
				// test the "count" cache; if there is a value, then we can skip the rest
				If ($LD(val,$$$DeepSeeAggCOUNT)&&($LG(val,$$$DeepSeeAggCOUNT)>0)) {
					Set x=$I(pStats($$$dsqStatCache))
					Quit 1
				}
			}
		}
		Else {
			// DTB401 - Test reference with macro
			// DTB971 - Use dsSafeRefCheckData to reference the global only once.
			$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,1,tAddr),val,tIsSafe,tHasData)				
			If (tIsSafe && tHasData) {
				// test the "count" cache; if there is a value, then we can skip the rest
				If (val>0) {
					Set x=$I(pStats($$$dsqStatCache))
					Quit 1
				}
			}
		}
	}

	Set x=$I(pStats($$$dsqStatCompute))

	// loop over *all* chunks in this cube, stop as soon as there is a bit
	Set tExists = 0
	If (tMeasure'="") {
		// use non-null measure index as well
		Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",""))
		While (tChunk '= "") {
			Set tMask = $$Mask(tSpec,tChunk,.tFactMask)
			$$$dsBitFind(tMask,1,tTempBit)		// DTB970
			If (tTempBit) {
				If (tMeasureType = "B") { // boolean: look at "true" index 
					// DTB970 - Use macros
					$$$dsBitAandB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,1,tChunk),tTempBits)
					$$$dsBitFind(tTempBits,1,c)
				}
				Else {
					// DTB970 - Use macros
					$$$dsBitAandNotB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,"N",tChunk),tTempBits)
					$$$dsBitFind(tTempBits,1,c)
				}
				If (c) {
					Set tExists = 1
					Quit
				}

			}
			Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk))
		}
	}
	Else {
		Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",""))
		While (tChunk '= "") {
			Set tMask = $$Mask(tSpec,tChunk,.tFactMask)
			$$$dsBitFind(tMask,1,tTempBit)		// DTB970
			If (tTempBit) {
				Set tExists = 1
				Quit
			}
			Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk))
		}
	}
	Quit tExists

	Set tSpec="",tMeasure=""

Sum(tSpec,tMeasure,tScale)
	// Note: measure *could* be boolean, but it all works out
	Set tScaleFactor = $Case(tScale,1:1E-1,2:1E-2,3:1E-3,4:1E-4,5:1E-5,6:1E-6,7:1E-7,8:1E-8,9:1E-9,10:1E-10,11:1E-11,12:1E-12,13:1E-13,14:1E-14,15:1E-15,16:1E-16,17:1E-17,18:1E-18,:1)

	Set tAddr = ""
	If tUseCache {
		$$$CallSpecToAddr(tSpec,tAddr)		// DTB980
	}
	Set tMeasureNo = +$E(tMeasure,2,*)
	
	// WAL296 -- Sum check cell cache
	$$$CallCheckCellCache(tFreshCellCache,tAddr)		// DTB971
	If (tFreshCellCache && tUseCache) {
		// DTB401 - Test reference with macro
		// DTB971 - Use dsSafeRefCheckData to reference the global only once.
		$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),val,tIsSafe,tHasData)				
		If (tIsSafe && tHasData) {
			If $LD(val,$$$DeepSeeAggSUM) {
				Set x=$I(pStats($$$dsqStatCache))
				Quit $LG(val,$$$DeepSeeAggSUM)
			}
		}
	}
	Set x=$I(pStats($$$dsqStatCompute))

	Set tSum = ""
	Set tCount = ""
	Set tChunk = $O(tExtent(""))
	While (tChunk '= "") {
		Set tMask = $$Mask(tSpec,tChunk,.tFactMask)
		If (tMask'="") {
			$$$dsBitAandB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,"-",tChunk),minus)		// DTB981 - Move outside of the tight loop
			Set tDigit = $O($$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,""))
			While (tDigit '= "") {
				If (+tDigit) {
					// DTB970 - Use macros
					$$$dsBitAandB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,tDigit,tChunk),data)
					
					$$$dsBitCount(data,1,tDataCount)
					$$$dsBitAandB(data,minus,tDataAndMinus)
					$$$dsBitCount(tDataAndMinus,1,tDMCount)
					
					Set sub = tDataCount-(2*tDMCount)
					Set:sub'=0 tSum = 2**(tDigit-1)*tScaleFactor*sub+tSum
				}
				Set tDigit = $O($$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,tDigit))
			}
			If (tSum = "") {
				$$$dsBitAandB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,"Z",tChunk),zeroBitStr)		// DTB970
				$$$dsBitCount(zeroBitStr,1,tZeroBitCount)
				If (tZeroBitCount > 0) { Set tSum = 0 }
			}
		}
		Set tChunk = $O(tExtent(tChunk))
	}
	If (tShowPlan) {
		// remember which indices were needed
		Set tFactMask = $G(tFactMask)
		Set:tFactMask="" tFactMask = 0 	// no dimensions
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"keys",tFactMask,tMeasure) = ""
	}
	
	// DTB401 - Test reference with macro
	$$$dsSafeRef($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),tVal,tIsSafe)				
	Set:tIsSafe $List($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),$$$DeepSeeAggSUM) = tSum
	Quit tSum

Min(tSpec,tMeasure,tScale)
	Set tAddr = ""
	If tUseCache {
		$$$CallSpecToAddr(tSpec,tAddr)		// DTB980
	}
	Set tMeasureNo = +$E(tMeasure,2,*)
	
	// WAL296 -- Min check cell cache
	$$$CallCheckCellCache(tFreshCellCache,tAddr)		// DTB971
	If (tFreshCellCache && tUseCache) {
		// DTB401 - Test reference with macro
		// DTB971 - Use dsSafeRefCheckData to reference the global only once.
		$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),val,tIsSafe,tHasData)				
		If (tIsSafe && tHasData) {
			If $LD(val,$$$DeepSeeAggMIN) {
				Set x=$I(pStats($$$dsqStatCache))
				Quit $LG(val,$$$DeepSeeAggMIN)
			}
		}
	}
	Set x=$I(pStats($$$dsqStatCompute))
	Set tMin = $$calcAggr(tSpec, tMeasure, 0, tScale)
	
	// DTB401 - Test reference with macro
	$$$dsSafeRef($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),tVal,tIsSafe)				
	Set:tIsSafe $List($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),$$$DeepSeeAggMIN) = tMin
	Quit tMin

Max(tSpec,tMeasure,tScale)
	Set tAddr = ""
	If tUseCache {
		$$$CallSpecToAddr(tSpec,tAddr)		// DTB980
	}
	Set tMeasureNo = +$E(tMeasure,2,*)
	
	// WAL296 -- Max check cell cache
	$$$CallCheckCellCache(tFreshCellCache,tAddr)		// DTB971
	If (tFreshCellCache && tUseCache) {
		// DTB401 - Test reference with macro
		// DTB971 - Use dsSafeRefCheckData to reference the global only once.
		$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),val,tIsSafe,tHasData)				
		If (tIsSafe && tHasData) {
			If $LD(val,$$$DeepSeeAggMAX) {
				Set x=$I(pStats($$$dsqStatCache))
				Quit $LG(val,$$$DeepSeeAggMAX)
			}
		}
	}
	Set x=$I(pStats($$$dsqStatCompute))
	Set tMax = $$calcAggr(tSpec, tMeasure, 1, tScale)
	
	// DTB401 - Test reference with macro
	$$$dsSafeRef($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),tVal,tIsSafe)				
	Set:tIsSafe $List($$$DeepSeeCellsGLVN(tCubeIndex,tResultSlot,tAddr,tMeasureNo),$$$DeepSeeAggMAX) = tMax
	Quit tMax

calcAggr(tSpec, tMeasure, isMax, tScale)
	s res = ""
	
	s chunk = $o(tExtent(""))	
	while (chunk '= "") { // go over all chunks
		s tMask = $$Mask(tSpec,chunk,.tFactMask)
		
		// JMD-ignore null values
		$$$dsBitCount(tMask,1,tTempBitCount)		// DTB970
		If (tTempBitCount>0) {
			$$$dsBitAandNotBIntoA(tMask,$$$DeepSeeIndexGLVN(tCubeIndex,tMeasure,"N",chunk))		// DTB970
		}
		s bitPos = $o($$$DeepSeeIndexGLVN(tCubeIndex, tMeasure, ""), -1)
		s chunkRes = "" // the result in this chunk

		s allBitStr = tMask // all candidate values in the chunk
		s negBitStr = $g($$$DeepSeeIndexGLVN(tCubeIndex, tMeasure, "-", chunk))
		if (negBitStr '= "") {
			if (isMax) { // calculate Max
				$$$dsBitAandNotB(allBitStr,negBitStr,posAllBitStr)		// DTB970
				$$$dsBitCount(posAllBitStr,1,tPosAllBitCount)
				if (tPosAllBitCount > 0) { // there are positive values, calculate max(|S|)
					s isAbsMax = 1, sign = 1, allBitStr = posAllBitStr
				}
				else { // only negative values, calculate min(|S|)
					$$$dsBitAandBIntoA(allBitStr,negBitStr)		// DTB980
					s isAbsMax = 0, sign = -1
				}
			}
			else { // calculate Min
				$$$dsBitAandB(allBitStr,negBitStr,negAllBitStr)		// DTB970
				$$$dsBitCount(negAllBitStr,1,tNegAllBitCount)
				if (tNegAllBitCount > 0) { // there are negative values, calculate max(|S|)
					s isAbsMax = 1, sign = -1, allBitStr = negAllBitStr
				}
				else { // only positive values, calculate min(|S|)
					$$$dsBitAandNotBIntoA(allBitStr,negBitStr)		// DTB970
					s isAbsMax = 0, sign = 1
				}
			}
		}
		else { // all values are positive
			s sign = 1, isAbsMax = isMax
		}
			
		$$$dsBitCount(allBitStr,1,tAllBitCount)		// DTB970
		while ((bitPos '= "") && (tAllBitCount > 0)) { // go over all bits in one chunk
			s bitStr = $g($$$DeepSeeIndexGLVN(tCubeIndex, tMeasure, bitPos, chunk)) // deleted ids are filtered in allBitStr						
			if (+bitPos && (bitStr '= ""))  {
				$$$dsBitAandB(bitStr,allBitStr,bitSet)		// DTB970
				If isAbsMax {
					$$$dsBitFind(bitSet,1,countBit)		// DTB970
				}
				Else {
					// need all bits
					$$$dsBitCount(bitSet,1,bitSetCount)
					$$$dsBitCount(allBitStr,1,allBitCount)
					s countBit = (allBitCount = bitSetCount)
				}
				if (countBit) {
					s allBitStr = bitSet
					s chunkRes = chunkRes + (2 ** (bitPos - 1)) 
				}
				else {
					$$$dsBitAandNotBIntoA(allBitStr,bitStr)		// DTB970
				}
			}
			$$$dsBitCount(allBitStr,1,tAllBitCount)		// DTB970
			s bitPos = $o($$$DeepSeeIndexGLVN(tCubeIndex, tMeasure, bitPos), -1)
		}
		
		if (chunkRes = "") {
			$$$dsBitAandB(tMask,$$$DeepSeeIndexGLVN(tCubeIndex, tMeasure, "Z", chunk),zeroBitStr)		// DTB970
			$$$dsBitCount(zeroBitStr,1,tZeroBitCount)
			if (tZeroBitCount > 0) { s chunkRes = 0 }
		}
		if (chunkRes '= "") {
			s chunkRes = sign * chunkRes	
			if ((res = "") || (isMax && (res < chunkRes)) || ('isMax && (res > chunkRes))) {
				s res = chunkRes 
			}
		}
		
		s chunk = $O(tExtent(chunk))			
	}

	If (tShowPlan) {
		// remember which indices were needed
		Set tFactMask = $G(tFactMask)
		Set:tFactMask="" tFactMask = 0 	// no dimensions
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"keys",tFactMask,tMeasure) = ""
	}
	Set tScaleFactor = $Case(tScale,1:1E-1,2:1E-2,3:1E-3,4:1E-4,5:1E-5,6:1E-6,7:1E-7,8:1E-8,9:1E-9,10:1E-10,11:1E-11,12:1E-12,13:1E-13,14:1E-14,15:1E-15,16:1E-16,17:1E-17,18:1E-18,:1)
	Quit $S(res="":"",1:res*tScaleFactor)
}

/// Insert the given fact/key into the given cell spec.
ClassMethod %SetFactIntoSpec(pFactCount As %Integer, pSpec As %List, pFact As %Integer, pKey As %String, pForce As %Boolean = 0) As %List [ Internal ]
{
	// JMD1453 if there are OR branches in the spec; apply fact to each
	Set tOrCount = $LL(pSpec)/(pFactCount+1)
	For oc = 1:1:tOrCount {
		Set tKey = pKey
		Set tOrOffset = (oc-1)*(pFactCount+1)
		If ('pForce) {
			Set ef = $LG(pSpec,pFact+1+tOrOffset)
			// test for conflicting facts; 
			// check for "@" for relationships
			If ((ef'="")&&(ef'=tKey)) {
				// JMD1509 check for relation keys and normalize!
				If ($E(tKey)="@") {
					Set tKey = ef _ "*" _ tKey
					Set tKey = ..%CanonizeRelationKey(tKey)
				}
				Else {
					Set tKey = ef _ "&" _ tKey
				}
			}
		}
		Set $List(pSpec,pFact+1+tOrOffset) = tKey
	}
	Quit pSpec
}

/// Combine 2 cell "specs" and return the resulting spec.<br>
/// Optionally set the <var>pRelationsOnly</var> flag to combine only the relation components of the spec.
ClassMethod %CombineSpecs(pFactCount As %Integer, pSpec1 As %List, pSpec2 As %List, pRelationsOnly = 0) As %List [ Internal ]
{
	If (pSpec1="") Quit pSpec2
	If (pSpec2="") Quit pSpec1

	// fold spec2 into spec1
	// find number of "or" pieces in each spec
	Set tOrCount1 = $LL(pSpec1)/(pFactCount+1)
	Set tOrCount2 = $LL(pSpec2)/(pFactCount+1)

	// make sure counts are integers!
	// (throw an error)
	If ((tOrCount1'=(tOrCount1\1))||(tOrCount2'=(tOrCount2\1))) {
		Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Internal error: %CombineSpecs"))
		Quit "INVALID SPEC"
	}

	// if no ORs, use simpler code
	If ((tOrCount1=1)&&(tOrCount2=1)) {
		For f = 1:1:pFactCount {
			Set tKey = $LG(pSpec2,f+1)

			// DP-424589 - If the pRelationsOnly flag is set and this fact is not a relation, leave this fact entry untouched and move on to the next
			If pRelationsOnly && ($E(tKey)'="@") Continue

			If (tKey'="") {
				Set ef = $LG(pSpec1,f+1)
				If ((ef'="")&&(ef'=tKey)) {
					// JMD1509 check for relation keys and normalize!
					If ($E(tKey)="@") {
						Set tKey = ef _ "*" _ tKey
						Set tKey = ..%CanonizeRelationKey(tKey)
					}
					Else {
						Set tKey = ef _ "&" _ tKey
					}
				}
				Set $List(pSpec1,f+1) = tKey
			}
		}

		Quit pSpec1
	}

	// deal with or*or
	// split s1 and s2 into pieces
	For s1 = 1:1:tOrCount1 {
		Set tOff = ((s1-1)*(pFactCount+1))
		Set tSpec(1,s1) = $List(pSpec1,1+tOff,pFactCount+tOff+1)
	}
	For s2 = 1:1:tOrCount2 {
		Set tOff = ((s2-1)*(pFactCount+1))
		Set tSpec(2,s2) = $List(pSpec2,1+tOff,pFactCount+tOff+1)
	}

	// now compute s1*s2
	For s1 = 1:1:tOrCount1 {
		For s2 = 1:1:tOrCount2 {
			Set tSpec1 = tSpec(1,s1)
			For f = 1:1:pFactCount {
				Set tKey = $LG(tSpec(2,s2),f+1)
				If (tKey'="") {
					Set ef = $LG(tSpec1,f+1)
					If ((ef'="")&&(ef'=tKey)) {
						Set tKey = ef _ $S($E(tKey)="@":"*",1:"&") _ tKey
					}
					Set $List(tSpec1,f+1) = tKey
				}
			}
			Set tOutput($I(tOutput)) = tSpec1
		}
	}
	
	// combine
	Set tOutSpec = ""
	Set k = $O(tOutput(""))
	While (k'="") {
		Set tOutSpec = tOutSpec _ tOutput(k)
		Set k = $O(tOutput(k))
	}
	Quit tOutSpec
}

/// Apply the slicer mask to a given query and bucket number.
ClassMethod %ApplySlicerMask(pCube As %String, pSlicerKey As %String = "", ByRef pExtent, pHasRelations As %Boolean = 0, ByRef pRelation) As %Status [ Internal ]
{
	Set tAddr = ""
	Set tCubeName = $$$UPPER(pCube)
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Set tSlotNo = $G(pExtent,0)

	Set tSC = $$$OK
	Try {
		// If there is no slicer key, there can be no change to the extent
		If (pSlicerKey="") Quit

		// apply slicer to every element within the provided extent list
		// N.B: It is assumed that this has already been verified to contain only non-null extent entries at this point
		Set tChunk = $O(pExtent(""))
		While (tChunk'="") {
			Set tLoadedFromCache = 0
			// DP-421810 - Check the cache for a previously completed slicer mask for this chunk
			// Don't read the active chunk
			If (tChunk'=$$$DeepSeeActiveChunk(tCubeIndex)) && $D($$$DeepSeeMaskGLVN(tCubeIndex,"slicer",tSlotNo,pSlicerKey,tChunk),tChunkMask) {
				$$$dsGloCacheRead("slicer")
				Set tLoadedFromCache = 1
			}
			Else {
				Kill tStackSpec,tStackOp	// All of the temp indices used in the calculation are going to need to be reset

				Set tSetOpDepth = 0						// Initialize for the current chunk
				Set tRollupOp = "and"
				Set tStackOp(0) = "and"					// Default operator behavior
				Set tStackSpec(0) = pExtent(tChunk)		// Might need this?

				// The primary loop navigates the nodes in the axis chain. Each item in the chain is treated as either a term or a component contributing to a term.
				// Nodes of type "mbr" or similar are simple terms in and of themselves, while the more complex set operations need to accumulate multiple results in
				// order to present themselves as a single term to their parent.
				
				// Find the top node of the axis chain. This convenience is unique to slicer processing since it will be pre-processed into an item of size=1
				Set tParentNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",""),1,tTopNode)
				For {
					// The loop quits when there is no longer a direct child of the previous parent node. Otherwise, it descends down to the next link in the chain.
					Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",tParentNodeNo,"ch",""),1)
					Quit:(tNodeNo="")
					Set tNode = $$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",tNodeNo)
				
					If $$$dsAxisNodeIsSetOp(tNode) {
						// - SET OPERATOR -
						// Log this information in the set operator stack and initialize a stackSpec location to collect the rolled up result.
						// The tStackSpec holds the bitmap that is to be rolled up into
						// The tStackOp contains the operation needed to perform the rollup
						
						If $G(tCurrRelationKey)'="" {
							// If a current relation has been accumulating, finish it off
							Set $$$dsAxisNodeKey(tVirtualNode) = $G(tCurrRelationKey)
							Set $$$dsAxisNodeFact(tVirtualNode) = $G(tCurrRelation)

							If $$MaskAxisNode(tVirtualNode,tChunk,.tMask) {
								$$$dsBitAandBIntoA(tStackSpec(tSetOpDepth),tMask)
							}
							Kill tCurrRelation,tCurrRelationKey		// Reset since this is complete
						}


						// If the SetOp depth of the current node is less than or equal to the running depth seen previously, roll up results to the level above
						// the new incoming depth and reset the new running depth. This rollup removes the 
						If (tSetOpDepth >= $$$dsAxisNodeSetOpDepthGet(tNode)) {
							// Do the rollup, starting with the current tSetOrDepth to the level above
							Set tRollupDepth = tSetOpDepth
							For {
								Set tRollupSource = tStackSpec(tRollupDepth)
								Kill tStackSpec(tRollupDepth),tStackOp(tRollupDepth)
								// Get the next rollup depth and fetch the operation for the next level up
								Set tRollupDepth = $O(tStackOp(tRollupDepth),-1,tRollupOp)
								If (tRollupOp="or") {
									$$$dsBitAorBIntoA(tStackSpec(tRollupDepth),tRollupSource)
								}
								ElseIf (tRollupOp="and") {
									$$$dsBitAandBIntoA(tStackSpec(tRollupDepth),tRollupSource)
								}

								// We want to perform the rollup for the first pass which has 
								//   tRollupDepth < (current node depth)
								// and then quit the first time a lower depth is encountered
								Quit:(tRollupDepth<$$$dsAxisNodeSetOpDepthGet(tNode))
							}
						} 

						

						// Establish the new running SetOpDepth for processing of the next node 
						Set tSetOpDepth = $$$dsAxisNodeSetOpDepthGet(tNode)
						
						// Track the current working operator for accumulating terms and initialize the accumulation target for this operator
						Set tStackOp(tSetOpDepth) = $$$dsAxisNodeSetOpType(tNode)
						Set tStackSpec(tSetOpDepth) = $Case(tStackOp(tSetOpDepth),"or":"",:pExtent(tChunk))		// Re-initialize this depth to the appropriate rollup target
					}
					ElseIf (tParentNodeNo=1)&&$$$IsDeepSeeNullAxisNode(tNode) {
						// DP-433445 - test for a null axis and immediately quit with a null bitmap
						Set tStackSpec(tSetOpDepth) = ""
						Quit
					}
					ElseIf ($$$dsAxisNodeTypeGet(tNode)="set")||($$$dsAxisNodeTypeGet(tNode)="msr")||($$$dsAxisNodeTypeGet(tNode)="lit")||($$$dsAxisNodeTypeGet(tNode)="agg") {
						// - NO-OP -
						// This is a calculation-neutral node in this context that may just pass through to the next child
					}
					ElseIf (tStackOp(tSetOpDepth)="and") {
						// - TERM (AND) -
						// This is an actual value that needs to be looked up in an index and AND'ed into a current result.

						// Accumulate intersecting relationship terms that are applied to the same remote cube with a compound *-delimited key.
						// This delays the actual call to $$Mask until the relation term is confirmed complete.
						If $D(pRelation(+$$$dsAxisNodeFactGet(tNode))) {
							If ($G(tCurrRelationKey)="") {
								// DP-433445 - This is the first actual relation key encountered in a chain
								Set tCurrRelationKey = $$$dsAxisNodeKeyGet(tNode)
								Set tCurrRelation = $$$dsAxisNodeFactGet(tNode)
							}
							ElseIf ($G(tCurrRelation)'="")&&($G(tCurrRelation)=$$$dsAxisNodeFactGet(tNode)) {
								// This is the same relation as before, accumulate the key 
								Set tCurrRelationKey = tCurrRelationKey_ "*" _ $$$dsAxisNodeKeyGet(tNode)
							}
							ElseIf ($G(tCurrRelation)'="")&&($G(tCurrRelation)'=$$$dsAxisNodeFactGet(tNode)) {
								// This is a different key than prior, mask the current key and start another one
								Set $$$dsAxisNodeKey(tVirtualNode) = tCurrRelationKey
								Set $$$dsAxisNodeFact(tVirtualNode) = tCurrRelation

								If $$MaskAxisNode(tVirtualNode,tChunk,.tMask) {
									$$$dsBitAandBIntoA(tStackSpec(tSetOpDepth),tMask)
								}

								// Now start the new relationKey
								Set tCurrRelationKey = $$$dsAxisNodeKeyGet(tNode)
								Set tCurrRelation = $$$dsAxisNodeFactGet(tNode)
							}
						}
						ElseIf ($$$dsAxisNodeIsAllMbr(tCubeIndex,tNode)) {
							// This is the "all" member, equivalent to contributing the current extent. In the AND case, this is equivalent to a no-op
						}
						ElseIf $$MaskAxisNode(tNode,tChunk,.tMask) {
							// Local term that has a result
							$$$dsBitAandBIntoA(tStackSpec(tSetOpDepth),tMask)
						}
						Else {
							// Local term that found no results, no need for more bit operations
							Set tStackSpec(tSetOpDepth) = ""
						}
					}
					ElseIf (tStackOp(tSetOpDepth)="or") {
						// - TERM (OR) -
						// This is an actual value that needs to be looked up in an index and OR'ed into a current result.
						If ($$$dsAxisNodeIsAllMbr(tCubeIndex,tNode)) {
							// This is the "all" member, equivalent to contributing the current extent. In the OR case, this is equivalent to including the
							// entire extent
							Set tStackSpec(tSetOpDepth) = pExtent(tChunk)
						}
						ElseIf $$MaskAxisNode(tNode,tChunk,.tMask) {
							$$$dsBitAorBIntoA(tStackSpec(tSetOpDepth),tMask)
						}
					}

					// Done processing this node, promote it to the parent node for the next pass
					Set tParentNodeNo = tNodeNo
				}

				If $G(tCurrRelationKey)'="" {
					// If a current relation is accumulating, finish it off
					Set $$$dsAxisNodeKey(tVirtualNode) = $G(tCurrRelationKey)
					Set $$$dsAxisNodeFact(tVirtualNode) = $G(tCurrRelation)

					If $$MaskAxisNode(tVirtualNode,tChunk,.tMask) {
						$$$dsBitAandBIntoA(tStackSpec(tSetOpDepth),tMask)
					}
					Kill tCurrRelation,tCurrRelationKey		// Reset since this is complete
				}
				
				// Perform a final rollup into tStackSpec(0) here since the chain has ran out of terms
				Set tRollupDepth = $O(tStackOp(""),-1,tRollupOp)
				If (tRollupDepth'=0) {
					For {
						Set tRollupSource = tStackSpec(tRollupDepth)
						Kill tStackSpec(tRollupDepth),tStackOp(tRollupDepth)
						// Get the next rollup depth and fetch the operation for the next level up
						Set tRollupDepth = $O(tStackOp(tRollupDepth),-1,tRollupOp)

						If (tRollupOp="or") {
							$$$dsBitAorBIntoA(tStackSpec(tRollupDepth),tRollupSource)
						}
						ElseIf (tRollupOp="and") {
							$$$dsBitAandBIntoA(tStackSpec(tRollupDepth),tRollupSource)
						}

						// This rolls up all the way to the top
						Quit:(tRollupDepth=0)
					}
				}
				// Set the chunk mask to reuse the caching code below
				Set tChunkMask = tStackSpec(0)
			}

			// Cache the result as a slicer
			If $D(tChunkMask) {
				// N.B: This needs to be ANDed in case the slicer mask includes information mapped from sources external to the cube
				Set pExtent(tChunk) = tChunkMask		// DP-424589 - No need to AND the chunk mask with the original extent since it was folded in as the final target of the rollup
				$$$dsBitFind(pExtent(tChunk),1,tBitPos)
				If ('tBitPos) {
					// The extent index provides a master index of which chunks need processing at all. Remove chunks from this
					// index early to uneccesary context processing.
					Kill pExtent(tChunk)
				}

				// DP-421810 - Cache the complete slicer mask, including the active chunk 
				If 'tLoadedFromCache && tSlotNo {
					$$$dsGloCacheSet("slicer")
					$$$dsBitNormalize(tChunkMask,$$$DeepSeeMaskGLVN(tCubeIndex,"slicer",tSlotNo,pSlicerKey,tChunk))		// DP-425943
				}
			}

			// next chunk
			Set tChunk = $O(pExtent(tChunk))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC

	// Directly convert an axis node into a mask for the requested chunk. The mask itself is returned in the tMask argument,
	// and the tag returns a boolean so the function can be used as a logic test.
MaskAxisNode(tAxisNode,tChunk,tMask) 
	Set tMaskData = 1
	Kill tMask

	Set fact = $$$dsAxisNodeFact(tAxisNode)
	Set key = $$$dsAxisNodeKey(tAxisNode)

	If ((fact'="")&&(key'="")) {
		If (pHasRelations && $D(pRelation(fact))&&($E(key)="@")) { // this is a relation
			Set key = ..%CanonizeRelationKey(key) // JSL4407		
			// JMD1017 use hash to prevent subscript error
			Set keyHash = $S($L(key)<100:key,1:$ZCRC(key,7))
			Set tMask = $G($$$DeepSeeJoinGLVN(tCubeIndex,fact,keyHash,tChunk))
			
		}
		Else {
			// test for OR and NOT in k
			// The mask for this OR can be accumulated in one pass as long as
			// the incoming mask is preserved throughout the loop over "|" pieces. This gets
			// accumulated in the tTempOrMask and replaces the tMask when the loop is complete.				
			Set tTempOrMask = ""
			For j=1:1:$L(key,"|") {
				Set keyPart = $P(key,"|",j)
				Set tNot = 0
				If ($E(keyPart)="!") {
					Set tNot = 1,keyPart = $E(keyPart,2,*)
				}
				If (tNot) {
					$$$dsBitLogicArbitraryList(tTempOrMask|(pExtent(tChunk)&~$$$DeepSeeIndexGLVN(tCubeIndex,fact,keyPart,tChunk)),tTempOrMask,"BitAND,BitOR")
				}
				Else {
					$$$dsBitAorBIntoA(tTempOrMask,$$$DeepSeeIndexGLVN(tCubeIndex,fact,keyPart,tChunk))
				}
			} // j
			
			Set tMask = tTempOrMask
		}
	}
	Else {
		Set tMaskData = 0
	}

	$$$dsBitFind(tMask,1,tTestBit)
	If 'tTestBit {
		Set tMask = "",tMaskData = 0
	}

	Quit tMaskData
}

/// For a given cube and query (key) return the number of
/// axes (including the slicer).<br/>
/// <var>pAxisType</var> is an array containing the type of each axis: "axis" or "slicer".<br/>
/// <var>pAxisNode</var> is an array containing the top node number for each axis.<br/>
/// <var>pAxisSize</var> is an array containing the number of leaf nodes for each axis.<br/>
/// <var>pSlicerAxis</var> indicates whether there is a slicer axis. If there is this will contain the axis number for the slicer otherwise 0.<br/>
ClassMethod %GetAxisInfo(pCubeName As %String, pKey As %String, Output pAxisType As %String, Output pAxisKey As %String, Output pAxisSize As %Integer, Output pSlicerAxis As %Boolean) As %Integer
{
	Set tAxisCount = 0
	Set pSlicerAxis = 0

	Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
	Set tSizeInfo = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"size"))
	Set tAxisCount = $LL(tSizeInfo)
	For a = 1:1:tAxisCount {
		Set tInfo = $LG(tSizeInfo,a)
		Set pAxisType(a) = $LG(tInfo,1)
		Set pAxisKey(a) = $LG(tInfo,2)
		Set pAxisSize(a) = $LG(tInfo,3)
		If (pAxisType(a)="slicer") {
			Set pSlicerAxis = a
		}
	}
	Quit tAxisCount
}

/// Take a cell address and return its canonic form.
ClassMethod %CanonizeAddr(pAddr As %String) As %String [ Internal ]
{
	// JMD1115
	// Do not remove non-matching ANDed items: 1&2 should remain 1&2
	// Note: OR binds tighter than AND, so:
	// 1&2&4|3 is the same as 1&2&3|4

	Set tOut = ""
	Set tLen = $L(pAddr,":")
	For f=1:1:tLen {
		Kill tTerms
		Set tKey = ""
		Set tFactKey = $P(pAddr,":",f)
		If (tFactKey'="") {
			// we have the form: A|B&C|D&E|F
			// factor out AND/ORs and return keys in alpha order
			For a = 1:1:$L(tFactKey,"&") {
				Set and = $P(tFactKey,"&",a)
				For b = 1:1:$L(and,"|") {
					Set k = $P(and,"|",b)
					// remove duplicate OR terms
					Set tTerms(a,k) = ""
				}
			}
			// JMD1160: do not process AND of OR expressions
			// 1|2&2 --> 1|2&2
			// find out which items are ORs
			Set a = $O(tTerms(""))
			While (a'="") {
				Set b = $O(tTerms(a,""))
				If ($O(tTerms(a,b))'="") {
					Set tOrTerms(a) = 1
				}
				Set a = $O(tTerms(a))
			}

			// process ANDs
			Set a1 = $O(tTerms(""))
			While (a1'="") {
				If ('$D(tOrTerms(a1))) {
					Set a2 = $O(tTerms(a1))
					While (a2'="") {
						If ('$D(tOrTerms(a2))) {
							// first test a1*a2
							Set b = $O(tTerms(a1,""))
							While (b'="") {
								Kill tTerms(a2,b)
								Set b = $O(tTerms(a1,b))
							}

							// then test a2*a1
							Set b = $O(tTerms(a2,""))
							While (b'="") {
								Kill tTerms(a1,b)
								Set b = $O(tTerms(a2,b))
							}
						}
						Set a2 = $O(tTerms(a2))
					}
				}
				Set a1 = $O(tTerms(a1))
			}

			// emit
			Set a = $O(tTerms(""))
			While (a'="") {
				Set tOR = ""
				Set b = $O(tTerms(a,""))
				While (b'="") {
					Set tOR = tOR _ $S(tOR'="":"|",1:"") _ b
					Set b = $O(tTerms(a,b))
				}
				Set:tOR'="" tKey = tKey _ $S(tKey'="":"&",1:"") _ tOR
				Set a = $O(tTerms(a))
			}
		}
		Set tOut = tOut _ $S(f>1:":",1:"") _ tKey
	}
	Quit tOut
}

/// Take a relationship key code and return its canonic form (put all pieces in
/// alpha-order).
ClassMethod %CanonizeRelationKey(pKeyCode As %String) As %String [ Internal ]
{
	If (pKeyCode'["*") {
		Quit pKeyCode
	}
	For p = 1:1:$L(pKeyCode,"*") {
		Set k = $P(pKeyCode,"*",p)
		// Do not add duplicate members to tList
		Set tCRC = "k"_$zcrc(k,7)
		If ((k'="") && ('$D(tCRCs(tCRC)))) {
			Set tCRCs(tCRC)=1
			Set tSub = $E(k,1,113)
			Set tList(tSub) = $I(tList(tSub))
			Set tList(tSub,tList(tSub)) = k
		}
	}
	Set tKeyCode = ""
	Set p = $O(tList(""))
	While (p'="") {
		If (tList(p)=1) {
			Set tKeyCode = tKeyCode _$S(tKeyCode="":"",1:"*") _ tList(p,1)
		} Else {
			// PFS052 - If we are here it means that we have strings that are not unique before first 113 characters
			// This set is probably small, so we can loop through results and use ]] to find their sort order
			For i = 1:1:tList(p) {
				For j = i:1:tList(p) {
					If tList(p,i)]]tList(p,j) {
						set tTemp = tList(p,j)
						Set tList(p,j) = tList(p,i)
						Set tList(p,i) = tTemp
					}
				}
			}
			// Now put the ordered sublist into tKeyCode
			For i = 1:1:tList(p) {
				Set tKeyCode = tKeyCode _$S(tKeyCode="":"",1:"*") _ tList(p,i)
			}
		}
		Set p = $O(tList(p))
	}
	Quit tKeyCode
}

/// Diagnostic.
ClassMethod PrintBits(pMsg, pBits) [ Internal ]
{
	W $E(pMsg,1,10),?10
	If (pBits'="") {
		Set l = $BitCount(pBits)
		W:l>70 !
		For n=1:1:l {
			Set b = $Bit(pBits,n)
			W $S(b=0:0,1:$C(27)_"[1m"_1_$C(27)_"[0m")
		}
	}
	W !
}

}
