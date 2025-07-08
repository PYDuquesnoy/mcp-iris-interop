/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class provides an API for analyzing MDX queries 
/// and generating report data. This class is intended for diagnostic purposes only. 
/// There is no guarantee made about either the behavior or future operation of this class. Production
/// applications should not make direct use of these APIs.<br/><br/>
/// Files generated are as follows:<br/>
///  - A general statistics report,<br/>
///  - PERFMON samples from running the query both uncached and cached,<br/>
///  - An export of the cube class and fact table. If this cube is a member of a relationship group,
/// all related cube classes will also be exported.
Class %DeepSee.Diagnostic.MDXUtils Extends (%XML.Adaptor, %ZEN.DataModel.Adaptor) [ System = 4 ]
{

Parameter VERSION [ Internal ] = "2.1 (January 10, 2014)";

Parameter UTILNAME [ Internal ] = "MDX Query Performance Analyzer";

/// MDX Query being analyzed.
Property Query As %DeepSee.Datatype.string;

/// DeepSee ResultSet from cached query preparartion (contains statistics).
Property ResultsCached As %DeepSee.ResultSet;

/// DeepSee ResultSet from uncached query preparation (contains statistics).
Property ResultsUncached As %DeepSee.ResultSet;

/// Last MDX result set prepared (cached / uncached)
Property lastPrep As %Integer [ InitialExpression = -1, Internal ];

/// PID of current PERFMON background check.
Property pJob As %Integer [ InitialExpression = 0, Internal ];

/// Collection period of current PERFMON background check.
Property pTime As %Integer [ InitialExpression = 0, Internal ];

/// Use cache for statistics - set by %Prep method.
Property UseCache As %Boolean;

/// Base directory for analysis output; defaults to install directory.
Property BaseDir As %String;

/// Holds the start times of the query execution and the start of %Run
Property StartTimes As array Of %Numeric;

/// This property contains the ordered list of cubes that have some logical relation
/// to the cube currently being queried. The list is ordered from least dependent to 
/// most independent.  
Property CubeGroup As %String [ MultiDimensional ];

/// Controls whether or not status updates should be output to the current device.
Property Verbose As %Boolean [ InitialExpression = 0 ];

/// Used to trigger communication to the UI via the ^DeepSee.MDXUtils global
Property TrackingOn As %Boolean [ InitialExpression = 0 ];

/// Prints the current version to the screen
ClassMethod Version() As %Status
{
	Write "Current MDXUtils version: ",!,..#VERSION
	Write !,"Database Engine Version: ",!,$ZV
	Q $$$OK
}

/// This method is used for analysis of an MDX query. This runs the query two times; once uncached and once cached.
/// During each of these a PERFMON report will be generated and saved to the destination folder. This utility
/// will also collect and save general query statistics, as well as export the Cube and Fact table definitions.
/// <br/><var>pMDX</var> - The MDX query to be analyzed 
/// <br/><var>pBaseDir</var> - The base directory for storing the output folder. This is set to the 
/// instance installation directory by default.
/// <br/><var>pVerbose</var> - If true, the analysis will print the long-form output to the current device. Setting
/// <var>pVerbose</var> = 0 will run the analysis completely silently.
/// <br><br>There are other options that may be turned on via the <var>pParms</var> array:
/// <br><var>pParms("CubeStatsOn")</var> = 1
/// <br><var>pParms("TimePERFMON")</var> = 15
/// <br><var>pParms("SystemPerformanceOn")</var> = 0
/// <br><var>pParms("SystemPerformanceProfile")</var> = ""
/// <br><var>pParms("UnattendedOn")</var> = 1
/// <br>"On" in flag name denotes it is treated as a boolean, "Time" denotes it accepts a positive integer
/// argument, in seconds.
ClassMethod %Run(pMDX As %String = "", pBaseDir As %String = "", pVerbose As %Boolean = 0, ByRef pParms = "", Output pOutFile = "") As %Status
{
	Set $ZT="runErr"

	Set tMDXUtilsRunId = $I(^DeepSee.MDXUtils)   // Get a run ID for this execution
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"initialize") = $ZTIMESTAMP
		
	// Initialization:
	// 1) Clean up any previous statistics globals if this is being run multiple times from the same process
	Kill ^||Uncached, ^||Cached
	// 2) Clear out all agents and agent logs
	Do ##class(%DeepSee.WorkMgr).%Reset()		// DTB706 - The WorkMgr is now responsible for the agent reset
	// 3) Initialize default parameters
	Set:'$D(pParms("CubeStatsOn")) pParms("CubeStatsOn") = 1
	Set:'$D(pParms("TimePERFMON")) pParms("TimePERFMON")=15
	Set:'$D(pParms("SystemPerformanceOn")) pParms("SystemPerformanceOn")=0
	Set:'$D(pParms("SystemPerformanceProfile")) pParms("SystemPerformanceProfile") = ""
	Set:'$D(pParms("UnattendedOn")) pParms("UnattendedOn") = 1

	Write:pVerbose !, "Beginning MDX Query Performance Analysis."
	
	Merge ^DeepSee.MDXUtils(tMDXUtilsRunId,tStep,"initialize","pParms") = pParms
	
	;Instantiate analysis object
	Set tAna = ##class(%DeepSee.Diagnostic.MDXUtils).%New(pMDX)
	If ('$ISOBJECT(tAna)) {
		If pVerbose {
			Write !, "Query Analysis failed."
			Do $System.OBJ.DisplayError(%objlasterror)
		}
		Quit %objlasterror
	}
	Set tAna.Verbose = pVerbose
	Set tAna.TrackingOn = $Get(pParms("TrackingOn"),0)
	
	Do tAna.StartTimes.SetAt($now(),"RunStart")
	
	;Set output directory
	Set tSC=tAna.SetBaseDir(.pBaseDir,pVerbose,pParms("UnattendedOn"))
	Merge ^DeepSee.MDXUtils(tMDXUtilsRunId,tStep,"initialize","pBaseDir")=pBaseDir
	
	Goto:$$$ISERR(tSC) Err
	
	;We need to prepare the MDX query before we get the cube name out of it.
	Set tSC = tAna.%Prep(pMDX,0)
	Goto:$$$ISERR(tSC) Err
	
	;This can be used later to make many report outputs;
	;a naming convention like CubeName-N-Filename would be
	;relatively easy to check and implement.
	
	Set tCubeName=tAna.ResultsUncached.%CubeKey
	
	// If the cube is the member of a logically related group, we want to 
	// collect some information on all of them. Store the group information here.
	Set tSC = tAna.GetQueryCubeGroup(tCubeName)
	Set:$$$ISERR(tSC) tAna.CubeGroup=1,tAna.CubeGroup(1)=tCubeName
	
	// Make the cube name safe for use in a file name
	Set tCubeFileName = $zstrip(tCubeName,"*P")
	Set tFileUncached=tAna.BaseDir_"Uncached_MDXPerf_"_tCubeFileName_"_"_$tr($h,",","_")_".html" //Asaf
	Set tFileCached=tAna.BaseDir_"Cached_MDXPerf_"_tCubeFileName_"_"_$tr($h,",","_")_".html" //Asaf
	
	// If selected, kick off a SystemPerformance in the background. This process will continue beyond the 
	// parent and place the reports in the base directory.
	If pParms("SystemPerformanceOn") {
		Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"SystemPerformance") = $ZTIMESTAMP
		Write:pVerbose !,"Initializing SystemPerformance in a background job..."
		Job ##class(%DeepSee.Diagnostic.MDXUtils).RunSystemPerformance(tAna.BaseDir,pParms("SystemPerformanceProfile"))
		Hang 30 // It takes a few seconds to start collecting statistics, so wait for it!
	}
	
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"uncached") = $ZTIMESTAMP
	Set tSC=tAna.Analyze(pMDX, tFileUncached, pParms("TimePERFMON"), 0)
	Goto:$$$ISERR(tSC) Err
	
	// - SAVE STATISTICS -							
	// Some of the statistics are calculated in the printing methods by 
	// reading values from the Results cache global. Since both the 
	// cached and uncached queries save to the same stats node, this means the 
	// Query-Query-Print-Print order will overwrite information and collect bad
	// statistics data.
	Try {
		Set nDev=##class(%Device).GetNullDevice()
		Open nDev u nDev										// Write this output to null device
		Set tStart=$zh
		Do tAna.ResultsUncached.%Print()
		Set ^||Uncached("stats","TotalTime")=$g(^||Uncached("stats","TotalTime"))+($zh-tStart)						
		Do tAna.ResultsUncached.%PrintStatistics()
		Use 0 Close nDev
		Merge ^||Uncached("stats")=$$$DeepSeeResultsGLVN(tAna.ResultsUncached.%CubeKey,tAna.ResultsUncached.%QueryKey,"stats")
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Goto Err	
	}												
	
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"cached") = $ZTIMESTAMP
	Set tSC=tAna.Analyze(pMDX,tFileCached,$S(pParms("TimePERFMON"):1,1:0),1)
	Goto:$$$ISERR(tSC) Err
	
	Try {
		Open nDev Use nDev										
		Set tStart=$zh
		Do tAna.ResultsCached.%Print()
		Set ^||Cached("stats","TotalTime")=$g(^||Cached("stats","TotalTime"))+($zh-tStart)					
		Do tAna.ResultsCached.%PrintStatistics()	
		Use 0 Close nDev
		Merge ^||Cached("stats")=$$$DeepSeeResultsGLVN(tAna.ResultsCached.%CubeKey,tAna.ResultsCached.%QueryKey,"stats")	
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Goto Err	
	}
	
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"begin report") = $ZTIMESTAMP												
	Set tSC = tAna.ToHTML(.tOutFile,pParms("CubeStatsOn"))
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,tStep,"report") = tOutFile
	Write:pVerbose !!, "MDX Query Analysis saved to: ", !,tOutFile,!
	Set pOutFile = tOutFile	
	Goto:$$$ISERR(tSC) Err
	
	Set tSC = tAna.ExportDefinitions(tCubeFileName)
	Goto:$$$ISERR(tSC) Err
	
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"run complete") = $ZTIMESTAMP
	Quit $$$OK
	
Err
	Do tAna.ToHTML(.tOutFile,0,tSC)
	Write:pVerbose !, "Error analyzing MDX query: ",!, $System.OBJ.DisplayError(tSC)
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"Error") = tSC
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,tStep,"report") = tOutFile
	Quit tSC
	
runErr
	Set $ZT=""
	Write:pVerbose !, "Error ",$ze," encountered; aborting."
	Set ^DeepSee.MDXUtils(tMDXUtilsRunId,$I(tStep),"Run-Time Error") = $ZE
	Quit $G(tSC)
}

/// Run MDX query analysis.<br/>
/// <var>pMDX</var> - (mandatory) MDX Query to run.<br/>
/// <var>outFile</var> - (mandatory) Output file for PERFMON statistics.<br/>
/// <var>perfTime</var> - PERFMON collection period; any non-zero value will run PERFMON.<br/>
/// <var>UseCache</var> - Use cache for query run (default false).<br/>
Method Analyze(pMDX As %String, pOutFile As %String, pPerfTime As %Integer = 0, pUseCache As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	if pPerfTime {
		If ..Verbose {
			Write !!, "Starting background PERFMON for system statistics "
			Write:pUseCache "(Cached query)."
			Write:'pUseCache "(Uncached query)."
		}
		
		Set tSC = ..InitPerf(pOutFile, pPerfTime)
		
		If $$$ISERR(tSC) {
			Write:..Verbose !,"Error on PERFMON: ",$System.OBJ.DisplayError(tSC)
			Quit tSC
		}
	}
	
	Set tSC = ..%Prep(pMDX,pUseCache)
	Quit:$$$ISERR(tSC) tSC
	
	Set tSC = ..%Exec()
	Quit:$$$ISERR(tSC) tSC
	
	if pPerfTime {
		Set tSC = ..WaitPerfStop()
		// h perfTime            // Shouldn't be necessary... dB 02/21/12
		If $$$ISERR(tSC) {
			;PERFMON completion failure
			Write:..Verbose !,"Error on PERFMON: " 
			Do $System.OBJ.DisplayError(tSC)
		} Else {
			;PERFMON completed ok
			Write:..Verbose !, "PERFMON results saved to: ",!,pOutFile
		}
	}
	
	Quit tSC
}

/// Prepare MDX query for execution and set internal variables accordingly.
Method %Prep(pMDX As %String = "", pUseCache As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC=$$$OK
	
	Try {
		// Instantiate variables here for other methods
		Set ..Query = pMDX		
		Set ..lastPrep = pUseCache
		
		// Prepare Query on instantiation; this will set up the rest of our properties.
		If pUseCache {
			Set ..ResultsCached = ##class(%DeepSee.ResultSet).%New()
			Set ..ResultsCached.%UseCache = pUseCache	
			Set tStart=$zh	
			Set tSC = ..ResultsCached.%PrepareMDX(pMDX)
			Set ^||Cached("stats","TotalTime")=$g(^||Cached("stats","TotalTime"))+($zh-tStart)
		} else {
			Set ..ResultsUncached = ##class(%DeepSee.ResultSet).%New()
			Set ..ResultsUncached.%UseCache = pUseCache
			Set tStart=$zh	
			Set tSC = ..ResultsUncached.%PrepareMDX(pMDX)
			Set ^||Uncached("stats","TotalTime")=$g(^||Uncached("stats","TotalTime"))+($zh-tStart)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Execute prepared MDX query; store results accordingly.
Method %Exec() As %Status [ Internal ]
{
	Quit:..lastPrep=-1 $$$ERROR($$$GeneralError, "No query has been prepared!")
	Write:..Verbose !,"Executing Query..."
	
	Set tSC = $$$OK
	Try {
		//Set:$G(tQueryKey)="" tQueryKey=""
		If ..lastPrep {   	// Cached Query
			Do ..StartTimes.SetAt($now(),"CachedStart")
			Set tStart=$zh
			Set tSC = ..ResultsCached.%ExecuteAsynch(.tQueryKey,.pParms,1)
			Set ^||Cached("stats","TotalTime")=$G(^||Cached("stats","TotalTime"))+($zh-tStart)
		} Else {   			// Uncached Query
			// - KILL PREVIOUS CACHE -							
			// If this query has been run, the results cache for that query must be deleted to 
			// get an accurate timing measurement	
			For ii=1:1:..CubeGroup {						 				
				Kill $$$DeepSeeResultsGLVN(..CubeGroup(ii))
				Kill $$$DeepSeeAxisGLVN(..CubeGroup(ii))					
			}
			Do ..StartTimes.SetAt($now(),"UncachedStart")
			Set tStart=$zh
			Set tSC = ..ResultsUncached.%ExecuteAsynch(.tQueryKey,.pParms,1)
			Set ^||Uncached("stats","TotalTime")=$G(^||Uncached("stats","TotalTime"))+($zh-tStart)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()	
	}	
	Quit tSC
}

/// Intended for use in report printing only. <br>
/// Print statistics of last analyzed query; includes ResultSet statistics.
Method PrintQueryStats() [ Internal ]
{
	
	// dB - removed the single-line print command in favor of replacing the 	
	// stored statistics. This will correct an overwrite problem seen with the 
	// Query-Query-Print-Print order
	If ..lastPrep {	
		Kill $$$DeepSeeResultsGLVN(..ResultsCached.%CubeKey,..ResultsCached.%QueryKey,"stats")													
		Merge $$$DeepSeeResultsGLVN(..ResultsCached.%CubeKey,..ResultsCached.%QueryKey,"stats")=^||Cached("stats")
		Do ..ResultsCached.%PrintStatistics()
		Write !,"-----------------------------------------------------"
		Write !,"Total Execution Time: ",^||Cached("stats","TotalTime")
	}
	If '..lastPrep {
		Kill $$$DeepSeeResultsGLVN(..ResultsUncached.%CubeKey,..ResultsUncached.%QueryKey,"stats")
		Merge $$$DeepSeeResultsGLVN(..ResultsUncached.%CubeKey,..ResultsUncached.%QueryKey,"stats")=^||Uncached("stats")
		Do ..ResultsUncached.%PrintStatistics()
		Write !,"-----------------------------------------------------"
		Write !,"Total Execution Time: ",^||Uncached("stats","TotalTime")
	}
}

/// Intended for use in report printing only. <br>
/// Cube Analyze output (to show indices cardinality)<br/>
Method PrintCubeStats(pVerbose As %Boolean = 1) [ Internal ]
{
	Try {
		// This may take a long time if the cubes are very large!
		For ii=1:1:..CubeGroup {
			Write:ii'=1 !!!
			Write !, "************************************************"
			Write !, "  Statistics for Cube " _ ..CubeGroup(ii)
			Write !, "    sourceType: " _ ..CubeGroup(ii,"sourceType")
			Write !, "************************************************",!
			Do ##class(%DeepSee.Utils).%Analyze(..CubeGroup(ii),"ifc",pVerbose)
		
			Do ##class(%DeepSee.Utils).%AnalyzeMissing(..CubeGroup(ii))
		}
	}
	Catch ex {	
		// Recover from the error and report
		Write !,"Error in PrintCubeStats: "
		Do $system.OBJ.DisplayError(ex.AsStatus())
		Write !,"Continuing..."
	}
}

/// Export Cube class and Cube fact class to single XML file.
Method ExportDefinitions(pCubeFileName) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tExpFile=..BaseDir_pCubeFileName_".xml"
		
		Set tItems=""
		// Export all cube and fact classes involved
		For ii=1:1:..CubeGroup {
			Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..CubeGroup(ii))
			Set tFactClass = ##class(%DeepSee.Utils).%GetCubeFactClass(..CubeGroup(ii))
		
			;Note - the export didn't work with lowercase .cls extensions.
			Set tItems = tItems_$s(ii=1:"",1:",")_tCubeClass_".CLS,"_tFactClass_".CLS"
			
			If ..CubeGroup(ii,"sourceType")="dataconnector" {
				Set tItems = tItems_","_$$$DeepSeeMetaGLVN("cubes",..CubeGroup(ii),"sourceClass")_".CLS"
			}
		}
		
		
		If '..Verbose {
			// Export does not have a Verbose option, write this output to null device
			Set nDev=##class(%Device).GetNullDevice()
			Open nDev u nDev										
			Set tSC = $System.OBJ.Export(.tItems,.tExpFile)
			Use 0 Close nDev
		} Else {
			Set tSC = $System.OBJ.Export(.tItems,.tExpFile)
		}
			
		If tSC {
			If ..Verbose {
				Write !, "Cube class and fact table definitions successfully exported to:"
				Write !, tExpFile
			}
		} Else {
			If ..Verbose {
				Write !,"ERROR exporting cube classes"
				Do $system.OBJ.DisplayError(tSC)
			}
		}
	}
	Catch ex {
		set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Unimplemented.
Method FindSelectivity() [ Internal ]
{
	// Find "selectivity" of Cube Analysis output by levels of cube; ie
	// Cardinality is unique values, so we'd like to know instead
	// the breakdown how many facts are are of certain value
	// (how many "Closed" or "Open"?)  Might reveal a problematic index
}

/// Intended for use in report printing only. <br>
/// Pinting method for the query plan
Method PrintPlan() [ Internal ]
{
	If ..lastPrep=0 {
		Do ..ResultsUncached.%ShowPlan()
	} ElseIf ..lastPrep=1 {
		Do ..ResultsCached.%ShowPlan()
	} Else {
		Write !, "No query available."
	}
}

/// Start background PERFMON process; this must be JOBbed off,<br>
/// and should only be done through the InitPerf() method.
ClassMethod StartPerf(pFile As %String = "", pTime As %Integer = 15) [ Internal ]
{
	; $$Collect^PERFMON returns a string that begins with a negative number
	; on error, or a 1 otherwise.  We can work with that for more detailed
	; error handling that might indicate a problem with the MONITOR class...
	; We'll need to use %SYSTEM.Event for signaling
	
	;MUST change to %SYS namespace; PERFMON stuff doesn't run implicitly.
	Zn "%SYS"
	
	Set tSC = $$$OK
	
	;Check to make sure this was jobbed off
	If ('$ZPARENT) {
		Set tSC = "0,Classmethod must be jobbed off."
		Goto SignalMain
	}
		
	If pFile="" {
		Set tSC = "0,PERFMON output file undefined."
		Goto SignalMain
	}
	
	Try {
    	Set tSC = $$Collect^PERFMON(pTime,"HTML",pFile)
    } 
    Catch ex {
    	Set tSC = "0,Error Collecting PERFMON Data: "_$system.Status.GetErrorText(ex.AsStatus()) 
    }
    
    // Certain errors can leave the Monitor in a Pause state.
    // Run Stop and report.
    If +tSC'=1 { 
    	/* PERFMON ERRORS
    	 1	Successful
    	 0  A non-PERFMON error 
		-1	Somebody else is using Monitor
		-3	Monitor is already running
		*/
  
    	// If the error is -1 we take no action since the monitor was started by someone else.
    	if +tSC <-1 {
	    	Do Stop^PERFMON()
	    	set tSC = "0,Ran Stop^PERFMON due to error. Code: "_tSC
    	}
    }
			
SignalMain
	;By here we've got a living parent, and something in the status code.
	;Send signal to parent process accordingly.


	Do $System.Event.Signal($ZPARENT, tSC)
	Quit
}

/// Starts PERFMON background process from %Run() context.<br>
/// This will also affect the ..pJob Property, and a subsequent<br>
/// call to WaitPerfStop will expect to deal with that PID.<br>
/// The ..pTime property will also be adjusted to wait an <br>
/// appropriate amount of time for the last PERFMON run to complete.
Method InitPerf(pFile As %String = "", pTime As %Integer = 15) As %Status [ Internal ]
{
	Set tChild=$ZCHILD
	;Utilize timeout, $TEST, and $ZCHILD variables for error processing.
		
	Job ..StartPerf(pFile, pTime)::10
	
	;No Child job was spawned ($ZCHILD did not change)
	Quit:($ZCHILD=tChild) $$$ERROR($$$GeneralError, "Unable to spawn child process.")
	
	;We timed out
	Quit:'$TEST $$$ERROR($$$GeneralError, "JOB command time out, could not start PERFMON.")
	
	;Here, we successfully spawned the PERFMON job.
	;Set the pJob property accordingly.
	Set ..pJob = $ZCHILD
	Set ..pTime = pTime
		
	Quit $$$OK
}

/// Wait for current PERFMON to stop; the information regarding that<br/>
/// process' PID and run period will have been set by a successful<br/>
/// InitPerf() earlier.<br/>
/// Lowest timeout threshold is 30 seconds.  
Method WaitPerfStop() As %Status [ Internal ]
{
	
	If '..pJob {
		;If ..pJob=0 we never spawned a PERFMON.
		Quit $$$ERROR($$$GeneralError, "PERFMON job did not run.")
	}
	Set tWaitStop = (2*..pTime)
	Set:(tWaitStop<30) tWaitStop = 30
	
	Write:..Verbose !, "Please wait while PERFMON data is collected, may be up to "_tWaitStop_" seconds... "
	Set tWaitReturn = $System.Event.WaitMsg()
	;The return from this is a list; the first piece is the Wait() return code,
	;and the second is the message from PERFMON execution.
	Set tWaitCode = $LI(tWaitReturn,1)
	Set tPerfmonCode = $P($LI(tWaitReturn,2),",",1)
	Set tPerfmonMessage = $P($LI(tWaitReturn,2),",",2)
	
	;0 implies a timeout occurred
	Quit:('tWaitCode) $$$ERROR($$$GeneralError, "Timed out waiting for PERFMON process "_..pJob)
	
	;-1 implies a delete of the resource occurred while we were waiting
	Quit:(tWaitCode=-1) $$$ERROR($$$GeneralError, "PERFMON process "_..pJob_" does not exist")
	
	;Normalize status code from Collect^PERFMON
	If (tPerfmonCode=1) {
	    ;This is OK
	    Set tSC = $$$OK
	} Else {
	    Set tSC = $$$ERROR($$$GeneralError, tPerfmonMessage)
    }
	
	Quit tSC
}

/// Determine the path where the collection data will be stored
Method SetBaseDir(pBaseDir As %String = "", pVerbose As %Boolean = 0, pUnattended = 1) As %Status [ Internal ]
{
	
	;Check that directory is defined; if not we go with the default.
	If ('pBaseDir)&&(pVerbose) {
		Write !!, "Analysis output directory will be:",!,..BaseDir
		Write !, "Press return to accept, or enter a different directory.",!
		Write "=> ",pBaseDir
	}
	
	Set:pBaseDir="" pBaseDir=..BaseDir
	Set pBaseDir=##class(%File).ComputeFullDBDir(pBaseDir)
	Set pBaseDir=pBaseDir_"MDXPerf"
	Set pBaseDir=##class(%File).ComputeFullDBDir(pBaseDir)
	Set pBaseDir=pBaseDir_$tr($tr($tr($zdt($h,3),"-","_"),":","")," ","_")
	Set pBaseDir=##class(%File).ComputeFullDBDir(pBaseDir)
	
	;By here we have something for Dir, validate it.
	If '##class(%File).DirectoryExists(pBaseDir) {

	If 'pUnattended {			
			;Directory doesn't exist, create it?
			Write !, pBaseDir
			Write !, "This directory doesn't exist." 
			Set ans=""
			For {
				Write !,"Create it (y/n)? "
				Read ans#1
				Quit:("YN"[($ZCONVERT(ans,"U")))
				Write !, "Please enter y or n."
			}
		
			;Quit - we didn't want to create the directory after all.
			Quit:ans="N" $$$ERROR($$$GeneralError, "Directory creation refused.")
	}
		
	;We couldn't create the directory
	Quit:$$$ISERR(##class(%File).CreateDirectoryChain(pBaseDir)) $$$ERROR($$$GeneralError, "Unable to create directory.")
					
	}
		
	Set ..BaseDir=pBaseDir
	Write:pVerbose !, "Using ",pBaseDir," for analysis output."
	Quit $$$OK
}

/// Intended for use in report printing only. <br>
/// Print the dependencies for the cube class and the the DeepSee model
Method PrintDependencies() As %Status [ Internal ]
{
	Set cube= ..ResultsUncached.%CubeKey
	Set cClass=##class(%DeepSee.Utils).%GetCubeClass(cube)
	
	// Display Cube Class dependencies
	Do $system.OBJ.GetDependencies(cClass,.list,"cr-u")
	
	Set iClass = $O(list(""))
	Write "***************************"
	Write !,"Cube Class Dependencies:"
	Write !,"***************************"
	Write:iClass="" !,"NONE"
	While iClass'="" {
		Write !,iClass
		Set iClass=$O(list(iClass))
	}
	
	// Display Source Class dependencies
	Set sClass=$$$DeepSeeMetaGLVN("cubes",cube,"sourceClass")
	Do $system.OBJ.GetDependencies(sClass,.list,"cr-u")
	
	Set iClass=$o(list(""))
	Write !!!,"***************************"
	Write !,"Source Class Dependencies:"
	Write !,"***************************"
	Write:iClass="" !,"NONE"
	While iClass'="" {
		Write !,iClass
		Set iClass=$o(list(iClass))
	}

	// Display the dependency graph for the cube being queried
	For ii=1:1:..CubeGroup {
		Write:ii=1 !!!!
		Write !,"***************************"
		Write !,"Cube Dependency Graph for " _ ..CubeGroup(ii) _ ":"
		Write !,"***************************",!
		Do ##class(%DeepSee.Utils).%WriteDependencyGraph(..CubeGroup(ii))
	}
	
	Quit $$$OK
}

/// Intended for use in report printing only. <br>
/// - NOT IMPLEMENTED -
Method PrintAgentMetrics() As %Status [ Internal ]
{
	// This is called if the process metrics have been turned on by a global flag. 
	// Once inside this method, we assume metrics have been collected!
	
	// Need to kill the background agents toinvoke %ZSTOP, which has the call
	// to merge the metrics.
	Do ##class(%DeepSee.WorkMgr).%KillAgents(1)
	Hang 1 // Might not need this...
	
	// Printing Section
	
	Write !,"NO AGENT METRICS TO PRINT!"
	
	Quit $$$OK
}

/// Switches to the %SYS namespace to run SystemPerformance. </br>
/// Best jobbed off?
ClassMethod RunSystemPerformance(pDir, pProfile = "1min") As %Status [ Internal ]
{
	// Add call to SystemPerformance to monitor disk activity of the uncached query.
	ZN "%SYS"
	
	Set tRunId = 0
	Do setlogdir^SystemPerformance(pDir)
	Set:pProfile'="" tRunId=$$run^SystemPerformance(pProfile)     // Try to start the called profile
	If 'tRunId {
		// If the passed in profile does not exist, create the default and start it
		Set rc=$$addprofile^SystemPerformance("1min","A 1-minute run sampling every 1 second",1,60)
		Set tRunId=$$run^SystemPerformance("1min")
	}
	
	// Abort if we don't have a run id by this point
	Quit:'tRunId $$$ERROR($$$GeneralError,"SystemPerformance failed to run")
	
	// Hang for the 
	Set tWaitString = $$$UPPER($$waittime^SystemPerformance(tRunId))
	Set tWait = 0
	If tWaitString["HOURS" {
		Set tWait = tWait + (tWaitString*3600)
		Set tWaitString = $P(tWaitString,"hours ",2)
	}
	If tWaitString["MINUTES" {
		Set tWait = tWait + (tWaitString*60)
		Set tWaitString = $P(tWaitString,"minutes ",2) 
	}
	Set tWait = tWait + tWaitString
	
	Hang tWait  

	// COLLECTION: Run in a tight loop until we've waited too long (10 minutes) or 
	// we complete the SystemPerformance collection
	Set tCollect=$$Collect^SystemPerformance(tRunId)
	Set tHangStart=$ZH, tHang=0
	While ('+tCollect & tHang<600 ) {
		Hang 5
		Set tCollect=$$Collect^SystemPerformance(tRunId)
		Set tHang=$ZH-tHangStart
	}

	Quit tCollect
}

/// Find the logical group that this cube belongs to. Information about the group 
/// as a whole is needed.
Method GetQueryCubeGroup(pCube) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Grab the dependency-based logical group for this cube
		Do ##class(%DeepSee.CubeManager.Utils).GetCubeGroups(.tGroups,.tCubes,.tBuild)	
		Merge tGroup = tBuild(tCubes(##class(%DeepSee.CubeVersion.Utils).%GetGenericCubeName(pCube))) //APV025
		Set ..CubeGroup=0
		Set tOrder = $o(tGroup(""),-1)
		While tOrder'="" {
			Set tCubeKey = tGroup(tOrder)
			// Work backwards in the buildorder to set the dependency group
			// Last cube USUALLY has the most dependencies
			Set ..CubeGroup($i(..CubeGroup)) = tCubeKey
			
			// save the source type. We test this for exporting a connector class
			Set ..CubeGroup(..CubeGroup,"sourceType") = $g($$$DeepSeeMetaGLVN("cubes",tCubeKey,"sourceType"))
			
			Set tOrder = $o(tGroup(tOrder),-1)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Clear the execution history from the logging global.
/// This will not affect any of the diagnostic reports.
ClassMethod %ClearHistory() As %Status
{
	Kill ^DeepSee.MDXUtils
	Quit $$$OK
}

/// Genenrate MDX Analysis as HTML file.
Method ToHTML(ByRef pFileName As %String, pCubeStats As %Boolean, pStatus As %Status = 1) As %Status [ Internal ]
{
	
	;Generate output HTML file for results
	s uData=$tr($h,",","_") //$p($h,",",1) //Asaf
	//s fHandle="Qry-"_uData_".html"
	s fHandle="MDXPerf_"_uData_".html" //Asaf
	s fHandle=..BaseDir_fHandle
	s oFile=##class(%Library.File).%New(fHandle)
	s rc=oFile.Open("WNS")
	q:$$$ISERR(rc) rc
	
	s pFileName=oFile.CanonicalName
	
	;*****Header section
	d oFile.WriteLine("<html>")
	d oFile.WriteLine("<head>")
	d oFile.WriteLine("<title>")
	d oFile.WriteLine("MDX Query Analyzer. Filename: "_pFileName)
	d oFile.WriteLine("</title>")
	d oFile.WriteLine("<meta http-equiv='Content-Type' content='text/html'>")
	d oFile.WriteLine("<style>")
	d oFile.WriteLine("pre {")
	d oFile.WriteLine("white-space: pre-wrap; /* css-3 */")
	d oFile.WriteLine("white-space: -moz-pre-wrap !important; /* Mozilla, since 1999 */")
	d oFile.WriteLine("white-space: -pre-wrap; /* Opera 4-6 */")
	d oFile.WriteLine("white-space: -o-pre-wrap; /* Opera 7 */")
	d oFile.WriteLine("word-wrap: break-word; /* Internet Explorer 5.5+ */")
	d oFile.WriteLine("}")
	d oFile.WriteLine("</style>")
	d oFile.WriteLine("</head>")
	d oFile.WriteLine("<body bgcolor='#FFFFFF' text='#000000'>")

	;*****Table of links
	d oFile.WriteLine("<table align='center' width='100%' border=1 bordercolor='#999999' bgcolor='#CCCCCC'>")
	d oFile.WriteLine("<tr bgcolor='#FFFFFF' bordercolor='#CCCCCC'>")
    d oFile.WriteLine("<td colspan='12' height='40' align='center'>")
    d oFile.WriteLine("  <font face='Arial, Helvetica, sans-serif' size=5 color='#0000FF'><b>"_..#UTILNAME_", Version "_..#VERSION_"</b></font>")
    d oFile.WriteLine("</td>")
	d oFile.WriteLine("</tr>")

	// Skip the table if we're just going to be exiting with an error
    If pStatus {
		d oFile.WriteLine("<tr bgcolor='#FFFFFF' bordercolor='#CCCCCC'>")
		
	    d oFile.WriteLine("<td align='center'>")
	    d oFile.WriteLine("  <font size='2' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a href='#general'>General</a></b></font>")
	    d oFile.WriteLine("</td>")
    
	    d oFile.WriteLine("<td align='center'>")
	    d oFile.WriteLine("  <font size='2' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a href='#qplan'>Query Plan</a></b></font>")
	    d oFile.WriteLine("</td>")
	    
	    d oFile.WriteLine("<td align='center'>")
	    d oFile.WriteLine("  <font size='2' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a href='#qstat'>Query Stats</a></b></font>")
	    d oFile.WriteLine("</td>")
	    
	    if pCubeStats {
		    d oFile.WriteLine("<td align='center'>")
		    d oFile.WriteLine("  <font size='2' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a href='#cubestat'>Cube Stats</a></b></font>")
		    d oFile.WriteLine("</td>")
	    }
	    
	    d oFile.WriteLine("<td align='center'>")
	    d oFile.WriteLine("  <font size='2' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a href='#dependson'>Dependencies</a></b></font>")
	    d oFile.WriteLine("</td>")
	    
	    d oFile.WriteLine("<td align='center'>")
	    d oFile.WriteLine("  <font size='2' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a href='#agentlog'>Agent Log</a></b></font>")
	    d oFile.WriteLine("</td>")
	    
	    /* Suppress until PrintAgentMetrics() is implimented
	    d oFile.WriteLine("<td align='center'>")
	    d oFile.WriteLine("  <font size='2' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a href='#agentmetrics'>Agent Metrics</a></b></font>")
	    d oFile.WriteLine("</td>")
	    */
    }
    
    d oFile.WriteLine("</table>")


	
	;*****General section
	; Date and Time generated
	; $ZV
	; MDX Query
	
	d oFile.WriteLine("<br>")
	d oFile.WriteLine("<font size='4' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a name='general'></a>General</b></font>")
	d oFile.WriteLine("<pre>")
	d oFile.WriteLine("Report generation time:<br> "_$zdt($h)_"<br>")
	d oFile.WriteLine("Version:<br>"_$ZV_"<br>")
	d oFile.WriteLine("Namespace:<br><b>"_$NAMESPACE_"</b><br>")
	d oFile.WriteLine("Input Query:<br><b>"_..Query_"</b><br>")
	If pStatus {
		d oFile.WriteLine("Adjusted Query:<br><b>"_$$$DeepSeeResultsGLVN(..ResultsUncached.%CubeKey,..ResultsUncached.%QueryKey)_"</b><br>")
		d oFile.WriteLine("Query Key:<br><b>"_..ResultsUncached.%QueryKey_"</b><br>")
	} Else {
		d oFile.WriteLine("<br>=== QUERY ERROR ===")
		Use fHandle
		Do $system.Status.DisplayError(pStatus)
		d oFile.WriteLine("<br>===================")
	}
	d oFile.WriteLine("</pre>")
	d oFile.WriteLine("<hr>")
	
	// If there was a query error, now we've printed it.
	// Jump to the end of the file
	Goto:$$$ISERR(pStatus) Footer
	
	;*****Query Plan section
	d oFile.WriteLine("<br>")
	d oFile.WriteLine("<font size='4' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a name='qplan'></a>Query Plan</b></font>")
	d oFile.WriteLine("<pre>")
	u fHandle d ..PrintPlan()
	d oFile.WriteLine("</pre>")
	d oFile.WriteLine("<hr>")
	
	
	;*****Query Stats section
	; Think of putting a table here -
	; one non-cached and one cached run
	d oFile.WriteLine("<br>")
	d oFile.WriteLine("<font size='4' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a name='qstat'></a>Query Stats</b></font><br>")
	// TABLE
	d oFile.WriteLine("<br><table align='center' width='90%' border=1 bordercolor='#999999' bgcolor='#CCCCCC'>")
	d oFile.WriteLine("<tr bgcolor='#FFFFFF' bordercolor='#CCCCCC'>")
	d oFile.WriteLine("<td align='center'><h3>Uncached Stats</h3</td><td align='center'><h3>Cached Stats</h3</td></tr>")
	d oFile.WriteLine("<tr bgcolor='#FFFFFF' bordercolor='#CCCCCC'>")
	// No cache run
    d oFile.WriteLine("<td><pre>")
    s ..lastPrep=0  //Asaf overridden by Dan
    u fHandle d ..PrintQueryStats()
	d oFile.WriteLine("</pre></td>")
	// Cache run
	s ..lastPrep=1
    d oFile.WriteLine("<td><pre>")
    u fHandle d ..PrintQueryStats()
	d oFile.WriteLine("</pre></td>")
	d oFile.WriteLine("</tr>")
	d oFile.WriteLine("</table>")
	
	d oFile.WriteLine("<pre>")
	d oFile.WriteLine("<br><b>"_$zdt(..StartTimes.GetAt("RunStart"))_"</b> - %Run Start<br>")
	d oFile.WriteLine("<b>"_$zdt(..StartTimes.GetAt("UncachedStart"))_"</b> - Uncached Start<br>")
	d oFile.WriteLine("<b>"_$zdt(..StartTimes.GetAt("CachedStart"))_"</b> - Cached Start<br>")
	d oFile.WriteLine("<pre>")

    // TABLE
	
	d oFile.WriteLine("<hr>")
	
	;*****Cube Stats section
	if pCubeStats {
		d oFile.WriteLine("<br>")
		d oFile.WriteLine("<font size='4' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a name='cubestat'></a>Cube Statistics</b></font>")
		d oFile.WriteLine("<pre>")
		u fHandle d ..PrintCubeStats(0)
		d oFile.WriteLine("</pre>")
		d oFile.WriteLine("<hr>")
	}
	
	;*****Class Dependency section
	d oFile.WriteLine("<br>")
	d oFile.WriteLine("<font size='4' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a name='dependson'></a>Dependencies</b></font>")
	d oFile.WriteLine("<pre>")
	u fHandle d ..PrintDependencies()
	d oFile.WriteLine("</pre>")
	d oFile.WriteLine("<hr>")
	
	
	;*****Agent Log section
	d oFile.WriteLine("<br>")
	d oFile.WriteLine("<font size='4' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a name='agentlog'></a>Agent Log</b></font>")
	d oFile.WriteLine("<pre>")
	u fHandle d ##class(%DeepSee.WorkMgr).%PrintLog()		// DTB706 - The WorkMgr is responsible for printing logs
	d oFile.WriteLine("</pre>")
	d oFile.WriteLine("<hr>")
	
	/* Suppress until PrintAgentMetrics() is fully implemented
	;*****Agent Metrics section
	d oFile.WriteLine("<br>")
	d oFile.WriteLine("<font size='4' face='Arial, Helvetica, sans-serif' color='#0000FF'><b><a name='agentmetrics'></a>Agent Metrics</b></font>")
	d oFile.WriteLine("<pre>")
	u fHandle d ..PrintAgentMetrics()
	d oFile.WriteLine("</pre>")
	d oFile.WriteLine("<hr>")
	*/
	
Footer
	;*****HTML footer
	d oFile.WriteLine("<br>=== End of Report ===")
	d oFile.WriteLine("</body>")
	d oFile.WriteLine("</html>")
	d oFile.Close()
	
	q $$$OK
}

Method %OnNew(pMDX As %String = "") As %Status [ Internal ]
{
	q:pMDX="" $$$ERROR($$$GeneralError, "No MDX Query defined.")
	s ..BaseDir=##class(%File).ComputeFullDBDir($System.Util.DataDirectory())
	
	q $$$OK
}

}
