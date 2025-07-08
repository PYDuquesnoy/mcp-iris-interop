/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class holds run-time information for a DeepSee MDX statement and
/// provides the machinery to prepare and execute it (via the
/// <class>%DeepSee.ResultSet</class> interface.
Class %DeepSee.Query.query Extends node [ System = 3 ]
{

/// Name of the cube this query is based on.<br/>
/// This is the FROM clause of the query.
Property cube As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// This indicates what type of MDX statement this is.
Property queryType As %DeepSee.Datatype.string(VALUELIST = ",SELECT,DRILLTHROUGH,CREATE,DROP,%BITSET", XMLPROJECTION = "attribute") [ InitialExpression = "SELECT" ];

/// For CREATE or DROP statements this specifies the target of the command.
Property %target As %DeepSee.Datatype.string(VALUELIST = ",SET,MEMBER", XMLPROJECTION = "none") [ Internal ];

/// For DROP statements this specifies the key of the item to be dropped.
Property %targetKey As %DeepSee.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// If true, then use results caching for this query.
Property useCache As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// If true, then this is a query on a compound cube.
Property %isCompound As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, this query is being run as a subquery in a compound cube.
Property %isCompoundMember As %Boolean [ InitialExpression = 0 ];

/// Contains the parent cube name if query is a member of a subquery.
Property parentCube As %String;

/// If true, then the query must be recomputed-- the cached results are not guaranteed to be up-to-date.
Property %mustCompute As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// If true, then the axes for the query must be recomputed.
Property %recomputeAxes As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Indicates, by axis, if empty value needs to be removed after processing.
/// This is used by compound queries.
Property %removeEmpty As %Boolean(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// If true recompute previously run queries whose data has been updated.
/// otherwise return old values.
Property recompute As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 1 ];

/// If true, execute using background agents.<br/>
/// This is set when using async mode.
Property useAgents As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// If true, execute this query in "plan" mode.<br/>
Property showPlan As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// Axes defined for this query.
Relationship axes As %DeepSee.Query.axis(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = query ];

/// For subqueries, remember which parent query initiated it.
Property parentQueryKey As %String(XMLPROJECTION = "none");

/// Canonic form of WITH clause. Used internally to create hash keys.
Property parentWITHText As %String(XMLPROJECTION = "none") [ Internal ];

/// Collection of all subqueries associated with this query.
Property subqueries As list Of %DeepSee.ResultSet(XMLPROJECTION = "NONE");

/// Slicer defined for this query.<br/>
/// This is the WHERE clause of the query.<br/>
/// From a definition perspective this is no different than any other axis.
Property slicer As %DeepSee.Query.axis(XMLPROJECTION = "ELEMENT");

/// Filter(s) defined for this query.<br/>
/// This is the ISC extension %FILTER clause of the query.
Property filters As list Of %DeepSee.Query.axis(XMLPROJECTION = "ELEMENT");

/// Used to hold cube/subjectArea level filter.
Property filterAxis As %DeepSee.Query.axis(XMLPROJECTION = "NONE");

/// Used as an indicator as to which axis supplies the measure information for this query. The
/// slicer is denoted by a 0, other axes are logged as their 1-based number. A value of -1 for this property
/// indicates the default measure will be used.
Property measureAxis As %Integer [ InitialExpression = -1 ];

/// Canonic form of WITH clause. Used internally to create hash keys.
Property %WITHText As %String(XMLPROJECTION = "none") [ Internal ];

/// Collection of <i>Named Sets</i> defined within the WITH clause of the query.
Property namedSets As array Of %DeepSee.Query.namedSet(XMLKEYNAME = "setName", XMLPROJECTION = "ELEMENT");

/// Collection of <i>Calculated Members</i> defined within the WITH clause of the query.
/// These are indexed by Dimension.MemberName.
Property calculatedMembers As array Of %DeepSee.Query.calculatedMember(XMLKEYNAME = "memberName", XMLPROJECTION = "ELEMENT");

/// Hash key used to address the results for this query.
/// This allows a query to be prepared and later restored.
Property %QueryKey As %String(XMLPROJECTION = "none") [ Internal ];

/// Array of timing and performance statistics for this query.
Property %Statistics As %DeepSee.Datatype.string [ Internal, MultiDimensional ];

/// List of fields in RETURN clause for DRILLTHROUGH statement.
Property %returnList As %String(MAXLEN = 2000, XMLPROJECTION = "none") [ Internal ];

/// List of fields in %ORDER BY clause for DRILLTHROUGH statement.
Property %orderList As %String(MAXLEN = 2000, XMLPROJECTION = "none") [ Internal ];

/// Name of listing specified by %LISTING statement in query.
Property %listing As %String(MAXLEN = 255, XMLPROJECTION = "none") [ Internal ];

/// For a drillthrough, this indicates whether the listing query is against the source table
/// or the fact table.
Property %listingSource As %String(VALUELIST = "source,facts", XMLPROJECTION = "none") [ Internal ];

/// Array of named parameters with current values.<br/>
Property %NamedParameters As %String [ Internal, MultiDimensional ];

/// Array of named parameter values supplied when this query was executed.<br/>
Property %ParameterValues As %String [ Internal, MultiDimensional ];

/// If true, this query contains references to related cubes.<br/>
/// This is set during the axis prepare phase.
Property %hasRelations As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// If true, this query contains references to related cubes.<br/>
/// Set during the parse phase, might replace %hasRelations.
Property %hasRelationship As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// If true, this query contains an %SQLRESTRIICT statement.<br/>
/// Set during the parse phase.
Property %hasSqlRestrict As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Maximum number of rows returned by a DRILLTHROUGH query.
/// This is set by the MAXROWS directive within a DRILLTHROUGH query.
Property %MaxListingRows As %Integer [ InitialExpression = 1000, Internal ];

/// For queries on compound cubes, this is the set of keys for the subqueries that have to be executed
/// and then joined.
Property compoundQueries As list Of %String(XMLPROJECTION = "NONE");

/// For DRILLTHROUGH queries on compound cubes, this is the MDX DRILLTHROUGH statements for each leg
/// of the compound query.
Property compoundDrillthroughs As list Of %String(XMLPROJECTION = "NONE");

/// Original text for each axis. Used as part of the axis key.<br/>
Property %originalAxisText As %String [ Internal, MultiDimensional ];

/// Original components of the WITH clause. Order is not necessarily preserved from the original query text.
Property %originalWITHContents As %String;

/// Current pivot variable settings for this query.
Property %variables As %String [ MultiDimensional ];

/// This holds a copy of all lock keys protecting this execution.
Property %LockKeys As %String [ MultiDimensional ];

/// Log a step within the execution of this query.
/// This is an internal diagnostic.
ClassMethod %QueryTrace(pMethod As %String, pCubeName As %String, pMessage As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// For now, log to screen
		If +$G(%dstrace) {
			$$$DSWRITELN("%QueryTrace --> "_pMethod_$S(pCubeName="":"",1:": ")_pCubeName_$S(pMessage="":"",1:": ")_pMessage)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Diagnostic. Print value of this node to the console.
Method %PrintNode(pLevel As %Integer = 0)
{
	Do ##super(pLevel)
	Set tCount = ..axes.Count()
	For n=1:1:tCount {
		Do ..axes.GetAt(n).%PrintNode(pLevel+1)
	}
	If ($IsObject(..slicer)) {
		Do ..slicer.%PrintNode(pLevel+1)
	}
}

/// Prepare this query.<br/>
/// This is the first step in executing a query.
Method %Prepare() As %Status
{
	Set tSC = $$$OK
	Set tStart = $ZH
	Try {
		Set ..%WITHText = ""
		Set ..%hasRelations = 0
		Set ..%target = ""
		Set ..%mustCompute = 0
		Set ..%recomputeAxes = 0
		Set ..%listing = ""
		Kill ..%removeEmpty
		Do ..compoundQueries.Clear()
		Do ..compoundDrillthroughs.Clear()
		Kill ..%originalAxisText

		// JMD1402: make sure %ToString does not resolve @parms just yet
		New %dsQueryPrepare
		Set %dsQueryPrepare = 1

		// query results may not be accurate if this method is not called!
		If ('$$CheckDeepSeeAccess^%qdsUtils()) {
			Set tSC = $$$ERROR($$$GeneralError,"DeepSee is not enabled on this system.")
			Quit
		}

		Set tSC = ..%QueryTrace("%Prepare",..cube,$ZDT($H,3))
		If $$$ISERR(tSC) Quit

		If (..cube="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name is missing.")
			Quit
		}

		Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..cube,.tSC)
		If $$$ISERR(tSC) Quit

		// JMD - test if cube is compiled
		// as incremental compile may have messed things up!
		Set tFactClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"factClass"))
		If (tFactClass="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube is not compiled.")
			Quit
		}

		Set tAbstract = ##class(%DeepSee.Utils).%IsCubeAbstract(..cube,.tSC)
		If $$$ISERR(tSC) Quit
		If (tAbstract) {
			Set tSC = $$$ERROR($$$GeneralError,"Cube is abstract.")
			Quit
		}

		// Test for (base) cube rebuild
		// but ignore SYNC
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		Lock +^DeepSee.Build(tCubeIndex,"QUERY"):1 Else  Set tSC = $$$ERROR($$$GeneralError,"Cube is locked for rebuilding: " _ ..cube)
		If $$$ISERR(tSC) Quit

		Lock -^DeepSee.Build(tCubeIndex,"QUERY")

		#; contextual info
		New %query,%cube,%cubeIndex
		Set %query = $this
		Set %cube = $$$UPPER(..cube)
		Set %cubeIndex = tCubeIndex

		#; apply rewrites to query (if present)

		#; see if there are filters associated with the cube
		#; if so, add to the filter list
		#; JMD1395 this could be passed in via %dsFilterSpec from the TaskMaster
		If $D(%dsFilterSpec) {
			Set tFilterSpec = $G(%dsFilterSpec)
		}
		Else {
			Set tFilterSpec = $zobjclassmethod(tCubeClass,"%GetFilterSpec")
		}
		If (tFilterSpec'="") {
			Set tFilterAxis = ##class(%DeepSee.Query.axis).%New()
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMDXExpression(tFilterSpec,$this,tFilterAxis,.tNode)
			If $$$ISERR(tSC) {
				Set pSC = $$$ERROR($$$GeneralError,"Error in filter expression: " _ tFilterSpec _ $C(13,10) _ $System.Status.GetErrorText(tSC))
				Quit
			}
			// DP-424293 - Tag this axis object as a filterAxis, which gets copied both into the filterAxis and as one of the filters
			Set tFilterAxis.%originalSpec = tFilterSpec
			Set tFilterAxis.context = "filterAxis"

			Set ..filterAxis = tFilterAxis.%ConstructClone()
			Do ..filters.Insert(tFilterAxis.%ConstructClone())
		}
		
		// +DTB125 - test for a measure in the filters. If a collision is detected, quit
		If ($IsObject(..slicer))&&
			(..%HasMeasure(..slicer.children.GetAt(1))) {
			Set ..measureAxis = 0
		}
		For f=1:1:..filters.Count() {
			If (..%HasMeasure(..filters.GetAt(f).children.GetAt(1))) {
				If (..measureAxis<0) {
					Set ..measureAxis = 0
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Two measures cannot be crossjoined (filters)")
					Quit
				}
			}
		}
		// -DTB125

		#; combine filters with slicer
		If ('$IsObject(..slicer) && (..filters.Count() = 1)) {
			// simple case
			// DP-424293 if this is the only filter, construct a direct copy as the slicer.
			Set ..slicer = ..filters.GetAt(1).%ConstructClone()
			Set ..slicer.context = "filter"
		}
		ElseIf (..filters.Count() > 0) {
			// fold with slicer
			Set tSC = ..%CombineFiltersWithSlicer()
			If $$$ISERR(tSC) Quit
		}

		If ($IsObject(..slicer)) {
			// remove expressions and aggregates from slicer
			Set tSC = ..%FlattenSlicer(..slicer)
			If $$$ISERR(tSC) Quit

			If (..slicer.children.Count()=0) {
				// No actual slicer content is defined, reset the slicer to null
				Set ..slicer = ""
			}
			ElseIf (..slicer.children.Count()=1) {
				// DP-429168 - This should always be the case if a slicer still exists after a call to %FlattenSlicer
				// See if it is eligible for a %OR function wrapped around the slicer contents.
				Set tSlicerChild = ..slicer.children.GetAt(1)
				Set tIsSet = tSlicerChild.%IsA("%DeepSee.Query.set") || (tSlicerChild.%IsA("%DeepSee.Query.setFunction") && (tSlicerChild.%GetType()=$$$dstSet))
				Set tIsTuple = tSlicerChild.%IsA("%DeepSee.Query.tuple")
				Set tIsOR = (tSlicerChild.%IsA("%DeepSee.Query.setFunction") && (tSlicerChild.function="%OR"))
				Set tHasMeasure = ..%HasMeasure(..slicer)

				If ('tIsOR && tIsSet && 'tIsTuple && 'tHasMeasure) {
					// DP-429168 - Actually add the %OR around the entire slicer.
					Set tOldSlicer = ..slicer.children.GetAt(1)
					Do ..slicer.children.Clear()
					Set tOrWrap = ##class(%DeepSee.Query.setFunction).%New("%OR")
					Do tOrWrap.children.Insert(tOldSlicer)
					Do ..slicer.children.Insert(tOrWrap)
				}
			}
		}
		
		//DP-401989: Allow for reporting of errors besides build errors
		
		If '..%IsExecutable(.tStatus,.tReason) {
			If ('tStatus){
				Set tSC=tStatus
				Quit
			}
			Else{
				// DTB908 - Check all elements of the query to make sure the necessary measures, dimensions,
				// and relationships are completely built.
				If $G(tReason)'="" {
					// DTB913 - If the reason (spec) for the failure is returned, incorporate it into the error.
					// The reason code will contain a lag to denote whether the particular spec is unavailable
					// because it is being built or because it has never been built.
					If $LG(tReason,3) {
						Set tSC = $$$ERROR($$$GeneralError,$$$FormatText("%2 in cube %1 is currently being built.",$LG(tReason,1),$LG(tReason,2)))
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,$$$FormatText("Build %2 in cube %1.",$LG(tReason,1),$LG(tReason,2)))
					}
				}
				Else {
					// DTB913 - The specific reason wasn't returned, but the error needs to be thrown anyway
					Set tSC = $$$ERROR($$$GeneralError,"Query contains unbuilt elements and cannot be executed")
				}
			}
			Quit
		}
		
		// DP-405378 - If applicable, perform the compound rewrites at this point. This is after 
		// the slicer processing has been completed
		Set tCompound = ##class(%DeepSee.Utils).%IsCubeCompound(..cube,.tJoinList,.tSC)
		If $$$ISERR(tSC) Quit
		If (tCompound) {
			Set ..%isCompound = 1
			Set tPrimarySubCube = $$$UPPER($P(tJoinList,",",1))

			// JMD1397
			If (..queryType="DRILLTHROUGH") {
				// create a list of drillthrough queries; one per leg
				For p = 1:1:$L(tJoinList,",") {
					Set tSubCube = $$$UPPER($P(tJoinList,",",p))
					Set tSC = ..%RewriteCompoundQuery(.tMDX,tPrimarySubCube,tSubCube,.tNonEmptyInfo)
					If $$$ISERR(tSC) Quit

					If (..%MaxListingRows'="") {
						Set tMDX = "DRILLTHROUGH MAXROWS " _ ..%MaxListingRows _ " " _ tMDX
					}
					Else {
						Set tMDX = "DRILLTHROUGH " _ tMDX
					}
					// pick up other modifiers
					If (..%returnList'="") {
						Set tMDX = tMDX _ " RETURN " _ ..%returnList
					}
					If (..%orderList'="") {
						Set tMDX = tMDX _ " %ORDER BY " _ ..%orderList
					}

					Do ..compoundDrillthroughs.Insert(tMDX)
				}
				// done
				Quit
			}

			// create compound queries
			For p = 1:1:$L(tJoinList,",") {
				Set ..%WITHText = $ZSTRIP($S(..%originalWITHContents'="":..%originalWITHContents,1:..%WITHToString()),"<>W")		// DTB306 - Store the WITH text before dispatching subqueries
				
				Set tSubCube = $$$UPPER($P(tJoinList,",",p))
				Set tSC = ..%RewriteCompoundQuery(.tMDX,tPrimarySubCube,tSubCube,.tNonEmptyInfo)
				If $$$ISERR(tSC) Quit
				
				Set tSC = ..%RegisterSubQuery(tMDX,.tKey,,1)
				If $$$ISERR(tSC) Quit
				
				Set ..subqueries.GetAt(tKey).%Query.%isCompoundMember = 1		// DTB260
				Set ..subqueries.GetAt(tKey).%Query.parentCube = ..cube
				
				If (tPrimarySubCube=tSubCube) {
					Merge ..%removeEmpty = tNonEmptyInfo
				}
				Do ..compoundQueries.Insert(tKey)
			}
			// JMD928: test for error first!
			If $$$ISERR(tSC) Quit

			// JMD919: nothing more to do for compound query
			// DTB943 - Since this is quitting out early, create resultkey here
			Set ..%QueryKey = ..%CreateResultKey(.tSC)
			Quit
		}

		// DTB141 - make sure all axes are present and fill them 
		// in if necessary.
		Set tSC = ..%CompleteAxes()
		If $$$ISERR(tSC) Quit

		Set tAxisCount = ..axes.Count()

		// JMD1400: remember original text for each axis
		For a = 1:1:tAxisCount {
			Set tAxis = ..axes.GetAt(a)
			Set tText = tAxis.%ToString()
			If (tText'="") {
				Set ..%originalAxisText(a) = tText
			}
		}

		#; apply rewrite for currentMembers and crossjoins along axes
		For a = 1:1:tAxisCount {
			Set tAxis = ..axes.GetAt(a)
			
			// +DTB125 - test for measure collision and reject it if found
			If (..%HasMeasure(tAxis)) {
				If (..measureAxis<0) {
					Set ..measureAxis = a
				} 
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Measures cannot exist on multiple axes")
					$$$ThrowStatus(tSC)
				}
			}
			// -DTB125
			
			// DTB414 - Rewrite the CrossJoin before rewriting the CurrentMember
			Set tHasCrossjoin = ..%HasCrossJoin(tAxis)
			Set tHasCmbr = ..%HasCurrentMember(tAxis)
			
			If (tHasCrossjoin) {		// DTB125 - always check for this as well as the %RewriteForCurrentMember
				// look for CROSSJOIN(AGG(a),b) OR CROSSJOIN(EXP,b)
				// convert to CROSSJOIN(b,AGG(a)) OR CROSSJOIN(b,EXP)
				// rewrite axis
				Set tSC = ..%RewriteForCrossJoin("",tAxis,.tNewAxis)
				If $$$ISERR(tSC) Quit
				If $IsObject(tNewAxis) {
					Do ..axes.SetAt(tNewAxis,a)
					Set tAxis = tNewAxis
				}

				/*
					w ">>> REWRITE CJOIN: ",!
					Do ..%PrintNode()
				*/
			}
			If (tHasCmbr) {
				// rewrite axis
				Set tSC = ..%RewriteForCurrentMember("",tAxis,.tNewAxis,.tCMbrIndex)
				If $$$ISERR(tSC) Quit
				If $IsObject(tNewAxis) {
					Do ..axes.SetAt(tNewAxis,a)
					Merge tNewAxis.%cmbrIndex = tCMbrIndex
				}
				/*
					w ">>> REWRITE CMBR: ",!
					Do ..%PrintNode()
				*/
				If (tHasCrossjoin) {
					// DTB439 - Do the crossjoin resolution again! The %RewriteForCurrentMember might have
					// rewritten terms that now need to be resolved in crossjoins.
					Set tSC = ..%RewriteForCrossJoin("",tAxis,.tNewAxis) 
					If $$$ISERR(tSC) Quit
					If $IsObject(tNewAxis) {
						Do ..axes.SetAt(tNewAxis,a)
						Set tAxis = tNewAxis
					}
				}
			}
			
			// JMD1116 See if there are any SUM|%OR(timeRange) and apply time folding
			Set tSC = ..%RewriteForTimeFolding("",tAxis,.tNewAxis)
			If $$$ISERR(tSC) Quit
			If $IsObject(tNewAxis) {
				Do ..axes.SetAt(tNewAxis,a)
			}
		}
		If $$$ISERR(tSC) Quit

		#; apply rewrite for currentMembers or crossjoins in slicer
		If ($IsObject(..slicer)) {
			Set tAxis = ..slicer
			If (..%HasCurrentMember(tAxis)) {
				Set tSC = ..%RewriteForCurrentMember("",tAxis,.tNewAxis,.tCMbrIndex)
				If $$$ISERR(tSC) Quit
				If $IsObject(tNewAxis) {
					Set ..slicer = tNewAxis
					Set ..slicer.context = "filter"		// DP-424293
					Merge tNewAxis.%cmbrIndex = tCMbrIndex
				}
			}
		}
		
		#; DP-402168 Alter query tree if necessary to account for an axis with an ORDER() in it
		If (tAxisCount>1) {
			For i=1:1:tAxisCount {
				Set tAxis = ..axes.GetAt(i)
				
				Set tOppAxisNo = '(i-1)+1
				Set tOppAxis = ..axes.GetAt(tOppAxisNo)
				
				Set tSC = ..%HasOrder(.tOppAxis, .tHasOrder)
				If $$$ISERR(tSC) Quit
				
				If tHasOrder {
					// Rewrite query if necessary
					Set tSC = ..%RewriteForOrder(.tAxis, .tOppAxis)
					If $$$ISERR(tSC) Quit
				}
			}
		}

		#; check for missing axes
		For a = 1:1:tAxisCount {
			Set tAxis = ..axes.GetAt(a)
			If ('$IsObject(tAxis) || (tAxis.children.Count()=0)) {
				Set tSC = $$$ERROR($$$GeneralError,"Missing axis in query: " _ a)
				Quit
			}
		}
		If $$$ISERR(tSC) Quit
		
		// DTB739 - Use method to generate key, still generate text for use later
		Set ..%QueryKey = ..%CreateResultKey(.tSC)
		If $$$ISERR(tSC) Quit
		
		// DTB865 - Make the query key visible in the trace as soon as possible
		Set tSC = ..%QueryTrace("%Prepare",..cube,"Query Key = "_..%QueryKey)
		If $$$ISERR(tSC) Quit

		// get list of buckets to process
		// (unless we already have them)
		If '$D($$$DeepSeeResultsGLVN(..cube,..%QueryKey,"bucketList")) {
			// get list of buckets for this cube
			Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(..cube,.tBucketList,.tActiveChunk)
			If $$$ISERR(tSC) Quit
			Merge $$$DeepSeeResultsGLVN(..cube,..%QueryKey,"bucketList") = tBucketList
			Set $$$DeepSeeResultsGLVN(..cube,..%QueryKey,"activeChunk") = tActiveChunk
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set ..%Statistics("Prepare") = $ZH - tStart
	Quit tSC
}

/// Check if pMember has an ORDER() function in it (or in one of its children).
Method %HasOrder(pMember, Output pHasOrder, Output pGroup) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pHasOrder = 0
	
		// Traverse pMember and its children
		If (pMember.%IsA("%DeepSee.Query.group")) {
			If (pMember.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(pMember.function)="ORDER")) {
				Set pHasOrder = 1
				Set pGroup = pMember
				Quit
			}
		
			For i=1:1:pMember.children.Count() {
				Set tSC = ..%HasOrder(pMember.children.GetAt(i), .pHasOrder, .pGroup)
				If $$$ISERR(tSC) Quit
				Quit:(pHasOrder=1)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Check if a given group has a subset function (HEAD, TAIL, SUBSET) in it and,
/// if so, return the first such subgroup with output pGroup.
Method %HasSubsetFunction(ByRef pMember, Output pGroup, Output pHasSubsetFunction) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pHasSubsetFunction = 0
	
		// Traverse pMember and its children 
		If (pMember.%IsA("%DeepSee.Query.group")) {
			If ((pMember.%IsA("%DeepSee.Query.setFunction"))&&
				(($$$UPPER(pMember.function)="HEAD") || 
				($$$UPPER(pMember.function)="TAIL") ||
				($$$UPPER(pMember.function)="SUBSET"))) {
				Set pHasSubsetFunction = 1
				Set pGroup = pMember
				Quit 
			}
		
			For i=1:1:pMember.children.Count() {
				Set tSC = ..%HasSubsetFunction(pMember.children.GetAt(i), .pGroup, .pHasSubsetFunction)
				If $$$ISERR(tSC) Quit
				Quit:(pHasSubsetFunction=1)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Make sure this query has an executable set of axes. Axes 0 and 1 (COLUMNS, ROWS) 
/// are required, axis 2 is optional. If either Rows or Columns are missing,
/// insert a placeholder %SEARCH term
Method %CompleteAxes() As %Status
{
	// Method added by DTB141
	Set tSC = $$$OK
	Set tResetAxes = 0
	Try {
		Set tNeedCols = 0
		Set tNeedRows = 0
		
		Set tColAxis = ..axes.GetAt(1)
		Set tRowAxis = ..axes.GetAt(2)
		Set tThirdAxis = ..axes.GetAt(3)
		
		// If any axis exists, all others below it must be filled in. Log which ones are needed.
		If $IsObject(tThirdAxis) {
			Set tNeedCols = 1
			Set tNeedRows = 1
		}
		If $IsObject(tRowAxis) {
			Set tNeedCols = 1
		}
		
		// make sure column axis is not empty if rows are present
		If tNeedCols && ('$IsObject(tColAxis)||(tColAxis.children.Count()=0)) {
			// inject default column axis
			Set tResetAxes = 1
			Kill tColAxis
			Set tColAxis = ##class(%DeepSee.Query.axis).%New()
			
			// inject %SEARCH dimension along missing axis!
			Set tMember = ##class(%DeepSee.Query.memberSpec).%New()
			Set tMember.spec = "[%SEARCH]"
			Do tColAxis.children.Insert(tMember)
		}
		If tNeedRows && ('$IsObject(tRowAxis)||(tRowAxis.children.Count()=0)) {
			If (..queryType '= "%BITSET") {
				// inject default row axis
				Set tResetAxes = 1
				Kill tRowAxis
				Set tRowAxis = ##class(%DeepSee.Query.axis).%New()

				// inject %SEARCH dimension along missing axis!
				Set tMember = ##class(%DeepSee.Query.memberSpec).%New()
				Set tMember.spec = "[%SEARCH]"
				Do tRowAxis.children.Insert(tMember)
			}
		}
		
		If $IsObject(tThirdAxis)&&(tThirdAxis.children.Count()=0) {
			// An empty third axis is menaingless, make sure it is removed
			Set tResetAxes = 1
			Kill tThirdAxis
		}

		If tResetAxes {
			Do ..axes.Clear()
			Do ..axes.Insert(tColAxis)
			Do ..axes.Insert(tRowAxis)
			If $IsObject($G(tThirdAxis)) {
				Do ..axes.Insert(tThirdAxis)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Test if a group has a current member in it.
Method %HasCurrentMember(pGroup As %DeepSee.Query.group) As %Boolean [ Internal ]
{
	Set tHasCmbr = 0
	Set tCount = pGroup.children.Count()
	For n = 1:1:tCount {
		Set tItem = pGroup.children.GetAt(n)
		If (tItem.%IsA("%DeepSee.Query.memberFunction")&&($$$UPPER(tItem.function)="CURRENTMEMBER")) {
			Set tHasCmbr = 1
		}
		ElseIf (tItem.%IsA("%DeepSee.Query.group")) {
			Set tHasCmbr = ..%HasCurrentMember(tItem)
		}
		Quit:tHasCmbr
	}
	Quit tHasCmbr
}

/// Test if a group has a crossjoin in it (with an aggregate or expression as its first child).
Method %HasCrossJoin(pGroup As %DeepSee.Query.group) As %Boolean [ Internal ]
{
	Set tHasCJ = 0
	Set tCount = pGroup.children.Count()
	For n = 1:1:tCount {
		Set tItem = pGroup.children.GetAt(n)
		If (tItem.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(tItem.function)["CROSSJOIN")) {
			// JMD844
			Set tHasCJ = 1
			Quit

			For j = 1:1:2 {		// DTB063: this For {} never executes!
				Set tArg = tItem.children.GetAt(j)

				If ($IsObject(tArg)&&tArg.%IsA("%DeepSee.Query.calculatedMember")) {
					// needs to be examined
					Set tHasCJ = 1
					Quit
				}
				ElseIf ($IsObject(tArg)&&tArg.%IsA("%DeepSee.Query.set")&&$IsObject(tArg.children.GetAt(1))&&tArg.children.GetAt(1).%IsA("%DeepSee.Query.calculatedMember")) {
					// MyRegion.AllMembers
					// needs to be examined
					Set tHasCJ = 1
					Quit
				}
				ElseIf ($IsObject(tArg)&&tArg.%IsA("%DeepSee.Query.setFunction")) {
					Set tFunc = $$$UPPER(tArg.function)
					If (tFunc["CROSSJOIN") {
						Set tHasCJ = ..%HasCrossJoin(tItem)
					}
					ElseIf ((j=1)&&..%IsAggFunc(tFunc)) {
						Set tHasCJ = 1
					}
					Quit:tHasCJ
				}
				ElseIf ((j=1)&&$IsObject(tArg)&&tArg.%IsA("%DeepSee.Query.expression")) {
					Set tHasCJ = 1
					Quit
				}
			}
		}
		ElseIf (tItem.%IsA("%DeepSee.Query.group")) {
			Set tHasCJ = ..%HasCrossJoin(tItem)
		}
		Quit:tHasCJ
	}
	Quit tHasCJ
}

/// Test if <var>pFunc</var> is an aggregate function
ClassMethod %IsAggFunc(pFunc As %String) As %Boolean
{
	// WAL031 -- add comma after %KPI	
	// DTB063 -- add %LABEL to this list
	Quit ",AGGREGATE,AVG,MIN,MAX,SUM,COUNT,%FIRST,%LAST,STDEV,STDDEV,STDEVP,STDDEVP,VAR,VARIANCE,VARP,VARIANCEP,PERCENTILE,PERCENTILERANK,%LABEL,%KPI,%MDX,"[ 
		(","_$$$UPPER(pFunc)_",")
}

/// Rewrite a group and clean up the current member functions within it.
/// On return <var>pCmbrIndex</var> contains the list of cmbr substitutions:
/// pCmbrIndex("$$CMBRn$$") = spec<br/>
/// <var>pCmbrID</var> and <var>pCmbrList</var> are used to track state as this function recurses.
Method %RewriteForCurrentMember(pParentGroup As %DeepSee.Query.group, pGroup As %DeepSee.Query.group, Output pNewGroup As %DeepSee.Query.group, ByRef pCmbrIndex, ByRef pCmbrID, Output pCmbrList, pLevel As %Integer = 0, pTreatAsExpr As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set debug = 0

	W:debug ?pLevel*4,"REWRITE: ",pGroup," ",$G(pTreatAsExpr)
	If (pGroup.%IsA("%DeepSee.Query.setFunction")||pGroup.%IsA("%DeepSee.Query.memberFunction")) {
		W:debug " ",pGroup.function
	}
	W:debug !

		Set pNewGroup = ""
		// bottom-up search for current members
		// If pTreatAsExpr is true, then skip this branch
		// e.g. ORDER(f,cmbr)
		If ('pTreatAsExpr && pGroup.%IsA("%DeepSee.Query.memberFunction")&&($$$UPPER(pGroup.function)="CURRENTMEMBER")) {
	W:debug ?pLevel*4,"CASE CMBR",!
			// no need to descend further: that info is in the cmember qualifier property (built at parse time)
			// add this cmbr to the list
			Set pNewGroup = pGroup

			// First prepare the key text if it doesn't already exist
			New %dsMakeKey
			Set %dsMakeKey = 1
			Set tOrigText = pGroup.%ToString()
			Set:(pGroup.%cmbrKeyText="") pGroup.%cmbrKeyText = tOrigText
			Kill %dsMakeKey
			
			Set tID = $I(pCmbrID)
			// JMD1094 CMBR Marker has be more unique
			Set tHash = $ZCRC(tOrigText,7)
			Set pGroup.%cmbrMarker = "$$CMBR"_tID_":"_tHash_"$$"

			Set pCmbrList(tID) = pGroup
			Set tFirstChild = pGroup.children.GetAt(1)
			Set tSpec = $S($IsObject(tFirstChild):tFirstChild.spec,1:"")
			Set pCmbrIndex(pGroup.%cmbrMarker) = tSpec

			// No point in hanging on to the children of this node
			Do pGroup.children.Clear()

			// find caption for cmbr
			Set tCaption = "Member"
			Set tRelSpec = ""
			If (tSpec'="") {
				// parse spec; test for relations
				Kill tSpecInfo
				Set tFCube = ..cube
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
					Set tFSpec = tRelationSpec
				}
				If $$$ISERR(tSC) Quit

				// try to find best caption for currentMember, otherwise use dimension name
				Set q = $$$UPPER(pGroup.%cmbrQualifier)
				Set qp = $Find(q,"PROPERTIES(""")
				If (qp) {
					// JMD1373 Pull out first arg only
					// preserve case
					Set tTest = $E(pGroup.%cmbrQualifier,qp,*)
					Set tPropName = ""
					For t = 1:1:$L(tTest) {
						Set ch = $E(tTest,t)
						If (ch="""") {
							Quit
						}
						Else {
							Set tPropName = tPropName_ch
						}
					}

					If (tPropName'="") {
						// find property caption
						Set tCaption = tPropName
						Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(tFCube,.tSC)
						If $$$ISERR(tSC) Quit
						// JMD1373: only lookup caption if we have a complete path
						If ($G(tSpecInfo(1))'="")&&($G(tSpecInfo(2))'="")&&($G(tSpecInfo(3))'="") {
							Set tCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER($G(tSpecInfo(1))),$$$UPPER($G(tSpecInfo(2))),$$$UPPER($G(tSpecInfo(3))),$$$UPPER(tPropName))
						}

						Set:tCaption="" tCaption = tPropName

						// JMD909 find format for property
						If (($G(tDimNo)'="")&&($G(tHierNo)'="")&&($G(tLevelNo)'="")) {
							Set tPropInfo =  $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tFCube),"mbr#",tDimNo,tHierNo,tLevelNo,"prop",$$$UPPER(tPropName)))
							Set pGroup.%cmbrFormat = $LG(tPropInfo,6)
						}
					}
				}
				Else {
					Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(tFCube, $$$UPPER($G(tSpecInfo(1))),,,.tCaption)
					If $$$ISERR(tSC) Quit
				}
			}
			Set pGroup.%cmbrLabel = tCaption
			Set pGroup.%cmbrRelSpec = tRelSpec

			// put in a wrapper value;
			// this might get replaced as we pop up the graph
			Set tWrapper = pGroup.%cmbrMarker
			Set:pGroup.%cmbrQualifier'="" tWrapper = tWrapper _ "." _ pGroup.%cmbrQualifier
			Set pGroup.%cmbrWrapper = tWrapper

		} // if CURRENTMEMBER
		Else {
	W:debug ?pLevel*4,"BTM UP",!
			// do a bottom up search of all nodes in this group	
			Kill tChildren
			Kill tCmbrList
			Set tCount = pGroup.children.Count()

			Set tFunc = ""
			Kill tFuncInfo
			If (pGroup.%IsA("%DeepSee.Query.setFunction")) {
				// find types of function args
				Set tFunc = $$$UPPER(pGroup.function)
				Do ##class(%DeepSee.Query.setFunction).%GetFunctionInfo(tFunc,,,,.tFuncInfo)
			}

			For a = 1:1:tCount {
				Set tChildren(a) = pGroup.children.GetAt(a)
				If '$IsObject(tChildren(a)) {
					Set tSC = $$$ERROR($$$GeneralError,"Bad query")
					Quit
				}
				If (tChildren(a).%IsA("%DeepSee.Query.group")) {
					Kill tNewChild
					Set tTreatAsExpr = $S($LG($G(tFuncInfo),a)=$$$dstExpression:1,1:0)
					If (tTreatAsExpr&&'tChildren(a).%IsA("%DeepSee.Query.expression")) {
						// replace child with equivalent expression (using internal NOP)
						Set tExpr = ##class(%DeepSee.Query.expression).%New()
						Set tExpr.operator = "NOP"
						Set tZero = ##class(%DeepSee.Query.constant).%New()
						Set tZero.value = ""
						Do tExpr.children.SetAt(tChildren(a),1)
						Do tExpr.children.SetAt(tZero,2)
						Set tChildren(a) = tExpr
					}
					
					Set tSC = ..%RewriteForCurrentMember(pGroup,tChildren(a),.tNewChild,.pCmbrIndex,.pCmbrID,.tCmbrList,pLevel+1,tTreatAsExpr)
					If $$$ISERR(tSC) Quit
					If $IsObject(tNewChild) {
						// replace this child
						Set tChildren(a) = tNewChild
					}
				}
			}
			If $$$ISERR(tSC) Quit

			// were there cmbrs in this branch?
			If $D(tCmbrList) {
				// DP-405378 - Fetch the orginal text without the resolved current member indices for key creation stability.
				// The %dsMakeKey signals some elements (eg: CURRENTMEMBER) to refer to pre-resolution values.
				New %dsMakeKey 
				Set %dsMakeKey = 1
				Set tOrigText = pGroup.%ToString()
				Kill %dsMakeKey
						
				If (pGroup.%IsA("%DeepSee.Query.setFunction")) {
					//W:debug ?pLevel*4+2,"SET",!
					// array for testing for aggregates and which children are expressions, if any
					// ! fold into %IsAggFunc
					Set tAggList("AGGREGATE") = 2
					Set tAggList("AVG") = 2
					Set tAggList("SUM") = 2
					Set tAggList("MIN") = 2
					Set tAggList("MAX") = 2
					Set tAggList("COUNT") = 0
					Set tAggList("%DISTINCT") = 0
					Set tAggList("%FIRST") = 2
					Set tAggList("%LAST") = 2
					Set tAggList("%LIST") = 2
					Set tAggList("STDEV") = 2
					Set tAggList("STDDEV") = 2
					Set tAggList("STDEVP") = 2
					Set tAggList("STDDEVP") = 2
					Set tAggList("MEDIAN") = 2
					Set tAggList("VAR") = 2
					Set tAggList("VARIANCE") = 2
					Set tAggList("VARP") = 2
					Set tAggList("VARIANCEP") = 2
					Set tAggList("PERCENTILE") = 2
					Set tAggList("PERCENTILERANK") = 2
					Set tAggList("%MDX") = 0
					Set tAggList("%KPI") = 0

					// functions that do NOT go into wrapper
					Set tIgnoreList("%LABEL") = ""

					Set tParentIsSet = 0
					If (($IsObject(pParentGroup)&&pParentGroup.%IsA("%DeepSee.Query.setFunction"))) {
						Set tParentFunc = $$$UPPER(pParentGroup.function)
						If ('$D(tAggList(tParentFunc))) {
							// ignore parent if it is an agg
							Set tParentIsSet = 1
						}
					}

					Set tCJoinList("CROSSJOIN") = ""
					Set tCJoinList("NONEMPTYCROSSJOIN") = ""

					Set tFunc = $$$UPPER(pGroup.function)
					Set tIsAgg = (tFunc'="") && $D(tAggList(tFunc))
					Set tIsCJoin = (tFunc'="") && $D(tCJoinList(tFunc))
					Set tIsIgnore = (tFunc'="") && $D(tIgnoreList(tFunc))

					If (tIsIgnore) {
						Set pNewGroup = pGroup
					}
					Else {
						// after we find an AGG function, we are done
						// if we don't we will have to add one

						// replace group with cmbr
						Set pNewGroup = ##class(%DeepSee.Query.memberFunction).%New()
						Set pNewGroup.function = "CurrentMember"
						Set tCaption = pGroup.function  // default

						Set tInnerWrapper = ""
						Set tRemoveCJoin = 0

						Set tItemCount = 0
						For a = 1:1:tCount {
							Set tSkip = 0
							If (tChildren(a).%IsA("%DeepSee.Query.memberFunction")&&($$$UPPER(tChildren(a).function)="CURRENTMEMBER")) {
								// child is a current member
								Set tCaption = tChildren(a).%cmbrLabel
							
								// pass up aggregate and measure
								Set pNewGroup.%cmbrAgg = tChildren(a).%cmbrAgg
								Set pNewGroup.%cmbrMeasure = tChildren(a).%cmbrMeasure
								Set pNewGroup.%cmbrLiteral = tChildren(a).%cmbrLiteral
								Set pNewGroup.%cmbrRelSpec = tChildren(a).%cmbrRelSpec
								Set pNewGroup.%cmbrFormat = tChildren(a).%cmbrFormat
							}
							
							If (tFunc="PERCENTILE")&&(a=3) {
								// DP-402439 - For PERCENTILE the %cmbrLiteral is read to place the particular value in
								// the function spec to be stored in the axis cache.
								Set pNewGroup.%cmbrLiteral = tChildren(a).value
							}

							If (tIsAgg && (a = tAggList(tFunc))) {
								// we expect an expression for this argument;
								// leave expression out of aggregate function; 
								// we will deal with it later!
								If (a<tCount) {
									// don't leave a gap!!!
									If tChildren(a).%IsA("%DeepSee.Query.expression") {
										// DP-402439 - If this is the expression argument for this function *and*
										// it has been written as a canonical %DeepSee.Query.expression (including the "NOP")
										// include the complete expression when building the innerWrapper  
										Set tArg = tChildren(a).%ToString()
									}
									Else {
										Set tArg = 0
									}
								}
								Else {
									Set tSkip = 1
								}
							}
							ElseIf (tIsCJoin && tChildren(a).%IsA("%DeepSee.Query.memberSpec")) {
								// CJOIN(x,measure) ==> move measure to cmbr, remove CJOIN
								// test for measure
								Set tSC = ..%GetMeasureFromSpec(tChildren(a).spec,.tMeasure)
								If $$$ISERR(tSC) Quit
								If (tMeasure'="") {
									Set tRemoveCJoin = 1
									Set tSkip = 1
									Set pNewGroup.%cmbrMeasure = tMeasure
								}
								Else {
									Set tArg = tChildren(a).%ToString()
								}
							}
							Else {
								Set tArg = tChildren(a).%ToString()
							}
						
							If ('tSkip) {
								Set tInnerWrapper = tInnerWrapper _ $S(tItemCount=0:"",1:",") _ tArg
								Set tItemCount = tItemCount + 1
							}
						}
						If (tRemoveCJoin) {
							If (tItemCount>1) {
								Set tWrapper = "("_tInnerWrapper_")"
							}
							Else {
								Set tWrapper = tInnerWrapper
							}
						}
						Else {
							Set tWrapper = pGroup.function_"("_tInnerWrapper_")"
						}
					
						Set pNewGroup.%cmbrWrapper = tWrapper
						Set pNewGroup.%cmbrLabel = tCaption
						If (tItemCount>1) {
							// put parens back
							Set tInnerWrapper = tWrapper
						}

						// return this cmbr up unless we are in an agg
						If ('tIsAgg) {
							If ('tParentIsSet) {
								// if our parent is a set, then we are done
								Set tID = $I(pCmbrID)
								Set pCmbrList(tID) = pNewGroup
							}
						}
						Else {
							// for aggregates with expressions,
							// rewrite the query to bury the cmbr in the expression
							Set pNewGroup.%cmbrAgg = tFunc
							If (+$G(tAggList(tFunc))>0) {
								Set tExp = $G(tChildren(+$G(tAggList(tFunc))))

								If $IsObject(tExp) {
									Set tInline = 0
									// test for simple expressions (measures)
									// that we can inline
									If (tExp.%IsA("%DeepSee.Query.constant")) {
										// add literal to cmbr
										// remove function from wrapper
										Set pNewGroup.%cmbrWrapper = tInnerWrapper
										Set pNewGroup.%cmbrLiteral = tExp.%GetValue()
										Set tInline = 1
									}
									ElseIf (tExp.%IsA("%DeepSee.Query.memberSpec")) {
										Set tSC = ..%GetMeasureFromSpec(tExp.spec,.tMeasure)
										If $$$ISERR(tSC) Quit
										If (tMeasure'="") {
											Set tCubeIndex = $$$DeepSeeIndex(..cube)
											Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbrs","MEASURES",$$$UPPER(tMeasure)))
												If (tInfo'="") {
												Set tMsrNo = +$LG(tInfo,2)
												Set tMsrInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",0,tMsrNo,0))
												// remove function from wrapper ???
												Set pNewGroup.%cmbrWrapper = tInnerWrapper
												Set pNewGroup.%cmbrMeasure = tMeasure
												Set tInline = 1
											}
										}
									}
									If ('tInline) {
										// rewrite expression by pushing cmbr down
										// remove function from wrapper
										Set pNewGroup.%cmbrWrapper = tInnerWrapper
										Set tSC = ..%PushDownCurrentMember(.tNewGroup, pNewGroup,tExp)
										If $$$ISERR(tSC) Quit
										Set pNewGroup = tNewGroup
									}
								}
							}
						}
						
						If pNewGroup.%IsA("%DeepSee.Query.memberFunction") {
							Set pNewGroup.%cmbrKeyText = tOrigText		// DP-405378 - Keep the original text available for key generation
						}
					}
				}
				ElseIf (pGroup.%IsA("%DeepSee.Query.tuple")) {
	W:debug ?pLevel*4+2,"TUPLE",!
					// replace tuple with cmbr
					Set pNewGroup = ##class(%DeepSee.Query.memberFunction).%New()
					Set pNewGroup.function = "CurrentMember"
					Set tCaption = "" // default

					Set tWrapper = ""

					Set tItemCount = 0
					For a = 1:1:tCount {
						Set tSkip = 0
						If (tChildren(a).%IsA("%DeepSee.Query.memberFunction")&&($$$UPPER(tChildren(a).function)="CURRENTMEMBER")) {
							// use first cmbr in tuple as label?
							// !!! or use last member of tuple !!!
							Set tCaption = tChildren(a).%cmbrLabel
						}
						ElseIf (tChildren(a).%IsA("%DeepSee.Query.memberSpec")) {
							// test for measure
							Set tSC = ..%GetMeasureFromSpec(tChildren(a).spec,.tMeasure)
							If $$$ISERR(tSC) Quit

							If (tMeasure'="") {
								Set pNewGroup.%cmbrMeasure = tMeasure
								Set pNewGroup.%cmbrAgg = "SUM"
								Set tSkip = 1
							}
						}
						If ('tSkip) {
							Set tWrapper = tWrapper _ $S(tItemCount=0:"",1:",") _ tChildren(a).%ToString()
							Set tItemCount = tItemCount + 1
						}
					}
					Set:tItemCount>1 tWrapper = "(" _ tWrapper _ ")"
					Set pNewGroup.%cmbrWrapper = tWrapper
					Set pNewGroup.%cmbrLabel = tCaption
					Set pNewGroup.%cmbrKeyText = tOrigText		// DP-405378 - Keep the original text available for key generation
				}
				Else {
	W:debug ?pLevel*4+2,"COPY",!
					// copy children into group; convert cmbrs
					For a = 1:1:tCount {
						Set tChild = tChildren(a)
						If (tChild.%IsA("%DeepSee.Query.memberFunction")&&($$$UPPER(tChild.function)="CURRENTMEMBER")) {
							If ((tChild.%cmbrWrapper'="")||(tChild.%cmbrQualifier'="")) {
								If (tChild.%cmbrAgg="") {
									Set tChild.%cmbrAgg = "SUM"
								}
							}
							If ((tChild.%cmbrMarker'="")&&(tChild.%cmbrWrapper="")) {
								If (tChild.%cmbrQualifier'="") {
									Set tChild.%cmbrWrapper = tChild.%cmbrMarker _ "." _ tChild.%cmbrQualifier
									Set tChild.%cmbrQualifier = ""
								}
								Else {
									Set tChild.%cmbrWrapper = tChild.%cmbrMarker
								}
							}							
						}
						Do pGroup.children.SetAt(tChild,a)
					}
					Set pNewGroup = pGroup
				}
			} // if CMBRlist
			ElseIf (pGroup.%IsA("%DeepSee.Query.calculatedMember")&&$IsObject(tChildren(1))) {
	W:debug ?pLevel*4,"CALC",!
				Set tGroupLabel = pGroup.originalName
				
				// DTB439 - Use parser to obtain correct label contents
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tGroupLabel,.tGroupLabelInfo)
				If $$$ISERR(tSC) Quit
				Set tGroupLabel = tGroupLabelInfo(1)
				
				// DTB596 - remove calcmbr from graph if it does not contain direct expressions.
				// Otherwse leave it as is.
				Set pNewGroup = tChildren(1)
				If (pNewGroup.%IsA("%DeepSee.Query.expression")||pNewGroup.%IsA("%DeepSee.Query.constant")) {
					// copy over label & format
					Set pNewGroup.formatString = pGroup.formatString
					Set pNewGroup.label = tGroupLabel
					// JMD1504
					If (pNewGroup.%IsA("%DeepSee.Query.expression")) {
						Set pNewGroup.solveOrder = pGroup.solveOrder
					}
				}
				Else {
					// DTB439 - In this case, maintain the calc member
					Set pNewGroup = pGroup
				}
			}
			Else {
	W:debug ?pLevel*4,"COPY GROUP",!

				// copy children into group
				For a = 1:1:tCount {
					Do pGroup.children.SetAt(tChildren(a),a)
				}
				Set pNewGroup = pGroup
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	W:debug ?pLevel*4,"===>>: ",pNewGroup
	If ($IsObject(pNewGroup)&&(pNewGroup.%IsA("%DeepSee.Query.setFunction")||pNewGroup.%IsA("%DeepSee.Query.memberFunction"))) {
		W:debug " ",pNewGroup.function," ",pNewGroup.%ToString()
	}
	W:debug !

	Quit tSC
}

/// Rewrite a group and rewrite any CJOIN(agg(a),b) to CJOIN(b,agg(a))).
/// Do the same for expression in the first child.
Method %RewriteForCrossJoin(pParentGroup As %DeepSee.Query.group, pGroup As %DeepSee.Query.group, Output pNewGroup As %DeepSee.Query.group, pLevel As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pNewGroup = ""
		Set tWrapper = ""

		If (pGroup.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(pGroup.function)["CROSSJOIN")) {
			Set tChild1 = pGroup.children.GetAt(1)
			Set tChild2 = pGroup.children.GetAt(2)
			// JMD1045: avoid OREF error
			If ('$IsObject(tChild1)||'$IsObject(tChild2)) {
				Quit
			}
			
			// DTB078 - Do not allow crossjoin of two measures
			// DTB125 - add status checks to capture individual crossjoin errors
			Set tChild1IsMeasure = ..%IsMeasure(tChild1,.tSC)
			If $$$ISERR(tSC) Quit
			Set tChild2IsMeasure = ..%IsMeasure(tChild2,.tSC)
			If $$$ISERR(tSC) Quit
			If tChild1IsMeasure&&tChild2IsMeasure {
				Set tSC = $$$ERROR($$$GeneralError,"Two measures cannot be crossjoined")
				Quit
			}
			
			// +DTB203 - Special handling for the Analyzer construction
			//   CJ(AGG(set),{MSR[S]})
			// AGG function that defines its own measure should already have been stripped out
			If (tChild1.%IsA("%DeepSee.Query.setFunction") && ..%IsAggFunc(tChild1.function) ) && 
					( (tChild1.function'="%LABEL")  || 
					(tChild1.children.GetAt(1).%IsA("%DeepSee.Query.setFunction") && ..%IsAggFunc(tChild1.children.GetAt(1).function)) )			
				&& tChild2IsMeasure {
				Set tHasLabel = 0
				If tChild1.function="%LABEL" {
					Set tHasLabel = 1
					Set tSC = ..%RemoveLabel(tChild1,.tLabel,.tTempNode)
					If $$$ISERR(tSC) Quit
					
					Set tChild1 = tTempNode
				}
				
				
				If tChild2.%IsA("%DeepSee.Query.set") {
					// Rewrite the current pGroup to be a set of AGG functions, one for each measure
					Set pNewGroup = ##class(%DeepSee.Query.set).%New()
					
					Set tChild2MeasureCount = tChild2.children.Count()
					For n=1:1:tChild2MeasureCount {
						Kill tAggFunction,tAggMeasure
						Set tAggFunction = tChild1.%ConstructClone()		// Multiple copies of these are needed
					
						Set tAggSet = tAggFunction.children.GetAt(1)
						Set tAggMeasure = tChild2.children.GetAt(n)
						
						Do tAggFunction.children.Clear()
						Do tAggFunction.children.Insert(tAggSet)
						Do tAggFunction.children.Insert(tAggMeasure)
						
						If tHasLabel {
							// Wrap the new aggregate in the label
							Set tSC = ..%AddLabel(tAggFunction,tLabel,.tAggLabel)
							If $$$ISERR(tSC) Quit		// This quits the FOR loop

							Do pNewGroup.children.Insert(tAggLabel)
						}
						Else {
							Do pNewGroup.children.Insert(tAggFunction)
						}
					}
					If $$$ISERR(tSC) Quit		// This quits the method
				}
				Else {
					// Insert single measure into the aggregate function and return it as the new group
					Set tAggSet = tChild1.children.GetAt(1)
					Set tAggMeasure = tChild2
					
					Do tChild1.children.Clear()
					Do tChild1.children.Insert(tAggSet)
					Do tChild1.children.Insert(tAggMeasure)
					
					If tHasLabel {
						// Wrap the new aggregate in the label
						Set tSC = ..%AddLabel(tChild1,tLabel,.tChildLabel)
						If $$$ISERR(tSC) Quit

						Set pNewGroup = tChildLabel
					}
					Else {
						Set pNewGroup = tChild1
					}
				}
				
				Quit		// No more crossjoin, quit the method
			}
			// -DTB203
			
			If (tChild1.%IsA("%DeepSee.Query.expression") ||
				tChild1.%IsA("%DeepSee.Query.calculatedMember") ||
				(tChild1.%IsA("%DeepSee.Query.setFunction")&&..%IsAggFunc(tChild1.function)) ||
				(tChild1.%IsA("%DeepSee.Query.set")&&$IsObject(tChild1.children.GetAt(1))&&tChild1.children.GetAt(1).%IsA("%DeepSee.Query.calculatedMember"))) {
				
				If tChild1IsMeasure &&
					tChild1.%IsA("%DeepSee.Query.calculatedMember") &&
					'..%IsCrossjoinSwapExempt(tChild1,tChild2) {
					// DTB400 - Rewrite the first child as a %MDX subquery to prevent need for the swap.
					// This will get tested for exemption again to verify successful replacement.
					Set tTempNode = ..%RewriteNodeAsSubquery(tChild1.children.GetAt(1))
					
					If tTempNode'=$$$NULLOREF {
						// DTB400 - Replace the calculatedMember's term with a new subquery
						Do tChild1.children.Clear()
						Do tChild1.children.Insert(tTempNode)
					}
				}
				
				// DTB400 - New test for swap exemption.		DTB074 - Test to see if we should abort the swap
				If '..%IsCrossjoinSwapExempt(tChild1,tChild2) {
					// Perform the swap
					Do pGroup.children.Clear()
					Do pGroup.children.Insert(tChild2)
					Do pGroup.children.Insert(tChild1)
				}
				
				If ('tChild1.%IsA("%DeepSee.Query.set")) {
					// if set, then this is the MyRegion.Members case!
					Set tFlag = ##class(%DeepSee.Query.flag).%New()
					Set tFlag.value = "HIDE_CHILDREN"
					Do pGroup.children.Insert(tFlag)
				}
			}
			// JMD844: convert CJ(A,CJ(B,C)) to CJ(CJ(A,B),C)
			// unless B&C are from same hierarchy but not same as A
			ElseIf (tChild2.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(tChild2.function)["CROSSJOIN")) {
				Set tA = tChild1
				Set tCJ = tChild2
				Set tB = tChild2.children.GetAt(1)
				Set tC = tChild2.children.GetAt(2)
				
				// +DTB125 - check for crossjoining measures
				Set tAIsMeasure = ..%IsMeasure(tA)
				Set tBIsMeasure = ..%IsMeasure(tB)
				Set tCIsMeasure = ..%IsMeasure(tC)
				
				If ((tAIsMeasure+tBIsMeasure+tCIsMeasure) > 1) {
					Set tSC = $$$ERROR($$$GeneralError,"Two measures cannot be crossjoined")
					Quit
				}
				// -DTB125

				// keep shufflin' and reducin'
				While ($IsObject(tCJ)) {

					// JMD1196
					// if B&C are from same hierarchy, and not the same as A, then do not shuffle
					// find member info
					Set tSC = ..%FindMemberInfo(tA,.tMemberA)
					If $$$ISERR(tSC) Quit

					Set tSC = ..%FindMemberInfo(tB,.tMemberB)
					If $$$ISERR(tSC) Quit

					Set tSC = ..%FindMemberInfo(tC,.tMemberC)
					If $$$ISERR(tSC) Quit

					Set tBCSame = 0
					Set tABCSame = 0
					If ($IsObject(tMemberB)&&$IsObject(tMemberC)&&
						(tMemberB.%dimNumber=tMemberC.%dimNumber) &&
						(tMemberB.%hierNumber=tMemberC.%hierNumber)) {
						Set tBCSame = 1
					}

					If (tBCSame && $IsObject(tMemberA)&&
						(tMemberA.%dimNumber=tMemberB.%dimNumber) &&
						(tMemberA.%hierNumber=tMemberB.%hierNumber)) {
						Set tABCSame = 1
					}

					If ('tBCSame || tABCSame) {
						Do tCJ.children.Clear()

						Do tCJ.children.Insert(tA)
						Do tCJ.children.Insert(tB)

						Do pGroup.children.Clear()
						Do pGroup.children.Insert(tCJ)
						Do pGroup.children.Insert(tC)

						// set up for another go around
						Set tA = tCJ
						Set tCJ = tC
						If (tCJ.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(tCJ.function)["CROSSJOIN")) {
							Set tB = tCJ.children.GetAt(1)
							Set tC = tCJ.children.GetAt(2)
						}
						Else {
							Set tCJ = ""
						}
					}
					Else {
						// do nothing more for now
						Set tCJ = ""
					}
				}
			}
		}
		Else {
			// keep going
			Set tCount = pGroup.children.Count()
			For a = 1:1:tCount {
				Set tChild = pGroup.children.GetAt(a)
				If (tChild.%IsA("%DeepSee.Query.group")) {
					Kill tNewChild
					Set tSC = ..%RewriteForCrossJoin(pGroup,tChild,.tNewChild,pLevel+1)
					If $$$ISERR(tSC) Quit
					If $IsObject(tNewChild) {
						// replace this child
						Do pGroup.children.SetAt(tNewChild,a)
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Rewrite a group if necessary to sort the members of pOppAxis. 
Method %RewriteForOrder(pAxis As %DeepSee.Query.axis, pOppAxis As %DeepSee.Query.axis) As %Status
{
	Set tSC = $$$OK
	Try {
		
		// DP-402168: Check for Order-Subset case, and if so, add context to pOppAxis
		// by copying the subset function group from pAxis to a subtree in pOppAxis
		Set tSC = ..%HasSubsetFunction(.pAxis, .tSubsetGroup, .tHasSubsetFunction)
		If $$$ISERR(tSC) Quit
		If tHasSubsetFunction {
			// Create a %OR node that will serve as the group replacing the measure expression
			Set tORNode = ##class(%DeepSee.Query.setFunction).%New("%OR")
			
			// Put tCopy below tORNode, and replace the child of tSubsetGroup that has the measure
			Set tCopy = tSubsetGroup.%ConstructClone(1)
			Do tORNode.children.Insert(tCopy)
			
			// Find tOrderGroup on pOppAxis
			Set tSC = ..%HasOrder(pOppAxis, .tHasOrder, .tOrderGroup)
			If $$$ISERR(tSC) Quit
			
			// Make a deep copy of tOrderGroup's children, then clear tOrderGroup's children
			Set tCount = tOrderGroup.children.Count() 
			Set tClone = tOrderGroup.%ConstructClone(1)
			Do tOrderGroup.children.Clear()
			
			// Fill tOrderGroup's children with tClone's, replacing the memberSpec with tOrNode
			For i=1:1:tCount {
				Set tChild = tClone.children.GetAt(i)
				If (tChild.%IsA("%DeepSee.Query.memberSpec")) { // Put tORnode into tOrderGroup function
					Do tOrderGroup.children.Insert(tORNode)
				} 
				Else {
					Do tOrderGroup.children.Insert(tChild)
				}
			}
		}
	} 
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility. See if this spec is for a measure. If so return the measure name.
ClassMethod %GetMeasureFromSpec(pSpec As %String, Output pMeasure) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pMeasure = ""
		If (pSpec="") Quit
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pSpec,.tSpecInfo,.tQuoted)
		If $$$ISERR(tSC) Quit

		If ($$$UPPER($G(tSpecInfo(1))) = "MEASURES") {
			Set pMeasure = $G(tSpecInfo(2))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Push a current member down into an expression tree.
Method %PushDownCurrentMember(Output pNewGroup As %DeepSee.Query.group, pCurrMember As %DeepSee.Query.group, pExpr As %DeepSee.Query.group, pLevel As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pExpr.%IsA("%DeepSee.Query.memberSpec")) {
			// test for measure!
			Set tSC = ..%GetMeasureFromSpec(pExpr.spec,.tMeasure)
			If $$$ISERR(tSC) Quit
			If (tMeasure'="") {
				// fold measure into cmbr
				Set pNewGroup = pCurrMember.%ConstructClone()
				Set pNewGroup.%cmbrMeasure = tMeasure
			}
			Else {
				// combine item with current member (using tuple)
				Set pNewGroup = ##class(%DeepSee.Query.tuple).%New()
				Set tClone = pCurrMember.%ConstructClone()
				Do pNewGroup.children.Insert(tClone)
				Do pNewGroup.children.Insert(pExpr)
			}
		}
		ElseIf (pExpr.%IsA("%DeepSee.Query.constant")) {
			// don't fold literal into cmbr!
			Set pNewGroup = pExpr.%ConstructClone()
		}
		ElseIf (pExpr.%IsA("%DeepSee.Query.group")) {
			// keep going
			For n=1:1:pExpr.children.Count() {
				Set tSC = ..%PushDownCurrentMember(.tNewGroup,pCurrMember,pExpr.children.GetAt(n),pLevel+1)
				If $$$ISERR(tSC) Quit
				Do pExpr.children.SetAt(tNewGroup,n)
			}
			If $$$ISERR(tSC) Quit
			Set pNewGroup = pExpr
		}
		Else {
			// combine item with current member (using tuple)
			Set pNewGroup = ##class(%DeepSee.Query.tuple).%New()
			Set tClone = pCurrMember.%ConstructClone()
			Do pNewGroup.children.Insert(tClone)
			Do pNewGroup.children.Insert(pExpr)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Build member restriction data from the materialized slicer axis.
/// This is called by %GetMembers to prune the results based on the current slicer.
Method %ProcessSlicerRestrictions(Output pBranches, Output pNoData As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// JMD947
		Kill pBranches
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		Set pNoData = 0

		// is there a slicer axis?
		If (..%QueryKey'="") {
			Set tSlicerKey = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axis",0))
			If (tSlicerKey'="") {
				Set tSC = ##class(%DeepSee.Query.Engine).%GetBranchesForSlicer(..cube,tSlicerKey,.pBranches,.tHasRelations,.tReferencedFacts)		// DTB567 - Return and check status
				If $$$ISERR(tSC) Quit
			}
		}
		If ('$D(pBranches)&&$D(tReferencedFacts)) {
			Set pNoData = 1
		}
		If $D(pBranches)&&($G(pBranches)=1)&&($LG($G(pBranches(1,1)),2)="NO MEMBER") {
			// DTB926 - Check specifically for the special NO MEMBER distinction in a single branch.
			// This means the slicer defines a null result.
			Set pNoData = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Walk down a given node within the slicer and flatten expressions and aggregate functions.
Method %FlattenSlicer(pNode As %DeepSee.Query.group, pLevel As %Integer = 0, Output pMoveAll As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pMoveAll = 0
		If '$IsObject(pNode) Quit

		If $IsObject(..axes.GetAt(3)) {
			// DTB141 - Analyzer may place a calculated measure on axis 3. Move everything in this case. 
			Set pMoveAll = 1
		}

		// JMD1213: in some limited cases move the entire slicer to axis 3!
		// namely: {expr,...} || {%KPI()}
		Set tTerm = pNode.children.GetAt(1)
		If ('pMoveAll && (pLevel=0) && $IsObject(tTerm) && (tTerm.%IsA("%DeepSee.Query.set")||tTerm.%IsA("%DeepSee.Query.setFunction"))) {
			// JMD1234: list of functions to allow in WHERE clause
			Set tSkip("EXCEPT") = ""
			Set tSkip("CROSSJOIN") = ""
			Set tSkip("NONEMPTYCROSSJOIN") = ""
			Set tSkip("%OR") = ""
			Set tSkip("%TIMERANGE") = ""

			// JMD1346 more set-generating functions
			Set tSkip("UNION") = ""
			Set tSkip("INTERSECT") = ""
			Set tSkip("EXCEPT") = ""
			Set tSkip("DISTINCT") = ""
			Set tSkip("HEAD") = ""
			Set tSkip("SUBSET") = ""
			Set tSkip("TAIL") = ""

			// JMD1374 let these pass thru and simplify them further down
			Set tSkip("AGGREGATE") = ""
			Set tSkip("SUM") = ""
			Set tSkip("COUNT") = ""

			For n = 1:1:tTerm.children.Count() {
				Set tChild = tTerm.children.GetAt(n)
				If (tChild.%IsA("%DeepSee.Query.expression")) {
					Set pMoveAll = 1
					Quit
				}
				ElseIf (tChild.%IsA("%DeepSee.Query.setFunction")) {
					Set tFunc =  $$$UPPER(tChild.function)
					// DTB063: if there are any functions that do not belong in the slicer,
					// move it in its entirety to the 3rd axis
					If ((tFunc'="")&&'$D(tSkip(tFunc))) {	// JMD1233
						Set pMoveAll = 1
					}
					Quit
				}
			}
		}

		If ('pMoveAll) {
			// now see if can remove unimportant items from the slicer
			// such as constants
			Set k = 0
			For n = 1:1:pNode.children.Count() {
				Set tRemove = 0
				Set tTerm = pNode.children.GetAt(n)
				If (tTerm.%IsA("%DeepSee.Query.constant")) {
					Set tRemove = 1
				}
				ElseIf (tTerm.%IsA("%DeepSee.Query.range")) {
					// JMD1116 -- see if we can compress this range
					Set tTerm = ..%CompressTimeRange(tTerm)
				}
				ElseIf (tTerm.%IsA("%DeepSee.Query.calculatedMember")) {
					// JMD1442 check for simple calc member
					Set tSimple = 0
					If (tTerm.children.Count()=1) {
						Set tFirstChild = tTerm.children.GetAt(1)
						If (tFirstChild.%IsA("%DeepSee.Query.memberSpec")) {
							Set tSimple = 1
						}
					}

					If ($IsObject(tTerm.parent) && 'tSimple) {
						Set tParent = tTerm.parent
						Set tRemove = 1
						If ((tParent.%IsA("%DeepSee.Query.setFunction"))) {
							If ($$$UPPER(tParent.function="CROSSJOIN")||$$$UPPER(tParent.function="NONEMPTYCROSSJOIN")) {
								// remove from crossjoin
								// JMD887 (unless first child is an %OR)
								Set tFirstChild = tTerm.children.GetAt(1)
								Set tSecondChild = tTerm.children.GetAt(2)
								If ($IsObject(tFirstChild) && tFirstChild.%IsA("%DeepSee.Query.setFunction") && ($$$UPPER(tFirstChild.function)="%OR")) {
									Set tRemove = 0
								}
							}
							Else {
								Set tRemove = 0
							}
						}
						Else {
							// JMD882: test for calc member that is a simple set or range
							// in this case, leave it in the slicer
							If (tTerm.children.Count()=1) {
								Set tFirstChild = tTerm.children.GetAt(1)

								// JMD887: do not flatten OR
								If (tFirstChild.%IsA("%DeepSee.Query.setFunction") && ($$$UPPER(tFirstChild.function)="%OR")) {
									Set tRemove = 0
									If ((tFirstChild.children.Count()=1)&&$IsObject(tFirstChild.children.GetAt(1))&&tFirstChild.children.GetAt(1).%IsA("%DeepSee.Query.range")) {
										// JMD1116 -- %OR(range) -- see if we can compress this range
										Set tArg1 = tFirstChild.children.GetAt(1)
										Set tNewTerm = ..%CompressTimeRange(tArg1)
										If (tNewTerm'=tArg1) {
											Do tTerm.children.SetAt(tNewTerm,1)
										}
									}
								}
								ElseIf (('tFirstChild.%IsA("%DeepSee.Query.setFunction"))&&(tFirstChild.%IsA("%DeepSee.Query.set")||tFirstChild.%IsA("%DeepSee.Query.range")||tFirstChild.%IsA("%DeepSee.Query.memberSpec"))) {
									Set tRemove = 0
									Set tSC = ..%FlattenSlicer(tTerm,pLevel+1,.pMoveAll)
									If $$$ISERR(tSC) Quit
									If (tTerm.children.Count()=0) {
										Set tRemove = 1
									}
								}
							}
						}

						If (tRemove) {
							// move expression to another axis
							// JMD1442 move everything
							Set pMoveAll = 1
						}
					}
				}
				ElseIf (tTerm.%IsA("%DeepSee.Query.expression")) {
					// remove expressions
					Set tRemove = 1

					// JMD1213 Move expression to third axis
					If (tRemove) {
						// JMD1442 move everything
						Set pMoveAll = 1
					}
				}
				ElseIf (tTerm.%IsA("%DeepSee.Query.tuple")||tTerm.%IsA("%DeepSee.Query.set")) {
					// process children
					Set tSC = ..%FlattenSlicer(tTerm,pLevel+1,.pMoveAll)
					If $$$ISERR(tSC) Quit
					If (tTerm.children.Count()=0) {
						Set tRemove = 1
					}
				}
				ElseIf (tTerm.%IsA("%DeepSee.Query.setFunction")) {
					Set tFunction = $$$UPPER(tTerm.function)
					If ((tFunction="SUM")||
						(tFunction="COUNT")|| 
						(tFunction="%DISTINCT")|| 
						(tFunction="AVG")|| 
						(tFunction="MIN")|| 
						(tFunction="MAX")|| 
						(tFunction="AGGREGATE")) {
						// replace function with simple set
						Set tSet = ##class(%DeepSee.Query.set).%New()
						For j = 1:1:tTerm.children.Count() {
							Set tChild = tTerm.children.GetAt(j)
							Do tSet.children.Insert(tChild)
						}
						Set tTerm = tSet
					}
					ElseIf ((tFunction="CROSSJOIN")||
							(tFunction="NONEMPTYCROSSJOIN")) {

						// process children
						Set tSC = ..%FlattenSlicer(tTerm,pLevel+1,.pMoveAll)
						If $$$ISERR(tSC) Quit

						// test if child was removed!
						If (tTerm.children.Count()<2) {
							// replace cross join with first arg
							Set tTerm = tTerm.children.GetAt(1)
						}
					}
					// JMD1116 test for %OR(TimeRange)
					ElseIf ((tFunction="%OR")&&(tTerm.children.Count()=1)&&($IsObject(tTerm.children.GetAt(1)))&&tTerm.children.GetAt(1).%IsA("%DeepSee.Query.range")) {
						Set tNewTerm = ..%CompressTimeRange(tTerm.children.GetAt(1))
						If (tNewTerm'=tTerm.children.GetAt(1)) {
							// DTB698 - The time compression has changed the term. 
							// Examine it further to determine how it should be placed back into this %OR
							If (tNewTerm.%IsA("%DeepSee.Query.setFunction")&&(tNewTerm.function="%OR")) {
								// DTB698 - If the compressed time range is already a %OR, use that in place of
								// the current %OR
								Set tTerm=tNewTerm
							}
							ElseIf (tNewTerm.%IsA("%DeepSee.Query.set")&&('tNewTerm.%IsA("%DeepSee.Query.tuple"))) {
								// DTB698 - If the returned term is a true set, place it directly into the current %OR
								Do tTerm.children.Clear()
								Do tTerm.children.Insert(tNewTerm)
							}
							Else {
								// DTB698 - Wrap the returned term in a set and set it into the current %OR
								Set tNewSet = ##class(%DeepSee.Query.set).%New()
								Do tNewSet.children.Insert(tNewTerm)
								Do tTerm.children.Clear()
								Do tTerm.children.Insert(tNewSet)
							}
						}
					}
					// JMD1460 - special handling for more complex %OR() cases
					ElseIf (tFunction="%OR") {
						Set tOrSet = tTerm.children.GetAt(1)
						If $IsObject(tOrSet) {
							For t=1:1:tOrSet.children.Count() {
								Set tTermChild = tOrSet.children.GetAt(t)
								
								If (tTermChild.%IsA("%DeepSee.Query.range")) {
									// JMD1466 - %OR({range})
									Set tNewTerm = ..%CompressTimeRange(tTermChild)
									If (tNewTerm'=tTermChild) {
										Do tOrSet.children.SetAt(tNewTerm,t)
									}
								}
								ElseIf (tTermChild.%IsA("%DeepSee.Query.setFunction")&&
									($$$UPPER(tTermChild.function)="%OR")
									&&(tTermChild.children.Count()=1)
									&&($IsObject(tTermChild.children.GetAt(1)))
									&&tTermChild.children.GetAt(1).%IsA("%DeepSee.Query.range")) {
									// JMD1460 - %OR(%OR(TimeRange))
									Set tNewTerm = ..%CompressTimeRange(tTermChild.children.GetAt(1))
									If (tNewTerm'=tTermChild.children.GetAt(1)) {
										Do tTermChild.children.SetAt(tNewTerm,1)
									}
								}
								ElseIf (tTermChild.%IsA("%DeepSee.Query.calculatedMember")) {
									// DTB069 - %OR({[CALCULATED].[MEMBER]}), recurse on the %OR node
									Set tSC = ..%FlattenSlicer(tTerm,pLevel+1,.pMoveAll)
									If $$$ISERR(tSC) Quit
								}
							}
						}
					}
				}
				If ('tRemove) {
					Set tList($I(k)) = tTerm
				}
			}
			If $$$ISERR(tSC) Quit

			// Rebuild collection with undeleted items
			If ('pMoveAll) {
				Do pNode.children.Clear()
				Set n = $O(tList(""))
				While (n'="") {
					Do pNode.children.Insert(tList(n))
					Set n = $O(tList(n))
				}
			}
		}

		// JMD1442: check for MoveAll at the end (only at the upper most level)
		If (pMoveAll && (pLevel=0)) {
			// JMD1213 Move entire slicer to axis 3
			While (..axes.Count()<2) {
				Set tAxis = ##class(%DeepSee.Query.axis).%New()
				// inject %SEARCH dimension along missing axis!
				Set tMember = ##class(%DeepSee.Query.memberSpec).%New()
				Set tMember.spec = "[%SEARCH]"
				Do tAxis.children.Insert(tMember)
				Do ..axes.Insert(tAxis)
			}
			
			// DTB141 - see if there is already something on axis 3
			Set tAxis = ..axes.GetAt(3)
			If ($IsObject(tAxis)) {
				Set tHasThirdAxis = 1
			} 
			Else {
				Set tHasThirdAxis = 0
				Set tAxis = ##class(%DeepSee.Query.axis).%New()
				Set tMember = ##class(%DeepSee.Query.memberSpec).%New()
				Set tMember.spec = "[%SEARCH]"
				Do tAxis.children.Insert(tMember)
				Do ..axes.Insert(tAxis)
			}

			Set tTerm = pNode.children.GetAt(1)
			If (tTerm.%IsA("%DeepSee.Query.calculatedMember")||tTerm.%IsA("%DeepSee.Query.setFunction")) {
				// ignore (do not wrap)
			}
			ElseIf (tTerm.%IsA("%DeepSee.Query.set")) {
				// wrap set in aggregate
				Set tAgg = ##class(%DeepSee.Query.setFunction).%New("%OR")
				Do tAgg.children.Insert(tTerm)
				Set tTerm = tAgg
			}
			
			// DTB141 - crossjoin this axis with a previous third axis term if it existed
			If $IsObject(tTerm) {
				If tHasThirdAxis {
					// There should only be one child of any axis
					Set tTerm2 = tAxis.children.GetAt(1)
					
					// Replace the original contents with a crossjoin
					Do tAxis.children.Clear()
					Set tCJ = ##class(%DeepSee.Query.setFunction).%New("NONEMPTYCROSSJOIN")
					Do tCJ.children.Insert(tTerm)
					Do tCJ.children.Insert(tTerm2)
					Do tAxis.children.Insert(tCJ)
					
					Set tAxis.nonEmpty = 1		// Always use NON EMPTY in the third axis
				}
				Else {
					Do tAxis.children.Clear()
					Do tAxis.children.Insert(tTerm)
				}
			}
			Do pNode.children.Clear()
			
			Set ..measureAxis = -1 				// DTB125 - reset the measureAxis if the slicer is moved
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Combine all filters into the slicer.
Method %CombineFiltersWithSlicer() As %Status [ Internal ]
{
	Set tSC = $$$OK

	// make a list of all terms
	// combine non-sets into a tuple
	// crossjoin remaining sets

	If ($IsObject(..slicer) && ( $G(%baseCubeQuery)||(..slicer.context'="filterAxis") )) {
		For n = 1:1:..slicer.children.Count() {
			Set tTerm = ..slicer.children.GetAt(n)
			Set tTerms($I(tTerms)) = tTerm
		}
	}
	For f = 1:1:..filters.Count() {
		Set tFilter = ..filters.GetAt(f)
		For n = 1:1:tFilter.children.Count() {
			Set tTerm = tFilter.children.GetAt(n)
			// JMD852: if filter is a set of one item, simplify
			While (tTerm.%IsA("%DeepSee.Query.set") && (tTerm.children.Count()=1)) {
				// JMD1442: simplify recursively
				Set tTerm = tTerm.children.GetAt(1)
			}
			Set tTerms($I(tTerms)) = tTerm
		}
	}

	// organize terms
	Set t = $O(tTerms(""))
	While (t'="") {
		Set tTerm = tTerms(t)
		If (tTerm.%IsA("%DeepSee.Query.tuple")) {
			For k = 1:1:tTerm.children.Count() {
				Set tMembers($I(tMembers)) = tTerm.children.GetAt(k)
			}
		}
		ElseIf (tTerm.%IsA("%DeepSee.Query.set")||tTerm.%IsA("%DeepSee.Query.range")||tTerm.%IsA("%DeepSee.Query.expression")) {
			// JMD1442 treat expression as set
			Set tSets($I(tSets)) = tTerm
		}
		ElseIf (tTerm.%IsA("%DeepSee.Query.setFunction")) {
			If ($$$UPPER(tTerm.function)="%OR") {
				// Set tMembers($I(tMembers)) = tTerm
				Set tSets($I(tSets)) = tTerm
			}
			Else {
				Set tSets($I(tSets)) = tTerm
			}
		}
		Else {
			Set tMembers($I(tMembers)) = tTerm
		}
		Set t = $O(tTerms(t))
	}

	// combine filters
	Set ..slicer = ""
	Set tTuple = ""

	If $D(tMembers) {
		Set tTuple = ##class(tuple).%New()
		Set m = $O(tMembers(""))
		While (m'="") {
			// skip duplicate tuple members
			Set tText = tMembers(m).%ToString()
			
			// DTB059 protect against long subscripts
			Set tTextHash = $S($L(tText)<100:tText,1:$ZCRC(tText,7))		
			While ($D(tMemberText(tTextHash)))&&($G(tMemberText(tTextHash))'=tText) {
				Set tText = tText_" "
				Set tTextHash = $S($L(tText)<100:tText,1:$ZCRC(tText,7))
			}

			If (tTextHash'="")&&'$D(tMemberText(tTextHash)) {
				Set tMemberText(tTextHash) = tText
				Do tTuple.children.Insert(tMembers(m))
			}
			Set m = $O(tMembers(m))
		}
	}

	If $D(tSets) {
		// add new tuple to list of sets
		Set:$IsObject(tTuple) tSets($I(tSets)) = tTuple

		Set tLastSet = ""
		Set s = $O(tSets(""))
		While (s'="") {
			Set tText = tSets(s).%ToString()
			
			// DTB059 protect against long subscripts
			Set tTextHash = $S($L(tText)<100:tText,1:$ZCRC(tText,7))		 
			While $D(tSetText(tTextHash))&&($G(tSetText(tTextHash))'=tText) {
				Set tText = tText_" "
				Set tTextHash = $S($L(tText)<100:tText,1:$ZCRC(tText,7))
			}
			
			// JMD1442 skip duplicate set members
			If ((tTextHash'="")&&'$D(tSetText(tTextHash))) {
				Set tSetText(tTextHash) = tText
				If $IsObject(tLastSet) {
					Set tFunc = ##class(setFunction).%New("NONEMPTYCROSSJOIN")
					Do tFunc.children.Insert(tLastSet)
					Do tFunc.children.Insert(tSets(s))
					Set tLastSet = tFunc
				}
				Else {
					Set tLastSet = tSets(s)
				}
			}
			Set s = $O(tSets(s))
		}
		Set ..slicer = ##class(axis).%New()
		Do ..slicer.children.Insert(tLastSet)
	}
	ElseIf $IsObject(tTuple) {
		Set ..slicer = ##class(axis).%New()
		Do ..slicer.children.Insert(tTuple)
	}

	Set ..slicer.%originalSpec = ..slicer.%ToString()		// DP-428221
	Set ..slicer.context = "filter"		// DP-424293

	Quit tSC
}

/// Given a cube, subquery key, and timestamp, determine if there
/// is an up-to-date result cache for the query.
/// Return true (1) if this is the case.<br/>
/// As a side effect, remove any out-of-date portions of the result cache for this query.
ClassMethod %TestSubQueryCache(pCubeName As %String, pQueryKey As %String, pTimestamp As %String, Output pCurrent As %Boolean, pQueryCube As %String) As %Status
{
	Set tSC = $$$OK
	Set pCurrent = 0
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		If (pQueryCube'="") {
			Set tQueryCube = $$$DeepSeeIndex(pQueryCube)
		}
		Else {
			Set tQueryCube = tCubeIndex
		}

		Set tSC = ..%QueryTrace("%TestSubQueryCache",pCubeName)
		If $$$ISERR(tSC) Quit

		#; is there a result cache entry for the query?
		#; it should have status=100
		Set tStatus = $G($$$DeepSeeResultsGLVN(tQueryCube,pQueryKey,"status"))
		If (tStatus >= 100) {
			#; there is an entry in the cache

			#; if there was an error, try again
			If ($G($$$DeepSeeResultsGLVN(tQueryCube,pQueryKey,"error"))'="") {
				Quit
			}

			#; check timestamp against cube
			Set tResultTimestamp = +$G($$$DeepSeeResultsGLVN(tQueryCube))
			If (tResultTimestamp = pTimestamp) {
				#; no changes to cube, so subquery is ok
				Set pCurrent = 1

				#; test date if cube has age dimensions
				Set tHasAge = +$G($$$DeepSeeMetaGLVN("cubes",tQueryCube,"hasAge"))
				If (tHasAge) {
					Set tToday = +$H
					Set tResultDay = +$G($$$DeepSeeResultsGLVN(tQueryCube,pQueryKey,"lastuse"))
					If (tToday'=tResultDay) {
						Set pCurrent = 0
						Set tSC = ..%QueryTrace("%TestSubQueryCache",pCubeName,"SubQuery run on prior day: "_tQueryCube)
						If $$$ISERR(tSC) Quit
					}
				}

				If (pCurrent) {
					// JMD885 Test next level of subqueries on related cubes, if needed
					Set tAxis = $O($$$DeepSeeResultsGLVN(tQueryCube,pQueryKey,"axis",""),1,tAxisKey)
					While (tAxis '= "") {
						Set tSubKey = $O($$$DeepSeeAxisGLVN(tQueryCube,tAxisKey,"subquery",""),1,ts)
						While ((pCurrent) && (tSubKey '= "")) {
							Set tQueryCube2 = $G($$$DeepSeeAxisGLVN(tQueryCube,tAxisKey,"subquery",tSubKey,"cube"))
							If (tQueryCube2'="") {
								Set tSC = ..%TestSubQueryCache(tQueryCube, tSubKey,ts,.pCurrent,tQueryCube2)
								If $$$ISERR(tSC) Quit
								If ('pCurrent) {
									Set tSC = ..%QueryTrace("%InitializeResultsCache",tQueryCube,"RELATED SUBQUERY OUT-OF-DATE " _ tQueryCube2)
									If $$$ISERR(tSC) Quit
								}
							}
							Set tSubKey = $O($$$DeepSeeAxisGLVN(tQueryCube,tAxisKey,"subquery",tSubKey),1,ts)
						}
						If $$$ISERR(tSC) Quit
						Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"axis",tAxis),1,tAxisKey)
					}
					If $$$ISERR(tSC) Quit
				}

				If (pCurrent) {
					Set tSC = ..%QueryTrace("%TestSubQueryCache",pCubeName,"SubQuery up-to-date: "_pQueryKey)
					If $$$ISERR(tSC) Quit
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set pCurrent = 0
	}

	Quit tSC
}

ClassMethod %CheckSubqueryResultsCache(pMainCube, pCubeName, pQueryKey, ByRef pUpToDate = 1) As %Status
{
	// Method added by WAL296
	Set tSC = $$$OK
	Try {	
		Set tSubqueryCube = $O($$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"subquery",""))
		While tSubqueryCube'="" {
			Set tSubqueryCubeKey = $O($$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"subquery",tSubqueryCube,""))
			While tSubqueryCubeKey'="" {
				Set tUpToDate = 1
				Set tUpToDateR = 1
				Set tSC = ..%CheckSubqueryResultsCache(pMainCube,tSubqueryCube,tSubqueryCubeKey,.tUpToDateR)
				If $$$ISERR(tSC) Quit
				Set tSC = ..%CheckResultsCache(tSubqueryCube,tSubqueryCubeKey,.tUpToDate)
				Set:('tUpToDateR&&($$$UPPER(pCubeName)=$$$UPPER(pMainCube))) $$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"staleSubquery",tSubqueryCubeKey) = "" 
				Set:('tUpToDate&&($$$UPPER(pCubeName)=$$$UPPER(pMainCube))) $$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"staleSubquery",tSubqueryCubeKey) = "" 
				Set:'tUpToDate pUpToDate=0
				Return:(('pUpToDate)&&(pCubeName'=pMainCube)) tSC
				If $$$ISERR(tSC) Quit
				Set tSubqueryCubeKey = $O($$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"subquery",tSubqueryCube,tSubqueryCubeKey))
			}
			Set tSubqueryCube = $O($$$DeepSeeResultsGLVN($$$UPPER(pCubeName),pQueryKey,"subquery",tSubqueryCube))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Do $system.Status.DisplayError(tSC)
	Quit tSC
}

ClassMethod %CheckResultsCache(pCubeName, pQueryKey, ByRef pUpToDate = 1) As %Status
{
	// Method added by WAL266
	Set tSC = $$$OK
	Try {	
		Set pUpToDate = 1
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tCubeTimestamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tCubeIndex)		// DTB838 - Fetch the common timestamp
		Set tStatus = $G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"status"))
		If ((tStatus >= 100)) {
			Set tUpToDate=1
			// if there was an error last time, run query again
			Set tHadErrorLastTime = ($G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"error"))'="")
			If (tHadErrorLastTime) {
				Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"CACHED QUERY HAD ERROR ON LAST EXEC")
				If $$$ISERR(tSC) Quit

				// make sure axes are recomputed
				Set tRecomputeAxes = 1
				
				// kill prior results
				// WAL303 -- remove kill
				//Kill $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey)
			}
			
			If ('tHadErrorLastTime) {
				#; this query is in the cache
				#; see if it is still valid
				Set tUpToDate = 1
				Set tMustRun = +$G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"mustCompute")) // run even if recompute is off

				#; test if there are any results in this cache entry
				Set tHasData = ''$D($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"data"))
				If ('tHasData) {
					Set tUpToDate = 0
					Set tMustRun = 1
					Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"RESULT CACHE HAS NO DATA")
					If $$$ISERR(tSC) Quit
				}
				ElseIf (tMustRun) {
					Set tUpToDate = 0
					// + WAL085 -- JMD1383 created a new way to state that a query must be rerun (the ..%receomputeAxes property)
					//             but neglected to set it in this case. I set it here, like the "TIMESTAMPS DO NOT MATCH" case below.
					//             "mustCompute" in the cache means that this is a non-cacheable KPI, 
					//             or %MDX containing query. Non-cacheable KPI's need to be run every time, and %MDX statements create
					//             subqueries that deal with caching on their own.
					Set tRecomputeAxes = 1
					// - WAL085
					Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"QUERY IS MARKED AS MUST-COMPUTE (%CheckResultsCache): " _ pQueryKey)
					If $$$ISERR(tSC) Quit
				}
				Else {
					Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"QUERY IS IN CACHE: " _ pQueryKey)
					If $$$ISERR(tSC) Quit

					#; check result timestamp against cube data timestamp
					Set tResultTimestamp = +$G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"timestamp"))
					
					#; check if query was run *today*
					#; this only needs to be done if there are "age" measures in play
					#; currently we check if the cube has any age dimensions or measures
					#; a more granular test would test if the query has any age references
					Set tHasAge = +$G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"hasAge"))
					If (tHasAge) {
						Set tToday = +$H
						Set tResultDay = +$G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"lastuse"))
					}
					Else {
						Set tToday = 0
						Set tResultDay = 0
					}
					// WAL NOTES: ..recompute is set by the containing result set and basically means
					//            "look at the data". If recompute is 0, that is the same as assuming the 
					//            cache is correct; this is only used in special situations
					If ((tResultTimestamp '= tCubeTimestamp) && 1) {						
						Set tUpToDate = 0
						// JMD1383
						Set tRecomputeAxes = 1
						Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"TIMESTAMPS DO NOT MATCH")
						If $$$ISERR(tSC) Quit
					}
					ElseIf (tResultDay '= tToday) {
						Set tUpToDate = 0
						Set tMustRun = 1
						Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"RESULTS RUN ON DIFFERENT DAY")
						If $$$ISERR(tSC) Quit
					}
					Else {
						#; Test existence of every axis this query refers to
						#; this guards against manual deletion of the axis cache
						#; a more thorough test is done further on
						Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"axis",""),1,tAxisKey)

						While (tAxis '= "") {
							If ('$D($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey))) {
								Set tUpToDate = 0
								Set tMustRun = 1
								Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"AXIS MISSING FROM CACHE: "_tAxisKey)
								If $$$ISERR(tSC) Quit
								Quit
							}
							ElseIf (+$G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"hasref"))) {
								// check for axes that have references to source data
								// mark as out-of-date, check later
								Set tUpToDate = 0
								Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"AXIS CONTAINS REFERENCE DATA: "_tAxisKey)
								If $$$ISERR(tSC) Quit
								Quit
							}
							Else {
								// JMD1329: check for "recompute" flag
								If +$G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"recompute")) {
									Set tUpToDate = 0
								}
							}
							Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"axis",tAxis),1,tAxisKey)
						}
					}
				}
	
				// JMD945 Test for KPI references, if needed
				// JMD1496 always test this
				// If ('tMustRun && (tUpToDate || ('..recompute))) {
				If (1) {
					Set tKPI = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"kpi",""),1,tOldKPITime)
					While (tKPI'="") {
						Try {
							Set tCurrKPITime = $Classmethod(tKPI,"%GetKPIClassTimeStamp")
						}
						Catch(ex) {
							Set tCurrKPITime = ""
						}
						If ((tCurrKPITime'=tOldKPITime)||(tCurrKPITime="")) {
							Set tUpToDate = 0
							Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"KPI MODIFIED OR FORCECOMPUTE: " _ tKPI)
							If $$$ISERR(tSC) Quit

							// kill old results
							// WAL303 -- remove kill
							//Kill $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey)
							Quit
						}
						Set tKPI = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"kpi",tKPI),1,tOldKPITime)
					}
				}

				// JMD887 Test termlists, if needed
				// JMD1496 always test this
				//If ('tMustRun && (tUpToDate || ('##class(%DeepSee.Query.query).recompute))) {
				If (1) {
					Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"axis",""),1,tAxisKey)
					While (tAxis '= "") {
						Set tTermList = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"termlist",""),1,ts)
						While ((tUpToDate) && (tTermList'="")) {
							If ($G(^DeepSee.TermList($$$UPPER(tTermList),"modDate"))'=ts) {
								Set tUpToDate = 0
								Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"TERMLIST OUT-OF-DATE: " _ tTermList)
								If $$$ISERR(tSC) Quit

								// kill old results
								// WAL303 -- remove kill
								//Kill $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey)
							}
							Set tTermList = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"termlist",tTermList),1,ts)
						}
						Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"axis",tAxis),1,tAxisKey)
					}
				}

				// JMD885 Test subqueries on related cubes, if needed
				If ('tMustRun && (tUpToDate || ('1))) {
					Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"axis",""),1,tAxisKey)
					While (tAxis '= "") {
						Set tSubKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"subquery",""),1,ts)
						While ((tUpToDate) && (tSubKey '= "")) {
							Set tQueryCube = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"subquery",tSubKey,"cube"))
							If (tQueryCube'="") {
								Set tSC = ##class(%DeepSee.Query.query).%TestSubQueryCache(tCubeIndex, tSubKey,ts,.tUpToDate,tQueryCube)
								If $$$ISERR(tSC) Quit
								If ('tUpToDate) {
									Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"RELATED SUBQUERY OUT-OF-DATE" _ tQueryCube)
									If $$$ISERR(tSC) Quit
								}
							}
							Set tSubKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"subquery",tSubKey),1,ts)
						}
						If $$$ISERR(tSC) Quit
						Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"axis",tAxis),1,tAxisKey)
					}
					If $$$ISERR(tSC) Quit
				}

				If ('tMustRun && (tUpToDate || ('1))) {
					//Set ##class(%DeepSee.Query.query).%Statistics("ResultsCache") = 1
					Set pToken = pQueryKey
					Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"lastuse") = $H

					If ('1) {
						Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"RECOMPUTE IS OFF")
					}
					Else {
						Set tSC = ##class(%DeepSee.Query.query).%QueryTrace("%InitializeResultsCache",tCubeIndex,"QUERY IS UP-TO-DATE")
					}
					If $$$ISERR(tSC) Quit
					Quit
				}
			}
			Set pUpToDate = tUpToDate
		}	
		Else {
			Set pUpToDate = 0	
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

/// Prepare the results cache for this query so that it
/// can contain the axis and cell values.<br/>
/// If the query is already in the results cache, then this
/// method may decide to re-use the previous results.
Method %InitializeResultsCache() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tLock = 0
	Try {
		If (..cube="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name is missing.")
			Quit
		}

		Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube)
		If $$$ISERR(tSC) Quit

		Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..cube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tCubeIndex = $$$DeepSeeIndex(..cube)

		#; contextual info
		New %query,%cube,%cubeIndex,%dsUseOrigValue
		Set %query = $this
		Set %cube = $$$UPPER(..cube)
		Set %cubeIndex = tCubeIndex
		Set %dsUseOrigValue = 1		// DTB967 - Report the original prepared value in %ToString

		// This just has to change in the upwards direction 
		#; find version of cube contents
		Set tCubeTimestamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tCubeIndex)		// DTB838 - Fetch the common timestamp
		
		// DTB739 - Use method to generate key, still generate text for use later
		Set tText = ..%ToString(.tSC)
		Set tQueryKey = ..%CreateResultKey(.tSC)		// DTB820 - The %CreateResultKey method will handle verification and setting of the object's %QueryKey property
		If $$$ISERR(tSC) Quit

		// JMD1381 prevent initialize and consolidate at same time
		Lock +^DeepSee.Query(tCubeIndex,..%QueryKey):1
		If ('$Test) {
			// for now this is an error
			Set tSC = $$$ERROR($$$GeneralError,"Unable to obtain query lock")
			Quit
		}
		Set tLock = 1
		Set tStatus = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status"))
		If ((tStatus >= 100) && (tText = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"query",1)))) {

			// + WAL296 -- recursively check if all subqueries are properly cached
			//             and log any stale ones
			//             This should work because we will run this logic at the beginning of any query,
			//             So if the subqueries are up to date they won't get stored here
			// Recursively check the results cache for all subqueries and their subqueries
			// First start with a clean slate
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"staleSubquery")
			Set tSubqueriesUpToDate = 1
			Set tSC = ..%CheckSubqueryResultsCache(tCubeIndex,tCubeIndex,..%QueryKey,.tSubqueriesUpToDate)
			If $$$ISERR(tSC) Quit
			If ('tSubqueriesUpToDate) {
				// Don't invalidate *this* cache
				// Just log so that we don't use bad cell cache later on in query execution
				Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"LOGGING STALE SUBQUERIES ")
				If $$$ISERR(tSC) Quit
			}	
			// - WAL296
						
			// if there was an error last time, run query again
			Set tHadErrorLastTime = ($G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"error"))'="")
			If (tHadErrorLastTime) {
				Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"CACHED QUERY HAD ERROR ON LAST EXEC")
				If $$$ISERR(tSC) Quit

				// make sure axes are recomputed
				Set ..%recomputeAxes = 1

				// DTB863 - Clear prior results while preserving query request information
				Set tSC = ..%ClearQueryResults(tCubeIndex,..%QueryKey)
				If $$$ISERR(tSC) Quit
			}
			If (..useCache && 'tHadErrorLastTime) {
				#; this query is in the cache
				#; see if it is still valid
				Set tUpToDate = 1
				Set tMustRun = +$G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"mustCompute")) // run even if recompute is off
				
				#; test if there are any results in this cache entry
				Set tHasData = ''$D($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"data"))
				If ('tHasData) {
					Set tUpToDate = 0
					Set tMustRun = 1
					Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"RESULT CACHE HAS NO DATA")
					If $$$ISERR(tSC) Quit
				}
				ElseIf (tMustRun) {
					Set tUpToDate = 0
					// + WAL085 -- JMD1383 created a new way to state that a query must be rerun (the ..%recomputeAxes property)
					//             but neglected to set it in this case. I set it here, like the "TIMESTAMPS DO NOT MATCH" case below.
					//             "mustCompute" in the cache means that this is a non-cacheable KPI, 
					//             or %MDX containing query. Non-cacheable KPI's need to be run every time, and %MDX statements create
					//             subqueries that deal with caching on their own.
					Set ..%recomputeAxes = 1
					// - WAL085
					Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"QUERY IS MARKED AS MUST-COMPUTE (%InitializeResultsCache): " _ ..%QueryKey)
					If $$$ISERR(tSC) Quit
				}
				Else {
					Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"QUERY IS IN CACHE: " _ ..%QueryKey)
					If $$$ISERR(tSC) Quit

					#; check result timestamp against cube data timestamp
					Set tResultTimestamp = +$G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"timestamp"))
				
					#; check if query was run *today*
					#; this only needs to be done if there are "age" measures in play
					#; currently we check if the cube has any age dimensions or measures
					#; a more granular test would test if the query has any age references
					Set tHasAge = +$G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"hasAge"))
					If (tHasAge) {
						Set tToday = +$H
						Set tResultDay = +$G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"lastuse"))
					}
					Else {
						Set tToday = 0
						Set tResultDay = 0
					}
					// WAL NOTES: ..recompute is set by the containing result set and basically means
					//            "look at the data". If recompute is 0, that is the same as assuming the 
					//            cache is correct; this is only used in special situations
					If ((tResultTimestamp '= tCubeTimestamp) && ..recompute) {
						Set tUpToDate = 0
						// JMD1383
						Set ..%recomputeAxes = 1
						Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"TIMESTAMPS DO NOT MATCH")
						If $$$ISERR(tSC) Quit
					}
					ElseIf (tResultDay '= tToday) {
						Set tUpToDate = 0
						Set tMustRun = 1
						Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"RESULTS RUN ON DIFFERENT DAY")
						If $$$ISERR(tSC) Quit
					}
					Else {
						#; Test existence of every axis this query refers to
						#; this guards against manual deletion of the axis cache
						#; a more thorough test is done further on
						Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axis",""),1,tAxisKey)

						While (tAxis '= "") {
							If ('$D($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey))) {
								Set tUpToDate = 0
								Set tMustRun = 1
								Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"AXIS MISSING FROM CACHE: "_tAxisKey)
								If $$$ISERR(tSC) Quit
								Quit
							}
							ElseIf (+$G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"hasref"))) {
								// check for axes that have references to source data
								// mark as out-of-date, check later
								Set tUpToDate = 0
								Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"AXIS CONTAINS REFERENCE DATA: "_tAxisKey)
								If $$$ISERR(tSC) Quit
								Quit
							}
							Else {
								// JMD1329: check for "recompute" flag
								If +$G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"recompute")) {
									Set tUpToDate = 0
								}
							}
							Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axis",tAxis),1,tAxisKey)
						}
					}
				}
				
				// JMD945 Test for KPI references, if needed
				// JMD1496 always test this
				// If ('tMustRun && (tUpToDate || ('..recompute))) {
				If (1) {
					Set tKPI = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"kpi",""),1,tOldKPITime)
					While (tKPI'="") {
						Try {
							Set tCurrKPITime = $Classmethod(tKPI,"%GetKPIClassTimeStamp")
						}
						Catch(ex) {
							Set tCurrKPITime = ""
						}
						If ((tCurrKPITime'=tOldKPITime) || (tCurrKPITime="")) || (tMustRun && '$D($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"pending"))) {		// DTB863 - Kill if the query needs to be run and there are no pending results
							Set tUpToDate = 0
							Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"KPI MODIFIED OR FORCECOMPUTE: " _ tKPI)
							If $$$ISERR(tSC) Quit

							// DTB863 - Clear prior results while preserving query request information
							Set tSC = ..%ClearQueryResults(tCubeIndex,..%QueryKey)
							Quit
						}
						Set tKPI = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"kpi",tKPI),1,tOldKPITime)
					}
				}

				// JMD887 Test termlists, if needed
				// JMD1496 always test this
				//If ('tMustRun && (tUpToDate || ('..recompute))) {
				If (1) {
					Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axis",""),1,tAxisKey)
					While (tAxis '= "") {
						Set tTermList = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"termlist",""),1,ts)
						While ((tUpToDate) && (tTermList'="")) {
							If ($G(^DeepSee.TermList($$$UPPER(tTermList),"modDate"))'=ts) {
								Set tUpToDate = 0
								Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"TERMLIST OUT-OF-DATE: " _ tTermList)
								If $$$ISERR(tSC) Quit

								// DTB863 - Clear prior results while preserving query request information
								Set tSC = ..%ClearQueryResults(tCubeIndex,..%QueryKey)
								If $$$ISERR(tSC) $$$ThrowStatus(tSC)
							}
							Set tTermList = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"termlist",tTermList),1,ts)
						}
						Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axis",tAxis),1,tAxisKey)
					}
				}
				
				// JMD885 Test subqueries on related cubes, if needed
				If ('tMustRun && (tUpToDate || ('..recompute))) {
					Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axis",""),1,tAxisKey)
					While (tAxis '= "") {
						Set tSubKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"subquery",""),1,ts)
						While ((tUpToDate) && (tSubKey '= "")) {
							Set tQueryCube = $G($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"subquery",tSubKey,"cube"))
							If (tQueryCube'="") {
								Set tSC = ..%TestSubQueryCache(tCubeIndex, tSubKey,ts,.tUpToDate,tQueryCube)
								If $$$ISERR(tSC) Quit
								If ('tUpToDate) {
									Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"RELATED SUBQUERY OUT-OF-DATE (2) " _ tQueryCube)
									If $$$ISERR(tSC) Quit
								}
							}
							Set tSubKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"subquery",tSubKey),1,ts)
						}
						If $$$ISERR(tSC) Quit
						Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axis",tAxis),1,tAxisKey)
					}
					If $$$ISERR(tSC) Quit
				}

				If ('tMustRun && (tUpToDate || ('..recompute))) {
					Set ..%Statistics("ResultsCache") = 1
					Set pToken = ..%QueryKey
					Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"lastuse") = $H

					If ('..recompute) {
						Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"RECOMPUTE IS OFF")
					}
					Else {
						Set tSC = ..%QueryTrace("%InitializeResultsCache",..cube,"QUERY IS UP-TO-DATE")
					}
					If $$$ISERR(tSC) Quit
					Quit
				}
				
				If 'tUpToDate {
					// DTB967 - If the cache is not up to date at this point, clear previous results so they cannot interfere
					// with upcoming worksheet-style processing, and cannot be accidentally reused.
					Set tSC = ..%ClearQueryResults(tCubeIndex,..%QueryKey)
					If $$$ISERR(tSC) Quit
				}
			}
		}

		// + WAL266 (3) -- %DeepSee.Component.pivotTable requires additional reporting about whether
		//             this query was out of date at some point
		//             Use %dsUpToDate
		Set:($G(tUpToDate)'="") %dsUpToDate = tUpToDate
		// - WAL266 (3)

		Set ..%Statistics("ResultsCache") = 0
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 0

		// JMD1046: remove old error (prevent invalid KPI name for valid KPI name on first call)
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"error")

		#; pre-process the query
		#; this will resolve member references,
		#; discover sub-query dependencies
		#; and test for the validity of the query
		Set tSC = ..%PreProcessQuery()
		If $$$ISERR(tSC) {
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 100
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"reason") = 1
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"error") = tSC
			// JMD1381 clear the processing flag
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"zprocessing")
			Quit
		}

		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 10

		#; return key
		Set pToken = ..%QueryKey

		#; set meta-data into cache
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"cube") = ..cube
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"query",1) = tText		// DTB518 - This is now the unresolved text
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"lastuse") = $H
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"timestamp") = tCubeTimestamp
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"queryType") = ..queryType
		Set:..showPlan $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"showPlan") = ..showPlan

		// JMD1215: set flag
		If (..%mustCompute) {
			// Set must-compute flag for cached results
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"mustCompute") = 1
		}

		// diagnostic aid!
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey) = tText

		// JMD1381 set the processing flag
		//Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"zprocessing") = 1		// DTB843 - Managed by locks
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	// JMD1381
	If (tLock && (..%QueryKey'="")) {
		Lock -^DeepSee.Query(tCubeIndex,..%QueryKey)
	}
	
	Quit tSC
}

/// Called after the axes are ready, this method does the final check to
/// determine if the query results can be re-used and if not, fills in
/// the starting values for the result cache.
Method %PrepareResultsCache() As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		Set tStatus = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status"))

		Set tSC = ..%QueryTrace("%PrepareResultsCache",..cube,"Status: "_tStatus)
		If $$$ISERR(tSC) Quit

		If (tStatus < 100) {
			// If tPartialInvalidate is true,
			// we will re-use some of the previously calculated results
			Set tPartialInvalidate = 1
			If ('tPartialInvalidate) {
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"bucketList")
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"activeChunk")
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"data")
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"leaf")
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"nonempty")
			}
			Else {
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"bucketList")
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"activeChunk")
				// get list of buckets for this cube
				Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(..cube,.tBucketList,.tActiveChunk)
				If $$$ISERR(tSC) Quit

				Merge $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"bucketList") = tBucketList
				Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"activeChunk") = tActiveChunk

				// see if any prior results are still valid:
				// if they are in the bucket list AND in the results global, then
				// they are still good, otherwise kill them
				Set tBkt = $O(tBucketList(""))
				While (tBkt '= "") {
					Set tValidSlot(tBucketList(tBkt)) = ""
					Set tBkt = $O(tBucketList(tBkt))
				}

				Set tSlot = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"data",""))
				While (tSlot '= "") {
					If ((tSlot'=0)&&'$D(tValidSlot(tSlot))) {
						// do not kill 0 node here
						Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"data",tSlot)
					}
					Set tSlot = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"data",tSlot))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the set of named parameters values defined by this query.
Method %GetParameterInfo(Output pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pParms
		Merge pParms = ..%NamedParameters
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute the pre-processing logic for this node.
Method %PreProcessQuery() As %Status
{
	Set tSC = $$$OK
	Try {
		#; contextual info
		New %query,%cube,%axisObject,%dsDepends
		Set %query = $this
		Set %cube = $$$UPPER(..cube)
		Set %cubeIndex = $$$DeepSeeIndex(..cube)

		Set tSC = ..%QueryTrace("%PreProcessQuery",..cube)
		If $$$ISERR(tSC) Quit

		// axes
		Set tCount = ..axes.Count()
		For a=1:1:tCount {
			Kill %dsDepends
			Set %dsDepends("x") = a

			Set tAxis = ..axes.GetAt(a)

			Set %axisObject = tAxis
			Set tSC = tAxis.%PreProcess()
			If $$$ISERR(tSC) {
				Do ..%QueryTrace("%PreProcessQuery",..cube,"Failure in axis preprocess: "_a)
				Quit
			}

			// pick up member dependencies
			Kill %dsDepends("x")
			Merge tAxis.%dependencies = %dsDepends
		}
		If $$$ISERR(tSC) Quit
		Kill %axisObject

		// process filter spec, if present
		// n.b. most likely already removed by %CombineFiltersWithSlicer
		If ($IsObject(..filterAxis)) {
			Set %axisObject = ..filterAxis
			Set tSC = ..filterAxis.%PreProcess(1)
			If $$$ISERR(tSC) Quit
		}
		// slicer
		If ($IsObject(..slicer)) {
			Kill %dsDepends
			Set %dsDepends("x") = 0
			Set %axisObject = ..slicer
			Set tSC = ..slicer.%PreProcess(1)
			If $$$ISERR(tSC) Quit

			// pick up member dependencies
			Kill %dsDepends("x")
			Merge ..slicer.%dependencies = %dsDepends
		}
		Kill %axisObject
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute this query using background agents.<br/>
/// If <var>pWait</var> is true (1) then do not return until the background
/// agents are finished.<br/>
/// If <var>pWait</var> is false, then <var>pTaskGroupId</var> will return the task group id
/// used to execute the query.
Method %ExecuteAsynch(pWait As %Boolean = 0, Output pTaskGroupId As %String, pAxesOnly As %Boolean = 0, pAxisQuery As %String = "", ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		Set pTaskGroupId = ""
		Set tSC = ..%QueryTrace("%ExecuteAsynch",..cube)
		If $$$ISERR(tSC) Quit

		Set ..useAgents = 1
		
		Set tSC = ##class(%DeepSee.Utils).%ArrayToList(.pParms,.tParmsList)		// DTB882 - Convert parms to list format for queueing into a task
		If $$$ISERR(tSC) Quit
		
		// DTB943 - Convert lock keys to list format for queueing into a task
		// A query.%LockKeys array includes all locks obtained directly by the managing ResultSet
		// and any %AncestorLockKeys set into that Resultset
		Merge tLockKeys = ..%LockKeys
		Set tSC = ##class(%DeepSee.Utils).%ArrayToList(.tLockKeys,.tLockKeysList)
		If $$$ISERR(tSC) Quit
		
		//APV013 - Moving this loop out of the If branch below to make tVars available to the else block as well				
		// PFS079 - Get variable context and pass to task
			Set tVar = $O(..%variables(""))
			While tVar '= "" {
				Set $List(tVars,$I(tVarsCount)) = $LB(tVar,..%variables(tVar))
				Set tVar = $O(..%variables(tVar))
			}
		
		
		If (pAxesOnly) {
			// JMD only execute axes; do it in the background
			// DTB704 - This is now handled by the %DeepSee.WorkMgr
			Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.pTaskGroupId,pWait,"AXES")
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Quit
			}
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"axesTaskGroup") = pTaskGroupId		// DTB719 - Always log the axesTaskGroup to the global

			Kill ^IRIS.Temp.DeepSeeUpdate($namespace,pTaskGroupId)

			// JMD1395 pick up current filterSpec
			// we can't reliably compute this in the background as we may have
			// a different user name
			Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..cube)
			Set tFilterSpec = $zobjclassmethod(tCubeClass,"%GetFilterSpec")
			
			// pass original query text to background
			// DTB704 - This is now handled by the %DeepSee.WorkMgr
			// DTB943 - Pass parameters and lock keys
			Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(pTaskGroupId,"EXECAXES",..cube,..%QueryKey,pAxisQuery,tFilterSpec,.tVars,$LB(tParmsList,tLockKeysList))		// DTB876 - Restore the use of the pAxesQuery as passed in
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB882
		}
		Else {
			// DTB719 - Create the query task group first, before %ExecuteAxes
			Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.pTaskGroupId,pWait,"EXEC")		// DTB - WorkMgr in the merge
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Quit
			}
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"execTaskGroup") = pTaskGroupId		// DTB719 - Always log the execTaskGroup to the global 
			
			Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(pTaskGroupId,"EXECAXESANDQUERY",..cube,..%QueryKey,,,.tVars,$LB(tParmsList,tLockKeysList)) //APV013 - passing in tVars
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB882
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		// if error, mark query as complete
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 100
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"reason") = 3
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"error") = tSC
		// JMD1381 clear the processing flag
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"zprocessing")
	}

	Quit tSC
}

/// Apply the set of named parameters values to this query and
/// then make sure the result cache is ready to accept values.
Method %ExecuteParameters(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		
		Set tSC = ..%QueryTrace("%ExecuteParameters",..cube)
		If $$$ISERR(tSC) Quit

		Kill ..%ParameterValues
		Set p = $O(pParms(""))
		While (p '= "") {
			Set ..%ParameterValues($$$UPPER(p)) = $G(pParms(p))
			Set p = $O(pParms(p))
		}
		
		// + DTB847 - Resolve the memberSpec with parameters
		#; contextual info
		New %query,%cube
		Set %query = $this
		Set %cube = $$$UPPER(..cube)
		Set tText = ..%ToString(.tSC)		// %ToString resolves memberSpec according to parameters
		Kill %query,%cube
		If $$$ISERR(tSC) {
			Set tSC = $$$OK
			Set tText = ""	
			Quit
		}
		// - DTB847
		
		Set tMDXRequest = $G($$$DeepSeeResultsGLVN($$$DeepSeeIndex(..cube),..%QueryKey,"query",0)) //APV023 - Wrapping ..cube with $$$DeepSeeIndex
		Set ..%QueryKey = ..%CreateResultKey(.tSC,,1,tMDXRequest)		// DTB739		// DTB882 -Refresh the key and supply the calling text 
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute this query and materialize the contents of the result axes.<br/>
/// The results are written to the results cache.
Method %ExecuteAxes() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tStart = $ZH
	Try {
		// DTB980 - Add timers
		$$$dsSetLogging
		$$$dsStartTimer
		
		If (..%QueryKey '= "") {
			Set tStatus = $G($$$DeepSeeResultsGLVN($$$DeepSeeIndex(..cube),..%QueryKey,"status"))
		}

		Set tSC = ..%QueryTrace("%ExecuteAxes",..cube,"Status: "_$G(tStatus,"N/A"))
		If $$$ISERR(tSC) Quit

		// These variables provide extra context when processing
		New %query,%cube,%axis,%leafCount,%isSlicer,%dsDepends,%axisObject,%slicerKey,%cubeIndex,%axisNo,%axisKey
		If (..%QueryKey = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid or missing query key")
			Quit
		}

		#; contextual info
		Set %query = $this
		Set %cube = $$$UPPER(..cube)
		Set %cubeIndex = $$$DeepSeeIndex(..cube)
		Set %isSlicer = 0
		Set %slicerKey = ""

		// JMD1156 was 100
		If (tStatus >= 30) {
			// results are ready
			Quit
		}
		ElseIf (tStatus < 10) {
			// JMD1156
			// + WAL049 -- Fix error message
			Set tSC = $$$ERROR($$$GeneralError,"Query must be prepared prior to calling ExecuteAxes: " _ %cubeIndex _"::"_ ..%QueryKey)		// DTB825 - Report query key
			// - WAL049
			Quit
		}

		// execute subqueries
		Set tSubQueryCount = ..subqueries.Count()
		If (tSubQueryCount>0) {
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 15
		}

		// no need to pass parms to subqueries-- they will already be resolved
		Kill tParmValues
		For n = 1:1:tSubQueryCount {
			Set tRS = ..subqueries.GetAt(n)

			If (%query.useAgents) {		// DTB704 - Only test useAgents
				If '+$G(%verbose) {
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
						Set tMsg = $S(tStatus < 35:"Computing subquery axes...",tStatus < 90:"Computing subquery cells...",1:"Consolidating subquery results...")
						Write $C(13,27)_"[0J"
						Write $J(tCount,4),": ",tMsg,"(",tStatus,")  "
						If (tComplete '= "") {
							Write $FN(tComplete,",",2),"% complete"
						}
						Hang $Case(tCount,1:0.1,2:0.2,:0.5)
						Set tStatus = tRS.%GetStatus(.tComplete)
					}
					Write $C(13,27)_"[0J"
				}

				// See if there are any outstanding async stats
				Set tQuery = tRS.%GetQuery()
				Set tExecTaskGroup = $G($$$DeepSeeResultsGLVN($$$DeepSeeIndex(tQuery.cube),tQuery.%QueryKey,"execTaskGroup"))
				If (tExecTaskGroup'="") {
					Set ..%Statistics("Cells") = $G(..%Statistics("Cells")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"Cells"))
					Set ..%Statistics("Calcs") = $G(..%Statistics("Calcs")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"Calcs"))
					Set ..%Statistics("Computes") = $G(..%Statistics("Computes")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"Computes"))
					Set ..%Statistics("CacheHits") = $G(..%Statistics("CacheHits")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"CacheHits"))
					Kill ^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup)
				}
			}
			Else {
				Set tSC = tRS.%Execute(.tParmValues)
				If $$$ISERR(tSC) Quit

				// fold in stats
				Set tQuery = tRS.%GetQuery()
				Set ..%Statistics("Computes") = $G(..%Statistics("Computes")) + $G(tQuery.%Statistics("Computes"))
				Set ..%Statistics("CacheHits") = $G(..%Statistics("CacheHits")) + $G(tQuery.%Statistics("CacheHits"))
				Set ..%Statistics("Cells") = $G(..%Statistics("Cells")) + $G(tQuery.%Statistics("Cells"))
				Set ..%Statistics("Calcs") = $G(..%Statistics("Calcs")) + $G(tQuery.%Statistics("Calcs"))
			}
			If $$$ISERR(tSC) Quit

			// save plan information
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"plan"))) = $LB("sq",tRS.%GetCubeName(),tRS.%GetQueryKey())
		}
		If $$$ISERR(tSC) Quit
		If (tSubQueryCount>0) {
			Set t2 = $ZH
			Set ..%Statistics("SubQueries") = t2 - tStart
			Set tStart = t2
		}
		Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 20

		If (..%isCompound) {
			// JMD1397
			If (..queryType'="DRILLTHROUGH") {
				Set tSC = ..%FoldCompoundQueries()
				If $$$ISERR(tSC) Quit
			}

			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 100
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"reason") = 4
			// JMD1381 clear the processing flag
			Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"zprocessing")
			Quit
		}

		/* axes */
		Set tAxisCount = ..axes.Count()
		
		// + WAL071
		// Every query will take out this same lock
		// This is a necessary bottleneck because we need to see if ALL axes
		// are available in a single, atomic step
		// This operation should be very fast
		Set tAxesAvailable = 0
		While ('tAxesAvailable) {
			Lock +^DeepSee.Query("ReserveAxes"):10
			If ('$Test) {
				Set tSC = $$$ERROR($$$GeneralError,"Unable to obtain CheckAxes lock")
				Quit
			}
			Set tSC = ..%ReserveAxes(.tAxesAvailable)
			Lock -^DeepSee.Query("ReserveAxes")
			If $$$ISERR(tSC) Quit
			
			If ('tAxesAvailable) {
				Hang 1	
			}
		}
		If $$$ISERR(tSC) Quit
		// - WAL071

		// this gets cleared if any of the axes are really out of date
		// if no axes, then always mark as invalid
		Set tAxesAreValid = $S(tAxisCount>0:1,1:0)

		/* process slicer (first) */
		If ($IsObject(..slicer)) {
			Set %isSlicer = 1
			Set tSC = ..%InitializeAxisCache("slicer",..slicer, .tAxisKey, .tCurrent)
			If $$$ISERR(tSC) Quit

			// use axis=0 for slicer
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"axis",0) = tAxisKey
			Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"format")

			Set tNodeNo = 1

			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"slicer") = ..slicer.%ToString()
			Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",tNodeNo) = $LB("slicer",0,0,,,+$G(%SetOpDepth(tAxisKey)),$classname()_":"_$$$dsCurrentMethod)		// DP-424589 - Add opdepth information for reference

			If (tCurrent<1) {
				If (tCurrent = 0) {
					Set tAxesAreValid = 0
				}
				Kill %dsDepends,%dsMeasures,%dsIsSlicer
				Set %dsDepends("x") = 0
				Set %dsMeasures("format") = ""
				Set tSlicerNode = tNodeNo
				Set %axis = tNodeNo // make available to entire tree
				Set %leafCount = 0
				Set %dsIsSlicer = 1	// some functions might want to know this!
				Set tStartA = $ZH
				Set %axisNo = -1
				Set %axisKey = tAxisKey
				Set tSC = ..slicer.%ProcessAxes(%cube,tAxisKey,.tNodeNo,.tNewNodeNo,tNodeNo)
				If $$$ISERR(tSC) Quit
				Kill %dsIsSlicer
				Set ..%Statistics("ExecuteSlicer") = $ZH - tStartA
				Kill %axisNo,%axisKey

				Set tSizeInfo(tAxisCount+1) = $LB("slicer",tAxisKey,%leafCount)
				Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"size") = tSizeInfo(tAxisCount+1)

				// is there a measure within the slicer
				Set tDefFormat = $G(%dsMeasures("format"))
				Kill %dsMeasures
				If (tDefFormat'="") {
					Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"format") = tDefFormat
					// JMD1092 Remember format in the slicer axis cache
					Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"format") = tDefFormat
				}

				// pick up member dependencies
				Kill %dsDepends("x")
				Merge ..slicer.%dependencies = %dsDepends

				// dependent facts
				Merge $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"fact") = ..slicer.%dependencies

				// test if any dependent facts are references
				// these get special treatment
				Set f = $O(..slicer.%dependencies(""))
				While (f'="") {
					Set fname = $G($$$DeepSeeMetaGLVN("cubes",%cube,"fact#",f))
					If ((fname'="")&&(+$G($$$DeepSeeMetaGLVN("cubes",%cube,"fact","prop",fname,"hasref")))) {
						Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"hasref") = f
						Quit
					}
					Set f = $O(..slicer.%dependencies(f))
				}

				// dependent subqueries
				For n = 1:1:..slicer.subqueries.Count() {
					Set tRS = ..slicer.subqueries.GetAt(n)
					Set tSQKey = tRS.%GetQueryKey()
					Set:tSQKey'="" $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"subquery",tSQKey) = ""
				}

				If (tCurrent < 0) {
					// reference axis: test crc to see if there has been a change
					Set tOldCRC = $G($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"oldcrc"))
					Set tSC = ..%ComputeAxisCRC(%cube,tAxisKey,.tCRC)
					If (tOldCRC'=tCRC) {
						Set tAxesAreValid = 0
					}
				}

				// JMD1403: walk over the slicer axis and see if
				// (a) there are any "deep relationships" in it
				// (b) there are any intersecting "deep relationships" in it
				If (..%hasRelations) {
					// COMBINE tuples from same deep relation

					// find set of relations for this cube
					Set r = $O($$$DeepSeeMetaGLVN("cubes",%cubeIndex,"rel#",""),1,data)
					While (r'="") {
						Set tRelation(r) = data
						Set r = $O($$$DeepSeeMetaGLVN("cubes",%cubeIndex,"rel#",r),1,data)
					}

					Set tNodeNo = $O($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",1,"all",""))
					While (tNodeNo'="") {
						Kill tRelInfo
		
						// walk up from bottom node
						Set tBaseNodeNo = tNodeNo
						Set tParentNo = tNodeNo
						While (tParentNo '= "") {
							Set tNode = $G($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",tParentNo))
							Set tType = $LG(tNode,1)
							Set tFact = $LG(tNode,7)
							Quit:(tType="slicer")

							If (tType="mbr") {
								Set tSpecial = $LG(tNode,22)
								If (tSpecial'="") && ($LG(tSpecial,3)>1) {
									Set tDeepSpec = $LG(tSpecial,1)
									Set tDeepCube = $LG(tSpecial,2)
									Set tRelInfo(tDeepCube,tParentNo,"spec") = tDeepSpec
									Set tRelInfo(tDeepCube,tParentNo,"cube") = ##class(%DeepSee.Utils).%GetRelatedCube(%cubeIndex,tRelation(tFact))   // DTB058
								}
							}
							Set tParentNo = $LG(tNode,4)
						}
						Set tNodeNo = $O($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",1,"all",tNodeNo))
					}
					// for each cube, find the set of filters and create
					// a new remote query
					Set tRelCube = $O(tRelInfo(""))
					While (tRelCube'="") {
						Kill tRelFilters
						Set tLastNodeNo = ""
						Set tTargetCube = ""
						Set tNodeNo = $O(tRelInfo(tRelCube,""))
						While (tNodeNo'="") {
							Set tRelFilters($I(tRelFilters)) = tRelInfo(tRelCube,tNodeNo,"spec")
							Set tTargetCube = tRelInfo(tRelCube,tNodeNo,"cube")
							If (tLastNodeNo'="") {
								// remove spec from node
								Set $List($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",tLastNodeNo),6) = ""
							}
							Set tLastNodeNo = tNodeNo
							Set tNodeNo = $O(tRelInfo(tRelCube,tNodeNo))
						}

						If (+$G(tRelFilters)>1) {
							// create new subquery
							Set tMDX = "%BITSET SELECT FROM ["_tTargetCube_"]"
							Set k = $O(tRelFilters(""))
							While (k'="") {
								Set tMDX = tMDX _ " %FILTER "_tRelFilters(k)
								Set k = $O(tRelFilters(k))
							}

							// n.b. this code is copied (and simplified) from memberRelationship

							// Create a resultSet for the query
							Set tRS = ##class(%DeepSee.ResultSet).%New()

							// pass on our named parameters to the subquery
							Merge tContext = ..%NamedParameters
							Do tRS.%SetParameterContext(.tContext)
							Set tRS.%UseCache = ..useCache
							Set tSC = tRS.%PrepareMDX(tMDX)
							If $$$ISERR(tSC) Quit
							
							// + WAL071
							Set tRS.%Query.parentQueryKey = $S(..parentQueryKey'="":..parentQueryKey,1:..%QueryKey) // WAL071 (2) -- use "root" of subquery tree if exists
							// - WAL071

							If +$G(%dsflags("RELATIONS")) {
								$$$DSWRITELN("*** (slicer)")
								$$$DSWRITELN("SUBQUERY: "_tMDX)
							}

							Kill tParmValues
							If (..useAgents) {		// DTB704 - Only test useAgents
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
										Write $J(tCount,4),": ",tMsg,"(",tStatus,")  "
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
							Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"plan"))) = $LB("sq",tRS.%GetCubeName(),tRS.%GetQueryKey())

							// +DTB458 - Log the subquery keys in the results global if a related cube is involved
							Set tSubqueryCube = tRS.%CubeKey
							Set tSubqueryKey = tRS.%GetQueryKey()
							If ($G(%cubeIndex)'="") && (tSubqueryCube'=$$$UPPER(%cubeIndex)) && (..%QueryKey'="") && (tSubqueryCube'="") && (tSubqueryKey'="") {
								Set $$$DeepSeeResultsGLVN($$$UPPER(%cubeIndex),..%QueryKey,"subquery",tSubqueryCube,tSubqueryKey) = "(5)"
							}
							// -DTB458

							// get results of subquery
							// later we will convert these to local bits
							Set tRemoteCube = tRS.%GetCubeName()
							Set tRemoteCubeIndex = $$$DeepSeeIndex(tRemoteCube)
							Set tQueryKey = tRS.%GetQueryKey()

							// axis count will always be 0
							Set tSpecialFactId = "@"_tQueryKey
							If (tLastNodeNo'="") {
								// replace spec from node
								Set $List($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",tLastNodeNo),6) = tSpecialFactId
							}
						}

						// next cube
						Set tRelCube = $O(tRelInfo(tRelCube))
					}

				} // hasRelations
				
				// DTB967 - Upon completion, mark the slicer axis with the cube timestamp
				Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"timestamp") = ##class(%DeepSee.Utils).%GetCubeDSTime(%cubeIndex)
			}
			Else {
				// use existing info
				Set tSizeInfo(tAxisCount+1) = $G($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"size"))

				// JMD1092 Pick up format from cached slicer
				Set tDefFormat = $G($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"format"))
				If (tDefFormat'="") {
					Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"format") = tDefFormat
				}
			}
			Set %slicerKey = tAxisKey
		}

		Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..cube)
		Set tFilterSpec = $zobjclassmethod(tCubeClass,"%GetFilterSpec")

		// DP-421530 - Execute a special slicer-only query whenever a slicer exists in the context of the base cube. 
		// This generates a slicer index that can be used in member fetch for levels.
		If $D($$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"slicer")) {
			Set tSELECT = "%BITSET" _ $S((..%WITHText'=""):" WITH " _ ..%WITHToString(),1:"") _ " SELECT"

			// DP-424293 - Reconstruct the where clause from the available filters, not the processed slicer designed for use with the base %cubeIndex.
			// This will produce %FILTER statments that are properly compatible with the %cube reference.
			Set tWHERE = ""
			For f=1:1:..filters.Count() {
				Set tFilterText = ..filters.GetAt(f).%ToString()
				Set:(tFilterText'="") tWHERE = tWHERE _ " %FILTER " _ tFilterText
			}

			// WAL080 -- use %cube, not %cubeIndex, so we reference subject areas instead of base cubes
			// DP-424293 - The WHERE clause is built to be compatible with the subject area or a cube with an implicit filterSpec
			Set tMDX = tSELECT _ " FROM ["_%cube_"]" _ tWHERE
			
			// PFS042 - Replace resolved CurrentMember with original text
			Set tCmbr = $O(..slicer.%cmbrIndex(""))
			While tCmbr'="" {
				set tMDX=$Replace(tMDX,tCmbr,..slicer.%cmbrIndex(tCmbr)_".CurrentMember")
				Set tCmbr = $O(..slicer.%cmbrIndex(tCmbr))	
			}
			
			If +$G(%dsflags("SUBQUERY")) {
				$$$DSWRITELN("SLICER SUBQUERY: "_tMDX)
				// + WAL080 -- use %cube, not %cubeIndex, so we reference subject areas instead of base cubes
				$$$DSWRITELN("*** ("_%cube_":"_..%QueryKey_")")
				// - WAL080
			}
			
			Set tBitRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tBitRS.%PrepareMDX(tMDX)


			// DTB593 - Bail out if the query failed prepare
			// DP-421530 - To prevent subquery recursion, do not execute if the new slicer-only query is identical to the original request
			If '$$$ISERR(tSC) && (tBitRS.%GetQueryKey()'=..%QueryKey) {
				Set tBitRS.%Query.parentQueryKey = $S(..parentQueryKey'="":..parentQueryKey,1:..%QueryKey) // WAL071 (2) -- use "root" of subquery tree if exists
				// DP-421530 - Set currently protected lock keys for the subquery
				Merge tLockKeys = ..%LockKeys
				Set tSC = tBitRS.%SetAncestorLockKeys(.tLockKeys)
				
				If ..useAgents {		// DTB704 - Only test useAgents
					Set tSC = tBitRS.%ExecuteAsynch(.tBitQueryKey,.tParmValues,1)
				}
				Else {
					Set tSC = tBitRS.%Execute()
					Set tBitQueryKey = tBitRS.%GetQueryKey()
				}
				
				Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"bitquery") = $G(tBitQueryKey)
				
				// Log the subquery keys in the results global
				Set tBitQueryCube = tBitRS.%CubeKey
				If (tBitQueryCube'="") && (tBitQueryKey'="") {
					Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"subquery",tBitQueryCube,tBitQueryKey) = "(6)"
				}
			}
			
			If $$$ISERR(tSC)&&+$G(%dsflags("SUBQUERY")) {
				// DTB593 - Report the query error to the shell
				$$$DSWRITELN("SLICER SUBQUERY ERROR: "_$system.Status.GetErrorText(tSC))
			}
		}
		// -DTB086

		// Construct axes contents
		For a=1:1:tAxisCount {
			Set tNodeNo = 1
			Set tAxis = ..axes.GetAt(a)
			Set %axisObject = tAxis // make visible to entire tree

			Kill tAxisKey
			Set tSC = ..%InitializeAxisCache("axis",tAxis, .tAxisKey, .tCurrent,$G(..%originalAxisText(a)))
			If $$$ISERR(tSC) Quit

			// axis number to key
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"axis",a) = tAxisKey

			Set tAxisNode = 1
			Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",tAxisNode) = $LB("axis",0,0,,tAxis.nonEmpty,+$G(%SetOpDepth(tAxisKey)),$classname()_":"_$$$dsCurrentMethod)		// DP-424589 - Add SetOpDepth information

			If (tCurrent<1) {
				If (tCurrent = 0) {
					Set tAxesAreValid = 0
				}
				// axis is not current
				Kill %dsDepends
				Set %dsDepends("x") = a
				Set %axis = tAxisNode // make available to entire tree (!!! not really needed)
				Set %axisNo = a
				Set %axisKey = tAxisKey
				Set %leafCount = 0
				Set tStartA = $ZH
				Set tSC = tAxis.%ProcessAxes(%cube,tAxisKey,.tNodeNo,.tNewNodeNo,tAxisNode)
				If $$$ISERR(tSC) Quit
				// pick up member dependencies
				Kill %dsDepends("x")
				Merge tAxis.%dependencies = %dsDepends

				Set ..%Statistics("ExecuteAxis "_a) = $ZH - tStartA

				If (%leafCount=0) {
					// it appears that there are no members in this axis: let's check
					Set t = $O($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",1,"all",""))
					While (t'="") {
						Set %leafCount = %leafCount + 1
						Set t = $O($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",1,"all",t))
					}
				}
				
				If (%leafCount=0) {
					// DTB681 - Mark the axis as null if there are truly no members
					Set tSC = ..%NullifyAxis(tAxisKey)
					If $$$ISERR(tSC) Quit
				}

				// note: this is intermediate size before empties are removed
				// it is used to determine the order in which axes are combined
				// when computing cell values
				Set tSizeInfo(a) = $LB("axis",tAxisKey,%leafCount)
				Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"size") = tSizeInfo(a)

				// dependent facts
				Merge $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"fact") = tAxis.%dependencies

				// test if any dependent facts are references
				// these get special treatment
				Set f = $O(tAxis.%dependencies(""))
				While (f'="") {
					Set fname = $G($$$DeepSeeMetaGLVN("cubes",%cube,"fact#",f))
					If ((fname'="")&&(+$G($$$DeepSeeMetaGLVN("cubes",%cube,"fact","prop",fname,"hasref")))) {
						Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"hasref") = f
						Quit
					}
					Set f = $O(tAxis.%dependencies(f))
				}

				// dependent subqueries
				For n = 1:1:tAxis.subqueries.Count() {
					Set tRS = tAxis.subqueries.GetAt(n)
					Set tSQKey = tRS.%GetQueryKey()
					If (tSQKey'="") {
						// store result timestamp along with reference
						Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"subquery",tSQKey) = $G($$$DeepSeeResultsGLVN(%cube,tSQKey,"timestamp"))
					}
				}

				If (tAxesAreValid && (tCurrent < 0)) {
					// reference axis: test crc to see if there has been a change
					Set tOldCRC = $G($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"oldcrc"))
					Set tSC = ..%ComputeAxisCRC(%cubeIndex,tAxisKey,.tCRC)
					If (tOldCRC'=tCRC) {
						Set tAxesAreValid = 0
					}
				}
			}
			Else {
				// use existing info
				Set tSizeInfo(a) = $G($$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"size"))
			}	
			
			// DTB967 - Upon completion, mark this visible axis with the cube timestamp
			Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"timestamp") = ##class(%DeepSee.Utils).%GetCubeDSTime(%cubeIndex)
		}
		If $$$ISERR(tSC) Quit
		Kill %axisNo,%axisKey

		If (tAxesAreValid) {
			Set tHasData = ''$D($$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"data"))
			If (tHasData) {
				// check time stamp to be sure
				#; find version of cube contents
				Set tCubeTimestamp = ##class(%DeepSee.Utils).%GetCubeDSTime(%cubeIndex)		// DTB967 - Use API to fetch current cube timestamp 
				Set tResultTimestamp = +$G($$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"timestamp"))
				// JMD1383 change from '= to =
				If (tCubeTimestamp=tResultTimestamp) {
					Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 100
					Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"reason") = 5
					// JMD1381 clear the processing flag
					Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"zprocessing")
					Set tSC = ..%QueryTrace("%ExecuteAxes",..cube,"CURRENT AXES ARE VALID")

					Set ..%Statistics("ResultsCache") = 1
					Quit
				}
			}
			Set tSC = ..%QueryTrace("%ExecuteAxes",..cube,"RESULTS CACHE HAS NO DATA")
			If $$$ISERR(tSC) Quit
		}

		// JMD1014: if an axis is not valid, we can't trust any prior results
		If ('tAxesAreValid) {
			Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"data")
			Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"leaf")
			Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"nonempty")
			Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"total")
		}

		// store dimension size info
		Set tSizeList = ""
		Set tVolume = 1

		Set n = $O(tSizeInfo(""))
		While (n '= "") {
			Set sz = $LG(tSizeInfo(n),3)
			Set:sz>0 tVolume = tVolume*sz // !!!
			Set tSizeList = tSizeList _ $LB(tSizeInfo(n))
			Set n = $O(tSizeInfo(n))
		}

		// store number of cells
		Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"size") = tSizeList
		Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"cells") = tVolume

		// resolve currentMember references, if any, before proceeding
		Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 22
		Set tSC = ##class(%DeepSee.Query.Engine).%ResolveCurrentMembers(%cube,..%QueryKey,$this)
		If $$$ISERR(tSC) Quit

		/*
		If (##class(%DeepSee.Utils).%TestForCancel(3)) {
			Set tSC = $$$ERROR($$$GeneralError,"Query cancelled (3).")
			Kill $$$DeepSeeAxisGLVN(%cubeIndex,..%QueryKey)
			Quit
		}
		*/

		// resolve relationships before proceeding
		If (..%hasRelations) {
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 25
			Set tSC = ##class(%DeepSee.Query.Engine).%ResolveRelationships(%cube,..%QueryKey,..useAgents)
			If $$$ISERR(tSC) Quit
		}

		Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 30
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Set ..%Statistics("ExecuteAxes") = $ZH - tStart
	Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"stats","ExecuteAxes") = ..%Statistics("ExecuteAxes")		// DP-421530
	
	If $$$ISERR(tSC) {
		// mark as done
		If ($G(%cubeIndex)'="")&&(..%QueryKey'="") {
			If $G(tAxisKey)'="" { 
				// DTB716 - If processing got far enough to make the axis key, mark the last axis with an error
				Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"error") = tSC
			}
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"status") = 100
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"reason") = 6
			Set $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"error") = tSC
			// JMD1381 clear the processing flag
			Do ..%ReleaseReservedAxes(%cubeIndex,..%QueryKey)		// DTB579 - Release axes
			Kill $$$DeepSeeResultsGLVN(%cubeIndex,..%QueryKey,"zprocessing")
		}
	}
	
	$$$dsStopTimer		// DTB980
	
	Quit tSC
}

Method %ReserveAxes(Output pAxesAvailable) As %Status [ Internal ]
{
	// Method added by WAL071
	Set tSC = $$$OK
	Try {
		Set pAxesAvailable = 1
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		// Slicer
		If ($IsObject(..slicer)) {
			Set tCurrentAxis = ..slicer
			Set tAxisKey = ""
			Set tSC = ..%MakeReserveAxisKey("slicer",tCurrentAxis,.tReserveKey)			// DTB319
			If $$$ISERR(tSC) Quit
			
			If (tReserveKey '= "") {
				// check for zprocessing on that axis key;
				// if not set, keep going
				If ($G($$$DeepSeeResultsGLVN(tCubeIndex,"reservedAxes",tReserveKey,"zprocessing"))'="") {
					If (..parentQueryKey = $$$DeepSeeResultsGLVN(tCubeIndex,"reservedAxes",tReserveKey,"zprocessing")) {
					}
					Else {
						Set pAxesAvailable = 0
					}
				}
				Else {
					Set tReserveKeys(tReserveKey) = "slicer:"_tCurrentAxis.%ToString()		// DTB319
				}
			}
		}
		// Other axes
		Set tAxisCount = ..axes.Count()
		For tCurrentAxisIndex = 1:1:tAxisCount {
			Set tCurrentAxis = ..axes.GetAt(tCurrentAxisIndex)
			If $IsObject(tCurrentAxis) {
				Set tReserveKey = ""
				Set tSC = ..%MakeReserveAxisKey("axis",tCurrentAxis,.tReserveKey)	// DTB319
				If $$$ISERR(tSC) Quit
				
				// DTB141 - Do not lock %SEARCH axes
				If (tReserveKey '= "") && 'tCurrentAxis.%IsSearch() {
					If ($G($$$DeepSeeResultsGLVN(tCubeIndex,"reservedAxes",tReserveKey,"zprocessing"))'="") {
						If (..parentQueryKey = $$$DeepSeeResultsGLVN(tCubeIndex,"reservedAxes",tReserveKey,"zprocessing")) {}
						Else {
							Set pAxesAvailable = 0
						}
					}
					Else {
						Set tReserveKeys(tReserveKey) = "axis:"_tCurrentAxis.%ToString()		// DTB319
					}
				}
			}
		}
		If (pAxesAvailable) {
			// loop through axis keys and claim them
			Set tReserveKey = $O(tReserveKeys(""),1,tText)
			Set tIndex = ""
			While (tReserveKey'="" && (..parentQueryKey="")) {
				// This is referenced later in %Consolidate to figure out which axes to release
				Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"reservedAxes",tReserveKey) = tText		// DTB579 - Set the cleanup global first
				// Store with axis key for other people to look at
				//Set $$$DeepSeeResultsGLVN(tCubeIndex,"reservedAxes",tReserveKey,"zprocessing") = ..%QueryKey		// DTB843 - Managed by locks

				Set tReserveKey = $O(tReserveKeys(tReserveKey),1,tText)	
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method to remove the zprocessing node for reserved axes
ClassMethod %ReleaseReservedAxes(pCubeName, pQueryKey) As %Status [ Internal ]
{
	// Method added by DTB168
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tReserveKey = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"reservedAxes",""))
		While (tReserveKey '= "") {
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,"reservedAxes",tReserveKey,"zprocessing")
			Set tReserveKey = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"reservedAxes",tReserveKey))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %MakeReserveAxisKey(pType As %String, pAxis As axis, Output pReserveKey As %String, pOriginalSpec As %String = "") As %String [ Internal ]
{
	// Method added by WAL071
	Set tSC = $$$OK
	Try {
		Set pAxisKey = ""
		Set tCubeIndex = $$$DeepSeeIndex(..cube)

		// make sure %ToString includes enough information for key generation
		New %dsMakeKey
		Set %dsMakeKey = 1

		// DTB319 - Create a reserve axis key. This is *not* the same key as in the axis cache, it is created from the more general
		// text without the WITH clause or axis placement
		If ($IsObject(..slicer)) {
			Set tText = ..slicer.%ToString()_":"_pAxis.%ToString()
		}
		Else {
			Set tText = pAxis.%ToString()
		}

		// if there is a filter, we need this as well
		If ($IsObject(..filterAxis)) {
			Set tText = tText_":"_..filterAxis.%ToString()
		}

		// JMD1400: if we have original text for the axis; tack it on
		If (pOriginalSpec'="") {
			Set tText = tText_":"_pOriginalSpec
		}
		
		Kill %dsMakeKey
		Set tLang = ..%GetLanguage()
		Set pReserveKey = "reserve:"_tLang_$ZCRC(tText,7)		// DTB319 - Prepend with "reserve" to distinguish from standard keys
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set up the axis cache for the given axis.
/// Also test if the axis already exists and is up-to-date.<br/>
/// On return, <var>pUpToDate</var> is 1 if the axis is up-to-date,
/// 0 if it is not, and -1 if it is a reference axis that needs further checking.
Method %InitializeAxisCache(pType As %String, pAxis As axis, Output pAxisKey As %String, Output pUpToDate As %Integer, pOriginalSpec As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pUpToDate = 1		// DTB967 - Initialize under the assumption the axis will be reused
		Set pAxisKey = ""
		Set tCubeIndex = $$$DeepSeeIndex(..cube)

		// DTB820 - All error handling and key stabilization is covered in %CreateAxisKey
		Set pAxisKey = ..%CreateAxisKey(.tSC,pType,pAxis,pOriginalSpec,.tText)
		If $$$ISERR(tSC) Quit
		
		// DTB820 - Move trace back into this method
		Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,tText)
		If $$$ISERR(tSC) Quit
		
		// DTB967 - Check to see if there was an error in this axis on the last processing attempt. 
		// If so, it must be recalculated.
		If $G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"error"))'="" {
			Set pUpToDate = 0
			Kill $$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"error")
			Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,"Axis contained an error on last execution, recalculating: "_pAxisKey)
			If $$$ISERR(tSC) Quit
		}
		
		// DTB967 - Test the timestamp for this axis against the current cube timestamp
		Set tCubeTimestamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tCubeIndex)
		Set tAxisTimestamp = +$G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"timestamp"))
		If 'tAxisTimestamp || (tAxisTimestamp<tCubeTimestamp) {
			Set pUpToDate = 0
			Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,"Axis is out of date. Key:"_pAxisKey_"; Cube timestamp:"_tCubeTimestamp_"; Axis timestamp:"_tAxisTimestamp)
			If $$$ISERR(tSC) Quit
		}
		
		// DTB967 - Check to see if the previous axis actually defined an actionable set
		If $D($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"axes",1,"all")) {
			Set tNode1 = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"axes",1,"all",""))
			If (tNode1="") {
				// There is no functional axis to work with, so assume this cannot be up to date
				Set pUpToDate = 0
				Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,"Axis was cached with no members:"_pAxisKey)
				If $$$ISERR(tSC) Quit
			}
			ElseIf (""=$O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"axes",1,"all",tNode1))) {
				// There is only one node. If it is the NO MEMBER (empty set), mark the axis as an automatic 
				// recompute. Also test for the event of a !NO MEMBER.
				Set tKeyID = $LG($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"axes",tNode1),6)
				If (tKeyID="NO MEMBER")||(tKeyID="!NO MEMBER") {
					Set pUpToDate = 0
				}
			}
		}
		
		// DTB967 - If the calling context has set the %recomputeAxes flag, return as if the axis
		// is not up to date.
		If (..%recomputeAxes) {
			Set pUpToDate = 0
			Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,"Axes marked as must-compute")
			If $$$ISERR(tSC) Quit
		}

		
		// DTB967 - This section performs a finer examination of the particular contents of the axis.
		// This will only initiate if all of the broad checks above determine the axis is a candidate
		// for reuse.
		If pUpToDate {
			// JMD871: if axis depends on slicer and/or is sensitive to updates to facts
			// then mark it as not up-to-date
			// same is true for computed dimensions
			If (+$G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"recompute"))) {
				// JMD1383 set to -1
				Set pUpToDate = -1
			}

			// JMD887 Test each termlist this axis uses
			Set tTermList = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"termlist",""),1,ts)
			While ((pUpToDate) && (tTermList'="")) {
				If ($G(^DeepSee.TermList($$$UPPER(tTermList),"modDate"))'=ts) {
					Set pUpToDate = 0
				}
				Set tTermList = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"termlist",tTermList),1,ts)
			}

			#; JMD1012 test if join indices are used and if they exist
			Set tHasRelations = +$G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"hasRelations"))
			If ((pUpToDate) && tHasRelations) {
				Set tAxisNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"axes",""))
				While ((pUpToDate) && (tAxisNodeNo'="")) {
					Set tNodeInfo = $G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"axes",tAxisNodeNo))
					If ($LG(tNodeInfo,1)="mbr") {
						Set tRelKey = $LG(tNodeInfo,6)
						Set tRelFact = $LG(tNodeInfo,7)	// use correct #
						If ((tRelFact'="")&&($E(tRelKey)="@")) {
							Set tRelKey=##class(%DeepSee.Query.Engine2).%CanonizeRelationKey(tRelKey) // JSL4407								
							// JMD1017 use hash to prevent subscript error
							Set khash = $S($L(tRelKey)<100:tRelKey,1:$ZCRC(tRelKey,7))
							Set tTest = $D($$$DeepSeeJoinGLVN(tCubeIndex,tRelFact,khash))
							If (tTest<10) {
								Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,"JOIN INDEX DOES NOT EXIST")
								If $$$ISERR(tSC) Quit
								Set pUpToDate = 0
							}
						}
					}
					Set tAxisNodeNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"axes",tAxisNodeNo))
				}
			}

			// Test each subquery this axis depends on
			Set tSubKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"subquery",""),1,ts)
			While ((pUpToDate) && (tSubKey '= "")) {
				// JMD885: Is this a query against a related cube?
				Set tQueryCube = $G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"subquery",tSubKey,"cube"))
				Set tSC = ..%TestSubQueryCache(tCubeIndex, tSubKey,ts,.pUpToDate,tQueryCube)
				If $$$ISERR(tSC) Quit
				Set tSubKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"subquery",tSubKey),1,ts)
			}
			If $$$ISERR(tSC) Quit

			// Test each fact this axis depends on
			Set tFactNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"fact",""),1,ts)
			While ((pUpToDate) && (tFactNo '= "")) {
				If (ts'=$G($$$DeepSeeResultsGLVN(tCubeIndex,"fact",tFactNo))) {
					Set pUpToDate = 0
				}
				Set tFactNo = $O($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"fact",tFactNo),1,ts)
			}

			// extra test for axis with reference
			// JMD1383 also test if axis is marked as "recompute"
			If (pUpToDate && ((+$G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"hasref")))||$G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"recompute")))) {
				Set tSC = ..%ComputeAxisCRC(tCubeIndex,pAxisKey,.tCRC)
				Set pUpToDate = -1
			}
		}

		If (pUpToDate>0) {
			Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,"REUSING AXIS: " _ tText)
			If $$$ISERR(tSC) Quit
			Set ..%Statistics("ResultsCache") = 1
			Quit  // axis is ready
		}

		Set tSC = ..%QueryTrace("%InitializeAxisCache",..cube,"CREATING AXIS: " _ tText)
		If $$$ISERR(tSC) Quit

		// DTB818 - Clear the axis while preserving the key generation text
		Set tKeyText = $G($$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"keyText"))
		Kill $$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey)
		Set:(tKeyText'="") $$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"keyText") = tKeyText

		// set up axis info
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"spec") = tText
		If ((pUpToDate<0) && $D(tCRC)) {
			Set $$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"oldcrc") = tCRC
		}
		
		// DTB818 - Log the requested axis for this session
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pAxisKey,"request",$$$DeepSeeSessionId) = pAxis.%originalSpec
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		// DTB967 - If anything has gone wrong while initializing, do not trust this axis cache
		// even if calling code decides to recover from the error status and move on.
		Set pUpToDate = 0
		Set ..%Statistics("ResultsCache") = 0
	}
	
	Quit tSC
}

/// Execute this query and calculate the contents of the resulting cells.<br/>
/// Note that this may be called on a partially constructed
/// query object if a ResultSet was prepared using an existing
/// query key.<br/>
Method %ExecuteCells(pTrace As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// DTB980 - Add timers
		$$$dsSetLogging
		$$$dsStartTimer
		
		Set tCube = $$$UPPER(..cube)
		Set tCubeIndex = $$$DeepSeeIndex(tCube)

		// status for tracing
		Set tStatus = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status"))
		Set tSC = ..%QueryTrace("%ExecuteCells",..cube,"Status: "_tStatus)
		If $$$ISERR(tSC) Quit

		Set tError = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"error"))
		If (tError'="") {
			Set tSC = tError
			Quit
		}

		Set tSC = ..%PrepareResultsCache()
		If ($$$ISERR(tSC)) {
			Quit
		}

		// test state of results
		Set tStatus = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status"))
		If (..%mustCompute) {
			// Set must-compute flag for cached results
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"mustCompute") = 1
		}

		If (tStatus = 100) {
			// already calculated
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","BucketsProcessed")
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","Consolidate")
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","ExecuteCells")
			Quit
		}
		If (tStatus < 30) {
			Set tSC = $$$ERROR($$$GeneralError,"%ExecuteCells: ExecuteAxes must be called prior to calling ExecuteCells.")
			Quit
		}

		// update status
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 35

		// calculate intermediate results
		Set t1 = $ZH
		Set tSC = ..%ExecuteIntermediateCells(..cube, ..%QueryKey, ..useAgents, pTrace,.tExecStats)
		If $$$ISERR(tSC) Quit

		Set t2 = $ZH
		// get list of buckets to process
		// (unless we already have them)
		If '$D($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"bucketList")) {
			// get list of buckets for this cube
			Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(tCube,.tBucketList,.tActiveChunk)
			If $$$ISERR(tSC) Quit
			Merge $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"bucketList") = tBucketList
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"activeChunk") = tActiveChunk
		}
		Else {
			Merge tBucketList = $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"bucketList")
			Set tActiveChunk = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"activeChunk"))
		}

		// if we are in "plan" mode, skip execution over non-active facts
		If (..showPlan) {
			Kill tBucketList
		}

		// treat active chunk as another bucket (with slot = -1)
		Set:tActiveChunk'="" tBucketList(-1) = -1

		Set tStatus = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status"))
		If (tStatus < 50) {
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 50
			Set tSC = ##class(%DeepSee.Query.Engine).%Consolidate(tCube,..%QueryKey,.tBucketList,pTrace,.tStats)
			If $$$ISERR(tSC) {
				Quit
			}

			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 60
			Set:(..queryType'="DRILLTHROUGH") $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"plan"))) = $LB("cons",tCube,..%QueryKey)

			Set t3 = $ZH

			// save timings stats in results global
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","ExecuteCells") = t2-t1
			Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","Consolidate") = t3-t2

			// local copy (if async these are in a global)
			Set ..%Statistics("Cells") = $G(tStats("Cells"))
			Set ..%Statistics("Calcs") = $G(tStats("Calcs"))
			Set ..%Statistics("Passes") = $G(tStats("Passes"))
			Set ..%Statistics("Computes") = $G(..%Statistics("Computes")) + $G(tExecStats($$$dsqStatCompute))
			Set ..%Statistics("CacheHits") = $G(..%Statistics("CacheHits")) +$G(tExecStats($$$dsqStatCache))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	// done: there might be errors!
	Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 100
	Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"reason") = 7
	// JMD1381 clear the processing flag
	Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"zprocessing")
	If $$$ISERR(tSC) {
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"error") = tSC
	}
	
	$$$dsStopTimer		// DTB980

	Quit tSC
}

/// This does the actual work of splitting the
/// cells into buckets and sections and executing them.<br/>
/// This may be called from a background agent.
ClassMethod %ExecuteIntermediateCells(pCubeName As %String, pQueryKey As %String, pUseAgents As %Boolean = 1, pTrace As %Boolean = 0, ByRef pStats) As %Status [ Internal ]
{
	Set tSC = $$$OK
	
	Try {
		// DTB980 - Add timers
		$$$dsSetLogging
		$$$dsStartTimer
		
		Set tSC = ..%QueryTrace("%ExecuteIntermediateCells",pCubeName,pQueryKey)
		If $$$ISERR(tSC) Quit

		Set tBucketsProcessed = 0
		Set pCubeName = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tGroupId = ""
		Set tShowPlan = $G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"showPlan"))
		Set tQueryType = $G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"queryType"))

		// JMD852: Turn off drill through optimizations
		Set tIsDrillThru = 0 // (tQueryType = "DRILLTHROUGH")
		If (tIsDrillThru) {
			Set pUseAgents = 0
			// reset plan info
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"plan")
		}

		If (pUseAgents) {
			// DTB704 - This is now handled by the %DeepSee.WorkMgr
			Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tGroupId,1,"CELLS")
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Quit
			}
			Kill ^IRIS.Temp.DeepSeeUpdate($namespace,tGroupId)
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"cellTaskGroup") = tGroupId
		}

		// get list of results buckets that remain from prior calculations
		// and thus do not need to be calculated
		Set tSlot = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"data",0))
		While (tSlot '= "") {
			Set tNoCalcList(tSlot) = ""
			Set tSlot = $O($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"data",tSlot))
		}

		// get list of buckets to process
		If '$D($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"bucketList")) {
			// get list of buckets for this cube
			Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(pCubeName,.tBucketList,.tActiveChunk)
			If $$$ISERR(tSC) Quit
			Merge $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"bucketList") = tBucketList
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"activeChunk") = tActiveChunk
		}
		Else {
			Merge tBucketList = $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"bucketList")
			Set tActiveChunk = $G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"activeChunk"))
		}

		// JMD873 - remove test for drill through
		If (tShowPlan) {
			// only process *active* chunk for showPlan
			Kill tBucketList
		}

		// treat active chunk as another bucket
		Set:tActiveChunk'="" tBucketList(-1) = tActiveChunk

		// count number of buckets
		Set tBucketCount = 0
		Set k = $O(tBucketList(""))
		While (k'="") {
			Set tBucketCount = tBucketCount + 1
			Set k = $O(tBucketList(k))
		}

		// test if we need to break up processing by sections
		// for *large* cubes do not bother
		Set tVolume = 1
		Set tMinAxis = ""
		Set tAxisCount = 0
		Set tSizeInfo = $G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"size"))
		For tAxis = 1:1:$LL(tSizeInfo) {
			Set tInfo = $LG(tSizeInfo,tAxis)
			Set tType = $LG(tInfo,1)
			Set tKey = $LG(tInfo,2)
			Set tSize = $LG(tInfo,3)
			Set tNode = 1
			If (tType = "axis") {
				Set tAxisCount = tAxisCount + 1
				Set tAxisSize(tAxis) = tSize
				Set tAxisNode(tAxis) = tNode
				Set tAxisKey(tAxis) = tKey
				Set tVolume = tVolume * tAxisSize(tAxis)
			}
		}

		Set tSectionCount = 0
		Set tSectionNo = 0
		Set tFirstEdge = 25
		Set tCellsPerSection = $S(tVolume>10000:10000,tVolume>1000:500,1:250)
		If ((tBucketCount < 4) && (tVolume > tCellsPerSection) & 'tIsDrillThru) {
			// split into sections
			// first find how to split along each axis
			Set n = 0
			Set tAxis = $O(tAxisSize(""))
			While (tAxis '= "") {
				Set n = n + 1
				If (n = 1) {
					Set tSectionSize(tAxis) = $S(tAxisSize(tAxis)<tFirstEdge:tAxisSize(tAxis),1:tFirstEdge)
					Set tSectionVol = tSectionSize(tAxis)
				}
				Else {
					Set tSectionSize(tAxis) = (tCellsPerSection/tSectionVol)
					Set:(tSectionSize(tAxis)\1)'=(tSectionSize(tAxis)/1) tSectionSize(tAxis) = (tSectionSize(tAxis)\1) + 1
					Set tSectionSize(tAxis) = $S(tSectionSize(tAxis)<1:1,tSectionSize(tAxis)>tAxisSize(tAxis):tAxisSize(tAxis),1:tSectionSize(tAxis))
					Set tSectionVol = tSectionVol * tSectionSize(tAxis)
				}

				If (tSectionSize(tAxis) < tAxisSize(tAxis)) {
					Set tPieces = tSectionSize(tAxis)
					Set tPieceNo = 1
					Set tCount = 0
					Set tNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tAxisNode(tAxis),"all",""))
					While (tNode '= "") {
						If (tCount = 0) {
							Set tSectionStart(tAxis,tPieceNo) = tNode
							Set tSectionCount = tSectionCount + 1
						}
						Set tCount = tCount + 1
						Set tNextNode = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey(tAxis),"axes",tAxisNode(tAxis),"all",tNode))
						If ((tCount = tPieces)||(tNextNode="")) {
							If (tNextNode '= "") {
								Set tCount = 0
								Set tPieceNo = tPieceNo + 1
							}
						}
						Set tNode = tNextNode
					}
					Set tPieceCount(tAxis) = tPieceNo
				}
				Set tAxis = $O(tAxisSize(tAxis))
			}
		}

		// execute for each section (if more than one)
		If $D(tPieceCount) {
			// execute for each section
			Set a = $O(tPieceCount(""))
			Set tFirstAxis = a
			Set tLastAxis = a
			While (a '= "") {
				Set tCounter(a) = 1
				Set tLastAxis = a
				Set a = $O(tPieceCount(a))
			}
		}

		Kill tStats
		Set tCount = 0
		Set tDone = 0
		While ('tDone) {
			Kill tSections
			Set tSectionSpec = ""  // serialized section list
			Set a = $O(tPieceCount(""))
			While (a '= "") {
				Set tEnd = $G(tSectionStart(a,tCounter(a)+1))
				Set tEnd = $S(tEnd="":"",1:+tEnd)
				Set tSections(a) = $LB(+tSectionStart(a,tCounter(a)),tEnd)
				Set tSectionSpec = tSectionSpec _ $S(tSectionSpec="":"",1:";") _ a_":"_+tSectionStart(a,tCounter(a))_":"_tEnd
				Set a = $O(tPieceCount(a))
			}

			// now execute for each bucket
			// (unless it is in the no-calc list)
			Set tBucket = $O(tBucketList(""))
			While (tBucket '= "") {
				Set tSlotNo = tBucketList(tBucket)
				If '$D(tNoCalcList(tSlotNo)) {
					Set tCount = tCount + 1
					Set tBucketsProcessed = tBucketsProcessed + 1
					Set tSlotNo = tBucketList(tBucket)
					If (pUseAgents) {
						// DTB704 - This is now handled by the %DeepSee.WorkMgr
						Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId,"EXECBUCKET",pCubeName,pQueryKey,tBucket,tSlotNo,tSectionSpec)
					}
					Else {
						Set tSC = ##class(%DeepSee.Query.Engine).%ExecuteForBucket(pCubeName,pQueryKey,tBucket,tSlotNo,.tSections,pTrace,.pStats)
					}
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB
				}
				// next bucket
				Set tBucket = $O(tBucketList(tBucket))
			}
			If $$$ISERR(tSC) Quit
			If ('$D(tPieceCount)) {
				Set tDone = 1
			}
			Else {
				// next section
				Set a = tLastAxis
				While (1) {
					Set tCounter(a) = tCounter(a) + 1
					If (tCounter(a) > tPieceCount(a)) {
						Set tCounter(a) = 1
						Set a = $O(tPieceCount(a),-1)
						If (a = "") {
							Set tDone = 1
							Quit
						}
					}
					Else {
						Quit
					}
				}
			}
		} // while('tDone)
		If $$$ISERR(tSC) Quit

		Set:tSectionCount=0 tSectionCount = 1
		Set:'tIsDrillThru $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"plan",$I($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"plan"))) = $LB($S(pUseAgents:"execA",1:"exec"),pCubeName,tCount/tSectionCount,tSectionCount)

		If (pUseAgents) {
			#; wait for agents
			// DTB704 - This is now handled by the %DeepSee.WorkMgr
			Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId)

			If $$$ISERR(tSC) {
				Set tText = $System.Status.GetErrorText(tSC)
				Do ##class(%DeepSee.Utils).%WriteToLog("Query","Error in %ExecuteIntermediateCells: " _ tText)
			}
	
			Set tExecTaskGroup = $G($$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"execTaskGroup"))
			If (tExecTaskGroup'="") {
				Set ^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"Computes") = +$G(^IRIS.Temp.DeepSeeUpdate($namespace,tGroupId,"Computes"))
				Set ^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"CacheHits") = +$G(^IRIS.Temp.DeepSeeUpdate($namespace,tGroupId,"CacheHits"))
			}
			Kill $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"cellTaskGroup")
		}

		If $$$ISOK(tSC) {
			Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"status") = 40
		}
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"stats","BucketsProcessed") = tBucketsProcessed
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"error") = tSC
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"status") = 100
		Set $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"reason") = 8
		// JMD1381 (2) clear the processing flag
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"zprocessing")
	}
	
	$$$dsStopTimer		// DTB980
	
	Quit tSC
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Set tText = ""

	If (..showPlan) {
		Set tText = tText _ "%SHOWPLAN "
	}

	If (..queryType = "DRILLTHROUGH") {
		If (..%listingSource="facts") {
			Set tText = tText _ "DRILLFACTS "
		}
		Else {
			Set tText = tText _ "DRILLTHROUGH "
		}
	}
	ElseIf (..queryType = "%BITSET") {
		Set tText = tText _ "%BITSET "
	}

	// named sets?
	Set tWITH = $ZSTRIP($S(..%originalWITHContents'="":..%originalWITHContents,1:..%WITHToString()),"<>W")		// DTB630
	If (tWITH '= "") {
		Set tText = tText _ "WITH " _ tWITH _ " "
	}
	Set ..%WITHText = tWITH // remember for later processing

	Set tText = tText _ "SELECT"

	Set tHasAxis = 0
	For a = 1:1:..axes.Count() {
		Set tAxis = ..axes.GetAt(a)
		Set tAxisText = tAxis.%ToString(.pSC)
		If (tAxisText '= "") {
			Set tText = tText _ $S(tHasAxis:",",1:" ") _ tAxisText _ " ON " _ (a-1)
			Set tHasAxis = 1
		}
		If $$$ISERR(pSC) Quit
	}
	If $$$ISERR(pSC) {
		Quit ""
	}

	If (..cube '= "") {
		// DP-424293 - Check for the flag which signals the request for the query which directly targets the base cube
		Set tCube = $S($G(%baseCubeQuery):$$$DeepSeeIndex(..cube),1:..cube)

		// DTB130 - if cube is a version, report the generic cube name in the query text
		Set tText = tText _ " FROM [" _ ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(tCube)_"]"
	}

	If ($IsObject(..slicer)) {
		// If a slicer exists produce a WHERE clause. This will take slightly different forms for cubes vs subject areas
		If $IsObject(..filterAxis) {
			// DP-424293 - If an implicit filterAxis is present, construct the slicer using its %FILTER components, which will 
			// respect the view context.
			Set tWHERE = ""
			For f=1:1:..filters.Count() {
				Set tFilter = ..filters.GetAt(f).%ToString(.pSC)
				If $$$ISERR(pSC) Quit

				Set:(tFilter'="") tWHERE = tWHERE _ " %FILTER " _ tFilter
			}
		}
		Else {
			Set tWHERE = " WHERE " _ ..slicer.%ToString(.pSC)
		}
		Set tText = tText _ tWHERE
	}
	If $$$ISERR(pSC) {
		Quit ""
	}

	If (..queryType = "DRILLTHROUGH") {
		If (..%returnList'="") {
			Set tText = tText _ " RETURN " _ ..%returnList
		}
	}
	Quit tText
}

/// Convert the WITH clause for this query (named sets and calculated members) to a canonic text representation.
Method %WITHToString() As %String
{
	Set tText = ""

	// Named sets
	Set tSetName = ""
	Set tSet = ..namedSets.GetNext(.tSetName)
	While (tSetName '= "") {
		Set tNamedSets(tSetName) = tSet
		Set tSet = ..namedSets.GetNext(.tSetName)
	}
	If ($D(tNamedSets)) {
		Set tSetName = $O(tNamedSets(""))
		While (tSetName '= "") {
			Set tText = tText _ " SET ["_tSetName_"] AS '"_tNamedSets(tSetName).definition_"' "
			Set tSetName = $O(tNamedSets(tSetName))
		}
	}

	// calculated members
	Set tMbrName = ""
	Set tMbr = ..calculatedMembers.GetNext(.tMbrName)
	While (tMbrName '= "") {
		Set tCalcMbrs(tMbrName) = tMbr
		Set tMbr = ..calculatedMembers.GetNext(.tMbrName)
	}
	If ($D(tCalcMbrs)) {
		Set tMbrName = $O(tCalcMbrs(""))
		While (tMbrName '= "") {
			Set tMbr = tCalcMbrs(tMbrName)
			
			// DTB630 - Respond with the original cased name
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tMbr.originalName,.tInfo)
			Set tOriginalNameText = tInfo(1)
			
			
			Set tText = tText _ " MEMBER ["_tMbr.parentDimension_"].["_$$$dsEscapeIdent(tOriginalNameText)_"] AS '"_tMbr.definition_"'"
			If (tMbr.formatString'="") {
				Set tText = tText _ ",FORMAT_STRING='"_$Replace(tMbr.formatString,"'","''")_"'"
			}
			If (+tMbr.solveOrder'=0) {
				Set tText = tText _ ",SOLVE_ORDER="_tMbr.solveOrder
			}
			Set tMbrName = $O(tCalcMbrs(tMbrName))
		}
	}

	Quit tText
}

/// See if the specified named set is defined.<br/>
/// <var>pName</var> should not have [ ] characters around it.
Method %LookupNamedSet(pName As %String, ByRef pSet As %DeepSee.Query.set, Output pSC As %Status) As %Boolean
{
	Set pSC = $$$OK
	// first look in local array defined by query
	Set pSet = ..namedSets.GetAt($$$UPPER(pName))
	If $IsObject(pSet) {
		// return a copy of this object
		Set pSet = pSet.%ConstructClone(1)
		Quit 1
	}

	// now look in pre-defined list of named sets
	Set tInfo = ""

	// session
	If $IsObject($G($$$DeepSeeSession)) {
		Set tSessionId = $$$DeepSeeSession.%GetSessionId()
		If $D($$$DeepSeeSessionGLVN(tSessionId,$$$UPPER(..cube),"namedSets",$$$UPPER(pName))) {
			Set tInfo = $G($$$DeepSeeSessionGLVN(tSessionId,$$$UPPER(..cube),"namedSets",$$$UPPER(pName)))
		}
	}
	
	// cube
	If ((tInfo="") && $D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"namedSets",$$$UPPER(pName)))) {
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"namedSets",$$$UPPER(pName)))
	}

	If (tInfo '= "") {
		// process this named set and add it to the local list
		Set tName = $LG(tInfo,1)
		Set tExpr = $LG(tInfo,2)
		Set pSet = ##class(%DeepSee.Query.namedSet).%New()
		Set pSet.name = tName
		Set pSet.origin = "cube"
		Set pSet.definition = tExpr
		Set pSC = ##class(%DeepSee.Query.Parser).%ParseMDXExpression(tExpr,$this,pSet,.tNode)
		If $$$ISERR(pSC) {
			Set pSC = $$$ERROR($$$GeneralError,"Error in named Set expression: " _ pName _ $C(13,10) _ $System.Status.GetErrorText(pSC))
			Quit 0
		}
		If '$IsObject(tNode) {
			Set pSC = $$$ERROR($$$GeneralError,"Pre-defined named set is invalid: " _ pName)
			Set pSet = ""
		}
		Else {
			Do ..namedSets.SetAt(pSet,pName)
			Quit 1
		}
	}

	Quit 0
}

/// See if the specified calculated member is defined.<br/>
/// <var>pMemberSpec</var> is an array of the names making up the member spec.
/// <var>pCount</var> is the number of names to look at in the list.
/// None of the names in the list should have [ ] characters around them.<br/>
/// If the last item in the list is the name of one of the few functions allowed on calculated dimensions,
/// then <var>pIsFunc</var> is set.
Method %LookupCalculatedMember(ByRef pMemberSpec As %String, pCount As %Integer, ByRef pSet As %DeepSee.Query.set, Output pSC As %Status, Output pIsFunc As %Boolean, pUseKey As %Boolean = 0) As %Boolean
{
	Set pSC = $$$OK
	Set pIsFunc = 0
	Kill pSet

	// pUseKey is used for computed dimensions
	// default: look for DIM.Member
	Set pDimName = $G(pMemberSpec(1))
	Set pName = $G(pMemberSpec(pCount))

	If (pName = "") {
		Quit 0
	}

	// JMD905 - test for special [%QualityMeasure] dimension
	If ($$$UPPER(pDimName)="%QUALITYMEASURE") {
		// look up the qmsr
		// JMD1098
		Set tQMName = ##class(%DeepSee.QualityMeasure.Utils).%ParseQualityMeasureName(pName,.tQGroup,.tQElement)

		// JMD get class for qmsr
		Set tQMsrClassLocal = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureClass(pName,.pSC)
		If $$$ISERR(pSC) {
			Quit 0
		}

		// JMD resolve linked measures
		Kill tVisited
		Set tQMsrClass = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasureClass(pName,.pSC,1,.tVisited)
		If $$$ISERR(pSC) {
			Quit 0
		}
		If (tQMsrClass="") {
			Set pSC = $$$ERROR($$$GeneralError,"Quality Measure not found: " _ tQMName)
			Quit 0
		}
		// place holder
		Set pSet = ##class(%DeepSee.Query.calculatedMember).%New()
		
		// parse the quality measure expression
		Set tFormat = ""
		If ((tQGroup="")&&(tQElement="")) {
			Set tFormat = $classmethod(tQMsrClass,"%GetFormat")
		}
		Set:tFormat="" tFormat = "#,##.##"
		Set pSet.formatString = tFormat
		Set pSet.originalName = $classmethod(tQMsrClassLocal,"%GetQualityMeasureCaption")
		Set:pSet.originalName="" pSet.originalName = $classmethod(tQMsrClass,"%GetQualityMeasureId")
		// tack group and element onto name
		Set:(tQGroup'="")||(tQElement'="") pSet.originalName = pSet.originalName_"/"_tQGroup
		Set:(tQElement'="") pSet.originalName = pSet.originalName_"/"_tQElement
		Set pSet.memberName = pSet.originalName

		Set tExpr = $classmethod(tQMsrClass,"%GetExpression",tQGroup,tQElement)
		// Add %LABEL with measure name to force dependency of cache key on quality measure name
		Set:tExpr'="" tExpr = "%LABEL("_tExpr_","_$$$quote(pSet.originalName)_")"
		Set pSC = ##class(%DeepSee.Query.Parser).%ParseMDXExpression(tExpr,$this,pSet,.tNode)
		If $$$ISERR(pSC) {
			If (pSC'["Error in calculated member expression: ") {
				Set pSC = $$$ERROR($$$GeneralError,"Error in quality measure: " _ pName _ $C(13,10) _ $System.Status.GetErrorText(pSC))
			}
			Else {
				Set pSC = $$$ERROR($$$GeneralError,"Error in quality measure: " _ pName)
			}
			Quit 0
		}
		If '$IsObject(tNode) {
			Set pSC = $$$ERROR($$$GeneralError,"Quality measure is invalid: " _ pName)
			Set pSet = ""
		}
		Else {
			// mark as resolved
			Set pSet.isResolved = 1
		}

		// JMD1406 set parentDimension so that %ToString works better
		Set pSet.parentDimension = pDimName
		Set pSet.qmsrName = pName
		Quit 1
	}

	// see if the member is defined locally
	Set pSet = ..calculatedMembers.GetAt($$$UPPER(pDimName)_"."_$$$UPPER(pName))
	If ($IsObject(pSet)) {
		If (pSet.isResolved) {
			// return a copy of this object
			Set pSet = pSet.%ConstructClone(1)
		}
		Else {
			// parse this calculated member
			Set pSC = ##class(%DeepSee.Query.Parser).%ParseMDXExpression(pSet.definition,$this,pSet,.tNode)
			If $$$ISERR(pSC) {
				If (pSC'["Error in calculated member expression: ") {
					Set pSC = $$$ERROR($$$GeneralError,"Error in calculated member expression: " _ pName _ $C(13,10) _ $System.Status.GetErrorText(pSC))
				}
				Else {
					Set pSC = $$$ERROR($$$GeneralError,"Error in calculated member expression: " _ pName)
				}
				Quit 0
			}

			If '$IsObject(tNode) {
				Set pSC = $$$ERROR($$$GeneralError,"Calculated member is invalid: " _ pName)
				Set pSet = ""
			}
			Else {
				// mark as resolved
				Set pSet.isResolved = 1
			}
		}
		Quit 1
	}

	// now look in pre-defined list of calculated members
	Set tInfo = ""

	// session
	If $IsObject($G($$$DeepSeeSession)) {
		Set tSessionId = $$$DeepSeeSession.%GetSessionId()
		If $D($$$DeepSeeSessionGLVN(tSessionId,$$$UPPER(..cube),"calcMbrs",$$$UPPER(pDimName)_"."_$$$UPPER(pName))) {
			Set tInfo = $G($$$DeepSeeSessionGLVN(tSessionId,$$$UPPER(..cube),"calcMbrs",$$$UPPER(pDimName)_"."_$$$UPPER(pName)))
		}
	}
	
	// DTB268 - Look for shared calculated members first, they will override cube members
	If (tInfo="") {
		Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMemberInfo(..cube,pDimName,pName,.tMbrInfo)
		If $D(tMbrInfo) {
			Set tInfo = $LB(tMbrInfo("dimension"),tMbrInfo("name"),tMbrInfo("expression"),tMbrInfo("format"),tMbrInfo("solveOrder"))	
		}
	}
	
	// cube
	If ((tInfo="") && $D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"calcMbrs",$$$UPPER(pDimName),$$$UPPER(pName)))) {
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"calcMbrs",$$$UPPER(pDimName),$$$UPPER(pName)))
	}

	// DTB554 - Following the expression lookup, replace any pivot variables with their current values
	Set tExpression = $LG(tInfo,3)
	If (tExpression'="") {
		Merge tVariables = ..%variables
		Set tSC = ..%ResolveVariablesInText(.tExpression,.tVariables)
		If $$$ISERR(tSC) Quit
		
		Set $LI(tInfo,3) = tExpression
	}	

	// JMD1329: if this is an MDX-computed dimension, treat it like a calc member
	If (tInfo="") {
		// first find out if this is a computed dimension:
		Set tDimClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"computedDims",$$$UPPER(pDimName)))
		If (tDimClass'="") {
			Set tBehavior = $classmethod(tDimClass,"%GetBehavior")
			If (tBehavior="MDX") {
				// find dim && hier #
				Set tDimNoInfo = ""
				Set tLevelName = ""
				If (pCount=4) {
					// dim + hier + level
					Set tLevelName = $G(pMemberSpec(3))
					Set tDimNoInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"mbrs",$$$UPPER(pDimName),$$$UPPER(pMemberSpec(2))))
				}
				ElseIf (pCount=3) {
					// dim + level
					Set tHierName = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"mbrs",$$$UPPER(pDimName),""))
					If (tHierName'="") {
						Set tLevelName = $G(pMemberSpec(2))
						Set tDimNoInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"mbrs",$$$UPPER(pDimName),$$$UPPER(tHierName)))
					}
				}
				Else {
					Set tHierName = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"mbrs",$$$UPPER(pDimName),""))
					If (tHierName'="") {
						Set tDimNoInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"mbrs",$$$UPPER(pDimName),$$$UPPER(tHierName)))
					}
				}

				If (tDimNoInfo'="") {
					Set tCubeName = $$$UPPER(..cube)
					Set tDimNo = $LG(tDimNoInfo,1)
					Set tHierNo = $LG(tDimNoInfo,2)
					// if we have been given a level name, find its number
					If (tLevelName'="") {
						// dispatch to dimension class
						Set tLevelNo = $classmethod(tDimClass,"%GetLevelNumber",tCubeName,tDimNo,tHierNo,tLevelName)
					}
					Else {
						// use first non-all level
						Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",tDimNo,tHierNo,""),1,tLevelInfo)
						While ((tLevelNo'="")&&($LG(tLevelInfo,1)'="l")) {
							Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",tDimNo,tHierNo,tLevelNo),1,tLevelInfo)
						}
					}
					If (tLevelNo'="") {
						Set tInfo = ""
						// JMD1366: first look in cube global
						Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",tDimNo,tHierNo,tLevelNo,"mbr",""),1,data)
						While (p'="") {
							Set tItemKey = $$$UPPER($LG(data,1))
							Set tItemName = $$$UPPER($LG(data,3))
							Set:tItemName="" tItemName=tItemKey ; // JSL4429, JSL4431 coment out because done at compile time in Generator JSL4432 comment back in since we want to avoid cube recompilation
							Set tItemID = $LG(data,2)
							If ((pUseKey&&(tItemKey=$$$UPPER(pName))||(('pUseKey)&&(tItemName=$$$UPPER(pName))))) { // JSL4429 second test is 'pUseKey
								Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeName)
								Set tItemCaption = $classmethod(tCubeClass,"%GetLevelMemberCaption",tDimNo,tHierNo,tLevelNo,tItemName)
								Set:tItemCaption="" tItemCaption = tItemName
								Set tInfo = $lb(pDimName,tItemCaption,tItemID)
								Quit
							}
							Set p = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",tDimNo,tHierNo,tLevelNo,"mbr",p),1,data)
						}
						If (tInfo="") {
							// dispatch to dimension class
							Set tDimObj = $classmethod(tDimClass,"%Create",tCubeName,"",tDimNo,tHierNo,tLevelNo)
							If '$IsObject(tDimObj) {
								Set pSC = $$$ERROR($$$GeneralError,"Unable to create computed dimension object: " _ tDimClass)
								Quit 0
							}
							Set tFunc = $$$UPPER(pName)
							If ((tFunc = "MEMBERS")||(tFunc = "ALLMEMBERS")||(tFunc = "%TOPMEMBERS")) {
								// Create a set of the members of the calculated dimension
								// do this here so that time folding and other goodies will apply
								// to the members
								Set pIsFunc = 1
								Kill tMemberList
								Set pSC = tDimObj.%GetAllMembers(.tMemberList,tCubeName,tDimNo,tHierNo,tLevelNo)
								If $$$ISERR(pSC) Quit 0

								Set pSet = ##class(%DeepSee.Query.set).%New()
								Set tDimName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(pDimName)

								Set k = $O(tMemberList(""))
								While (k'="") {
									Set tMbrName = $LG(tMemberList(k),2)
									Kill tMemberSpecList
									Set tMemberSpecList($I(tMemberSpecList)) = tDimName
									// + WAL040
									If (pCount=4) {
										// hierarchy
										Set tMemberSpecList($I(tMemberSpecList)) = pMemberSpec(2)
										// level
										Set tMemberSpecList($I(tMemberSpecList)) = pMemberSpec(3)
									}
									// - WAL040
									Set tMemberSpecList($I(tMemberSpecList)) = tMbrName
									Set t = ..%LookupCalculatedMember(.tMemberSpecList,tMemberSpecList,.tSubSet,.pSC)
									If $$$ISERR(pSC) Quit

									Do pSet.children.Insert(tSubSet)
									Set k = $O(tMemberList(k))
								}
								Quit 1
							}
							ElseIf (pUseKey) {
								Set tSC = tDimObj.%FindComputedMemberByKey(pName,.tFlag,.tNAME,.tID)
								If $$$ISERR(tSC) Quit
								If (tFlag) {
									Set tInfo = $lb(pDimName,tNAME,tID)
								}
							}
							Else {
								Set tSC = tDimObj.%FindComputedMemberByName(pName,.tFlag,.tKEY,.tID)
								If $$$ISERR(tSC) Quit
								If (tFlag) {
									Set tInfo = $lb(pDimName,pName,tID)
								}
							}
						}
					}
				}
			}
		}
	}

	If (tInfo'="") {
		// process this member and add it to the local list
		Set tName = $LG(tInfo,2)
		Set tExpr = $LG(tInfo,3)
		Set tFormat = $LG(tInfo,4)
		Set pSet = ##class(%DeepSee.Query.calculatedMember).%New()
		Set pSet.memberName = pName
		Set pSet.originalName = tName
		Set pSet.parentDimension = pDimName
		Set pSet.formatString = tFormat
		Set pSet.origin = "cube"
		Set pSet.definition = tExpr
		Set pSC = ##class(%DeepSee.Query.Parser).%ParseMDXExpression(tExpr,$this,pSet,.tNode)
		If $$$ISERR(pSC) {
			If (pSC'["Error in calculated member expression: ") {
				Set pSC = $$$ERROR($$$GeneralError,"Error in calculated member expression: " _ pName _ $C(13,10) _ $System.Status.GetErrorText(pSC))
			}
			Else {
				Set pSC = $$$ERROR($$$GeneralError,"Error in calculated member expression: " _ pName)
			}
			Quit 0
		}
		If '$IsObject(tNode) {
			Set pSC = $$$ERROR($$$GeneralError,"Pre-defined calculated member is invalid: " _ pName)
			Set pSet = ""
		}
		Else {
			// add to local set
			Set pSet.isResolved = 1
			Do ..calculatedMembers.SetAt(pSet,$$$UPPER(pDimName)_"."_$$$UPPER(pName))
			Quit 1
		}
	}
	ElseIf ('$D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cube),"mbrs",$$$UPPER(pDimName)))) {
		// Test for functions
		// (only if this is a *pure* computed or calculated dimension)

		Set tFunc = $$$UPPER(pName)
		If ((tFunc = "MEMBERS")||(tFunc = "ALLMEMBERS")||(tFunc = "%TOPMEMBERS")) {
			// Create a set of the members of the calculated dimension
			Set pIsFunc = 1
			Set pSC = ..%GetCalculatedMembers(pDimName,.tList)
			If $$$ISERR(pSC) {
				Quit 0
			}

			Set pSet = ##class(%DeepSee.Query.set).%New()
			Set tDimName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(pDimName)

			Set k = $O(tList(""))
			While (k'="") {
				Set tMbrName = ##class(%DeepSee.Query.Parser).%UnquoteIdent(tList(k))
				
				Kill tMemberSpecList
				Set tMemberSpecList($I(tMemberSpecList)) = tDimName
				Set tMemberSpecList($I(tMemberSpecList)) = tMbrName
				Set t = ..%LookupCalculatedMember(.tMemberSpecList,tMemberSpecList,.tSubSet,.pSC)
				If $$$ISERR(pSC) Quit

				Do pSet.children.Insert(tSubSet)
				Set k = $O(tList(k))
			}
			Quit 1
		}
	}
	Quit 0
}

/// Find the list of calculated members in the given dimension.
/// Return a list of their names:
/// pList(UNAME) = name
Method %GetCalculatedMembers(pDimName As %String, ByRef pList As %String) As %Status
{
	Set tSC = $$$OK
	Set tCube = $$$UPPER(..cube)
	Set tDimName = $$$UPPER(pDimName)
	Kill pList

	// first look at cube
	Set tKey = $O($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",tDimName,""))
	While (tKey'="") {
		Set tName = $LG($G($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",tDimName,tKey)),2)
		Set pList($$$UPPER(tName)) = tName
		Set tKey = $O($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",tDimName,tKey))
	}

	// now get members defined in this query
	Set tKey = ""
	Set tSet = ..calculatedMembers.GetNext(.tKey)
	While (tKey '= "") {
		If ($$$UPPER(tSet.parentDimension)=tDimName) {
			Set pList(tSet.memberName) = tSet.originalName
		}
		Set tSet = ..calculatedMembers.GetNext(.tKey)
	}
	Quit tSC
}

/// Add the given subquery to the list of subqueries and return its key (for subsequent lookup).
Method %RegisterSubQuery(pMDX As %String, Output pKey As %Integer, pAxis As axis = "", pSkipWITH As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		// Create a resultSet for the query
		Set tSC = ..%CreateSubQueryResultSet(pMDX,.tRS,pSkipWITH)
		If $$$ISERR(tSC) Quit

		Do ..subqueries.Insert(tRS)
		Set pKey = ..subqueries.Count()

		// also add subquery to axis list
		If ($IsObject(pAxis)) {
			Do pAxis.subqueries.Insert(tRS)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Create and prepare a result set for a subquery within this query.
Method %CreateSubQueryResultSet(pMDX As %String, Output pRS As %DeepSee.ResultSet, pSkipWITH As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		// Create a resultSet for the query
		Set pRS = ##class(%DeepSee.ResultSet).%New()

		// pass on our named parameters to the subquery
		// as well as named sets and members
		Merge tContext = ..%NamedParameters
		Do pRS.%SetParameterContext(.tContext)
		Set pRS.%UseCache = ..useCache

		Set tWITH = ""
		
		Merge tLockKeys = ..%LockKeys		// NB: Passing the multidimensional array property directly into the method only passes the top node!
		Set tSC = pRS.%SetAncestorLockKeys(.tLockKeys)		// DTB943 - Communicate the protected lock keys to the subquery

		If ('pSkipWITH) {
			// DTB821 - Use method which preserves case of member names
			Set tWITHText = ..%WITHToString()
			If tWITHText'="" {
				Set tWITH = "WITH " _ $ZSTRIP(tWITHText,"<W")
			}
		}

		Set pMDX = tWITH _ $S(tWITH="":"",1:" ") _ pMDX
		Set tSC = pRS.%PrepareMDX(pMDX)
		If $$$ISERR(tSC) Quit
		
		// + WAL071 -- Mark this query as subquery
		Set pRS.%Query.parentQueryKey = $S(..parentQueryKey'="":..parentQueryKey,1:..%QueryKey) // WAL071 (2) -- use "root" of subquery tree if exists
		// - WAL071
		
		Set tWITHText = $ZSTRIP($S(..%originalWITHContents'="":..%originalWITHContents,1:..%WITHText),"<>W")		// DTB630
		Set pRS.%Query.parentWITHText = $S(..parentWITHText'="":..parentWITHText,1:tWITHText)	// DTB306 - Record the original WITH text in case it is needed for ordering functions
		
		// +DTB458 - Log the subquery keys in the results global if a related cube is involved
		Set tSubqueryCube = pRS.%CubeKey
		Set tSubqueryKey = pRS.%GetQueryKey()
		If ($G(%cubeIndex)'="") && (tSubqueryCube'=$$$UPPER(%cubeIndex)) && (..%QueryKey'="") && (tSubqueryCube'="") && (tSubqueryKey'="") {
			Set $$$DeepSeeResultsGLVN($$$UPPER(%cubeIndex),..%QueryKey,"subquery",tSubqueryCube,tSubqueryKey) = "(4)"
		}
		// -DTB458
	}
	Catch(ex) {
		Set pRS = ""
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Retrieve a ResultSet from the set of registered subqueries.
Method %GetSubQuery(pKey As %Integer, Output pRS As %DeepSee.ResultSet) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pRS = ..subqueries.GetAt(pKey)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Clear out current statistics for this query.
Method %ClearStatistics()
{
	Kill ..%Statistics
}

/// Write out current statistics for this query.
Method %PrintStatistics()
{
	Set tCubeName = $$$UPPER(..cube)
	Set tCubeIndex = $$$DeepSeeIndex(..cube)

	// copy stats from result global
	Set ..%Statistics("Consolidate") = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","Consolidate"))
	Set ..%Statistics("ExecuteAxes") = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","ExecuteAxes"))		// DP-421530
	Set ..%Statistics("ExecuteCells") = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","ExecuteCells"))
	Set ..%Statistics("BucketsProcessed") = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","BucketsProcessed"))

	Set ..%Statistics("JoinIndexCount") = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","JoinIndexCount"))
	If $D($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","JoinIndexTime")) {
		Set ..%Statistics("JoinIndexTime") = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"stats","JoinIndexTime"))
	}

	// See if there are any outstanding async stats
	Set tExecTaskGroup = $G($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"execTaskGroup"))
	If (tExecTaskGroup'="") {
		Set ..%Statistics("Cells") = $G(..%Statistics("Cells")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"Cells"))
		Set ..%Statistics("Calcs") = $G(..%Statistics("Calcs")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"Calcs"))
		Set ..%Statistics("Computes") = $G(..%Statistics("Computes")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"Computes"))
		Set ..%Statistics("CacheHits") = $G(..%Statistics("CacheHits")) + $G(^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup,"CacheHits"))
		Kill ^IRIS.Temp.DeepSeeUpdate($namespace,tExecTaskGroup)
	}

	// find number of slicer planes
	Set tSlicerCount = 0
	Set tTotalAxisCount = ##class(Engine2).%GetAxisInfo(tCubeIndex,..%QueryKey,.tAxisType,.tAxisKey,.tAxisSize,.tSlicerAxis)
	// JMD1374: sometimes the slicer is treated as a normal 3rd axis
	// check for this;
	If ((tSlicerAxis=0)&&(tTotalAxisCount=3)) {
		Set tSlicerAxis = 3
	}
	If (tSlicerAxis>0) {
		Set tSlicerCount = +$G(tAxisSize(tSlicerAxis))
	}

	Write "Query Statistics:",?31,$S(..showPlan:"PLAN MODE",1:""),!
	Write " Results Cache:",?39,+$G(..%Statistics("ResultsCache")),!
	Write " Query Tasks:",?25,$$FormatCount($G(..%Statistics("BucketsProcessed"))),!
	Write " Computations:",?25,$$FormatCount($G(..%Statistics("Computes"))),!
	Write " Cache Hits:",?25,$$FormatCount($G(..%Statistics("CacheHits"))),!
	Write " Cells:",?25,$$FormatCount($G(..%Statistics("Cells"))),!
	Write " Slices:",?25,$$FormatCount(tSlicerCount),!
	Write " Expressions:",?25,$$FormatCount($G(..%Statistics("Calcs"))),!
	Write " Join Indices:",?25,$$FormatCount($G(..%Statistics("JoinIndexCount"))),!

	If $D($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"keys")) {
		Set tIC = 0
		Write !,"Index Usage:",!
		// show index usage
		Set tKey = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"keys",""))
		While (tKey'="") {
			Set t = $D($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"keys",tKey))
			Set tFactNames=""
			If (tKey '= 0) {
				For f=1:1:$LL(tKey) {
					Set:+$LG(tKey,f) tFactNames = tFactNames _ $S(tFactNames="":"",1:",") _ $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"fact#",f))
				}
				If ((t=1)||(t=11)) {
					Set tIC = tIC + 1
					Write ?2,tIC,?5,"(",tFactNames,")",!
				}
			}
			// measures
			Set tMsr = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"keys",tKey,""))
			While (tMsr'="") {
				Set tMsrName = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"msr#",tMsr))
				Set tIC = tIC + 1
				Write ?2,tIC,?5,"(",tFactNames,$S(tFactNames="":"",1:","),tMsrName,")",!

				Set tMsr = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"keys",tKey,tMsr))
			}

			// next key
			Set tKey = $O($$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"keys",tKey))
		}
	}

	Write !
	Write " Prepare:",?25,$$FormatMS($G(..%Statistics("Prepare"))),!
	Write:$D(..%Statistics("SubQueries")) " Subqueries:",?25,$$FormatMS($G(..%Statistics("SubQueries"))),!
	Write:$D(..%Statistics("JoinIndexTime")) " Join indices:",?25,$$FormatMS($G(..%Statistics("JoinIndexTime"))),!
	Write " Execute Axes:",?25,$$FormatMS($G(..%Statistics("ExecuteAxes"))),!

	Write:$D(..%Statistics("ExecuteAxis 1")) "  Columns:",?25,$$FormatMS($G(..%Statistics("ExecuteAxis 1"))),!
	Write:$D(..%Statistics("CrossJoin 1")) "   Crossjoin:",?25,$$FormatMS($G(..%Statistics("CrossJoin 1"))),!
	Write:$D(..%Statistics("GetMembers 1")) "   Members:",?25,$$FormatMS($G(..%Statistics("GetMembers 1"))),!
	Write:$D(..%Statistics("ExecuteAxis 2")) "  Rows:",?25,$$FormatMS($G(..%Statistics("ExecuteAxis 2"))),!
	Write:$D(..%Statistics("CrossJoin 2")) "   Crossjoin:",?25,$$FormatMS($G(..%Statistics("CrossJoin 2"))),!
	Write:$D(..%Statistics("GetMembers 2")) "   Members:",?25,$$FormatMS($G(..%Statistics("GetMembers 2"))),!

	Write:$D(..%Statistics("ExecuteSlicer")) "  Execute Slicer:",?25,$$FormatMS($G(..%Statistics("ExecuteSlicer"))),!

	Write " Execute Cells:",?25,$$FormatMS($G(..%Statistics("ExecuteCells"))),!
	Write " Consolidate:",?25,$$FormatMS($G(..%Statistics("Consolidate"))),!
	Write " Total Time:",?25,$$FormatMS($G(..%Statistics("Prepare"))+$G(..%Statistics("ExecuteAxes"))+$G(..%Statistics("ExecuteCells"))+$G(..%Statistics("Consolidate"))+$G(..%Statistics("SubQueries"))),!
	Quit

	Set t=""
FormatCount(t)
	Quit $J($FN(t,","),15)

FormatMS(t)
	Quit $J($FN(t*1000,",",3),15)_" ms"
}

/// Evaluate the given named parameter and return its value.
Method %ResolveNamedParm(pParmName As %String, Output pValue As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pValue = ""
		If ((pParmName="")||('$ZName(pParmName))) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid or missing named parameter: "_pParmName)
			Quit
		}

		If ('$D(..%NamedParameters($$$UPPER(pParmName)))) {
			Set tSC = $$$ERROR($$$GeneralError,"Named parameter is not defined: "_pParmName)
			Quit
		}

		// resolve the named parameter
		// first see if a value was supplied when the query was executed:
		If ($D(..%ParameterValues($$$UPPER(pParmName)))) {
			Set pValue = $G(..%ParameterValues($$$UPPER(pParmName)))
		}
		Else {
			Set pValue = $G(..%NamedParameters($$$UPPER(pParmName),"VALUE"))
			// test for code
			// n.b., code cannot be supplied at execute time
			If (($E(pValue,1)="{")&&($E(pValue,*)="}")) {
				New %text
				Set x = "Set %text = "_$E(pValue,2,*-1)
				X x
				Set pValue = %text
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Compute a CRC on the given query axis.<br/
/// This is used to determine if a cached axis is still valid.
ClassMethod %ComputeAxisCRC(pCube As %String, pAxisKey As %String, Output pCRC) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set h = $ZH
		Set pCRC = 0
		Set tCube = $$$UPPER(pCube)
		If $D($$$DeepSeeAxisGLVN(tCube,pAxisKey,"crc"),tCRC) {
			Set pCRC = tCRC
			Quit
		}

		// compute
		Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCube,pAxisKey,"axes",""),1,tNode)
		While (tNodeNo'="") {
			Set tType = $LG(tNode,1)
			Set tName = $LG(tNode,5)
			Set tMbrId = $LG(tNode,6)
			Set tFact = $LG(tNode,7)
			Set pCRC = pCRC + $ZCRC(tNodeNo_tType_tFact_tMbrId_tName,7)
			Set tNodeNo = $O($$$DeepSeeAxisGLVN(tCube,pAxisKey,"axes",tNodeNo),1,tNode)
		}
		
		// save
		Set $$$DeepSeeAxisGLVN(tCube,pAxisKey,"crc") = pCRC
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Combine the results of a set of subqueries against the components of a compound cube.
Method %FoldCompoundQueries() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(..cube)

		// copy over results from 1st subquery.
		Set tSubKey = ..compoundQueries.GetAt(1)
		Set tRS = ..subqueries.GetAt(tSubKey)
		Set tSubCube = $$$UPPER(tRS.%GetCubeName())
		Set tSubQueryKey = tRS.%GetQueryKey()

		// use first subquery to get the shape of the results
		// DTB857 - Preserve calling query information
		Merge tQueryTextInfo = $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"query")
		
		Merge tSubQueryCache = $$$DeepSeeResultsGLVN(tSubCube,tSubQueryKey)
		Kill tSubQueryCache("query")		// DTB857 - Remove the subquery text information
		
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey)			// DTB863 - Leave this in-line since it already manages "query" node
		
		// DTB857 - Merge cache components back into the current cache
		Merge $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey) = tSubQueryCache
		Merge $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"query") = tQueryTextInfo
		
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"cube") = tCubeIndex
		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"query",1) = ..%ToString()

		// DTB857 - Clear these sections after the merge to make sure they are actually empty before continuing
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"data")
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"nonempty")

		Set $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"status") = 50

		// now build a fake bucket list from the intermediate results of the subqueries
		Set tSlotNo = 0
		For n=1:1:..compoundQueries.Count() {
			Set tSubKey = ..compoundQueries.GetAt(n)
			Set tRS = ..subqueries.GetAt(tSubKey)
			Set tSubCube = $$$UPPER(tRS.%GetCubeName())
			Set tSubQueryKey = tRS.%GetQueryKey()

			Set k = $O($$$DeepSeeResultsGLVN(tSubCube,tSubQueryKey,"data",""))
			While (k'="") {
				If (k'=0)&&(k>=-1) {		// DTB481 - Only consider individual results buckets, ie {-1,1,2,3,...,N}. Bucket 0 is built from these.
					Set tSlotNo = tSlotNo + 1
					Set tBucketList(tSlotNo) = tSlotNo
					Merge $$$DeepSeeResultsGLVN(tCubeIndex,..%QueryKey,"data",tSlotNo) = $$$DeepSeeResultsGLVN(tSubCube,tSubQueryKey,"data",k)
				}
				Set k = $O($$$DeepSeeResultsGLVN(tSubCube,tSubQueryKey,"data",k))
			}
		}

		// JMD: if there are any NON EMPTY axes, pass this to Consolidate
		Kill tNonEmptyList
		Merge tNonEmptyList = ..%removeEmpty

		Set tSC = ##class(%DeepSee.Query.Engine).%Consolidate(tCubeIndex,..%QueryKey,.tBucketList,0,.tStats,.tNonEmptyList)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Rewrite this query for use by a leg of a compound query.<br/>
/// <var>pNonEmptyInfo</var> indicates which axes are NON EMPTY; this is because
/// the rewritten query does not have NON EMPTY-- it is applied at the end of the query.
Method %RewriteCompoundQuery(Output pMDX As %String, pPrimaryCube As %String, pSubCube As %String, Output pNonEmptyInfo) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pMDX = ""
		Kill pNonEmptyInfo
		Set tRQuery = ..%New()
		Set tRQuery.cube = pSubCube

		// copy over this query to subquery
		Set tText = ""

		If (..%originalWITHContents'="") {
			// PFS028 - Call RewriteWITH for original WITH
			Set tSC = ..%RewriteWITH(..%originalWITHContents,pPrimaryCube,pSubCube,.tText)
			If $$$ISERR(tSC) Quit
		}
		
		If (##class(%DeepSee.Utils).%IsCubeCompound(..cube)) {
			// DTB630 - A calculated  member defined in the compound cube needs to be passed in as a WITH clause as well.
			Set tCompoundDef = ##class(%DeepSee.Utils).%GetSubjectAreaModel(..cube)
			
			Set tTempText = ""
			
			// Calculated Members
			Set tMbrIdx= ""
			Set tMbr = tCompoundDef.calculatedMembers.GetNext(.tMbrIdx)
			While (tMbrIdx'="") {
				If $$$UPPER(tText)'[$$$UPPER(("["_tMbr.dimension_"].["_tMbr.name_"]")) {
					// Ony add this calculated member if one by the same name does not exist in the query WITH text 
					Set tTempText = tTempText _ " MEMBER ["_tMbr.dimension_"].["_tMbr.name_"] AS '"_tMbr.valueExpression_"'"
					
					If (tMbr.formatString'="") {
						Set tTempText = tTempText _ ",FORMAT_STRING='"_$Replace(tMbr.formatString,"'","''")_"'"
					}
				}
				
				Set tMbr = tCompoundDef.calculatedMembers.GetNext(.tMbrIdx)
			}

			// Named Sets
			Set tSetIdx = ""
			Set tMbr = tCompoundDef.namedSets.GetNext(.tSetIdx)
			While (tSetIdx'="") {
				If $$$UPPER(tText)'[$$$UPPER("SET ["_tMbr.name_"]") {
					// Only add this named set if one by the same name does not exist in the query WITH text 
					Set tTempText = tTempText _ " SET ["_tMbr.name_"] AS '"_tMbr.setExpression_"' "
				}
				
				Set tMbr = tCompoundDef.namedSets.GetNext(.tSetIdx)
			}
			
			If tTempText'="" {
				//PFS028 - Call RewriteWITH for cube-defined Calc Members/Named Sets
				Set tSC = ..%RewriteWITH(tTempText,pPrimaryCube,pSubCube,.tText)
				If $$$ISERR(tSC) Quit
			}
		}

		Set tWITH = ""
		Set:tText'="" tWITH = "WITH"_tText_" "

		// axes
		For a=1:1:..axes.Count() {
			Set tAxis = ..axes.GetAt(a)
			Set:tAxis.nonEmpty pNonEmptyInfo(a) = 1
			Set tSC = ..%RewriteGroup(.tNewGroup,0,pPrimaryCube,pSubCube,tAxis,.tCalcMbrNames)
			If $$$ISERR(tSC) Quit

			Do tRQuery.axes.Insert(tNewGroup) 
		}
		If $$$ISERR(tSC) Quit

		// filters
		For f=1:1:..filters.Count() {
			Set tSC = ..%RewriteGroup(.tNewGroup,1,pPrimaryCube,pSubCube,..filters.GetAt(f),.tCalcMbrNames)
			If $$$ISERR(tSC) Quit
			If ($IsObject(tNewGroup)&&(tNewGroup.children.Count()>0)) {
				Set tNewGroup.context = "filter"		// DP-424293
				Do tRQuery.filters.Insert(tNewGroup) 
			}
		}
		If $$$ISERR(tSC) Quit

		// slicer
		If ($IsObject(..slicer)) {
			Set tSC = ..%RewriteGroup(.tNewGroup,1,pPrimaryCube,pSubCube,..slicer,.tCalcMbrNames)
			If $$$ISERR(tSC) Quit
			// test for empty axis
			If ($IsObject(tNewGroup)&&(tNewGroup.children.Count()>0)) {
				Set tRQuery.slicer = tNewGroup
				Set tRQuery.slicer.context = "filter"		// DP-424293
			}
		}

		#; combine filters with slicer
		If ('$IsObject(tRQuery.slicer) && (tRQuery.filters.Count() = 1)) {
			// simple case
			Set tRQuery.slicer = tRQuery.filters.GetAt(1).%ConstructClone()
			Set tRQuery.slicer.context = "filter"		// DP-424293
		}
		ElseIf (tRQuery.filters.Count() > 0) {
			// fold with slicer
			Set tSC = tRQuery.%CombineFiltersWithSlicer()
			If $$$ISERR(tSC) Quit
		}
		
		If ($IsObject(tRQuery.slicer)) {
			// remove expressions and aggregates from slicer
			Set tSC = tRQuery.%FlattenSlicer(tRQuery.slicer)
			If $$$ISERR(tSC) Quit

			// if nothing left, remove
			If (tRQuery.slicer.children.Count()=0) {
				Set tRQuery.slicer = ""
			}
		}

		Set pMDX = tWITH _ tRQuery.%ToString()
		If +$G(%dsflags("COMPOUND")) {
			$$$DSWRITELN($C(13,10)_">>> COMPOUND SUBQUERY: "_pMDX)    // DTB306
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

Method %RewriteWITH(pWithText As %String, pPrimaryCube As %String, pSubCube As %String, Output pText As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pPrimaryCube)
		
		// DTB630 - Only pass on the contents of the original WITH clause to the subcube.
		Set tTestMDX = "WITH " _ $ZSTRIP(pWithText,"<>W") _ " SELECT FROM [" _ pPrimaryCube _ "]"
		Set tTestRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tTestRS.%PrepareMDX(tTestMDX)
		If $$$ISERR(tSC) Quit
		
		Set tTestQuery = tTestRS.%GetQuery()
		
		// Named sets
		Set tSetName = ""
		Set tSet = tTestQuery.namedSets.GetNext(.tSetName)
		While (tSetName '= "") {
			Set tNamedSets(tSetName) = tSet
			Set tSet = tTestQuery.namedSets.GetNext(.tSetName)
		}
		If ($D(tNamedSets)) {
			Set tSetName = $O(tNamedSets(""))
			While (tSetName '= "") {
				Set tGroup = ##class(%DeepSee.Query.set).%New()
				Do tGroup.children.Insert(tNamedSets(tSetName).children.GetAt(1))

				Set tSC = ..%RewriteGroup(.tNewGroup,0,pPrimaryCube,pSubCube,tGroup)
				If $$$ISERR(tSC) Quit
				Set tBody = tNewGroup.%ToString()

				Set pText = pText _ " SET ["_tSetName_"] AS '"_tBody_"' "
				Set tSetName = $O(tNamedSets(tSetName))
			}
		}

		// calculated members
		Set tMbrName = ""
		Set tMbr = tTestQuery.calculatedMembers.GetNext(.tMbrName)
		While (tMbrName '= "") {
			Set tCalcMbrs(tMbrName) = tMbr
			Set tMbr = tTestQuery.calculatedMembers.GetNext(.tMbrName)
		}

		If ($D(tCalcMbrs)) {
			// JMD911: find caption for calc mbr
			Set tMbrName = $O(tCalcMbrs(""))
			While (tMbrName '= "") {
				Set tMbr = tCalcMbrs(tMbrName)

				// JMD911: find caption for calc mbr
				Set tMbrCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER(tMbr.parentDimension),$$$UPPER(tMbr.memberName))

				// JMD911.2: if no caption, use original name
				If (tMbrCaption="") {
					Set tMbrCaption=tMbr.originalName
					If ($E(tMbrCaption)="[") {
						// unquote
						Set tMbrCaption=$E(tMbrCaption,2,$L(tMbrCaption)-1)
					}
				}

				Set tCalcMbrNames($$$UPPER(tMbr.parentDimension),$$$UPPER(tMbr.memberName)) = tMbrCaption

				Set tGroup = ##class(%DeepSee.Query.set).%New()
				Do tGroup.children.Insert(tMbr.children.GetAt(1))
				Set tSC = ..%RewriteGroup(.tNewGroup,0,pPrimaryCube,pSubCube,tGroup)
				If $$$ISERR(tSC) Quit
				Set tBody = tNewGroup.%ToString()
				// JMD770
				If (tBody'="") {
					Set pText = pText _ " MEMBER ["_tMbr.parentDimension_"].["_tMbrCaption_"] AS '"_tBody_"'"
					If (tMbr.formatString'="") {
						Set pText = pText _ ",FORMAT_STRING='"_$Replace(tMbr.formatString,"'","''")_"'"
					}
					If (+tMbr.solveOrder>0) {
						Set pText = pText _ ",SOLVE_ORDER="_tMbr.solveOrder
					}
				}
				Set tMbrName = $O(tCalcMbrs(tMbrName))
			}
		}
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Rewrite part of a query for use by a compound query.
Method %RewriteGroup(Output pNewGroup As %DeepSee.Query.group, pIsSlicer As %Boolean, pPrimaryCube As %String, pSubCube As %String, pGroup As group, ByRef pCalcMbrNames As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// JMD911 pCalcMbrNames

		Set tCompoundCube = $$$UPPER(..cube)

		Set pNewGroup = $classmethod(pGroup.%ClassName(1),"%New")
		For n = 1:1:pGroup.children.Count() {
			If $$$ISERR(tSC) Quit
			Set tItem = pGroup.children.GetAt(n)
			Set tNewItem = ""

			If (tItem.%IsA("%DeepSee.Query.memberSpec")) {
				// parse spec

				Kill tSpecInfo
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tItem.spec,.tSpecInfo,.tQuoted)
				If $$$ISERR(tSC) Quit

				// names are unquoted
				Set tDim = $$$UPPER($G(tSpecInfo(1)))
				Set tHier = $$$UPPER($G(tSpecInfo(2)))
				Set tLevel = $$$UPPER($G(tSpecInfo(3)))

				If (tDim="MEASURES") {
					Set tFunc = ""
					// make sure measure is in compound cube and base cube
					// if measure has a "sourceCube" then it only applies to that cube

					Set tAllMeasures = 0
					If (pGroup.%IsA("%DeepSee.Query.memberFunction")) {
						If (tHier="") {
							If (($$$UPPER(pGroup.function) = "MEMBERS")||($$$UPPER(pGroup.function) = "ALLMEMBERS")) {
								// special case: loop over measures here
								Set tAllMeasures = 1
								Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"mbrs",tDim,""))
								Set pNewGroup = ##class(%DeepSee.Query.set).%New()
							}
						}
						Else {
							Set pNewGroup = ##class(%DeepSee.Query.set).%New()
							Set tFunc = pGroup.function
						}
					}
					Set tDone = 0
					While ('tDone) {
						If ((tHier="")||('$D($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"mbrs",tDim,tHier)))) {
							Set tSC = $$$ERROR($$$GeneralError,"Measure not found in compound cube: " _ tHier)
							Quit
						}

						// find out what to do with measure
						Set tStrategy = ""

						Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"mbrs",tDim,tHier))
						Set tMInfo = $G($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"mbr#",+$LG(tInfo,1),+$LG(tInfo,2),0))
						Set tSourceCube = $$$UPPER($LG(tMInfo,14))
						Set tMeasureName = tHier
						// JMD1502
						Set tMsrFormat = $LG(tMInfo,12)

						If (tSourceCube'="") {
							If (tSourceCube'=pSubCube) {
								Set tStrategy = "UseNull"
							}
							Set tMeasureName = $LG(tMInfo,3)
						}
						ElseIf ('$D($$$DeepSeeMetaGLVN("cubes",pSubCube,"mbrs",tDim,tHier))) {
							Set tStrategy = "UseNull"
						}
						ElseIf (pIsSlicer) {
							Set tStrategy = "LeaveAlone"
						}

						If (tStrategy="UseCount") {
							Set tNewItem = ##class(%DeepSee.Query.memberSpec).%New()
							Set tNewItem.spec = "[MEASURES].["_tHier_"]"
						}
						ElseIf (tStrategy="LeaveAlone") {
							Set tNewItem = ##class(%DeepSee.Query.memberSpec).%New()
							Set tNewItem.spec = "[MEASURES].["_tHier_"]"
						}
						ElseIf (tStrategy="UseNull") {
							If ('pIsSlicer) {
								// insert %Label() function around special NULL aggregate
								Set tNewItem = ##class(%DeepSee.Query.setFunction).%New("%LABEL")

								Set tCountName = ##class(%DeepSee.Utils).%GetCountName(pSubCube,.tSC)
								If $$$ISERR(tSC) Quit

								Set tArg = ##class(%DeepSee.Query.memberSpec).%New()
								Set tArg.spec = "[MEASURES].["_tCountName_"].NULL"
								Do tNewItem.children.Insert(tArg)

								// lookup caption
								Set tArg = ##class(%DeepSee.Query.constant).%New()
								Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(..cube,tDim,tHier,,.tCaption)
								Set:tCaption="" tCaption = tHier

								Set tArg.value = tCaption
								Do tNewItem.children.Insert(tArg)
								// JMD1502 apply format to measure
								If (tMsrFormat'="") {
									Set tArg = ##class(%DeepSee.Query.constant).%New()
									Set tArg.value = tMsrFormat
									Do tNewItem.children.Insert(tArg)
								}
							}
							Else {
								Set tCountName = ##class(%DeepSee.Utils).%GetCountName(pSubCube,.tSC)
								If $$$ISERR(tSC) Quit

								Set tNewItem = ##class(%DeepSee.Query.memberSpec).%New()
								Set tNewItem.spec = "[MEASURES].["_tCountName_"].NULL"
							}
						}
						ElseIf (tStrategy="Remove") {
							Set tNewItem = ""
						}
						Else {
							// leave in place 
							// insert %Label() function (to keep same shape of axis!)
							Set tNewItem = ##class(%DeepSee.Query.setFunction).%New("%LABEL")
							Set tArg = ##class(%DeepSee.Query.memberSpec).%New()
							Set tArg.spec = "[MEASURES].["_tMeasureName_"]"
							If (tFunc'="") {
								Set tArg.spec = tArg.spec _ "." _ tFunc
							}
							Do tNewItem.children.Insert(tArg)

							// lookup caption
							Set tArg = ##class(%DeepSee.Query.constant).%New()
							Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(..cube,tDim,tHier,,.tCaption)
							Set tArg.value = tCaption
							Do tNewItem.children.Insert(tArg)

							// JMD1502 apply format to measure
							If (tMsrFormat'="") {
								Set tArg = ##class(%DeepSee.Query.constant).%New()
								Set tArg.value = tMsrFormat
								Do tNewItem.children.Insert(tArg)
							}
						}
						If (tAllMeasures) {
							Do pNewGroup.children.Insert(tNewItem)
							Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"mbrs",tDim,tHier))
							If (tHier="") {
								Set tNewItem = ""
								Set tDone=1
							}
						}
						Else {
							Set tDone = 1
						}
					}
					// end of measures
				}
				Else {
					// make sure dimension is in compound cube and base cube
					If ((tDim="")||'$D($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"mbrs",tDim))) {
						Set tSC = $$$ERROR($$$GeneralError,"Dimension not found in compound cube: " _ tDim)
						Quit
					}

					// if 2 dimensions have the same name, then we know they are shared
					// as we test for this at compile time
					If ('$D($$$DeepSeeMetaGLVN("cubes",pSubCube,"mbrs",tDim))) {
						// insert %CUBE() function
						Set tNewItem = ##class(%DeepSee.Query.setFunction).%New("%CUBE")

						// primary cube
						Set tArg = ##class(%DeepSee.Query.constant).%New()
						Set tArg.value = pPrimaryCube
						Do tNewItem.children.Insert(tArg)

						// set
						Set tArg = ##class(%DeepSee.Query.constant).%New()
						If (pGroup.%IsA("%DeepSee.Query.memberFunction")) {
							Set tArg.value = pGroup.%ToString()
							Do tNewItem.children.Insert(tArg)
							Set pNewGroup = tNewItem
							Set tNewItem = ""  
						}
						Else {
							Set tArg.value = tItem.%ToString()
							Do tNewItem.children.Insert(tArg)
						}

						// see if we should use connectsBy to join the cubes
						If $D($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"connectsBy")) {
							Set tSharedDim = $O($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"connectsBy",""))

							While (tSharedDim'="") {
								Set tArg = ##class(%DeepSee.Query.constant).%New()
								Set tArg.value = tSharedDim
								If (tNewItem'="") {
									Do tNewItem.children.Insert(tArg)
								}
								Else {
									Do pNewGroup.children.Insert(tArg)
								}
								Set tSharedDim = $O($$$DeepSeeMetaGLVN("cubes",tCompoundCube,"connectsBy",tSharedDim))
							}
						}
					}
					Else {
						// shared: leave in place
						Set tNewItem = ##class(%DeepSee.Query.memberSpec).%New()
						Set tNewItem.spec = tItem.spec
					}
				}
				// end memberSpec
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.memberFunction")) {
				Set tSC = ..%RewriteGroup(.tNewItem,pIsSlicer,pPrimaryCube,pSubCube,tItem,.pCalcMbrNames)
				If $$$ISERR(tSC) Quit

				If (tNewItem.%IsA("%DeepSee.Query.memberFunction")) {
					Set tNewItem.function = tItem.function
					Set tNewItem.%cmbrQualifier = tItem.%cmbrQualifier
					Set tNewItem.%cmbrMarker = tItem.%cmbrMarker
					Set tNewItem.%cmbrMeasure = tItem.%cmbrMeasure
					Set tNewItem.%cmbrLiteral = tItem.%cmbrLiteral
				}
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.range")) {
				// We have to be careful to get the same shape for the range!
				Set tGroup = ##class(%DeepSee.Query.set).%New()
				Do tGroup.children.Insert(tItem.startMember)
				Set tSC = ..%RewriteGroup(.tNewGroup,pIsSlicer,pPrimaryCube,pSubCube,tGroup,.pCalcMbrNames)
				If $$$ISERR(tSC) Quit
				Set tRangeChild = tNewGroup.children.GetAt(1)


				// JMD899: Test for %CUBE()
				If (tRangeChild.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(tRangeChild.function)="%CUBE")) {
					// JMD899: If there is a %CUBE function, we have to push the range into it:
					// %CUBE(cube,"start:end")
					Set tNewItem = tRangeChild
					// append range to 2nd arg of %CUBE()
					Set tNewItem.children.GetAt(2).value = tNewItem.children.GetAt(2).value _ ":" _ tItem.endMember.%ToString()
				}
				Else {
					Set tNewItem = ##class(%DeepSee.Query.range).%New()
					Set tNewItem.startMember = tRangeChild

					Set tGroup = ##class(%DeepSee.Query.set).%New()
					Do tGroup.children.Insert(tItem.endMember)
					Set tSC = ..%RewriteGroup(.tNewGroup,pIsSlicer,pPrimaryCube,pSubCube,tGroup,.pCalcMbrNames)
					If $$$ISERR(tSC) Quit
					Set tNewItem.endMember = tNewGroup.children.GetAt(1)
				}
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.setFunction")) {
				// JMD912: we can't use NONEMPTY CJ in subquery
				// because each branch must have the same members
				If ($$$UPPER(tItem.function) = "NONEMPTYCROSSJOIN")  {
					Set tItem.function = "CROSSJOIN"
				}
				Set tSC = ..%RewriteGroup(.tNewItem,pIsSlicer,pPrimaryCube,pSubCube,tItem,.pCalcMbrNames)
				If $$$ISERR(tSC) Quit
				Set tNewItem.function = tItem.function
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.expression")) {
				Set tSC = ..%RewriteGroup(.tNewItem,pIsSlicer,pPrimaryCube,pSubCube,tItem,.pCalcMbrNames)
				If $$$ISERR(tSC) Quit
				Set tNewItem.operator = tItem.operator
				Set tNewItem.isScalarFunction = tItem.isScalarFunction
				Set tNewItem.scalarArgCount = tItem.scalarArgCount
				Set tNewItem.label = tItem.label
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.constant")) {
				Set tNewItem = tItem.%ConstructClone()
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.flag")) {
				Set tNewItem = tItem.%ConstructClone()
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.calculatedMember")) {
				// calc member is already rewritten in WITH clause
				Set tNewItem = tItem.%ConstructClone()
				// JMD911: use correct name
				If ((tNewItem.parentDimension'="")&&(tNewItem.memberName'="")) {
					If ($D(pCalcMbrNames($$$UPPER(tNewItem.parentDimension),$$$UPPER(tNewItem.memberName)))) {
						Set tNewItem.memberName = pCalcMbrNames($$$UPPER(tNewItem.parentDimension),$$$UPPER(tNewItem.memberName))
					}
				}
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.namedSet")) {
				// set is already rewritten in WITH clause
				Set tNewItem = tItem.%ConstructClone()
			}
			ElseIf (tItem.%IsA("%DeepSee.Query.group")) {
				Set tSC = ..%RewriteGroup(.tNewItem,pIsSlicer,pPrimaryCube,pSubCube,tItem,.pCalcMbrNames)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Unhandled type in %RewriteGroup "_tItem.%ClassName())
				Quit
			}
			Do:tNewItem'="" pNewGroup.children.Insert(tNewItem)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the RFC 1766 code of the current language.
/// Used to ensure that cached values preserve localization.
ClassMethod %GetLanguage() As %String [ Internal ]
{
	// JMD998
	Set tLang = ""
	If $IsObject($G(%session)) {
		Set tLang = %session.Language
	}
	Set:tLang="" tLang = $$$DefaultLanguage

	// JMD1215: save cache space by folding enus with en!
	Set:tLang="en-us" tLang="en"

	// JMD1012 (remove - from lang)
	Quit $TR(tLang,"-","")
}

/// See if a time range can be compressed into smaller units.
Method %CompressTimeRange(pNode As %DeepSee.Query.range) As %DeepSee.Query.node [ Internal ]
{
	Set tTerm = pNode

	// see if this is a candidate for date compression
	// must be a time dimension with year,month,and day levels

	// preprocess to get member information
	Set tSC = tTerm.%PreProcess(1)
	If $$$ISERR(tSC) Quit tTerm

	If ($IsObject(tTerm.%member)&&(tTerm.%member.%IsA("%DeepSee.Query.memberTime"))) {
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		Set tDimNo = tTerm.%member.%dimNumber
		Set tHierNo = tTerm.%member.%hierNumber
		Set tLevelNo = tTerm.%member.%levelNumber
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
		Set tTimeClass = $LG(tInfo,6)
		Set tDimName = $LG(tInfo,2)
		Set tHierName = $LG(tInfo,3)
		
		Set tTimeClassType = ##class(%DeepSee.Utils).%GetTimeLevelType(tTimeClass) // + WAL133
		Set tTimeClassCalendar = ##class(%DeepSee.Utils).%GetTimeLevelCalendar(tTimeClass) // + WAL134
				
		If (tTimeClassType="day") {
			// check upper levels
			Set tDayName = $LG(tInfo,4)
			Set tYearLevel = "",tYearName=""
			Set tMonthLevel = "",tMonthName=""
			For tl=tLevelNo:-1:1 {
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tl))
				Set tTimeClass = $LG(tInfo,6)
				Set tTimeClassType = ##class(%DeepSee.Utils).%GetTimeLevelType(tTimeClass) // + WAL133
				If ((tYearLevel="")&&(tTimeClassType="year")) {       // + WAL133
					Set tYearLevel = tl
					Set tYearName = $LG(tInfo,4)
				}
				If ((tMonthLevel="")&&(tTimeClassType="month")) {     // + WAL133
					Set tMonthLevel = tl
					Set tMonthName = $LG(tInfo,4)
				}
			}

			If ((tYearLevel'="")&&(tMonthLevel'="")) {
				// see if we can compress into ranges
				If (..%SplitDateRange(tTerm.startMember.%member.%memberKey,tTerm.endMember.%member.%memberKey,.tCompressedRange, tTimeClassCalendar)) { // + WAL134
					// convert ranges to set of ranges
					Set tSet = ##class(%DeepSee.Query.set).%New()
					Set k=$O(tCompressedRange(""))
					While (k'="") {
						Set tRUnit = $LG(tCompressedRange(k),1)
						Set tRStart = $LG(tCompressedRange(k),2)
						Set tREnd = $LG(tCompressedRange(k),3)
						If (tRUnit="year") {
							If (tRStart=tREnd) {
								Set tRSpec = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec.spec = "["_tDimName_"].["_tHierName_"].["_tYearName_"].&["_tRStart_"]"
								Do tSet.children.Insert(tRSpec)
							}
							Else {
								Set tRFunc = ##class(%DeepSee.Query.setFunction).%New("%OR")
								Set tRRange = ##class(%DeepSee.Query.range).%New()
								Set tRSpec1 = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec1.spec = "["_tDimName_"].["_tHierName_"].["_tYearName_"].&["_tRStart_"]"
								Set tRSpec2 = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec2.spec = "["_tDimName_"].["_tHierName_"].["_tYearName_"].&["_tREnd_"]"
								Set tRRange.startMember = tRSpec1
								Set tRRange.endMember = tRSpec2
								Do tRFunc.children.Insert(tRRange)
								Do tSet.children.Insert(tRFunc)
							}
						}
						ElseIf (tRUnit="month") {
							If (tRStart=tREnd) {
								Set tRSpec = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec.spec = "["_tDimName_"].["_tHierName_"].["_tMonthName_"].&["_tRStart_"]"
								Do tSet.children.Insert(tRSpec)
							}
							Else {
								Set tRFunc = ##class(%DeepSee.Query.setFunction).%New("%OR")
								Set tRRange = ##class(%DeepSee.Query.range).%New()
								Set tRSpec1 = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec1.spec = "["_tDimName_"].["_tHierName_"].["_tMonthName_"].&["_tRStart_"]"
								Set tRSpec2 = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec2.spec = "["_tDimName_"].["_tHierName_"].["_tMonthName_"].&["_tREnd_"]"
								Set tRRange.startMember = tRSpec1
								Set tRRange.endMember = tRSpec2
								Do tRFunc.children.Insert(tRRange)
								Do tSet.children.Insert(tRFunc)
							}
						}
						Else {
							If (tRStart=tREnd) {
								Set tRSpec = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec.spec = "["_tDimName_"].["_tHierName_"].["_tDayName_"].&["_tRStart_"]"
								Do tSet.children.Insert(tRSpec)
							}
							Else {
								Set tRFunc = ##class(%DeepSee.Query.setFunction).%New("%OR")
								Set tRRange = ##class(%DeepSee.Query.range).%New()
								Set tRSpec1 = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec1.spec = "["_tDimName_"].["_tHierName_"].["_tDayName_"].&["_tRStart_"]"
								Set tRSpec2 = ##class(%DeepSee.Query.memberSpec).%New()
								Set tRSpec2.spec = "["_tDimName_"].["_tHierName_"].["_tDayName_"].&["_tREnd_"]"
								Set tRRange.startMember = tRSpec1
								Set tRRange.endMember = tRSpec2
								Do tRFunc.children.Insert(tRRange)
								Do tSet.children.Insert(tRFunc)
							}
						}
						Set k=$O(tCompressedRange(k))
					}
					Set tTerm = tSet
				}
			}
		}
	}
	Quit tTerm
}

/// Given a start and end of a date range, return a set of ranges that cover the original
/// range with as few members as possible. The higher level units are months and years.
/// Return an array of ranges:<br/>
/// pRange(n) = $LB("day|month|year",start,end)<br/>
ClassMethod %SplitDateRange(pStartDate As %Date, pEndDate As %Date, Output pRange, pCalendar As %String = "gregorian") As %Boolean [ Internal ]
{
	
	// + WAL134 -- this method implements the logic for grouping dates
	//             all direct $ZDT and $ZDTH calls are in methods called from here
	Kill pRange	
	If ((pStartDate>=pEndDate)||(pStartDate="")||(pEndDate="")) {
		Quit 0
	}
	// + WAL134
	Do ..%SplitDate(pStartDate,pCalendar,.tStartY,.tStartM,.tStartD)
	Do ..%SplitDate(pEndDate,pCalendar,.tEndY,.tEndM,.tEndD)
	// - WAL134
	
	// split into pre-days, mid months, and post-days
	// convert to canonic months
	Set tStartMonths = (tStartY*12)+(tStartM-1)
	If (tStartD>1) {
		Set tStartMonths = tStartMonths + 1
		Set tPreStart = pStartDate
		Set tPreEnd = ..%GetLastDayHorolog(tStartY,tStartM,pCalendar)
	}
	Set tEndMonths = (tEndY*12)+(tEndM-1)
	If (tEndD<..%GetLastDay(tEndY,tEndM,pCalendar)) {
		Set tEndMonths = tEndMonths - 1
		Set tPostStart = ..%GetFirstDayHorolog(tEndY,tEndM,pCalendar)
		Set tPostEnd = +pEndDate
	}
	If $D(tPreStart) {
		Set pRange($I(pRange)) = $LB("day",tPreStart,tPreEnd)
	}

	If ((tEndMonths-tStartMonths) >= 0) {
		// compress months into years
		Set tMidStartYear = tStartMonths\12
		Set tMidStartMonth = (tStartMonths#12)+1
		Set tMidEndYear = tEndMonths\12
		Set tMidEndMonth = (tEndMonths#12)+1

		If ((tMidStartMonth=1)&&(tMidEndMonth=12)) {
			// years only
			Set pRange($I(pRange)) = $LB("year",tMidStartYear,tMidEndYear)
		}
		ElseIf (((tMidEndYear-tMidStartYear)>=1)&&(tMidStartMonth=1)) {
			// year plus some months
			Set pRange($I(pRange)) = $LB("year",tMidStartYear,tMidEndYear-1)
			Set pRange($I(pRange)) = $LB("month",tMidEndYear_"01",tMidEndYear_$$$iscPadZero(tMidEndMonth,2))
		}
		ElseIf (((tMidEndYear-tMidStartYear)>=1)&&(tMidEndMonth=12)) {
			// some months then year
			Set pRange($I(pRange)) = $LB("month",tMidStartYear_$$$iscPadZero(tMidStartMonth,2),tMidStartYear_"12")
			Set pRange($I(pRange)) = $LB("year",tMidStartYear+1,tMidEndYear)
		}
		ElseIf ((tMidEndYear-tMidStartYear)>1) {
			// months, years, months
			Set pRange($I(pRange)) = $LB("month",tMidStartYear_$$$iscPadZero(tMidStartMonth,2),tMidStartYear_"12")
			Set pRange($I(pRange)) = $LB("year",tMidStartYear+1,tMidEndYear-1)
			Set pRange($I(pRange)) = $LB("month",tMidEndYear_"01",tMidEndYear_$$$iscPadZero(tMidEndMonth,2))
		}
		Else {
			Set pRange($I(pRange)) = $LB("month",tMidStartYear_$$$iscPadZero(tMidStartMonth,2),tMidEndYear_$$$iscPadZero(tMidEndMonth,2))
		}
		
		// tack on last range
		If $D(tPostStart) {
			Set pRange($I(pRange)) = $LB("day",tPostStart,tPostEnd)
		}
	}
	Else {
		// do nothing
		Kill pRange
		Quit 0
	}

	// debug
	/*
	Set k = $O(pRange(""))
	While (k'="") {
		Set tUnit = $LG(pRange(k),1)
		Set tStart = $LG(pRange(k),2)
		Set tEnd = $LG(pRange(k),3)
		If (tUnit="year") {
			W k,?10,tUnit,?20,tStart,?35,tEnd,!
		}
		ElseIf (tUnit="month") {
			W k,?10,tUnit,?20,tStart,?35,tEnd,!
		}
		Else {
			W k,?10,tUnit,?20,$P($ZDT(tStart,3)," "),?35,$P($ZDT(tEnd,3)," "),!
		}
		Set k = $O(pRange(k))
	}
	*/
	Quit 1
}

/// Return the last day (number) of the given year and month.
ClassMethod %GetLastDay(pYear As %Integer, pMonth As %Integer, pCalendar As %String) As %Integer [ Internal ]
{
	// + WAL134
	If ($$$UPPER(pCalendar)["HIJRI") {
		Quit ##class(%DeepSee.Utils).%HijriDaysInMonth(pYear,pMonth,pCalendar)	
	}
	
	// Otherwise gregorian dates
	If (pMonth=12) {
		Quit 31
	}
	Set tDate = $ZDT($ZDTH(pYear_"-"_$$$iscPadZero(pMonth+1,2)_"-01",3)-1,3)
	Quit +$E(tDate,9,10)
}

/// Return the last day (number) of the given year and month.
ClassMethod %GetLastDayHorolog(pYear As %Integer, pMonth As %Integer, pCalendar As %String = "gregorian") As %Integer [ Internal ]
{
	// Method Added by WAL134
	If ($$$UPPER(pCalendar)["HIJRI") {
		Set tLastDayInMonth = ##class(%DeepSee.Utils).%HijriDaysInMonth(pYear,pMonth,pCalendar)	
		Set tDate = tLastDayInMonth_" "_pMonth_" "_pYear
		If ($$$UPPER(pCalendar)["HIJRITABULAR") {
			Quit +$ZDTH(tDate,19)
		}
		ElseIf ($$$UPPER(pCalendar)["HIJRIOBSERVED") {
			Quit +$ZDTH(tDate,21)
		}
	}
	
	// Gregorian
	Quit +$ZDTH(pYear_"-"_$$$iscPadZero(pMonth,2)_"-"_$$$iscPadZero(..%GetLastDay(pYear,pMonth,pCalendar),2),3)
}

ClassMethod %GetFirstDayHorolog(pYear As %Integer, pMonth As %Integer, pCalendar As %String = "gregorian") As %Integer [ Internal ]
{
	// Method Added by WAL134
	If ($$$UPPER(pCalendar)["HIJRITABULAR") {	
		Set tDate = "1 "_pMonth_" "_pYear
		Quit +$ZDTH(tDate,19)
	}
	ElseIf ($$$UPPER(pCalendar)["HIJRIOBSERVED") {	
		Set tDate = "1 "_pMonth_" "_pYear
		Quit +$ZDTH(tDate,21)
	}
	
	// Gregorian
	Quit +$ZDTH(pYear_"-"_$$$iscPadZero(pMonth,2)_"-01",3)
}

/// Return the last day (number) of the given year and month.
ClassMethod %SplitDate(pDate As %Date, pCalendar As %String = "gregorian", Output pYear, Output pMonth, Output pDay) As %Status [ Internal ]
{
	// Method Added by WAL134
	// Take date and calendar and dump stuff out
	If ($$$UPPER(pCalendar) = "GREGORIAN") {
		Set tDate = $ZDT(pDate,3)
		Set pYear = +$E(tDate,1,4)
		Set pMonth = +$E(tDate,6,7)
		Set pDay = +$E(tDate,9,10)	
	}
	ElseIf ($$$UPPER(pCalendar) = "HIJRITABULAR") {
		Set tDate = $ZDT(pDate,19)
		Set pYear = +$P(tDate," ",3)
		Set pMonth = +$P(tDate," ",2)
		Set pDay = +$P(tDate," ",1)
	}
	ElseIf ($$$UPPER(pCalendar) = "HIJRIOBSERVED") {
		Set tDate = $ZDT(pDate,21)
		Set pYear = +$P(tDate," ",3)
		Set pMonth = +$P(tDate," ",2)
		Set pDay = +$P(tDate," ",1)
	}
}

/// Rewrite a group and rewrite any SUM(timeRange) as SUM(foldedTimeRange).
/// Also applies to %OR().
Method %RewriteForTimeFolding(pParentGroup As %DeepSee.Query.group, pGroup As %DeepSee.Query.group, Output pNewGroup As %DeepSee.Query.group, pLevel As %Integer = 0) As %Status [ Internal ]
{
	// JMD1116
	Set tSC = $$$OK

	Try {
		Set pNewGroup = ""
		Set tWrapper = ""
		If (pGroup.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(pGroup.function)="SUM")&&$IsObject(pGroup.children.GetAt(1))&&pGroup.children.GetAt(1).%IsA("%DeepSee.Query.range")) {
			// aggregate
			Set tChild1 = pGroup.children.GetAt(1)
			Set tTerm = ..%CompressTimeRange(tChild1)
			If (tTerm'=tChild1) {
				// replace this child
				Do pGroup.children.SetAt(tTerm,1)
			}
		}
		ElseIf (pGroup.%IsA("%DeepSee.Query.setFunction")&&($$$UPPER(pGroup.function)="%OR")&&(pGroup.children.Count()=1)&&($IsObject(pGroup.children.GetAt(1)))&&pGroup.children.GetAt(1).%IsA("%DeepSee.Query.range")) {
			// %OR
			Set tChild1 = pGroup.children.GetAt(1)
			Set tTerm = ..%CompressTimeRange(tChild1)
			If (tTerm'=tChild1) {
				// + WAL061 -- Don't use aggregate for %BITSET query, just use the folded %OR set
				If (..queryType="%BITSET") {
					Do pGroup.children.SetAt(tTerm,1)
				}
				// - WAL061
				Else {
					// replace %OR(range) with %OR(set)
					Set pNewGroup = ##class(%DeepSee.Query.setFunction).%New("%OR")
					Set pNewGroup.label = "Range"
					Do pNewGroup.children.Insert(tTerm)
				}
			}
		}
		Else {
			// keep going
			Set tCount = pGroup.children.Count()
			For a = 1:1:tCount {
				Set tChild = pGroup.children.GetAt(a)
				If (tChild.%IsA("%DeepSee.Query.group")) {
					Kill tNewChild
					Set tSC = ..%RewriteForTimeFolding(pGroup,tChild,.tNewChild,pLevel+1)
					If $$$ISERR(tSC) Quit
					If $IsObject(tNewChild) {
						// replace this child
						Do pGroup.children.SetAt(tNewChild,a)
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method.
/// Try to find the dimension info assoiciated with the provided query object.
Method %FindMemberInfo(pNode As %DeepSee.Query.node, Output pMember As %DeepSee.Query.member) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// JMD1196
		Set pMember = ""
		// Try to find a member spec
		Set tNode = pNode
		While ($IsObject(tNode)&&('tNode.%IsA("%DeepSee.Query.memberSpec"))) {
			If (tNode.%IsA("%DeepSee.Query.group")) {
				Set tNode = tNode.children.GetAt(1)
			}
			Else {
				Set tNode = ""
			}
		}

		// pre-process spec now to get info
		// note: this method is never called on the slicer
		If ($IsObject(tNode)&&(tNode.%IsA("%DeepSee.Query.memberSpec"))) {
			Set tSC = tNode.%PreProcess()
			If $$$ISERR(tSC) Quit

			Set pMember = tNode.%member
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility Method. Determine whether the current node can be considered a measure.
/// Returns:
/// "cell" 	- This node is a spreadsheet function and is exempt
/// 1 		- This node functions as a measure
/// 0 		- This node does not function as a measure
ClassMethod %IsMeasure(pNode As %DeepSee.Query.node, Output pStatus) As %String [ Internal ]
{
	Set tIsMeasure = 0
	Set pStatus = $$$OK
	Set tMeasureFuncTypes("MX") = ""
	Set tMeasureFuncTypes("ST") = ""
	Set tMeasureFuncTypes("V") = ""
	Set tMeasureFuncTypes("I") = ""
	Try {			
		// DTB074 - Treat as measures:
		// - simple measures
		// - calculated measures
		// - raw expressions
		// - aggregate functions
		// - sets containing only measures
		// - measures renamed using %LABEL
		// - functions which use their own measures to return a number
		
		If pNode.%IsA("%DeepSee.Query.function") {
			// DTB125 - Test the return type of a function node for a measure-like return.
			Set tFunctionU = $$$UPPER(pNode.function)
			Do pNode.%GetFunctionInfo(tFunctionU,.tIsImplemented,.tArgCount,.tReturnType,.tArgTypes)
			
			// DTB153 - Test memberFunctions first, then move on to setFunctions
			// Specific functions are treated first, then classes
			If pNode.%IsA("%DeepSee.Query.memberFunction") {
				If (tFunctionU="CURRENTMEMBER")&&($$$UPPER(pNode.%cmbrQualifier)["PROPERTIES") {
					// This is measure-like behavior
					Set tIsMeasure = 1
					Quit	
				}
				Else {
					// All other memberFunctions return members
					Quit
				}
			}
			ElseIf (tFunctionU["%CELL") {
				// DTB153 - Spreadsheet functions are a special exemption
				Set tIsMeasure = "cell"
				Quit
			}
			ElseIf (tFunctionU="%TERMLIST")||(tFunctionU="%CUBE") {
				// These get a pass, no way to tell before they are resolved!
				Quit
			}
			ElseIf (tFunctionU="%LABEL") {
				// DTB144 - Recurse into the label to make a choice based on what it is renaming (first child)
				Set tIsMeasure = ..%IsMeasure(pNode.children.GetAt(1))
				Quit
			}
			ElseIf (tFunctionU="%SPACE") {
				// DTB399 - This is not a measure
				Quit
			}
			ElseIf tIsImplemented&&
					(tReturnType'="")&&
					$D(tMeasureFuncTypes(tReturnType)) {
				If (($LG(tArgTypes,1)="M")||($LG(tArgTypes,1)="S"))&&
					($LG(tArgTypes,2)'="F") {
					// DTB153 - Some aggregation functions which return numbers are exempt 
					// if they do not define their own measure. Check the measure argument.
					If (tArgCount=1)&&($LG(tArgTypes,2)="E") {
						Set tExpression = pNode.children.GetAt(2)
						Set tIsMeasure = ..%IsMeasure(tExpression)
						Quit
					}
					ElseIf (tArgCount=2)&&($LG(tArgTypes,3)="E") {
						Set tExpression = pNode.children.GetAt(3)
						Set tIsMeasure = ..%IsMeasure(tExpression)
						Quit
					}
				}
				Else {
					// No specific reason to exempt this setFunction
					Set tIsMeasure = 1
					Quit
				}
			}
			ElseIf (tReturnType="S") {
				// DTB153 - Refine exemptions within the set functions that return sets
				If (tFunctionU["CROSSJOIN")||(tFunctionU="UNION") {		
					// DTB125 - Add case to check individual CROSSJOINS for measures. 
					Set tChild1 = pNode.children.GetAt(1)
					Set tChild2 = pNode.children.GetAt(2)
					
					If ('$IsObject(tChild1)||'$IsObject(tChild2)) {
						// JMD1045: avoid OREF error
						Quit
					}
					
					// Report error of crossjoin between two measures
					Set tChild1IsMeasure = ..%IsMeasure(tChild1,.pStatus)
					If $$$ISERR(pStatus) Quit
					Set tChild2IsMeasure = ..%IsMeasure(tChild2,.pStatus)
					If $$$ISERR(pStatus) Quit
					
					If (tFunctionU["CROSSJOIN")&&(tChild1IsMeasure&&tChild2IsMeasure) {
						Set pStatus = $$$ERROR($$$GeneralError,"Two measures cannot be crossjoined")
						Quit
					} 
					ElseIf (tChild1IsMeasure||tChild2IsMeasure) {
						// Note that the resulting set acts like a measure
						Set tIsMeasure = 1
						Quit
					}
				}
				ElseIf ($LG(tArgTypes,1)="L")||($LG(tArgTypes,1)="M") {
					// These will always treturn members
					Quit
				}
				ElseIf ($LG(tArgTypes,1)="S") {
					// See if the setFunction is called on a measure
					Set tIsMeasure = ..%IsMeasure(pNode.children.GetAt(1))
					If ($LG(tArgTypes,2)="S") {
						// DTB153 - this is the EXCEPT and INTERCEPT case. If one set is a measure and one is not,
						// there will be no results. No need to block that at this stage
						Set tIsMeasure = tIsMeasure && ..%IsMeasure(pNode.children.GetAt(2))
					}
					Quit
				}
			}
			ElseIf (tReturnType="M") {
				// None of the set functions with member return types can return measures
				Quit
			}
			Else {
				// No specific reason to call this function a measure
				Quit
			}
		} 
		
		// Proceed with more tests on non-functions
		If pNode.%IsA("%DeepSee.Query.set")&&pNode.children.Count() {  // DTB153 - skip empty sets
			If pNode.%IsA("%DeepSee.Query.tuple") {
				// DTB125 - This acts like a crossjoin, only one item can be a measure
				For ii=1:1:pNode.children.Count() {
					Set tIsMeasure = tIsMeasure + ..%IsMeasure(pNode.children.GetAt(ii))
				}	
				If (tIsMeasure>1) {
					Set pStatus = $$$ERROR($$$GeneralError,"Two measures cannot exist in a tuple")
					Quit
				}
			}
			Else {
				// DTB153 - This is a set. Recurse and flag it as a measure if any of its 
				// items are measures
				For ii=1:1:pNode.children.Count() {
					Set tIsMeasure = tIsMeasure || ..%IsMeasure(pNode.children.GetAt(ii))
				}	
			}
		}
		ElseIf pNode.%IsA("%DeepSee.Query.memberSpec") {
			// Test to see if this is a simple measure
			Set pStatus = ..%GetMeasureFromSpec(pNode.spec,.tMeasure)
			If $$$ISERR(pStatus) Quit 
			Set tIsMeasure = (tMeasure'="")
		} 
		ElseIf (pNode.%IsA("%DeepSee.Query.calculatedMember")) {
			If (pNode.parentDimension="MEASURES") {
				Set tIsMeasure = 1
				Quit
			}
			Else {
				// Recurse to test the contents of the calculated member
				Set tIsMeasure = ..%IsMeasure(pNode.children.GetAt(1))
				Quit
			}
		}
		ElseIf pNode.%IsA("%DeepSee.Query.expression") { 
			// This returns a number, but it may be derived from spreadsheet functions.
			// Check both arguments of the expression and allow this only if spreadsheet functions are involved
			Set tArg1IsMeasure = ..%IsMeasure(pNode.children.GetAt(1))
			Set tArg2IsMeasure = ..%IsMeasure(pNode.children.GetAt(2))
			
			If (tArg1IsMeasure="cell")||(tArg2IsMeasure="cell") {
				Set tIsMeasure = "cell"
				Quit
			}
			Else {
				// Expressions are generally measures.
				Set tIsMeasure = 1
				Quit
			}
		} 
		ElseIf pNode.%IsA("%DeepSee.Query.constant") { 
			If (pNode.value="") {
				// This is a placeholder, ignore it
				Quit
			}
			Else {
				// A number is a measure
				Set tIsMeasure = 1
				Quit
			}
		}
		Else {
			Quit 
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tIsMeasure
}

/// Utility Method. Determine whether the current node can be considered a member
ClassMethod %IsMember(pNode As %DeepSee.Query.node, Output pStatus) As %Boolean [ Internal ]
{
	Set tIsMember = 0
	Set pStatus = $$$OK		// DTB125
	Set tMemberFuncTypes("M") = ""
	Set tMemberFuncTypes("S") = ""
	Try {			
		// DTB078 - Treat as members:
		// - simple members
		// - %OR
		// - sets containing only members
		// - members renamed using %LABEL
		// - functions that return members
		If ..%IsMeasure(pNode,.pStatus) {
			// DTB153 - A node cannot be considered both a measure and a member
			Quit
		}
		If $$$ISERR(pStatus) Quit
		
		If pNode.%IsA("%DeepSee.Query.function") {
			// DTB125 - Test the return type of a function node for a member return 
			Set tFunctionU = $$$UPPER(pNode.function)
			Do pNode.%GetFunctionInfo(tFunctionU,.tIsImplemented,.tArgCount,.tReturnType,.tArgTypes)
			
			If pNode.%IsA("%DeepSee.Query.memberFunction") {
				If (tFunctionU="CURRENTMEMBER")&&($$$UPPER(pNode.%cmbrQualifier)["PROPERTIES") {
					// This is measure-like behavior
					Quit	
				}
				Else {
					// All other memberFunctions return members
					Set tIsMember = 1
					Quit
				}
			}
			ElseIf (tReturnType ="M") {
				// This function returns a member
				Set tIsMember = 1
				Quit
			}
			ElseIf (tFunctionU="%LABEL") {
				// DTB144 - Recurse into the label to make a choice based on what it is renaming (first child)
				Set tIsMember = ..%IsMember(pNode.children.GetAt(1))
				Quit
			} 
		} 
		
		// Proceed with more specific tests
		If pNode.%IsA("%DeepSee.Query.memberSpec") {
			// Test to make sure this is not a measure
			Set pStatus = ..%GetMeasureFromSpec(pNode.spec,.tMeasure)
			If $$$ISERR(pStatus) Quit 
			Set tIsMember = (tMeasure="")
		} 
		ElseIf ( pNode.%IsA("%DeepSee.Query.set") || 
			pNode.%IsA("%DeepSee.Query.calculatedMember") ) {
			// This is a set - recurse to make sure all of its items are members
			Set tIsMember = 1
			For ii=1:1:pNode.children.Count() {
				Set tIsMember = tIsMember && ..%IsMember(pNode.children.GetAt(ii))
			}	
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.range")) {
			// DTB364 - Ranges are sets of members
			Set tIsMember = 1
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	Quit tIsMember
}

/// Test for an existence of a measure in <var>pNode</var>.
ClassMethod %HasMeasure(pNode As %DeepSee.Query.node, ByRef pStatus As %Status) As %Boolean [ Internal ]
{
	// Method added by DTB125
	Set pStatus = $$$OK
	Set tHasMeasure = 0
	Set tMemberFuncTypes("M") = ""
	Set tMemberFuncTypes("S") = ""
	Try {
		If pNode.%IsA("%DeepSee.Query.axis") {
			// Test the axis contents
			Set tHasMeasure = ..%IsMeasure(pNode.children.GetAt(1))
		}
		ElseIf (..%IsMeasure(pNode,.pStatus)) {
			Set tHasMeasure = 1
			Quit
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	Quit tHasMeasure
}

/// Utility method to test for related cube terms in a %DeepSee.Query.node object
ClassMethod %HasRelations(pCube, pNode As %DeepSee.Query.node, ByRef pStatus As %Status) As %Boolean
{
	Set pStatus=$$$OK
	Try{
		//%DeepSee.Query.memberSpec is the only type of DeepSee query runtime object that could be from a related cube
		If pNode.%IsA("%DeepSee.Query.memberSpec"){ 
			d ##class(%DeepSee.Utils).%GetDimensionInfo(pCube, pNode.spec,,,,.relationName)
			Return:relationName'="" 1
		}
		ElseIf (pNode.%IsA("%DeepSee.Query.constant")) || (pNode.%IsA("%DeepSee.Query.flag")){
			Return 0
		}
		ElseIf pNode.%IsA("%DeepSee.Query.range"){
			Return ..%HasRelations(pCube, pNode.startMember, .pStatus) || ..%HasRelations(pCube, pNode.endMember, .pStatus)
		}
		ElseIf pNode.%IsA("%DeepSee.Query.query"){
			Set axisCount=pNode.axes.Count()
			For i=1:1:axisCount{
				Set tAxis = pNode.axes.GetAt(i)
				If ..%HasRelations(pCube, tAxis, .pStatus){
					Return 1
				}
			}
			If $IsObject(pNode.filterAxis){
				If ..%HasRelations(pCube, pNode.filterAxis, .pStatus){
					Return 1
				}
			}
			If $IsObject(pNode.slicer){
				If ..%HasRelations(pCube, pNode.slicer, .pStatus){
					Return 1
				}
			}
		}
		ElseIf pNode.%IsA("%DeepSee.Query.group"){
			Set childCount=pNode.children.Count()
			For i=1:1:childCount{
				Set tChild = pNode.children.GetAt(i)
				If ..%HasRelations(pCube, tChild, .pStatus){
					Return 1
				}
			}
		}

	}
	Catch(ex){
		Set pStatus=ex.AsStatus()
	}
	
	Return 0
}

/// Add a %LABEL to <var>pReferenceGroup</var>. The label is supplied to the method as an abstracted 
/// %LABEL object <var>pLabel</var>. The input group is placed in the first argument of a %LABEL 
/// which contains all the same parameters that are defined in <var>pLabel</var>. The newly labeled group
/// is returned in <var>pLabeledGroup</var>.
ClassMethod %AddLabel(pReferenceGroup As %DeepSee.Query.group, pLabel As %DeepSee.Query.group = "", Output pLabeledGroup As %DeepSee.Query.group) As %Status
{
	// Method added by DTB203
	Set tSC = $$$OK
	Set pLabeledGroup = $$$NULLOREF
	Try {
		If ((pReferenceGroup.%IsA("%DeepSee.Query.setFunction") && ..%IsAggFunc(pReferenceGroup.function) ) && 
			(pReferenceGroup.function="%LABEL")) {
			// This is already labeled, return the original
			Set pLabeledGroup = pReferenceGroup
			Quit
		}
	
		If pLabel="" {
			Set tSC = $$$ERROR($$$GeneralError,"No label supplied to %AddLabel")
			Quit
		}
	
		Set pLabeledGroup = pLabel.%ConstructClone()
		Set tArgCount = pLabeledGroup.children.Count()
		Do pLabeledGroup.children.Clear()
		
		Do pLabeledGroup.children.Insert(pReferenceGroup)
		
		For a=2:1:tArgCount {
			// Copy other label arguments to the new label
			Do:$IsObject(pLabel.children.GetAt(a)) pLabeledGroup.children.Insert(pLabel.children.GetAt(a).%ConstructClone())
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Remove the %LABEL and expose the group is is acting upon. The abstracted contents of the %LABEL
/// are returned as the <var>pLabelGroup</var>.
ClassMethod %RemoveLabel(pReferenceGroup As %DeepSee.Query.group, Output pLabelGroup As %DeepSee.Query.group, Output pInnerGroup As %DeepSee.Query.group) As %Status
{
	// Method added by DTB203
	Set tSC = $$$OK
	Set pLabelGroup = $$$NULLOREF
	Set pInnerGroup = $$$NULLOREF
	Try {
		If '((pReferenceGroup.%IsA("%DeepSee.Query.setFunction") && ..%IsAggFunc(pReferenceGroup.function) ) && 
			(pReferenceGroup.function="%LABEL")) {
			// This isn't a label, return the original
			Set pInnerGroup = pReferenceGroup
			Quit
		}
		
		Set pInnerGroup = pReferenceGroup.children.GetAt(1).%ConstructClone()
		
		Set pLabelGroup = pReferenceGroup.%ConstructClone()
		Set tArgCount = pLabelGroup.children.Count()
		Do pLabelGroup.children.Clear()
		Set tNullMember = ##class(%DeepSee.Query.constant).%New()
		Set tNullMember.type = "string"
		
		Do pLabelGroup.children.Insert(tNullMember)
		
		For a=2:1:tArgCount {
			// Copy other label arguments to the new label
			Do:$IsObject(pReferenceGroup.children.GetAt(a)) pLabelGroup.children.Insert(pReferenceGroup.children.GetAt(a).%ConstructClone())
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod %RemoveLabelsInFilterExpression(pReferenceGroup As %DeepSee.Query.group, Output pOutputGroup As %DeepSee.Query.group, pCubeName As %String = "") As %Status
{
	// Method added by DTB493
	Set tSC = $$$OK
	Try {
		If pCubeName="" {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name must be supplied to %RemoveLabelsInExpression")
			Quit
		}
		
		Set tCubeName = $$$UPPER(pCubeName)

		Kill pOutputGroup
		Set pOutputGroup = pReferenceGroup.%ConstructClone()
		Do pOutputGroup.children.Clear()

		If pReferenceGroup.%IsA("%DeepSee.Query.expression") {
			Set tTerm(1) = pReferenceGroup.children.GetAt(1).%ConstructClone()
			Set tTerm(2) = pReferenceGroup.children.GetAt(2).%ConstructClone()
			
			For t=1:1:2 {
				Set tInputTerm = tTerm(t)
				If tTerm(t).%IsA("%DeepSee.Query.expression") {
					Set tSC = ..%RemoveLabelsInFilterExpression(.tInputTerm,.tOutputTerm,tCubeName)
				}
				ElseIf tTerm(t).%IsA("%DeepSee.Query.constant") {
					Set tOutputTerm = tInputTerm
				}
				ElseIf tTerm(t).%IsA("%DeepSee.Query.setFunction")&&(tTerm(t).function="%LABEL") {
					Set tSC = ..%RemoveLabel(tInputTerm,.tLabel,.tInner)
					
					// The %LABEL is maintaining the shape of results across subcubes.
					// This label is the display caption of the measure. There is no reverse lookup 
					// for captioned measures, so search their definitions for the right caption.
					Set tExpressionCaption = $$$UPPER(tLabel.children.GetAt(2).value)
					
					Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(tCubeName)
					
					Set tExpressionName = ""
					Set tMeasureNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",0,0))
					While ((tMeasureNo'="")&&(tExpressionName="")) {
						Set tMeasureName = $LG($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",0,tMeasureNo,0),3)
						Set tTestCaption = $classmethod(tClassName,"%GetMemberCaption","MEASURES",tMeasureName)
						
						If ($$$UPPER(tTestCaption)=$$$UPPER(tExpressionCaption)) {
							Set tExpressionName = tMeasureName
							Quit
						}
						
						Set tMeasureNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",0,tMeasureNo))
					}
					
					If tInner.%IsA("%DeepSee.Query.memberFunction")&&(tInner.function="NULL") {
						// Recreate the original replacement object from the label text
						Set tMDX = "SELECT MEASURES.[" _ tExpressionName _ "] ON 0 FROM [" _ tCubeName _ "]"
						Set tRS = ##class(%DeepSee.ResultSet).%New()
						Set tSC = tRS.%PrepareMDX(tMDX)
						If $$$ISERR(tSC)
						
						Set tOutputTerm = tRS.%GetQuery().axes.GetAt(1)
					}
					Else {
						Set tOutputTerm = tInner
					}
				}
				Else {
					Set tOutputTerm = tInputTerm
				}
				
				Set tTerm(t) = tOutputTerm
			}
			
			For t=1:1:2 {
				Set tSC = pOutputGroup.children.Insert(tTerm(t))
				If $$$ISERR(tSC) Quit
			}
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Argument supplied to %RemoveLabelsInExpression is not an expression")
			Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test to determine if the two provided crossjoin terms are swap-exempt
ClassMethod %IsCrossjoinSwapExempt(pNode1, pNode2) As %Boolean [ Internal ]
{
	// Method added by DTB400
	Set tSwapExempt = 0
	
	Set tNode1IsMember = ..%IsMember(pNode1)
	Set tNode2IsMember = ..%IsMember(pNode2)
	Set tNode1IsMeasure = ..%IsMeasure(pNode1)
	Set tNode2IsMeasure = ..%IsMeasure(pNode2)
	
	If pNode1.%IsA("%DeepSee.Query.calculatedMember")&&(pNode1.children.Count()=1) {
		// Dig into a calculated member to see if it is a subquery
		Set tChild=pNode1.children.GetAt(1)
		If tChild.%IsA("%DeepSee.Query.setFunction")&&( (tChild.function="%KPI")||(tChild.function="%MDX") ) {
			Set tSwapExempt = 1
		}
		
		If tChild.%IsA("%DeepSee.Query.setFunction")&&'tNode1IsMeasure {
			Set tSwapExempt = 1
		}

	}
	
	If pNode1.%IsA("%DeepSee.Query.setFunction")&&( (pNode1.function="%KPI")||(pNode1.function="%MDX") ) {
		// Directly written subquery/KPI is exempt
		Set tSwapExempt = 1
	}
	
	// Other conditions
	If '(tSwapExempt) {
		Set tSwapExempt = tSwapExempt || 
				tNode2IsMeasure ||
				(tNode1IsMember&&tNode2IsMember) ||
				($G(tNode1FunctionU)="%MDX") || 
				($G(tNode1FunctionU)="%KPI") 
	}
	
	Quit tSwapExempt
}

/// Write the node as the columns clause in an %MDX subquery.
ClassMethod %RewriteNodeAsSubquery(pNode) As %DeepSee.Query.node
{
	// Method added by DTB400
	Set tNewNode = ##class(%DeepSee.Query.setFunction).%New("%MDX")
	
	Try {
		Set tMDX = "SELECT " _ pNode.%ToString() _ " ON 0 FROM " _ %cube
		
		// Add two child nodes (constants) to the setFunction:
		//  1) The MDX query
		//  2) The %CONTEXT parameter
		Set tMDXChild1 = ##class(%DeepSee.Query.constant).%New()
		Set tMDXChild1.finalValue = 0
		Set tMDXChild1.type = "string"
		Set tMDXChild1.label = "Constant"
		Set tMDXChild1.value = tMDX
		
		Set tMDXChild2 = ##class(%DeepSee.Query.constant).%New()
		Set tMDXChild2.finalValue = 0
		Set tMDXChild2.type = "string"
		Set tMDXChild2.label = "Constant"
		Set tMDXChild2.value = "%CONTEXT"
		
		Do tNewNode.children.Insert(tMDXChild1)
		Do tNewNode.children.Insert(tMDXChild2)
	}
	Catch {
		Set tNewNode = $$$NULLOREF
	}
	
	Quit tNewNode
}

Method %SetVariables(ByRef pVariables) As %Status
{
	// Method added by DTB554
	Set tSC = $$$OK
	Try {
		Kill ..%variables
		Merge ..%variables = pVariables
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Resolve any instances of "$variable.Name" in the text <var>pMDX</var> using values in the lookup array
/// <var>pVariables</var>.
ClassMethod %ResolveVariablesInText(pMDX As %String, ByRef pVariables) As %Status
{
	// Method added by DTB554
	Set tSC = $$$OK
	Try {
		// DP-416993 - Note the presence of actual pivot variables and log the pre- and post-resolve text 
		Set tUsesVariables = ($$$LOWER(pMDX)["$variable.")
		Do:tUsesVariables ##class(%DeepSee.Utils).%WriteToLog("ResolveVariables","Pre-resolve query text: "_pMDX)

		// JMD1276: resolve any pivot variables within the query
		// these are basically macro substitutions using the named parameter list as values
		Set tMarker = "$variable."
		Set tMDXLower = $$$LOWER(pMDX)
		If (tMDXLower[tMarker) {
			Set tMDX = ""
			Set p=1,next=1
			While (next>0) {
				Set next = $Find(tMDXLower,tMarker,next)
				If (next=0) {
					Set tMDX = tMDX _ $E(pMDX,p,*)
					Quit
				}
				Else {
					Set tMDX = tMDX _ $E(pMDX,p,next-$L(tMarker)-1)
					Set p = next
					While (($E(pMDX,next)'="")&&($ZNAME("X"_$E(pMDX,next)))) {
						Set next = next+1
					}
					Set tVar = $$$LOWER($E(pMDX,p,next-1))
					If (tVar="") {
						Set tMDX = tMDX _ tMarker
					}
					Else {
						Set tValue = $G(pVariables(tVar))
						Set:tValue="" tValue = """"""
						
						// JMD1349: translate "%NOT value" to "value.%NOT"
						If ($E(tValue,1,5) = "%NOT ") {
							Set tValue = $E(tValue,6,*)_".%NOT"
						}
						Set tMDX = tMDX _ tValue
					}
				}
				Set p = next
			}
			Set pMDX = tMDX
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	// DP-416993 - Log any resolve error, or the result of actual variable resolution in the query text
	If $$$ISERR(tSC) {
		Do ##class(%DeepSee.Utils).%WriteToLog("ResolveVariables","Resolve query text error: "_$system.Status.GetOneErrorText(tSC))
	}
	ElseIf tUsesVariables {
		Do ##class(%DeepSee.Utils).%WriteToLog("ResolveVariables","Resolved query text: "_pMDX)
	}

	Quit tSC
}

/// Set the axis to a literal null
ClassMethod %NullifyAxis(pAxisKey) As %Status
{
	// Method added by DTB681
	Set tSC = $$$OK
	
	Try {
		Kill $$$DeepSeeAxisGLVN(%cubeIndex,pAxisKey,"axes",1,"ch")
		Set $$$DeepSeeAxisGLVN(%cubeIndex,pAxisKey,"axes",1,"ch",2) = ""
		Set $$$DeepSeeAxisGLVN(%cubeIndex,pAxisKey,"axes",1,"all",2) = ""

		Kill $$$DeepSeeAxisGLVN(%cubeIndex,pAxisKey,"axes",2)
		// JMD1028 Use NULL instead of No Results
		// Set $$$DeepSeeAxisGLVN(%cubeIndex,tAxisKey,"axes",2) = $lb("lit",1,1,1,"","No Result")
		Set $$$DeepSeeAxisGLVN(%cubeIndex,pAxisKey,"axes",2) = $lb("lit",1,1,1,"",$S(+$G(%dsIsSlicer):0,1:""))		// DTB - Zero is better for slicer
		Set %leafCount = 1

		// JMD871: mark that this axis need to be recomputed if cube data changes
		Set $$$DeepSeeAxisGLVN(%cubeIndex,pAxisKey,"recompute") = 1
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Generate the result key for the current query object.
Method %CreateResultKey(Output pStatus As %Status = {$$$OK}, Output pFinalText = "", pRefreshKey As %Boolean = 0, pMDXRequest As %String = "") As %String
{
	// Method added by DTB739
	Set tKey = ""
	
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		Set:pRefreshKey ..%QueryKey = ""		// DTB868 - Optionally destroy the current key in favor of generating a new one
		
		If (..%QueryKey'="") {
			// DTB820 - Return the same key text that was stored when this key was generated
			Set tKey = ..%QueryKey
			Set pFinalText = $G($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"query","keyText"))
			
			If (pFinalText="") {
				Set pStatus = $$$ERROR($$$GeneralError,"Failure to retrieve keyText for result key: " _ tKey)
			}
			Quit
		}
		
		New %dsMakeKey,%query,%cube,%dsQueryPrepare,%dsUseOrigValue
		Set %dsMakeKey = 1
		Set %dsQueryPrepare = 1		// DTB847 - Do not perform resolution
		Set %dsUseOrigValue = 1		// DTB967 - Report the original prepared value in %ToString when generating keys

		// DTB847 - Provide context to the %ToString
		Set %query = $this
		Set %cube = $$$UPPER(..cube)
		Set tText = ..%ToString(.pStatus)		// %ToString can resolve memberSpec - %dsQueryPrepare prevents that resolution and honestly interprets the current string
		Kill %query,%cube,%dsMakeKey
		If $$$ISERR(pStatus) Quit
		
		// Display the direct text as returned by %ToString. 
		If +$G(%dsflags("REWRITE")) {
			Write "*** Final query text ***",!
			Write tText,!
			Write "***",!
		}
		
		// DTB967 - This query is distinct if its visible axes are distinct 
		For a=1:1:..axes.Count() {
			Set tAxisText = $G(..%originalAxisText(a))
			Set:(tAxisText'="") tText = tText _ ":" _ $ZCRC($$$UPPER(tAxisText),7)
		}
		
		// JMD1381 tText *has* to be valid at this point
		// compute unique key for this query (include current locale: JMD998)
		Set tLang = ..%GetLanguage()
		
		Set tDone=0
		While ('tDone) {
			Set tKey = tLang_$ZCRC($$$UPPER(tText),7)
			
			// test if query exists and is current
			If ($D($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"query","keyText"),tKeyText)) {
				If ($$$UPPER($G(tKeyText))=$$$UPPER(tText)) {
					Set tDone = 1
				}
				Else {
					// key collision: make new seed text
					Set tText = tText _ " "
				}
			}
			Else {
				// no query is filed under this key yet
				Set tDone = 1
			}
		}
		
		// Store the final keyText used to produce this key
		Set ..%QueryKey = tKey		// DTB820
		Set $$$DeepSeeResultsGLVN(tCubeIndex,tKey,"query","keyText") = $$$UPPER(tText)
		If (pMDXRequest'="") {
			// DTB882 - If the key has changed, preserve the request text
			Set $$$DeepSeeResultsGLVN(tCubeIndex,tKey,"query",0) = pMDXRequest
		}
		
		Set pFinalText = tText
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tKey = ""
	}
	
	Quit tKey
}

/// Generate an axis key for a %DeepSee.Query.axis object.
Method %CreateAxisKey(Output pStatus As %Status = {$$$OK}, pType = "", pAxis As %DeepSee.Query.axis = {$$$NULLOREF}, pOriginalSpec = "", Output pFinalText = "", pRefreshKey As %Boolean = 0) As %String
{
	// Method added by DTB739
	Set tKey = ""
	
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(..cube)
		Set:pRefreshKey pAxis.%AxisKey = ""		// DTB868 - Optionally destroy the current key in favor of generating a new one
		
		If pAxis.%AxisKey'="" {
			// DTB820 - Return the same key text that was stored when this key was generated
			Set tKey = pAxis.%AxisKey
			Set pFinalText = $G($$$DeepSeeAxisGLVN(tCubeIndex,tKey,"keyText"))
			
			If (pFinalText="") {
				Set pStatus = $$$ERROR($$$GeneralError,"Failure to retrieve keyText for axis key: " _ tKey)
			}
			Quit
		}

		New %dsMakeKey,%query,%cube,%dsQueryPrepare,%dsUseOrigValue
		Set %dsMakeKey = 1
		Set %dsQueryPrepare = 1		// DTB847 - Do not perform resolution
		Set %dsUseOrigValue = 1		// DTB967 - Report the original prepared value in %ToString when generating keys

		// create key for axis
		// if present, we need the slicer as well
		If ($IsObject(..slicer)) {
			Set tText = ..slicer.%ToString()_":"_pAxis.%ToString(.pStatus)
		}
		Else {
			Set tText = pAxis.%ToString(.pStatus)
		}
		If $$$ISERR(pStatus) Quit

		// if there is a filter, we need this as well
		If ($IsObject(..filterAxis)) {
			Set tText = tText_":"_..filterAxis.%ToString(.pStatus)
		}
		If $$$ISERR(pStatus) Quit

		Kill %dsMakeKey
		
		// JMD1400: if we have original text for the axis; tack it on
		If (pOriginalSpec'="") {
			Set tText = tText_":"_pOriginalSpec
		}
		
		// DTB967 - Perform the UPPER at this point to normalize the axis and slicer/filter contents
		Set tText = $$$UPPER(tText)
		
		// DTB967 - Add the WITH clause to the key generation as-is. Two MEMBERS that differ 
		// only in case in otherwise identical queries will map to a different axis key and 
		// present the identifier being defined by this WITH clause for this query.
		If (..%WITHText'="") {
			Set tText = ..%WITHText_":"_tText
		}
		
		Set tText = $$$UPPER(pType)_":"_tText


		// JMD998
		Set tLang = ..%GetLanguage()

		Set tDone=0
		While ('tDone) {
			Set tKey = tLang_$ZCRC(tText,7)		// DTB967 - Remove blanket $$$UPPER to preserve WITH MEMBER casing

			// test if axis exists and is current
			If ($D($$$DeepSeeAxisGLVN(tCubeIndex,tKey,"keyText"),tKeyText)) {
				If ($$$UPPER($G(tKeyText))=$$$UPPER(tText)) {
					Set tDone = 1
				}
				Else {
					// key collision: make new seed text
					Set tText = tText _ " "
				}
			}
			Else {
				// no axis is filed under this key yet
				Set tDone = 1
			}
		}
		
		// Store the final keyText used to produce this key		
		Set $$$DeepSeeAxisGLVN(tCubeIndex,tKey,"keyText") = tText
		Set pAxis.%AxisKey = tKey	// DTB820 - Store the new axis key in the object
		
		Set pFinalText = tText
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tKey = ""
	}
	
	Quit tKey
}

/// This method provides a means for safely killing previously cached results without destroying the<br>
/// ^DeepSee.Cache.Results(CUBEKEY,QueryKey,"query") <br>
/// node. Primarily this allows %PrepareKey to function if an execution determines the remainder of the cache is stale
/// and cannot be reused.
ClassMethod %ClearQueryResults(pCubeName As %String = "", pQueryKey As %String = "") As %Status [ Internal ]
{
	// Method added by DTB863
	Set tSC = $$$OK
	
	Try {
		If (pCubeName="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name must be supplied to %ClearQueryResults")
			Quit
		}
		If (pQueryKey="") {
			Set tSC = $$$ERROR($$$GeneralError,"QueryKey must be supplied to %ClearQueryResults")
			Quit
		}
		
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		
		Merge tQueryTextInfo = $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"query")
		Kill $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey)
		Merge $$$DeepSeeResultsGLVN(tCubeIndex,pQueryKey,"query") = tQueryTextInfo
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Test the current query object for enabled dimensions, measures, and relationships as aplicable.
/// If all items have completed a build process and contain queryable data, the query is executable. 
Method %IsExecutable(Output pStatus = {$$$OK}, Output pReason As %String = "") As %Boolean
{
	// Method added by DTB908
	Set tReturn = 1
	
	Try {
		// DTB951 - Decorate the cube name with [] if not already present
		Set tCubeName = $S($E(..cube)="[":..cube,1:"[" _ ..cube _ "]")
		
		For tAxis=1:1:..axes.Count() {
			Set tReturn = tReturn && ..axes.GetAt(tAxis).%IsEnabled(tCubeName,.pStatus,.pReason)
			If $$$ISERR(pStatus) $$$ThrowStatus(pStatus)
			If 'tReturn Quit
		}
		If 'tReturn Quit
		
		For tFilter=1:1:..filters.Count() {
			Set tReturn = tReturn && ..filters.GetAt(tFilter).%IsEnabled(tCubeName,.pStatus,.pReason)
			If $$$ISERR(pStatus) $$$ThrowStatus(pStatus)
			If 'tReturn Quit
		}
		If 'tReturn Quit
		
		If $IsObject(..slicer) {
			Set tReturn = tReturn && ..slicer.%IsEnabled(tCubeName,.pStatus,.pReason)
			If ($$$ISERR(pStatus) || 'tReturn) Quit
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

}
