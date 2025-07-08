/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized version of the member provider class used for relationships.<br/>
/// This providers delagates the job of providing information to the related cube
/// by generating queries against it.
Class %DeepSee.Query.memberRelationship Extends %DeepSee.Query.member [ System = 3 ]
{

/// Name of this relationship.
Property %relationship As %DeepSee.Datatype.entityName;

/// Member spec to apply against the related cube.
Property %remoteSpec As %String(MAXLEN = 30000);

/// Name of cube the relationship refers to.
Property %relatedCube As %DeepSee.Datatype.entityName;

/// Cardinality of the relationship.
Property %cardinality As %String;

/// Inverse of the relationship.
Property %inverse As %DeepSee.Datatype.entityName;

/// True if this is the No Relation member.
Property %isNullRelation As %Boolean [ InitialExpression = 0 ];

/// Is this the stored side of the relationship?
Property %isStoredSide As %Boolean [ InitialExpression = 0 ];

/// Used to hold additional values for %OR references 
Property %ORList As %String [ MultiDimensional ];

/// Depth (number of hops) of the relationship.
Property %relationshipDepth As %Boolean [ InitialExpression = 0 ];

/// List of additional related cubes more than one level away.
Property %deepCubes As %List;

/// Apply relationship information to this provider.<br/>
/// <var>pSpec</var> is an array of the tokens that make up the member specification.
Method %ApplyRelationInfo(ByRef pSpec, pRelatedCube As %String, pCardinality As %String, pInverse As %String, pIsStored As %Boolean, ByRef pMemberKey) As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%relationship = $G(pSpec(1))
		Set ..%relatedCube = $$$UPPER(pRelatedCube)
		Set ..%cardinality = pCardinality
		Set ..%inverse = $$$UPPER(pInverse)
		Set ..%isNullRelation = 0
		Set ..%isStoredSide = +pIsStored

		Set ..%hierNumber = 0
		Set ..%levelNumber = 0

		// validate
		If ('##class(%DeepSee.Utils).%CubeExists(..%relatedCube,.x)) {
			Set tSC  = $$$ERROR($$$GeneralError,"Cube referred to by relationship does not exist: "_..%relationship_"->"_..%relatedCube)
			Quit
		}

		// do not allow reference to measures in related cubes
		If ($$$UPPER($G(pSpec(2))) = "MEASURES") {
			Set tSC  = $$$ERROR($$$GeneralError,"References to measures in related cubes is not allowed: "_..%relationship_"."_pSpec(2))
			Quit
		}

		// check for reference to "no relation" member
		Set tNullRef = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..%cube),"relations",$$$UPPER(..%relationship),"nullReplacement"))
		Set tLastItem = ""
		Set tIsKey = 0
		Set k = $O(pSpec(""),-1)
		Set:k'="" tLastItem = $G(pSpec(k))
		Set:k'="" tIsKey = +$G(pMemberKey(k))

		// JMD972
		If (tIsKey) {
			If ((k=2)&&(tNullRef'="")&&("<null>"=tLastItem)) {
				Set ..%isNullRelation = 1
				Set ..%remoteSpec = tNullRef
				Quit
			}
		}
		Else {
			If ((k=2)&&(tNullRef'="")&&($$$UPPER(tNullRef)=$$$UPPER(tLastItem))) {
				Set ..%isNullRelation = 1
				Set ..%remoteSpec = tNullRef
				Quit
			}
		}

		// JMD1403 find the *depth* of the relationship: how many hops to actual cube
		Set ..%relationshipDepth = 1
		Set ..%deepCubes = ""
		Set tTargetCube = $$$UPPER(pRelatedCube)
		Set n = $O(pSpec(1))
		While (n'="") {
			Set tDim = $$$UPPER(pSpec(n))
			// is this a relationship?
			Set tIsRelation = ''$D($$$DeepSeeMetaGLVN("cubes",tTargetCube,"relations",tDim))
			If (tIsRelation) {
				Set ..%relationshipDepth = ..%relationshipDepth + 1
				Set tTargetCube = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",tTargetCube,"relations",tDim,"relatedCube")))
				Set ..%deepCubes = ..%deepCubes _ $LB(tTargetCube)
			}
			Else {
				Quit
			}
			Set n = $O(pSpec(n))
		}

		// assemble spec
		Set tSpec = ""
		Set tNeedDot = 0
		Set tIsRange = 0
		Set n = $O(pSpec(""))
		While (n'="") {
			If (+n > 1) {
				Set tItem = pSpec(n)
				If ($E(tItem,1)="(") {
					// function args
					Set tSpec = tSpec _ tItem
				}
				ElseIf ($E(tItem,1)=":") {
					// range
					Set tSpec = tSpec _ ":"
					Set tNeedDot = 0
					Set tIsRange = 1
					Set n = $O(pSpec(n)) // skip relation name
				}
				ElseIf (##class(%DeepSee.Query.memberFunction).%GetFunctionInfo(tItem,.tImplemented,.tArgCount,.tReturn,.tArgs,.tArgDesc)) {
					// function
					Set tSpec = tSpec _ $S(tNeedDot:".",1:"") _ tItem
					Set tNeedDot = 1
				}
				Else {
					If +$G(pMemberKey(n)) {
						Set tItem = "&["_$$$dsEscapeIdent(tItem)_"]"	// DTB112
					}
					Else {
						// PFS051 - Build spec with UPPER if this item is not the key
 						Set tItem = "["_$$$dsEscapeIdent($$$UPPER(tItem))_"]"		// DTB112
					}
					Set tSpec = tSpec _ $S(tNeedDot:".",1:"") _ tItem
					Set tNeedDot = 1
				}
			}
			Set n = $O(pSpec(n))
		}
		// JMD1449 wrap range in %OR
		If (tIsRange) {
			Set tSpec = "%OR("_tSpec_")"
		}

		Set ..%remoteSpec = tSpec

		// JMD972
		If ($E(tSpec,1,1)="&") {
			Set tSC  = $$$ERROR($$$GeneralError,"Incomplete or invalid relationship reference: "_..%relationship_"."_tSpec)
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Combine the given member object into this one.
/// This is used to combine %OR(members) into one statement.
Method %MergeOR(pMember2 As memberRelationship) As %Status
{
	Set tSC = $$$OK
	Try {
		// add spec to OR list
		If (pMember2.%remoteSpec'="") {
			Set ..%ORList(pMember2.%remoteSpec) = ""
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Process the member name and key information for this tuple.
/// Put the result into <var>pSet</var>.
Method %ProcessMembers(pParent As %Integer, Output pSet As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		$$$dsSetLogging		// DTB981
		
		Set tExists = ..%GetNodeInfo(..%cube,..%dimNumber, ..%hierNumber, ..%levelNumber, .tFact)
		If (tExists) {
			If (..%isNullRelation) {
				// NO relation member

				Set tNullRef = ..%remoteSpec
				// get caption for relation
				Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(..%cube, tNullRef, "", "", .tRelationCaption)
				If $$$ISERR(tSC) Quit
				Set:tRelationCaption="" tRelationCaption = tNullRef

				Set tFactId = -1E14
				Set tCaption = tNullRef

				// (for use by cmbr & listings)
				Set tRemoteSpec = ..%remoteSpec
				Set pSet(1) = $LB("mbr",1,1,+pParent,tCaption,tFactId,tFact,,..%dimNumber,..%hierNumber,..%levelNumber,,"",tRemoteSpec)
				// PFS089 - Populate this node so Deep Relation subqueries can be mapped back to their original query
				Set $List(pSet(1),22) = $LB(,..%deepCubes,..%relationshipDepth,..%relatedCube)
				Quit
			}

			// get name of fact class containing relationship index
			// and the name of the fact
			Set tStart = $ZH
			Set tLastCol = 0

			// query needs to resolve relationships
			Set %query.%hasRelations = 1

			// JMD1012: note in cache
			Set tCubeIndex = $$$DeepSeeIndex(..%cube)
			Set $$$DeepSeeAxisGLVN(tCubeIndex,%axisKey,"hasRelations") = 1

			If ($D(..%ORList)) {
				// construct %OR expression
				Set tORList = ""
				Set ko = $O(..%ORList(""))
				While (ko'="") {
					Set tORList = tORList _ $S(tORList="":"",1:",") _ ko
					Set ko = $O(..%ORList(ko))
				}
				Set tRemoteMbrs = "%OR({"_..%remoteSpec_$S(tORList="":"",1:",")_tORList_"})"
			}
			Else {
				Set tRemoteMbrs = ..%remoteSpec
			}

			// execute bitset sub-query against related cube
			Set tOnClause = $S(tRemoteMbrs="":" ",1:" ON COLUMNS ")

			Set tNonEmpty = $S($IsObject($G(%axisObject)):%axisObject.nonEmpty,1:0)
			// JMD1403: add non empty if we are the slicer
			If (+$G(%dsIsSlicer)) {
				Set tNonEmpty = 1
			}

			// JMD1069 add NON EMPTY to remote query
			Set tMDX = "%BITSET SELECT "_$S(tNonEmpty:"NON EMPTY ",1:"")_tRemoteMbrs_tOnClause _"FROM ["_..%relatedCube_"]"

			// JMD1069 see if there is anything interesting in the slicer!
			// (make sure *we* are not the slicer)
			// If so, push it into the subquery; things are filtered again later
			// so we do not have to be exact
			// DTB061 push the slicer regardless of the setting for NON EMPTY
			Set tPushSlicer = 1
			If (tPushSlicer&&'$G(%dsIsSlicer)&&$IsObject($G(%query))&&$IsObject(%query.slicer)) {
				Set tSC = ..%GetFiltersForRelationship(.tFilters,%query.slicer)
				If $$$ISERR(tSC) Quit
				Set km = $O(tFilters(""))
				While (km'="") {
					Set tMDX = tMDX _ " %FILTER "_tFilters(km)
					Set km = $O(tFilters(km))
				}
			}

			If +$G(%dsflags("RELATIONS")) {
				$$$DSWRITELN("*** (depth: "_..%relationshipDepth_")")
				$$$DSWRITELN("SUBQUERY: "_tMDX)
			}

			// JMD1403: if relationship has depth>1, add additional info;
			// later we may have to combine this with other information from another axis
			// and create a cell-specific sub query
			Set tSpecialInfo = ""
			If (tRemoteMbrs'="") {
				// spec,CUBE(s)
				Set tSpecialInfo = $LB(tRemoteMbrs,..%deepCubes,..%relationshipDepth,..%relatedCube)
			}

			// Create a resultSet for the query
			Set tRS = ##class(%DeepSee.ResultSet).%New()

			// pass on our named parameters to the subquery
			Merge tContext = %query.%NamedParameters
			Do tRS.%SetParameterContext(.tContext)
			Set tRS.%UseCache = %query.useCache
			Set tSC = tRS.%PrepareMDX(tMDX)
			If $$$ISERR(tSC) Quit
			
			// + WAL071 (2) -- make sure to use "root" query key in case this is a subquery's subquery
			Set tRS.%Query.parentQueryKey = $S(%query.parentQueryKey'="":%query.parentQueryKey,1:%query.%QueryKey)
			// - WAL071 (2)

			Kill tParmValues
			If (%query.useAgents) {		// DTB704 - Only test useAgents
				If ('$G(%verbose)) {
					Set tSC = tRS.%ExecuteAsynch(.tQueryKey,.tParmValues,1)
					If $$$ISERR(tSC) Quit
				}
				Else {
					Set tSC = tRS.%ExecuteAsynch(.tQueryKey,.tParmValues,0)
					If $$$ISERR(tSC) Quit

					// give feedback to shell
					Set tCube = tRS.%GetCubeName()
					Set tKey = tRS.%GetQueryKey()
					Write "Processing..."
					Hang 0.01
					Set tCount = 0
					Set tStatus = tRS.%GetStatus(.tComplete)
					While ((tStatus<100)&&(tStatus>=0)) {
						Set tCount = tCount + 1
						Set tMsg = $S(tStatus < 35:"Computing related cube axes...",tStatus < 90:"Computing related cube cells...",1:"Consolidating related cube results...")
						Write $C(13,27)_"[0J"
						Write $J(tCount,4),": ",tMsg,"(",tStatus,":",tQueryKey,")  "
						If (tComplete '= "") {
							Write $FN(tComplete,",",2),"% complete"
						}
						Hang $Case(tCount,1:0.1,2:0.2,:0.5)
						Set tStatus = tRS.%GetStatus(.tComplete)
					}
					Write $C(13,27)_"[0J"
				}
			}
			Else {
				Set tSC = tRS.%Execute(.tParmValues)
				If $$$ISERR(tSC) Quit
			}
			Set tCubeIndex = $$$DeepSeeIndex(..%cube)
			Set $$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"plan"))) = $LB("sq",tRS.%GetCubeName(),tRS.%GetQueryKey())

			// +DTB458 - Log the subquery keys in the results global if a related cube is involved
			Set tSubqueryCube = tRS.%CubeKey
			Set tSubqueryKey = tRS.%GetQueryKey()
			If ($G(tCubeIndex)'="") && (tSubqueryCube'=$$$UPPER(tCubeIndex)) && (tSubqueryCube'="") && (tSubqueryKey'="") {
				Set $$$DeepSeeResultsGLVN($$$UPPER(tCubeIndex),%query.%QueryKey,"subquery",tSubqueryCube,tSubqueryKey) = "(3)"
			}
			// -DTB458

			// JMD885: note this subquery in axis cache
			If (($G(%axisKey)'="")) {
				Set tSQKey = tRS.%GetQueryKey()
				Set tRelCube = $$$DeepSeeIndex(tRS.%GetCubeName())
				Set $$$DeepSeeAxisGLVN(tCubeIndex,%axisKey,"subquery",tSQKey) = $G($$$DeepSeeResultsGLVN(tRelCube))
				Set:tSQKey'="" $$$DeepSeeAxisGLVN(tCubeIndex,%axisKey,"subquery",tSQKey,"cube") = tRelCube
			}

			// loop over results of subquery
			// and place them into the output member array
			// later we will convert these to local bits
			Set tRemoteCube = tRS.%GetCubeName()
			Set tRemoteCubeIndex = $$$DeepSeeIndex(tRemoteCube)
			Set tQueryKey = tRS.%GetQueryKey()
			Set tSubQueryAxisCount = tRS.%GetAxisCount()

			If (tSubQueryAxisCount = 0) { // scalar result
				Set tCol = 1
				Set tAxisKey = ""
			}
			Else { // vector
				Set tCol = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"leaf",1,""))
				Set tSizeInfo = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"size"))
				Set tAxisKey = $LG($LG(tSizeInfo,1),2)  // get axis key for first axis
			}

			// +DTB086
			// If a slicer is in play, retrieve the bitset query key for the slicer on the primary cube
			Set tBitQueryKey=""
			If ('$G(%dsIsSlicer)&&$IsObject($G(%query))&&$IsObject(%query.slicer)) {	
				Set tBitCubeIndex = $$$UPPER(%query.cube)
				
				Set tBitQueryKey = $G($$$DeepSeeResultsGLVN(tBitCubeIndex,%query.%QueryKey,"bitquery"))
				
				If +$G(%dsflags("RELATIONS")) {
					$$$DSWRITELN("*** ("_tRemoteCubeIndex_"->"_tBitCubeIndex_":"_%query.%QueryKey_")")
					$$$DSWRITELN("SLICER SUBQUERY KEY: "_tBitQueryKey)
				}
			}	
			// -DTB086
			
			Set tUseOptimizationCount = 0		// DTB529 - Track how many times the engine engages the member optimization
			While (tCol '= "") {
				Set tNode = ""
				If (tSubQueryAxisCount = 0) {
					Set tFactId =  "@"_tQueryKey_"---"_##class(%DeepSee.Utils).%GetCubeDSTime(tRemoteCubeIndex)		// DP-418010
					Set tName = ..%relationship
					Set tFactKey = ""
				}
				Else {
					Set tNodeNo = $G($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"leaf",1,tCol))
					Set tNode = $G($$$DeepSeeAxisGLVN(tRemoteCubeIndex,tAxisKey,"axes",tNodeNo))
					Set tFactNo = $LG(tNode,7)

					// construct a hash key to use for each bitset
					Set tFactId = "@"_tQueryKey_"-"_tNodeNo_"-"_tFactNo_"-"_##class(%DeepSee.Utils).%GetCubeDSTime(tRemoteCubeIndex)		// DP-418010
					Set tName = $LG(tNode,5)
					Set tFactKey = $LG(tNode,13)
				}

				// Place member into output set
				// Place remote spec in set to help with drill through
				Set tIsLiteral = 0
				// PFS080 - If node is type lit, set flag
				If $LG(tNode,1) = "lit" {
					// DTB807 - Set the current return member as the detected literal
					Set $LI(tNode,4) = +pParent 
					Set pSet(tCol) = tNode
					Set tIsLiteral = 1
				}
				// JMD1361 Remember OR list
				If ($D(..%ORList)) {
					Set tRemoteSpec = tRemoteMbrs
				}
				Else {
					Set tRemoteSpec = ..%remoteSpec
					If (tRemoteSpec'="") {
						Set rx = $$$UPPER($P(tRemoteSpec,".",$L(tRemoteSpec,".")))
						If ((rx = "MEMBERS")||(rx = "ALLMEMBERS")||(rx = "%TOPMEMBERS")) {
							Set tRemoteSpec = $P(tRemoteSpec,".",1,$L(tRemoteSpec,".")-1)
							If (tFactKey'="") {
								Set tRemoteSpec = tRemoteSpec _ ".&["_$$$dsEscapeIdent(tFactKey)_"]"	// DTB112
							}
						}
						ElseIf (rx["PROPERTIES(") {
							// special case for remote PROPERTIES()
							Set pSet(tCol) = $LB("lit",1,1,+pParent,tName,$LG(tNode,6))
							Set tIsLiteral = 1
						}
					}
				}
				
				// DTB129 - Extract this test for readability
				Set tUseMemberOptimization = 'tIsLiteral &&
											(tBitQueryKey'="") &&
											tNonEmpty &&				// DTB415 - This variable always has a value
											'$G(%dsIsSlicer) &&			// DTB415 - Add this to make sure the optimization is never triggered on a slicer
											(tFactKey'="NO MEMBER")		// DTB129 - no members were returned by the subquery
											
				// +DTB529 - System-configurable optimization switch. The value of
				//   tUseMemberOptimization
				// is the value chosen by the engine at runtime. A '0' according to DTB129 and DTB415 decision-making 
				// indicates the optimization *cannot be attempted*.
				Set:tUseMemberOptimization tUseMemberOptimization = $$$DeepSeeOptimizer($$$memberRelationship,0,tUseMemberOptimization)
				Set tUseOptimizationCount = $G(tUseOptimizationCount) + $G(tUseMemberOptimization)
				
				If +$G(%dsflags("RELATIONS"))&&(tUseOptimizationCount>0)&&'(tUseOptimizationCount#500) {
					$$$DSWRITELN("*** Member key joinIndex optimization count: "_tUseOptimizationCount)
				}
				// -DTB529
				
				If tUseMemberOptimization {
					// +DTB086 - use information from the bitset-slicer query on the primary cube to
					// limit the axis returned. An axis without NON EMPTY cannot use this optimization!
					Set tIntersect=0
					If ..%isStoredSide {
						// This side of the relationship contains the index. Use this index to limit the members passed 
						// to the final query results
						Set tLocalResultSlot = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",""))
						While (tLocalResultSlot'="")&&('tIntersect) {
							Set tLocalResultNode = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,""))
							While (tLocalResultNode'="")&&('tIntersect) {
								Set tLocalChunk = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,tLocalResultNode,""),1,tLocalMask)
								While (tLocalChunk'="")&&('tIntersect) {
									
									$$$dsBitFind(tLocalMask,1,tLocalBit)		// DTB981
									If tLocalBit {		
										// DTB104 - Only run the inner loop if there are results in this local chunk. 
										Set tRemoteMask = ""
										Set tRemoteResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",""))
										While (tRemoteResultSlot'="")&&('tIntersect) {
											Set tRemoteChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tRemoteResultSlot,tNodeNo,""),1,tRemoteMask)
											While (tRemoteChunk'="")&&('tIntersect) {
												Set tRemoteOffset = (tRemoteChunk-1)*64000
												
												$$$dsBitFind(tRemoteMask,1,tBit)		// DTB981
												While (tBit>0)&&('tIntersect) {
													Set tRemoteFactId = tRemoteOffset + tBit - 1
													Set tMemberMask = $G($$$DeepSeeIndexGLVN(tBitCubeIndex,tFact,tRemoteFactId,tLocalChunk))
													$$$dsBitAandB(tLocalMask,tMemberMask,tIntersectMask)		// DB981
													$$$dsBitFind(tIntersectMask,1,tIntersect)
													$$$dsBitFindNext(tRemoteMask,1,tBit+1,tBit)		// DTB981
												}
												Set tRemoteChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tRemoteResultSlot,tNodeNo,tRemoteChunk),1,tRemoteMask)
											} 
											Set tRemoteResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tRemoteResultSlot))
										} 
									}
									// Always run the $Order to test for and retrieve the next available local mask 
									Set tLocalChunk = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,tLocalResultNode,tLocalChunk),1,tLocalMask)
								} 
								Set tLocalResultNode = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,tLocalResultNode))
							}
							Set tLocalResultSlot = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot))
						} 

					} 	// %isStoredSide
					Else {
						// The related index is stored in the other cube. Look up the fact number corresponding to this 
						// relationship in the other cube and use it to limit this axis result
						Set tRelName = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",tBitCubeIndex,"rel#",tFact)))
						// find information on fact from remote cube
						Set tInverse = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",tBitCubeIndex,"relations",tRelName,"inverse")))
						Set tFactInfo = $G($$$DeepSeeMetaGLVN("cubes",tRemoteCubeIndex,"mbrs",tInverse))
						// test for bad meta data
						If (tFactInfo="") {
							Set tSC = $$$ERROR($$$GeneralError,"memberRelationship.%ProcessMembers: Invalid inverse relation: " _ tRemoteCubeIndex _ "." _ tInverse)
							Quit
						}
						Set tFactNode = $G($$$DeepSeeMetaGLVN("cubes",tRemoteCubeIndex,"mbr#",$LG(tFactInfo,1),$LG(tFactInfo,2),$LG(tFactInfo,3)))

						Set tRemoteFact = $LG(tFactNode,5)
						
						Set tLocalResultSlot = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",""))
						While (tLocalResultSlot'="")&&('tIntersect) {
							Set tLocalResultNode = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,""))
							While (tLocalResultNode'="")&&('tIntersect) {
								Set tLocalChunk = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,tLocalResultNode,""),1,tLocalMask)
								While (tLocalChunk'="")&&('tIntersect) {  		// DTB104 - Remove $bitfind(tLocalMask) from the while condition 
									Set tLocalOffset = (tLocalChunk-1)*64000
									
									$$$dsBitFind(tLocalMask,1,tBit)		// DTB981
									While (tBit>0)&&('tIntersect) {
										Set tLocalFactId = tLocalOffset + tBit - 1
										Set tRemoteMask = ""
										Set tRemoteResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",""))
										While (tRemoteResultSlot'="")&&('tIntersect) {
											Set tRemoteChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tRemoteResultSlot,tNodeNo,""),1,tRemoteMask)
											While (tRemoteChunk'="")&&('tIntersect) {
												// DTB128 - This fact in the "one" cube may not have any facts in the "many" 
												// cube associated with it. Protect the lookup with $Get()
												Set tMemberMask = $G($$$DeepSeeIndexGLVN(tRemoteCubeIndex,tRemoteFact,tLocalFactId,tRemoteChunk))		
												
												$$$dsBitAandB(tRemoteMask,tMemberMask,tIntersectMask)		// DTB981
												$$$dsBitFind(tIntersectMask,1,tIntersect)		// DTB981
												Set tRemoteChunk = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tRemoteResultSlot,tNodeNo,tRemoteChunk),1,tRemoteMask)
											}
											Set tRemoteResultSlot = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"data",tRemoteResultSlot))
										}
										
										$$$dsBitFindNext(tLocalMask,1,tBit+1,tBit)		// DTB981
									}
									Set tLocalChunk = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,tLocalResultNode,tLocalChunk),1,tLocalMask)
								}
								Set tLocalResultNode = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot,tLocalResultNode))
							}
							Set tLocalResultSlot = $O($$$DeepSeeResultsGLVN(tBitCubeIndex,tBitQueryKey,"data",tLocalResultSlot))
						}
					}	// '%isStoredSide

					If tIntersect {
						Set pSet($I(tReducedCol)) = $LB("mbr",1,1,+pParent,tName,tFactId,tFact,,..%dimNumber,..%hierNumber,..%levelNumber,,tFactKey,tRemoteSpec)
						If (tSpecialInfo'="") {
							// tack on special info: use node 22
							Set $List(pSet(tReducedCol),22) = tSpecialInfo
						}
					}
					Set tLastCol = $G(tReducedCol,0)
					// -DTB086
					
					// +DTB129
					If '(tLastCol) {
						// All members from the subquery have been removed 
						// emulate a NO MEMBER subquery result
						Set tCaption = $$$Text("No Member","%DeepSee")
						
						Set tRemoteSpec = ..%remoteSpec
						Set pSet(1) = $LB("mbr",1,1,+pParent,tCaption,tFactId,tFact,,..%dimNumber,..%hierNumber,..%levelNumber,,"",tRemoteSpec)
				
					}
					// - DTB129
				}
				ElseIf ('tIsLiteral) {
					// DTB086 - If the optimization cannot be used, 
					// revert to old behavior so we still get results
					Set pSet(tCol) = $LB("mbr",1,1,+pParent,tName,tFactId,tFact,,..%dimNumber,..%hierNumber,..%levelNumber,,tFactKey,tRemoteSpec)
					If (tSpecialInfo'="") {
						// JMD1403 tack on special info: use node 22
						Set $List(pSet(tCol),22) = tSpecialInfo
					}
					Set tLastCol = tCol
				}
				
				// next member
				If (tSubQueryAxisCount = 0) { // scalar result
					Set tCol = ""
				}
				Else {
					Set tCol = $O($$$DeepSeeResultsGLVN(tRemoteCubeIndex,tQueryKey,"leaf",1,tCol))
				}
				
			}

			If (..%isStoredSide) {
				If (($$$UPPER(..%remoteSpec)[".MEMBERS")||($$$UPPER(..%remoteSpec)[".ALLMEMBERS")||($$$UPPER(..%remoteSpec)[".%TOPMEMBERS")) {
					// see if there is a nullReplacement for this relationship
					// !!! (for use by cmbr)
					Set tRemoteSpec = ..%remoteSpec
					Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..%cube),"mbr#",..%dimNumber,..%hierNumber,..%levelNumber))
					Set tNullRef = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..%cube),"relations",$$$UPPER($LG(tDimInfo,2)),"nullReplacement"))
					If (tNullRef'="") {
						// add holder for items that have no relation
						Set tLastCol = tLastCol + 1

						// get caption for relation
						Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(..%cube, tNullRef, "", "", .tRelationCaption)
						If $$$ISERR(tSC) Quit
						Set:tRelationCaption="" tRelationCaption = tNullRef

						Set tFactId = -1E14
						Set tCaption = tNullRef

						// JMD976: no remote spec in this case
						Set tRemoteSpec = ""
						Set pSet(tLastCol) = $LB("mbr",1,1,+pParent,tCaption,tFactId,tFact,,..%dimNumber,..%hierNumber,..%levelNumber,,"",tRemoteSpec)
					}
				}
			}
		} // tExists
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Compute the filters to tack onto a relationship subquery.
Method %GetFiltersForRelationship(Output pFilters As %String, pGroup As %DeepSee.Query.node, pLevel As %Integer = 0, ByRef pOmitted) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pFilters
		
		// get terms
		// JMD1088 test for memberSpec
		If (pGroup.%IsA("%DeepSee.Query.memberSpec")) {
			If '$IsObject(pGroup.%member) {
				// DP-433435 - Call to %PreProcess to produce the member provider
				Set tSC = pGroup.%PreProcess()
				If $$$ISERR(tSC) Quit
			}

			Set tTerms($I(tTerms)) = pGroup
		}
		ElseIf (pGroup.%IsA("%DeepSee.Query.setFunction") && ($$$UPPER(pGroup.function)["CROSSJOIN")) {
			// DP-433435 - Directly process the incoming term
			Set tTerms($I(tTerms)) = pGroup
		}
		ElseIf (pGroup.%IsA("%DeepSee.Query.group")) {
			For n = 1:1:pGroup.children.Count() {
				Set tTerm = pGroup.children.GetAt(n)

				// if item is a set of one item, simplify
				If (tTerm.%IsA("%DeepSee.Query.set") && (tTerm.children.Count()=1)) {
					Set tTerms($I(tTerms)) = tTerm.children.GetAt(1)
				}
				Else {
					Set tTerms($I(tTerms)) = tTerm
				}
			}
		}
		Else {
			Set tTerms($I(tTerms)) = pGroup
		}

		// look at the terms; see if they are applicable
		Set m = 0
		Set t = $O(tTerms(""))
		While (t'="") {
			Set tTerm = tTerms(t)
			If (tTerm.%IsA("%DeepSee.Query.tuple")) {
				For k = 1:1:tTerm.children.Count() {
					Set tMember = tTerm.children.GetAt(k)
					If tMember.%IsA("%DeepSee.Query.memberSpec") {
						If '$IsObject(tMember.%member) {
							// DP-433435 - Call to %PreProcess to produce the member provider
							Set tSC = tMember.%PreProcess()
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						}

						If (tMember.%member.%IsA("%DeepSee.Query.memberRelationship")) {
							If (..%relatedCube=tMember.%member.%relatedCube) &&
								($$$UPPER(..%relationship)=$$$UPPER(tMember.%member.%relationship)) {
								// DTB200 - Check the %relationship in case the cube has multiple 
								// pointers to the same related cube
								Set tSpec = ..%GetSpecForMember(tMember.%member)
								Set:tSpec'="" pFilters($I(pFilters)) = tSpec
							}
						}
					}
					Set x = tTerm.children.GetAt(k)
				}
			}
			ElseIf (tTerm.%IsA("%DeepSee.Query.memberSpec")) {
				If '$IsObject(tTerm.%member) {
					// DP-433435 - Call to %PreProcess to produce the member provider
					Set tSC = tTerm.%PreProcess()
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				}

				If (tTerm.%member.%IsA("%DeepSee.Query.memberRelationship")) {
					// JMD1106 skip null relations
					If ((..%relatedCube=tTerm.%member.%relatedCube)&&('tTerm.%member.%isNullRelation)) &&
						($$$UPPER(..%relationship)=$$$UPPER(tTerm.%member.%relationship)) {
						// DTB200 - Check the %relationship in case the cube has multiple 
						// pointers to the same related cube
						Set tSpec = ..%GetSpecForMember(tTerm.%member)
						If tSpec'="" {
							Set pFilters($I(pFilters)) = tSpec
						}
						Else {
							Set pOmitted(pLevel,$I(pOmitted(pLevel))) = tTerm
						}
					}
					Else {
						// DTB187 - Log that there was a relationship term omitted.
						Set pOmitted(pLevel,$I(pOmitted(pLevel))) = tTerm
					}
				}
			}
			ElseIf (tTerm.%IsA("%DeepSee.Query.range")) {
				If ($IsObject(tTerm.startMember)&&$IsObject(tTerm.startMember.%member)) {
					If (tTerm.startMember.%member.%IsA("%DeepSee.Query.memberRelationship")) {
						If (..%relatedCube=tTerm.startMember.%member.%relatedCube) &&
							($$$UPPER(..%relationship)=$$$UPPER(tTerm.%member.%relationship)) {
							// DTB200 - Check the %relationship in case the cube has multiple 
							// pointers to the same related cube
							Set tSpec1 = ..%GetSpecForMember(tTerm.startMember.%member)
							Set tSpec2 = ..%GetSpecForMember(tTerm.endMember.%member)
							Set tSpec = tSpec1_":"_tSpec2
							Set:tSpec'="" pFilters($I(pFilters)) = tSpec
						}
					}
				}
			}
			ElseIf (tTerm.%IsA("%DeepSee.Query.set")) {
				// Note: range is passed as a memberSpec!
				Set tSC = ..%GetFiltersForRelationship(.tFilters,tTerm,pLevel+1,.pOmitted)
				If $$$ISERR(tSC) Quit
				Set tClause = ""
				Set tSCount = 0
				Set k = $O(tFilters(""))
				While (k'="") {
					Set tSCount = tSCount + 1
					Set tClause = tClause _ $S(tSCount>1:",",1:"")_tFilters(k)
					Set k = $O(tFilters(k))
				}
				Set:tSCount>1 tClause = "{"_tClause_"}"
				Set:tClause'="" pFilters($I(pFilters)) = tClause
			}
			ElseIf (tTerm.%IsA("%DeepSee.Query.setFunction")) {
				If ($$$UPPER(tTerm.function)="%OR") {
					Kill tFilters
					Kill pOmitted		// DTB187
					
					Set tChild = tTerm.children.GetAt(1)
					// PFS109 - Handle nested %ORs
					If (tChild.%IsA("%DeepSee.Query.set"))||(tChild.%IsA("%DeepSee.Query.setFunction")) {
						Set tSC = ..%GetFiltersForRelationship(.tFilters,tChild,pLevel+1,.pOmitted)
						If $$$ISERR(tSC) Quit
					}
					ElseIf tChild.%IsA("%DeepSee.Query.memberSpec") {
						If '$IsObject(tChild.%member) {
							// DP-433435 - Call to %PreProcess to produce the member provider
							Set tSC = tChild.%PreProcess()
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						}
						
						If (tChild.%member.%IsA("%DeepSee.Query.memberRelationship")) {
							If (..%relatedCube=tChild.%member.%relatedCube) {
								Set tSpec = ..%GetSpecForMember(tChild.%member)
								Set:tSpec'="" tFilters(1) = tSpec
							}
						}
					}
					
					// DTB187 - If a heterogeneous %OR dropped terms in a set, we cannot claim
					// the rest of the set is a valid filter for a subquery
					If '$D(pOmitted(pLevel+1)) {
						Set tClause = ""
						Set tSCount = 0
						Set k = $O(tFilters(""))
						While (k'="") {
							Set tSCount = tSCount + 1
							Set tClause = tClause _ $S(tSCount>1:",",1:"")_tFilters(k)
							Set k = $O(tFilters(k))
						}
						Set:tSCount>1 tClause = "{"_tClause_"}"
						Set:tClause'="" pFilters($I(pFilters)) = "%OR("_tClause_")"
					}
				}
				ElseIf (($$$UPPER(tTerm.function)="NONEMPTYCROSSJOIN")||($$$UPPER(tTerm.function)="CROSSJOIN")) {
					Set tSC = ..%GetFiltersForRelationship(.tFilters1,tTerm.children.GetAt(1),pLevel+1,.pOmitted)
					If $$$ISERR(tSC) Quit

					Set tClause1 = ""
					Set tSCount = 0
					Set k = $O(tFilters1(""))
					While (k'="") {
						Set tSCount = tSCount + 1
						Set tClause1 = tClause1 _ $S(tSCount>1:",",1:"")_tFilters1(k)
						Set k = $O(tFilters1(k))
					}
					If (tSCount>1) {
						// DP-433435 - Reassemble the clause terms with the appropriate bracket type
						Set tBrackets = $S(tTerm.children.GetAt(1).%IsA("%DeepSee.Query.tuple"):"()",1:"{}")
						Set tClause1 = $E(tBrackets,1)_tClause1_$E(tBrackets,2)
					}

					Set tSC = ..%GetFiltersForRelationship(.tFilters2,tTerm.children.GetAt(2),pLevel+1,.pOmitted)
					If $$$ISERR(tSC) Quit

					Set tClause2 = ""
					Set tSCount = 0
					Set k = $O(tFilters2(""))
					While (k'="") {
						Set tSCount = tSCount + 1
						Set tClause2 = tClause2 _ $S(tSCount>1:",",1:"")_tFilters2(k)
						Set k = $O(tFilters2(k))
					}
					If (tSCount>1) {
						// DP-433435 - Reassemble the clause terms with the appropriate bracket type
						Set tBrackets = $S(tTerm.children.GetAt(2).%IsA("%DeepSee.Query.tuple"):"()",1:"{}")
						Set tClause2 = $E(tBrackets,1)_tClause2_$E(tBrackets,2)
					}

					If ((tClause1'="")&&(tClause2'="")) {
						Set pFilters($I(pFilters)) = "NONEMPTYCROSSJOIN("_tClause1_","_tClause2_")"
					}
					ElseIf (tClause1'="") {
						Set pFilters($I(pFilters)) = tClause1
					}
					ElseIf (tClause2'="") {
						Set pFilters($I(pFilters)) = tClause2
					}
				}
			}
			Set t = $O(tTerms(t))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method. Return a spec for the given member.
Method %GetSpecForMember(pMember As %DeepSee.Query.memberRelationship) As %String [ Internal ]
{
	Set tSpec = ""
	If ($D(pMember.%ORList)) {
		// construct %OR expression
		Set tORList = ""
		Set ko = $O(pMember.%ORList(""))
		While (ko'="") {
			Set tORList = tORList _ $S(tORList="":"",1:",") _ ko
			Set ko = $O(pMember.%ORList(ko))
		}
		Set tSpec = "%OR({"_pMember.%remoteSpec_$S(tORList="":"",1:",")_tORList_"})"
	}
	Else {
		Set tSpec = pMember.%remoteSpec
	}
	Quit tSpec
}

}
