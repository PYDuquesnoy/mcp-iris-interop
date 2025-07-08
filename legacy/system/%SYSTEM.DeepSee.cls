/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%SYSTEM.DeepSee</class> class provides an interface for the
/// most common DeepSee tasks.<br/>
/// <p>You can use it via the special <b>$system</b> object:
/// <example language="cache">
///  Do $system.DeepSee.BuildCube("MyCube")
/// </example>
/// For a more complete API, refer to the <class>%DeepSee.Utils</class> class.
Class %SYSTEM.DeepSee Extends Help [ Abstract, System = 4 ]
{

/// Stops all DeepSee background agents, clears any pending tasks,
/// and clears the result cache for the current namespace.
/// If <var>pClearCells</var> is true, then the cell cache for the
/// current namespace is also cleared.<br/>
/// This method is provided as a convenience for developers for 
/// use on development or test systems.<br/>
/// You should not use this method
/// on production systems as it will have immediate effect on the
/// performance of end user operations.
ClassMethod Reset(pClearCells As %Boolean = 0) As %Status
{
	Quit ##class(%DeepSee.Utils).%Reset(pClearCells)
}

/// Update <em>all</em> facts in the DeepSee cube <var>pCubeName</var> 
/// with data from the source table.<br/>
/// This will delete any information currently in the cube.
/// If <var>pAsync</var> is true, then background tasks are used.<br/>
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
/// If <var>pIndexOnly</var> is true, only rebuild the fact table indices.<br/>
/// If <var>pMaxFacts</var> is non-zero, then only build this number of facts.<br/>
/// If the <var>pFactList</var> is supplied the build will only update the columns listed in that fact list. 
/// The list must consist of the specific fact names and can have either a comma-delimited or $LB format.
ClassMethod BuildCube(pCubeName As %String, pAsync As %Boolean = 1, pVerbose As %Boolean = 1, pIndexOnly As %Boolean = 0, pMaxFacts As %Integer = 0, pTracking As %Boolean = 1, ByRef pBuildStatistics As %String = 0, pFactList As %String = "") As %Status
{
	// DTB891 - Add pFactList pass-through
	Quit ##class(%DeepSee.Utils).%BuildCube(pCubeName,.pAsync,pVerbose,pIndexOnly,pMaxFacts,pTracking,.pBuildStatistics,pFactList)
}

/// For the specified cube, find and apply all changes from the source data that have been made since the
/// last call to this method.
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
/// If the <var>pFactList</var> is supplied the build will only update the columns listed in that fact list. 
/// The list must consist of the specific fact names and can have either a comma-delimited or $LB format.
ClassMethod SynchronizeCube(pCubeName As %String, pVerbose As %Boolean = 0, Output pFactsUpdated As %Integer, pReadCommitted As %Boolean = 1, pCheckReferences As %Boolean = 1, pAsync As %Boolean = 1, ByRef pSynchronizeStatistics As %String = 0) As %Status
{
	// DTB300 - Add remaining parameters
	// DTB1130 - Support for factList is removed from synchronize
	Quit ##class(%DeepSee.Utils).%SynchronizeCube(pCubeName,pVerbose,.pFactsUpdated,pReadCommitted,pCheckReferences,pAsync,.pSynchronizeStatistics)
}

/// Delete all cache that has been invalidated for cube <var>pCubeName</var>.<br>
/// The results cache is stored in partitions, and a partition of the results cache 
/// is invalidated during the cube synchronization process if one or more of the 
/// records being updated contributed to the results within that partition.<br>
/// A cube build removes the entire cache and so automatically performs this
/// operation.
ClassMethod PurgeObsoleteCache(pCubeName As %String) As %Status
{
	// Method added by DTB274
	Quit ##class(%DeepSee.Utils).%PurgeObsoleteCache(pCubeName)
}

/// Delete all indices and cache values for the given cube.
ClassMethod KillCube(pCubeName As %String) As %Status
{
	Quit ##class(%DeepSee.Utils).%KillCube(pCubeName)
}

/// Display a list of all cubes within this namespace (that are visible to the current user) to the console.
ClassMethod ListCubes()
{
	Do ##class(%DeepSee.Utils).%GetCubeList(.tList)
	Set n = 0
	Set tItem = $O(tList(""))
	While (tItem '= "") {
		Set n = n + 1
		Write n,?5,tItem,!
		Set tItem = $O(tList(tItem))
	}
}

/// Invoke the DeepSee command line shell.
ClassMethod Shell() As %Status
{
	Do $System.Process.NewLineRecallContext("MDX")
	Do ##class(%DeepSee.Shell).%Go()
}

}
