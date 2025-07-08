/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Utility container for the management of cube versions
Class %DeepSee.CubeVersion.Utils Extends %RegisteredObject
{

Parameter DEPRECATED = "deprecated";

Parameter ACTIVE = "active";

Parameter PENDING = "pending";

/// If a cube has different versions, get the name of the version currently active given the reference name <var>pCubeGenericName</var>. 
/// If a cube does not use cube versioning this will return the upper-case cube index.
ClassMethod %GetVersionedCubeName(pCubeGenericName As %String = "", pVersion As %Integer = "", pSC As %Status) As %String
{
	// Method added by DTB130
	Set pSC = $$$OK
	Set tCubeNameU = $$$UPPER(pCubeGenericName)
	Set tVersionedCubeName = tCubeNameU
	Try {
		If (pVersion'="")&&'$D($$$DeepSeeMetaGLVN("versionIndex","versions",tCubeNameU,pVersion)) {
			Set tVersionedCubeName = ""
			Set pSC = $$$ERROR($$$GeneralError,"Requested version for "_tCubeNameU_" does not exist:"_pVersion)
		}
		
		Set tCubeVersion = $S(pVersion'="":pVersion,1:..%GetActiveCubeVersion(tCubeNameU))
		If (tCubeVersion'="") {
			Set tVersionedCubeName = $G($$$DeepSeeMetaGLVN("versionIndex","versions",tCubeNameU,tCubeVersion,"cube"))
		}
	}
	Catch ex {
		Set pSC = ex.AsStatus()
	}
	Quit tVersionedCubeName
}

/// If a cube has different versions, get the reference name given a version name <var>pCubeName</var>. 
/// If the cube was not produced using cube versioning this will return the upper-case cube index.
ClassMethod %GetGenericCubeName(pCubeVersionName As %String = "", pSC As %Status) As %String
{
	// Method added by DTB130
	Set pSC = $$$OK
	Set tCubeNameU = $$$UPPER(pCubeVersionName)
	Set tCubeGenericName = tCubeNameU
	Try {
		If (tCubeNameU'="")&&$D($$$DeepSeeMetaGLVN("versionIndex","versionOf",tCubeNameU)) {
			Set tCubeGenericName = $G($$$DeepSeeMetaGLVN("versionIndex","versionOf",tCubeNameU))
		}
	}
	Catch ex {
		Set pSC = ex.AsStatus()
	}
	Quit tCubeGenericName
}

ClassMethod %ActivatePendingCubeVersion(pCubeGenericName As %String, pRemoveDeprecated As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	// Method added by DTB130
	Set tSC = $$$OK
	Set tCubeIndex = $$$DeepSeeIndex(pCubeGenericName)
	Try {
		// Test for pre-requisite conditions before attempting the switch 
		Set tPendingVersion = ..%GetPendingCubeVersion(pCubeGenericName)
		If tPendingVersion="" {
			Set tSC = $$$ERROR($$$GeneralError,"No pending version for cube: "_pCubeGenericName)	
			Quit
		}
		W:pVerbose !,"Pending version for " _ pCubeGenericName _ ": " _ tPendingVersion
		
		// There may or may not be a currently active version, it is not required
		Set tActiveVersion = ..%GetActiveCubeVersion(pCubeGenericName)
		
		// Synchronize the pending cube just before the switch. This will ensure that the new version 
		// is more current than the previous. Swallow any errors that result from the synchronize.
		Set tPendingVersionIndex = $$$DeepSeeIndex(..%GetVersionedCubeName(pCubeGenericName,tPendingVersion))
		Do $system.DeepSee.SynchronizeCube(tPendingVersionIndex)
		W:pVerbose !,"Pending version synchronized: "_tPendingVersionIndex
		
		// Perform the actual switch
		// Prevent queries on the generic cube name during the switch
		Set tLocked = 0
		Lock +^DeepSee.Build(tCubeIndex):1 Else  Set tLocked=1
		If tLocked {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to obtain the lock needed to activate cube version: " _ pCubeGenericName)
			Quit
		}
		W:pVerbose !,"Queries locked for cube: "_pCubeGenericName
		
		// Check the build lock for the pending version--make sure it is not building while preparing to switch
		Set tVersionLocked = 0		
		Lock +^DeepSee.Build(tPendingVersionIndex):1 Else  Set tVersionLocked=1
		If tVersionLocked {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to obtain the lock needed to activate cube version: " _ tPendingVersionIndex)
			Quit
		}
		
		// Once the cube is locked, kill all current queries on that cube
		W:pVerbose !,"Killing active tasks for cube: "_pCubeGenericName
		Set tSC = ..%KillTasksForCube(tCubeIndex)
		If $$$ISERR(tSC) Quit
		Set tSC = ..%KillTasksForCube(tPendingVersionIndex)
		If $$$ISERR(tSC) Quit
		
		// If the cube has relationships, adjust the inverse to point to this cube
		Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tPendingVersionIndex,"relations",""))
		While (tRelation'="") {
			If ($$$DeepSeeMetaGLVN("cubes",tPendingVersionIndex,"relations",tRelation,"cardinality")="one") {
				// Look for an inverse relation in the the independent cube to update a two-way relationship
				// This is needed to prevent requiring a second compile on the independent cube
				Set tRelatedCubeName = $$$DeepSeeMetaGLVN("cubes",tPendingVersionIndex,"relations",tRelation,"relatedCube")		// Must exist for valid relationship
				Set tInverseRelation = $$$DeepSeeMetaGLVN("cubes",tPendingVersionIndex,"relations",tRelation,"inverse")			// Existence enforced by %CreateCubeVersionDefinition
				
				If $D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tRelatedCubeName),"relations",$$$UPPER(tInverseRelation))) {
					Set $$$DeepSeeMetaGLVN("cubes",$$$UPPER(tRelatedCubeName),"relations",$$$UPPER(tInverseRelation),"relatedCube") = tPendingVersionIndex
					W:pVerbose !,"Cube relationship updated: " _tRelatedCubeName
				}
			}
			Set tRelation = $O($$$DeepSeeMetaGLVN("cubes",tPendingVersionIndex,"relations",tRelation))
		}
		
		Set tSC = ..%SetActiveCubeVersion(pCubeGenericName,tPendingVersion)
		If $$$ISERR(tSC) Quit
		W:pVerbose !,"Cube version activated: "_tPendingVersionIndex
		
		If (tActiveVersion'="") {
			// DTB130 - If there was an active version, deprecate it
			W:pVerbose !,"Deprecating previously active version: "_..%GetVersionedCubeName(pCubeGenericName,tActiveVersion)
			Set tSC = ..%DeprecateCubeVersion(pCubeGenericName,tActiveVersion)
			If $$$ISERR(tSC) Quit
			
			If pRemoveDeprecated {
				// Remove the previously active version
				W:pVerbose !,"Removing previously active version: "_..%GetVersionedCubeName(pCubeGenericName,tActiveVersion)
				Set tSC = ..%RemoveCubeVersion(pCubeGenericName,tActiveVersion)
				If $$$ISERR(tSC) Quit
			}
		}
		Else {
			If pRemoveDeprecated {
				// There was no use of versions previously, kill the generic cube
				W:pVerbose !,"Removing non-versioned cube data"
				Set tSC = ##class(%DeepSee.Utils).%KillCube(pCubeGenericName)
			}
		}

		// Remove the pending index
		Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),"pendingVersion")
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Do:pVerbose $system.OBJ.DisplayError(tSC)
	}
	
	// DTB519 - Always call the unlock just before exit
	Lock -^DeepSee.Build($G(tPendingVersionIndex))
	Lock -^DeepSee.Build($G(tCubeIndex))
	
	W:pVerbose !
	Quit tSC
}

/// Mark a cube version as deprecated. Once deprecated, a version is ready for removal.
ClassMethod %DeprecateCubeVersion(pCubeGenericName As %String = "", pVersion As %Integer) As %Status
{
	// Method added by DTB130 
	Set tSC = $$$OK
	Try {
		If (pVersion = ..%GetPendingCubeVersion(pCubeGenericName)) {
			Set tSC = ..%SetPendingCubeVersion(pCubeGenericName,pVersion)
			If $$$ISERR(tSC) Quit
		}
		If (pVersion = ..%GetActiveCubeVersion(pCubeGenericName)) {
			Set tSC = $$$ERROR($$$GeneralError,"Cannot deprecate active cube version:"_pCubeGenericName_":"_pVersion)
			Quit
		}
		Else {
			Set tSC = ..%SetCubeVersionStatus(pCubeGenericName,pVersion,..#DEPRECATED)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Completely remove all components of a cube version from the system. This cannot be performed on a cube version marked "active".
ClassMethod %RemoveCubeVersion(pCubeGenericName As %String = "", pVersion As %Integer) As %Status
{
	// Method added by DTB130 
	Set tSC = $$$OK
	Try {
		Set tCubeVersionName = ..%GetVersionedCubeName(pCubeGenericName,pVersion,.tSC)
		If $$$ISERR(tSC) Quit
		
		If '(..%IsVersion(tCubeVersionName)) {
			Set tSC = $$$ERROR($$$GeneralError,"Cube version does not exist:"_pCubeGenericName_":"_pVersion)
			Quit
		}

		// Make sure this cube is safe to remove
		If ..%IsActiveVersion(tCubeVersionName) {
			Set tSC = $$$ERROR($$$GeneralError,"Cannot remove active cube version:"_pCubeGenericName_":"_pVersion)
			Quit
		}
		If '(..%IsDeprecatedVersion(tCubeVersionName)) {
			Set tSC = $$$ERROR($$$GeneralError,"Cube version must be deprecated before removal")
			Quit
		}
		
		// Remove the version by deleting its [generated] definition class. The projection will handle the rest
		Set tVersionClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeVersionName)
		
		If ##class(%Dictionary.ClassDefinition).%ExistsId(tVersionClass) {
			Set tSC = ##class(%DeepSee.Utils).%KillCube(tCubeVersionName)
			If $$$ISERR(tSC) Quit		// DTB589
			Set tSC = $system.OBJ.Delete(tVersionClass,"-d")
			If $$$ISERR(tSC) Quit		// DTB589
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the active version number for <var>pCubeGenericName</var>
ClassMethod %GetActiveCubeVersion(pCubeGenericName As %String) As %Integer
{
	// Method added by DTB130 
	Set tVersionNo = "" 
	If (pCubeGenericName'="") {
		Set tVersionNo = $G($$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),"activeVersion"))
	}
	
	Quit tVersionNo
}

/// Return the pending version number for <var>pCubeGenericName</var>. An empty string indicates there is no pending version.
ClassMethod %GetPendingCubeVersion(pCubeGenericName As %String = "") As %String
{
	// Method added by DTB130
	Set tVersionNo = "" 
	If (pCubeGenericName'="") {
		Set tVersionNo = $G($$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),"pendingVersion"))
	}
	Quit tVersionNo
}

/// Given the generic name of a versioned cube, collect the list of deprecated versions currently on the system.
ClassMethod %GetDeprecatedVersionList(pCubeGenericName As %String = "", ByRef pList) As %Status
{
	Kill pList
	Set pList = ""
	Set tSC = $$$OK
	Try {
		Set tCubeGenericNameU = $$$UPPER(pCubeGenericName)
		Set tVersionNo = $O($$$DeepSeeMetaGLVN("versionIndex","versions",tCubeGenericNameU,""))
		While (tVersionNo'="") {
			If (..%GetCubeVersionStatus(pCubeGenericName,tVersionNo) = ..#DEPRECATED) {
				Set pList(tVersionNo) = ..%GetVersionedCubeName(pCubeGenericName,tVersionNo)
			}
			Set tVersionNo = $O($$$DeepSeeMetaGLVN("versionIndex","versions",tCubeGenericNameU,tVersionNo))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the current promotion status of version <var>pVersion</var> the cube <var>pCubeGenericName</var>.
ClassMethod %GetCubeVersionStatus(pCubeGenericName As %String, pVersion As %Integer) As %String
{
	// Method added by DTB130 
	Set tVersionStatus = "" 
	If (pCubeGenericName'="") {
		Set tVersionStatus = $G($$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),pVersion,"status"))
	}
	Quit tVersionStatus
}

/// It is valid to manually write a cube logical name that can look like a version when it is not. 
/// Verify the cube name entered in <var>pCubeName</var> is a true version of a generic cube definition.
/// Optionally return the decomposition of the original cube name into its genericName and version parts.
/// If a non-versioned cube is entered as <var>pCubeName</var>, then:<br>
///  <var>pCubeGenericName</var> = <var>pCubeName</var>
///  <var>pVersion</var> = ""
ClassMethod %IsVersion(pCubeName As %String, Output pCubeGenericName, Output pVersion) As %Boolean
{
	// Method added by DTB130
	Set tIsVersion = 0
	Set pCubeGenericName = ""
	Set pVersion = ""
	Try {
		If pCubeName = "" Quit
		
		If $D($$$DeepSeeMetaGLVN("versionIndex","versionOf",$$$UPPER(pCubeName))) {
			Set tIsVersion = 1
			Set pCubeGenericName = $G($$$DeepSeeMetaGLVN("versionIndex","versionOf",pCubeName))
			Set pVersion = $P(pCubeName,$$$dsVersionDelim,$L(pCubeName,$$$dsVersionDelim))
		}
		Else {
			Set pCubeGenericName = pCubeName
		}
	}
	Catch ex {
		// Swallow error
	}
	
	Quit tIsVersion
}

/// Test whether the current cube <var>pCubeVersionName</var> is the active version.
ClassMethod %IsActiveVersion(pCubeVersionName As %String) As %Boolean
{
	// Method added by DTB130 
	Set tIsActiveVersion = 0
	If ..%IsVersion(pCubeVersionName,.tCubeGenericName,.tVersion) {
		Set tIsActiveVersion = ( tVersion = $G($$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tCubeGenericName),"activeVersion")) )
	}

	Quit tIsActiveVersion
}

/// Test whether the current cube <var>pCubeVersionName</var> is the pending version.
ClassMethod %IsPendingVersion(pCubeVersionName As %String) As %Boolean
{
	// Method added by DTB130 
	Set tIsPendingVersion = 0
	If ..%IsVersion(pCubeVersionName,.tCubeGenericName,.tVersion) {
		Set tIsPendingVersion = ( tVersion = $G($$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tCubeGenericName),"pendingVersion")) )
	}

	Quit tIsPendingVersion
}

/// Test whether the current cube <var>pCubeVersionName</var> is deprecated.
ClassMethod %IsDeprecatedVersion(pCubeVersionName As %String) As %Boolean
{
	// Method added by DTB130 
	Set tIsDeprecatedVersion = 0
	If ..%IsVersion(pCubeVersionName,.tCubeGenericName,.tVersion) {
		Set tIsDeprecatedVersion = ( ..#DEPRECATED=$G($$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tCubeGenericName),tVersion,"status")) )
	}

	Quit tIsDeprecatedVersion
}

/// Performs the actual work of marking a specific version as the active version that will be used when 
/// the generic name <var>pCubeGenericName</var> is used. This will remove the "active" flag from any other
/// version of <var>pCubeGenericName</var>.
ClassMethod %SetActiveCubeVersion(pCubeGenericName As %String, pVersion As %Integer) As %Status [ Internal ]
{
	// Method added by DTB130 
	Set tSC = $$$OK
	Try {
		Set tActiveCubeVersion = ..%GetActiveCubeVersion(pCubeGenericName)
		If (tActiveCubeVersion'="")&&(tActiveCubeVersion'=pVersion) {
			// Remove the "active" status from the other version
			Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),tActiveCubeVersion,"status")
		}
		
		Set $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),"activeVersion") = pVersion
		
		// Setting to the null version is allowed
		Set:(pVersion'="") tSC = ..%SetCubeVersionStatus(pCubeGenericName,pVersion,..#ACTIVE)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Performs the actual work of marking a specific version as the pending version for the cube <var>pCubeGenericName</var>. 
/// This will remove the "pending" flag from any other version of <var>pCubeGenericName</var>.
ClassMethod %SetPendingCubeVersion(pCubeGenericName As %String, pVersion As %Integer) As %Status [ Internal ]
{
	// Method added by DTB130 
	Set tSC = $$$OK
	Try {
		Set tPendingCubeVersion = ..%GetPendingCubeVersion(pCubeGenericName)
		If (tPendingCubeVersion'="")&&(tPendingCubeVersion'=pVersion) {
			// Remove the "pending" status from the other version
			Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),tPendingCubeVersion,"status")
		}
		
		Set $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),"pendingVersion") = pVersion
		Set tSC = ..%SetCubeVersionStatus(pCubeGenericName,pVersion,..#PENDING)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Performs the actual work of storing the current promotion status of version <var>pVersion</var> for the cube <var>pCubeGenericName</var>.
/// This will only accept valid status strings: "active","pending","deprecated".
ClassMethod %SetCubeVersionStatus(pCubeGenericName As %String, pVersion As %Integer, pNewCubeStatus As %String) As %Status [ Internal ]
{
	// Method added by DTB130 
	Set tSC = $$$OK
	Set tNewCubeStatus = $$$LOWER(pNewCubeStatus) 
	
	Set tValidCubeStatus(..#ACTIVE) = ""
	Set tValidCubeStatus(..#PENDING) = ""
	Set tValidCubeStatus(..#DEPRECATED) = ""
	Try {
		If $D(tValidCubeStatus(tNewCubeStatus)) {
			Set $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(pCubeGenericName),pVersion,"status") = tNewCubeStatus
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Kill all active tasks for a cube. This is used just before activating a pending cube to clear any queries that are running.
ClassMethod %KillTasksForCube(pCubeName As %String) [ Internal ]
{
	Set tSC = $$$OK
	Set tCubeNameU = $$$UPPER(pCubeName)
	Try {
		Set tTaskGroup = $O($$$DeepSeeTaskGroupGLVN(""))
		While (tTaskGroup'="") {
			Set tTaskNo = $O($$$DeepSeeTaskGroupGLVN(tTaskGroup,"tasks",""),1,tTaskData)
			While tTaskNo'="" {
				If ($$$UPPER($LG(tTaskData,3))=tCubeNameU) {
					// Remove all tasks from the task global
					Do ##class(%DeepSee.WorkMgr).%KillTasksForGroup(tTaskGroup)		// DTB706 - This is now handled by the WorkMgr
				}
				Set tTaskNo = $O($$$DeepSeeTaskGroupGLVN(tTaskGroup,"tasks",tTaskNo),1,tTaskData)
			}
			// Remove from the task group global
			//Kill $$$DeepSeeTaskGroupGLVN(tTaskGroup)
			Set tTaskGroup = $O($$$DeepSeeTaskGroupGLVN(tTaskGroup))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// <b>Called by the %GetModel generator - do not call this directly</b>.<br> 
/// Create a new definition class for a cube which contains a copy of the cube definition class currently being compiled. The new class
/// will have the name <br><br>
/// &lt<var>pClassName</var>&gt.Version&lt<var>pCube.version</var>&gt <br><br>
/// The <var>pClassName</var> must be the name of a cube definition class with the parameter <parameter>USECUBEVERSIONS</parameter>=1 and 
/// the corresponding cube model <var>pCube</var> must be the cube defined in that class. Additionally, <var>pCube</var> must have the "version"
/// attribute set to a valid integer value. <br><br>
/// The generated model will have <parameter>USECUBEVERSIONS</parameter> and version attributes removed to prevent recursion in the compiler. The  
/// <var>pCube</var> object is unchanged after this call.
ClassMethod %CreateCubeVersionDefinition(pClassName As %String = "", pCube As %DeepSee.Model.cube, Output pNewClassName, Output pNewCubeIndex) As %Status [ Internal ]
{
	// Method added by DTB130
	Set tSC = $$$OK
	Try {
		If '$IsObject(pCube)||'pCube.version {
			Set tSC = $$$ERROR($$$GeneralError,"Cannot create a cube version definition without a defined version number")
			Quit
		}
 		If (pClassName="") {
	 		Set tSC = $$$ERROR($$$GeneralError,"No class name for creating a cube version definition")
			Quit
 		}

		Set tNewClassName = pClassName _ ".Version" _ pCube.version
		
		If ##class(%Dictionary.ClassDefinition).%ExistsId(tNewClassName) {
			Set tSC = ##class(%Dictionary.ClassDefinition).%DeleteId(tNewClassName)
			If $$$ISERR(tSC) Quit
		}
		Set tSC = ##class(%Compiler.COS.Refactor).ChangeClName(pClassName,tNewClassName,pClassName,.pNewClassName) 
		If $$$ISERR(tSC) Quit
		
		// Make sure the desired class is generated. If not, clean up and exit.
		If pNewClassName'=tNewClassName {
			Do ##class(%Dictionary.ClassDefinition).%DeleteId(pNewClassName)
			Set pNewClassName = ""			
			Set tSC = $$$ERROR($$$GeneralError,"Could not properly create versioned cube class")
			Quit
		}
		
		// Since %ConstructClone is not supported for %DeepSee.Model.cube, manipulate the current object before 
		// storing in a version file and restore its state after the new file is written
		Set tPrevName = pCube.name
		Set tPrevVersion = pCube.version 
		Set tPrevCaption = pCube.caption
		
		Set pCube.name = pCube.name _ $$$dsVersionDelim _ pCube.version
		Set pNewCubeIndex = $$$UPPER(pCube.name)
		Set pCube.version = ""							// The generated cube version cannot itself be versioned!
		Set:pCube.caption="" pCube.caption = tPrevName 	// Don't let the version get displayed as the name in user-facing pages
		
		// Redirect relationships according to versions
		For r=1:1:pCube.relationships.Count() {
			Set tRel = pCube.relationships.GetAt(r)
			If tRel.inverse="" {
				// Force relationships in versioned cubes to define inverses
				Set tSC = $$$ERROR($$$GeneralError,"Relationship in versioned cube must define an inverse: " _ tRel.name)
				$$$ThrowStatus(tSC)
			}

			Set tPrevRelation(r) = tRel.relatedCube
			
			// Get the proper version to relate to.
			//  - If there is a pending version, that one will build and this must link to, and build after, that version
			//  - If there is no pending version, then link to the active version since it was not updated
			//  - If neither an active or pending version exists, use the original 
			Set tRelationVersionNo = ##class(%DeepSee.CubeVersion.Utils).%GetPendingCubeVersion(tRel.relatedCube)
			If (tRelationVersionNo="") {
				Set tRelationVersionNo = ##class(%DeepSee.CubeVersion.Utils).%GetActiveCubeVersion(tRel.relatedCube)
			}
			If (tRelationVersionNo'="") {
				// +DTB373 - Determine the generated class name vor a related version
				// so it can be added to the class DependsOn list
				if (tRel.cardinality="one") {
					Set tRelClassName = ##class(%DeepSee.Utils).%GetCubeClass(tRel.relatedCube)_".Version"_tRelationVersionNo
					Set tDependsOnClasses(tRelClassName) = ""
					
				}
				// -DTB373
				
				Set tRel.relatedCube = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(tRel.relatedCube,tRelationVersionNo)
			}
		}
		
		Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pNewClassName)
		Set tClassDefinition.Abstract = 0
		Set tClassDefinition.GeneratedBy = pClassName
		
		// +DTB373 - Add the generated version class to the class DependsOn list
		If $D(tDependsOnClasses) {
			Set tDependsOnClass = $O(tDependsOnClasses(""))
			While tDependsOnClass'="" {
				Set tClassDefinition.DependsOn = tClassDefinition.DependsOn _ $S($L(tClassDefinition.DependsOn):",",1:"") _ tDependsOnClass
				Set tDependsOnClass = $O(tDependsOnClasses(tDependsOnClass))
			}
		}
		// -DTB373
		
		// delete the old USECUBEVERSIONS parameter
		Set tIndex = tClassDefinition.Parameters.FindObjectId(pNewClassName_"||USECUBEVERSIONS")
		If tIndex'="" Do tClassDefinition.Parameters.RemoveAt(tIndex)
		
		// NB - Copied from %SaveCubeDefinition - that method does more than we want here 
		// delete the old XDATA block named Cube
		Set tIndex = tClassDefinition.XDatas.FindObjectId(pNewClassName_"||Cube")
		If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		
		// create XData block to hold the Cube Model
		Set tCubeXData = ##class(%Dictionary.XDataDefinition).%New()
	
		Set tCubeXData.SequenceNumber = $I(tSeqNo)
		Set tCubeXData.Description = "Cube definition from " _ pClassName _ "."
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
		Set tSC = tWriter.RootObject(pCube)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.EndDocument()
		If $$$ISERR(tSC) Quit

		// contents of xdata block is the xml for the model
		Set tSC = tCubeXData.Data.CopyFrom(tTempStream)
		If $$$ISERR(tSC) Quit

		// save the cube class
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
		
		Set pCube.name = tPrevName
		Set pCube.version = tPrevVersion
		Set pCube.caption = tPrevCaption
		
		For r=1:1:pCube.relationships.Count() {
			Set tRel = pCube.relationships.GetAt(r)
			Set tRel.relatedCube = tPrevRelation(r)
		}
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
