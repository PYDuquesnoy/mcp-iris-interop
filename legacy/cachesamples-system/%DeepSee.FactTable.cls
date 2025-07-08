/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Base class for all DeepSee fact tables.
Class %DeepSee.FactTable Extends (%Persistent, %DeepSee.IndexBuilder) [ Abstract, NoExtent, System = 3 ]
{

/// Name of the cube that created this fact table.
Parameter CUBENAME As STRING;

/// Name of the source table that provides data for this fact table.
Parameter SOURCECLASS As STRING;

/// Turn off extent management for fact tables.
Parameter MANAGEDEXTENT = 0;

/// Return the total number of items within the Fact table.<br/>
/// The actual implementation is generated when the cube is compiled.
ClassMethod %Count() As %Integer [ Abstract ]
{
}

/// Build all facts with data from the source table.
ClassMethod %BuildAllFacts(pVerbose As %Boolean = 0) As %Status [ Abstract, Internal ]
{
}

/// Update a range of Facts with data from the source table row with ids from <var>pStartId</var> to <var>pEndId</var>.<br/>
/// The actual implementation is generated when the cube is compiled.<br/>
/// If <var>pBatchMode</var> is true, then we are building the entire
/// cube from scratch (in parallel).
ClassMethod %UpdateFacts(pStartId As %String, pEndId As %String, pBatchMode As %Boolean = 0, ByRef pChunks As %Integer, pVerbose As %Boolean = 0, pTaskGroup As %String = "", Output pUpdates As %Integer, pRefProp As %String = "", pRefID As %String = "", ByRef pDimTables, pFactList As %String = "") As %Status [ Abstract, Internal ]
{
}

/// Does the actual work of updating one fact (with source id <var>pID</var>) in the fact table with
/// data in the array <var>%var</var> (which is subscripted by fact name).<br/>
/// The actual implementation is generated when the cube is compiled.<br/>
/// <var>pDimensionsOnly</var> is a special flag used by dimension-preloading.
ClassMethod %ProcessFact(pID As %String, pBatchMode As %Boolean = 0, ByRef %var As %String, Output pFactId As %Integer, Output pErrorMsg As %String, ByRef pDimTables, pDimensionsOnly As %Boolean = 0, pFactList As %String = "") As %Status [ Abstract, Internal ]
{
}

/// Does the actual work of deleting one fact (with source id <var>pID</var>) from the fact table.<br/>
/// The actual implementation is generated when the cube is compiled.
ClassMethod %DeleteFact(pID As %String, Output pFactId As %Integer, Output pErrorMsg As %String) As %Status [ Abstract, Internal ]
{
}

/// Precalculate certain aggregate values when a cube is built (if the cube's precompute property is set)
/// for the specified range of facts.<br/>
/// Do not call this method directly.<br/>
/// The actual implementation is generated when the cube is compiled.
/// <var>pAggGLVN</var> is the name of the (private) global in which
/// to put the answers.
ClassMethod %PrecomputeAggregates(pStartChunk As %Integer, pEndChunk As %Integer, pAggGLVN As %String, pVerbose As %Boolean = 0, pTaskGroup As %String = "") As %Status [ Abstract, Internal ]
{
}

/// This is called when there is an error in filing data into this cube.
/// It writes the error message to a log file.
ClassMethod %LogError(pSC As %Status) As %Status [ Internal ]
{
	Set tFile = "DeepSeeUpdate_"_$Translate(..#CUBENAME,"/\","--")
	Set tMsg = $System.Status.GetOneErrorText(pSC)
	Quit ##class(%DeepSee.Utils).%WriteToLog("UPDATE",tMsg,tFile)
}

/// Kill the update log file.
ClassMethod %KillLogFile() As %Status [ Internal ]
{
	Set tFile = "DeepSeeUpdate_"_..#CUBENAME
	Quit ##class(%DeepSee.Utils).%KillLogFile(tFile)
}

}
