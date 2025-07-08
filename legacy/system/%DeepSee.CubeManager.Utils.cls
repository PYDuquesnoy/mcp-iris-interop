/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Utility container for the cube manager
Class %DeepSee.CubeManager.Utils Extends %RegisteredObject [ System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

/// THIS METHOD IS DEPRECATED. Refer to %BuildCube in <class>%DeepSee.Utils</class> directly instead.
ClassMethod BuildCube(pCubeName As %String = "", pAsync As %Boolean = 1, pVerbose As %Boolean = 1, pIndexOnly As %Boolean = 0, pMaxFacts As %Integer = 0, pTracking As %Boolean = 0, pRepair As %Boolean = 0, pMapCube As %DeepSee.CubeManager.RegistryMapCube = "", ByRef pBuildStats, pFactList As %String = "") As %Status [ Deprecated ]
{
	// DP-430862 -  This is currently a deprecated pass-through since the base function performs all the same functions
	Quit ##class(%DeepSee.Utils).%BuildCube(.tCubeKey,.pAsync,pVerbose,pIndexOnly,pMaxFacts,pTracking,.pBuildStats, pFactList)
}

/// THIS METHOD IS DEPRECATED. The dependencies built into %BuildCube in <class>%DeepSee.Utils</class> perform the same function and should be used instead.<br>
/// This method will build the target cube, and then trigger a build of the entire list of cubes that depend on it through 
/// cube relationships.<br>
/// Build statistics for each cube in the registry can be returned by reference in <var>pBuildStats(CUBENAME)</var>.
ClassMethod RepairBuild(pCubeName As %String, pMap As %DeepSee.CubeManager.RegistryMap = "", pAsync As %Boolean = 1, pVerbose As %Boolean = 1, pIndexOnly As %Boolean = 0, pMaxFacts As %Integer = 0, pTracking As %Boolean = 0, ByRef pBuildStats, pFactList As %String = "") As %Status [ Deprecated ]
{
	// DP-430862 - The base method builds any dependent cubes by default.
	Quit ##class(%DeepSee.Utils).%BuildCube(pCubeName,pAsync,pVerbose,pIndexOnly,pMaxFacts,pTracking,.pBuildStats,pFactList)
}

/// This is a utility method which executes a complete build of all currently registered cubes in the current cube registry. 
/// The build initiated by this utility will walk through every cube and build it in the order it is listed in
/// the DeepSee Cube Registry page. This can be used to initialize the system, for example after 
/// importing a new registry definition or restoring a backup of the source data.<br>
/// Build statistics for each cube in the registry can be returned by reference in <var>pBuildStats(CUBENAME)</var>.
ClassMethod BuildAllRegisteredGroups(pMap As %DeepSee.CubeManager.RegistryMap = "", ByRef pBuildStats, pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Set tBuildSC = $$$OK
	Try {
		// This will only load the currently active registry
		If pMap = $$$NULLOREF {
			// DTB382 - Load the map from storage if it is not provided by the caller
			Set pMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1)
			If $$$ISERR(tSC) Quit
		}
		
		Kill pBuildStats
		
		Set tGroupIndex=""
		For ii=1:1:pMap.Groups.Count() {
			Set tGroup = pMap.Groups.GetNext(.tGroupIndex)
			
			If ('tGroup.Disabled) {
				// WAL027 added tracking
				Kill tBuildStats
				
				Set tGroupSC = tGroup.BuildGroup(tGroupIndex,,pVerbose,,,1,1,.tBuildStats)
				If $$$ISERR(tGroupSC) Set tBuildSC = $S(tBuildSC:tGroupSC,1:$system.Status.AppendStatus(tBuildSC,tGroupSC))
			
				For {
					Set tStatName = $O(tBuildStats($G(tStatName)),1,tValue)
					Quit:(tStatName="")
					
					If (tStatName="cubes") Continue 
					Do $I(pBuildStats(tStatName),tValue)
				}
				Merge pBuildStats("cubes") = tBuildStats("cubes")		// DTB469 - Add statistics information to the return array
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Set:$$$ISERR(tBuildSC) tSC = tBuildSC

	Quit tSC
}

/// This is a utility method which executes a complete build of one registered cube group in the current cube registry. 
/// The build initiated by this utility will walk through every cube and build it in the order it is listed in
/// the DeepSee Cube Registry page.<br><br>
/// The value of <var>pGroupName</var> must exactly match the case of the registered group name to inititate the 
/// group build.<br>
/// Build statistics for each cube in the group can be returned by reference in <var>pBuildStats(CUBENAME)</var>.
ClassMethod BuildOneRegisteredGroup(pGroupName = "", pMap As %DeepSee.CubeManager.RegistryMap = "", ByRef pBuildStats, pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		// This will only load the currently active registry
		If pMap = $$$NULLOREF {
			// DTB382 - Load the map from storage if it is not provided by the caller
			Set pMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1,.tLookup)
		}
		Else {
			Set tSC = pMap.ToArray(,,,.tLookup)
		}
		If $$$ISERR(tSC) Quit
		
		Kill pBuildStats
		
		If $D(tLookup("groups",pGroupName)) {
			Set tGroupIndex = tLookup("groups",pGroupName)
			// WAL027 add tracking
			Set tSC = pMap.Groups.GetAt(tGroupIndex).BuildGroup(tGroupIndex,,pVerbose,,,1,1,.pBuildStats)	// DTB469 - Return build stats to the caller
		} Else {
			Set tSC = $$$ERROR($$$RegGroupDNE,pGroupName)
		}
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// THIS METHOD IS DEPRECATED - Use <method>%DeepSee.Utils:%SynchronizeCube</method> directly instead.
ClassMethod SynchronizeCube(pCubeName As %String = "", pVerbose As %Boolean = 1, Output pFactsUpdated As %Integer, pReadCommitted As %Boolean = 1, pCheckReferences As %Boolean = 1, pAsync As %Boolean = 0, pMapCube As %DeepSee.CubeManager.RegistryMapCube = "", ByRef pSynchronizeStats) As %Status [ Deprecated ]
{
	// DP-430862 -  This is currently a deprecated pass-through since the base function performs all the same functions
	Quit ##class(%DeepSee.Utils).%SynchronizeCube(pCubeName,pVerbose,.pFactsUpdated,pReadCommitted,pCheckReferences,pAsync,.pSynchronizeStats)
}

/// Used to enter cube information into the Cube Registry Table. This will return an error 
/// if <var>pCubeName</var> refers to a subject area or is undefined. The method 
/// automatically determines whether to update or create a new entry in the registry
/// based on the existence of <var>pCubeName</var>. 
/// <br><br>This can be called from the command line or from UI server
/// processes.
ClassMethod RegisterCube(pCube As %DeepSee.CubeManager.RegistryMapCube = "", pGroup As %DeepSee.CubeManager.RegistryMapGroup = "") As %Status [ Internal ]
{
	// Perform some checks to see if the cube is a new entry or is an update
	set tCubeKey = pCube.CubeKey
	quit:'$data($$$DeepSeeMetaGLVN("cubes",tCubeKey)) $$$ERROR($$$CubeDNE)
	if $data($$$DeepSeeMetaGLVN("cubes",tCubeKey,"baseCube")) {
		// This node is only defined for subject areas
		quit $$$ERROR($$$RegRejectSubjectArea)
	}
	
	// Check to see if this is an update or a new item in the registry
	if ##class(%DeepSee.CubeManager.CubeRegistry).%ExistsId(tCubeKey) {
		set tEventType = "update"
		set tReg = ##class(%DeepSee.CubeManager.CubeRegistry).%OpenId(tCubeKey)
	} else {
		set tEventType = "register"
		set tReg = ##class(%DeepSee.CubeManager.CubeRegistry).%New()
	}
		
	// Transfer input values to the registry and save the cube information
	set tReg.CubeKey = tCubeKey
	set tReg.Disabled = pCube.Disabled  		// Cubes are enabled by default
	set tReg.MgmtGroup = pGroup.GroupName		// DTB588
	set tReg.UpdatePlan = pCube.UpdatePlan
	set tReg.BuildTimeUnit = pCube.BuildTimeUnit
	set tReg.BuildFrequency = pCube.BuildFrequency
	set tReg.SynchTimeUnit = pCube.SynchTimeUnit
	set tReg.SynchFrequency= pCube.SynchFrequency
	set tReg.NaturalBuildOrder = pCube.NaturalBuildOrder
	set tReg.CustomBuildOrder = pCube.CustomBuildOrder
	
	set tSaveStatus = tReg.%Save()
	kill tReg
	
	// Record the event
	set tCubeEvent = ##class(%DeepSee.CubeManager.CubeEvent).%New()
	set tCubeEvent.CubeKey = tCubeKey
	set tSC = tCubeEvent.TransferRegistryInfo(tCubeKey,"register",pCube,pGroup)		// DTB382 - Pass the cube object	// DTB588 - Pass the group object
	set tCubeEvent.EventStatus = tSaveStatus			// This is the status of the tReg.%Save
	set tCubeEvent.CubeEvent = tEventType
	set tCubeEvent.StartTime = $system.SQL.Functions.DATEADD("day",0,$H)
	set tCubeEvent.FinishTime = tCubeEvent.StartTime	// This event type has no meaningful duration
	set tCubeEvent.CubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeKey)
	set tSC=tCubeEvent.%Save()
	
	quit tSC
}

/// Retrieves the timestamp of the the last registered data update for the cube. Updates 
/// performed outside of the Cube Manager will not be recognized in this check. 
ClassMethod GetLastUpdate(pCubeKey, pUpdateType = "synch") As %String
{
	If pUpdateType = "synch" {
		// This is simply the last update to the cube
		&sql(SELECT MAX(FinishTime) INTO :tLastUpdate FROM %DeepSee_CubeManager.CubeEvent WHERE CubeEvent IN ('build','synch','repair') AND CubeKey=:pCubeKey)
	}
	ElseIf pUpdateType = "build" {
		// Building can include "cleaning" type updates, so we should exclude synchs from this check
		&sql(SELECT MAX(FinishTime) INTO :tLastUpdate FROM %DeepSee_CubeManager.CubeEvent WHERE CubeEvent IN ('build','repair') AND CubeKey=:pCubeKey)
	
	}
	Quit $G(tLastUpdate,0)
}

/// Utility method used to determine whether this cube needs to be processed
/// when we write to the registry. Cubes that have not been updated don't 
/// get processed because we don't want to generate a cube history event
/// unnecessarily.
ClassMethod IsUpdate(pCube As %DeepSee.CubeManager.RegistryMapCube, pGroupName As %String) As %Boolean
{
	Set tUpdate = 0
	Set tCubeName = pCube.CubeKey
	Set tRegCube = ##class(%DeepSee.CubeManager.CubeRegistry).%OpenId(tCubeName)
	
	// cube not defined yet -- certainly an update
	If (tRegCube = "") {
		Set tUpdate = 1
		Quit tUpdate
	}
	
	// Check all table properties
	Set:(pGroupName'=tRegCube.MgmtGroup) tUpdate = 1
	Set:(pCube.BuildFrequency'=tRegCube.BuildFrequency) tUpdate = 1
	Set:(pCube.CustomBuildOrder'=tRegCube.CustomBuildOrder) tUpdate = 1
	Set:(pCube.NaturalBuildOrder'=tRegCube.NaturalBuildOrder) tUpdate = 1
	Set:(pCube.BuildTimeUnit'=tRegCube.BuildTimeUnit) tUpdate = 1
	Set:(pCube.SynchFrequency'=tRegCube.SynchFrequency) tUpdate = 1
	Set:(pCube.SynchTimeUnit'=tRegCube.SynchTimeUnit) tUpdate = 1
	Set:(pCube.UpdatePlan'=tRegCube.UpdatePlan) tUpdate = 1
	Set:(pCube.Disabled'=tRegCube.Disabled) tUpdate = 1
	
	Quit tUpdate
}

/// THIS METHOD IS DEPRECATED - The group table is no longer kept in favor of the XML storage scheme.
/// This method should no longer be used. 
ClassMethod RegisterGroup(pGroup As %DeepSee.CubeManager.RegistryMapGroup) As %Status [ Deprecated, Internal ]
{
	Quit $$$ERROR($$$GeneralError,"Deprected")
}

/// This does the actual work of removing a cube from the SQL registry table, and records the event.
ClassMethod UnregisterCube(pCubeName As %String = "", pMapCube As %DeepSee.CubeManager.RegistryMapCube = "") As %Status [ Internal ]
{
	set tCubeKey = $$$UPPER(pCubeName)
	
	set tCubeEvent = ##class(%DeepSee.CubeManager.CubeEvent).%New()
	set tCubeEvent.CubeKey = tCubeKey
	set tSC = tCubeEvent.TransferRegistryInfo(tCubeKey,"unregister",pMapCube)		// DTB382 - Pass the cube object
	if $$$ISERR(tSC) quit tSC		// Cube is not registered or it is disabled
	
	set tCubeEvent.CubeEvent = "unregister"
	set tCubeEvent.CubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeKey)
	set tCubeEvent.StartTime = $system.SQL.Functions.DATEADD("day",0,$H)
	set tCubeEvent.FinishTime = tCubeEvent.StartTime	// This event type has no meaningful duration
	set tCubeEvent.EventStatus = ##class(%DeepSee.CubeManager.CubeRegistry).%DeleteId(tCubeKey)
	set tSC = tCubeEvent.%Save()
	
	quit tSC
}

/// Deletes a whole group from the SQL registry table.
ClassMethod UnregisterGroup(pGroupName As %String = "", pMapGroup As %DeepSee.CubeManager.RegistryMapGroup = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if $IsObject(pMapGroup) {
			Quit:'pMapGroup.IsRegistered
			// DTB382 - If the group object is provided, pass each of the cube objects it contains in the unregister method
			for i=1:1:pMapGroup.Cubes.Count() {
				set tMapCube=pMapGroup.Cubes.GetAt(i)
				Set tSC = ##class(%DeepSee.CubeManager.Utils).UnregisterCube(tMapCube.CubeKey,tMapCube)
				If $$$ISERR(tSC) Quit
			}
		} else {
			set tSQL = "Select CubeKey from %DeepSee_CubeManager.CubeRegistry Where MgmtGroup = ? ORDER BY CustomBuildOrder"
			set tRS = ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL,pGroupName)
			
			while tRS.%Next() {
				Set tSC = ##class(%DeepSee.CubeManager.Utils).UnregisterCube(tRS.%Get("CubeKey"))
				If $$$ISERR(tSC) Quit
			}
		}
	}
	catch ex {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Retrieve the name of the Cube Registry currently marked Active
ClassMethod GetActiveRegistry() As %String
{
	Set tClassName = $G(^DeepSee.CubeManager("activeRegistry"))
	If tClassName'="" {
		&sql(SELECT COUNT(Name) INTO :tClassExists FROM %Dictionary.ClassDefinition WHERE Super = '%DeepSee.CubeManager.RegistryDefinitionSuper' AND Name = :tClassName )
	    If 'tClassExists {
		    Kill ^DeepSee.CubeManager("activeRegistry")
		    Set tClassName = ""
	    }
	}
	Quit tClassName
}

/// Change which Cube Registry is currently active. The Active Registry is the 
/// only one that is visible to the updater tasks. 
ClassMethod SetActiveRegistry(pClassName = "DeepSee.CubeManager.CubeRegistryDefinition", pMustExist = 1) As %Status
{
	If (pClassName = "") {
		Quit $$$ERROR($$$GeneralError,"Cannot set Active Cube Registry to empty string.")
	}
	Set tSC = $$$OK
	Try {
		&sql(SELECT COUNT(Name),Super INTO :tClassExists,:tSuper FROM %Dictionary.ClassDefinition WHERE Name = :pClassName )
		Set tValidRegistryExists = ( tClassExists && ( tSuper["%DeepSee.CubeManager.RegistryDefinitionSuper" ) )
		
		If tValidRegistryExists {
			Set tMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,pClassName,1)
		}
		ElseIf 'tClassExists {
	        If pMustExist {
		        $$$ThrowStatus($$$ERROR($$$GeneralError,$$$Text("Class does not exist","%DeepSee")_": "_pClassName))
	        }

            Set tMap = ##class(%DeepSee.CubeManager.RegistryMap).%New()
            Set tMap.StorageClass = pClassName
            Set tSC = ##class(%DeepSee.CubeManager.Utils).WriteToRegistry(tMap)
		}
		Else {
			$$$ThrowStatus($$$ERROR($$$GeneralError,$$$Text("Class exists, but is not a valid Cube Registry storage class","%DeepSee")_": "_pClassName))
		}
        If $$$ISERR(tSC) Quit
        
        Set tSC = ##class(%DeepSee.CubeManager.Utils).ScheduleUpdaterTasks(tMap)
        If $$$ISERR(tSC) Quit
		
		Set ^DeepSee.CubeManager("activeRegistry") = pClassName
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Retrieve the map that describes the current state of the Cube
/// Registry and all other unregistered cubes on the system. By default, the 
/// currently active registry is loaded first and then this is augmented with 
/// the remaining unregistered natural cube groups. The registry object can be loaded 
/// from a non-active registry class by supplying the name of the alternate storage class 
/// in the <var>pClassName</var> parameter. The unregistered groups may be ignored when 
/// loading the class by setting <var>pRegisteredOnly</var> = 1<br><br>
/// Optionally <var>pLookup</var> may be constructed to provide an index of the ordered locations 
/// of every cube loaded into the map object. This takes the form<br>
/// 	pLookup(<var>CubeKey</var>) = $LB(<var>GroupPosition</var>,<var>CubePosition</var>)<br>
/// <example>
/// Set CubeName = "HOLEFOODS"
/// Set Map = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(,,,.Lookup)
/// Set GroupIdx = $LG(Lookup("cubes",CubeName),1)
/// Set CubeIdx = $LG(Lookup("cubes",CubeName),2)
/// Set Cube = Map.Groups.GetAt(GroupIdx).Cubes.GetAt(CubeIdx)
/// </example>
ClassMethod BuildRegistryMap(ByRef pStatus, pClassName = "", pRegisteredOnly = 0, ByRef pLookup) As %DeepSee.CubeManager.RegistryMap
{
	Set pStatus = $$$OK
	Set tMap = ""
	Kill pLookup
	Try {
		If (pClassName '= "") {
			Set tClassName = pClassName
		}
		ElseIf $D(^DeepSee.CubeManager("activeRegistry")) {
			Set tClassName = ##class(%DeepSee.CubeManager.Utils).GetActiveRegistry()
		}
		Else {
			// DP-431398 - Allow the registry class to be left blank in case no registry exists on the system
			Set tClassName = ""
		}

		
		If (tClassName'="") {
			// Load a pre-existing registry if that is available
			Set tMap = ##class(%DeepSee.CubeManager.RegistryMap).LoadFromClass(tClassName,.pStatus)
			If $$$ISERR(pStatus) Quit		// DTB449

			Set pStatus = tMap.ToArray(,.tRegCubes)
			If $$$ISERR(pStatus) Quit
			
			Set pStatus = ##class(%DeepSee.CubeUtils).%GetCubeGroups(.tNatGroups,.tNatCubes,.tNatBuildOrders)
			If $$$ISERR(pStatus) Quit
			
			For ii=1:1:tMap.Groups.Count() {
				Set tGroup = tMap.Groups.GetAt(ii)
				
				For jj=1:1:tMap.Groups.GetAt(ii).Cubes.Count() {
					Set tCube = tGroup.Cubes.GetAt(jj)
					
					Set tSC = tCube.UpdateSubjectAreas()
					
					// Always fetch the current dependent cubes for this cube.
					Set tCube.DependentCubes = ""
					Set tSC = ##class(%DeepSee.CubeUtils).%GetDependentCubes(tCube.CubeKey,.tDependentCubeList,.tNatGroups,.tNatCubes,.tNatBuildOrders)
					For {
						Set tDepCube = $O(tDependentCubeList($G(tDepCube)))
						Quit:(tDepCube="")

						Set tCube.DependentCubes = tCube.DependentCubes _ $S($L(tCube.DependentCubes):",",1:"") _ tDepCube
					}
					
					Set pLookup("cubes",tCube.CubeKey) = $LB(ii,jj)
				}
				Set pLookup("groups",tGroup.GroupName) = ii
			}
		}
		Else {
			// Initialize an empty map for return.
			Set tMap = ##class(%DeepSee.CubeManager.RegistryMap).%New()
		}
		
		If pRegisteredOnly Quit

		// Remove any registered cubes from the natural arrays and add their remaining contents 		
		// to the Registry Map
		Set tCubeKey = $O(tRegCubes(""))
		While tCubeKey '= "" {
			If $D(tNatCubes(tCubeKey)) {
				Set tGroup = tNatCubes(tCubeKey)
				
				Kill tNatBuildOrders(tGroup,tNatGroups(tGroup,tCubeKey))     
				Kill tNatGroups(tGroup,tCubeKey)
				Kill tNatCubes(tCubeKey)
			}
	
			Set tCubeKey = $O(tRegCubes(tCubeKey))
		}
		
		// Use the pruned natural arrays to augment the loaded registry map 
		// with the unregistered items.
		set tNatGroupIndex = $order(tNatGroups(""))
		Set tNatNamingCounter = tNatGroups		// DTB751 - Start the overflow counter at the largest possible natural group number
		while tNatGroupIndex'="" {
			// DTB751 - Test for collision between the newely generated name and existing registry groups. 
			// If a collision is found, increment the overflow counter and try again.
			Set tNewGroupName = "Group "_tNatGroupIndex
			While $D(pLookup("groups",tNewGroupName)) {
				Set tNewGroupName = "Group "_$I(tNatNamingCounter)
			}
			
			set tGroup = ##class(%DeepSee.CubeManager.RegistryMapGroup).%New(tNewGroupName)
		
			// Loop over the cubes in the registry group and store their information 
			// as children of the group object
			set tNatBuildOrder = $order(tNatBuildOrders(tNatGroupIndex,""))
			while tNatBuildOrder'="" {
				set tCubeName = tNatBuildOrders(tNatGroupIndex,tNatBuildOrder)
				set tCube = ##class(%DeepSee.CubeManager.RegistryMapCube).%New(tCubeName)
				set tCube.NaturalGroup = tNatGroupIndex
				set tCube.NaturalBuildOrder = tNatBuildOrder
				If 'tCube.DSTimeEnabled {
					Set tCube.UpdatePlan = "Build"
				}
				
				// Get the dependent cube list for the unregistered cubes
				Set tCube.DependentCubes = ""
				Set tSC = ##class(%DeepSee.CubeManager.Utils).GetDependentCubes(tCubeName,,.tDependentCubeList,.tNatGroups,.tNatCubes,.tNatBuildOrders)		// DTB353 - Pass in knwn indices
				For {
					Set tDepCube = $O(tDependentCubeList($G(tDepCube)))
					Quit:(tDepCube="")

					Set tCube.DependentCubes = tCube.DependentCubes _ $S($L(tCube.DependentCubes):",",1:"") _ tDepCube
				}
			
				Set tSC = tCube.UpdateSubjectAreas()

				Do tGroup.Cubes.Insert(tCube)
				Set pLookup("cubes",tCube.CubeKey) = $LB(tMap.Groups.Previous("")+1,tGroup.Cubes.Previous(""))
				
				Set tNatBuildOrder = $order(tNatBuildOrders(tNatGroupIndex,tNatBuildOrder))
			}
			
			Do tMap.Groups.Insert(tGroup)
			Set pLookup("groups",tGroup.GroupName) = tMap.Groups.Previous("")
		
			Set tNatGroupIndex = $order(tNatGroups(tNatGroupIndex))
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tMap
}

/// Walk through a CubeManager.RegistryMap object and register the cubes. This saves the 
/// complete registry to an XData block in a container class, and saves limited information
/// to the registry table for SQL reference. 
ClassMethod WriteToRegistry(ByRef pCubeMap As %DeepSee.CubeManager.RegistryMap, ByRef pValidation) As %Status
{
	Set tSC = $$$OK
	
	Try {
		Set InvalidGroups = 0  		// - don't write to registry if groups are invalid 
		
		// Validate each group and save cubes to the table.
		Set tCurrentGroupKey = ""
		For i=1:1:pCubeMap.Groups.Count() {
			Set tCurrentGroup = pCubeMap.Groups.GetNext(.tCurrentGroupKey)
			Set tCurrentGroupName = tCurrentGroup.GroupName 
			If (tCurrentGroup.IsRegistered = 1) {
				// Only record the group in the update table if the group is valid
				Set tCurrentCubeKey = ""
				
				For j = 1:1:tCurrentGroup.Cubes.Count() {
					Set tCurrentCube = tCurrentGroup.Cubes.GetNext(.tCurrentCubeKey)
					
					If '##class(%DeepSee.CubeManager.Utils).IsValidCubeSchedule(tCurrentCube,.tSC) {
						$$$ThrowStatus(tSC)
					}
				
					Set tCurrentCube.CustomBuildOrder = j 
					
					If (##class(%DeepSee.CubeManager.Utils).IsUpdate(tCurrentCube,tCurrentGroupName)) {	
						Set tSC = ##class(%DeepSee.CubeManager.Utils).RegisterCube(tCurrentCube,tCurrentGroup)		// DTB588 - This now accepts the full group object
					}
				}	
			}
			Else {
				// Remove the group from the table and flag the group for removal
				// from the map
				set tSC = ##class(%DeepSee.CubeManager.Utils).UnregisterGroup(tCurrentGroupName,tCurrentGroup)			// DTB382 - Pass in group object
				Set tRemove(tCurrentGroupKey)=""
			}
		}
		
		// Prune the registry for XML storage
		Set tGroupIdx = $O(tRemove(""),-1)
		While tGroupIdx'="" {
			// Loop backward through the RegistryMap groups and remove non-registered items
			// Note: the indices may not be sequential when submitted!
			Do pCubeMap.Groups.RemoveAt(tGroupIdx)
			Set tGroupIdx = $O(tRemove(tGroupIdx),-1)
		}

		Set tSC = pCubeMap.SaveToClass()   
	} 
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Schedule the build and synch tasks according to the settings in a CubeManager.RegistryMap object.
/// A return status of $$$OK indicates that every attempt to create or modify a build/synch task was successful. If the 
/// scheduling encounters an error, the error will be logged to the DeepSee logs and returned in the 
/// <var>pTaskInfo</var> object in the properties <br>
/// - pTaskInfo.ScheduleBuildSC<br>
/// - pTaskInfo.ScheduleSynchSC
ClassMethod ScheduleUpdaterTasks(pCubeMap As %DeepSee.CubeManager.RegistryMap = "", Output pTaskInfo As %DynamicObject = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	//APV - replacing %Zen.ProxyObject with %DynamicObject to allow for exporting pTaskInfo as a JSON object without needing to make %Zen.ProxyObject extend %JSON.Adaptor
	//Set:'$IsObject(pTaskInfo) pTaskInfo = ##class(%ZEN.proxyObject).%New()
	Set:'$IsObject(pTaskInfo) pTaskInfo = ##class(%DynamicObject).%New()
	
	Quit:'$IsObject(pCubeMap) tSC
	
	Try {
		Set tScheduleBuild = 0		// - don't build if no groups are scheduled for build
		Set tScheduleSynch = 0		// - don't synch if no groups are scheduled for synch
		
		Set tCurrentGroupKey = ""
		For i=1:1:pCubeMap.Groups.Count() {
			Set tCurrentGroup = pCubeMap.Groups.GetNext(.tCurrentGroupKey)
			If (tCurrentGroup.IsRegistered = 1) {
				Set tCurrentCubeKey = ""
				For j = 1:1:tCurrentGroup.Cubes.Count() {
					Set tCurrentCube = tCurrentGroup.Cubes.GetNext(.tCurrentCubeKey)
					
					// Find out which tasks this registry requires
					If 'tCurrentGroup.Disabled && 'tCurrentCube.Disabled {
						Set tScheduleBuild = ( tScheduleBuild || (tCurrentCube.UpdatePlan["Build") )
						Set tScheduleSynch = ( tScheduleSynch || (tCurrentCube.UpdatePlan["Synch") )
					}
					
					If (tCurrentCube.UpdatePlan["Synch") {
						// Get Synch Interval in number of minutes
						Set tSynchInterval = tCurrentCube.SynchFrequency * $s(tCurrentCube.SynchTimeUnit="Hour":60,tCurrentCube.SynchTimeUnit="Day":1440,1:1)
						Set tSynchIntervals(tSynchInterval) = ""
					}
				}
			}
		}
		
		
		Set tSuspend = pCubeMap.Disabled
		Set tDailyStartTime = $zth( pCubeMap.BuildStartHour _ ":" _ pCubeMap.BuildStartMinute ) 
		
		If tScheduleBuild {
			Set tSCBuild = ##class(%SYS.Task.DeepSeeBuild).Schedule(tSuspend,0,1,"",tDailyStartTime)		// DTB494
			If $$$ISERR(tSCBuild) {
				Do ##class(%DeepSee.Utils).%WriteToLog("Schedule",$system.Status.GetErrorText(tSCBuild)_":"_$NAMESPACE)
			}
		} Else {
			//Suspend the build task if the the map does not schedule builds
			Set tSCBuild = ##class(%SYS.Task.DeepSeeBuild).Schedule(1)		// DTB494
		}
		Set pTaskInfo.ScheduleBuildSC = tSCBuild
		
		If tScheduleSynch {
			// Find the greatest common denominator for the synch interval. This is how frequently we
			// must schedule the synch task to make sure that it always fires when a cube needs to synch
			set tLowestSynchInterval = $order(tSynchIntervals(""))
			For i=tLowestSynchInterval:-1:1 {
				Set tInterval = $order(tSynchIntervals(""))
				Set tIntervalFound=1
				//Make sure this interval evenly divides all found intervals
				While (tInterval '= "") {
					Set:((tInterval/i) '= (tInterval\i)) tIntervalFound=0
					Set tInterval = $order(tSynchIntervals(tInterval))	
				}
				If (tIntervalFound) {
					Set tScheduleSynchInterval=i
					Quit
				}
			}
			Set tSC = ##class(%DeepSee.CubeManager.Utils).GetSynchScheduleParameters(.tScheduleSynchInterval,.tDailyFrequency,.tDailyFrequencyTime,.tDailyIncrement,.tDailyStartTime)
			If $$$ISERR(tSC) Quit
			
			Set tSCSynch = ##class(%SYS.Task.DeepSeeSynchronize).Schedule(tSuspend, tDailyFrequency, tDailyFrequencyTime, tDailyIncrement,tDailyStartTime)		// DTB494
			If $$$ISERR(tSCSynch) {
				Do ##class(%DeepSee.Utils).%WriteToLog("Schedule",$system.Status.GetErrorText(tSCSynch)_":"_$NAMESPACE)
			}
		} Else {
			//Suspend the synchronize task if the the Registry Map does not schedule any cube synchronization
			Set tSCSynch = ##class(%SYS.Task.DeepSeeSynchronize).Schedule(1)		// DTB494
		}
		Set pTaskInfo.ScheduleSynchSC = tSCSynch

		// DTB433 - This error is returned to the CubeRegistry page on attempt to schedule the tasks.
		// 		The system error may be examined to return a more user-friendly error message.
		//		Do not include the characters ":" or "[" in messages geenrated here as it may get
		//		incorrectly parsed in the UI.
		If ($$$ISOK(tSCBuild)&&$$$ISOK(tSCSynch)) {
			Set tSC = $$$OK
		}
		ElseIf ($system.Status.GetOneErrorText(tSCBuild)["Failed to acquire read lock on instance of '%SYS.Task'") || 
				($system.Status.GetOneErrorText(tSCBuild)["Failed to acquire read lock on instance of '%SYS.Task'") {
			// This error is reported when the tasks fail to open in the sceduler.
			// This occurs when a task is running.
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Failure scheduling updater tasks. At least one task is currently running. See the Business Intelligence log for more details."))
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Error scheduling updater tasks. Check the Business Intelligence Log."))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convenience method -- takes the number of seconds between synchs
/// and sets the parameters for the call to ##class(%DeepSee.CubeManager.Task.Synch).Schedule
ClassMethod GetSynchScheduleParameters(pScheduleSynchInterval As %String = 0, Output pDailyFrequency, Output pDailyFrequencyTime, Output pDailyIncrement, Output pDailyStartTime) [ Internal ]
{
	Set tSC = $$$OK
	Set pDailyFrequency = 1
	Set pDailyFrequencyTime = 0
	Set pDailyIncrement = 60
	Set pDailyStartTime = 0
	
	try {
		// Convert tScheduleSynchInterval from minutes to the appropriate unit
		// And determine parameters for the task
		If (pScheduleSynchInterval <= 59) {
			Set pDailyFrequency=1
			Set pDailyFrequencyTime=0
			Set pDailyIncrement=pScheduleSynchInterval
			Set pDailyStartTime=0
		} 
		Elseif (pScheduleSynchInterval <=1339) {
			Set pDailyFrequency=1
			Set pDailyFrequencyTime=1
			Set pDailyIncrement=(pScheduleSynchInterval\60)
			Set pDailyStartTime=0
		} 
		Else {
			// Schedule to run once per day -- SynchGroup implements rule checking
			Set pDailyFrequency=0
		}
	}
	catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// THIS METHOD IS DEPRECATED. The method %GetCubeFactCount in <class>%DeepSee.Utils</class> should be used instead.
ClassMethod GetCubeSize(pCubeKey) As %Integer [ Deprecated, Internal ]
{
	quit ##class(%DeepSee.Utils).%GetCubeFactCount(pCubeKey)
}

/// - DEPRECATED -<br>
/// Resets the entire cube registry table.
ClassMethod UnregisterAll() As %Status [ Deprecated, Internal ]
{
	Set tSC = $$$OK
	try {	
		/// Clears all cubes from the registry
		set tSQL = "SELECT ID FROM %DeepSee_CubeManager.CubeRegistry"
		set tRS = ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL)
		while tRS.%Next() {
			set tSC = ##class(%DeepSee.CubeManager.Utils).UnregisterCube(tRS.%Get("ID"))
			If $$$ISERR(tSC) Quit
		}
	}
	catch ex {
		set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Retrieves a group by name from the Cube Registry.
ClassMethod GetCubeGroup(pGroupName As %String, pMap As %DeepSee.CubeManager.RegistryMap = "", Output pStatus) As %DeepSee.CubeManager.RegistryMapGroup [ Internal ]
{
	// Method implemented by DTB241
	Set pStatus = $$$OK
	Set tGroup = $$$NULLOREF
	Try {
		// If the map wasn't passed in, get a copy of it.
		If pMap = $$$NULLOREF {
			// DTB382 - Load the map from storage if it is not provided by the caller
			Set pMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1,.tLookup)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = pMap.ToArray(,,,.tLookup)
		}

		Set tGroupIdx = $G(tLookup("groups",pGroupName))
		If tGroupIdx'="" {
			Set tGroup = pMap.Groups.GetAt(tGroupIdx)
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	Quit tGroup
}

/// Merge two array-based cube groups together into a single group. This will automatically determine
/// an acceptable build order for the resulting group and return this in the <var>pMergeGroup</var>
/// array.<br><br>
/// If <var>pMergedGroupName</var> is supplied, this will be the new group name. If this argument
/// is "", the group will inherit the name stored in the array <var>pGroup1</var>.
ClassMethod MergeCubeGroups(ByRef pGroup1, ByRef pGroup2, ByRef pMergeGroup, pMergedGroupName = "") As %Status [ Internal ]
{
	kill pMergeGroup
	try {
		set tSC = $$$OK
		
		// Determine what name should be used for the new group
		set tGroup1Name = $o(pGroup1(""))
		set tGroup2Name = $o(pGroup2(""))
	
		If pMergedGroupName'="" {
			set tGroupName = pMergedGroupName
		}
		Else {
			set tGroupName = tGroup1Name
		}

		// merge the two groups together
		merge pMergeGroup(tGroupName) = pGroup1(tGroup1Name)
		merge pMergeGroup(tGroupName) = pGroup2(tGroup2Name)
		
		set tSC = ##class(%DeepSee.CubeManager.Utils).FindGroupBuildOrders(.pMergeGroup)
	}
	catch ex {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

/// THIS METHOD IS DEPRECATED - Registry groups no longer need to be tested for validity. 
/// Boolean test which returns 1 if the group supplied as the argument is no 
/// less than the union of the natural groups of each of its members. If this 
/// test returns 0, the specific reason for the failure will be recorded in 
/// <var>pStatus</var>.
ClassMethod IsValidGroup(ByRef pGroup As %DeepSee.CubeManager.RegistryMapGroup, ByRef pStatus As %Status, ByRef pGroups, ByRef pCubes, ByRef pBuildOrders) As %Boolean [ Deprecated ]
{
	Set tBool = 0, pStatus = $$$OK
	Try {	
		// Status returns the reason why Validation failed if it did
		Set tMissingCubes = ""
		
		If '$D(pGroups)||'$D(pCubes)||'$D(pBuildOrders) {
			// DTB353 - Only do this if all of the arrays are not already known
			Set pStatus = ##class(%DeepSee.CubeManager.Utils).GetCubeGroups(.pGroups,.pCubes,.pBuildOrders)
			If $$$ISERR(pStatus) {
				Quit
			}
		}
		
		Set pStatus = pGroup.ToArray(.tGroup)
		If $$$ISERR(pStatus) Quit

		Set tGroupName = $O(tGroup(""))
		Set tCube = $O(tGroup(tGroupName,""))
		
		Set tBool = 1  // Return 1 if we do not encounter an error in validity checking
		
		While tCube'="" {
			// Look up the natural group for each cube and make sure all cubes
			// in that group are included in the group being validated.
			Set tNaturalGroup = $G(pCubes(tCube))
			If (tNaturalGroup="")||'##class(%DeepSee.Utils).%CubeExists(tCube) {
				// DTB241 - Add direct test for cube existence.
				$$$ThrowStatus($$$ERROR($$$CubeDNE,tCube)) 
			}
			
			Set tRefCube = $O(pGroups(tNaturalGroup,""))
			While tRefCube'="" {
				// DTB130 - ignore cube versions if they find their way into this list!
				If ('$Data(tGroup(tGroupName,tRefCube))&&'##class(%DeepSee.CubeVersion.Utils).%IsVersion(tRefCube)) {
					// This cube should be in the group passed in.
					// If it's not, switch the return flag and add 
					// the cube name to the error message.
					Set tBool = 0
					Set tMissingCubes = 1
					Set tMissingCubes(tRefCube)=""
				}
				Set tRefCube = $O(pGroups(tNaturalGroup,tRefCube))
			}
			Set tCube = $O(tGroup(tGroupName,tCube))
		}
		If tMissingCubes {
			Set tMissingCubeString = ""
			Set tMissingCube = $O(tMissingCubes(""))
			While tMissingCube'="" {
				Set tMissingCubeString = $S($G(tMissingCubeString)="":tMissingCube,1:tMissingCubeString_","_tMissingCube)
				Set tMissingCube = $O(tMissingCubes(tMissingCube))
			}
			set pStatus = $$$ERROR($$$GeneralError,"Other cubes should be included in group """_pGroup.GroupName_""": "_tMissingCubeString)
		}
	}
	Catch ex {
		Set tBool = 0
		Set pStatus = ex.AsStatus()
	}
	
	Quit tBool
}

/// Validation for the current cube settings. 
ClassMethod IsValidCubeSchedule(pCube As %DeepSee.CubeManager.RegistryMapCube, Output pStatus) As %Boolean
{
	Set tIsValid = 1
	Set pStatus=$$$OK
	Try {
		If 'pCube.DSTimeEnabled && ( pCube.UpdatePlan [ "Synch" ) {
			$$$ThrowStatus($$$ERROR($$$GeneralError,pCube.CubeKey_": "_$$$Text("This cube cannot be synchronized. Please select a different Update Plan","%DeepSee")))
		}

	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tIsValid = 0
	}
	
	Quit tIsValid
}

/// THIS METHOD IS DEPRECATED. Refer to %GetCubeGroups() in <class>%DeepSee.CubeUtils</class> instead.
/// Calculates the natural groups for all cubes on the system. Group information is
/// returned in array form. These arrays are organized as follows: <br><br>
/// <var>pGroups</var>(groupName,cubeKey) = buildOrder<br>
/// <var>pCubes</var>(cubeKey) = groupName<br>
/// <var>pBuildOrders</var>(groupName,buildPosition) = cubeKey<br><br>
/// If the cube has dependencies, there will be an additional array<br><br>
/// <var>pCubes</var>(cubeKey,"dependents")<br><br>
/// which will list the cubes that must be updated if this one has been updated.
ClassMethod GetCubeGroups(ByRef pGroups, ByRef pCubes, ByRef pBuildOrders, pReg = 0) As %Status [ Deprecated ]
{
	// This is called by IsValidGroup(), and so cannot call that!
	Set tSC = $$$OK
	Try {
		set tSC = ##class(%DeepSee.CubeManager.Utils).FindCubeGroups(.pGroups,.pCubes)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%DeepSee.CubeManager.Utils).FindGroupBuildOrders(.pGroups,.pBuildOrders)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// THIS METHOD IS DEPRECATED. Refer to FindCubeGroups() in <class>%DeepSee.CubeUtils</class> instead.
/// Automatically assign groups based on cube relationships. All cubes which 
/// are independent of each other will be assigned to their own group.
ClassMethod FindCubeGroups(ByRef pGroups, ByRef pCubes) As %Status [ Deprecated, Internal ]
{
	try {
		set tSC = $$$OK
		kill pCubes,pGroups
		do ##class(%DeepSee.Utils).%GetCubeList(.tCubeNames,"cubes",1)
		
		set tCubeName=$order(tCubeNames(""))
		//index for current group
		while tCubeName'="" {
		    set tNewGroup = $increment(pGroups)
			kill tGroup
			// Start a temp group with the current cube, then look for any relations
			set tGroup(tCubeName) = $get(pCubes(tCubeName))
		
			// we will always be adding a new group, and the current
			// cube will always be a member of that group
			set pGroups(tNewGroup,tCubeName) = ""
			set pCubes(tCubeName) = tNewGroup
		
			// look for relationships to the current cube
			// +DTB360 - Replace %GetDependencyGraph with direct 
			// reference this cube's relationships
			Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",""))
			While tRelation'="" {
				Set tRelCube = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",tRelation,"relatedCube")))
				Set tIsStored = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",tRelation,"storedSide"))
				If tIsStored {
					Set:'$D(pCubes(tRelCube,"dependents",tCubeName)) x = $I(pCubes(tRelCube,"dependents"))
					Set pCubes(tRelCube,"dependents",tCubeName)=""
				}
				Else {
					Set:'$D(pCubes(tCubeName,"dependents",tRelCube)) x = $I(pCubes(tCubeName,"dependents"))
					Set pCubes(tCubeName,"dependents",tRelCube)=""
				}
				
				set tGroup(tRelCube) = $get(pCubes(tRelCube))
				
				Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",tRelation))
			}
			// -DTB360

			//now I know all cubes in this relationship graph
			//grab all groups listed, remove cubes from old groups 
			//global and add them all to a new group
			set tRelCube = $order(tGroup(""))
			while tRelCube '= "" {
			
				set tGrpIdx = tGroup(tRelCube)
				//tRelCube is one of the member cubes below
				if (tGrpIdx '= "") {
					set tMemberCube = $order(pGroups(tGrpIdx,""))
					while tMemberCube '= "" {
						set pGroups(tNewGroup,tMemberCube) = ""
						set pCubes(tMemberCube) = tNewGroup
						set tMemberCube = $order(pGroups(tGrpIdx,tMemberCube))
					}
					kill pGroups(tGrpIdx)
				}
				else {
					set pGroups(tNewGroup,tRelCube) = ""
					set pCubes(tRelCube) = tNewGroup
				}
				set tRelCube = $order(tGroup(tRelCube))
			}	
			set tCubeName = $order(tCubeNames(tCubeName))	    	
		}		
	
		// The groups currently have gaps in the numbering, which is undesirable. 
		// Go through and rearrange the pGroups 
		kill tGroups
	
		set tOldGroup = $order(pGroups(""))
		While tOldGroup '= "" {
			set tNewGroup = $increment(tGroups)
			merge tGroups(tNewGroup) = pGroups(tOldGroup)
		
			// Go through the group members and update the cubes array
			set tMemberCube = $order(tGroups(tNewGroup,""))
			while tMemberCube '= "" {
				set pCubes = $increment(pCubes)
				set pCubes(tMemberCube)=tNewGroup
			
				set tMemberCube = $order(tGroups(tNewGroup,tMemberCube))
			}

			// Step to next group
			set tOldGroup = $order(pGroups(tOldGroup))
		}
		kill pGroups				// Kill the old non-sequential group list
		merge pGroups = tGroups		// replace it with the new sequential list
	}
	catch ex {
		set tSC = ex.AsStatus()
	}

	quit tSC
}

/// THIS METHOD IS DEPRECATED. Refer to FindGroupBuiildOrders() in <class>%DeepSee.CubeUtils</class> instead.
/// Pass in an array of group members, as found by <method>GetCubeGroups</method>,
/// and determine an acceptable build order. The order is returned as an integer
/// stored in each node of the group:<br>
/// <var>pGroups</var>(<var>group #</var>,<var>Cube</var>) = <var>Build order</var>
/// <br><br>
ClassMethod FindGroupBuildOrders(ByRef pGroups, ByRef pBuildOrders) As %Status [ Deprecated, Internal ]
{
	// Method rewritten by DTB277
	Set tSC = $$$OK
	Try {
		Merge tGroupsRef = pGroups
		Kill pBuildOrders
		//for each cube in the list, get the dependency graph
		Set tGroupIdx = $O(pGroups(""))
		while tGroupIdx'="" {
			Kill tParents,tDependencies,tDepth
			Set tCubeName=$O(pGroups(tGroupIdx,""))
			While tCubeName'="" {
				Set:'$D(tDependencies(tCubeName)) tDependencies(tCubeName) = 0
				Set:'$D(tParents(tCubeName)) tParents(tCubeName) = 0
				
				// DTB360 - Replace %GetDependencyGraph with direct reference to this cube's relationships
				// DP-416595 - Only add cubes already in pGroup to the ordering indices
 				Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",""))
				While tRelation'="" {
					Set tRelCube = $$$UPPER($G($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",tRelation,"relatedCube")))
					If $D(pGroups(tGroupIdx,tRelCube)) {
						Set tIsStored = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",tRelation,"storedSide"))
						If tIsStored {
							Set:'$D(tParents(tCubeName,"par",tRelCube)) tParents(tCubeName) = $I(tParents(tCubeName))
							Set tParents(tCubeName,"par",tRelCube) = ""
							
							Set:'$D(tDependencies(tRelCube,"ch",tCubeName)) tDependencies(tRelCube) = $I(tDependencies(tRelCube))
							Set tDependencies(tRelCube,"ch",tCubeName) = ""
						}
						Else {
							Set:'$D(tParents(tRelCube,"par",tCubeName)) tParents(tRelCube) = $I(tParents(tRelCube))
							Set tParents(tRelCube,"par",tCubeName) = ""
							
							Set:'$D(tDependencies(tCubeName,"ch",tRelCube)) tDependencies(tCubeName) = $I(tDependencies(tCubeName))
							Set tDependencies(tCubeName,"ch",tRelCube) = ""
						}	
					}
					
					Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",tRelation))
				}
				
				Set tCubeName=$O(pGroups(tGroupIdx,tCubeName))
			}
			
			
			// Start out the build order with cubes that we know have zero parents.
			// There is guaranteed to be at least one.
			Set tCubeName = $O(tParents(""),1,tParentCount)
			While tCubeName'="" {
				If tParentCount = 0 {
					// Maintain a relationship depth index. The cubes at depth zero are fully independent.
					Set tDepth(tCubeName) = 0
					Set tDepth(0,tCubeName) = ""
					Kill tParents(tCubeName)
				}
				
				// The first dependency depth can also be filled in on this pass.
				Set tDependentCube = $O(tDependencies(tCubeName,"ch",""))
				While tDependentCube'="" {
					Set tCurrentDepth = 1
					Set tDepth(tDependentCube) = tCurrentDepth
					Set tDepth(tCurrentDepth,tDependentCube) = ""
					Set tDependentCube = $O(tDependencies(tCubeName,"ch",tDependentCube))
				}

				Set tCubeName = $O(tParents(tCubeName),1,tParentCount)
			}
			
			Set tLoopCounter =0
			
			// Keep adding relationship depth while any cube at the current depth has children, then
			// recurse into that depth. The tDepth array will stop growing whenever all cubes at the 
			// current tReferenceDepth have zero children. This condition can only be met once all 
			// cubes in the current group have been processed.
			Set tReferenceDepth = $O(tDepth(0))
			While (tReferenceDepth'="") {
				Set tLoopCounter=tLoopCounter+1
				If tLoopCounter>1000 {
					// Something likely went wrong, break out of what is probably an otherwise infinite loop!
					Set tSC = $$$ERROR($$$GeneralError,"Relationship depth of more than 1000")
					Quit
				}

				Set tCurrentDepth = tReferenceDepth+1
			
				Set tCubeName = $O(tDepth(tReferenceDepth,""))
				While tCubeName'="" {
					// Push all children of any cube assigned to the previous depth down one level.
					Set tDependentCube = $O(tDependencies(tCubeName,"ch",""))
					While tDependentCube'="" {
						If $D(tDepth(tDependentCube)) {
							// Remove the equal-or-shallower entry before adding it at the current depth
							// to avoid duplicate entries. There will be at most one other entry at any given depth.
							Kill tDepth(tDepth(tDependentCube),tDependentCube)
						}

						// Place this cube in the list for the current depth record its position for fast reference.
						Set tDepth(tDependentCube) = tCurrentDepth
						Set tDepth(tCurrentDepth,tDependentCube) = ""
		
						Set tDependentCube = $O(tDependencies(tCubeName,"ch",tDependentCube))
					}
					Set tCubeName = $O(tDepth(tReferenceDepth,tCubeName))
				}
				Set tReferenceDepth = $O(tDepth(tReferenceDepth))
			}
			If $$$ISERR(tSC) Quit
			
			// Use the depth array to assign a build order
			Set tReferenceDepth = $O(tDepth(""))
			While (tReferenceDepth'="") {
				Set tCubeName = $O(tDepth(tReferenceDepth,""))
				While tCubeName'="" {
					// The order within any particular depth is interchangeable for dependency purposes. Use the
					// alphabetic sort provided by the array.
					Set pBuildOrders(tGroupIdx,$I(pBuildOrders(tGroupIdx))) = tCubeName
					Set pGroups(tGroupIdx,tCubeName) = pBuildOrders(tGroupIdx)
					
					Set tCubeName = $O(tDepth(tReferenceDepth,tCubeName))
				}
				Set tReferenceDepth = $O(tDepth(tReferenceDepth))
			}
			
			Set tGroupIdx = $O(pGroups(tGroupIdx))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// THIS METHOD IS DEPRECATED. Refer to %GetDependentCubes() in <class>%DeepSee.CubeUtils</class> instead.<br>
/// This method accumulates the complete list of cubes dependent on this target 
/// cube, based on defined relationships. Every cube in <var>pDependentCubes</var> must be 
/// built following a build of <var>pCubeName</var>. This is an alphabetical
/// list, it is not a build order.<br>
/// The registry map can optionally be passed in as <var>pMap</var> to take
/// advantage of the relationship information already stored in the cube 
/// registry, avoiding the recalcualtion of natural groups on the system.
ClassMethod GetDependentCubes(pCubeName = "", pMap As %DeepSee.CubeManager.RegistryMap = "", Output pDependentCubes, ByRef pGroups, ByRef pCubes, ByRef pBuildOrders) As %Status [ Deprecated ]
{
	Set tSC = $$$OK
	Set pDependentCubes=""
	If (pCubeName="") {
		Quit tSC
	}
	Set tCubeKey = $$$UPPER(pCubeName)
	
	Try {
		Set tSC = ##class(%DeepSee.CubeUtils).%GetDependentCubes(tCubeKey,.tDependentCubes,.pGroups,.pCubes,.pBuildOrders)
		If $$$ISERR(tSC) Quit
		
		// Convert the array into the comma-delimited list that is stored 
		// with the registry.
		Set tDependentCube = $O(tDependentCubes(""))
		While tDependentCube'="" {
			Set pDependentCubes = $G(pDependentCubes)_$S($G(pDependentCubes)'="":",",1:"")_tDependentCube
			Set tDependentCube = $O(tDependentCubes(tDependentCube))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// This is an internal method to keep the SQL references current with the 
/// RegistryMap object representation. This does the actual work of marking 
/// the cube referenced by <var>pCubeName</var> as disabled in the Registry table.
ClassMethod DisableCube(pCubeName) As %Status [ Internal ]
{
	// Add some event record saving
	set tSC = $$$OK
	set tCube = ##class(%DeepSee.CubeManager.CubeRegistry).%OpenId($$$UPPER(pCubeName),,.tSC)
	quit:$$$ISERR(tSC) $SYSTEM.Status.Error($$$ERRORCODE($$$GeneralError),"Cube does not exist in registry table")
	set tCube.Disabled = 1
	quit tCube.%Save()
}

/// This is an internal method to keep the SQL references current with the 
/// RegistryMap object representation. This does the actual work of marking 
/// the cube referenced by <var>pCubeName</var> as enabled in the Registry table.
ClassMethod EnableCube(pCubeName As %String) As %Status [ Internal ]
{
	// Add some event record saving
	set tSC = $$$OK
	set tCube = ##class(%DeepSee.CubeManager.CubeRegistry).%OpenId($$$UPPER(pCubeName),,.tSC)
	quit:$$$ISERR(tSC) $SYSTEM.Status.Error($$$ERRORCODE($$$GeneralError),"Cube does not exist in registry table")
	set tCube.Disabled = 0
	quit tCube.%Save()
}

/// Compile a reference index to look up DeepSee folder items that depend on 
/// cubes and data sources. Each branch of the return array 
/// <br> <var>pCubeIdx(cube)</var> <br> holds all folder items that <b>might</b> 
/// be dependent upon this cube. Before cube removal, all items in this branch 
/// of the tree should be checked for dependency beginning at the leaf nodes.
/// <br><br>
/// A similar strategy should be used when removiung a data source, ie a pivot or a KPI.
/// In this case, the <var>pSourceIdx</var> should be used, as it sorts information 
/// according to the data source.
/// <br><br>
/// it is not trivial to tell if you are actually USING the relationships when 
/// they are defined so the assumption is made that all folderitems pointing to 
/// one are using dimensions from the others in a relationship network.
///  
/// 
ClassMethod GetDSItemItinerary(ByRef byCube, ByRef bySource) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		k Return,byCube,bySource
		set tStatement = ##class(%SQL.Statement).%New(0,"%DeepSee_Dashboard")
		
		// Get the sources used by dashboards 
		set tSC = tStatement.%Prepare("select ID from Definition where fullname NOT['$PREVIEW'")
		set tRS = tStatement.%Execute()
		while tRS.%Next() {
			set tDash = ##class(%DeepSee.Dashboard.Definition).%OpenId(tRS.%Get("ID"))
			for ii=1:1:tDash.widgets.Count() {
				set tSource = tDash.widgets.GetAt(ii).dataSource
				set:tSource'="" bySource($p(tSource,".",$l(tSource,".")),tSource,"dashboard",tDash.name) = tDash.%Id()		
			}
		}
		
		// Get the pivots based on cubes. Merge the information above into the 
		// cube reference as well
		set tSC = tStatement.%Prepare("select ID,fullName,cubename from Pivot") 
		set tRS = tStatement.%Execute()
		while tRS.%Next() {
			set tCube = $$$UPPER(tRS.%Get("cubename"))
			set tPivot = tRS.%Get("fullname")
			set byCube(tCube,"pivot",tPivot) = tRS.%Get("ID")
			// If the pivot was found in the dashboard search, add as dependent on this cube
			if $d(bySource("pivot",tPivot)) {
				merge byCube(tCube,"pivot",tPivot) = bySource("pivot",tPivot)
			}
			
			s tBase = ##class(%DeepSee.Utils).%GetBaseCube(tCube)
			if tBase'="" {
				// This cube is a subject area. Add other nodes
				// storing its same dependencies on the base cube.
				If ##class(%DeepSee.Utils).%IsCubeCompound(tCube,.tJoin) {
					for ii=1:1:$l(tJoin,",") {
						// Subject area is a compound cube definition. 
						// All cubes involved should be added to the list.
						merge byCube($$$UPPER($p(tJoin,",",ii))) = byCube(tCube)
						do CheckRelated($$$UPPER($p(tJoin,",",ii)))
					}
				} 
				else {
					// This subject area is not compound, and so has only one base cube.
					// Check this cube for relationships
					merge byCube(tBase) = byCube(tCube)
					do CheckRelated(tBase)
				}
			}
			else {
				// This is a standard cube. Check for relationships
				do CheckRelated(tCube)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
	
CheckRelated(pCube)	

	kill tGraph
	// This cube is not a subject area. See if it depends on other
	// cubes due to relationships.
	do ##class(%DeepSee.Utils).%GetDependencyGraph(.tGraph,pCube)
	set tDepCube = $o(tGraph(""))
	while tDepCube'="" {
		set tIndCube = $o(tGraph(tDepCube,""))
		while tIndCube'="" {
			merge byCube(tIndCube) = byCube(pCube)
			set tIndCube = $o(tGraph(tDepCube,tIndCube))
		}
		set tDepCube = $o(tGraph(tDepCube))
	}
	quit
}

/// Set the flag which unlocks the ability to choose independent synchronization in the Cube Registry page.
/// Independent synchronization allows for the group synchronization to skip the triggered update due to relationship
/// dependency and trigger the update only due to scheduling.
ClassMethod SetIndependentGroupSync(pIndependent = 0) As %Status [ Internal ]
{
	// Method added by DTB470
	Set tSC = $$$OK
	Try {
		Set ^DeepSee.CubeManagerSettings("enableIndependentSync") = pIndependent
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the flag which unlocks the ability to choose independent synchronization in the Cube Registry page.
ClassMethod GetIndependentGroupSync() As %Boolean [ Internal ]
{
	// Method added by DTB470
	Quit +$Get(^DeepSee.CubeManagerSettings("enableIndependentSync"),0)
}

}
