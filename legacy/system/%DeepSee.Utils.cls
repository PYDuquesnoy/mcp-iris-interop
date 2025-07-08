/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySite, %occUtility, %DeepSee)

/// This class contains a number of DeepSee utility methods.
Class %DeepSee.Utils Extends %RegisteredObject [ System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

/// Stops all DeepSee background agents, clears any pending tasks,
/// and clears the result cache for the current namespace.
/// If <var>pClearCells</var> is true, then the cell cache for the
/// current namespace is also cleared.<br/>
/// This method is provided as a convenience for developers for 
/// use on development or test systems. You should not use this method
/// on production systems as it will have immediate effect on the
/// performance of end user operations.
ClassMethod %Reset(pClearCells As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Set tSC = ##class(%DeepSee.WorkMgr).%KillAgents(1)		// DTB706 - This is now handled by the WorkMgr

	Kill $$$DeepSeeAxisGLVN
	Kill $$$DeepSeeResultsGLVN
	Kill $$$DeepSeeListingGLVN
	Kill $$$DeepSeeListingBitGLVN
	Kill $$$DeepSeeListingResultsGLVN		// DTB142 - Kill listing results as well
	Kill $$$DeepSeeJoinGLVN
	Kill $$$DeepSeeKPIGLVN
	Kill $$$DeepSeeQueryNonceGLVN			// DTB762
	Kill $$$DeepSeeParameterNonceGLVN		// DTB796
	If (pClearCells) {
		Kill $$$DeepSeeCellsGLVN
		Kill $$$DeepSeeBucketsGLVN
		Kill $$$DeepSeeMaskGLVN					// DP-413393
	}
	Set tSC = ..%KillLogFile()
	Quit tSC
}

/// Test if the current query execution should be cancelled.
/// Not currently used.
ClassMethod %TestForCancel(pFlag As %String = "") As %Boolean [ Internal ]
{
	Quit 0
	Set tCancel = 0
	If +$G(%dsPivotNonce) {
		// give other processes a chance!
		Hang 0.001
		If $D(^DeepSee.Cancel(%dsPivotNonce)) {
			Set tCancel = 1
		}
	}
	Quit tCancel
}

/// Run the server init code.<br/>
/// This gives customer applications a chance to establish environmental settings.
/// This is called whenever a DeepSee session is created or when a background process begins work on a %DeepSee.WorkMgr queue.<br/>
/// The server init code is a valid ObjectScript expression stored in the ^DeepSee.InitCode global.
/// Server init code should not write any output to the current device nor
/// should this code kill any % variables required by Zen or DeepSee.
ClassMethod %RunServerInitCode() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tInitCode = $G($$$DeepSeeInitCode)
		If (tInitCode'="") {
			X tInitCode
			Set tSC = ##class(%DeepSee.Utils).%WriteToLog("ServerInitCode",tInitCode)
			If $$$ISERR(tSC) Quit
			
			// DTB956 - It's bad practice to initialize a %SYSTEM.WorkMgr queue environment 
			// without tearing down the configuration. Notify the user via the log if this 
			// teardown is missing from the namespace. This is only a note in the log rather than an 
			// error due to legacy concerns.
			If '$D($$$DeepSeeCloseCode) {
				Set tSC = ##class(%DeepSee.Utils).%WriteToLog("ServerInitCode","ServerInitCode executed with no CloseCode")
				If $$$ISERR(tSC) Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = $$$ERROR($$$GeneralError,"Error in DeepSee ServerInit Code:" _ $ZE)
	}
	Quit tSC
}

/// Run the server close code.<br/>
/// This gives customer applications a chance to clear environmental settings.
/// This method is called whenever a DeepSee session is closed or when a background process completes work on a %DeepSee.WorkMgr queue.<br/>
/// The server close code is a valid ObjectScript expression stored in the ^DeepSee.CloseCode global.
/// Server close code should not write any output to the current device nor
/// should this code kill any % variables required by Zen or DeepSee.
ClassMethod %RunServerCloseCode() As %Status
{
	// Method added by DTB956
	Set tSC = $$$OK
	Try {
		Set tCloseCode = $G($$$DeepSeeCloseCode)
		If (tCloseCode'="") {
			X tCloseCode
			Set tSC = ##class(%DeepSee.Utils).%WriteToLog("ServerCloseCode",tCloseCode)
		}
	}
	Catch(ex) {
		Set tSC = $$$ERROR($$$GeneralError,"Error in DeepSee ServerClose Code:" _ $ZE)
	}
	Quit tSC
}

/// Run the server audit code.<br/>
/// This gives customer applications a chance to audit viewing of DeepSee dashboard pages.
/// This is called whenever a DeepSee dashaboard is viewed in the user portal.<br/>
/// The server audit code is a valid ObjectScript expression stored in the ^DeepSee.AuditCode global.
/// Server audit code should not write any output to the current device nor
/// should this code kill any % variables required by Zen or DeepSee.<br/>
/// The variable, %dsDashboard, will contain the id (name) of the current dashboard item.
ClassMethod %RunServerAuditCode(pDashboardId As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		New %dsDashboard
		Set %dsDashboard = pDashboardId
		Set tAuditCode = $G($$$DeepSeeAuditCode)
		If (tAuditCode'="") {
			X tAuditCode
			Set tSC = ##class(%DeepSee.Utils).%WriteToLog("ServerAuditCode",tAuditCode)
		}
	}
	Catch(ex) {
		Set tSC = $$$ERROR($$$GeneralError,"Error in DeepSee ServerAudit Code:" _ $ZE)
	}
	Quit tSC
}

/// Test if the given cube is available for querying.
ClassMethod %IsCubeAvailable(pCubeName As %String, Output pReason As %String) As %Boolean
{
	Set tSC = $$$OK
	Set tAvailable = 1
	Set pReason = ""
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		
		// test for permission
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If (tClassName = "") {
			Set tAvailable = 0
			Set pReason = $$$FormatText($$$Text("Subject area '%1' does not exist or you do not have permission to view it.","%DeepSee"),pCubeName)
			Quit
		}
		
		If $D($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"compileError")) {
			// DTB949 - Return a specific message for compile failure. This will apply to both cubes
			// and subject areas since both are stored under the "cubes" subscript.
			Set tAvailable = 0
			Set pReason = $$$FormatText($$$Text("Subject area '%1' failed to compile and cannot be used.","%DeepSee"),pCubeName)
			Quit
		}
		
		// test for rebuild
		Lock +^DeepSee.Build(tCubeIndex,"QUERY"):0.1 Else  Set tAvailable = 0
		If ('tAvailable) {
			Set pReason = $$$FormatText($$$Text("Subject area '%1' is currently being rebuilt and is not available.","%DeepSee"),pCubeName)
			Quit
		}
		Lock -^DeepSee.Build(tCubeIndex,"QUERY")
	}
	Catch(ex) {
		Set tAvailable = 0
		Set pReason = $ZE
	}
	Quit tAvailable
}

/// Update <em>all</em> facts in a list of target DeepSee cubes <var>pCubeList</var> and all cubes with relationship dependencies
/// with data from the source table(s).<br/>
/// This will delete any information currently in all cubes affected.<br><br>
/// <var>pAsync</var> controls whether DeepSee performs the build in multiple background processes.
/// If this argument is true, the system uses multiple processes per cube build in dependency order and does not return until they are all complete.
/// If this argument is false, the system uses a single process and does not return until it is complete.<br>
/// If you have specified initialBuildOrder for any cubes targeted for build, the system will reset the value of <var>pAsync</var> to 0 and use a single process
/// to build each cube which has this defined. The value used for this will be included in the individual cube statistics in <var>pBuildStatistics</var>.<br/>
/// When a limit is imposed on background agents for a particular namespace using <method>%SetAgentCount</method>, only one build may be active
/// at a time in that namespace. This will not have any effect on behavior of builds in other namespaces.<br/>
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
/// If <var>pIndexOnly</var> is true, only rebuild the fact table indices.<br/>
/// If <var>pMaxFacts</var> is non-zero, then only build this number of facts for each cube.<br/>
/// <var>pTracking</var> is an internal argument used when this method is run in the background and specifies that status information should be stored.<br/>
/// <var>pBuildStatistics</var> returns an array of information about the cube build. <br/>
/// The array has four subscripts that describe the totals across all cubes built. In addition, the statistics returned for each of the individual cubes are 
/// filed under <var>pBuildStatistics("cubes",CubeIndex)</var>.
/// For example, if tStats is the argument used, as in:
/// <example>do ##class(%DeepSee.Utils).%BuildCube("PATIENTS",1,,,,,.tStats)</example> 
/// the array will look like the following: <br/>
/// 		tStats("cubes","PATIENTS")=""							<br>
/// 		tStats("cubes","PATIENTS","async")=1					<br>
/// 		tStats("cubes","PATIENTS","elapsedTime")=2.070832		<br>
/// 		tStats("cubes","PATIENTS","errors")=0					<br>
/// 		tStats("cubes","PATIENTS","expressionTime")=1.373914	<br>
/// 		tStats("cubes","PATIENTS","factCount")=5000				<br>
/// 		tStats("cubes","PATIENTS","iKnowTime")=0				<br>
/// 		tStats("cubes","PATIENTS","missingReferences")=0		<br>
/// 		tStats("elapsedTime")=2.070832							<br>
/// 		tStats("errors")=0										<br>
/// 		tStats("expressionTime")=1.373914						<br>
/// 		tStats("factCount")=5000								<br>
/// 		tStats("iKnowTime")=0									<br>
/// 		tStats("missingReferences")=0 							<br/>
/// <br/>
/// If the <var>pFactList</var> is supplied the build will only update the columns listed in that fact list. 
/// The list must consist of the specific fact names and can have either a comma-delimited or $LB format.
/// If this list is supplied, the specific facts being updated will be individually marked as unavailable for queries
/// and queries referencing dimensions based on those facts will throw an error on prepare.
ClassMethod %BuildCube(pCubeList As %String = "", pAsync As %Boolean = 1, pVerbose As %Boolean = 1, pIndexOnly As %Boolean = 0, pMaxFacts As %Integer = 0, pTracking As %Boolean = 1, ByRef pBuildStatistics As %String = "", pFactList As %String = "") As %Status
{
	Set tSC = $$$OK
	If pCubeList = "" Quit $$$ERROR($$$CubeListRequired)
	
	Try {
		Kill pBuildStatistics
		Kill ^IRIS.Temp.CubeManager($j) 
		Set pCubeList = ##class(%DeepSee.CubeUtils).%NormalizeCubeList(pCubeList,.tSC)
		If $$$ISERR(tSC) Quit

		If (($LL(pCubeList)>1)&&(pFactList'="")) {
			// DP-436216 - Reject Selective Build on multiple cubes
			Set tSC = $$$ERROR($$$FactListMultipleCubes)
			Quit
		}

		// Fetch the build order index and expanded cube list due to cube dependencies
		Set tSC = ##class(%DeepSee.CubeUtils).%GetUpdateLists(pCubeList,.tBuildOrders,.tGroupsToBuild,.tCubesToBuild)
		If $$$ISERR(tSC) Quit		// DP-431688

		// Walk down the build orders in each flagged group and kick off a build for every cube that is identified as a required build
		For {
			Set tGroup = $O(tGroupsToBuild($G(tGroup)))
			Quit:(tGroup="")

			For {
				Set tGroupPos = $O(tBuildOrders(tGroup,$G(tGroupPos)),1,tCubeToBuild)
				Quit:(tGroupPos="")

				// If this cube listed in the buildorders is flagged for a build, record this as a cube event also.
				If $D(tCubesToBuild(tCubeToBuild)) {
					// Perform the build for the current cube
					Set tAsync = pAsync		// Reinitialize the requested async variable that might get forced to 0 due to the cube's conditions
					
					If ((pFactList="")||(tCubeToBuild=$LG(pCubeList))) {
						// DP-436216 - If there was no fact list requested then all cubes are full builds.
						//   - If the request was for a selective build and the current cube is the only requested target, 
						//     continue with the full build.
						Set tBuildStatus = ..%BuildOneCube(tCubeToBuild, .tAsync, pVerbose, pIndexOnly, pMaxFacts, pTracking, .tSingleStatistics, pFactList)
					}
					Else {
						// If a fact list was requested and the current cube is not the requested target, run a synchronize instead
						Set tBuildStatus = ..%SynchronizeOneCube(tCubeToBuild, pVerbose,.tFactsUpdated,,,tAsync,.tSingleStatistics)
					}

					// Return the build statistics for the total set and for each cube individually
					Merge pBuildStatistics("cubes",tCubeToBuild) = tSingleStatistics
					Set pBuildStatistics("cubes",tCubeToBuild,"async") = tAsync
					Set pBuildStatistics("cubes",tCubeToBuild,"status") = tBuildStatus
					For {
						Set tStatName = $O(tSingleStatistics($G(tStatName)),1,tValue)
						Quit:(tStatName="")
						Do $I(pBuildStatistics(tStatName),tValue)
					}
					
					Merge ^IRIS.Temp.CubeManager($j,"completed",tCubeToBuild) = ^IRIS.Temp.DeepSeeTracking($j)
			
					// If the build of a single cube failed, fail the overall build attempt
					If $$$ISERR(tBuildStatus) $$$ThrowStatus(tBuildStatus)
				}
			}
		}

	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Update <em>all</em> facts in the DeepSee cube <var>pCubeName</var> 
/// with data from the source table.<br/>
/// This will delete any information currently in the cube.<br><br>
/// <var>pAsync</var> controls whether DeepSee performs the build in multiple background processes.
/// If this argument is true, the system uses multiple processes and does not return until they are all complete.
/// If this argument is false, the system uses a single process and does not return until it is complete.<br>
/// If you have specified initialBuildOrder, the system will reset the value of pAsync to 0 and use a single process to build the cube. 
/// The presence of initialBuildOrder in the cube definition will override this setting and will force <var>pAsync</var>=0.
/// The parameter may be passed by reference to communicate to the caller whether or not this
/// override has taken place.<br/>
/// When a limit is imposed on background agents for a particular namespace using <method>%SetAgentCount</method>, only one build may be active
/// at a time in that namespace. This will not have any effect on behavior of builds in other namespaces.<br/>
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
/// If <var>pIndexOnly</var> is true, only rebuild the fact table indices.<br/>
/// If <var>pMaxFacts</var> is non-zero, then only build this number of facts.<br/>
/// <var>pTracking</var> is an internal argument used when this method is run in the background and specifies that status information should be stored.<br/>
/// <var>pBuildStatistics</var> returns an array of information about the cube build. <br/>
/// The array has four subscripts. For example, if tStats is the argument used, as in: <br/>
/// do ##class(%DeepSee.Utils).%BuildCube("PATIENTS",1,,,,,.tStats) the array will look like the following: <br/>
/// 		tStats("elapsedTime")=10.000643          <br/>
/// 		tStats("errors")=1                       <br/>
/// 		tStats("factCount")=5000                 <br/>
/// 		tStats("missingReferences")=1            <br/>
/// <br/>
/// If the <var>pFactList</var> is supplied the build will only update the columns listed in that fact list. 
/// The list must consist of the specific fact names and can have either a comma-delimited or $LB format.
/// If this list is supplied, the specific facts being updated will be individually marked as unavailable for queries
/// and queries referencing dimensions based on those facts will throw an error on prepare.
ClassMethod %BuildOneCube(pCubeName As %String = "", pAsync As %Boolean = 1, pVerbose As %Boolean = 1, pIndexOnly As %Boolean = 0, pMaxFacts As %Integer = 0, pTracking As %Boolean = 1, ByRef pBuildStatistics As %String = "", pFactList As %String = "") As %Status
{
	Set tSC = $$$OK
	New %dsBuildLock
	Set %dsBuildLock = 0
	$$$dsSetLogging

	Try {
		If (pCubeName = "") {
			Set tSC = $$$ERROR($$$CubeNameRequired,$$$dsCurrentMethod)
			Quit
		}
		If '..%IsCubePhysical(pCubeName,.tSC) Quit		// DP-431688

		Set tUpdateLimitedList = ($G(pFactList)'="")		// DTB906 - Use a compact variable to indicate selective fact updates
		
		// +DTB130 - if a cube uses versions, build the pending version when called using the generic name. If a version
		// is specifically passed in via pCubeName, build it
		Set tPendingVersionNo = ##class(%DeepSee.CubeVersion.Utils).%GetPendingCubeVersion(pCubeName)
		If (tPendingVersionNo'="") {
			Set pCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(pCubeName,tPendingVersionNo)
		}
		Else {
			Set tCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(pCubeName)
			If ##class(%DeepSee.CubeVersion.Utils).%IsActiveVersion(tCubeName) {
				Set tSC = $$$ERROR($$$RejectActiveCubeBuild, tCubeName)
				Quit
			}
		}
		// -DTB130
		If $$$ISERR(tSC) Quit
		
		Do:pTracking UpdateTracking("begin")		// DTB975 - Set tracking immediately to avoid the client missing server activity
		
		// DTB941 - Parameter validation is now complete, move on to processing
		Set tCubeNameU = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)

		$$$dsSetAppInfo($LB(tCubeIndex,pAsync))		// DP-419418 - Register with the activity monitor


		// Start recording a CubeEvent now that the Cube Index is validated	
		Set tCubeEvent = ##class(%DeepSee.CubeManager.CubeEvent).%New()
		Set tCubeEvent.CubeKey = tCubeIndex
		Set tSC = tCubeEvent.TransferRegistryInfo(tCubeIndex,"build")
		If $$$ISERR(tSC) Quit
		
		Set tCubeEvent.CubeEvent = "build"
		Set tCubeEvent.StartTime = $ZDT($H,3)
		// Save the intermediate as a way of recording the update as "in-progress"
		Set tCubeEvent.EventStatus = $$$ERROR($$$GeneralError,$$$Text("Build In Progress","%DeepSee"))
		Set tSC = tCubeEvent.%Save()
		If $$$ISERR(tSC) Quit

		
		If (tUpdateLimitedList)&&'$$$dsSupportsSelectedList(tCubeNameU) {
			// DTB891 - Consult the namedFactNums setting for this cube and quit with an error if it is not enabled
			Set tSC = $$$ERROR($$$RequireNamedFactNums,pCubeName)
			Quit
		}
		Else {
			// DTB891 - Convert to a list build format since it is more universally supported
			// DTB961 - Reinforce the list by including the cube in the call to normalize
			Set tFactList = ..%NormalizeFactList(pFactList,.tSC,tCubeIndex)
			If $$$ISERR(tSC) Quit
		}
		// DTB900 - Check the supplied fact list against the cube's fact table
		If '..%IsValidFactList(tCubeNameU,tFactList,.tSC,.tReason) {
			Set tSC = $$$ERROR($$$InvalidFactListParm,$$$dsCurrentMethod, $ListToString(tFactList,", "), $ListToString(tReason,", "))		// DTB915 - Add reason to the error message
			Quit
		}
		If $$$ISERR(tSC) Quit

		Set tDSTIME = ""

		New %dsCubeName
		Set %dsCubeName = tCubeNameU

		// do not allow concurrent calls to BuildCube
		// also prevent queries while this cube is being built
		If tUpdateLimitedList {
			// DTB906 - If a selected fact list is in play, individually lock them
			Set tSC = ..%LockFactList(tCubeIndex,tFactList,.%dsBuildLock)
		}
		Else {
			Lock +^DeepSee.Build(tCubeIndex):1 Else  Set tSC = $$$ERROR($$$NoCubeLock, pCubeName, $$$dsCurrentMethod)
			Set %dsBuildLock = 1
		}
		If $$$ISERR(tSC) Quit
		
		// + DTB923 - If the agent count is limited, enforce single cube build behavior
		Set tAgentCountMax = +..%GetAgentCount("buildMax")
		Set tAgentCount = +..%GetAgentCount("build")

		Set tIsAgentLocked = 0
		If tAgentCount || tAgentCountMax {
			// Agents are limited for the current task or for the build category. Determine the agent count to use in this request
			If (tAgentCountMax && ('tAgentCount || (tAgentCount>tAgentCountMax))) {
				Set tAgentCount = tAgentCountMax
			}
			
			Write:pVerbose !,"Agent count is limited to " _tAgentCount _".",!
			Write:pVerbose "Requesting single cube build lock...",!
			Lock +^DeepSee.Build("LIMITAGENTS")
			Write:pVerbose "Proceeding with build of [",pCubeName,"]",!
			Set tIsAgentLocked = 1
		}
		// - DTB923
		
		If tUpdateLimitedList {
			// DTB908 - Mark the specific dimensions being built as enabled=0
			Set tSC = ..%MarkFactsEnabled(tCubeIndex,tFactList,0,1)
			If $$$ISERR(tSC) Quit
		}

		// track time spent in user expressions
		Kill ^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeIndex)

		Set tFactClass = $zobjclassmethod(tClassName,"%GetFactClass")

		If (pTracking) {
			// WAL024
			Kill ^IRIS.Temp.CubeManagerUpdateTracking(+$J,##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCubeName))		// DTB130 - clean up according to the generic name
		}

		// run server init code
		Set tSC = ##class(%DeepSee.Utils).%RunServerInitCode()
		If $$$ISERR(tSC) Quit

		// clear update log
		Set tSC = $zobjclassmethod(tFactClass,"%KillLogFile")
		If $$$ISERR(tSC) Quit

		// reset build error list
		Kill $$$DeepSeeBuildErrorsGLVN(tCubeNameU)
		
		// +DTB531 - Purge listing globals. If the build is happening in the first hour of the day
		// the purge of listings will start with the day prior.
		Kill $$$DeepSeeListingBitGLVN(tCubeNameU)
		Set tListingPurgeDate = $S($P($H,",",2)<3600:$H-1,1:+$H)
		Set tSC = ..%PurgeListings(0,tListingPurgeDate)
		If $$$ISERR(tSC) Quit
		// -DTB531

		// get details on source class
		Set tSC = $zobjclassmethod(tClassName,"%GetSourceInfo",.tSourceInfo)
		If $$$ISERR(tSC) Quit

		Set tInitialBuildOrder = $G(tSourceInfo("initialBuildOrder"))
		Set tBuildRestriction = $G(tSourceInfo("buildRestriction"))
		Set tSourceIsBitFriendly = +$G(tSourceInfo("posint"))
		Set tMaxFacts = $G(tSourceInfo("maxFacts"))
		If (+pMaxFacts>0) {
			Set tMaxFacts = $S('tUpdateLimitedList:+pMaxFacts,1:0)		// DTB921 - Ignore maxfacts for Selective Build
		}
		
		// DTB320 - Force synchronous build if initial build order is defined to preserve the ordering
		If (tInitialBuildOrder'="")&&(pAsync) {
			Set pAsync=0
			Write:pVerbose !,"Initial Build Order defined: Switching to synchronous build.",!
		}

		// JMD1177: get the current dstime counter
		Set tSourceClassName = $G(tSourceInfo("sourceClass"))
		
		// DTB422 - Cube updates no longer care about the source's dsinterval setting, everything will get translated to an increment-style
		// update log. Push all IDs from the buffer and increment the top counter of this log before proceeding.
		Set tSC = ..%ProcessUpdateBuffer(tSourceClassName)
		If $$$ISERR(tSC) Quit
		Set tDSTIME = $I($$$DeepSeeUpdateQueue)
		

		// notify (for iKnow)
		// JMD953: make sure error is returned
		Set tSC = $classmethod(tFactClass,"%OnStartBatch",tCubeNameU,pVerbose)

		Write:pVerbose !,"Building cube [",pCubeName,"]",!

		If tUpdateLimitedList {
			// DTB891 - Do not remove the data for all facts. This needs to be cleared out column-wise.
			// Purge only the relevant indices that will be rebuilt. 
			Write:pVerbose "Deleting selected indices..."
			
			// DTB961 - Process the fact list to find the corresponding index list for calling %BuildIndices
			Set tSC = $classmethod(tFactClass,"%PurgeIndices",..%FindCubeIndexList(tCubeIndex,,tFactList))
			If $$$ISERR(tSC) Quit
			Write:pVerbose $C(13,27)_"[0J"
			Write:pVerbose "Selected indices deleted.",!
		}
		ElseIf ('pIndexOnly) {
			Do:pTracking UpdateTracking("delete",,0)
			Write:pVerbose "Deleting existing cube..."
			Set tSC = $classmethod(tClassName,"%KillFacts")
			If $$$ISERR(tSC) Quit
			Write:pVerbose $C(13,27)_"[0J"
			Write:pVerbose "Existing cube deleted.",!
			Do:pTracking UpdateTracking("delete",,100)
		}
		Else {
			Write:pVerbose "Deleting existing indices..."
			Set tSC = $classmethod(tFactClass,"%PurgeIndices")
			If $$$ISERR(tSC) Quit
			Write:pVerbose $C(13,27)_"[0J"
			Write:pVerbose "Existing indices deleted.",!
		}

		// clear precompute cache
		Set tStart = $ZH

		Set tPercentComplete = 0

		New %dsfactcount,%dserrors,%dserrcount		// DTB473
		Set %dsfactcount = 0
		Set %dserrcount = 0
		New %dsmaxfacts
		If (tMaxFacts>0) {
			Set %dsmaxfacts = tMaxFacts
		}

		New %dsMissingRef
		Set %dsMissingRef = 0

		If ('pAsync) {
			If ('pIndexOnly) {
				Set tSC = $classmethod(tClassName,"%BuildFactTable",pVerbose,tFactList)		// DTB891
				If $$$ISERR(tSC) Quit
				
				// DP-408261 - Normalize a potentially null fact count to a printable integer
				Set tFacts = +$G(%dsfactcount)

				Write:pVerbose $C(13,27)_"[0J"
				Write:pVerbose "Fact table built:"
				Write:pVerbose ?25,$J($FN(tFacts,",",0),10)_" fact(s) (1 worker used)",!
				If (%dserrcount>0) {
					Write:pVerbose ?25,$J($FN(+$G(%dserrcount),",",0),10)_" error(s)",!
				}
				If (%dsMissingRef>0) {
					Write:pVerbose ?25,$J($FN(+$G(%dsMissingRef),",",0),10)_" missing reference(s)",!
				}
			}

			Write:pVerbose "Building indices..."
			
			// DTB961 - Process the fact list to find the corresponding index list for calling %BuildIndices
			Set tSC = $classmethod(tFactClass,"%BuildIndices",..%FindCubeIndexList(tCubeIndex,,tFactList))
			If $$$ISERR(tSC) Quit
			
			Write:pVerbose $C(13,27)_"[0J"
			Write:pVerbose "Fact indices built: ",?25,$J($FN(tFacts,",",0),10)," fact(s) (1 worker used)",!
		}
		Else {
			If ('pIndexOnly) {
				Do:pTracking UpdateTracking("facts",0,0)

				// if true, then use a temp file to build tables in parallel
				// that would not normally be done in parallel
				Set tUseTempFile = 1

				If ('tSourceIsBitFriendly || (tMaxFacts>0) ||( tInitialBuildOrder'="") || (tBuildRestriction'="") || (tFactList'="")) {		// DTB927 - Use temp file if there is a fact list
					If (tUseTempFile) {
						Set tSC = $zobjclassmethod(tFactClass,"%BuildTempFile",tCubeIndex,.tImplemented,pVerbose)
						If $$$ISERR(tSC) Quit
						If ('tImplemented) {
							Set tUseTempFile = 0
						}
					}

					If ('tUseTempFile) {
						// build fact table in one process
						Set tSC = $classmethod(tClassName,"%BuildFactTable",pVerbose,tFactList)		// DTB891 - Pass tFactList
						If $$$ISERR(tSC) Quit

						Write:pVerbose $C(13,27)_"[0J"
						Write:pVerbose "Fact table built:"
						Write:pVerbose ?25,$FN(+$G(%dsfactcount),",",0)_" fact(s)"
						If (%dserrcount>0) {
							Write:pVerbose ", ",$FN(+$G(%dserrcount),",",0)_" error(s)"
						} Else {
							Set tFacts = $FN(+$G(%dsfactcount),",",0)
						}
						Write:pVerbose " (1 worker used)",!
					}
					Else {
						// JMD1203: invoke callback
						Set tSC = $classmethod(tClassName,"%OnBuildCube",tFactList)		// DTB891 - Pass pFactList as supplied by the user to the user callback
						If $$$ISERR(tSC) Quit

						// use temp file of source ids, to build in parallel
						// use background tasks
						// DTB704 - This is now handled by the %DeepSee.WorkMgr
						Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tGroupId,1,"BUILDCUBETEMP",1,.tWorkMgr)		// DTB923 - Request WorkMgr oref
						
						If $$$ISERR(tSC) {
							Do $System.Status.DisplayError(tSC)
							Quit
						}

						$$$dsSetAppInfo($LB(tCubeIndex,pAsync,$G(tGroupId)))		// DP-419418 - Update the activity monitor with group ID
						
						// use temp global to track progress
						// background tasks will update this
						Kill $$$DeepSeeTempUpdate($namespace,tGroupId)

						// update facts for each "chunk"
						Set tChunk = $O($$$DeepSeeTempSourceId(tCubeIndex,""))		// DP-412844
						While (tChunk '= "") {
							// DTB704 - This is now handled by the %DeepSee.WorkMgr
							Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId,"UPDATEFACTSTEMP",pCubeName,"",tCubeIndex,tChunk,,tFactList,,.tWorkMgr)		// DTB891 - Queue up the tFactList	// DTB923 - Include WorkMgr oref
							
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB
							Set tChunk = $O($$$DeepSeeTempSourceId(tCubeIndex,tChunk))		// DP-412844
						}
						If $$$ISERR(tSC) Quit

						// now wait on tasks to complete
						If ('pVerbose && ('pTracking)) {
							// DTB704 - This is now handled by the %DeepSee.WorkMgr
							Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId,,,.tWorkMgr,.tMaxTaskGroupWorkers)		// DTB923 - Include WorkMgr oref
							If $$$ISERR(tSC) Quit
							
							// DTB794 - Set local variables in this case as well
							Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
							Set tErrors = +$G($$$DeepSeeBuildErrorsGLVN(tCubeNameU))
							Set tMissingRefs = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"missing"))
							Kill $$$DeepSeeTempUpdate($namespace,tGroupId)
						}
						Else {
							Set tTimeOut = 2
							Set tCompleted = 0
							Set tPct = 0
							Set tMaxTaskGroupWorkers = 0
							While ('tCompleted) {
								Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
								Set tCount = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"count"))
								Set tComplete = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"complete"))
								Set:tCount>0 tPercentComplete = (tComplete/tCount)*100
								Write:pVerbose $C(13,27)_"[0J"_"Building fact table: ",?25,$J($FN(tFacts,",",0),10)," fact(s) updated.  "_$J($FN(+$G(tPercentComplete),",",0),3)_"% tasks complete"
								Do:pTracking UpdateTracking("facts",tFacts,tPercentComplete)
								// DTB704 - This is now handled by the %DeepSee.WorkMgr
								Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId,.tCompleted,tTimeOut,.tWorkMgr,.tMaxTaskGroupWorkers)		// DTB923 - Include WorkMgr oref
							
								If $$$ISERR(tSC) Quit
								Set tPct = tPct + 1
							}
							Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
							Set tErrors = +$G($$$DeepSeeBuildErrorsGLVN(tCubeNameU))
							Set tMissingRefs = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"missing"))		// DTB301
							
							// Statitics output printed to terminal
							Write:pVerbose $C(13,27)_"[0J"
							Set tAgentCount = tMaxTaskGroupWorkers //APV011
							Write:pVerbose "Fact table built: ",?25,$J($FN(tFacts,",",0),10)," fact(s) (Max number of worker(s) used at a time: "_tAgentCount_")",! //APV008
							Write:pVerbose&&(tErrors) "Errors: ",?25,$J($FN(tErrors,",",0),10)," error(s)",!
							If (tMissingRefs>0) {
								// DTB301 - Report missing references
								Write:pVerbose ?25,$J($FN(+$G(tMissingRefs),",",0),10)_" missing reference(s)",!
							}

							Kill $$$DeepSeeTempUpdate($namespace,tGroupId)
							Do:pTracking UpdateTracking("facts",tFacts,tPercentComplete)
						}
						// kill temp file
						Kill $$$DeepSeeTempSourceId(tCubeIndex)		// DP-412844 - Table storage is now organized by cube index
					}
				}
				Else {
					// we can build the fact table in parallel
			
					// JMD1203: invoke callback
					Set tSC = $classmethod(tClassName,"%OnBuildCube")
					If $$$ISERR(tSC) Quit

					// find range of id values for source table
					Set tSC = $zobjclassmethod(tClassName,"%GetSourceIds",.tStartId,.tEndId)
					If $$$ISERR(tSC) Quit

					// use background tasks
					// DTB704 - This is now handled by the %DeepSee.WorkMgr
					Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tGroupId,1,"BUILDCUBE",1,.tWorkMgr)		// DTB923 - Request WorkMgr oref
					
					If $$$ISERR(tSC) {
						Do $System.Status.DisplayError(tSC)
						Quit
					}

					$$$dsSetAppInfo($LB(tCubeIndex,pAsync,$G(tGroupId)))		// DP-419418 - Update the activity monitor with group ID
					
					// break range into bitmap chunk-size sub-ranges
					Set tItemCount = 0
					Set tStartChunk = (+tStartId\64000)+1
					Set tRangeStartId = ((tStartChunk-1)*64000)
					While (tRangeStartId <= tEndId) {
						Set tRangeEndId = tRangeStartId + 64000 - 1
						Set:(tRangeStartId<tStartId) tRangeStartId = tStartId
						Set:((tRangeEndId)>tEndId) tRangeEndId = tEndId 

						Set tItemCount = tItemCount + 1
						Set tWorkList(tItemCount) = $LB(tRangeStartId,tRangeEndId)
						Set tStartChunk = tStartChunk + 1
						Set tRangeStartId = ((tStartChunk-1)*64000)
					}

					// use temp global to track progress
					// background tasks will update this
					Kill $$$DeepSeeTempUpdate($namespace,tGroupId)

					// update facts for each item
					Set tItem = $O(tWorkList(""))
					While (tItem '= "") {
						Set tRangeStartId = $LG(tWorkList(tItem),1)
						Set tRangeEndId = $LG(tWorkList(tItem),2)
						// DTB704 - This is now handled by the %DeepSee.WorkMgr
						Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId,"UPDATEFACTS",pCubeName,"",tRangeStartId,tRangeEndId,,tFactList,,.tWorkMgr)		// DTB891	// DTB923 - Include WorkMgr oref
						
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB
						Set tItem = $O(tWorkList(tItem))
					}
					If $$$ISERR(tSC) Quit

					// now wait on tasks to complete
					If ('pVerbose && ('pTracking)) {
						// DTB704 - This is now handled by the %DeepSee.WorkMgr
						Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId,,,.tWorkMgr,.tMaxTaskGroupWorkers)		// DTB923 - Include WorkMgr oref
						
						// DTB798 - Set local variables in this case as well
						Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
						Set tErrors = +$G($$$DeepSeeBuildErrorsGLVN(tCubeNameU))
						Set tMissingRefs = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"missing"))
						If $$$ISERR(tSC) Quit
					}
					Else {
						Set tTimeOut = 2
						Set tCompleted = 0
						Set tPct = 0
						Set tMaxTaskGroupWorkers=0
						While ('tCompleted) {
							Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
							Set tCount = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"count"))
							Set tComplete = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"complete"))
							Set:tCount>0 tPercentComplete = (tComplete/tCount)*100
							Write:pVerbose $C(13,27)_"[0J"_"Building fact table: ",?25,$J($FN(tFacts,",",0),10)," fact(s) updated.  "_$J($FN(+$G(tPercentComplete),",",0),3)_"% tasks complete"
							Do:pTracking UpdateTracking("facts",tFacts,tPercentComplete)
							// DTB704 - This is now handled by the %DeepSee.WorkMgr
							Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId,.tCompleted,tTimeOut,.tWorkMgr,.tMaxTaskGroupWorkers)		// DTB923 - Include WorkMgr oref
					
							If $$$ISERR(tSC) Quit
							Set tPct = tPct + 1
						}
						Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
						Write:pVerbose $C(13,27)_"[0J"
						Set tAgentCount = tMaxTaskGroupWorkers //APV011
						Write:pVerbose "Fact table built: ",?25,$J($FN(tFacts,",",0),10)," fact(s) ("_tAgentCount_" worker(s) used)",!

						Set tErrors = +$G($$$DeepSeeBuildErrorsGLVN(tCubeNameU))
						Write:pVerbose&&(tErrors) "Errors: ",?25,$J($FN(tErrors,",",0),10)," error(s)",!
						
						// DTB301 - Report missing references
						Set tMissingRefs = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"missing"))
						If (tMissingRefs>0) {
							Write:pVerbose ?25,$J($FN(+$G(tMissingRefs),",",0),10)_" missing reference(s)",!
						}

						Kill $$$DeepSeeTempUpdate($namespace,tGroupId)
						Do:pTracking UpdateTracking("facts",tFacts,tPercentComplete)
					}
				}
			}
			Set tTotalFacts = tFacts		// DP-423720

			If $$$ISERR(tSC) Quit

			Do:pTracking UpdateTracking("facts",$G(tFacts),100)

			// build indices
			Do:pTracking UpdateTracking("indices",0,0)
			Set tSC = $zobjclassmethod(tClassName,"%GetFactIdRange",.tStartFactId,.tEndFactId)
			If $$$ISERR(tSC) Quit

			// DTB704 - This is now handled by the %DeepSee.WorkMgr
			// DTB923 - Plan to reuse the current WorkMgr oref if it was previously created, else request a new one
			Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tGroupId,1,"BUILDINDICES",'$IsObject($G(tWorkMgr)),.tWorkMgr)
			
			If $$$ISERR(tSC) Quit
			$$$dsSetAppInfo($LB(tCubeIndex,pAsync,$G(tGroupId)))		// DP-419418 - Update the activity monitor with group ID
			
			// use temp global to track progress
			// background tasks will update this
			Kill $$$DeepSeeTempUpdate($namespace,tGroupId)

			// build indices
			Kill tWorkList

			If ((tStartFactId'="")&&(tEndFactId'="")) {
				Set tItemCount = 0
				Set tStartChunk = (+tStartFactId\64000)+1
				Set tRangeStartId = ((tStartChunk-1)*64000)
				While (tRangeStartId <= tEndFactId) {
					Set tRangeEndId = tRangeStartId + 64000 - 1
					Set:(tRangeStartId<tStartFactId) tRangeStartId = tStartFactId
					Set:((tRangeEndId)>tEndFactId) tRangeEndId = tEndFactId

					Set tItemCount = tItemCount + 1
					Set tWorkList(tItemCount) = $LB(tRangeStartId,tRangeEndId)
					Set tStartChunk = tStartChunk + 1
					Set tRangeStartId = ((tStartChunk-1)*64000)
				}
			}

			Set tItem = $O(tWorkList(""))
			While (tItem '= "") {
				Set tRangeStartId = $LG(tWorkList(tItem),1)
				Set tRangeEndId = $LG(tWorkList(tItem),2)
				// DTB704 - This is now handled by the %DeepSee.WorkMgr
				// DTB961 - Process the fact list to find the corresponding index list for ultimately calling %BuildIndices
				Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId,"BUILDINDICES",pCubeName,"",tRangeStartId,tRangeEndId,,..%FindCubeIndexList(tCubeIndex,,tFactList),,.tWorkMgr)		// DTB923 - Include WorkMgr oref
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB
				
				Set tItem = $O(tWorkList(tItem))
			}
			If $$$ISERR(tSC) Quit

			// now wait on tasks to complete
			If ('pVerbose&&('pTracking)) {
				// DTB704 - This is now handled by the %DeepSee.WorkMgr
				Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId,,,.tWorkMgr,.tMaxTaskGroupWorkers)		// DTB923 - Include WorkMgr oref
				
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tTimeOut = 2
				Set tCompleted = 0
				Set tPct = 0
				Set tMaxTaskGroupWorkers=0
														
				While ('tCompleted) {
					Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
					Set tFacts = $S((tFacts>$G(tTotalFacts)):tTotalFacts,1:tFacts)		// DP-423720
					Set tCount = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"count"))
					Set tComplete = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"complete"))
					Set:tCount>0 tPercentComplete = (tComplete/tCount)*100
					Write:pVerbose $C(13,27)_"[0J"_"Building indices... "_$J($FN(tFacts,",",0),10)_" fact(s) processed. "_$J($FN(+$G(tPercentComplete),",",0),3)_"% tasks complete"
					Do:pTracking UpdateTracking("indices",tFacts,tPercentComplete)
					
					// DTB704 - This is now handled by the %DeepSee.WorkMgr
					Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId,.tCompleted,tTimeOut,.tWorkMgr, .tMaxTaskGroupWorkers)		// DTB923 - Include WorkMgr oref
					
					If $$$ISERR(tSC) Quit
					Set tPct = tPct + 1
				}
				Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
				Set tFacts = $S((tFacts>$G(tTotalFacts)):tTotalFacts,1:tFacts)		// DP-423720
				Write:pVerbose $C(13,27)_"[0J"
				Set tAgentCount = tMaxTaskGroupWorkers //APV011
				Write:pVerbose "Fact indices built: ",?25,$J($FN(tFacts,",",0),10)," fact(s) ("_tAgentCount_" worker(s) used)",!
				Do:pTracking UpdateTracking("indices",tFacts,tPercentComplete)
				Kill $$$DeepSeeTempUpdate($namespace,tGroupId)
				If $$$ISERR(tSC) Quit
			}
			Do:pTracking UpdateTracking("indices",$G(tFacts),100)
		}

		// notify (for iKnow)
		If (pVerbose) {
			Write $C(13,27)_"[0J"
			Write "Processing iKnow Indices..."
		}
		
		// BDB324: track iKnow index build
		do ##class(%iKnow.DeepSee.CubeUtils).GetIKnowMeasures(pCubeName,.tIKMsrs)
		do:pTracking&&$d(tIKMsrs) UpdateTracking("iknow",0,0)
		
		// JMD953: make sure error is returned
		Set tSC = $classmethod(tFactClass,"%OnEndBatch",tCubeNameU,pVerbose)
		If $$$ISERR(tSC) Quit

		// BDB324: mark iKnow index build end
		do:pTracking&&$d(tIKMsrs) UpdateTracking("iknow",$g(tFacts),100)

		If (pVerbose) {
			Write $C(13,27)_"[0J"
			Write !
		}

		// update sync point (timestamp)
		// DTB422 - Store the update time in the update global
		// DTB899 - Do not update if pFactList is supplied. INSERTS were not processed in selective build
		// DP-430862 - Set the cube timestamp if it hasn't been set yet
		If ( 'tUpdateLimitedList || '##class(%DeepSee.Utils).%GetCubeDSTime(tCubeNameU) ) { 
			Set tSC = ##class(%DeepSee.Utils).%SetCubeDSTime(tCubeNameU,tDSTIME)		// DTB838 - Use API
			If $$$ISERR(tSC) Quit
		}

		// update lastDataUpdate
		Set $$$DeepSeeUpdateQueue("cubes",tCubeNameU,"lastDataUpdate") = $ZTIMESTAMP		// DTB422

		Set tSC = ..%PrecomputeAggregates(pCubeName,pAsync,pVerbose,pTracking)
		If $$$ISERR(tSC) Quit

		If (pVerbose) {
			Write $C(13,27)_"[0J"
			Write "Complete",!
			Write "Elapsed time: ",?25,$J($FN($ZH-tStart,"",6),14),"s",!
			Write "Source expression time: ",?25,$J($FN(+$G(^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeNameU,"expr")),"",6),14),"s",!
			
			If ($D(^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeNameU,"iknow"))) {
				Write "iKnow processing time: ",?25,$J($FN(+$G(^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeNameU,"iknow")),"",6),14),"s",!
			}
		}
		
		// + WAL270 -- return array of build statistics
		//             some cases use the % variables, some don't -- safely check both
		// DTB423 - Remove formatting from statistics
		Set pBuildStatistics("factCount") = +$G(%dsfactcount)
		Set:$G(pBuildStatistics("factCount"))=0 pBuildStatistics("factCount") = +$G(tFacts)
		Set pBuildStatistics("errors") = +$G(%dserrors)
		Set:$G(pBuildStatistics("errors"))=0 pBuildStatistics("errors") = +$G(tErrors)
		Set pBuildStatistics("missingReferences") = +$G(%dsMissingRef)
		Set:$G(pBuildStatistics("missingReferences"))=0 pBuildStatistics("missingReferences") = +$G(tMissingRefs)
		Set pBuildStatistics("elapsedTime") = $ZH-$G(tStart)
		If ($G(tCubeNameU)'="") {
			// DTB432 - Add additional build statistics
			Set pBuildStatistics("expressionTime") = +$G(^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeNameU,"expr"))
			Set pBuildStatistics("iKnowTime") = +$G(^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeNameU,"iknow"))
		}
		// - WAL270

		If (pVerbose) {
			// check cardinality of dimensions
			Set tThreshold = 20000
			Set tSC = ..%GetDimensionTables(pCubeName,.tTables,1)
			If $$$ISERR(tSC) Quit
			Set k = $O(tTables(""))
			While (k'="") {
				If ($G(tTables(k)) > tThreshold) {
					Write "**Warning** dimension table '"_k_"' has a large number of members ("_tTables(k)_")",!
				}
				Set k = $O(tTables(k))
			}
		}
		
		// DTB908 - Mark the specific dimensions being built as enabled=1, inProgress=0 if this completes successfully
		// In the case of a complete build, mark them all
		Set tSC = ..%MarkFactsEnabled(tCubeIndex,tFactList)
		If $$$ISERR(tSC) Quit

		// DTB1130 - Include an automatic synchronize following the successful build. This runs independently of the presence
		//   of the pFactList for the build, updating each targeted fact in its entirety
		Set tSC = $zobjclassmethod(tClassName,"%GetSourceInfo",.tSourceInfo)
		If $$$ISERR(tSC) Quit
		
		If ($G(tSourceInfo("dstime"))'="") {
			Write:pVerbose "Synchronize after build...",!
			Do:pTracking UpdateTracking("sync",,0)
			Set tSC = ..%SynchronizeOneCube(pCubeName,pVerbose,.tFactsUpdated,1,1,pAsync,.tSyncStats)
			If $$$ISERR(tSC) Quit
			Do:pTracking UpdateTracking("sync",tFactsUpdated,100)
		}

		// DTB1130 - Include automatic purge of unusable cache and clear out update global
		Write:pVerbose "Purging cache...",!
		Do:pTracking UpdateTracking("purge",,0)
		Set tSC = ..%DeleteObsoleteCache(pCubeName)
		If $$$ISERR(tSC) Quit

		Do:pTracking UpdateTracking("purge",,100)
		Set tSC = ..%PurgeDSTIME()
		If $$$ISERR(tSC) Quit

		// Notify of completion
		Set tCompletionTime = $h
		Write:pVerbose "Build completed: " _ $ZDT(tCompletionTime,3)
		Set ^IRIS.Temp.DeepSeeBuildStats.prevBuildFinished($namespace, tCubeNameU) = tCompletionTime
		Do:pTracking UpdateTracking("complete")

		Set tCubeEvent.EventStatus = tSC
		Set tCubeEvent.FinishTime = $ZDT($H,3)
		Set tCubeEvent.CubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeIndex)
		Set tCubeEvent.FactsUpdated = tCubeEvent.CubeSize
		Set tCubeEvent.NCores = $S(pAsync:##class(%SYSTEM.CPU).%New().nCores,1:1)
		Set tCubeEvent.AsynchUpdate = pAsync
		
		Set tCubeEvent.iKnowTime = $Get(pBuildStatistics("iKnowTime"))
		Set tCubeEvent.ExprTime = $Get(pBuildStatistics("expressionTime"))
		Set tCubeEvent.ErrorCount = $Get(pBuildStatistics("errors"))
		Set tCubeEvent.MissingRefs = $Get(pBuildStatistics("missingReferences"))
	
		Set tSC = tCubeEvent.%Save()

		// DP-430862 - Run the cube's PostBuildCode if it is defined
		Set tSC = ##class(%DeepSee.CubeUtils).ExecuteCustomCode(tCubeIndex,"postbuild")
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()

		// Record this status in the CubeEvent if one was created
		If $IsObject($G(tCubeEvent)) {
			Set tCubeEvent.EventStatus = tSC
			Set tCubeEvent.FinishTime = $ZDT($H,3)
			Do tCubeEvent.%Save()
		}
	}
	
	// JMD1480
	If ($$$ISOK(tSC)&&(tCubeNameU'="")) {
		Set tErrors = +$G($$$DeepSeeBuildErrorsGLVN(tCubeNameU))
		If (tErrors) {
			// DTB426 - Return the number of build errors.
			Set tSC = $$$ERROR($$$BuildHasErrors,tErrors,tCubeNameU)
		}
	}
	
	// DTB233 - Call %OnAfterBuildCube
	Set tCallBackSC = $$$OK
	If $G(tClassName)'="" {
		Set tErrors = +$G(tErrors)
		Set tCallBackSC = $classmethod(tClassName,"%OnAfterBuildCube",tSC,tErrors)
	}
	If $$$ISOK(tSC)&&$$$ISERR(tCallBackSC) {
		// If the user chose to return an error in an otherwise successful build, return it
		Set tSC = tCallBackSC
	}
	
	// DTB956 - Run the server close code if it is present. This happens after the %OnAfterBuildCube
	// so that user code executes with the InitCode setup in place.
	Do ##class(%DeepSee.Utils).%RunServerCloseCode()
	
	// Release the lock after the user callback is complete
	If (%dsBuildLock) {
		If tUpdateLimitedList {
			// DTB906 - Release all columns in the fact list
			// DTB961 - This return status is unnecessary and would overwrite any previous error
			Do ..%UnlockFactList(tCubeIndex,tFactList)
		}
		Else {
			Lock -^DeepSee.Build(tCubeIndex)
		}
	}
	// DTB923 - Release agent-limited build lock
	If +$G(tIsAgentLocked) {
		Lock -^DeepSee.Build("LIMITAGENTS")
		Set tIsAgentLocked = 0
	}
	
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}
	If pTracking,$$$ISERR(tSC) {
		Do $System.Status.DecomposeStatus(tSC,.errors)		// DTB426 - Don't reset the return status
		Set error = $O(errors(""))
		While error '= "" {
			Do UpdateTracking("error",,,errors(error))	
			Set error = $O(errors(error))	
		}
	}
	
	// DP-421530 - Set up the bucketList
	D ##class(%DeepSee.Query.Engine).%GetBucketList(pCubeName)

	Quit tSC
UpdateTracking(phase,count,pct,errors)
	Quit:($G(pCubeName)="")		// DP-419767 - Protect global references against null cube name

	// DTB975 - Add a "begin" phase
	// DTB1130 - Add "sync" phase
	Set tStep = $Case(phase,"begin":0,"delete":1,"facts":2,"indices":3,"iknow":4,"aggs":5,"sync":6,"error":100,:99)

	// DP-417743 - Clear the tracking global if in the "begin" phase
	Kill:(tStep=0) $$$DeepSeeUpdateTracking($namespace,$$$UPPER(pCubeName))

	Set $$$DeepSeeUpdateTracking($namespace,$$$UPPER(pCubeName),tStep) = $LB(phase,$G(count),$G(pct),$G(errors))
	// WAL024
	// DTB130 - use the generic name for update tracking
	Set ^IRIS.Temp.CubeManagerUpdateTracking(+$J,##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCubeName),tStep) = $LB(phase,$G(count),$G(pct),$G(errors))
	Quit
}

/// Log a %Status to the ^DeepSee.BuildErrors global.
ClassMethod %LogBuildError(pCubeName As %String = "", pRecordID As %Integer = 0, pStatus As %Status = {$$$OK}) As %Status
{
	// Method Added by DTB836
	Set tSC = $$$OK
	Try {
		If (pCubeName="") {
			Set tSC = $$$ERROR($$$GeneralError,"Cube name must be supplied to %LogBuildError")
			Quit
		}
		If '$D(pRecordID) || (pRecordID=$c(0)) || (pRecordID=""){ //APV100
			Set tSC = $$$ERROR($$$GeneralError,"Record number must be supplied to %LogBuildError")
			Quit
		}

		
		Set tCubeNameU = $$$UPPER(pCubeName)
		
		S:($G($$$DeepSeeBuildErrorsGLVN(tCubeNameU,pRecordID))="") x = $I($$$DeepSeeBuildErrorsGLVN(tCubeNameU))		// Prevent double-counting
		Set $$$DeepSeeBuildErrorsGLVN(tCubeNameU,pRecordID) = pStatus
		Set $$$DeepSeeBuildErrorsGLVN(tCubeNameU,pRecordID,"info") = $LB($H,$J)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Command line utility for monitoring cube build progress. This repeats the same information
/// available to the Architect's build winow in a terminal.
ClassMethod %BuildStatus(pCubeName As %String = "")
{
	Set tCubeNameU = $$$UPPER(pCubeName)
	If (pCubeName="") {
		Set tSC = $$$ERROR($$$CubeNameRequired,$$$dsCurrentMethod)
		Quit
	}
	If ('..%IsBaseCube(pCubeName)) {
		Set tSC = $$$ERROR($$$RejectSubjectArea,$$$dsCurrentMethod,pCubeName)
		Quit
	}

	If ($DATA($$$DeepSeeUpdateTracking($namespace, tCubeNameU)) = 0) {
		// DP-417600 - Account for the case where this is called but the cube has never been built
		Set tMsg = "There is no build in progress."
		If $D(^IRIS.Temp.DeepSeeBuildStats.prevBuildFinished($namespace, tCubeNameU),tPrevBuildTimeStamp) {
			Set tMsg = tMsg _ " Last build was finished on " _ $ZDT(tPrevBuildTimeStamp,3) _ "."
		}
		Write tMsg
		Quit 
	}
	Set tIsComplete = 0
	Set tStep = $O($$$DeepSeeUpdateTracking($namespace, tCubeNameU,""),1,info)
	Set tOutput = ""
	Set table = ""
	Set tUserCancel = 0
	While 'tIsComplete&&'tUserCancel {
		Set tPhase = $LG(info,1)
		Set:tPhase="complete"!(tPhase="error") tIsComplete = 1 
		Set tCount = $LG(info,2)
		Set tPct = $LG(info,3) 
		Set tErr = $LG(info,4)
		Set tMsg = $Case(tPhase,"delete":"Deleting facts","facts": "Building "_ $FN(tCount,",",0)_ " facts","indices":"Building "_$FN(tCount,",",0)_" indices","aggs":"Computed "_$FN(tCount,",",0)_" aggregates","iknow":"Processing iKnow measures","sync":"Running final syncronize","error":"Error",:"Complete")
		
		If ((tPhase'="begin") && (tPhase'="complete")) {Set table(tPhase) = tMsg}
		Set prop = $O(table(""))
		Write $CHAR(13)
		While (prop '= "") {
			Write table(prop), " | "
			Set prop = $O(table(prop))
		}
		
		If $D($$$DeepSeeUpdateTracking($namespace, tCubeNameU)) {
			Set tStep = $O($$$DeepSeeUpdateTracking($namespace, tCubeNameU,tStep),1,info)
		}
		Else {
			Set tIsComplete = 1 
		}

		// DP-417743 - Give the user an opportunity to interrupt by pressing any key
		Read:('tIsComplete) *x:1 Set tUserCancel = $TEST

		// Reset the cursor to replace the current line
		If (tErr = "") {
			Write $CHAR(13), tOutput
		}
		Else {
			Write !, tErr
		}
	}
	Write:tIsComplete !, "COMPLETE"
	
	// Use this opportunity to clear the tracking global if the build has completed
	Kill:('$G($$$DeepSeeUpdateTracking.buildInProgress($namespace))) $$$DeepSeeUpdateTracking($namespace,tCubeNameU)
}

/// For the given cube, iterate over all facts in the build error log and attempt to
/// reprocess each fact. If the processing succeeds, remove the item from the error log.
ClassMethod %FixBuildErrors(pCube As %String, pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCount = 0
		Set tErrorCount = 0
		Set tCubeNameU = $$$UPPER(pCube)
		Set tSourceId = $O($$$DeepSeeBuildErrorsGLVN(tCubeNameU,""))
		
		// DTB631 - Find the source class for the cube to verify the logged ID
		Set tCubeClass = ..%GetCubeClass(tCubeNameU)
		Set tSC = $zobjclassmethod(tCubeClass,"%GetSourceInfo",.tSourceInfo)
		If $$$ISERR(tSC) Quit
		Set tSourceClass = tSourceInfo("sourceClass")
		
		While (tSourceId'="") {
			Set tSC2 = ..%ProcessFact(pCube,tSourceId,0)
			If $$$ISOK(tSC2)||((tSourceClass'="")&&'$classmethod(tSourceClass,"%ExistsId",tSourceId)) {		// DTB631
				Write:pVerbose "Fact '",tSourceId,"' corrected",!
				Set tCount = tCount + 1
				// remove error from list
				Kill $$$DeepSeeBuildErrorsGLVN(tCubeNameU,tSourceId)
				Set $$$DeepSeeBuildErrorsGLVN(tCubeNameU) = $G($$$DeepSeeBuildErrorsGLVN(tCubeNameU)) - 1
			}
			Else {
				Set tErrorCount = tErrorCount + 1
				If (pVerbose) {
					Do $System.Status.DisplayError(tSC2)
					Write !
				}
			}
			Set tSourceId = $O($$$DeepSeeBuildErrorsGLVN(tCubeNameU,tSourceId))
		}

		Write:pVerbose !!,$FN(tCount,",")," fact(s) corrected for '",pCube,"'",!
		Write:pVerbose $FN(tErrorCount,",")," error(s) remaining for '",pCube,"'",!
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Display the list of errors encountered in the most recent build of the given cube.
ClassMethod %PrintBuildErrors(pCube As %String = "")
{
	If (pCube'="") {
		// PFS060 - Check for existence of cube and inform user if cube does not exist
		Set tCubeExists = ..%CubeExists(pCube)
		If 'tCubeExists {
			Write $$$FormatText($$$Text("Cube '%1' does not exist"),pCube),!
			Quit
		}
		Set tCubeNameU = $$$UPPER(pCube)
		Set tCount = 0
		Set k = $O($$$DeepSeeBuildErrorsGLVN(tCubeNameU,""))
		While (k'="") {
			Set tCount = tCount + 1
			Set tSC = $G($$$DeepSeeBuildErrorsGLVN(tCubeNameU,k))
			Set tTime = $LG($G($$$DeepSeeBuildErrorsGLVN(tCubeNameU,k,"info")),1)		// DTB836 - Check for time stamp
			Write $J($FN(tCount,","),5),$J("",3),"Source ID: ",k		// DTB291 - Print source ID
			Write:(tTime'="") !,?8,"Time: ",$ZDT(tTime)		// DTB836
			Write !,?8,$System.Status.GetErrorText(tSC),!!
			Set k = $O($$$DeepSeeBuildErrorsGLVN(tCubeNameU,k))
		}
		Write $FN(tCount,",")," build error(s) for '",pCube,"'",!
	} 
	Else {
		// PFS060 - Provide useful feedback to the user if no cube name is supplied
		Write $$$Text("Please enter a cube name"),!
	}
}

/// Precompute aggregate values for the given cube (if its precompute property is non-zero).<br/>
/// If <var>pAsync</var> is true, then background tasks are used.<br/>
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
ClassMethod %PrecomputeAggregates(pCubeName As %String, pAsync As %Boolean = 1, pVerbose As %Boolean = 1, pTracking As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	$$$dsSetLogging

	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$GeneralError,"Precompute cannot be called on a SubjectArea: " _ pCubeName)
			Quit
		}

		// compute preaggregates
		Set tPrecompute = $zobjclassmethod(tClassName,"%GetPrecomputeLevel")
		If (tPrecompute = 0) {
			// nothing to do
			Quit
		}

		Set tStart = $ZH
		Do:pTracking UpdateTracking("aggs",0,0)

		Set tFactClass = $zobjclassmethod(tClassName,"%GetFactClass")

		// aggregrate pre-computed values and move into cell cache
		Set tCube = $$$UPPER(pCubeName)
		Set tChunksPerBucket = $$$DeepSeeChunksPerBucket(pCubeName)

		Set tPercentComplete = 0

		Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(pCubeName,.tBucketList,.tActiveChunk)
		If $$$ISERR(tSC) Quit
		If (pAsync) {
			Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tGroupId,1,"PRECOMPUTE")		// DTB704 - This is now handled by the %DeepSee.WorkMgr
			If $$$ISERR(tSC) Quit
			$$$dsSetAppInfo($LB(pCubeName,pAsync,$G(tGroupId)))		// DP-419418 - Register with the activity monitor
		}

		Set tCount = 0
		Set tLastBucket = $O(tBucketList(""),-1)
		Set tBucketNo = $O(tBucketList(""))
		While (tBucketNo '= "") {
			Set tSlotNo = $G(tBucketList(tBucketNo))

			Set tStartChunk = ((tBucketNo-1)*tChunksPerBucket)+1
			Set tEndChunk = tStartChunk + tChunksPerBucket - 1
			If ((tActiveChunk >= tStartChunk)&&(tActiveChunk <= tEndChunk)) {
				Set tEndChunk = tActiveChunk - 1
			}

			If ('pAsync) {
				// construct process private GLVN to hold results
				// We use a global to avoid <STORE> errors and indirection to avoid contention!
				Set tAggGLVN = "^||DeepSee.Agg."_$ZCRC(tCube,7)
				Kill @tAggGLVN
				Set tSC = $zobjclassmethod(tFactClass,"%PrecomputeAggregates",tStartChunk,tEndChunk,tAggGLVN,pVerbose,,.tCount)
				If $$$ISERR(tSC) {
					Kill @tAggGLVN
					Quit
				}
				Kill $$$DeepSeeCellsGLVN(tCube,tSlotNo)
				Merge $$$DeepSeeCellsGLVN(tCube,tSlotNo) = @tAggGLVN
				Kill @tAggGLVN
				Write:pVerbose !,"Elapsed time: ",$ZH-tStart,"s",!
			}
			Else {
				// queue task
				Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId, "PRECOMPUTE",pCubeName,"",tStartChunk,tEndChunk,tSlotNo)		// DTB704 - This is now handled by the %DeepSee.WorkMgr
				If $$$ISERR(tSC) Quit
			}
			Set tBucketNo = $O(tBucketList(tBucketNo))
		}

		If (pAsync) {
			// now wait on precompute tasks to complete
			If ('pVerbose && 'pTracking) {
				Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId)		// DTB704 - This is now handled by the %DeepSee.WorkMgr
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tTimeOut = 2
				Set tCompleted = 0
				Set tPct = 0
				While ('tCompleted) {
					Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
					Set tCount = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"count"))
					Set tComplete = +$G($$$DeepSeeTaskGroupGLVN(tGroupId,"complete"))
					Set:tCount>0 tPercentComplete = (tComplete/tCount)*100
					Write:pVerbose $C(13,27)_"[0J"_"Precomputing aggregates... "_$J($FN(tFacts,",",0),10)_" fact(s) processed. "_$J($FN(+$G(tPercentComplete),",",0),3)_"% tasks complete"
					Do:pTracking UpdateTracking("aggs",tFacts,tPercentComplete)
					Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId,.tCompleted,tTimeOut)		// DTB704 - This is now handled by the %DeepSee.WorkMgr
					If $$$ISERR(tSC) Quit
					Set tPct = tPct + 1
				}
				Set tFacts = +$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
				Write:pVerbose $C(13,27)_"[0J"
				Write:pVerbose "Aggregates complete: ",$FN(tFacts,",",0)," fact(s). ",$ZH-tStart,"s",!
				Do:pTracking UpdateTracking("aggs",tFacts,tPercentComplete)
				Kill $$$DeepSeeTempUpdate($namespace,tGroupId)
				If $$$ISERR(tSC) Quit
			}
		}
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC

UpdateTracking(phase,count,pct,errors)
	Set tStep = $Case(phase,"delete":1,"facts":2,"indices":3,"aggs":4,:5)
	Set $$$DeepSeeUpdateTracking($namespace,$$$UPPER(pCubeName),tStep) = $LB(phase,$G(count),$G(pct),$G(errors))
	Quit
}

/// Precompute the aggregates witin the given cube and the given group name within the cube's
/// CellCache specification.<br/>
/// Set <var>pGroupName</var> to "*" for all groups.
ClassMethod %ComputeAggregateGroup(pCubeName As %String, pGroupName As %String, pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		// get information from cube
		Set tSC = $zobjclassmethod(tClassName,"%GetCellCachePreLoads",.tInfo)
		If $$$ISERR(tSC) Quit

		If (pGroupName="*") {
			Set tGroupName = $O(tInfo(""))
		}
		Else {
			Set tGroupName = pGroupName
		}
		While (tGroupName'="") {
			Merge tCombo = tInfo($$$UPPER(tGroupName))
			If '$D(tCombo) {
				Write:pVerbose "Group not found: ",tGroupName,!
				Quit
			}

			Write:pVerbose "Group: ",tGroupName,!
			Set tSC = ..%ComputeAggregateCombos(pCubeName,.tCombo,pVerbose)
			If $$$ISERR(tSC) Quit

			If (pGroupName="*") {
				Set tGroupName = $O(tInfo(tGroupName))
			}
			Else {
				Quit
			}
		}
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Loop over fact table for cube and precompute the aggregates for the specified combinations
/// in <var>pCombo</var>.<br/>
/// pCombo(n) = "FactName1,FactName2,MsrName1"
ClassMethod %ComputeAggregateCombos(pCubeName As %String, ByRef pCombos, pVerbose As %Boolean = 1, pTracking As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tStart = $ZH
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tFactTable = ..%GetCubeFactTable(pCubeName,.tSC)
		Set tCubeName = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		// find list of facts we need and their #s
		Set n = $O(pCombos(""))
		While (n'="") {
			For f = 1:1:$L(pCombos(n),",") {
				Set tFactName = $P(pCombos(n),",",f)
				Set tFactNo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"fact","prop",tFactName))
				If (tFactNo="") {
					Set tSC = $$$ERROR($$$GeneralError,"Fact not found in cube: "_tFactName)
					Quit
				}
				// JMD973: pick up factName alias
				Set tAlias = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"fact","prop",tFactName,"alias"))
				Set:tAlias'="" tFactName = tAlias

				Set tFactList(tFactName) = tFactNo
				Set tWorkList(n,f) = tFactName
			}
			If $$$ISERR(tSC) Quit
			Set n = $O(pCombos(n))
		}
		If $$$ISERR(tSC) Quit

		If '$D(tFactList) {
			Quit
		}

		// process for each "bucket"
		Set tSC = ##class(%DeepSee.Query.Engine).%GetBucketList(pCubeName,.tBucketList,.tActiveChunk)
		If $$$ISERR(tSC) Quit

		Set tChunksPerBucket = $$$DeepSeeChunksPerBucket(pCubeName)
		Set tCount = 0
		Set tLastBucket = $O(tBucketList(""),-1)
		Set tBucketNo = $O(tBucketList(""))
		While (tBucketNo '= "") {
			Set tSlotNo = $G(tBucketList(tBucketNo))

			Set tStartChunk = ((tBucketNo-1)*tChunksPerBucket)+1
			Set tEndChunk = tStartChunk + tChunksPerBucket - 1
			If ((tActiveChunk >= tStartChunk)&&(tActiveChunk <= tEndChunk)) {
				Set tEndChunk = tActiveChunk - 1
			}

			// use process private global to hold results
			// We use a global to avoid <STORE> errors and indirection to avoid contention!
			Kill ^||DeepSee.Agg(tCubeName)
			Set tSC = ..%ComputeAggregateForBucket(pCubeName,tStartChunk,tEndChunk,.tFactList,.tWorkList,pVerbose,.tCount)
			If $$$ISERR(tSC) {
				Kill ^||DeepSee.Agg(tCubeName)
				Quit
			}

			// merge new values in on top of current values
			Merge $$$DeepSeeCellsGLVN(tCubeIndex,tSlotNo) = ^||DeepSee.Agg(tCubeName)
			Kill ^||DeepSee.Agg(tCubeName)

			Set tBucketNo = $O(tBucketList(tBucketNo))
		}

		Write:pVerbose $C(13,27)_"[0J"
		Write:pVerbose "Precomputing complete:"
		Write:pVerbose " ",$FN(tCount,",",0)_" fact(s) processed"
		Write:pVerbose !,"Elapsed time: ",$ZH-tStart,"s",!
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// Compute aggregate combinations for one "bucket".
ClassMethod %ComputeAggregateForBucket(pCubeName As %String, pStartChunk As %Integer, pEndChunk As %Integer, ByRef pFactList, ByRef pWorkList, pVerbose As %Boolean = 1, ByRef pCount As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeName = $$$UPPER(pCubeName)
		Set tFactTable = ..%GetCubeFactTable(pCubeName,.tSC)
		Set tLastCount = pCount
		Set tStartID = ((pStartChunk-1)*64000)+1
		Set tEndID = pEndChunk*64000

		// create sql statement
		Set tSELECT = "%ID"
		Set f = $O(pFactList(""))
		While (f'="") {
			Set tSELECT = tSELECT _ "," _ f
			Set f = $O(pFactList(f))
		}
		Set tSQL = "SELECT " _ tSELECT _ " FROM " _ tFactTable _
					" WHERE %ID BETWEEN ? AND ?"

		// execute query, compute values
		Set tRS = ##class(%ResultSet).%New()
		Set tSC = tRS.Prepare(tSQL)
		If $$$ISERR(tSC) Quit

		Set tSC = tRS.Execute(tStartID,tEndID)
		If $$$ISERR(tSC) Quit

		While (tRS.Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set pCount = pCount + 1
			If (pVerbose && ((pCount#25000)=0)) {
				Write $C(13,27)_"[0J"
				Write "Precomputing..."
				Write " ",$FN(pCount,",",0)_" fact(s)"
			}

			// process each set in the work list
			Set n = $O(pWorkList("")) 
			While (n'="") {
				Set tKeyMask = ""
				Set tMeasure = ""
				Set tMeasureNo = ""
				Set f = $O(pWorkList(n,""),1,tFactName) 
				While (f'="") {
					Set tFactNo = pFactList(tFactName)
					// construct key
					If ($E(tFactNo)="M") {
						Set tMeasureNo = +$E(tFactNo,2,*)
						Set tMeasure = tRS.Data(tFactName)
					}
					Else {
						Set tValue = tRS.Data(tFactName)
						Set $List(tKeyMask,tFactNo) = tValue
					}
					Set f = $O(pWorkList(n,f),1,tFactName) 
				}

				// update counts
				If (tKeyMask'="") {
					// convert mask to index
					Set tKeyIndex = ""
					For f=1:1:$LL(tKeyMask) {
						Set tKeyIndex = tKeyIndex _ ":" _ $LG(tKeyMask,f)
					}
					If (tMeasure="") {
						// count
						Set x = $I(^||DeepSee.Agg(tCubeName,tKeyIndex))
					}
					Else {
						// aggregates
						Set agg = $G(^||DeepSee.Agg(tCubeName,tKeyIndex,tMeasureNo))
						Set min = $LG(agg,2),max=$LG(agg,3),count=$LG(agg,4)
						Set min = $S((min="")||(min>tMeasure):tMeasure,1:min)
						Set max = $S((max="")||(max<tMeasure):tMeasure,1:max)
						Set ^||DeepSee.Agg(tCubeName,tKeyIndex,tMeasureNo) = $LB(tMeasure+$LG(agg,1),min,max,count+1)
					}
				}
				// next item
				Set n = $O(pWorkList(n)) 
			}
		}
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// Delete any stale cache for cube <var>pCubeName</var>.
ClassMethod %DeleteObsoleteCache(pCubeName = "") As %Status [ Internal ]
{
	// Method added by DTB1130
	Set tSC = $$$OK
	Set tLock = 0
	Try {
		Set pCubeName = $$$UPPER(pCubeName)
		If (pCubeName = "") {
			Set tSC = $$$ERROR($$$CubeNameRequired,$$$dsCurrentMethod)
			Quit
		} 
		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$RejectSubjectArea,$$$dsCurrentMethod,pCubeName)
			Quit
		}
		
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		// lock the inactive list for this cube
		Lock +$$$DeepSeeBucketsGLVN(tCubeIndex,"inactive"):10
		If ('$Test) {
			Set tSC = $$$ERROR($$$NoCubeLock,pCubeName,$$$dsCurrentMethod)
			Quit
		}
		Set tLock = 1

		// walk down the inactive list
		Set tSlot = $O($$$DeepSeeBucketsGLVN(tCubeIndex,"inactive",""))
		While (tSlot '= "") {
			// kill cell cache for this node
			Kill $$$DeepSeeCellsGLVN(tCubeIndex,tSlot)

			// Mask Cache/runtime index
			Set tMaskType = $O($$$DeepSeeMaskGLVN(tCubeIndex,""))
			While (tMaskType'="") {
				Kill $$$DeepSeeMaskGLVN(tCubeIndex,tMaskType,tSlot)
				Set tMaskType = $O($$$DeepSeeMaskGLVN(tCubeIndex,tMaskType))
			}

			// kill all results cached for this node
			Set tKey = $O($$$DeepSeeResultsGLVN(tCubeIndex,""))
			While (tKey '= "") {
				Kill $$$DeepSeeResultsGLVN(tCubeIndex,tKey,"data",tSlot)
				Set tKey = $O($$$DeepSeeResultsGLVN(tCubeIndex,tKey))
			}

			// remove node from inactive list
			Kill $$$DeepSeeBucketsGLVN(tCubeIndex,"inactive",tSlot)

			// add node to free list
			Set $$$DeepSeeBucketsGLVN(tCubeIndex,"free",tSlot) = ""

			// next slot
			Set tSlot = $O($$$DeepSeeBucketsGLVN(tCubeIndex,"inactive",tSlot))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	// unlock the inactive list
	Lock:tLock -$$$DeepSeeBucketsGLVN(tCubeIndex,"inactive")
	Quit tSC
}

/// [Deprecated] Cache is purged automatically on cube update and does not need to be called in user code.
ClassMethod %PurgeObsoleteCache(pCubeName As %String) As %Status [ Internal ]
{
	// Method deprecated by DTB1130. This remains for backwards compatibility of legacy user code.
	Quit $$$OK
}

/// For the specified cube, update one fact from the source table (with id of <var>pSourceId</var>).
/// If the fact does not yet exist, it is inserted, if does exist it is updated.<br/>
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
/// <var>pMissingReferences</var> how missing references to related cubes were encountered.
/// Refer to the <method>%SynchronizeOneCube</method> for details.<br/>
/// This method logs current time as the cube's last data update but does not advance the cube's DSTIME timestamp.
ClassMethod %ProcessFact(pCubeName As %String, pSourceId As %String = "", pVerbose As %Boolean = 0, Output pMissingReferences As %Integer, pFactList As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMissingReferences = 0
		Set tUpdateLimitedList = (pFactList'="")		// DTB - Use a compact variable to indicate selective fact updates
		Set tCubeName = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(tCubeName)
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		If (pSourceId="") Quit

		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$RejectSubjectArea,$$$dsCurrentMethod,pCubeName)
			Quit
		}
		
		If (tUpdateLimitedList)&&'$$$dsSupportsSelectedList(tCubeIndex) {
			// DTB900 - Consult the namedFactNums setting for this cube and quit with an error if it is not enabled
			Set tSC = $$$ERROR($$$RequireNamedFactNums,pCubeName)
			Quit
		}
		Else {
			// DTB900 - Convert to a list build format since it is more universally supported
			// DTB961 - Reinforce the list by including the cube in the call to normalize
			Set tFactList = ..%NormalizeFactList(pFactList,.tSC,tCubeIndex)
			If $$$ISERR(tSC) Quit
		}
		// DTB900 - Check the supplied fact list against the cube's fact table
		If '..%IsValidFactList(tCubeIndex,tFactList,.tSC,.tReason) {
			Set tSC = $$$ERROR($$$InvalidFactListParm,$$$dsCurrentMethod,$ListToString(tFactList,", "),tReason)
			Quit
		}
		If $$$ISERR(tSC) Quit

		// JMD1450 Test for missing references
		New %dsMissingRef
		Set %dsMissingRef = 0
		If (tUpdateLimitedList) {
			// DTB886 - Dispatch to %UpdateFactsList
			Set tSC = $classmethod(tClassName,"%UpdateFactsList",pFactList,pSourceId,,0,pVerbose)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = $classmethod(tClassName,"%UpdateFacts",pSourceId,,0,pVerbose)
			If $$$ISERR(tSC) Quit
		}

		If (%dsMissingRef) {
			Set pMissingReferences = %dsMissingRef
		}
		Kill %dsMissingRef

		// update lastDataUpdate
		// DTB988 - Removed call to %SetCubeDSTime to avoid interference with processing of system-managed collections of IDs
		Set $$$DeepSeeUpdateQueue("cubes",tCubeName,"lastDataUpdate") = $ZTIMESTAMP		// DTB422
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}

	Quit tSC
}

/// For the specified cube, delete one fact from the source table (with id of <var>pSourceId</var>).
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
/// This method logs current time as the cube's last data update but does not advance the cube's DSTIME timestamp.
ClassMethod %DeleteFact(pCubeName As %String, pSourceId As %String = "", pVerbose As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pSourceId="") Quit

		Set tCubeName = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$RejectSubjectArea,$$$dsCurrentMethod,pCubeName)
			Quit
		}

		Set tSC = $zobjclassmethod(tClassName,"%DeleteFact",pSourceId)
		If $$$ISERR(tSC) Quit
		Write:pVerbose $$$Text("Fact deleted","%DeepSee"),!
		
		// update lastDataUpdate
		// DP-422565 - Removed call to %SetCubeDSTime to avoid interference with processing of system-managed collections of IDs
		Set $$$DeepSeeUpdateQueue("cubes",tCubeIndex,"lastDataUpdate") = $ZTIMESTAMP
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}

	Quit tSC
}

/// Run a synchronize operation on one or more target cubes defined in <var>pCubeList</var> and all cubes with
/// relationship dependencies. For each cube, find and apply all changes from the source data that have been made since the
/// last call to this method.<br>
/// If <var>pVerbose</var> is true, then status information is written to the console.<br><br>
/// On return, <var>pFactsUpdated</var> will return the number of facts updated.<br><br>
/// By default, reads from the source table use READ COMMITTED mode, you can turn this off
/// (if you can tolerate reads of values from uncommitted transactions) by setting
/// <var>pReadCommitted</var> to 0.<br><br>
/// If this cube has facts that reference (via relationships) facts within another cube and any
/// of those remote facts are missing (because the related cube has not been synchronized), then
/// this method will report success and the missing references will be treated as build errors.<br>
/// To avoid this type of error, it is better to plan your synchronization so that the related cubes are 
/// synchronized first (in the same order the cubes are built).<br><br>
/// The <var>pCheckReferences</var> argument is deprecated and no longer has any effect on updates.<br><br>
/// <var>pAsync</var> controls whether DeepSee performs the synchronize in multiple background processes.
/// If this argument is true, the system uses multiple processes and does not return until they are all complete.
/// If this argument is false, the system uses a single process and does not return until it is complete.<br> 
/// By default this method runs in the synchronous mode to avoid any potential interference
/// with agents involved in background processing. If asynchronous mode is turned on, the synchronization work
/// will be divided among all available Low priority agents.<br><br>
/// <var>pSynchronizeStatistics</var> returns an array of information about the synchronize. <br>
/// The array has subscripts for the totals of each metric across the group, as well as filing each individual
/// cube statistics under the "cubes" subscript.
/// For example, if tStats is the argument used, as in:
/// <example>do ##class(%DeepSee.Utils).%SynchronizeCube("PATIENTS",1,,,,,.tStats)</example> 
/// the array might look like the following: <br>
/// 		tStats("cubes","PATIENTS","elapsedTime")=.000643	<br>
/// 		tStats("cubes","PATIENTS","errors")=1				<br>
/// 		tStats("cubes","PATIENTS","factCount")=5			<br>
/// 		tStats("cubes","PATIENTS","missingReferences")=1	<br>
///  		tStats("elapsedTime")=.000643          <br>
/// 		tStats("errors")=1                     <br>
/// 		tStats("factCount")=5                  <br>
/// 		tStats("missingReferences")=1          <br>
/// <br>
/// If any errors occur during the synchronize process but all source records are successfully checked,
/// this cube will treat processing for this timestamp as complete. The expectation is that any
/// individual update errors can and should be resolved individually or through the <method>%FixBuildErrors</method>
/// method and not by the synchronize itself.
ClassMethod %SynchronizeCube(pCubeList As %String = "", pVerbose As %Boolean = 1, Output pFactsUpdated As %Integer, pReadCommitted As %Boolean = 1, pCheckReferences As %Boolean = 1, pAsync As %Boolean = 0, ByRef pSynchronizeStatistics As %String = "") As %Status
{
	Set tSC = $$$OK
	If pCubeList = "" Quit $$$ERROR($$$CubeListRequired)
	
	Try {
		Kill pSynchronizeStatistics
		Kill ^IRIS.Temp.CubeManager($j) 
		Set pCubeList = ##class(%DeepSee.CubeUtils).%NormalizeCubeList(pCubeList,.tSC)
		If $$$ISERR(tSC) Quit
		
		// Fetch the build order index and expanded cube list due to cube dependencies
		Set tSC = ##class(%DeepSee.CubeUtils).%GetUpdateLists(pCubeList,.tBuildOrders,.tGroupsToBuild,.tCubesToBuild)
		If $$$ISERR(tSC) Quit		// DP-431688

		// Get the registry map to look up custom code if defined
		Set tMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1,.tRegLookup)
		If $$$ISERR(tSC) Quit

		// Walk down the build orders in each flagged group and kick off a synchronize for every cube that is identified as a required build
		For {
			Set tGroup = $O(tGroupsToBuild($G(tGroup)))
			Quit:(tGroup="")

			For {
				Set tGroupPos = $O(tBuildOrders(tGroup,$G(tGroupPos)),1,tCubeToBuild)
				Quit:(tGroupPos="")

				// If this cube listed in the buildorders is flagged for a build, record this as a cube event also.
				If $D(tCubesToBuild(tCubeToBuild)) {
					// Perform the actual synchronize
					Set tSyncStatus = ..%SynchronizeOneCube(tCubeToBuild, pVerbose, .tFactsUpdated, pReadCommitted, pCheckReferences, pAsync, .tSingleStatistics)
					// Return the synchronize statistics for the total set and for each cube individually
					Do $Increment(pFactsUpdated,tFactsUpdated)			// DP-431825 - Report facts updated back
					Set pFactsUpdated(tCubeToBuild) = tFactsUpdated
					Merge pSynchronizeStatistics("cubes",tCubeToBuild) = tSingleStatistics
					Set pSynchronizeStatistics("cubes",tCubeToBuild,"status") = tSyncStatus
					For {
						Set tStatName = $O(tSingleStatistics($G(tStatName)),1,tValue)
						Quit:(tStatName="")
						Do $I(pSynchronizeStatistics(tStatName),tValue)
					}


					Merge ^IRIS.Temp.CubeManager($j,"completed",tCubeToBuild) = ^IRIS.Temp.DeepSeeTracking($j)
			
					// If the build of a single cube failed, fail the overall build attempt
					If $$$ISERR(tSyncStatus) $$$ThrowStatus(tSyncStatus)
				}
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// For the specified cube, find and apply all changes from the source data that have been made since the
/// last call to this method.
/// If <var>pVerbose</var> is true, then status information is written to the console.<br><br>
/// On return, <var>pFactsUpdated</var> will return the number of facts updated.<br><br>
/// By default, reads from the source table use READ COMMITTED mode, you can turn this off
/// (if you can tolerate reads of values from uncommitted transactions) by setting
/// <var>pReadCommitted</var> to 0.<br><br>
/// If this cube has facts that reference (via relationships) facts within another cube and any
/// of those remote facts are missing (because the related cube has not been synchronized), then
/// this method will report success and the missing references will be treated as build errors.<br>
/// To avoid this type of error, it is better to plan your synchronization so that the related cubes are 
/// synchronized first (in the same order the cubes are built).<br><br>
/// The <var>pCheckReferences</var> argument is deprecated and no longer has any effect on updates.<br><br>
/// <var>pAsync</var> controls whether DeepSee performs the synchronize in multiple background processes.
/// If this argument is true, the system uses multiple processes and does not return until they are all complete.
/// If this argument is false, the system uses a single process and does not return until it is complete.<br> 
/// By default this method runs in the synchronous mode to avoid any potential interference
/// with agents involved in background processing. If asynchronous mode is turned on, the synchronization work
/// will be divided among all available Low priority agents.<br><br>
/// <var>pSynchronizeStatistics</var> returns an array of information about the synchronize. <br>
/// The array has four subscripts. For example, if tStats is the argument used, as in: <br>
/// do ##class(%DeepSee.Utils).%SynchronizeOneCube("PATIENTS",1,,,,,.tStats) the array might look like the following: <br>
/// 		tStats("elapsedTime")=.000643          <br/>
/// 		tStats("errors")=1                     <br/>
/// 		tStats("factCount")=5                  <br/>
/// 		tStats("missingReferences")=1          <br/>
/// <br>
/// If any errors occur during the synchronize process but all source records are successfully checked,
/// this cube will treat processing for this timestamp as complete. The expectation is that any
/// individual update errors can and should be resolved individually or through the <method>%FixBuildErrors</method>
/// method and not by the synchronize itself.
ClassMethod %SynchronizeOneCube(pCubeName As %String = "", pVerbose As %Boolean = 1, Output pFactsUpdated As %Integer, pReadCommitted As %Boolean = 1, pCheckReferences As %Boolean = 1, pAsync As %Boolean = 1, ByRef pSynchronizeStatistics As %String = "") As %Status
{
	Set tSC = $$$OK
	Set tSyncIsLocked = 0
	$$$dsSetLogging

	Try {
		If (pCubeName = "") {
			Set tSC = $$$ERROR($$$CubeNameRequired, $$$dsCurrentMethod)
			Quit
		}
		If '..%IsCubePhysical(pCubeName,.tSC) Quit		// DP-431688

		Set pFactsUpdated = 0
		
		// +DTB130 - if a cube uses versions, synchronize the active version when called using the generic cube name.
		// If a version name is passed in via pCubeName, synchronize it 
		Set tActiveVersionNo = ##class(%DeepSee.CubeVersion.Utils).%GetActiveCubeVersion(pCubeName)
		If (tActiveVersionNo'="") {
			Set pCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(pCubeName,tActiveVersionNo)
			W:pVerbose "Synchronizing cube version "_pCubeName,!
		}
		// -DTB130
		
		Set tCubeName = $$$UPPER(pCubeName)
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		// JMD1450
		New %dsMissingRef
		Set tMissingRefs = 0

		// JMD1033
		New %dsReadCommitted
		Set %dsReadCommitted = +pReadCommitted

		// do not allow concurrent calls or calls during build
		// but allow queries
		// wait a long time (30 seconds)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		// DTB1130 - If this is called from a build there is no need for a second lock, the lock held by the build will protect this synchronize
		If '$G(%dsBuildLock) {
			Lock +^DeepSee.Build(tCubeIndex,"SYNC"):30 Else  Set tSC = $$$ERROR($$$NoCubeLock, pCubeName, $$$dsCurrentMethod)
			If $$$ISERR(tSC) Quit
			
			Set tSyncIsLocked = 1
		}

		$$$dsSetAppInfo($LB(tCubeIndex,pAsync))		// DP-419418 - Register with the activity monitor

		// Start recording a CubeEvent now that the Cube Index is validated	
		Set tCubeEvent = ##class(%DeepSee.CubeManager.CubeEvent).%New()
		Set tCubeEvent.CubeKey = tCubeIndex
		Set tCubeEvent.StartTime = $ZDT($H,3)
		
		// Transfer the registry information to the CubeEvent
		Set tSC = tCubeEvent.TransferRegistryInfo(tCubeIndex,"synch")
		If $$$ISERR(tSC) Quit
		
		Set tCubeEvent.CubeEvent = "synch"
		// Save the intermediate as a way of recording the update as "in-progress"
		Set tCubeEvent.EventStatus = $$$ERROR($$$GeneralError,$$$Text("Synchronize In Progress","%DeepSee"))
		Set tSC = tCubeEvent.%Save()
		If $$$ISERR(tSC) Quit

		// DP-430862 - Fire the cube's PreSynchCode here if that exists. If the presynch code returns an abort flag, quit the synchronize and
		// log that abort as the event status.
		Set tSC = ##class(%DeepSee.CubeUtils).ExecuteCustomCode(tCubeIndex,"presynch",.tAbortSynch)
		If $G(tAbortSynch) {
			Set tCubeEvent.EventStatus = $$$ERROR($$$SyncAbort)
			Set tCubeEvent.FinishTime = $ZDT($H,3)
			Set tCubeEvent.CubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeIndex)
			Set tCubeEvent.FactsUpdated = 0
			Set tSC = tCubeEvent.%Save()

			Set pFactsUpdated = "abort"		// DP-431825
			
			Quit
		}
		

		Write:pVerbose !,"Synchronizing cube [",tCubeIndex,"]",!

		// track time spent in user expressions
		Kill ^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeIndex)

		Set tStart = $ZH		// DTB404 - Always set this

		Set tFactClass = $zobjclassmethod(tClassName,"%GetFactClass")

		// get details on source class
		Set tSC = $zobjclassmethod(tClassName,"%GetSourceInfo",.tSourceInfo)
		If $$$ISERR(tSC) Quit
		
		Set tSourceClass = $G(tSourceInfo("sourceClass"))

		Set tSourceDSTIME = $$$UPPER($G(tSourceInfo("dstime")))
		If (tSourceDSTIME="") {
			Set tSC = $$$ERROR($$$NoDSTIME, pCubeName)
			Quit	
		}
		
		Set tClassList(tSourceClass) = ""

		// get list of additional source tables to test
		Set tStarCls = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"depends",""),1,f)
		While (tStarCls'="") {
			Set tStarList(tStarCls) = f // f = field expression

			// find table(s) that reference the source field(s)
			Set tSC = ..%FindDimensionTableForProperty(tCubeName,f,.tDimList)
			Merge tStarListTables(tStarCls) = tDimList

			Set tStarCls = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"depends",tStarCls),1,f)
		}

		// find our last sync point (timestamp)
		Set tLastTimeStamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tCubeName)		// DTB838 - Use API

		// DP-430862 - If this cube has never been updated before, perform the initial build. 
		If 'tLastTimeStamp {
			Lock:tSyncIsLocked -^DeepSee.Build(tCubeIndex,"SYNC")
			Set tSC = ..%BuildOneCube(pCubeName,pAsync,pVerbose)
			Quit
		}

		// also test all possible subclasses of source class
		Merge tClassList = tSourceInfo("sourceSubClass")

		// check if there are outstanding changes to the source table(s)
		// use merged list
		Merge tMergeList = tClassList
		Merge tMergeList = tStarList
		
		If (tLastTimeStamp = $G($$$DeepSeeUpdateQueue)) {
			Set tChanges = 0
			// check each class
			Set tClass = $O(tMergeList(""))
			While ((tClass'="")&&('tChanges)) {
				If ($D($$$DeepSeeUpdateBuffer(tClass))) {
					Set tChanges = 1
				}
				Set tClass = $O(tMergeList(tClass))
			}
			If ('tChanges) {
				// DTB422 - Consider this a data update - cube was up-to-date as of xxx
				Set $$$DeepSeeUpdateQueue("cubes",tCubeName,"lastDataUpdate") = $ZTIMESTAMP
				Write:pVerbose "No changes detected.",!

				Set tCubeEvent.EventStatus = tSC
				Set tCubeEvent.FinishTime = $ZDT($H,3)
				Set tCubeEvent.CubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeIndex)
				Set tCubeEvent.FactsUpdated = pFactsUpdated	
				Set tSC = tCubeEvent.%Save()
				
				Quit
			}
		}
		
		// DTB422 - Safely transfer update IDs in each class from the buffer to the
		// concurrency protected update global. This is done within the
		// synchronize lock so only one process may do this at a time.
		Set tClass = $O(tClassList(""))
		While tClass'="" {
			Set tSC = ..%ProcessUpdateBuffer(tClass)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			Set tClass = $O(tClassList(tClass))
		}

		// DTB422 - Cube updates no longer care about the source's dsinterval setting, everything will get translated to an increment-style
		// update log.
		Set tNewTimeStamp = $I($$$DeepSeeUpdateQueue)
		
		Set tCounter = 0
		Set tFactsUpdated = 0
		Set tErrors = 0

		// apply all changes to reference clases 
		// we care about update, and ignore deletes and inserts
		// as they will be handled if and when the main source table changes

		Set tClass = $O(tStarList(""))
		While (tClass'="") {
			Set ts = +tLastTimeStamp
			While ((ts'="")&&(ts<tNewTimeStamp)) {
				Set id = $O($$$DeepSeeUpdateQueue(tClass,ts,""),1,reason)
				While (id'="") {
					Set tCounter = tCounter + 1
					Set tDelta = 0
					// call fact class (once per change)
					If ($G(reason)=0) {
						// update
						Kill tDimList
						Merge tDimList = tStarListTables(tClass)
						
						// NB (DTB891): If this is revived the fact list needs to be taken into consideration!
						// JMD783 	Set tSC = $zobjclassmethod(tClassName,"%UpdateFacts","","",,pVerbose,,.tDelta,tStarList(tClass),id,.tDimList)
					}
					ElseIf ($G(reason)=2) {
						// delete (ignore)
					}
					If $$$ISERR(tSC) {
						// JMD1474: ignore error and continue
						Set tErrors = tErrors + 1
						Set tSC = $$$OK
					}
					Else {
						Set tFactsUpdated = tFactsUpdated + tDelta
					}
					If (pVerbose && '(tCounter#100)) {
						Write $C(13,27)_"[0J"
						Write $FN(tFactsUpdated,",",0)," fact(s) updated"
					}
					Set id = $O($$$DeepSeeUpdateQueue(tClass,ts,id),1,reason)
				}
				If $$$ISERR(tSC) Quit
				Set ts = $O($$$DeepSeeUpdateQueue(tClass,ts))
			}
			If $$$ISERR(tSC) Quit
			Set tClass = $O(tStarList(tClass))
		}
		If $$$ISERR(tSC) Quit

		// get the list of modified source class records since last sync point
		// and apply them
		Set tClass = $O(tClassList(""))
		While (tClass'="") {
			Set ts = +tLastTimeStamp
			While ((ts'="")&&(ts<tNewTimeStamp)) {
				Set id = $O($$$DeepSeeUpdateQueue(tClass,ts,""),1,reason)
				While (id'="") {
					Set tCounter = tCounter + 1
					// call fact class (once per change)
					If pAsync {
						// DTB976 - Use chunks of 64k facts at a time
						Set tChunk = tCounter\64000+1
						Set tOffset = tCounter#64000+1
						// PFS094 - Include reason into temp file so deletes can be asynchronous
						Set:id'="" $$$DeepSeeTempSourceId(tCubeIndex,tChunk,id) = $LB("",$G(reason))		// DP-412844
					}
					Else {
						// PFS094 - Only handle delete here if in synchronous mode
						// PFS013 - Properly remove fact from cube if update reason = 2
						If '$zobjclassmethod(tClassName,"%CheckSourceId",id) || ($G(reason)=2) {
							// DTB300 - Deletion is still only done synchronously
							Set tSC = $classmethod(tClassName,"%DeleteFact",id)
						} Else {
							// JMD1450 Test for missing references
							Set %dsMissingRef = 0
							Set tSC = $classmethod(tClassName,"%UpdateFacts",id)
							
							If (pCheckReferences && %dsMissingRef) {
								Set tMissingRefs = tMissingRefs + 1
							}
							Kill %dsMissingRef
							
							If $$$ISERR(tSC) {
								// JMD1474: ignore error and continue
								Set tErrors = tErrors + 1
								Set tSC = $$$OK
							}
							Else {
								Set tFactsUpdated = tFactsUpdated + 1
							}
							If (pVerbose && '(tCounter#100)) {
								Write $C(13,27)_"[0J"
								Write $FN(tFactsUpdated,",",0)," fact(s) updated"
							}
						}
					}
					
					Set id = $O($$$DeepSeeUpdateQueue(tClass,ts,id),1,reason)
				}
				If $$$ISERR(tSC) Quit
				
				If pAsync&&($G(tChunk)>0) {
			  		// DTB300 - use background tasks to process the temp file for this timestamp
			  		If pVerbose {
				  		// DTB976 - The task count is the value of tChunk after the offset loop completes
				  		Write !,"Synchronize time interval " _ ts _ " using " _ tChunk _ " background tasks",!
			  		}
			  		
			  		Set %dsMissingRef = 0
					Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tGroupId,1,"SYNCHRONIZE")		// DTB704 - This is now handled by the %DeepSee.WorkMgr
					If $$$ISERR(tSC) Quit

					$$$dsSetAppInfo($LB(tCubeIndex,pAsync,$G(tGroupId)))		// DP-419418 - Update the activity monitor with group ID

					Kill $$$DeepSeeTempUpdate($namespace,tGroupId)
					
					// Queue a task to update facts for each "chunk" in high-priority synchronize mode.
					Set tChunk = $O($$$DeepSeeTempSourceId(tCubeIndex,""))		// DP-412844
					While (tChunk '= "") {
						// DTB704 - This is now handled by the %DeepSee.WorkMgr
						Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tGroupId, "UPDATEFACTSTEMP",tCubeName,"",tCubeIndex,tChunk,pAsync)
						If $$$ISERR(tSC) Quit
						Set tChunk = $O($$$DeepSeeTempSourceId(tCubeIndex,tChunk))		// DP-412844
					}
					If $$$ISERR(tSC) Quit
					
					Set tSC = ##class(%DeepSee.WorkMgr).%WaitForTaskGroup(tGroupId)

					// Kill temp file independent of task status. This will be rebuilt in the next call if needed.
					Kill $$$DeepSeeTempSourceId(tCubeIndex)		// DP-412844 - Table storage is now organized by cube index
					If $$$ISERR(tSC) Quit
					
					// Read the statistics recorded by the background agents
					//Set tFactsUpdated=$G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
					Set tFactsUpdated = tFactsUpdated + $G($$$DeepSeeTempUpdate($namespace,tGroupId,"facts"))
					Set tErrors=$G($$$DeepSeeTempUpdate($namespace,tGroupId,"errors"))
					If (pCheckReferences) {
						Set tMissingRefs = tMissingRefs + $G($$$DeepSeeTempUpdate($namespace,tGroupId,"missing"))
					}
				}
				
				Set ts = $O($$$DeepSeeUpdateQueue(tClass,ts))
			}
			If $$$ISERR(tSC) Quit
			Set tClass = $O(tClassList(tClass))
		}
		If $$$ISERR(tSC) Quit

		// update sync point (timestamp)
		// DTB422 - No such thing as an interval type anymore. Always update to allow a purge up to this timestamp
		// WAL243 - update DSTIME regardless of whether we have missing refs/errors
		Set tSC = ..%SetCubeDSTime(tCubeName,tNewTimeStamp)
		Set $$$DeepSeeUpdateQueue("cubes",tCubeName,"lastDataUpdate") = $ZTIMESTAMP		// DTB422

		If (pVerbose) {
			Write $C(13,27)_"[0J"
			Write $FN(tFactsUpdated,",",0), " fact(s) updated" _ $S(pAsync:" asynchronously",1:""),!
			Write:tErrors $FN(tErrors,",",0), " error(s)",!
			Write:tMissingRefs $FN(tMissingRefs,",",0), " missing reference(s)",!
			Write "Elapsed time: ",$ZH-tStart,"s",!
		}
		
		Set pFactsUpdated = +$G(tFactsUpdated)		// DTB448
		
		// + WAL270 -- return synchronize statistics
		// DTB404 - Protect read of statistics with $Get()
		// DTB423 - Remove formatting from statistics
		Set pSynchronizeStatistics("factCount") = +$G(tFactsUpdated)
		Set pSynchronizeStatistics("errors") = +$G(tErrors)
		Set pSynchronizeStatistics("missingReferences") = +$G(tMissingRefs)
		Set pSynchronizeStatistics("elapsedTime") = $ZH-$G(tStart)
		If ($G(tCubeIndex)'="") {
			// DTB432 - Add additional synchronize statistics
			Set pSynchronizeStatistics("expressionTime") = +$G(^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeName,"expr"))
			Set pSynchronizeStatistics("iKnowTime") = +$G(^IRIS.Temp.DeepSeeBuildStats($namespace,tCubeName,"iknow"))
		}
		// - WAL270

		// DTB1130 - Run a purge operation if the cache wasn't already deleted by %BuildCube
		If '$G(%dsBuildLock) {
			Write:pVerbose !,"Purging cache...",!
			Set tSC = ..%DeleteObsoleteCache(pCubeName)
			If $$$ISERR(tSC) Quit

			Set tSC = ..%PurgeDSTIME()
			If $$$ISERR(tSC) Quit
		}

		Set tCubeEvent.EventStatus = tSC
		Set tCubeEvent.FinishTime = $ZDT($H,3)
		Set tCubeEvent.CubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeIndex)
		Set tCubeEvent.FactsUpdated = pFactsUpdated	

		Set tCubeEvent.ExprTime = $Get(pSynchronizeStatistics("expressionTime"))
		Set tCubeEvent.ErrorCount = $Get(pSynchronizeStatistics("errors"))
		Set tCubeEvent.MissingRefs = $Get(pSynchronizeStatistics("missingReferences"))

		Set tSC = tCubeEvent.%Save()

		// DP-430862 - Run the cube's PostSynchCode if it is defined
		Set tSC = ##class(%DeepSee.CubeUtils).ExecuteCustomCode(tCubeIndex,"postsynch")
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	// Record this final status in the CubeEvent if one was created
	If $IsObject($G(tCubeEvent)) {
		Set tCubeEvent.EventStatus = tSC
		Set tCubeEvent.FinishTime = $ZDT($H,3)
		Do tCubeEvent.%Save()
	}

	If (tSyncIsLocked) {
		Lock -^DeepSee.Build(tCubeIndex,"SYNC")
	}
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
	}

	Quit tSC
}

/// Process the ^OBJ.DSTIME update buffer into the concurrency-protected
/// update global. To protect an update entry in the ^OBJ.DSTIME buffer within
/// a transaction, the process setting the buffer should use
/// <example language="cos">
/// 	Lock +^DeepSee.Build(pClassName,ID)
/// </example>
/// The <var>ID</var> is not needed for concurrency protection between the transactional process
/// and <method>%ProcessUpdateBuffer</method>, but will prevent lock contention between
/// transactional processes if this is used.
ClassMethod %ProcessUpdateBuffer(pClassName = "", pNoKill = 0) As %Status [ Internal ]
{
	// Method added by DTB422
	Set tSC = $$$OK

	Try {
		If (pClassName = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No class name supplied to process updates.")
			Quit
		}
		
		// Take out a special lock on the class in order to prevent two processes from attempting to perform this
		// buffer processing. Without this, two cubes based on the same class getting synchronized at the same time
		// could trigger the original problem again!
		Lock +^DeepSee.Build(pClassName,"Process DSTIME"):30 
		If '$Test {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to obtain the lock needed to process the OBJ.DSTIME update buffer: " _ pClassName)
			Quit
		}
		
		If ..%HasUpdates(pClassName) {
			// Interval vs. Increment is ignored for the buffered update. Only increment exists in
			// the local update global.
			// N.B. The increment of the top node is controlled in the synchronize call.
			// This transfer acts like a production update - the method setting the
			// update entry does not bump the top node!
			Set tNewTimestamp = +$G($$$DeepSeeUpdateQueue)

			Set tSourceTimestamp = $O($$$DeepSeeUpdateBuffer(pClassName,""))
			While (tSourceTimestamp'="") {
				Set tID = $O($$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp,""),1,tType)
				While tID'="" {
					Set $$$DeepSeeUpdateQueue(pClassName,tNewTimestamp,tID) = tType
					// Remove this ID from the buffer
					Kill:'pNoKill $$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp,tID)
					
					Set tID = $O($$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp,tID),1,tType)
				}
				
				Set $$$DeepSeeUpdateQueue("classes",pClassName,"lastTimestamp") = tSourceTimestamp		// DTB503
	
				Set tSourceTimestamp = $O($$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp))
			}
		}
		Lock -^DeepSee.Build(pClassName,"Process DSTIME")		// Release the lock
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Lock -^DeepSee.Build(pClassName,"Process DSTIME")		// Release the lock
	}
	Quit tSC
}

/// Clear the update buffer for a given class. This will completely remove the current contents
/// of ^OBJ.DSTIME(<var>pClassName</var>).
ClassMethod %ClearUpdateBuffer(pClassName = "") As %Status [ Internal ]
{
	// Method added by DTB422
	Set tSC = $$$OK
	Try {
		If (pClassName = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No class name supplied to process updates.")
			Quit
		}
		
		If ..%HasUpdates(pClassName) {
			// Loop through all timestamps and IDs under this source class.
			Set tSourceTimestamp = $O($$$DeepSeeUpdateBuffer(pClassName,""))
			While (tSourceTimestamp'="") {
				Set tID = $O($$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp,""),1,tType)
				While tID'="" {
					// Remove this ID from the buffer
					Kill $$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp,tID)
					
					Set tID = $O($$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp,tID),1,tType)
				}
	
				Set tSourceTimestamp = $O($$$DeepSeeUpdateBuffer(pClassName,tSourceTimestamp))
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test the ^OBJ.DSTIME update buffer for new updates in the class <var>pClassName</var>
ClassMethod %HasUpdates(pClassName = "") As %Boolean
{
	// Method added by DTB422
	Set tHasUpdates = 0
	Try {
		If (pClassName = "") {
			// Noting to test for updates
			Quit
		}
		
		Set tHasUpdates = $D($$$DeepSeeUpdateBuffer(pClassName))
	}
	Catch ex {
		Set tHasUpdates = 0
	}
	
	Quit tHasUpdates
}

/// Update the sync timestamp for the given cube.
ClassMethod %SetCubeDSTime(pCubeName As %String, pVersion As %Integer = "") As %Status
{
	Set tSC = $$$OK
	Try {
		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$GeneralError,"%SetCubeDSTime cannot be called on a SubjectArea: " _ pCubeName)
			Quit
		}
		
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		// update sync point (timestamp)
		Set $$$DeepSeeUpdateQueue("cubes",tCubeIndex,"dstime") = pVersion
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Query the sync timestamp for the given cube.
ClassMethod %GetCubeDSTime(pCubeName As %String, Output pStatus As %Status) As %Integer
{
	// Method added by DTB422
	Set tDsTime = ""
	Set pStatus = $$$OK
	
	Try {
		If ('..%IsBaseCube(pCubeName)) {
			Set pStatus = $$$ERROR($$$GeneralError,"%GetCubeDSTime cannot be called on a SubjectArea: " _ pCubeName)
			Quit
		}
		
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		// update sync point (timestamp)
		Set tDsTime = +$G($$$DeepSeeUpdateQueue("cubes",tCubeIndex,"dstime"))		// DTB838 - Protect query of the global if the update queue hasn't been written to yet
 	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}
	Quit tDsTime
}

/// Purge all entries in the listing cache older than <var>pStartDay</var>. If this is
/// omitted, the start day used will be the current day.
ClassMethod %PurgeListings(pVerbose As %Integer = 0, pStartDay = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCount = 0
		Set tDay = $S(pStartDay'="":pStartDay,1:+$H)		// DTB531
		// find all days in cache prior to today
		Set tDay = $O($$$DeepSeeListingResultsGLVN(tDay),-1)
		While (tDay'="") {
			Write:pVerbose "Deleting listings for ",$ZDT(tDay,3),!
			Kill $$$DeepSeeListingResultsGLVN(tDay)
			Set tCount = tCount + 1
			Set tDay = $O($$$DeepSeeListingResultsGLVN(tDay),-1)
		}

		Write:pVerbose "Completed: ",tCount," listing(s) purged",!
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// <p><method>%PurgeDSTIME</method> purges all nodes in ^DeepSee.Update that have already been processed by all cubes,
/// and by all classes that extend <class>%DeepSee.TimeSync</class>.
/// This method checks the DSTIME value for each cube, and for each class that extends %DeepSee.TimeSync, 
/// and computes the oldest DSTIME value that has not yet been
/// synchronized. All DSTIME values older than that time are purged from the DSTIME index.</p>
/// <p>If a class has entries in the DSTIME index and no cubes use that class as a source class then those DSTIME
/// entries are not purged.</p>
/// <p>
/// <table border=1>
/// <th>
/// Parameters
/// </th>
/// <tr>
/// 		<td>pVerbose</td>
/// 		<td>Input</td>
/// 		<td>
/// 			If true then status messages will be displayed on the current device.
/// 		</td>
/// </tr>
/// <tr>
/// 		<td>pPurged</td>
/// 		<td>Output</td>
/// 		<td>
/// 			An array of DSTIME entries that have been purged. For example:
/// 			<pre>
/// 		purged("DeepSee.Study.CityRainfall")=1
/// 		purged("DeepSee.Study.Patient")=2
/// 		purged("HoleFoods.Transaction")=0
/// 			</pre>
/// 			The array subscript is the class name and the value is the DSTIME value that was purged.
/// 		</td>
/// </tr>
/// </table>
/// </p>
/// <br>
/// 	<p>
/// 	<b>Return value</b>: This method returns a %Status value indicating success or failure.
/// 	</p>
ClassMethod %PurgeDSTIME(pVerbose As %Integer = 0, Output pPurged As %Library.String(MAXLEN="")) As %Status
{
	//  Build array of source classes and the cubes that use them
	try {
		kill pPurged
		set tCube = $order($$$DeepSeeMetaGLVN("cubes",""))
		while (tCube '= "") {
			set tIsCube = ..%IsBaseCube(tCube)
			if tIsCube {
				// get cube class
				Set tClassName = ..%GetCubeClass(tCube,.tSC)
				If (tClassName'="") {
					// get details on cube's source class
					Set tSC = $zobjclassmethod(tClassName,"%GetSourceInfo",.tSourceInfo)
					If $$$ISERR(tSC) Quit

					// create list of cube's source class and subclasses (if any)
					Kill tCubeSources
					set tSourceClass = $Get($$$DeepSeeMetaGLVN("cubes",tCube,"sourceClass"))
					If (tSourceClass'="") {
						Set tCubeSources(tSourceClass) = ""
					}
					Merge tCubeSources = tSourceInfo("sourceSubClass")			

					// look at each source class
					Set tSourceClass = $O(tCubeSources(""))
					While (tSourceClass'="") {
						set tCubeTime = ##class(%DeepSee.Utils).%GetCubeDSTime(tCube)		// DTB422 - DSTIME stamp is in the update global		// DTB838 - Use API

						// For each source class in ^DeepSee.Update, find the oldest to-be-processed timestamp from the cubes
						if '$Data(tSourceClassList(tSourceClass)) { 
							set tSourceClassList(tSourceClass) = tCubeTime
						}
						elseif (tCubeTime < tSourceClassList(tSourceClass)) { 
							set tSourceClassList(tSourceClass) = tCubeTime
						}
						set tSourceClassList(tSourceClass,tCube) =  tCubeTime

						Set tSourceClass = $O(tCubeSources(tSourceClass))
					}
				}
			}
			set tCube = $order($$$DeepSeeMetaGLVN("cubes",tCube))
		}
		// JMM581:
		// Now iterate over non-cube "consumer" classes, and add their source classes to the list if not already
		// present, or adjust the oldest to-be-processed timestamp if older than the oldest found previously
		set tConsumerClass = $order($$$DeepSeeDSTIMENonCubeConsumers(""))
		while (tConsumerClass '= "") {
			// For each source class of this consumer, add to list of source classes, or if already present,
			// adjust oldest to-be-processed timestamp
			set tSourceClass = $order($$$DeepSeeDSTIMECheckpoint(tConsumerClass,""))
			while (tSourceClass'="") {
				set tCheckpointTime = $g($$$DeepSeeDSTIMECheckpoint(tConsumerClass,tSourceClass))
				if '$Data(tSourceClassList(tSourceClass)) { 
					set tSourceClassList(tSourceClass) = tCheckpointTime
				}
				elseif (tCheckpointTime < tSourceClassList(tSourceClass)) { 
					set tSourceClassList(tSourceClass) = tCheckpointTime
				}
				if $Data(tSourceClassList(tSourceClass,tConsumerClass)) {
					// TBD: This would mean a consumer classname was the same as a cube name. 
					// However, the existing code never uses this once it's been set.
				}
				else {
					set tSourceClassList(tSourceClass,tConsumerClass) =  tCheckpointTime
				}
				set tSourceClass = $order($$$DeepSeeDSTIMECheckpoint(tConsumerClass,tSourceClass))
			}
			set tConsumerClass = $order($$$DeepSeeDSTIMENonCubeConsumers(tConsumerClass))
		}

		set tSourceClass = $Order($$$DeepSeeUpdateQueue(""))
		while (tSourceClass '= "") {
			// For the source class, kill all entries in ^DeepSee.Update < the oldest timestamp to-be-processed.
			// (since they have aleady been processed by all cubes that use the source class)
			// Also, kill all DSTIME entries for the source class if there are no cubes defined.
			// Jeff Miller 6/17/14: The above line appears to be incorrect, no DSTIME entries are killed for
			// a source class if there are no cubes (or, now, non-cube consumer classes) defined.
			// What should we do if the oldest cube time is null? Wouldn't this indicate that no cubes have yet
			// been sync'ed and that a %BuildCube call should be used?

			if (tSourceClass '= $$$DeepSeeDSTIMECheckpointSubscript)&&(tSourceClass'="cubes") {
				if pVerbose {
					write !,"Processing class '",tSourceClass,"'. "
					if $Data(tSourceClassList(tSourceClass)) {
						write "Oldest DSTIME synchronized: ",$Select(tSourceClassList(tSourceClass):tSourceClassList(tSourceClass),1:"<<all>>")
					}
					else { write "No cubes using this class as a source have been found!" }
				}
				if $Get(tSourceClassList(tSourceClass)) '="" {
					set tIndex = $Order($$$DeepSeeUpdateQueue(tSourceClass,""))
					while (tIndex '= "") && (tIndex < tSourceClassList(tSourceClass)) {
						kill $$$DeepSeeUpdateQueue(tSourceClass,tIndex)
						set pPurged(tSourceClass) = tIndex
						if pVerbose {
							write !,$Char(9),"purged DSTIME('",tSourceClass,"',",tIndex,")"
						}
						set tIndex = $o($$$DeepSeeUpdateQueue(tSourceClass,tIndex))
					}
				}
			}
			set tSourceClass = $o($$$DeepSeeUpdateQueue(tSourceClass))
	 	}
	 	if pVerbose {
		 	write !,"Complete."
		 	if '$Data(pPurged) {
			 	write " No DSTIME entries were purged."
		 	}
	 	}
	 	set tSC = $$$OK
	}
	catch tException {
		set tSC = tException.AsStatus()
		if pVerbose {
			write !,"An error occurred: "
			do $system.OBJ.DisplayError(tSC)
		}
	}
	quit tSC
}

/// Purge the ^OBJ.DSTIME update buffer when there are no cubes present to clear entries
/// via updates.<br>
/// <var>pClass</var> [Required] - The class to be purged from the ^OBJ.DSTIME update buffer.
/// The "*" wildcard may be used to purge all classes present in the buffer.<br>
/// <var>pPurgeUpTo</var> [Required] - This is the oldest timestamp that must be retained in the purge.
/// Every entry older than this will be removed. The "*" wildcard may be used to remove all entries for
/// the given <var>pClass</var>.<br>
/// <var>pIncrement</var> - If true, the purge method will automatically advance the top node of ^OBJ.DSTIME
/// to advance the timestamp of all non-interval type entries to support the next purge. This parameter is set to
/// 1 by default.
ClassMethod %PurgeUpdateBuffer(pClass As %String = "", pPurgeUpTo As %String = "", pIncrement As %Boolean = 1, pVerbose As %Boolean = 0) As %Status
{
	// Method added by DTB503
	Set tClassRequest = $G(pClass)			// Name of the class to be purged from ^OBJ.DSTIME
	Set tPurgeTo = $G(pPurgeUpTo)			// The final timestamp that should be purged
	Set tPurgeAll = ($G(pPurgeUpTo)="*")	// If true, purge everything under the class
	
	Set tSC = $$$OK
	Try {
		// Test input arguments
		If (tClassRequest="") {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Class name must be provided to purge DeepSee update buffer."))
			Quit
		}
		
		If (tPurgeTo="") {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Timestamp must be provided to purge DeepSee update buffer."))
			Quit
		}

		
		// Increment the top counter 
		Set:pIncrement x = $I($$$DeepSeeUpdateBuffer)
		
		// Determine the list of classes that should be purged
		If tClassRequest="*" {
			Set tClass = $O($$$DeepSeeUpdateBuffer(""))
			While tClass'="" {
				Set tClasses(tClass)=""
				Set tClass = $O($$$DeepSeeUpdateBuffer(tClass))
			}
		}
		Else {
			Set tClasses(tClassRequest) = ""
		}

		// Work through the list of classes and execute the purge
		Set tClass = $O(tClasses(""))
		While tClass'="" {
			If '##class(%Dictionary.CompiledClass).%ExistsId(tClass) {
				Set tSC = $$$ERROR(5351,tClass)
				$$$ThrowStatus(tSC)
			}
			
			If tPurgeAll {
				Write:pVerbose !,"Purging all entries for class " _ tClass
				Kill $$$DeepSeeUpdateBuffer(tClass)
			}
			Else {
				// Find the last actual timestamp in the global which collates before the requested purgeTo timestamp
				//Set tPurgeTo = $O($$$DeepSeeUpdateBuffer(tClass,tPurgeTo),-1)
				
				Set tTimestamp = $O($$$DeepSeeUpdateBuffer(tClass,""))
				While ((tTimestamp'="")&&(tPurgeTo ] tTimestamp)) {
					Write:pVerbose !,"Purging "_tClass _ ":" _ tTimestamp
					Kill $$$DeepSeeUpdateBuffer(tClass,tTimestamp)
					
					Set tTimestamp = $O($$$DeepSeeUpdateBuffer(tClass,tTimestamp))		// Work backward from the target purge timestamp
				}
			}
			
			Set tClass = $O(tClasses(tClass))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete all indices and cache values for the given cube.
ClassMethod %KillCube(pCubeName As %String = "", pForce = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pCubeName = "") {
			Set tSC = $$$ERROR($$$CubeNameRequired,$$$dsCurrentMethod)
			Quit
		}
		If '..%IsCubePhysical(pCubeName,.tSC) Quit		// DP-431688

		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		If ##class(%DeepSee.CubeVersion.Utils).%IsActiveVersion(pCubeName)&&'pForce {
			// DTB216 - Prevent unintentional kill of active cube
			Set tSC = $$$ERROR($$$GeneralError,pCubeName _ " is the active version. %KillCube must be forced for an active cube version: " _ pCubeName)
			Quit
		}

		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$GeneralError,"%KillCube cannot be called on a SubjectArea: " _ pCubeName)
			Quit
		}

		Set tFactClass = $zobjclassmethod(tClassName,"%GetFactClass")
		Set tSC = $zobjclassmethod(tClassName,"%KillFacts")
		If $$$ISERR(tSC) Quit
		
		Kill $$$DeepSeeBuildErrorsGLVN($$$DeepSeeIndex(pCubeName))		// DTB603 - Remove build errors
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Delete any KPI cache values for the given cube.
ClassMethod %KillKPICacheForCube(pCubeName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCubeName = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)

		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$GeneralError,"%KillKPICacheForCube cannot be called on a SubjectArea: " _ pCubeName)
			Quit
		}
		If $D($$$DeepSeeKPIGLVN("-index-",tCubeIndex)) {
			Set tKPI = $O($$$DeepSeeKPIGLVN("-index-",tCubeIndex,""))
			While (tKPI'="") {
				Kill $$$DeepSeeKPIGLVN(tKPI)
				Kill $$$DeepSeeKPIGLVN("-index-",tCubeIndex,tKPI)
				Set tKPI = $O($$$DeepSeeKPIGLVN("-index-",tCubeIndex,tKPI))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the logical name of its %COUNT measure.
ClassMethod %GetCountName(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tName = "%COUNT"
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tName = $zobjclassmethod(tClassName,"%GetCountName")
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}
	Quit tName
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the display name of its %COUNT measure.
ClassMethod %GetCountCaption(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tName = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tName = $zobjclassmethod(tClassName,"%GetCountCaption")
		}
	}
	Catch(ex) {
		Set tName = ""
		Set pStatus = ex.AsStatus()
	}
	If (tName="") {
		Set tName = ..%GetCountName(pCubeName)
		If ($$$UPPER(tName) ="%COUNT") {
			Set tName = $$$Text("Count","%DeepSee")
		}
	}
	Quit tName
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the class name of its fact table.
ClassMethod %GetCubeFactClass(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tFactClass = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tFactClass = $zobjclassmethod(tClassName,"%GetFactClass")
		}
	}
	Catch(ex) {
		Set tFactClass = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tFactClass
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the SQL name of its fact table.
ClassMethod %GetCubeFactTable(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tFactTable = ""
	Set pStatus = $$$OK
	Try {
		Set tFactClass = ..%GetCubeFactClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tFactTable = ##class(%DeepSee.Generator).%GetSQLTableName(tFactClass)
	}
	Catch(ex) {
		Set tFactTable = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tFactTable
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the number of rows within its fact table.
ClassMethod %GetCubeFactCount(pCubeName As %String, Output pStatus As %Status) As %Integer
{
	Set tCount = 0
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tCount = $zobjclassmethod(tClassName,"%GetFactCount")
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tCount
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the number of members within the given dimension level.
ClassMethod %GetCubeMemberCount(pCubeName As %String, Output pStatus As %Status, pDimName As %String = "", pHierName As %String = "", pLevelName As %String = "") As %Integer
{
	Set tCount = 0
	Set pStatus = $$$OK
	Try {
		Set tCube = $$$UPPER(pCubeName)
		If ((pLevelName'="")&&(pHierName'="")&&(pDimName'="")) {
			Set tMbrNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),$$$UPPER(pLevelName)))
		}
		ElseIf ((pHierName'="")&&(pDimName'="")) {
			Set tMbrNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName)))
		}
		ElseIf (pDimName'="") {
			Set tMbrNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",$$$UPPER(pDimName)))
		}
		Else {
			Quit
		}

		If (tMbrNode = "") {
			Set pStatus = $$$ERROR($$$GeneralError,"Level not found")
			Quit
		}

		Set tDimNo = +$LG(tMbrNode,1)
		Set tHierNo = +$LG(tMbrNode,2)
		Set tLevelNo = +$LG(tMbrNode,3)
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo))
		Set tClass = $LG(tInfo,6)
		If ((tClass'="")&&$$$comClassDefined(tClass)) {
			Try {
				If $zobjclassmethod(tClass,"%IsA","%DeepSee.ComputedDimension.Base") {
					// provide more info for computed dims
					Set tCount = $zobjclassmethod(tClass,"%Count",tCube,tDimNo,tHierNo,tLevelNo)
				}
				ElseIf $zobjclassmethod(tClass,"%IsA","%DeepSee.Time.AbstractLevel") {
					Set tCount = $zobjclassmethod(tClass,"%Count",tCube,tDimNo,tHierNo,tLevelNo)
				}
				Else {
					Set tCount = $zobjclassmethod(tClass,"%Count")
				}
			}
			Catch(ex) {
				// swall errors
			}
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tCount
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return its name in its original case.
ClassMethod %GetCubeName(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tName = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tName = $zobjclassmethod(tClassName,"%GetCubeName")
		}
		If (tName="")&&(tClassName'="") {
			// DTB949 - If we still have no cube name at this point, look directly at the metadata
			// to try to fill it in.
			Set tName = $G($$$DeepSeeMetaGLVN("classes",tClassName))
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tName
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// test if it is abstract.<br/>
/// An abstract cube does not contain any data and cannot be queried.
ClassMethod %IsCubeAbstract(pCubeName As %String, Output pStatus As %Status) As %Boolean
{
	Set tAbstract = 0
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tAbstract = $zobjclassmethod(tClassName,"%IsAbstract")
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tAbstract
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// test if it is a compound cube (composed of two or more cubes joined together).<br/>
ClassMethod %IsCubeCompound(pCubeName As %String, Output pJoinList As %String, Output pStatus As %Status) As %Boolean
{
	Set tCompound = 0
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tCompound = $zobjclassmethod(tClassName,"%IsCompound",.pJoinList)
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tCompound
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the date and time that the cube definition was last modifed.
ClassMethod %GetCubeModifiedDate(pCubeName As %String, Output pStatus As %Status) As %DeepSee.Datatype.dateTime
{
	Set tDate = ""
	Set pStatus = $$$OK
	Try {
		Set tDate = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"lastSchemaUpdate"))
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tDate
}

/// Given the logical name, <var>pKPI</var> of a DeepSee KPI,
/// return the date of the time the KPI definition was modified (in $H format).
ClassMethod %GetKPIModifiedDate(pKPI As %String, Output pStatus As %Status) As %DeepSee.Datatype.dateTime
{
	Set tDate = ""
	Set pStatus = $$$OK
	Try {
		Set tDate = $G($$$DeepSeeMetaGLVN("kpis",$$$UPPER(pKPI),"lastSchemaUpdate"))
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tDate
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube, return its caption.
ClassMethod %GetCubeCaption(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tCaption = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tCaption = $zobjclassmethod(tClassName,"%GetCubeCaption")
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tCaption
}

/// Given the logical name, <var>pKPI</var> of a DeepSee KPI, return its caption.
ClassMethod %GetKPICaption(pKPI As %String, Output pStatus As %Status) As %String
{
	Set tCaption = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetKPIClass(pKPI,.pStatus)
		If $$$ISOK(pStatus) {
			Set tCaption = $zobjclassmethod(tClassName,"%GetKPICaption")
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tCaption
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// test if it exists.
ClassMethod %CubeExists(pCubeName As %String = "", Output pStatus As %Status) As %Boolean
{
	Set pStatus = $$$OK
	If ($G(pCubeName)="") {
		// DTB790 - Return an error if called without a Cube name
		Set pStatus = $$$ERROR($$$GeneralError,"Cube name must be supplied")
		Quit 0
	}
	Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
	Quit (tClassName'="")
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// test if it exists.
ClassMethod %KPIExists(pKPIName As %String = "", Output pStatus As %Status) As %Boolean
{
	// Method added by DTB297
	Set pStatus = $$$OK
	If ($G(pKPIName)="") {
		// DTB790 - Return an error if called without a KPI name
		Set pStatus = $$$ERROR($$$GeneralError,"KPI name must be supplied")
		Quit 0
	}
	Set tClassName = ..%GetKPIClass(pKPIName,.pStatus)
	Quit (tClassName'="")
}

/// Test that the current user holds privileges on the given cube.
ClassMethod %CheckPrivilege(pCubeName As %String) As %Boolean [ Final ]
{
	// JMD1472 treat "disabled" as no privilege
	Set tDisabled = +$G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"disabled"))
	Quit:tDisabled 0

	Set tResource = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"resource"))
	Quit ((tResource="")||$System.Security.Check(tResource,"READ")||$System.Security.Check(tResource,"USE"))
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the class name of the cube definition.
ClassMethod %GetCubeClass(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tClassName = ""
	Set pStatus = $$$OK
	Try {
		// No privilege is same as does not exist
		If ((pCubeName'="")&&($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName)))'="")&&..%CheckPrivilege(pCubeName)) {
			Set tClassName = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName))
		}
		Else {
			Set pStatus = $$$ERROR($$$GeneralError,"Cannot find Subject Area: '" _ pCubeName _ "'")
		}
	}
	Catch(ex) {
		Set tClassName = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tClassName
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the class name of it associated actionClass, if any.
ClassMethod %GetCubeActionClass(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tClassName = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"actionClass"))
	}
	Catch(ex) {
		Set tClassName = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tClassName
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube return its class description.
ClassMethod %GetCubeDescription(pCubeName As %String, Output pStatus As %Status) As %String
{
	Set tDesc = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISERR(pStatus) Quit

		Set tDesc = $$$comClassKeyGet(tClassName,$$$cCLASSdescription)
	}
	Catch(ex) {
		Set tDesc = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tDesc
}

/// Given the logical name, <var>pKPIName</var> of a DeepSee KPI,
/// return its name in its original case.
ClassMethod %GetKPIName(pKPIName As %String, Output pStatus As %Status) As %String
{
	Set tName = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetKPIClass(pKPIName,.pStatus)
		If ($$$ISOK(pStatus)&&(tClassName'="")) {
			Set tName = $zobjclassmethod(tClassName,"%GetKPIName",pKPIName)
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tName
}

/// Given the logical name, <var>pKPIName</var> of a DeepSee KPI, test if it is public.
ClassMethod %IsKPIPublic(pKPIName As %String) As %Boolean
{
	Set tPublic = 0
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetKPIClass(pKPIName,.pStatus)
		If ($$$ISOK(pStatus)&&(tClassName'="")) {
			Set tPublic = $classmethod(tClassName,"%IsPublic")
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}
	Quit tPublic
}

/// Given the logical name, <var>pKPIName</var> of a DeepSee KPI return its class description.
ClassMethod %GetKPIDescription(pKPIName As %String, Output pStatus As %Status) As %String
{
	Set tDesc = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetKPIClass(pKPIName,.pStatus)
		If $$$ISERR(pStatus) Quit

		Set tDesc = $$$comClassKeyGet(tClassName,$$$cCLASSdescription)
	}
	Catch(ex) {
		Set tDesc = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tDesc
}

/// Given the logical name, <var>pKPIName</var> of a DeepSee KPI,
/// return the class name of the KPI definition.
ClassMethod %GetKPIClass(pKPIName As %String, Output pStatus As %Status) As %String
{
	Set tClassName = ""
	Set pStatus = $$$OK
	Try {
		// check for extensions
		Set tExt = $P(pKPIName,".",$L(pKPIName,"."))
		If (tExt = "worksheet") {
			Set tClassName = "%DeepSee.KPIWorksheet"
			Quit
		}
		ElseIf (tExt = "worksheet") {
			Set tClassName = "Ens.BusinessMetricKPI"
			Quit
		}
		ElseIf (tExt = "kpi") {
			// strip off ext
			Set pKPIName = $P(pKPIName,".",1,$L(pKPIName,".")-1)
		}

		Set tClassName = ""

		// JMD900: test for built-in plug-ins
		If ($E($$$UPPER(pKPIName),1,9)="%DEEPSEE.") {
			Set tClassIndex = $$$UPPER("%DeepSee.PlugIn."_$P(pKPIName,".",2))
			If ($D(^rINDEXCLASS(tClassIndex),tInfo)) {
				// Get correct case of name
				Set tClassName = $LG(tInfo,2)
			}
		}
		ElseIf ((pKPIName'="")&&($G($$$DeepSeeMetaGLVN("kpis",$$$UPPER(pKPIName)))'="")) {
			Set tClassName = $$$DeepSeeMetaGLVN("kpis",$$$UPPER(pKPIName))
		}

		// No privilege is same as does not exist
		If (tClassName'="") {
			If ('$zobjclassmethod(tClassName,"%CheckResource")) {
				Set tClassName = ""
			}
		}

		If (tClassName="") {
			Set pStatus = $$$ERROR($$$GeneralError,"Cannot find KPI: '" _ pKPIName _ "'")
		}
	}
	Catch(ex) {
		Set tClassName = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tClassName
}

/// Return a list of all currently defined DeepSee KPIs visible to the current user.
/// This is used by utilities.<br/>
/// This list takes the form:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type) 
ClassMethod %GetKPIList(Output pList) As %Status [ Final ]
{
	Set tSC  = $$$OK
	Kill pList

	// JMD900: find all built-in plug-ins
	// These are in the %DeepSee.PlugIn package
	Set tCLASS = "%DEEPSEE.PLUGIN."
	Set tCLASS = $O(^rINDEXCLASS(tCLASS))
	While ($E(tCLASS,1,16)="%DEEPSEE.PLUGIN.") {
		Set tClassName = $LG(^rINDEXCLASS(tCLASS),2)
		If $$$comClassDefined(tClassName) {
			Set tAbstract = +$$$comClassKeyGet(tClassName,$$$cCLASSabstract)
			If ('tAbstract && $classmethod(tClassName,"%IsA","%DeepSee.KPIPlugIn")) {
				If ($classmethod(tClassName,"%IsPublic")) {
					Set tName = $classmethod(tClassName,"%GetKPIName",.tSC)
					If $$$ISERR(tSC) Quit
					If (tName'="") {
						Set tKPI = $$$UPPER(tName)
						Set tDate = ""
						Set tCaption = $classmethod(tClassName,"%GetKPICaption")
						Set pList(tKPI) = $LB(tName,tCaption,tDate,"kpi")
					}
				}
			}
		}
		Set tCLASS = $O(^rINDEXCLASS(tCLASS))
	}
	If $$$ISERR(tSC) Quit tSC
	
	// Now get local plug-ins from KPI global
	Set tKPI = $O($$$DeepSeeMetaGLVN("kpis",""))
	While (tKPI '= "") {
		If (..%IsKPIPublic(tKPI)) {
			// get original name
			Set tName = ..%GetKPIName(tKPI,.tSC)
			If $$$ISERR(tSC) Quit
			If (tName'="") {
				Set tDate = ..%GetKPIModifiedDate(tKPI)
				Set pList(tKPI) = $LB(tName,..%GetKPICaption(tKPI),tDate,"kpi")
			}
		}
		Set tKPI = $O($$$DeepSeeMetaGLVN("kpis",tKPI))
	}
	Quit tSC
}

/// Return a list of all currently defined DeepSee "Plug-in" KPIs visible to the current user.
/// If <var>pBaseName</var> is provided, then only list plug-ins visible to this base cube.<br/>
/// This is used by utilities.<br/>
/// This list takes the form:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type)<br/>
/// pList(NAME,"props",propName) = ""<br/>
ClassMethod %GetKPIPlugInList(Output pList, pBaseName As %String = "", pPlugInType As %String = "", pUseCubeVersion As %Boolean = 0) As %Status [ Final ]
{
	Set tSC = $$$OK
	Kill pList
	
	// DTB336
	Set tBaseName = pBaseName
	Set:'pUseCubeVersion tBaseName = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(tBaseName)

	Do ..%GetKPIList(.tList)
	Set tKPI = $O(tList(""))
	While (tKPI'="") {
		Set tKPIClass = ..%GetKPIClass(tKPI,.tSC)
		If $$$ISERR(tSC) Quit

		If ((tKPIClass'="")&&($classmethod(tKPIClass,"%IsA","%DeepSee.KPIPlugIn"))) {
			Set tSkip = 0
			If (pPlugInType'="") {
				Set tType = $$$UPPER($classmethod(tKPIClass,"%GetPlugInType"))
				If (tType'=$$$UPPER(pPlugInType)) {
					Set tSkip = 1
				}
			}
			If ('tSkip&&(tBaseName'="")) {
				Set tSkip = 1
				Set tKPICubes = $$$UPPER($classmethod(tKPIClass,"%GetBaseCube"))
				For n=1:1:$L(tKPICubes,",") {
					Set tCube = $P(tKPICubes,",",n)
					If (tCube="*") {
						Set tSkip = 0
						Quit
					}
					ElseIf (tCube'="") {
						Kill tCubeList
						Do ..%GetCubeList(.tCubeList,"",1,tCube)
						If ($D(tCubeList($$$UPPER(tBaseName)))) {
							Set tSkip = 0
							Quit
						}
					}
				}
			}
			If ('tSkip) {
				// Get properties for this KPI
				Kill tPropList
				Do $classmethod(tKPIClass,"%GetKPIPropertyInfo",.tPropList)

				Set pList(tKPI) = tList(tKPI)
				Merge pList(tKPI,"props") = tPropList
			}
		}

		Set tKPI = $O(tList(tKPI))
	}

	Quit tSC
}

/// Return a list of all currently defined DeepSee worksheets visible to the current user.
/// This is used by utilities.<br/>
/// This list takes the form:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type)<br/>
/// If <var>pHidden</var> is true, then include trash and local items.
ClassMethod %GetWorksheetList(Output pList, pHidden As %Boolean = 0) As %Status [ Final ]
{
	Set tSC = $$$OK
	Kill pList
	Try {
		Set tFlag = $zu(115,8,0)
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare("SELECT ID FROM %DeepSee_UserLibrary.Worksheet")
		If $$$ISERR(tSC) Quit

		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.ID '="") {
				Set tItem = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tRS.ID)
				If ($IsObject(tItem)) {
					Set tDate = $ZDTH(tItem.timeModified,3)
					Set tFullName = $P(tItem.fullName,".",1) // name without extension
					If (pHidden || ($E(tFullName,1)'="$")|| ($E(tFullName,1,3)="$$$")) {
						If (tItem.%CheckResource()) {
							Set pList(tItem.fullName) = $LB(tFullName,tItem.name,tDate,"worksheet")
						}
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

/// Return a list of all currently defined Business Metrics visible to the current user.
/// This is used by utilities.<br/>
/// This list takes the form:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type) 
ClassMethod %GetMetricList(Output pList) As %Status [ Final ]
{
	Kill pList
	If (##class(%Library.EnsembleMgr).IsEnsembleNamespace()) {
		Try {
			Set tSC = $classmethod("Ens.BusinessMetricKPI","%GetBusinessMetricList",.pList)
		}
		Catch(ex) {
		}
	}
	Quit $$$OK
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the default cube element (dimension and possibly level) as a string ("[Product].[Name]").<br/>
/// Note: this is no longer used by DeepSee.
ClassMethod %GetDefaultMember(pCubeName As %String) As %String
{
	Set tSpec = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"defmbr"))
	If (tSpec = "") {
		Set tMeasure = ..%GetDefaultMeasure(pCubeName)
		If (tMeasure '= "") {
			Set tSpec = "[Measures]."_tMeasure
		}
		Else {
			Set tDim = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"defdim"))
			Set tSpec = tDim
		}
	}
	If (tSpec = "") {
		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISERR(pStatus) Quit
		Set tSpec = "[Measures].["_..%GetCountName(pCubeName)_"]"
	}
	Quit tSpec
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the name of the default Measure.
/// Note: this is no longer used by DeepSee.
ClassMethod %GetDefaultMeasure(pCubeName As %String) As %String
{
	Set tMeasure = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"defmsr"))
	Quit tMeasure
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// and a dimension name, return the name of the default Hierarchy (this
/// is only defined if there is no more than one hierarchy for this dimension).
ClassMethod %GetDefaultHierarchy(pCubeName As %String, pDimName As %String) As %String
{
	Set tHierName = ""

	Set tHier = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),""))
	If (tHier'="") {
		Set tInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),tHier)
		Set tDimNo = +$LG(tInfo,1)
		Set tHierNo = +$LG(tInfo,2)
		Set tLevelNo = +$LG(tInfo,3)
		Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbr#",tDimNo,tHierNo,tLevelNo))
		If ($LG(tMbrInfo,1)="all") {
			// skip all level
			Set tHier = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),tHier))
			If (tHier="") {
				Quit ""
			}
			Set tInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),tHier)
			Set tDimNo = +$LG(tInfo,1)
			Set tHierNo = +$LG(tInfo,2)
			Set tLevelNo = +$LG(tInfo,3)
			Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbr#",tDimNo,tHierNo,tLevelNo))
		}

		Set tHierName = $LG(tMbrInfo,3)

		// see if there is another hierarchy
		Set tHier = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),tHier))
		If (tHier'="") {
			Set tInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),tHier)
			Set tDimNo = +$LG(tInfo,1)
			Set tHierNo = +$LG(tInfo,2)
			Set tLevelNo = +$LG(tInfo,3)
			Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbr#",tDimNo,tHierNo,tLevelNo))
			If ($LG(tMbrInfo,1)="all") {
				// skip all level
				Set tHier = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),tHier))
			}
			If (tHier'="") {
				Set tHierName = ""
			}
		}
	}
	Quit tHierName
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// and a dimension and hierarchy name, return the name of the default Level (this
/// is only defined if there is no more than one level for this hierarchy).
ClassMethod %GetDefaultLevel(pCubeName As %String, pDimName As %String, pHierName As %String) As %String
{
	Set tLevelName = ""

	Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),""))
	If (tLevel'="") {
		Set tInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),tLevel)
		Set tDimNo = +$LG(tInfo,1)
		Set tHierNo = +$LG(tInfo,2)
		Set tLevelNo = +$LG(tInfo,3)
		Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbr#",tDimNo,tHierNo,tLevelNo))

		If ($LG(tMbrInfo,1)="all") {
			// skip all level
			Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),tLevel))
			Set tInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),tLevel)
			Set tDimNo = +$LG(tInfo,1)
			Set tHierNo = +$LG(tInfo,2)
			Set tLevelNo = +$LG(tInfo,3)
			Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbr#",tDimNo,tHierNo,tLevelNo))
		}

		Set tLevelName = $LG(tMbrInfo,4)

		// see if there is another level
		Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),tLevel))
		If (tLevel'="") {
			Set tInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),tLevel)
			Set tDimNo = +$LG(tInfo,1)
			Set tHierNo = +$LG(tInfo,2)
			Set tLevelNo = +$LG(tInfo,3)
			Set tMbrInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbr#",tDimNo,tHierNo,tLevelNo))
			If ($LG(tMbrInfo,1)="all") {
				// skip all level
				Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),tLevel))
			}
			If (tLevel'="") {
				Set tLevelName = ""
			}
		}
	}
	Quit tLevelName
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube known to exist,
/// return true if it is a base cube (and not a Subject Area).
ClassMethod %IsBaseCube(pCubeName As %String) As %Boolean [ Internal ]
{
	Quit ($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"baseCube"))="")
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee subject area known to exist,
/// return its base cube.
ClassMethod %GetBaseCube(pCubeName As %String) As %String
{
	Quit $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"baseCube"))
}

ClassMethod %GetSourceClass(pCubeName As %String) As %String
{
	Quit $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"sourceClass"))
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// and the name of a relationship in the cube, return the name of the cube referred to by the
/// relationship.
ClassMethod %GetRelatedCube(pCubeName As %String, pRelationName As %String) As %String
{
	Quit $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"relations",$$$UPPER(pRelationName),"relatedCube"))
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// and the name of a dimension, test if the dimension is a relationship.
ClassMethod %IsRelationship(pCubeName As %String, pDimension As %String) As %Boolean
{
	Set tIsRelation = 0
	Set pCubeName = $$$UPPER(pCubeName)
	Set pDimension = $$$UPPER(pDimension)
	If (pDimension'="") {
		Set tDimNode = $G($$$DeepSeeMetaGLVN("cubes",pCubeName,"mbrs",pDimension))
		If (tDimNode'="") {
			Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",pCubeName,"mbr#",$LG(tDimNode,1),$LG(tDimNode,2),$LG(tDimNode,3)))
			Set tIsRelation = $LG(tDimInfo,1) = "r"
		}
	}
	Quit tIsRelation
}

/// Return a list of the dimensions (and measures) within the specified cube.<br/>
/// On return, <var>pInfo</var> will contain array of the form:<br/>
/// pInfo(DimNo,HierNo,LevelNo) = $LB(type,DimName,HierName,LevelName)<br/>
/// type can be "d","h","l","m","r" or "all" for dimension, hierarchy, level, measure, relationship or all level.<br/>
/// Note that all measures are found under DimNo 0 and have no LevelName.
/// Dimensions whose name starts with "%" are not listed.<br/>
/// Dimensions that only contain calculated members are returned as:<br/>
/// pInfo(-1,hierNo,memberNo)<br/>
/// If <var>pUseInFilter</var> is true, then only return levels whose useInFilter flag is true.<br/>
/// If <var>pExtendedInfo</var> is true, also return $LB(factNumber, factID, SQL column ID, isEnabled, inProgress) settings.
ClassMethod %GetDimensionList(pCube As %String, ByRef pInfo, pIncludeCalcMbrs As %Boolean = 0, pUseInFilter As %Boolean = 0, pExtendedInfo = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pInfo
		Set tCube = $$$DeepSeeIndex(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		// walk over dimension index
		Set tDimNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",""))
		While (tDimNo '= "") {
			Set tHierNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,""))
			While (tHierNo '= "") {
				Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,""),1,info)
				While (tLevelNo '= "") {
					Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,0,0))
					Set tHidden = +$LG(tDimInfo,17)
					Set tType = $LG(info,1)
					Set tDimName = $LG(info,2)
					Set tHierName = $LG(info,3)
					Set tLevelName = $LG(info,4)
					Set tLevelUseForFilter = $S('pUseInFilter:1,1:$LG(info,19,1)) // JMD1278
					If ('tHidden && ($E(tDimName,1,1)'="%") && (tLevelUseForFilter)) {
						Set pInfo(tDimNo,tHierNo,tLevelNo) = $LB(tType,tDimName,tHierName,tLevelName)
						
						If pExtendedInfo {
							// DTB918 - Add the internal reference codes for this fact
							Set tFactNo = $LG(info,5)
							If (tFactNo'="") {
								Set tFactID = $S(($E(tFactNo))="M":$G($$$DeepSeeMetaGLVN("cubes",tCube,"msr#",tFactNo)),1:$G($$$DeepSeeMetaGLVN("cubes",tCube,"fact#",tFactNo)))
								Set tSqlColID = $G($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tFactID,"alias"),tFactID)
								Set tIsEnabled = $$$dsFactEnabled(tCube,tFactID)	//$G($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tFactID,"enabled"),1)
								Set tInProgress = $$$dsFactInProgress(tCube,tFactID)		//$G($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tFactID,"inProgress"),0)
							}
							Else {
								// Null settings are returned if the tFactID is null. This will occur in the event
								// lookups fail.
								Set tFactID = ""
								Set tSqlColID = ""
								Set tIsEnabled = ""
								Set tInProgress = ""
							}
							Set pInfo(tDimNo,tHierNo,tLevelNo) = pInfo(tDimNo,tHierNo,tLevelNo) _ $LB(tFactNo,tFactID,tSqlColID,tIsEnabled,tInProgress)
						}
					}
					Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo),1,info)
				}
				Set tHierNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo))
			}
			Set tDimNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo))
		}

		If (pIncludeCalcMbrs) {
			// Calculated members
			// combine local list with those defined in the cube
			// calcMbrs(dim,mbr) = $LB(dim,mbr,spec)
			Merge tCalcMbrs = $$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs")
			
			// +DTB268 - Add shared calculated members
			Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMembers(tCube,.tSharedCalcMbrs)
			Set tSharedCalcIdx = $O(tSharedCalcMbrs(""),1,tSharedCalcData)
			While tSharedCalcIdx'="" {
				Set tSharedCalcDimKey = $$$UPPER($LG(tSharedCalcData,1))
				Set tSharedCalcKey = $$$UPPER($LG(tSharedCalcData,2))
				Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMemberInfo(tCube,tSharedCalcDimKey,tSharedCalcKey,.tMbrInfo)
				If $D(tMbrInfo) {
					// $LB(dimension,name,expression,format,hidden)
					Set tSharedCalcMbrs(tSharedCalcDimKey,tSharedCalcKey) = $LB(tMbrInfo("dimension"),tMbrInfo("name"),tMbrInfo("expression"),tMbrInfo("format"))		// DTB461 - Remove solveOrder in the hidden position
				}
				
				Set tSharedCalcIdx = $O(tSharedCalcMbrs(tSharedCalcIdx),1,tSharedCalcData)
			}
			
			Merge tCalcMbrs = tSharedCalcMbrs		// DTB461
			// -DTB268

			Set tHierNo = 0
			Set tDim = $O(tCalcMbrs(""))
			While (tDim '= "") {
				If ((tDim '= "MEASURES")&&('$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim)))) {
					Set tHierNo = tHierNo + 1
					Set tLevelNo = 0
					Set k = $O(tCalcMbrs(tDim,""))
					If (k'="") {
						Set tDimInfo = tCalcMbrs(tDim,k)
						Set tDimName = tDim
						Set tDimCaption = $LG(tDimInfo,1)
						Set pInfo(-1,tHierNo,tLevelNo) = $LB("d",tDimCaption)
					}
				}
				Set tDim = $O(tCalcMbrs(tDim))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Get the members (dimensions, measures, and actual members of dimensions) of the specified cube as a tree format that can
/// be displayed within a <class>%ZEN.Component.dynaTree</class>.<br/>
/// <var>pCube</var> is the cube name.<br/>
/// <var>pTree</var> is an array returned by reference that contains the member data.<br/>
/// <var>pSkipMeasures</var> is used internally and indicates that measures (as well as named filters) should not be listed.<br/>
/// <var>pRoot</var> is used to specify that an incremental load of children is requested; if provided it is the spec of a parent node.<br/>
/// <var>pLocalCalcMembers</var> is used to pass in additional calculated members.<br/>
/// <var>pLocalNamedSets</var> is used to pass in additional named sets.<br/>
/// <var>pVisited</var> and <var>pRelatedBy</var> are not used.<br/>
/// <var>pSkeleton</var> indicates that members and relationships are not displayed.<br/>
ClassMethod %GetMemberTree(pCube As %String, ByRef pTree, ByRef pVisited As %String, pSkipMeasures As %Boolean = 0, pRoot As %String = "", ByRef pLocalCalcMembers As %List, ByRef pLocalNamedSets As %List, pRelatedBy As %String = "", pLevel As %Integer = 0, pSkeleton As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			Set tSession = $G($$$DeepSeeSession)
		}

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit
		// JMD1193: only fetch 100 at first
		Set tMemberBucket = 100
		// allow for 5x before switching to groups
		Set tMaxMembers = tMemberBucket*5
		Set tStartMbr = ""
		Set tEndMbr = ""
		Set tSkipProps = 0

		// n.b. ignore visited and related by 

		If ('..%CheckPrivilege(tCube)) Quit
		
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tCountName = ..%GetCountName(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		If (pRoot'="") {
			// get children for a single node
			// add members of this level to tree
			Kill pTree
			Set pTree = 1
			Set tRootSpec = pRoot

			// JMD1193: if pRoot starts with @@@ this is one group of a large dimension
			If ($E(pRoot,1,3)="@@@") {
				// @@@:start:end:spec
				Set tStartMbr = $P(pRoot,":",2)
				Set tEndMbr = $P(pRoot,":",3)
				Set tRootSpec = $P(pRoot,":",4,999)
				Set tSkipProps = 1
				Set tMaxMembers = tEndMbr
			}

			// if pRoot starts with @@ then this is a request to load the dimensions
			// of a related cube 
			ElseIf ($E(pRoot,1,2)="@@") {
				// @@cube@@relation[^prefix}
				Set tParentCube = $P($P(pRoot,"^",1),"@@",2)
				Set tRelationName = $P($P(pRoot,"^",1),"@@",3)
				Set tPrefix = $P(pRoot,"^",2)
				Set tRelatedCube = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tParentCube),"relations",$$$UPPER(tRelationName),"relatedCube"))

				// Get dimensions of relationship (sans measures)
				Kill tRelTree
				Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tRelatedCube,.tRelTree,.pVisited,1,"",,,"",pLevel+1)
				If $$$ISERR(tSC) Quit

				If $D(tRelTree) {
					// copy subtree into this one (from the Dimensions Node)
					Set tXName = tPrefix_$S(tPrefix="":"",1:".")_"["_$$$dsEscapeIdent(tRelationName)_"]" // JSL4451 - invoke $$$dsEscapeIdent
					Do ..%CopyTree(tXName,.pTree,0,.tRelTree,2)
				}
				Quit
			}

			// parse spec
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCube,tRootSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo)
			If $$$ISERR(tSC) Quit
			If (tRelationName '="") {
				Set tRelatedCube = $G($$$DeepSeeMetaGLVN("cubes",tCube,"relations",$$$UPPER(tRelationName),"relatedCube"))

				Kill tRelTree
				Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tRelatedCube,.tRelTree,.pVisited,1,tRelationSpec,,,"",pLevel+1)
				If $$$ISERR(tSC) Quit

				// add to output tree; add relation to spec
				Set k = $O(tRelTree(""))
				While (k'="") {
					Set tInfo = $G(tRelTree(k))
					If ($LG(tInfo,1)'="") {
						Set tMbrSpec = "["_$$$dsEscapeIdent(tRelationName) _"]"_ "." _ $LG(tInfo,2) // JSL4451 - invoke $$$dsEscapeIdent
						Set $List(tInfo,2) = tMbrSpec
						Set pTree($I(pTree)) = tInfo
						Set pTree(0,"ch",pTree) = ""
					}
					Set k = $O(tRelTree(k))
				}
				Quit
			}

			Set tLevelNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo))
			Set tDim = $LG(tLevelNode,2)
			Set tHier = $LG(tLevelNode,3)
			Set tLevel = $LG(tLevelNode,4)

			// pick up dimension properties
			If ('tSkipProps) {
				Set tPropNo = 0
				Set tProp = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",""))
				While (tProp '= "") {
					Set tPropInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",tProp))
					Set tPropName = $LG(tPropInfo,4)
					Set tPropCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,tHier,tLevel,tProp)
					Set tPropDescription=""
					try {
						Set tPropDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim,tHier,tLevel,tProp) // JSL4475
					} catch {}
					Set tPropHidden = +$LG(tPropInfo,17)
					If ('tPropHidden) {
						Set tHasMembers = 1
						Set tPropNo = tPropNo + 1
						Set tIcon = "deepsee/ds2_cards_44.png"
						Set tMbrSpec = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec($LB(tDim,tHier,tLevel))_".CurrentMember.Properties("""_tPropName_""")" // JSL4451 - invoke $$$dsEscapeIdent
						Set pTree($I(pTree)) = $LB(tPropCaption,tMbrSpec,0,"",0,tIcon,$s(tPropDescription'="":tPropDescription,1:$$$Text("Property: ","%DeepSee") _ tPropCaption),"color:darkblue;") // JSL4475 use tPropDescription
						Set pTree(0,"ch",pTree) = ""
					}
					Set tProp = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",tProp))
				}
			}

			// JMD1193 remember state of tree, so we can delete nodes
			// find out if this is a time dimension
			Set tStartOfMembers = pTree
			Set tTimeClass = $LG($G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,0)),6)
			Set tIsTime = (tTimeClass'="")
			If (tIsTime) {
				Set tMaxMembers = 5000
			}

			// members
			If ((tDim'="")&&(tHier'="")&&(tLevel'="")) {
				//Set tMbrSpec = "["_tDim_"].["_tHier_"].["_tLevel_"]"		// DTB127 - Unescaped, quoted identifiers should not be used in specs
				Set tMbrSpecEscape = ##class(%DeepSee.Query.Parser).%BuildEscapedSpec($LB(tDim,tHier,tLevel))		// DTB268
				// JMD-- do not show calc members amongst the levels

				// JMD1193: pass along start/end if present
				If ('tIsTime && (tStartMbr'="")&&(tEndMbr'="")) {
					New %dsStartMbr
					Set %dsStartMbr = tStartMbr
					New %dsEndMbr
					Set %dsEndMbr = tEndMbr
				}
				Set tSC = ..%GetDimensionMembers(tCube,tMbrSpecEscape,"filter",.tMembers,$S(tMaxMembers="":"",1:tMaxMembers+1),,,-1)		// DTB127 - Use the escaped spec
				If $$$ISERR(tSC) {
					Quit
				}
			}

			Set tMCount = 0
			Set m = $O(tMembers(""),1,tMbrInfo)
			While ((m'="")&&(tMCount < tMaxMembers)) {
				Set tMCount = tMCount + 1
				Set tTooltip = $LG(tMbrInfo,5)
				If (tTooltip="") {
					Set tTooltip = $LG(tMbrInfo,2)
				}
				Else {
					Set tTooltip = $LG(tMbrInfo,2) _ " - " _ tTooltip
				}
				// + WAL145 -- If the key returned is already wrapped in "&[" and "]" peel those off so the
				//             logic below doesn't double them.
				Set tMbrKey = $LG(tMbrInfo,4)
				If ($E(tMbrKey,1,2)="&[")||($E(tMbrKey)="[") {
					// DTB315 - Check for quote before parsing
					Do ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tMbrKey,.tParseInfo)
					Set:($G(tParseInfo(1))'="") tMbrKey = tParseInfo(1) 
				}
				Set pTree($I(pTree)) = $LB($LG(tMbrInfo,2),tMbrSpecEscape_".&["_$$$dsEscapeIdent(tMbrKey)_"]",0,"",0,,tTooltip)
				// - WAL145
				Set pTree(0,"ch",pTree) = ""
				Set m = $O(tMembers(m),1,tMbrInfo)
			}
			If (tMCount = 0) {
				Set pTree($I(pTree)) = $LB($$$Text("No members","%DeepSee"),"",0,"",0,,"","font-style:italic;")
				Set pTree(0,"ch",pTree) = ""
			}
			ElseIf (('tIsTime)&&(m'="")) {
				// JMD1193: there are more members to fetch
				// do not show them; instead provide another level of tree to group them

				// remove all members from tree
				Set kx = $O(pTree(tStartOfMembers))
				While (kx'="") {
					Kill pTree(kx)
					Kill pTree(0,"ch",kx)
					Set kx = $O(pTree(kx))
				}
				Set pTree = tStartOfMembers

				// find total members
				Set tTotalMemberCount = ..%GetCubeMemberCount(tCube,.tSC,tDim,tHier,tLevel)
				If (tTotalMemberCount < ((tMemberBucket*tMemberBucket)+1)) {
					// create a set of groups with special @@@: marker
					Set tPage = tMemberBucket
					For kn = 1:tPage:tTotalMemberCount {
						Set tLastNo = $S((kn+tPage-1)>tTotalMemberCount:tTotalMemberCount,1:(kn+tPage-1))
						Set tLabel = "#"_kn_" - #"_tLastNo
						Set pTree($I(pTree)) = $LB(tLabel,"@@@"_":"_kn_":"_tLastNo_":"_tRootSpec,1,"",0,,"")
						Set pTree(0,"ch",pTree) = ""
					}
				} Else {
					// PFS004 - Show meaningful message when a dimension has too many members to display in Analyzer Member Tree
					Set pTree($I(pTree)) = $LB($$$Text("Too many members to display","%DeepSee"),"",0,"",0,,"","font-style:italic;")
					Set pTree(0,"ch",pTree) = ""
				}
			}
		}
		Else {
			// get entire tree (non-member nodes)

			// Calculated members
			// combine local list with those defined in the cube
			Kill tCalcMbrs
			Merge tCalcMbrs = $$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs")
			
			// +DTB268 - Add shared calculated members
			Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMembers(tCube,.tSharedCalcArray)
			Set tSharedCalcIdx = $O(tSharedCalcArray(""),1,tSharedCalcData)
			While tSharedCalcIdx'="" {
				Set tSharedCalcDimKey = $$$UPPER($LG(tSharedCalcData,1))
				Set tSharedCalcKey = $$$UPPER($LG(tSharedCalcData,2))
				Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMemberInfo(tCube,tSharedCalcDimKey,tSharedCalcKey,.tMbrInfo)
				If $D(tMbrInfo) {
					// $LB(dimension,name,expression,format,hidden)
					Set tSharedCalcMbrs(tSharedCalcDimKey,tSharedCalcKey) = $LB(tMbrInfo("dimension"),tMbrInfo("name"),tMbrInfo("expression"),tMbrInfo("format"))		// DTB461 - Remove solveOrder in the hidden position
				}
				
				Set tSharedCalcIdx = $O(tSharedCalcArray(tSharedCalcIdx),1,tSharedCalcData)
			}
			Merge tCalcMbrs = tSharedCalcMbrs
			// -DTB268
			
			Merge tCalcMbrs = pLocalCalcMembers

			Kill tFilterList
			Set tSC = ..%GetNamedFilters(tCube,.tFilterList)
			If $$$ISERR(tSC) Quit

			Kill tVariableList
			Set tSC = ..%GetPivotVariables(tCube,.tVariableList)
			If $$$ISERR(tSC) Quit

			// plug-ins
			Set tSC = ..%GetKPIPlugInList(.tPlugInList,tCube,"Pivot")
			If $$$ISERR(tSC) Quit

			Set tDimCount = 0
			Set tMsrCount = 0
			Set tFilterCount = 0
			Set tPlugInCount = 0
			Set tQMsrCount = 0
			Set tVariableCount = 0
			Kill pTree
			Set tMsrRoot = 1
			Set tDimRoot = 2
			// JMD1223 change pTree from 3 to 2
			Set pTree = 2
			Set tFilterRoot = ""
			Set tNamedSetsRoot = ""
			Set tPlugInRoot = ""
			Set tQMsrRoot = ""
			Set tVariableRoot = ""

			// named filters
			If $D(tFilterList) {
				Set f = $O(tFilterList(""))
				While (f'="") {
					Set tFilterInfo = tFilterList(f)
					Set tIcon = "deepsee/ds2_gear_44.png"
					// value is %FILTER-- pivot will look up the spec
					If (tFilterRoot="") {
						Set tFilterRoot = $I(pTree)
					}
					Set pTree($I(pTree)) = $LB($LG(tFilterInfo,1),"%FILTER",0,"",0,tIcon,$LG(tFilterInfo,2))
					Set pTree(tFilterRoot,"ch",pTree) = ""
					Set tFilterCount = tFilterCount + 1
					Set f = $O(tFilterList(f))
				}
			}

			// pivot variables
			If $D(tVariableList) {
				Set f = $O(tVariableList(""))
				While (f'="") {
					Set tVariableInfo = tVariableList(f)
					Set tIcon = "deepsee/ds2_keyhole_44.png"
					// value is $variable.variableName -- pivot will resolve this
					If (tVariableRoot="") {
						Set tVariableRoot = $I(pTree)
					}
					Set pTree($I(pTree)) = $LB($LG(tVariableInfo,2),"$variable."_$LG(tVariableInfo,1),0,"",0,tIcon,$LG(tVariableInfo,5))
					Set pTree(tVariableRoot,"ch",pTree) = ""
					Set tVariableCount = tVariableCount + 1
					Set f = $O(tVariableList(f))
				}
			}

			// JMD905: quality measures
			If $D(tQMsrList) {
				If (tQMsrRoot="") {
					Set tQMsrRoot = $I(pTree)
				}

				// first split into catalog/set/id
				Set q = $O(tQMsrList(""))
				While (q'="") {
					Set tQName = $LG(tQMsrList(q),1)
					Set tQCatalog = $P(tQName,"/",1)
					Set tQSet = $P(tQName,"/",2)
					Set tQId = $P(tQName,"/",3)
					Set tQList(tQCatalog,tQSet,tQId) = $LB(tQName,$LG(tQMsrList(q),2))
					Set q = $O(tQMsrList(q))
				}

				// now add to tree
				Set tIcon = "deepsee/ds2_beaker_44.png"
				Set tQCatalog = $O(tQList(""))
				While (tQCatalog'="") {
					Set pTree($I(pTree)) = $LB(tQCatalog,,1,"",0,"",$$$Text("Catalog","%DeepSee"))
					Set pTree(tQMsrRoot,"ch",pTree) = ""
					Set tQCatNo = pTree
					Set tQMsrCount = tQMsrCount + 1

					Set tQSet = $O(tQList(tQCatalog,""))
					While (tQSet'="") {
						Set pTree($I(pTree)) = $LB(tQSet,,1,"",0,"",$$$Text("Set","%DeepSee"))
						Set pTree(tQCatNo,"ch",pTree) = ""
						Set tQSetNo = pTree

						Set tQId = $O(tQList(tQCatalog,tQSet,""))
						While (tQId'="") {
							// JMD1098 Get groups and elements of the qmsr
							Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityElements($LG(tQList(tQCatalog,tQSet,tQId),1),.tQElList)

							Set tSpec = "[%QualityMeasure].["_$$$dsEscapeIdent($LG(tQList(tQCatalog,tQSet,tQId),1))_"]" // JSL4451 - invoke $$$dsEscapeIdent
							Set pTree($I(pTree)) = $LB(tQId,tSpec,''$D(tQElList),"",0,tIcon,$LG(tQList(tQCatalog,tQSet,tQId),2),"font-weight:bold;")
							Set pTree(tQSetNo,"ch",pTree) = ""
							Set tQIdNo = pTree

							// add groups to tree
							Set tQGroup = $O(tQElList(""))
							While (tQGroup'="") {
								Set tSpec = "[%QualityMeasure].["_$$$dsEscapeIdent($LG(tQList(tQCatalog,tQSet,tQId),1))_"/"_$$$dsEscapeIdent(tQGroup)_"]" // JSL4451 - invoke $$$dsEscapeIdent
								Set pTree($I(pTree)) = $LB(tQGroup,tSpec,1,"",0,"",$$$Text("Group","%DeepSee"),"color:#608060;")
								Set pTree(tQIdNo,"ch",pTree) = ""
								Set tQGroupNo = pTree

								Set tQElement = $O(tQElList(tQGroup,""))
								While (tQElement'="") {
									Set tSpec = "[%QualityMeasure].["_$$$dsEscapeIdent($LG(tQList(tQCatalog,tQSet,tQId),1))_"/"_$$$dsEscapeIdent(tQGroup)_"/"_$$$dsEscapeIdent(tQElement)_"]" // JSL4451 - invoke $$$dsEscapeIdent
									Set pTree($I(pTree)) = $LB(tQElement,tSpec,0,"",0,"",$$$Text("Element","%DeepSee"),"color:#606080;")
									Set pTree(tQGroupNo,"ch",pTree) = ""

									Set tQElement = $O(tQElList(tQGroup,tQElement))
								}
								Set tQGroup = $O(tQElList(tQGroup))
							}


							Set tQId = $O(tQList(tQCatalog,tQSet,tQId))
						}
						Set tQSet = $O(tQList(tQCatalog,tQSet))
					}
					Set tQCatalog = $O(tQList(tQCatalog))
				}
			}

			// JMD900: plug ins
			If $D(tPlugInList) {
				Set f = $O(tPlugInList(""))
				While (f'="") {
					If $D(tPlugInList(f,"props")) {
						Set tPlugInInfo = tPlugInList(f)
						// value is %FILTER-- pivot will look up the spec
						If (tPlugInRoot="") {
							Set tPlugInRoot = $I(pTree)
						}
						Set tPlugInName = $LG(tPlugInInfo,1)
						Set tPlugInCaption = $LG(tPlugInInfo,2)
						Set tToolTip = $LG(tPlugInInfo,2)
						Set pTree($I(pTree)) = $LB(tPlugInCaption,,1,"",0,"",tToolTip)
						Set pTree(tPlugInRoot,"ch",pTree) = ""
						Set tParentNo = pTree
						
						Set tIcon = "deepsee/ds2_zap_44.png"
						Set k = $O(tPlugInList(f,"props",""))
						While (k'="") {
							Set tProp = $G(tPlugInList(f,"props",k))
							Set tPropCaption = $G(tPlugInList(f,"props",k,"caption"),tProp)

							// KPI reference (with %CONTEXT)
							Set tSpec = "%KPI("_$$$quote(tPlugInName)_","_$$$quote(tProp)_",,""%CONTEXT"")"

							Set pTree($I(pTree)) = $LB(tPropCaption,tSpec,0,"",0,tIcon,tPropCaption)
							Set pTree(tParentNo,"ch",pTree) = ""
							Set k = $O(tPlugInList(f,"props",k))
						}
						
						Set tPlugInCount = tPlugInCount + 1
					}
					Set f = $O(tPlugInList(f))
				}
			}

			// walk over dimension list
			// build ordered list of dimensions
			Set tDim = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",""))
			While (tDim '= "") {
				Set tDimNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))
				Set tDimNo = +$LG(tDimNode,1)
				Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,0,0))
				Set tHidden = +$LG(tDimInfo,17)
				If ('tHidden) {
					// make sure dim #s collate correctly
					Set tOrderedDims($TR($J(tDimNo,4)," ",0)_":"_tDim) = tDim
				}
				Set tDim = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))
			}

			// walk over dimension list
			// build list of levels and measures
			Set tDimKey = $O(tOrderedDims(""))
			While (tDimKey '= "") {
				Set tDim = tOrderedDims(tDimKey)
				Set tDimNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))
				Set tDimNo = $LG(tDimNode,1)
				If (tDimNo'="") {
					Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,0,0))
					Set tDimName = $LG(tDimInfo,2)
					Set tShowHier = $LG(tDimInfo,18)

					If ($E(tDimName,1,1)'="%") {
						Set tAllName = $LG(tDimInfo,4)
						Set tDimCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim)
						Set tDimDescription=""
						try {
							Set tDimDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim) // JSL4475
						} catch {}
						Set tIsRelation = ''$D($$$DeepSeeMetaGLVN("cubes",tCube,"relations",tDim))

						If (tIsRelation) {
							Set tRelatedCube = $LG(tDimInfo,6)
							Set tCardinality = $LG(tDimInfo,7)
							Set tInverse = $LG(tDimInfo,8)

							// add relation to tree
							// lazy-load its dimensions on demand!
							// use special string to specify cube and relation name:
							// @@cube@@relation

							If (..%CheckPrivilege(tRelatedCube)) {
								Set ni = $I(pTree)
								If (pSkeleton) {
									Set tHasChildren = 0
									Set tRelCode = tDimName
								}
								Else {
									Set tHasChildren = 1
									Set tRelCode = "@@"_tCube_"@@"_tDimName
								}
								Set pTree(ni) = $LB(tDimCaption,tRelCode,tHasChildren,"",0,,$s(tDimDescription'="":tDimDescription,1:tDimCaption),"font-weight:bold;color:rgb(10,92,116);font-style:italic;")
								Set pTree(tDimRoot,"ch",ni) = ""
								Set tDimCount = tDimCount + 1 //JKG JSL4469
							}
						}
						Else {
							If (tDim'="MEASURES") {
								// add dimension to tree
								// $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)

								Set tDimCount = tDimCount + 1
								Set tHasChild = $D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))=11

								// JMD1206: use first level and not %TopMembers
								//Set pTree($I(pTree)) = $LB(tDimCaption,"["_tDimName_"]" _ ".%TopMembers",tHasChild,"",0,,tDimCaption,"font-weight:bold;color:#606060;")

								// find first hier/level
								Set tXDimNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",$$$UPPER(tDim)))
								Set xd = +$LG(tDimNode,1)
								Set xh = 1
								Set xl = +$LG(tDimNode,3)
								Set tXDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",xd,xh,xl))
								Set tXType = $LG(tXDimInfo,1)
								While (tXType '= "l") {
									Set xl = xl + 1
									Set tXDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",xd,xh,xl))
									If tXDimInfo="" Quit
									Set tXType = $LG(tXDimInfo,1)
								}
								Set tXHierName = $LG(tXDimInfo,3)
								Set tXLevelName = $LG(tXDimInfo,4)
								Set tTopSpec = "["_$$$dsEscapeIdent(tDimName) _"]"_".["_$$$dsEscapeIdent(tXHierName) _"]"_".["_$$$dsEscapeIdent(tXLevelName) _"]"_".Members" // JSL4451 - invoke $$$dsEscapeIdent

								Set pTree($I(pTree)) = $LB(tDimCaption,tTopSpec,tHasChild,"",0,,$s(tDimDescription'="":tDimDescription,1:tDimCaption),"font-weight:bold;color:#606060;") // JSL4475 - use tDimDescription
								Set pTree(tDimRoot,"ch",pTree) = ""
								Set tDimParent = pTree

								// add all level, if present
								If (tAllName '= "") {
									Set tAllCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,$$$UPPER(tAllName))
									If (tAllCaption '= "") {
										Set pTree($I(pTree)) = $LB(tAllCaption,"["_$$$dsEscapeIdent(tDimName)_"].["_$$$dsEscapeIdent(tAllName)_"]",0,"",0,,tAllCaption) // JSL4451 - invoke $$$dsEscapeIdent
										Set pTree(tDimParent,"ch",pTree) = ""
									}
								}

								// add calculated members in *this* dimension
								If ($D(tCalcMbrs(tDim))) {
									Set tMbr = $O(tCalcMbrs(tDim,""))
									While (tMbr '= "") {
										Set tInfo = tCalcMbrs(tDim,tMbr)
										Set tMbrCaption = $LG(tInfo,2)
										Set tMbrHidden = +$LG(tInfo,5)
										If ('tMbrHidden) {
											Set c = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,tMbrCaption)
											Set:c'="" tMbrCaption = c
											Set tMbrDescription=""
											try {
												Set tMbrDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim,$LG(tInfo,2)) // JSL4476
											} catch {}
											Set tDimCount = tDimCount + 1
											Set tHasChild = 0

											Set tIcon = "deepsee/deepsee/ds2_beaker2_44.png"
											Set tStyle = "color:rgb(91,92,67);"
											// use different color for locally defined items
											If ($D(pLocalCalcMembers(tDim,tMbr)))||($D(tSharedCalcMbrs(tDim,tMbr))) {
												Set tStyle = "color:rgb(91,92,167);"
											}
											
											// DTB268 - Flag the calc member as shared
											Set tSharedToken="" 
											If ($D(tSharedCalcMbrs(tDim,tMbr)))&&('$D(pLocalCalcMembers(tDim,tMbr))) {
												Set tSharedToken = "%SHAREDCALC."
											}
											
											Set pTree($I(pTree)) = $LB(tMbrCaption,tSharedToken_"["_$$$dsEscapeIdent(tDim)_"].["_$$$dsEscapeIdent(tMbr)_"]",tHasChild,"",0,tIcon,$s(tMbrDescription'="":tMbrDescription,1:tMbrCaption),tStyle) // JSL4451 - invoke $$$dsEscapeIdent
											Set pTree(tDimParent,"ch",pTree) = ""
										}
										Set tMbr = $O(tCalcMbrs(tDim,tMbr))
									}
								}
							}

							// walk over hierarchy list
							// build ordered list of hierarchies
							Kill tOrderedHiers
							Set tHierCount = 0
							Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,""))
							While (tHier '= "") {
								Set tHierNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
								Set tHierNo = $LG(tHierNode,2)
								Set tHierLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,$LG(tHierNode,3)))
								Set tHierType = $LG(tHierLevelInfo,1) // actual level associated with hierarchy name
								If (tHierType'="all") {
									Set tHierCount = tHierCount + 1
								}
								If (tHierNo '= "a") {
									// n.b. "a" is a dimension attribute-- not used
									Set tOrderedHiers($TR($J(tHierNo,4)," ",0)_":"_tHier) = tHier
								}
								Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
							}

							Set tHierKey = $O(tOrderedHiers(""))
							While (tHierKey '= "") {
								Set tHier = tOrderedHiers(tHierKey)
								Set tHierNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
								Set tHierNo = $LG(tHierNode,2)
								Set tHierInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,0))
								Set tHierLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,$LG(tHierNode,3)))
								Set tHierType = $LG(tHierLevelInfo,1) // actual level associated with hierarchy name
								Set tHierName = $LG(tHierInfo,3)
								Set tHierCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,tHier)
								Set tHierDescription=""
								try {
									Set tHierDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim,tHier) // JSL4475
								} catch {}
								Set tHidden = +$LG(tHierInfo,17)

								If (tHierType '= "all") {
									If (tDim = "MEASURES") {
										// measures use different hidden slot!
										Set tHidden = +$LG(tHierInfo,11)
										If ('tHidden && 'pSkipMeasures) {
											Set tMsrType = $LG(tHierLevelInfo,8)
											If (tHierName=$$$UPPER(tCountName)) {
												Set tMsrSourceCube = $LG(tHierLevelInfo,14)
												If (tMsrSourceCube'="") {
													// measure in compound cube
													Set tHierCaption = ##class(%DeepSee.Utils).%GetCountCaption(tMsrSourceCube)
												}
											}
											Set tMsrCount = tMsrCount + 1
											Set tIcon = $Case(tMsrType,"date":"deepsee/ds2_clock_44.png",:"deepsee/ds2_location_44.png")
											Set pTree($I(pTree)) = $LB(tHierCaption,"[Measures].["_$$$dsEscapeIdent(tHierName)_"]",0,"",0,tIcon,$s(tHierDescription'="":tHierDescription,1:tHierCaption)) // JSL4451 - invoke $$$dsEscapeIdent
											Set pTree(tMsrRoot,"ch",pTree) = ""
										}
									}
									Else {
										If ('tHidden) {
											// list levels in level # order
											Kill tLevelList
											Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,""))
											While (tLevel '= "") {
												Set tLevelNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,tLevel))
												Set tLevelNo = $LG(tLevelNode,3)
												Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo))
												Set tLevelType = $LG(tLevelInfo,1)
												Set tLevelName = $LG(tLevelInfo,4)
												Set tLevelCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,tHier,tLevel)
												Set tLevelDescription=""
												try {
													Set tLevelDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim,tHier,tLevel) // JSL4475
												} catch {}
												Set tLevelHidden = $LG(tLevelInfo,17)

												If (tLevelType '= "all") { // we are not interested in the all level
													If ('tLevelHidden) {
														// are there properties
														Set tPropNo = 0
														Set tProp = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",""))
														While (tProp '= "") {
															Set tPropInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",tProp))
															Set tPropName = $LG(tPropInfo,4)
															Set tPropCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,tHier,tLevel,tProp)
															Set tPropDescription=""
															try {
																Set tPropDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim,tHier,tLevel,tProp) // JSL4475
															} catch {}
															Set tPropHidden = +$LG(tPropInfo,17)
															If ('tPropHidden) {
																Set tHasMembers = 1
																Set tPropNo = tPropNo + 1
																Set tIcon = "deepsee/ds2_cards_44.png"
																Set tLevelList(tLevelNo,tPropNo) = $LB(tPropCaption,"["_$$$dsEscapeIdent(tDimName)_"].["_$$$dsEscapeIdent(tHierName)_"].["_$$$dsEscapeIdent(tLevelName)_"].CurrentMember.Properties("""_tPropName_""")",0,"",0,tIcon,$s(tPropDescription'="":tPropDescription,1:$$$Text("Property: ","%DeepSee") _ tPropCaption),"color:darkblue;") // JSL4451 - invoke $$$dsEscapeIdent
															}
															Set tProp = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",tProp))
														}
							 							// JMD
							 							// Set tMemberCount = ..%GetCubeMemberCount(tCube,.tSC,tDimName,tHierName,tLevelName)
							 							Set tMemberCount = 1
														If $$$ISERR(tSC) Quit
														If (((tMemberCount > 0) && 'pSkeleton) || ($G(tPropNo)>0)) {
															Set tLevelLabel = tDimCaption_"."_tHierCaption_"."_tLevelCaption
															Set tHasMembers = 1
														}
														Else {
															Set tLevelLabel = tDimCaption_"."_tHierCaption_"."_tLevelCaption 
															Set tHasMembers = 0
														}
														Set tLevelList(tLevelNo) = $LB(tLevelCaption,"["_$$$dsEscapeIdent(tDimName)_"].["_$$$dsEscapeIdent(tHierName)_"].["_$$$dsEscapeIdent(tLevelName)_"]",tHasMembers,"",0,,$s(tLevelDescription'="":tLevelDescription,1:tLevelLabel)) // JSL4451 - invoke $$$dsEscapeIdent
													}
												}
												Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,tLevel))
											}
											If $$$ISERR(tSC) Quit

											Set tHierParent = tDimParent
											If ((tShowHier=1)||((tShowHier'=0)&&(tHierCount>1))) {
												// show the hierarchy
												Set tHierLabel = tDimCaption_"."_tHierCaption
												Set pTree($I(pTree)) = $LB(tHierCaption,"",1,"",0,,tHierLabel)
												Set pTree(tDimParent,"ch",pTree) = ""
												Set tHierParent = pTree
											}

											// now add levels to tree
											Set tNo = $O(tLevelList(""))
											While (tNo'="") {
												Set tMbrSpec = $LG(tLevelList(tNo),2) // don't invoke $$$dsEscapeIdent!
												Set $List(tLevelList(tNo),2) = tMbrSpec _ ".Members"
												Set pTree($I(pTree)) = tLevelList(tNo)
												Set pTree(tHierParent,"ch",pTree) = ""
												Set tNodeNo = pTree

												Set tNo = $O(tLevelList(tNo))
											}
										}
									}
								}
								Set tHierKey = $O(tOrderedHiers(tHierKey))
								If $$$ISERR(tSC) Quit
							}
						} // relation
					} // dimname
				} // dimno

				Set tDimKey = $O(tOrderedDims(tDimKey))
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit

			Set tDim = $O(tCalcMbrs(""))
			While (tDim '= "") {
				Set tIcon = "deepsee/ds2_beaker2_44.png"
				If (tDim = "MEASURES") {
					If ('pSkipMeasures) {
						Set tMbr = $O(tCalcMbrs(tDim,""))
						While (tMbr '= "") {
							Set tInfo = tCalcMbrs(tDim,tMbr)
							Set tMbrCaption = $LG(tInfo,2)
							Set tMbrHidden = +$LG(tInfo,5)
							If ('tMbrHidden) {
								Set c = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,tMbrCaption)
								Set tMbrDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim,tMbrCaption)
								Set:c'="" tMbrCaption = c
								Set tMsrCount = tMsrCount + 1
								Set tHasChild = 0

								Set tStyle = "color:rgb(91,92,67);"
								// use different color for locally defined items
								If ($D(pLocalCalcMembers(tDim,tMbr)))||($D(tSharedCalcMbrs(tDim,tMbr))) {
									Set tStyle = "color:rgb(91,92,167);"
								}
								// DTB268 - Flag the calc member as shared
								Set tSharedToken="" 
								If ($D(tSharedCalcMbrs(tDim,tMbr)))&&('$D(pLocalCalcMembers(tDim,tMbr))) {
									Set tSharedToken = "%SHAREDCALC."
								}
								
								Set pTree($I(pTree)) = $LB(tMbrCaption,tSharedToken_"["_$$$dsEscapeIdent(tDim)_"].["_$$$dsEscapeIdent(tMbr)_"]",tHasChild,"",0,tIcon,$s(tMbrDescription'="":tMbrDescription,1:tMbrCaption),tStyle) // JSL4451 - invoke $$$dsEscapeIdent
								Set pTree(tMsrRoot,"ch",pTree) = ""
							}
							Set tMbr = $O(tCalcMbrs(tDim,tMbr))
						}
					}
				}
				ElseIf ('$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))) {
					// Get info from first member
					Set k = $O(tCalcMbrs(tDim,""))
					If (k'="") {
						Set tDimInfo = tCalcMbrs(tDim,k)
						Set tDimName = tDim
						Set tDimCaption = $LG(tDimInfo,1)
						Set tDimDescription=""
						try {
							Set tDimDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",tDim) // JSL4476
						} catch {}
						// !!! ALL MEMBERS
						// make sure this isn't a "regular" dimension
						// JMD1006: only add entry if there are non-hidden children
						Set tParentCreated = 0

						While (k'="") {
							Set tMbrInfo = tCalcMbrs(tDim,k)
							Set tMbrHidden = +$LG(tMbrInfo,5)
							If ('tMbrHidden) {
								// JMD1006
								If ('tParentCreated) {
									Set pTree($I(pTree)) = $LB(tDimCaption,"["_$$$dsEscapeIdent(tDimName)_"]" _ ".AllMembers",1,"",0,,$s(tDimDescription'="":tDimDescription,1:tDimCaption),"font-weight:bold;color:rgb(80,120,80);") // JSL4451 - invoke $$$dsEscapeIdent
									Set pTree(tDimRoot,"ch",pTree) = ""
									Set tDimParent = pTree
									Set tParentCreated = 1
								}
								
								// DTB268 - Color all local members
								Set tStyle = "color:rgb(91,92,67);"
								// use different color for locally defined items
								If ($D(pLocalCalcMembers(tDim,k)))||($D(tSharedCalcMbrs(tDim,k))) {
									Set tStyle = "color:rgb(91,92,167);"
								}
								//DTB268 - Flag the calc member as shared
								Set tSharedToken="" 
								If ($D(tSharedCalcMbrs(tDim,k)))&&'($D(pLocalCalcMembers(tDim,k))) {
									Set tSharedToken = "%SHAREDCALC."
								}
								
								Set tMbrSpec = tSharedToken_"["_$$$dsEscapeIdent(tDim)_"].["_$$$dsEscapeIdent($LG(tMbrInfo,2))_"]" // JSL4451 - invoke $$$dsEscapeIdent
								Set tDimDescription=$zobjclassmethod(tClassName,"%GetMemberDescription",tDim,$LG(tMbrInfo,2))
								Set pTree($I(pTree)) = $LB($LG(tMbrInfo,2),tMbrSpec,0,"",0,tIcon,$s(tDimDescription'="":tDimDescription,1:$LG(tMbrInfo,2)),tStyle) // JSL4476	// DTB268 - Add icon and style
								Set pTree(tDimParent,"ch",pTree) = ""
							}
							Set k = $O(tCalcMbrs(tDim,k))
						}
					}
				}
				Set tDim = $O(tCalcMbrs(tDim))
			}

			// Named sets
			// combine local list with those defined in the cube
			Merge tNamedSets = $$$DeepSeeMetaGLVN("cubes",tCube,"namedSets")
			Merge tNamedSets = pLocalNamedSets

			Set tSet = $O(tNamedSets(""))
			While (tSet '= "") {
				Set tInfo = tNamedSets(tSet)
				Set tSetCaption = $LG(tInfo,1)
				Set tSetCaption = $zobjclassmethod(tClassName,"%GetMemberCaption","%%NAMEDSETS",tSetCaption)
				Set tSetDescription = $zobjclassmethod(tClassName,"%GetMemberDescription","%%NAMEDSETS",$LG(tInfo,1))
				Set tDimCount = tDimCount + 1
				Set tHasChild = 0
	
				If (tNamedSetsRoot="") {
					Set tNamedSetsRoot = $I(pTree)
				}
				Set tIcon = "deepsee/ds2_sun_44.png"
				Set pTree($I(pTree)) = $LB(tSetCaption,"["_$$$dsEscapeIdent(tSet)_"]",tHasChild,"",0,tIcon,$s(tSetDescription'="":tSetDescription,1:tSetCaption),"font-weight:bold;color:rgb(91,92,67);") // JSL4451 - invoke dsEscapeIdent
				Set pTree(tNamedSetsRoot,"ch",pTree) = ""
				Set tSet = $O(tNamedSets(tSet))
			}

			// now add the top nodes
			If (tDimCount >= 0) {
				Set tHasChild = tDimCount > 0
				Set pTree(0,"ch",tDimRoot) = ""
				Set pTree(tDimRoot) = $LB($$$Text("Dimensions","%DeepSee"),"",tHasChild,"",1,,$$$Text("Dimensions","%DeepSee"),"font-weight:bold;")
			}
			If ((tMsrCount >= 0) && 'pSkipMeasures) {
				Set tHasChild = tMsrCount > 0
				Set pTree(0,"ch",tMsrRoot) = ""
				Set pTree(tMsrRoot) = $LB($$$Text("Measures","%DeepSee"),"",tHasChild,"",1,,$$$Text("Measures","%DeepSee"),"font-weight:bold;")
			}
			If ((tFilterCount > 0) && (tFilterRoot'="") && 'pSkipMeasures) {
				Set tHasChild = tFilterCount > 0
				Set pTree(0,"ch",tFilterRoot) = ""
				Set pTree(tFilterRoot) = $LB($$$Text("Named Filters","%DeepSee"),"",tHasChild,"",1,,$$$Text("Named Filters","%DeepSee"),"font-weight:bold;")
			}
			If ((tQMsrCount > 0) && (tQMsrRoot'="")) {
				Set tHasChild = tQMsrCount > 0
				Set pTree(0,"ch",tQMsrRoot) = ""
				Set pTree(tQMsrRoot) = $LB($$$Text("Quality Measures","%DeepSee"),"",tHasChild,"",1,,$$$Text("Quality Measures","%DeepSee"),"font-weight:bold;")
			}
			If ((tPlugInCount > 0) && (tPlugInRoot'="")) {
				Set tHasChild = tPlugInCount > 0
				Set pTree(0,"ch",tPlugInRoot) = ""
				Set pTree(tPlugInRoot) = $LB($$$Text("Plug-ins","%DeepSee"),"",tHasChild,"",1,,$$$Text("Plug-ins","%DeepSee"),"font-weight:bold;")
			}
			If ($D(tNamedSets) && (tNamedSetsRoot'="") ) {
				Set tHasChild = ''$D(tNamedSets)
				Set pTree(0,"ch",tNamedSetsRoot) = ""
				Set pTree(tNamedSetsRoot) = $LB($$$Text("Named Sets","%DeepSee"),"",tHasChild,"",1,,$$$Text("Named Filters","%DeepSee"),"font-weight:bold;")
			}
			If ((tVariableCount > 0) && (tVariableRoot'="")) {
				Set tHasChild = tVariableCount > 0
				Set pTree(0,"ch",tVariableRoot) = ""
				Set pTree(tVariableRoot) = $LB($$$Text("Pivot Variables","%DeepSee"),"",tHasChild,"",1,,$$$Text("Pivot Variables","%DeepSee"),"font-weight:bold;")
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get list of saved pivots for a cube for display within a tree.
ClassMethod %GetPivotTree(pCube As %String, ByRef pTree, pCurrPivot As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			Set tSession = $G($$$DeepSeeSession)
		}

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		If ('..%CheckPrivilege(tCube)) Quit

		Set pCurrPivot = $P(pCurrPivot,".",1)

		// list of pivots
		Set tSC = ..%GetPivotList(.tPivotList,0,pCube)
		If $$$ISERR(tSC) Quit

		Set tPivotCount = 0
		Kill pTree
		Set pTree = 0
		Set tPivotRoot = ""

		If $D(tPivotList) {
			If (tPivotRoot="") {
				Set tPivotRoot = $I(pTree)
			}

			// JMD1417 replace old logic
			// list of items by full name
			Kill tItems
			Set k = $O(tPivotList(""))
			While (k'="") {
				Set tFullName = $LG(tPivotList(k),1)
				Set tItems(tFullName) = k
				Set k = $O(tPivotList(k))
			}

			// now emit items into folders
			Kill tFolderRoot
			Set tFolderRoot(-1E14) = tPivotRoot

			Set k = $O(tItems(""))
			While (k'="") {
				Set tIndex = tItems(k)
				Set tPivotName = $LG(tPivotList(tIndex),2) 
				Set tFullName = k
				Set tStyle = ""
				If (tFullName = pCurrPivot) {
					Set tStyle = "font-weight:bold; color:darkblue;"
				}

				If (tFullName["/") {
					Set tFolder =$P(tFullName,"/",1,$L(tFullName,"/")-1)
					Set tName = $P(tFullName,"/",$L(tFullName,"/"))

					// pull apart folder; test if we have seen the pieces of the folder
					Set tRoot = tPivotRoot
					For fn = 1:1:$L(tFolder,"/") {
						Set tFName = $P(tFolder,"/",fn)
						Set tFNameFull = $P(tFolder,"/",1,fn)
						If '$D(tFolderRoot(tFNameFull)) {
							Set pTree($I(pTree)) = $LB(tFName,"",1)
							Set pTree(tRoot,"ch",pTree) = ""
							Set tRoot = pTree
							Set tFolderRoot(tFNameFull) = tRoot
						}
						Else {
							Set tRoot = tFolderRoot(tFNameFull)
						}
					}
				}
				Else {
					Set tFolder = -1E14
					Set tName = tFullName
				}

				Set pTree($I(pTree)) = $LB(tPivotName,tFullName,0,"",0,"","",tStyle)
				Set pTree(tFolderRoot(tFolder),"ch",pTree) = ""
				Set tPivotCount = tPivotCount + 1

				Set k = $O(tItems(k))
			}
		}

		If ((tPivotCount > 0) && (tPivotRoot'="")) {
			Set tHasChild = tPivotCount > 0
			Set pTree(0,"ch",tPivotRoot) = ""
			Set pTree(tPivotRoot) = $LB($$$Text("Pivots","%DeepSee"),"",tHasChild,"",1,,$$$Text("Pivots saved for this Subject Area","%DeepSee"),"font-weight:bold;")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get list of quality measures for display within a tree.
ClassMethod %GetQualityMeasureTree(pCube As %String, ByRef pTree) As %Status
{
	Set tSC = $$$OK
	Try {
		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			Set tSession = $G($$$DeepSeeSession)
		}

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		If ('..%CheckPrivilege(tCube)) Quit

		// quality measures
		Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasuresForCube(.tQMsrList,pCube)
		If $$$ISERR(tSC) Quit

		Set tQMsrCount = 0
		Kill pTree
		Set pTree = 1
		Set tQMsrRoot = ""

		// JMD905: quality measures
		If $D(tQMsrList) {
			If (tQMsrRoot="") {
				Set tQMsrRoot = $I(pTree)
			}

			// first split into catalog/set/id
			Set q = $O(tQMsrList(""))
			While (q'="") {
				Set tQName = $LG(tQMsrList(q),1)
				Set tQCatalog = $P(tQName,"/",1)
				Set tQSet = $P(tQName,"/",2)
				Set tQId = $P(tQName,"/",3)
				Set tCaption = $LG(tQMsrList(q),2)
				Set:tCaption="" tCaption = tQId
				Set tDesc = $LG(tQMsrList(q),3)
				Set tQList(tQCatalog,tQSet,tQId) = $LB(tQName,tCaption,tDesc)
				Set q = $O(tQMsrList(q))
			}

			// now add to tree
			Set tIcon = "deepsee/ds2_beaker_44.png"
			Set tQCatalog = $O(tQList(""))
			While (tQCatalog'="") {
				Set pTree($I(pTree)) = $LB(tQCatalog,,1,"",0,"",$$$Text("Catalog","%DeepSee"))
				Set pTree(tQMsrRoot,"ch",pTree) = ""
				Set tQCatNo = pTree
				Set tQMsrCount = tQMsrCount + 1

				Set tQSet = $O(tQList(tQCatalog,""))
				While (tQSet'="") {
					Set pTree($I(pTree)) = $LB(tQSet,,1,"",0,"",$$$Text("Set","%DeepSee"))
					Set pTree(tQCatNo,"ch",pTree) = ""
					Set tQSetNo = pTree

					Set tQId = $O(tQList(tQCatalog,tQSet,""))
					While (tQId'="") {
						// JMD1098 Get groups and elements of the qmsr
						Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityElements($LG(tQList(tQCatalog,tQSet,tQId),1),.tQElList)

						Set tSpec = "[%QualityMeasure].["_$$$dsEscapeIdent($LG(tQList(tQCatalog,tQSet,tQId),1))_"]" // JSL4451 invoke $$$dsEscapeIdent
						Set pTree($I(pTree)) = $LB($LG(tQList(tQCatalog,tQSet,tQId),2),tSpec,''$D(tQElList),"",0,tIcon,$LG(tQList(tQCatalog,tQSet,tQId),3),"font-weight:bold;")
						Set pTree(tQSetNo,"ch",pTree) = ""
						Set tQIdNo = pTree

						// add groups to tree
						Set tQGroup = $O(tQElList(""))
						While (tQGroup'="") {
							Set tSpec = "[%QualityMeasure].["_$$$dsEscapeIdent($LG(tQList(tQCatalog,tQSet,tQId),1)_"/"_tQGroup)_"]" // JSL4451 invoke $$$dsEscapeIdent
							Set pTree($I(pTree)) = $LB(tQGroup,tSpec,1,"",0,"",$$$Text("Group","%DeepSee"),"color:#608060;")
							Set pTree(tQIdNo,"ch",pTree) = ""
							Set tQGroupNo = pTree

							Set tQElement = $O(tQElList(tQGroup,""))
							While (tQElement'="") {
								Set tSpec = "[%QualityMeasure].["_$$$dsEscapeIdent($LG(tQList(tQCatalog,tQSet,tQId),1)_"/"_tQGroup_"/"_tQElement)_"]" // JSL4451 invoke $$$dsEscapeIdent
								Set pTree($I(pTree)) = $LB(tQElement,tSpec,0,"",0,"",$$$Text("Element","%DeepSee"),"color:#606080;")
								Set pTree(tQGroupNo,"ch",pTree) = ""

								Set tQElement = $O(tQElList(tQGroup,tQElement))
							}
							Set tQGroup = $O(tQElList(tQGroup))
						}


						Set tQId = $O(tQList(tQCatalog,tQSet,tQId))
					}
					Set tQSet = $O(tQList(tQCatalog,tQSet))
				}
				Set tQCatalog = $O(tQList(tQCatalog))
			}
		}


		If ((tQMsrCount > 0) && (tQMsrRoot'="")) {
			Set tHasChild = tQMsrCount > 0
			Set pTree(0,"ch",tQMsrRoot) = ""
			Set pTree(tQMsrRoot) = $LB($$$Text("Quality Measures","%DeepSee"),"",tHasChild,"",1,,$$$Text("Quality Measures","%DeepSee"),"font-weight:bold;")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Copy source tree (from root) into <var>pTree</var> at the given parent node.
/// Return number of nodes copied.
ClassMethod %CopyTree(pName As %String, ByRef pTree, pParent As %Integer, ByRef pSource, pRoot As %Integer) As %Integer [ Internal ]
{
	Set tCount = 0
	Set k = $O(pSource(pRoot,"ch",""))
	While (k '= "") {
		Set tNode = pSource(k)
		Set tVal = $LG(tNode,2)
		If ((tVal'="")) {
			Set tName = pName
			Set:$E(tName)'="[" tName = "["_tName_"]"
			If ($E(tVal,1,2)="@@") {
				// relation ref
				Set tVal = tVal_"^"_tName
			}
			Else {
				Set tVal = ""_tName_"."_tVal
			}
			Set $List(tNode,2) = tVal
		}
		Set tCount = tCount + 1
		Set pTree($I(pTree)) = tNode
		Set pTree(pParent,"ch",pTree) = ""
		If $D(pSource(k,"ch")) {
			Set tCount = tCount + ..%CopyTree(pName,.pTree,pTree,.pSource,k)
		}
		Set k = $O(pSource(pRoot,"ch",k))
	}
	Quit tCount
}

/// Return the dimension,hierarchy, and level number of the specified element
/// within the specified cube.<br/>
/// <var>pCubeName</var> is the name of the cube.<br/>
/// <var>pSpec</var> specifies the dimension in the form:
/// "Dim.Hier.Level" or "Dim.Hier.Level.member".<br/>
/// If <var>pStrict</var> is false, then find a level: Hier or Level can be omitted if they are not ambiguous.<br/>
/// <var>pSpecInfo</var> is the array produced by parsing <var>pSpec</var>.
/// This is returned as a convenience.<br/>
/// <var>pLocalCalcMembers</var> is an optional list of locally defined calculated members.
/// <var>pLocalNamedSets</var> is an optional list of locally defined named sets.
ClassMethod %GetDimensionInfo(pCubeName As %String, pSpec As %String, Output pDimNo, Output pHierNo, Output pLevelNo, Output pRelationName As %String, Output pRelationSpec As %String, Output pSpecInfo As %String, ByRef pLocalCalcMembers, pStrict As %Boolean = 1, ByRef pLocalNamedSets) As %Status
{
	Set tSC = $$$OK
	Try {
		Set (pDimNo,pHierNo,pLevelNo) = ""
		Set pRelationName = ""
		Set pRelationSpec = ""
		Set tCube = $$$UPPER(pCubeName)
		Set tIsTop = 0

		// JMD920: prevent undefined
		If (tCube="") Quit

		// JMD1276
		If ($E(pSpec,1,5)="%VAR:") {
			Set pDimNo = -2
			Set pHierNo = 0
			Set pLevelNo = 0
			Quit
		}

		// DTB043 - Test for %OR() wrapped around expression; remove it
		If ($E(pSpec,1,4)="%OR(") {
			Set pSpec = $E(pSpec,5,$L(pSpec)-1)
		}

		// replace %TopMembers
		// to make filters in pivotTable work
		If (pSpec [ ".%TopMembers") {
			Set tIsTop = 1
			Set tDim = $Replace(pSpec,".%TopMembers","")
			If ($E(tDim)="[") {
				Set tDim = $E(tDim,2,*-1)
			}
			// guess which hier and level to use!
			Set tDimNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",$$$UPPER(tDim)))
			Set d = +$LG(tDimNode,1)
			Set h = 1
			Set l = +$LG(tDimNode,3)
			Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",d,h,l))
			Set tType = $LG(tDimInfo,1)
			While (tType '= "l") {
				Set l = l + 1
				Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",d,h,l))
				If tDimInfo="" Quit
				Set tType = $LG(tDimInfo,1)
			}
			Set tHier = $LG(tDimInfo,3)
			Set tLevel = $LG(tDimInfo,4)

			Set pSpec = "["_tDim _"]"_".["_tHier _"]"_".["_tLevel _"]"_".Members"
		}
		ElseIf ($E(pSpec,1,1)="{") {
			// spec is a set expression: analyze first element
			Set pSpec = $E(pSpec,2,$L(pSpec)-1)
			If ($L(pSpec,"],[")>1) {
				Set pSpec = $P(pSpec,"],[",1) _ "]"
			}
		}

		Kill pSpecInfo
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pSpec,.pSpecInfo,.tQuoted)
		If $$$ISERR(tSC) Quit

		Set tDim = $$$UPPER($G(pSpecInfo(1)))
		Set tHier = $$$UPPER($G(pSpecInfo(2)))
		Set tLevel = $$$UPPER($G(pSpecInfo(3)))

		// check if tDim is a relationship
		If ((tDim'="")&&$D($$$DeepSeeMetaGLVN("cubes",tCube,"relations",tDim))) {
			Set pRelationName = tDim
			Set pRelationSpec = $P(pSpec,".",2,$L(pSpec,"."))  // remove first piece
			Quit
		}
		
		// Test for quality measures
		// JMD905 - test for special [%QualityMeasure] dimension
		If ((tDim="%QUALITYMEASURE")&&(tHier'="")) {
			// look up the qmsr
			Set tQMsrClass = $G($$$DeepSeeQMsrGLVN("qmsrNames",tHier))
			If (tQMsrClass="") {
				Set tSC = $$$ERROR($$$GeneralError,"Quality Measure not found: " _ tHier)
				Quit
			}
			Set pDimNo = -2
			Set pHierNo = 0
			Set pLevelNo = 0
			Quit
		}

		// DTB575 - Test for $NAMEDFILTER token
		If (tDim="$NAMEDFILTER") {
			Set pDimNo = -2
			Set pHierNo = 0
			Set pLevelNo = 0
			Quit
		}

		// Named sets
		// combine local list with those defined in the cube
		Merge tNamedSets = $$$DeepSeeMetaGLVN("cubes",tCube,"namedSets")
		Merge tNamedSets = pLocalNamedSets
		If ((tDim'="")&&$D(tNamedSets(tDim))&&'$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))) {
			Set pDimNo = -2
			Set pHierNo = 0
			Set pLevelNo = 0
			Quit
		}

		// check for calculated members
		// combine local list with those defined in the cube
		Merge tCalcMbrs = $$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs")
		
		// +DTB268 - Add shared calculated members
		Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMembers(tCube,.tSharedCalcArray)
		Set tSharedCalcIdx = $O(tSharedCalcArray(""),1,tSharedCalcData)
		While tSharedCalcIdx'="" {
			Set tSharedCalcDimKey = $$$UPPER($LG(tSharedCalcData,1))
			Set tSharedCalcKey = $$$UPPER($LG(tSharedCalcData,2))
			Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMemberInfo(tCube,tSharedCalcDimKey,tSharedCalcKey,.tMbrInfo)
			If $D(tMbrInfo) {
				// $LB(dimension,name,expression,format,hidden)
				Set tSharedCalcMbrs(tSharedCalcDimKey,tSharedCalcKey) = $LB(tMbrInfo("dimension"),tMbrInfo("name"),tMbrInfo("expression"),tMbrInfo("format"))		// DTB461 - Remove solveOrder in the hidden position
			}
			
			Set tSharedCalcIdx = $O(tSharedCalcArray(tSharedCalcIdx),1,tSharedCalcData)
		}
		Merge tCalcMbrs = tSharedCalcMbrs
		// -DTB268
		
		Merge tCalcMbrs = pLocalCalcMembers

		// first test for calc mbrs within their own dimension
		If ((tDim'="")&&$D(tCalcMbrs(tDim))&&'$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))) {
			Set pDimNo = -1
			Set pHierNo = 0
			Set pLevelNo = 0
			Quit
		}

		// resolve missing terms
		If (('pStrict) && (tDim'="")) {
			If ((tHier="")||('$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier)))) {
				Set tHier = ..%GetDefaultHierarchy(pCubeName,tDim)
				If (tHier'="") {
					// slide items down
					Set n = $O(pSpecInfo(""),-1)
					While ((n'="")&&(n>1)) {
						Set pSpecInfo(n+1) = pSpecInfo(n)
						Set n = $O(pSpecInfo(n),-1)
					}
					Set pSpecInfo(2) = tHier
					Set tHier = $$$UPPER(tHier)
					Set tLevel = $$$UPPER($G(pSpecInfo(3)))
				}
			}

			If ((tHier'="")&&((tLevel="")||('$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,tLevel))))) {
				Set tLevel = ..%GetDefaultLevel(pCubeName,tDim,tHier)
				If (tLevel'="") {
					// slide items down
					Set n = $O(pSpecInfo(""),-1)
					While ((n'="")&&(n>2)) {
						Set pSpecInfo(n+1) = pSpecInfo(n)
						Set n = $O(pSpecInfo(n),-1)
					}
					Set pSpecInfo(3) = tLevel
					Set tLevel = $$$UPPER(tLevel)
				}
			}
		}

		// look at cube metadata
		//DP-401989: Protected against invalid global references
		If ($G(tMbr)="") Set tMbr=""
		If ((tDim'="") && $D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim)) && (tHier'="") && $D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier)) && (tLevel '= "")) {
			Set tMbr = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,tLevel))
		}
		ElseIf ( (tDim'="") && $D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim)) && (tHier'="") ) {
			Set tMbr = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
		}
		ElseIf (tDim '= "") {
			Set tMbr = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))
		}
		Else {
			Quit
		}
		If (tMbr'=""){
			Set pDimNo = $LG(tMbr,1)
			Set pHierNo = $LG(tMbr,2)
			Set pLevelNo = $LG(tMbr,3)
		}
		If (tIsTop) {
			//Set pLevelNo = pLevelNo + 1 // !!!check for ALL
		}

		If ((pDimNo="")||(pHierNo="")||(pLevelNo="")) {		// DTB641 - fix typo
			// test again for calc member within dimension
			If ((tDim'="")&&$D(tCalcMbrs(tDim))) {
				Set pDimNo = -1
				Set pHierNo = 0
				Set pLevelNo = 0
				Quit
			}

			Set tSC = $$$ERROR($$$GeneralError,"%GetDimensionInfo: Invalid Member spec: " _ pCubeName _ ":" _ pSpec)
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Given the dimension,hierarchy, and level number for a dimension
/// within the specified cube, return it's specification string.
ClassMethod %GetDimensionSpec(pCubeName As %String, Output pSpec As %String, pDimNo As %Integer, pHierNo As %Integer = 0, pLevelNo As %Integer = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCubeName)
		Set tIsTop = 0

		Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo))

		Set tDim = $LG(tDimInfo,2)
		Set tHier = $LG(tDimInfo,3)
		Set tLevel = $LG(tDimInfo,4)

		Set pSpec = "["_tDim _"]"
		Set:tHier'="" pSpec = pSpec _ ".["_tHier _"]"
		Set:tLevel'="" pSpec = pSpec _ ".["_tLevel _"]"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return the measures within the given cube as an array of form:<br/>
/// pMeasures(n) = $LB(name,caption,type,hidden,factName)<br/>
/// If <var>pSkipCalculated</var> is true, then do not include calculated measures.
ClassMethod %GetCubeMeasures(pCube As %String, ByRef pMeasures, pSkipCalculated As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pMeasures
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit
		
		Set tCountName = $$$UPPER(..%GetCountName(pCube,.tSC))
		If $$$ISERR(tSC) Quit

		Set tCount = 0
		Set tMsr = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",""))
		While (tMsr '= "") {
			Set tMsrNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsr))
			Set tDimNo = $LG(tMsrNode,1)
			Set tMsrNo = $LG(tMsrNode,2)

			Set tMsrInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tMsrNo,0))
			Set tMsrName = $LG(tMsrInfo,3)
			Set tMsrType = $LG(tMsrInfo,8)
			Set tMsrHidden = $LG(tMsrInfo,11)
			Set tMsrCaption = $zobjclassmethod(tClassName,"%GetMemberCaption","MEASURES",tMsr)

			// JMD900: pick up fact name
			Set tMsrIndexNo = $LG(tMsrInfo,5)
			Set tMsrFactName = ""
			If (tMsrIndexNo'="") {
				Set tMsrFactName = $G($$$DeepSeeMetaGLVN("cubes",tCube,"msr#",tMsrIndexNo))
			}

			If (tMsrName = tCountName) {
				Set tMsrCaption = ..%GetCountCaption(tCube,.tSC)
				If $$$ISERR(tSC) Quit
			}

			Set tCount = tCount + 1
			Set pMeasures(tCount) = $LB(tMsrName,tMsrCaption,tMsrType,tMsrHidden,tMsrFactName)

			Set tMsr = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsr))
		}
		If $$$ISERR(tSC) Quit

		If ('+pSkipCalculated) {
			// calculated measures
			// +DTB587 - Collect cube- and user-defined calculated measures 
			Merge tCalcMbrs = $$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs")
			
			Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMembers(tCube,.tSharedCalcMbrs)
			If $$$ISERR(tSC) Quit
			
			Set tSharedCalcIdx = $O(tSharedCalcMbrs(""),1,tSharedCalcData)
			While tSharedCalcIdx'="" {
				Set tSharedCalcDimKey = $$$UPPER($LG(tSharedCalcData,1))
				Set tSharedCalcKey = $$$UPPER($LG(tSharedCalcData,2))
				Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMemberInfo(tCube,tSharedCalcDimKey,tSharedCalcKey,.tMbrInfo)
				If $D(tMbrInfo) {
					// $LB(dimension,name,expression,format,hidden)
					Set tSharedCalcMbrs(tSharedCalcDimKey,tSharedCalcKey) = $LB(tMbrInfo("dimension"),tMbrInfo("name"),tMbrInfo("expression"),tMbrInfo("format"))		// DTB461 - Remove solveOrder in the hidden position
				}
				
				Set tSharedCalcIdx = $O(tSharedCalcMbrs(tSharedCalcIdx),1,tSharedCalcData)
			}
			
			Merge tCalcMbrs = tSharedCalcMbrs
			// -DTB587
			
			Set tDim = $O(tCalcMbrs(""))
			While (tDim '= "") {
				If (tDim = "MEASURES") {
					Set tMbr = $O(tCalcMbrs(tDim,""),1,tInfo)
					While (tMbr '= "") {
						// PFS066 - Use tMbrName to get tMbrCaption from %GetMemberCaption, use tMbrName if no caption specified
						Set tMbrName = $LG(tInfo,2)
						Set tMbrCaption = $zobjclassmethod(tClassName,"%GetMemberCaption","Measures",tMbrName)
						Set:tMbrCaption="" tMbrCaption = tMbrName
						Set tMbrType = "numeric"

						Set tCount = tCount + 1
						// PFS066 - Name should be first list item in output, not caption
						Set pMeasures(tCount) = $LB(tMbrName,tMbrCaption,tMbrType)
						Set tMbr = $O(tCalcMbrs(tDim,tMbr),1,tInfo)
					}
				}
				Set tDim = $O(tCalcMbrs(tDim))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return all named filters for a given cube as an array of form:<br/>
/// pFilters(n) = $LB(name,tooltip,spec,cube)<br/>
ClassMethod %GetNamedFilters(pCube As %String, ByRef pFilters, pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		
		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336
		
		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) {
			// JMD932: fail without error
			Set tSC = $$$OK
			Quit
		}

		// get any named filters from our base cube
		Set tBaseCube = ..%GetBaseCube(tCube)
		If (tBaseCube'="") {
			Set tSC = ..%GetNamedFilters(tBaseCube,.tBaseFilters)
			If $$$ISERR(tSC) Quit
			Merge pFilters = tBaseFilters
		}

		If ('$D($$$DeepSeeFiltersGLVN(tCube))) Quit

		Set tFilter = $O($$$DeepSeeFiltersGLVN(tCube,""))
		While (tFilter '= "") {
			Set tFilterNode = $G($$$DeepSeeFiltersGLVN(tCube,tFilter))
			Set tFilterName = $LG(tFilterNode,1)
			Set tFilterTip = $LG(tFilterNode,2)
			Set tFilterSpec = $LG(tFilterNode,3)
			Set pFilters($I(pFilters)) = $LB(tFilterName,tFilterTip,tFilterSpec,tCube)
			Set tFilter = $O($$$DeepSeeFiltersGLVN(tCube,tFilter))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Delete the given named filter for the given cube.
/// If <var>pFilterName</var> is "*", then delete all named filters for the cube.
ClassMethod %DeleteNamedFilter(pCube As %String, pFilterName As %String = "", pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pFilterName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		
		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		If (pFilterName="*") {
			Kill $$$DeepSeeFiltersGLVN(tCube)
		}
		Else {
			Kill $$$DeepSeeFiltersGLVN(tCube,$$$UPPER(pFilterName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return details on the given named filter in the array <var>pInfo</var>.
ClassMethod %GetNamedFilterInfo(pCube As %String, pFilterName As %String, Output pInfo, pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pInfo
		If (pFilterName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		
		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tInfo = $G($$$DeepSeeFiltersGLVN(tCube,$$$UPPER(pFilterName)))
		If (tInfo'="") {
			Set pInfo("name") = $LG(tInfo,1)
			Set pInfo("tooltip") = $LG(tInfo,2)
			Set pInfo("spec") = $LG(tInfo,3)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Save a named filter.
ClassMethod %SaveNamedFilter(pCube As %String, pFilterName As %String, pTooltip As %String, pSpec As %String, pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pFilterName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		// save filter
		Set $$$DeepSeeFiltersGLVN(tCube,$$$UPPER(pFilterName)) = $LB(pFilterName,pTooltip,pSpec)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return all shared calculated members for a given cube as an array of form:<br/>
/// pCalcMbrs(n) = $LB(name,tooltip,dimension,cube)<br/>
ClassMethod %GetSharedCalcMembers(pCube As %String, ByRef pCalcMbrs, pUseCubeVersion As %Boolean = 0) As %Status
{
	// Method added byDTB268
	Kill pCalcMbrs
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) {
			// JMD932: fail without error
			Set tSC = $$$OK
			Quit
		}

		// get any shared calculated members from our base cube
		Set tBaseCube = ..%GetBaseCube(tCube)
		If (tBaseCube'="") {
			Set tSC = ..%GetSharedCalcMembers(tBaseCube,.tBaseMembers)
			If $$$ISERR(tSC) Quit
			Merge pCalcMbrs = tBaseMemebrs
		}

		If ('$D($$$DeepSeeSharedCalcGLVN(tCube))) Quit

		Set tSharedDim = $O($$$DeepSeeSharedCalcGLVN(tCube,""))
		While (tSharedDim'="") {
			Set tSharedCalc = $O($$$DeepSeeSharedCalcGLVN(tCube,tSharedDim,""),1,tCalcNode)
			While (tSharedCalc '= "") {
				Set tCalcDim = $LG(tCalcNode,1)
				Set tCalcName = $LG(tCalcNode,2)
				Set pCalcMbrs($I(pCalcMbrs)) = $LB(tCalcDim,tCalcName,"["_tCalcDim_"].["_tCalcName_"]",tCube)
				Set tSharedCalc = $O($$$DeepSeeSharedCalcGLVN(tCube,tSharedDim,tSharedCalc),1,tCalcNode)
			}
			Set tSharedDim = $O($$$DeepSeeSharedCalcGLVN(tCube,tSharedDim))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Delete the given shared calculated member for the given cube.
/// If <var>pCalcMbrName</var> is "*", then delete all shared calculated members for the cube.
ClassMethod %DeleteSharedCalcMember(pCube As %String = "", pCalcMbrName As %String = "", pDimension As %String = "", pUseCubeVersion As %Boolean = 0) As %Status
{
	// Method added byDTB268
	Set tSC = $$$OK
	Try {
		If (pCalcMbrName="") Quit
		If (pDimension="")&&(pCalcMbrName'="*") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		If (pCalcMbrName="*") {
			Kill $$$DeepSeeSharedCalcGLVN(tCube)
		}
		Else {
			Kill $$$DeepSeeSharedCalcGLVN(tCube,$$$UPPER(pDimension),$$$UPPER(pCalcMbrName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return details on the given shared calculated member in the array <var>pInfo</var>.
ClassMethod %GetSharedCalcMemberInfo(pCube As %String, pDimension As %String = "", pCalcMbrName As %String = "", Output pInfo, pUseCubeVersion As %Boolean = 0) As %Status
{
	// Method added byDTB268
	Set tSC = $$$OK
	Try {
		Kill pInfo
		If (pCalcMbrName="") Quit
		If (pDimension="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		// $LB(pDimension,pCalcMbrName,pValueExpression,pFormatString,pSolveOrder)
		Set tInfo = $G($$$DeepSeeSharedCalcGLVN(tCube,$$$UPPER(pDimension),$$$UPPER(pCalcMbrName)))
		If (tInfo'="") {
			Set pInfo("dimension") = $LG(tInfo,1)
			Set pInfo("name") = $LG(tInfo,2)
			Set pInfo("expression") = $LG(tInfo,3)
			Set pInfo("format") = $LG(tInfo,4)
			Set pInfo("solveOrder") = $LG(tInfo,5)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Store the details of a calulated member in the shared location.
ClassMethod %SaveSharedCalcMember(pCube As %String = "", pCalcMbrName As %String = "", pDimension = "", pValueExpression = "", pFormatString = "", pSolveOrder, pUseCubeVersion As %Boolean = 0) As %Status
{
	// Method added byDTB268
	Set tSC = $$$OK
	If (pCalcMbrName="") {
		Set tSC = $$$ERROR($$$GeneralError,"Shared calculated member must define a name")
		Quit
	}
	If (pDimension="") {
		Set tSC = $$$ERROR($$$GeneralError,"Shared calculated member must define a dimension")
		Quit
	}
		
	Try {
		Set tCube = $$$UPPER(pCube)
		If (tCube="") {
			Set tSC = $$$ERROR($$$GeneralError,"No cube defined for shared calculated member")
			Quit
		}
		
		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336
		
		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit
		
		// This matches the format of calc members in 
		Set $$$DeepSeeSharedCalcGLVN(tCube,$$$UPPER(pDimension),$$$UPPER(pCalcMbrName)) = $LB(pDimension,pCalcMbrName,pValueExpression,pFormatString,pSolveOrder)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return all pivot variables for a given cube as an array of form:<br/>
/// pVariables(n) = $LB(name,caption,defValue,context,desc)<br/>
ClassMethod %GetPivotVariables(pCube As %String, ByRef pVariables, pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		
		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) {
			// fail without error
			Set tSC = $$$OK
			Quit
		}

		// get any variables from our base cube
		Set tBaseCube = ..%GetBaseCube(tCube)
		If (tBaseCube'="") {
			Set tSC = ..%GetPivotVariables(tBaseCube,.tBaseVariables)
			If $$$ISERR(tSC) Quit
			Merge pVariables = tBaseVariables
		}

		If ('$D($$$DeepSeeVariablesGLVN(tCube))) Quit

		Set tVariable = $O($$$DeepSeeVariablesGLVN(tCube,""))
		While (tVariable '= "") {
			Set tVariableNode = $G($$$DeepSeeVariablesGLVN(tCube,tVariable))
			Set tVariableName = $LG(tVariableNode,1)
			Set tVariableCaption = $LG(tVariableNode,2)
			Set:tVariableCaption="" tVariableCaption = tVariableName
			Set tVariableDesc = $LG(tVariableNode,3)
			Set tVariableDefValue = $LG(tVariableNode,4)
			Set tVariableContext = $LG(tVariableNode,5)
			Set pVariables($I(pVariables)) = $LB(tVariableName,tVariableCaption,tVariableDefValue,tVariableContext,tVariableDesc)
			Set tVariable = $O($$$DeepSeeVariablesGLVN(tCube,tVariable))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Delete the given pivot variable for the given cube.
/// If <var>pVariableName</var> is "*", then delete all pivot variables for the cube.
ClassMethod %DeletePivotVariable(pCube As %String, pVariableName As %String = "", pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pVariableName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		If (pVariableName="*") {
			Kill $$$DeepSeeVariablesGLVN(tCube)
		}
		Else {
			Kill $$$DeepSeeVariablesGLVN(tCube,$$$UPPER(pVariableName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return details on the given pivot variable in the array <var>pInfo</var>.
ClassMethod %GetPivotVariableInfo(pCube As %String, pVariableName As %String, Output pInfo, pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pInfo
		If (pVariableName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		
		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tInfo = $G($$$DeepSeeVariablesGLVN(tCube,$$$UPPER(pVariableName)))
		If (tInfo'="") {
			Set pInfo("name") = $LG(tInfo,1)
			Set pInfo("displayName") = $LG(tInfo,2)
			Set pInfo("description") = $LG(tInfo,3)
			Set pInfo("defaultValue") = $LG(tInfo,4)
			Set pInfo("context") = $LG(tInfo,5)
			Set pInfo("type") = $LG(tInfo,6)
			Set pInfo("sourceType") = $LG(tInfo,7)
			Set pInfo("sourceName") = $LG(tInfo,8)
			Set pInfo("valueList") = $LG(tInfo,9)
			Set pInfo("displayList") = $LG(tInfo,10)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Save a pivot variable.
/// The variable's attributes are in the array <var>pInfo</var>.
ClassMethod %SavePivotVariable(pCube As %String, pVariableName As %String, ByRef pInfo As %String, pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pVariableName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		// save variable
		Set $$$DeepSeeVariablesGLVN(tCube,$$$UPPER(pVariableName)) = $LB(pVariableName,
																	$G(pInfo("displayName")),
																	$G(pInfo("description")),
																	$G(pInfo("defaultValue")),
																	$G(pInfo("context")),
																	$G(pInfo("type")),
																	$G(pInfo("sourceType")),
																	$G(pInfo("sourceName")),
																	$G(pInfo("valueList")),
																	$G(pInfo("displayList"))
																	)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Find all values for a given pivot variable.<br/>
/// Return pValues(n) = $LB(text,spec)
ClassMethod %GetPivotVariableValues(pCube As %String, pVariableName As %String, Output pValues, pUseCubeVersion As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pVariableName="") Quit
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit

		Set:'pUseCubeVersion tCube = ##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube)		// DTB336

		// check permission
		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tInfo = $G($$$DeepSeeVariablesGLVN(tCube,$$$UPPER(pVariableName)))
		If (tInfo'="") {
			Set tSourceType = $LG(tInfo,7)
			Set tSourceName = $LG(tInfo,8)

			If (tSourceType="kpi") {
				// get "Value" column from KPI
				Set tKPIName = $P(tSourceName,".",1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tKPIName)

				Set tSC = $classmethod(tKPIClass,"%GetKPIValueArray",tKPIName,.tValues,$LB("%series","Value"))
				If $$$ISERR(tSC) Quit

				Set k = $O(tValues(""))
				While (k'="") {
					Set pValues($I(pValues)) = $LB($LG(tValues(k),1),$LG(tValues(k),2))
					Set k = $O(tValues(k))
				}
				If $$$ISERR(tSC) Quit
			}
			ElseIf (tSourceType="termlist") {
				Set tTermList = $P(tSourceName,".",1)
				Set tSC = ##class(%DeepSee.TermList).%GetValueArray(tTermList,.tArray)
				If $$$ISERR(tSC) Quit

				Set k = $O(tArray(""))
				While (k'="") {
					Set pValues($I(pValues)) = $LB(k,tArray(k))
					Set k = $O(tArray(k))
				}
			}
			// + WAL157 -- we need to return values for manual pivot variables too
			ElseIf (tSourceType="manual") {
				// DTB569 - Replace escaped commas with a special character
				Set tValueList = $Replace($LG(tInfo,9),"\,",$C(1))
				Set tCaptionList = $Replace($LG(tInfo,10),"\,",$C(1))
				
				For i=1:1:$L(tValueList,",") {
					Set tValue = $P(tValueList,",",i)
					Set tCaption = $P(tCaptionList,",",i)
					Set tCaption = $S(tCaption'="":tCaption,1:tValue)
					
					// DTB569 - Replace escaped commas in the individual items
					Set tValue = $Replace(tValue,$C(1),",")
					Set tCaption = $Replace(tCaption,$C(1),",")
					
					Set pValues(i) = $LB(tCaption,tValue)		// DTB525 - Caption comes first!
				}
			}
			// - WAL157
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return the searchable measures within the given cube as an array of form:<br/>
/// pMeasures(n) = $LB(name,caption,type)
ClassMethod %GetCubeSearchableMeasures(pCube As %String, ByRef pMeasures) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pMeasures
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tCount = 0
		Set tMsr = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",""))
		While (tMsr '= "") {
			Set tMsrNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsr))
			Set tDimNo = $LG(tMsrNode,1)
			Set tMsrNo = $LG(tMsrNode,2)

			Set tMsrInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tMsrNo,0))
			Set tMsrName = $LG(tMsrInfo,3)
			Set tMsrType = $LG(tMsrInfo,8)
			Set tMsrSearch = +$LG(tMsrInfo,13)
			If (tMsrSearch) {
				Set tMsrCaption = $zobjclassmethod(tClassName,"%GetMemberCaption","MEASURES",tMsr)
				Set tCount = tCount + 1
				Set pMeasures(tCount) = $LB(tMsrName,tMsrCaption,tMsrType)
			}
			Set tMsr = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsr))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return the localized display name for a given element within the given cube.
ClassMethod %GetDimensionCaption(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, ByRef pCaption As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pCaption = ""

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		If ((pDimNo="")||(pHierNo="")||(pLevelNo="")) Quit

		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo))
		Set tDimName = $LG(tInfo,2)
		Set tHierName = $LG(tInfo,3)
		Set tLevelName = $LG(tInfo,4)

		Set pCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER(tDimName),$$$UPPER(tHierName),$$$UPPER(tLevelName))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return the localized display name for a given element within the given cube given a dimension,
/// hierarchy, and level name.
ClassMethod %GetMemberCaption(pCube As %String, pDimName As %String, pHierName As %String = "", pLevelName As %String = "", ByRef pCaption As %String) As %Status
{
	// This returns the level caption, not a member caption
	Set tSC = $$$OK
	Try {
		Set pCaption = ""

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set pCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER(pDimName),$$$UPPER(pHierName),$$$UPPER(pLevelName))

		If (pCaption="")&&(pHierName="")&&(pLevelName="") {
			// DTB454 - Test to see if this is a shared calculated member. 
			// This is not generated during the class compile!
			Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMembers(pCube,.tSharedCalcMbrs)
			If $$$ISERR(tSC) Quit
			
			Set tSharedCalcIdx = $O(tSharedCalcMbrs(""),1,tSharedCalcInfo)
			While (tSharedCalcIdx'="") {
				Set tDimName = $LG(tSharedCalcInfo,1)
				If $$$UPPER(tDimName)=$$$UPPER(pDimName) {
					Set pCaption = tDimName
					Set tSharedCalcIdx=""
				}
				Else {
					Set tSharedCalcIdx = $O(tSharedCalcMbrs(tSharedCalcIdx),1,tSharedCalcInfo)
				}
			}

		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return the localized description for a given element within the given cube given a dimension,
/// hierarchy, and level name.
ClassMethod %GetMemberDescription(pCube As %String, pDimName As %String, pHierName As %String = "", pLevelName As %String = "", ByRef pDescription As %String) As %Status
{
	// This method added by JSL4475
	Set tSC = $$$OK
	Try {
		Set pDescription = ""

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set pDescription = $zobjclassmethod(tClassName,"%GetMemberDescription",$$$UPPER(pDimName),$$$UPPER(pHierName),$$$UPPER(pLevelName))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Test if a given element within the given cube has child levels.
ClassMethod %MemberHasChildren(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, ByRef pHasChildren As %Boolean) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pHasChildren = 0

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tNextLevel = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo))
		If (tNextLevel'="") {
			Set pHasChildren = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Given a cube and a measure name, i.e. "Patient Count", return the fact table column name for that measured.
ClassMethod %GetMeasureFact(pCube As %String, pMeasureName As %String, Output pMeasureFact As %String) As %Status
{
	// Method added by WAL190
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCube,"[Measures].["_pMeasureName_"]",.tDNO,.tHNO,.tLNO)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(pCube,tDNO,tHNO,0,.pMeasureFact)
		If $$$ISERR(tSC) Quit
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

/// Return the fact name associated with a given element within the given cube.
ClassMethod %GetDimensionFact(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, ByRef pFactName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pFactName = ""
		If ((pDimNo="")||(pHierNo="")||(pLevelNo="")) {
			Quit
		}

		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo))
		Set tType = $LG(tInfo,1)
		If (tType="m") || (tType="l") {
			// find fact for measure
			Set tMsr = $LG(tInfo,5)
			Set:tMsr'="" pFactName = $G($$$DeepSeeMetaGLVN("cubes",tCube,$case(tType,"m":"msr#","l":"fact#"),tMsr))
			// check for alias
			Set:pFactName'="" tAlias = $G($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",pFactName,"alias"))
			Set:$G(tAlias)'="" pFactName=tAlias
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return the properties of a given level within the given cube as an array of form:<br/>
/// pProperties(n) = $LB(name,caption,type)
ClassMethod %GetDimensionProperties(pCube As %String, pDimName As %String, pHierName As %String, pLevelName As %String, ByRef pProperties) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pMeasures
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tClassName = ..%GetCubeClass(pCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set tLevelNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",$$$UPPER(pDimName),$$$UPPER(pHierName),$$$UPPER(pLevelName)))
		If (tLevelNode="") {
			Quit
		}

		Set tDimNo = $LG(tLevelNode,1)
		Set tHierNo = $LG(tLevelNode,2)
		Set tLevelNo = $LG(tLevelNode,3)

		Set tCount = 0
		Set tProp = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",""))
		While (tProp '= "") {
			Set tPropInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",tProp))
			Set tPropName = $LG(tPropInfo,4)
			Set tPropType = $LG(tPropInfo,5)
			Set tPropCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",$$$UPPER(pDimName),$$$UPPER(pHierName),$$$UPPER(pLevelName),$$$UPPER(tProp))

			Set tCount = tCount + 1
			Set pProperties(tCount) = $LB(tPropName,tPropCaption,tPropType)
			Set tProp = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",tProp))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return a list of all levels within the given cube.<br/>
/// On return <var>pLevels</var> contains a list of all levels of the form:<br/>
/// pLevels(n) = $LB(type,dimName,hierName,levelName)<br/>
/// Type is "l" for level, "m" for measure (in which case there is no levelName) or
/// "r" for relationship (in which case there is only a dimension name).<br/>
/// If <var>pSkipAll</var> is true, do not return any "all" levels.<br/>
/// If <var>pSkipComputed</var> is true, do not return any levels for computed dimensions.<br/>
ClassMethod %GetCubeLevels(pCube As %String, ByRef pLevels, pSkipAll As %Boolean = 0, pSkipComputed As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		// walk over dimension list
		Set tDim = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",""))
		While (tDim '= "") {
			Set tDimNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))
			Set tDimNo = $LG(tDimNode,1)
			If (tDimNo'="") {
				Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,0,0))
				Set tDimName = $LG(tDimInfo,2)
				Set tIsRelation = ''$D($$$DeepSeeMetaGLVN("cubes",tCube,"relations",$$$UPPER(tDimName)))

				If (tIsRelation) {
					Set tRelatedCube = $G($$$DeepSeeMetaGLVN("cubes",tCube,"relations",$$$UPPER(tDimName),"relatedCube"))
					Set pLevels($I(tIndex)) = $LB("r",tDimName)
				}
				ElseIf (tDim="MEASURES") {
					Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,""))
					While (tHier '= "") {
						Set tHierNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
						Set tHierNo = $LG(tHierNode,2)
						Set tHierInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,0))
						Set tHierName = $LG(tHierInfo,3)
						Set tHidden = +$LG(tHierInfo,11)
						If ('tHidden) {
							Set pLevels($I(tIndex)) = $LB("m",tDimName,tHierName)
						}
						Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
					}
				}
				ElseIf (tDim'="MEASURES") {
					Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,""))
					While (tHier '= "") {
						Set tHierNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
						Set tHierNo = $LG(tHierNode,2)
						If (tHierNo '= "a") {
							Set tHierInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,0))
							Set tHierLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,$LG(tHierNode,3)))
							Set tHierType = $LG(tHierLevelInfo,1) // actual level associated with hierarchy name
							Set tHierName = $LG(tHierInfo,3)
							Set tHidden = +$LG(tHierInfo,11)
							If (tHierType '= "all") {
								Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,""))
								While (tLevel '= "") {
									Set tLevelNode = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,tLevel))
									Set tLevelNo = $LG(tLevelNode,3)
									Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo))
									Set tLevelType = $LG(tLevelInfo,1)
									Set tLevelName = $LG(tLevelInfo,4)
									Set tLevelClass = $LG(tLevelInfo,6)
									If (('pSkipAll)||(tLevelType'="all")) {
										If (('pSkipComputed)||'$classmethod(tLevelClass,"%IsA","%DeepSee.ComputedDimension.Base")) {
											If ($$$UPPER(tLevelName)'="%SEARCH") {
												Set pLevels($I(tIndex)) = $LB("l",tDimName,tHierName,tLevelName)
											}
										}
									}
									Set tLevel = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier,tLevel))
								}
								If $$$ISERR(tSC) Quit
							}
						}
						Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
					}
					If $$$ISERR(tSC) Quit
				} // is relation
			} // dimno

			Set tDim = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return an array of all (non-default) listings for the given cube.
/// The array is of the form:<br/>
/// pListings(name) = $LB(caption,fields,order,type,source,edit)<br/>
/// If there are no listings, then <var>pListings</var> will be undefined.<br/>
/// If <var>pType</var> is defined, then only return listings of the given type.
ClassMethod %GetCubeListings(pCube As %String, Output pListings As %List, pType As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pListings
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tCubeClass = ..%GetCubeClass(tCube,.tSC)
		If $$$ISERR(tSC) Quit

		// walk over listings in cube metatdata
		Set tListing = $O($$$DeepSeeMetaGLVN("cubes",tCube,"listing",""))
		While (tListing '= "") {
			Set tFields = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing,"fieldList"))
			Set tOrder = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing,"orderBy"))
			Set tType = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing,"listingType"),"table")
			Set tResource = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing,"resource"))

			// JMD989: use (localized) display name for caption
			Set tCaption = $classmethod(tCubeClass,"%GetListingCaption",tListing) 
			Set:tCaption="" tCaption=tListing
			Set tDescription=""
			try {
				Set tDescription = $classmethod(tCubeClass,"%GetListingDescription",tListing)  // JSL4477
			} catch {}
			If ((pType="")||(pType=tType)) {
				If ((tResource="")||($System.Security.Check(tResource,"USE"))) {
					Set pListings(tListing) = $s(tDescription'="":$LB(tCaption,tFields,tOrder,tType,"cube",0, tDescription),1:$LB(tCaption,tFields,tOrder,tType,"cube",0))	// Add source and edit rights to the $LB JSL4477 - add tDescription in 7th place
				}
			}
			Set tListing = $O($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing))
		}

		// +DTB082 - Check for the existence of any listings defined via listing groups.
		// If the current cube or subject area is set to prevent use of listing groups, 
		// do not load from the alternative source.
		Set tListing = $O($$$DeepSeeListingGroupGLVN("cubes",tCube,"listing",""))
		Set tListingGroupsDisabled = $G($$$DeepSeeMetaGLVN("cubes",tCube,"disableListingGroups"),0)
		
		While (tListing '= "")&&'tListingGroupsDisabled {
			Set tFields = $G($$$DeepSeeListingGroupGLVN("cubes",tCube,"listing",tListing,"fieldList"))
			Set tOrder = $G($$$DeepSeeListingGroupGLVN("cubes",tCube,"listing",tListing,"orderBy"))
			Set tType = $G($$$DeepSeeListingGroupGLVN("cubes",tCube,"listing",tListing,"listingType"),"table")
			Set tResource = $G($$$DeepSeeListingGroupGLVN("cubes",tCube,"listing",tListing,"resource"))

			// JMD989: use (localized) display name for caption
			Set tListGroup = $G($$$DeepSeeListingGroupGLVN("cubes",tCube,"listing",tListing,"group"))
			Set:tListGroup'="" tGroupClass = $G($$$DeepSeeListingGroupGLVN("groups",tListGroup))
			Set:tGroupClass'="" tCaption = $classmethod(tGroupClass,"%GetListingCaption",tListing) 
			Set:tCaption="" tCaption=tListing
			Set tDescription=""
			try {
				Set tDescription = $classmethod(tGroupClass,"%GetListingDescription",tListing)  // JSL4477 // DTB139 - call method from group class
			} catch {}
			If ((pType="")||(pType=tType)) {
				If ((tResource="")||($System.Security.Check(tResource,"USE"))) {
					// DTB084 - communicate listing group edit rights
					Set tEditRights = $S(tResource'="":$System.Security.Check(tResource,"WRITE"),1:1)
					Set pListings(tListing) = $s(tDescription'="":$LB(tCaption,tFields,tOrder,tType,"listingGroup",tEditRights,tDescription),1:$LB(tCaption,tFields,tOrder,tType,"listingGroup",tEditRights)) // JSL4477 - add tDescription in 7th place
				}
			}
			Set tListing = $O($$$DeepSeeListingGroupGLVN("cubes",tCube,"listing",tListing))
		}
		// -DTB082
 
		// are there listing fields?
		Kill tList
		Set tSC = ##class(%DeepSee.Utils).%GetCubeListingFields(tCube,.tList)
		If $$$ISERR(tSC) Quit
		If $D(tList) {
			Set pListings("$$$CUSTOM") = $LB($$$Text("Custom Listing","%DeepSee"))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all defined listing fields for the given cube.
/// The array is of the form:<br/>
/// pListings(name) = $LB(caption,expression)<br/>
/// If there are no listing fields, then <var>pFields</var> will be undefined.<br/>
ClassMethod %GetCubeListingFields(pCube As %String, Output pFields As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pFields
		Set tCube = $$$UPPER(pCube)
		If (tCube="") Quit
		If ('$D($$$DeepSeeMetaGLVN("cubes",tCube))) Quit

		Set tCubeClass = ..%GetCubeClass(tCube,.tSC)
		If $$$ISERR(tSC) Quit

		// walk over fields
		Set tField = $O($$$DeepSeeMetaGLVN("cubes",tCube,"listingFields",""))

		While (tField '= "") {
			Set tExpr = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listingFields",tField,"fieldExpression"))
			Set tResource = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listingFields",tField,"resource"))

			// use (localized) display name for caption
			Set tCaption = $classmethod(tCubeClass,"%GetListingFieldCaption",tField) 
			Set tDescription=""
			try {
				Set tDescription = $classmethod(tCubeClass,"%GetListingFieldDescription",tField) // JSL4477
			} catch {}
			Set:tCaption="" tCaption=tField
			If ((tResource="")||($System.Security.Check(tResource,"USE"))) {
				Set pFields(tField) = $s(tDescription'="":$LB(tCaption,tExpr,tDescription),1:$LB(tCaption,tExpr)) // JSL4477 tDescription
			}
			Set tField = $O($$$DeepSeeMetaGLVN("cubes",tCube,"listingFields",tField))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return a list of members of the specified dimension
/// for the specified cube.<br/>
/// <var>pCubeName</var> is the name of the cube.<br/>
/// <var>pSpec</var> specifies the dimension in the form:
/// "Dim.Hier.Level".<br/>
/// <var>pContext</var> is used to indicate a particular calling context. This affects the behavior when trimming the list of members using related filters.<br/>
/// The list is returned via <var>pMembers</var>. This takes the form:<br/>
/// pMembers(n) = $LB(value,name,memberId,memberKey,[description])<br/>
/// Return the member class as a convenience.<br/>
/// If <var>pRelatedFilters</var> is provided, it is an array of other filter values to use to
/// restrict the set of members. It takes the form:<br/>
/// pRelatedFilters(spec) = key<br/>
/// If <var>pCalcMode</var> is 1, then only return calculated members.
/// If <var>pCalcMode</var> is -1, then only return non-calculated members.
ClassMethod %GetDimensionMembers(pCubeName As %String, pSpec As %String, pContext As %String = "", Output pMembers, pMaxMembers As %Integer = 100, Output pMemberClass As %String, ByRef pRelatedFilters, pCalcMode As %Integer = 0, pSearchKey As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD910
		Kill pMembers

		Set n = 0
		// +PFS022 - Use active version unless version is specified
		Set tActiveVersionNo = ##class(%DeepSee.CubeVersion.Utils).%GetActiveCubeVersion(pCubeName)
		If (tActiveVersionNo'="") {
			Set pCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(pCubeName,tActiveVersionNo)
		}
		// -PFS022
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tMaxMembers = pMaxMembers // Maximum number of members to return
		Set tIsSubjectArea = '##class(%DeepSee.Utils).%IsBaseCube(pCubeName) //APV016

		Set tCubeClass = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		If (pSpec="") {
			// nothing to do
			Quit
		}

		// Get info on the specified dimension
		Kill tRelationName
		Kill tRelationSpec
		// JMD1397: Use tCubeIndex
		Set tSC = ..%GetDimensionInfo(tCubeIndex,pSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec)
		If $$$ISERR(tSC) Quit

		If (tRelationName'="") {
			// +DTB164 - Pre-process the related filters to assist in passing context information to a related cube
			Set s = $O(pRelatedFilters("")) 
			While s'="" {
				If pRelatedFilters(s) = "" {
					// This is more than a spec/key pair. Attempt to break it into an array of individual specs (heterogeneous %OR)
					Set TestSC = ..%FilterSpecToArray(tCubeIndex,s,.pRelatedFilters)
				}
				Set s = $O(pRelatedFilters(s))
			}

			// Look at the current subject area's filterspec to see if it contains this relationship. 
			// If it does, attempt to extract those elements for context.
			Set tRelatedFilterSpec = $classmethod(tCubeClass,"%GetFilterSpec")
			If $$$UPPER(tRelatedFilterSpec)[$$$UPPER(tRelationName) {
				Set TestSC = ..%FilterSpecToArray(tCubeIndex,tRelatedFilterSpec,.pRelatedFilters)
			}	
			// -DTB164

			Set tRelatedCube = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"relations",$$$UPPER(tRelationName),"relatedCube"))

			// JMD1305: pass along relevant pRelatedFilters 
			Kill tRelFiltersX
			Set s = $O(pRelatedFilters(""))
			While (s'="") {
				// DTB038: Only pass related filter specs that belong to this related cube
				If $E(s,1,3)="%OR" {
					// DTB164 - Examine the contents of a heterogeneous %OR and attempt to construct a new complex spec for the cube in question
					Set tRelSpec = $O(pRelatedFilters(s,""),1,tRelKey)
					Set tORSet = ""
					Set tRelSpecCount = 0
					While tRelSpec'="" {
						Kill tSpecRelationName
						Set tSC = ..%GetDimensionInfo(pCubeName,tRelSpec,,,,.tSpecRelationName)
						If (tRelationName=tSpecRelationName)&&$$$ISOK(tSC) {
							Set tRelSpecCount = tRelSpecCount+1
							Kill tSpecInfoX
							Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tRelSpec,.tSpecInfoX,.tQuoted,.tMemKey)
							If $$$ISERR(tSC) Continue		// DTB164 - Try other filters even if one fails
							Set tSpecX = ""
							Set s2 = $O(tSpecInfoX(1))
							While (s2'="") {
								Set tSpecX = tSpecX _ $S(tSpecX="":"",1:".") _ $S(+$G(tMemKey(s2)):"&",1:"") _ "["_ tSpecInfoX(s2) _ "]"
								Set s2 = $O(tSpecInfoX(s2))
							}
							
							// Process the current spec and add it to a set (assume heterogeneous)
							// key could be a set of values {a,b}
							If ($E(tRelKey,1)="{") {
								Set tORSpec = ""
								Set tRelKey=$E(tRelKey,2,$L(tRelKey)-1)
								For sx = 1:1:$L(tRelKey,",&") {
									Set tORSpec = tORSpec _ $S(tORSpec'="":",",1:"") _ tORSpec _"."_$S(sx=1:"",1:"&")_$P(tRelKey,",&",sx)
								}
							}
							ElseIf ($E(tRelKey,1,4)="%NOT") {
								// (JMD1104) deal with %NOT
								Set tORSpec = tSpecX _"."_tRelKey
							}
							ElseIf (($E(tRelKey,1,2)'="&[")||(tRelSpec["&[")) {
								// (JMD951)  if there is already a key; don't tack one on!
								// (JMD1095) if key does not have &[] (or is missing) then it is not a key
								Set tORSpec = tSpecX
							}
							Else {
								Set tORSpec = tSpecX _"."_tRelKey
							}
							
							Set tORSet = tORSet _ $S($L(tORSet):",",1:"") _ tORSpec
						}
						
						Set tRelSpec = $O(pRelatedFilters(s,tRelSpec),1,tRelKey)
					}
					
					If (tORSet'="") {
						Set:(tRelSpecCount>1) tORSet = "%OR({" _ tORSet _ "})"
						Set tRelFiltersX(tORSet) = ""
					}
				}
				Else {
					Kill tSpecRelationName
					Set tSC = ..%GetDimensionInfo(pCubeName,s,.tRelDimNo,.tRelHierNo,.tRelLevelNo,.tSpecRelationName)
					If (tRelationName=tSpecRelationName)&&$$$ISOK(tSC) {
						Kill tSpecInfoX
						Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(s,.tSpecInfoX,.tQuoted,.tMemKey)
						If $$$ISERR(tSC) Continue		// DTB164 - Try other filters even if one fails
						Set tSpecX = ""
						Set s2 = $O(tSpecInfoX(1))
						While (s2'="") {
							Set tSpecX = tSpecX _ $S(tSpecX="":"",1:".") _ $S(+$G(tMemKey(s2)):"&",1:"") _ "["_ tSpecInfoX(s2) _ "]"
							Set s2 = $O(tSpecInfoX(s2))
						}
						Set:tSpecX'="" tRelFiltersX(tSpecX) = pRelatedFilters(s)
					}
				}
				Set s = $O(pRelatedFilters(s))
			}
			// JMD1410: swallow the error
			// most likely there is a reference to a local calculated member that
			// we do not have access to at this point
			Set tSC = $$$OK
			If $$$ISERR(tSC) Quit
			Set tSC = ..%GetDimensionMembers(tRelatedCube, tRelationSpec, pContext, .pMembers, pMaxMembers,,.tRelFiltersX,pCalcMode,pSearchKey)  // DTB080
			If $$$ISERR(tSC) Quit
			// add relation name back onto value?
			Quit
		}

		// check for calculated members
		// DTB743 - Consult the user settings for filters before folding in members
		Set tSuppressCalc = (pContext="filter") && ( +$G(tLevelNo) && '+$G(^DeepSee.UserPortalSettings("Controls","showCalculated")) )
		If (pCalcMode'=-1) && ('tSuppressCalc) {
			Set tDimName = ""
			If (tDimNo = -1) {
				// dimension only containing calc members
				Set tDimName = $$$UPPER(##class(%DeepSee.Query.Parser).%UnquoteIdent(pSpec))
			}
			Else {
				// get dim name
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
				Set tDimName = $$$UPPER($LG(tInfo,2))
			}

			// If there are calculated members for this dimension, fold them into the member list
			If (tDimName'="") {
				Set tMbr = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"calcMbrs",tDimName,""))
				While (tMbr'="") {
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"calcMbrs",tDimName,tMbr))
					Set tName = $LG(tInfo,2)
					// + WAL146 -- Check to see if this calculated member has a display name
					Set tCaption = $zobjclassmethod(tCubeClass,"%GetMemberCaption",$$$UPPER(tDimName),$$$UPPER(tName))
					Set:($G(tCaption)="") tCaption = tName
					Set pMembers($I(n)) = $LB("["_tName_"]",tCaption,tName,tName)
					// - WAL146
					Set tMbr = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"calcMbrs",tDimName,tMbr))
				}
				
				// +DTB454 - Add shared calc members to the member list
				Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMembers(tCubeIndex,.tSharedCalcMembers)
				If $$$ISERR(tSC) Quit
				
				Set tSharedCalcIdx = $O(tSharedCalcMembers(""),1,tSharedCalcInfo)
				While tSharedCalcIdx'="" {
					If ($$$UPPER($LG(tSharedCalcInfo,1))=tDimName) {
						Set tName = $LG(tSharedCalcInfo,2)
						Set tCaption = $zobjclassmethod(tCubeClass,"%GetMemberCaption",$$$UPPER(tDimName),$$$UPPER(tName))
						Set:($G(tCaption)="") tCaption = tName
						Set pMembers($I(n)) = $LB("["_tName_"]",tCaption,tName,tName)
					}
					
					Set tSharedCalcIdx = $O(tSharedCalcMembers(tSharedCalcIdx),1,tSharedCalcInfo)
				}
				// -DTB454
			}
		}

		// no more to do
		If (pCalcMode=1) Quit

		If (tDimNo = -1) {
			// this is a dimension of only calculated members-- nothing more to do
			Quit
		}

		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
		Set pMemberClass = $LG(tInfo,6)
		Set tRollupKey = ""
		Set tHierInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,0))
		Set tMbrClass = $LG(tHierInfo,6)
		Set:tMbrClass="" tMbrClass = "%DeepSee.Query.memberData"

		// JMD1329: check for MDX computed dims
		// get dim name
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
		Set tDimName = $$$UPPER($LG(tInfo,2))
		Set tDimClass = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"computedDims",tDimName))
		Set tBehavior="" ; JSL4431
		Set:tDimClass'="" tBehavior=$classmethod(tDimClass,"%GetBehavior") ; JSL4431 - only call classmethod once because results stored in variable
		If ((tBehavior="MDX")||(tBehavior="SQL")) { // JSL4431 - add SQL as behavior
			// for MDX computed, get list directly from the dimension class
			// not from query so that we get the unprocessed member names

			Set tDimObj = $classmethod(tDimClass,"%Create",pCubeName,"",tDimNo,tHierNo,tLevelNo)
			If '$IsObject(tDimObj) {
				Set tSC = $$$ERROR($$$GeneralError,"Unable to create computed dimension object: " _ tDimClass)
				Quit
			}
			// JMD1366 also look at both pre-defined and run-time lists
			Kill tMemberList
			Set tSC = tDimObj.%GetAllMembers(.tMemberList,pCubeName,tDimNo,tHierNo,tLevelNo)
			If $$$ISERR(tSC) Quit

			// copy results
			Set n = 0
			Set k = $O(tMemberList(""),1,data)
			While (k'="") {
				Set n = n + 1
				Set tMbrId = $LG(data,1)
				Set tValue = $LG(data,2)
				Set tMbrKey = $LG(data,3)
				Set tDesc = $LG(data,4)			// DTB219
				Set pMembers(n) = $LB("["_tValue_"]",tValue,tMbrId,tMbrKey,tDesc)
				Set k = $O(tMemberList(k),1,data)
			}
			Quit
		}
		Else {
			// we need to provide a fake axis global so that GetMembers has a place to put the results
			Set tParent = 1
			New %axis
			Set tAxisKey = $I($$$DeepSeeAxisGLVN(tCubeIndex,"tempAxisKey"),-1)		// DTB483 - Obtain a key unique to this current call
			Set %axis = tAxisKey
			Set tNodeNo = 1
			Lock +$$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey):5 Else  Set tSC=$$$ERROR($$$GeneralError,"Unable to get lock in %GetDimensionMembers")
			If $$$ISERR(tSC) Quit
			Kill $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey)

			#; see if there are filters associated with the cube
			#; if so, add to the filter list
			Set tFilters = 0
			Set tFilterSpec = $classmethod(tCubeClass,"%GetFilterSpec")
			If (tFilterSpec'="") {
				Set tFilters($I(tFilters)) = tFilterSpec
			}

			#; JMD947: convert related filters to %FILTER clauses
			#; Build spec from related filters, if any
			If ($D(pRelatedFilters)) {
				Set s = $O(pRelatedFilters(""))
				While (s'="") {
					// from a widget, *s* may be the complete spec
					If (pRelatedFilters(s)="") {
						Set tFilters($I(tFilters)) = s 
					}
					Else {
						Set tKey = pRelatedFilters(s)
						// key could be a set of values {a,b}
						If ($E(tKey,1)="{") {
							Set tSpec = ""
							Set tKey=$E(tKey,2,$L(tKey)-1)
							For sx = 1:1:$L(tKey,",&") {
								Set tSpec = tSpec _ $S(tSpec'="":",",1:"") _ s _"."_$S(sx=1:"",1:"&")_$P(tKey,",&",sx)
							}
							// JMD1423: wrap set with %OR
							// (assumed heterogeneous set!)
							// Set tSpec = "{"_tSpec_"}"
							Set tSpec = "%OR({"_tSpec_"})"
						}
						ElseIf ($E(tKey,1,4)="%NOT") {
							// JMD1104 deal with %NOT
							Set tSpec = s _"."_tKey
						}
						ElseIf (($E(tKey,1,2)'="&[")||(s["&[")) {
							// JMD951  if there is already a key; don't tack one on!
							// JMD1095 if key does not have &[] (or is missing) then it is not a key
							Set tSpec = s
						}
						Else {
							Set tSpec = s _"."_tKey
						}
						Set tFilters($I(tFilters)) = tSpec
					}
					Set s = $O(pRelatedFilters(s))
				}
			}

			If ($D(tFilters)) {
				// JMD947: make sure slicer axis is processed
				Set tMDX = "SELECT FROM ["_pCubeName_"]"
				Set k = $O(tFilters(""))
				While (k'="") {
					// special case for %NOT!
					// %NOT of multiple items comes in as spec.%NOT {set}
					If (tFilters(k)[".%NOT ") {
						Set tSpec1 = $P(tFilters(k),".%NOT ",1)
						Set tKeys1 = $P(tFilters(k),".%NOT ",2)
						If ($E(tKeys1)="{") {
							Set tSpec2 = ""
							// set of values
							Set tKeys1 = $E(tKeys1,2,$L(tKeys1)-1)
							// process each one
							Set kc = 0
							For p = 1:1:$L(tKeys1,"],") {
								Set tKeyX = $P(tKeys1,"],",p)
								Set:$E(tKeyX,$L(tKeyX))'="]" tKeyX = tKeyX _ "]"
								If (tKeyX'="") {
									Set tSpec2 = tSpec2_$S(kc:",",1:"")_tSpec1_"."_tKeyX_".%NOT"
									Set kc = kc+1
								}
							}
							If (tSpec2'="") {
								If (kc>1) {
									Set tMDX = tMDX _ " %FILTER (" _ tSpec2_")"
								}
								Else {
									Set tMDX = tMDX _ " %FILTER " _ tSpec2
								}
							}
						}
						Else {
							//APV014 - check for empty tKeys1
							If (tKeys1=""){
									Set tMDX = tMDX _ " %FILTER " _ tSpec1_".%NOT"
							}
							Else{				
								Set tMDX = tMDX _ " %FILTER " _ tSpec1_"."_tKeys1_".%NOT"
							}
						}
					}
					// JMD1067: skip .Members in filter
					ElseIf ($$$UPPER(tFilters(k))'[".MEMBERS") {
						Set tFilter = $ZSTRIP(tFilters(k),"<W")
						
						// DTB644 - Some filters can come in with a %FILTER in front!
						If $E(tFilter,1,7)="%FILTER" {
							Set tFilter = $E(tFilter,8,*)
						}
						
						Set tMDX = tMDX _ " %FILTER " _ tFilter
					}
					Set k = $O(tFilters(k))
				}
				
				If (tMDX'="") {
					Set tRS = ##class(%DeepSee.ResultSet).%New()
					Set tSC = tRS.%PrepareMDX(tMDX)
					If $$$ISERR(tSC) Quit
					Set tSC = tRS.%Execute()
					If $$$ISERR(tSC) Quit

					// pass query along
					New %query
					Set %query = tRS.%GetQuery()
					
					//APV016 - Set %slicerKey to be used in %GetMembers and in %Intersect (if that path of execution is taken)
					New %slicerKey
					Set %slicerKey = $S($IsObject(%query.slicer): %query.slicer.%AxisKey, 1:$G($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"axis",0))) 
				}
			}

			// JMD947: pass flag to force member restriction by slicer
			New %dsRestrictBySlicer
			Set %dsRestrictBySlicer = 1

			// JMD1193: force a TOP clause in the members query
			New %dsMaxMembers
			Set %dsMaxMembers = pMaxMembers

			// JMD1283: add an additional WHERE to the members query
			// this is used by the filter search box
			If (pSearchKey'="") {
				New %dsMemberSearch
				Set %dsMemberSearch = pSearchKey
			}

			If pContext="filter" {
				// DTB599
				New %reduce		// DTB758
				Set %reduce = 1
			}

			Set tSC = $zobjclassmethod(tMbrClass,"%GetMembers",tCubeIndex,tDimNo,tHierNo,tLevelNo,"",tParent,tAxisKey,.tNodeNo)
			If $$$ISERR(tSC) Quit

			// special case for NOW
			If ($zobjclassmethod(tMbrClass,"%HasFeature",tCubeIndex,tDimNo,tHierNo,tLevelNo,"NOW")) {
				Set n = n + 1
				Set pMembers(n) = $LB("[NOW]",$$$Text("NOW","%DeepSee"),"NOW","NOW")
			}
		}

		//APV016
		Set tIsListDimension = (+$LG($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"mbr#",tDimNo,tHierNo,tLevelNo)),16)=1)
		If (tIsSubjectArea && tIsListDimension) {
			Do ##class(%DeepSee.Query.member).%GetNodeInfo(pCubeName, tDimNo, tHierNo, tLevelNo, .pFact)  //fetch pFact to use in %Intersect
			If ($D(%slicerKey)=0) { 					
				New %slicerKey
				Set %slicerKey = $S($IsObject(%query.slicer): %query.slicer.%AxisKey, 1:$G($$$DeepSeeResultsGLVN(tCubeIndex,%query.%QueryKey,"axis",0))) //Set %slicerKey to allow intersect to operate on subject areas
			}
			
			// copy results into output array
			Set tKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tParent,"ch",""))
			While ((tKey '= "")&&(n<tMaxMembers)) {
				Set tNode = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tKey)
				Set tValue = $LG(tNode,5)
				Set tMbrId = $LG(tNode,6)
				Set tMbrKey = $LG(tNode,13)
				Set tDesc = $LG(tNode,23)
				
				If (##class(%DeepSee.Query.Engine).%IntersectExists(pCubeName,pFact,tMbrId)>0) {		// DP-415899
					Set n = n + 1
					Set pMembers(n) = $LB("["_tValue_"]",tValue,tMbrId,tMbrKey,tDesc)
				}
			
				Set tKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tParent,"ch",tKey))
			}
		}
		Else { // If ((not a subject area) or  (is a subject area and not a list dimension))
			// copy results into output array
			Set tKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tParent,"ch",""))
			While ((tKey '= "")&&(n<tMaxMembers)) {
				Set n = n + 1
				Set tNode = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tKey)
				Set tValue = $LG(tNode,5)
				Set tMbrId = $LG(tNode,6)
				Set tMbrKey = $LG(tNode,13)
				Set tDesc = $LG(tNode,23)
				Set pMembers(n) = $LB("["_tValue_"]",tValue,tMbrId,tMbrKey,tDesc)	
				Set tKey = $O($$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes",tParent,"ch",tKey))
			}
		}

		Kill $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey)
		Lock -$$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey)
		
		// DTB483 - Keep the counter limited
		Set tUserLimit = $system.License.GetUserLimit()
		Set $$$DeepSeeAxisGLVN(tCubeIndex,"tempAxisKey") = -((-tAxisKey)#$S(tUserLimit<1000:1000,1:tUserLimit))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Lock -$$$DeepSeeAxisGLVN($G(tCubeIndex),$G(tAxisKey))		// DP-413393 - Clear out axis lock if an exception skipped the call to release
	}
	Quit tSC
}

/// Convert a string <var>pSpec</var> into array form and add it to the array <var>pFilterArray</var>. The
/// value for <var>pSpec</var> may be any valid MDX WHERE clause referencing non-calculated members.
/// If a member being inserted into the array already exists, the selection data will be replaced by the 
/// intersection of the preexisting member or set and the new member or set provided by the argument.
ClassMethod %FilterSpecToArray(pCube As %String, pSpec As %String, ByRef pFilterArray) As %Status
{
	// Method added by DTB164
	Set tSC = $$$OK
	Try {
		// Normalize the cube name
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pCube,.tInfo)
		If $$$ISERR(tSC) Quit
		Set tCube = "[" _ $$$dsEscapeIdent(tInfo(1)) _ "]"
		
		// Create a query that can be parsed into an object
		Set tMDX = "SELECT " _ pSpec _ " ON 0 FROM " _ tCube
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMDX(tMDX,.tQuery)
		If $$$ISERR(tSC) Quit
		
		Set tSpecOBJ = tQuery.axes.GetAt(1).children.GetAt(1)
		
		// Recursively examine the object representation of the original pSpec looking for sets, ranges, or members
		Set tSC = ..%SlicerNodeToSpecArray(tSpecOBJ,.pFilterArray)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Perfroms the actual work of recursively walking a slicer tree and representing it as an array if possible.
/// Contents of the <var>pFilterArray</var> can be returned in two different forms:<br>
/// Single argument: pFilterArray(levelSpec) = key<br>
/// heterogeneous %OR: pFilterArray(ORText,levelSpec) = key
ClassMethod %SlicerNodeToSpecArray(node As %DeepSee.Query.node, ByRef pFilterArray) As %Status [ Internal ]
{
	// Method added by DTB164
	Set tSC = $$$OK
	Try {
		If node.%IsA("%DeepSee.Query.memberSpec") {
			// Look through the resolved spec array to see if this is a range or a single member
			Set tSC = node.%ResolveValue()
			If $$$ISERR(tSC) Quit
			
			Set tIsRange=0
			Set tMemberKeyNos(1) = $O(node.%memberKeys(""))
			If $O(node.%memberKeys(tMemberKeyNos(1)))'="" {
				Set tMemberKeyNos(2) = $O(node.%memberKeys(tMemberKeyNos(1)))
				Set tIsRange=1
			}
			
			Set tIdentIdx = $O(node.%resolvedSpec(""))
			Set tLevelSpec = ""
			While (tIdentIdx'="") {
				If (tIdentIdx=tMemberKeyNos(1))||(node.%resolvedSpec(tIdentIdx)=":") {
					Quit
				}

				Set tLevelSpec = tLevelSpec _ $S($L(tLevelSpec):".",1:"") _ "[" _ $$$dsEscapeIdent(node.%resolvedSpec(tIdentIdx)) _ "]"
				Set tIdentIdx = $O(node.%resolvedSpec(tIdentIdx))
			}
			
			Set tKey = $S((tMemberKeyNos(1)'=""):"&[" _ $$$dsEscapeIdent(node.%resolvedSpec(tMemberKeyNos(1))) _ "]",1:"")
			If tIsRange {
				Set:(tMemberKeyNos(2)'="") tKey = tKey _ ":" _ "&[" _ $$$dsEscapeIdent(node.%resolvedSpec(tMemberKeyNos(2))) _ "]"
			}

			Set pFilterArray(tLevelSpec) = tKey
		} 
		ElseIf node.%IsA("%DeepSee.Query.range") {
			// DTB164 - Not Implemented - Does not seem to be used!
		}
 		ElseIf node.%IsA("%DeepSee.Query.set") {
	 		Set tUniqueSpecCount = 0
	 		Set tParentFunction = $S(node.parent.%IsA("%DeepSee.Query.setFunction"):node.parent.function,1:"")
	 		
	 		For ii=1:1:node.children.Count() {
		 		Kill tSetItemArray
		 		Set tSetItemNode = node.children.GetAt(ii)
		 		
		 		Set tSC = ..%SlicerNodeToSpecArray(tSetItemNode,.tSetItemArray)
		 		
 				Set tItemSpec = $O(tSetItemArray(""),1,tKey) 
 				While tItemSpec'="" {
	 				Set tItemSpecU = $$$UPPER(tItemSpec)
					Set:'$D(tSetSpecs(tItemSpecU)) tUniqueSpecCount = tUniqueSpecCount+1

					If tKey'="" {
						Set tSetSpecs(tItemSpecU,$I(tSetSpecs(tItemSpecU))) = tKey
					}
					Else {
						Set tSetSpecs(tItemSpecU) = ""
					}
	 				Set tItemSpec = $O(tSetItemArray(tItemSpec),1,tKey)
 				}
	 		}
	 		
	 		If ($O(tSetSpecs(""))'=$O(tSetSpecs(""),-1)) {
		 		// Set contents containing multiple level specs cannot be represented individually in the array format. 
		 		//   A.&[Key1]||B.&[Key2] 
		 		// gets logically converted to
		 		//   A.&[Key1]&&B.&[Key2]
		 		// To prevent this, add the entire set as the spec. The result is similar to what the Adanced Filter editor provides as 
		 		// context.
		 		If (tParentFunction="%OR") {
			 		// This is a heterogeneous %OR
			 		Set tORString = node.parent.%ToString()
		 		}
		 		Else {
			 		// Wrap the set in an %OR
			 		Set tORString = "%OR(" _ node.%ToString() _ ")"
		 		}
		 		Set pFilterArray(tORString) = ""
		 		
		 		// Process and record all members under each spec. This allows for examination of the specs for relationship identifiers
		 		// prior to reconstructing a new %OR statmement to be executed on another cube
				Set tSpec = $O(tSetSpecs(""))
				While tSpec'="" {
					Set tKeySet = ""
					Set tKeyCount = $G(tSetSpecs(tSpec),0)
					For k=1:1:tKeyCount {
						Set tKeySet = tKeySet _ $S($L(tKeySet):",",1:"") _ tSetSpecs(tSpec,k)
					}
					
					Set:((tKeySet'="")&&(tKeyCount>1)) tKeySet = "{" _ tKeySet _ "}"
					
					Set pFilterArray(tORString,tSpec) = tKeySet
					Set tSpec = $O(tSetSpecs(tSpec))
		 		}
	 		}
			Else {
				// Process all members of the single spec
				Set tSpec = $O(tSetSpecs(""))
				Set tKeySet = ""
				Set tKeyCount = $G(tSetSpecs(tSpec),0)
				For k=1:1:tKeyCount {
					Set tKeySet = tKeySet _ $S($L(tKeySet):",",1:"") _ tSetSpecs(tSpec,k)
				}
				
				Set:((tKeySet'="")&&(tKeyCount>1)) tKeySet = "{" _ tKeySet _ "}"
				
				Set pFilterArray(tSpec) = tKeySet
			}
 		}
		Else {
			// Recurse to look for members and sets
			For ii=1:1:node.children.Count() {
				Set tChild = node.children.GetAt(ii)
				Set tSC = ..%SlicerNodeToSpecArray(tChild,.pFilterArray)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Give a cube, a level within the cube, and the key value of a member of the level,
/// return the name of the level member.<br/>
/// <var>pCubeName</var> is the name of the cube.<br/>
/// <var>pSpec</var> specifies the dimension in the form:
/// "Dim.Hier.Level".<br/>
/// <var>pKey</var> is a key value. This may include the &[] around the key value.<br/>
/// <var>pValue</var> is the returned display value.<br/>
ClassMethod %GetLevelNameForKey(pCubeName As %String, pSpec As %String, pKey As %String, Output pValue As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCubeName)
		Set pValue = ""
		If (pCubeName="")||(pKey="") Quit

		Set pKey = $ZSTRIP(pKey,"<>W")

		// See if key needs parsing
		Set tIsNot = 0
		If ($E(pKey,1,5)="%NOT ") {
			Set pKey = $E(pKey,6,$L(pKey))
			Set tIsNot = 1
		}

		// n.b, if the key is *supposed* to start and end with {} then we are in trouble!
		If (($E(pKey,1)="{")&&($E(pKey,$L(pKey))="}")) {
			// set of values
			Set pKey = $E(pKey,2,$L(pKey)-1)
			// process each one
			Set pValue = ""
			For p = 1:1:$L(pKey,"],") {
				Set tKey = $P(pKey,"],",p)
				Set:$E(tKey,$L(tKey))'="]" tKey = tKey _ "]"
				Set tSC = ..%GetLevelNameForKey(pCubeName,pSpec,tKey,.tValue)
				If ($$$ISOK(tSC)&&(tValue'="")) {
					Set pValue = pValue _ $S(pValue="":"",1:"+") _ tValue
				}
			}
			If (tIsNot && (pValue'="")) {
				Set pValue = "NOT " _ pValue
			}
			Quit
		}

		// JMD1275 test for range
		If (pKey["]:&[") {
			Set tKey1 = $P(pKey,"]:&[",1)_"]"
			Set tKey2 = "&["_$P(pKey,"]:&[",2)
			Set tSC = ..%GetLevelNameForKey(pCubeName,pSpec,tKey1,.tValue1)
			If $$$ISERR(tSC) Quit
			Set tSC = ..%GetLevelNameForKey(pCubeName,pSpec,tKey2,.tValue2)
			If $$$ISERR(tSC) Quit
			Set pValue = tValue1 _ ":" _ tValue2
			Quit
		}

		If ($E(pKey,1,2)="&[") {
			// DTB112 - removing &[ and ] using $E() is not robust--parse the key to properly expose the identifier
			Do ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pKey,.tInfo)
			Set pKey = tInfo(1)
		}

		Set tSC = ..%GetDimensionInfo(pCubeName,pSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo)
		If $$$ISERR(tSC) Quit

		If (tRelationName'="") {
			Set tRelatedCube = $G($$$DeepSeeMetaGLVN("cubes",tCube,"relations",$$$UPPER(tRelationName),"relatedCube"))
			Set tSC = ..%GetLevelNameForKey(tRelatedCube, tRelationSpec, pKey, .pValue)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tDimNo=-1) {
			// calculated member: name = key
			Set pValue = pKey
		}
		ElseIf (tDimNo=-2) {
			// named set: name = key
			Set pValue = pKey
		}
		Else {
			// check for calc member within this dimension
			// get dim name
			Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo))
			Set tDimName = $$$UPPER($LG(tInfo,2))
			If ((tDimName'="")&&(pKey'="")) {
				If $D($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",tDimName,$$$UPPER(pKey))) {
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",tDimName,$$$UPPER(pKey)))
					Set pValue = $LG(tInfo,2)
					Quit
				}
			}

			Set tHierInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,0))
			Set tMbrClass = $LG(tHierInfo,6)
			Set:tMbrClass="" tMbrClass = "%DeepSee.Query.memberData"
			Set tMbrProvider = $zobjclassmethod(tMbrClass,"%New")
			Set tMbrProvider.%cube = tCube
			Set tMbrProvider.%levelNumber = tLevelNo
			Set tSC = $zobjmethod(tMbrProvider,"%FindMemberByKey",pKey,tDimNo,tHierNo,.tExists,.pValue,0)
			If $$$ISERR(tSC) Quit
		}

		If (tIsNot && (pValue'="")) {
			Set pValue = "NOT " _ pValue
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse a filter key value and convert all keys to display values in the context of <var>pKPIClass</var>.
ClassMethod %ParseKeyForDisplay(pKey As %String, Output pValue As %String, pKPIClass As %String = "", pFilterName As %String = "") As %Status
{
	// Method added by WAL209
	Set tSC = $$$OK
	Try {
		Set pValue = ""

		Set pKey = $ZSTRIP(pKey,"<>W")

		// See if key needs parsing
		Set tIsNot = 0
		If ($E(pKey,1,5)="%NOT ") {
			Set pKey = $ZSTRIP($E(pKey,5,$L(pKey)),"<>W")		// DTB609 - Support an optional space after the %NOT
			Set tIsNot = 1
		}

		// n.b, if the key is *supposed* to start and end with {} then we are in trouble!
		If (($E(pKey,1)="{")&&($E(pKey,$L(pKey))="}")) {
			// This is a set of values. First identify the comma-delimited set
			Set pKey = $E(pKey,2,$L(pKey)-1)
			// process each one
			Set pValue = ""
			
			// DTB609 - Choose most appropriate set delimiter.
			If (pKey["],&[") {
				Set tUrlDelimiter = "],&["
			}
			ElseIf (pKey["],[") {
				Set tUrlDelimiter = "],["
			}
			Else {
				Set tUrlDelimiter = ","
			}

			For p = 1:1:$L(pKey,tUrlDelimiter) {
				Set tKey = $P(pKey,tUrlDelimiter,p)
				If (tUrlDelimiter="],&[") {
					// DTB609 - Leave this with a key
					Set:($E(tKey,1,2)'="&[") tKey = "&[" _ tKey
					Set:($E(tKey,$L(tKey))'="]") tKey = tKey _ "]"
				}
				ElseIf (tUrlDelimiter = "],[") {
					// DTB609 - Leave the key as an exposed member name
					Set:($E(tKey)="[") tKey = $E(tKey,2,*)
					Set:($E(tKey,$L(tKey))="]") tKey = $E(tKey,1,*-1)
				}

				Set tSC = ..%ParseKeyForDisplay(tKey,.tValue,pKPIClass,pFilterName)		// DTB609
				If ($$$ISOK(tSC)&&(tValue'="")) {
					Set pValue = pValue _ $S(pValue="":"",1:" + ") _ tValue
				}
			}
			If (tIsNot && (pValue'="")) {
				Set pValue = "NOT " _ pValue
			}
			Quit
		}

		// JMD1275 test for range
		If (pKey["]:&[") {
			Set tKey1 = $P(pKey,"]:&[",1)_"]"
			Set tKey2 = "&["_$P(pKey,"]:&[",2)
			Set tSC = ..%ParseKeyForDisplay(tKey1,.tValue1,pKPIClass,pFilterName)		// DTB609
			If $$$ISERR(tSC) Quit
			Set tSC = ..%ParseKeyForDisplay(tKey2,.tValue2,pKPIClass,pFilterName)		// DTB609
			If $$$ISERR(tSC) Quit
			Set pValue = tValue1 _ ":" _ tValue2
			Quit
		}

		If ($E(pKey,1,2)="&[") {
			// DTB112 - removing &[ and ] using $E() is not robust--parse the key to properly expose the identifier
			Do ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pKey,.tInfo)
			Set pKey = tInfo(1)
			Set pValue = pKey
			
			Set pValue = $classmethod(pKPIClass,"%GetFilterDisplayValue",pFilterName,pKey)		// DTB609
		}
		Else {
			If (($E(pKey,1)'="[")&&($E(pKey,$L(pKey))="]")) Set pKey = $E(pKey,1,$L(pKey)-1)
			Set pKey=$classmethod(pKPIClass,"%GetFilterDisplayValue",pFilterName,pKey)		// DTB609
			Set pKey = $REPLACE(pKey,","," + ")
			Set pValue = pKey	
		}

		If (tIsNot && (pValue'="")) {
			Set pValue = "NOT " _ pValue
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a cube and the dimension, heirarchy, and level numbers, translate the member ID 
/// into the member key.
/// <var>pCubeName</var> is the name of the cube.<br/>
/// <var>pID</var> is an ID in the dimension's star table.<br/>
/// <var>pKey</var> is the returned key corresponding to that ID.<br/>
ClassMethod %GetMemberKeyForID(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pID As %String, Output pKey As %String) As %Status [ Internal ]
{
	// Method added by DTB247
	Set tSC = $$$OK
	Set pKey = ""
	Try {
		If (pID="NO MEMBER") {
			// DP-415764 - Don't bother looking anything up if the null member token is passed in.
			// This is considered successful and returns pKey="".
			Quit
		}

		Set tCubeKey = $$$UPPER(pCubeName)
		Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeKey,"mbr#",pDimNo,pHierNo,pLevelNo))
	
		// Look up the the table and property name
		Set tLevelClass = $LG(tLevelInfo,6)
		Set tKeyProperty = $LG(tLevelInfo,12)
		
		If ($P(tLevelClass,".",1,2)="%DeepSee.Time") {
			// Key and ID are the same for time dimensions, there is no lookup
			Set pKey = pID
			Quit
		}

		Set tLevelTable = ##class(%DeepSee.Utils).%GetSQLTableName(tLevelClass)
		Set tKeyFieldName = ##class(%DeepSee.Utils).%GetSQLColumnName(tLevelClass,tKeyProperty)
		
		// Build the SQL statement to retrieve the key corresponding to the ID
		Set tSQL = "SELECT " _ tKeyFieldName _ " FROM " _ tLevelTable _ " WHERE ID = " _ pID 
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) Quit
		
		Set tResult = tStatement.%Execute()
		If $$$ISERR(tSC) Quit
	
		If tResult.%Next() {
			Set pKey = tResult.%GetData(1)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return an instance of the <class>%DeepSee.Model.cube</class>
/// meta-data object that describes the cube.<br/>
/// Return "" if the given cube does not exist.<br/>
/// When called on a subject area, this redirects to %GetSubjectAreaModel.
ClassMethod %GetModel(pCubeName As %String, Output pStatus As %Status) As %DeepSee.Model.cube
{
	Set tCube = ""
	Set pStatus = $$$OK
	Try {
		If ('..%IsBaseCube(pCubeName)) {
			// DP-429138 - Redirect to load the subject area model
			Set tCube = ..%GetSubjectAreaModel(pCubeName,.tSC)
			Quit
		}

		Set tClassName = ..%GetCubeClass(pCubeName,.pStatus)
		If $$$ISOK(pStatus) {
			// GetModel only works for *compiled* cubes!
			If ($System.OBJ.IsUpToDate(tClassName)) {
				If $zobjclassmethod(tClassName,"%IsA","%DeepSee.CubeDefinition") {
					Set tCube = $zobjclassmethod(tClassName,"%GetModel")
				}
				Else {
					Set pStatus = $$$ERROR($$$GeneralError,"Class is not cube definition")
					Quit
				}
			}
			Else {
				// get model from XData directly
				Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName,0,.pStatus)
				If $$$ISERR(pStatus) Quit
				#; find the XDATA block named Cube
				Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(tClassName,"Cube",0,.pStatus)
				If $$$ISERR(pStatus) Quit
				If $IsObject(tXData) {
					#; get XDATA as stream
					Set tStream = tXData.Data
					Do tStream.Rewind()

					If (tStream.Size > 0) {
						#; render the stream into cube meta-data object (with children)
						Set tReader = ##class(%XML.Reader).%New()

						Set pStatus = tReader.OpenStream(tStream)
						If $$$ISERR(pStatus) Quit

						Do tReader.Correlate("cube","%DeepSee.Model.cube")

						#; there should only be one cube defined
						Do tReader.Next(.tCube,.tSC)
						If $$$ISERR(tSC) Quit
						If '$IsObject(tCube) {
							Set pStatus = $$$ERROR($$$GeneralError,"No <cube> element defined in Cube block.")
							Quit
						}
					}
				}
				If (tCube = "") {
					Set pStatus = $$$ERROR($$$GeneralError,"Class does not contain a cube definition")
					Quit
				}
			}
		}
		If $IsObject(tCube) Set tCube.Timestamp = $ZDT($$$defClassKeyGet(tClassName,$$$cCLASStimechanged),3,,6)
	}
	Catch(ex) {
		Set tCube = ""
		Set pStatus = ex.AsStatus()
	}
	Quit tCube
}

/// Given the logical name, <var>pName</var> of a DeepSee subject,
/// return an instance of the <class>%DeepSee.Model.SubjectArea.subjectArea</class>
/// meta-data object that describes the cube.<br/>
/// Return "" if the given cube does not exist.<br/>
/// This method does not work on base cubes; use %GetModel.
ClassMethod %GetSubjectAreaModel(pName As %String, Output pStatus As %Status) As %DeepSee.Model.SubjectArea.subjectArea
{
	Set tSubjectArea = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pName,.pStatus)
		If $$$ISOK(pStatus) {
			// get model from XData directly
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName)
			#; find the XDATA block named Cube
			Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||SubjectArea")
			If tIndex'="" {
				#; get XDATA as stream
				Set tStream = tClassDefinition.XDatas.GetAt(tIndex).Data
				Do tStream.Rewind()

				If (tStream.Size > 0) {
					#; render the stream into cube meta-data object (with children)
					Set tReader = ##class(%XML.Reader).%New()

					Set tSC = tReader.OpenStream(tStream)
					If $$$ISERR(tSC) Quit

					Do tReader.Correlate("subjectArea","%DeepSee.Model.SubjectArea.subjectArea")

					#; there should only be one subjectArea defined
					Do tReader.Next(.tSubjectArea,.tSC)
					If $$$ISERR(tSC) Quit
					If '$IsObject(tSubjectArea) {
						Set tSC = $$$ERROR($$$GeneralError,"No <subjectArea> element defined in SubjectArea block.")
						Quit
					}
				}
			}
			If (tSubjectArea = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Class does not contain a subject area definition")
				Quit
			}
		}
		If $IsObject(tSubjectArea) Set tSubjectArea.Timestamp = $ZDT($$$defClassKeyGet(tClassName,$$$cCLASStimechanged),3,,6)
	}
	Catch(ex) {
		Set tSubjectArea = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tSubjectArea
}

/// Builds a list of functions (methods) for a given FunctionSet class
/// This list is returned in <var>funcset</var>.<br/>
/// The list is of the form list(NAME) = $LB(class,name,specparsed,return).<br/>
/// This method is not currently used.
/// [Previously private]
ClassMethod %GetFunctionSet(ByRef funcset, pClass As %String) As %Status
{
	Set tSC = $$$OK

	// loop over all methods of the class
	Set method="" For { Set method=$$$comMemberNext(pClass,$$$cCLASSmethod,method)  Quit:""=method
		Set name = $$$UPPER(method)
		Set:'$D(funcset(name)) funcset(name) = $LB(pClass,method,
								$$$comMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHformalspecparsed),
								$$$comMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHreturntype)
								)
	}

	// now find all subclasses of funcset
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute(pClass)  Quit:$$$ISERR(tSC) tSC
	While (tRS.Next(.tSC)) {
		Quit:$$$ISERR(tSC)
		Set tSC = ..%GetFunctionSet(.funcset,$G(tRS.Data("Name")))  Quit:$$$ISERR(tSC)
	}
	Quit tSC
}

/// Builds a list of available time level classes.
/// The list is of the form pClasses(calendar,NAME) = class.
/// [Previously private]
ClassMethod %GetTimeLevelClasses(Output pClasses) As %Status
{
	Kill pClasses
	Set tSC = $$$OK

	Try {		// DTB856 - Add Try/Catch
		// Find all subclasses of Time Level class
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("%DeepSee.Time.AbstractLevel")  
		If $$$ISERR(tSC) Quit
		While (tRS.Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tName = $G(tRS.Data("Name"))
			Set tShortName = $$$UPPER($P(tName,".",$L(tName,".")))
			Set tCalendar = $classmethod(tName,"%GetCalendar")		// DTB177
			If $D(pClasses(tCalendar,tShortName)) {
				Set tSC = $$$ERROR($$$GeneralError,"Ambiguous Time Level Class: "_tName)
				Quit
			}
			Set pClasses(tCalendar,tShortName) = tName		// DTB177 - Insert calendar into time function reference table
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Protected lookup of the type of a time function. If the argument <var>pClassName</var> 
/// is not a valid time class (extends <class>%DeepSee.Time.AbstractLevel</class>), then the 
/// method returns an empty string.
ClassMethod %GetTimeLevelType(pClassName As %String) As %String
{
	// Method added by DTB188
	Set tType = ""
	Try {
		If (pClassName'="") &&
				##class(%Dictionary.CompiledClass).%ExistsId(pClassName) &&
				$ClassMethod(pClassName,"%IsA","%DeepSee.Time.AbstractLevel") {
			Set tType = $PARAMETER(pClassName,"DIMTYPE")
		}
	}
	Catch ex {
		Set tType = ""
	}
	Quit tType
}

/// Protected lookup of the calendar used for a time function. If the argument <var>pClassName</var> 
/// is not a valid time class (extends <class>%DeepSee.Time.AbstractLevel</class>), then the 
/// method returns an empty string.
ClassMethod %GetTimeLevelCalendar(pClassName As %String) As %String
{
	// Method added by DTB188
	Set tType = ""
	Try {
		If (pClassName'="") &&
				##class(%Dictionary.CompiledClass).%ExistsId(pClassName) &&
				$ClassMethod(pClassName,"%IsA","%DeepSee.Time.AbstractLevel") {
			Set tType = $PARAMETER(pClassName,"CALENDAR")
		}
	}
	Catch ex {
		Set tType = ""
	}
	Quit tType
}

/// Given a date in $H format and a calendar, return the number of days since Jan 0 1900
/// This is excel's version of $H and is needed to export dates as dates to excel
ClassMethod %ExcelFormatDate(pDate As %String, pCalendar As %String) As %String
{
	// WAL264 -- if we encounter any error just return pDate
	Try {
		Set tExcelDate = pDate
		
		Set tStartDate = $ZDATEH("Dec 30 1899",6,,,,,,,,1) // WAL242 && SK -- use localeopt
		Set tEndDate = pDate		// DTB628
		
		Set:($G(tEndDate)'="") tExcelDate = ##class(%SYSTEM.SQL.Functions).DATEDIFF("d",tStartDate,tEndDate)	
	}
	Catch ex {
		Set tExcelDate = pDate	
	}
	Quit tExcelDate
}

/// Loop over all indices for a given cube and show details.<br/>
/// <var>pCubeName</var> is the name of the cube.<br/>
/// <var>pFlags</var> is a set of flags that can control what is analyzed:
/// flags include "i" (include indices), "f" (include facts), "c" (include cell cache).
/// The default is "i".<br/>
/// <var>pVerbose</var> indicates that status information is to be displayed while the analysis is done.<br/>
ClassMethod %Analyze(pCubeName As %String, pFlags As %String = "i", pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pCubeName="") {
			Write "No cube name specified",!
			Quit
		}
		Set tCube = $$$DeepSeeIndex(pCubeName)
		Set tFactClass = $$$UPPER(..%GetCubeFactClass(tCube))
		If (tFactClass="") {
			Write "Cube not found: ",pCubeName,!
			Quit
		}

		Set tIncludeIndices = pFlags["i"
		Set tIncludeCells = pFlags["c"
		Set tIncludeFacts = pFlags["f"

		Set tStart = $ZH
		// fact table
		If (tIncludeFacts) {
			Set tFacts = 0
			Set tFactSize = 0
			Set tID = $O($$$DeepSeeFactGLVN(tFactClass,""),1,data)
			While (tID '= "") {
				If (pVerbose&&'(tID#1000)) Write $C(13,27)_"[0J"_"Analyzing facts: "_tID
				Set tFacts = tFacts + 1
				Set tFactSize = tFactSize + $L(data)
				Set tID = $O($$$DeepSeeFactGLVN(tFactClass,tID),1,data)
			}
		}

		// indices
		If (tIncludeIndices) {
			Set tIndex = $O($$$DeepSeeIndexGLVN(tCube,""))
			While (tIndex '= "") {
				If (pVerbose) Write $C(13,27)_"[0J"_"Analyzing index: "_tIndex

				If ($E(tIndex) = "$") {
					#; extent index
					Set tChunk = $O($$$DeepSeeIndexGLVN(tCube,tIndex,""),1,data)
					While (tChunk '= "") {
						Set tSize(tIndex) = $L(data) + $G(tSize(tIndex))
						Set tChunk = $O($$$DeepSeeIndexGLVN(tCube,tIndex,tChunk),1,data)
					}
				}
				ElseIf ($E(tIndex) = "%") {
					// non-dimension index
				}
				Else {
					Set tValue = $O($$$DeepSeeIndexGLVN(tCube,tIndex,""))
					While (tValue '= "") {
						Set tValueCount(tIndex) = $G(tValueCount(tIndex)) + 1
						Set tChunk = $O($$$DeepSeeIndexGLVN(tCube,tIndex,tValue,""),1,data)
						While (tChunk '= "") {
							Set tSize(tIndex) = $L(data) + $G(tSize(tIndex))
							Set tChunk = $O($$$DeepSeeIndexGLVN(tCube,tIndex,tValue,tChunk),1,data)
						}
						Set tValue = $O($$$DeepSeeIndexGLVN(tCube,tIndex,tValue))
					}
				}
				Set tIndex = $O($$$DeepSeeIndexGLVN(tCube,tIndex))
			}

			If (pVerbose) Write $C(13,27)_"[0J"
		}

		// cell cache
		Set tCells = 0
		Set tBuckets = 0
		If (tIncludeCells) {
			Set tSlot = $O($$$DeepSeeCellsGLVN(tCube,""))
			While (tSlot '= "") {
				Set tBuckets = tBuckets + 1
				Set tKey = $O($$$DeepSeeCellsGLVN(tCube,tSlot,""))
				While (tKey '= "") {
					Set tCells = tCells + 1
					Set tMsr = $O($$$DeepSeeCellsGLVN(tCube,tSlot,tKey,""))
					If (tMsr '= "") {
						While (tMsr '= "") {
							Set tCells = tCells + 1
							Set tMsr = $O($$$DeepSeeCellsGLVN(tCube,tSlot,tKey,tMsr))
						}
					}
					If (pVerbose&&'(tCells#10000)) Write $C(13,27)_"[0J"_"Analyzing cell cache: "_ $FN(tCells,",",0) _ "/" _ tBuckets
					Set tKey = $O($$$DeepSeeCellsGLVN(tCube,tSlot,tKey))
				}
				Set tSlot = $O($$$DeepSeeCellsGLVN(tCube,tSlot))
			}
			If (pVerbose) Write $C(13,27)_"[0J"
		}

		// output
		If (tIncludeIndices) {
			Write !,"----------------------------------------------------------------"
			Write !,?4,"Index",?34,"Approx. Size",?53,"Cardinality"
			Set tTotal = 0
			Set tTotalCardinality = 0
			Set tIndex = $O(tSize(""))
			While (tIndex'="") {
				Set tIndexName = $S($E(tIndex)="$":"Extent Index",
					$E(tIndex)="M":$G($$$DeepSeeMetaGLVN("cubes",tCube,"msr#",tIndex),tIndex),
					1:$G($$$DeepSeeMetaGLVN("cubes",tCube,"fact#",tIndex),tIndex))
				// WAL052 -- Use alias so output can be interpreted
				If ($D($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tIndexName,"alias"))) {
					Set tIndexName = $$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tIndexName,"alias")
				}
				// WAL052
				Write !,$E(tIndex,1,3),?4,$E(tIndexName,1,24),?28,$J($FN(tSize(tIndex),",",0),18),?40,$J($FN($G(tValueCount(tIndex)),",",0),18)
				Set tTotal = tTotal + tSize(tIndex)
				Set tTotalCardinality = tTotalCardinality + $G(tValueCount(tIndex))
				Set tIndex = $O(tSize(tIndex))
			}
	
			Write !,"----------------------------------------------------------------"
			Write !,?4,"Total: ",?28,$J($FN(tTotal,",",0),18)," bytes",?60,tTotalCardinality
			Write !
		}
		If (tIncludeFacts) {
			Write !,?4,"Fact Table: ",?28,$J($FN(tFactSize,",",0),18)," bytes in ",$FN(tFacts,",",0)," fact(s)"
		}
		If (tIncludeCells) {
			Write !,?4,"Cell Cache: ",?28,$J($FN(tCells,",",0),18)," cell(s) in ",tBuckets," bucket(s)"
		}
		If (pVerbose) {
			Write !,?4,"Elapsed time: ",?32,$J($FN($ZH-tStart,",",3),18),"s"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If (pVerbose && $$$ISERR(tSC)) {
		Do $System.Status.DisplayError(tSC)
		Quit
	}
	Quit tSC
}

/// Examine the levels and measures for a given cube and report on how many missing values there are.<br/>
/// <var>pCubeName</var> is the name of the cube.<br/>
ClassMethod %AnalyzeMissing(pCube As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..%GetCubeLevels(pCube,.tLevels,1,1)
		If $$$ISERR(tSC) Quit

		Set tFactCount = ..%GetCubeFactCount(pCube)

		If (tFactCount>0) {
			Write !,"-----------------------------------------------------------------------------"
			Write !,?4,"Level",?50,$J("#Missing",18),?69,$J("%Missing",8)

			Set n = $O(tLevels(""))
			While (n'="") {
				Set tMDX = ""
				Set tType = $LG(tLevels(n),1)
				If (tType="l") {
					Set tSpec = "["_$LG(tLevels(n),2)_"].["_$LG(tLevels(n),3)_"].["_$LG(tLevels(n),4)_"]"
					Set tMDX = "SELECT "_tSpec_".&[<null>] ON ROWS FROM ["_pCube_"]"
				}
				ElseIf (tType="m") {
					Set tCountName=##class(%DeepSee.Utils).%GetCountName(pCube,.tSC)
					If $$$ISERR(tSC) Quit
					If ($LG(tLevels(n),3)'=tCountName) {
						Set tSpec = "["_$LG(tLevels(n),2)_"].["_$LG(tLevels(n),3)_"]"
						Set tMDX = "SELECT FROM ["_pCube_"] WHERE %SEARCH.&["_tSpec_" IS NULL]"
					}
				}
				ElseIf (tType="r") {
					// find null ref for relation
					Set tRelation = $LG(tLevels(n),2)
					Set tNullRef = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"relations",$$$UPPER(tRelation),"nullReplacement"))
					If (tNullRef'="") {
						Set tSpec = "["_tRelation_"]"
						Set tMDX = "SELECT FROM ["_pCube_"] WHERE "_tSpec_".&["_tNullRef_"]"
					}
				}

				If (tMDX'="") {
					Set tRS = ##class(%DeepSee.ResultSet).%New()
					Set tSC = tRS.%PrepareMDX(tMDX)
					If $$$ISERR(tSC) Quit
					Set tSC = tRS.%Execute()
					If $$$ISERR(tSC) Quit
					Set tCount = tRS.%GetOrdinalValue()
					Write !,$Case(tType,"l":"Lvl","m":"Msr","r":"Rel",:tType),?4,$E(tSpec,1,44),?50,$J($FN(tCount,",",0),18),?70,$J($FN((tCount/tFactCount)*100,",",2),6),"%"
				}
				Set n = $O(tLevels(n))
			}
		}

		Write !!,?4,"TOTAL FACTS",?50,$J($FN(tFactCount,",",0),18)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}

	Quit tSC
}

/// Return an array of the dimension tables (class names) used for a given cube.
/// If <var>pCardinality</var> is true, compute the size of each table.
ClassMethod %GetDimensionTables(pCubeName As %String, Output pStarTables, pCardinality As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pStarTables
		If (pCubeName="") {
			Write "No cube name specified",!
			Quit
		}
		Set tCube = $$$DeepSeeIndex(pCubeName)

		Set tStar = $O($$$DeepSeeMetaGLVN("cubes",tCube,"star",""))
		While (tStar'="") {
			Set tSize = 0
			If (pCardinality) {
				Set tSize = $Classmethod(tStar,"%Count")
			}
			Set pStarTables(tStar) = tSize
			Set tStar = $O($$$DeepSeeMetaGLVN("cubes",tCube,"star",tStar))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Rebuild the indices for every dimension table used for cube <var>pCubeName</var>.
/// If <var>pCubeName</var> is "*", then perform this on every cube within the current namespace
/// that is visible to the current user.
ClassMethod %BuildDimensionTableIndices(pCubeName As %String, pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pCubeName="") {
			Write:pVerbose "No cube name specified",!
			Quit
		}

		If (pCubeName="*") {
			// get list of all cubes
			Set tSC = ..%GetCubeList(.tList,"cubes",1)
		}
		Else {
			Set tList(pCubeName) = ""
		}

		// loop over list
		Set tCubeName = $O(tList(""))
		While (tCubeName'="") {
			Write:pVerbose "Cube: ",tCubeName,!
			Set tSC = ..%GetDimensionTables(tCubeName,.tTables,1)
			If $$$ISERR(tSC) Quit
			Set k = $O(tTables(""))
			While (k'="") {
				Write:pVerbose k,"..."
				Do $classmethod(k,"%BuildIndices")
				Write:pVerbose " done",!
				Set k = $O(tTables(k))
			}
			Set tCubeName = $O(tList(tCubeName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Read portion of fact table into memory.
/// Used during index loading.
ClassMethod %ReadFacts(pCubeName As %String, pStartId As %Integer, pEndId As %Integer) [ Internal ]
{
	Set tCube = $$$UPPER(pCubeName)
	Set tFactClass = $$$UPPER(..%GetCubeFactClass(tCube))
	Set tID = $O($$$DeepSeeFactGLVN(tFactClass,pStartId),1,data)
	While ((tID '= "")&&(+tID < pEndId)) {
		Set tID = $O($$$DeepSeeFactGLVN(tFactClass,tID),1,data)
	}
}

/// Loop over all indices for the given cube and compress them.
ClassMethod %CompressIndices(pCubeName As %String, pVerbose As %Boolean = 0) As %Status
{
	// DTB272 - Add Try/Catch block and return status
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCubeName)
		If (tCube="") {
			Set tSC = $$$ERROR($$$GeneralError,"No cube name specified")
			Quit
		}
		If ('..%IsBaseCube(pCubeName)) {
			Set tSC = $$$ERROR($$$GeneralError,"%CompressIndices cannot be called on a SubjectArea: " _ pCubeName) 
			Quit
		}

		Set tIndex = $O($$$DeepSeeIndexGLVN(tCube,""))
		While (tIndex '= "") {
			// We assume that non-bitmap indices start with %
			If ($E(tIndex) = "$") {
			}
			ElseIf ($E(tIndex) = "%") {
				// non-dimension index
			}
			Else {
				If (pVerbose) Write $C(13,27)_"[0J"_"Compressing index: ",tIndex
				Set n = 0
				Set tValue = $O($$$DeepSeeIndexGLVN(tCube,tIndex,""))
				While (tValue '= "") {
					Set n = n + 1
					Write:(pVerbose&&'(n#100)) $C(13,27)_"[0J"_"Compressing index: ",tIndex," (",tValue,")"
					Set tChunk = $O($$$DeepSeeIndexGLVN(tCube,tIndex,tValue,""),1,data)
					While (tChunk '= "") {
						If ($BitCount(data,1)=0) {
							Kill $$$DeepSeeIndexGLVN(tCube,tIndex,tValue,tChunk)
						}
						Else {
							Set $$$DeepSeeIndexGLVN(tCube,tIndex,tValue,tChunk) = $BitLogic(data)
						}
						Set tChunk = $O($$$DeepSeeIndexGLVN(tCube,tIndex,tValue,tChunk),1,data)
					}
					Set tValue = $O($$$DeepSeeIndexGLVN(tCube,tIndex,tValue))
				}
			}
			Set tIndex = $O($$$DeepSeeIndexGLVN(tCube,tIndex))
		}
		If (pVerbose) Write $C(13,27)_"[0J"_"Complete"
	}
	Catch ex {
		Set tSC =ex.AsStatus()
	}

	If (pVerbose&&$$$ISERR(tSC)) Write $system.Status.GetOneStatusText(tSC),!		// DTB272 - Display any error message
	
	Quit tSC
}

/// Convert a class name of the form %Library.xxx to %xxx.
ClassMethod %DenormalizeType(pType As %String) As %String [ CodeMode = expression ]
{
$S($E(pType,1,9)="%Library.":"%"_$P(pType,".",2,999),1:pType)
}

/// Returns the SQL table name for class <var>pClass</var>. Returns the empty string if the supplied <var>pClass</var>
/// does not have an associated table.
ClassMethod %GetSQLTableName(pClass As %String, pVerifyExists = 0) As %String
{
	Set tTableName = $S(pClass="":"",1:$$$comClassKeyGet(pClass,$$$cCLASSsqlschemaname)_"."_$$$comClassKeyGet(pClass,$$$cCLASSsqltablename))
	If (tTableName=".") {
		Set tTableName = $Replace(pClass,".","_",,$length(pClass,".")-2)
	}
	
	Quit $S(('pVerifyExists||##class(%SYSTEM.SQL.Schema).TableExists(tTableName)):tTableName,1:"")		// DTB786 - Optionally verify the table does in fact exist
}

/// Returns the SQL name of property <var>pProp</var> for class <var>pClass</var>.
ClassMethod %GetSQLColumnName(pClass As %String, pProp As %String) As %String [ Final ]
{
	If (pProp = "") {
		Quit ""
	}
	ElseIf (pProp = "%ID") {
		Quit "%ID"
	}
	Set tCol = $Get($$$EXTPROPsqlcolumnname($$$pEXT,pClass,pProp))
	If (tCol'="") {
		Set x = $$QuoteId^%occStorageUtil(tCol,.tColQ)
		Set tCol = tColQ
	}
	Quit tCol
}

/// Return an <b>array</b> of all currently defined DeepSee Cubes visible to the current user.
/// This is used by utilities.<br/>
/// This array takes the form:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type)<br/>
/// <var>pType</var>, if defined, can be "cubes" or "subjectAreas". This will limit the returned
/// list to those item types.<br/>
/// <var>pNonAbstract</var>, if true, limits the returned items to non-abstract cubes.<br/>
/// <var>pBaseCube</var>, if provided, limits the returned items to the base cube and its descendants.<br/>
/// If there are no cubes, then <var>pList</var> will be <b>undefined</b>.
ClassMethod %GetCubeList(Output pList, pType As %String = "", pNonAbstract As %Boolean = 0, pBaseCube As %String = "") As %Status [ Final ]
{
	Kill pList
	Set tIsCube = 1
	Set tCube = $O($$$DeepSeeMetaGLVN("cubes",""))
	While (tCube '= "") {
		Set tIsVersion = ##class(%DeepSee.CubeVersion.Utils).%IsVersion(tCube)		// DTB130 - don't include internal version cubes in the list
		Set tIsAbstract = ..%IsCubeAbstract(tCube)
		If ( ..%CheckPrivilege(tCube) && 'tIsVersion && (($D($$$DeepSeeMetaGLVN("cubes",tCube))>10)||tIsAbstract) ) {
			Set tIsCube = ..%IsBaseCube(tCube)
			If (pNonAbstract && tIsCube && tIsAbstract) {
				// skip
			}
			Else {
				If ((pType="")||((pType="cubes")&&tIsCube)||((pType="subjectAreas")&&'tIsCube)) {
					// JMD900: test base cube
					If ((pBaseCube="")||(pBaseCube=tCube)||($$$UPPER(..%GetBaseCube(tCube))=$$$UPPER(pBaseCube))) {
						// get original cube name (plus type extension)
						Set tType = $S(tIsCube:"cube",1:"subjectArea")
						Set pList(tCube) = $LB(..%GetCubeName(tCube),..%GetCubeCaption(tCube),..%GetCubeModifiedDate(tCube),tType)
					}
				}
			}
		}
		Set tCube = $O($$$DeepSeeMetaGLVN("cubes",tCube))
	}
	Quit $$$OK
}

/// Return an array of all currently DeepSee Cubes and subject areas
/// in a format that can be used by a finderDialog.
/// <var>pType</var>, if defined, can be "cubes" or "subjectAreas". This will limit the returned
/// list to those item types.
/// <var>pNonAbstract</var>, if true, limits the returned items to non-abstract cubes.
ClassMethod %GetCubeListArray(ByRef pParameters, Output pMetaData, Output %pData, pType As %String = "", pNonAbstract As %Boolean = 0) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetCubeList(.tList,pType,pNonAbstract)
		If $$$ISERR(tSC) Quit

		Set tSC = ..%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all currently defined DeepSee Pivots
/// in a format that can be used by a finderDialog.
ClassMethod %GetPivotListArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetPivotList(.tList)
		If $$$ISERR(tSC) Quit

		Set tSC = ..%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all currently defined DeepSee dashboards
/// in a format that can be used by a finderDialog.
ClassMethod %GetDashboardListArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetDashboardList(.tList)
		If $$$ISERR(tSC) Quit

		Set tSC = ..%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all currently defined, public DeepSee KPIs
/// in a format that can be used by a finderDialog.
ClassMethod %GetKPIListArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetKPIList(.tList)
		If $$$ISERR(tSC) Quit

		Set tSC = ..%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all currently defined DeepSee Worksheets
/// in a format that can be used by a finderDialog.
ClassMethod %GetWorksheetListArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetWorksheetList(.tList)
		If $$$ISERR(tSC) Quit

		Set tSC = ..%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all currently defined Business Metrics
/// in a format that can be used by a finderDialog.
ClassMethod %GetMetricListArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetMetricList(.tList)
		If $$$ISERR(tSC) Quit

		Set tSC = ..%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Helper method.
/// Convert the items in <var>pList</var> into an array that can be used by a finderDialog.
ClassMethod %BuildItemListArray(ByRef pList, Output pMetaData, Output %pData, ByRef pParameters) As %Status [ Final, Internal ]
{
#define timeUTCHtoLocal(%utc) $zu(193,%utc,0)
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","translatedName","type","date","caption")
		Set tSearch = $$$UPPER($G(pParameters("search")))
		// + WAL078
		Set tOrderByCaption = $G(pParameters("orderByCaption"))
		// - WAL078
		// separator character within names
		Set tSep = "/"

		Set tItem="" For  {
			Set tItem = $O(pList(tItem)) Quit:tItem=""

			// get values
			Set tName = $LG(pList(tItem),1)
			Set tCaption = $ZSTRIP($LG(pList(tItem),2),"<>W")		// DP-423648
			Set:tCaption["$$$" tCaption = ##class(%DeepSee.UserPortal.Utils).%ResolveText($TR(tCaption,"#","/"))

			// apply search to caption
			Set tSkip = 0
			If ((tSearch'="")&&($$$UPPER(tCaption)'[tSearch)) {
				Set tSkip = 1
			}

			If ('tSkip) {
				Set h = $LG(pList(tItem),3)
				Set:h="" h = $H // default to today
				// convert to local time
				Set h = $$$timeUTCHtoLocal(h)
				Set tTime = $ZDT(h,3)
				Set tItemType =	 $LG(pList(tItem),4)

				// apply pParameters("sort") criteria
				If $g(pParameters("sort"))="date" {
					If $d(tBucketINDEX)=0 {
						Set tBucketNAME(-4)=$$$Text("Today","%ZEN")
						Set tBucketNAME(-3)=$$$Text("Yesterday","%ZEN")
						Set tBucketNAME(-2)=$$$Text("Earlier this week","%ZEN")
						Set tBucketNAME(-1)=$$$Text("Last week","%ZEN")
						Set tBucketNAME(0)=$$$Text("Older than last week","%ZEN")
						Set tTodayH=$p($H,",",1),tLastSatH=tTodayH-$zdt(tTodayH,10)-1
						Set tBucketINDEX(tTodayH)=-4
						If tTodayH-1>tLastSatH Set tBucketINDEX(tTodayH-1)=-3
						For tH=tTodayH-2:-1:tLastSatH+1 Set tBucketINDEX(tH)=-2
						For tH=tLastSatH:-1:tLastSatH-6 Set tBucketINDEX(tH)=-1
					}
					Set tBucketIndex=+$get(tBucketINDEX($p($zdth(tTime,3),",",1)))
					Set tBucketName=tBucketNAME(tBucketIndex)
					Set tTempData(tBucketIndex)=$lb(tBucketName,tBucketName,"date","","","")
					Set tTempData(tBucketIndex,tTime,$i(tTempData(tBucketIndex,tTime)))=$lb(tName,tName,tItemType,##class(%ZEN.FinderUtils).mactime(tTime),tCaption)
				} Else {
					Set tRef="%pData(",tLength=$l(tName,tSep)
					For i=1:1:tLength {
						Set tType=$S(i=tLength:tItemType,1:"folder")
						// + WAL078 - If its requested that we order by caption prefix the index (tName) with the caption
						// 			(i=tLength) prevents us from ordering folders by their item captions
						//   DTB804 - Double-quotes existing in the caption must be escaped for the indirection to work
						//	 DP-418790 - Prepend "folder" types with the ! character so they sort first when added as subscripts
						// 			to the %pData array. Otherwise, sort by caption
						Set tRef = tRef_""""_$S(tType="folder":"!.",1:"")_$zcvt($S((tOrderByCaption&&(i=tLength)&&($G(tCaption)'="")):$$$iscEscapeDblQuote(tCaption),1:""),"u")_$$$iscEscapeDblQuote($zcvt($p(tName,tSep,i),"u"))_"."_tType_""","
						// - WAL078
						Set tRefSetLeft=$e(tRef,1,*-1)_")"
						Set tDName = $p(tName,tSep,i)
						Set:tDName["$$$" tDName = ##class(%DeepSee.UserPortal.Utils).%ResolveText($TR(tDName,"#","/"))
						Set tDName2=$p(tName,tSep,1,i)
						Set tTranslatedName=##class(%DeepSee.UserPortal.Utils).%ResolveName(tDName2)
						Set @tRefSetLeft=$lb(tDName,tDName2,tTranslatedName,tItemType,##class(%ZEN.FinderUtils).mactime(tTime),tCaption)
					}
				}
			}
        }
        // Convert tTempData(A,B,C) to %pData(A,i++) with B sorted backwards
		If $d(tTempData) {
			Set i="" For  {
				Set i=$o(tTempData(i)) Quit:i=""
				Set %pData(i)=tTempData(i)
				Set index=0
				Set j="" for  {
					Set j=$o(tTempData(i,j),-1) Quit:j=""
					Set k="" for  {
						Set k=$o(tTempData(i,j,k)) Quit:k=""
						Set %pData(i,$i(index))=tTempData(i,j,k)
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

/// Return a list of all currently defined MDX functions.
/// This is used by utilities.<br/>
/// If <var>pAsTree</var> is true, return a format that a tree control can consume.
ClassMethod %GetFunctionList(Output pList, pAsTree As %Boolean = 0) As %Status [ Final ]
{
	// make sure global is defined
	Set tSC = ##class(%DeepSee.Query.setFunction).%BuildFunctionMetaData()
	Set tSC = ##class(%DeepSee.Query.memberFunction).%BuildFunctionMetaData()

	// mark some functions as hidden
	Set tHidden("%ADDPARENTS") = ""
	Set tHidden("%CELL") = ""
	Set tHidden("%CELLZERO") = ""
	Set tHidden("%RANK") = ""
	Set tHidden("%CHILDRENORSELF") = ""

	Kill pList

	If (pAsTree) {
		Set tSetRoot = 1
		Set tMbrRoot = 2
		Set pList(0,"ch",tSetRoot) = ""
		Set pList(tSetRoot) = $LB($$$Text("Set functions","%DeepSee"),"",1,"",1,,$$$Text("Dimensions","%DeepSee"),"font-weight:bold;")
		Set pList(0,"ch",tMbrRoot) = ""
		Set pList(tMbrRoot) = $LB($$$Text("Member functions","%DeepSee"),"",1,"",1,,$$$Text("Measures","%DeepSee"),"font-weight:bold;")
		Set pList = 2
	}

	Set tCat = $O($$$DeepSeeFunctionGLVN(""))
	While (tCat '= "") {
		Set tFunc = $O($$$DeepSeeFunctionGLVN(tCat,""),1,tInfo)
		While (tFunc '= "") {
			Set tImplemented = $LG(tInfo,1)
			Set tReturns = $LG(tInfo,2)
			Set tArgTypes = $LG(tInfo,3)
			Set tArgDesc = $LG(tInfo,4)

			If (tImplemented && '$D(tHidden(tFunc))) {
				Set tArgs = ""
				Set tOptArgs = 0
				For n=$S(tCat="mbr":2,1:1):1:$LL(tArgTypes) {
					Set tIsOpt = $P($LG(tArgDesc,n),":")=0
					Set:tIsOpt tOptArgs = tOptArgs + 1
					If ($LG(tArgTypes,n)=$$$dstFlag) {
						Set tArgName = $TR($P($LG(tArgDesc,n),":",2),",","|")
					}
					Else {
						Set tArgName = ##class(%DeepSee.Query.function).%TypeFlagToString($LG(tArgTypes,n))
					}
					Set tArgs = tArgs _ $S(tArgs'="":",",1:"") _ $S(tIsOpt:"[",1:"") _ tArgName
				}
				Set:tArgs'="" tArgs = "("_tArgs_$TR($J("",tOptArgs)," ","]")_")"

				If (tCat = "mbr") {
					Set tSig = ##class(%DeepSee.Query.function).%TypeFlagToString($LG(tArgTypes,1)) _ "."_tFunc _ tArgs _ " returns " _ ##class(%DeepSee.Query.function).%TypeFlagToString(tReturns)
				}
				Else {
					Set tSig = tFunc_tArgs _ " returns " _ ##class(%DeepSee.Query.function).%TypeFlagToString(tReturns)
				}
				If (pAsTree) {
					Set pList($I(pList)) = $LB(tFunc,tFunc,0,"",0,,tSig)
					Set pList($Case(tCat,"mbr":tMbrRoot,:tSetRoot),"ch",pList) = ""
				}
				Else {
					Set pList(tFunc) = tSig
				}
			}
			Set tFunc = $O($$$DeepSeeFunctionGLVN(tCat,tFunc),1,tInfo)
		}
		Set tCat = $O($$$DeepSeeFunctionGLVN(tCat))
	}
	Quit $$$OK
}

/// This utility method tests a DeepSee time level class to
/// verify that it is implemented correctly.<br/>
/// There are several tests:<br/>
/// Test 1: test the %Convert, %KeyToValue, and %ValueToKey methods.<br/>
/// Test 2: test the %Convert, %KeyToValue, and %ValueToKey methods.<br/>
ClassMethod %TestTimeClass(pClassName As %String, pTest As %Integer = 1, pFormat As %String = "") As %Status
{
	// !!! TEST GETLEVELMEMBERS
	
	Set tSC = $$$OK
	Try {
		// See if class exists
		Set tName = $zobjclassmethod(pClassName,"%GetName")
		Set:tName="" tName = "[Name not defined]"
		Write "Level name: ",tName,!
	
		// build a range of dates
		For n = 1:1:10 {
			Set h = $ZDTH("1900-01-01",3) + (n*455) _ "," _ $R(86400)
			Set tDates(h) = ""
		}

		If (pTest = 1) {
			// convert test
			Write "Logical Value is provided by %Convert method",!
			Write "Display Value is provided by %KeyToValue method on the logical value",!
			Write "Key Value is provided by %ValueToKey method on the display value",!

			Write "-------------------------------",!
			Write "Time",?20,"Logical",?30,"Display",?45,"Key",!

			Set h = $O(tDates(""))
			While (h'="") {
				Set tErr = ""
				Set tConvert = $zobjclassmethod(pClassName,"%Convert",h)
				Set tValue = $zobjclassmethod(pClassName,"%KeyToValue",tConvert,pFormat)
				Set tKey = $zobjclassmethod(pClassName,"%ValueToKey",tValue,pFormat)
				If (tKey'=tConvert) {
					Set tErr = "(Logical != Key)"
				}
			
				Write $E($ZDT(h,6),1,11),?13,$E($ZDT(h,3),12,13),":",
					?20,tConvert,?30,tValue,?45,tKey
				If (tErr'="") {
					Write ?62,tErr
				}

				Write !
				Set h = $O(tDates(h))
			}
			// make sure test for invalid member fails!!!
			Set tValue = "Members"
			Set tKey = $zobjclassmethod(pClassName,"%ValueToKey",tValue,pFormat)
			If (tKey '= "") {
				Write "Error: %ValueToKey should return """" for invalid member: ",tValue,"(",tKey,")",!
			}


		}
		ElseIf (pTest = 2) {
			// range test
			Write "-------------------------------",!
			Write "The %KeyToBaseRange method finds the starting and ending",!
			Write "time (as $H) for a given logical value.",!
			Write "Time",?15,"Logical",?25,"Start",?45,"End",!

			Set h = $O(tDates(""))
			While (h'="") {
				Set tErr = ""
				Set tConvert = $zobjclassmethod(pClassName,"%Convert",h)

				Set tSC = $zobjclassmethod(pClassName,"%KeyToBaseRange",tConvert,.tStartRange,.tEndRange)
				If $$$ISERR(tSC) Quit
			
				Write $E($ZDT(h,6),1,11),":",
					?15,tConvert,?25,$ZDT(tStartRange,3),?45,$ZDT(tEndRange,3)
				If (tErr'="") {
					Write ?60,tErr
				}

				Write !
				Set h = $O(tDates(h))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Do $System.OBJ.DisplayError(tSC)
	}
	Quit tSC
}

/// Compute pre-loaded cell cache entries for the given cube
/// based on the cell cache specification within the cube's definition.
ClassMethod %LoadCellCache(pCubeName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tClassName = ..%GetCubeClass(pCubeName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tSC = $zobjclassmethod(tClassName,"%GetCellCachePreLoads",.tList)
		If $$$ISERR(tSC) Quit

		Set n = $O(tList(""))
		While (n '= "") {
			Kill tSpec
			Merge tSpec = tList(n)
			Set tSC = ..%ComputeCellCache(pCubeName,.tSpec)
			Set n = $O(tList(n))
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Generate and execute a query that will force the update of the
/// cell cache for given cube and levels.
ClassMethod %ComputeCellCache(pCubeName As %String, ByRef pSpec) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tAxisCount = 0
		Set tMsrCount = 0

		Set tSpec = $O(pSpec(""))
		While (tSpec '= "") {
			Set tFact = pSpec(tSpec)
			If ($E(tFact) = "M") {
				Set tMsrCount = tMsrCount + 1
				Set tMsr(tMsrCount) = tSpec
			}
			Else {
				Set tAxisCount = tAxisCount + 1
				Set tAxis(tAxisCount) = tSpec
			}
			Set tSpec = $O(pSpec(tSpec))
		}

		// construct query
		Set tMDX = "SELECT "
		For a=1:1:tAxisCount {
			If (a < 6) {
				Set tMDX = tMDX _ $S(a>1:",",1:"") _ tAxis(a) _ ".Members ON " _ (a-1)
			}
		}

		// add measures (if any)
		If ((tAxisCount>0)&&(tMsrCount>0)) {
			Set tMDX = tMDX _ ","
		}
		If (tMsrCount>1) {
			Set tMDX = tMDX _ "{"
		}
		For m=1:1:tMsrCount {
			Set tMDX = tMDX _ $S(m>1:",",1:"") _ tMsr(m)
		}
		If (tMsrCount>1) {
			Set tMDX = tMDX _ "}"
		}
		If (tMsrCount>0) {
			Set tMDX = tMDX _ " ON " _ tAxisCount
		}

		Set tMDX = tMDX _ " FROM " _ pCubeName
		
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tRS.%UseCache = 0
		Set tSC = tRS.%PrepareMDX(tMDX)
		If $$$ISERR(tSC) Quit

		// DTB704 - Always use %ExecuteAsynch
		Set tSC = tRS.%ExecuteAsynch(.tQueryKey)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse the given DeepSee range expression.<br/>
/// A range expression takes the form:<br/>
/// spec:replace;spec:replace;<br/>
/// spec takes the form:<br/>
/// value | (value,value) | [value,value] <br/>
/// () specifies a non-inclusive edge of a range.<br/>
/// [] specifies a inclusive edge of a range.<br/>
/// <var>pContext</var> is used for error reporting.
/// <var>pCode</var> contains a generated expression that 
/// implement the range expression (using x as an input value).
ClassMethod %ParseRangeExpression(pRange As %String, Output pOutput, pContext As %String = "", Output pCode As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pCode = ""
		Kill pOutput
		Set tItem = 0
		Set tState = 0
		Set p = 1
		Set tToken = ""
		Set tIsRange = 0
		Set tValueInc = ""
		Set tIsMultiRange = 0
		While ($$$ISOK(tSC) && (p <= $L(pRange))) {
			Set ch = $E(pRange,p)
			Set p = p + 1
			If (tState = 0) {
				If ((ch = "(")||(ch = "[")) {
					Set tIsRange = 1
					Set tStartCond = $Case(ch,"(":">",:">=")
					Set tToken = ""
					Set tState = 2
				}
				ElseIf (ch=";") {
					// ignore
				}
				ElseIf (ch'=" ") {
					Set tIsRange = 0
					Set tStartCond = "="
					Set tEndCond = ""
					Set tToken = ch
					Set tState = 1
				}
			}
			ElseIf (tState = 1) {
				If (ch=":") {
					Set tValue1 = tToken
					Set tToken = ""
					Set tState = 5
					Set tQuoted = 0
				}
				Else {
					Set tToken = tToken _ ch
				}
			}
			ElseIf (tState = 2) {
				// first part of range
				If (ch=",") {
					Set tValue1 = tToken
					Set tToken = ""
					Set tState = 3
				}
				ElseIf ((ch = ")")||(ch = "]")) {
					// error
					Set tSC = $$$ERROR($$$GeneralError,"Range expression must have 2 values"_pContext)
				}
				ElseIf (ch=":") {
					// This is a multi-range expression
					Set tValue1 = tToken
					Set tToken = ""
					Set tState = 31
					//Set tSC = $$$ERROR($$$GeneralError,"Range expression not closed"_pContext)
				}
				Else {
					Set tToken = tToken _ ch
				}
			}
			ElseIf (tState = 3) {
				// second part of range
				If ((ch = ")")||(ch = "]")) {
					Set tEndCond = $Case(ch,")":"<",:"<=")
					Set tValue2 = tToken
					Set tToken = ""
					Set tState = 4
				}
				ElseIf (ch=",") {
					// error
					Set tSC = $$$ERROR($$$GeneralError,"Range expression must have 2 values"_pContext)
				}
				ElseIf (ch=":") {
					// error
					Set tSC = $$$ERROR($$$GeneralError,"Range expression not closed"_pContext)
				}
				Else {
					Set tToken = tToken _ ch
				}
			}
			ElseIf (tState = 31) {
				// Second part of multi-range
				// wait for :
				If ((ch = ")")||(ch = "]")) {
					Set tSC = $$$ERROR($$$GeneralError,"Multi-Range expression must have 3 values"_pContext)
				}
				ElseIf (ch=",") {
					// error
					Set tSC = $$$ERROR($$$GeneralError,"Invalid Multi-Range Expression"_pContext)
				}
				ElseIf (ch=":") {
					Set tValueInc = tToken
					Set tToken = ""
					Set tState = 32
				}
				Else {
					Set tToken = tToken _ ch
				}
			}
			ElseIf (tState = 32) {
				// Third part of multi-range
				// wait for 0 or ]
				If ((ch = ")")||(ch = "]")) {
					Set tEndCond = $Case(ch,")":"<",:"<=")
					Set tValue2 = tToken
					Set tToken = ""
					Set tState = 4
					Set tIsMultiRange = 1
				}
				ElseIf (ch=",") {
					// error
					Set tSC = $$$ERROR($$$GeneralError,"Invalid Multi-Range Expression"_pContext)
				}
				ElseIf (ch=":") {
					// error
					Set tSC = $$$ERROR($$$GeneralError,"Invalid Multi-Range Expression"_pContext)
				}
				Else {
					Set tToken = tToken _ ch
				}
			}
			ElseIf (tState = 4) {
				// wait for : after range spec
				If (ch = ":") {
					Set tState = 5
					Set tQuoted = 0
				}
			}
			ElseIf (tState = 5) {
				// get replace value
				If ((ch = """") && (tToken="")) {
					Set tQuoted = 1
				}
				ElseIf ((ch = """") && (tQuoted)) {
					Set tQuoted = 0
				}
				ElseIf ('tQuoted&&(ch = ";")) {
					if (tIsMultiRange) {
						For t1=tValue1:tValueInc:tValue2 {
							Quit:t1=tValue2
							Set tReplace = tToken
							Set tItem = tItem + 1
							Set t2 = t1 + tValueInc
							If (t1=tValue1) {
								Set tLeftCond = tStartCond
							}
							Else {
								Set tLeftCond = ">="
							}
							If (t2=tValue2) {
								Set tRightCond = tEndCond
							}
							Else {
								Set tRightCond = "<"
							}
							Set tReplace = $replace(tReplace,"%1",t1)
							Set tReplace = $replace(tReplace,"%2",t2)
							If (tReplace["$$$eval") {
								Set tSC = ..%ExpandRangeMacro(.tReplace,"$$$eval",pContext)
								Quit:$$$ISERR(tSC)
							}
							Set pOutput(tItem) = $LB(1,tLeftCond,t1,tRightCond,t2,tReplace)
						}
						Set tIsMultiRange = 0
					} Else {
						Set tReplace = tToken
						Set tItem = tItem + 1
						Set pOutput(tItem) = $LB(tIsRange,tStartCond,tValue1,tEndCond,tValue2,tReplace)
					}
					Set tState = 0
				}
				Else {
					Set tToken = tToken _ ch
				}
			}
		}

		If ($$$ISOK(tSC) && (tState '= 0)) {
			Set tSC = $$$ERROR($$$GeneralError,"Range expression must end with ;"_pContext)
		}
		If $$$ISERR(tSC) Quit

		// create code
		// JMD1408: add initial test for ""
		Set pCode = "$S((x=""""):"""","
		For n = 1:1:tItem {
			Set tExpr = ""
			Set tIsRange = +$LG(pOutput(n),1)
			Set tStartCond = $LG(pOutput(n),2)
			Set tValue1 = $LG(pOutput(n),3)
			Set tEndCond = $LG(pOutput(n),4)
			Set tValue2 = $LG(pOutput(n),5)
			Set tReplace = $LG(pOutput(n),6)
			If ('tIsRange) {
				Set tExpr = "x=" _ $$$quote(tValue1)
			}
			Else {
				If (tValue1'="") {
					Set tExpr = "(x" _ tStartCond _ $$$quote(tValue1)_ ")"
				}
				If (tValue2'="") {
					Set tExpr = tExpr _ $S(tExpr="":"",1:"&&") _ "(x" _ tEndCond _ $$$quote(tValue2) _ ")"
				}
			}

			If (tExpr'="") {
				Set pCode = pCode _ tExpr _ ":" _ $$$quote(tReplace) _ ","
			}
		}
		Set pCode = pCode _ "1:"""")"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod %ExpandRangeMacro(ByRef pReplace As %String, pExp As %String, pContext As %String = "") As %Status [ Private ]
{
	#dim tP1,tP2,tExpIdx,tN,i,ch,tStatement
	
	set tExpIdx = $f(pReplace,pExp)
	set tP1 = $f(pReplace,"(",tExpIdx)
	Quit:tP1=0 $$$ERROR($$$GeneralError,"Macro"_pExp_" is without opening parenthesis: "_pReplace_pContext)
	
	set tN=1
	set tP2 = 0
	for i=tP1:1:$l(pReplace) {
		set ch = $e(pReplace,i)
		if (ch="(") {
			set tN = tN + 1
		}
		ElseIf (ch=")") {
			set tN = tN - 1
			if (tN=0) {
				set tP2 = i
				Quit
			}
		}
	}
	
	Quit:tP2=0 $$$ERROR($$$GeneralError,"Macro"_pExp_" is not closed: "_pReplace_pContext)
	
	Set tStatement = "set %xxx="_$e(pReplace,tP1,tP2-1)
	x tStatement
	Set tExpIdx = tExpIdx - $l(pExp)
	
	set $e(pReplace,tExpIdx,tP2) = %xxx
	
	Quit $$$OK
}

/// Delete the given DeepSee log file.
ClassMethod %KillLogFile(pFileName As %String = "DeepSeeTasks") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill ^DeepSee.LastLogError
		Set tFile = ##class(%Library.File).NormalizeFilename($system.Util.ManagerDirectory() _ pFileName _ "_" _ $namespace _ ".log")
		Lock +^DeepSee.Log(tFile):5 Else   Set tSC=$$$ERROR($$$GeneralError,"Unable to get lock for log file")
		If $$$ISOK(tSC),##class(%Library.File).Exists(tFile) {
			Set tOK = ##class(%Library.File).Delete(tFile)
			If 'tOK {
				Set tSC = $$$ERROR($$$GeneralError,"Unable to delete file: "_tFile)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $get(tFile)'="" Lock -^DeepSee.Log(tFile)#"I"
	Quit tSC
}

/// Appends an error message to a DeepSee log file within the log directory. This method uses
/// locks to support simultaneous updates from from multiple processes.<br/>
/// <var>pSource</var> is the source of the error.<br/>
/// <var>pMsg</var> is the error message.<br/>
/// <var>pFileName</var> is the name of the log file.
/// This should not include a file path or file extension.<br/>
ClassMethod %WriteToLog(pSource As %String = "", pMsg As %String = "", pFileName As %String = "DeepSeeTasks") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tLocked = 0
	Try {
		// Put file in mgr directory
		// append namespace to file name
		Set tFile = ##class(%Library.File).NormalizeFilename($system.Util.ManagerDirectory() _ pFileName _ "_" _ $namespace _ ".log")
		Set io = $io
		Lock +^DeepSee.Log(tFile):5 Else   Set tSC=$$$ERROR($$$GeneralError,"Unable to get lock for log file")
		If $$$ISERR(tSC) Quit
		Set tLocked = 1
		// See if the file exists, if not we are the first to create it an need to set the attributes properly so others can write to it also
		set tFileExisted = ##class(%Library.File).Exists(tFile)
		Open tFile:"WSA":0 Else  Set tSC=$$$ERROR($$$FileCanNotOpen,tFile)
		If $$$ISERR(tSC) Quit
		Use tFile
		Set tTime = $zdatetime($ZU(188),3,,3)			// DTB332 - Use $ZU function which accounts for local time
		Write tTime," ",$J($J,10)," ",$J($E(pSource,1,10),10)," ",pMsg,!
		Use io
		Close tFile
		If 'tFileExisted {
				// chmod owner=rw,group=rw,others=rw
			If $$$ISUNIX Do ##class(%File).SetAttributes(tFile,256+128+32+16+4+2)
		}

		// test for file rollover (within lock)
		If (##class(%Library.File).GetFileSize(tFile)>5000000) {
			Set tRolloverFile = ##class(%Library.File).NormalizeFilename($system.Util.ManagerDirectory() _ pFileName _ "_" _ $namespace _ ".old")
			Do ##class(%Library.File).CopyFile(tFile,tRolloverFile,1)
			Do ..%KillLogFile(pFileName)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Use io
	}
	If ($G(tLocked)) {
		Lock -^DeepSee.Log(tFile)#"I"
		Close tFile
	}
	If $$$ISERR(tSC) {
		// Note this error in a global
		Set ^DeepSee.LastLogError = $System.Status.GetOneErrorText(tSC)
	}
	Quit tSC
}

/// Return the full name of a DeepSee log file.
ClassMethod %GetLogFileName(pFileName As %String = "DeepSeeTasks") As %String [ Internal ]
{
	Quit ##class(%Library.File).NormalizeFilename($system.Util.ManagerDirectory() _ pFileName _ "_" _ $namespace _ ".log")
}

/// Return the properties of a cube data source in a format that can be consumed
/// by a Zen dynaTree control.<br/>
/// <var>pRoot</var> is used to specify that an incremental load of children is requested; if provided it is the spec of a parent node.<br/>
ClassMethod %GetDataSourceTree(pClass As %String, Output pTree, ByRef pParms, pLevel As %Integer = 0, pParentRef As %String = "", pRoot As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		If (pClass = "") {
			If (pLevel = 0) {
				Set n = $I(pTree)
				Set pTree(n) = $LB($$$Text("No Data Source","%DeepSee"),"",0,,,,,"color:red;")
				Set pTree(0,"ch",n) = ""
			}
			Quit
		}

		// special case: test for worksheets and kpis
		Set tExt = $P(pClass,".",$L(pClass,"."))
		If ((tExt="kpi")||(tExt="metric")||(tExt="worksheet")) {
			If (tExt="kpi") {
				Set tName = $P(pClass,".",1,$L(pClass,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				Set tName = ""
			}
			ElseIf (tExt="worksheet") {
				Set tName = pClass
				Set tKPIClass = "%DeepSee.KPIWorksheet"
			}
			Else {
				Set tName = pClass
				Set tKPIClass = "Ens.BusinessMetricKPI"
			}

			New %datacontroller
			Set tCriteria = ##class(%ZEN.proxyObject).%New()
			Set tSC = ##class(%DeepSee.AbstractKPI).%CreateLocalController(.tController,tKPIClass,tName,tCriteria)
			If $$$ISERR(tSC) Quit
			Set %datacontroller = tController

			Set tSC = tController.%GetModelPropertyInfo(.tPropInfo)
			If $$$ISERR(tSC) Quit

			// sort prop info; remove % properties
			Set tProp = $O(tPropInfo(""))
			While (tProp'="") {
				If (tProp '[ "%") {
					Set tInfo(tPropInfo(tProp)) = tProp
				}
				Set tProp = $O(tPropInfo(tProp))
			}

			Set k = $O(tInfo(""))
			While (k'="") {
				Set n = $I(pTree)
				Set tName = tInfo(k)
				Set tDisplayName = tName
				Set pTree(n) = $LB(tDisplayName,tName)
				Set pTree(0,"ch",n) = ""
				Set k = $O(tInfo(k))
			}
			Quit
		}

		If '$$$defClassDefined(pClass) {
			If (pLevel = 0) {
				Set n = $I(pTree)
				Set pTree(n) = $LB($$$FormatText($$$Text("Class not found '%1'","%DeepSee"),pClass),"",0,,,,,"color:red;")
				Set pTree(0,"ch",n) = ""
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Class not found: "_pClass)
			}
			Quit
		}

		If '$$$comClassDefined(pClass) {
			If (pLevel = 0) {
				Set n = $I(pTree)
				Set pTree(n) = $LB($$$FormatText($$$Text("Class not compiled '%1'","%DeepSee"),pClass),"",0,,,,,"color:red;")
				Set pTree(0,"ch",n) = ""
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Class not compiled:"_pClass)
			}
			Quit
		}

		If (pRoot '= "") {
			// incremental load of children
			// follow chain in pRoot
			Set tPropName = ""
			Set tType = pClass
			For p=1:1:$L(pRoot,".") {
				Set tPropName = $P(pRoot,".",p)
				Set tType = $$$comMemberKeyGet(tType,$$$cCLASSproperty,tPropName,$$$cPROPtype)
			}
			Set tRef = pParentRef _ $S(pParentRef="":"",1:".") _ pRoot
			Set tSC = ..%GetDataSourceTree(tType, .pTree, .pParms, pLevel + 1,tRef)
			If $$$ISERR(tSC) Quit
			Quit
		}

		Set tClsType = $$$getClassType(pClass)
		Set tTopNode = ""
		Set tTopHasChildren = 0
		If (pLevel = 0) {
			// Add class to top of tree

			// check type of class
			If (tClsType '= "persistent") {
				// see if this is a DataConnector
				If ('$zobjclassmethod(pClass,"%IsA","%DeepSee.DataConnector")) {
					Set n = $I(pTree)
					Set pTree(n) = $LB($$$FormatText($$$Text("Data source must be persistent: '%1'","%DeepSee"),pClass),"",0,,,,,"color:red;")
					Set pTree(0,"ch",n) = ""
					Quit
				}
				Else {
					// Ask data connector for list of properties
					Set tSC = $zobjclassmethod(pClass,"%GetPropertyInfo",.tPropInfo)
					If $$$ISERR(tSC) Quit

					Set k = $O(tPropInfo(""))
					While (k'="") {
						Set n = $I(pTree)
						Set tName = $LG(tPropInfo(k),1)
						Set tDisplayName = $LG(tPropInfo(k),2)
						Set pTree(n) = $LB(tDisplayName,tName)
						Set pTree(0,"ch",n) = ""
						Set k = $O(tPropInfo(k))
					}

					Quit
				}
			}

			Set n = $I(pTree)
			Set tTopNode = n
			Set tExpanded = 1
			Set pTree(n) = $LB(pClass,"",tTopHasChildren,,tExpanded)
			Set pTree(0,"ch",n) = ""
		}

		Set tRootNo = +$G(pTree)
		If (tClsType = "persistent") {
			// Add %ID to list of properties
			Set n = $I(pTree)
			Set tRef = pParentRef _ $S(pParentRef="":"",1:".") _ "%ID"
			Set pTree(n) = $LB("%ID",tRef,0)
			Set pTree(tRootNo,"ch",n) = ""
			Set tTopHasChildren = 1
		}

		Set tRS = ##class(%ResultSet).%New("%Dictionary.CompiledClass.MemberSummary")
		Set tSC = tRS.%Execute(pClass,"a")
		Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(pClass)
		Set tRow = 0
		While (tRS.Next()) {
			Set tRow = tRow+1
			Set tPropName = tRS.Data("Name")
			// Get info on the property
			Set tType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tPropName,$$$cPROPtype)
			Set tPrivate = +$$$comMemberKeyGet(pClass,$$$cCLASSproperty,tPropName,$$$cPROPprivate)
			Set tTransient = +$$$comMemberKeyGet(pClass,$$$cCLASSproperty,tPropName,$$$cPROPtransient)
			Set tSqlComputed = +$$$comMemberKeyGet(pClass,$$$cCLASSproperty,tPropName,$$$cPROPsqlcomputed)
			$$$comMemberArrayGetLvar(tCaption,pClass,$$$cCLASSproperty,tPropName,$$$cXXXXparamvalue,"CAPTION")		// DTB541 - Look for a class-defined default caption for this property
			
			If 'tPrivate {
				if 'tTransient || ( tTransient && tSqlComputed) {
					Set tClsType = $$$getClassType(tType)
					Set tRef = pParentRef _ $S(pParentRef="":"",1:".") _ tPropName // _ ";" _ $S((tCaption'=""):"$$$CAPTION:"_tCaption,1:"")		// DTB541 - Send the default caption along with the value

					Set n = $I(pTree)
					Set pTree(n) = $LB(tPropName,tRef,0,,,,$S(tCaption'="":tCaption,1:tPropName))		// DTB541
					Set pTree(tRootNo,"ch",n) = ""
					Set tTopHasChildren = 1

					If ((tClsType = "persistent")||(tClsType = "serial")) {
						// mark that there are child nodes
						Set $List(pTree(n),3) = 1 	
					}
				}
			}
			If $$$ISERR(tSC) Quit
		}

		// mark if top node has children
		If ((tTopNode'="")&&(tTopHasChildren)) {
			Set $List(pTree(tTopNode),3) = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method to create and save a cube definition class. Used by Architect.
ClassMethod %SaveCubeDefinition(pClassName As %String, pSuper As %String = "", pDesc As %String, pModel As %DeepSee.Model.cube, pDomain As %String = "", pDependsOn As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pClassName = pClassName

		// open the class definition
		If (##class(%Dictionary.ClassDefinition).%ExistsId(pClassName)) {
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
			If pSuper = "" Set pSuper = tClassDefinition.Super
			#; delete the old XDATA block named Cube
			Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||Cube")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)

			#; delete the old DOMAIN parameter
			Set tIndex = tClassDefinition.Parameters.FindObjectId(pClassName_"||DOMAIN")
			If tIndex'="" Do tClassDefinition.Parameters.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = pClassName
			Set tClassDefinition.ProcedureBlock = 1
		}

		Set tClassDefinition.Super = $S(pSuper="":"%DeepSee.CubeDefinition",1:pSuper)
		Set tClassDefinition.Description = $Replace(pDesc,$C(10),$C(13,10))

		// Only use explicitly provided dependency
		Set tClassDefinition.DependsOn = pDependsOn

		// sequence number controls the order in which class members are displayed
		Set tSeqNo = 0

		#; DOMAIN param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(pClassName_":"_"DOMAIN")
		Set tParmDef.Default = pDomain
		Do tClassDefinition.Parameters.Insert(tParmDef)

		// create XData block to hold the Cube Model
		Set tCubeXData = ##class(%Dictionary.XDataDefinition).%New()
	
		Set tCubeXData.SequenceNumber = $I(tSeqNo)
		Set tCubeXData.Description = "Cube definition from Architect."
		Set tCubeXData.XMLNamespace = "http://www.intersystems.com/deepsee"

		Set tCubeXData.Name = "Cube"
		Set tCubeXData.parent = tClassDefinition

		// use XML writer to format output
		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.Indent = 1
		Set tTempStream = ##class(%Stream.TmpCharacter).%New()
		Set tSC = tWriter.OutputToStream(.tTempStream)
		// Set tSC = tWriter.OutputToString()
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.StartDocument()
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.RootObject(pModel)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.EndDocument()
		If $$$ISERR(tSC) Quit

		//Set tString = tWriter.GetXMLString()

		// contents of xdata block is the xml for the model
		//Set tSC = tCubeXData.Data.Write(tString)
		Set tSC = tCubeXData.Data.CopyFrom(tTempStream)
		If $$$ISERR(tSC) Quit

		// save the cube class
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
		Set pModel.Timestamp = $ZDT(tClassDefinition.TimeChanged,3,,6)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method to create and save a subject area definition class. Used by Architect.
ClassMethod %SaveSubjectAreaDefinition(pClassName As %String, pSuper As %String = "", pDesc As %String, pModel As %DeepSee.Model.SubjectArea.subjectArea, pDomain As %String = "", pDependsOn As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pClassName = pClassName

		// open the class definition
		If (##class(%Dictionary.ClassDefinition).%ExistsId(pClassName)) {
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
			#; delete the old XDATA block named SubjectArea
			Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||SubjectArea")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)

			#; delete the old DOMAIN parameter
			Set tIndex = tClassDefinition.Parameters.FindObjectId(pClassName_"||DOMAIN")
			If tIndex'="" Do tClassDefinition.Parameters.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = pClassName
			Set tClassDefinition.ProcedureBlock = 1
		}

		Set tClassDefinition.Super = $S(pSuper="":"%DeepSee.SubjectArea",1:pSuper)
		Set tClassDefinition.Description = $Replace(pDesc,$C(10),$C(13,10))

		// Only use explicitly provided dependency
		Set tClassDefinition.DependsOn = pDependsOn

		// sequence number controls the order in which class members are displayed
		Set tSeqNo = 0

		#; DOMAIN param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(pClassName_":"_"DOMAIN")
		Set tParmDef.Default = pDomain
		Do tClassDefinition.Parameters.Insert(tParmDef)

		// create XData block to hold the Model
		Set tCubeXData = ##class(%Dictionary.XDataDefinition).%New()
	
		Set tCubeXData.SequenceNumber = $I(tSeqNo)
		Set tCubeXData.Description = "SubjectArea definition from Architect."
		Set tCubeXData.XMLNamespace = "http://www.intersystems.com/deepsee/subjectarea"

		Set tCubeXData.Name = "SubjectArea"
		Set tCubeXData.parent = tClassDefinition

		// use XML writer to format output
		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.Indent = 1
		Set tSC = tWriter.OutputToString()
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.StartDocument()
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.RootObject(pModel)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.EndDocument()
		If $$$ISERR(tSC) Quit

		Set tString = tWriter.GetXMLString()

		// contents of xdata block is the xml for the model
		Set tSC = tCubeXData.Data.Write(tString)
		If $$$ISERR(tSC) Quit

		// save the cube class
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return a list of all currently defined DeepSee Pivots visible to the current user.
/// This is used by utilities.<br/>
/// This list takes the form:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type)<br/>
/// If <var>pHidden</var> is true, then include trash and local items.<br/>
/// If <var>pCubeName</var> is provided, then only list pivots based on it.
ClassMethod %GetPivotList(Output pList, pHidden As %Boolean = 0, pCubeName As %String = "") As %Status [ Final ]
{
	Set tSC = $$$OK
	Kill pList
	Try {
		Set tFlag = $zu(115,8,0)
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare("SELECT ID FROM %DeepSee_Dashboard.Pivot")
		If $$$ISERR(tSC) Quit
		
		Set pCubeName = $$$UPPER(pCubeName)

		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.ID '="") {
				Set tItem = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tRS.ID)
				If ($IsObject(tItem)) {
					Set tDate = $ZDTH(tItem.timeModified,3)
					Set tFullName = $P(tItem.fullName,".",1) // name without extension
					If (pHidden || ($E(tFullName,1)'="$") || ($E(tFullName,1,3)="$$$")) {
						If ((pCubeName="")||(pCubeName=$$$UPPER(tItem.cubeName))) {
							If (tItem.%CheckResource()) {
								Set pList(tItem.fullName) = $LB(tFullName,tItem.name,tDate,"pivot")
							}
						}
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

/// Return a list of all currently defined DeepSee dashboards visible to the current user.
/// This is used by utilities.<br/>
/// This list takes the form:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type) 
ClassMethod %GetDashboardList(Output pList) As %Status [ Final ]
{
	Set tSC = $$$OK
	Kill pList
	Try {
		Set tFlag = $zu(115,8,0)
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare("SELECT ID FROM %DeepSee_Dashboard.Definition")
		If $$$ISERR(tSC) Quit

		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.ID '="") {
				Set tItem = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tRS.ID)
				If ($IsObject(tItem)) {
					Set tFName = $P(tItem.folderName,"/",1)
					If (($E(tFName,1)'="$")||($E(tFName,1,3)="$$$")) {
						Set tDate = $ZDTH(tItem.timeModified,3)
						Set tFullName = $P(tItem.fullName,".",1) // name without extension
						If (tItem.%CheckResource()) {
							Set pList(tItem.fullName) = $LB(tFullName,tItem.name,tDate,"dashboard")
						}
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

/// Utility method. Convert a date value to %Date ($H) format.<br/>
/// <var>pDateType</var> indicates the incoming date format.
ClassMethod %ConvertDate(pDate As %String, pDateType As %String) As %Date
{
	Set tValue = pDate
	If (pDate'="") {
		If (pDateType = "MVDATE") {
			// multi-value date
			Set tValue = pDate + 46385
		}
		ElseIf (pDateType = "FDATE") {
			// fileman date
			Set tValue = ##class(%Library.FilemanDate).LogicalToOdbc(pDate)
			Set:tValue'="" tValue = $ZDTH(tValue,3,,,,,,,,"Invalid date")
		}
		ElseIf (pDateType = "FTIMESTAMP") {
			// fileman timestamp
			Set tValue = ##class(%Library.FilemanTimeStamp).LogicalToOdbc(pDate)
			Set:tValue'="" tValue = $ZDTH(tValue,3,,,,,,,,"Invalid date")
		}
		ElseIf (pDateType = "TIMESTAMP") {
			Set tValue = $ZDTH(pDate,3,,,,,,,,"Invalid date")
		}
		ElseIf (pDateType = "TIME") {
			Set tValue = "58074,"_pDate
		}
	}
	Quit tValue
}

/// Set the default number of background processes used by DeepSee for the group specified by <var>pType</var>.
/// Tasks executed by background agents are divided into "build" and "runTime" groups. This method can be used
/// to set a per-group limit or to set a maximum number of processes that may be active across multiple groups.
/// The limits can be set with the following value for <var>pType</var>:<br>
/// - "build" - number of agents that will be requested for a single worker group performing cube build tasks<br>
/// - "runTime" - number of agents that will be requested for queries and processing of user code such as KPIs<br>
/// - "buildMax" - the maximum number of agents that can be active for user tasks<br>
/// - "runTimeMax" - the maximum number of agents that can be active for user tasks
ClassMethod %SetAgentCount(pNumAgents As %Integer = "", pType = "build", Output pStatus As %Status) As %Integer
{
	Set pStatus = $$$OK
	
	// DTB929 - Allowed category types
	Set tTypes("build") = ""
	Set tTypes("buildMax") = ""
	Set tTypes("runTime") = ""
	Set tTypes("runTimeMax") = ""
	
	Set tOldValue = ""
	If '$D(tTypes(pType)) {
		// DTB923 - Separate settings for build and runtime
		Set pStatus = $$$ERROR($$$GeneralError,"Invalid type supplied to %SetAgentCount: " _ pType)
	}
	Else {
		// DTB929 - The routine handles all types
		Set tOldValue = $$SetAgentCount^%SYS.DeepSee(pNumAgents,pType,.pStatus)
	}
	
	Quit tOldValue
}

/// Get the current default agent count for the group specified by <var>pType</var>.
/// <var>pType</var> can be used to query any of the limits:<br>
/// - "build" - number of agents that will be requested for a single worker group performing cube build tasks<br>
/// - "runTime" - number of agents that will be requested for queries and processing of user code such as KPIs<br>
/// - "buildMax" - the maximum number of agents that can be active for build tasks<br>
/// - "runTimeMax" - the maximum number of agents that can be active for user tasks
ClassMethod %GetAgentCount(pType = "build", Output pStatus As %Status) As %Integer
{
	Set pStatus = $$$OK
	
	// DTB929 - Allowed category types
	Set tTypes("build") = ""
	Set tTypes("buildMax") = ""
	Set tTypes("runTime") = ""
	Set tTypes("runTimeMax") = ""
	
	Set tCount = ""
	// DTB923 - Separate settings for build and runtime
	If '$D(tTypes(pType)) {
		Set pStatus = $$$ERROR($$$GeneralError,"Invalid type supplied to %GetAgentCount: " _ pType)
	}
	Else {
		Set tCount = $$GetAgentCount^%SYS.DeepSee(pType)
	}

	Quit tCount
}

/// Set an entry into the DS Time index used to track changes to transactional classes.<br/>
/// This is intended for classes that use DSTIME="manual" and wish to maintain the DSTIME index
/// manually. It should be called whenever an instance of the class is inserted, updated, or deleted.<br/>
/// <var>pClassName</var> is the (case-sensitive) class name of the transactional class.<br/>
/// <var>pObjectId</var> is object id of the affected object instance.<br/>
/// <var>pAction</var> is 0 for updates, 1 for inserts, and 2 for deletes.<br/>
/// <var>pInterval</var> is the time interval value corresponding to the DSINTERVAL parameter. If this is not greater than zero then 
/// a standard DSTIME index entry is set, otherwise a DSINTERVAL index entry is set.<br>
ClassMethod %SetDSTimeIndex(pClassName As %String, pObjectId As %String, pAction As %Integer, pInterval As %Integer = 0)
{
	if +pInterval '> 0 {
		Set $$$DeepSeeUpdateBuffer(pClassName,$Get($$$DeepSeeUpdateBuffer,0),pObjectId)=pAction
	}
	else {
		$$$DSTIMEH(pClassName,pObjectId,pAction,pInterval,tDST,tDSS)
	}
}

/// Return the URL for the DeepSee management portal error page.
ClassMethod %GetErrorPageURL(pError As %String) As %String
{
	Quit "_DeepSee.UI.ErrorPage.zen?ERROR="_$ZCVT(pError,"O","URL")
}

/// Given a class name, return the set of classes projected for collection properties of the class.
ClassMethod %GetCollectionProjections(pClassname As %String, ByRef pProjectedClass As %String(MAXLEN=255)) As %Status
{
	Kill pProjectedClass
	Set tExtent = $$$comClassArrayNext(pClassname,$$$cCLASSextents,"")
	While tExtent '= "" {
		Set tProperty = $ListGet($$$comClassArrayGet(pClassname,$$$cCLASSextents,tExtent))
		If (tProperty '= "") {
			Set pProjectedClass(tProperty) = tExtent
		}
		Set tExtent = $$$comClassArrayNext(pClassname,$$$cCLASSextents,tExtent)
	}
	Quit $$$OK
}

/// Add a time interval to a given date (in $H format).<br/>
/// The interval is of the form "99y99m99d" (years, months, and days).
/// There can be a leading minus sign.
ClassMethod %AddTimeInterval(pDate As %Date, pInterval As %String) As %Date
{
	If ((pInterval="")||(pInterval="-")) Quit pDate
	If (+pDate=0) Quit ""

	Set tInterval = pInterval
	Set tDate = $ZDT(+pDate,3)
	Set tYear = +$E(tDate,1,4)
	Set tMonth = +$E(tDate,6,7)
	Set tDay = +$E(tDate,9,10)

	// double negative is positive
	If ($E(tInterval,1,2) = "--") {
		Set tInterval = $E(tInterval,3,$L(tInterval))
	}
	
	// JMD986
	// check for leading minus
	Set tSign = 1
	If ($E(tInterval,1,1) = "-") {
		Set tInterval = $E(tInterval,2,$L(tInterval))
		Set tSign = -1
	}
	Set tYearInt = 0
	If (tInterval["y") {
		Set tYearInt = +$P(tInterval,"y",1)*tSign
		Set tInterval = $P(tInterval,"y",2)
	}

	Set tMonthInt = 0
	If (tInterval["m") {
		Set tMonthInt = +$P(tInterval,"m",1)*tSign
		Set tInterval = $P(tInterval,"m",2)
	}

	Set tDayInt = 0
	If (tInterval["d") {
		Set tDayInt = +$P(tInterval,"d",1)*tSign
	}

	If (tDayInt'=0) {
		Set tDay = tDay + tDayInt
		While (tDay>..%DaysInMonth(tYear,tMonth)) {
			Set tDay = tDay - ..%DaysInMonth(tYear,tMonth)
			Set tMonth = tMonth + 1
			If (tMonth>12) {
				Set tYear = tYear + 1
				Set tMonth = tMonth - 12
			}
		}

		While (tDay<1) {
			Set tMonth = tMonth - 1
			If (tMonth<1) {
				Set tYear = tYear - 1
				Set tMonth = tMonth + 12
			}
			Set tDay = tDay + ..%DaysInMonth(tYear,tMonth)
		}
	}
	If (tMonthInt'=0) {
		Set tMonth = tMonth + tMonthInt
		While (tMonth>12) {
			Set tYear = tYear + 1
			Set tMonth = tMonth - 12
		}
		While (tMonth<1) {
			Set tYear = tYear - 1
			Set tMonth = tMonth + 12
		}
	}
	Set tYear = tYear + tYearInt

	// if new month/year is past last day of month, round off to end of month
	If (tDay>..%DaysInMonth(tYear,tMonth)) {
		Set tDay = ..%DaysInMonth(tYear,tMonth)
	}
	Quit $ZDTH(tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero(tDay,2),3)
}

/// Return number of days in the given year and month.
ClassMethod %DaysInMonth(y, m) As %Integer
{
	Quit $Case(m,1:31,2:$S(..%IsLeapYear(y):29,1:28),3:31,4:30,5:31,6:30,7:31,8:31,9:30,10:31,11:30,12:31,:0)
}

/// Return number of days in the given year and month.
ClassMethod %HijriDaysInMonth(y = "", m = "", calendar = "hijriTabular") As %Integer
{
	// Added by DTB180
	Try {
		Set tFormat = $Case(calendar,"hijriTabular":19,"hijriObserved":21,:19)		// DTB182 - Add support for observed hijri

		Set tDayCount = ""
		If ((+y>0)&&(+m>0)) {
			// DTB242 - Protect against improper arguments
			Set tTestDate = $ZDTH("29 "_m_" "_y,tFormat)
			Set tTestDate = +tTestDate+1
			Set tTestDate = $ZDT(tTestDate,tFormat)
			Set tMonth = $P(tTestDate," ",2)
			Set tDayCount = $S((tMonth=m):30,1:29)
		}
	}
	Catch ex {
		// DTB872 - Try/Catch/Throw a more informative error 
		$$$ThrowStatus($System.Status.AppendStatus(ex.AsStatus(),$$$ERROR($$$GeneralError,"Error in %HijriDaysInMonth inputs: y="_y_", m="_m)))
	}

	Quit tDayCount
	
	//Quit $Case(m,1:30,2:29,3:30,4:29,5:30,6:29,7:30,8:29,9:30,10:29,11:30,12:$S(..%IsHijriLeapYear(m):30,1:29),:0)
}

/// Add a time interval to a given date (in $H format).<br/>
/// The interval is of the form "99y99m99d" (years, months, and days).
/// There can be a leading minus sign.
ClassMethod %AddHijriTimeInterval(pDate As %Date, pInterval As %String, pCalendar As %String = "hijriTabular") As %Date
{
	If ((pInterval="")||(pInterval="-")) Quit pDate
	If (+pDate=0) Quit ""
	
	Set tFormat = $Case(pCalendar,"hijriTabular":19,"hijriObserved":21,:19)		// DTB182 - Add support for observed hijri

	Set tInterval = pInterval
	Set tDate = $ZDT(+pDate,tFormat)
	Set tDay = $P(tDate," ",1)
	Set tMonth = $P(tDate," ",2)
	Set tYear = $P(tDate," ",3)

	// double negative is positive
	If ($E(tInterval,1,2) = "--") {
		Set tInterval = $E(tInterval,3,$L(tInterval))
	}
	
	// JMD986
	// check for leading minus
	Set tSign = 1
	If ($E(tInterval,1,1) = "-") {
		Set tInterval = $E(tInterval,2,$L(tInterval))
		Set tSign = -1
	}

	Set tYearInt = 0
	If (tInterval["y") {
		Set tYearInt = +$P(tInterval,"y",1)*tSign
		Set tInterval = $P(tInterval,"y",2)
	}

	Set tMonthInt = 0
	If (tInterval["m") {
		Set tMonthInt = +$P(tInterval,"m",1)*tSign
		Set tInterval = $P(tInterval,"m",2)
	}

	Set tDayInt = 0
	If (tInterval["d") {
		Set tDayInt = +$P(tInterval,"d",1)*tSign
	}

	If (tDayInt'=0) {
		Set tOffsetDate = pDate + tDayInt
		Set tDate = $ZDT(+tOffsetDate,tFormat)
		Set tDay = $P(tDate," ",1)
		Set tMonth = $P(tDate," ",2)
		Set tYear = $P(tDate," ",3)
	}
	If (tMonthInt'=0) {
		Set tMonth = tMonth + tMonthInt
		While (tMonth>12) {
			Set tYear = tYear + 1
			Set tMonth = tMonth - 12
		}
		While (tMonth<1) {
			Set tYear = tYear - 1
			Set tMonth = tMonth + 12
		}
	}
	Set tYear = tYear + tYearInt

	// if new month/year is past last day of month, round off to end of month
	If (tDay>..%HijriDaysInMonth(tYear,tMonth,pCalendar)) {
		Set tDay = ..%HijriDaysInMonth(tYear,tMonth,pCalendar)	 // DTB180
	}
	Quit $ZDTH(tDay_" "_tMonth_" "_tYear,tFormat)
}

/// Return whether the given year is a leap year.
ClassMethod %IsLeapYear(y) As %Boolean
{
	// DTB181 - Reject anything non-numeric
	Set tIsValidYear = y?.4N
	If 'tIsValidYear Quit 0
	
	If ((y#4) = 0) {
		If '(((y#100) = 0) && ((y#400) '= 0)) {
			Quit 1
		}
	}
	Quit 0
}

/// Return whether the given year is a leap year.
ClassMethod %IsHijriLeapYear(y, calendar = "hijriTabular") As %Boolean
{
	// DTB181 - Reject anything non-numeric
	Set tIsValidYear = y?.4N
	If 'tIsValidYear Quit 0
	
	Set tFormat = $Case(calendar,"hijriTabular":19,"hijriObserved":21,:19)		// DTB182 - Add support for observed hijri
	
	Set tTestDate = $ZDTH("29 12 "_y,tFormat)
	Set tTestDate = +tTestDate+1
	Set tTestDate = $ZDT(tTestDate,tFormat)
	Set tMonth = $P(tTestDate," ",2)
	Quit (tMonth=12)
}

/// Format a date value (in $H format) according to the format in <var>pFormat</var>.<br/>
/// The format string can contain:<br/>
/// "y" - Year number (4 digits).<br/>
/// "q" - Quarter number.<br/>
/// "m" - Month number, with no leading zero.<br/>
/// "mm" - Month number, with leading zero.<br/>
/// "mmm" - Short name of month (using server locale).<br/>
/// "mmmm" - Long name of month (using server locale).<br/>
/// "d" - Day number, with no leading zero.<br/>
/// "dd" - Day number, with leading zero.<br/>
/// "ddd" - Short name of day (using server locale).<br/>
/// "dddd" - Long name of day (using server locale).<br/>
/// "\x" - display character "x"<br/>
/// " " - space<br/>
/// "/" - "/" <br/>
/// "-" - "-" <br/>
/// "." - "." <br/>
ClassMethod %FormatDate(pDate As %Date, pFormat As %String = "") As %String
{
	If (+pDate=0) Quit ""
	If (pFormat="") Quit $ZDT(+pDate,3)
	Set tOut = ""

	Set tDate = $ZDT(pDate,3)
	For p=1:1:$L(pFormat) {
		Set fc = $E(pFormat,p)
		If (fc="\") {
			// escaped literal
			Set p = p + 1
			Set fc = $E(pFormat,p)
			Set tOut = tOut _ fc
		}
		ElseIf ((fc=" ")||(fc="/")||(fc="-")||(fc=".")||(fc=",")||(fc=";")||(fc=":")) {
			// literal
			Set tOut = tOut _ fc
		}
		Else {
			Set k = p + 1
			Set fx = fc
			While ($E(pFormat,k)=fc) {
				Set fx = fx _ fc
				Set p = p + 1
				Set k = p + 1
			}
			If (fc = "y") {
				// year #
				Set tOut = tOut _ $E(tDate,1,4)
			}
			ElseIf (fc = "q") {
				// quarter #
				Set tOut = tOut _ (1+(((+$E(tDate,6,7)-1)\3)))
			}
			ElseIf (fx = "m") {
				// month #, no zero
				Set tOut = tOut _ +$E(tDate,6,7)
			}
			ElseIf (fx = "mm") {
				// month #, with zero
				Set tOut = tOut _ $E(tDate,6,7)
			}
			ElseIf (fx = "mmm") {
				// month short name
				Set tOut = tOut _ $E($ZDT(pDate,5),1,3)
			}
			ElseIf (fx = "mmmm") {
				// month full name
				Set tOut = tOut _ $P($ZDT(pDate,9)," ")
			}
			ElseIf (fx = "d") {
				// day, no zero
				Set tOut = tOut _ +$E(tDate,9,10)
			}
			ElseIf (fx = "dd") {
				// day, with zero
				Set tOut = tOut _ $E(tDate,9,10)
			}
			ElseIf (fx = "ddd") {
				// day, short name
				Set tOut = tOut _ $E($ZDT(pDate,11),1,3)
			}
			ElseIf (fx = "dddd") {
				// day, full name
				Set tOut = tOut _ $P($ZDT(pDate,12)," ")
			}
		}
	}
	Quit tOut
}

/// Unformat a date value according to the given format and convert to $H (or "").<br/>
/// See <method>%FormatDate</method> for information on formats.
ClassMethod %UnformatDate(pValue As %String, pFormat As %String = "") As %Date
{
	If (pValue="") Quit ""
	If (pFormat="") Quit $ZDTH(pValue,3)

	Set tDate = ""
	Set tYear = ""
	Set tMonth = ""
	Set tDay = ""

	Set n = 1
	For p=1:1:$L(pFormat) {
		Set fc = $E(pFormat,p)
		If (fc="\") {
			// escaped literal
			Set p = p + 1
			Set fc = $E(pFormat,p)
			If ($$$UPPER($E(pValue,n))'=$$$UPPER(fc)) {
				// literal has to match (or we may be ambiguous)
				Set tYear = ""
				Quit
			}
			Set n = n + 1
		}
		ElseIf ((fc=" ")||(fc="/")||(fc="-")||(fc=".")||(fc=",")||(fc=";")||(fc=":")) {
			If ($E(pValue,n)'=fc) {
				Set tYear = ""
				Quit
			}
			Set n = n + 1
		}
		Else {
			Set k = p + 1
			Set fx = fc
			While ($E(pFormat,k)=fc) {
				Set fx = fx _ fc
				Set p = p + 1
				Set k = p + 1
			}
			Set tDel=$E(pFormat,k) // JSL4491
			If (fc = "y") {
				// year #
				Set tYear = +$ZSTRIP($E(pValue,n,$L(pValue)),"<>W")\1  // JSL4491 year starts at n and we want natural number (Z+) that starts at n.  
																	   // JSL4491 + operator gives us a number of form a.b and \1 removes the .b if it exists
				Set n = n + $L(tYear)
			}
			ElseIf (fc = "q") {
				// quarter #
				Set q = +$E(pValue,n,n+1)
				Set n = n + $L(q)
				Set tMonth = ((q-1)*3)+1
			}
			ElseIf (fx = "m") {
				Set tMonth = +$E(pValue,n,n+1)
				Set n = n + $L(tMonth)
			}
			ElseIf (fx = "mm") {
				Set tMonth = +$E(pValue,n,n+1)
				Set n = n + 2
			}
			ElseIf (fx = "mmm") {
				Set tName = $E(pValue,n,n+2)
				Set d = $ZDTH(tName_" 1 2000",6)
				Set:d'="" tMonth = +$E($ZDT(d,3),6,7)
				Set n = n + 3
			}
			ElseIf (fx = "mmmm") {
				Set tName = $S((tDel'=""):$P($E(pValue,n,$L(pValue)),tDel,1),1:$E(pValue,n,$L(pValue))) // DTB344 = Account for case with no delimiter
				Set d = $ZDTH(tName_" 1, 2000",9)
				Set:d'="" tMonth = +$E($ZDT(d,3),6,7)
				Set n = n + $L(tName)
			}
			ElseIf (fx = "d") {
				Set tDay = +$E(pValue,n,n+1)
				Set n = n + $L(tDay)
			}
			ElseIf (fx = "dd") {
				Set tDay = +$E(pValue,n,n+1)
				Set n = n + 2
			}
			ElseIf (fx = "ddd") {
				Set tName = $E(pValue,n,n+2)
				Set n = n + 3
			}
			ElseIf (fx = "dddd") {
				Set tName = $S((tDel'=""):$P($E(pValue,n,$L(pValue)),tDel,1),1:$E(pValue,n,$L(pValue))) // DTB344 = Account for case with no delimiter
				Set n = n + $L(tName)
			}
		}
	}

	Set:+tYear<1841 tYear=1841
	Set:+tMonth<1 tMonth=1
	Set:+tDay<1 tDay=1

	Quit:tYear="" ""
	
	Set tDate = tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero(tDay,2)
	Quit $ZDTH(tDate,3,,,,,,,,"")
}

/// Format a date value (in partial date ODBC format) according to the format in <var>pFormat</var>.<br/>
/// The format string can contain:<br/>
/// "y" - Year number (4 digits).<br/>
/// "q" - Quarter number.<br/>
/// "m" - Month number, with no leading zero.<br/>
/// "mm" - Month number, with leading zero.<br/>
/// "mmm" - Short name of month (using server locale).<br/>
/// "mmmm" - Long name of month (using server locale).<br/>
/// "d" - Day number, with no leading zero.<br/>
/// "dd" - Day number, with leading zero.<br/>
/// "ddd" - Short name of day (using server locale).<br/>
/// "dddd" - Long name of day (using server locale).<br/>
/// "\x" - display character "x"<br/>
/// " " - space<br/>
/// "/" - "/" <br/>
/// "-" - "-" <br/>
/// "." - "." <br/>
/// Missing pieces are replaced with the localized text "Unknown".
ClassMethod %FormatPartialDate(pDate As %String = "", pFormat As %String = "") As %String
{
	// Method added by DTB685
	Try {
		If (+pDate=0) {
			Set tOut = ""
			Quit
		}
		
		Set tUnknownText = $$$Text("Unknown")		// String to be inserted when a date piece is missing
		
		Set tDate = pDate
		
		// Look at the partial date and rebuild a complete ODBC-formatted stand-in
		// if the date is truly partial
		Set tYear = $P(tDate,"-",1)
		Set tMonth = $P(tDate,"-",2)
		Set tDay = $P(tDate,"-",3)
		Set tMonthNull = 0
		Set tDayNull = 0
		
		// Account for null months and days
		If (tMonth="")||(tMonth="00") {
			Set tMonthNull = 1
			Set tMonth = "01"
		}
		If (tDay="")||(tDay="00") {
			Set tDayNull = 1
			Set tDay = "01"
		}
		If (tMonthNull||tDayNull) {
			Set tDate = tYear _ "-" _ tMonth _ "-" _ tDay
		}
		Set tDateH = $ZDH(tDate,3)
		
		Set tOut = ""

		// If no format is supplied, return the original key with "Unknown" substitutes
		If (pFormat="") {
			Set tOut = tYear _ "-" _ $S(tMonthNull:tUnknownText,1:tMonth) _ "-" _ $S(tDayNull:tUnknownText,1:tDay)
			Quit
		}
		
		For p=1:1:$L(pFormat) {
			Set fc = $E(pFormat,p)
			If (fc="\") {
				// escaped literal
				Set p = p + 1
				Set fc = $E(pFormat,p)
				Set tOut = tOut _ fc
			}
			ElseIf ((fc=" ")||(fc="/")||(fc="-")||(fc=".")||(fc=",")||(fc=";")||(fc=":")) {
				// literal
				Set tOut = tOut _ fc
			}
			Else {
				Set k = p + 1
				Set fx = fc
				While ($E(pFormat,k)=fc) {
					Set fx = fx _ fc
					Set p = p + 1
					Set k = p + 1
				}
				If (fc = "y") {
					// year #
					Set tOut = tOut _ $E(tDate,1,4)
				}
				ElseIf (fc = "q") {
					// quarter #
					Set tOut = tOut _ (1+(((+$E(tDate,6,7)-1)\3)))
				}
				ElseIf (fx = "m") {
					// month #, no zero
					//Set tOut = tOut _ $S(tMonthNull:$$$Text("Unknown"),1:+$E(tDate,6,7))
					Set tOut = tOut _ $S(tMonthNull:"0",1:+$E(tDate,6,7))
				}
				ElseIf (fx = "mm") {
					// month #, with zero
					//Set tOut = tOut _ $S(tMonthNull:$$$Text("Unknown"),1:$E(tDate,6,7))
					Set tOut = tOut _ $S(tMonthNull:"00",1:$E(tDate,6,7))
				}
				ElseIf (fx = "mmm") {
					// month short name
					//Set tOut = tOut _ $S(tMonthNull:$$$Text("Unknown"),1:$E($ZDT(tDateH,5),1,3))
					Set tOut = tOut _ $S(tMonthNull:$E($$$Text("Unknown"),1,3),1:$E($ZDT(tDateH,5),1,3))
				}
				ElseIf (fx = "mmmm") {
					// month full name
					Set tOut = tOut _ $S(tMonthNull:$$$Text("Unknown"),1:$P($ZDT(tDateH,9)," "))
				}
				ElseIf (fx = "d") {
					// day, no zero
					//Set tOut = tOut _ $S(tDayNull:$$$Text("Unknown"),1:+$E(tDate,9,10))
					Set tOut = tOut _ $S(tDayNull:"0",1:+$E(tDate,9,10))
				}
				ElseIf (fx = "dd") {
					// day, with zero
					//Set tOut = tOut _ $S(tDayNull:$$$Text("Unknown"),1:$E(tDate,9,10))
					Set tOut = tOut _ $S(tDayNull:"00",1:$E(tDate,9,10))
				}
				ElseIf (fx = "ddd") {
					// day, short name
					//Set tOut = tOut _ $S(tDayNull:$$$Text("Unknown"),1:$E($ZDT(tDateH,11),1,3))
					Set tOut = tOut _ $S(tDayNull:$E($$$Text("Unknown"),1,3),1:$E($ZDT(tDateH,11),1,3))
				}
				ElseIf (fx = "dddd") {
					// day, full name
					Set tOut = tOut _ $S(tDayNull:$$$Text("Unknown"),1:$P($ZDT(tDateH,12)," "))
				}
			}
		}
	}
	Catch ex {
		Set tOut = pDate
	}

	Quit tOut
}

/// Unformat a date value according to the given format and convert to $H (or "").<br/>
/// See <method>%FormatDate</method> for information on formats.
ClassMethod %UnformatPartialDate(pValue As %String, pFormat As %String = "") As %Date
{
	// Method added by DTB685
	If (pValue="") Quit ""
	If (pFormat="") Quit $ZDTH(pValue,3)

	Set tDate = ""
	Set tYear = ""
	Set tMonth = ""
	Set tDay = ""

	Set tUnknownText = $$$Text("Unknown")

	Set n = 1
	For p=1:1:$L(pFormat) {
		Set fc = $E(pFormat,p)
		If (fc="\") {
			// escaped literal
			Set p = p + 1
			Set fc = $E(pFormat,p)
			If ($$$UPPER($E(pValue,n))'=$$$UPPER(fc)) {
				// literal has to match (or we may be ambiguous)
				Set tYear = ""
				Quit
			}
			Set n = n + 1
		}
		ElseIf ((fc=" ")||(fc="/")||(fc="-")||(fc=".")||(fc=",")||(fc=";")||(fc=":")) {
			If ($E(pValue,n)'=fc) {
				Set tYear = ""
				Quit
			}
			Set n = n + 1
		}
		Else {
			Set k = p + 1
			Set fx = fc
			While ($E(pFormat,k)=fc) {
				Set fx = fx _ fc
				Set p = p + 1
				Set k = p + 1
			}
			Set tDel=$E(pFormat,k) // JSL4491
			If (fc = "y") {
				// year #
				Set tYear = +$ZSTRIP($E(pValue,n,$L(pValue)),"<>W")\1  // JSL4491 year starts at n and we want natural number (Z+) that starts at n.  
																	   // JSL4491 + operator gives us a number of form a.b and \1 removes the .b if it exists
				Set n = n + $L(tYear)
			}
			ElseIf (fc = "q") {
				// quarter #
				Set q = +$E(pValue,n,n+1)
				Set n = n + $L(q)
				Set tMonth = ((q-1)*3)+1
			}
			ElseIf (fx = "m") {
				Set tMonth = $E(pValue,n,n+1)
				
				If tMonth="0" {
					Set tMonth = "00"
					Set n = n + 1
				}
				Else {
					Set tMonth = +tMonth
					Set n = n + $L(tMonth)	
				}
			}
			ElseIf (fx = "mm") {
				Set tMonth = $E(pValue,n,n+1)
				
				If tMonth="00" {
					Set tMonth = "00"
					Set n = n + 2
				}
				Else {
					Set tMonth = +tMonth
					Set n = n + 2	
				}
			}
			ElseIf (fx = "mmm") {
				Set tName = $E(pValue,n,n+2)
				
				If tName=$E(tUnknownText,1,3) {
					Set tMonth="00"
					Set n = n + 3
				}
				Else {
					Set d = $ZDTH(tName_" 1 2000",6)
					Set:d'="" tMonth = +$E($ZDT(d,3),6,7)
					Set n = n + 3
				}
			}
			ElseIf (fx = "mmmm") {
				Set tName = $S((tDel'=""):$P($E(pValue,n,$L(pValue)),tDel,1),1:$E(pValue,n,$L(pValue))) // DTB344 = Account for case with no delimiter
				
				If tName=$E(tUnknownText) {
					Set tMonth = "00"
					Set n = n + $L(tUnknownText)
				}
				Else {
					Set d = $ZDTH(tName_" 1, 2000",9)
					Set:d'="" tMonth = +$E($ZDT(d,3),6,7)
					Set n = n + $L(tName)
				}
			}
			ElseIf (fx = "d") {
				Set tDay = $E(pValue,n,n+1)
				
				If tDay="0" {
					Set tDay = "00"
					Set n = n + 1
				}
				Else {
					Set tDay = +tDay
					Set n = n + $L(tDay)	
				}	
			}
			ElseIf (fx = "dd") {
				Set tDay = $E(pValue,n,n+1)
				
				If tDay="00" {
					Set tDay = "00"
					Set n = n + 2
				}
				Else {
					Set tDay = +tDay
					Set n = n + 2	
				}
			}
			ElseIf (fx = "ddd") {
				// DTB - This is indeterminate in the unformatting direction!
				Set tName = $E(pValue,n,n+2)
				
				If tName=$E(tUnknownText,1,3) {
					Set tDay = "00"
					Set n = n + 3
				}
				Else {
					Set tDay = tName
					Set n = n + 3	
				}
			}
			ElseIf (fx = "dddd") {
				// DTB - This is indeterminate in the unformatting direction!
				Set tName = $S((tDel'=""):$P($E(pValue,n,$L(pValue)),tDel,1),1:$E(pValue,n,$L(pValue))) // DTB344 = Account for case with no delimiter
				
				If tName=$E(tUnknownText) {
					Set tDay = "00"
					Set n = n + $L(tUnknownText)
				}
				Else {
					Set tDay = tName
					Set n = n + $L(tName)	
				}
			}
		}
	}

	Set:+tYear<1841 tYear=1841
	Set:(tMonth'="00")&&(+tMonth<1) tMonth=1
	Set:(tDay'="00")&&(+tDay<1) tDay=1

	Quit:tYear="" ""
	
	Set tDate = tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero(tDay,2)
	Quit tDate
}

/// Method to convert day of week name to a number from 1 to 7 <br> 
///   pDayName: full day name (e.g. Monday) or day short name (e.g. Mon)<br>
///   pFullName: If true pDayName is the full day name: if false, pDayName is the short day name<br>
///   pLocale: if not specified, default to current locale.<br>
ClassMethod %DayOfWeekToNumber(pDayName, pFullName As %Boolean = 1, pLocale As %String = "")
{
	// Method added by DTB392
	set pDayName = $ZCONVERT($g(pDayName),"U")
	// Get the day names for the locale (uses current locale if locale = "")
	Set tFmt=##class(%SYS.NLS.Format).%New(pLocale)
	if pFullName {
		Set tDays=tFmt.WeekdayName
	} Else {
		Set tDays=tFmt.WeekdayAbbr
	}
	set tDays=$ZCONVERT(tDays,"U")
	// Convert to $list format
	set tDaysList =$listfromstring($p(tDays," ",2,*)," ")
	set tDayNumber=$listfind(tDaysList,pDayName)
	if tDayNumber'=0 {
		// tFirstDayofWeek = 0 to 6 (Sunday to Saturday)
		set tFirstDayOfWeek=(-(##class(%SYSTEM.SQL.Functions).DAYOFWEEK(62997)-1)#7 + 1 )#7
		// adjust tDayNumber based on tFirstDayOfWeek
		set tDayNumber=tDayNumber-1-tFirstDayOfWeek#7+1
	} Else {
		set tDayNumber=""
	}
	quit tDayNumber
}

/// Invoke the DeepSee command line shell.
ClassMethod %Shell()
{
	Do $System.Process.NewLineRecallContext("MDX")
	Do ##class(%DeepSee.Shell).%Go()
}

/// Programmatic API for updating the value of a dimension property after a cube has been built.</br>
/// <example language="cache">
/// Set tSC = ##class(%DeepSee.Utils).%UpdateDimensionProperty(
/// 	"Holefoods","[Outlet].[H1].[Region].&[Asia]","Asia2")
/// </example>
/// It takes the following arguments:<br/>
/// <var>pCubeName</var>-name of the cube.<br/>
/// <var>pSpec</var>-specification of member to update as an MDX expression. This must completely specify a level and a single key value
/// within the level. For example: "[Product].[P1].[Product Category].&[Candy]"<br/>
/// You can set the value of a dimension property by adding Properties(propName) to the end of the spec:
/// "[Outlet].[H1].[City].&[23].Properties(""Population"")"
/// <var>pValue</var>-if defined, this is new NAME value for a dimension member or the value to use for a dimension property.<br/>
/// <var>pKey</var>-if defined, this is new KEY value for a dimension member. Ignored for a dimension property.<br/>
/// There a number of restrictions on this method:<br/>
/// You cannot update a time dimension.<br/>
/// You cannot update a member of relationship.<br/>
/// You cannot update a level property whose isReference is true.<br/>
ClassMethod %UpdateDimensionProperty(pCubeName As %String, pSpec As %String, pValue As %String, pKey As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// Get info on the specified dimension
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCubeName,pSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo)
		If $$$ISERR(tSC) Quit

		If ('$D(pValue)&&'$D(pKey)) {
			Set tSC = $$$ERROR($$$GeneralError,"Either pValue or pKey must be defined for %UpdateDimensionProperty")
			Quit
		}

		If (tRelationName'="") {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty cannot be used with a relationship")
			Quit
		}

		Set tCube = $$$UPPER(pCubeName)
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)		// DTB838
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo))
		Set tClass = $LG(tInfo,6)

		If (($LG(tInfo,1)'="l")||(tClass="")) {
			Set tSC = $$$ERROR($$$GeneralError,"pSpec does not refer to a valid level")
			Quit
		}

		If $zobjclassmethod(tClass,"%IsA","%DeepSee.ComputedDimension.Base") {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty cannot be called on a computed dimension")
			Quit
		}
		ElseIf $zobjclassmethod(tClass,"%IsA","%DeepSee.Time.AbstractLevel") {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty cannot be called on a time dimension")
			Quit
		}
		// now find specific member within level
		// assume least member of spec is key
		Set k = $O(tSpecInfo(""),-1)
		Set tKey = $S(k="":"",1:$G(tSpecInfo(k)))

		// test for Properties()
		Set tPropName = ""
		If ($$$UPPER($E(tKey,1,12))="PROPERTIES(""") {
			Set tPropName = $P($$$UPPER(tKey),"PROPERTIES(""",2)
			Set tPropName = $P(tPropName,""")",1)
			Set k = $O(tSpecInfo(k),-1)
			Set tKey = $S(k="":"",1:$G(tSpecInfo(k)))
		}

		// get info on dimension table and create SQL statement
		Set tExists = ##class(%DeepSee.Query.member).%GetNodeInfo(pCubeName,tDimNo, tHierNo, tLevelNo, .tFact, .tStarClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,,.tStarKeyField)
		If ('tExists) {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty invalid dimension")
			Quit
		}
		If (tStarKeyField="") {
			Set tStarKeyField = "%ID"
		}
		If (tStarField="") {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty: this dimension cannot be updated")
			Quit
		}
		Set tStarTable = ##class(%DeepSee.Utils).%GetSQLTableName(tStarClass)
		If (tStarTable = "") {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty: Dimension table missing or not found: '" _ tStarClass _ "'")
			Quit
		}

		// See if key exists
		Set tSQL = "SELECT %ID FROM " _ tStarTable _ " WHERE "_tStarKeyField_" =?"
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) Quit

		Set tID = ""
		Set tRS = tStatement.%Execute(tKey)
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tID = tRS.ID
			Quit
		}

		If (tID="") {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty: Key not found in dimension table: '" _ tKey _ "'")
			Quit
		}

		// update
		Set tFieldList = ""

		Set tPropField = ""
		If (tPropName'="") {
			Set tPropInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tDimNo,tHierNo,tLevelNo,"prop",tPropName))
			Set tPropField = $LG(tPropInfo,3)
			If (tPropField="") {
				Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty: Property not found in dimension table: '" _ tPropName _ "'")
				Quit
			}
			Set tFieldList = tFieldList _ $S(tFieldList="":"",1:",") _ tPropField_"='"_$$$iscEscapeSQL($G(pValue))_"'"
		}
		Else {
			If $D(pValue) {
				Set tFieldList = tFieldList _ $S(tFieldList="":"",1:",") _ tStarField_"='"_$$$iscEscapeSQL(pValue)_"'"
			}
			If $D(pKey) {
				Set tFieldList = tFieldList _ $S(tFieldList="":"",1:",") _ tStarKeyField_"='"_$$$iscEscapeSQL(pKey)_"'"
			}
		}

		Set tSQL = "UPDATE " _ tStarTable _ " SET "_tFieldList_" WHERE %ID = '"_tID_"'"
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) Quit

		Set tRS = tStatement.%Execute()
		If (tRS.%SQLCODE'=0) {
			Set tSC = $$$ERROR($$$GeneralError,"%UpdateDimensionProperty: update of dimension table failed: "_ tRS.%SQLCODE)
			Quit
		}
		
		// DTB838 - If successful, advance the DSTIME update counter to signal an update has been recorded
		Set:(##class(%DeepSee.Utils).%GetCubeDSTime(tCubeIndex)=+$G($$$DeepSeeUpdateQueue)) tTimeStamp = $I($$$DeepSeeUpdateQueue)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Write the cube dependency graph for the given cube.
ClassMethod %WriteDependencyGraph(pCubeName As %String)
{
	Do ..%GetDependencyGraph(.tGraph,pCubeName)
	Set tCube1 = $O(tGraph(""))
	While (tCube1'="") {
		Set tCube2 = $O(tGraph(tCube1,""))
		While (tCube2'="") {
			Write "Cube ",tCube1," depends on ",tCube2,!
			Set tCube2 = $O(tGraph(tCube1,tCube2))
		}
		Set tCube1 = $O(tGraph(tCube1))
	}
}

/// Get the cube dependency graph for the given cube:
/// pGraph(cube, dependentCube) = ""
ClassMethod %GetDependencyGraph(ByRef pGraph, pCubeName As %String, pDirection As %String = "", pLevel As %Integer = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $$$UPPER(pCubeName)
		Kill:pDirection="" pGraph

		// find all cubes that depend on this one
		Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tCube,"relations",""))
		While (tRelation'="") {
			Set tOtherCube = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",tCube,"relations",tRelation,"relatedCube")))
			Set tIsStored = $G($$$DeepSeeMetaGLVN("cubes",tCube,"relations",tRelation,"storedSide"))
			
			If (tIsStored && (pDirection'="up")) {
				// this cube is dependent on the other one
				Set pGraph(tCube,tOtherCube) = pLevel
				// recurse down
				If '$D(pGraph(tOtherCube)) {
					Set tSC = ..%GetDependencyGraph(.pGraph, tOtherCube, "down", pLevel+1)
				}
			}
			ElseIf ('tIsStored && (pDirection'="down")) {
				// this cube is independent of the other one
				// recurse up
				If '$D(pGraph(tOtherCube)) {
					Set tSC = ..%GetDependencyGraph(.pGraph, tOtherCube, "up", pLevel-1)
				}
				Set pGraph(tOtherCube,tCube) = pLevel
			}
			Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tCube,"relations",tRelation))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a cube and a source property name, return the list of dimension tables
/// that make use of the source property.
ClassMethod %FindDimensionTableForProperty(pCubeName As %String, pSourceProp As %String, Output pList) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pList
		Set tCube = $$$UPPER(pCubeName)
		Set tSourceProp = $$$UPPER(pSourceProp)

		Set j = $O($$$DeepSeeMetaGLVN("cubes",tCube,"star",""))
		While (j'="") {
			Set k = $O($$$DeepSeeMetaGLVN("cubes",tCube,"star",j,"prop",""))
			While (k'="") {
				Set tSource = $G($$$DeepSeeMetaGLVN("cubes",tCube,"star",j,"prop",k,"source"))
				If ($$$UPPER(tSource)=tSourceProp) {
					Set pList(j) = ""
				}
				Set k = $O($$$DeepSeeMetaGLVN("cubes",tCube,"star",j,"prop",k))
			}
			Set j = $O($$$DeepSeeMetaGLVN("cubes",tCube,"star",j))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of standard paper sizes in the form:<br/>
/// pList(n) = $LB(name,size)<br/>
/// Where size is "WxH units", e.g., "8.5x11 in"
ClassMethod %GetPaperSizeList(Output pList) As %Status [ Internal ]
{
	// list of page sizes
	Set pList($I(n)) = $LB($$$Text("Letter","%DeepSee"),"8.5x11 in")
	Set pList($I(n)) = $LB($$$Text("Legal","%DeepSee"),"8.5x14 in")
	Set pList($I(n)) = $LB($$$Text("Statement","%DeepSee"),"5.5x8.5 in")
	Set pList($I(n)) = $LB($$$Text("Executive","%DeepSee"),"7.25x10.5 in")
	Set pList($I(n)) = $LB("11x17","11x17 in")
	Set pList($I(n)) = $LB("A2","420x594 mm")
	Set pList($I(n)) = $LB("A3","297x420 mm")
	Set pList($I(n)) = $LB("A4","210x297 mm")
	Set pList($I(n)) = $LB("A5","148x210 mm")
	Set pList($I(n)) = $LB("A6","105x148 mm")

	// merge in user-extensions
	// ^DeepSee.PaperSizes(n) = $LB(name,dimensions)
	Set k = $O(^DeepSee.PaperSizes(""))
	While (k'="") {
		Set pList($I(n)) = $G(^DeepSee.PaperSizes(k))
		Set k = $O(^DeepSee.PaperSizes(k))
	}

	Quit $$$OK
}

/// Export a DeepSee query or KPI to the file <var>pFile</var> in CSV format.<br/>
/// <var>pParms</var> controls the content and display of the export.<br/>
/// pParms("TITLE") = title<br/>
/// pParms("SUBTITLE") = subtitle<br/>
/// pParms("SHOWDATE") = "on" (includes current date and time in the export)</br><br>
/// Data export should rely on either a base MDX query or an available KPI.<br>
/// pParms("MDX") = MDX Statement to execute<br/>
/// pParms("KPI") = KPI class name<br/>
/// Exports operating in MDX mode expect filter clauses to be included in the query. When filters are being applied to the KPI class,
/// they may be provided in the array:<br/>
/// pParms("FILTER",<var>filterName</var>) = <var>filterValue</var><br/>
/// Filters can optionally be included as a printed table in the export, provided by the FILTERNAMES and FILTERVALUES parameters:<br/>
/// pParms("FILTERNAMES") = A $C(10)-delimited list of filter names to display<br/>
/// pParms("FILTERVALUES") = A $C(10)-delimited list of filter values to display<br/><br/>
/// Defined listings can be applied to a resultset using:<br/>
/// pParms("LISTINGNAME") = Name of a listing to execute.<br/> A KPI must support use of a named listing or else this will be ignored. 
/// An MDX query must be in DRILLTHROUGH mode and the cube must have that listing defined for the listing to be applied.<br/><br/>
ClassMethod %ExportExcelToFile(pFile As %String, ByRef pParms As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		New %session,%request,%response
		Set %request = ##class(%CSP.Request).%New()
		Set %response = ##class(%CSP.Response).%New()
		Set %session = ##class(%CSP.Session).%New(666)
		
		// DTB362 - Test the MDX query to see if there are
		// early indications there will be a problem
		If $G(pParms("MDX"))'="" {
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX($G(pParms("MDX")))
			If $$$ISERR(tSC) Quit
		}
		
		// Apply parameters to the export by adding them to the request object.
		Set k = $O(pParms(""),1,tValue)
		While (k'="") {
			If (k="MDX") {
				// DP-406616 - The query itself has its own nonce location 
				Set %request.Data("NONCE",1) = ..%CreateQueryNonce(tValue)
			}
			ElseIf (k="FILTER") {
				// DP-411626 - A FILTER array has been provided in the parameters. Pass these to the document provider via the request.
				For {
					Set tFilterName = $O(pParms("FILTER",$G(tFilterName)),1,tFilterValue)
					Quit:(tFilterName="")

					Set %request.Data("FILTER",$I(tFilterIdx)) = ..%CreateParameterNonce(tFilterName _ ":" _ $G(tFilterValue))
				}
			}
			Else {
				// DP-406616 - For all remaining parameters, consult the macro for which parameters need to be nonced
				Set %request.Data(k,1) = $S($$$dsExportNonceUrl(k):..%CreateParameterNonce(tValue),1:tValue)
			}
			Set k = $O(pParms(k),1,tValue)
		}
		
		// DTB214 - The export expects FILTER to apply to the results for KPI exports.
		// DP-406616 - This value is always nonced.
		// DP-411626 - Keep sending FILTERNAMES/FILTERVALUES to FILTER for backwards compatibility
		If $D(pParms("FILTERNAMES")) {
			Set tFilterNames = pParms("FILTERNAMES")
			Set tFilterValues = pParms("FILTERVALUES")
			For f=1:1:$L(tFilterNames,$C(10)) {
				// DP-411626 - Don't overwrite a functional filter that was specifically provided
				Set tFilterName = $P(tFilterNames,$C(10),f)
				Set tFilterValue = $P(tFilterValues,$C(10),f)
				Set:((tFilterName'="") && '$D(pParms("FILTER",tFilterName))) %request.Data("FILTER",$I(tFilterIdx)) = ..%CreateParameterNonce( tFilterName _ ":" _ tFilterValue)
			}
		}

		// open the file
		Set io = $io
		If (pFile'="") {
			Open pFile:"WNU":0 Else  Set tSC = $$$ERROR($$$GeneralError,"Unable to open file: "_pFile) Quit
			Use pFile
		}
		
		Set tSC = ##class(%DeepSee.UI.MDXExcel).OnPage()
		If (pFile'="") {
			Use io
			Close pFile
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Export a DeepSee query or KPI to the file <var>pFile</var> in CSV format.<br/>
/// <var>pParms</var> controls the content and display of the export.<br/>
/// pParms("TITLE") = title<br/>
/// pParms("SUBTITLE") = subtitle<br/>
/// pParms("SHOWDATE") = "on" (includes current date and time in the export)</br><br>
/// Data export should rely on either a base MDX query or an available KPI.<br>
/// pParms("MDX") = MDX Statement to execute<br/>
/// pParms("KPI") = KPI class name<br/>
/// Exports operating in MDX mode expect filter clauses to be included in the query. When filters are being applied to the KPI class,
/// they may be provided in the array:<br/>
/// pParms("FILTER",<var>filterName</var>) = <var>filterValue</var><br/>
/// Filters can optionally be included as a printed table in the export, provided by the FILTERNAMES and FILTERVALUES parameters:<br/>
/// pParms("FILTERNAMES") = A $C(10)-delimited list of filter names to display<br/>
/// pParms("FILTERVALUES") = A $C(10)-delimited list of filter values to display<br/><br/>
/// Defined listings can be applied to a resultset using:<br/>
/// pParms("LISTINGNAME") = Name of a listing to execute.<br/> A KPI must support use of a named listing or else this will be ignored. 
/// An MDX query must be in DRILLTHROUGH mode and the cube must have that listing defined for the listing to be applied.<br/><br/>
ClassMethod %ExportPDFToFile(pFile As %String, ByRef pParms As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		New %session,%request,%response
		Set %request = ##class(%CSP.Request).%New()
		Set %response = ##class(%CSP.Response).%New()
		Set %session = ##class(%CSP.Session).%New(666)
		
		// DTB362 - Test the MDX query to see if there are
		// early indications there will be a problem
		If $G(pParms("MDX"))'="" {
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX($G(pParms("MDX")))
			If $$$ISERR(tSC) Quit
		}

		// Apply parameters to the export by adding them to the request object.
		Set k = $O(pParms(""),1,tValue)
		While (k'="") {
			If (k="MDX") {
				// DP-406616 - The query itself has its own nonce location 
				Set %request.Data("NONCE",1) = ..%CreateQueryNonce(tValue)
			}
			ElseIf (k="FILTER") {
				// DP-411626 - A FILTER array has been provided in the parameters. Pass these to the document provider via the request.
				For {
					Set tFilterName = $O(pParms("FILTER",$G(tFilterName)),1,tFilterValue)
					Quit:(tFilterName="")

					Set %request.Data("FILTER",$I(tFilterIdx)) = ..%CreateParameterNonce(tFilterName _ ":" _ $G(tFilterValue))
				}
			}
			Else {
				// DP-406616 - For all remaining parameters, consult the macro for which parameters need to be nonced
				Set %request.Data(k,1) = $S($$$dsExportNonceUrl(k):..%CreateParameterNonce(tValue),1:tValue)
			}
			Set k = $O(pParms(k),1,tValue)
		}
				
		// DTB214 - The export expects FILTER to apply to the results for KPI exports.
		// DP-406616 - This value is always nonced.
		// DP-411626 - Keep sending FILTERNAMES/FILTERVALUES to FILTER for backwards compatibility
		If $D(pParms("FILTERNAMES")) {
			Set tFilterNames = pParms("FILTERNAMES")
			Set tFilterValues = pParms("FILTERVALUES")
			For f=1:1:$L(tFilterNames,$C(10)) {
				// DP-411626 - Don't overwrite a functional FILTER entry that was specifically provided
				Set tFilterName = $P(tFilterNames,$C(10),f)
				Set tFilterValue = $P(tFilterValues,$C(10),f)
				Set:((tFilterName'="") && '$D(pParms("FILTER",tFilterName))) %request.Data("FILTER",$I(tFilterIdx)) = ..%CreateParameterNonce( tFilterName _ ":" _ tFilterValue)
			}
		}

		// open the file
		Set io = $io
		If (pFile'="") {
			Open pFile:"WNU":0 Else  Set tSC = $$$ERROR($$$GeneralError,"Unable to open file: "_pFile) Quit
			Use pFile
		}
		Set tSC = ##class(%DeepSee.UI.MDXPDF).OnPage()
		If (pFile'="") {
			Use io
			Close pFile
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Export a DeepSee query or KPI to the file <var>pFile</var> in CSV format.<br/>
/// <var>pParms</var> controls the content and display of the export.<br/>
/// pParms("TITLE") = title<br/>
/// pParms("SUBTITLE") = subtitle<br/>
/// pParms("SHOWDATE") = "on" (includes current date and time in the export)</br>
/// pParms("SIMPLE") = 1 (exports only the data table without any filter or title information)<br/><br>
/// Data export should rely on either a base MDX query or an available KPI.<br>
/// pParms("MDX") = MDX Statement to execute<br/>
/// pParms("KPI") = KPI class name<br/>
/// Exports operating in MDX mode expect filter clauses to be included in the query. When filters are being applied to the KPI class,
/// they may be provided in the array:<br/>
/// pParms("FILTER",<var>filterName</var>) = <var>filterValue</var><br/>
/// Filters can optionally be included as a printed table in the export, provided by the FILTERNAMES and FILTERVALUES parameters:<br/>
/// pParms("FILTERNAMES") = A $C(10)-delimited list of filter names to display<br/>
/// pParms("FILTERVALUES") = A $C(10)-delimited list of filter values to display<br/><br/>
/// Defined listings can be applied to a resultset using:<br/>
/// pParms("LISTINGNAME") = Name of a listing to execute.<br/> A KPI must support use of a named listing or else this will be ignored. 
/// An MDX query must be in DRILLTHROUGH mode and the cube must have that listing defined for the listing to be applied.<br/><br/>
ClassMethod %ExportCSVToFile(pFile As %String = "", ByRef pParms As %String, Output pOutFile) As %Status
{
	// Method added by DP-402897
	Set tSC = $$$OK
	
	Try {
		If ($D(pParms)\10) {
			// This is an array and needs to be converted to an object for the provider
			Set tParms = {}
			Set tParms.title = $G(pParms("TITLE"))
			If ($G(pParms("SUBTITLE"))'="") {
				Set tParms.subtitle = $G(pParms("SUBTITLE"))
				Set tParms.subtitleOn = "on"
			}
			Set tParms.mdx = $G(pParms("MDX"))
			Set tParms.kpi = $G(pParms("KPI"))
			Set tParms.listing = $G(pParms("LISTINGNAME"))
			
			// DP-411626 - If a FILTER array has been provided in the parameters, pass these to the document provider via the filterKeys.
			Set tParms.filterNames = []
			Set tParms.filterValues = []
			Set tParms.filterKeys = []
			For {
				Set tFilterName = $O(pParms("FILTER",$G(tFilterName)),1,tFilterValue)
				Quit:(tFilterName="")

				Set tKey = {}
				Set tKey.spec = tFilterName
				Set tKey.key = tFilterValue
				Do tParms.filterKeys.%Push(tKey)
			}

			If ($G(pParms("FILTERNAMES"))'="") {
				Set tFilterNames = $G(pParms("FILTERNAMES"))
				Set tFilterValues = $G(pParms("FILTERVALUES"))
				For n=1:1:$L(tFilterNames,$C(10)) {
					Set tFilterName = $P(tFilterNames,$C(10),n)
					Set tFilterValue = $P(tFilterValues,$C(10),n)

					Do tParms.filterNames.%Push(tFilterName)
					Do tParms.filterValues.%Push(tFilterValue)
				
					// DP-412279 - The CSVProvider uses a prepared key object to apply filters to the model.
					// DP-411626 - Keep sending FILTERNAMES/FILTERVALUES entries to filterKeys for backwards compatibility but do 
					// not duplicate any references already provided in the FILTER.
					If ((tFilterName'="") && '$D(pParms("FILTER",tFilterName))) {
						Set tKey = {}
						Set tKey.spec = tFilterName
						Set tKey.key = tFilterValue
						Do tParms.filterKeys.%Push(tKey)
					}
				}
			}

			// DP-411278 Add SHOWDATE support
			If ($G(pParms("SHOWDATE"))="on") {
				Set tParms.showDate="on"
			}
			
			Set tParms.simple = $G(pParms("SIMPLE"))
		}
		ElseIf $IsObject(pParms) {
			// Pass the object parameters directly if passed in as an object
			Set tParms = pParms
		}
		
		Set tNewFileName = ##class(%DeepSee.Component.deepseeCSVProvider).ExportCSV(tParms.mdx,##class(%File).GetFilename(pFile),tParms.%ToJSON(),.tSC)
		If $$$ISERR(tSC) Quit
		Set tNewFileName = ##class(%DeepSee.Component.deepseeCSVProvider).ScopeFileName(tNewFileName)
	
		// DP-406415 - Copy the scoped file from the provider to the custom file location provided by the caller.
		If (##class(%File).GetDirectory(pFile)'="") {
			// The requested file is a full file path, copy the temp file in the mgr/temp directory.
			// to the fully qualified location.			
			Do ##class(%File).CopyFile(tNewFileName,pFile,0,.return)
			
			// Delete the temp file.
			Do ##class(%File).Delete(tNewFileName)

			Set pOutFile = pFile
		}
		Else {
			// No file path is requested, return the generated mgr/temp file location to the caller.
			Set pOutFile = tNewFileName
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Compute the "age" (time difference) between <var>pStart</var> and <var>pEnd</var> as a number
/// of units specified by <var>pUnits</var> ("years","months","days").
ClassMethod %ComputeAge(pStart As %Date, pEnd As %Date, pUnits As %String = "years") As %Integer
{
	// JMD1134
	Set tAge = ""
	// WAL079 -- handle negative ages just in case they are needed
	Set tIsNegative = (pStart>pEnd)
	Set:(tIsNegative) tTemp=pStart,pStart=pEnd,pEnd=tTemp
	If (pUnits = "days") {
		Set tAge = +pEnd - pStart
	}
	Else {
		Set tStartDate = $ZDT(pStart,3)
		Set tEndDate = $ZDT(pEnd,3)

		// look at years/months
		Set tStartYear = +$E(tStartDate,1,4)
		Set tEndYear = +$E(tEndDate,1,4)
		Set tStartMonth = +$E(tStartDate,6,7)
		Set tEndMonth = +$E(tEndDate,6,7)
		Set tStartDay = +$E(tStartDate,9,10)
		Set tEndDay = +$E(tEndDate,9,10)

		// WAL079 -- convert year/month to a number of months for easy computation
		Set tMonthAge = (tEndYear*12 + tEndMonth)-(tStartYear*12 + tStartMonth)
		If (pUnits = "years") {
			// WAL079 -- convert months back to years, integer division (so that we round down)
			Set tAge = tMonthAge\12
		}
		ElseIf (pUnits = "months") {
			// WAL079 -- i.e., April 3rd to May 2nd is not a full month
			If (tEndDay<tStartDay) {
				Set tMonthAge = tMonthAge - 1
			}
			Set tAge = tMonthAge
		}
	}
	If (tIsNegative) {
		Set tAge = 0-tAge	
	}
	
	Quit tAge
}

/// Sometimes we need to pass a query (or XML) to another process via a URL.
/// I.E. has trouble with large URL parameters, so the best approach is to store the query
/// text in a global and pass a one-time token (or nonce) as part of the URL.
/// Assumes that the query is encrypted.
/// Returns "ERROR:"_details if there is an error.
ClassMethod %CreateQueryNonce(pText As %String, pMode As %String = "MDX") As %String
{
	Set tSC = $$$OK
	Set tNonce = ""
	Try {
		Set tText = pText
		// + WAL075 -- query is no longer encrypted
		/*
		If (pMode="MDX") {
			// decrypt
			Set tText = ##class(%CSP.Page).Decrypt(tText)
		}
		*/
		// - WAL075
		// convert utf-8
		// WAL075 (3) -- since we didn't encrypt/decrypt we don't need to convert from UTF8
		// Set tText = $ZCVT(tText,"I","UTF8")
		Set tNonce = $I($$$DeepSeeQueryNonceGLVN) 
		Set $$$DeepSeeQueryNonceGLVN(tNonce) = tText
	}
	Catch(ex) {
		Set tSC = $System.Status.GetErrorText(ex.AsStatus())
	}

	If $$$ISERR(tSC) {
		Set tNonce = "ERROR:"_$System.Status.GetErrorText(tSC)
	}
	Quit tNonce
}

/// Sometimes we need to pass parameters to another process via a URL.
/// I.E. has trouble with large URL parameters, so the best approach is to store the parameter
/// text in a global and pass a one-time token (or nonce) as part of the URL.
/// Assumes that the parm unencrypted.
/// Returns "ERROR:"_details if there is an error.
ClassMethod %CreateParameterNonce(pParm As %String) As %String
{
	Set tSC = $$$OK
	Set tNonce = ""
	Try {
		Set tText = pParm
		Set tNonce = $I($$$DeepSeeParameterNonceGLVN)
		Set $$$DeepSeeParameterNonceGLVN(tNonce) = tText
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()		// DTB452 - Return a %Status from the Catch block
	}

	If $$$ISERR(tSC) {
		Set tNonce = "ERROR:"_$System.Status.GetErrorText(tSC)
	}
	Quit tNonce
}

ClassMethod %GetParameterNonce(pNonce As %Integer)
{
	// DTB916 - Clear out the nonce cache as soon as it is successfully read
	If ($g(pNonce)'="") {
		Set tParameter = $G($$$DeepSeeParameterNonceGLVN(pNonce))
		Kill $$$DeepSeeParameterNonceGLVN(pNonce)
	}
	Else {
		Set tParameter = ""
	}

	Quit tParameter
}

/// <p>Utility method to retrieve <var>pMaxResults</var> cube members based on a simple search key. By default, this
/// method will return normal cube members only, but a range of flags serve to indicate which type
/// of results to return on top, as long as they match the search key (level names, measure
/// names or computed members).<br/>
/// Members are returned as <pre>pMembers(n) = $lb(<i>Caption</i>, <i>Spec</i>, ["measure"|"level"|"member"])</pre></p>
/// <p>Use <var>pDimList</var> to limit the search scope to those dimensions, hierarchies or levels
/// listed in this comma-separated list of specs.</p>
/// <p>This method does not return "all" levels, nor will it check cube relationships.</p>
ClassMethod %FindCubeMembers(pCube As %String, pSearchKey As %String, Output pMembers, pDimList As %String = "", pIncludeLevelNames As %Boolean = 0, pIncludeMeasures As %Boolean = 0, pIncludeComputed As %Boolean = 0, pMaxResults As %Integer = 10) As %Status
{
	set tSC = $$$OK
	try {
		kill pMembers
		set pMembers = 0
		set tSearchKey = $$$UPPER(pSearchKey)
		set tCube = $$$DeepSeeIndex(pCube)
		
		// parse pDimList
		kill tDimFilter
		set tDimFilter = 0
		if (pDimList'="") {
			set tDimFilter = 1
			for i = 1:1:$l(pDimList,",") {
				set tSpec = $zstrip($p(pDimList,",",i),"<>W")
				set tDimFilter($case($l(tSpec,"."), 1:"D", 2:"H", 3:"D"), $$$UPPER(tSpec)) = ""
			}
		}
		
		// first find all cube levels
		set tSC = ..%GetCubeLevels(pCube, .tLevels)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tLevels(i),1,tLevelInfo)
			quit:i=""
			
			set tLevelType = $li(tLevelInfo,1)
			continue:(tLevelType="r")
			
			if (tLevelType="m") {
				continue:'pIncludeMeasures
				set tName = $li(tLevelInfo,3)
				set tSC = ..%GetMemberCaption(pCube, "MEASURES", tName,, .tMsrCaption)
				quit:$$$ISERR(tSC)
				
				continue:'$find($$$UPPER(tMsrCaption),tSearchKey)
				set tSpec = "[MEASURES].["_tName_"]"
				
				// check filter
				continue:tDimFilter&&'$d(tDimFilter("D","[MEASURES]"))&&'$d(tDimFilter("H",$$$UPPER(tSpec)))
				
				set pMembers($i(pMembers)) = $lb(tMsrCaption, tSpec, "measure")
				quit:pMembers>=pMaxResults
				continue
			}
			
			set tDim = $li(tLevelInfo,2)
			set tHier = $li(tLevelInfo,3)
			set tLevel = $li(tLevelInfo,4)
			set tSpec = "["_tDim_"].["_tHier_"].["_tLevel_"]"
			
			// filter first
			if tDimFilter && '$d(tDimFilter("D",$$$UPPER($p(tSpec,".",1)))) &&
			  '$d(tDimFilter("H",$$$UPPER($p(tSpec,".",1,2)))) &&
			  '$d(tDimFilter("L",$$$UPPER(tSpec))) {
				 continue
			 }
			 
			// check dimension info
			set tSC = ..%GetDimensionInfo(pCube, tSpec, .tDimNo, .tHierNo, .tLevelNo, .tRelName, .tRelSpec,, .tLocalCalcMbrs, .tLocalNamedSets)
			quit:$$$ISERR(tSC)
			
			// check the level name
			if (pIncludeLevelNames) {
				set tSC = ..%GetDimensionCaption(pCube, tDimNo, tHierNo, tLevelNo, .tLevelCaption)
				quit:$$$ISERR(tSC)
				if $find($$$UPPER(tLevelCaption),tSearchKey) {
					set pMembers($i(pMembers)) = $lb(tLevelCaption, tSpec_".Members", "level")
					quit:pMembers>=pMaxResults
				}
			}
			
			set tMbrClass = $lg($g($$$DeepSeeMetaGLVN("cubes", tCube, "mbr#", tDimNo, tHierNo, 0)),6)
			//set tLvlClass = $lg($g($$$DeepSeeMetaGLVN("cubes", tCube, "mbr#", tDimNo, tHierNo, tLevelNo)),6)
			
			continue:'pIncludeComputed&&(tMbrClass="%DeepSee.Query.memberComputed")
			
			set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(pCube, tSpec, .tMembers,, pSearchKey)
			quit:$$$ISERR(tSC)
			
			set j = ""
			for {
				set j = $order(tMembers(j),1,tMemberInfo)
				quit:j=""
				set pMembers($i(pMembers)) = $lb($li(tMemberInfo,1), tSpec_"."_$li(tMemberInfo,2), "member")
				quit:pMembers>=pMaxResults
			}
			quit:pMembers>=pMaxResults
		}
		quit:$$$ISERR(tSC)
		quit:pMembers>=pMaxResults
		
		// Not covered:
		//	- "all" level for dimensions
		// 	- cube relationships
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Return resource list containing type=Application only.
ClassMethod GetResourceList() As %String
{
	Try {
		Set tSC = $$$OK
		Set tOutput = ""
		Do ResourceList^%SYS.SECURITY("*",-1,-1,.res)
		Set tItem = $O(res(""))
		While tItem '= "" {
			If $LG(res(tItem),3) = 2147483648 {
				Set tOutput = tOutput _ $S(tOutput'="":",",1:"")_tItem	
			}
			Set tItem = $O(res(tItem))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tOutput = $System.Status.GetErrorText(tSC)
	}
	Quit tOutput
}

/// Given a fact id, see if there are any or groups (1|2|3) that can be compressed
/// into ranges.
ClassMethod %CompressList(pFactId As %String) As %String [ Internal ]
{
	Quit:(pFactId'["|") pFactId
	Set tOut = ""
	Set tCount = $L(pFactId,"|")+1	// add extra "" on the end
	Set tRangeStart = ""
	Set tLastID = ""
	For p = 1:1:tCount {
		Set tID = $P(pFactId,"|",p)
		If (tRangeStart="") {
			Set tRangeStart = tID
			Set:tID'="" tOut = tOut _ $S(tOut="":"",1:"|") _ tID
		}
		ElseIf (tID'=(tLastID+1)) {
			// id is not part of a range	(dates?)
			Set:(tRangeStart'=tLastID) tOut = tOut _ ">" _ tLastID
			Set tRangeStart = tID
			Set:tID'="" tOut = tOut _ $S(tOut="":"",1:"|") _ tID
		}
		Set tLastID = tID
	}
	Quit tOut
}

/// Diagnostic.
ClassMethod %TestForZProcessing(pKill As %Boolean = 0) [ Internal ]
{
	Set tCube = $O($$$DeepSeeResultsGLVN(""))
	While (tCube'="") {
		Set tKey = $O($$$DeepSeeResultsGLVN(tCube,""))
		While (tKey'="") {
			If $D($$$DeepSeeResultsGLVN(tCube,tKey,"zprocessing")) {
				Write "zprocessing: ",tCube,":",tKey,!
				Write $G($$$DeepSeeResultsGLVN(tCube,tKey,"query",1)),!
			}
			ElseIf (pKill) {
				Kill $$$DeepSeeResultsGLVN(tCube,tKey)
			}
			Set tKey = $O($$$DeepSeeResultsGLVN(tCube,tKey))
		}
		Set tCube = $O($$$DeepSeeResultsGLVN(tCube))
	}
}

/// Indicates whether the default application for this namespace will process DeepSee Pages.
ClassMethod %IsDeepSeeEnabled(pNamespace = "") As %Boolean
{
	// DTB073 - Provide an API to determine whether a namespace is DeepSee enabled
	Set tEnabled = 0
	
	Try {
		Set tNamespace = $S(pNamespace="":$NAMESPACE,1:$$$UPPER(pNamespace))
		
		If (pNamespace="%SYS") {
			// DTB766 - Quit with 0 if this is the %SYS namespace. The checks below will return 1.
			Set tEnabled = 0
			Quit
		}
		
		Set tApplication = $system.CSP.GetDefaultApp(tNamespace)
		If $E(tApplication,1)'="/" {
			Set tApplication = "/" _ tApplication
		}
		If $E(tApplication,*)'="/" {
			Set tApplication = tApplication _ "/"
		}
		Set tEnabled = $$IsDeepSeeEnabled^%SYS.cspServer(tApplication)
	}
	Catch {
	}
	
	Quit tEnabled
}

/// Test whether pClassName is a DataConnector. This uses a direct global lookup so users do not need to rely 
/// on access to %Dictionary tables
ClassMethod %IsDataConnector(pClassName As %String = "", pStatus As %Status) As %Boolean
{
	// Method added by DTB160
	Set tIsConnector = 0
	Set pStatus = $$$OK
	
	Try {
		Set tIsConnector = ($$$comClassKeyGet(pClassName,$$$cCLASSsuper)="%DeepSee.DataConnector")
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tIsConnector
}

/// Method for programmatically creating a pivot table <br>
/// The GetMDXforPivot method returns the MDX query for saved pivot. <br> 
/// <br>
/// Arguments:<br>
/// <li>pPivotFullName</li> 
/// The name of the pivot including folder name<br>
/// Format: folder/pivot name<br>
/// Example: My Folder/My Pivot<br>
/// <br>
/// <LI>pExecute</LI>
/// Boolean value (optional):<br>
/// 0 - Do not execute the MDX query (Default) <br>
/// 1 - Execute the MDX query<br> 
/// <br>
/// <LI>pResultSet</LI>
/// Output argument (optional): <br>
/// Instance of %DeepSee.ResultSet for the MDX query:<br>
/// This can be used to access the query results, meta data, statistics, etc.
/// <br>
/// To get the text of the MDX query, use only the pPivotFullName argument <br>
/// To get the text of the MDX query and run the query, use pPivotFullName and pExecute<br>
/// To get the text of the MDX query, run the query, and get the ResultSet, use pPivotFullName, pExecute and pResultSet<br>
ClassMethod %GetMDXFromPivot(pPivotFullName = "", Output pStatus As %Status, pExecute As %Boolean = 0, ByRef pParms, Output pResultSet As %DeepSee.ResultSet) As %String
{
	// Method added by DTB245
	Set pStatus = $$$OK
	Set tMDX = ""
	Set pResultSet = ""
	Try {
		// This is a convenience method rearranging the return from %GetResultSetFromPivot
		Set pResultSet = ##class(%DeepSee.Utils).%GetResultSetFromPivot(pPivotFullName,.pStatus,pExecute,.pParms,.tMDX)
	}
	Catch ex {
		// Return empty string if there is an error
		Set pStatus = ex.AsStatus()
		Set tMDX = ""
	}
	
	Quit tMDX
}

/// Programmatically execute a stored pivot table. The <var>pPivotTableName</var> is the full
/// Folder/SubFolder/Name of the pivot table. Execute parameters may optionally be passed in through
/// the <var>pParms</var> array. If desired, the resultset constructed in the execution procedure can
/// be returned using <var>pResultSet</var>.
ClassMethod %ExecutePivot(pPivotFullName = "", ByRef pParms, Output pResultSet) As %Status
{
	// Method added by DTB245
	Set tSC = $$$OK
	Try {
		// This is a convenience method rearranging the return from %GetResultSetFromPivot
		Set pResultSet = ##class(%DeepSee.Utils).%GetResultSetFromPivot(pPivotFullName,.tSC,1,.pParms)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Programmatically create an instance of a <class>%DeepSee.ResultSet</class> from 
/// a stored pivot table. The <var>pPivotTableName</var> is the full
/// Folder/SubFolder/Name of the pivot table. By default, the query is only prepared 
/// and returned ready for execution. The query can be asynchronously executed as part 
/// of the retrieval process by setting <var>pExecute</var>=1. Execute parameters may optionally be passed in through
/// the <var>pParms</var> array.
ClassMethod %GetResultSetFromPivot(pPivotFullName = "", Output pStatus As %Status, pExecute As %Boolean = 0, ByRef pParms, Output pMDX) As %DeepSee.ResultSet
{
	// Method added by DTB245
	Set pStatus = $$$OK
	Set tResultSet = ""
	Try {
		Set tDataSource = pPivotFullName
		If ($$$LOWER($E(tDataSource,*-5,*))'=".pivot") {
			Set tDataSource = tDataSource_".pivot"
		}
		
		// Load a component to access its methods
		Set tPivotObj = ##class(%DeepSee.Component.pivotTable).%New()

		// Open the saved pivot
		Set tPivotDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDataSource,.pStatus)
		If '$IsObject(tPivotDef) Quit
		
		// Copy saved pivot information to the pivotTable component
		set pStatus = tPivotDef.%CopyToComponent(tPivotObj)
		If $$$ISERR(pStatus) Quit
		 
		// Get filter info
		Set pStatus = tPivotObj.%GetFilterInfo(.tFilterInfo,.tAdvancedFilters)
		If $$$ISERR(pStatus) Quit
		
		// Call %CreateResultSet, which creates the MDX query
		Set tResultSet = tPivotObj.%CreateResultSet(.pStatus, .pParms , .tFilterInfo , .tAdvancedFilters , .pMDX )
		If $$$ISERR(pStatus) Quit
		
		If pExecute {
			// DTB704 - Always use %ExecuteAsynch
			Set pStatus = tResultSet.%ExecuteAsynch(,.pParms,1)
		}
	}
	Catch ex {
		// Return null object if there is an error
		Set pStatus = ex.AsStatus()
		Set tResultSet = $$$NULLOREF
	}
	Quit tResultSet
}

ClassMethod %GetChildSpec(pItemList As %String, pCubeName As %String, pAxisNo As %Integer = 0, Output pChildSpec As %String = "") As %Status
{
	// Method added by WAL166
	// DTB - NOTE: pAxisNo is not used! 
	Set tSC = $$$OK
	Set pChildSpec = ""		// DTB864 - Initialize
	
	Try {
		Set k = $O(pItemList(""),1,tInfo)
		Set tHasChildren = 0
		Set tIsRelation = 0
		Set tSpec = ""
		Set c = 0
		While (k'="") {
			Set c = c + 1
			Set tIsAgg = 0
			Set tDimName = $LG(tInfo,3)
			Set tRelSpec = $LG(tInfo,10)
			Set tIsLastItem = ($O(pItemList(k))="")

			// JMD1361 Check for %OR
			If (tRelSpec'="") {
				If ($E(tRelSpec,1,4)'="%OR(") {
					// strip off children and key
					Set tRelSpec = $P(tRelSpec,".children",1)
					Set tRelSpec = $P(tRelSpec,".&[",1)
				}
			}
			If (tRelSpec'="") {
				// JMD1289 try to find names for relationship
				Set tRCubeCaption = tDimName
				Set tRelCube = $$$UPPER(##class(%DeepSee.Utils).%GetRelatedCube(pCubeName,tDimName))

				// JMD1361
				If ($E(tRelSpec,1,4)="%OR(") {
					// strip off %OR, decorate each item, and reapply %OR
					// assume no commas in spec!
					Set t = $E(tRelSpec,6,*-2)
					If (tRelCube'="") {
						// use first OR term to get caption
						Set tRCubeCaption = ##class(%DeepSee.Utils).%GetCubeCaption(tRelCube)
						Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tRelCube,$P(t,",",1),.tRelDimNo)
						If $$$ISERR(tSC) Quit
					}
					Set ts = ""
					For tp = 1:1:$L(t,",") {
						Set ts = ts _ $S(ts="":"",1:",") _ "["_tDimName_"]"_"."_$P(t,",",tp)
					}
					Set tItemSpec = "%OR({"_ts_"})"

					Set:tItemSpec'="" tSpec = tSpec _ $S(tSpec="":"",1:",") _ tItemSpec
					If (tIsLastItem) {
						If (c>1) {
							Set tSpec = "("_tSpec_")"
						}
					}
					Set:tIsLastItem tIsRelation = 1
				}
				ElseIf ($$$UPPER(tRelSpec) '[ ".%TOPMEMBERS") {
					If (tRelCube'="") {
						Set tRCubeCaption = ##class(%DeepSee.Utils).%GetCubeCaption(tRelCube)
						Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tRelCube,tRelSpec,.tRelDimNo)
						If $$$ISERR(tSC) Quit
					}
					Set tItemSpec = "[" _ tDimName _ "]." _ tRelSpec

					// JMD862: Test for and use "All level"
					// we should test if there are children of this related level!
					If ($LG(tInfo,6)'="") {
						Set tItemSpec = tItemSpec _ ".&[" _ $$$dsEscapeIdent($LG(tInfo,6))_"]"
						If (tIsLastItem) {
							Set tChildSpec = tItemSpec_".children"
						}
						Else {
							Set tChildSpec = tItemSpec
						}
					}
					Else {
						If (tRelCube'="") {
							Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tRelCube,tRelSpec,.tRelDimNo)
							If $$$ISERR(tSC) Quit
							If (tRelDimNo'="") {
								// is there an All level?
								Set tAllLevel = $LG($G($$$DeepSeeMetaGLVN("cubes",tRelCube,"mbr#",tRelDimNo,0,0)),4)
								If (tAllLevel'="") {
									If (tIsLastItem) {
										Set tChildSpec = tItemSpec_".["_tAllLevel_"].children"
									}
									Else {
										Set tChildSpec = tItemSpec_".["_tAllLevel_"]"
									}
								}
							}
						}
					}
					
					Set:tItemSpec'="" tSpec = tSpec _ $S(tSpec="":"",1:",") _ tItemSpec
					If (tIsLastItem) {
						If (c>1) {
							Set tSpec = "("_tSpec_")"
						}
					}
					Set:tIsLastItem tIsRelation = 1
				}
				Quit:tIsLastItem
			}
			ElseIf (tDimName="") {
				// assume an aggregate; loop over children, build set
				Set tIsAgg = 1
				Set tSetSpec = ""
				// JMD1366: try to be smarter about text for computed dimension
				// with %OR in it!
				Set tText = $LG(tInfo,2)
				Set tAgg = $LG(tInfo,4)

				Set k2 = $O(pItemList(k,""),1,tInfo2)
				While (k2'="") {
					// !!! change to recursive function!
					Set tDimNo = $LG(tInfo2,7)
					Set tHierNo = $LG(tInfo2,8)
					Set tLevelNo = $LG(tInfo2,9)
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(pCubeName,tDimNo,tHierNo,tLevelNo,.tCaption)
					If $$$ISERR(tSC) Quit

					Set tItemSpec = "["_$LG(tInfo2,3) _ "]"
					Set:$LG(tInfo2,4)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo2,4) _ "]"
					Set:$LG(tInfo2,5)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo2,5) _ "]"
					Set:$LG(tInfo2,6)'="" tItemSpec = tItemSpec _ ".&[" _ $$$dsEscapeIdent($LG(tInfo2,6))_"]"
					Set tSetSpec = tSetSpec _ $S(tSetSpec="":"",1:",") _ tItemSpec
					Set k2 = $O(pItemList(k,k2),1,tInfo2) // WAL166
				}
				Set tSetSpec = "{"_tSetSpec_"}"
				Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ tSetSpec
			}
			Else {
				Set tDimNo = $LG(tInfo,7)
				Set tHierNo = $LG(tInfo,8)
				Set tLevelNo = $LG(tInfo,9)
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(pCubeName,tDimNo,tHierNo,tLevelNo,.tCaption)
				If $$$ISERR(tSC) Quit
				
				// WAL032 -- handle %OR members
				Set tORSpec=$LG(tInfo,11)
				// WAL032

				// JMD976: test for null relationship
				If (($LG(tInfo,3)'="")&&($LG(tInfo,4)="")&&##class(%DeepSee.Utils).%IsRelationship(pCubeName,$LG(tInfo,3))) {
					Set tItemSpec = "["_$LG(tInfo,3) _ "].&[<null>]"
				}
				ElseIf (tORSpec'="") {
					// WAL032
					Set tBaseItemSpec = "["_$LG(tInfo,3) _ "]"
					Set:$LG(tInfo,4)'="" tBaseItemSpec = tBaseItemSpec _ ".[" _ $LG(tInfo,4) _ "]"
					Set:$LG(tInfo,5)'="" tBaseItemSpec = tBaseItemSpec _ ".[" _ $LG(tInfo,5) _ "]"
					
					Set tSC = ##class(%DeepSee.Utils).%MemberHasChildren(pCubeName,tDimNo,tHierNo,tLevelNo,.tHasChildren)
					If $$$ISERR(tSC) Quit
					
					Set tIsLastItem = ($O(pItemList(k))="")	
					
					// Use next level in hierarchy for final child spec
					If (tIsLastItem && tHasChildren) {
						Set tSC = ##class(%DeepSee.Utils).%GetDimensionSpec(pCubeName,.tChildLevelSpec,tDimNo,tHierNo,tLevelNo+1)
						If $$$ISERR(tSC) Quit
						Set tItemSpecForChild=tChildLevelSpec_".MEMBERS"
					}
					Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
					Set tDimensionInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
					Set tMemberClass = $lg(tDimensionInfo,6)
					// Loop through the OR members specs
					For i=1:1:$length(tORSpec,"|") {
						Set tORMember = $p(tORSpec,"|",i)
						Set tORMemberKey = $classmethod(tMemberClass,"%GetMemberSpec",tORMember,"Patients",tDimNo,tHierNo,tLevelNo)
						Set:$G(tORMemberKey)'="" tItemSpec = tBaseItemSpec _ "." _ $G(tORMemberKey)
						Set tCompleteItemSpec = $G(tCompleteItemSpec) _ $S($G(tCompleteItemSpec)="":"",1:",") _ tItemSpec
					}
					// Add %OR to tItemSpec
					Set:$G(tCompleteItemSpec)'="" tCompleteItemSpec="%OR({"_tCompleteItemSpec_"})"
					Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ tCompleteItemSpec
					Set tItemSpec = tCompleteItemSpec
					If (c > 1) {
						Set tChildSpec = "CROSSJOIN("_tChildSpec_","_$S($G(tItemSpecForChild)'="":tItemSpecForChild,1:tItemSpec)
					}
					Else {
						Set tChildSpec = $S($G(tItemSpecForChild)'="":tItemSpecForChild,1:tItemSpec)
					}
				}
				Else {
					Set tItemSpec = "["_$LG(tInfo,3) _ "]"
					Set:$LG(tInfo,4)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo,4) _ "]"
					Set:$LG(tInfo,5)'="" tItemSpec = tItemSpec _ ".[" _ $LG(tInfo,5) _ "]"
					Set:$LG(tInfo,6)'="" tItemSpec = tItemSpec _ ".&[" _ $$$dsEscapeIdent($LG(tInfo,6))_"]"
					Set tSpec = tSpec _ $S(tSpec="":"",1:",") _ tItemSpec
					If (c > 1) {
						Set tChildSpec = "CROSSJOIN("_tChildSpec_","_tItemSpec
					}
					Else {
						Set tChildSpec = tItemSpec
					}
				}
				// WAL032
			}

			// next item
			Set k = $O(pItemList(k),1,tInfo)
			If ('tIsAgg&&(k="")) {
				// last item, test for children
				Set tSC = ##class(%DeepSee.Utils).%MemberHasChildren(pCubeName,tDimNo,tHierNo,tLevelNo,.tHasChildren)
				If $$$ISERR(tSC) Quit

				// WAL032 -- don't add ".children" if we are dealing with a %OR spec
				If (tHasChildren&&($LG(tInfo,11)="")) {
					Set tChildSpec = tChildSpec _ ".children"
				}
				// WAL032
			}
			If ('tIsAgg&&(c > 1)) {
				Set tChildSpec = tChildSpec_")"
			}
		}
		
		// make a tuple
		If ('tIsRelation) {
			If (c > 1) {
				Set tSpec = "("_tSpec_")"
			}
			If ('tHasChildren) {
				Set tChildSpec = ""
			}
		}
		Set pChildSpec = tChildSpec
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		// DTB864 - Make sure the return is the null string if there is an error
		Set pChildSpec = ""
	}
	
	Quit tSC
}

/// Convert a node of the graph returned by %GetCubeListArray into a comma-delimited 
/// valueList. This may be called on the graph itself.
ClassMethod %ProcessCubeListArrayNode(ByRef pNode, pCurrentString = "", ByRef pValueList = "") As %Status [ Internal ]
{
	// Method added by DTB321
	Set tSC = $$$OK
	Try {
		Set tItem = $O(pNode(""))
		While tItem'="" {
			If ($P(tItem,".",*)="folder") {
				// Folder: recurse
				Merge tNewNode = pNode(tItem)
				Set tNewString = pCurrentString _ $S($L(pCurrentString):"/",1:"") _ $LG(pNode(tItem),1)
				Do ..%ProcessCubeListArrayNode(.tNewNode,tNewString,.pValueList)
			}
			Else {
				// Cube: Add to the list
				// N.B. Security has already been checked in %GetCubeList
				Set pValueList = pValueList _ $S($L(pValueList):",",1:"") _ pCurrentString _ $S($L(pCurrentString):"/",1:"") _ $LG(pNode(tItem),1)
			}

			Set tItem = $O(pNode(tItem))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Split a single fieldList string into the individual fields.</br>
/// The output <var>pFieldArray</var> returns each SELECT item in</br>
/// pFieldArray(termNumber) = $LB( $LB(fieldIdenitifier,"AS",logicalHeader), $LB(fieldIdenitifier,"AS",displayHeader))</br></br>
/// The <var>pLocalize</var> parameter can be used to request behavior of the $$$TEXT macro in the header portion:</br>
/// 0 - Return the original text value from $$$TEXT</br>
/// 1 - Return the header value localized to the language of the current client</br>
/// When <var>pLocalize</var> is used, a default domain can be provided in <var>pDomain</var>. This domain will be used for translation for each
/// instance of $$$TEXT that does not specify its own domain.
ClassMethod %ParseSQLFieldList(pFieldString = "", pDomain = "", Output pFieldArray, pLocalize As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Kill pFieldArray
	Set pFieldArray = ""
	
	Try {
		If (pFieldString="") {
			Quit
		}
		
		Set tSELECT = pFieldString

		Set tSQLParser = ##class(%DeepSee.SQL.Parser).%New(.tSELECT)
		
		Set tSC = tSQLParser.%Tokenize()
		If $$$ISERR(tSC) Quit
		
		
		Set tSC = tSQLParser.%ParseSelect(tSQLParser.%GetTokenList(),.tSelectItems,.tSpecialTokens)
		
		For itemNo=0:1:tSelectItems.%Size()-1 {
			Set tHeaderPos = -1		// Default: There is no header
			Kill tTextPos
			Set tSelectItemTokens = tSelectItems.%Get(itemNo)
			
			// Search for a header
			If $D(tSpecialTokens("tokens","$$$TEXT[",itemNo)) {
				// First check for the $$$TEXT macro. Mark the position of the macro.
				Set tTextPos = $O(tSpecialTokens("tokens","$$$TEXT[",itemNo,""))
				If $D(tSpecialTokens("tokens","""",itemNo,tTextPos-1)) {
					// If the preceding character is " the header begins on the
					// previous token
					Set tHeaderPos = tTextPos-1
				}
				Else {
					Set tHeaderPos = tTextPos
				}
			}
			ElseIf ($D(tSpecialTokens("tokens","AS",itemNo))) {
				Set tHeaderPos = $O(tSpecialTokens("tokens","AS",itemNo,"")) + 1
			}
			ElseIf ($D(tSpecialTokens("tokens","""",itemNo))) {
				// Delimited identifier. If this is not the first token,
				// consider it a header
				Set tPos = $O(tSpecialTokens("tokens","""",itemNo,""))
				Set:(tPos) tHeaderPos=tPos
			}
			ElseIf (tSelectItemTokens.%Size()>1) {
				// If the final token is not a closing parenthesis,
				// it should be a header
				Set tFinalToken = tSelectItemTokens.%Get(tSelectItemTokens.%Size()-1)
				Set tPenultToken = tSelectItemTokens.%Get(tSelectItemTokens.%Size()-2)
				If (tFinalToken'=")") &&
						(tFinalToken'="]") &&
						(tPenultToken'="->") &&
						'tSQLParser.%IsOperatorToken(tPenultToken) {
					Set tHeaderPos = tSelectItemTokens.%Size()-1
				}
			}
			
			Set tSC = tSQLParser.%ProcessSelectItem(tSelectItemTokens,$G(tHeaderPos,-1),pDomain,.tItemPair,pLocalize)		// DTB827 - Pass localization flag
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			
			Set pFieldArray($I(pFieldArray)) = tItemPair
		}		// Single Select Item
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Convert a single-subscript array to an $LB format
ClassMethod %ArrayToList(ByRef pParms, Output pParmsList As %List) As %Status
{
	// Method added by DTB882
	Set tSC = $$$OK
	
	Try {
		Set pParmsList = $LB()		// Default return is an empty list
		Set tParmName = $O(pParms(""),1,tParmData)
		While (tParmName'="") {
			Set $LI(pParmsList,$I(tListIdx)) = $LB(tParmName,tParmData)
			Set tParmName = $O(pParms(tParmName),1,tParmData)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Convert a parameters list in $LB format to an array
ClassMethod %ArrayFromList(pParmsList As %List = {$LB()}, ByRef pParms) As %Status
{
	// Method added by DTB882
	Set tSC = $$$OK
	Try {
		For tParmIdx=1:1:$LL(pParmsList) {
			Set tParmDef = $LG(pParmsList,tParmIdx)
			Set:(tParmDef'="") pParms($LG(tParmDef,1)) = $LG(tParmDef,2)
		}
		
		If '$D(pParms) {
			// Return a null variable if nothing was set from the list to prevent <UNDEFINED> references
			Set pParms = ""
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Test a <var>pFactList</var> to make sure it contains only SQL column identifiers that are actually defined in <var>pCube</var>.
ClassMethod %IsValidFactList(pCube As %String = "", pFactList As %String = "", Output pStatus As %Status, pReason As %String = "") As %Boolean
{
	// Method added by DTB900
	Set pStatus = $$$OK
	Set tIsValidFactList = 0
	Set pReason = ""
	
	Try {
		// Normalize the incoming pFactList to a $LB for examination
		Set tFactList = ..%NormalizeFactList(pFactList)
		
		If (tFactList=$LB()) {
			// Consider an empty list to be valid and quit
			Set tIsValidFactList = 1 
			Quit
		}

		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set tFactTable = ##class(%DeepSee.Utils).%GetCubeFactTable(tCubeIndex)
		Set tRS = ##class(%SQL.Statement).%ExecDirect(.tS,"SELECT * FROM " _ tFactTable)
		Set tFactMeta = tRS.%GetMetaData()
				
		// Check the contents of the non-empty fact list against the cube's metadata
		Set tIsValidFactList = 1
		For ii=1:1:$LL(tFactList) {
			Set tFactNameU = $$$UPPER($LG(tFactList,ii))
			
			// DTB915 - Return the specific invalid column identifiers
			Set tFactIsValid = $D(tFactMeta.columnIndex(tFactNameU))
			If 'tFactIsValid {
				Set pReason = pReason _ $LB($LG(tFactList,ii))
			}

			Set tIsValidFactList = tIsValidFactList && tFactIsValid
		}
		
		If 'tIsValidFactList {
			// DTB908 - Report an error if validation has failed
			Set pStatus = $$$ERROR($$$GeneralError,"Fact list does not contain valid column identifiers for cube:"_tCubeIndex_":"_$ListToString(tFactList,","))
		}
	}
	Catch ex {
		Set tIsValidFactList=0
		Set pStatus = ex.AsStatus()
	}
	
	Quit tIsValidFactList
}

/// Take as input a <var>pFactList</var> in either comma-delimited string or $LB format and 
/// return a fact list in $LB format with any empty entries removed.
/// If <var>pCubeName</var> is supplied, any supporting fields that are required to produce a successful
/// Selective Build given the cube definition are added to the original list.
ClassMethod %NormalizeFactList(pFactList = "", Output pStatus As %Status, pCubeName = "") As %List
{
	Set pStatus = $$$OK
	
	Try {
		Set tTest = $S($ListValid(pFactList):pFactList,1:$ListFromString(pFactList,","))
		Set tReturn = ""
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		
		// Collect the non-null terms in the incoming list
		For ii=1:1:$LL(tTest) {
			If $LD(tTest,ii) && ($LG(tTest,ii)'="") {
				Set tTerms($ListGet(tTest,ii)) = ""
			}
		}
		
		// DTB961 - Reinforce the targeted fact list with any other data columns that must
		// be included for a successful build
		Do:(tCubeIndex'="") ..%ReinforceFactList(tCubeIndex,.tTerms)
		
		// Reassemble the list from the processed collection
		Set tFactName = $O(tTerms(""))
		While (tFactName'="") {
			Set tReturn = tReturn _ $LB(tFactName)
			Set tFactName = $O(tTerms(tFactName))
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}

	Quit tReturn
}

/// This examines an array of facts for a given cube as provided in <var>pFacts</var> 
/// - For levels in a hierarchy all parent levels in that hierarchy will also be included in the list.
/// - For time levels the common reference column in the fact table on which the time functions operate
/// will also be added to the list.
ClassMethod %ReinforceFactList(pCubeIndex = "", ByRef pFacts) As %Status [ Internal ]
{
	// Method added by DTB961
	Set tSC = $$$OK
	
	Try {
		Set tCubeIndex = pCubeIndex
		
		// Attempt to identify named lower members of a hierarchy. All parents must also be in the list for 
		// a cube's Selective Build. If the cube index is not supplied, skip this step.
		If (tCubeIndex'="") {
			Merge tCubeProperties = $$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop")
			
			Set tFactName = $O(pFacts(""))
			While (tFactName'="") {
				Set tDimNo = $G(tCubeProperties(tFactName,"dimNo"))
				Set tHierNo = $G(tCubeProperties(tFactName,"hierNo"))
				Set tLevelNo = $G(tCubeProperties(tFactName,"levelNo"))
				
				If (tDimNo'="") {
					// Add to the list based on the dimension information
					Set tNode = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
					If (+tLevelNo>1) {
						// This level may have a parent level in a hierachy. Look up for other "l" nodes. 
						// The "all" member might be the first node in the list.
						Set tParentLevel = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo),-1,tParentNode)
						While ($LG(tParentNode,1)="l") {
							// This hierarchical parent is a true level. Add it to the facts that need to 
							// be processed.
							Set pFacts($LG(tParentNode,7)) = ""
							
							Set tParentLevel = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tParentLevel),-1,tParentNode)
						}
					}
					
					If $classmethod($LG(tNode,6),"%IsA","%DeepSee.Time.AbstractLevel") {
						// This is a time level, which means the fact table will require a non-indexed
						// data column. This will make sure that column is included in the list along with the 
						// actual indexed column for the level originally supplied.
						Set pFacts($LG(tNode,7)) = ""
					}
				}

				Set tFactName = $O(pFacts(tFactName))
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Provided a <var>pCubeName</var> and a valid <var>pFactList</var> for that cube, return the list
/// of buildable indices contained in the original fact list. If no fact list is supplied, the method
/// returns a null string.<br>
/// This is best used following normalization of the fact list using <method>%NormalizeFactList</method>
/// method with the cubename suplied.
ClassMethod %FindCubeIndexList(pCubeName = "", Output pStatus As %Status, pFactList = "") As %List [ Internal ]
{
	// Method added by DTB961
	Set pStatus = $$$OK
	Set tIndexList = ""
	
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		Set tFactClass = ..%GetCubeFactClass(tCubeIndex)
		Set tFactList = ..%NormalizeFactList(pFactList)
		
		If (tFactList'="") {
			// DP-423547 - Collect a quick reference for any dependsOn indices if they exist. This has the form
			//  tDependsOn(factNo,indexKey) = ""
			Set tDependsOn1 = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"factDepends",""))
			While (tDependsOn1'="") {
				Set tDependsOn2 = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"factDepends",tDependsOn1,""))
				While (tDependsOn2'="") {
					Set tDependsOn(tDependsOn1,tDependsOn1 _ "&" _ tDependsOn2) = ""
					Set tDependsOn(tDependsOn2,tDependsOn1 _ "&" _ tDependsOn2) = ""
					Set tDependsOn2 = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"factDepends",tDependsOn1,tDependsOn2))
				}
				Set tDependsOn1 = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"factDepends",tDependsOn1))
			}
			
			// Look through the supplied fact list and check it against the existence of a defined index
			Set tPtr = 0
			While $listnext(tFactList,tPtr,tFact) {
				Set tFactNo = $$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFact)
				If ##class(%Dictionary.IndexDefinition).%ExistsId(tFactClass_"||"_tFact) {
					Set tIndexList = tIndexList _ $LB(tFact)
				}

				// DP-423547 - Look for any dependsOn indices for this fact and add to the index list
				Set tDepIdx = $O(tDependsOn(tFactNo,""),1,tFactNo2)
				While (tDepIdx'="") {
					Set tDepIndexName = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact#",$P(tDepIdx,"&",1))) _ "AND" _ $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact#",$P(tDepIdx,"&",2)))
					
					// Confirm existence and prevent duplicate entries before adding to the return list
					If ##class(%Dictionary.IndexDefinition).%ExistsId(tFactClass_"||"_tDepIndexName) && '$LISTFIND(tIndexList,tDepIndexName) {
						Set tIndexList = tIndexList _ $LB(tDepIndexName)
					}

					Set tDepIdx = $O(tDependsOn(tFactNo,tDepIdx),1,tFactNo2)
				}
			}
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tIndexList = ""
	}
	
	Quit tIndexList
}

/// Take out locks for the specific column identifiers in a <var>pFactList</var> under the synchronze lock. This
/// will prevent a general build or a synchronize but will not prevent selected updates of other 
/// columns in the fact table.
ClassMethod %LockFactList(pCubeName As %String, pFactList As %List, ByRef pLocked, pLockTimeout = 1) As %Status
{
	// Method added by DTB906
	Set tSC = $$$OK
	Set pLocked = 0
	
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		//Set tLockedList = $LB()
		
		For ii=1:1:$LL(pFactList) {
			Set tColumnID = $LG(pFactList,ii)
			If (tColumnID'="") {
				Lock +^DeepSee.Build(tCubeIndex,"SYNC",tColumnID):pLockTimeout Else  Set tSC = $$$ERROR($$$GeneralError,"Unable to obtain the lock needed to update cube: " _ pCubeName)
				If $$$ISERR(tSC) Quit
			} 
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		// If locking failed, run an unlock on all potential resources
		Do ..%UnlockFactList(tCubeIndex,pFactList)
	}
	Else {
		// Lock succeeded, send notification back to the caller
		Set pLocked = 1
	}
	
	Quit tSC
}

/// Release the update locks for the selected fact list.
ClassMethod %UnlockFactList(pCubeName As %String, pFactList As %List) As %Status
{
	// Method added by DTB906
	Set tSC = $$$OK
	
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		For ii=1:1:$LL(pFactList) {
			Set tColumnID = $LG(pFactList,ii)
			If (tColumnID'="") {
				Lock -^DeepSee.Build(tCubeIndex,"SYNC",tColumnID)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Mark dimensions as enabled or disabled according to <var>pEnabled</var>. If the fact list is not supplied, mark all as enabled. Otherwise,
/// mark only the dimensions supplied in the fact list.<br>
/// This method can also optionally mark that a dimension is in the process of updating using the <var>pInProgress</var> paraeter. 
ClassMethod %MarkFactsEnabled(pCubeName As %String = "", pFactList As %String = "", pEnabled = 1, pInProgress = 0) As %Status
{
	// Method added by DTB908
	Set tSC = $$$OK
	
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
		// DTB961 - Reinforce the list by including the cube in the call to normalize
		Set tFactList = ..%NormalizeFactList(pFactList,.tSC,tCubeIndex)
		If $$$ISERR(tSC) Quit
		
		If '..%IsValidFactList(tCubeIndex,tFactList,.tSC) {
			Quit
		}
		
		// Create a temporary index for identifiying the items in the fact list
		For ii=1:1:$LL(tFactList) {
			Set tFactListArray($$$UPPER($LG(tFactList,ii))) = ""
		}

		// Step through the various facts represented by columnIDs and mark enabled based on the fact list.
		// - This covers dimensions and relationships
		Set tFactNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact#",""),1,tFactID)
		While (tFactNo'="") {
			Do SetFactEnabled(tFactID,pEnabled,pInProgress,.tFactListArray)
			
			Set tFactNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact#",tFactNo),1,tFactID)
		}
		
		// - This covers measures
		Set tMsrNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"msr#",""),1,tMsrID)
		While (tMsrNo'="") {
			Do SetFactEnabled(tMsrID,pEnabled,pInProgress,.tFactListArray)
			
			Set tMsrNo = $O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"msr#",tMsrNo),1,tMsrID)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
	
SetFactEnabled(tFactID,enabled,inProgress,tFactListArray)
	// Check for the use of an alias [defined factName] when searching for the facts to 
	// mark enabled. This performs the actual set.
	Set tColID = ""
	If $D(tFactListArray($$$UPPER(tFactID))) {
		// The logical identifier n the metadata is also the SQL column identifier
		Set tColID = tFactID
	}
	Else {
		// The alias needs to be checked since the logical model name did not match
		Set tAlias = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactID,"alias"),tFactID)
		If $D(tFactListArray($$$UPPER(tAlias))) {
			Set tColID = tAlias
		} 
	}
	
	If '$D(tFactListArray) || (tColID'="") {
		If $D($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactID)) {
			Set $$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactID,"enabled") = enabled
			Set $$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactID,"inProgress") = inProgress
		}
	}

	Quit
}

/// Check to see if a given dimension is currently queryable for a given cube.
ClassMethod %IsFactEnabled(pCubeName As %String = "", pSpec As %String = "", Output pStatus As %Status, Output pFactName As %String, Output pInProgress) As %Boolean
{
	// Method added by DTB908
	Set tReturn = 0
	Set pStatus = $$$OK
	Set pInProgress = 0
	
	Try {
		If (pCubeName="") {
			Set pStatus = $$$ERROR($$$GeneralError,"Cube name must be supplied to %IsFactEnabled")
			Quit
		}
		
		Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pCubeName,.tCubeParseInfo)
		If $$$ISERR(tSC) Quit
		
		// DTB951 - This does not assume the incoming cube name was sanitized to parse into a single 
		// item. Test for multiple pieces after the parse successfully completes.
		Set tLastIdx = $O(tCubeParseInfo(""),-1,tFinalPiece)
		If (tLastIdx = 1) {
			// DTB951 - A simple string or []-quoted cube name has been parsed and we can just use the contents
			// of the only node
			Set tCubeName = tCubeParseInfo(1)
		}
		ElseIf (tLastIdx > 1) {
			// DTB951 - The cube name was not quoted and contains a '.', ':', or some other character that parses
			// into multiple parts. The original incoming pCubeName can be used directly.
			Set tCubeName = pCubeName
		}

		Set tCubeIndex = $$$DeepSeeIndex(tCubeName)
		
		Set pStatus = ..%GetDimensionInfo(tCubeIndex,pSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelation,.tRelationSpec,.tSpecInfo,,0)
		If $$$ISERR(pStatus) Quit
		
		// The plan for relationships is to check the most local relationship reference, and then recursively check deeper levels to make sure all relations and
		// ultimately the actual dimension where it rests in the destination cube
		Set tHasRelation = (tRelation'="")
		
		If tHasRelation {
			// DTB913 - A null reference for a relationship can end up as a single null key, consider this enabled
			Do ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tRelationSpec,.tSpecParseInfo)
			Set tFirstPieceU = $$$UPPER($G(tSpecParseInfo(1)))
			If (tFirstPieceU=$$$UPPER("<null>")) || (tFirstPieceU=$$$UPPER($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"relations",$$$UPPER(tRelation),"nullReplacement"))) {
				Set tReturn = 1
				Quit
			}
			
			Set tFactID = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"relations",$$$UPPER(tRelation),"fact"))
			
			Set pFactName = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"fact","prop",tFactID,"alias"),tFactID)
		}
		Else {
			Set tFactInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
			
			Set tType = $LG(tFactInfo,1)
			If (tType="h") {
				// Special case: the spec was not fully qualified, look for a real level
				Set tLevelNo=$O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo),1,tFactInfo)
				While (tLevelNo'="")&&(tType'="l") {
					Set tType = $LG(tFactInfo,1)
					Set tLevelNo=$O($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo),1,tFactInfo)
				}
			}

			Set tLocation = $S((tType="l"):"fact#",(tType="m"):"msr#",1:"fact#")
			Set tFactNo = $LG(tFactInfo,5)
			// + DTB913 - Special treatment for %COUNT
			If (+$S($E(tFactNo)="M":$E(tFactNo,2,*),1:tFactNo)>1) {
				Set tFactID = $$$DeepSeeMetaGLVN("cubes",tCubeIndex,tLocation,tFactNo)
			}
			ElseIf (($LG(tFactInfo,3)="%COUNT")||(tFactNo=1)||(tType="all")) {
				// There is no metadata for this!
				Set tReturn=1
				Quit
			}
			Else {
				// More sophisticated checking could happen here, but this breaks too much to default to 0! 
				Set tReturn = 1
				Quit
			}
			// - DTB913
			
			Set pStatus = ..%GetDimensionFact(tCubeIndex,tDimNo,tHierNo,tLevelNo,.pFactName)		// DTB911 - Use available API to fetch name
			If $$$ISERR(pStatus) Quit
		}
		
		// Check the enabled status. A missing value should be treated as enabled
		Set tReturn = $$$dsFactEnabled(tCubeIndex,tFactID)
		Set pInProgress = $$$dsFactInProgress(tCubeIndex,tFactID)
		
		// Now recurse into relations if it applies
		If tReturn && tHasRelation && (tRelationSpec'="") {
			Set tRelCube = $$$DeepSeeMetaGLVN("cubes",tCubeIndex,"relations",$$$UPPER(tRelation),"relatedCube")
			Set tReturn = tReturn && ..%IsFactEnabled(tRelCube,tRelationSpec,.pStatus)
			If $$$ISERR(pStatus) Quit
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

/// Test the raw string to verify it is a valid cube name. A valid cube name must begin with an 
/// alpha-numeric character or an underscore. Remaining characters in the cube name must be alpha-numeric,
/// space, underscore, period, slash, and colons.
ClassMethod %IsValidCubeName(pCubeName As %String = "", Output pReason) As %Boolean
{
	// Method Added by DTB951
	Set tIsValid = 1
	Try {
		If (pCubeName="") Quit
		
		// Rules according to documentation:
		// R1: The first character must be either a letter (in the Latin-1 character set), a number, or the underscore character (_).
		Set tFirstChar = $E(pCubeName)
		If '( (tFirstChar?1AN) ||
				(tFirstChar="_") ) {
			Set tIsValid = 0
			Set pReason = 1
			Quit
		}
 
		// R2: The other characters must be either letters, numbers, spaces, underscore, period, slash, or colon characters.
		If '($zstrip(pCubeName,"*"," ._:/")?.AN) {
			Set tIsValid = 0
			Set pReason = 2
			Quit
		}
	}
	Catch ex {
		Set tIsValid = 0
	}

	Quit tIsValid
}

/// Produce a serialized representation of the cube model suitable for import to an AtScale environment.
/// The JSON output will be saved in the file <var>pFileName</var>.<br>
/// If a calendar has been created to support time dimensions in the AtScale environment, that can be passed in
/// via <var>pCalendar</var> using either table or class reference syntax.
ClassMethod %AtScaleExportCube(pCubeName As %String = "", pFileName As %String = "", pCalendar As %String = "") As %Status
{
	// Method added by DP-404535
	Set tSC = $$$OK
	Set tRefIndex = {}
	
	Try {
		If (pFileName="") {
			Set tSC = $$$ERROR($$$FileNameRequired)
			Quit
		}
		If '..%CubeExists(pCubeName,.tSC) {
			Quit
		}
		
		If (pCalendar'="") {
			// DP-408675 - Check for existence of the calendar if provided before handing off
			// to the exporter
			Set tCalendarClass = $TR(pCalendar,"_",".")
			If '##class(%Dictionary.CompiledClass).%ExistsId(tCalendarClass) {
				Set tSC = $$$ERROR($$$ClassDoesNotExist,tCalendarClass)
				Quit
			}

			Set tRefIndex.calendarClass = tCalendarClass
		}
		
		// Prepare the export file. 
		Set tFileStream = ##class(%Stream.FileCharacter).%New()
		Set tSC = tFileStream.LinkToFile(pFileName)
		If $$$ISERR(tSC) Quit
		
		Set tCubeModel = ..%GetModel(pCubeName)
		
		// + DP-410163 - Pre-process the model to run-time ready status before export
		// Resolve inheritance (if any)
		Set tSC = tCubeModel.%ResolveInheritance()
		If $$$ISERR(tSC) Quit

		// Resolve shared dimensions (if any)
		Set tSC = tCubeModel.%ResolveSharedDimensions(.tSharedInfo)
		If $$$ISERR(tSC) Quit

		// Apply overrides to model (if any)
		Set tSC = tCubeModel.%ApplyOverrides($Name(^DeepSee.Overrides))
		If $$$ISERR(tSC) Quit
		// - DP-410163
		
		
		Do tFileStream.WriteLine(tCubeModel.%AtScaleExport(.tSC,.tRefIndex).%ToJSON())
		If $$$ISERR(tSC) Quit
		
		Do tFileStream.%Save()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// This is a compact test to verify that a <var>pCubeName</var> can be updated directly via IUD operations. 
/// This test includes checking for existence, checking that the target is not a subject area,
/// and checking that the target is not abstract. If this method returns false, it will provide a reason for testing
///  false in the <var>pStatus</var> output.
ClassMethod %IsCubePhysical(pCubeName As %String = "", Output pStatus) As %Boolean
{
	// Method added by DP-431688
	Set pStatus = $$$OK

	Try {
		If '..%CubeExists(pCubeName) {
			Set pStatus = $$$ERROR($$$CubeDNE,pCubeName)
		}
		If ('..%IsBaseCube(pCubeName)) {
			Set pStatus = $$$ERROR($$$RejectSubjectArea, $$$dsCurrentMethod, pCubeName)
			Quit
		}
		If (..%IsCubeAbstract(pCubeName)) {
			Set pStatus = $$$ERROR($$$RejectAbstractCube, $$$dsCurrentMethod, pCubeName)
			Quit
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}

	Quit pStatus
}

}
