/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Playback Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// This process ID
Property ProcessID As %String [ InitialExpression = {$job} ];

/// A unique number representing this run
Property RunID As %Integer;

/// Container for the Run object
Property Run As %WebStress.Run;

/// Pointer to %WebStress.Tests
Property TestID As %Integer;

/// Container for the %WebStress.Tests object
Property Test As %WebStress.Tests;

/// Pointer to %WebStress.Scripts
Property ScriptID As %Integer;

/// Container for the %WebStress.Script object
Property Script As %WebStress.Scripts;

/// The name of the generator that will be used to generate the traffic
Property Generator As %String;

/// The address of the web server that will be used
Property WebServer As %String;

/// The port number on the web server
Property WebServerPort As %Integer;

/// The number of sessions per process
Property Sessions As %Integer;

/// The date that the test run will start. Can be blank.
Property StartDate As %Date;

/// The date that the test run will stop. Can be blank.
Property StopDate As %Date;

/// The time that the test run will start. Can be blank.
Property StartTime As %Time;

/// The time that the test run will stop. Can be blank.
Property StopTime As %Time;

/// The number of minutes that the test will run. Used instead of start/stop date/time or can be blank if start/stop date/time are used.
Property RunMins As %Integer;

/// The number of minutes that the test will run for before recording the statistics starts.
/// <br>
/// This is to ensure that all the processes are running and that a consistent load is being applied to the server before the recording starts.
/// <br>
/// The value should be long enough to ensure that each script is able to run through to completion at least once
Property WarmUpMins As %Integer;

/// The number of minutes that the test will run for at the end of recording the statistics.
/// <br>
/// This ensures that we do not get any abnormally 'quick' timings at the end of statistics recording due to a lower load on the server.
Property CoolDownMins As %Integer;

/// The number of seconds to pause at the end of each script.
/// <br>
/// This gives a more realistic playback as 'human' input would normally pause before running the same workflow again.
Property ScriptPause As %Integer;

/// This is a pointer to the URL in the script that we will loop back to rather than just back to the first URL.
/// <br>
/// This may because the first URL is thestart of the user login process and we don't want to have the 'virtual user' logging in every time.
Property LoopBackURL As %Integer;

/// This is the percentage of the time that the LoopBackURL will be used rather than the first URL
Property LoopBackPcnt As %Integer;

/// The difference between the time on this machine and the time on the 'controller' (The system that initiated the run)
Property TimeDiff As %Float;

/// This property used internally for debugging and logging purposes.
Property debug As %Boolean;

/// A flag that indicates whether or not to save the returned page information into disk files.
Property SavePage As %Boolean;

/// The root directory of where to sabe the returned page details if indicated to do so by the SavePage property
Property SavePageDir As %String;

/// Used to hold an array of all the page types where we specify no delay before making the call
Property NoDelay As array Of %String;

/// Used to hold an array of all the page types where we don't want to record statistics
Property NoResults As array Of %String;

/// A collection of sessions for this process
Property HttpSessions As list Of %WebStress.Playback.Session;

Property RecordStart As %Integer;

Property RecordStop As %Integer;

Property TestStop As %Integer;

Property ProxyAddress As %String;

Property ProxyPort As %Integer;

Property SSLConfiguration As %String;

Property NextInvoke As %String [ MultiDimensional ];

Property Status As %WebStress.Playback.Status;

/// The array showing which session is to be run next
Index Main On (RunID, Generator, ProcessID) [ IdKey, PrimaryKey, Unique ];

/// Enter here to start the run processing
ClassMethod Run(RunID As %Integer, TestID As %Integer, ScriptID As %Integer, Generator As %String, WebServer As %String, WebServerPort As %Integer = 80, Sessions As %Integer = 1, StartDate As %Date = "", StopDate As %Date = "", StartTime As %Time = "", StopTime As %Time = "", RunMins As %Integer, WarmUpMins As %Integer, CoolDownMins As %Integer, ScriptPause As %Integer, LoopBackUrl As %Integer = "", LoopBackPcnt As %Integer = "", TimeDiff As %Integer, debug As %Boolean = 0, Visual As %Boolean = 0, SavePage As %Boolean = 0, SavePageDir As %String, ProxyAddress As %String, ProxyPort As %Integer, SSLConfiguration As %String)
{
	try {
		// We need an entry in the Playback class in case anything goes wrong
		set objPlayback = ##class(%WebStress.Playback).%New()
		set objPlayback.RunID = RunID
		set objPlayback.TestID = TestID
		set objPlayback.ScriptID = ScriptID
		set objPlayback.Generator = Generator
		set objPlayback.WebServer = WebServer
		set objPlayback.WebServerPort = WebServerPort
		set objPlayback.Sessions = Sessions
		set objPlayback.StartDate = StartDate
		set objPlayback.StopDate = StopDate
		set objPlayback.StartTime = StartTime
		set objPlayback.StopTime = StopTime
		set objPlayback.RunMins = RunMins
		set objPlayback.WarmUpMins = WarmUpMins
		set objPlayback.CoolDownMins = CoolDownMins
		set objPlayback.ScriptPause = ScriptPause
		set objPlayback.LoopBackURL = LoopBackUrl
		set objPlayback.LoopBackPcnt = LoopBackPcnt
		set objPlayback.TimeDiff = TimeDiff
		set objPlayback.debug = debug
		set objPlayback.SavePage = SavePage
		set objPlayback.SavePageDir = SavePageDir
		set objPlayback.ProxyAddress = ProxyAddress
		set objPlayback.ProxyPort = ProxyPort
		set objPlayback.SSLConfiguration = SSLConfiguration
				
		// Check the various parameters before we go any further
		if debug use $principal write !,"Checking Test exists"
		if ##class(%WebStress.Tests).%ExistsId(TestID) {
			if debug use $principal write !,"Checking Script exists"
			if ##class(%WebStress.Scripts).%ExistsId(ScriptID) {
				if debug use $principal write !,"Locking Run global"
				// Lock the global to indicate that we're running
				lock +^WebStress.Run(##class(%WebStress.Control).SystemID(),$Job):0 set sc=$Test
				if sc {
			
					// Initiate the playback object with everything that is needed for this process and clear down any existing data
					do ##class(%WebStress.Playback).%DeleteId(RunID_"||"_Generator_"||"_$job)
					//kill ^WebStress.Iterations(TestID,RunID,##class(%WebStress.Control).SystemID(),ScriptID,"I")
					set objScript = ##class(%WebStress.Scripts).%OpenId(ScriptID,0,.status)
					set ScriptName = objScript.Name
	
					// Entry for monitor etc
					set ^WebStress.ControlD(TestID,##class(%WebStress.Control).SystemID(),"Jobs",$Job)=ScriptID
	
					&sql(delete from %WebStress_Results.Calls where TestID = :TestID and RunID = :RunID and Script = :ScriptName and Generator = :Generator and WebServer = :WebServer and Process = :Process)				
					set process = $job
					&sql(delete from %WebStress_Playback.Status where ProcessId = :process)
					set objStatus = ##class(%WebStress.Playback.Status).%New()
					set objStatus.TestID = TestID
					set objStatus.RunID = RunID
					set objStatus.Script = ScriptName
					set objPlayback.ProcessID = process
					set objStatus.Status = 1
					set objStatus.StatusText = "Starting"
					set objStatus.ProcessID = $job
					set objStatus.SystemID = ##class(%WebStress.Control).SystemID()
					do objStatus.%Save()
					set objPlayback.Status = objStatus
	
					if debug use $principal write !,objStatus.StatusText
	
					// Calculate the internal properties
					do objPlayback.GetTimes()
	
					set ^WebStress.ControlD(TestID,##class(%WebStress.Control).SystemID(),"Jobs",$Job) = ScriptID
					// Ensure that we have at least one session
					if Sessions < 1 set Sessions = 1
					// Gather all the information that we'll need
					if (StartDate '= "")&&(StartTime '= "") {
						set thisTime = StartDate * 86400 + StartTime
						set correctedTime = thisTime - TimeDiff
						set StartDate = correctedTime \ 86400, StartTime = correctedTime # 86400
						set thisTime = StopDate * 86400 + StopTime
						set correctedTime = thisTime - TimeDiff
						set StopDate = correctedTime \ 86400, StopTime = correctedTime # 86400
					}
					set objPlayback.Test = ##class(%WebStress.Tests).%OpenId(TestID,0)
					set objPlayback.Script = ##class(%WebStress.Scripts).%OpenId(ScriptID,0)

					// Get the 'no delay' page types
					set objRs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
					do objRs.Prepare("select Code from %WebStress_Tables.NoDelay")
		   			do objRs.Execute()
					while objRs.Next() {
						set code = $zconvert(objRs.GetData(1),"l")
						do objPlayback.NoDelay.SetAt("",code)
					}
				
					// Get the 'no results' page types
					set objRs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
					do objRs.Prepare("select Code from %WebStress_Tables.NoResults")
	    			do objRs.Execute()
					while objRs.Next() {
						set code = $zconvert(objRs.GetData(1),"l")
						do objPlayback.NoResults.SetAt("",code)
					}

					// Setup the session data for each session
					for session = 1:1:objPlayback.Sessions {
						set objSession = ##class(%WebStress.Playback.Session).%New()
						set objSession.HttpRequest = ##class(%Net.HttpRequest).%New()
						set objSession.WebServer = WebServer
						set sessionStart = (objPlayback.Script.TotalLengthMins * 60) / objPlayback.Sessions * (session-1) + $zh
		        		set objPlayback.NextInvoke(sessionStart,session) = $listbuild(objPlayback.Script.URLs.Next(""),1)
						do objPlayback.HttpSessions.InsertAt(objSession,session)
					}

					// Now wait for the correct signal/time to start
					set objStatus.Status = 2
					set objStatus.StatusText = "Waiting for start"
					if debug use $principal write !,objStatus.StatusText
					do objStatus.%Save()
			
					set status = ..RunWait(TestID,StartDate,StopDate,StartTime,StopTime)
			   
					// Ok to go!
				    if status = 1 {
					    if debug use $principal write !,"Warmup"
					    set objStatus.Status = 3
					    set objStatus.StatusText = "Warmup"
						do objStatus.%Save()
					    do objPlayback.Playback()
				    }
				    else {
					    set objStatus.Status = 6
					    set objStatus.StatusText = "Stopping"
						if debug use $principal write !,objStatus.StatusText
					    do objStatus.%Save()
				    }
    
				    if objStatus.Status '= 0 set objStatus.Status = 7, objStatus.StatusText = "Stopped"
				    if debug use $principal write !,objStatus.StatusText
		    		do objStatus.%Save()
				}
				else {
					if debug use $principal write !,"Could not lock process run entry"
					do objPlayback.SetError(0,"","",2,"Could not lock process run entry")
				}
			}
			else {
				if debug use $principal write !,"No Script exists for ScriptID = "_ScriptID
				do objPlayback.SetError(0,"","",2,"No Script exists for ScriptID = "_ScriptID)
			}
		}
		else {
			if debug use $principal write !,"No Test exists for TestID = "_TestID
			do objPlayback.SetError(0,"","",2,"No Test exists for TestID = "_TestID)
		}
    
	    // Now unlock the status global again
	    lock -^WebStress.Run(##class(%WebStress.Control).SystemID(),$Job)
	}
	catch {
		// Overall error catch
		if $data(objPlayback) {
			do objPlayback.SetError(0,"","",2,$zerror)
		}
		
	}
}

/// This runs the playback
Method Playback()
{
	#dim objParam as %WebStress.Scripts.URLS.Parameters
	#dim objUrl as %WebStress.Scripts.URLS
	
	// Keep looping until told to stop
	set runTime = ""
	for  {
		if ..RunStop() quit
		// Get the next run time from the array
		set runTime = $order(..NextInvoke(runTime))
		if (runTime '= "")&&(runTime '> $zh) {
			set session = ""
			for  {
				// Get each session for this run time
				set session = $order(..NextInvoke(runTime,session),1,data)
				if session = "" quit
				set urlId = $list(data,1)
				set firstUrl = $list(data,2)
				if (firstUrl)&&(..Script.PreRunCode '= "") do ..PreRunCode()
				// Now get rid of this next invoke entry. We will set another entry at the end of this script run
				kill ..NextInvoke(runTime,session)
				// Keep checking the stop flag as each session's run can take a while
				if ..RunStop() quit
				set objUrl = ..Script.URLs.GetAt(urlId)
				set ..HttpSessions.GetAt(session).HttpRequest.HTTPVersion = $piece(objUrl.Protocol,"/",2)
				if objUrl.SpecifiedPort '= "" {
					set ..HttpSessions.GetAt(session).HttpRequest.Port = objUrl.SpecifiedPort
				}
				else {
					set ..HttpSessions.GetAt(session).HttpRequest.Port = ..WebServerPort
				}
				if (..Script.OriginalServer '= objUrl.ServerChange)&&(objUrl.ServerChange '= "") {
					set ..HttpSessions.GetAt(session).HttpRequest.Server = objUrl.ServerChange
				}
				else {
					set ..HttpSessions.GetAt(session).HttpRequest.Server = ..WebServer
				}
				if (..ProxyAddress '= "")&&(..ProxyPort '= "") {
					set ..HttpSessions.GetAt(session).HttpRequest.ProxyPort = ..ProxyPort
					set ..HttpSessions.GetAt(session).HttpRequest.ProxyServer = ..ProxyAddress
				}
				if ..SSLConfiguration '= "" {
					set ..HttpSessions.GetAt(session).HttpRequest.SSLConfiguration = ..SSLConfiguration
					set ..HttpSessions.GetAt(session).HttpRequest.Https = 1
				}
				
				// Check to see if the session ID is stored and if so then put it into the headers
				if (..HttpSessions.GetAt(session).CSPSessionType = "C")&&(..HttpSessions.GetAt(session).CSPSessionCookie '= "") {
					do ..HttpSessions.GetAt(session).HttpRequest.SetHeader("Cookie",..HttpSessions.GetAt(session).CSPSessionCookie)
				}
				
				// Overwrite the timeout when specified
				if ..Test.Timeout '= "" set ..HttpSessions.GetAt(session).HttpRequest.Timeout = ..Test.Timeout
				
				// Check for whether this session is ready to store the results from the call
				set ..HttpSessions.GetAt(session).Record = ..CheckRecordStatus()
				
				// Do the pre-execute
				// All we will allow for the moment is changing the parameters
				// which are the important ones for the randomisation
				kill params,paramIndex
				// Now get the parameters
				// We setup the array of 'params' in order to be legacy compliant with previous versions
				set param = ""
				for  {
					set objParam = objUrl.Parameters.GetNext(.param)
					if param = "" quit
					if objParam.Key '= "" {
						set params(objParam.Key) = objParam.Type
						set index = $increment(paramIndex(objParam.Key))
						if objParam.Key '= "CSPCHD" set params(objParam.Key,index) = objParam.Value
					}
				}

				// Now call the pre-execute
				// Pass in as many potentially useful variables as possible
				if objUrl.PreExecute '= "" do ..PreExecute(.objUrl,.params)

				// Now put the parameters back in
				set key = ""
				for  {
					set key = $order(params(key),1,type)
					if key = "" quit
					if key '= "CSPCHD" {
						set index = ""
						for  {
							set index = $order(params(key,index),1,value)
							if index = "" quit
							if type = "P" {
								do ..HttpSessions.GetAt(session).HttpRequest.SetParam(key,value,index)
							}
							else {
								do ..HttpSessions.GetAt(session).HttpRequest.InsertFormData(key,value)
							}
						}
					}
				}
				// If we are using the CSPToken then put that into the parameters so that the links will work
				if ..HttpSessions.GetAt(session).CSPSessionType = "T" do ..HttpSessions.GetAt(session).HttpRequest.InsertFormData("CSPCHD",..HttpSessions.GetAt(session).CSPSessionToken)
				
				// Get page type to check against 'nodelay' array
				set pageSuffix = $zconvert($piece(objUrl.Path,".",$length(objUrl.Path,".")),"l")
				if '..NoDelay.IsDefined(pageSuffix) {
					// Delay before call			
					if ..Test.DelayType = "U" {
						// Use the delay that was in the recorded script
						hang (objUrl.Delay / 1000)
					}
					elseif ..Test.DelayType = "R" {
						// Use a random delay
						set delay = $random(..Test.RandomDelayMax) + ..Test.RandomDelayMin
						hang delay
					}
				}
				
				// If we have to save anything to files then start now as otherwise the data could change after the calls
				if ..SavePage {
					set dir = ##class(%Library.File).NormalizeDirectory(..SavePageDir)
					set dir = dir_$job, dir = ##class(%Library.File).NormalizeDirectory(dir)
					set dir = dir_session, dir = ##class(%Library.File).NormalizeDirectory(dir)
					if '##class(%Library.File).DirectoryExists(dir) do ##class(%Library.File).CreateDirectoryChain(dir)
					set file = dir_urlId_"."_pageSuffix
					set fileTxt = file_".txt"
					// Now put out a text file with all the calls and headers etc
					open fileTxt:"WNS":1 set ok = $test
					if ok {
						use fileTxt
						write objUrl.Verb," ",objUrl.Path,!
						do ..HttpSessions.GetAt(session).HttpRequest.OutputHeaders()
						write !!
						do ..HttpSessions.GetAt(session).HttpRequest.OutputParams("","")
						write !!
						set stream = ##class(%Stream.TmpCharacter).%New()
						set x = ..HttpSessions.GetAt(session).HttpRequest.OutputFormData(stream,"")
						do stream.Rewind()
						write stream.Read()
						write !!
						close fileTxt
					}
				}
				
				// Now make the call to the server
				if ..debug use $principal write !,urlId," ",objUrl.Verb," ",objUrl.Path
				if objUrl.Verb = "GET" {
					set status = ..HttpSessions.GetAt(session).HttpRequest.Get(objUrl.Path)
				}
				elseif objUrl.Verb = "POST" {
					set status = ..HttpSessions.GetAt(session).HttpRequest.Post(objUrl.Path)
				}
				// Do the post execute
				if objUrl.PostExecute '= "" do ..PostExecute(.objUrl)
				
				if status {
					// Perform any user specified error checking
					set errorStatus = 0
					if ..Script.ErrorCheck '= "" do ..ErrorCheck(.errorStatus,.errorText,.objUrl,session,urlId)
					if errorStatus {
						// Setup the error
						if errorStatus {
							do ..SetError(session,urlId,objUrl,errorStatus,errorText)
                            if errorStatus=2 {
                                //Fatal
                                set ..Status.Status = 8
                                set ..Status.StatusText = errorText
                                do ..Status.%Save()
                                halt
                            }
                        }
					}
					
					else {
						// Now store the results
						if (..HttpSessions.GetAt(session).Record = 1)&&('..NoResults.IsDefined(pageSuffix)) {
							set objResult = ##class(%WebStress.Calls).%New()
							set objResult.TestID = ..TestID
							set objResult.RunID = ..RunID
							set objResult.Script = ..Script.Name
							set objResult.Generator = ..Generator
							set objResult.WebServer = ..WebServer
							set objResult.Process = $job
							set objResult.Session = session
							set objResult.Iteration = ..HttpSessions.GetAt(session).Iterations
							set objResult.URL = urlId
							set objResult.Verb = objUrl.Verb
							set objResult.Path = objUrl.Path
							set objResult.CharactersSent = ..HttpSessions.GetAt(session).HttpRequest.SentChars
							set objResult.CharactersReceived = ..HttpSessions.GetAt(session).HttpRequest.RecChars
							set objResult.TimeToFirstCharacter = $justify(..HttpSessions.GetAt(session).HttpRequest.TTFC * 1000,0,0)
							set objResult.TimeToLastCharacter = $justify(..HttpSessions.GetAt(session).HttpRequest.TTLC * 1000,0,0)
							set objResult.HttpStatusCode = ..HttpSessions.GetAt(session).HttpRequest.HttpResponse.StatusCode
							set objResult.RecordedTime = ($horolog * 86400) + $piece($horolog,",",2) - ..TimeDiff
							set status = objResult.%Save()
							if 'status do ..SetError(session,urlId,objUrl,1,$system.Status.GetOneErrorText(status,1))
						}
					}
					
					// Save the page content
					if ..SavePage {
						// Just save the 'normal' content to the standard file name
						open file:"WNS":1 set ok = $test
						if ok {
							use file
							do ..HttpSessions.GetAt(session).HttpRequest.HttpResponse.Data.OutputToDevice()
							close file
						}
						// Now add in the full response content to the text file
						open fileTxt:"WAS":1 set ok = $test
						if ok {
							use fileTxt
							do ..HttpSessions.GetAt(session).HttpRequest.HttpResponse.OutputToDevice()
							close fileTxt
						}
					}
					
					// Put the returned headers back into the session object
					// Remove cookies first
					do ..HttpSessions.GetAt(session).HttpRequest.RemoveHeader("Cookie")
					set header = ""
					for  {
						set header = ..HttpSessions.GetAt(session).HttpRequest.HttpResponse.GetNextHeader(header)
						if header = "" quit
						set head = $zconvert($piece(header,":",1),"U")
						if head = "SET-COOKIE" {
							set value = ..HttpSessions.GetAt(session).HttpRequest.HttpResponse.GetHeader(header)
							if $zcvt(value,"U")["CSPSESSIONID" {
								set ..HttpSessions.GetAt(session).CSPSessionType = "C"
								set ..HttpSessions.GetAt(session).CSPSessionCookie = value
							}
							else {
								do ..HttpSessions.GetAt(session).HttpRequest.SetHeader("Cookie",value)
							}
						}
					}
					// Need to check here in page content if we need the CSPCHD (Token) value for this session
					// No need to go through the page content if we already have a marker for either Token or Cookie
					if ..HttpSessions.GetAt(session).CSPSessionType = "" {
						do ..HttpSessions.GetAt(session).HttpRequest.HttpResponse.Data.Rewind()
						set found = 0
						do {
							set temp = ..HttpSessions.GetAt(session).HttpRequest.HttpResponse.Data.Read()
							if temp["CSPCHD=" {
								set f1 = $find(temp,"CSPCHD=")
								// Read more into the 'temp' variable so that we will find the delimiters
								set temp = $extract(temp,f1-10,$length(temp))
								while $length(temp) < 1000 {
									set temp = temp_..HttpSessions.GetAt(session).HttpRequest.HttpResponse.Data.Read(1000)
								}
								set f1 = $find(temp,"CSPCHD=")
								// See if we can find an '>' signifying that this is in the HTML <a> type link
								set f2 = $find(temp,">",f1)
								if 'f2 {
									// Look for a double quote instead
									set f2 = $find(temp,"""",f1)
									if 'f2 {
										// try a single quote
										set f2 = $find(temp,"'",f1)
										if f2 set found = 1
									}
									else {
										// Found it in the double quote
										set found = 1
									}
								}
								else {
									// Found it in the <a> type element
									set found = 1
								}
							}
						} while ('found)&&('..HttpSessions.GetAt(session).HttpRequest.HttpResponse.Data.AtEnd)
						if found {
							// So we have the string with the CSPToken value. Now we need to isolate it
							// Sub-string on the found delimiter
							set value = $extract(temp,f1,f2-2)
							// Remove any type of quote and also any named pair separator
							set value = $piece($piece($piece(value,"""",1),"'",1),"&",1)
							if value '= "" {
								// So long as we have something then put it into the array
								set ..HttpSessions.GetAt(session).CSPSessionType = "T"
								set ..HttpSessions.GetAt(session).CSPSessionToken = value
							}
						}
					}
				}
				else {
					// Didn't get a good status code back from the call
					do ..SetError(session,urlId,objUrl,1,$system.Status.GetOneErrorText(status,1))
				}
					
				// Now set the next invoke entry
				set delay = objUrl.Delay\1000
				if ..Test.DelayType = "N" set delay = 0
				if ..Test.DelayType = "R" set delay = ..Test.RandomDelayMin +$random(..Test.RandomDelayMax - ..Test.RandomDelayMin)
				set urlId = ..Script.URLs.Next(urlId), firstUrl = 0
				if urlId = "" {
					// End of script
					set val = ..HttpSessions.GetAt(session).Iterations
					set x = $increment(val)
					set ..HttpSessions.GetAt(session).Iterations = val
					if ..Script.PostRunCode '= "" do ..PostRunCode()
					set urlId = ..Script.URLs.Next("")
					if ..HttpSessions.GetAt(session).Record = 1 {
						set x = $increment(^WebStress.Iterations(..TestID,..RunID,##class(%WebStress.Control).SystemID(),..ScriptID,"I"))
					}
					// Check for loop back percentage
					if +..LoopBackURL {
						set loopCheck = (x#10) * (..LoopBackPcnt / 100) # 1 * 10
						set loopCheck = $select(..LoopBackPcnt=100:1,loopCheck < (..LoopBackPcnt / 10):1,1:0)
						if loopCheck set urlId = ..LoopBackURL
					}
					set firstUrl = 1
					hang ..ScriptPause
				}
				set ..NextInvoke($zh+delay,session) = $listbuild(urlId,firstUrl)
			}
		}
	}
}

Method RunStop(controller As %Boolean = 0) As %Boolean
{
	set stop = 0
	// Check the stop date/time
	if (..StartDate '= "")&&(..StartTime '= "")&&(..StopDate '= "")&&(..StopTime '= "") {
		set now = ($horolog * 86400) + $piece($horolog,",",2)
		set testStop = (..StopDate *86400) + ..StopTime
	    if now > testStop {
    	    set stop = 1
	    }
	}
	elseif (($horolog * 86400) + $piece($horolog,",",2)) > ..TestStop {
		// Check that we've reached the end of the set running time
		set stop = 1
	}
    else {
	    // Check the run flag
        set stop = +$get(^WebStress.RunFlag(..TestID))
        if stop set stop = stop - 1
    }
    if stop {
	    if (controller=0) {
	    	merge ^WebStress.Results.CallsD(..TestID,..RunID,..Script.Name,..Generator,..WebServer,$JOB)=^IRIS.Temp.CallsD(..TestID,..RunID,..Script.Name,..Generator,..WebServer,$JOB)
	    }
	    set ..Status.Status = 6
	    set ..Status.StatusText = "Stopping"
	    do ..Status.%Save()
    }
    quit stop
}

ClassMethod RunWait(TestID As %Integer, StartDate As %Integer, StopDate As %Integer, StartTime As %Integer, StopTime As %Integer, debug As %Boolean) As %Integer
{
	set status=0
	for  {
		// Check the run flag. 0 (zero) means wait, 1 (one) means start, 2 (two) means stop
		if $data(^WebStress.RunFlag(TestID)) {
        	set status = +$get(^WebStress.RunFlag(TestID))
            if status quit
		}
		elseif (StartDate '= "")&&(StopDate '= "")&&(StartTime '= "")&&(StopTime '= "") {
        	set now = ($horolog * 86400) + $piece($horolog,",",2)
			set start = (StartDate * 86400) + StartTime
			set end = (StopDate * 86400) + StopTime
			if now > end set status = 2 quit
           	if now > start set status = 1 quit
		}
		hang 1
	}
	quit status
}

Method CheckRecordStatus()
{
	set testRecord = 0
	set now = ($horolog * 86400) +($piece($horolog,",",2))
	if (now >= ..RecordStart)&&(now <= ..RecordStop) {
		set testRecord = 1
		if ..Status.Status < 4 {
			set ..Status.Status = 4
			set ..Status.StatusText = "Recording"
			do ..Status.%Save()
		}
	}
	elseif (now > ..RecordStop) {
		set testRecord = 0
		set ..Status.Status = 5
		set ..Status.StatusText = "Cool down"
		do ..Status.%Save()
	}
	
	quit testRecord
}

Method GetTimes()
{
	set ..RecordStart = ($horolog * 86400) + $piece($horolog,",",2) + (60 * ..WarmUpMins)
	if ..RunMins > 0 {
		set ..RecordStop = ..RecordStart + (..RunMins * 60)
		set ..TestStop = ..RecordStop + (..CoolDownMins * 60)
	}
	else {
		set ..TestStop = (..StopDate * 86400) + ..StopTime
		set ..RecordStop = ..TestStop - (..CoolDownMins * 60)
	}
}

/// This is called before a URL call is made to the server. Normally to reset any parameters
Method PreExecute(ByRef objUrl As %WebStress.Scripts.URLS, ByRef params As %String) [ ProcedureBlock = 0 ]
{
	if objUrl.PreExecute '= "" set ^imb("pre",objUrl.%Id())=objUrl.PreExecute
	xecute objUrl.PreExecute
}

/// Called after a URL call has been made to the server
Method PostExecute(ByRef objUrl As %WebStress.Scripts.URLS) [ ProcedureBlock = 0 ]
{
	xecute objUrl.PostExecute
}

/// Called after each call to check the page error status
Method ErrorCheck(ByRef errorStatus As %Integer = 0, errorText As %String = "", ByRef objUrl As %WebStress.Scripts.URLS, session As %Integer, urlId As %Integer) [ ProcedureBlock = 0 ]
{
	try {
		set errorCheck = "set errorStatus = "_..Script.ErrorCheck_"(.errorText)"
		xecute ("set errorStatus = "_..Script.ErrorCheck_"(.errorText)")
	}
	catch {
		do ..SetError(session,urlId,objUrl,1,$zerror)
	}
}

/// This is called at the start of the full script
Method PreRunCode(ByRef objUrl As %WebStress.Scripts.URLS, session As %Integer, urlId As %Integer) [ ProcedureBlock = 0 ]
{
	try {
		xecute ("set run = "_..Script.PreRunCode)
		if 'run {
			set ..Status.Status = 9
			set ..Status.StatusText = "Pre-script stop"
			do ..Status.%Save()
			halt
		}
	}
	catch {
		do ..SetError(session,urlId,objUrl,1,$zerror)
	}
}

/// This is called at the end of the full script
Method PostRunCode() [ ProcedureBlock = 0 ]
{
	try {
		xecute ("set run = "_..Script.PostRunCode)
		if 'run {
			set ..Status.Status = 10
			set ..Status.StatusText = "Post-script stop"
			do ..Status.%Save()
			halt
		}
	}
	catch {
		do ..SetError(session,urlId,objUrl,1,$zerror)
	}
}

Method SetError(session As %Integer, urlId As %Integer, objUrl As %WebStress.Scripts.URLS, errorStatus As %Integer, errorText As %String)
{
	set objError=##class(%WebStress.Errors).%New()
	set objError.RunID = ..RunID
	set objError.TestID = ..TestID
	set objError.ScriptID = ..ScriptID
	set objError.Process = $Job
	set objError.Session = session
	set objError.SystemIdentifier = ##class(%WebStress.Control).SystemID()
	set objError.ErrorNumber = $increment(^WebStress.ErrorsD(..TestID,..RunID,..ScriptID,objError.SystemIdentifier))
	set objError.ErrorStatus = errorStatus
	set objError.ErrorText = errorText
	set objError.URLNumber = urlId
	if $IsObject(objUrl) {
		set objError.URLVerb = objUrl.Verb
		set objError.URLPath = objUrl.Path
	}
	do objError.%Save()
}

Storage Default
{
<Data name="NoDelay">
<Attribute>NoDelay</Attribute>
<Structure>subnode</Structure>
<Subscript>"NoDelay"</Subscript>
</Data>
<Data name="NoResults">
<Attribute>NoResults</Attribute>
<Structure>subnode</Structure>
<Subscript>"NoResults"</Subscript>
</Data>
<Data name="PlaybackDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Run</Value>
</Value>
<Value name="3">
<Value>TestID</Value>
</Value>
<Value name="4">
<Value>Test</Value>
</Value>
<Value name="5">
<Value>ScriptID</Value>
</Value>
<Value name="6">
<Value>Script</Value>
</Value>
<Value name="7">
<Value>WebServer</Value>
</Value>
<Value name="8">
<Value>WebServerPort</Value>
</Value>
<Value name="9">
<Value>Sessions</Value>
</Value>
<Value name="10">
<Value>StartDate</Value>
</Value>
<Value name="11">
<Value>StopDate</Value>
</Value>
<Value name="12">
<Value>StartTime</Value>
</Value>
<Value name="13">
<Value>StopTime</Value>
</Value>
<Value name="14">
<Value>RunMins</Value>
</Value>
<Value name="15">
<Value>WarmUpMins</Value>
</Value>
<Value name="16">
<Value>CoolDownMins</Value>
</Value>
<Value name="17">
<Value>ScriptPause</Value>
</Value>
<Value name="18">
<Value>LoopBackURL</Value>
</Value>
<Value name="19">
<Value>LoopBackPcnt</Value>
</Value>
<Value name="20">
<Value>TimeDiff</Value>
</Value>
<Value name="21">
<Value>debug</Value>
</Value>
<Value name="22">
<Value>SavePage</Value>
</Value>
<Value name="23">
<Value>SavePageDir</Value>
</Value>
<Value name="24">
<Value>Status</Value>
</Value>
<Value name="25">
<Value>StatusText</Value>
</Value>
<Value name="26">
<Value>HttpSessions</Value>
</Value>
<Value name="27">
<Value>RecordStart</Value>
</Value>
<Value name="28">
<Value>RecordStop</Value>
</Value>
<Value name="29">
<Value>TestStop</Value>
</Value>
<Value name="30">
<Value>ProxyAddress</Value>
</Value>
<Value name="31">
<Value>ProxyPort</Value>
</Value>
<Value name="32">
<Value>SSLConfiguration</Value>
</Value>
</Data>
<DataLocation>^WebStress.PlaybackD</DataLocation>
<DefaultData>PlaybackDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.PlaybackD</IdLocation>
<IndexLocation>^WebStress.PlaybackI</IndexLocation>
<StreamLocation>^WebStress.PlaybackS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
