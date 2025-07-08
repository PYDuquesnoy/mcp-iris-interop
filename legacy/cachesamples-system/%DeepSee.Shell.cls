/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class implements a simple command line shell for executing queries against DeepSee cubes 
/// and viewing the results.
Class %DeepSee.Shell Extends %RegisteredObject [ System = 4 ]
{

/// Simple command line shell for testing queries.<br/>
/// The shell will prompt for an MDX query, execute it and 
/// display its results to the console. Enter "q" and press
/// Enter to exit the Shell.
ClassMethod %Go(pAsync As %Boolean = 1, pCache As %Boolean = 1)
{
	Set tSC = $$$OK
	Set tTrace = 0
	Set tStats = 0
	Set tCache = pCache
	Set tAsync = pAsync
	Set tRecompute = 1
	Set tQuery = ""
	Set tCube = ""
	Set tKey = ""
	Set tShowNodeNums = 0
	Set tXMLA = 0
	Set tMaxRows = 1000
	New %verbose
	
	New %dsflags
	Kill %dsflags

	If ('$$CheckDeepSeeAccess^%qdsUtils()) {
		Write "DeepSee is not enabled on this system.",!
		Quit
	}

	// create a new session (or use the one currently in scope)
	Set tSession = $G($$$DeepSeeSession)
	If ('$IsObject(tSession)) {
		New $$$DeepSeeSession
		Do ##class(%DeepSee.Session).%CreateSession(,.tSC)
		If $$$ISERR(tSC) {
			Write "Error creating DeepSee session:"
			Do $System.Status.DisplayError(tSC)
			Quit
		}
	}

	Write "DeepSee Command Line Shell",!
	Write "----------------------------------------------------",!
	Write "Enter q to quit, ? for help.",!

	While (1) {
		Set tRS = ""
		Write ">>"
		Read x
		Write !

		Set x = $ZSTRIP(x,"<>W") // remove leading/trailing " "
		Set tCommand = $$$UPPER($P(x," ",1))
		Set tFlag = $P(x," ",2,999)
		If ($E(tFlag,1)="""") {
			Set p = $Find(tFlag,"""",2)
			If (p > 0) {
				// quoted string
				Set tFlag = $E(tFlag,2,p-2)
			}
			Else {
				Set tFlag = $P(x," ",2)
			}
		}
		Else {
			Set tFlag = $P(x," ",2)
		}

		// test for commands
		If ((tCommand="?")||(tCommand="HELP")) {
			// Help
			Write "Deep See Command Line Shell",!
			Write "----------------------------------------------------",!
			Write "To execute an MDX query, type it in and press ENTER.",!
			Write !,"Available commands:",!
			Write """q[uit]"" Exit the shell.",!
			Write !
			Write """g[o]"" Run the most recently executed or loaded query.",!
			Write """k[ill] *name*"" Kill saved query.",!
			Write """k[ill] *"" Kill all saved queries.",!
			Write """l[ist]"" List saved queries.",!
			Write """o[pen] *name*"" Open a previously saved query.",!
			Write """s[ave] *name*"" Save the most recently run query using the given name.",!
			Write """i[mport] [file]"" Load a set of queries from a storage file",!
			Write """e[xport] [file]"" Export the current set of saved queries to a storage file",!
			Write !
			Write """#"" Run query most recently run by Analyzer Page.",!
			Write """async [on|off]"" Turn async mode on or off. Async is now: ",$S(tAsync:"on",1:"off"),!
			Write """build <cubename>"" Rebuild the given cube.",!
			Write """cache [on|off]"" Turn result caching on or off. Caching is now: ",$S(tCache:"on",1:"off"),!
			Write """cube"" Display list of available cubes.",!
			Write """cube <cubename>"" Display elements of the given cube.",!
			Write """flag [flagname] [on|off]"" Turn a diagnostic on or off.",!
			Write """func"" Display list of supported MDX functions.",!
			Write """plan"" Show plan.",!
			Write """printquery"" Show the parsed query structure.",!
			Write """reset [0|1]"" Reset the query cache.",!
			Write """rows #"" Set maximum number of rows to display.",!
			Write """set [varname] [value]"" Set the value of a pivot variable.",!
			Write """stats [on|off]"" Display query statistics. Statistics is now: ",$S(tStats:"on",1:"off"),!
			Write """trace [on|off]"" Trace.  Trace is now: ",$S(tTrace:"on",1:"off"),!
			Write """user[name]"" Display the current username.",!
			
			Continue
		}
		ElseIf (tCommand="") {
			Continue
		}
		ElseIf ((tCommand="Q")||(tCommand="QUIT")) {
			Quit
		}
		ElseIf ((tCommand="FLAG")||(tCommand="FLAGS")) {
			Set tOption = $$$UPPER($P(x," ",2))
			Set tValue = $Case($$$UPPER($P(x," ",3)),"ON":1,"OFF":0,:"")
			If ((tOption = "")||(tOption = "?")) {
				// show possible flags
				Write """flag cmbr on|off"" Show current member processing. ",$G(%dsflags("CMBR")),!
				Write """flag compound on|off"" Show rewrite of compound queries. ",$G(%dsflags("COMPOUND")),!
				Write """flag crossjoin on|off"" Show crossjoin processing. ",$G(%dsflags("CROSSJOIN")),!
				Write """flag relations on|off"" Show relationship processing. ",$G(%dsflags("RELATIONS")),!
				Write """flag rewrite on|off"" Show rewrite of query. ",$G(%dsflags("REWRITE")),!
				Write """flag subquery on|off"" Show subquery processing. ",$G(%dsflags("SUBQUERY")),!
			}
			ElseIf ((tOption="CLEAR")||(tOption="RESET")) {
				Kill %dsflags
			}
			Else {
				If (tValue=1) {
					Set %dsflags(tOption)=1
					Set tValue = "on"
				}
				ElseIf (tValue=0) {
					Kill %dsflags(tOption)
					Set tValue = "off"
				}
				Else {
					Set tValue = $Case(+$G(%dsflags(tOption)),1:"on",:"off")
				}
				Write tOption," is: ",tValue,!
			}
			Continue
		}
		ElseIf (tCommand="SET") {
			// JMD1276
			Set tOption = $$$LOWER($P(x," ",2))
			Set tValue = $P(x," ",3,999)
			If ((tOption = "")||(tOption = "?")) {
				// show possible flags
				Write """set variable value"" Set a local pivot variable. ",!
				Write """set CLEAR"" Clear all local pivot variables. ",!
				Set k = $O(tPivotVariables(""))
				While (k'="") {
					Write k," is: ",tPivotVariables(k),!
					Set k = $O(tPivotVariables(k))
				}
			}
			ElseIf ((tOption="clear")) {
				Kill tPivotVariables
			}
			Else {
				Set tPivotVariables(tOption) = tValue
				Write tOption," is: ",tValue,!
			}
			Continue
		}
		ElseIf (tCommand="BUILD") {
			If (tFlag'="") {
				Do ##class(%DeepSee.Utils).%BuildCube(tFlag)
				Write !
			}
			Else {
				Write "Please provide a cube name to build",!
			}
			Continue
		}
		ElseIf (tCommand="RESET") {
			Do ##class(%DeepSee.Utils).%Reset(+tFlag)
			Write "Query cache reset",!
			Continue
		}
		ElseIf (tCommand="EVAL") {
			If (tFlag'="") {
				Set tExpr = "Write "_tFlag
				Try {
					X tExpr
					Write !
				}
				Catch(ex) {
					Write $ZE,!
				}
			}
			Continue
		}
		ElseIf (tCommand="TRACE") {
			Set tTrace = $Case($$$UPPER(tFlag),"ON":1,"OFF":0,:tTrace)
			Write "Trace is: ",$S(tTrace:"on",1:"off"),!
			Set %dstrace = tTrace // !!!
			Continue
		}
		ElseIf (tCommand="STATS") {
			Set tStats = $Case($$$UPPER(tFlag),"ON":1,"OFF":0,:tStats)
			Write "Stats are: ",$S(tStats:"on",1:"off"),!
			Continue
		}
		ElseIf (tCommand="CACHE") {
			Set tCache = $Case($$$UPPER(tFlag),"ON":1,"OFF":0,:tCache)
			Write "Cache is: ",$S(tCache:"on",1:"off"),!
			Continue
		}
		ElseIf (tCommand="RECOMPUTE") {
			Set tRecompute = $Case($$$UPPER(tFlag),"ON":1,"OFF":1,:tRecompute)
			Write "Recompute is: ",$S(tRecompute:"on",1:"off"),!
			Continue
		}
		ElseIf (tCommand="ASYNC") {
			Set tAsync = $Case($$$UPPER(tFlag),"ON":1,"OFF":0,:tAsync)
			Write "Async is: ",$S(tAsync:"on",1:"off"),!
			Continue
		}
		ElseIf (tCommand="XMLA") {
			Set tXMLA = $Case($$$UPPER(tFlag),"ON":1,"OFF":0,:tXMLA)
			Write "XMLA mode is: ",$S(tXMLA:"on",1:"off"),!
			Continue
		}
		ElseIf (tCommand="!") {
			Set tShowNodeNums = 'tShowNodeNums
			Continue
		}
		ElseIf (tCommand="#") {
			// run historic query
			Set n = +tFlag
			If (n = 0) {
				Set n = $G(^DeepSee.QueryLog($UserName))
			}
			If (n="")||('$D(^DeepSee.QueryLog($UserName,n))) {
				Write "No query found: ",n,!
				Continue
			}
			Set x = ^DeepSee.QueryLog($UserName,n)
			Set tQuery = x
			Write x,!
		}
		ElseIf ((tCommand="G")||(tCommand="GO")) {
			// run current query
			If (tQuery = "") {
				Write "There is no query to run.",!
				Continue
			}
			Set x = tQuery
			Write x,!
		}
		ElseIf ((tCommand="S")||(tCommand="SAVE")) {
			// save current query
			If (tQuery = "") {
				Write "There is no query to save.",!
				Continue
			}
			If (tFlag = "") {
				Write "Please provide a name to save the query with.",!
				Continue
			}
			Set ^DeepSee.Shell($UserName,tFlag) = tQuery
			Write "Query saved as: '",tFlag,"'",!
			Continue
		}
		ElseIf ((tCommand="O")||(tCommand="OPEN")) {
			// open query
			If (tFlag = "") {
				Write "Please provide the name of the query to load.",!
				Continue
			}
			Set x = $G(^DeepSee.Shell($UserName,tFlag))
			If (x = "") {
				Write "Query not found: '",tFlag,"'",!
				Continue
			}
			Set tQuery = x
			Write tQuery,!
		}
		ElseIf ((tCommand="ROWS")) {
			// open query
			If (tFlag '= "") {
				Set tMaxRows = +tFlag
			}
			Write "Maximum rows to display is: ",tMaxRows,!
			Continue
		}
		ElseIf ((tCommand="L")||(tCommand="LIST")) {
			// list queries
			Set tName = $O(^DeepSee.Shell($UserName,""))
			While (tName '= "") {
				Write "---------------------------------",!
				Write tName,":",!
				Write $G(^DeepSee.Shell($UserName,tName)),!
				Set tName = $O(^DeepSee.Shell($UserName,tName))
			}
			Continue
		}
		ElseIf ((tCommand="K")||(tCommand="KILL")) {
			// Kill queries
			If (tFlag = "*") {
				Kill ^DeepSee.Shell($UserName)
			}
			ElseIf (tFlag'="") {
				If ('$D(^DeepSee.Shell($UserName,tFlag))) {
					Write "Query not found: '",tFlag,"'",!
				}
				Else {
					Kill ^DeepSee.Shell($UserName,tFlag)
					Write "Query deleted: '",tFlag,"'",!
				}
			}
			Continue
		}
		ElseIf (tCommand="I")||(tCommand="IMPORT") {
			// DP-425786 - Add import
			If (tFlag="") {
				Read "Enter a script file to import: ",tFlag:60
				W !
			}

			If (tFlag="") {
				// Let this fall through to the Continue
				W "No file provided",!
				Continue
			}
			Else {
				// Do the actual import. Read queries from a file formatted with single line "####" delimiters
				Set stream=##class(%Stream.FileCharacter).%New()
				Set sc=stream.LinkToFile($ZSTRIP(tFlag,"<>W"))
				If $$$ISERR(sc) {
					// Recover from link failure and display error
					W $system.Status.GetOneErrorText(sc),!
					Continue
				}

				Set qIdx = 1
				Set mdx=""
				While 'stream.AtEnd {
					Set line=stream.ReadLine()

					if (line'="####") {
						Set mdx=mdx_" "_line
						continue
					}
					While $D(^DeepSee.Shell($UserName,qIdx)) {
						// Search for the next available integer query ID
						Do $I(qIdx)
					}
					Set ^DeepSee.Shell($UserName,qIdx) = $ZSTRIP(mdx,"<>W")
					Write "Import ---------------------------------",!
					Write qIdx,":",!
					Write mdx,!
					
					Set mdx=""
				}

				Kill stream
			}

			Continue
		}
		ElseIf (tCommand="E")||(tCommand="EXPORT") {
			// DP-425786 - Add export
			If (tFlag="") {
				Read "Enter a script file to export: ",tFlag:60
				W !
			}

			If (tFlag="") {
				// Let this fall through to the Continue
				W "No file provided",!
				Continue
			}
			Else {
				// Do the actual export. Write queries to file separated by a "####" which produces files compatible with ISC testing logic.
				Set stream=##class(%Stream.FileCharacter).%New()
				Set sc=stream.LinkToFile($ZSTRIP(tFlag,"<>W"))
				If $$$ISERR(sc) {
					// Recover from link failure and display error
					W $system.Status.GetOneErrorText(sc),!
					Continue
				}

				Set qIdx = $O(^DeepSee.Shell($UserName,""),1,mdx)
				While (qIdx'="") {
					Do stream.WriteLine($ZSTRIP(mdx,"<>W"))
					Do stream.WriteLine("####")

					Set qIdx = $O(^DeepSee.Shell($UserName,qIdx),1,mdx)
				}

				Do stream.%Save()
				Kill stream
			}

			Continue
		}
		ElseIf (tCommand="TASKLOG") {
			Do ##class(%DeepSee.WorkMgr).%PrintLog()		// DTB706 - The WorkMgr now prints logs
			Continue
		}
		ElseIf (tCommand="FUNC") {
			// list functions
			Do ##class(%DeepSee.Utils).%GetFunctionList(.tFuncs)
			Set f = $O(tFuncs(""),1,tUsage)
			While (f'="") {
				Write f,!
				Write ?5,tUsage,!
				Set f = $O(tFuncs(f),1,tUsage)
			}
			Continue
		}
		ElseIf (tCommand="CUBE") {
			Set tCubeName = tFlag
			If (tCubeName = "") {
				// show list of cubes
				Write "Available cubes:",!
				Write "----------------",!
				Do ##class(%DeepSee.Utils).%GetCubeList(.tList)
				Set n = 0
				Set tItem = $O(tList(""))
				While (tItem '= "") {
					Set n = n + 1
					Write n,?5,tItem,!
					Set tItem = $O(tList(tItem))
				}
			}
			Else {
				// show elements of cube
				Write "Elements of cube '",tCubeName,"':",!
				Write "-----------------------------------------",!
				Do ##class(%DeepSee.Utils).%GetDimensionList(tCubeName,.tTree)
				If ($D(tTree)) {
					Do ..%ListMembers(.tTree)
				}
			}
			Continue
		}
		ElseIf (tCommand="AXISINFO") {
			// list axis info
			If ((tCube'="")&&(tKey'="")) {
				Set tCubeIndex = $$$DeepSeeIndex(tCube)
				Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"axis",""),1,tAxisKey)
				While (tAxis '= "") {
					Kill info
					Write "Axis: ",tAxis,!
					Merge info = $$$DeepSeeAxisGLVN(tCubeIndex,tAxisKey,"axes")
					ZW info
					Set tAxis = $O($$$DeepSeeResultsGLVN(tCubeIndex,tKey,"axis",tAxis),1,tAxisKey)
				}
			}
			Continue
		}
		ElseIf (tCommand="CELLINFO") {
			If ((tCube'="")&&(tKey'="")) {
				Do ##class(%DeepSee.Query.Engine).%PrintCells(tCube,tKey)
			}
			Continue
		}
		ElseIf (tCommand = "PLAN") {
			If ((tCube = "")||(tKey = "")) {
				Write "No query to show plan for.",!
				Continue
			}
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareKey(tCube,tKey)
			If $$$ISOK(tSC) {
				Do tRS.%ShowPlan()
			}
			Else {
				Do $System.Status.DisplayError(tSC)
				W !
			}
			Continue
		}
		ElseIf (tCommand = "DRILL") {	// !!!
			If ((tCube = "")||(tKey = "")) {
				Write "No query to drill into",!
				Continue
			}
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareKey(tCube,tKey)
			If $$$ISOK(tSC) {
				Set r1 = +$P(x," ",2)
				Set c1 = +$P(x," ",3)
				Set r2 = +$P(x," ",4)
				Set c2 = +$P(x," ",5)
				Set:r1=0 r1=1
				Set:c1=0 c1=1
				Set:r2=0 r2=r1
				Set:c2=0 c2=c1

				Set tSC = tRS.%GetSlicerForCellRange(.tSubQuery,r1,c1,r2,c2)
				If $$$ISERR(tSC) {
					Do $System.Status.DisplayError(tSC)
					Write !
					Continue
				}
				Write tSubQuery,!				
			}
			Continue
		}
		ElseIf (tCommand="NS") || (tCommand="NAMESPACE") {
			// DP-425786 - Print the current namespace or switch to the requested namespace
			If tFlag'="" {
				zn tFlag
			}
			
			w "Current namespace is " _ $namespace,!
			Continue
		}
		ElseIf (tCommand="PRINTQUERY") {
			// DP-425786 - Print out the structure of the last prepared query using %PrintQuery
			If ((tCube = "")||(tKey = "")) {
				Write "No query to print.",!
			}
			Else {
				Set tRS = ##class(%DeepSee.ResultSet).%New()
				Set tSC = tRS.%PrepareKey(tCube,tKey)
				If $$$ISOK(tSC) {
					Write "%PrintNode of query '",tCube,"':",tKey,!
					Write "-----------------------------------------",!
					Do tRS.%GetQuery().%PrintNode()
				}
				Else {
					Do $System.Status.DisplayError(tSC)
					W !
				}
			}
			Continue
		}
		ElseIf (tCommand="USER")||(tCommand="USERNAME") {
			// DP-425786 - Print username
			W "Current User: " _ $USERNAME,!
			Continue
		}
		Else {
			// remember query
			Set tQuery = x
		}

		// diagnostic code
		If ('tCache) {
			If (tCube'="") {
				Set tCubeIndex = $$$DeepSeeIndex(tCube)
				Kill $$$DeepSeeResultsGLVN(tCubeIndex)
				Kill $$$DeepSeeAxisGLVN(tCubeIndex)
				Kill $$$DeepSeeCellsGLVN(tCubeIndex)		// DTB866
			}
		}

		Set tCube = ""
		Set tKey =""

		// Do ##class(%DeepSee.Utils).%WriteToLog("Shell",tQuery)

		Set tStartTime = $ZH
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		// Set tRS.%Trace = tTrace
		Set tRS.%UseCache = tCache
		Set tRS.%Recompute = tRecompute
		Set tSC = tRS.%PrepareMDX(tQuery,.tPivotVariables)
		If $$$ISERR(tSC) {
			Do $System.Status.DisplayError(tSC)
			Write !
			Continue
		}

		// test if the query has named parameters
		Kill tParmValues
		Set tSC = tRS.%GetParameterInfo(.tParms)
		If $$$ISERR(tSC) {
			Do $System.Status.DisplayError(tSC)
			Write !
			Continue
		}

		If $D(tParms) {
			// prompt for parameter values
			Set tFirst = 1
			Set p = $O(tParms(""))
			While (p '= "") {
				Set tValue = $G(tParms(p,"VALUE"))
				Set tPrivate = +$G(tParms(p,"PRIVATE"))
				Set tCaption = $G(tParms(p,"CAPTION"),p)
				If ('tPrivate) {
					If (tFirst) {
						Write !,"Please supply parameter value(s) for this query:",!
						Set tFirst = 0
					}
					Write tCaption
					If (tValue'="") {
						Write " (",tValue,")"
					}
					Write ":"
					Read pv
					Write !
					If (pv'="") {
						Set tParmValues(p) = pv
					}
				}
				Set p = $O(tParms(p))
			}
		}

		If (tAsync) {
			Set %verbose = 1
			Set tSC = tRS.%ExecuteAsynch(.tQueryKey,.tParmValues)
			
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Write !
				Continue
			}
			Set tCube = tRS.%GetCubeName()
			Set tKey = tRS.%GetQueryKey()
			Write "Processing..."
			Hang 0.01
			Set tCount = 0
			Set tStatus = tRS.%GetStatus(.tComplete,.tSC)
			// Do ##class(%DeepSee.Utils).%WriteToLog("Shell","Waiting... " _tStatus)
			While ((tStatus<100)&&(tStatus>0)&&$$$ISOK(tSC)) {
				Set tCount = tCount + 1
				Set tMsg = $S(tStatus < 35:"Computing axes...",tStatus < 90:"Computing cells...",1:"Consolidating results...")
				Write $C(13,27)_"[0J"
				Write $J(tCount,4),": ",tMsg,"(",tStatus,")  "
				If (tComplete '= "") {
					Write $FN(tComplete,",",2),"% complete"
				}
				Hang $Case(tCount,1:0.1,2:0.2,:0.5)
				Set tStatus = tRS.%GetStatus(.tComplete,.tSC)
			}
			Write $C(13,27)_"[0J"
			If (tStatus < 0) {
				Write "ERROR: Query status of -1",!
			}
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Write !
				Continue
			}
		}
		Else {
			Kill %verbose
			Set tSC = tRS.%Execute(.tParmValues)
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Write !
				Continue
			}
			Set tCube = tRS.%GetCubeName()
			Set tKey = tRS.%GetQueryKey()
		}

		If (tTrace) {
			Write tRS.%GetQuery().%ToString(),!
		}

		If (tXMLA) {
			Set tSC = tRS.%OutputXMLA()
			If $$$ISERR(tSC) {
				Do $System.Status.DisplayError(tSC)
				Write !
				Continue
			}
		}
		Else {
			Set tElapsedTime = $ZH - tStartTime

			Write !
			If tRS.%GetStatus() {		// DTB097
				Set tSC = tRS.%Print(.stat,tShowNodeNums,tMaxRows)
				If $$$ISERR(tSC) {
					//Do $System.Status.DisplayError(tSC)
					Write !
					Continue
				}
				If (tStats) {
					Write $TR($J("=",44)," ","="),!
					Do tRS.%PrintStatistics()
				}
				Write $TR($J("-",75)," ","-"),!
				Write "Elapsed time:",?20,tElapsedTime,"s",!

				// Test for pending results...
				Set tPendingUsed = 0
				If ((tCube'="")&&(tKey'="")) {
					Set tQueryStatus = tRS.%GetQueryStatus(tCube,tKey,.tPctComplete,.tQSC,.tPending)
					While (tPending) {
						Write "Results pending...",!
						Set tSC = ##class(%DeepSee.Query.Engine).%UpdatePendingResults(tCube,tKey,.tPending)
						If $$$ISERR(tSC) {
							Write "Error in %UpdatePendingResults:",!
							Do $System.Status.DisplayError(tSC)
						}
						Set tSC = tRS.%Print(.stat,tShowNodeNums,tMaxRows)
						Hang:tPending 1
						Set tPendingUsed = 1
						Write $TR($J("-",75)," ","-"),!		// DP-428448
						Set tElapsedTime = $ZH - tStartTime
					}
				}

				Write:+$G(tPendingUsed) "Elapsed time:",?20,tElapsedTime,"s",!		// DP-428448
			}
			Else {
				// +DTB097 - Something went wrong in execution--look for a query error.
				Set tSubjectIndex = $$$UPPER(tRS.%GetCubeName())
				Set tCubeIndex = ##class(%DeepSee.Utils).%GetBaseCube(tSubjectIndex)
				If tCubeIndex="" {
					Set tCubeIndex = tSubjectIndex
				}

				Set tQueryKey = tRS.%GetQueryKey()
				If tQueryKey="" {
					Set tQueryKey = tRS.%Query.%QueryKey
				}
	
				If $D($$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"error")) {
					// Look for an error in the query cache. If we find one, display it
					Set tSC = $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"error")
				}
				ElseIf $$$ISERR(tSC) {
					// If tSC already contains an error show it, even if ugly
				}
				Else {
					// Otherwise, just give a generic error
					Set tSC = $$$ERROR($$$GeneralError,"Query failed to complete")
				}
				
				Do $system.OBJ.DisplayError(tSC)
				W !
				Set tSC = $$$OK
				// -DTB097
			}
		}
	}

	// If we created a session, clean it up
	If ('$IsObject(tSession)) {
		Set x = $$$DeepSeeSession.%EndSession()
	}
}

/// Write out members of the cube's dimension list.
ClassMethod %ListMembers(ByRef pTree)
{
	Set tDimName = ""
	Set tHierName = ""
	Set tLevelName = ""

	// walk over dimension index
	Set tDimNo = $O(pTree(""))
	While (tDimNo '= "") {
		Set tHierNo = $O(pTree(tDimNo,""))
		While (tHierNo '= "") {
			Set tLevelNo = $O(pTree(tDimNo,tHierNo,""),1,info)
			While (tLevelNo '= "") {
				If (tDimName '= $LG(info,2)) {
					Set tDimName = $LG(info,2)
					Write tDimName,!
				}
				If (tHierName '= $LG(info,3)) {
					Set tHierName = $LG(info,3)
					Write:tHierName'="" ?2,tHierName,!
				}
				If (tLevelName '= $LG(info,4)) {
					Set tLevelName = $LG(info,4)
					Write:tLevelName'="" ?4,tLevelName,!
				}
				Set tLevelNo = $O(pTree(tDimNo,tHierNo,tLevelNo),1,info)
			}
			Set tHierNo = $O(pTree(tDimNo,tHierNo))
		}
		Set tDimNo = $O(pTree(tDimNo))
	}
}

/// Read a series of MDX queries from file <var>pQueryFile</var>, execute them
/// and write the results to file <var>pResultFile</var>.<br/>
/// A query consists of all text up to a line containing the command "go".<br/>
/// If <var>pResultFile</var> is not supplied, write results to the console.<br/>
/// If <var>pShowStats</var> is false, do not write query statistics.
ClassMethod %RunQueryFile(pQueryFile As %String, pResultFile As %String = "", pShowStats As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		Set io = $io
		Set tQueryFile = ##class(%File).%New(pQueryFile)
		Set tSC = tQueryFile.Open("R")
		If $$$ISERR(tSC) Quit

		If (pResultFile'="") {
			Open pResultFile:("NWS"):5
			Use pResultFile
			Write "********************************************************",!
			Write "Results for file: ",pQueryFile,!
			Write:pShowStats "Namespace: ",$namespace,!
			Write:pShowStats "Time started: ",$ZDT($H,3),!
		}

		Set tQueryNo = 0
		Set tMDX = ""
		While ('tQueryFile.AtEnd) {
			Set tLine = tQueryFile.ReadLine()
			If ($$$UPPER(tLine)'="GO") {
				Set tMDX = tMDX _ tLine
			}
			Else {
				Set tQueryNo = tQueryNo + 1
				If (pResultFile'="") {
					Use pResultFile
					Write "------------------------------------------------------",!
					Write "Query ",tQueryNo,!
					Write tMDX,!
					Use io
				}
				Else {
					Write "------------------------------------------------------",!
					Write "Query ",tQueryNo,":",!,tMDX,!
				}
				Set tRS = ##class(%DeepSee.ResultSet).%New()
				Set tSC = tRS.%PrepareMDX(tMDX)
				Set tMDX = ""
				If $$$ISERR(tSC) {
					Do $System.Status.DisplayError(tSC)
					If (pResultFile'="") {
						Use pResultFile
						Do $System.Status.DisplayError(tSC)
						Write !
						Use io
					}
					Set tSC = $$$OK
					Continue
				}

				Set tSC = tRS.%ExecuteAsynch()
				
				If $$$ISERR(tSC) {
					Do $System.Status.DisplayError(tSC)
					If (pResultFile'="") {
						Use pResultFile
						Do $System.Status.DisplayError(tSC)
						Write !
						Use io
					}
					Set tSC = $$$OK
					Continue
				}
				// show progress to console
				Set tCube = tRS.%GetCubeName()
				Set tKey = tRS.%GetQueryKey()
				Write "Processing..."
				Hang 0.01
				Set tCount = 0
				Set tStatus = tRS.%GetStatus(.tComplete)
				While ((tStatus<100)&&(tStatus>=0)) {
					Set tCount = tCount + 1
					Set tMsg = $S(tStatus < 35:"Computing axes...",tStatus < 90:"Computing cells...",1:"Consolidating results...")
					Write $C(13,27)_"[0J"
					Write $J(tCount,4),": ",tMsg,"(",tStatus,")  "
					If (tComplete '= "") {
						Write $FN(tComplete,",",2),"% complete"
					}
					Hang $Case(tCount,1:0.1,2:0.2,:0.5)
					Set tStatus = tRS.%GetStatus(.tComplete)
				}
				Write $C(13,27)_"[0J"
				If (tStatus < 0) {
					Write "ERROR: Query status of -1",!
				}
				
				// Show results
				If (pResultFile'="") {
					Use pResultFile
				}
				Write "------------------------------------------------------",!
				Do tRS.%Print()
				Write "------------------------------------------------------",!
				If (pResultFile'="") {
					Use io
				}

				If (pShowStats) {
					If (pResultFile'="") {
						Use pResultFile
					}
					Do tRS.%PrintStatistics()
					If (pResultFile'="") {
						Use io
					}
				}
				Set tRS = ""
			}
		}

		If (pResultFile'="") {
			Use pResultFile
			Write !!
			Write "Time completed: ",$ZDT($H,3),!
			Write "********************************************************",!
			Use io
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}

	// restore device
	Use:$D(io) io

	If (pResultFile'="") {
		Close pResultFile

		// also write error to console
		If $$$ISERR(tSC) {
			Do $System.Status.DisplayError(tSC)
		}
	}
	Quit tSC
}

}
