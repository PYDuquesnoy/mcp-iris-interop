/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is responsible for exposing the functionality of %DeepSee.CubeManager.Utils via REST APIs
Class %DeepSee.REST.v2.CommandServer Extends %DeepSee.REST.REST
{

XData UrlMap
{
<Routes>
   <!-- Send objects in this format: {"MDX":"QUERY"} HTTP method: POST -->
   <Route Url="/BuildCube" Method="POST" Call="BuildCube"/>
   <Route Url="/RepairBuild" Method="POST" Call="RepairBuild"/>
   <Route Url="/BuildAllRegisteredGroups" Method="POST" Call="BuildAllRegisteredGroups"/>
   <Route Url="/BuildOneRegisteredGroup" Method="POST" Call="BuildOneRegisteredGroup"/>
   <Route Url="/SynchronizeCube" Method="POST" Call="SynchronizeCube"/>
   <Route Url="/GetLastUpdate" Method="POST" Call="GetLastUpdate"/>
   <Route Url="/GetActiveRegistry" Method="POST" Call="GetActiveRegistry"/>
   <Route Url="/SetActiveRegistry" Method="POST" Call="SetActiveRegistry"/>
   <Route Url="/BuildRegistryMap" Method="POST" Call="BuildRegistryMap"/>
   <Route Url="/WriteToRegistry" Method="POST" Call="WriteToRegistry"/>
   <Route Url="/ScheduleUpdaterTasks" Method="POST" Call="ScheduleUpdaterTasks"/>
   <Route Url="/GetSynchScheduleParameters" Method="POST" Call="GetSynchScheduleParameters"/>
   <Route Url="/GetCubeSize" Method="POST" Call="GetCubeSize"/>
   <Route Url="/IsValidGroup" Method="POST" Call="IsValidGroup"/>
   <Route Url="/IsValidCubeSchedule" Method="POST" Call="IsValidCubeSchedule"/>
  </Routes>
}

ClassMethod %ValidateRequest(pUrl As %String, pMethod As %String) As %Status
{
	Set tSC = $$$OK
	Try{
		If (pMethod="POST") {
			Set tContentObj = %request.Content
			//[ is the 'contains' operator
			
			If (pUrl["/RepairBuild") {
				Set cubeName = tContentObj.cubeName
				If ($G(cubeName)=""){
					Set tSC = $$$ERROR($$$PropertyRequired,"cubeName")
					Quit
				}
			}
			
			If (pUrl["/RegisterGroup") {
				Set group = tContentObj.group
				If ($G(group)=""){
					Set tSC = $$$ERROR($$$PropertyRequired,"group")
					Quit
				}
			}
			
			
			If (pUrl["/IsValidCubeSchedule") {
				Set cube = tContentObj.cube
				If ($G(cube)=""){
					Set tSC = $$$ERROR($$$PropertyRequired,"cube")
					Quit
				}
			}
			
			If (pUrl["/GetLastUpdate" || (pUrl["/GetCubeSize")) {
				Set cubeKey = tContentObj.cubeKey
				If ($G(cubeKey)=""){
					Set tSC = $$$ERROR($$$PropertyRequired,"cubeKey")
					Quit
				}
			}	
		}
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// A wrapper for <method>%DeepSee.Utils.%BuildCube</method> which records 
/// cube event information when building the cube.
/// Required Properties: cubeName
/// Optional Properties: async, indexOnly, maxFacts, tracking, mapCube, buildStats, factList
ClassMethod BuildCube(namespace As %String) As %Status
{
	Set tSC = $$$OK
	Set answer={}
	Set errorExists=0
	Try{
		Set tSC = ..%SetRequestField("cubeName", %request.Content.cubeName, "",.cubeName)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("async", %request.Content.async, 1,.async)	
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("indexOnly", %request.Content.indexOnly, 0,.indexOnly)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("maxFacts", %request.Content.maxFacts, 0,.maxFacts)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("tracking", %request.Content.tracking, 0,.tracking)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("mapCube", %request.Content.mapCube, "",.mapCube, "%DeepSee.CubeManager.RegistryMapCube")
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("buildStats", %request.Content.buildStats,,.buildStats)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("factList", %request.Content.factList, "", .factList)
		
		Set tSC = ##class(%DeepSee.Utils).%BuildCube(cubeName,
														async,
														0, //Setting verbose to 0 to ensure the output is only JSON
														indexOnly,
														maxFacts,
														tracking,
														.buildStats,
														factList)
		
		If $$$ISERR(tSC) Quit

		Set cubeIndex = $$$DeepSeeIndex(cubeName)
		If ($D(buildStats)) {
			Set buildStatsJSON = {}
			For {
				Set stat = $O(buildStats($G(stat))) 
				Quit:(stat="") 
				Continue:(stat="cubes")
				Do buildStatsJSON.%Set(stat, buildStats(stat))			
			}	
			Do buildStatsJSON.%Set("status",buildStats("cubes",cubeIndex,"status"))
			If $$$ISERR(buildStatsJSON.%Get("status")) {
				 	S errorExists=1
				 	Do buildStatsJSON.%Set("status", $System.Status.GetErrorText(buildStatsJSON.%Get("status")))
			}
			Do answer.%Set("buildStats", buildStatsJSON)
		}											
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do ..%SetAnswerStatus(.answer, errorExists, tSC, "buildStats")
	Do answer.%ToJSON()
	Quit $$$OK
}

/// This method provides a means of doing an unscheduled repair build of a registered cube.
/// Required Properties: cubeName
/// Optional Properties: map, async, indexOnly, maxFacts, tracking, buildStats, factList
ClassMethod RepairBuild(namespace As %String) As %Status
{
	Set answer={}
	Set tSC=$$$OK
	Set errorExists=0
	S listOfBuildStatsWithError=""
	Try{
		Set cubeName = %request.Content.cubeName
		Set tSC= ..%SetRequestField("map", %request.Content.map, "", .map, "%DeepSee.CubeManager.RegistryMap")
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("async", %request.Content.async, 1, .async)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("indexOnly", %request.Content.indexOnly, 0, .indexOnly)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("maxFacts", %request.Content.maxFacts, 0, .maxFacts)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("tracking", %request.Content.tracking, 0, .tracking)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("buildStats", %request.Content.buildStats,,.buildStats)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("factList", %request.Content.factList, "", .factList)
		
		Set tSC = ##class(%DeepSee.Utils).%BuildCube(cubeName,
														async,
														0, //Setting verbose to 0 to ensure the output is only JSON
														indexOnly,
														maxFacts,
														tracking,
														.buildStats,
														factList)
															
		If $$$ISERR(tSC) Quit
		
		Set buildStatsList={} //This will store a list of buildStats JSON objects
		Set i=1
		
		If ($D(buildStats)){
			For {
				Set cubeIndex = $O(buildStats("cubes",$G(cubeIndex)))
				Quit:(cubeIndex="")
				Set buildStatsJSON = {}
				
				For {
					Set stat = $O(buildStats("cubes",cubeIndex,$G(stat)))
					Quit:(stat="")
					Do buildStatsJSON.%Set(stat, buildStats("cubes",cubeIndex, stat))
				}
				If $$$ISERR(buildStats("cubes",cubeIndex, "status")) {
				 	S errorExists=1
				 	Set listOfBuildStatsWithError = listOfBuildStatsWithError_$lb(i)		// DP-427658 - Faster list accumulation
				 	Do buildStatsJSON.%Set("status", $System.Status.GetErrorText(buildStatsJSON.%Get("status")))
			 	}
			 	Do buildStatsList.%Set("buildStats_"_i, buildStatsJSON)
				Set i = i+1
			}
			Do answer.%Set("buildStats", buildStatsList)	
		}														
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do ..%SetAnswerStatus(.answer, errorExists, tSC, "buildStats", listOfBuildStatsWithError)
	Do answer.%ToJSON()
	Quit $$$OK
}

/// This is a utility method which executes a complete build of all currently registered cubes in the current cube registry.
/// Required Properties: None
/// Optional Properties: map, buildStats
ClassMethod BuildAllRegisteredGroups(namespace As %String) As %Status
{
	Set answer={}
	Set tSC=$$$OK
	Set errorExists=0
	S listOfBuildStatsWithError=""
	Try{
		Set tSC= ..%SetRequestField("map", %request.Content.map, "", .map, "%DeepSee.CubeManager.RegistryMap")
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("buildStats", %request.Content.buildStats,,.buildStats)
		
		Set tSC = ##class(%DeepSee.CubeManager.Utils).BuildAllRegisteredGroups(map, 
																			   .buildStats, 
																			   0)
																
		If $$$ISERR(tSC) Quit
		
		Set buildStatsList={}
		Set i=1
		
		If ($D(buildStats)){
			For {
				Set cubeIndex = $O(buildStats("cubes",$G(cubeIndex)))
				Quit:(cubeIndex="")
				Set buildStatsJSON = {}

				For {
					Set stat = $O(buildStats("cubes",cubeIndex, $G(stat)))
					Quit:(stat="")
					Do buildStatsJSON.%Set(stat, buildStats("cubes",cubeIndex, stat))
				}
				If $$$ISERR(buildStats("cubes",cubeIndex, "status")) {
				 	S errorExists=1
				 	Set listOfBuildStatsWithError = listOfBuildStatsWithError_$lb(i)		// DP-427658 - Faster list accumulation
				 	Do buildStatsJSON.%Set("status", $System.Status.GetErrorText(buildStatsJSON.%Get("status")))
			 	}
				Do buildStatsList.%Set("buildStats_"_i, buildStatsJSON)
				Set i = i+1	
			}
		}	
		Do answer.%Set("buildStats", buildStatsList)											
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}

	Do ..%SetAnswerStatus(.answer, errorExists, tSC, "buildStats", listOfBuildStatsWithError)
	Do answer.%ToJSON()
	Quit $$$OK
}

/// This is a utility method which executes a complete build of one registered cube group in the current cube registry.
/// Required Properties: None
/// Optional Properties: groupName, map, buildStats
ClassMethod BuildOneRegisteredGroup(namespace As %String) As %Status
{
	Set answer={}
	Set tSC=$$$OK
	Set errorExists=0
	S listOfBuildStatsWithError=""
	Try{
		Set tSC= ..%SetRequestField("groupName", %request.Content.groupName, "", .groupName)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("map", %request.Content.map, "", .map, "%DeepSee.CubeManager.RegistryMap")
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("buildStats", %request.Content.buildStats,,.buildStats)
		
		Set tSC = ##class(%DeepSee.CubeManager.Utils).BuildOneRegisteredGroup(groupName,
																			  map,
																			  .buildStats,
																			  0)
																
		If $$$ISERR(tSC) Quit

		Set buildStatsList={}
		Set i=1

		If ($D(buildStats)){
			For {
				Set cubeIndex = $O(buildStats("cubes",$G(cubeIndex)))
				Quit:(cubeIndex="")
				Set buildStatsJSON = {}				
				
				For {
					Set stat = $O(buildStats("cubes",cubeIndex, $G(stat)))
					Quit:(stat="")
					Do buildStatsJSON.%Set(stat, buildStats("cubes",cubeIndex, stat))
				}
				If $$$ISERR(buildStats("cubes",cubeIndex, "status")) {
				 	S errorExists=1
				 	Set listOfBuildStatsWithError = listOfBuildStatsWithError_$lb(i)		// DP-427658 - Faster list accumulation
				 	Do buildStatsJSON.%Set("status", $System.Status.GetErrorText(buildStatsJSON.%Get("status")))
			 	}
				Do buildStatsList.%Set("buildStats_"_i, buildStatsJSON)
				Set i = i+1
			}
		}				
		Do answer.%Set("buildStats", buildStatsList)
										
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do ..%SetAnswerStatus(.answer, errorExists, tSC, "buildStats", listOfBuildStatsWithError)
	Do answer.%ToJSON()
	
	Quit $$$OK
}

/// A wrapper for <method>%DeepSee.Utils.%SynchronizeCube</method> which records 
/// cube event information when building the cube.
/// Required Properties: None
/// Optional Properties: cubeName, readCommitted, checkReferences, async, mapCube, synchronizeStats
ClassMethod SynchronizeCube(namespace As %String) As %Status
{
		
	Set answer={}
	Set tSC=$$$OK
	Set errorExists=0
	S listOfBuildStatsWithError=""
	Try{
		Set tSC= ..%SetRequestField("cubeName", %request.Content.cubeName, "", .cubeName)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("readCommitted", %request.Content.readCommitted, 1, .readCommitted)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("checkReferences", %request.Content.checkReferences, 1, .checkReferences)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("async", %request.Content.async, 0, .async)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("mapCube", %request.Content.mapCube, "", .mapCube, "%DeepSee.CubeManager.RegistryMapCube")
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("synchronizeStats", %request.Content.synchronizeStats,,.synchronizeStats) //No default value being passed since this is ByRef
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%DeepSee.Utils).%SynchronizeCube(cubeName,
																0,
																.factsUpdated,
																readCommitted,
																checkReferences,
																async,
																.synchronizeStats)
															  														
		If $$$ISERR(tSC) Quit

		Set cubeIndex = $$$DeepSeeIndex(cubeName)
		If ($D(factsUpdated)){
			Do answer.%Set("factsUpdated",factsUpdated(cubeIndex))
		}
		If ($D(synchronizeStats)) {
			Set synchronizeStatsJSON = {}
			For {
				Set stat = $O(synchronizeStats($G(stat)))
				Quit:(stat="") 
				Continue:(stat="cubes")
				Do synchronizeStatsJSON.%Set(stat, synchronizeStats(stat))			
			}	
			Do synchronizeStatsJSON.%Set("status",synchronizeStats("cubes",cubeIndex,"status"))
			If $$$ISERR(synchronizeStatsJSON.%Get("status")) {
				 	S errorExists=1
				 	Do synchronizeStatsJSON.%Set("status", $System.Status.GetErrorText(synchronizeStatsJSON.%Get("status")))
			}
			Do answer.%Set("synchronizeStats", synchronizeStatsJSON)
		}									
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do ..%SetAnswerStatus(.answer, errorExists, tSC, "synchronizeStats")
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Retrieves the timestamp of the the last registered data update for the cube. Updates 
/// performed outside of the Cube Manager will not be recognized in this check. 
/// Required Properties: cubeKey
/// Optional Properties: updateType
ClassMethod GetLastUpdate(namespace As %String) As %Status
{
	Set tSC=$$$OK
	Set answer={}
	Do answer.%Set("tSC", tSC)

	Try{
		Set tSC= ..%SetRequestField("updateType", %request.Content.updateType, "synch",.updateType)
		
		Set lastUpdateJSON = ##class(%DeepSee.CubeManager.Utils).GetLastUpdate(%request.Content.cubeKey, 
																						  updateType)
		Do answer.%Set("lastUpdate", lastUpdateJSON)
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Retrieve the name of the Cube Registry currently marked Active
/// Required Properties: None
/// Optional Properties: None
ClassMethod GetActiveRegistry(namespace As %String) As %Status
{
  
	Set answer = {}
	Set activeRegistry=##class(%DeepSee.CubeManager.Utils).GetActiveRegistry()
	Do answer.%Set("activeRegistry", activeRegistry)
	Do answer.%Set("Error", "")
	Do answer.%Set("status", $$$OK)  
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Change which Cube Registry is currently active. The Active Registry is the 
/// only one that is visible to the updater tasks. 
/// Required Properties: None
/// Optional Properties: className, mustExist
ClassMethod SetActiveRegistry(namespace As %String) As %Status
{
	
	Set answer={}
	Set tSC=$$$OK
	Try{
		Set tSC= ..%SetRequestField("className", %request.Content.className,"DeepSee.CubeManager.CubeRegistryDefinition",.className)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("mustExist", %request.Content.mustExist,1,.mustExist)	
		Set tSC =  ##class(%DeepSee.CubeManager.Utils).SetActiveRegistry(className, 
																		 mustExist)											
		If $$$ISERR(tSC) Quit
								
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Retrieve the map that describes the current state of the Cube Registry and all other unregistered cubes on the system.
/// Required Properties: None 
/// Optional Properties: className, registeredOnly
/// For the lookup variable in the output JSON, for each array in the "cubes" object, the first value corresponds to that 
/// the GroupIdx value and the second the CubeIdx value for that cube. The Cube can then be retrieved as follows:
/// Set Cube = Map.Groups.GetAt(GroupIdx).Cubes.GetAt(CubeIdx)
ClassMethod BuildRegistryMap(namespace As %String) As %Status
{
	
	Set answer={}
	Set tSC=$$$OK
	
	Try{
		Set tSC= ..%SetRequestField("status", %request.Content.status,,.status) //No default value being passed since this is ByRef
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("className", %request.Content.className,"",.className)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("registeredOnly", %request.Content.registeredOnly,0,.registeredOnly)	
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("lookup", %request.Content.lookup,,.lookup) //No default value being passed since this is ByRef
		
		Set registryMap =  ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.status,
																				className,
																				registeredOnly,
																				.lookup)
		
		If $$$ISERR(status) Quit
		Set tSC = registryMap.%JSONExportToString(.registryMapString)
		If $$$ISERR(tSC) Quit
		Do answer.%Set("registryMap", registryMapString)			
		If ($D(lookup))
		{
			Set lookupJSON = ..%lookup2JSON(.lookup)
			Do answer.%Set("lookup", lookupJSON)
			
		}	
										
		If $$$ISERR(tSC) {
			Quit
		}									
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()
	
	Quit $$$OK
}

/// Walk through a CubeManager.RegistryMap object and register the cubes.
/// Required Properties: cubeMap
/// Optional Properties: None
ClassMethod WriteToRegistry(namespace As %String)
{
	
	Set answer={}
	Set tSC=$$$OK
	Try{
		Set tSC= ..%SetRequestField("cubeMap", %request.Content.cubeMap,,.cubeMap, "%DeepSee.CubeManager.RegistryMap")
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("validation", %request.Content.validation,,.validation) //validation is a string
		Set tSC = ##class(%DeepSee.CubeManager.Utils).WriteToRegistry(.cubeMap,
																	  .validation)															  
		If $$$ISERR(tSC) Quit
		Set tSC = cubeMap.%JSONExportToString(.cubeMapString)
		If $$$ISERR(tSC) Quit				
		Do answer.%Set("cubeMap", cubeMapString)					
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC){
		If $D(validation) Do answer.%Set("validation", validation) //'validation' will contain a value if there was a problem with missing groups/invalid groups
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%Set("tSC", tSC)
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Schedule the build and synch tasks according to the settings in a CubeManager.RegistryMap object.
/// Required properties: None
/// Optional properties: cubeMap
ClassMethod ScheduleUpdaterTasks(namespace As %String) As %Status
{
	
	Set answer={}
	Set tSC=$$$OK

	Try{
		Set tSC= ..%SetRequestField("cubeMap", %request.Content.cubeMap,"",.cubeMap, "%DeepSee.CubeManager.RegistryMap")
		
		Set tSC =  ##class(%DeepSee.CubeManager.Utils).ScheduleUpdaterTasks(cubeMap,
																			.taskInfo)																
		If $$$ISERR(tSC) Quit
		
		Do answer.%Set("taskInfo", taskInfo)
		
		If $$$ISERR(tSC) Quit									
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Convenience method -- takes the number of seconds between synchs
/// and sets the parameters for the call to %SYS.Task.DeepSeeSynchronize:Schedule() 
/// Required Properties: None
/// Optional Properties: scheduleSynchInterval, dailyFrequency, dailyFrequencyTime, dailyIncrement, dailyStartTime
ClassMethod GetSynchScheduleParameters(namespace As %String) As %Status
{
	Set answer={}
	Set tSC=$$$OK

	Try{
		Set tSC= ..%SetRequestField("scheduleSynchInterval", %request.Content.scheduleSynchInterval,0,.scheduleSynchInterval)
		If $$$ISERR(tSC) Quit

		Set tSC =  ##class(%DeepSee.CubeManager.Utils).GetSynchScheduleParameters(scheduleSynchInterval, 
																				  .dailyFrequency, 
																				  .dailyFrequencyTime, 
																				  .dailyIncrement, 
																				  .dailyStartTime)
		
		If $$$ISERR(tSC) Quit
		Set synchParamsJSON={}
		Set synchParamsJSON.dailyFrequency = dailyFrequency
		Set synchParamsJSON.dailyFrequencyTime = dailyFrequencyTime
		Set synchParamsJSON.dailyIncrement = dailyIncrement
		Set synchParamsJSON.dailyStartTime = dailyStartTime
		
		Do answer.%Set("synchParams", synchParamsJSON)
		If $$$ISERR(tSC) Quit						
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Given the logical name, <var>pCubeName</var> of a DeepSee cube,
/// return the number of rows within its fact table.
/// Required Properties: None
/// Optional Properties: cubeKey
ClassMethod GetCubeSize(namespace As %String) As %Status
{
	
	Set tSC=$$$OK
	Set answer={}
 
	Try{
		Set tSC= ..%SetRequestField("cubeKey", %request.Content.cubeKey,,.cubeKey)
		Set cubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(cubeKey)
		Do answer.%Set("cubeSize", cubeSize)
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()

	Quit $$$OK
}

/// Boolean test which returns 1 if the group supplied as the argument is no 
/// less than the union of the natural groups of each of its members.
/// Required Properties: group
/// Optional Properties: groups, cubes, buildOrders
ClassMethod IsValidGroup(namespace As %String) As %Status
{
	Set answer={}
	Set tSC=$$$OK
	Try{
		Set tSC= ..%SetRequestField("group", %request.Content.group,,.group, "%DeepSee.CubeManager.RegistryMapGroup") 
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("status", %request.Content.status,,.tSC)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("groups", %request.Content.groups,,.groups)
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("cubes", %request.Content.cubes,,.cubes)		
		If $$$ISERR(tSC) Quit
		Set tSC= ..%SetRequestField("buildOrders", %request.Content.buildOrders,,.buildOrders)	
		Set isValid = ##class(%DeepSee.CubeManager.Utils).IsValidGroup(.group, 
																	   .status, 
																	   .groups, 
																	   .cubes, 
																	   .buildOrders)
		Set tSC=status	
		Do answer.%Set("isValid", isValid)
		Do group.%JSONExportToString(.groupString)
		Do answer.%Set("group", groupString)
		If $$$ISERR(tSC) Quit
		
		Do answer.%Set("groups",..%Array2JSON(.groups))
		Do answer.%Set("cubes",..%Array2JSON(.cubes))
		Do answer.%Set("buildOrders",..%Array2JSON(.buildOrders))
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()
	Quit $$$OK
}

/// Validation for the current cube settings. 
/// Required Properties: cube
/// Optional Properties: None
ClassMethod IsValidCubeSchedule(namespace As %String) As %Status
{
	Set answer={}
	Set tSC=$$$OK

	Try{
		Set tSC= ..%SetRequestField("cube",%request.Content.cube,,.cube,"%DeepSee.CubeManager.RegistryMapCube")
		Set isValid = ##class(%DeepSee.CubeManager.Utils).IsValidCubeSchedule(cube,
																			  .tSC)
		Do answer.%Set("isValid", isValid)																	  																	  													 
		If $$$ISERR(tSC) Quit

	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Do answer.%ToJSON()
	Quit $$$OK
}

/// This method is very specific to the APIs currently written in %DeepSee.REST.v2.CommandServer and is designed to be a utility function only for that class 
/// <var>answer</var> is a dynamic abstract object, <var>errorExists</var> is a 0 or 1 indicating if an error has occured or not. If <var>errorExists</var> is 1,
/// <var>tSC</var> is the status variable to be returned from the methodthat is invoking this method 
/// <var>listOfStatusVarWithError</var> is a list of integers used for methods like /Command/RepairBuild and /Command/BuildAllRegisteredGroups where the variable containing the 
/// status (such as buildStats for these 2 APIs) has 2 indices and the <var>answer</var> needs to indicate which buildstat contains the error  
ClassMethod %SetAnswerStatus(ByRef answer, errorExists As %Integer, tSC As %Status, statusVarName As %String, listOfStatusVarWithError = "") As %Status
{
	Do answer.%Set("Error", $System.Status.GetErrorText(tSC))
	If ( (errorExists) && (listOfStatusVarWithError'="")) {
		//stringOfErroneousIndices is a string that contains a comma separated list of all the status variables that contain errors
		S stringOfStatusVarWithError=""
		S ptr=0
		S count=0
		While $LISTNEXT(listOfStatusVarWithError,ptr,value) {
		  If count=0{
		  	S stringOfErroneousIndices = value
		  }
		  Else{
		  	S stringOfErroneousIndices = stringOfErroneousIndices_","_value
		  }
	      S count=count+1
	    }
		Do answer.%Set("Error", $System.Status.GetErrorText($$$ERROR($$$GeneralError,"Error reported in the following "_statusVarName_": "_stringOfErroneousIndices)))
	}
	ElseIf((errorExists) && (listOfStatusVarWithError="")){
		Do answer.%Set("Error", $System.Status.GetErrorText($$$ERROR($$$GeneralError,"Error reported in "_statusVarName)))
	}
	Do answer.%Set("status", $System.Status.IsOK(tSC))
	Quit $$$OK
}

/// A special case of %DeepSee.REST.REST.%Array2JSON used to modify the <var>lookup</var> 
/// variable returned by %DeepSee.REST.v2.CommandServer.%BuildRegistryMap
ClassMethod %lookup2JSON(ByRef array)
{
	set JSON = ##class(%DynamicObject).%New()
	set key = $order(array(""))
	while ( key'="" )
	{
		// create a new entry
		set subJSON = ##class(%DynamicArray).%New()
		if ( $get(array(key))'="" )
		{
			//In case of lookup("cubes", ...)
			if ( $LISTVALID(array(key)) ){
				Set GroupIdx=$LG(array(key),1)
				Set CubeIdx=$LG(array(key),2)
				do subJSON.%Push(GroupIdx)
				do subJSON.%Push(CubeIdx)
			}
			//In case of lookup("groups", ...)
			else{
				do subJSON.%Push(array(key))
			}
			
		}
		if ( $order(array(key,""))'="" )
		{
			kill subarray
			merge subarray = array(key)
			set subarrayJSON = ..%lookup2JSON(.subarray)
			do subJSON.%Push(subarrayJSON)
		}
		do JSON.%Set(key,subJSON)
		set key = $order(array(key))
	}
	return JSON
}

}
