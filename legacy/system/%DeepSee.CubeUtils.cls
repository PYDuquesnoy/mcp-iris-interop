/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.CubeUtils Extends %RegisteredObject [ System = 4 ]
{

/// Convert a cube list in various user-supplied formats to a normalized %List format. The accepted formats for the incoming <var>pItemList</var> are:
/// <ul>
/// <li>A %List</li>
/// <li>A comma-delimited list</li>
/// <li>A %DynamicArray</li>
/// <li>A %String that represents a single item.</li>
/// </ul>
ClassMethod %NormalizeCubeList(pCubeList = "", Output pSC As %Status) As %List [ Internal ]
{
	Set pSC = $$$OK
	Set tCubeList = ""

	Try {
		If $IsObject(pCubeList) && pCubeList.%IsA("%DynamicArray") {
			For n=0:1:(pCubeList.%Size()-1) {
				Set tCubeList = tCubeList _ $LB($$$UPPER(pCubeList.%Get(n)))
			}
		}
		ElseIf $ListValid(pCubeList) {
			Set tCubeList = $ListFromString($$$UPPER($ListToString(pCubeList,,3)),",",2)
		}
		Else {
			// N.B. This relies on the fact that cubes reject commas in their logical names
			Set tCubeList = $ListFromString($$$UPPER(pCubeList),",",2)
		}
	}
	Catch ex {
		Set pSC = ex.AsStatus()
		Set tCubeList = ""
	}

	Quit tCubeList
}

/// Given a list of one or more <var>pTargetCubes</var>, return the complete list of all cubes that require updating, and the names of the
/// relationship groups which contain all of the cubes in that list. In addition, return the complete Build Orders index which can be directly used to 
/// assign build order and minimal grouping to the expanded list <var>pcubesToUpdate</var>.
ClassMethod %GetUpdateLists(pTargetCubes, Output pBuildOrders, Output pGroupsToUpdate, Output pCubesToUpdate) As %String
{
	Set tSC = $$$OK
	Try {
		Kill pBuildOrders, pGroupsToUpdate, pCubesToUpdate

		Set pTargetCubes = ##class(%DeepSee.CubeUtils).%NormalizeCubeList(pTargetCubes,.tSC)
		If $$$ISERR(tSC) Quit
		
		// Fetch the system indices that describe all of the logical dependency groups on the system
		Set tSC = ##class(%DeepSee.CubeUtils).%GetCubeGroups(.tGroups,.tCubes,.pBuildOrders)
		If $$$ISERR(tSC) Quit

		// Loop over the cube list to accumulate all of the cubes that should be built based on dependencies to the cubes in the target list
		For c=1:1:$LL(pTargetCubes) {
			// For each cube, verify this is a valid base cube and fetch its list of dependent cubes
			Set tCubeKey=$$$UPPER($LG(pTargetCubes,c))
			
			If '##class(%DeepSee.Utils).%IsCubePhysical(tCubeKey,.tSC) $$$ThrowStatus(tSC)

			Set tSC = ##class(%DeepSee.CubeUtils).%GetDependentCubes(tCubeKey,.tDependentCubes,.tGroups,.tCubes,.pBuildOrders)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)

			// Merge this target cube's list of dependents into the overall list
			Merge pCubesToUpdate = tDependentCubes
			
			// Set the target cube into the list of cubes and groups to build
			Set pCubesToUpdate(tCubeKey) = ""
			Set pGroupsToUpdate(tCubes(tCubeKey)) = ""
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// This method accumulates the complete list of cubes dependent on this target 
/// cube, based on defined relationships. Every cube in <var>pDependentCubes</var> must be 
/// built following a build of <var>pCubeName</var>. This is an alphabetical
/// list, it is not a build order.<br>
/// Optionally the <var>pGroups</var>, <var>pCubes</var>, and <var>pBuildOrders</var> arrays may be 
/// returned as output to the caller, or they may be provided by reference avoiding the
/// recalculation of natural groups on the system. 
ClassMethod %GetDependentCubes(pCubeName = "", Output pDependentCubes, ByRef pGroups, ByRef pCubes, ByRef pBuildOrders) As %Status
{
	Set tSC = $$$OK
	Kill pDependentCubes
	If (pCubeName="") {
		Quit tSC
	}
	
	Try {
		Set tCubeKey = $$$DeepSeeIndex(pCubeName)
		
		If '$D(pGroups)||'$D(pCubes)||'$D(pBuildOrders) {
			Set tSC = ..%GetCubeGroups(.pGroups,.pCubes,.pBuildOrders)
		}
		If $$$ISERR(tSC) Quit

		// Check for dependents of this cube
		Set tGroupName = $G(pCubes(tCubeKey))
		If tGroupName="" {
			Set tSC = $$$ERROR($$$GeneralError,"Cube does not exist")
			Quit
		} ElseIf '$D(pCubes(tCubeKey,"dependents")) { 
			// Output is already correctly set to ""
			Quit
		} 
		
		// Begin with the immediate dependents of this cube.
		Merge tDependentCubes = pCubes(tCubeKey,"dependents")

		// Walk down the group's build order starting at the cube of interest
		// to accumulate its list of dependent cubes.
		Merge tBuildGroup = pBuildOrders(tGroupName)
		Set tBuildIndex = $O(tBuildGroup(pGroups(tGroupName,tCubeKey)),1,tCubeKey)
		While tBuildIndex'="" {
			// If the current cube is in the list of dependents, add its dependents
			// to the list.
			Merge:$D(tDependentCubes(tCubeKey)) tDependentCubes = pCubes(tCubeKey,"dependents")
		
			Set tBuildIndex = $O(tBuildGroup(tBuildIndex),1,tCubeKey)
		}
		
		// Convert the array into the comma-delimited list that is stored 
		// with the registry.
		Set tDependentCube = $O(tDependentCubes(""))
		While tDependentCube'="" {
			Set pDependentCubes = $G(pDependentCubes)_$S($G(pDependentCubes)'="":",",1:"")_tDependentCube
			Set tDependentCube = $O(tDependentCubes(tDependentCube))
		}
		Merge pDependentCubes = tDependentCubes
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Calculates the natural groups for all cubes on the system. Group information is
/// returned in array form. These arrays are organized as follows: <br><br>
/// <var>pGroups</var>(groupName,cubeKey) = buildOrder<br>
/// <var>pCubes</var>(cubeKey) = groupName<br>
/// <var>pBuildOrders</var>(groupName,buildPosition) = cubeKey<br><br>
/// If the cube has dependencies, there will be an additional array<br><br>
/// <var>pCubes</var>(cubeKey,"dependents")<br><br>
/// which will list the cubes that must be updated if this one has been updated.
ClassMethod %GetCubeGroups(ByRef pGroups, ByRef pCubes, ByRef pBuildOrders) As %Status
{
	// This is called by IsValidGroup(), and so cannot call that!
	Set tSC = $$$OK
	Try {
		Set tSC = ..FindCubeGroups(.pGroups,.pCubes)
		If $$$ISERR(tSC) Quit
		
		Set tSC =  ..FindGroupBuildOrders(.pGroups,.pBuildOrders)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Automatically assign groups based on cube relationships. All cubes which 
/// are independent of each other will be assigned to their own group.
ClassMethod FindCubeGroups(ByRef pGroups, ByRef pCubes) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Kill pCubes,pGroups
	
	Try {
		Do ##class(%DeepSee.Utils).%GetCubeList(.tCubeNames,"cubes",1)
		
		Set tCubeName=$order(tCubeNames(""))
		//index for current group
		While tCubeName'="" {
		    Set tNewGroup = $increment(pGroups)
			Kill tGroup
			// Start a temp group with the current cube, then look for any relations
			Set tGroup(tCubeName) = $get(pCubes(tCubeName))
		
			// we will always be adding a new group, and the current
			// cube will always be a member of that group
			Set pGroups(tNewGroup,tCubeName) = ""
			Set pCubes(tCubeName) = tNewGroup
		
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
				
				Set tGroup(tRelCube) = $get(pCubes(tRelCube))
				
				Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",tRelation))
			}
			// -DTB360

			//now I know all cubes in this relationship graph
			//grab all groups listed, remove cubes from old groups 
			//global and add them all to a new group
			Set tRelCube = $order(tGroup(""))
			While tRelCube '= "" {
			
				Set tGrpIdx = tGroup(tRelCube)
				//tRelCube is one of the member cubes below
				If (tGrpIdx '= "") {
					Set tMemberCube = $order(pGroups(tGrpIdx,""))
					While tMemberCube '= "" {
						Set pGroups(tNewGroup,tMemberCube) = ""
						Set pCubes(tMemberCube) = tNewGroup
						Set tMemberCube = $order(pGroups(tGrpIdx,tMemberCube))
					}
					Kill pGroups(tGrpIdx)
				}
				Else {
					Set pGroups(tNewGroup,tRelCube) = ""
					Set pCubes(tRelCube) = tNewGroup
				}
				Set tRelCube = $order(tGroup(tRelCube))
			}	
			Set tCubeName = $order(tCubeNames(tCubeName))	    	
		}		
	
		// The groups currently have gaps in the numbering, which is undesirable. 
		// Go through and rearrange the pGroups 
		Kill tGroups
	
		Set tOldGroup = $order(pGroups(""))
		While tOldGroup '= "" {
			Set tNewGroup = $increment(tGroups)
			Merge tGroups(tNewGroup) = pGroups(tOldGroup)
		
			// Go through the group members and update the cubes array
			Set tMemberCube = $order(tGroups(tNewGroup,""))
			While tMemberCube '= "" {
				Set pCubes = $increment(pCubes)
				Set pCubes(tMemberCube)=tNewGroup
			
				Set tMemberCube = $order(tGroups(tNewGroup,tMemberCube))
			}

			// Step to next group
			Set tOldGroup = $order(pGroups(tOldGroup))
		}
		Kill pGroups				// Kill the old non-sequential group list
		Merge pGroups = tGroups		// replace it with the new sequential list
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Pass in an array of group members, as found by <method>FindCubeGroups</method>,
/// and determine an acceptable build order. The order is returned as an integer
/// stored in each node of the group:<br>
/// <var>pGroups</var>(<var>group #</var>,<var>Cube</var>) = <var>Build order</var>
/// <br><br>
ClassMethod FindGroupBuildOrders(ByRef pGroups, ByRef pBuildOrders) As %Status [ Internal ]
{
	// Method rewritten by DTB277
	Set tSC = $$$OK
	Try {
		Merge tGroupsRef = pGroups
		Kill pBuildOrders
		//for each cube in the list, get the dependency graph
		Set tGroupIdx = $O(pGroups(""))
		While tGroupIdx'="" {
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

/// Look up custom code in the registry and execute it. For a particular <var>pCubeKey</var> the caller may request that custom code stored in
/// the cube registry under <var>pCustomCodeType</var>. Available code types are  "presynch", "postsynch", and "postbuild". If there is no such
/// custom code entry, this method will be a no-op. In the special case of PreSynchCode, 
/// this can optionally return a boolean value for <var>pAbortSynch</var> for the case of PreSynchCode.
ClassMethod ExecuteCustomCode(pCubeName As %String = "", pEventType As %String = "", Output pAbortSynch) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Quit:( (pCubeName="") || (pEventType="") ) tSC

	Set tCubeKey = $$$DeepSeeIndex(pCubeName)
	Set tReturn = $$$OK

	Try {
		// Look for the cube in the registered map and fetch the relevant code
		Set tMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1,.tLookup)
		If $$$ISERR(tSC) Quit

		If '$D(tLookup("cubes",tCubeKey),tMapLocation) Quit
		

		Set tCodeLocation = $Case(pEventType,"presynch":"PreSynchCode","postsynch":"PostSynchCode","postbuild":"PostBuildCode",:"")
		If (tCodeLocation="") {
			Set tSC = $$$ERROR($$$InvalidCustomCodeType,pEventType)
			Quit
		}
		
		Set tCube = tMap.Groups.GetAt($LG(tMapLocation,1)).Cubes.GetAt($LG(tMapLocation,2))
		Set tCustomCode = $Property(tCube,tCodeLocation)

		If tCustomCode'="" {
			Set tCubeEvent = ##class(%DeepSee.CubeManager.CubeEvent).%New()
			Set tCubeEvent.CubeKey = tCubeKey
			Set tSC = tCubeEvent.TransferRegistryInfo(tCubeKey)
			If $$$ISERR(tSC) Quit
			
			Set tCubeEvent.CubeEvent = pEventType
			Set tCubeEvent.CubeSize = ##class(%DeepSee.Utils).%GetCubeFactCount(tCubeKey)
			Set tCubeEvent.StartTime = $system.SQL.Functions.DATEADD("day",0,$H)
			
			Set tSC = tCubeEvent.%Save()
			If $$$ISERR(tSC) Quit


			If pEventType="presynch" {
				Set tCode = "(tAbortSynch) " _ $Replace(tCustomCode,"$$$ABORTSYNCH","tAbortSynch") _ " Quit 1"
				Set tReturn = $XECUTE(tCode,.pAbortSynch)
			}
			// DTB030
			ElseIf pEventType="postsynch" {
				Set tCode = tCustomCode _ " Quit 1"
				Set tReturn = $XECUTE(tCode) 
			}
			ElseIf pEventType="postbuild" {
				Set tCode = tCustomCode _ " Quit 1"
				Set tReturn = $XECUTE(tCode)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $IsObject($G(tCubeEvent)) {
		Set tCubeEvent.FinishTime = $system.SQL.Functions.DATEADD("day",0,$H)
		// If the custom code returns an error, or if there is an error in exectution, record this in the CubeEvent
		Set tCubeEvent.EventStatus = $system.Status.AppendStatus(tSC,tReturn)
		Set tSC = tCubeEvent.%Save()
	}
	
	Quit tSC
}

}
