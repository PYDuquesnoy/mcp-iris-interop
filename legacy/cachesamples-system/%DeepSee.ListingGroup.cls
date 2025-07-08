/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// This class contains APIs for managing Listing Groups.
/// A listing group porvides the ability to define DeepSee listings
/// outside of the cube and subject area definitions.
Class %DeepSee.ListingGroup Extends %RegisteredObject [ System = 4 ]
{

/// Returns a list of listing groups currently stored. The return structure is <br>
/// <var>pList(GroupID,counter)</var> = $LB(GroupID,Name,Caption,CubeList,Class).
/// If the setting <var>pCompiled</var> = 1 is used, only listing groups that have successfully 
/// been compiled will be returned. Otherwise, all models currently saved will be returned.
ClassMethod %GetListingGroups(Output pList, pCompiled = 1, pRequestCube = "*")
{
	Set tSC = $$$OK
	Kill pList
	Try {
		// +DTB539
		If (pRequestCube'="*")&&'##class(%DeepSee.Utils).%CubeExists(pRequestCube,.tSC) {
			Quit
		}
		Set tRequestCubeU = $S(pRequestCube="":"*",1:$$$UPPER(pRequestCube))
		// -DTB539
		
		If pCompiled {
			// Get information from the metatdata
			Set tGroupID = $O($$$DeepSeeListingGroupGLVN("groups",""),1,tClassName)
			While tGroupID'="" {
				Set tGroupName = $G($$$DeepSeeListingGroupGLVN("groups",tGroupID,"name"))
				Set tGroupCaption = $G($$$DeepSeeListingGroupGLVN("groups",tGroupID,"displayName"))
				Set:tGroupCaption="" tGroupCaption = tGroupName
				
				Set tCubeU = $O($$$DeepSeeListingGroupGLVN("groups",tGroupID,"cubes",""))
				Set tCubeList = ""
				Set tKeepGroup = (tRequestCubeU="*")		// DTB539 - Allow limiting of the list by cube
				While tCubeU'="" {
					Set tKeepGroup = tKeepGroup || (tCubeU = tRequestCubeU)
					Set tCubeList = tCubeList _ $S($L(tCubeList):",",1:"") _ tCubeU 
					
					Set tCubeU = $O($$$DeepSeeListingGroupGLVN("groups",tGroupID,"cubes",tCubeU))
				}
				Set:tKeepGroup pList(tGroupID,$I(pList(tGroupID))) = $LB(tGroupID,tGroupName,tGroupCaption,tCubeList,tClassName)

				Set tGroupID = $O($$$DeepSeeListingGroupGLVN("groups",tGroupID),1,tClassName)
			}
		} Else {
			// Query the subclasses of %DeepSee.ListingGroupDefinition
			//Set tSQL = "SELECT ID FROM %Dictionary.ClassDefinition WHERE Super = '%DeepSee.ListingGroupDefinition'"
			//Set tRS = ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL)
			Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
			Set tSC = tRS.Execute("%DeepSee.ListingGroupDefinition")
			
			While tRS.%Next() {
				Set tClassName = tRS.%GetData(1)
				Set tModel = ##class(%DeepSee.ListingGroup).%GetModel(tClassName)
				Set tGroupCaption = tModel.displayName
				Set:tGroupCaption="" tGroupCaption = tModel.name
				
				If (tModel.name'="") {
					Set tGroupID = $$$UPPER(tModel.name)
					If ((tModel.resource="")||($system.Security.Check(tModel.resource)'="")) {
						Set:((tRequestCubeU="*")||($$$UPPER(tModel.targetCubes)[tRequestCubeU)) pList(tGroupID,$I(pList(tGroupID))) = $lb(tGroupID,tModel.name,tGroupCaption,$$$UPPER(tModel.targetCubes),tClassName)		// DTB539 - Allow limiting of the list by cube
					}
				}
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Look up the storage class for a given listing group. The parameter 
/// <var>pCompiled</var> = 1 indicates only the available metadata should be returned. 
/// <var>pCompiled</var> = 0 returns all listing definition classes defined in the namespace.
ClassMethod %GetClassName(pListingGroupName = "", pCompiled = 1) As %String
{
	Set tClassName = ""
	Try {
		Set tListGroupNameU = $$$UPPER(pListingGroupName) 
		If tListGroupNameU'="" {
			Do ##class(%DeepSee.ListingGroup).%GetListingGroups(.tList,pCompiled)
			Set tClassName = $LG(tList(tListGroupNameU,1),5)
		}
	}
	Catch ex {
		Set tClassName = ""
	}
	Quit tClassName
}

/// Utility method to delete a listing group definition. This will delete both compiled 
/// and uncompiled definitions.
ClassMethod %DeleteListingGroup(pListingGroup) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tClassName = ..%GetClassName(pListingGroup,0)
		If tClassName="" Quit
		
		Set tClass = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName)
		If tClass="" Quit
		
		If ( tClass.SuperIsDefined() && (tClass.Super = "%DeepSee.ListingGroupDefinition") ) {
			Set tSC = $SYSTEM.OBJ.Delete(tClassName,"/displaylog=0")
		} Else {
			Set tSC = $$$ERROR($$$GeneralError,"Cannot delete: class is not a listing group definition")
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method for saving a listing group object to its class.
ClassMethod %SaveListingGroup(pGroupObject As %DeepSee.Model.ListingGroup.listingGroup, pClassName = "") As %Status
{
	
	Set tSC = $$$OK
	Try {
		Set tSC = pGroupObject.%SaveToClass(pClassName)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod %ListingGroupExists(pListGroupName = "", pCompiled = 1) As %Boolean
{
	Set tExists = 0
	Try {
		Set tListGroupNameU = $$$UPPER(pListGroupName) 
		If tListGroupNameU'="" {
			Do ##class(%DeepSee.ListingGroup).%GetListingGroups(.tList,pCompiled)
			Set tExists = $D(tList(tListGroupNameU))
		} 
	}
	Catch ex {
		Set tExists=0
	}
	Quit tExists
}

/// Serialize the listing group model stored in the class <var>pClassName</var>.
ClassMethod %GetModel(pClassName = "", Output pStatus As %Status) As %DeepSee.Model.ListingGroup.listingGroup [ Internal ]
{
	
	Set pStatus = $$$OK
	Try {
		Set tModel = ##class(%DeepSee.Model.ListingGroup.listingGroup).%LoadFromClass(pClassName,pStatus)
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	Quit tModel
}

/// Return an array of all currently defined DeepSee ListingGroups
/// in a format that can be used by a finderDialog.
ClassMethod %GetListingGroupArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetListingGroups(.tList,0)
		If $$$ISERR(tSC) Quit

		K n
		Set tName = $O(tList(""))
		While tName'="" {
			Set tItem = tList(tName,1)
			Set tIntList($I(n)) = $LB($LG(tItem,1),$LG(tItem,2),"","listingGroup")
			Set tName = $O(tList(tName))
		}

		Set tSC = ##class(%DeepSee.Utils).%BuildItemListArray(.tIntList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
