/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// Contains the logic for calculating the results of a DeepSee query.
Class %DeepSee.Query.Engine Extends %RegisteredObject [ System = 3 ]
{

/// Maximum number of items in a listing.
/// Setting this above 20000 can cause browser timeouts.
Parameter MAXLISTING = 20000;

/// <b>DEPRECATED</b> - Use <method>%DeepSee.Utils:%PurgeObsoleteCache</method>.
/// Delete all unused buckets from the result cache
/// for cube <var>pCubeName</var>.
ClassMethod %PurgeBuckets(pCubeName As %String) As %Status [ Deprecated, Internal ]
{
	// Method deprecated by DTB274
	Quit $$$ERROR(5758,"%PurgeBuckets. Use %DeepSee.Utils:%PurgeObsoleteCache")
}

/// Get the bucket list for the given cube.<br/>
/// If the list is not in the cache, build it
/// and store it in the results global for the cube.<br/>
/// The list is of the form:<br/>
/// pBucketList(bucketNo) = slotNo<br/>
/// <var>pActiveChunk</var> contains the number of the active chunk.
ClassMethod %GetBucketList(pCubeName As %String, Output pBucketList As %Integer, Output pActiveChunk As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tLock = 0
	Try {
		Kill pBucketList
		Set pCubeName = $$$UPPER(pCubeName)
		If (pCubeName = "") {
			Set tSC = $$$ERROR($$$CubeNameRequired,$$$dsCurrentMethod)
			Quit
		}
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		Set pActiveChunk = $G($$$DeepSeeActiveChunk(tCubeIndex))
		If $D($$$DeepSeeResultsGLVN(tCubeIndex,0,"buckets")) {
			Merge pBucketList = $$$DeepSeeResultsGLVN(tCubeIndex,0,"buckets")
			Quit
		}

		Set tChunksPerBucket = $$$DeepSeeChunksPerBucket(pCubeName)

		Set tFactClass = ##class(%DeepSee.Utils).%GetCubeFactClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		// Lock the bucket list for this cube
		Lock +$$$DeepSeeBucketsGLVN(tCubeIndex):10
		If ('$Test) {
			Set tSC = $$$ERROR($$$NoCubeLock,tCubeIndex,$$$dsCurrentMethod)
			Quit
		}
		Set tLock = 1

		// Determine how many buckets are needed
		Set tFirstFact = $$$DeepSeeFirstFact(tFactClass)
		Set tFirstBucket = $$$DeepSeeFactToBucket(pCubeName,tFirstFact)
		Set tLastFact = $$$DeepSeeLastFact(tFactClass)
		Set tLastBucket = $$$DeepSeeFactToBucket(pCubeName,tLastFact)

		If (pActiveChunk="") {
			// find active chunk
			Set pActiveChunk = (tLastFact\64000) + 1
			Set $$$DeepSeeActiveChunk(tCubeIndex) = pActiveChunk
		}

		// test if the *active* chunk is the only chunk
		If (pActiveChunk=1) {
			Quit
		}

		// build list, allocate new slots as we go
		For bno = tFirstBucket:1:tLastBucket {
			Set tStartChunk = ((bno-1)*tChunksPerBucket)+1
			// stop if the starting chunk for the bucket is equal to
			// or ahead of the active chunk
			If (tStartChunk >= pActiveChunk) {
				Quit
			}

			If $D($$$DeepSeeBucketsGLVN(tCubeIndex,"active",bno),sno) {
				Set pBucketList(bno) = sno
			}
			Else {
				// allocate new slot
				Set sno = $O($$$DeepSeeBucketsGLVN(tCubeIndex,"free",""))
				If (sno '= "") {
					// remove entry from free list
					Kill $$$DeepSeeBucketsGLVN(tCubeIndex,"free",sno)
				}
				Else {
					// allocate a new number
					Set sno = $Increment($$$DeepSeeBucketsGLVN(tCubeIndex,"active"))
				}
				// add new slot to list
				Set $$$DeepSeeBucketsGLVN(tCubeIndex,"active",bno) = sno
				Set pBucketList(bno) = sno
			}
		}

		// copy to cache
		Merge $$$DeepSeeResultsGLVN(tCubeIndex,0,"buckets") = pBucketList
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	// unlock
	Lock:tLock -$$$DeepSeeBucketsGLVN(tCubeIndex)
	Quit tSC
}

/// Invalidate any buckets affected by the given bitmap chunks from the result cache
/// for cube <var>pCubeName</var>.<br/>
/// As a side effect, test if the active chunk has changed, if so
/// adjust buckets to compensate.
ClassMethod %InvalidateBuckets(pCubeName As %String, pFactClass As %String, ByRef pChunkList) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tLock = 0
	Try {
		Set pCubeName = $$$UPPER(pCubeName)
		If (pCubeName = "") {
			Set tSC = $$$ERROR($$$CubeNameRequired,$$$dsCurrentMethod)
			Quit
		}
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		Set tChunksPerBucket = $$$DeepSeeChunksPerBucket(pCubeName)
		// Lock the bucket list for this cube
		Lock +$$$DeepSeeBucketsGLVN(tCubeIndex):10
		If ('$Test) {
			Set tSC = $$$ERROR($$$NoCubeLock,tCubeIndex,$$$dsCurrentMethod)
			Quit
		}
		Set tLock = 1

		// see if the *active* chunk has changed
		Set tLastFact = $$$DeepSeeLastFact(pFactClass)
		Set tChunk = (tLastFact\$$$DeepSeeBitsPerChunk) + 1
		Set tActiveChunk = $G($$$DeepSeeBucketsGLVN(tCubeIndex,"chunk"))

		If (tChunk '= tActiveChunk) {
			Set $$$DeepSeeBucketsGLVN(tCubeIndex,"chunk") = tChunk
			If (tActiveChunk '= "") {
				// invalidate bucket containing active chunk
				// JMD1350: compute active bucket correctly!
				Set tActiveBucket = ((tActiveChunk-1)\tChunksPerBucket) + 1
				Set tBucketList(tActiveBucket) = ""
			}
		}

		// look at list of chunks, assemble list of buckets to invalidate
		Set tChunk = $O(pChunkList(""))
		While (tChunk '= "") {
			If (tChunk '= tActiveChunk) {
				Set tBucketList(((tChunk-1)\tChunksPerBucket) + 1) = ""
			}
			Set tChunk = $O(pChunkList(tChunk))
		}

		// delete cached list
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,0,"buckets")

		Set tTrackUpdates = +$G(^DeepSee.UpdateCounter)

		Set tBucketNo = $O(tBucketList(""))
		While (tBucketNo '= "") {
			// Count updates per bucket
			Set:tTrackUpdates x = $I(^DeepSee.UpdateCounter(tCubeIndex,tBucketNo))

			// move slot(s) from active list to inactive list
			If $D($$$DeepSeeBucketsGLVN(tCubeIndex,"active",tBucketNo),sno) {
				Kill $$$DeepSeeBucketsGLVN(tCubeIndex,"active",tBucketNo)
				Set $$$DeepSeeBucketsGLVN(tCubeIndex,"inactive",sno) = ""
			}
			Set tBucketNo = $O(tBucketList(tBucketNo))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	// unlock
	Lock:tLock -$$$DeepSeeBucketsGLVN(tCubeIndex)
	Quit tSC
}

/// Notification that a cube has been removed / recompiled.
ClassMethod %CubeRemoved(pCubeName As %String, pClassName As %String) As %Status
{
	Set tSC = $$$OK
	Set tSC = ..%ClearCache(pCubeName)
	Quit tSC
}

/// Clear the results cache for the given cube.
/// If <var>pResultsOnly</var> is true, then only clear the results cache.
ClassMethod %ClearCache(pCubeName As %String, pResultsOnly As %Boolean = 0) As %Status
{
	Set tSC = $$$OK

	If (pCubeName '= "") {
		Set tCubeName = $$$UPPER(pCubeName)
		// skip subject areas
		If ($G($$$DeepSeeMetaGLVN("cubes",tCubeName,"baseCube"))="") {
			Kill $$$DeepSeeBucketsGLVN(tCubeName)
			Kill $$$DeepSeeResultsGLVN(tCubeName)
			Kill $$$DeepSeeAxisGLVN(tCubeName)
			Kill $$$DeepSeeListingGLVN(tCubeName)
			Kill $$$DeepSeeListingBitGLVN(tCubeName)
			If ('pResultsOnly) {
				Kill $$$DeepSeeCellsGLVN(tCubeName)
			}
		}
	}
	Quit tSC
}

/// Compute the values of cells within the result cube.<br/>
/// <var>pCube</var> is the name of the cube.<br/>
/// <var>pKey</var> is the query key.<br/>
/// <var>pBucketNo</var> is the logical bucket number to execute.<br/>
/// <var>pSlotNo</var> is the physical bucket slot number containing the results.<br/>
/// <var>pSection</var>, if defined, specifies, by axis, which sections of the result to calculate:<br/>
/// pSection(axis) = $LB(startNode,endNode)<br/>
/// <var>pTrace</var> is a debugging flag.<br/>
ClassMethod %ExecuteForBucket(pCube As %String, pKey As %String, pBucketNo As %Integer, pSlotNo As %Integer, ByRef pSections As %List, pTrace As %Boolean = 0, ByRef pStats) As %Status [ Internal ]
{
	// dispatch
	Quit ##Class(Engine2).%ExecuteForBucket(pCube,pKey,pBucketNo,pSlotNo,.pSections,pTrace,.pStats)
}

/// For a given query, consolidate the partial answers into a final answer
/// and, if required, remove empty rows and columns.<br/>
/// <var>pNonEmptyList</var> is an additional list of non-empty axes to apply when folding
/// compound cubes.
ClassMethod %Consolidate(pCube As %String, pKey As %String, ByRef pBucketList As %Integer, pTrace As %Boolean = 0, ByRef pStats, ByRef pNonEmptyList) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// DTB980 - Add timer
		$$$dsSetLogging
		$$$dsStartTimer
		
		Set (tStatCells,tStatCalcs,tStatPasses) = 0
		Set tAgeToday = +$H-$$$dsReferenceTime

		// test for query type
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tQueryType = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"queryType"))
		Set tIsBitSet = (tQueryType = "%BITSET")
		Set tIsDrillThru = (tQueryType = "DRILLTHROUGH")
		If (tIsBitSet) {
			// build index and nothing else
			Set tSC = ..%BuildLeafIndex(pCube,pKey)
			Quit
		}

		// Kill previous results
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",-2)	// slicer
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0)
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf")

		// JMD1015: clear out non-empty data
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty")

		// see if there are currentMember substitutions in play
		If ($D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap"))) {
			Set tHasCMBR = 1
		}
		Else {
			Set tHasCMBR = 0
		}

		// Find axes
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		// n.b. do not modify tAxisNode -- we use it later !!!!

		// JMD1401: if we have 3 non-slicer axes, we will *flatten* the third axis
		// into the first 2.
		// This is different than "folding" which does the same thing for the slicer.
		// This happens at the end

		Set tSlicerSize = 0
		For a=1:1:tTotalAxisCount {
			Set tAxisNode(a) = 1
			Set tRealAxisKey(a) = tAxisKey(a) // axis key in original order
			If (tAxisType(a) = "slicer") {
				// if present, slicer is always first in the list
				Set tSlicerSize = tAxisSize(a)
				Set:tSlicerSize>1 tAxisList(999,a) = tAxisKey(a)
			}
			ElseIf (tAxisType(a) = "axis") {
				Set tAxisList(-tAxisSize(a),a) = tAxisKey(a)
			}
		}

		// initialize axis info (using size ordered list)
		Kill tAxisKey
		Set tAxisCount = 0
		Set s = $O(tAxisList(""))
		While (s'="") {
			Set a = $O(tAxisList(s,""))
			While (a'="") {
				Set tAxisCount = tAxisCount + 1
				Set tAxisRoot(tAxisCount) = 1
				Set tAxisKey(tAxisCount) = tAxisList(s,a)
				Set tRealAxisNo(tAxisCount) = a
				Set tSortedAxisNo(a) = tAxisCount // reverse index
				Set tStartNode(tAxisCount) = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tAxisRoot(tAxisCount),"all",""))
				Set tNodeNo(tAxisCount) = tStartNode(tAxisCount)
				If (tNodeNo(tAxisCount)'="") {
					Set tNodeType(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tNodeNo(tAxisCount)),1)
					Set tIsNodeMarkedNonEmpty(tAxisKey(tAxisCount)) = $$$dsAxisNodeNECJGet($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tNodeNo(tAxisCount)))  //APV095
					Set tNodeDistinct(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tNodeNo(tAxisCount)),6)="%DISTINCT"
				}
				Else {
					Set tNodeType(tAxisCount) = "lit"
					Set tNodeDistinct(tAxisCount) = 0
				}
				// if true, then axis has a NON EMPTY clause
				Set tAxisNonEmpty(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tAxisRoot(tAxisCount)),5)

				// JMD897: test for override of non empty
				If (+$G(pNonEmptyList(a))) {
					Set tAxisNonEmpty(tAxisCount) = 1
				}
				Set a = $O(tAxisList(s,a))
			}
			Set s = $O(tAxisList(s))
		}

		// tRealAxisCount: axes in intermediate results
		// tFinalAxisCount: axes in final results
		If (tSlicerSize < 2) {
			Set tRealAxisCount = tAxisCount
			Set tFinalAxisCount = tAxisCount
			Set tAnswerSlot = 0 // result slot for final answers
			Set tFoldSlot = 0 // results are not folded
			Set tNeedsFolding = 0
		}
		Else {
			Set tRealAxisCount = tAxisCount
			Set tFinalAxisCount = tAxisCount - 1
			Set tAnswerSlot = -2 // result slot for intermediate answers
			Set tFoldSlot = 0 // results are folded
			Set tNeedsFolding = 1
		}

		//Write "QUERY: ",$G(^DeepSee.Cache.Results(pCube,pKey,"query",1)),!
		//Write "AXES ",tAxisCount,":",tRealAxisCount,":",tFinalAxisCount,":",tSlicerSize,!

		// general loop over all axes
		Set tDone = 0
		Set nc = 0
		While ('tDone) {
			Set nc = nc + 1
			If $$$ISERR(tSC) Quit
			// process cell
			Set tValue = ""

			// contruct address, test for expressions
			Kill tNodeNums
			Kill tNodeNumsNonEmpty
			Set tIsCalculated = 0
			Set tIsDistinct = 0
			For a=1:1:tRealAxisCount {
				Set tNodeNums(tRealAxisNo(a)) = +tNodeNo(a)
				Set tNodeNumsNonEmpty(tRealAxisNo(a)) = tAxisNonEmpty(a)
				If (a <= tFinalAxisCount) {
					// no calculations along slicer
					Set tIsCalculated = tIsCalculated || 
						(tNodeType(a)="eq") || 
						(tNodeType(a)="exp") || 
						(tNodeType(a)="lit") || 
						(tNodeType(a)="cell") || 
						(tNodeType(a)="agg") ||
						$D($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(a),"cellAgg",tNodeNums(tRealAxisNo(a))))		// DTB400

					If (tNodeDistinct(a)) {
						Set tIsDistinct = 1
					}
				}
			}

			Kill tAddr,tAddrNonEmpty
			Set n = 0
			Set k = $O(tNodeNums(""))
			While (k '= "") {
				Set tAddr($I(n)) = tNodeNums(k)
				Set tAddrNonEmpty(n) = tNodeNumsNonEmpty(k)
				Set k = $O(tNodeNums(k))
			}
			
			// DTB400 - Resolve Agg addresses to point to the aggregate parent
			Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,tRealAxisCount)
			If $$$ISERR(tSC) Quit
			Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddrNonEmpty,tRealAxisCount)
			If $$$ISERR(tSC) Quit

			// see if there are any currentMember children *under* this cell, use -1 slot
			Kill tCMData
			If (tHasCMBR) {
				Set tBucket = $O(pBucketList(""))
				While (tBucket '= "") {
					Set tSlotNo = pBucketList(tBucket)
					Merge:tRealAxisCount=0 tCMData(tSlotNo) = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,"ch")
					Merge:tRealAxisCount=1 tCMData(tSlotNo) = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1),"ch")
					Merge:tRealAxisCount=2 tCMData(tSlotNo) = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1),tAddr(2),"ch")
					Merge:tRealAxisCount=3 tCMData(tSlotNo) = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1),tAddr(2),tAddr(3),"ch")
					If ((tSlotNo=-1)&&'$D(tCMData)) {
						// assume no more to do
						Quit
					}
					Set tBucket = $O(pBucketList(tBucket))
				}
			}

			If $D(tCMData) {
				// consolidate sub-result over all buckets
				Set cc = $O(tCMData(-1,""))
				While (cc '= "") {
					Set (tAgg,tValue,tCount,tSum,tMin,tMax) = ""
					// accumulate over every intermediate bucket
					Set tBucket = $O(pBucketList(""))
					While (tBucket '= "") {
						Set tSlotNo = pBucketList(tBucket)
						Set tCMNode = $G(tCMData(tSlotNo,cc))
						If (tCMNode'="") {
							If (tIsDrillThru) {
								Set tValue = tCMNode
							}
							If ($IsValidNum(tCMNode)) {
								Set tValue = tValue + tCMNode
							}
							ElseIf ('$ListValid(tCMNode)) {
								// string!
								Set tValue = tCMNode
							}
							Else {
								Set tAgg = $LG(tCMNode,1)
								Set c = $LG(tCMNode,2)
								If ($P(tAgg,":",1)="MIN") {
									Set:c'="" tMin = $S(tMin="":c,tMin<c:tMin,1:c)
								}
								ElseIf($P(tAgg,":",1)="MAX") {
									Set:c'="" tMax = $S(tMax="":c,tMax>c:tMax,1:c)
								}
								Else {
									Set s = $LG(tCMNode,3)
									Set:c'="" tCount = tCount + $LG(tCMNode,2)
									Set:s'="" tSum = tSum + $LG(tCMNode,3)
								}
							}
						}
						// next bucket
						Set tBucket = $O(pBucketList(tBucket))
					}

					If ($P(tAgg,":",1) = "AVG") {
						Set tValue = $S(tCount="":"",tCount=0:0,1:tSum/tCount)
					}
					ElseIf ($P(tAgg,":",1) = "MIN") {
						Set tValue = tMin
					}
					ElseIf ($P(tAgg,":",1) = "MAX") {
						Set tValue = tMax
					}

					// place value in 0 slot
					If (tValue '= "") {
						Set tCMData(0,cc) = tValue
					}
					Set cc = $O(tCMData(-1,cc))
				}
			}

			// currentMember handling
			// See if we need to overlay substitutions due to currentMember
			Set tCMBRResolved = 0
			If (tHasCMBR) {
				// test each subst entry and see if we have nodes in play
				Set tCMbrNode = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tAddr(1)),+$G(tAddr(2)),+$G(tAddr(3))))
				Set tCMType = $LG(tCMbrNode,1)
				Set tCMAgg = $$$UPPER($LG(tCMbrNode,16,"SUM"))
				Set tCMLiteral = $LG(tCMbrNode,21)
				// replace node with overlay
				If ((tCMAgg="%MDX")||(tCMAgg="%KPI")) {
					Set tValue = ""
					Set tCNode = tCMbrNode
					Set tOp = tCMAgg
					Set tOpFlag = $LG(tCNode,7)
					Set tOpFlagValue = $LG(tCNode,8)
					Kill tAggContext
					Kill tAggFlags
					Set:tOpFlag'="" tAggFlags(tOpFlag)=tOpFlagValue

					Set tSC = ..%AggregateStart(tOp,.tAggFlags,.tAggContext)
					If $$$ISERR(tSC) Quit

					Set kk = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tAddr(1)),+$G(tAddr(2)),+$G(tAddr(3)),""))
					While (kk'="") {
						Set tKNode = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tAddr(1)),+$G(tAddr(2)),+$G(tAddr(3)),kk))
						If ($LG(tKNode,1)="lit") {
							Set tSC = ..%AggregateAccum(tOp,.tAggFlags,.tAggContext,$LG(tKNode,6))
							If $$$ISERR(tSC) Quit
						}
						Set kk = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tAddr(1)),+$G(tAddr(2)),+$G(tAddr(3)),kk))
					}
					Set tSC = ..%AggregateEnd(tOp,.tAggFlags,.tAggContext,.tValue,,tCubeIndex,pKey)
					If $$$ISERR(tSC) Quit

					Do SETRESULT(tRealAxisCount,tAnswerSlot,tValue)
					Set tCMBRResolved = 1
					If ('tNeedsFolding && (tFinalAxisCount>=1)) {
						// mark that this node has values
						For a=1:1:tFinalAxisCount {
							Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 20
						}
					}
				}
				ElseIf $D(tCMData(0)) {
					// replace node with aggregate over subvalues
					Set tValue = 0
					Set tCount = 0
					If (tCMAgg="SUM") {
						Set cc = $O(tCMData(0,""))
						While (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set tValue = tValue + cv
							Set cc = $O(tCMData(0,cc))
						}
					}
					ElseIf (tCMAgg="%LIST") {
						Set tValue = ""
						Set cc = $O(tCMData(0,""))
						While (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set tValue = tValue _ $S(tValue="":"",1:",") _ cv
							Set cc = $O(tCMData(0,cc))
						}
					}
					ElseIf (tCMAgg="AVG") {
						Set cc = $O(tCMData(0,""))
						While (cc '="") {
							Set tCount = tCount + 1
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set tValue = tValue + cv
							Set cc = $O(tCMData(0,cc))
						}
						Set tValue = $S(tCount=0:"",1:tValue/tCount)
					}
					ElseIf (tCMAgg="%FIRST") {
						Set cc = $O(tCMData(0,""))
						If (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set tValue = cv
						}
					}
					ElseIf (tCMAgg="%LAST") {
						Set cc = $O(tCMData(0,""),-1)
						If (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set tValue = cv
						}
					}
					ElseIf (tCMAgg="MIN") {
						Set tValue = ""
						Set cc = $O(tCMData(0,""))
						While (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set x = cv
							Set tValue = $S(tValue="":x,tValue<x:tValue,1:x)
							Set cc = $O(tCMData(0,cc))
						}
					}
					ElseIf (tCMAgg="MAX") {
						Set tValue = ""
						Set cc = $O(tCMData(0,""))
						While (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set x = cv
							Set tValue = $S(tValue="":x,tValue>x:tValue,1:x)
							Set cc = $O(tCMData(0,cc))
						}
					}
					ElseIf (tCMAgg="COUNT") {
						Set cc = $O(tCMData(0,""))
						While (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set x = cv
							Set:(+x)>0 tCount = tCount + 1
							Set cc = $O(tCMData(0,cc))
						}
						Set tValue = tCount
					}
					Else {
						// aggregate function applied to cmbr
						Set tOp = tCMAgg
						Set tOpFlag = $LG(tCMbrNode,7)
						Set tOpFlagValue = $LG(tCMbrNode,8)
						Kill tAggContext
						Kill tAggFlags
						Set:tOpFlag'="" tAggFlags(tOpFlag)=tOpFlagValue
						Set tSC = ..%AggregateStart(tOp,.tAggFlags,.tAggContext)
						If $$$ISERR(tSC) Quit

						Set cc = $O(tCMData(0,""))
						While (cc '="") {
							Set cv = $S(tCMLiteral="":$G(tCMData(0,cc)),1:tCMLiteral)
							Set tSC = ..%AggregateAccum(tOp,.tAggFlags,.tAggContext,cv)
							If $$$ISERR(tSC) Quit
							Set cc = $O(tCMData(0,cc))
						}

						Set tSC = ..%AggregateEnd(tOp,.tAggFlags,.tAggContext,.tValue,,tCubeIndex,pKey)
						If $$$ISERR(tSC) Quit
					}
					Do SETRESULT(tRealAxisCount,tAnswerSlot,tValue)
					Set tCMBRResolved = 1
					If ('tNeedsFolding && (tFinalAxisCount>=1)) {
						// mark that this node has values
						For a=1:1:tFinalAxisCount {
							Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 21
						}
					}
				}
				Else {
					If (tCMType="lit") {
						// JMD1504 check other axes for %CELL and expression!
						Set tHasExpr = 0
						For a=1:1:tFinalAxisCount {
							Set tNType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(a),"axes",tNodeNo(a)),1)
							If ((tNType="cell")||(tNType="exp")||(tNType="lit")) {
								Set tHasExpr = 1
								Quit
							}
						}
						
						If ('tHasExpr) {
							Set tCMBRResolved = 1
							Set tValue = $LG(tCMbrNode,6)

							// JMD924: use special literal aggregate type so that values
							// are not summed by the slicer!
							If (tNeedsFolding) {
								Set tValue = $LB("LIT",tValue)
							}
							Do SETRESULT(tRealAxisCount,tAnswerSlot,tValue)

							// JMD874 test visible flag
							If ('tNeedsFolding && (tFinalAxisCount>=1) && +$LG(tCMbrNode,2)) {
								// mark that this node has values
								// JMD1303: test for missing value
								// JMD1323: add test for nonempty
								// n.b. this is why IIF(currentMember) does not work with NON EMPTY
								// 
								For a=1:1:tFinalAxisCount {
									If ('tAddrNonEmpty(a)||(tValue'="")) {
										If ($G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)))="") {
											// JMD1323 (2) don't set if already set
											Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 11
										}
									}
								}
							}
						}
					}
				}
			}

			If ('tCMBRResolved) {
				If (tIsCalculated && 'tIsDistinct) {
					// add to list of cells to resolve
					// create encoded address for cell
					Set tCellAddr = ""
					For a=1:1:tFinalAxisCount {
						Set tCellAddr = tCellAddr _ $S(a>1:",",1:"") _ tAddr(a)
					}

					// find out if there is an aggregate in play for this cell
					Set tCAgg = ""
					Set tSlotNo = $G(pBucketList(-1))
					If (tSlotNo'="") {
						// Get node for bucket (if defined)
						Set tNodeDefined = $Case(tRealAxisCount,
							0:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo),tNode),
							1:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1)),tNode),
							2:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1),tAddr(2)),tNode),
							3:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1),tAddr(2),tAddr(3)),tNode),
							:"")
						If (tNodeDefined="") {
							Set tSC = $$$ERROR($$$GeneralError,"Too many axes in query: " _ tRealAxisCount)
							Quit
						}
						If (tNodeDefined && $D(tNode)&&(tNode'="")) {
							If ($ListValid(tNode)) {
								Set tCAgg = $LG(tNode,1)
							}
						}
					}
					
					Set:tCellAddr'="" tCalcCells(tCellAddr) = tCAgg
					Set x = $I(tStatCalcs)
				}
				Else {
					// consolidate
					Set x = $I(tStatCells)
					Set (tAgg,tValue,tCount,tSum,tMin,tMax) = ""
					// accumulate over every intermediate bucket
					Set tBucket = $O(pBucketList(""))
					While (tBucket '= "") {
						Set tSlotNo = pBucketList(tBucket)
						// Get node for bucket (if defined)
						Set tNodeDefined = $Case(tRealAxisCount,
							0:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo),tNode),
							1:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1)),tNode),
							2:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1),tAddr(2)),tNode),
							3:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlotNo,tAddr(1),tAddr(2),tAddr(3)),tNode),
							:"")
						If (tNodeDefined="") {
							Set tSC = $$$ERROR($$$GeneralError,"Too many axes in query: " _ tRealAxisCount)
							Quit
						}

						If (tNodeDefined && $D(tNode)&&(tNode'="")) {
							If (tIsDrillThru) {
								Set tValue = tNode
							}
							ElseIf ($IsValidNum(tNode)) {
								Set tValue = tValue + tNode
							}
							ElseIf ('$ListValid(tNode)) {
								// string!
								Set tValue = tNode
							}
							Else {
								Set tAgg = $LG(tNode,1)
								Set c = $LG(tNode,2)
								If ($P(tAgg,":",1)="MIN") {
									Set:c'="" tMin = $S(tMin="":c,tMin<c:tMin,1:c)
								}
								ElseIf($P(tAgg,":",1)="MAX") {
									Set:c'="" tMax = $S(tMax="":c,tMax>c:tMax,1:c)
								}
								Else {
									Set s = $LG(tNode,3)
									Set:c'="" tCount = tCount + $LG(tNode,2)
									Set:s'="" tSum = tSum + $LG(tNode,3)
								}
							}
						}
						// next bucket
						Set tBucket = $O(pBucketList(tBucket))
					}

					If ($P(tAgg,":",1) = "AVG") {
						If (tNeedsFolding) {
							Set tValue = $LB(tAgg,tCount,tSum)
						}
						Else {
							Set tValue = $S(tCount="":"",tCount=0:0,1:tSum/tCount)
						}
					}
					ElseIf ($P(tAgg,":",1) = "MIN") {
						If (tNeedsFolding) {
							Set tValue = $LB(tAgg,tMin)
						}
						Else {
							Set tValue = tMin
						}
					}
					ElseIf ($P(tAgg,":",1) = "MAX") {
						If (tNeedsFolding) {
							Set tValue = $LB(tAgg,tMax)
						}
						Else {
							Set tValue = tMax
						}
					}
					ElseIf (tAgg '= "") {
						Set tSC = $$$ERROR($$$GeneralError,"Unsupported Aggregate: " _ tAgg)
						Quit
					}

					If ('tNeedsFolding && ($P(tAgg,":",2)'="")) {
						// Resolve age
						Set tAge = $P(tAgg,":",2)
						If (tAge="Days") {
							Set:tValue'="" tValue = tAgeToday-tValue
						}
					}

					// place value in result cache
					If (tValue '= "") {
						// has a value
						Do SETRESULT(tRealAxisCount,tAnswerSlot,tValue)
						// JMD884: do not set if more than 2 axes!
						// JMD1233: no, test if all axes are visible in this case
						If ('tNeedsFolding && (tFinalAxisCount>=1) && (tFinalAxisCount<8)) {
							// mark that this node has values
							Set tVisible = 1
							If (tFinalAxisCount>2) {
								For a=1:1:tFinalAxisCount {
									Set tVisible = tVisible * $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tSortedAxisNo(a)),"axes",tAddr(a))),2)
									Quit:'tVisible
								}
							}
							If (tVisible) {
								For a=1:1:tFinalAxisCount {
									Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 23
								}
							}
						}
					}
					Else {
						// no value
						If ('tNeedsFolding && (tFinalAxisCount>=1)) {
							For a=1:1:tFinalAxisCount {
								If ('tAddrNonEmpty(a) && ('tIsNodeMarkedNonEmpty(tAxisKey(tRealAxisNo(a))))) {  //APV095
									// NON-EMPTY is *not* specified along this axis
									// so mark that this node has values
									// a is a *real* axis number
									Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 24
								}
							}
						}
					}
				}
			}

			// find next cell
			Set tAxis = tRealAxisCount
			While (1) {
				If (tRealAxisCount = 0) {
					Set tDone = 1
					Quit
				}
				Set tNodeNo(tAxis) = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tAxisRoot(tAxis),"all",tNodeNo(tAxis)))
				If (tNodeNo(tAxis)'="") {
					Set tIsNodeMarkedNonEmpty(tAxisKey(tAxis)) = $$$dsAxisNodeNECJGet($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)))  //APV095
					Set tNodeType(tAxis) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)),1)
					Set tNodeDistinct(tAxis) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)),6)="%DISTINCT"
					Quit
				}
				// try previous axis
				If (tAxis > 1) {
					Set tNodeNo(tAxis) = tStartNode(tAxis)
					If (tNodeNo(tAxis)'="") {
						Set tIsNodeMarkedNonEmpty(tAxisKey(tAxis)) = $$$dsAxisNodeNECJGet($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)))  //APV095
						Set tNodeType(tAxis) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)),1)
						Set tNodeDistinct(tAxis) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)),6)="%DISTINCT"
					}
					Else {
						Set tDone = 1
						Quit
					}
					Set tAxis = tAxis - 1
				}
				Else {
					Set tDone = 1
					Quit
				}
 			}
		}

		/************************************************/
		// Fold "planes" of slicer into final answer
		If (tNeedsFolding) {
			// re-initialize axis info (using size ordered list)
			Set tAxisCount = 0
			Set s = $O(tAxisList(""))
			While (s'="") {
				Set a = $O(tAxisList(s,""))
				If (s = 999) {
					Set tSlicerKey = tAxisList(s,a)
				}
				Else {
					While (a'="") {
						Set tAxisCount = tAxisCount + 1
						Set tAxisRoot(tAxisCount) = 1
						Set tAxisKey(tAxisCount) = tAxisList(s,a)
						Set tStartNode(tAxisCount) = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tAxisRoot(tAxisCount),"all",""))
						Set tNodeNo(tAxisCount) = tStartNode(tAxisCount)
						If (tNodeNo(tAxisCount)'="") {
							Set tNodeType(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tNodeNo(tAxisCount)),1)
						}
						Else {
							Set tNodeType(tAxisCount) = "lit" // !!!
						}
						Set tAxisNonEmpty(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tAxisRoot(tAxisCount)),5)
						// DTB629 - add missing override from JMD897
						If (+$G(pNonEmptyList(a))) {
							Set tAxisNonEmpty(tAxisCount) = 1
						}
						Set a = $O(tAxisList(s,a))
					}
				}
				Set s = $O(tAxisList(s))
			}

			// loop over all but slicer axes
			Set tDone = 0
			While ('tDone) {
				// process cell
				Set tValue = ""

				// construct address
				Kill tNodeNums
				Kill tNodeNumsNonEmpty
				Set tIsCalculated = 0
				For a=1:1:tFinalAxisCount {
					Set tNodeNums(tRealAxisNo(a)) = +tNodeNo(a)
					Set tNodeNumsNonEmpty(tRealAxisNo(a)) = tAxisNonEmpty(a)
				}
				Kill tAddr,tAddrNonEmpty
				Set n = 0
				Set k = $O(tNodeNums(""))
				While (k '= "") {
					Set tAddr($I(n)) = tNodeNums(k)
					Set tAddrNonEmpty(n) = tNodeNumsNonEmpty(k)
					Set k = $O(tNodeNums(k))
				}
				
				// DTB400 - Resolve Agg addresses
				Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,tRealAxisCount)
				If $$$ISERR(tSC) Quit
				Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddrNonEmpty,tRealAxisCount)
				If $$$ISERR(tSC) Quit

				Set (tAgg,tValue,tCount,tSum,tMin,tMax) = ""
				// accumulate over every slice
				Set tSlice = $O($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",1,"all",""))
				While (tSlice '= "") {
					// check if slice is visible
					Set tSliceVisible = +$LG($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",tSlice),2)
					If (tSliceVisible) {
						Set tNodeDefined = $Case(tRealAxisCount,
							1:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tSlice),tNode),
							2:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tAddr(1),tSlice),tNode),
							3:$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tAddr(1),tAddr(2),tSlice),tNode),
							:"")
						If (tNodeDefined="") {
							Set tSC = $$$ERROR($$$GeneralError,"Too many axes in query: "_tRealAxisCount)
							Quit
						}

						If (tNodeDefined && (tNode'="")) {
							If (tIsDrillThru) {
								// create list of specs to be OR'd together
								// JMD873: test if value=node
								Set:tValue'=tNode tValue = tValue _ tNode
							}
							ElseIf (tNode = +tNode) {
								Set tValue = tValue + tNode
							}
							ElseIf ('$ListValid(tNode)) {
								// string!
								Set tValue = tNode
							}
							Else {
								Set tAgg = $LG(tNode,1)
								Set c = $LG(tNode,2)
								// JMD924: special literal aggregate
								If ($P(tAgg,":",1)="LIT") {
									Set:tValue="" tValue = c
								}
								ElseIf ($P(tAgg,":",1)="MIN") {
									Set:c'="" tMin = $S(tMin="":c,tMin<c:tMin,1:c)
								}
								ElseIf($P(tAgg,":",1)="MAX") {
									Set:c'="" tMax = $S(tMax="":c,tMax>c:tMax,1:c)
								}
								Else {
									Set s = $LG(tNode,3)
									Set:c'="" tCount = tCount + $LG(tNode,2)
									Set:s'="" tSum = tSum + $LG(tNode,3)
								}
							}
						}
					}
					// next slice
					Set tSlice = $O($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",1,"all",tSlice))
				}

				If ($P(tAgg,":",1) = "LIT") {
				}
				ElseIf ($P(tAgg,":",1) = "AVG") {
					Set tValue = $S(tCount="":"",tCount=0:0,1:tSum/tCount)
				}
				ElseIf ($P(tAgg,":",1) = "MIN") {
					Set tValue = tMin
				}
				ElseIf ($P(tAgg,":",1) = "MAX") {
					Set tValue = tMax
				}
				ElseIf (tAgg '= "") {
					Set tSC = $$$ERROR($$$GeneralError,"Unsupported Aggregate: " _ tAgg)
					Quit
				}

				If (($P(tAgg,":",2)'="")) {
					// Resolve age
					Set tAge = $P(tAgg,":",2)
					If (tAge="Days") {
						Set:tValue'="" tValue = tAgeToday-tValue
					}
				}

				// place value in final result cache
				If (tValue '= "") {
					Do SETRESULT(tFinalAxisCount,tFoldSlot,tValue)
					If (tFinalAxisCount >= 1) {
						// mark that this node has values
						For a=1:1:tFinalAxisCount {
							Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 25
						}
					}
				}
				Else {
					// no value
					If (tFinalAxisCount >= 1) {
						For a=1:1:tFinalAxisCount {
							Set:'tAddrNonEmpty(a) $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 26
						}
					}
				}

				// find next cell
				Set tAxis = tFinalAxisCount
				While (1) {
					If (tFinalAxisCount = 0) {
						Set tDone = 1
						Quit
					}
					Set tNodeNo(tAxis) = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tAxisRoot(tAxis),"all",tNodeNo(tAxis)))
					If (tNodeNo(tAxis)'="") {
						Set tNodeType(tAxis) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)),1)
						Quit
					}
					// try previous axis
					If (tAxis > 1) {
						Set tNodeNo(tAxis) = tStartNode(tAxis)
						Set tNodeType(tAxis) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)),1)
						Set tAxis = tAxis - 1
					}
					Else {
						Set tDone = 1
						Quit
					}
	 			}
			}
		}
		If $$$ISERR(tSC) Quit

		/************************************************/
		// JMD1496
		// resolve calculated cells
		// these are the cells marked as tIsCalculated=1 above
		If $D(tCalcCells) {
			// + WAL051
			Set tSC = ..%ComputeExpressions(pCube,pKey,1,.tCalcCells,.tPendingCalcCells,.pNonEmptyList)
			// - WAL051
			If $$$ISERR(tSC) Quit

			// remember cell dependencies
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"calcCells")
			Merge $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"calcCells") = tPendingCalcCells
		}

		// +DTB327 - If axes have been marked with complex subset functions,
		// remove results nodes. This happens before the leaf index is built to make
		// sure results display properly.
		For a=1:1:2 {
			// There are no subsets on the slicer, only do subsets on axes 1 and 2.
			If $D(tRealAxisNo(a))&&$D($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tRealAxisNo(a)),"subset")) {
				Set tSC = ..%ProcessResultSubset(tCubeIndex,pKey,a)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			}
		}
		// -DTB327
		

		/************************************************/
		Set tSC = ..%BuildLeafIndex(pCube,pKey)
		If $$$ISERR(tSC) Quit

		// JMD1401 If we have 3D results, flatten into 2D while preserving 3 axes

		Set tAxis3 = +$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",3))
		If (tAxis3>1) {
			// remember first z node address; this is where we
			// will put the flattened answer
			Set z = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",3,""),1,tZNodeNo)

			Set c = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",1,""),1,tCNode)
			While (c'="") {
				Set r = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",2,""),1,tRNode)
				While (r'="") {
					Set tAccum = ""
					// flatten along z axis
					Set z = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",3,""),1,tZNode)
					While (z'="") {
						Set tVal = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,tCNode,tRNode,tZNode))
						If (tVal'="") {
							If (tIsDrillThru) {
								// create list of specs to be OR'd together
								Set:tAccum'=tVal tAccum = tAccum _ tVal
							}
							Else {
								If ($IsValidNum(tAccum)&&$IsValidNum(tVal)) {
									Set tAccum = tAccum + tVal
								}
								Else {
									Set tAccum = tVal
								}
							}
						}
						Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,tCNode,tRNode,tZNode)
						Set z = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",3,z),1,tZNode)
					}

					// put answer into tZNodeNo node
					Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,tCNode,tRNode,tZNodeNo) = tAccum
					Set r = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",2,r),1,tRNode)
				}
				Set c = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",1,c),1,tCNode)
			}

			// reset leaf indices
			/* !!!
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",3)
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",3) = 1
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",3,1) = 1
			*/
		}

		// compute grand totals and other aggregates for this result
		Set tMaxValue = ""
		Set tMinValue = ""
		Set tSC = ..%ComputeTotals(pCube,pKey,.tMaxValue,.tMinValue)
		If $$$ISERR(tSC) Quit

		// stats
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"stats","min") = $G(tMinValue)
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"stats","max") = $G(tMaxValue)
		Set pStats("Cells") = tStatCells
		Set pStats("Calcs") = tStatCalcs
		Set pStats("Passes") = tStatPasses
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	$$$dsStopTimer		// DTB980
	Quit tSC

	// set value into final result
	Set (tSlot,tResultAxisCount) = "" // for syntax checker
SETRESULT(tResultAxisCount,tSlot,tValue)
	Goto $Case(tResultAxisCount,0:DIM0,1:DIM1,2:DIM2,3:DIM3,:DIMERR)
DIM0
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot) = tValue
	Quit
DIM1
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1)) = tValue
	Quit
DIM2
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1),tAddr(2)) = tValue
	Quit
DIM3
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1),tAddr(2),tAddr(3)) = tValue
	Quit
DIMERR
	Set tSC = $$$ERROR($$$GeneralError,"Too many dimensions in query: " _ (tAxisCount))
	Quit

	// lookup value in result cache; tOpKey is array of subscripts
GETVAL(tRealAxisCount,tAnswerSlot,tOpKey)
	Quit $Case(tRealAxisCount,
		1:$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tOpKey(1))),
		2:$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tOpKey(1),tOpKey(2))),
		3:$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tOpKey(1),tOpKey(2),tOpKey(3))),
		:"")
}

/// Compute all the cell expressions within a consolidated query.
/// This is called during the consolidation phase and also to update expressions
/// as pending results are resolved.
ClassMethod %ComputeExpressions(pCube As %String, pKey As %String, pPhase As %Integer, ByRef pCalcCells, Output pPendingCells, ByRef pNonEmptyList) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// pPhase is 1 ("consolidate" - called from consolidate) 
		// or 0 ("pending" - updates from pending results)

		// on return this is the list of cells that depend on "pending" results
		Kill pPendingCells

		// resolve calculated cells
		// these are the cells marked as tIsCalculated=1 by %Consolidate

		// set context variables
		// logic copied from %Consolidate
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tQueryType = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"queryType"))
		Set tIsDrillThru = (tQueryType = "DRILLTHROUGH")

		// Find axes
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		// n.b. do not modify tAxisNode -- we use it later !!!!

		// JMD1401: if we have 3 non-slicer axes, we will *flatten* the third axis
		// into the first 2.
		// This is different than "folding" which does the same thing for the slicer.
		// This happens at the end

		Set tSlicerSize = 0
		For a=1:1:tTotalAxisCount {
			Set tAxisNode(a) = 1
			Set tRealAxisKey(a) = tAxisKey(a) // axis key in original order
			If (tAxisType(a) = "slicer") {
				// if present, slicer is always first in the list
				Set tSlicerSize = tAxisSize(a)
				Set:tSlicerSize>1 tAxisList(999,a) = tAxisKey(a)
			}
			ElseIf (tAxisType(a) = "axis") {
				Set tAxisList(-tAxisSize(a),a) = tAxisKey(a)
			}
		}

		// initialize axis info (using size ordered list)
		Kill tAxisKey
		Set tAxisCount = 0
		Set s = $O(tAxisList(""))
		While (s'="") {
			Set a = $O(tAxisList(s,""))
			While (a'="") {
				Set tAxisCount = tAxisCount + 1
				Set tAxisRoot(tAxisCount) = 1
				Set tAxisKey(tAxisCount) = tAxisList(s,a)
				Set tRealAxisNo(tAxisCount) = a
				Set tSortedAxisNo(a) = tAxisCount // reverse index
				Set tStartNode(tAxisCount) = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tAxisRoot(tAxisCount),"all",""))
				Set tNodeNo(tAxisCount) = tStartNode(tAxisCount)
				If (tNodeNo(tAxisCount)'="") {
					Set tNodeType(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tNodeNo(tAxisCount)),1)
					Set tNodeDistinct(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tNodeNo(tAxisCount)),6)="%DISTINCT"
				}
				Else {
					Set tNodeType(tAxisCount) = "lit"
					Set tNodeDistinct(tAxisCount) = 0
				}
				// if true, then axis has a NON EMPTY clause
				Set tAxisNonEmpty(tAxisCount) = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tAxisRoot(tAxisCount)),5)

				// JMD897: test for override of non empty
				If (+$G(pNonEmptyList(a))) {
					Set tAxisNonEmpty(tAxisCount) = 1
				}
				Set a = $O(tAxisList(s,a))
			}
			Set s = $O(tAxisList(s))
		}

		// tRealAxisCount: axes in intermediate results
		// tFinalAxisCount: axes in final results
		If (tSlicerSize < 2) {
			Set tRealAxisCount = tAxisCount
			Set tFinalAxisCount = tAxisCount
			Set tAnswerSlot = 0 // result slot for final answers
			Set tFoldSlot = 0 // results are not folded
			Set tNeedsFolding = 0
		}
		Else {
			Set tRealAxisCount = tAxisCount
			Set tFinalAxisCount = tAxisCount - 1
			Set tAnswerSlot = -2 // result slot for intermediate answers
			Set tFoldSlot = 0 // results are folded
			Set tNeedsFolding = 1
		}

		// + WAL082 -- since we are using the resolved list of cells we should only need one pass
		//             should be able to remove unresolved/related cases from this loop
		Merge tCalcCellsForOrdering = pCalcCells
		Set tSC = ..%ResolveComputations(pCube, pKey, .tCalcCellsForOrdering, .tOrderedCalcCells, tFinalAxisCount, .tRealAxisKey)
		If $$$ISERR(tSC) Quit
		Set tCellIndex = $O(tOrderedCalcCells(""))
		Set tCellAddr = $S(tCellIndex="":"",1:tOrderedCalcCells(tCellIndex))
		// - WAL082
		While (tCellAddr '= "") {
			Set tCellAddrInfo = $G(pCalcCells(tCellAddr))
			Kill tAddr
			For a=1:1:tFinalAxisCount {
				Set tAddr(a) = $P(tCellAddr,",",a)
			}
			
			// DTB400 - Resolve aggregate addresses and store the original
			Merge tOriginalAddr = tAddr
			Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,tFinalAxisCount,1)
			If $$$ISERR(tSC) Quit

			// see if we can evaluate
			Kill tValue
			Kill tPendingInfo
			Set tVWeight = 0		// used to resolve conflicts between axes
			Set tVisible = 1

			// first look at all axes to find what kind of cell this is,
			// its visibility,
			// and which axis to look at in order to resolve it
			Set tCellType = ""
			Set tCellWeight = 0
			Set tSolveOrder = 0
			Set tCalcAxis = 0
			
			For a = 1:1:tFinalAxisCount {
				If $$$ISERR(tSC) Quit
				Set tCNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a)))
				Set tCellType = $LG(tCNode,1)
				
				Set tVisible = tVisible && +$LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tOriginalAddr(a))),2)

				// JMD1498 find weight of child with highest weight
				// solve order trumps cell weight, if present
				// in case of tie, lowest axis wins
				Kill tVisited
				Do ..%ComputeCellWeight(tCubeIndex,tRealAxisKey(a),tAddr(a),.tAWeight,.tASolveOrder,0,.tVisited)
				If (tASolveOrder>tSolveOrder) {
					Set tCalcAxis = a
					Set tSolveOrder = tASolveOrder
					Set tCellWeight = tAWeight
				}
				ElseIf ((tASolveOrder=tSolveOrder)&&(tAWeight>tCellWeight)) {
					Set tCalcAxis = a
					Set tCellWeight = tAWeight
				}
			}
			
			Set a = tCalcAxis
			If (a>0) {
				If $$$ISERR(tSC) Quit
				Set tCNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a)))
				Set tCType = $LG(tCNode,1)
				If (tCType="lit") {
					// literal-- pick it up
					Set tValue = $LG(tCNode,6)
				}
				ElseIf (tCType="cell") {
					// cell function: see if we can resolve it
					Set tCellFunc = $LG(tCNode,6)

					// get function args: they are children of the function
					Kill tArgs
					Set tChildNo = 0
					Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a),"ch",""))
					While (tChild '= "") {
						Set tChildNo = tChildNo + 1
						Set tArgs(tChildNo) = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tChild)),6)
						Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a),"ch",tChild))
					}

					// see if we can resolve the function
					If ((tCellFunc = "%CELL")||(tCellFunc = "%CELLZERO")) {
						// tAddr is address of *this* cell,
						// now find cell relative to this and put it into
						// tOpKey; only 2-D results are supported
						Kill tOpKey
						For b = 1:1:tFinalAxisCount {
							If (b>2) {
								Set tOpKey(b) = tAddr(b)
							}
							Else {
								Set tOpKey(b) = ..%FindRelativeNode(tCubeIndex,tRealAxisKey(b),tAxisNode(b),tAddr(b),tArgs(b),1,pKey,b)		// DTB770 - Add check for "nonempty" indicators
							}
							If (tOpKey(b)="") {
								Set tValue = 0
							}
						}
						If ('$D(tValue)) {
							// test if target addr is resolved
							Set tOpCellAddr = ""
							For b=1:1:tFinalAxisCount {
								Set tOpCellAddr = tOpCellAddr _ $S(b>1:",",1:"") _ tOpKey(b)
							}

							// JMD736
							If ((tArgs(1)=0)&&(tArgs(2)=0)) {
								Set tValue = "@CIRC"
							}
							Else {
								Set tValue = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKey)
								If (tIsDrillThru) {
									Set tValue = tValue
								}
								ElseIf ((tValue="")&&(tCellFunc = "%CELLZERO")) {
									Set tValue = 0
								}
							}
						}
					}
				}
				ElseIf (tCType="agg") {
					// aggregate function
					Set tOp = $LG(tCNode,6)
					Set tOpFlag = $LG(tCNode,7)
					Set tOpFlagValue = $LG(tCNode,8)
					If (tOp = "AGGREGATE") {
						// Aggregate() -- use aggregate currently in context
						Set tOp = $G(pCalcCells(tCellAddr))
						Set:tOp="" tOp = "SUM"
					}
					Kill tAggContext
					Kill tAggFlags
					Set:tOpFlag'="" tAggFlags(tOpFlag)=tOpFlagValue
					Set tSC = ..%AggregateStart(tOp,.tAggFlags,.tAggContext)
					If $$$ISERR(tSC) Quit

					// JMD1390 if %KPI is in an expression, force sync computation
					If ((tOp="%KPI")&&'tVisible) {
						// JMD1496: turn this off
						//Set tAggContext(tOp,"sync") = 1
					}
					Kill tOpKey
					For b = 1:1:tFinalAxisCount {
						Set tOpKey(b) = tAddr(b)
					}
					Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a),"ch",""))
					Set tAggLastNode = 0
					
					Set tAggNodeNo = ""
					If ($LG($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a)),24)'="") {
						// DTB400 - Chained aggregate
						Set tAggNodeNo = tAddr(a)
					}
					
					While (tChild '= "") {
						If $$$ISERR(tSC) Quit
						// contruct addr for child
						// child could be result of crossjoin or tuple
						// and thus could have a set of descendants

						// DTB400 - Chained aggregate
						Set tAggChildInfo = $$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tChild)
						Set tAggParentNo = $LG(tAggChildInfo,24)

						Kill tDescNodes
						
						If ($G(tAggParentNo)'="") {
							// Manually walk the aggregate chain
							Set tDescNodes(tChild) = ""
						}
						ElseIf ($G(tAggNodeNo)="") {
							Do ..%GetDescendantNodes(.tDescNodes,tCubeIndex,tRealAxisKey(a),tChild)
						}

						Set tLeafChild = $O(tDescNodes(""))
						While (tLeafChild'="") {
							Set n = 0
							Set tOpKey(a) = tLeafChild
							Set k = $O(tOpKey(""))
							While (k '= "") {
								Set tOpAddr($I(n)) = k
								Set k = $O(tOpKey(k))
							}
							Set tOpCellAddr = ""
							For ax=1:1:tFinalAxisCount {
								Set tOpCellAddr = tOpCellAddr _ $S(ax>1:",",1:"") _ tOpKey(ax)
							}
							
							If ($G(tAggParentNo)'="") {
								// DTB400 - These values are no longer in the results cache, get it from the axis
								If ($LG(tAggChildInfo,1)="exp")&&($LG(tAggChildInfo,6)="NOP") {
									// DTB400 - Skip this for the next node
									Set tVal = ""
								}
								ElseIf ($LG(tAggChildInfo,1)="cmbr") {
									// DTB400 - Read this value from the resolved cmbrMap
									If '$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(tOpKey(1)),+$G(tOpKey(2)),+$G(tOpKey(3))),tCmbrDetails) {
										Set tSC = $$$ERROR($$$GeneralError,"Unresolved cmbr:"_tCubeIndex_":"_pKey_":"_+$G(tOpKey(1))_":"_+$G(tOpKey(2))_":"_+$G(tOpKey(3)))
										$$$ThrowStatus(tSC)
									}
									Set tVal = $LG(tCmbrDetails,6)		// DP-402439 - Use tCmbrDetails output from $Data for a single global ref
								}
								Else {
									Set tVal = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"cellAgg",tOriginalAddr(a),tChild),6)
								}
							}
							Else {
								Set tVal = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKey)
							}
							
							If (tIsDrillThru) {
								Set tValue = $G(tValue) _ tVal
							}
							Else {
								Set tAccumulate = 1
								If ((tOp="%MDX")||(tOp="%KPI"))&&(tVal="") {
									If ($LG(tAggChildInfo,1)="exp")&&($LG(tAggChildInfo,6)="NOP") {
										// This is an expression node with no value - do not accumulate it
										Set tAccumulate = 0
									}

									// This might be the second child of a NOP expression, in which case it should not be accumulated.
									Set tTestParent = $G($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",$LG(tAggChildInfo,4)))
									Set tTestGrandParent = $G($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",$LG(tTestParent,4)))
									If ($LG(tTestGrandParent,1)="exp")&&($LG(tTestGrandParent,6)="NOP") {
										Set tAccumulate = 0
									}
									
								}
								
								If tAccumulate {
									Set tSC = ..%AggregateAccum(tOp,.tAggFlags,.tAggContext,tVal)
									If $$$ISERR(tSC) Quit
								}
							}
							
							Set tLeafChild = $O(tDescNodes(tLeafChild))
						}
						
						If (tAggParentNo'="") {
							Set tAddr(a) = tChild
							Set tChild = ""
						}
						ElseIf ($G(tAggNodeNo)'="") {
							// DTB400 - Reset the aggregate chain info to stop walking the chain
							set tAggNodeNo=""
						}

						Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a),"ch",tChild))
					}
					If $$$ISERR(tSC) Quit
					
					Merge tAddr = tOriginalAddr		// DTB400
					
					If ('tIsDrillThru) {
						// JMD: Some aggregates (namely %KPI and %MDX) may need the context of the
						// current cell; compute it here
						If ((tOp = "%KPI")||(tOp = "%MDX")) {
							// find context of current cell
							// convert to tuple(s)
							Set tSC = ..%ComputeTupleForCell(pCube,pKey,.tAddr,.tTuple)
							If $$$ISERR(tSC) Quit
							
							// combine tuples into one ";"-delimited list	
							Set tCellSpec = ""
							Set ta = $O(tTuple(""))
							While (ta'="") {
								// escape any ; in the spec
								Set ts = $Replace(tTuple(ta),";",";;")
								Set tCellSpec = tCellSpec _ $S(tCellSpec="":"",1:";") _ ts
								Set ta = $O(tTuple(ta))
							}

							// Add slicer (with "F:" prefix)
							Set tSlicer = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"slicer"))
							If (tSlicer '= "") {
								// DTB247 - The "slicer" node may only contain an unresolvable calculated member string
								Set tSlicerKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"axis",0))
								If tSlicerKey'="" {
									// Find the final leaf in the slicer to begin from
									
									// DTB818 - Check for a logged request node for this DeepSee session. If it exists, use it. Otherwise
									//   resolve the filed axis nodes back into MDX text 
									// DTB947 - This broke the %CONTEXT if a calc measure was used in the slicer for a %MDX
									//   subquery. The DTB818 change is only intended for %KPI
									If (tOp="%KPI")&&$D($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"request",$$$DeepSeeSessionId),tRequestSpec)&&($G(tRequestSpec)'="") {
										Set ts = "F:"_$Replace(tRequestSpec,";",";;")
										Set tCellSpec = tCellSpec _ $S(tCellSpec="":"",1:";") _ ts
									}
									Else {
										Set tSlicerLeaf = $O($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",1,"all",""),-1)
										While (tSlicerLeaf'="") {
											// DTB681 - Make sure the slicer leaf exists
											Set tSlicer = ..%GetSpecForAxisNode(pCube,pKey,0,tSlicerLeaf)
											Set ts = "F:"_$Replace(tSlicer,";",";;")
											Set tCellSpec = tCellSpec _ $S(tCellSpec="":"",1:";") _ ts
											Set tSlicerLeaf = $O($$$DeepSeeAxisGLVN(tCubeIndex,tSlicerKey,"axes",1,"all",tSlicerLeaf),-1)
										}
									}
								}
							}
							// pass along as part of context
							Set:tCellSpec'="" tAggContext(tOp,"context") = tCellSpec
						}
						// +DTB060: We are on an aggregate axis. Test the other axes and intermediate results to see if this cell should display for a null cell
						Set tShowResult=1		
						If tFinalAxisCount>=1 {
							For b=1:1:tFinalAxisCount {
								If ($G(tAxisNonEmpty(tSortedAxisNo(b)),0)&&(a'=b)) {
									Set tShowResult = tShowResult&&$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",b,tAddr(b)))
								}
							}
						}
						Set tAggContext("ShowResult") = tShowResult
						// -DTB060
						
						Set tSC = ..%AggregateEnd(tOp,.tAggFlags,.tAggContext,.tValue,.tPendingInfo,tCubeIndex,pKey)
						If $$$ISERR(tSC) Quit
					}
				}
				ElseIf (tCType="eq") {
					// pass through value of child node
					Set tOp = $LG(tCNode,6)
					// see if our child has been resolved
					Kill tOpKey
					For b = 1:1:tFinalAxisCount {
						Set tOpKey(b) = tAddr(b)
					}
					Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a),"ch",""))
					If (tChild'="") {
						// "child" could be a tuple, if so get its deepest child
						While (1) {
							Set tChildInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tChild))
							If ((($LG(tChildInfo,1)="mbr")||($LG(tChildInfo,1)="msr"))&&$D($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tChild,"ch"))) {
								Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tChild,"ch",""))
							}
							Else {
								Quit
							}
						}

						// contruct addr for child
						Set n = 0
						Set tOpKey(a) = tChild
						Set k = $O(tOpKey(""))
						While (k '= "") {
							Set tOpAddr($I(n)) = k
							Set k = $O(tOpKey(k))
						}
						Set tOpCellAddr = ""
						For a=1:1:tFinalAxisCount {
							Set tOpCellAddr = tOpCellAddr _ $S(a>1:",",1:"") _ tOpKey(a)
						}
						Set tValue = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKey)
					}
				}
				ElseIf (tCType="exp") {
					// expression -- see if we can evaluate
					// get address of all operands
					Set tOp = $LG(tCNode,6)
					Set tTertiary = $Case(tOp,"IIF":1,:0)
					Set tIsScalar = 0
					Set tMaxArgs = 0
					Kill tChildExp
					If (tTertiary) {
						Set tChildCount = 3
					}
					Else {
						// test for scalar
						// scalar (-1 means not a scalar; otherwise number of args)
						Set tScalarArgs = ##class(%DeepSee.Query.scalarFunction).%IsScalarFunction(tOp)
						If (tScalarArgs=-1) {
							Set tChildCount=2
						}
						Else {
							Set tIsScalar = 1
							Set tMinArgs = +$P(tScalarArgs,":",1)
							Set tMaxArgs = $S(tScalarArgs[":":+$P(tScalarArgs,":",2),1:tMinArgs)
							Set tChildCount = tMaxArgs
						}
					}

					// get node #s
					Kill tChildNode
					For cn=1:1:tChildCount { 
						// DTB400 - Look for tagged expression arguments that are arguments within a chained aggregate structure
						If ($LG($G(tChildNode),24)'="")&&($G(tChildExp(cn-1))'=$LG($G(tChildNode),24)) {
							// Chained expression
							Set tChildExp(cn) = $O(^DeepSee.Cache.Axis(tCubeIndex,tRealAxisKey(a),"axes",$G(tChildExp(cn-1)),"ch",$G(tChildExp(cn-1))))
						}
						Else {
							// Laterally branched children arguments
							Set tChildExp(cn) = $O(^DeepSee.Cache.Axis(tCubeIndex,tRealAxisKey(a),"axes",tAddr(a),"ch",$G(tChildExp(cn-1))))
						}
						Quit:tChildExp(cn)=""
						
						Set tChildNode = $$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",$G(tChildExp(cn)))		// DTB400
					}

					// DTB068 - drill to bottom to find value if child is a set, orset, tuple, or ortuple.
					For cn=1:1:tChildCount {
						If ($G(tChildExp(cn))'="") {
							Set tChildExpType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tChildExp(cn)),1)
							If ((tChildExpType["tuple")||(tChildExpType["set"))  {
								While (1) {
									Set tSubNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,tRealAxisKey(a),"axes",tChildExp(cn),"ch",""))
									If (tSubNode="") {
										Quit
									}
									Else {
										Set tChildExp(cn) = tSubNode
									}
								}
							}
						}
					}

					Kill tOpKey
					For b = 1:1:tFinalAxisCount {
						If (a = b) {
							For cn=1:1:tChildCount {
								Set tOpKey(cn,b) = $G(tChildExp(cn))
							}
						}
						Else {
							For cn=1:1:tChildCount {
								Set tOpKey(cn,b) = tAddr(b)
							}
						}
					}

					// strip out missing arguments
					Set cn = $O(tOpKey(""),-1)
					While (cn'="") {
						Set ck = $O(tOpKey(cn,""))
						While (ck'="") {
							If (tOpKey(cn,ck)="") {
								Kill tOpKey(cn)
								Set tChildCount = tChildCount - 1
								Quit
							}
							Set ck = $O(tOpKey(cn,ck))
						}
						Set cn = $O(tOpKey(cn),-1)
					}

					// contruct addr for each op
					Kill tOpAddr,tOpCellAddr
					For op = 1:1:tChildCount {
						Set n = 0
						Set k = $O(tOpKey(op,""))
						While (k '= "") {
							Set tOpAddr(op,$I(n)) = k
							Set k = $O(tOpKey(op,k))
						}
						Set tOpCellAddr(op) = ""
						For aq=1:1:tFinalAxisCount {
							Set tOpCellAddr(op) = tOpCellAddr(op) _ $S(aq>1:",",1:"") _ tOpKey(op,aq)
						}
					}
					// if all children have been resolved, then we can evaluate
					If (tOp = "IIF") {
						If (('$D(pCalcCells(tOpCellAddr(1))))&&(($G(tOpCellAddr(2))="")||('$D(pCalcCells(tOpCellAddr(2)))))&&(($G(tOpCellAddr(3))="")||('$D(pCalcCells(tOpCellAddr(3)))))) {
							Kill tOpKeys
							Merge tOpKeys = tOpKey(1)
							Set tVal1 = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKeys)
							// JMD1357
							If (tChildCount>=2) {
								Kill tOpKeys
								Merge tOpKeys = tOpKey(2)
								Set tVal2 = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKeys)
							}
							Else {
								Set tVal2 = ""
							}
							If (tChildCount>=3) {
								Kill tOpKeys
								Merge tOpKeys = tOpKey(3)
								Set tVal3 = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKeys)
							}
							Else {
								Set tVal3 = ""
							}
							If (tIsDrillThru) {
								Set tValue = tVal2 _ tVal3
							}
							Else {
								If (tVal1) {
									Set tValue = tVal2
								}
								Else {
									Set tValue = tVal3
								}
							}
							Set:tValue="" tIIFMissing = 1
						}
					}
					ElseIf(",+,-,*,/,>,>=,<,<=,=,<>,NOP,AND,OR,"[(","_tOp_",")) {
						Kill tOpKeys
						Merge tOpKeys = tOpKey(1)
						Set tVal1 = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKeys)
						Kill tOpKeys
						Merge tOpKeys = tOpKey(2)
						Set tVal2 = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKeys)
						// for numeric comparisons, treat null as zero,
						If ((tOp="=")||(tOp=">")||(tOp=">=")||(tOp="<")||(tOp="<=")||(tOp="<>")) {
							If ($IsValidNum(tVal1)&&(tVal2="")) {
								Set tVal2 = 0
							}
							If ($IsValidNum(tVal2)&&(tVal1="")) {
								Set tVal1 = 0
							}
						}

						// for expressions involving "" value, propagate null
						If (tOp="NOP") {
							// special NOP operator used for
							// synthetic expressions
							Set tValue = tVal1 _ tVal2
						}
						ElseIf (tIsDrillThru) {
							Set tValue = tVal1 _ tVal2
						}
						ElseIf ((tVal1="")||(tVal2="")) {
							// pass null along
							Set tValue = ""
						}
						ElseIf ($E(tVal1)="@") {
							// propagate errors
							Set tValue = tVal1
						}
						ElseIf ($E(tVal2)="@") {
							// propagate errors
							Set tValue = tVal2
						}
						ElseIf ($IsValidNum(tVal1)&&$IsValidNum(tVal2)) {
							// divide by zero is NULL!
							Set tValue = $Case(tOp,
									"+":tVal1+tVal2,
									"*":tVal1*tVal2,
									"/":$S(tVal2'=0:tVal1/tVal2,1:""),
									"-":tVal1-tVal2,
									">":tVal1>tVal2,
									"<":tVal1<tVal2,
									">=":tVal1>=tVal2,
									"<=":tVal1<=tVal2,
									"=":tVal1=tVal2,
									"<>":tVal1'=tVal2,
									"AND":tVal1&&tVal2,
									"OR":tVal1||tVal2,
									:"N/A")
						}
						Else { // strings
							Set tValue = $Case(tOp,
									"+":tVal1_tVal2,
									">":(tVal1]]tVal2)&&(tVal1'=tVal2),
									"<":(tVal1']]tVal2)&&(tVal1'=tVal2),
									">=":(tVal1]]tVal2)||(tVal1=tVal2),
									"<=":(tVal1']]tVal2)||(tVal1=tVal2),
									"=":tVal1=tVal2,
									"<>":tVal1'=tVal2,
									:"N/A")
						}
					}
					ElseIf (tIsScalar) {
						// invoke scalar function (up to 6 args)
						Kill tScalarVals
						Set tScalarResolved = 1
						For sa = 1:1:tChildCount {
							If (('$D(pCalcCells(tOpCellAddr(sa))))) {
								Kill tOpKeys
								Merge tOpKeys = tOpKey(sa)
								Set tScalarVals(sa) = $$GETVAL(tFinalAxisCount,tFoldSlot,.tOpKeys)
							}
							Else {
								Set tScalarResolved = 0
								Quit
							}
						}
					
						If (tScalarResolved) {
							Set tValue = $Case(tChildCount,
								0:##class(%DeepSee.Query.scalarFunction).%EvaluateScalar(tOp),
								1:##class(%DeepSee.Query.scalarFunction).%EvaluateScalar(tOp,tScalarVals(1)),
								2:##class(%DeepSee.Query.scalarFunction).%EvaluateScalar(tOp,tScalarVals(1),tScalarVals(2)),
								3:##class(%DeepSee.Query.scalarFunction).%EvaluateScalar(tOp,tScalarVals(1),tScalarVals(2),tScalarVals(3)),
								4:##class(%DeepSee.Query.scalarFunction).%EvaluateScalar(tOp,tScalarVals(1),tScalarVals(2),tScalarVals(3),tScalarVals(4)),
								5:##class(%DeepSee.Query.scalarFunction).%EvaluateScalar(tOp,tScalarVals(1),tScalarVals(2),tScalarVals(3),tScalarVals(4),tScalarVals(5)),
								6:##class(%DeepSee.Query.scalarFunction).%EvaluateScalar(tOp,tScalarVals(1),tScalarVals(2),tScalarVals(3),tScalarVals(4),tScalarVals(5),tScalarVals(6)),
								:"N/A")
						}
					}
					Else {
						Set tValue = "N/A"
					}
				} // tCType="exp"
			} // for a

			Set tFound = 1
			If ($D(tValue)) {
				Kill pCalcCells(tCellAddr)

				// JMD900: if there are pending results, note them in the pending section
				If (pPhase=1) {
					If ($D(tPendingInfo)) {
						Set tPendingAddr = ""
						Set pa = $O(tAddr(""))
						While (pa'="") {
							Set tPendingAddr = tPendingAddr_$S(tPendingAddr="":"",1:",")_tAddr(pa)
							Set pa = $O(tAddr(pa))
						}
						If (tPendingAddr'="") {
							Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"pending",tPendingAddr) = tPendingInfo
						}
					}
				}

				// place value in result cache
				If (tValue'="") {
					// has value
					Do SETRESULT(tFinalAxisCount,tFoldSlot,tValue)
					// note cells dependent on pending cells
					
					If ($P(tValue," ",1)="@Computing") {
						If ('$D(tPendingInfo)) {
							Set pPendingCells(tCellAddr) = tCellAddrInfo
						}
					}
					
					// mark that this node has values
					If (tVisible) {
						If (tFinalAxisCount>=1) {
							For a=1:1:tFinalAxisCount {
								// + WAL110 -- first condition means that this node is already non empty for 
								//             a reason *other than* the current pending node we're looking 
								//             at. In this case, mark the node 29 so that the %UpdatePendingResults
								//             logic knows not to remove it even if the pending result turns out
								//             to be empty
								If (($G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)))'=27)
									&&($G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)))'="")) {
									Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 29
								}
								Else {
									Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 27
								}
								// - WAL110 
							}
						}
					}
				}
				Else {					
					// no value
					If (tVisible && (tFinalAxisCount>=1)) {
						For a=1:1:tFinalAxisCount {
							// if not NON EMPTY set display flag
							// JMD970.2: convert to sorted axis no
							// JMD1373: IIF and missing currmember value
							If ($G(tIIFMissing,0)) {
 								If $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)))=11 {
	 								// JMD1373 (2) test for non-empty
	 								If ($G(tAxisNonEmpty(tSortedAxisNo(a)),0)) {
	 									Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a))
	 								}
 								}
							}
							Else {
								Set:'$G(tAxisNonEmpty(tSortedAxisNo(a)),0) $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 28
							}
						}
					}
				}
				Kill tIIFMissing
			}
			// + WAL082 -- iterate through ordered list of cells returned by %ResolveComputations
			//             instead of using pCalcCells directly
			Set tCellIndex = $O(tOrderedCalcCells(tCellIndex))
			Set tCellAddr = $S(tCellIndex="":"",1:tOrderedCalcCells(tCellIndex))
			// - WAL082
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC

	// set value into final result (copy)
SETRESULT(tResultAxisCount,tSlot,tValue)
	Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,tAxisCount)		// DTB400
	If $$$ISERR(tSC) Quit
	Goto $Case(tResultAxisCount,0:DIM0,1:DIM1,2:DIM2,3:DIM3,:DIMERR)
DIM0
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot) = tValue
	Quit
DIM1
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1)) = tValue
	Quit
DIM2
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1),tAddr(2)) = tValue
	Quit
DIM3
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1),tAddr(2),tAddr(3)) = tValue
	Quit
DIMERR
	Set tSC = $$$ERROR($$$GeneralError,"Too many dimensions in query: " _ (tResultAxisCount))
	Quit

	// lookup value in result cache; tOpKey is array of subscripts
	// copied from %Consolidate
GETVAL(tRealAxisCount,tAnswerSlot,tOpKey)
	Quit $Case(tRealAxisCount,
		1:$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tOpKey(1))),
		2:$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tOpKey(1),tOpKey(2))),
		3:$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tAnswerSlot,tOpKey(1),tOpKey(2),tOpKey(3))),
		:"")
}

/// This is called by %ComputeExpressions
/// pCalcCells contains the list of addresses for all cells that need to be computed.
/// %ResolveComputations returns an ordered list (pOrderedCalcCells) of the form:
///       pOrderedCalcCells(index)=cellAddr
/// The addresses are ordered such a way that no cell contains a computation referencing a cell 
/// occurring later in the list. This means that %ComputeExpressions can evaluate all calculated cells
/// in a single pass.
ClassMethod %ResolveComputations(pCube As %String, pKey As %String, ByRef pCalcCells, Output pOrderedCalcCells, pFinalAxisCount As %String, ByRef pRealAxisKey) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tQueryType = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"queryType"))
		Set tIsDrillThru = (tQueryType = "DRILLTHROUGH")
		// WAL082 -- "depth" is used to make sure that a cell follows the cells
		//           it depends on in pOrderedCalcCells
		Set pOrderedCalcCells("depth") = 0
		// WAL082 -- tStack maintains a list of nodes we need to revisit after resolving references
		Set tStack=0
		Set tCellAddr = $O(pCalcCells(""))	
		While (tCellAddr'="") {
			Set tCellAddrInfo = $G(pCalcCells(tCellAddr))
			Kill tAddr
						
			// Split the addr into a node of each axis
			For a=1:1:pFinalAxisCount {
				Set tAddr(a) = $P(tCellAddr,",",a)
			}
			
			// DTB400 - Resolve aggregate address
			Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,pFinalAxisCount)
			If $$$ISERR(tSC) Quit

			// see if we can evaluate
			Kill tValue
			Kill tPendingInfo
			Set tVWeight = 0		// used to resolve conflicts between axes
			Set tVisible = 1

			// first look at all axes to find what kind of cell this is,
			// its visibility,
			// and which axis to look at in order to resolve it
			Set tCellType = ""
			Set tCellWeight = 0
			Set tSolveOrder = 0
			Set tCalcAxis = 0
			For a = 1:1:pFinalAxisCount {
				If $$$ISERR(tSC) Quit
				Set tCNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a)))
				Set tVisible = tVisible && +$LG(tCNode,2)
				Set tCellType = $LG(tCNode,1)

				// JMD1498 find weight of child with highest weight
				// solve order trumps cell weight, if present
				// in case of tie, lowest axis wins
				Kill tVisited
				Do ..%ComputeCellWeight(tCubeIndex,pRealAxisKey(a),tAddr(a),.tAWeight,.tASolveOrder,0,.tVisited)
				If (tASolveOrder>tSolveOrder) {
					Set tCalcAxis = a
					Set tSolveOrder = tASolveOrder
					Set tCellWeight = tAWeight
				}
				ElseIf ((tASolveOrder=tSolveOrder)&&(tAWeight>tCellWeight)) {
					Set tCalcAxis = a
					Set tCellWeight = tAWeight
				}
			}
			// WAL082 -- only one axis can specify the computation; this is determined in the 
			//           above block and used below (tCalcAxis)
			//
			//           The If block below is the heart of this method
			//           For each node type it determines if the computation can be resolved
			//           or if it refers to another calculated cell. If the computation can't be 
			//           resolved, %ResolveComputations is called recursively on the referent
			Set a = tCalcAxis
			If (a>0) {
				If $$$ISERR(tSC) Quit
				Set tCNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a)))
				Set tCType = $LG(tCNode,1)

				Set tAddrIterator = ""

				If (tCType="lit") {
					// literal-- pick it up
					Set tValue = $LG(tCNode,6)
					
					// WAL082 -- if we can resolve this node, remove it from pCalcCells and place it in the
					//           ordered array
					//           This code is the same for all node types
					//           pOrderedCalcCells("index",tCellAddr) is used throughout to test 
					//           whether a referent is a calculated node or not and is killed at the end
					//           If a node refers to a calculated node depth is increased to make sure the
					//           referent gets resolved first
					If ($D(pCalcCells(tCellAddr))) {
						Set pOrderedCalcCells(pOrderedCalcCells("depth"),$i(pOrderedCalcCells)) = tCellAddr
						Set pOrderedCalcCells("index",tCellAddr) = ""
						Kill pCalcCells(tCellAddr)
						Set tStackIndex = $O(tStack(""),-1)
						If (tStackIndex'="") {
							Set tCellAddr = tStack(tStackIndex)
							Kill tStack(tStackIndex)
							If (tStack>0) Set tStack = tStack - 1
							Continue	
						}
					}
				}
				ElseIf (tCType="cell") {
					// cell function: see if we can resolve it
					Set tCellFunc = $LG(tCNode,6)

					// get function args: they are children of the function
					Kill tArgs
					Set tChildNo = 0
					Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a),"ch",""))
					While (tChild '= "") {
						Set tChildNo = tChildNo + 1
						Set tArgs(tChildNo) = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tChild)),6)
						Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a),"ch",tChild))
					}
					
					// see if we can resolve the function
					If ((tCellFunc = "%CELL")||(tCellFunc = "%CELLZERO")) {
						// tAddr is address of *this* cell,
						// now find cell relative to this and put it into
						// tOpKey; only 2-D results are supported

						Kill tOpKey
						For b = 1:1:pFinalAxisCount {
							If (b>2) {
								Set tOpKey(b) = tAddr(b)
							}
							Else {
								Set tAxisNode(b) = 1  // WAL082 -- this is always 1 in %ComputeExpressions; just hardcode instead of passing as an argument
								Set tOpKey(b) = ..%FindRelativeNode(tCubeIndex,pRealAxisKey(b),tAxisNode(b),tAddr(b),tArgs(b),1,pKey,b)		// DTB770 - Add check for "nonempty" indicators
							}
							If (tOpKey(b)="") {
								Set tValue = 0
							}
						}
						//  WAL082 -- Resolution rules for %CELL and %CELLZERO
						//            If there is no value AND the referent is in pCalcCells, we aren't resolved
						//            otherwise we are
						If ('$D(tValue)) {
							Set tOpCellAddr = ""
							For b=1:1:pFinalAxisCount {
								Set tOpCellAddr = tOpCellAddr _ $S(b>1:",",1:"") _ tOpKey(b)
							}
							// JMD736
							If ((tArgs(1)=0)&&(tArgs(2)=0)) {
								Set tValue = "@CIRC"
								Set tResolved = 1
							}
							// WAL082 -- if we are referring to a calculated cell that isn't resolved yet, go resolve that cell
							//           before moving on
							ElseIf ($D(pCalcCells(tOpCellAddr))) {
								// WAL082 -- Place this node on the stack so that we revisit it after resolving referents.
								//           Start the loop over, processing the referent (tOpCellAddr)
								
								// DTB141 - check the stack for loops before adding to it
								If $D(tStack) {
									Set tStackAddr = $O(tStack(""),-1)
									Set tLoopTest = 0
									While (tStackAddr'="") {
										If (tStack(tStackAddr)=tOpKey(b))||(tStack(tStackAddr)=tCellAddr) {
											If tLoopTest {
												Set tFunctionOne = $LG($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a)),6)
												Set tFunctionTwo = $LG($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tOpKey(a)),6)
												
												Set tSC = $$$ERROR($$$GeneralError,"Cannot resolve loop in cell functions ("_tFunctionOne_":"_tFunctionTwo_")")
											}
											Else {
												Set tLoopTest = 1
											}
										}
										Set tStackAddr = $O(tStack(tStackAddr),-1)
									}
								}
								
								If $$$ISERR(tSC) Quit
								
								Set tStack($i(tStack)) = tCellAddr
								Set tCellAddr = tOpCellAddr
								Continue
							}
							Set tResolved=1
							If ($D(pOrderedCalcCells("index",tOpCellAddr))) {
								Set pOrderedCalcCells("depth") = $i(pOrderedCalcCells("depth"))
							}
						}
						// WAL082 -- all of our referents are resolved, mark as resolved
						If ($D(tValue) || ($G(tResolved)'="")) {
							If ($D(pCalcCells(tCellAddr))) {
								Set pOrderedCalcCells(pOrderedCalcCells("depth"),$i(pOrderedCalcCells)) = tCellAddr
								Set pOrderedCalcCells("index",tCellAddr) = ""
								Kill pCalcCells(tCellAddr)
								
								// WAL082 -- get next item from stack; start the loop over to process that item
								Set tStackIndex = $O(tStack(""),-1)
								If (tStackIndex'="") {
									Set tCellAddr = tStack(tStackIndex)
									Kill tStack(tStackIndex)
									If (tStack>0) Set tStack = tStack - 1
									Continue	
								}
							}
						}
					}
				}
				ElseIf (tCType="agg") {
					// aggregate function
					Kill tOpKey
					For b = 1:1:pFinalAxisCount {
						Set tOpKey(b) = tAddr(b)
					}
					Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a),"ch",""))
					While (tChild '= "") {
						If $$$ISERR(tSC) Quit
						// contruct addr for child
						// child could be result of crossjoin or tuple
						// and thus could have a set of descendants

						Kill tDescNodes
						Do ##class(%DeepSee.Query.Engine).%GetDescendantNodes(.tDescNodes,tCubeIndex,pRealAxisKey(a),tChild)

						Set tLeafChild = $O(tDescNodes(""))
						While (tLeafChild'="") {
							Set tContinue=0
							Set n = 0
							Set tOpKey(a) = tLeafChild
							Set k = $O(tOpKey(""))
							While (k '= "") {
								Set tOpAddr($I(n)) = k
								Set k = $O(tOpKey(k))
							}
							Set tOpCellAddr = ""
							For ax=1:1:pFinalAxisCount {
								Set tOpCellAddr = tOpCellAddr _ $S(ax>1:",",1:"") _ tOpKey(ax)
							}
							If ($D(pCalcCells(tOpCellAddr))) {
								Set tStack($i(tStack)) = tCellAddr
								Set tCellAddr = tOpCellAddr
								Set tContinue = 1
								Quit
							}
							If ($D(pOrderedCalcCells("index",tOpCellAddr))) {
								Set pOrderedCalcCells("depth") = $i(pOrderedCalcCells("depth"))
							}
							Set tLeafChild = $O(tDescNodes(tLeafChild))
						}
						If ($G(tContinue)=1) Quit
						Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a),"ch",tChild))
					}
					If ($G(tContinue)=1) Continue
					// WAL082 -- all children are resolved, mark us as resolved
					If ($D(pCalcCells(tCellAddr))) {
						Set pOrderedCalcCells(pOrderedCalcCells("depth"),$i(pOrderedCalcCells)) = tCellAddr
						Set pOrderedCalcCells("index",tCellAddr) = ""
						Kill pCalcCells(tCellAddr)
						
						Set tStackIndex = $O(tStack(""),-1)
						If (tStackIndex'="") {
							Set tCellAddr = tStack(tStackIndex)
							Kill tStack(tStackIndex)
							If (tStack>0) Set tStack = tStack - 1
							Continue	
						}
					}
					If $$$ISERR(tSC) Quit
				}
				ElseIf (tCType="eq") {
					// pass through value of child node
					Set tOp = $LG(tCNode,6)
					// see if our child has been resolved
					Kill tOpKey
					For b = 1:1:pFinalAxisCount {
						Set tOpKey(b) = tAddr(b)
					}
					Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a),"ch",""))
					If (tChild'="") {
						// "child" could be a tuple, if so get its deepest child
						While (1) {
							Set tChildInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tChild))
							If ((($LG(tChildInfo,1)="mbr")||($LG(tChildInfo,1)="msr"))&&$D($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tChild,"ch"))) {
								Set tChild = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tChild,"ch",""))
							}
							Else {
								Quit
							}
						}
						// contruct addr for child
						Set n = 0
						Set tOpKey(a) = tChild
						Set k = $O(tOpKey(""))
						While (k '= "") {
							Set tOpAddr($I(n)) = k
							Set k = $O(tOpKey(k))
						}
						Set tOpCellAddr = ""
						For a=1:1:pFinalAxisCount {
							Set tOpCellAddr = tOpCellAddr _ $S(a>1:",",1:"") _ tOpKey(a)
						}
						// WAL082 -- if NOT resolved
						If ($D(pCalcCells(tOpCellAddr))) {
							Set tStack($i(tStack)) = tCellAddr
							Set tCellAddr = tOpCellAddr
							Continue
						}
						// WAL082 -- If child was just processed, make sure this node has a higher depth
						If ($D(pOrderedCalcCells("index",tOpCellAddr))) {
							Set pOrderedCalcCells("depth") = $i(pOrderedCalcCells("depth"))
						}
					}
					// WAL082 -- we resolved the child, so we're resolved now
					If ($D(pCalcCells(tCellAddr))) {
						Set pOrderedCalcCells(pOrderedCalcCells("depth"),$i(pOrderedCalcCells)) = tCellAddr
						Set pOrderedCalcCells("index",tCellAddr) = ""
						Kill pCalcCells(tCellAddr)
						
						Set tStackIndex = $O(tStack(""),-1)
						If (tStackIndex'="") {
							Set tCellAddr = tStack(tStackIndex)
							Kill tStack(tStackIndex)
							If (tStack>0) Set tStack = tStack - 1
							Continue	
						}
					}
				}
				ElseIf (tCType="exp") {
					// expression -- see if we can evaluate
					// get address of all operands
					Set tOp = $LG(tCNode,6)
					Set tTertiary = $Case(tOp,"IIF":1,:0)
					Set tIsScalar = 0
					Set tMaxArgs = 0
					Kill tChildExp
					If (tTertiary) {
						Set tChildCount = 3
					}
					Else {
						// test for scalar
						// scalar (-1 means not a scalar; otherwise number of args)
						Set tScalarArgs = ##class(%DeepSee.Query.scalarFunction).%IsScalarFunction(tOp)
						If (tScalarArgs=-1) {
							Set tChildCount=2
						}
						Else {
							Set tIsScalar = 1
							Set tMinArgs = +$P(tScalarArgs,":",1)
							Set tMaxArgs = $S(tScalarArgs[":":+$P(tScalarArgs,":",2),1:tMinArgs)
							Set tChildCount = tMaxArgs
						}
					}

					// get node #s
					For cn=1:1:tChildCount {
						Set tChildExp(cn) = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tAddr(a),"ch",$G(tChildExp(cn-1))))
						Quit:tChildExp(cn)=""
					}

					// DTB068 - drill to bottom to find value if child is a set, orset, tuple, or ortuple.
					For cn=1:1:tChildCount {
						If ($G(tChildExp(cn))'="") {
							Set tChildExpType = $LG($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tChildExp(cn)),1)
							If ((tChildExpType["tuple")||(tChildExpType["set"))  {
								While (1) {
									Set tSubNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,pRealAxisKey(a),"axes",tChildExp(cn),"ch",""))
									If (tSubNode="") {
										Quit
									}
									Else {
										Set tChildExp(cn) = tSubNode
									}
								}
							}
						}
					}

					Kill tOpKey
					For b = 1:1:pFinalAxisCount {
						If (a = b) {
							For cn=1:1:tChildCount {
								Set tOpKey(cn,b) = $G(tChildExp(cn))
							}
						}
						Else {
							For cn=1:1:tChildCount {
								Set tOpKey(cn,b) = tAddr(b)
							}
						}
					}

					// strip out missing arguments
					Set cn = $O(tOpKey(""),-1)
					While (cn'="") {
						Set ck = $O(tOpKey(cn,""))
						While (ck'="") {
							If (tOpKey(cn,ck)="") {
								Kill tOpKey(cn)
								Set tChildCount = tChildCount - 1
								Quit
							}
							Set ck = $O(tOpKey(cn,ck))
						}
						Set cn = $O(tOpKey(cn),-1)
					}

					// contruct addr for each op
					Kill tOpAddr,tOpCellAddr
					For op = 1:1:tChildCount {
						Set n = 0
						Set k = $O(tOpKey(op,""))
						While (k '= "") {
							Set tOpAddr(op,$I(n)) = k
							Set k = $O(tOpKey(op,k))
						}
						Set tOpCellAddr(op) = ""
						For aq=1:1:pFinalAxisCount {
							Set tOpCellAddr(op) = tOpCellAddr(op) _ $S(aq>1:",",1:"") _ tOpKey(op,aq)
						}
					}
					If (tOp = "IIF") {
						Set tOpNumber = 3
					}
					ElseIf(",+,-,*,/,>,>=,<,<=,=,<>,NOP,AND,OR,"[(","_tOp_",")) {
						Set tOpNumber = 2
					}
					ElseIf (tIsScalar) {
						Set tOpNumber = tChildCount
					}
					If ($G(tOpNumber)'="") {
						For i=1:1:tOpNumber {
							Set tContinue=0
							If ($D(tOpCellAddr(i))) {
								If ($D(pCalcCells(tOpCellAddr(i)))) {
									Set tStack($i(tStack)) = tCellAddr
									Set tCellAddr = tOpCellAddr(i)
									Set tContinue=1
									Quit
								}
								If ($D(pOrderedCalcCells("index",tOpCellAddr(i)))) {
									Set pOrderedCalcCells("depth") = $i(pOrderedCalcCells("depth"))
								}			
							}					
						}
						If ($G(tContinue)=1) Continue
						// WAL082 -- we resolved all children, so we're resolved now; add to ordered list
						If ($D(pCalcCells(tCellAddr))) {
							Set pOrderedCalcCells(pOrderedCalcCells("depth"),$i(pOrderedCalcCells)) = tCellAddr
							Set pOrderedCalcCells("index",tCellAddr) = ""
							Kill pCalcCells(tCellAddr)
							
							Set tStackIndex = $O(tStack(""),-1)
							If (tStackIndex'="") {
								Set tCellAddr = tStack(tStackIndex)
								Kill tStack(tStackIndex)
								If (tStack>0) Set tStack = tStack - 1
								Continue	
							}
						}		
					}
				} // tCType="exp"
				// WAL082 -- if we aren't calculated, then move on
				Else {
					// WAL082 -- if it's some other type, just move it over so we don't hang the show
					If ($D(pCalcCells(tCellAddr))) {
						Set pOrderedCalcCells(pOrderedCalcCells("depth"),$i(pOrderedCalcCells)) = tCellAddr
						Set pOrderedCalcCells("index",tCellAddr) = ""
						Kill pCalcCells(tCellAddr)
					}
				}
			} // for a
			// WAL082 -- each loop should remove some or all calc cells
			//           the cell we looked at should be gone by now
			//           so iterate by grabbing the first remaining cell
			Set tCellAddr = $O(pCalcCells(""))
		}
		// WAL082 -- Flatten pOrderedCalcCells into a one dimensional array
		//           %ComputeExpressions will iterate through the final array
		//           to compute the expressions in the right order
		Kill pOrderedCalcCellsFinal
		Kill pOrderedCalcCells("index")
		Set tDepth = $O(pOrderedCalcCells(""))	
		While (tDepth'="") {
			Set tIndex = $O(pOrderedCalcCells(tDepth,""))
			While (tIndex '= "") {
				Set pOrderedCalcCellsFinal($i(pOrderedCalcCellsFinal)) = pOrderedCalcCells(tDepth,tIndex)
				Set tIndex = $O(pOrderedCalcCells(tDepth,tIndex))	
			}
			Set tDepth = $O(pOrderedCalcCells(tDepth))	
		}
		Kill pOrderedCalcCells
		Merge pOrderedCalcCells = pOrderedCalcCellsFinal
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Compute the "weight" of the given node within an axis.
/// This is used to determine which axis has precedence when computing a cell value.
ClassMethod %ComputeCellWeight(pCubeIndex As %String, pAxisKey As %String, pNodeNo As %Integer, Output pWeight As %Decimal, Output pSolveOrder As %Decimal, pLevel As %Integer = 0, ByRef pVisited) [ Internal ]
{
	If ($D(pVisited(pNodeNo))) {
		Quit
	}
	Set pVisited(pNodeNo) = ""
	// JMD1498
	If (pLevel=0) {
		Set pWeight = 0
		Set pSolveOrder = 0
	}
	Set tCNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pNodeNo))
	Set tCellType = $LG(tCNode,1)
	Set tCSolveOrder = +$LG(tCNode,15)

	Set:tCSolveOrder>=pSolveOrder pSolveOrder=tCSolveOrder

	// weight for this axis
	// weight is adjusted by solve_order: higher solve order always
	// trumps intrinsic weight.
	Set tWeight = $Case(tCellType,"lit":2,"eq":3,"exp":4,"agg":5,"cell":6,:1)
	If (tCellType="agg") {
		Set tOp = $LG(tCNode,6)
		If ((tOp="%KPI")||(tOp="%MDX")) {
			// JMD1390 lower weight for %KPI and %MDX
			Set tWeight = tWeight - 0.5
		}
	}
	ElseIf (tCellType="cell") {
		// JMD1498 implicit solveorder for %CELL
		Set:pSolveOrder<10 pSolveOrder=10
	}

	Set:tWeight>=pWeight pWeight=tWeight
	// now test child nodes
	Set tChildNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pNodeNo,"ch",""))
	While (tChildNodeNo'="") {
		Do ..%ComputeCellWeight(pCubeIndex,pAxisKey,tChildNodeNo,.pWeight,.pSolveOrder,$S(pLevel<0:pLevel,1:pLevel+1),.pVisited)
		Set tChildNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pNodeNo,"ch",tChildNodeNo))
	}

	// JMD1504 for (local) top node, check higher level nodes
	If (pLevel=0) {
		If ((tCellType="lit")||(tCellType="exp")||(tCellType="cell")) {
			Set tParentNodeNo = $LG(tCNode,4)
			While (tParentNodeNo'="") {
				Set tParentNode = $G($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",tParentNodeNo))
				Set tParentType = $LG(tParentNode,1)
				If ((tParentType="axis")||(tParentType="set")) {
					Quit
				}
				Do ..%ComputeCellWeight(pCubeIndex,pAxisKey,tParentNodeNo,.pWeight,.pSolveOrder,-1,.pVisited)
				Set tParentNodeNo = $LG(tParentNode,4)
			}
		}
	}
}

/// If the given query has pending results, update them.
ClassMethod %UpdatePendingResults(pCube As %String, pKey As %String, Output pPending As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Try {
		// JMD1390 Let KPI know we are checking on pending results
		// and we do not want to test the data timestamp!
		New %dsKPIPending
		Set %dsKPIPending = 1

		// JMD900
		Set pPending = 0
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tCubeName = $$$UPPER(pCube)
		Set tChanges = 0 

		If $D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"pending")) {
			Set pPending = 1
			Set tPendingAddr = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"pending",""),1,tInfo)
			While (tPendingAddr'="") {
				// $LB(tKPIClass,tKPI,tProp,tSeries,tCellContext,tCacheKey)
				Set tKPIClass = $LG(tInfo,1)
				Set tKPI = $LG(tInfo,2)
				Set tProp = $LG(tInfo,3)
				Set tSeries = $LG(tInfo,4)
				Set tCellContext = $LG(tInfo,5)
				Set tCacheKey = $LG(tInfo,6)
				Set tFilterList = $LG(tInfo,7)
				Kill tFilters
				For fn=1:2:$LL(tFilterList) {
					Set tFilters($LG(tFilterList,fn)) = $LG(tFilterList,fn+1)
				}
				Set tPctComplete = 100
				// + WAL203 -- pass query key (parent query key for the KPI)
				Set tSC = $Classmethod(tKPIClass,"%GetKPIValue",tKPI,.tResult,tProp,tSeries,.tFilters,tCellContext,.tCacheKey,.tPctComplete,pKey)
				// - WAL203
				If $$$ISERR(tSC) {
					// return error as value of cell
					Set pResult = $System.Status.GetErrorText(tSC)
					Set tSC = $$$OK
					Quit
				}

				If (tPctComplete>=100) {
					// remove pending node
					Set tChanges = tChanges + 1
					Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"pending",tPendingAddr)
				}
				
				// construct cell addr
				Kill tAddr
				Set tAxisCount = $L(tPendingAddr,",")
				For k=1:1:tAxisCount {
					Set tAddr(k) = $P(tPendingAddr,",",k)
				}
				
				// DTB - Resolve Agg addresses
				Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,tAxisCount)
				If $$$ISERR(tSC) Quit
				
				Do SETRESULT(tAxisCount,0,tResult)
				
				// + WAL110 -- remove empty cells from "nonempty" nodes. These are used to construct the leaf index
				For a=1:1:tAxisCount {
					// if either rows of columns are non empty take note
					Set tAxisNonEmpty = 0
					If (a<=2) {
						Set tAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex, pKey, "axis", a))
						// second to last argument is 1 because axis root is always 1
						Set tAxisNonEmpty = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",1),5)
					}
					// 29 means one of two things:
					//        1) The pending result has a value, determined here
					//        2) This node is nonempty regardless of whether the pending node is empty or not
					//		     Determined in ..%ComputeExpressions
					// Either way, don't delete the node
					If ($G(tResult)'="") {
						Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)) = 29
					}
					ElseIf (($G(tResult)="")&&($G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a)))'=29)) {
						// Make sure this query is non empty before removing the marker
						If (tAxisNonEmpty) {
							Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tAddr(a))
						}
					}
				}
				// - WAL110

				// next node
				Set tPendingAddr = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"pending",tPendingAddr),1,tInfo)
			}
		}

		// did all the nodes get resolved?
		Set tRecompute = 0
		If ('$D($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"pending"))) {
			Set pPending = 0
			Set tRecompute = 1

			// + WAL110 -- rebuild the leaf index if some cells turned out to be empty
			//             and this is a nonempty query
			Set tSC = ..%BuildLeafIndex(tCubeIndex,pKey)
			If $$$ISERR(tSC) Quit
			// - WAL110
		}
		ElseIf (tChanges>0) {
			// JMD1494: recompute totals
			Set tRecompute = 1
		}

		// JMD1496
		If (tRecompute) {
			Kill tCalcCells
			Merge tCalcCells = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"calcCells")
			If $D(tCalcCells) {
				Kill tPendingCells
				Set tSC = ..%ComputeExpressions(pCube,pKey,0,.tCalcCells,.tPendingCells)
				If $$$ISERR(tSC) Quit
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"calcCells")
				Merge $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"calcCells") = tPendingCells
			}

			Set tMaxValue = ""
			Set tMinValue = ""
			Set tSC = ..%ComputeTotals(pCube,pKey,.tMaxValue,.tMinValue)
			If $$$ISERR(tSC) Quit

			// update stats
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"stats","min") = $G(tMinValue)
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"stats","max") = $G(tMaxValue)
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Kill %dsKPIPending
	Quit tSC

	// set value into final result (copy)
SETRESULT(tResultAxisCount,tSlot,tValue)
	Set tSC = ..%ResolveAggregateAddress(tCubeIndex,pKey,.tAddr,tResultAxisCount)
	Goto $Case(tResultAxisCount,0:DIM0,1:DIM1,2:DIM2,3:DIM3,:DIMERR)
DIM0
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot) = tValue
	Quit
DIM1
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1)) = tValue
	Quit
DIM2
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1),tAddr(2)) = tValue
	Quit
DIM3
	Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",tSlot,tAddr(1),tAddr(2),tAddr(3)) = tValue
	Quit
DIMERR
	Set tSC = $$$ERROR($$$GeneralError,"Too many dimensions in query: " _ (tResultAxisCount))
	Quit
}

/// Find the tuple expression for the given cell in the given query.
/// Prepend the axis # onto each tuple (#:).
ClassMethod %ComputeTupleForCell(pCube As %String, pKey As %String, ByRef pAddr, Output pTuple) As %Status [ Internal ]
{
	Kill pTuple
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Set tCubeName = $$$UPPER(pCube)

	Set a = 0
	Set k = $O(pAddr(""))
	While (k'="") {
		Set a = a + 1
		Set tNodeNo = pAddr(k)

		// !!! - refactor ResultSet to call this code
		Set tSpec = ..%GetSpecForAxisNode(pCube,pKey,a,tNodeNo)
		Set:tSpec'="" pTuple(a) = a_":"_tSpec

		// next axis
		Set k = $O(pAddr(k))
	}
	Quit $$$OK
}

/// Return the spec (tuple) for a given axis node in a query.
/// For example, this would return the MDX tuple for the rows clause of a given pivot cell.
ClassMethod %GetSpecForAxisNode(pCube As %String, pKey As %String, pAxisNo As %Integer, pNodeNo As %Integer, ByRef pPluginInfo As %String) As %String [ Internal ]
{
	Set tItems = 0
	Set tAxisSpec = ""
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Set tCubeName = $$$UPPER(pCube)
	Set tAxisKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"axis",pAxisNo))
	Set tNodeNo = pNodeNo
	
	// + WAL170
	Set tPlugInList = ""
	Set tSC = ##class(%DeepSee.Utils).%GetKPIPlugInList(.tPlugInList)
	If $$$ISERR(tSC) Quit
	// - WAL170
	
	Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",pNodeNo))
	Set tDone = 0
	While ('tDone) {
		Set tDone = 1
		Set tNodeType = $LG(tNodeInfo,1)
		Set tAggType = $LG(tNodeInfo,6)

		If ((tNodeType="agg")&&(tAggType'="%KPI")&&(tAggType'="%MDX")) {
			// visit children of this node
			Set tLoopChildren = 1
			Set tChildNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo,"ch",""))

			// n.b. for COUNT:EXCLUDEEMPTY we should add special processing here to find
			// only the members that are contributing
		}
		ElseIf ((tNodeType="exp")||((tNodeType="agg")&&((tAggType="%KPI")||(tAggType="%MDX")))) {
			// + WAL170 -- figure out if THIS kpi is a plugin
			If ((tAggType="%KPI")) {
				Set tKPIName = $$$UPPER($LG(tNodeInfo,8))
				Set tKPIProp = $LG(tNodeInfo,5)
				If ($G(tPlugInList(tKPIName))'="") { // WAL223
					// DTB564 - Look up the actual property name within the 
					Set tFirstChildNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo,"ch",""))
					Set tKPIProp = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tFirstChildNodeNo),6)
					
					Set pPluginInfo("NAME") = tKPIName
					Set pPluginInfo("PROP") = tKPIProp
				}
			}
			// - WAL170
			
			// + WAL262 -- get PlugIn arguments (i.e., "%cube","PATIENTS") from axis
			Set tIndex = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo,"ch",""))
			Set tStartIndex=tIndex
			Set tLastArg = ""
			While tIndex'="" {
				// This means we're looking at user defined arguments
				If ((tIndex-tStartIndex)>=2) {
					Set tArgumentInfo = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tIndex)		// DTB775 - Common reference for readability
					If ($LG(tArgumentInfo,24)'=tNodeNo) Quit		// DTB775 - Make sure this is still an argument of the original plugin argument
					
					If ($LG(tArgumentInfo,5)="") {
						If ($LG(tArgumentInfo,6)'="")&&($LG(tArgumentInfo,6)'="%CONTEXT"){
							Set tArgs($LG(tArgumentInfo,6))=""
							Set tLastArg = $LG(tArgumentInfo,6)
						}
					}
					ElseIf ($LG(tArgumentInfo,5)="Constant") {
						If tLastArg'="" {
							Set tArgs(tLastArg) = $LG(tArgumentInfo,6)
						}
					}
				}
				Set tIndex = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tIndex,"ch",""))
			}
			Merge pPluginInfo("ARGUMENTS") = tArgs
			// - WAL262
			
			// JMD913
			// move up to parent of this node
			Set tNodeNo = $LG(tNodeInfo,4)
			Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo))
			Set tDone = 0
		}
		//ElseIf (tNodeType="slicer") {
			// DTB247 - If a slicer is queried, start at the top and loop through children
			//Set tLoopChildren=1	
			//Set tChildNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",pNodeNo,"ch",""))
		//}
		Else {
			Set tLoopChildren = 0
		}
	}

	While((tLoopChildren=0)||(tChildNodeNo'="")) {
		If (tLoopChildren) {
			Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tChildNodeNo))
			Set tNodeType = $LG(tNodeInfo,1)
		}

		Set tId = $LG(tNodeInfo,6)
		Set tParent = $LG(tNodeInfo,4)
		Set tKey = $LG(tNodeInfo,13)
		Set tDimNo = $LG(tNodeInfo,9)
		Set tHierNo = $LG(tNodeInfo,10)
		Set tLevelNo = $LG(tNodeInfo,11)

		If ((tDimNo '= "")&&(tHierNo '= "")&&(tLevelNo '= "")) {		// DTB563
			Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
			Set tMbrType = $LG(tMbrInfo,1)
			Set tSpec = ""
			If (tMbrType="r") {
				Set tNullRef = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"relations",$$$UPPER($LG(tMbrInfo,2)),"nullReplacement"))
				If ((tNullRef'="")&&(tId=-1E14)) {
					// no relation
					Set tSpec = "["_$LG(tMbrInfo,2)_"]"_".["_tNullRef_"]"
				}
				Else {
					// JMD1316: get relationship spec from relationship member

					// tack on remote spec
					Set tRemoteSpec = $LG(tNodeInfo,14)
					// JMD1361: test for %OR in relationship
					If ($E(tRemoteSpec,1,4)="%OR(") {
						// strip off %OR, decorate each item, and reapply %OR
						// assume no commas in spec!
						Set t = $E(tRemoteSpec,5,*-1)
						If $E(t)="{" {
							// DTB563 - Account for optional explicit set '{}' within the %OR
							Set t = $E(t,2,*-1)
						}
						
						Set ts = ""
						For tp = 1:1:$L(t,",") {
							Set ts = ts _ $S(ts="":"",1:",") _ "["_ $$$dsEscapeIdent($LG(tMbrInfo,2)) _ "]" _ "."_$P(t,",",tp)
						}
						Set tSpec = "%OR({"_ts_"})"
					}
					Else {
						If (tRemoteSpec'="") {
							Set tSpec = "["_$$$dsEscapeIdent($LG(tMbrInfo,2))_"]"_"."_tRemoteSpec
						}
						// special case for drilldown
						If ($$$UPPER($P(tSpec,".",$L(tSpec,".")))="CHILDREN") {
							Set tSpec = $P(tSpec,".",1,$L(tSpec,".")-1)
							Set:tKey'="" tSpec = tSpec _ ".&[" _ $$$dsEscapeIdent(tKey) _ "]"
						}
					}
				}
			} // "r"
			ElseIf (tNodeType="msr") {
				Set pMeasure = $LG(tMbrInfo,3)
			}
			ElseIf ($G(tId)'="") {		// DTB563 - Push into specific condition
				// JMD909 - fix for drill on Properties()
				If (($LG(tMbrInfo,2)'="")&&($LG(tMbrInfo,3)'="")&&($LG(tMbrInfo,4)'="")&&(tKey'="")) {
					If (tId["|") {
						// get dim #s
						Set tLevelNode = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbrs",$$$UPPER($LG(tMbrInfo,2)),$$$UPPER($LG(tMbrInfo,3)),$$$UPPER($LG(tMbrInfo,4))))
						Set tMbrClass = $LG(tMbrInfo,6)
						Set tIsTime = $classmethod(tMbrClass,"%IsA","%DeepSee.Time.AbstractLevel")
						// JMD1361: %OR in play: recreate set from ids
						// note: currently this will not work for %OR(computedDim)
						For p = 1:1:$L(tId,"|") {
							Set tId2 = $P(tId,"|",p)
							Set tMbrSpec = ""
							If (tIsTime) {
								// n.b. not needed; just avoids method call
								Set tMbrSpec = "&["_$$$dsEscapeIdent(tId2)_"]"
							}
							Else {
								// convert ID to KEY
								Set tMbrSpec = $classmethod(tMbrClass,"%GetMemberSpec",tId2,tCubeIndex,$LG(tLevelNode,1),$LG(tLevelNode,2),$LG(tLevelNode,3))
							}
							
							If (tMbrSpec'="")&&(tMbrSpec'="&[]") {
								// DTB622 - Only add real executable members to this set
								Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ "["_$LG(tMbrInfo,2)_"].["_$LG(tMbrInfo,3)_"].["_$LG(tMbrInfo,4)_"]."_tMbrSpec
							}
						}
						Set:tSpec'="" tSpec = "%OR({"_tSpec_"})"
					}
					// + WAL148 -- Handle not case
					ElseIf (tId["!") {
						Set tSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec($LB($LG(tMbrInfo,2),$LG(tMbrInfo,3),$LG(tMbrInfo,4),tKey),.tSC,1) _ ".%NOT"		// DTB955 - USe API
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}
					// - WAL148
					Else {
						// no OR
						If ($LG(tMbrInfo,5)=1) {
							// DTB955 - This is the %SEARCH dimension, which does *not* use an escaped key
							Set tSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec($LB($LG(tMbrInfo,2)),.tSC) _ ".&["_tKey_"]"
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						}
						Else {
							// DTB955 - The level is defined in the cube definition, build the complete spec to reference it
							Set tSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec($LB($LG(tMbrInfo,2),$LG(tMbrInfo,3),$LG(tMbrInfo,4),tKey),.tSC,1)
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						}
					}
				}
			} // else

			// If any parent nodes are members, construct a tuple
			// check for relations in parents as well
			Set tIsTuple = 0
			Set tORSetNo = 0
			Kill tORSetChildren			//tORSetChildren is used to group everything under an 'orset'
			Kill tTupleChildren			//tTupleChildren is used to group everything under an 'tuple'
			Set tORSetChildNo = 0		//counter for tORSetChildren
			Set tTupleChildNo = 0		//counter for tTupleChildren
			Set tNumTimesTupleJoins=0	//number of times a tuple node joins 2 other inner nodes (else condition in the tuple condition)
			Kill tORSetExpression
			Kill tTupleExpression

			// Go from current node all the way up the axis chain in an attempt to find the value of the outermost operator
			Set tPrevNode = pNodeNo
			While(tPrevNode'=""){
				Set tCurrNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tPrevNode))
				Set tCurrNodeType = $LG(tCurrNode,1)
				If (tCurrNodeType'="axis") && (tCurrNodeType'="slicer") && (tCurrNodeType'="set"){ //This condition should never be reached in the first iteration
					Set tOutermostOperator = tCurrNodeType //tOutermostOperator will be used after the axis chain is parsed
				}
				Else{
					Quit
				}
				Set tPrevNode = $LG($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tPrevNode),4)
			}

			While (tParent'="") {
				Set tPNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tParent))
				Set tPNodeType = $LG(tPNodeInfo,1)
				
				If (tPNodeType="orset") {
					// JMD1453 add to list of or sets
					Set tCombinedTerms = ..CombineSetAndTerms(.tORSetChildren, $G(tSpec),, .tSC) //tSpec contains a concatenation of mbrs and msrs, while tORSetChildren contains ortuples. tCombinedTerms contains both of them
					Set tORSetExpression = "%OR({" _ tCombinedTerms _ "})" 					
					If (tOutermostOperator="mbr") || (tOutermostOperator="msr") || (tOutermostOperator="tuple"){
						Set tTupleChildNo=tTupleChildNo+1
						Set tTupleChildren(tTupleChildNo) = tORSetExpression
						Kill tORSetExpression
					}
					Set tSpec = ""
					Set tIsTuple = 0
					Kill tORSetChildren
					Set tORSetChildNo=0
				}
				ElseIf (tPNodeType="ortuple"){
					// DP-409762:
					// Since an ortuple will always be inside an orset node, an ortuple will always be ORed with other top-level 
					// members of an orset. These top-level members can be stored inside a temporary array (tORSetChildren) 
					// until the orset is reached, at which point all the elements in the tORSetChildren array will be combined.
					
					Set tORSetChildNo = tORSetChildNo + 1
					Set:tIsTuple tSpec = "(" _ tSpec _ ")"
					Set tORSetChildren(tORSetChildNo) = tSpec
					Set tSpec = ""
					Set tIsTuple = 0
				}
				ElseIf (tPNodeType="tuple") {
					// JMD1453 add tuple to or set list
					Set tTupleChildNo = tTupleChildNo + 1
					If tSpec'=""{ 
						Set:tIsTuple tSpec = "(" _ tSpec _ ")"
						Set tTupleChildren(tTupleChildNo) = tSpec
					}
					Else{
						Set tCombinedTupleTerms = ..CombineSetAndTerms(.tTupleChildren,,, .tSC)
						Kill tTupleChildren
						Set tTupleChildNo=1
						Set tTupleChildren(tTupleChildNo)=tCombinedTupleTerms
					}
					Set tSpec = ""
					Set tIsTuple = 0
				}
				ElseIf ((tPNodeType="mbr")||(tPNodeType="msr")) {
					Set tPType = $LG(tPNodeInfo,1)
					Set tPId = $LG(tPNodeInfo,6)
					Set tPKey = $LG(tPNodeInfo,13)
					Set tPDimNo = $LG(tPNodeInfo,9)
					Set tPHierNo = $LG(tPNodeInfo,10)
					Set tPLevelNo = $LG(tPNodeInfo,11)
					
					If ((tPDimNo '= "")&&(tPHierNo '= "")&&(tPLevelNo '= "")) {		// DTB547 - Simplify this IF condition, push other conditions to the inner IF statement
						Set:tSpec'="" tIsTuple = 1
						Set tPMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tPDimNo,tPHierNo,tPLevelNo))
						Set tPMbrType = $LG(tPMbrInfo,1)
						Set tPSpec = ""
						If ($G(tPMbrType)="r") {
							// tack on remote spec
							Set tRemoteSpec = $LG(tPNodeInfo,14)
							// JMD976
							If (tPId=-1E14) {
								// no relation
								Set tPSpec = "["_$LG(tPMbrInfo,2)_"]"_".&[<null>]"
							}
							ElseIf (tRemoteSpec'="") {
								// JMD1361: test for %OR in relationship
								If ($E(tRemoteSpec,1,4)="%OR(") {
									// strip off %OR, decorate each item, and reapply %OR
									// assume no commas in spec!
									Set t = $E(tRemoteSpec,5,*-1)
									If $E(t)="{" {
										// DTB582 - Account for optional explicit set '{}' within the %OR
										Set t = $E(t,2,*-1)
									}
									Set ts = ""
									For tp = 1:1:$L(t,",") {
										Set ts = ts _ $S(ts="":"",1:",") _ "["_ $$$dsEscapeIdent($LG(tPMbrInfo,2)) _ "]" _ "."_$P(t,",",tp)
									}
									Set tPSpec = "%OR({"_ts_"})"
								}
								Else {
									Set tPSpec = "["_$LG(tPMbrInfo,2)_"]"_"."_tRemoteSpec
								}
							}
						}
						ElseIf ($G(tPType)="msr") {
							Set pMeasure = $LG(tPMbrInfo,3)
						}
						ElseIf ($G(tPId)'="") {		// DTB547 - Push this condition into the inner IF statement
							// + WAL128 --  If we are dealing with an %OR of members,
							//              reassemble this into a %OR statement by putting the ID ($LG(axisNode,6))
							//              back together.
							//              This ensures that we get all the cell context for the listing
							Set tCurrPBaseSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec($LB($LG(tPMbrInfo,2),$LG(tPMbrInfo,3),$LG(tPMbrInfo,4)))		// DTB248
							If (tPId [ "|") {
								If (tPKey'="") {
									Set tOrTermCount = 0
									For i=1:1:$L(tPId,"|") {
										Set tCurrPId = $P(tPId,"|",i)
										Set tSC = ##class(%DeepSee.Utils).%GetMemberKeyForID(tCubeIndex,tPDimNo,tPHierNo,tPLevelNo,tCurrPId,.tCurrPKey)
										If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DP-414765

										If (tCurrPKey'="") {
											// DTB622 - Only add real executable members to this set
											Set x = $I(tOrTermCount)
											Set tCurrPSpec = tCurrPBaseSpec _ ".&["_$$$dsEscapeIdent(tCurrPKey)_"]"		// DTB248
											If (tPSpec'="") {
												Set tPSpec = tPSpec _ ","	
											}
											Set tPSpec = tPSpec _ tCurrPSpec
										}
									}
									
									If (tOrTermCount>1) {
										Set tPSpec = "%OR({" _ tPSpec _ "})"
									}	
								}
							}
							// + WAL148 -- handle %NOT case here, add ".%NOT" to tPSpec
							ElseIf (tPId["!") {
								Set tPSpec = tCurrPBaseSpec _ ".&["_$$$dsEscapeIdent(tPKey)_"].%NOT"		// DTB248
							}
							// - WAL148
							ElseIf (tPKey'="") {
								Set tPSpec = tCurrPBaseSpec _ ".&["_$$$dsEscapeIdent(tPKey)_"]"		// DTB28
							}
							// - WAL128
						}
						// JMD1387
						If (tSpec="") {
							Set tSpec = tPSpec
						}
						ElseIf (tPSpec'="") {
							Set tSpec = tPSpec_","_tSpec
							Set tIsTuple = 1
						}
					} // mbr|msr
				}
				
				Set tParent = $LG(tPNodeInfo,4)
			}
			If (tOutermostOperator="mbr") || (tOutermostOperator="msr") || (tOutermostOperator="agg") {
				Set tTupleExpression = ..CombineSetAndTerms(.tTupleChildren, tSpec, .tNumTerms, .tSC)
				Set:tTupleExpression'="" tTupleExpression = "("_tTupleExpression_")"
				Set tSpec = tTupleExpression
			}
			ElseIf tOutermostOperator="tuple"{
				Set tTupleExpression = ..CombineSetAndTerms(.tTupleChildren, tSpec,, .tSC)
				Set:( (tTupleExpression'="") && (tNumTimesTupleJoins'=1)) tTupleExpression = "("_tTupleExpression_")"
				Set tSpec = tTupleExpression
			}
			ElseIf tOutermostOperator="orset" {
				If $D(tTupleChildren){ //this handles the case where the actual outermost operator is an implicit tuple but the operator listed in the axis cache is an orset
					Set tSpec = "("_..CombineSetAndTerms(.tTupleChildren, $G(tORSetExpression),, .tSC)_")"
				}
				Else{
					Set tSpec = $G(tORSetExpression)
				}
			}

			Set tAxisSpec = tAxisSpec _ $S(tAxisSpec="":"",1:",") _ tSpec
			Set tItems = tItems + 1
		}
		If (tLoopChildren) {
			Set tChildNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo,"ch",tChildNodeNo))
		}
		Else {
			Quit
		}
	} // while()
	
	If (tItems > 1) {
		Set:tAxisSpec'="" tAxisSpec = "{" _ tAxisSpec _ "}"
	}
	
	Quit tAxisSpec
}

/// Extract elements from <var>pSet</var> and concatenate them. Concatenate this result with pTerms
ClassMethod CombineSetAndTerms(ByRef pSet, pTerms, Output pNumTerms, Output pSC) As %String [ Internal ]
{
	Set pSC=$$$OK
	Set tCombinedTerms=""
	Set tNumTerms=0
	Try{
		
		Set tCounter = $O(pSet(""))
		While (tCounter'="") {
			If tCombinedTerms'=""{
				Set tCombinedTerms = pSet(tCounter)_","_tCombinedTerms
			}
			Else{
				Set tCombinedTerms = pSet(tCounter)
			}
			Set tCounter = $O(pSet(tCounter))
			Set tNumTerms=tNumTerms+1
		}
		
		If (pTerms'="") && (tCombinedTerms=""){
			Set tCombinedTerms = pTerms
		}
		ElseIf (pTerms'="") && (tCombinedTerms'=""){
			Set tCombinedTerms = pTerms_","_tCombinedTerms
		}
		Set pNumTerms = tNumTerms+$S(pTerms'="":$L(pTerms, ","), 1:0)
	}
	Catch(ex){
		Set pSC = ex.AsStatus()
	}
	return tCombinedTerms
}

/// Get set of (leaf) descendant nodes for a given member node
ClassMethod %GetDescendantNodes(ByRef pNodeList, pCubeIndex As %String, pAxisKey As %Integer, pNodeNo As %Integer) [ Internal ]
{
	Set tNodeType = $LG($G($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pNodeNo)),1)
	If ((tNodeType="exp")) {
		// do not descend
		Set pNodeList(pNodeNo) = ""
		Quit
	}
	// JMD1390 (%KPI(...,%MDX()))
	If ((tNodeType="agg")) {
		// do not descend
		Set pNodeList(pNodeNo) = ""
		Quit
	}

	Set tChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pNodeNo,"ch",""))
	If (tChild="") {
		// add to list
		Set pNodeList(pNodeNo) = ""
	}
	Else {
		While (tChild'="") {
			Do ..%GetDescendantNodes(.pNodeList,pCubeIndex,pAxisKey,tChild)
			Set tChild = $O($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pNodeNo,"ch",tChild))
		}
	}
}

/// Given a node number, find the node <var>pOffset</var> nodes away.
/// This is used by spreadsheet functions to resolve addresses.
ClassMethod %FindRelativeNode(pCubeIndex As %String, pAxisKey As %Integer, pAxisRoot As %Integer, pNodeNo As %Integer, pOffset As %Integer, pCheckNonempty = 0, pQueryKey As %String = "", pAxisNo As %Integer = "") As %Integer [ Internal ]
{
	Set tNodeNo = $$LEAFNODE(pNodeNo)
	Set tDir = $S(pOffset>0:1,1:-1)
	
	// DTB770 - If pCheckNonempty is in play, it will require more information. Make sure we have it.
	If (pCheckNonempty)&&((pQueryKey="")||(pAxisNo="")) {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Cannot check non-empty relative nodes without a query key and axis number."))
	}

	While ((tNodeNo'="")&&(pOffset'=0)) {
		// find next node
		Set tNodeNo = $O($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pAxisRoot,"all",tNodeNo),tDir)
		If (tNodeNo'="") {
			// see if this node is visible
			Set tInfo = $G($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",tNodeNo))
			Set tVisible = +$LG(tInfo,2)
			
			// DTB770 - Check the result cache's "nonempty" node for this member node. Offsets only count
			// the relative nonempty nodes if pCheckNonempty=1
			Set tCount = 1
			If (pCheckNonempty) {
				Set tCount = +$G($$$DeepSeeResultsGLVN(pCubeIndex,pQueryKey,"nonempty",pAxisNo,tNodeNo))
			}
			
			// DTB772 - A %CELL function might not have its nonempty node set yet. Assume these are going to return a
			// nonempty result and count these too. 
			// DTB774 - Count *all* calculation functions as likely information that needs to be considered!
			Set tCellType = $LG(tInfo,1)
			If (tCellType="cell")||(tCellType="exp")||(tCellType="agg") || (tCellType="lit") {//APV031 - adding "lit" to this list
				Set tCount = 1
			}

			If (tVisible && tCount) {
				Set pOffset = pOffset - tDir
			}
		}
	}
	Quit tNodeNo
	Set k = ""

LEAFNODE(k)
	// find first visible leaf node above k (or k itself)
	// this is the node that %CELL computes its offset from
	Set tTop = k
	While (1) {
		Set tInfo = $G($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",tTop))
		If ($D($$$DeepSeeAxisGLVN(pCubeIndex,pAxisKey,"axes",pAxisRoot,"all",tTop))&&+$LG(tInfo,2)) {
			Quit
		}
		Set tParent = $LG(tInfo,4)
		If (tParent="") {
			Quit
		}
		Set tTop = tParent
	}
	Quit tTop
}

/// This is called at the start of processing for an aggregate function.<br/>
/// <var>pFunction</var> is the aggregate function.<br/>
/// <var>pFlags</var> is a set of flags for the aggregate function.<br/>
/// <var>pContext</var> is used to hold any context required to compute the
/// aggregate.<br/>
ClassMethod %AggregateStart(pFunction As %String, ByRef pFlags, ByRef pContext) As %Status
{
	Set tSC = $$$OK
	Try {
		// If pContext("COUNT") is defined, then it is
		// assumed to be an instance of an aggregate class that will perform
		// the actual work.

		If (pFunction="COUNT") {
			Set pContext("COUNT") = ""
		}
		ElseIf (pFunction="%POSTCOUNT") {
			Set pContext("%POSTCOUNT") = ""
		}
		ElseIf (pFunction="SUM") {
			Set pContext("SUM") = ""
		}
		ElseIf (pFunction="%DISTINCT") {
			Set pContext("%DISTINCT") = ""
		}
		ElseIf (pFunction="%MDX") {
			// execute MDX function
			// first get parameter values from child nodes (by accumulating them)
			Set pContext("%MDX","parms") = 0
			Set pContext("%MDX","query") = $G(pFlags("query"))
		}
		ElseIf (pFunction="%KPI") {
			Set pContext("%KPI","parms") = 0
			Set pContext("%KPI","kpi") = $G(pFlags("kpi"))
		}
		ElseIf (pFunction="%LIST") {
			Set pContext("%LIST") = ""
		}
		ElseIf (pFunction="%FIRST") {
			Set pContext("%FIRST") = ""
		}
		ElseIf (pFunction="%LAST") {
			Set pContext("%LAST") = ""
		}
		ElseIf (pFunction="AVG") {
			Set pContext("SUM") = ""
			Set pContext("COUNT") = ""
		}
		ElseIf (pFunction="MIN") {
			Set pContext("MIN") = ""
		}
		ElseIf (pFunction="MAX") {
			Set pContext("MAX") = ""
		}
		ElseIf ((pFunction="STDEV")||(pFunction="STDDEV")) {
			Set pContext("OBJ") = ##class(%DeepSee.Aggregate.StDev).%New()		// DP-415385
		}
		ElseIf ((pFunction="STDEVP")||(pFunction="STDDEVP")) {
			Set pContext("OBJ") = ##class(%DeepSee.Aggregate.StDevP).%New()		// DP-415385
		}
		ElseIf ((pFunction="VAR")||(pFunction="VARIANCE")) {
			Set pContext("OBJ") = ##class(%DeepSee.Aggregate.Var).%New()		// DP-415385
		}
		ElseIf ((pFunction="VARP")||(pFunction="VARIANCEP")) {
			Set pContext("OBJ") = ##class(%DeepSee.Aggregate.VarP).%New()		// DP-415385
		}
		ElseIf (pFunction="MEDIAN") {
			Set pContext("OBJ") = ##class(%DeepSee.Aggregate.Median).%New()		// DP-415385
		}
		ElseIf (pFunction="PERCENTILE") {
			Set pContext("OBJ") = ##class(%DeepSee.Aggregate.Percentile).%New()		// DP-415385
			Set pContext("OBJ").percentile = +$G(pFlags("PERCENTILE"))
		}
		ElseIf (pFunction="PERCENTILERANK") {
			Set pContext("OBJ") = ##class(%DeepSee.Aggregate.PercentileRank).%New()		// DP-415385
			Set pContext("OBJ").value = +$G(pFlags("VALUE"))
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Unsupported Aggregate Function: "_pFunction)
			Quit
		}
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		If (ex.Name = "<CLASS DOES NOT EXIST>") {
			// Aggregate class not present
			Set tSC = $$$ERROR($$$GeneralError,"Aggregate Function Class Not Found: "_pFunction)
		}
	}
	Quit tSC
}

/// This is called during processing for an aggregate function.
/// It is called for each value in the set being aggregated.
ClassMethod %AggregateAccum(pFunction As %String, ByRef pFlags, ByRef pContext, pValue) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pValue = $ZSTRIP(pValue,"<>W")

		// JMD1496 test for pending result
		If ($P(pValue," ",1)="@Computing") {
			Set pContext("@Computing") = pValue
		}

		If (pFunction="COUNT") {
			Set:((pValue'="")||('$D(pFlags("EXCLUDEEMPTY")))) pContext("COUNT") = pContext("COUNT") + 1
		}
		ElseIf (pFunction="%POSTCOUNT") {
			Set:((pValue'="")||('$D(pFlags("EXCLUDEEMPTY")))) pContext("%POSTCOUNT") = pContext("%POSTCOUNT") + 1
		}
		ElseIf (pFunction="SUM") {
			If (pContext("SUM")="") {
				// If SUM of one, non-number, preserve it!
				Set pContext("SUM") = pValue
			}
			Else {
				Set:pValue'="" pContext("SUM") = pContext("SUM") + pValue
			}
		}
		ElseIf (pFunction="%DISTINCT") {
			Set pContext("%DISTINCT") = pContext("%DISTINCT") + pValue
		}
		ElseIf (pFunction="%LIST") {
			Set pContext("%LIST") = pContext("%LIST") _ $S(pContext("%LIST")'="":",",1:"") _ pValue
		}
		ElseIf (pFunction="%MDX") {
			Set n = $I(pContext("%MDX","parms"))
			Set pContext("%MDX","parms",n) = pValue
		}
		ElseIf (pFunction="%KPI") {
			Set n = $I(pContext("%KPI","parms"))
			Set pContext("%KPI","parms",n) = pValue
		}
		ElseIf (pFunction="%FIRST") {
			If ((pContext("%FIRST")="")&&(pValue'="")) {
				Set pContext("%FIRST") = pValue
			}
		}
		ElseIf (pFunction="%LAST") {
			If (pValue'="") {
				Set pContext("%LAST") = pValue
			}
		}
		ElseIf (pFunction="AVG") {
			Set:pValue'="" pContext("COUNT") = pContext("COUNT") + 1
			Set:pValue'="" pContext("SUM") = pContext("SUM") + pValue
		}
		ElseIf (pFunction="MIN") {
			Set:pValue'="" pContext("MIN") = $S(pContext("MIN")="":pValue,pValue<pContext("MIN"):pValue,1:pContext("MIN"))
		}
		ElseIf (pFunction="MAX") {
			Set:pValue'="" pContext("MAX") = $S(pContext("MAX")="":pValue,pValue>pContext("MAX"):pValue,1:pContext("MAX"))
		}
		ElseIf ($IsObject($G(pContext("OBJ")))) {
			// dispatch
			Set tObj = pContext("OBJ")
			If (pValue'="") {
				Do tObj.ProcessValue(pValue)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This is called at the end of processing for an aggregate function.<br/>
/// If the aggregate is being computed in the background, then <var>pPendingInfo</var> will contain details.
ClassMethod %AggregateEnd(pFunction As %String, ByRef pFlags, ByRef pContext, Output pResult, Output pPendingInfo, pCubeName As %String = "", pQueryKey As %String = "") As %Status
{
	Set tSC = $$$OK
	Kill pPendingInfo
	Set pResult = ""
	// JMD1390
	New %dsKPISync
	 
	// DTB060: Some aggregates may require different behavior due to context supplied by other axes. 
	// This flag denotes a result should be shown even if the cell contains the null set 
	Set tShowResult = $G(pContext("ShowResult"),1) 		

	Try {
		// JMD1492
		If ($G(pContext("@Computing"))'="") {
			Set pResult = pContext("@Computing")
			Quit
		}
		
		If (pFunction="COUNT") {
			Set tResult = pContext("COUNT")										// DTB060
			Set pResult = $S((tShowResult||(tResult'="")):+tResult,1:"")
		}
		ElseIf (pFunction="%POSTCOUNT") {
			Set tResult = pContext("%POSTCOUNT")								// DTB060
			Set pResult = $S((tShowResult||(tResult'="")):+tResult,1:"")		
		}
		ElseIf (pFunction="SUM") {
			Set pResult = pContext("SUM")
		}
		ElseIf (pFunction="%DISTINCT") {
			Set tResult = pContext("%DISTINCT")									// DTB060
			Set pResult = $S((tShowResult||(tResult'="")):+tResult,1:"")
		}
		ElseIf (pFunction="%LIST") {
			Set pResult = pContext("%LIST")
		}
		ElseIf (pFunction="%MDX") {
			// assemble query parms
			Set tDirective = ""
			Set tDirectiveArg = ""
			Set tName = ""
			Kill tParms
			Set k = $O(pContext("%MDX","parms",""))
			While (k'="") {
				If ((k#2)=1) {
					// parm name
					Set tName = $G(pContext("%MDX","parms",k))
					// JMD900: look for directives
					If (($$$UPPER(tName)="%CONTEXT")) {
						Set tDirective = $$$UPPER(tName)
						Set tName = ""
						// argument
						Set ka = $O(pContext("%MDX","parms",k))
						If (ka'="") {
							Set tDirectiveArg = $G(pContext("%MDX","parms",ka))
						}
					}
				}
				Else {
					// parm value
					If (tName'="") {
						// treat empty value as missing
						Set tVal = $G(pContext("%MDX","parms",k))
						Set:tVal'="" tParms(tName) = tVal
						Set tName = ""
					}
				}
				Set k = $O(pContext("%MDX","parms",k))
			}

			// execute query
			Set tMDX = $G(pContext("%MDX","query"))
			If (tMDX="") {
				Set pResult = "NO QUERY"
			}
			Else {
				// JMD900: Tack on cell context as %FILTER clauses
				Set tFilterClause = ""
				If (tDirective="%CONTEXT") {
					Set tCellContext = $G(pContext("%MDX","context"))
					If (tCellContext'="") {
						// split directive flags
						Kill tDFlags
						For x=1:1:$L(tDirectiveArg,"|") {
							Set xa = $$$UPPER($P(tDirectiveArg,"|",x))
							If (xa="ROWS") {
								Set tDFlags(2) = 1
							}
							ElseIf (xa="COLUMNS") {
								Set tDFlags(1) = 1
							}
							ElseIf (xa="FILTERS") {
								Set tDFlags("F") = 1
							}
							ElseIf (xa="ALL") {
								Set tDFlags(1) = 1
								Set tDFlags(2) = 1
								Set tDFlags("F") = 1
							}
							ElseIf (xa'="") {
								// JMD1046: prevent bogus context from acting like "all"
								Set:'$D(tDFlags) tDFlags(1) = 0
							}
						}

						// split context by ";", unescape
						Set tContext = $Replace(tCellContext,";;",$C(0))
						For p=1:1:$L(tContext,";") {
							Set tSpec = ""
							Set xs = $Replace($P(tContext,";",p),$C(0),";")
							Set tPreFix = $P(xs,":",1)
							If '$D(tDFlags) {
								Set tSpec = $P(xs,":",2,999)
							}
							ElseIf (+$G(tDFlags(tPreFix))) {
								Set tSpec = $P(xs,":",2,999)
							}
							Set:tSpec'="" tFilterClause = tFilterClause _ " %FILTER "_tSpec
						}
					}
					Set tMDX = tMDX_tFilterClause
				}

				Set tRS = ##class(%DeepSee.ResultSet).%New()
				Set tSC = tRS.%PrepareMDX(tMDX)
				If $$$ISERR(tSC) {
					// return error as value of cell
					Set pResult = $System.Status.GetErrorText(tSC)
					Set tSC = $$$OK
					Quit
				}

				// DTB348 - Prevent hang due to reserved axes
				Set tRS.%Query.parentQueryKey = pQueryKey

				Set tSC = tRS.%Execute(.tParms)
				If $$$ISERR(tSC) {
					// return error as value of cell
					Set pResult = $System.Status.GetErrorText(tSC)
					Set tSC = $$$OK
					Quit
				}

				// get value of top,left cell
				Set tAxisCount = tRS.%GetAxisCount()
				Set pResult = $Case(tAxisCount,
					1:tRS.%GetOrdinalValue(1),
					:tRS.%GetOrdinalValue(1,1))
					
				// +DTB458 - Log the subquery keys in the results global if a related cube is involved
				Set tSubqueryCube = tRS.%CubeKey
				Set tSubqueryKey = tRS.%GetQueryKey()
				If ($G(pCubeName)'="") && (tSubqueryCube'=$$$UPPER(pCubeName)) && (pQueryKey'="") && (tSubqueryCube'="") && (tSubqueryKey'="") {
					Set $$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"subquery",tSubqueryCube,tSubqueryKey) = "(1)"
				}
				// -DTB458
			}
		}
		ElseIf (pFunction="%KPI") {
			// invoke KPI
			Set tKPI = $G(pContext("%KPI","kpi"))

			If (tKPI="") {
				Set pResult = "NO KPI"
			}
			Else {
				Set tResult = ""
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tKPI)

				// JMD900: assemble query parms
				Set tProp = $G(pContext("%KPI","parms",1))
				Set tSeries = $G(pContext("%KPI","parms",2),1)

				Set tDirective = ""
				Set tDirectiveArg = ""
				Set tName = ""
				Kill tParms
				Set k = $O(pContext("%KPI","parms",2))
				
				While (k'="") {
					If ((k#2)=1) {
						// parm name
						Set tName = $G(pContext("%KPI","parms",k))
						If (($$$UPPER(tName)="%CONTEXT")) {
							Set tDirective = $$$UPPER(tName)
							Set tName = ""
							// argument
							Set ka = $O(pContext("%KPI","parms",k))
							If (ka'="") {
								Set tDirectiveArg = $G(pContext("%KPI","parms",ka))
							}
						}
					}
					Else {
						// parm value
						If (tName'="") {
							// treat empty value as missing
							Set tVal = $G(pContext("%KPI","parms",k))
							Set:tVal'="" tParms(tName) = tVal
							Set tName = ""
						}
					}
					Set k = $O(pContext("%KPI","parms",k))
				}

				If '$D(tParms("%cube")) {
					// pass cube name to KPI as filter
					// JMD1124: quote logical cube name
					Set tParms("%cube") = "["_$$$UPPER(pCubeName)_"]"
				}

				Set tCellContext = ""
				If ($$$UPPER(tDirective) = "%CONTEXT") {
					Set tCContext = $G(pContext("%KPI","context"))
					If (tCContext'="") {
						// split directive flags
						Kill tDFlags
						For x=1:1:$L(tDirectiveArg,"|") {
							Set xa = $$$UPPER($P(tDirectiveArg,"|",x))
							If (xa="ROWS") {
								Set tDFlags(2) = 1
							}
							ElseIf (xa="COLUMNS") {
								Set tDFlags(1) = 1
							}
							ElseIf (xa="FILTERS") {
								Set tDFlags("F") = 1
							}
							ElseIf (xa="ALL") {
								Set tDFlags(1) = 1
								Set tDFlags(2) = 1
								Set tDFlags("F") = 1
							}
							ElseIf (xa'="") {
								// JMD1046: prevent bogus context from acting like "all"
								Set:'$D(tDFlags) tDFlags(1) = 0
							}
						}

						// split context by ";", remove prefixes and reassemble
						Set tContext = $Replace(tCContext,";;",$C(0))
						For p=1:1:$L(tContext,";") {
							Set tSpec = ""
							Set xs = $Replace($P(tContext,";",p),$C(0),";")
							Set tPreFix = $P(xs,":",1)
							If '$D(tDFlags) {
								// No flags defaults to "all"
								Set tSpec = $P(xs,":",2,999)
							}
							ElseIf (+$G(tDFlags(tPreFix))) {
								Set tSpec = $P(xs,":",2,999)
							}
							Set:tSpec'="" tCellContext = tCellContext _ $S(tCellContext="":"",1:";") _ $Replace(tSpec,";",";;")
						}
					}
				}

				Try {
					// JMD1390 test for force sync computation
					If (+$G(pContext("%KPI","sync"))) {
						Set %dsKPISync = 1
					}
					Set tPctComplete = 100
					// + WAL203 -- pass this query key (parent query key for the KPI)
					Set tSC = $Classmethod(tKPIClass,"%GetKPIValue",tKPI,.pResult,tProp,tSeries,.tParms,tCellContext,.tCacheKey,.tPctComplete,pQueryKey)
					// - WAL203
					Kill %dsKPISync
					If $$$ISERR(tSC) {
						// return error as value of cell
						Set pResult = $System.Status.GetErrorText(tSC)
						// JMD1494 log error
						Do ##class(%DeepSee.Utils).%WriteToLog("Query","Error in %KPI function: " _ pResult)
						Set tSC = $$$OK
						Quit
					}
					// JMD945: remember KPI timestamp
					If (pCubeName'="") {
						Set $$$DeepSeeResultsGLVN(pCubeName,pQueryKey,"kpi",tKPIClass) = $Classmethod(tKPIClass,"%GetKPIClassTimeStamp")
					}

					// JMD900
					If (tPctComplete<100) {
						// incomplete: return pending info
						// serialize filters
						Set tList = ""
						Set k = $O(tParms(""))
						While (k'="") {
							Set tList = tList _ $LB(k	) _ $LB(tParms(k))
							Set k = $O(tParms(k))
						}
						Set pPendingInfo = $LB(tKPIClass,tKPI,tProp,tSeries,tCellContext,tCacheKey,tList)
					}
				}
				Catch(ex) {
					// JMD1494 log error
					Set tSC = ex.AsStatus()
					Set tText = $System.Status.GetErrorText(tSC)
					Do ##class(%DeepSee.Utils).%WriteToLog("Query","Error in %KPI function: " _ tText)
					
					// return error as value of cell
					Set tSC = $$$OK
					Set pResult = "Invalid KPI"
				}
			}
		}
		ElseIf (pFunction="%FIRST") {
			Set pResult = pContext("%FIRST")
		}
		ElseIf (pFunction="%LAST") {
			Set pResult = pContext("%LAST")
		}
		ElseIf (pFunction="AVG") {
			Set tCount = pContext("COUNT")
			Set pResult = $S(tCount>0:(pContext("SUM")/tCount),1:"")
		}
		ElseIf (pFunction="MIN") {
			Set pResult = pContext("MIN")
		}
		ElseIf (pFunction="MAX") {
			Set pResult = pContext("MAX")
		}
		ElseIf ($IsObject($G(pContext("OBJ")))) {
			// dispatch
			Set tObj = pContext("OBJ")
			Set pResult = tObj.GetResult()
			Kill pContext("OBJ")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// For a completed query, construct an index of all visible leaf
/// nodes, in display order, for each axis.<br/>
/// This takes the form:<br/>
/// Results("leaf",axisNo,leafNo) = nodeNo
ClassMethod %BuildLeafIndex(pCube As %String, pKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Try {
		// Find axes, sans slicer
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tQueryType = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"queryType"))
		Set tIsBitSet = (tQueryType = "%BITSET")

		// JMD1401
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf")

		Set tSizeInfo = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"size"))
		Set tAxisCount = 0
		Set tCount = $LL(tSizeInfo)
		For a = 1:1:tCount {
			Set tInfo = $LG(tSizeInfo,a)
			If ($LG(tInfo,1)="axis") {
				Set tAxisCount = tAxisCount + 1
				Set tAxisKey(tAxisCount) = $LG(tInfo,2)
			}
		}

		// now build index for each axis
		For a = 1:1:tAxisCount {
			Set tCellNo = 0
			Set tNodeNo = 1
			Set tLevel = 1
			Set tAxisKey = tAxisKey(a)

			While (tNodeNo '= "") {
				// see if this node is visible and exists
				If (tIsBitSet || +$G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"nonempty",a,tNodeNo),0)) {
					Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo))
					If ($LG(tNodeInfo,2)) {
						Set tCellNo = tCellNo + 1
						Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",a,tCellNo) = tNodeNo
					}
				}

				// now find next node along this axis
				Set tFound = 0
				Do {
					// children first
					Set tNextNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo,"ch",""))
					If (tNextNode = tNodeNo) {
						// loop in axis: should never happen!
						Set tSC = $$$ERROR($$$GeneralError,"Internal error: cycle detected in query axis: "_tAxisKey)
						Quit
					}
					If (tNextNode '= "") {
						Set tFound = 1
						Set tLevel = tLevel + 1
						Quit
					}

					// now sibling
					Set tParent = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tNodeNo)),4)
					While (tParent '= "") {
						Set tNextNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tParent,"ch",tNodeNo))
						If (tNextNode '= "") {
							Set tFound = 1
							Quit
						}
						// go up
						Set tNodeNo = tParent
						Set tLevel = tLevel - 1
						Set tParent = $LG($G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tParent)),4)
					}
				} While(0)
				If $$$ISERR(tSC) Quit

				If (tFound) {
					Set tNodeNo = tNextNode
				}
				Else {
					Set tNodeNo = ""
				}
			}
			// store cell count for axis
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",a) = tCellNo

		} // next a
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// For a completed query, compute totals and other aggregates for each row and column
/// of the result.
/// If the query has more than 2 axes, then this does nothing.
ClassMethod %ComputeTotals(pCube As %String, pKey As %String, ByRef pMaxValue As %Decimal, ByRef pMinValue As %Decimal) As %Status [ Internal ]
{
	Set tSC = $$$OK

	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"total")

		// JMD1492 recompute min/max value for query
		// this is used for coloring;
		// we need to recompute as there could have been pending results

		Set tQueryType = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"queryType"))
		Set tIsBitSet = (tQueryType = "%BITSET")
		If (tIsBitSet) Quit
	
		// find number of axes (sans slicer)
		Set tSizeInfo = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"size"))
		Set tAxisCount = 0
		Set tCount = $LL(tSizeInfo)
		For a = 1:1:tCount {
			Set tInfo = $LG(tSizeInfo,a)
			If ($LG(tInfo,1)="axis") {
				Set tAxisCount = tAxisCount + 1
			}
		}

		// only 2-d results make sense
		// 1-d case is always converted to 2d...
		Set tColAxis = 1
		Set tRowAxis = 2
		Set tPageAxis = 3
		Set tTotal = 0

		Set pIndex = $I(^||DeepSee.Temp)

		Kill ^||DeepSee.ColAgg
		Kill ^||DeepSee.RowAgg
		
		// JMD1205
		// we *could* get a 3D result when there is a complex slicer
		// in this case, we have to fold the "pages" together
		// JMD1401 - this should not happen any more!
		If (tAxisCount=0) {
			// single cell
			Set tValue = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0))
			Set:$ISVALIDNUM(tValue)&&((tValue>pMaxValue)||(pMaxValue="")) pMaxValue = tValue
			Set:$ISVALIDNUM(tValue)&&((tValue<pMinValue)||(pMinValue="")) pMinValue = tValue
		}
		// + WAL226 -- add handling for 1 axis queries
		ElseIf (tAxisCount=1) {
			// Find out which axis we have
			Set tAxisNo = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",""))
			Set n = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tAxisNo,""),1,tNode)
			While (n'="") {
				Set tValue = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,tNode))
				If (tValue'="") {
					Set:$ISVALIDNUM(tValue)&&((tValue>pMaxValue)||(pMaxValue="")) pMaxValue = tValue
					Set:$ISVALIDNUM(tValue)&&((tValue<pMinValue)||(pMinValue="")) pMinValue = tValue
					Set tTotal = tTotal + tValue
					If (tAxisNo = 1) {
						// rows-wise
						Set ^||DeepSee.RowAgg(1,"count") = 1+$G(^||DeepSee.RowAgg(1,"count"))
						Set ^||DeepSee.RowAgg(1,"sum") = tValue+$G(^||DeepSee.RowAgg(1,"sum"))
						Set ^||DeepSee.RowAgg(1,"min") = $S($G(^||DeepSee.RowAgg(1,"min"))="":tValue,^||DeepSee.RowAgg(1,"min")>tValue:tValue,1:^||DeepSee.RowAgg(1,"min"))
						Set ^||DeepSee.RowAgg(1,"max") = $S($G(^||DeepSee.RowAgg(1,"max"))="":tValue,^||DeepSee.RowAgg(1,"max")<tValue:tValue,1:^||DeepSee.RowAgg(1,"max"))						
					}
					ElseIf (tAxisNo = 2) {
						Set ^||DeepSee.ColAgg(1,"count") = 1+$G(^||DeepSee.ColAgg(1,"count"))
						Set ^||DeepSee.ColAgg(1,"sum") = tValue+$G(^||DeepSee.ColAgg(1,"sum"))
						Set ^||DeepSee.ColAgg(1,"min") = $S($G(^||DeepSee.ColAgg(1,"min"))="":tValue,^||DeepSee.ColAgg(1,"min")>tValue:tValue,1:^||DeepSee.ColAgg(1,"min"))
						Set ^||DeepSee.ColAgg(1,"max") = $S($G(^||DeepSee.ColAgg(1,"max"))="":tValue,^||DeepSee.ColAgg(1,"max")<tValue:tValue,1:^||DeepSee.ColAgg(1,"max"))						
					}
				}
				Set n = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tAxisNo,n),1,tNode)
			}
		}
		// - WAL226
		ElseIf ((tAxisCount=2)||(tAxisCount=3)) {
			Set c = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tColAxis,""),1,tCNode)
			While (c'="") {
				Set r = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tRowAxis,""),1,tRNode)
				While (r'="") {
					If (tAxisCount=2) {
						Set tValue = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,tCNode,tRNode))
					}
					Else {
						// 3D: loop over pages
						Set tValue = ""
						Set p = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tPageAxis,""),1,tPNode)
						While (p'="") {
							Set v = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,tCNode,tRNode,tPNode))
							Set:(v'="") tValue = tValue + v
							Set p = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tPageAxis,p),1,tPNode)
						}
					}

					If $IsValidNum(tValue) {
						// DTB363 - Only execute this section if the value is a valid numeric
						Set:((tValue>pMaxValue)||(pMaxValue="")) pMaxValue = tValue
						Set:((tValue<pMinValue)||(pMinValue="")) pMinValue = tValue

						Set tTotal = tTotal + tValue
						// rows-wise
						Set ^||DeepSee.RowAgg(r,"count") = 1+$G(^||DeepSee.RowAgg(r,"count"))
						Set ^||DeepSee.RowAgg(r,"sum") = tValue+$G(^||DeepSee.RowAgg(r,"sum"))
						Set ^||DeepSee.RowAgg(r,"min") = $S($G(^||DeepSee.RowAgg(r,"min"))="":tValue,^||DeepSee.RowAgg(r,"min")>tValue:tValue,1:^||DeepSee.RowAgg(r,"min"))
						Set ^||DeepSee.RowAgg(r,"max") = $S($G(^||DeepSee.RowAgg(r,"max"))="":tValue,^||DeepSee.RowAgg(r,"max")<tValue:tValue,1:^||DeepSee.RowAgg(r,"max"))

						Set ^||DeepSee.ColAgg(c,"count") = 1+$G(^||DeepSee.ColAgg(c,"count"))
						Set ^||DeepSee.ColAgg(c,"sum") = tValue+$G(^||DeepSee.ColAgg(c,"sum"))
						Set ^||DeepSee.ColAgg(c,"min") = $S($G(^||DeepSee.ColAgg(c,"min"))="":tValue,^||DeepSee.ColAgg(c,"min")>tValue:tValue,1:^||DeepSee.ColAgg(c,"min"))
						Set ^||DeepSee.ColAgg(c,"max") = $S($G(^||DeepSee.ColAgg(c,"max"))="":tValue,^||DeepSee.ColAgg(c,"max")<tValue:tValue,1:^||DeepSee.ColAgg(c,"max"))
					}

					Set r = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tRowAxis,r),1,tRNode)
				}
				Set c = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",tColAxis,c),1,tCNode)
			}
		}

		// compute averages & pct of total
		// JMD908 -- do not ignore neg numbers for pct of total
		Set r = $O(^||DeepSee.RowAgg(""))
		While (r'="") {
			Set tCount = +$G(^||DeepSee.RowAgg(r,"count"))
			Set:tCount>0 ^||DeepSee.RowAgg(r,"avg") = $G(^||DeepSee.RowAgg(r,"sum"))/tCount
			Set:tTotal'=0 ^||DeepSee.RowAgg(r,"pct") = $G(^||DeepSee.RowAgg(r,"sum"))/tTotal
			Set r = $O(^||DeepSee.RowAgg(r))
		}
		Set c = $O(^||DeepSee.ColAgg(""))
		While (c'="") {
			Set tCount = +$G(^||DeepSee.ColAgg(c,"count"))
			Set:tCount>0 ^||DeepSee.ColAgg(c,"avg") = $G(^||DeepSee.ColAgg(c,"sum"))/tCount
			Set:tTotal'=0 ^||DeepSee.ColAgg(c,"pct") = $G(^||DeepSee.ColAgg(c,"sum"))/tTotal
			Set c = $O(^||DeepSee.ColAgg(c))
		}

		// Move results into results global
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"total") = tTotal
		Merge $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"total",tColAxis) = ^||DeepSee.ColAgg
		Merge $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"total",tRowAxis) = ^||DeepSee.RowAgg

		Kill ^||DeepSee.ColAgg
		Kill ^||DeepSee.RowAgg
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Build an array (in the ^||DeepSee.Temp global) of the values in the first "column" of a query for each "row".<br/>
/// This is used by functions such as Filter et. al. to get values from subquery
/// results.<br/>
/// On return <var>pIndex</var> holds the subscript for the temp global.<br/>
/// The results are returned in an array subscripted by internal tuple names:<br/>
/// Fact : Value $C(2)  Fact : Value<br/>
/// In addition, the total of the value is returned via <var>pTotal</var> as some
/// consumers are interested in this value.<br/>
/// If <var>pPreserveOrder</var>, then the results are returned in ranked order using a leading
/// numeric subscript.
ClassMethod %GetAxisValues(Output pIndex, pCube As %String, pKey As %String, Output pTotal As %Double, pPreserveOrder As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pData
		Set pTotal = 0
		Set pIndex = $I(^||DeepSee.Temp)
		Set pCube = $$$UPPER(pCube)

		// Find axes
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		Set tRowAxisKey = tAxisKey(2)
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		// loop along leaf nodes, pick up values
		Set col = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",1,""),1,c)
		If (col="") {
			Set tSC = $$$ERROR($$$GeneralError,"%GetAxisValues requires 2-D results")
			Quit
		}

		Set tRank = 0
		Set tCount = 0
		Set tLastValue = ""
		Set row = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",2,""),1,r)
		While (row '= "") {
			Set tRowNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",r))
			Set tValue = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,c,r))
			If (tValue '= "") {
				Set tCount = tCount + 1
				If (tValue '= tLastValue) {
					Set tRank = tCount
				}
				Set tLastValue = tValue
				Set pTotal = pTotal + $S((tValue=1E-14):0,1:tValue)		// DTB324 - Convert back to 0 when calculating total
				// construct internal tuple for this value
				Set tIndex = ""
				Set tType = $LG(tRowNode,1)
				While (tType'="axis") {
					// +DTB333 - Account for compound cube dimensions by looking for a sharesFrom index if this cube is a member 
					// of a compound cube. If this fact is shared, look up the defining cube's fact number to create the
					// index in ^||DeepSee.Temp [DTB260].
					Set tFact = $LG(tRowNode,7)
					Set tDimNo = $LG(tRowNode,9)		// DTB493 - Test the dimension number of the axis first
					
					If ((tType="mbr")||(tType="msr"))&&(tDimNo'="") {
						If (($IsObject($G(%query))&&%query.%isCompoundMember)||##class(%DeepSee.Utils).%IsCubeCompound(pCube)) {
							Set tHierNo = $LG(tRowNode,10)
							Set tLevelNo = $LG(tRowNode,11)
							Set tDimName = $LG($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,0,0),2)
							Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"sharesFrom",""))
							While tSharesFromCubeIndex'="" { 
								If $D($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"sharesFrom",tSharesFromCubeIndex,$$$UPPER(tDimName))) {
									// Get the fact number from the original cube
									Set tSharedDim = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbrs",$$$UPPER(tDimName)),1)
									Set tFact = $LG($$$DeepSeeMetaGLVN("cubes",tSharesFromCubeIndex,"mbr#",tSharedDim,tHierNo,tLevelNo),5)
								}
								Set tSharesFromCubeIndex = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"sharesFrom",tSharesFromCubeIndex))
							}
						}
						If (tType = "mbr") {
							Set tKey = $LG(tRowNode,6)
						}
						ElseIf (tType = "msr") {
							Set tKey = ""
						}
						
						// n.b., fact and/or key  may be "" (such as ALL level)
						Set tIndex = tFact_":"_tKey _ $S(tIndex="":"",1:$C(2)) _ tIndex
					}
					// -DTB333
					
					Set tParent = $LG(tRowNode,4) // go to parent
					Set tRowNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tRowAxisKey,"axes",tParent))
					Set tType = $LG(tRowNode,1)
				}
				If (pPreserveOrder) {
					Set:tIndex'="" ^||DeepSee.Temp(pIndex,tRank,tIndex) = tValue
				}
				Else {
					Set:tIndex'="" ^||DeepSee.Temp(pIndex,tIndex) = tValue
				}
			}
			Set row = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"leaf",2,row),1,r)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Call <method>%Intersect</var> with the <var>pExistsOnly</var> flag set.
ClassMethod %IntersectExists(pCube As %String, pIndex1 As %String, pKey1 As %String, pIndex2 As %String = "", pKey2 As %String = "") As %Boolean [ Internal ]
{
	Quit ..%Intersect(pCube,pIndex1,pKey1,pIndex2,pKey2,1)
}

/// Given a pair of index and key names, test if there 
/// is an intersection of the implied sets
/// within the specified cube. Return true (1) if there is a possible intersection. If a slicer is present 
/// it will also be applied before testing the intersection.<br/>
/// This method may be called in two modes, controlled by <var>pExistsOnly</var>:<br>
/// 0 - Fully compute the intersection for any bucket looked at in this intersection and cache the result for later use<br>
/// 1 - Stop examination of the requested intersection as soon as a single fact is found that fits the supplied intersect parameters
ClassMethod %Intersect(pCube As %String, pIndex1 As %String, pKey1 As %String, pIndex2 As %String = "", pKey2 As %String = "", pExistsOnly = 0) As %Boolean [ Internal ]
{
	New $$$dsRuntimeCache
	// DTB968 - Note logging and start local timer
	$$$dsSetLogging
	$$$dsStartTimer
	
	// n.b. we always apply a slicer to this test;
	// this may make NONEMPTYCROSSJOIN behave differently than other implementations
	Set tFound = 0
	Set tAddr = ":"	// add extra slot at start of address!
	Set tCubeName = $$$UPPER(pCube)
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Set tHasSlicer = 0
	Set tMax = $S(pIndex2="":pIndex1,pIndex1>pIndex2:pIndex1,1:pIndex2)
	For n=1:1:tMax {
		Set tAddr = tAddr _ $S(n>1:":",1:"") _ $S(n=pIndex1:pKey1,n=pIndex2:pKey2,1:"")
	}

	// no query key
	If ('$IsObject($G(%query))&&(%query.%QueryKey="")) Quit 1
	Set tQueryKey = %query.%QueryKey

	If (tAddr="") Quit 0

	// DP-423012 - @-keys arent in the index but they should be in a %Bitset temp index that can be referenced
	If ((pKey1["@") || (pKey2["@")) Quit 1

	// JMD1330: if there is no entry for the index, then we know there are no records
	If ((pIndex1'="")&&(pKey1'="")&&(pKey1'["|")&&(pKey1'["!")) {
		If '$D($$$DeepSeeIndexGLVN(tCubeIndex,pIndex1,pKey1)) Quit 0
	}
	If ((pIndex2'="")&&(pKey2'="")&&(pKey2'["|")&&(pKey2'["!")) {
		If '$D($$$DeepSeeIndexGLVN(tCubeIndex,pIndex2,pKey2)) Quit 0
	}

	// JMD1059: is there a dependsOn index between the 2 keys: AxB or BxA
	// DTB669 - Cannot use dependsOn indices to eliminate the intersection if either key is a %NOT key
	// DTB952 - Correct typo in pKey2 ! test
	If ((pIndex1'="")&&(pIndex2'="")&&(pKey1'="")&&(pKey2'="")&&($E(pKey1)'="!")&&($E(pKey2)'="!")) {
		If $D($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"factDepends",pIndex1,pIndex2)) {
			If (pKey1["|")||(pKey2["|") {
				// DTB669 - One or both keys are %OR. Look through the combinations and continue if there are any intersections.
				//    (A|B)&(C|D) == (A&C)|(A&D)|(B&C)|(B&D)
				Set tDependsOnIntersection = 0
				For tKey1Idx=1:1:$L(pKey1,"|") {
					For tKey2Idx=1:1:$L(pKey2,"|") {
						Set tKey1Part = $P(pKey1,"|",tKey1Idx)
						Set tKey2Part = $P(pKey2,"|",tKey2Idx)
						
						If $D($$$DeepSeeIndexGLVN(tCubeIndex,pIndex1_"&"_pIndex2,tKey1Part,tKey2Part)) {
							// No need to continue if we already found something
							Set tDependsOnIntersection = 1
							Quit
						}
					}
					
					If tDependsOnIntersection {
						Quit
					}
				}
				
				If 'tDependsOnIntersection {
					// Return zero if no intersections have been found in the OR examination
					Quit 0
				}
			}
			ElseIf ('$D($$$DeepSeeIndexGLVN(tCubeIndex,pIndex1_"&"_pIndex2,pKey1,pKey2))) {
				// Simple keys, there is no intersection
				Quit 0
			}
		}
		ElseIf $D($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"factDepends",pIndex2,pIndex1)) {
			If (pKey1["|")||(pKey2["|") {
				// DTB669 - One or both keys are %OR. Look through the combinations and continue if there are any intersections.
				//    (A|B)&(C|D) == (A&C)|(A&D)|(B&C)|(B&D)
				Set tDependsOnIntersection = 0
				For tKey1Idx=1:1:$L(pKey1,"|") {
					For tKey2Idx=1:1:$L(pKey2,"|") {
						Set tKey1Part = $P(pKey1,"|",tKey1Idx)
						Set tKey2Part = $P(pKey2,"|",tKey2Idx)
						
						If $D($$$DeepSeeIndexGLVN(tCubeIndex,pIndex2_"&"_pIndex1,tKey2Part,tKey1Part)) {
							// No need to continue if we already found something
							Set tDependsOnIntersection = 1
							Quit
						}
					}
					
					If tDependsOnIntersection {
						Quit
					}
				}
				
				If 'tDependsOnIntersection {
					// Return zero if no intersections have been found in the OR examination
					Quit 0
				}
			}
			ElseIf ('$D($$$DeepSeeIndexGLVN(tCubeIndex,pIndex2_"&"_pIndex1,pKey2,pKey1))) {
				// Simple keys, there is no intersection
				Quit 0
			}
		}
	}

	If ($G(%slicerKey)'="") {
		Do ..%GetBranchesForSlicer(pCube,%slicerKey,.tBranch,.tHasRelations)
		If (tHasRelations) {
			// there *could* be a match
			Quit 1
		}
	}
	
	If ('$D(tBranch)) {
		Set tBranch(1) = "" // make sure there is one branch
		Set tAddr(1) = tAddr
	}
	Else {
		// fold slicer branches into tAddr (per each branch)
		Set tHasSlicer = 1		// DP-415899 - Note that there is an actual slicer

		Set bno = $O(tBranch(""))
		While (bno'="") {
			Set tAddr(bno) = tAddr
			Set i = $O(tBranch(bno,""),1,data)
			While (i '= "") {
				Set f = $LG(data,1)
				Set k = $LG(data,2)

				// get current key for fact and replace (with AND if needed)
				Set ck = $P(tAddr(bno),":",f+1)
				Set k = $S(ck="":k,1:ck_"&"_k)
				Set $P(tAddr(bno),":",f+1) = k
				Set i = $O(tBranch(bno,i),1,data)
			}
			Set bno = $O(tBranch(bno))
		}
	}

	// put all addresses in canonic form
	Set bno = $O(tBranch(""))
	While (bno'="") {
		Set:tAddr(bno)'="" tAddr(bno) = ##class(%DeepSee.Query.Engine2).%CanonizeAddr(tAddr(bno))
		Set bno = $O(tBranch(bno))
	}

	Set tChunksPerBucket = $$$DeepSeeChunksPerBucket(tCubeName)

	// test each bucket in the list until we find something
	// get the current bucket list
	// DP-420583 - Do not use a merge to load the entire bucketList from the cache global to a transient array. Each node will be read directly as needed.
	If '$D($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"bucketList")) {
		// The buckets haven't been processed for this query yet. Get the bucket list as it exists to identify valid cache as of this moment.
		If $D($$$DeepSeeResultsGLVN(tCubeIndex,0,"bucketList")) {
			// If the bucketlist is filed in the results cache, file a copy under this queryKey.
			Set (tActiveChunk, $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"activeChunk")) = $G($$$DeepSeeActiveChunk(tCubeIndex))
			Merge $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"bucketList") = $$$DeepSeeResultsGLVN(tCubeIndex,0,"bucketList")
		} 
		Else {
			// The bucketlist has not been filed for this cube, calculate it from cube metadata and store it in the query cache.
			// The $$$DeepSeeResultsGLVN(tCubeIndex,0,"bucketList") will get filled out during the %GetBucketList call.
			Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(tCubeName,.tBucketList,.tActiveChunk)
			If $$$ISERR(tSC) Quit
			Merge $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"bucketList") = tBucketList
			Set $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"activeChunk") = tActiveChunk
		}
	}
	Else {
		Set tActiveChunk = $G($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"activeChunk"))
	}


	// Test key [pairs] against each OR branch in the slicer. In the case where both keys are defined, Calculate the result and
	// cache results on the full buckets for later.
	Set bno = $O(tBranch(""))
	While (('tFound)&&(bno '= "")) {
		Set tCount = ""
		Set tBit = 0			// DP-413393 - This is 0 until a set bit is found in the intersection mask
		Set tBucketResults = 0	// Indicates whether there are any results found in any previous OR-key key combination for the current bucket
		Set tBucket = 0			// Initialize bucket to test false if a chunk match has not declared a bucket
		Set (tSlotNo,tStartChunk,tEndChunk) = 0

		If ((pIndex2="")||(pKey2="")) || ((pIndex1=pIndex2) && (pKey1=pKey2)) {
			// Single-key inspection
			For kp1=1:1:$L(pKey1,"|") {
				Quit:tFound		// This OR key is finished without processing further terms
				
				Set tMemberKey1 = $P(pKey1,"|",kp1)
				Set tNotKey1 = ($E(tMemberKey1)="!")
				Set tIndexKey1 = $S(tNotKey1:$E(tMemberKey1,2,*),1:tMemberKey1)
				
				Set tChunk1 = $S(tBucketResults:$$FindNextChunk(pIndex1,tIndexKey1,tStartChunk-1,tNotKey1,.tTempMask,.tTempIsExtent),1:$$FindNextChunk(pIndex1,tIndexKey1,"",tNotKey1,.tTempMask,.tTempIsExtent))

				While ('tFound) && (tChunk1'="") {
					// Keep trying while waiting for existence or a complete bucket result.

					// Reset the bucket constraints if no previous key examination has turned up results. Otherwise the bucket number
					// and bounds will be retained to limit future searches on remaining parts of the OR-key.
					If 'tBucketResults {
						Set tBucket = ((tChunk1-1)\tChunksPerBucket)+1
						Set tSlotNo = +$G($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"bucketList",tBucket))
						Set tStartChunk = ((tBucket-1)*tChunksPerBucket)+1
						Set tEndChunk = tStartChunk + tChunksPerBucket - 1
					}

					// Check the cache for the slotNo now that we have it 
					If (tSlotNo>0) {
						$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,tSlotNo,tAddr(bno)),val,tIsSafe,tHasData)
						If (tIsSafe && tHasData && (val > 0)) {
							// If this has valid cache, then the entire bucket and the entire OR-key have already been evaluated so this can quit out
							Set tFound = 1
							Quit
						}
					}



					// Get the slicer mask for this chunk
					Set tNullSlicer = 0
					Kill tSlicerMask
					If tHasSlicer {
						// DP-423281 - Global caching for this value occurs in the tag if applicable
						Set tNullSlicer = ($$GetSlicerMask(.tSlicerMask,.tBranch,bno,tChunk1)="")
					}

					// Produce a tTempMask according to the specific key that can be folded into other results
					// DP-420583 - If the slicer is null for this chunk skip right to advancing to the next chunk and looking at bucket results.
					If 'tNullSlicer {
						If tNotKey1 {
							// NOT
							If tTempIsExtent {
								// No need for $bitlogic if the mask for a negated nonexistent is what was turned up in the index search.
								// Either tTempMask is already set to the extent, or it can be replaced by the slicer mask which would be more restrictive.
								Set:$D(tSlicerMask) tTempMask = tSlicerMask
							}
							ElseIf $D(tSlicerMask) {
								// The extent index is folded into the slicer mask 
								$$$dsBitAandNotB(tSlicerMask,tTempMask,tTempMask)
							}
							Else {
								// A Not-Index mask needs to be checked against the extent so as not to pick up and count facts that were deleted.
								$$$dsBitAandNotB($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk1),tTempMask,tTempMask)
							}
						}
						Else {
							If pExistsOnly&&'tHasSlicer {
								// Assume the existence of a chunk in the index that led to this point is enough of a test for existence
								Set tFound = 1
								Continue
							}
							Else {
								// Perform the full intersect
								If ($D(tSlicerMask)) {
									$$$dsBitAandBIntoA(tTempMask,tSlicerMask)
								}
								Else {
									$$$dsBitNormalizeIntoA(tTempMask)
								}
							}
						}

						// Evaluation of result for this key's chunk
						If pExistsOnly {	
							$$$dsBitFind(tTempMask,1,tBit)
							If (tBit>0) {
								Set tFound = 1
								Quit
							}
						}
						Else {
							// Cache this current chunk result locally since it might be added to via more members in a %OR-key, to be totalled over the bucket later 
							If '$D(tChunkBits(tChunk1)) {
								Set tChunkBits(tChunk1) = tTempMask
							} 
							Else {
								$$$dsBitAorBIntoA(tChunkBits(tChunk1),tTempMask)
							}
						}
					}

					// Advance to the next chunk with an index
					Set tChunk1 = $$FindNextChunk(pIndex1,tIndexKey1,tChunk1,tNotKey1,.tTempMask,.tTempIsExtent)


					// Compare the chunk to the current bucket number. If the new chunk lies outside the bucket which
					// contained the chunk just processed, evaluate all chunks that have been seen in this bucket.
					// If in existsOnly mode, accumulate and cache the bucket. Quit if the bucket has results.
					Set tBucketComplete = (tChunk1="") || ( tBucket '= (((tChunk1-1)\tChunksPerBucket)+1) ) 

					// This initates a bucket count over chunks just visited whenever a bucket is completed for a particular index key.
					// It is needed for two cases: 
					//  - To find the first time a key returned actual results in a bucket.
					//  - For the final key, all indices have been visited and the final tally can be accumulated and cached if applicable.
					If 'pExistsOnly && tBucket && tBucketComplete {
						Set tFound = $$EvaluateBucket(($L(pKey1,"|")=kp1), .tBucketResults)

						// Quit out of the chunk-wise search if any complete bucket result is found. This tBucketResults
						// maintains throughout the search of all keys and so this is what allows the 2nd through Nth keys
						// to have no hits and keep the search limited to the single bucket.
						Quit:tBucketResults
					}		

				}		// Search chunks for result
			}			// OR-key pieces

		}
		Else {
			// Two-key intersection. Initiate loops through each of the %OR'ed member for both of the keys
			For kp1=1:1:$L(pKey1,"|") {				// First key loop
				Set tMemberKey1 = $P(pKey1,"|",kp1)
				Set tNotKey1 = ($E(tMemberKey1)="!")
				Set tIndexKey1 = $S(tNotKey1:$E(tMemberKey1,2,*),1:tMemberKey1)

				For kp2=1:1:$L(pKey2,"|") {			// Second key loop
					Set tMemberKey2 = $P(pKey2,"|",kp2)
					Set tNotKey2 = ($E(tMemberKey2)="!")
					Set tIndexKey2 = $S(tNotKey2:$E(tMemberKey2,2,*),1:tMemberKey2)

					// Initialize the search over chunks in this pair of indices. If a bucket is noted at this point, it means there
					// have been results found in that bucket in some OR-key pairing and the search need not exceed the bounds of that bucket.
					Set tChunk1 = $S(tBucketResults:$$FindNextChunk(pIndex1,tIndexKey1,tStartChunk-1,tNotKey1,.tKeyMask1,.tKey1IsExtent),1:$$FindNextChunk(pIndex1,tIndexKey1,"",tNotKey1,.tKeyMask1,.tKey1IsExtent))
					Set tChunk2 = $S(tBucketResults:$$FindNextChunk(pIndex2,tIndexKey2,tStartChunk-1,tNotKey2,.tKeyMask2,.tKey2IsExtent),1:$$FindNextChunk(pIndex2,tIndexKey2,"",tNotKey2,.tKeyMask2,.tKey2IsExtent))

					
					// Do the search for matching chunks between the two indices. When a match is found the bitmaps will be intersected 
					// and evaluated using $$EvaluateBucket
					For {
						Quit:(tFound || (tChunk1="") || (tChunk2=""))		// Quit if the target is found or the search has run out of data


						// Test for a match while waiting for a complete bucket result or existence based on pExistsOnly
						If (tChunk1=tChunk2) {
							// Both keys have data in this chunk, determine which bucket this is in, define the endpoints for that bucket,
							// and do the intersect
							Set tNullSlicer = 0
							Kill tSlicerMask
							If tHasSlicer {
								// DP-423281 - Global caching for this value occurs in the tag if applicable
								Set tNullSlicer = ($$GetSlicerMask(.tSlicerMask,.tBranch,bno,tChunk1)="")
							} 

							// Reset the bucket constraints if no previous key has turned up results. Otherwise the bucket number
							// and bounds will be retained to limit future searches.
							If 'tBucketResults {
								Set tBucket = ((tChunk1-1)\tChunksPerBucket)+1
								Set tSlotNo = +$G($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"bucketList",tBucket))
								Set tStartChunk = ((tBucket-1)*tChunksPerBucket)+1
								Set tEndChunk = tStartChunk + tChunksPerBucket - 1
							}

							// Check the cache for the slotNo now that we have it 
							If (tSlotNo>0) {
								$$$dsSafeRefCheckData($$$DeepSeeCellsGLVN(tCubeIndex,tSlotNo,tAddr(bno)),val,tIsSafe,tHasData)
								// If this has valid cache, then the entire bucket and the entire OR-key have already been evaluated so this can quit out
								If (tIsSafe && tHasData && (val > 0)) {
									Set tFound = 1
									Quit
								}
							}


							// Calculate the mask for this pair of keys. Key masks for missing keys that are going to be negated can be set to the null string so &~[null] has no
							// effect in the relevant $bitlogic
							// DP-420583 - If the slicer is null for this chunk skip right to advancing to the next chunk
							If 'tNullSlicer {
								If (tNotKey1&&tNotKey2) {
									// NOT 1 and NOT 2
									// - This is the only case that needs the extent bits. Any direct use of an index will already have
									//   the extent embedded in the set bits, but a negation can include bits that are unset due to being removed
									//   from the extent entirely.
									Set:tKey1IsExtent tKeyMask1 = ""
									Set:tKey2IsExtent tKeyMask2 = ""

									If $D(tSlicerMask) {
										$$$dsBitLogicArbitrary(tSlicerMask&~tKeyMask1&~tKeyMask2,tTempMask,"BitAND",2)
									}
									Else {
										$$$dsBitLogicArbitrary($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk1)&~tKeyMask1&~tKeyMask2,tTempMask,"BitAND",2)		// DTB989
									}
								}
								ElseIf tNotKey1 {
									// NOT 1 and 2
									
									Set:tKey1IsExtent tKeyMask1 = ""
									If $D(tSlicerMask) {
										$$$dsBitLogicArbitrary(tSlicerMask&~tKeyMask1&tKeyMask2,tTempMask,"BitAND",2)
									}
									Else {
										$$$dsBitAandNotB(tKeyMask2,tKeyMask1,tTempMask)
									}
								}
								ElseIf tNotKey2 {
									// 1 and NOT 2
									
									Set:tKey2IsExtent tKeyMask2 = ""
									If $D(tSlicerMask) {
										$$$dsBitLogicArbitrary(tSlicerMask&tKeyMask1&~tKeyMask2,tTempMask,"BitAND",2)
									}
									Else {
										$$$dsBitAandNotB(tKeyMask1,tKeyMask2,tTempMask)
									}
								}
								Else {
									// 1 and 2
									If $D(tSlicerMask) {
										$$$dsBitLogicArbitrary(tSlicerMask&tKeyMask1&tKeyMask2,tTempMask,"BitAND",2)
									}
									Else {
										$$$dsBitAandB(tKeyMask1,tKeyMask2,tTempMask)
									}
								}

								// Evaluation of this matched chunk. Either directly search for an existence bit or collect it for a count across the bucket 
								If pExistsOnly {	
									$$$dsBitFind(tTempMask,1,tBit)
									Set:(tBit>0) tFound = 1
								}
								Else {
									// Cache this current result locally since it might be added to via more members in a %OR-key, to be totalled later 
									If $D(tChunkBits(tChunk1)) {
										$$$dsBitAorBIntoA(tChunkBits(tChunk1),tTempMask)
									} 
									Else {
										Set tChunkBits(tChunk1) = tTempMask
									}
								}
							}

							// Advance chunk1 to initiate the search for the next chunk match
							Set tChunk1 = $$FindNextChunk(pIndex1,tIndexKey1,tChunk1,tNotKey1,.tKeyMask1,.tKey1IsExtent)
						}
						ElseIf (tChunk1<tChunk2) {
							// Advance chunk1 to catch up to chunk2.
							Set tChunk1 = $$FindNextChunk(pIndex1,tIndexKey1,tChunk2-1,tNotKey1,.tKeyMask1,.tKey1IsExtent)
						}
						ElseIf (tChunk2<tChunk1) {
							// Advance chunk2 to catch up to chunk1
							Set tChunk2 = $$FindNextChunk(pIndex2,tIndexKey2,tChunk1-1,tNotKey2,.tKeyMask2,.tKey2IsExtent)
						}


						// Compare both chunks to the current bucket number. If either of the new chunks lie outside the bucket which
						// contained the chunk just processed, a subsequent match will not be discovered in this bucket so evaluate all collected chunks
						// If not in existsOnly mode, accumulate and cache the bucket.
						Set tBucketComplete = (tChunk1="") || (tChunk2="") || 
								(( tBucket '= (((tChunk1-1)\tChunksPerBucket)+1) ) || ( tBucket '= (((tChunk2-1)\tChunksPerBucket)+1) ))

						// This counts the final result and is currently reached for every key in an OR-key. 
						If 'pExistsOnly && tBucket && tBucketComplete {
							Set tFound = $$EvaluateBucket((($L(pKey1,"|")=kp1)&&($L(pKey2,"|")=kp2)), .tBucketResults)

							// Quit out of the chunk-wise search if any complete bucket result is found. This tBucketResults
							// maintains throughout the search of all keys and so this is what allows the 2nd through Nth keys
							// to have no hits and keep the search limited to the single bucket.
							Quit:tBucketResults
						}		

					}			// Search chunks for result
				}				// Second OR-Key
			}					// First OR-Key

		}

		// DP-420247 - Run a final Evaluate bucket in case the final key(s) skipped processing since they had no chunks in the bucket.
		// This isn't necessary if tFound is already set, $$EvaluateBucket only returns tFound if it ran on a cacheable result.
		Set:'tFound tFound = $$EvaluateBucket(1,tBucketResults)

		// next slicer OR branch
		Set bno = $O(tBranch(bno))
	}

	$$$dsStopTimer		// DTB968
	
	Quit tFound

	// Find the next chunk that exists in the index. 
	// This function exists to handle the case where the key does not exist in the index and is also negated,
	// which contributes the extent mask to the intersect evaluation
FindNextChunk(tIndex,tKey,tCurrChunk,tNot,tMask,tIsExtent)
	// Added by DP-417984
	Set tIsExtent = 0
	Set tNextChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,tIndex,tKey,tCurrChunk),1,tMask)
	If (tNextChunk="") && tNot {
		// NOT of a non-existent member returns the extent mask.
		Set tNextChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tCurrChunk),1,tMask)
		Set:(tNextChunk'="") tIsExtent = 1
	}

	Quit tNextChunk

	// Assuming a bucket has been defined and bounded by start/end chunks, accumumlate the count. Calling this once
	// OR-key results have already been confirmed (tBucketResults=1) AND there are still more OR-keys to visit skips the
	// full evaluation and returns the current tFound
EvaluateBucket(tLastKey, tBucketResults)
	// Added by DP-417984
	// Return previous tFound if more keys are going to be accumulated and a bucket has already been confirmed to have results
	Quit:(('tLastKey)&&tBucketResults) tFound

	Set tCount = ""
	
	Set tEvalChunk = $O(tChunkBits(tStartChunk-1),1,tEvalChunkBits)
	While (tEvalChunk'="") && (tEvalChunk<=tEndChunk) {
		If tEvalChunk=tActiveChunk {
			// If this search has reached the active chunk it will be the last chunk visited and will not be cached. Returning tFound based on the first set bit is sufficient.
			// The tBucketResults flag is set whenever results are found for the benefit of following OR-keys
			$$$dsBitFind(tEvalChunkBits,1,tActiveBit)
			Set (tFound,tBucketResults) = (tActiveBit>0)
		}
		Else {
			$$$dsBitCountAccum(tEvalChunkBits,1,tCount)
			Set tBucketResults = (tCount>0)
		}

		Set tEvalChunk = $O(tChunkBits(tEvalChunk),1,tEvalChunkBits)
	}
	
	// If this count has been calculated for an intersection on this bucket, store that value in the cell cache
	// unless the bucket is only the active chunk.
	// A numeric value for tCount means data exists for this intersection under this slicer and has been calculated. If
	// tCount reaches this point as a null value it indicates there was no chunk-wise data aligned with the (key1,key2) intersection
	// of interest. This is distinct from chunks in the intersection being examined and ultimately returning zero.
	// A result can't be cached on the tAddr address from this position unless it's the final key for BOTH OR-keys.
	If (tStartChunk '= tActiveChunk) && +$G(tSlotNo) && (tAddr(bno)'="") && tLastKey {
		// DTB401 - Test reference with macro
		$$$dsSafeRef($$$DeepSeeCellsGLVN(tCubeIndex,tSlotNo,tAddr(bno)),tVal,tIsSafe)
		Set:tIsSafe $$$DeepSeeCellsGLVN(tCubeIndex,tSlotNo,tAddr(bno)) = tCount

		// There has to be a result to set tFound even though a null result can be cached
		Set:+tCount tFound = 1
	}

	Quit tFound

	// Build mask from slicer for the given chunk
GetSlicerMask(tMask,tBranch,tBranchNo,tChunk)
	Set tIsActiveChunk = (tChunk=tActiveChunk)
	
	// DTB989 - Consult the mask cache for this slicer key
	If 'tIsActiveChunk &&
		$D($$$DeepSeeMaskGLVN(tCubeIndex,"slicerBranch",tSlotNo,%slicerKey,tBranchNo,tChunk),tMask) {
		$$$dsGloCacheRead("slicerBranch")
		Quit tMask
	}
	Kill tChunkExtentBits		// DP-420583 - Reset extent bits in case it was set during analysis for a previous chunk

	Set i = $O(tBranch(tBranchNo,""),1,data)
	While (i '= "") {
		Set f = $LG(data,1)
		Set k = $LG(data,2)
		If ((f'="")&&(k'="")) {
			// test for OR and NOT in k
			// DTB989 - The mask for this OR can be accumulated in one pass as long as
			// the incoming mask is preserved throughout the loop over "|" pieces. This gets
			// accumulated in the tTempOrMask and replaces the tMask when the loop is complete.				
			Set tTempOrMask = ""
			For j=1:1:$L(k,"|") {
				Set k2 = $P(k,"|",j)
				If ('$D(tMask)) {
					Set tNot = 0
					If ($E(k2)="!") {
						Set tNot = 1,k2 = $E(k2,2,*)
					}
					If (tNot) {
						// DTB970 - Use macros
						Set:'$D(tChunkExtentBits) tChunkExtentBits = $$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk)
						$$$dsBitLogicArbitraryList(tTempOrMask|(tChunkExtentBits&~$$$DeepSeeIndexGLVN(tCubeIndex,f,k2,tChunk)),tTempOrMask,"BitAND,BitOR")		// DTB989
					}
					Else {
						$$$dsBitAorBIntoA(tTempOrMask,$$$DeepSeeIndexGLVN(tCubeIndex,f,k2,tChunk))		// DTB989
					}
				}
				Else {
					Set tNot = 0
					If ($E(k2)="!") {
						Set tNot = 1,k2 = $E(k2,2,*)
					}
					If (tNot) {
						// DTB970 - Use macros
						$$$dsBitLogicArbitraryList(tTempOrMask|(tMask&~$$$DeepSeeIndexGLVN(tCubeIndex,f,k2,tChunk)),tTempOrMask,"BitAND,BitOR")		// DTB989
					}
					Else {
						// DTB970 - Use macros
						$$$dsBitLogicArbitraryList(tTempOrMask|(tMask&$$$DeepSeeIndexGLVN(tCubeIndex,f,k2,tChunk)),tTempOrMask,"BitAND,BitOR")		// DTB989
					}
				}
			} // j
			
			Set tMask = tTempOrMask		// DTB989
			
			$$$dsBitFind(tMask,1,tTestBit)		// DTB970
			If 'tTestBit {
				// DTB989 - Break out of the slicer branch loop if the mask is empty at this point
				Set tMask = ""
				Quit
			}
		}
		
		Set i = $O(tBranch(tBranchNo,i),1,data)
	}
	
	// DTB989 - Cache this mask result for the slicer branch if there were results
	If 'tIsActiveChunk {
		$$$dsGloCacheSet("slicerBranch")
		Set $$$DeepSeeMaskGLVN(tCubeIndex,"slicerBranch",tSlotNo,%slicerKey,tBranchNo,tChunk) = tMask
	}
	
	Quit tMask		// Return the mask to make this locally cacheable
}

/// Traverse a node of type "orset", beginning at the bottom and working up. If any of the
/// nodes contained in the orset intersect with the the node represented by pNode2, the method
/// will return true. If there are zero intersections in any of the nodes in the orset chain,
/// the method returns false.
ClassMethod %IntersectOrset(pCubeIndex, pKey, pOrsetLeafNode, pNode2, Output pStatus As %Status) As %Boolean [ Internal ]
{
	// Method added by DTB248
	Set pStatus = $$$OK
	Set tOrsetIntersect = 0
	Try {
		Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pOrsetLeafNode))
		Set tType1 = $$$dsAxisNodeTypeGet(tNode1)
		Set tParent = $$$dsAxisNodeParentGet(tNode1)
		Set tKey1 = $$$dsAxisNodeKeyGet(tNode1)
		Set tFact1 = $$$dsAxisNodeFactGet(tNode1)
		// find hierarchy of first set
		Set tDim1 = $$$dsAxisNodeDimGet(tNode1)
		Set tHier1 = $$$dsAxisNodeHierGet(tNode1)
		Set tLevel1 = $$$dsAxisNodeLevelGet(tNode1)

		Set tNode2 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",pNode2))
		Set tType2 = $$$dsAxisNodeTypeGet(tNode2)
		Set tKey2 = $$$dsAxisNodeKeyGet(tNode2)
		Set tFact2 = $$$dsAxisNodeFactGet(tNode2)
		// find hierarchy of second set
		Set tDim2 = $$$dsAxisNodeDimGet(tNode2)
		Set tHier2 = $$$dsAxisNodeHierGet(tNode2)
		Set tLevel2 = $$$dsAxisNodeLevelGet(tNode2)
		
		Set tClimbOrset = 1
		Set tOrsetIntersect = 0
		While (tClimbOrset) {
			If ((tDim1=tDim2)&&(tHier1=tHier2)) {
				// JMD779: optimization
				If (tLevel2>tLevel1) {
					Set tOrsetIntersect = tOrsetIntersect||##class(%DeepSee.Query.Engine).%IntersectExists(pCubeIndex,tFact2,tKey2)		// DP-415899
				}
			}
			// JMD1045: if JMD779 test passes, we still need to test both
			// as we could have the Asia->Brasil case
			Set tOrsetIntersect = tOrsetIntersect||##class(%DeepSee.Query.Engine).%IntersectExists(pCubeIndex,tFact1,tKey1,tFact2,tKey2)		// DP-415899
			
			If ('tOrsetIntersect) {
				// Keep looking for a possible intersection
				Set tNode1 = $G($$$DeepSeeAxisGLVN(pCubeIndex,pKey,"axes",tParent))

				Set tNodeType = $$$dsAxisNodeTypeGet(tNode1)
				Set tParent = $$$dsAxisNodeParentGet(tNode1)
				Set tKey1 = $$$dsAxisNodeKeyGet(tNode1)
				Set tFact1 = $$$dsAxisNodeFactGet(tNode1)
						
				Set tDim1 = $$$dsAxisNodeDimGet(tNode1)
				Set tHier1 = $$$dsAxisNodeHierGet(tNode1)
				Set tLevel1 = $$$dsAxisNodeLevelGet(tNode1)
				
				If (tNodeType="orset") {
					// Discontinue climbing up the chain
					Set tClimbOrset=0
				}
			}
			Else {
				Set tClimbOrset = 0
			}
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tOrsetIntersect = 0
	}

	Quit tOrsetIntersect
}

/// Compute the number of facts within the current slicer.
/// Return -1 if there is no slicer or all/most facts are selected by it or
/// if the count is greater than <var>pMaxCount</var>.
ClassMethod %CountFactsWithSlicer(pCube As %String, pSlicerKey As %String, pMaxCount As %Integer = 10000) As %Integer [ Internal ]
{
	Set tCubeName = $$$UPPER(pCube)
	Set tCubeIndex = $$$DeepSeeIndex(pCube)

	Do ..%GetBranchesForSlicer(tCubeName,pSlicerKey,.tBranch)
	If ('$D(tBranch)) {
		Quit -1
	}

	Set tChunksPerBucket = $$$DeepSeeChunksPerBucket(tCubeName)
	// test each bucket in the list until we find something
	Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(tCubeName,.tBucketList,.tActiveChunk)
	If $$$ISERR(tSC) Quit 0
	Set tCount = 0

	// first test active chunk
	// Test against each OR branch in the slicer
	Set bno = $O(tBranch(""))
	While ((tCount<pMaxCount)&&(bno '= "")) {
		If ($D($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tActiveChunk))) {
			Kill tMask
			Do ..%GetSlicerMask(tCubeIndex,.tMask,.tBranch,bno,tActiveChunk)
			If $D(tMask) {
				$$$dsBitCountAccum(tMask,1,tCount)		// DTB981
			}
		}
		// next branch
		Set bno = $O(tBranch(bno))
	}
	If (tCount >= pMaxCount) {
		Quit -1
	}

	// now test buckets
	Set bno = $O(tBranch(""))
	While ((tCount<pMaxCount)&&(bno '= "")) {
		Set tBucket = $O(tBucketList(""))
		While ((tCount<pMaxCount) && (tBucket'="")) {
			Set tSlotNo = tBucketList(tBucket)
			// calculate count from indices

			// get start/end bitmap chunk for this bucket
			Set tStartChunk = ((tBucket-1)*tChunksPerBucket)+1
			Set tEndChunk = tStartChunk + tChunksPerBucket - 1

			// walk down set of chunks
			For tChunk = tStartChunk:1:tEndChunk {
				If ((tChunk'=tActiveChunk) && $D($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",tChunk))) {
					Kill tMask
					Do ..%GetSlicerMask(tCubeIndex,.tMask,.tBranch,bno,tChunk,tSlotNo)

					If $D(tMask) {
						$$$dsBitCountAccum(tMask,1,tCount)		// DTB981
					}
				}
			}
			// next bucket
			Set tBucket = $O(tBucketList(tBucket))
		}
		// next branch
		Set bno = $O(tBranch(bno))
	}
	If (tCount >= pMaxCount) {
		Quit -1
	}
	Quit tCount
}

/// Given a slicer axis key, return a graph of branch nodes in the slicer that
/// can be to compute the facts within the slicer.<br/>
/// The branch structure looks like:<br/>
/// pBranch(1)=2<br/>
/// pBranch(1,1)=$lb(1,2006)<br/>
/// pBranch(1,2)=$lb(8,"24")<br/>
/// pBranch(2)=2<br/>
/// pBranch(2,1)=$lb(1,2007)<br/>
/// pBranch(2,2)=$lb(8,"24")<br/>
/// Each top-level branch needs to be OR'd together, within each branch items are ANDed.
/// Each node contains $LB(fact,key).<br/>
/// <var>pReferencedFacts</var> is array of facts referenced in the slicer; this is used
/// to disambiguate slicers with no effect from slicers that restrict everything.
ClassMethod %GetBranchesForSlicer(pCube As %String, pSlicerKey As %String, Output pBranch, Output pHasRelations As %Boolean, Output pReferencedFacts As %String) As %Status [ Internal ]
{
	// See if we can use the slicer to restrict
	// walk up the slicer nodes (from the end points specified by the all index) 
	// and find the conditions (as a number of OR branches)
	Set tSC = $$$OK
	// DP-413393
	$$$dsSetLogging
	$$$dsStartTimer

	
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Kill pBranch
	Set tBranchNo = 0
	Set pHasRelations = 0
	Kill pReferencedFacts
	
	Try {		// DTB567 - Wrap this method in a Try block
		Set tLeafNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",1,"all",""))
		If (tLeafNode="") {
			// JMD955: no leaf nodes; could be a slicer that restricts *everything*
			Set k = $O($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",1))
			While (k'="") {
				Set tNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",k))
				Set tNodeType = $LG(tNode,1)
				Set tFact = $LG(tNode,7)
				If ((tNodeType="set")&&'$D($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",k,"ch"))) {
					// special case: an empty set is also a slicer that restricts everything!
					Set pReferencedFacts("EMPTY SET") = ""
				}
				Else {
					Set:(tFact'="")&&(tNodeType="mbr") pReferencedFacts(tFact) = $LB($LG(tNode,9),$LG(tNode,10),$LG(tNode,11))		// DTB526 - Return lookup information
				}
				Set k = $O($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",k))
			}
		}
		Else {
			While (tLeafNode'="") {
				// JMD1453 instead of walking up; first find the top and walk back down
				Kill tList
				Set tLevel = 0
				Kill tLocalBranch
				Kill tRelatedBranch		// DTB694
				Set tLocalBranchCount = 1

				Set tParent = tLeafNode
				While (tParent'="") {
					Set tNode = $$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",tParent)
					Set tNodeType = $LG(tNode,1)
					If ((tNodeType="axis")||(tNodeType="slicer")) {
						Quit
					}
					ElseIf ((tNodeType="mbr")||(tNodeType="msr")) {
						// test for key and fact so we don't have to later
						Set tKey = $LG(tNode,6)
						Set tFact = $LG(tNode,7)
						Set:(tFact'="")&&(tNodeType="mbr") pReferencedFacts(tFact) = $LB($LG(tNode,9),$LG(tNode,10),$LG(tNode,11))		// DTB526 - Return lookup information
						If (((tFact'="")&&(tKey'=""))) {
							Set:$D($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"rel#",tFact)) pHasRelations = 1		// DTB694
							Set tList($I(tLevel)) = tNode
						}
					}
					ElseIf ((tNodeType="tuple")||(tNodeType="orset")||(tNodeType="ortuple")) {
						Set tList($I(tLevel)) = tNode
					}
					Set tParent = $LG(tNode,4)
				}

				// walk back down the list
				Set q = $O(tList(""),-1,tNode)
				While (q'="") {
					Set tNodeType = $LG(tNode,1)
					If (tNodeType = "mbr") {
						Set tKey = $LG(tNode,6)
						Set tFact = $LG(tNode,7)

						Set:tLocalBranchCount=0 tLocalBranchCount=1
						// add to each local branch
						For lb=1:1:tLocalBranchCount {
							If tKey["@" {
								// DTB694 & PFS - Add to Related Branch and merge later
								Set tRelatedBranch(lb,tFact,$I(tRelatedBranch(lb))) = tKey
							} Else {
								Set tLocalBranch(lb,$I(tLocalBranch(lb))) = $LB(tFact,tKey)
							}
						}
					}
					ElseIf (tNodeType = "orset") {

						// remember branches up to this point so we can copy it to new branches
						Kill tPriorBranch
						Set tPriorCount = tLocalBranchCount
						For pb = 1:1:tPriorCount {
							Set k = $O(tLocalBranch(pb,""),1,tOther)
							While (k'="") {
								Set tPriorBranch(pb,$I(tPriorBranch(pb))) = tOther
								Set k = $O(tLocalBranch(pb,k),1,tOther)
							}
						}

						// fetch the items in the orset
						Set tORCount = 0
						Set tORTuple = 0
						Set tInORtuple = 0
						Kill tORList
						Kill tRelatedORList		// DTB694
						Set q2 = $O(tList(q),-1,tNode2)
						While (q2'="") {
							Set tNode2Type = $LG(tNode2,1)
							If (tNode2Type="mbr") {
								Set tKey = $LG(tNode2,6)
								Set tFact = $LG(tNode2,7)
								If (tInORtuple) {
									Set tORTuple = tORTuple + 1
								}
								Else {
									Set tORCount = tORCount + 1
									Set tORTuple = 1
								}
								If tKey["@" {
									// DTB694 - Special accumulation of the ortuple nodes
									Set tRelatedORList(tORCount,tFact,tORTuple) = tKey
								} Else {
									Set tORList(tORCount,tORTuple) = $LB(tFact,tKey)
								}
								// advance
								Set q = q2
							}
							ElseIf (tNode2Type="ortuple") {
								Set tInORtuple = 1
								Set tORTuple = 0
								Set tORCount = tORCount + 1
							}
							ElseIf ((tNode2Type="tuple")||(tNode2Type="orset")) {
								// done with orset; do not advance
								Quit
							}
							Set q2 = $O(tList(q2),-1,tNode2)
						}

						// recreate local branches; per prior branch
						// start fresh
						Kill tLocalBranch
						Set tLocalBranchCount = 0

						For pb = 1:1:tPriorCount {
							For oc = 1:1:tORCount {
								Set tLocalBranchCount = tLocalBranchCount + 1
								Set k = $O(tPriorBranch(pb,""),1,tOther)
								While (k'="") {
									Set tLocalBranch(tLocalBranchCount,$I(tLocalBranch(tLocalBranchCount))) = tOther
									Set k = $O(tPriorBranch(pb,k),1,tOther)
								}
								Set ox = $O(tORList(oc,""))
								While (ox'="") {
									Set tLocalBranch(tLocalBranchCount,$I(tLocalBranch(tLocalBranchCount))) = tORList(oc,ox)
									Set ox = $O(tORList(oc,ox))
								}
							}
						}
					}

					// next node
					Set:q'="" q = $O(tList(q),-1,tNode)
				}
				// DTB694 - Merge both related branches into the tLocalBranch
				Set tSC = ##class(%DeepSee.Query.Engine).%MergeRelatedBranches(.tRelatedBranch,.tLocalBranch)		// DTB694
				Set tSC = ##class(%DeepSee.Query.Engine).%MergeRelatedBranches(.tRelatedORList,.tLocalBranch)		// DTB694

				// fold local branches into main branch
				Set lb=$o(tLocalBranch(""))
				While lb'="" {
					Set tBranchNo = tBranchNo + 1
					Merge pBranch(tBranchNo) = tLocalBranch(lb)
					Set lb=$o(tLocalBranch(lb))
				}

				// next leaf
				Set tLeafNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,pSlicerKey,"axes",1,"all",tLeafNode))
			}
		}	
	}
	Catch ex {
		Set tSC = ex.AsStatus()		// DTB604
	}
	
	If $$$ISOK(tSC) {
		// DTB567 - always clean the branches for inconsistencies
		Set tSC = ..%CleanBranchesForSlicer(.pBranch,tCubeIndex)
	}
	
	$$$dsStopTimer		// DP-413393
	Quit tSC
}

ClassMethod %MergeRelatedBranches(ByRef pRelatedBranch, Output pLocalBranch) As %Status
{
	// Method added by DTB694 & PFS
	Set tSC = $$$OK
	Try {
		If $D(pRelatedBranch) {
			// DTB323 - There are related keys. Look for ANDed keys in this branch  
			// and insert the combination key into the local branch as well.
			Set tBranch = $O(pRelatedBranch(""))
			While tBranch'="" {
				Set tFact = $O(pRelatedBranch(tBranch,""))
				While tFact'="" {
					Set tRelComboKey = ""
					Set tItem = $O(pRelatedBranch(tBranch,tFact,""),1,tKey)
					While tItem'="" {
						Set tRelComboKey = tRelComboKey _ $S($L(tRelComboKey):"*",1:"") _ tKey
						Set tItem = $O(pRelatedBranch(tBranch,tFact,tItem),1,tKey)
					}
					Set tRelComboKey = ##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tRelComboKey)
					Set pLocalBranch(tBranch,$I(pLocalBranch(tBranch))) = $LB(tFact,tRelComboKey)
					Set tFact = $O(pRelatedBranch(tBranch,tFact))
				}
				Set tBranch = $O(pRelatedBranch(tBranch))
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// The raw collection of the slicer branches can produce branches that define logically null sets.
/// This removes those branches, and removes duplicate entries within a branch that would lead to
/// extra processing.
ClassMethod %CleanBranchesForSlicer(ByRef pSlicerBranches, pCube As %String = "") As %Status
{
	// Method added by DTB567
	Set tSC = $$$OK
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	
	Try {
		If '$D(pSlicerBranches) {
			// Do nothing and exit
			Quit
		}
		
		// Remove duplicate entries in a single branch.
		// Contradictory entries in an AND mean the whole branch is removed
		ZKill pSlicerBranches
		Set tOrBranchNo = $O(pSlicerBranches(""))
		While (tOrBranchNo'="") {
			Kill tAndBranch
			Merge tAndBranch = pSlicerBranches(tOrBranchNo)
			Kill pSlicerBranches(tOrBranchNo)
			Set tSC = ..%ReduceSlicerAndBranch(.tAndBranch,tCubeIndex)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			
			If +$G(tAndBranch) {
				Merge pSlicerBranches($I(pSlicerBranches)) = tAndBranch
			}

			Set tOrBranchNo = $O(pSlicerBranches(tOrBranchNo))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Examine the branch-representation of an AND within the slicer and reduce it to
/// the smallest number of logically separate elements. In this process, duplicate entries
/// of a single fact is removed, and contradictory intersections nullify the entire branch.
ClassMethod %ReduceSlicerAndBranch(ByRef pAndBranch, pCube As %String = "") As %Status [ Internal ]
{
	// Method added by DTB567
	Set tSC = $$$OK
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Try {
		If '$D(pAndBranch) {
			// Do nothing and exit
			Quit
		}
		
		Set tRemoveBranch = 0
		
		While ($O(pAndBranch(""))'="")&&'tRemoveBranch {
			// Keep going until we've visited everything
			
			Set tAndNo = $O(pAndBranch(""),1,tRefTerm)
			// We will always keep the term found here
			Kill pAndBranch(tAndNo)
			
			Set tRefFactNo = $LG(tRefTerm,1)
			Set tRefKey = $LG(tRefTerm,2)
			
			// Test for reasons *not* to keep this term in the cleaned AND branch
			If (tRefKey="NO MEMBER") {
				// DTB926 - This AND branch cannot have any data in it since one item is NO MEMBER
				Set tRemoveBranch = 1
				Quit
			}
			ElseIf ((tRefKey="!NO MEMBER") && ($D(tTempTree) || ($O(pAndBranch(tAndNo))'=""))) {
				// DP-407899 - A key of !NO MEMBER is the reference to the entire set, and so contributes nothing as a slicer.
				// - If anything else has accumulated in the temp tree, this will contribute nothing and can be ommited
				// - If nothing has accumulated yet, but there is more to be examined in pAndBranch, this does not need to be accumulated
				Continue
			}
			Else {
				// Move set here to only include the term if it hasn't been skipped
				Set tTempTree(tAndNo) = tRefTerm
			}
			
			// Search the rest of the branch for a match
			Set tAndNo = $O(pAndBranch(""),1,tAndTerm)
			While (tAndNo'="") {
				// Attempt to remove duplicate key entries. If conflicting keys are found, see if the entire
				// AND branch should be removed.
				Set tAndFactNo = $LG(tAndTerm,1)
				Set tAndKey = $LG(tAndTerm,2)
				
				If (tAndFactNo=tRefFactNo)&&(tRefKey'["@") {
					// Fact numbers match, check the key
					If (tAndKey=tRefKey) {
						// Keys match, remove duplicate
						Kill pAndBranch(tAndNo)
					}
					Else {
						// Keys do not match. Take a closer look
						Set tIsList = 0
						If ($E(tAndKey)="@") {
							// Relationships cannot behave like lists at this time
						}
						ElseIf (tAndFactNo=1) {
							// DTB567 (2) - Searchable measure term, the key is an index ID coresponding to the resolved term.
							// At this point the specific nature of the original comparison is not available, so treat all
							// of these terms as list-like.
							Set tIsList = 1
						}
						Else {
							// See if this is a list dimension
							Set tFactName = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact#",tAndFactNo))
							If (tFactName'="") {		// DTB567 (2) - Protect against a possible failure in lookup
								Set tDimNo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactName,"dimNo"),0)
								Set tHierNo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactName,"hierNo"),0)
								Set tLevelNo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactName,"levelNo"),0)
								Set tLevelNode = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
								
								Set tIsList = +$LG(tLevelNode,16)
							}
						}
						
						If ((tAndKey'["!")&&(tAndKey'["|") &&
							(tRefKey'["!")&&(tRefKey'["|")) {
							// The terms do not match and none of them are NOTs or ORs. This implies there are no possible
							// intersections, and this whole branch can be removed.
							Set:'$G(tIsList) tRemoveBranch = 1
							Quit		// While
						}
						Else {
							// Further processing is optional to attempt to reduce keys that are NOTs
							// or compact ORs.
						}
					}
				}

				Set tAndNo = $O(pAndBranch(tAndNo),1,tAndTerm)
			}
		}
		
		Kill pAndBranch
		If tRemoveBranch || '$D(tTempTree) {
			// DTB926 - Mark as NO MEMBER
			// DP-407899 - Also return a NO MEMBER if nothing has been accumulated in the tTempTree
			Set pAndBranch($I(pAndBranch)) = $LB(-1,"NO MEMBER")
		}
		Else {
			Set tIndex = $O(tTempTree(""))
			While (tIndex'="") {
				Set pAndBranch($I(pAndBranch)) = tTempTree(tIndex)
				Set tIndex = $O(tTempTree(tIndex))
			}
		}
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Reduce to minimal AND logic for the purposes of identifying global fact restrictions. 
/// This attempts to simplify the restriction terms by reducing a slicer tree<br>
/// pSlicerBranches(OrIndex,AndIndex)<br>
/// structure into a single OR branch. This produces the minimally restrictive representation of the slicer.
/// Note that this should not be used when calculating the final results, as it will throw away
/// some restrictions!
ClassMethod %ReduceOrsInSlicer(ByRef pSlicerBranches, pCube As %String = "") As %Status
{
	// Method added by DTB567
	Set tSC = $$$OK
	Try {
		// Need a clean representation of the branch structure
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tSC = ..%CleanBranchesForSlicer(.pSlicerBranches,tCubeIndex)
		If $$$ISERR(tSC) Quit
		
		While $D(pSlicerBranches)&&($O(pSlicerBranches(""))'="") {
			Set tRefOrNo = $O(pSlicerBranches(""))
			Set tRefAndNo = $O(pSlicerBranches(tRefOrNo,""),1,tRefNode)
			If (tRefAndNo="") {
				// If there are no entries left in this branch, it is not possible to find
				// any more entries to keep!
				Quit
			}
			Set tKeepRef = 1		// Assume we will keep this
			
			// Look at all the other OR branches for the same node
			Set tOrNo = $O(pSlicerBranches(tRefOrNo))
			While (tOrNo'="")&&tKeepRef {
				Set tAndNo = $O(pSlicerBranches(tOrNo,""),1,tAndNode)
				Set tFoundInBranch = 0
				While (tAndNo'="") {
					If (tAndNode=tRefNode) {
						Set tFoundInBranch = 1
						Kill pSlicerBranches(tOrNo,tAndNo)		// Remove this entry
					}
					
					Set tAndNo = $O(pSlicerBranches(tOrNo,tAndNo),1,tAndNode)
				}
				
				If 'tFoundInBranch {
					Set tKeepRef = 0
				}
				
				Set tOrNo = $O(pSlicerBranches(tOrNo))
			}
			
			// If the same term was found in all other nodes, then keep it
			If tKeepRef {
				Set tTempTree(1,$I(tTempTree(1))) = tRefNode
			}
			
			Kill pSlicerBranches(tRefOrNo,tRefAndNo)
		}
		
		Kill pSlicerBranches
		Merge pSlicerBranches = tTempTree
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the bit mask from the slicer for a given slicer branch and a given chunk.
/// <var>pCubeName</var> is the uppercase cubename.
ClassMethod %GetSlicerMask(pCubeIndex As %String, ByRef pMask As %Binary, ByRef pBranch, pBranchNo As %Integer = 0, pChunk As %Integer = 0, pSlotNo As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK

	// DP-413393 - Add timers and caching
	$$$dsSetLogging
	$$$dsStartTimer
	
	Try { 
		// Determine if the targeed chunk is the cube's active chunk. If so, it does not get cached.
		Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(pCubeIndex,,.tActiveChunk)
		If $$$ISERR(tSC) Quit
		Set tIsActiveChunk = (pChunk=tActiveChunk)

		If 'tIsActiveChunk && ($G(%slicerKey)'="") && $D(pBranch) &&
			$D($$$DeepSeeMaskGLVN(pCubeIndex,"slicerBranch",pSlotNo,%slicerKey,pBranchNo,pChunk),pMask) {
			$$$dsGloCacheRead("slicerBranch")
			Quit
		}

		// This operates on a single branch of the overall slicer's 
		Set tAndBranchItem = $O(pBranch(pBranchNo,""),1,data)
		While (tAndBranchItem '= "") {
			Set tFact = $LG(data,1)			// Fact ID for looking up in the index global
			Set tNodeKey = $LG(data,2)		// Complete "mbr" key as filed in the axis node. Could be a single member or a homogeneous %OR "|"-delimited key
			If ((tFact'="")&&(tNodeKey'="")) {
				// test for OR and NOT in tNodeKey
				// The mask for this OR can be accumulated in one pass as long as
				// the incoming mask is preserved throughout the loop over "|" pieces. This gets
				// accumulated in the tTempOrMask and replaces the tMask when the loop is complete.	
				Set tTempOrMask = ""
				For tKeyPos=1:1:$L(tNodeKey,"|") {
					Set tKey = $P(tNodeKey,"|",tKeyPos)
					If ('$D(pMask)) {
						// No mask exists yet. Directly fold the key mask into the current key accumulation
						Set tNot = 0
						If ($E(tKey)="!") {
							Set tNot = 1,tKey = $E(tKey,2,*)
						}
						If (tNot) {
							Set:'$D(tChunkExtentBits) tChunkExtentBits = $$$DeepSeeIndexGLVN(pCubeIndex,"$Fact",pChunk)
							$$$dsBitLogicArbitraryList(tTempOrMask|(tChunkExtentBits&~$$$DeepSeeIndexGLVN(pCubeIndex,tFact,tKey,pChunk)),tTempOrMask,"BitAND,BitOR")
						}
						Else {
							$$$dsBitAorBIntoA(tTempOrMask,$$$DeepSeeIndexGLVN(pCubeIndex,tFact,tKey,pChunk))
						}
					}
					Else {
						// There is a mask defined. And it with the current individual key mask and fold it into the current key accumulation 
						Set tNot = 0
						If ($E(tKey)="!") {
							Set tNot = 1,tKey = $E(tKey,2,*)
						}
						If (tNot) {
							$$$dsBitLogicArbitraryList(tTempOrMask|(pMask&~$$$DeepSeeIndexGLVN(pCubeIndex,tFact,tKey,pChunk)),tTempOrMask,"BitAND,BitOR")
						}
						Else {
							$$$dsBitLogicArbitraryList(tTempOrMask|(pMask&$$$DeepSeeIndexGLVN(pCubeIndex,tFact,tKey,pChunk)),tTempOrMask,"BitAND,BitOR")
						}
					}
				} // tKeyPos - key "|" pieces

				Set pMask = tTempOrMask
				
				$$$dsBitFind(pMask,1,tTestBit)
				If 'tTestBit {
					// This method returns a non-existent mask rather than a null string to support $D tests that are used on the by-ref variable.
					Kill pMask
					Quit
				}
			}

			Set tAndBranchItem = $O(pBranch(pBranchNo,tAndBranchItem),1,data)
		} // tAndBranchItem

		// Store this mask in the cache if it applies to a completed (non-active) chunk.
		If 'tIsActiveChunk && ($G(pMask)'="") {
			$$$dsGloCacheSet("slicerBranch")
			Set $$$DeepSeeMaskGLVN(pCubeIndex,"slicerBranch",pSlotNo,%slicerKey,pBranchNo,pChunk) = pMask
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	$$$dsStopTimer
	Quit tSC
}

/// For a given query, resolve currentMember references.
/// This means looking at all other axes and applying the CurrentMember
/// expression to every case where the current member appears.
ClassMethod %ResolveCurrentMembers(pCube As %String, pKey As %String, pQuery As %DeepSee.Query.query) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		// See which axes have current member references
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		Set tHasCmbr = 0

		// DTB400 - Look at which axes have current members
		For a=1:1:3 {
			Set tHasCmbr(a) = $D($$$DeepSeeAxisGLVN(tCubeIndex,$S($G(tAxisKey(a))="":"*",1:tAxisKey(a)),"axes",1,"cmbr"))
		}
		
		// DTB400 - Walk through cmbr
		Set tAddr(1) = $S((tSlicerAxis=1)||($G(tAxisKey(1))=""):0,1:$O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(1),"axes",1,$S(tHasCmbr(1):"cmbr",1:"all"),"")))
		While (tAddr(1)'="") {
			Set tAddr(2) = $S((tSlicerAxis=2)||($G(tAxisKey(2))=""):0,1:$O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(2),"axes",1,$S(tHasCmbr(2):"cmbr",1:"all"),"")))
			While (tAddr(2)'="") {
				Set tAddr(3) = $S((tSlicerAxis=3)||($G(tAxisKey(3))=""):0,1:$O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(3),"axes",1,$S(tHasCmbr(3):"cmbr",1:"all"),"")))
				While (tAddr(3)'="") {
					// see if there is a cmbr along *any* axis
					Kill tMap
					Set:$D($$$DeepSeeAxisGLVN(tCubeIndex,$S($G(tAxisKey(1))="":"*",1:tAxisKey(1)),"axes",1,"cmbr",tAddr(1))) tMap(1) = ""
					Set:$D($$$DeepSeeAxisGLVN(tCubeIndex,$S($G(tAxisKey(2))="":"*",1:tAxisKey(2)),"axes",1,"cmbr",tAddr(2))) tMap(2) = ""
					Set:$D($$$DeepSeeAxisGLVN(tCubeIndex,$S($G(tAxisKey(3))="":"*",1:tAxisKey(3)),"axes",1,"cmbr",tAddr(3))) tMap(3) = ""
					If $D(tMap) {
						Set tSC = ..%ProcessOneCurrentMember(pCube,pKey,pQuery,.tAddr,.tMap,tSlicerAxis)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DP-402439 - Do not swallow this error
					}
					Set tAddr(3) = $S(($G(tAxisKey(3))=""):"",1:$O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(3),"axes",1,$S(tHasCmbr(3):"cmbr",1:"all"),tAddr(3))))
				}
				Set tAddr(2) = $S(($G(tAxisKey(2))=""):"",1:$O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(2),"axes",1,$S(tHasCmbr(2):"cmbr",1:"all"),tAddr(2))))
			}
			Set tAddr(1) = $S(($G(tAxisKey(1))=""):"",1:$O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(1),"axes",1,$S(tHasCmbr(1):"cmbr",1:"all"),tAddr(1))))
		}
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Process current member information for one cell.
ClassMethod %ProcessOneCurrentMember(pCube As %String, pKey As %String, pQuery As %DeepSee.Query.query, ByRef pAddr, ByRef pMap, pSlicerAxis As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)

		// pMap tells us which axis has a cmbr reference
		// there may be more than one!
		Set tCMbrAxis = $O(pMap(""))
		While (tCMbrAxis'="") {
			If $$$ISERR(tSC) Quit

			// find info on the cmbr
			// n.b. this info node is created in memberFunction.FXCurrentMember
			Set tCMbrNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tCMbrAxis),"axes",pAddr(tCMbrAxis)))

			// wrapper is expression with one or more $$CMBRn$$ tokens in it
			Set tWrapper = $LG(tCMbrNodeInfo,17)
			Set tOptimizedWrapper = $C(0)

			// Set tRelSpec = $LG(tCMbrNodeInfo,18) // !!! not used
			Kill tContextAxisNo,tContextNode,tContextNodeNo

			// visit each cmbr ($$CMBRn$$) in the cmbrIndex for this axis
			// cmbrIndex is built by axis.%ProcessAxes
			Set tCMbrIndex = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tCMbrAxis),"cmbrIndex",""),1,tCMbrIndexInfo)
			While (tCMbrIndex'="") {
				If $$$ISERR(tSC) Quit
				Set tCurrentSpec = $LG(tCMbrIndexInfo,1)
				Set tCurrentDim = $LG(tCMbrIndexInfo,2)
				Set tCurrentHier = $LG(tCMbrIndexInfo,3)
				Set tCurrentRelSpec = $LG(tCMbrIndexInfo,5)

				Kill tRelSpecInfo
				Set tRDimNo = 0
				If (tCurrentRelSpec'="") {
					// parse full spec (used for comparison)
					Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tCurrentSpec,.tSpecInfo,.tQuoted)
					If $$$ISERR(tSC) Quit

					// get dim# of this relationship
					Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tCurrentRelSpec,.tRelSpecInfo,.tQuoted)
					If $$$ISERR(tSC) Quit

					Set tRDim = $G(tRelSpecInfo(1))
					Set tRDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbrs",tRDim))
					Set tRDimNo = +$LG(tRDimInfo,1)
					
					// PFS076 - We only need the related dim for the current cube, the node spec will contain the rest of the relationship references already
					Set tCurrentRelSpec = "[" _ $$$dsEscapeIdent(tRDim) _ "]"
				}

				// look at each (of the first 3) axes and try to find a match
				Set tFound = 0
				For b = 1:1:tTotalAxisCount {
					If (b '= tSlicerAxis) {
						Set tNodeNo = $G(pAddr(b))
						If (tNodeNo'="") {
							Set tCheckNodeNo = tNodeNo
							While ('tFound && (tCheckNodeNo'="")) {
								// look at node and it's parents in turn
								// (the context node could be within a tuple)
								Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(b),"axes",tCheckNodeNo))

								If (tCurrentRelSpec'="") {
									// relationship
									Set tDimNo = $LG(tNodeInfo,9)
									If (($LG(tNodeInfo,1)'="cmbr")&&(tNodeInfo'="")&&(tRDimNo'="")&&(tDimNo = tRDimNo)) {
										Set tRelSpec = $$$UPPER($LG(tNodeInfo,14))
										// same relation, make sure specs match
										If ((tCurrentRelSpec_"."_tRelSpec)[tCurrentSpec) {
											Set tFound = 1
											Set tContextAxisNo(tCMbrIndex) = b
											Set tContextNodeNo(tCMbrIndex) = tCheckNodeNo
											Set tContextNode(tCMbrIndex) = tNodeInfo
										}
									}
								}
								Else {
									Set tDimNo = $LG(tNodeInfo,9)
									Set tHierNo = $LG(tNodeInfo,10)
									If (($LG(tNodeInfo,1)'="cmbr")&&(tNodeInfo'="")&&(tDimNo'="")&&(tDimNo = tCurrentDim)&&(tHierNo'="")&&(tHierNo = tCurrentHier)) {
										Set tFound = 1
										Set tContextAxisNo(tCMbrIndex) = b
										Set tContextNodeNo(tCMbrIndex) = tCheckNodeNo
										Set tContextNode(tCMbrIndex) = tNodeInfo
									}
								}
								Set tCheckNodeNo = $LG(tNodeInfo,4)	// parent
							} // next parent
						}
					}
				}  // for b
				If ('tFound) {
					// axis # is 0 for unresolved items
					Set tContextAxisNo(tCMbrIndex) = $LB(0,0)
					// this is a special value: $LB(spec,dim,hier,level) of default member
					Set tContextNode(tCMbrIndex) = tCMbrIndexInfo
				}

				// next index
				Set tCMbrIndex = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tCMbrAxis),"cmbrIndex",tCMbrIndex),1,tCMbrIndexInfo)
			}

			// plug resolved values into wrapper
			Kill tReferencedNodes
			Set rk = $O(tContextNode(""))
			While (rk'="") {
				If $$$ISERR(tSC) Quit
				Set tContextAxis = +$G(tContextAxisNo(rk))
				If (tContextAxis=0) {
					// unresolved reference
					Set tRkNode = tContextNode(rk)
					Set tDimNo = $LG(tRkNode,2)
					Set tHierNo = $LG(tRkNode,3)
					Set tLevelNo = $LG(tRkNode,4)
					Set tURelSpec = $LG(tRkNode,5)
					If (tURelSpec="") {
						Set:((tDimNo'=0)&&(tLevelNo=0)) tLevelNo = 1		// get all level
						Set tKey = ""
						Set tFact = ""
					}
					Else {
						// unresolved cmbr in relationship
						Set tDimNo = tRDimNo
						Set tHierNo = 0
						Set tLevelNo = 0
						Set tKey = ""
						Set tFact = ""
					}
				}
				Else {
					Set tRkNode = tContextNode(rk)
					Set tDimNo = $LG(tRkNode,9)
					Set tHierNo = $LG(tRkNode,10)
					Set tLevelNo = $LG(tRkNode,11)
					Set tKey = $LG(tRkNode,13)
 					Set tFact = $LG(tRkNode,7)
					Set tID = $LG(tRkNode,6)

					// remember so that we can ignore this node later!
					Set tReferencedNodes(tContextAxis,tContextNodeNo(rk)) = ""
				}

				// test for non-mbr node
				If ((tDimNo'="")&&(tHierNo'="")&&(tLevelNo'="")) {
					Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
					Set tLevelType = $LG(tLevelInfo,1)
					Set tDimName = $LG(tLevelInfo,2)
					Set tHierName = $LG(tLevelInfo,3)
					Set tLevelName = $LG(tLevelInfo,4)
					If (tLevelType = "r") {
						// relationship
						Set tSpec = "["_tDimName_"]"
						Set tRefSpec = $LG(tRkNode,14) // remote spec
						If (tRefSpec="") {
							// unresolved
							Set tSpec = $LG(tRkNode,1)
						}
						Else {
							Kill tTestSpecInfo
							Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tRefSpec,.tRefSpecInfo,.tQuoted)
							If $$$ISERR(tSC) Quit
							
							// PFS083 - Since this is related, we need more spec context than just first 3 nodes
							// Skip last node since it will be the key and it will be added after
							Set tLast = $O(tRefSpecInfo(""),-1)
							Set tCurr = $O(tRefSpecInfo(""))
							While (tCurr'=tLast) {
								Set tSpec = tSpec _ ".[" _ tRefSpecInfo(tCurr) _ "]"
								Set tCurr = $O(tRefSpecInfo(tCurr))
							}
						}
						If (tKey'="") {
							Set tSpec = tSpec _ ".&[" _ tKey _ "]"
						}
						Else {
							// Find "No Relation" reference
							// JMD976: always use <null>
							Set tSpec = "["_tDimName_"].&[" _ "<null>" _ "]"

							// JMD976.3 test for <null>.Properties
							Set tTest = $$$UPPER($Replace(tWrapper,rk,""))
							If ($E(tTest,1,12)=".PROPERTIES(") {
								// return null in this case
								Set tOptimizedWrapper = ""
							}
						}
					}
					Else {
						Set tSpec = "["_tDimName_"]"
						Set:tHierName'="" tSpec = tSpec _ ".["_tHierName_"]"

						// for measures, there is no level
						Set:tLevelName'="" tSpec = tSpec _ ".["_tLevelName_"]"

						If ((tLevelName'="") && (tLevelType '= "all")) {
							If (tKey'="") {
								Set:tKey'="" tSpec = tSpec _ ".&[" _ tKey _ "]"
							}
						}
					}
				}

				// JMD741
				// optimization
				// it is very common to use CurrentMember.properties(xxx)
				// detect this simple case and resolve it without a subquery
				// n.b., for relationships, levelNo will be 0 and the optimization is skipped.
				// JMD743
				// Skip optimization for intrinsic properties
				Set tPropertyOptimize = 1
				If (tPropertyOptimize&&(tOptimizedWrapper=$C(0))) {
					Set tTest = $Replace(tWrapper,rk,"")
					If ((tSpec'="")&&($$$UPPER($E(tTest,1,12))=".PROPERTIES(")) {
						// JMD1373 pull apart args for PROPERTIES; preserve case
						Set tTest = $E(tTest,13,$L(tTest))
						Kill tPArgs, tPTypes
						Set tPArgNo = 0
						Set tPState = 1
						Set tPArg = ""
						For t = 1:1:$L(tTest) {
							Set ch = $E(tTest,t)
							If (tPState = 1) {
								// start
								If (ch="""") {
									Set tPState = 2
								}
								ElseIf (ch=",") {
									Set tPArgNo = tPArgNo + 1
									Set tPArgs(tPArgNo) = ""
									Set tPTypes(tPArgNo) = ""
									Set tPArg = ""
								}
								ElseIf (ch=")") {
									Quit
								}
								Else {
									Set tPArg = ch
									Set tPState = 3
								}
							}
							ElseIf (tPState = 2) {
								// "string"
								If (ch="""") {
									Set tPArgNo = tPArgNo + 1
									Set tPArgs(tPArgNo) = tPArg
									Set tPTypes(tPArgNo) = "string"
									Set tPArg = ""
									Set tPState = 5
								}
								Else {
									Set tPArg = tPArg_ch
								}
							}
							ElseIf (tPState = 3) {
								// ident/flag
								If ((ch=",")||(ch=")")) {
									Set tPArgNo = tPArgNo + 1
									Set tPArgs(tPArgNo) = tPArg
									Set tPTypes(tPArgNo) = "ident"
									Set tPArg = ""
									Set tPState = 1
								}
								Else {
									Set tPArg = tPArg_ch
								}
							}
							ElseIf (tPState = 5) {
								// comma after "string"
								If ((ch=",")||(ch=")")) {
									Set tPState = 1
								}
							}
						}
						Set tPropName = $G(tPArgs(1))
						// check for invalid arguments
						If ((tPropName="")||($G(tPTypes(1))'="string")||(tPArgNo>3)) {
							Set tOptimizedWrapper = "@PROPERTY"
						}
						Else {
							If ((+tLevelNo>0)&&(",ID,KEY,NAME,MEMBER_NAME,CAPTION,CUBE_NAME,LEVEL_NUMBER,LEVEL,HIERARCHY,DIMENSION,LEVEL_CAPTION,DIMENSION_CAPTION,HIERARCHY_CAPTION,"'[(","_$$$UPPER(tPropName)_","))) {
								// get property value from cube
								Kill tLocalSet
								If ($G(tID)'="") {
									Set tSC = ##class(%DeepSee.Query.memberData).%GetPropertyValue(tCubeIndex,tDimNo,tHierNo,tLevelNo,tPropName,-1,.tLocalSet,tID)
									If $D(tLocalSet(1)) {
										Set tOptimizedWrapper = $LG(tLocalSet(1),6)
										
										// JMD1373 Check for default value
										If ($D(tPArgs(2))&&(tOptimizedWrapper="@NOPROPERTY")) {
											Set tOptimizedWrapper = $G(tPArgs(2))
										}

										// JMD909
										Set tLitFormat  = $LG(tLocalSet(1),12)
									}
								}
							}
						}
					}
				}

				// replace CMBR marker with resolved spec
				Set tWrapper = $Replace(tWrapper,rk,tSpec)

				// next resolved item
				Set rk = $O(tContextNode(rk))
			}

			If (tOptimizedWrapper'=$C(0)) {
				// get value directly: skip subquery
				Set tInfoNode = $LB("lit",1,1,$LG(tCMbrNodeInfo,4),,tOptimizedWrapper)

				// JMD874: pass on visible and calculate flags
				Set $List(tInfoNode,2) = $LG(tCMbrNodeInfo,2)
				Set $List(tInfoNode,3) = $LG(tCMbrNodeInfo,3)

				Set $List(tInfoNode,4) = $LG(tCMbrNodeInfo,4)
				Set $List(tInfoNode,5) = $LG(tCMbrNodeInfo,5)
				Set $List(tInfoNode,7) = $LG(tCMbrNodeInfo,7)
				Set $List(tInfoNode,8) = $LG(tCMbrNodeInfo,8)
				Set $List(tInfoNode,15) = $LG(tCMbrNodeInfo,15)
				Set $List(tInfoNode,16) = $LG(tCMbrNodeInfo,16,"SUM")
				Set $List(tInfoNode,19) = $LG(tCMbrNodeInfo,19)
				Set $List(tInfoNode,20) = $LG(tCMbrNodeInfo,20)
				Set $List(tInfoNode,21) = $LG(tCMbrNodeInfo,21)	// literal value

				// JMD909: pick up format
				Set $List(tInfoNode,12) = $G(tLitFormat)
			}
			Else {
				// find out more about context of the original cmbr node
				// we may need to add context to the subquery
				Set tFilterSpec = ""
				Set tFilterClause = ""
				Set tFilterCount = 0
				Set tTestNodeNo = $LG(tCMbrNodeInfo,4)
				While (tTestNodeNo'="") {
					Set tSpec = ""
					Set tTestNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tCMbrAxis),"axes",tTestNodeNo))
					If ($LG(tTestNode,1)="mbr") {
						// add to context
						Set tDimNo = $LG(tTestNode,9)
						Set tHierNo = $LG(tTestNode,10)
						Set tLevelNo = $LG(tTestNode,11)
						Set tKey = $LG(tTestNode,13)
						Set tID = $LG(tTestNode,6)
	 					Set tFact = +$LG(tTestNode,7)
						If ((tDimNo'="")&&(tHierNo'="")&&(tLevelNo'="")) {
							Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
							Set tLevelType = $LG(tLevelInfo,1)
							Set tDimName = $LG(tLevelInfo,2)
							Set tHierName = $LG(tLevelInfo,3)
							Set tLevelName = $LG(tLevelInfo,4)
							If (tLevelType = "r") {
								// relationship
								Set tSpec = "["_tDimName_"]"
								Set tRef = $LG(tTestNode,14)		// DTB062
								Set:tRef'="" tSpec = tSpec _ "."_tRef
							}
							Else {
								Set tSpec = "["_tDimName_"]"
								Set:tHierName'="" tSpec = tSpec _ ".["_tHierName_"]"
								Set:tLevelName'="" tSpec = tSpec _ ".["_tLevelName_"]"
								If ((tLevelName'="") && (tLevelType '= "all")) {
									If (tKey'="") {
										Set:tKey'="" tSpec = tSpec _ ".&[" _ tKey _ "]"
									}
								}
								If ((tFact>0)&&(tID'="")) {
									Set $List(tFilterSpec,tFact) = tID
								}
							}
						}
					}
					If (tSpec'="") {
						Set tFilterCount = tFilterCount + 1
						Set tFilterClause = tFilterClause _ $S(tFilterClause'="":",",1:"") _ tSpec
					}
					Set tTestNodeNo = $LG(tTestNode,4)
				}
				
				//+PFS040 - Use modified version of SetContext function here to create cell spec and incorporate %ORs
				// number of fact properties in cube
				Set tFactCount = $G($$$DeepSeeMetaGLVN("cubes",pCube,"factCount"))
				// construct base spec
				// this is a $List with "" defined for each fact
				// plus an initial slot (reserved for future use)
				// if there is a filterSpec fold it into the base spec
				Set tBaseSpec = $LB("")
				For n = 1:1:tFactCount {
					Set tBaseSpec = tBaseSpec _ $LB("")
				}
				
				// JMD1453: check for "orset";
				Set tInOR = 0
				Set tInORtuple = 0		// "ortuple": tuple as leg of OR

				// list of "orsets", by OR and branch within OR
				Set tORSetNo = 0
				Kill tORList
				
				// build chain of nodes back up to the top
				Set tLevelCount = 1
				Set tChain(tLevelCount) = $LG(tCMbrNodeInfo,4)
				Set tChainNode(tLevelCount) = tCMbrNodeInfo
				If ($LG(tCMbrNodeInfo,1)="lit") {
					Set:'$D(tLiteral) tLiteral = $LG(tCMbrNodeInfo,6)
				}

				Set tParentNo = $LG(tCMbrNodeInfo,4)
				While (tParentNo '= "") {
					Set tLevelCount = tLevelCount + 1
					Set tChain(tLevelCount) = tParentNo
					Set tParentNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tCMbrAxis),"axes",tParentNo))
					If ($LG(tParentNode,1)="lit") {
						Set:'$D(tLiteral) tLiteral = $LG(tParentNode,6)
					}
					Set tNewParentNo = $LG(tParentNode,4)

					Set tChainNode(tLevelCount) = tParentNode
					If (tParentNo = tNewParentNo) {
						// cycle: should not happen
						Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Internal error: Cycle detected in axis"))
					}
					Set tParentNo = tNewParentNo
				}

				// build stacks of node info from top down
				Set tLevel = 0
				For nn = tLevelCount:-1:1 {
					Set tLevel = tLevel + 1
					Set tStackNo(tLevel) = tChain(nn)
					Set tStackNode(tLevel) = tChainNode(nn)
					Set tSNode = tStackNode(tLevel)
					Set tSType = $LG(tSNode,1)
					Set tSKey = $LG(tSNode,6)
					Set tSFact = $LG(tSNode,7)

					Set tStackSpec(tLevel) = $G(tStackSpec(tLevel-1),tBaseSpec)
					
					If (tSType = "orset") {
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
					} ElseIf ((tSType'="msr")&&(tSType'="lit")&&(tSType'="exp")) {
						// set spec for this level
						If (tSType '= "cmbr") {
							If ((tSFact'="")&&(tSKey'="")) {
								If (tInOR) {
									If (tInORtuple) {
										// JMD1453: add to current ortuple
										Set ox = $G(tORList(tORSetNo))
										Set:ox="" ox = $I(tORList(tORSetNo))
										Set tORList(tORSetNo,ox) = ##class(Engine2).%CombineSpecs(tFactCount,$G(tORList(tORSetNo,ox)),##class(Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tLevel),tSFact,tSKey))
									}
									Else {
										// JMD1453: accumulate OR spec
										Set ox = $I(tORList(tORSetNo))
										Set tORList(tORSetNo,ox) = ##class(Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tLevel),tSFact,tSKey)
									}
								} else {
									// JMD1453
									Set tStackSpec(tLevel) = ##class(Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tLevel),tSFact,tSKey)
								}
							}
						}
					}
					
					Set tFilterSpec = $G(tStackSpec(tLevel))
					
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
							Set tFilterSpec = ##class(Engine2).%CombineSpecs(tFactCount,tFilterSpec,tORSpec)
						}
						Set oc = $O(tORList(oc))
					}
				} // For nn
				//-PFS040

				// add context filter to subquery
				Set tFILTER = ""
				If (tFilterCount = 1) {
					Set tFILTER = " %FILTER " _ tFilterClause
				}
				ELseIf (tFilterCount > 1) {
					// make a tuple
					Set tFILTER = " %FILTER (" _ tFilterClause _ ")"
				}

				// execute the wrapper expression and place results into map
				// determine if *this* axis is the slicer
				Set tIsSlicer = (pSlicerAxis=tCMbrAxis)

				If (tWrapper="") {
					Set tSELECT = "[%SEARCH] ON 0 "
				}
				Else {
					Set tSELECT = tWrapper_" ON 0 "
				}
				Set tMDX = "SELECT "_tSELECT_"FROM " _ "["_pQuery.cube_"]"
				If (('tIsSlicer)&&$IsObject(pQuery.slicer)) {
					Set tWHERE = pQuery.slicer.%ToString()
					If (tWHERE["$$CMBR") {
						// n.b. ignore slicer if it has an unresolved CMBR in it
						Set tWHERE = ""
					}
					Set:tWHERE'="" tWHERE = " WHERE " _ tWHERE
					Set tMDX = tMDX _ tWHERE
				}
				Set tMDX = tMDX _ tFILTER
				If +$G(%dsflags("CMBR")) {
					$$$DSWRITELN(">>> CURRENTMEMBER  "_tMDX)
				}

				// Create a resultSet for the query
				Set tSC = pQuery.%CreateSubQueryResultSet(tMDX,.tRS)
				If $$$ISERR(tSC) Quit

				// n.b. It would be better to only execute the *axes* of this
				// query and NOT generate the results, but that might mess up Filter etc.

				Kill tParmValue
				If (pQuery.useAgents) {		// DTB704 - Only test useAgents
					Set tSC = tRS.%ExecuteAsynch(.tQK,.tParmValues,1)
				}
				Else {
					Set tSC = tRS.%Execute(.tParmValues)
				}

				// JMD1324: if we are processing a node with no key
				// (such as the parent SUM node), then it is ok to return here
				If (tKey="")&&$$$ISERR(tSC) Quit

				If $$$ISERR(tSC) {
					// JMD1302: handle error in subquery
					// (such as CurrentMember.PrevMember.Properties() where there is no prev member)
					// easy way is to change the subquery to return a literal
					Set tMDX = "SELECT """" ON 0 FROM " _ "["_pQuery.cube_"]"

					Set tSC = pQuery.%CreateSubQueryResultSet(tMDX,.tRS)
					If $$$ISERR(tSC) Quit
					Set tSC = tRS.%Execute(.tParmValues)
					If $$$ISERR(tSC) Quit
				}

				// now find the axis containing the results of the query!
				Set tLocalQueryKey = tRS.%GetQueryKey()
				Set tLocalKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,tLocalQueryKey,"axis",1))
				
				// If CurrentMember resolves to a single member
				// we insert an alias in the result cache that points to this member
				// if currentMember resolves to a set, we turn it into
				// an aggregate expression over the set (SUM by default)
				// or use aggregate function is in play

				// resolve each leaf node of the temp results and place into results cache
				Set tIsAll = 0
				If (tLocalKey="") {
					Set tSC = $$$ERROR($$$GeneralError,"Internal error in ProcessOneCurrentMember")
					Quit
				}
				Else {
					//W "RESULTS:",!
					//ZW $$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey)

					Set tLeafCount = 0
					Set tHasAgg = 0
					Set tAggType = ""
					Set tLiteral = ""
					Set tLeafNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",""))
					While (tLeafNodeNo'="") {
						Set tLeafNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",tLeafNodeNo))
						Set tLeafType = $LG(tLeafNode,1)
						If ((tLeafType="agg")) {
							Set tHasAgg = 1
							Set tAggType = $LG(tLeafNode,6)
							// special case(s)
							If (tAggType="%DISTINCT") {
								// pull answer out of query
								// treat as literal
								Set tHasAgg = 0
								Set tLiteral = tRS.%GetOrdinalValue(1,1)
							}
							ElseIf ((tAggType="%MDX")||(tAggType="%KPI")) {
								Set tAggOpFlag = $LG(tLeafNode,7)
								Set tAggOpValue = $LG(tLeafNode,8)
							}
						}
						ElseIf ((tLeafType="mbr")) {
							// compute cell spec
							Set tSC = ..%ComputeCMbrCellSpec(.tCellSpec,.tCellMsr,.tCellAgg,.tCellMsrScale,.tCellMsrType,pCube,pKey,.pAddr,tCMbrAxis,tCubeIndex,tLocalKey,tLeafNodeNo,.tReferencedNodes,tIsSlicer,tFilterSpec)
							If $$$ISERR(tSC) Quit
							If (($G(tCellSpec)'="")&&$ListValid(tCellSpec)) {
								Set tLeafCount = tLeafCount + 1
								Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(pAddr(1)),+$G(pAddr(2)),+$G(pAddr(3)),tLeafNodeNo) = tCellSpec
								// JMD1488 we need to track the agg/msr for the child cell separately
								// from the parent agg node
								If ((tCellAgg'="")||(tCellMsr'="")) {
									Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(pAddr(1)),+$G(pAddr(2)),+$G(pAddr(3)),tLeafNodeNo,"agg") = $LB(tCellAgg,tCellMsr,tCellMsrScale,tCellMsrType)
								}
								
								// JMD763
								If (tCellMsr'="") {
									Set $List(tCMbrNodeInfo,15) = tCellMsr
									Set $List(tCMbrNodeInfo,19) = tCellMsrScale
									Set $List(tCMbrNodeInfo,20) = tCellMsrType
								}
								If ((tCellAgg'="")&&(tCellAgg'="SUM")) {
									Set $List(tCMbrNodeInfo,16) = tCellAgg
								}
							}
							Else {
								Set tLiteral = tCellSpec
								Quit
							}
						}
						ElseIf (tLeafType="lit") {
							If ((tAggType="%MDX")||(tAggType="%KPI")) {
								// parameters to function are placed as literal children
								Set tLeafCount = tLeafCount + 1
								Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(pAddr(1)),+$G(pAddr(2)),+$G(pAddr(3)),tLeafNodeNo) = tLeafNode
							}
							ElseIf ('tHasAgg) {
								Set tLiteral = $LG(tLeafNode,6)
							}
						}
						Set tLeafNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tLocalKey,"axes",1,"all",tLeafNodeNo))
					}
					If $$$ISERR(tSC) Quit
				}

				// place an info node in the map
				If (tIsAll) {
					Set tInfoNode = $LB("mbr",,1,1,$LG(tCMbrNodeInfo,4))
				}
				ElseIf (((tLiteral'="")||(tLeafCount=0))&&'tHasAgg) {
					Set tInfoNode = $LB("lit",1,1,$LG(tCMbrNodeInfo,4),,tLiteral)
				}
				Else {
					// Note: literals must be treated as aggs or they will not get counted correctly
					Set tType = $S(tHasAgg||(tLeafCount>1)||($LG(tCMbrNodeInfo,21)'=""):"agg",1:"mbr")
					Set tInfoNode = $LB(tType,1,1,1)
					Set $List(tInfoNode,4) = $LG(tCMbrNodeInfo,4)
					Set $List(tInfoNode,5) = $LG(tCMbrNodeInfo,5)
					Set $List(tInfoNode,7) = $LG(tCMbrNodeInfo,7)
					Set $List(tInfoNode,8) = $LG(tCMbrNodeInfo,8)
					Set $List(tInfoNode,15) = $LG(tCMbrNodeInfo,15)
					Set $List(tInfoNode,16) = $LG(tCMbrNodeInfo,16,"SUM")
					Set $List(tInfoNode,19) = $LG(tCMbrNodeInfo,19)
					Set $List(tInfoNode,20) = $LG(tCMbrNodeInfo,20)
					Set $List(tInfoNode,21) = $LG(tCMbrNodeInfo,21)	// literal value

					// JMD1488 pick up correct agg type for parent agg
					If (tHasAgg) {
						// DP-402439 - Do not nullify slot 15 (function metric), it reverts the measure to 
						// the default %COUNT!
						Set $List(tInfoNode,16) = tAggType
					}

					If ((tAggType="%MDX")||(tAggType="%KPI")) {
						Set $List(tInfoNode,7) = $G(tAggOpFlag)
						Set $List(tInfoNode,8) = $G(tAggOpValue)
					}
				}
			} // subquery
			
			// DTB062 - remember which axis this CMBR came from
			Set $List(tInfoNode,23) = $LB(tCMbrAxis,tAxisKey(tCMbrAxis))
			
			Merge tAddr = pAddr		// DTB400 - Remember which aggregate this current member came from
				
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"cmbrMap",+$G(pAddr(1)),+$G(pAddr(2)),+$G(pAddr(3))) = tInfoNode
			
			// can we look at another axis? (don't bother)
			Quit
			Set tCMbrAxis = $O(pMap(tCMbrAxis))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Compute a cell spec for one node within a current member cell (pAddr).
ClassMethod %ComputeCMbrCellSpec(Output pCellSpec, Output pMsr, Output pCellAgg, Output pCellMsrScale, Output pCellMsrType, pCube As %String, pKey As %String, ByRef pAddr, pCMbrAxis, pCMbrCubeIndex, pLocalKey, pLeafNodeNo, ByRef pReferencedNodes, pIsSlicer As %Boolean = 0, pFilterSpec As %List = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pCellSpec
		Set pMsr = ""
		Set pCellAgg = ""
		Set pCellMsrScale = ""
		Set pCellMsrType = ""
		Set tCubeIndex = $$$DeepSeeIndex(pCube)

		// number of fact properties in cube
		Set tFactCount = $G($$$DeepSeeMetaGLVN("cubes",pCube,"factCount"))
		// JMD1453
		If (tFactCount="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube must be recompiled")
			Quit
		}

		Set tIsDrillThru = 0

		// construct base spec
		// this is a $List with "" defined for each fact
		// plus an initial slot (reserved for future use)
		// if there is a filterSpec fold it into the base spec
		// PFS040 - Use pFilterSpec if it is populated, start at n=2 since tBaseSpec is initialized as $LB("")
		Set tBaseSpec = $LB("")
		For n = 2:1:$Select($LL(pFilterSpec)>tFactCount:$LL(pFilterSpec),1:tFactCount+1) {
			Set tBaseSpec = tBaseSpec _ $LB($LG(pFilterSpec,n))
		}

		// Find axes
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		If (tTotalAxisCount = 0) {
			Quit
		}

		// pretend there are 3 axes
		For a=1:1:3 {
			If (a = pCMbrAxis) {
				Set tNodeNo(a) = pLeafNodeNo
				Set tNode(a) = $G($$$DeepSeeAxisGLVN(pCMbrCubeIndex,pLocalKey,"axes",pLeafNodeNo))
			}
			Else {
				// JMD1488 also look at slicer to pick up msrs
				Set tNodeNo(a) = +$G(pAddr(a))
				Set tNode(a) = $G($$$DeepSeeAxisGLVN(tCubeIndex,$G(tAxisKey(a),"*"),"axes",+$G(pAddr(a))))
			}
		}
		Set tCellSpec = tBaseSpec
		Set tHasSkip = 0
		Kill tValue
		Kill tLiteral
		Kill tCMbrSet

		// recreate facts for this cell using the substitute node and ignoring
		// the node supplying the reference
		// for slicer, do NOT ignore supplying node
		// the SubstAxis is the axis with the CMBR in it
		Kill tSpec
		Kill tLiteral
		For tAxis=1:1:3 {
			If ($G(tNode(tAxis))'="") {
				Set tSpec(tAxis) = tBaseSpec
				
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
				If ('pIsSlicer&&(tAxis'=pCMbrAxis)&&$D(pReferencedNodes(tAxis,tNodeNo(tAxis)))) {
					// remove key from this node
					Set $List(tNode(tAxis),6) = ""
				}
				Set tChainNode(tLevelCount) = tNode(tAxis)
				If ($LG(tNode(tAxis),1)="lit") {
					Set:'$D(tLiteral) tLiteral = $LG(tNode(tAxis),6)
				}

				Set tParentNo = $LG(tNode(tAxis),4)
				While (tParentNo '= "") {
					Set tLevelCount = tLevelCount + 1
					Set tChain(tLevelCount) = tParentNo
					If (tAxis=pCMbrAxis) {
						Set tParentNode = $G($$$DeepSeeAxisGLVN(pCMbrCubeIndex,pLocalKey,"axes",tParentNo))
					}
					Else {
						Set tParentNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tParentNo))
						If ('pIsSlicer&&$D(pReferencedNodes(tAxis,tParentNo))) {		// DTB878 - Fix typo to properly use the numerical index
							// remove key from this node
							Set $List(tParentNode,6) = ""
						}
					}
					If ($LG(tParentNode,1)="lit") {
						Set:'$D(tLiteral) tLiteral = $LG(tParentNode,6)
					}
					Set tNewParentNo = $LG(tParentNode,4)

					Set tChainNode(tLevelCount) = tParentNode
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
					Set tLevel(tAxis) = tLevel
					Set tStackNo(tAxis,tLevel) = tChain(nn)
					Set tStackNode(tAxis,tLevel) = tChainNode(nn)
					Set tSNode = tStackNode(tAxis,tLevel)
					Set tSType = $LG(tSNode,1)
					Set tKey = $LG(tSNode,6)
					Set tFact = $LG(tSNode,7)
					Set tKey(tAxis,tLevel(tAxis)) = tKey
					Set tFact(tAxis,tLevel(tAxis)) = tFact

					Set tStackSpec(tAxis,tLevel(tAxis)) = $G(tStackSpec(tAxis,tLevel(tAxis)-1),tBaseSpec)

					Set sf = $LG(tSNode,20)
					If (sf'="") {
						For sx = 1:1:$L(sf,",") {
							Set fno = $P(sf,",",sx)
							// use key for current fact, if present
							Set tSkipSet(fno) = $S(tFact=fno:tKey,1:"")
						}
					}
					
					// PFS040 - Add handling or %ORs
					If (tSType = "orset") {
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
						Set tStackMeasure(tAxis,tLevel(tAxis)) = $G(tStackMeasure(tAxis,tLevel(tAxis)-1))
						Set tStackMeasureType(tAxis,tLevel(tAxis)) = $G(tStackMeasureType(tAxis,tLevel(tAxis)-1))
						Set tStackAgg(tAxis,tLevel(tAxis)) = $G(tStackAgg(tAxis,tLevel(tAxis)-1))
						Set tStackScale(tAxis,tLevel(tAxis)) = $G(tStackScale(tAxis,tLevel(tAxis)-1))
						Set:$G(tStackDistinct(tAxis,tLevel(tAxis)))="" tStackDistinct(tAxis,tLevel(tAxis)) = $G(tStackDistinct(tAxis,tLevel(tAxis)-1))
					} ElseIf ((tSType'="msr")&&(tSType'="lit")&&(tSType'="exp")) {
						// inherit current measure, agg
						Set tStackMeasure(tAxis,tLevel(tAxis)) = $G(tStackMeasure(tAxis,tLevel(tAxis)-1))
						Set tStackMeasureType(tAxis,tLevel(tAxis)) = $G(tStackMeasureType(tAxis,tLevel(tAxis)-1))
						Set tStackAgg(tAxis,tLevel(tAxis)) = $G(tStackAgg(tAxis,tLevel(tAxis)-1))
						Set tStackScale(tAxis,tLevel(tAxis)) = $G(tStackScale(tAxis,tLevel(tAxis)-1))
						Set:$G(tStackDistinct(tAxis,tLevel(tAxis)))="" tStackDistinct(tAxis,tLevel(tAxis)) = $G(tStackDistinct(tAxis,tLevel(tAxis)-1))
						
						// set spec for this level
						If (tSType '= "cmbr") {
							If ((tFact'="")&&(tKey'="")) {
								If (tInOR) {
									If (tInORtuple) {
										// JMD1453: add to current ortuple
										Set ox = $G(tORList(tORSetNo))
										Set:ox="" ox = $I(tORList(tORSetNo))
										Set tORList(tORSetNo,ox) = ##class(Engine2).%CombineSpecs(tFactCount,$G(tORList(tORSetNo,ox)),##class(Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tAxis,tLevel(tAxis)),tFact,tKey))
									}
									Else {
										// JMD1453: accumulate OR spec
										Set ox = $I(tORList(tORSetNo))
										Set tORList(tORSetNo,ox) = ##class(Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tAxis,tLevel(tAxis)),tFact,tKey)
									}
								} else {
									// JMD1453
									Set tStackSpec(tAxis,tLevel(tAxis)) = ##class(Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tAxis,tLevel(tAxis)),tFact,tKey)
								}
							}
						}
					}
					ElseIf (tSType="msr") {
						Set pMsr = $LG(tSNode,7)
						// JMD763
						Set pCellAgg = $LG(tSNode,8)
						Set pCellMsrScale = $LG(tSNode,13)
						Set pCellMsrType = "number" // is this ok?
					}
					
					
					Set tMeasure(tAxis) = $G(tStackMeasure(tAxis,tLevel(tAxis)))
					Set tMeasureType(tAxis) = $G(tStackMeasureType(tAxis,tLevel(tAxis)))
					Set tAgg(tAxis) = $G(tStackAgg(tAxis,tLevel(tAxis)))
					Set tDistinct(tAxis) = $G(tStackDistinct(tAxis,tLevel(tAxis)))
					Set tMsrScale(tAxis) = $G(tStackScale(tAxis,tLevel(tAxis)))
					Set tSpec(tAxis) = $G(tStackSpec(tAxis,tLevel(tAxis)))
					Set tSubstSpec(tAxis) = $G(tSubstStackSpec(tAxis,tLevel(tAxis)))
					
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
							Set tSpec(tAxis) = ##class(Engine2).%CombineSpecs(tFactCount,tSpec(tAxis),tORSpec)
						}
						Set oc = $O(tORList(oc))
					}

					Kill tSkipFacts(tAxis)
					Merge tSkipFacts(tAxis) = tSkipSet
				} // For nn
			}
		} // for tAxis

		// find cell context from axes context
		Set tHasSkip = 0
		For a=1:1:3 {
			// JMD1488 skip slicer here
			If ((a'=tSlicerAxis)&&($G(tNode(a))'="")) {
				Set tNodeNums(a) = +tNodeNo(a)
				Set tAxisSpec = $G(tSpec(a))
				If (a'=tSlicerAxis) {
					Set:$D(tSkipFacts(a)) tHasSkip = 1
					// combine specs
					// PFS040 - Use tAxisSpec length since there may be %ORs
					For f = 1:1:$LL(tAxisSpec)-1 {
						Set tKey = $LG(tAxisSpec,f+1)
						If (tKey'="") {
							Set ef = $LG(tCellSpec,f+1)
							If ((ef'="")&&(ef '= tKey)) {
								Set tKey = ef _ $S($E(tKey)="@":"*",1:"&") _ tKey
							}
							//Set:$e(tKey)="@" tKey=##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tKey) // JSL4407 relationship
							Set $List(tCellSpec,f+1) = tKey
						} ElseIf ($LG(tCellSpec,f+1,0)=0) {
							Set $List(tCellSpec,f+1) = tKey
						}
					}
				}
			}
		} // for a

		// now remove everything referenced in the skip facts set
		If (tHasSkip && 'pIsSlicer) {
			For a=1:1:3 {
				// cell address in original axis order
				Set tNodeNums(a) = +tNodeNo(a)
				Set tAxisSpec = $G(tSpec(a))
				If (a'=tSlicerAxis) {
					For f = 1:1:$LL(tCellSpec)-1 {
						If $D(tSkipFacts(a,f)) {
							Set $List(tCellSpec,f+1) = tSkipFacts(a,f)
						}
					}
				}
			}
		}
		Set pCellSpec = $S($D(tLiteral):tLiteral,1:tCellSpec)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// For a given query, compute any bitsets that come from queries against related cubes.
ClassMethod %ResolveRelationships(pCube As %String, pKey As %String, pUseAgents As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill tIntersectIndex
		Set tGroupId = ""
		Set tFlipCount = 0
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		If (pUseAgents) {
			// DTB704 - This is now handled by the %DeepSee.WorkMgr
			Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tGroupId,1,"JOIN")
			
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Quit
			}
		}

		// number of fact properties in cube
		Set tFactCount = $G($$$DeepSeeMetaGLVN("cubes",pCube,"factCount"))
		// JMD1453
		If (tFactCount="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube must be recompiled")
			Quit
		}

		// find set of relations for this cube
		Set r = $O($$$DeepSeeMetaGLVN("cubes",pCube,"rel#",""),1,data)
		While (r'="") {
			Set tRelation(r) = data
			Set r = $O($$$DeepSeeMetaGLVN("cubes",pCube,"rel#",r),1,data)
		}

		// construct base spec
		// this is a $List with "" defined for each fact
		// plus an initial slot (reserved for future use)
		Set tBaseSpec = $LB("")
		For n = 1:1:tFactCount {
			Set tBaseSpec = tBaseSpec _ $LB("")
		}

		// Find axes
		Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(pCube,pKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
		If (tTotalAxisCount = 0) {
			Quit
		}

		// build list ordered by size of axis
		Set tSlicerSize = 0
		Set tSlicerAxis = ""
		For a=1:1:tTotalAxisCount {
			If (tAxisType(a) = "slicer") {
				// slicer is always first in the list
				Set tAxisList(-999999,a) = tAxisKey(a)		// DTB225 - Use 999999 to match artificial filter order in %ExecuteForBucket
				Set tSlicerSize = tAxisSize(a)
				Set tSlicerAxis = a
			}
			ElseIf (tAxisType(a) = "axis") {
				Set tAxisList(-tAxisSize(a),a) = tAxisKey(a)
			}
		}

		Kill tAxisKey

		// initialize axis info (using size ordered list)
		Set tAxisCount = 0
		Set s = $O(tAxisList(""))
		While (s'="") {
			Set a = $O(tAxisList(s,""))
			While (a'="") {
				Set tAxisCount = tAxisCount + 1
				Set tOrigAxisNo = a
				Set tRealAxisNo(tAxisCount) = a
				Set tAxisRoot(tAxisCount) = 1
				Set tAxisKey(tAxisCount) = tAxisList(s,a)
				Set tStartNode(tAxisCount) = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxisCount),"axes",tAxisRoot(tAxisCount),"all",""))
				Set tEndNode(tAxisCount) = ""
				Set tNodeNo(tAxisCount) = tStartNode(tAxisCount)
				If (tNodeNo(tAxisCount)="") {
					Set axno = ($G(tAxisList(s,a)))
					// axno is a key and not 1,2 etc.
					// JMD1069 Set tSC = $$$ERROR($$$GeneralError,"No members found for axis (r):" _ axno)
					Quit
				}
				Else {
					Do SetContext(tAxisCount)
				}
				Set a = $O(tAxisList(s,a))
			}
			If $$$ISERR(tSC) Quit
			Set s = $O(tAxisList(s))
		}
		If $$$ISERR(tSC) Quit

		// general loop over all axes
		Set tDone = 0
		While ('tDone) {
			Kill tNodeNums
			Set tCellSpec = tBaseSpec
			Set tSlicerSpec = tBaseSpec
			Set tDistinctAxis = ""			// non-"" if this cell has a %DISTINCT calc

			// JMD1403 look for the intersection of "deep relationships" to the same cube
			Set tDeepCount = 0	// number of intersecting axes
			Kill tDeepSpecs
			If $D(tDeepInfo) {
				Set tDeepCube = ""
				Set tDRelCube = ""
				Set tDRelFact = ""
				For a=1:1:tAxisCount {
					If (tRealAxisNo(a)'=tSlicerAxis) {
						If $D(tDeepInfo(a)) {
							If (tDeepCube="") {
								Set tDeepCube = $O(tDeepInfo(a,""))
								Set tDeepCount = 1
								If (tDeepCube'="") {
									Set tDRelFact = tDeepInfo(a,tDeepCube,"fact")
									Set tDRelCube = tDeepInfo(a,tDeepCube,"cube")
									Set k = $O(tDeepInfo(a,tDeepCube,"specs",""))
									While (k'="") {
										Set tDeepSpecs($I(tDeepSpecs)) = tDeepInfo(a,tDeepCube,"specs",k)
										Set k = $O(tDeepInfo(a,tDeepCube,"specs",k))
									}
								}
							}
							Else {
								If (tDeepCube = $O(tDeepInfo(a,""))) {
									Set tDeepCount = tDeepCount + 1
									Set k = $O(tDeepInfo(a,tDeepCube,"specs",""))
									While (k'="") {
										Set tDeepSpecs($I(tDeepSpecs)) = tDeepInfo(a,tDeepCube,"specs",k)
										Set k = $O(tDeepInfo(a,tDeepCube,"specs",k))
									}
								}
							}
						}
					}
				}
			}
			
			// DTB305 - The shallow context is set into the relMap node by 3D address first, which then can be augmented by the
			// deep relationship subquery.

			// find intersection of axes
			For a=1:1:tAxisCount {
				Set tNodeNums(+tNodeNo(a)) = ""
				Set tAxisSpec = $G(tSpec(a))
				If (tRealAxisNo(a)=tSlicerAxis) {
					// fold in later
					Set tSlicerSpec = tAxisSpec
				}
				Else {
					// combine specs (only relation specs will be included)
					// JMD852: Use "*" to combine specs and not "&" to avoid
					// confusion with key AND/OR logic
					For f = 1:1:tFactCount {
						Set tKey = $LG(tAxisSpec,f+1)
						If (tKey'="") {
							Set ef = $LG(tCellSpec,f+1)
							If ((ef'="")&&(ef '= tKey)) {
								Set tKey = ef _ "*" _ tKey
							}
							Set $List(tCellSpec,f+1) = ##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tKey) // JSL4407
						}
					}
				}

				If ($G(tDistinct(a))'="") {
					Set tDistinctAxis = a
				}
			} // for a
			
			// fold in slicer, if present
			If (tSlicerSpec'="") {
				// JMD1453
				Set tCellSpec = ##class(Engine2).%CombineSpecs(tFactCount,tCellSpec,tSlicerSpec)
			}

			// +DTB305 - Test if this cell context should be added to the accumulated subqueries
			Set tSpecialFactId = ""
			If ((tDeepCount>0)&&($G(tDeepSpecs)>1)) {
				Set tJMD1403 = 1
				If (tJMD1403) {
					// record this cell address; 
					// use normalized 3D address for all cases
					Kill nx
					Set nx(1)=1,nx(2)=1,nx(3)=1			// DTB225 - Initialize to prevent undefined
					For nxi=1:1:3 {
						Set ra = $G(tRealAxisNo(nxi))
						If (ra'="") && (tNodeNo(nxi)'="") {
							// PFS081 - Do not set to empty string
							Set nx(ra) = tNodeNo(nxi)	// DTB225 - Switch indices to use correct real axis order
						}
					}
					
					// Record the current cell context in the overlay node. References for JoinIndices using information from a
					// deep relationship subquery might get added later.
					Set $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"relMap",nx(1),nx(2),nx(3)) = tCellSpec
					
					// Add all context information to the intersectIndex. This is organized
					//   tDeepInfo(axis,cube)
					Set a = $O(tDeepInfo(""))
					While (a'="") {
						Set tDeepCubeIndex = $O(tDeepInfo(a,""))
						While tDeepCubeIndex'="" {
							// Cube or the deep subquery
							Set tDCube = $$$UPPER(tDeepInfo(a,tDeepCubeIndex,"cube")) 
							
							// Collect context address information from previous axes
							Set tDContextSpec = $G(tDContextSpecs(tDCube))
							
							Set tSpecIdx = $O(tDeepInfo(a,tDeepCubeIndex,"specs",""),1,tDRelSpec)
							While tSpecIdx {
								// Parse out the path from the fully qualified member spec to use as a contextual axis. Parse out the member key
								// to use as a contextual coordinate.
								Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tDRelSpec,.tInfo)
								Set tDKeyIdx = $O(tInfo(""),-1,tDKey) 
								Set tDKey = $$$dsEscapeIdent(tDKey)
								Set tDLevelSpec = $Replace($Piece(tDRelSpec,tDKey,1,*-1),".&[","")
								Set tComplex = 0
								
								// PFS081 - If this is not true, this is not a simple spec. Convert it and handle separately
								If tDLevelSpec_".&["_tDKey_"]"'=tDRelSpec {
									Set tComplex = 1
									Set tDLevelSpec = $zcrc(tDRelSpec,7)
									Set tDKey = $zcrc(tDKey,7)
								}
								
								// PFS089 - If the noData node is set, populate spec and key accordingly
								Set tDNoData = $G(tDeepInfo(a,tDeepCubeIndex,"noData",tSpecIdx),0)
								If tDNoData {
									Set tDLevelSpec = tDRelSpec
									Set tDKey = -1E14
								}
								
								If '$D(tIntersectIndex(tDCube,tDLevelSpec)) {
									// Keep track of levels seen by the context intersections and assign each level spec a temporary id.
									// This is used as a coordinate to cross-reference context levels with positional axes in the original table.
									Set tIntersectIndex(tDCube,$I(tIntersectIndex(tDCube))) = tDLevelSpec
									Set tIntersectIndex(tDCube,tDLevelSpec) = tIntersectIndex(tDCube)
									
									Set tIntersectIndex(tDCube,"fact") = tDeepInfo(a,tDeepCubeIndex,"fact")
								}
								
								// PFS081 - Store full spec and the intersectSpec as data, may be large
								If $G(tComplex) {
									Set tIntersectIndex(tDCube,tDLevelSpec,"spec") = tDRelSpec
								}
								
								If '$D(tIntersectIndex(tDCube,tDLevelSpec,"keys",tDKey)) {
									// Set the new address for a particular member into the intersect index and assign it an id within the level.
									// This is used as the contextual coordinate along each level to cross-reference specific cell context with a
									// specific positional address in the orginal table.
									// Often the native SQL id is not stored with these members in the ^DeepSee.Cache.Axis global if they are referencing
									// members that are subject to combination with a JoinIndex
									Set tIntersectIndex(tDCube,tDLevelSpec,"keyIndex",$I(tIntersectIndex(tDCube,tDLevelSpec,"keyIndex"))) = tDKey
									Set tIntersectIndex(tDCube,tDLevelSpec,"keys",tDKey) = tIntersectIndex(tDCube,tDLevelSpec,"keyIndex")
									
									If tDNoData {
										// PFS089 - Log the full spec and the relationship reference
										// Later on we can build the relationship reference and map back to the full spec
										Set tNoDataSpecList = ""
										Set tInfoLast = $O(tInfo(""),-1)
										Set tInfoPos = $O(tInfo(""))
										While tInfoPos < (tInfoLast-2) {
											Set tNoDataSpecList = tNoDataSpecList _ $LB(tInfo(tInfoPos))
											Set tInfoPos = $O(tInfo(tInfoPos))
										}
										Set tDRelSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec(tNoDataSpecList)
										Set tIntersectIndex(tDCube,tDLevelSpec,"keyIndex",tIntersectIndex(tDCube,tDLevelSpec,"keyIndex"),"noData") = tDRelSpec
										Set tIntersectIndex(tDCube,tDRelSpec,"noDataKey") = tIntersectIndex(tDCube,tDLevelSpec,"keyIndex")
										Set tIntersectIndex(tDCube,tDRelSpec,"fullSpec") = tDLevelSpec
									}
								}

								// Set the actual context address into the coordinate
								Set $LI(tDContextSpec,tIntersectIndex(tDCube,tDLevelSpec)) = tIntersectIndex(tDCube,tDLevelSpec,"keys",tDKey)
								
								// Get the next context axis for the current positional axis.
								Set tSpecIdx = $O(tDeepInfo(a,tDeepCubeIndex,"specs",tSpecIdx),1,tDRelSpec)
							}
							// Store the current context spec for this cube
							Set tDContextSpecs(tDCube) = tDContextSpec
							
							// Get the next cube along this axis
							Set tDeepCubeIndex = $O(tDeepInfo(a,tDeepCubeIndex))
						}

						// Get info for the next positional axis.
						Set a = $O(tDeepInfo(a))
					}
					
					// Store the cell adress for lookup by context address
					Set tDCube = $O(tDContextSpecs(""))
					While tDCube'="" {
					    Set tDContextSpec = $G(tDContextSpecs(tDCube))
					    If (tDContextSpec'="") {
							Set tIntersectIndex(tDCube,"contextAddr",tDContextSpec) = $LB(nx(1),nx(2),nx(3))
					    }
						
						Set tDCube = $O(tDContextSpecs(tDCube))
					}
				}
			}
			// -DTB305
			

			// JMD1403: add id for intersecting deep relationship
			// this *could* replace the existing id, but let's play it safe
			Set tJMD1403 = 1
			If (tJMD1403&&($G(tSpecialFactId)'="")) {
				Set ef = $LG(tCellSpec,tDRelFact+1)
				If ((ef'="")&&(ef '= tSpecialFactId)) {
					Set tSpecialFactId = ef _ "*" _ tSpecialFactId
					
				}
				Set tSpecialFactId = ##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tSpecialFactId) // JSL4407
				Set $List(tCellSpec,tDRelFact+1) = tSpecialFactId

				// mark that this cell has an "overlay"; 
				// use normalized 3D address for all cases
				Kill nx
				Set nx(1)=1,nx(2)=1,nx(3)=1			// DTB225 - Initialize to prevent undefined
				For nxi=1:1:3 {
					Set ra = $G(tRealAxisNo(nxi))
					If (ra'="") {
						Set nx(ra) = tNodeNo(nxi)	// DTB225 - Switch indices to use correct real axis order
						//Set nx(nxi) = tNodeNo(ra)
					}
				}
				Set $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"relMap",nx(1),nx(2),nx(3)) = tCellSpec
			}
			
			// DTB - Convenient debugging statements, to be left commented out
			//Write ">>>>>>",$G(tNodeNo(1)),",",$G(tNodeNo(2)),",",$G(tNodeNo(3)),!
			//Write "tCellSpec",?30,$ListToString(tCellSpec,":"),!
			//Write "tSlicerSpec",?30,$ListToString(tSlicerSpec,":"),!
			//Write "  ",$G(tCellCalc)," ",$G(tHasExpression),!
			//Write "tFactCount=",tFactCount," ","length tCellSpec=",$LL(tCellSpec),!

			// for each restriction based on a relation
			// combine remote bits and transpose to local bits
			// store the result in the fact index keyed by the intersection code
			// the intersection code takes the form:
			// remoteQueryKey-nodeNo&remoteQueryKey-nodeNo ...
			// + DTB817 - Create a join index for the cell spec and the current slicer spec
			Set tSC = ..%SpecToJoinIndex(tCellSpec, pCube, pKey, pUseAgents, .tRelation, .tIntersect, tGroupId)
			If $$$ISERR(tSC) Quit
			
			Set tSC = ..%SpecToJoinIndex(tSlicerSpec, pCube, pKey, pUseAgents, .tRelation, .tIntersect, tGroupId)
			If $$$ISERR(tSC) Quit
			// - DTB817

			// JMD880: Make sure children of %DISTINCT get join indices built
			If (tDistinctAxis'="") {
				Set tChildNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tNodeNo(tDistinctAxis),"ch",""))
				While (tChildNo'="") {
					Set tChildSpec = tCellSpec
					Set tChildNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tChildNo))
					Set tChildType = $LG(tChildNode,1)

					If (tChildType = "mbr") {
						Set tChildKey = $LG(tChildNode,6)
						Set tChildFact = $LG(tChildNode,7)

						// set spec for this level: if this is a relationship
						If ((tChildFact'="")&&(tChildKey'="")) {
							If ($D(tRelation(tChildFact))) {
								Set ef = $LG(tChildSpec,tChildFact+1)
								If ((ef'="")&&(ef '= tChildKey)) {
									Set tChildKey = ef _ "*" _ tChildKey
								}
								Set $List(tChildSpec,tChildFact+1) = tChildKey
							}
						}

						Set tRelNo = $O(tRelation(""),1,tRelName)
						While (tRelNo'="") {
							Set tKeyCode = $LG(tChildSpec,tRelNo+1)
							Set tKeyCode=##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tKeyCode) // JSL4407
							If ((tKeyCode '= "")&&'$D(tIntersect(tRelNo,tKeyCode))) {
								Set tIntersect(tRelNo,tKeyCode) = "" // track that we have visited this intersection
								Set tRemoteCube = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCube,"relations",$$$UPPER(tRelName),"relatedCube")))
								If (pUseAgents) {
									Set tFlipCount = tFlipCount + 1
									// DTB704 - This is now handled by the %DeepSee.WorkMgr
									Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId,"JOININDEX",pCube,pKey,tRemoteCube,tRelNo,tKeyCode)
								}
								Else {
									Set tSC = ..%CreateJoinIndex(pCube,tRemoteCube,tRelNo,tKeyCode,pKey)
								}
								If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB
							}
							Set tRelNo = $O(tRelation(tRelNo),1,tRelName)
						}
						If $$$ISERR(tSC) Quit
					}

					// next child
					Set tChildNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tDistinctAxis),"axes",tNodeNo(tDistinctAxis),"ch",tChildNo))
				}
			}

			// find next cell intersection
			Set tAxis = tAxisCount
			While (1) {
				Set tNodeNo(tAxis) = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tAxisRoot(tAxis),"all",tNodeNo(tAxis)))
				If ((tNodeNo(tAxis)'="") && (tNodeNo(tAxis)'=tEndNode(tAxis))) {
					Do SetContext(tAxis)
					Quit
				}
				// try previous axis
				If (tAxis > 1) {
					Set tNodeNo(tAxis) = tStartNode(tAxis)
					// reset context
					If (tNodeNo(tAxis)'="") {
						// DTB513 - Protect against null entry in tNodeNo
						Do SetContext(tAxis)
					}
					Set tAxis = tAxis - 1
				}
				Else {
					Set tDone = 1
					Quit
				}
 			}
		}	// End of the general loop over all axes


		
		// +DTB305
		// For each cube containing a set of deep relationship context addresses, build and execute a single %BITSET subquery that executes all
		// context coordinates. Translate these results to the original positional coordinates
		If $D(tIntersectIndex) {
			Set tDRelCube = $O(tIntersectIndex(""))
			While tDRelCube'="" {
				// Construct one query per cube
				Set tDFactNo = tIntersectIndex(tDRelCube,"fact")
				Set tSubquerySpec = tBaseSpec
				Set nx(1) = $O($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"relMap",""))
				Set nx(2) = $O($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"relMap",nx(1),""))
				Set nx(3) = $O($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"relMap",nx(1),nx(2),""))
				
				Kill tDSets
				For tLevelIdx=1:1:tIntersectIndex(tDRelCube) {
					Set tDLevelSpec = tIntersectIndex(tDRelCube,tLevelIdx)
					Set tDKeyList = ""
					For tKeyIdx=1:1:tIntersectIndex(tDRelCube,tDLevelSpec,"keyIndex") {
						// First accumulate keys into a list. Prepend the level spec to each one
						Set tDKey = tIntersectIndex(tDRelCube,tDLevelSpec,"keyIndex",tKeyIdx)
						
						If $G(tIntersectIndex(tDRelCube,tDLevelSpec,"keyIndex",tKeyIdx,"noData"))'="" {
							// PFS089 - Use null relation spec
							Set tDKeyList = tDKeyList _ $LB($G(tIntersectIndex(tDRelCube,tDLevelSpec,"keyIndex",tKeyIdx,"noData"))_".&[<null>]")
						} Else {
							Set tDKeyList = tDKeyList _ $LB(tDLevelSpec_".&["_tDKey_"]")
						}
					}
					
					// Record the set of members for this level spec, sorting by count
					Set tSetSize = $LL(tDKeyList)
					Set x = $I(tDSets)
				
					Set tDSets(tSetSize,$I(tDSets(tSetSize))) = $S(tSetSize>1:"{",1:"") _ $ListToString(tDKeyList) _ $S(tSetSize>1:"}",1:"")
					
					// Record the specs as they are entered
					Set tDSets(tSetSize,tDSets(tSetSize),"levelSpec") = tDLevelSpec
					
					// PFS081 - If this is populated, it means spec is complex, override tDSets with stored complex spec
					If $G(tIntersectIndex(tDRelCube,tDLevelSpec,"spec"))'="" {
						Set tDSets(tSetSize,tDSets(tSetSize),"levelSpec") = tIntersectIndex(tDRelCube,tDLevelSpec,"spec")
						Set tDSets(tSetSize,tDSets(tSetSize)) = tIntersectIndex(tDRelCube,tDLevelSpec,"spec")
					}
				}
				
				// Make a single crossjoined axis of all sets in the current related cube
				Set tCount = 0
				Set tColClause = ""
				Set tSize = $O(tDSets(""),-1,tDSizeCount)		// Go from largest set (innermost of the CJ) to smallest set (outermost of the CJ)
				While tSize'="" {
					Set tSizeIdx = $O(tDSets(tSize,""),1,tDSet)
					While tSizeIdx'="" {
						// Record set order to easily read the contextual coordinates from the subquery's ordinal key array
						Set tDSets("order",$I(tCount)) = tDSets(tSize,tSizeIdx,"levelSpec")
						
						If tCount>1 {
							Set tColClause = "NONEMPTYCROSSJOIN("_tDSet_","_tColClause_")"
						}
						Else {
							Set tColClause = tDSet
						}
						
						Set tSizeIdx = $O(tDSets(tSize,tSizeIdx),1,tDSet)
					}
					
					Set tSize = $O(tDSets(tSize),-1,tDSizeCount)
				}
				
				// Assemble the columns-only %BITSET subquery.
				Set tDQueries(tDRelCube) = "%BITSET SELECT " _ tColClause _ " ON 0 FROM [" _ tDRelCube _ "]"
				
				
				// Execute the subquery
				Set tDRS = ##class(%DeepSee.ResultSet).%New()
				
				// pass on our named parameters to the subquery
				Merge tContext = %query.%NamedParameters
				Do tDRS.%SetParameterContext(.tContext)
				Set tDRS.%UseCache = %query.useCache
				
				Set tSC = tDRS.%PrepareMDX(tDQueries(tDRelCube))
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				
				Set tDRS.%Query.parentQueryKey = $S(%query.parentQueryKey'="":%query.parentQueryKey,1:%query.%QueryKey)
				
				If +$G(%dsflags("RELATIONS")) {
					$$$DSWRITELN("*** (deep)")
					$$$DSWRITELN("SUBQUERY: "_tDQueries(tDRelCube))
				}
				
				Kill tParmValues
				
				If (%query.useAgents) {		// DTB704 - Only test useAgents
					If ('$G(%verbose)) {
						Set tSC = tDRS.%ExecuteAsynch(.tDQueryKey,.tParmValues,1)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}
					Else {
						Set tSC = tDRS.%ExecuteAsynch(.tDQueryKey,.tParmValues,0)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)

						// give feedback to shell
						Set tCube = tDRS.%GetCubeName()
						Set tKey = tDRS.%GetQueryKey()
						Write "Processing..."
						Hang 0.01
						Set tLoopCount = 0
						Set tStatus = tDRS.%GetStatus(.tComplete)
						While ((tStatus<100)&&(tStatus>=0)) {
							Set tLoopCount = tLoopCount + 1
							Set tMsg = $S(tStatus < 35:"Computing deep related cube axes...",tStatus < 90:"Computing related cube cells...",1:"Consolidating related cube results...")
							Write $C(13,27)_"[0J"
							Write $J(tCount,4),": ",tMsg,"(",tStatus,")  "
							If (tComplete '= "") {
								Write $FN(tComplete,",",2),"% complete"
							}
							Hang $Case(tLoopCount,1:0.1,2:0.2,:0.5)
							Set tStatus = tDRS.%GetStatus(.tComplete)
						}
						Write $C(13,27)_"[0J"
					}
				}		
				Else {
					Set tSC = tDRS.%Execute(.tParmValues)
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					
					Set tDQueryKey = tDRS.%GetQueryKey()
				}
				
				// +DTB458 - Log the subquery keys in the results global if a related cube is involved
				Set tSubqueryCube = tDRS.%CubeKey
				If ($G(tCubeIndex)'="") && (tSubqueryCube'=$$$UPPER(tCubeIndex)) && (pKey'="") && (tSubqueryCube'="") && (tDQueryKey'="") {
					Set $$$DeepSeeResultsGLVN($$$UPPER(tCubeIndex),pKey,"subquery",tSubqueryCube,tDQueryKey) = "(2)"
				}
				// -DTB458
			
				// Create JoinIndex entries for this cube query
				Set tSpecialFactId = "@" _ tDQueryKey
				
				// Loop over results for this cube query. 
				// Use the "leaf" nodes to identify resultSlots. The factId does NOT need
				// the fact portion (3rd "-" delimited piece) of the join address, just the table location, eg:
				//      @subQueryKey-resultSlot
				For c=1:1:tDRS.%GetAxisSize(1) {
					// Deep query is a columns-only crossjoin
					Set tResultSlot = $$$DeepSeeResultsGLVN(tDRelCube,tDQueryKey,"leaf",1,c)
					Set tSubqueryKeyCode = tSpecialFactId _ "-" _ tResultSlot
					Set $LI(tSubquerySpec,tDFactNo+1) = tSubqueryKeyCode
					
					Kill tContextAddr
					// +PFS075 - Use %GetOrdinalLabelNodes to get full node context
					Set tSC = tDRS.%GetOrdinalLabelNodes(1,c,.tNodes)
					Set tNodePos = $O(tNodes(""))
					While tNodePos'="" {
						Set tDSpec = $LG(tNodes(tNodePos),14)
						Set tSpecialRelCube = $LG($LG(tNodes(tNodePos),22),4)
						If tDSpec '= "" {
							Set tSC = ##class(%DeepSee.Utils).%GetDimensionSpec(tDRelCube,.tDRelNameSpec,$LG(tNodes(tNodePos),9),$LG(tNodes(tNodePos),10),$LG(tNodes(tNodePos),11))
							If $$$ISERR(tSC) Quit
							Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tDRelNameSpec,.tDRelNameSpecInfo)
							If $$$ISERR(tSC) Quit
							Set tDRelName = tDRelNameSpecInfo(1)
							Set tDKey = $LG(tNodes(tNodePos),13)
							If tDKey="" {
								// PFS089 - Generate RelSpec to map to fullSpec and use noDataKey
								Set tDRelSpecList = $LB(tDRelName)
								Set tDRelSpec = $LG($LG(tNodes(tNodePos),22),1)
								D ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tDRelSpec,.tRelSpecInfo)
								Set tDRelDepth = $LG($LG(tNodes(tNodePos),22),3)
								// PFS089 - Extract Depth-1 items from spec to build RelSpec
								For i=1:1:tDRelDepth-1 {
									Set tDRelSpecList = tDRelSpecList _ $LB(tRelSpecInfo(i))
								}
								
								Set tDRelSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec(tDRelSpecList)
								Set tDRelSpec = $$$UPPER(tDRelSpec)
								Set tDFullRelSpec = tIntersectIndex(tDRelCube,tDRelSpec,"fullSpec")
								Set $LI(tContextAddr,tIntersectIndex(tDRelCube,tDFullRelSpec)) = tIntersectIndex(tDRelCube,tDRelSpec,"noDataKey")
							} Else {
								// PFS081 - Use method to convert spec, this can handle both complex and simple specs
								Set tDRelSpec = ##class(%DeepSee.Query.Engine).%ConvertDeepSpec(tDRelCube,tSpecialRelCube,tDRelName,tDSpec)
								If $D(tIntersectIndex(tDRelCube,$zcrc(tDRelSpec,7))) {
									// PFS081 - This is a complex spec, get the generated key
									Set tDRelSpec = $zcrc(tDRelSpec,7)
									Set tDKey = tIntersectIndex(tDRelCube,tDRelSpec,"keyIndex",1)
								} Else {
									// PFS081 - This is a simple spec, use the key from the original tDSpec text
									Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tDSpec,.tSpecInfo)
									Set tDKeyIdx = $O(tSpecInfo(""),-1,tDKey)
									Set tDKey = $$$dsEscapeIdent(tDKey)
								}
								Set $LI(tContextAddr,tIntersectIndex(tDRelCube,tDRelSpec)) = tIntersectIndex(tDRelCube,tDRelSpec,"keys",tDKey)
							}
						}
						Set tNodePos = $O(tNodes(tNodePos))
					}
					// -PFS075
					
					// Look up the positional cell address for the relMap overlay using the contextual address and the intersect index.
					// The relMap address should always be 3D.
					Set tRelMapSpec=""
					Set tRelMapAddr = $G(tIntersectIndex(tDRelCube,"contextAddr",tContextAddr))
					If tRelMapAddr'="" {
						Set nx(1) = $LG(tRelMapAddr,1)
						Set nx(2) = $LG(tRelMapAddr,2)
						Set nx(3) = $LG(tRelMapAddr,3)
						
						// Use the newly acquired cellSpec to build the full joinIndex keycode from the previous relMap
						Set tRelMapSpec = $G($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"relMap",nx(1),nx(2),nx(3)))
					}
					
					Set tFullRelMapSpec = ##class(%DeepSee.Query.Engine2).%CombineSpecs(tFactCount,tRelMapSpec,tSubquerySpec)
					// Put the augmented cell spec back in the overlay node
					Set $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"relMap",nx(1),nx(2),nx(3)) = tFullRelMapSpec
					
					Set tFullKeyCode = $LG(tFullRelMapSpec,tDFactNo+1)
					If tFullKeyCode'="" {
						// Call %CreateJoinIndex for this cell spec subquery cell address
						// This can be tasked off or executed by the current process
						If (pUseAgents) {
							Set tFlipCount = tFlipCount + 1
							// DTB704 - This is now handled by the %DeepSee.WorkMgr
							Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId,"JOININDEX",pCube,pKey,tDRelCube,tDFactNo,tFullKeyCode)
						}
						Else {
							Set tSC = ..%CreateJoinIndex(pCube,tDRelCube,tDFactNo,tFullKeyCode,pKey)
						}
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB
					}
				}
				
				// Move on to the next deep subquery
				Set tDRelCube = $O(tIntersectIndex(tDRelCube))
			}
		}
		// -DTB305


		// Wait for Join Indices if they were tasked to the agents
		If (pUseAgents) {		// DTB704 - Only test pUseAgents
			#; wait for agents
			If ($G(%verbose)) {
				Write "Computing cube join..."
			}

			// DTB704 - This is now handled by the %DeepSee.WorkMgr
			Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId)
			If $$$ISERR(tSC) {
				Set tText = $System.Status.GetErrorText(tSC)
				Do ##class(%DeepSee.Utils).%WriteToLog("Engine","Error in %ResolveRelationships: " _ tText)
				Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"status") = -1
				Quit
			}

			If ($G(%verbose)) {
				Write $C(13,27)_"[0J"
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		If $$$ISERR(tSC) {
			Set tText = $System.Status.GetErrorText(tSC)
			Do ##class(%DeepSee.Utils).%WriteToLog("Engine","Error in %ResolveRelationships: " _ tText)
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"status") = -1
			Quit
		}
	}
	
	Quit tSC

	// set context for the given node
SetContext(tAxis)
	Set tNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tNodeNo(tAxis)))
	Set tType = $LG(tNode,1)
	Set tCalc(tAxis) = +$LG(tNode,3)
	Set tSpec(tAxis) = tBaseSpec
	Kill tDeepInfo(tAxis)

	// [n.b.] we could save some work by checking if we
	// have already seen the parent, but this does not seem worth it
	// DTB187: check for "orset";
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
		Set tParentNode = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tParentNo))
		Set tChainNode(tLevelCount) = tParentNode
		Set tParentNo = $LG(tParentNode,4)
	}

	// build stacks of node info from top down
	Set tLevel = 0
	For nn = tLevelCount:-1:1 {
		Set tLevel = tLevel + 1
		Set tLevel(tAxis) = tLevel
		Set tStackNo(tAxis,tLevel) = tChain(nn)
		Set tStackNode(tAxis,tLevel) = tChainNode(nn)
		Set tSNode = tStackNode(tAxis,tLevel)
		Set tSType = $LG(tSNode,1)
		Set tKey = $LG(tSNode,6)
		Set tFact = $LG(tSNode,7)
		Set tKey(tAxis,tLevel(tAxis)) = tKey
		Set tFact(tAxis,tLevel(tAxis)) = tFact
		Set tStackSpec(tAxis,tLevel(tAxis)) = $G(tStackSpec(tAxis,tLevel(tAxis)-1),tBaseSpec)

		Set tStackDistinct(tAxis,tLevel(tAxis)) = ""
		Set:$G(tStackDistinct(tAxis,tLevel(tAxis)))="" tStackDistinct(tAxis,tLevel(tAxis)) = $G(tStackDistinct(tAxis,tLevel(tAxis)-1))

		If (tSType = "mbr") {
			// set spec for this level: if this is a relationship
			If ((tFact'="")&&(tKey'="")) {
				If ($D(tRelation(tFact))) {

					// JMD1403 look for special info for deep relationships
					Set tSpecial = $LG(tSNode,22)
					If (tSpecial'="") && ($LG(tSpecial,3)>1) {
						Set tDeepKey = $LG(tSNode,13)
						Set tDeepSpec = $LG(tSNode,14)	// DTB057
						Set tDeepCube = $LG(tSpecial,2)
						// add to DeepInfo list by cube
						Set idx = $I(tDeepInfo(tAxis,tDeepCube,"specs"))
						Set tDeepInfo(tAxis,tDeepCube,"specs",idx) = tDeepSpec
						Set tDeepInfo(tAxis,tDeepCube,"cube") = ##class(%DeepSee.Utils).%GetRelatedCube(tCubeIndex,tRelation(tFact))	// DTB058
						Set tDeepInfo(tAxis,tDeepCube,"fact") = tFact
						If tDeepKey = "" {
							// PFS089 - Mark noData node so tIntersectIndex can be built with noData info
							Set tDeepInfo(tAxis,tDeepCube,"noData",idx) = 1
						}
					}

					Set ef = $LG(tStackSpec(tAxis,tLevel(tAxis)),tFact+1)
					If ((ef'="")&&(ef '= tKey)) {
						Set tKey = ef _ "*" _ tKey
						Set tKey= ##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tKey) // JSL4407
					}
					//Set $List(tStackSpec(tAxis,tLevel(tAxis)),tFact+1) = tKey
					If (tInOR) {
						If (tInORtuple) {
							// DTB187: add to current ortuple
							Set ox = $G(tORList(tORSetNo))
							Set:ox="" ox = $I(tORList(tORSetNo))
							Set tORList(tORSetNo,ox) = ##class(%DeepSee.Query.Engine2).%CombineSpecs(tFactCount,$G(tORList(tORSetNo,ox)),##class(%DeepSee.Query.Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tAxis,tLevel(tAxis)),tFact,tKey))
						}
						Else {
							// DTB187: accumulate OR spec
							Set ox = $I(tORList(tORSetNo))
							Set tORList(tORSetNo,ox) = ##class(%DeepSee.Query.Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tAxis,tLevel(tAxis)),tFact,tKey)
						}
					}
					Else {
						Set tStackSpec(tAxis,tLevel(tAxis)) = ##class(%DeepSee.Query.Engine2).%SetFactIntoSpec(tFactCount,tStackSpec(tAxis,tLevel(tAxis)),tFact,tKey)
					}
				}
			}
		}
		ElseIf (tSType = "orset") {
			// DTB187: start accumulating an "orset"
			Set tORSetNo = tORSetNo + 1
			Set tInOR = 1
			Set tInORtuple = 0
		}
		ElseIf (tSType = "ortuple") {
			// DTB187: start accumulating an "ortuple"
			Set tInORtuple = 1
			// advance to next or branch
			If ($D(tORList(tORSetNo))) {
				Set ox = $I(tORList(tORSetNo))
			}
		}
		ElseIf (tSType = "tuple") {
			// DTB187: stop accumulating "orset"
			Set tInOR = 0
			Set tInORtuple = 0
		}
		ElseIf (tSType="lit") {
			// DTB807 - Check to see if this is a literal null. This would nullify results of any intersection
			// that is not part of %OR.
			If 'tInOR {
				Set tSpec(tAxis) = ""
				Quit
			}
		}

		// test for %DISTINCT
		If (tSType = "agg") {
			If ($LG(tSNode,6)="%DISTINCT") {
				Set tStackDistinct(tAxis,tLevel(tAxis)) = 1
			}
		}

		Set tSpec(tAxis) = $G(tStackSpec(tAxis,tLevel(tAxis)))
		
		// DTB187: fold in OR sets
		Set oc = $O(tORList(""))
		While (oc'="") {
			Set tORSpec = ""
			Set ox = $O(tORList(oc,""))
			While (ox'="") {
				Set tORSpec = tORSpec _ $G(tORList(oc,ox))
				Set ox = $O(tORList(oc,ox))
			}
			If (tORSpec'="") {
				Set tSpec(tAxis) = ##class(%DeepSee.Query.Engine2).%CombineSpecs(tFactCount,tSpec(tAxis),tORSpec)
			}
			Set oc = $O(tORList(oc))
		}
		
		Set tDistinct(tAxis) = $G(tStackDistinct(tAxis,tLevel(tAxis)))
	}
	Quit
}

/// Produce all join index entries for a particular <var>pSpec</var>. The references <var>pCube</var> and <var>pKey</var>are required.
/// The array <var>pRelation</var> contains the metadata about the current relationships in play in the cube. The by-reference 
/// <var>pIntersect</var> can be used to prevent duplicate calculations of the same join index keys.
ClassMethod %SpecToJoinIndex(pSpec As %List, pCube As %String = "", pKey As %String = "", pUseAgents As %Boolean = 1, ByRef pRelation, ByRef pIntersect, pGroupId As %String = "") As %Status
{
	// Method added by DTB817
	Set tSC = $$$OK
	
	Try {
		If (pCube="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name must be supplied in %SpecToJoinIndex")
			Quit
		}
		If (pKey="") {
			Set tSC = $$$ERROR($$$GeneralError,"Query Key name must be supplied in %SpecToJoinIndex")
			Quit
		}

		Set tFactCount = $G($$$DeepSeeMetaGLVN("cubes",pCube,"factCount"))
		
		Set tOrCount = $LL(pSpec)/(tFactCount+1)		// DTB187 - Test the spec for heterogeneous OR
		For oc=1:1:tOrCount {
			Set tOrOffset = (oc-1)*(tFactCount+1)
			Set tRelNo = $O(pRelation(""),1,tRelName)
			
			While (tRelNo'="") {
				Set tKeyCode = $LG(pSpec,tRelNo+1+tOrOffset)		// DTB187 - Add OR offset
				Set tKeyCode= ##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tKeyCode) // JSL4407
				// JMD1017 use hash to prevent subscript error
				Set tKeyCodeHash = $S($L(tKeyCode)<100:tKeyCode,1:$ZCRC(tKeyCode,7))
				
				If ((tKeyCode '= "")&&'$D(pIntersect(tRelNo,tKeyCodeHash))) {
					Set pIntersect(tRelNo,tKeyCodeHash) = "" // track that we have visited this intersection
					Set tRemoteCube = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCube,"relations",$$$UPPER(tRelName),"relatedCube")))
					
					If (pUseAgents) {
						// DTB704 - This is now handled by the %DeepSee.WorkMgr
						Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(pGroupId,"JOININDEX",pCube,pKey,tRemoteCube,tRelNo,tKeyCode)
					}
					Else {
						Set tSC = ..%CreateJoinIndex(pCube,tRemoteCube,tRelNo,tKeyCode,pKey)
					}
					
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB
				}
				
				Set tRelNo = $O(pRelation(tRelNo),1,tRelName)
			}		// tRelNo
		}			// tOrCount
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// This is a deep relationships spec conversion method. It will take the subquery text and convert the spec
/// to the original form. This takes in a related cube that is running the query, the cube of the target relationship dimension,
/// the name of the relation, the spec text, and if the output should include the key or not.
ClassMethod %ConvertDeepSpec(pDRelCube As %String, pSpecialRelCube As %String, pRelName As %String, pDSpec As %String, pIncludeKey As %Boolean = 0) As %String [ Internal ]
{
	// Method added by PFS081
	Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pDSpec,.tSpecInfo)
	
	Set tDRelSpec = ""
	Set tDKeyIdx = $O(tSpecInfo(""),-1,tDKey)
	Set tDKey = $$$dsEscapeIdent(tDKey)
	Set tDLevelSpec = $Replace($Piece(pDSpec,tDKey,1,*-1),".&[","")
	Set tSpecialRelCube = $$$UPPER(pSpecialRelCube)
	Set tRelName = $$$UPPER(pRelName)
	
	If tDLevelSpec_".&["_tDKey_"]"'=pDSpec {
		// PFS081 - This is a complex spec, create query object and recurse through object
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tMDX = "SELECT "_pDSpec_" on 0 FROM ["_ tSpecialRelCube _"]"
		D tRS.%ParseMDX(tMDX,.tQuery)
		Set tAxis = tQuery.axes.GetAt(1)
		Set tSC = ##class(%DeepSee.Query.Engine).%ConvertDeepMemberSpec(pDRelCube, tSpecialRelCube, tRelName, .tAxis)
		Set tDRelSpec = tAxis.%ToString()
	} Else {
		Set tDRelSpecList = $LB(tRelName)
		Set tDInfoPos = $O(tSpecInfo(""))
		While tDInfoPos<tDKeyIdx {
			Set tDRelSpecList = tDRelSpecList _ $LB(tSpecInfo(tDInfoPos))
			Set tDInfoPos = $O(tSpecInfo(tDInfoPos))
		}
		
		Set tDRelSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec(tDRelSpecList)
		
		If pIncludeKey {
			Set tDRelSpec = tDRelSpec _ ".&[" _ $$$dsEscapeIdent(tDKey) _ "]"
		}
	}
	
	Quit tDRelSpec
}

/// This method will iterate through the query object of a complex spec. Once a memberSpec is reached,
/// the spec will be replaced by the original top level query spec. This helps match the tIntersectIndex
ClassMethod %ConvertDeepMemberSpec(pDRelCube As %String, pSpecialRelCube As %String, pRelName As %String, pNode As %DeepSee.Query.node) As %Status [ Internal ]
{
	// Method added by PFS081
	Set tSC = $$$OK
	
	If pNode.%IsA("%DeepSee.Query.range") {
		// Convert both start and end members
		Set tStartMember = pNode.startMember
		Set tEndMember = pNode.endMember
		Set tSC = ##class(%DeepSee.Query.Engine).%ConvertDeepMemberSpec(pDRelCube, pSpecialRelCube, pRelName,.tStartMember)
		If $$$ISERR(tSC) Quit tSC
		Set tSC = ##class(%DeepSee.Query.Engine).%ConvertDeepMemberSpec(pDRelCube, pSpecialRelCube, pRelName,.tEndMember)
		If $$$ISERR(tSC) Quit tSC
	} ElseIf pNode.%IsA("%DeepSee.Query.memberSpec") {
		// We have found a member spec, convert this simple spec
		Set pNode.spec = ##class(%DeepSee.Query.Engine).%ConvertDeepSpec(pDRelCube, pSpecialRelCube, pRelName, pNode.spec, 1)
	} Else {
		// Loop through children nodes to see if they contain a member spec
		For i=1:1:pNode.children.Count() {
			Set tChild = pNode.children.GetAt(i)
			Set tSC = ##class(%DeepSee.Query.Engine).%ConvertDeepMemberSpec(pDRelCube, pSpecialRelCube, pRelName,.tChild)
		}
	}
	
	Quit tSC
}

/// Given a cube, a remote cube, and a "key code" describing an interection against
/// the remote cube, construct an index in the cube based on intersecting the remote
/// bits and transposing to local bits.
ClassMethod %CreateJoinIndex(pCube As %String, pRemoteCube As %String, pFactNo As %Integer, pKeyCode As %String, pQueryKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tLock = 0
	Try {
		Set tStartTime = $ZH
		// DTB968 - Note logging and start local timer
		$$$dsSetLogging
		$$$dsStartTimer
		
		// JMD1501 normalize key code so that it matches when we use it later
		Set pKeyCode = ##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(pKeyCode)

		// JMD1017 use hash to prevent subscript error
		Set tKeyCodeHash = $S($L(pKeyCode)<100:pKeyCode,1:$ZCRC(pKeyCode,7))

		Set tUseCache = 1
		If $IsObject($G(%query)) {
			Set tUseCache = %query.useCache
		}

		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tRemoteCubeIndex = $$$DeepSeeIndex(pRemoteCube)
		// Get details on relationship
		Set tRelName = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCube,"rel#",pFactNo)))
		If (tRelName="") {
			Set tSC = $$$ERROR($$$GeneralError,"%CreateJoinIndex: Invalid relation number")
			Quit
		}
		Set tCardinality = $G($$$DeepSeeMetaGLVN("cubes",pCube,"relations",tRelName,"cardinality"))
		Set tStoredSide = +$G($$$DeepSeeMetaGLVN("cubes",pCube,"relations",tRelName,"storedSide"))
		If ('tStoredSide) {
			// find information on fact from remote cube
			Set tInverse = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",pCube,"relations",tRelName,"inverse")))
			Set tFactInfo = $G($$$DeepSeeMetaGLVN("cubes",pRemoteCube,"mbrs",tInverse))
			// JMD1102 test for bad meta data
			If (tFactInfo="") {
				Set tSC = $$$ERROR($$$GeneralError,"%CreateJoinIndex: Invalid inverse relation: " _ pRemoteCube _ "." _ tInverse)
				Quit
			}
			Set tFactNode = $G($$$DeepSeeMetaGLVN("cubes",pRemoteCube,"mbr#",$LG(tFactInfo,1),$LG(tFactInfo,2),$LG(tFactInfo,3)))

			Set tRemoteFact = $LG(tFactNode,5)
			Set tFactName = $G($$$DeepSeeMetaGLVN("cubes",pRemoteCube,"fact#",tRemoteFact))
			// +DTB163
			If $D($$$DeepSeeMetaGLVN("cubes",tRemoteCubeIndex,"fact","prop",tFactName,"alias")) {
				// The reverse lookup index for relationships is built on the relationship's
				// factName, if it exists.
				Set tFactName = $$$UPPER($$$DeepSeeMetaGLVN("cubes",tRemoteCubeIndex,"fact","prop",tFactName,"alias"))
			}
			set tFactName = $$$UPPER(tFactName)	
			// -DTB163
		}

		// JMD1403: lock while building join index
		Lock +$$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash):30
		If '$Test {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to get lock for join index")
			Quit
		}
		Set tLock = 1
		
		// WAL297 -- evaluate why we are having a problem with deciding to use the cached join
		//           index in the case of deep relationships here
		//           Use pKeyCode *not* tKeyCodeHash
		Set tFresh = 1

		// DP-418010 - If there are related queries in the address, test each of the subqueries to see if this
		// cell cache address is up to date. This starts by walking the subquery array and compares to the supplied address.
		Merge:'$D(tSubQueries) tSubQueries = $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"subquery")
	
		Set tSubQueryCube = $O(tSubQueries(""))
		While ((tSubQueryCube'="")&&tFresh) {
			Set tSubQueryKey = $O(tSubQueries(tSubQueryCube,""))
			While ((tSubQueryKey'="")&&tFresh) {
				// Check to see if this subQuery is in the cell cache address at all. If it is check the timestamps.
				Set pos = 0
				For k = 1:1:($L(pKeyCode,"@"_tSubQueryKey)-1) {
					// DP-418010 - Test all instances of the current subquery in the cell cache address itself for up-to-date
					// If any are stale, then the whole address is stale.
					Quit:'tFresh
				
					Set pos = $Find(pKeyCode,tSubQueryKey,pos)
					Set tSubQCellAddr = "@"_tSubQueryKey_$P($P($E(pKeyCode,pos,*),":",1),"*",1)

					Set:'$D(tCubeTime(tSubQueryCube)) tCubeTime(tSubQueryCube) = ##class(%DeepSee.Utils).%GetCubeDSTime(tSubQueryCube)
					Set tFresh = '(tCubeTime(tSubQueryCube)>$P(tSubQCellAddr,"-",4))
				}

				Set tSubQueryKey = $O(tSubQueries(tSubQueryCube,tSubQueryKey))
			}

			Set tSubQueryCube = $O(tSubQueries(tSubQueryCube))
		}

		// JMD1013: join timestamp is "remote:local" timestamp. Test this against the individual 
		// participants' individual timestamps.
		Set tThisTimestamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tCubeIndex)		// DTB838 - Fetch the common timestamp
		Set tRemoteTimestamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tRemoteCubeIndex)
		Set tLocalTimestamp = $G($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash))
		Set tLocalTimestampR = $P(tLocalTimestamp,":",1)
		Set tLocalTimestampL = $P(tLocalTimestamp,":",2)
		
		Set tActiveChunkOnly = 0
		// WAL297 -- check tFresh
		If (tFresh && tUseCache && (tRemoteTimestamp'="")&&((+tRemoteTimestamp)=(+tLocalTimestampR))&&((+tThisTimestamp)=(+tLocalTimestampL))) {
			// DP-405521 - Recalculate only the active chunk since it exists outside
			// the bounds of bucket invalidation and should always be recalculated. This would be true if the 
			// remote cube has not changed at all, since local pointers to related facts could be all that was changed.
			Set tActiveChunkOnly = +$G($$$DeepSeeActiveChunk(tCubeIndex))
		}
		ElseIf (tRemoteTimestamp="") {
			// cache has been deleted; provide a timestamp for current data
			Set tRemoteTimestamp = 1
			Set $$$DeepSeeResultsGLVN(tRemoteCubeIndex) = tRemoteTimestamp
		}
				
		If 'tActiveChunkOnly&&$D($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash)) {
			// DTB304 - Only kill if there is data to avoid unnecessary DB write lock
			Kill $$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash)
		}

		// split key code into component queries
		// take off leading "@" off of each piece
		// JMD852: use "*" to delimit pieces
		Set qn = 0
		For q = 1:1:$L(pKeyCode,"*") {
			Set x = $P(pKeyCode,"*",q)
			If ($E(x)="@") {
				Set qn = qn + 1

				// JMD1017: this could be an OR list!
				For q2 = 1:1:$L(x,"|") {
					Set x2=$E($P(x,"|",q2),2,*)
					Set tQueryKey(qn,q2) = $P(x2,"-",1)
					Set tNodeNo(qn,q2) = $P(x2,"-",2)
					Set tRFactNo(qn,q2) = $P(x2,"-",3)
				}
			}
			ElseIf (x=-1E14) {
				// if there is a null in the list, then there are no results
				Kill tQueryKey
				Quit
			}
		}

		Set q2 = $O(tQueryKey(1,""))
		If ((q2="")||($G(tQueryKey(1,q2))="")) {
			Quit  // only null value
		}

		// test if we need to OR some results
		If ((tCardinality="many")&&(tStoredSide)) {
			Set tUseOR = 1
		}
		Else {
			Set tUseOR = 0
		}

		// !!! for OR we cannot rely on first query only
		// use first query to loop over results
		// (this is ok, as we are ANDing the results)
		// visit each chunk of bits and convert to local id #s
		// tResultSlot is bucket # in remote cube
		Set tUseLocalIndex = 1 // if true, process index masking using local var
		Set tResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,q2),"data",""))

		While (tResultSlot '= "") {
			// JMD1403: we seem to have a 2D cell address...
			If ($G(tNodeNo(1,q2)) = "") {
				Set tNodeNo(1,q2) = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,q2),"data",tResultSlot,""))
			}

			If ($G(tNodeNo(1,q2)) = "") {
				Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,q2),"data",tResultSlot,""))
			}
			Else {
				Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,q2),"data",tResultSlot,tNodeNo(1,q2),""))
			}

			// loop over remote chunks
			While (tChunk '= "") {
				Kill tMask
				Set tOffset = (tChunk-1)*64000
				// OR the qx's
				Set qx = $O(tQueryKey(1,""))
				While (qx'="") {
					If ($G(tNodeNo(1,qx)) = "") {
						Set tMaskB = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,qx),"data",tResultSlot,tChunk))					// DTB187 - Use qx
					}
					Else {
						Set tMaskB = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,qx),"data",tResultSlot,tNodeNo(1,qx),tChunk))	// DTB187 - Use qx
					}
					// DTB970
					$$$dsBitFind(tMaskB,1,tTempBitPos)
					Set:tTempBitPos=0 tMaskB = ""
					If $G(tMask)="" {
						Set tMask = tMaskB
					}
					Else {
						$$$dsBitAorBIntoA(tMask,tMaskB)
					}
					Set qx = $O(tQueryKey(1,qx))
				}

				// combine mask against other results, if any
				Set q = $O(tQueryKey(1))
				While ((tMask'="")&&(q'="")) {
					Kill tMaskC
					Set qx2 = $O(tQueryKey(q,""))
					Set qx = $O(tQueryKey(q,""))
					While (qx'="") {
						// JMD1403: we seem to have a 2D cell address...
						If ($G(tNodeNo(q,q2)) = "") {
							Set tNodeNo(q,q2) = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(q,q2),"data",tResultSlot,""))
						}

						If ($G(tNodeNo(q,qx)) = "") {
							Set tMaskB = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(q,qx),"data",tResultSlot,tChunk))					// DTB187 - Use qx
						}
						Else {
							Set tMaskB = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(q,qx),"data",tResultSlot,tNodeNo(q,qx),tChunk))	// DTB187 - Use qx
						}
						// DTB970
						$$$dsBitFind(tMaskB,1,tTempBitPos)
						Set:tTempBitPos=0 tMaskB = ""
						If $G(tMaskC)="" {
							Set tMaskC = tMaskB
						}
						Else {
							$$$dsBitAorBIntoA(tMaskC,tMaskB)
						}
						// JMD1102 use q not 1 for first subscript
						Set qx = $O(tQueryKey(q,qx))
					}

					If ($G(tNodeNo(q,qx2)) = "") {
						If (tUseOR) {
							$$$dsBitAorBIntoA(tMask,tMaskC)			// DTB970
						}
						Else {
							$$$dsBitAandBIntoA(tMask,tMaskC)		// DTB970
						}
					}
					Else {
						If (tUseOR && ($G(tRFactNo(q,qx2))=$G(tRFactNo(1,q2)))) {
							// OR items from same fact; otherwise AND
							$$$dsBitAorBIntoA(tMask,tMaskC)			// DTB970
						}
						Else {
							$$$dsBitAandBIntoA(tMask,tMaskC)		// DTB970
						}
					}
					// DTB970
					$$$dsBitFind(tMask,1,tTempBitPos)
					Set:tTempBitPos=0 tMask = ""
					Set q = $O(tQueryKey(q))
				}

				// flip bits from remote to local (based on whether this is the stored side)
				If (tMask'="") {
					If (tStoredSide) {
						// e.g., select patient.mbr from lab
						// look at each bit--these are the ids of the remote table
						$$$dsBitFind(tMask,1,tBit)		// DTB970
						While (tBit > 0) {
							Set tRemoteId = tOffset + tBit - 1

							// convert RemoteId to local id(s) using bitmap relation index
							If ($D($$$DeepSeeIndexGLVN(tCubeIndex,pFactNo,tRemoteId))) {
								Set tLocalChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFactNo,tRemoteId,""),1,data)
								While (tLocalChunk '= "") {
									// DP-426867 - Continue with this chunk if all chunks are being processed, or if it is the active chunk
									// since the cache for the active chunk is always reset.
									If 'tActiveChunkOnly || (tLocalChunk = $G($$$DeepSeeActiveChunk(tCubeIndex))) {
										If (tUseLocalIndex) {
											$$$dsBitAorBIntoA(tJoinIndex(tLocalChunk),data)		// DTB970
										}
										Else {
											// DTB970
											$$$dsBitAorBIntoA(data,$$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk))
											$$$dsBitFind(data,1,tTempBit)
											If (tTempBit>0) {
												Set $$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk) = data
											}
											Else {
												Kill $$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk)
											}
										}
									}
									Set tLocalChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFactNo,tRemoteId,tLocalChunk),1,data)
								} 
							}
							
							$$$dsBitFindNext(tMask,1,tBit+1,tBit)		// DTB970
						}
					}
					Else {
						// e.g., select lab.mbr from patient
						$$$dsBitFind(tMask,1,tBit)		// DTB970
						While (tBit > 0) {
							Set tRemoteId = tOffset + tBit - 1

							// convert RemoteId to local id using inverse relation index
							Set tID = $O($$$DeepSeeRelationGLVN(tRemoteCubeIndex,tFactName,tRemoteId,""))
							If (tID '= "") && (tID'=-1E14) {
								Set tLocalChunk = tID\64000+1
								Set tLocalOffset = tID#64000+1
								If 'tActiveChunkOnly || (tLocalChunk = $G($$$DeepSeeActiveChunk(tCubeIndex))) {		// DP-405521 - Continue calculation if this is the active chunk for this cube
									If (tUseLocalIndex) {
										$$$dsBitSet(tJoinIndex(tLocalChunk),tLocalOffset,1)		// DTB970
									}
									Else {
										$$$dsBitSet($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk),tLocalOffset,1)		// DTB970
									}
								}
								// Note: Deleted inclusion of $O call that was meant in-case there were multiple IDs
								// There is at-most-one ID to be found in this lookup as the index is not created for the cardinality="many" direction
								// When included, the line of code did not have a functional purpose and caused queries to take significantly longer.
							}
							$$$dsBitFindNext(tMask,1,tBit+1,tBit)		// DTB970
						}
					}
				}

				// next chunk
				If ($G(tNodeNo(1,q2)) = "") {
					Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,q2),"data",tResultSlot,tChunk))
				}
				Else {
					Set tChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,q2),"data",tResultSlot,tNodeNo(1,q2),tChunk))
				}
			}

			// next result slot
			Set tResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey(1,q2),"data",tResultSlot))
		}
		// compress and copy new join index into final location
		// DTB304 - Engage $SortBegin to collect all results before transferring them to the final global
		Set x = $SortBegin($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash))	
		
		If (tUseLocalIndex) {
			// DP-405521 - If tActiveChunkOnly then the local tJoinIndex should only contain the
			// active chunk and doesn't need an extra check for inclusion
			Set tLocalChunk = $O(tJoinIndex(""),1,data)
			While (tLocalChunk '= "") {
				$$$dsBitFind(data,1,tTempBit)		// DTB970
				If (tTempBit>0) {
					$$$dsBitNormalize(data,$$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk))		// DTB970
				}
				Set tLocalChunk = $O(tJoinIndex(tLocalChunk),1,data)
			}
		}
		Else {
			Set tLocalChunk = $O($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,""),1,data)
			While (tLocalChunk '= "") {
				// DP-426867 - Continue with this chunk if all chunks are being processed, or if it is the active chunk
				// since the cache for the active chunk is always reset.
				If 'tActiveChunkOnly || (tLocalChunk = $G($$$DeepSeeActiveChunk(tCubeIndex))) {
					$$$dsBitFind(data,1,tTempBit)		// DTB970
					If (tTempBit>0) {
						$$$dsBitNormalize(data,$$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk))		// DTB970
					}
					Else {
						Kill $$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk)
					}
				}	

				Set tLocalChunk = $O($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash,tLocalChunk),1,data)
			}
		}

		// Set timestamp for index
		// JMD1013: join timestamp is "remote:local" timestamp
		Set $$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash) = tRemoteTimestamp_":"_tThisTimestamp

		// DTB304 - Commit the entries to the JoinIndex
		Set x = $SortEnd($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash))

		// mark number of join indices and time spent
		Set x = $I($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"stats","JoinIndexCount"))
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"stats","JoinIndexTime") = $G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"stats","JoinIndexTime")) + ($ZH - tStartTime)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	// JMD1403
	If (tLock) {
		Lock -$$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash):30
		// DTB304 - Commit the entries if something went wrong so it can be examined
		Set x = $SortEnd($$$DeepSeeJoinGLVN(tCubeIndex,pFactNo,tKeyCodeHash))
	}
	
	$$$dsStopTimer		// DTB968
	
	Quit tSC
}

/// Given a cube and member within a cube (fact and id value), find the distinct
/// set of correlated members in one or more other facts (given by list of fact numbers: <var>pFactList</var>).
/// This is used by compound cubes.<br/>
/// On return <var>pMembers</var> contains the set of distinct id values.<br/>
/// This takes the form: pMembers(n) = $LB(fact1id,fact2id,...)
/// <var>pStatement</var> is the SQL statement object used to fetch the results. It is possible
/// to pass this into a subsequent call to avoid re-preparing the query.
ClassMethod %GetCorrelatedMembers(pCube As %String, ByRef pStatement As %SQL.StatementResult, Output pMembers, pFactNo As %Integer, pFactId As %String, pFactList As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pMembers
		Set tCube = $$$UPPER(pCube)
		Set tFactTable = ##class(%DeepSee.Utils).%GetCubeFactTable(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tFactCount = $LL(pFactList)
		If '$IsObject($G(pStatement)) {
			Set tSELECT = ""
			For n=1:1:tFactCount {
				Set t = +$LG(pFactList,n)
				Set tFName = $$$DeepSeeMetaGLVN("cubes",tCube,"fact#",t)
				Set tSELECT = tSELECT_$S(tSELECT="":"",1:",") _ tFName
			}

			Set tFactName = $$$DeepSeeMetaGLVN("cubes",tCube,"fact#",pFactNo)

			Set tSQL = "SELECT DISTINCT "_tSELECT_" FROM " _ tFactTable _ " WHERE " _ tFactName _ "=?"

			Set pStatement = ##class(%SQL.Statement).%New()
			Set tSC = pStatement.%Prepare(tSQL)
			If $$$ISERR(tSC) Quit
		}
		Set tCount = 0
		Set tRS = pStatement.%Execute(pFactId)
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tItem = ""
			For n=1:1:tFactCount {
				Set tItem = tItem_$LB(tRS.%GetData(n))
			}
			Set tCount = tCount + 1
			Set pMembers(tCount) = tItem
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// For a level (<var>pFactNo</var>) with a dependsOn attribute, find the set of members 
/// that apply for the given "master" fact.
ClassMethod %FindDependentMembers(pCube As %String, ByRef pMemberIds As %String, pFactNo As %Integer, pMasterFactNo As %Integer, pMasterId As %String, pConditionNo As %Integer = 0) As %Status [ Internal ]
{
	// JMD910
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		If (pMasterId="") Quit

		Set tIndexName = pMasterFactNo_"&"_pFactNo

		// look at combo index: split apart | or list if present
		For p=1:1:$L(pMasterId,"|") {
			Set tIsNot = 0
			Set tMasterId = $P(pMasterId,"|",p)
			If ($E(tMasterId)="!") {
				// JMD1120
				Set tIsNot = 1
				Set tMasterId = $E(tMasterId,2,*)

				// start with list of all ids and prune
				Set tMbrId = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFactNo,""))
				While (tMbrId'="") {
					Set tMemberIds(tMbrId) = ""
					Set tMbrId = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFactNo,tMbrId))
				}
			}
			Set tMbrId = $O($$$DeepSeeIndexGLVN(tCubeIndex,tIndexName,tMasterId,""))
			While (tMbrId'="") {
				Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,tIndexName,tMasterId,tMbrId,""))
				While (tChunk'="") {
					If (tIsNot) {
						// prune (JMD1120-fix test)
						$$$dsBitFind($$$DeepSeeIndexGLVN(tCubeIndex,tIndexName,tMasterId,tMbrId,tChunk),1,tBitPos)		// DTB981
						If (tBitPos=0) {
							Kill tMemberIds(tMbrId)
							Quit
						}
					}
					Else {
						$$$dsBitFind($$$DeepSeeIndexGLVN(tCubeIndex,tIndexName,tMasterId,tMbrId,tChunk),1,tBitPos)		// DTB981
						If tBitPos {
							Set tMemberIds(tMbrId) = ""
							Quit
						}
					}
					Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,tIndexName,tMasterId,tMbrId,tChunk))
				}
				Set tMbrId = $O($$$DeepSeeIndexGLVN(tCubeIndex,tIndexName,tMasterId,tMbrId))
			}
		}

		/// JMD947: make sure multiple tests are ANDed.
		If (pConditionNo=1) {
			Merge pMemberIds = tMemberIds
		}
		Else {
			Set k = $O(pMemberIds(""))
			While (k'="") {
				If '$D(tMemberIds(k)) {
					Kill pMemberIds(k)
				}
				Set k = $O(pMemberIds(k))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Process any subset functions that have been noted for processing in the axis cache under<br>
///   ^DeepSee.Cache.Axis(cube,axisKey,"subset")<br>
/// For each subset node the results currently in the result cache will be trimmed according to the subset
/// function and the count of that subset function. If multiple subset functions are nested within one another,
/// the innermost function will be processed first and subsequent nested functions will be processed on the remaining
/// results.<br>
/// If these nodes do not exist in the axis cache this method will do nothing.
ClassMethod %ProcessResultSubset(pCube, pQueryKey, pAxisNo) As %Status
{
	// Method added by DTB327
	Set tSC = $$$OK
	Try {
		Set tAxisKey = $G($$$DeepSeeResultsGLVN(pCube,pQueryKey,"axis",pAxisNo))
		If tAxisKey="" {
			Set tSC = $$$ERROR($$$GeneralError,$$$FormatText("Query %1 does not have axis %2 defined"),pQueryKey,pAxisNo)
			Quit
		}
		
		Set tLevel = 0
		
		// Process any subset functions from the highest node number backwards. This will
		// ensure inner nested subsets are processed first.
		Set tSubsetNodeNo = $O($$$DeepSeeAxisGLVN(pCube,tAxisKey,"subset",""),-1)
		While (tSubsetNodeNo'="") {
			Set tSubsetIndex = $O($$$DeepSeeAxisGLVN(pCube,tAxisKey,"subset",tSubsetNodeNo,""),1,tSubsetData)	// DTB328 - Multiple truncations for the same set are possible
			While tSubsetIndex'="" {
				Set tNodeCount = 0
				Kill tVisitedNodes
				
				Set tFunction = $LG(tSubsetData,1)
				Set tStartIndex = +$LG(tSubsetData,2)
				Set tCount = +$LG(tSubsetData,3)
				
				// DTB328 - Set endpoint conditions according to the truncation function in play
				If (tFunction = "SUBSET") {
					Set tEndIndex = $S(tCount="":1E100,1:tStartIndex + tCount - 1)
				}
				Else {
					Set tEndIndex = tStartIndex + tCount
				}
				
				Set tDirection = $Case(tFunction,"HEAD":1,"SUBSET":1,"TAIL":-1,:1)
			
				Set tAxisNode = $O($$$DeepSeeAxisGLVN(pCube,tAxisKey,"axes",1,"all",""),tDirection)
				While (tAxisNode'="") {
					Set tNodeIsVisible = $LG($$$DeepSeeAxisGLVN(pCube,tAxisKey,"axes",tAxisNode),2,0)
					
					If tNodeIsVisible {
						If (pAxisNo=1) {
							If ($D($$$DeepSeeResultsGLVN(pCube,pQueryKey,"data",0,tAxisNode)) || $D($$$DeepSeeResultsGLVN(pCube,pQueryKey,"nonempty",pAxisNo,tAxisNode))) {
								// If there is a result for this node, see if we should count it as part of the subset
								Set tParent = $LG($$$DeepSeeAxisGLVN(pCube,tAxisKey,"axes",tAxisNode),4)
								
								While tParent>=tSubsetNodeNo {
									// Search up to see if the set of interest is an ancestor
									If (tParent=tSubsetNodeNo) {
										Set tNodeCount = tNodeCount+1
									}
									
									Set tParent = $LG($$$DeepSeeAxisGLVN(pCube,tAxisKey,"axes",tParent),4)
								}
							}
							
							If (tNodeCount>tEndIndex)||(tNodeCount<tStartIndex) {
								// Kill the results nodes that are outside of the set
								Kill $$$DeepSeeResultsGLVN(pCube,pQueryKey,"data",0,tAxisNode)
								// Remove the corresponding nonempty node
								Kill $$$DeepSeeResultsGLVN(pCube,pQueryKey,"nonempty",pAxisNo,tAxisNode)
							}
						}
						ElseIf (pAxisNo=2) {
							Set tAxis1Node = $O($$$DeepSeeResultsGLVN(pCube,pQueryKey,"data",0,""))
							While (tAxis1Node'="") {
								// Loop through all data on the other axis
								If ($D($$$DeepSeeResultsGLVN(pCube,pQueryKey,"data",0,tAxis1Node,tAxisNode)) || $D($$$DeepSeeResultsGLVN(pCube,pQueryKey,"nonempty",pAxisNo,tAxisNode))) {
									// If there is a result for this node, see if we should count it as part of the subset
									Set tParent = $LG($$$DeepSeeAxisGLVN(pCube,tAxisKey,"axes",tAxisNode),4)
									
									While tParent>=tSubsetNodeNo {
										// Search up to see if the set of interest is an ancestor
										If (tParent=tSubsetNodeNo) {
											// In the two-axis case, keep note of each axis 2 node has been visited.
											// If it is a new node, add it to the count
											If '$D(tVisitedNodes(tAxisNode)) {
												Set tNodeCount = tNodeCount + 1
												Set tVisitedNodes(tAxisNode) = 1
											}
										}
										
										Set tParent = $LG($$$DeepSeeAxisGLVN(pCube,tAxisKey,"axes",tParent),4)
									}
								}
								
								If (tNodeCount>tEndIndex)||(tNodeCount<tStartIndex) {
									// Kill the results nodes that are outside of the set
									Kill $$$DeepSeeResultsGLVN(pCube,pQueryKey,"data",0,tAxis1Node,tAxisNode)
									// Remove the corresponding nonempty node
									Kill $$$DeepSeeResultsGLVN(pCube,pQueryKey,"nonempty",pAxisNo,tAxisNode)
								}
								
								Set tAxis1Node = $O($$$DeepSeeResultsGLVN(pCube,pQueryKey,"data",0,tAxis1Node))
							}
						}
					}			// node is visible
					
					Set tAxisNode = $O($$$DeepSeeAxisGLVN(pCube,tAxisKey,"axes",1,"all",tAxisNode),tDirection)
				}
				
				Set tSubsetIndex = $O($$$DeepSeeAxisGLVN(pCube,tAxisKey,"subset",tSubsetNodeNo,tSubsetIndex),1,tSubsetData)
			}
			Set tSubsetNodeNo = $O($$$DeepSeeAxisGLVN(pCube,tAxisKey,"subset",tSubsetNodeNo),-1)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Diagnostic.
ClassMethod %PrintCells(pCubeName As %String, pKey As %String) [ Internal ]
{
	Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
	Set a = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"axis",""))
	While (a'="") {
		Set tAxisKey(a) = $$$DeepSeeResultsGLVN(tCubeIndex,pKey,"axis",a)
		Set a = $O($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"axis",a))
	}
	If ('$D(tAxisKey(1))||'$D(tAxisKey(2))) {
		Write "Query must have 2 dimensions",!
		Quit
	}

	// columns	
	Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(1),"axes",1))
	While (tNodeNo'="") {
		Set tCols(tNodeNo) = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(1),"axes",tNodeNo)
		Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(1),"axes",tNodeNo))
	}

	// rows
	Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(2),"axes",1))
	While (tNodeNo'="") {
		Set tRows(tNodeNo) = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(2),"axes",tNodeNo)
		Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(2),"axes",tNodeNo))
	}
	
	Set wid = 8
	Set indent = 15
	Set n = 0
	Set c = $O(tCols(""))
	While (c'="") {
		Set tType = $LG(tCols(c),1)
		Write ?indent+(n*wid),c,":",tType,$S($LG(tCols(c),2):"*",1:"")
		Set n = n + 1
		Quit:(indent+(n*wid))>79
		Set c = $O(tCols(c))
	}
	Write !

	Set n = 0
	Set c = $O(tCols(""))
	While (c'="") {
		Set tType = $LG(tCols(c),1)
		Set tName = $Case(tType,"exp":$LG(tCols(c),6),"lit":$LG(tCols(c),6),"agg":$LG(tCols(c),6),:$LG(tCols(c),5))
		Write ?indent+(n*wid),$E(tName,1,wid-2)
		Set n = n + 1
		Quit:(indent+(n*wid))>79
		Set c = $O(tCols(c))
	}
	Write !
	
	Set r = $O(tRows(""))
	While (r'="") {
		Set tType = $LG(tRows(r),1)
		Set tName = $Case(tType,"exp":$LG(tRows(r),6),"lit":$LG(tRows(r),6),"agg":$LG(tRows(r),6),:$LG(tRows(r),5))
		Write $J(r,2)," ",$S($LG(tRows(r),2):"*",1:" "),tType," ",tName

		// cell values
		Set n = 0
		Set c = $O(tCols(""))
		While (c'="") {
			Set tValue = $G($$$DeepSeeResultsGLVN(tCubeIndex,pKey,"data",0,c,r))
			Write ?indent+(n*wid),$E(tValue,1,wid-1)
			Set n = n + 1
			Quit:(indent+(n*wid))>79
			Set c = $O(tCols(c))
		}

		Write !

		Set r = $O(tRows(r))
	}
}

/// Given a current address in the results cache, find the root node for the aggregate. If the input address is not the
/// child of an aggregate, change nothing. If <var>pFindAggregate</var>=1, then search the axes for a special aggregate node.
/// If none is found, 
ClassMethod %ResolveAggregateAddress(pCubeIndex = "", pQueryKey = "", ByRef pAddr, pRealAxisCount = "", pFindAggregate = 0) As %Status
{
	// Method added by DTB400
	Set tSC = $$$OK
	Merge pResolvedAddr = pAddr
 	Try {
		If (pCubeIndex="") {
			Quit
		}
		If (pQueryKey = "") {
			Quit
		}
		If (pRealAxisCount="") {
			Set pRealAxisCount = $O(pAddr(""),-1)
		}
		
		// Work up the chain from the current address to find the aggregate location
		For a=1:1:pRealAxisCount {
			Set tAxisKey = $G($$$DeepSeeResultsGLVN(pCubeIndex,pQueryKey,"axis",a))
			If tAxisKey'="" {
				// Check the original node supplied in the input address. If it is not part of an aggregate,
				// do not bother searching further.
				Set tNodeNo = pAddr(a)
				If ('pFindAggregate)&&(tNodeNo>0)&&($LG($$$DeepSeeAxisGLVN(pCubeIndex,tAxisKey,"axes",tNodeNo),24)="") Set tNodeNo=0
				
				While +tNodeNo>0 {
					Set tAggParentNo = $LG($$$DeepSeeAxisGLVN(pCubeIndex,tAxisKey,"axes",tNodeNo),24)
					If (tAggParentNo'="") {
						If (tAggParentNo=tNodeNo) {
							// Break out of the loop if this is the agg parent
							Quit
						}
						Else {
							// Check to see if this aggregate has a parent
							Set tNodeNo = tAggParentNo
						}
					}
					Else {
						// Use the natural parent of the node and keep looking
						Set tNodeNo = $LG($$$DeepSeeAxisGLVN(pCubeIndex,tAxisKey,"axes",tNodeNo),4)
					}

				}
			}
			If (+$G(tNodeNo)>1) {
				Set pAddr(a) = tNodeNo
			}
		}		// Axis
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Set the logging global to signal the engine to record events according to the appropriate level.
/// pLogLevel may be set to<br>
/// - 1 - Record basic metrics such as method timers
/// - 2 - Record actual counts of computational operations during query execution
ClassMethod %SetLogging(pLogLevel = 0)
{
	// Method added by DTB968
	Set tPrev = ..%GetLogSetting()
	Set $$$dsLoggingGlobal = pLogLevel
	Quit tPrev
}

/// Return the current MDX Engine log setting.
ClassMethod %GetLogSetting()
{
	// Method added by DTB968
	Quit $G($$$dsLoggingGlobal)
}

/// Clear all data stored in the runtime log. This preserves the original log level setting.
ClassMethod %ClearLog()
{
	// Method added by DTB968
	Set tPrev = ..%GetLogSetting()
	Kill $$$dsLoggingGlobal
	Do:(tPrev'="") ..%SetLogging(tPrev)
}

/// Diagnostic printout of the recorded computation metrics
ClassMethod %PrintLog(Output pStatistics, pVerbose = 1)
{
	Kill pStatistics
	Merge pStatistics =  $$$dsLoggingGlobal
	
	w:pVerbose !,"==== Engine Log Statistics ====",!
	w:pVerbose "- Timers -",!
	Set tTotalTime = 0
	Set tTimerName = $O(pStatistics("timers",""),1,tTime)
	While (tTimerName'="") {
		w:pVerbose ?2,tTimerName_": "_tTime,!
		Set tTotalTime = tTotalTime + tTime
		
		Set tTimerName = $O(pStatistics("timers",tTimerName),1,tTime)
	}
	w:pVerbose "Total Time: "_tTotalTime,!!
	
	w:pVerbose "- Bit Operations -",!
	Set tTotalCount = 0
	Set tOp = $O(pStatistics("ops",""))
	While (tOp'="") {
		w:pVerbose ?2,tOp,!
		
		Set tOpCount = 0
		Set tSource = $O(pStatistics("ops",tOp,"source",""),1,tSourceCount)
		While (tSource'="") {
			w:pVerbose ?4,tSource_": "_tSourceCount,!
			
			Set tOpCount = tOpCount + tSourceCount
			Set tTotalCount = tTotalCount + tSourceCount
			
			// Return a quick-reference total method count
			Set pStatistics("sources",tSource) = $G(pStatistics("sources",tSource)) + tSourceCount
			
			Set tSource = $O(pStatistics("ops",tOp,"source",tSource),1,tSourceCount)
		}
		w:pVerbose ?2,tOp_" Total: "_tOpCount,!
		
		Set tOp = $O(pStatistics("ops",tOp))
	}
	w:pVerbose "Total Operations: "_tTotalCount,!
	w:pVerbose "===============================",!
}

}
