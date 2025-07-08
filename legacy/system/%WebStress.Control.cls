/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

/// Incremental number associated with each test
Property RunNumber As %Integer;

/// The test identifier
Property Test As %String(TRUNCATE = 1);

/// The status code associated with the test
Property Status As %String(DISPLAYLIST = ",Unknown,Preparing,Waiting,Warmup,Recording,Cooldown,Stopping,Stopped,Error", TRUNCATE = 1, VALUELIST = ",0,1,2,3,4,5,6,7,8") [ InitialExpression = 0 ];

/// A description of the last error
Property ErrorText As %String(MAXLEN = 255, TRUNCATE = 1);

/// An array containing the progress of the test preparation
Property Progress As array Of %WebStress.Control.Progress;

/// An array constructed when the encryption flag is being changed on the application servers
Property AppServerStatus As array Of %WebStress.Control.AppServers;

/// An array showing the number of processes started on each generator
Property ProcessStatus As array Of %WebStress.Control.Processes;

/// Shows the control status on each generator
Property GeneratorStatus As array Of %WebStress.Control.GeneratorStatus;

/// The list of jobs running on a generator
Property Jobs As array Of %String(TRUNCATE = 1);

/// The job number of the monitor process
Property MonitorJob As %String(TRUNCATE = 1);

/// A string uniquely identifying this system (hostname_namespace_manager's directory)
Property SystemIdentifier As %String(TRUNCATE = 1);

/// The time difference (secs) between the starting machine and the other generators
Property TimeDiff As %Integer;

Property TimeStart As %TimeStamp;

Property TimeStop As %TimeStamp;

/// A description of this run
Property RunDescription As %String(TRUNCATE = 1);

Index Test On (Test, SystemIdentifier) [ IdKey, PrimaryKey, Unique ];

ClassMethod StartPrepare(testID As %String, runDescription As %String) As %String
{
	job ClassMethod^%apiOBJ("%WebStress.Control","Prepare",testID,runDescription)
	quit $zchild
}

ClassMethod Prepare(testID As %String, runDescription As %String) As %Status
{
	// All the references to the %WebStress.Control class are set manually.
	// This is because more than one process will be attempting to update properties of the class at the same time
	set $ztrap="Trap"
	
	do {
		// Ensure that no one else is trying to do this
		lock +^WebStress.ControlD(testID,..SystemID()):0 set status=$test 
		if 'status set $li(^WebStress.ControlD(testID,..SystemID()),2)="This process is already being run" quit
		// Delete this control record
		kill ^WebStress.ControlD(testID,..SystemID())
		// Set run status in the global
		set $li(^WebStress.ControlD(testID,..SystemID()),7)=1
		// Put the user input run description in
		set $li(^WebStress.ControlD(testID,..SystemID()),11)=runDescription
		// We will keep an index of the generator names/systemID so clear it down first
		kill ^WebStress.GenSys(testID)
		// Check that all the generators are in the required state
		set status = ..CheckGeneratorRunStatus(testID) if 'status quit
		// Get the get unique run number across all the machines
		set nextRunNumber = ..GetMaxRunNumber(testID)+1
		// Put the run number in
		set $li(^WebStress.ControlD(testID,..SystemID()),5) = nextRunNumber
		// Set the encryption flag on the application servers if required
		if ##class(%WebStress.Tests).%OpenId(testID,0).SetAppEncrypt=1 set status = ..SetAppEncrypt(testID,1) if 'status quit
		// Start processes
		set status = ..GeneratorProcs(testID,nextRunNumber,runDescription)
		// Now check that all the generators are in the correct state
		for i=1:1:10 {
			set status = ..CheckGeneratorIsRunning(testID)
			if status quit
			hang 3
		}
		if 'status {
			do ..SetError(testID,"","Problem with generator preparation")
		}
		else {
			// Put the status into the global
			set $li(^WebStress.ControlD(testID,..SystemID()),7)=2
		}

		lock -^WebStress.ControlD(testID,..SystemID())
		if $lg(^WebStress.ControlD(testID,..SystemID()),2)="" {
			do ..SetProgress(testID,"Done")
			set status=1
		}
		else {
			set $li(^WebStress.ControlD(testID,..SystemID()),7)=8,status=0
		}
	} while 0
	lock -^WebStress.ControlD(testID,..SystemID())
	
	quit status
	
Trap
	set $ztrap=""
	do ..SetError(testID,$zerror,"Error in preparation: ")
	quit 0
}

ClassMethod CheckGeneratorRunStatus(testID) As %Status
{
	set systemID = ..SystemID()
	set status = ..GetGeneratorDetails(testID,.generators)
	if status {
		set generator=""
		for  {
			set generator=$order(generators(generator),1,location)
			if generator="" quit
			kill commsClient
			set commsClient=##class(%WebStress.Comms.Client).%New(generator,location)	// IMB 2013-06-28 Security fix
			if $IsObject(commsClient) {
				do ..SetProgress(testID,"Checking run status on generator: "_generator_" at location: "_location)
				set objStatus = commsClient.CheckGeneratorRunStatus(testID,systemID)
				if $IsObject(objStatus) {
					if objStatus.Running set status=0
					set objC = ##class(%WebStress.Control).%New()
					do ..SetProgress(testID,"Generator: "_generator_" is "_$select(objStatus.Running:"running",1:"not running")_". Current status: "_objC.StatusLogicalToDisplay(objStatus.Status))
					kill objC
					set ^WebStress.GenSys(testID,objStatus.GenSystemID) = generator
				}
				if 'status {
					set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Problem with generator: "_generator
				}
			}
			else {
				set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Could not authenticate web service on generator: "_generator
				do ..SetProgress(testID,"Could not authenticate web service on generator: "_generator)
				set status = $system.Status.Error(5001,"Could not authenticate web service on generator: "_generator)
				quit
			}
		}
	}
	quit status
}

ClassMethod CheckGeneratorIsRunning(testID As %String) As %Status
{
	set systemID = ..SystemID()
	set status = ..GetGeneratorDetails(testID,.generators)
	if status {
		set generator=""
		for  {
			set generator=$order(generators(generator),1,location)
			if generator="" quit
			kill commsClient
			set commsClient=##class(%WebStress.Comms.Client).%New(generator,location)	// IMB 2013-06-28 Security fix
			if $IsObject(commsClient) {
				do ..SetProgress(testID,"Checking generator is running: "_generator)
				set objStatus = commsClient.CheckGeneratorIsRunning(testID,systemID)
				if $IsObject(objStatus) {
					if 'objStatus.Running set status=0
					set objC = ##class(%WebStress.Control).%New()
					do ..SetProgress(testID,"Generator: "_generator_" is "_$select(objStatus.Running:"running",1:"not running")_". Current status: "_objC.StatusLogicalToDisplay(objStatus.Status))
					kill objC
				}
				if 'status {
					set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Problem with generator: "_generator
				}
			}
			else {
				set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Could not authenticate web service on generator: "_generator
				do ..SetProgress(testID,"Could not authenticate web service on generator: "_generator)
				set status = $system.Status.Error(5001,"Could not authenticate web service on generator: "_generator)
				quit
			}
		}
	}
	quit status
}

ClassMethod GetGeneratorDetails(testID As %String, ByRef generators As %String) As %Status
{
	set status=$$$OK
	set objTest = ##class(%WebStress.Tests).%OpenId(testID,0)
	if $IsObject(objTest) {
		set paramCount = objTest.Parameters.Count()
		for param=1:1:paramCount {
			set objParam = objTest.Parameters.GetAt(param)
			if $IsObject(objParam) {
				set objGenerator=objParam.Generator
				if $IsObject(objGenerator) {
					set name=objGenerator.Name
					set addr=objGenerator.Address
					set dir=objGenerator.WebStressDir
					set port=objGenerator.DirectPort
					if $extract(dir,1)'="/" set dir="/"_dir
					if $extract(dir,$length(dir))'="/" set dir=dir_"/"
					set location="http://"_addr
					if port'="" set location=location_":"_port
					set location=location_dir
					set location=location_"%WebStress.Comms.Server.cls"
					set generators(name)=location
				}
				else {
					set status=%objlasterror
					do ..SetError(testID,status,"Test #"_testID_", Parameter #"_param_" (Generator) : ")
					quit
				}
			}
			else {
				set status=%objlasterror
				do ..SetError(testID,status,"Test #"_testID_", Parameter #"_param_" : ")
				quit
			}
		}
	}
	else {
		set status=%objlasterror
		do ..SetError(testID,status,"Test #"_testID_" : ")
	}
	quit status
}

ClassMethod GeneratorRunStatus(testID As %String, senderID As %String) As %WebStress.Control.GeneratorStatus
{
	set obj = ##class(%WebStress.Control.GeneratorStatus).%New()
	set systemID = ..SystemID()
	set obj.GenSystemID=systemID
	if systemID = senderID {
		set obj.Running=0
	}
	else {
		lock +^WebStress.ControlD(testID,..SystemID()):0 set obj.Running='$test
		lock -^WebStress.ControlD(testID,..SystemID())
	}
	set obj.Status=+$lg($get(^WebStress.ControlD(testID,..SystemID())),7)
	//set obj.Status=obj.Running
	quit obj
}

ClassMethod GeneratorIsRunning(testID As %String, senderID As %String) As %WebStress.Control.GeneratorStatus
{
	set obj = ##class(%WebStress.Control.GeneratorStatus).%New()
	set systemID = ..SystemID()
	if systemID = senderID {
		set obj.Running=1
	}
	else {
		lock +^WebStress.ControlD(testID,..SystemID()):0 set obj.Running='$test
		lock -^WebStress.ControlD(testID,..SystemID())
	}
	set obj.Status=obj.Running
	quit obj
}

ClassMethod SetAppEncrypt(testID As %String, value As %Integer) As %Status
{
	set status=$$$OK
	&sql(declare APP cursor for
		select Name,WebSrvAddress,WebSrvPort,URL,CacheUserName,CachePassword,SecurityCheck
		into :name,:addr,:port,:url,:user,:pass,:check
		from %WebStress_Machines.ApplicationServers)
	&sql(open APP)
  if SQLCODE<0 {
		s status=$$$ERROR($$$SQLError,SQLCODE,$g(%msg))
  } else {
	for  {
		&sql(fetch APP)
		if SQLCODE'=0 quit
		if $extract(url,1)'="/" set url="/"_url
		if $extract(url,$length(url))'="/" set url=url_"/"
		set session=##class(%Net.HttpRequest).%New()
		set session.Server = addr
		if port'="" set session.Port=port
		do session.SetParam("status",value)
		set url=url_"%25WebStress.Portal.Encrypt.cls"
		if check {
			set url=url_"?IRISUsername="_user_"&IRISPassword="_pass
		}
		set status=session.Get(url)
	}
	if SQLCODE<0 s status=$$$ADDSC(status,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
	&sql(close APP)
	if SQLCODE<0 s status=$$$ADDSC(status,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
  }
	if $g(name)'="" {
		do ..SetProgress(testID,"Setting NoEncrypt Flag on webserver: "_name_":"_status)
	}
	quit status
}

ClassMethod GetAppServerStats(testID As %Integer, runID As %Integer, ByRef appServerStats As %String)
{
	&sql(declare APPSTATS cursor for
		select Name,WebSrvAddress,WebSrvPort,URL
		into :name,:addr,:port,:url
		from %WebStress_Machines.ApplicationServers)
	&sql(open APPSTATS)
	Quit:SQLCODE<0
	for  {
		&sql(fetch APPSTATS)
		if SQLCODE'=0 quit
		if $extract(url,1)'="/" set url="/"_url
		if $extract(url,$length(url))'="/" set url=url_"/"
		set session=##class(%Net.HttpRequest).%New()
		set session.Server = addr
		if port'="" set session.Port=port
		set cookie=""
		for  {
			set cookie=$order(^WebStress.Playback(..SystemID(),$job,"cookies",name,cookie),1,cookieData)
			if cookie="" quit
			set cookieName=$li(cookieData,1), cookieDomain=$li(cookieData,2),cookiePath=$li(cookieData,3)
			set cookieValue=$li(cookieData,4), cookieExpires=$li(cookieData,5), cookieSecure=+$li(cookieData,6)
			do session.InsertCookie(cookieName, cookieValue, cookiePath, cookieDomain, cookieExpires, cookieSecure) 
		}
		set status=session.Get(url_"%WebStress.Portal.AppStats.cls")
		if status {
			// Get cookies so that we don't keep racking up new CSP sessions/licenses each time
			kill ^WebStress.Playback(..SystemID(),$job,"cookies",name)
			set cookieCount = session.GetFullCookieList(.cookies)
			for cookie=1:1:cookieCount set ^WebStress.Playback(..SystemID(),$job,"cookies",name,cookie)=cookies(cookie)
			set response=session.HttpResponse.Data.Read(20000)
			set response=$zcvt(response,"l")
			set stats=$piece($piece(response,"<body>",2),"</body>",1)
			set stats=$zstrip(stats,"*CW")
			set len=$length(stats,":")
			for i=1:2:len {
				set var=$piece(stats,":",i),value=$piece(stats,":",i+1)
				if var'="" set appServerStats("now",name,var)=value
			}
			if $data(appServerStats("last",name)) {
				set line=$i(^WebStress.Results.AppStatsD(testID,runID,name))
				set elapsed = appServerStats("now",name,"timenow")-appServerStats("last",name,"timenow")
				set CSPSessions = appServerStats("now",name,"sessioncount")
				set GlobRefs = $justify(appServerStats("now",name,"gref")-appServerStats("last",name,"gref")/elapsed,0,0)
				set GlobalSetsKills = $justify(appServerStats("now",name,"gsk")-appServerStats("last",name,"gsk")/elapsed,0,0)
				set LUAvailable = appServerStats("now",name,"luavailable")
				set LUConsumed = appServerStats("now",name,"luconsumed")
				set PhysicalReads = $justify(appServerStats("now",name,"pread")-appServerStats("last",name,"pread")/elapsed,0,0)
				set PhysicalWrites = $justify(appServerStats("now",name,"pwri")-appServerStats("last",name,"pwri")/elapsed,0,0)
				set RSeizes = $justify($piece(appServerStats("now",name,"rseizes"),",",1)-$piece(appServerStats("last",name,"rseizes"),",",1)/elapsed,0,0)
				set RSeizesRatio = ""
				set temp1 = $piece(appServerStats("now",name,"rseizes"),",",1)-$piece(appServerStats("last",name,"rseizes"),",",1)
				set temp3 = $piece(appServerStats("now",name,"rseizes"),",",3)-$piece(appServerStats("last",name,"rseizes"),",",3)
				if temp1 set RSeizesRatio = $justify(temp3/temp1*100,0,2)
				set temp1=appServerStats("now",name,"rlas")-appServerStats("last",name,"rlas")
				set temp2=appServerStats("now",name,"gref")-appServerStats("last",name,"gref")
				set temp3=appServerStats("now",name,"pread")-appServerStats("last",name,"pread") if temp3=0 set temp3=1
				set Ratio = $justify((temp1+temp2)/temp3,0,0)
				set Seizes = $justify($piece(appServerStats("now",name,"seizes"),",",1)-$piece(appServerStats("last",name,"seizes"),",",1)/elapsed,0,0)
				set SeizesRatio = ""
				set temp1 = $piece(appServerStats("now",name,"seizes"),",",1)-$piece(appServerStats("last",name,"seizes"),",",1)
				set temp3 = $piece(appServerStats("now",name,"seizes"),",",3)-$piece(appServerStats("last",name,"seizes"),",",3)
				if temp1 set SeizesRatio = $justify(temp3/temp1*100,0,2)
				set StatsDate=+$horolog
				set StatsTime=$piece($horolog,",",2)
				set WDQSize = appServerStats("now",name,"wdqsize") //appServerStats("last",name,"wdqsize")_"/"_appServerStats("now",name,"wdqsize")
				set WDWake = appServerStats("now",name,"wdwake") //appServerStats("last",name,"wdwake")_"/"_appServerStats("now",name,"wdwake")
				set data=$lb("",CSPSessions,GlobRefs,GlobalSetsKills,LUAvailable,LUConsumed,PhysicalReads,PhysicalWrites,RSeizes,RSeizesRatio,Ratio,Seizes,SeizesRatio,StatsDate,StatsTime,WDQSize,WDWake)
				set ^WebStress.Results.AppStatsD(testID,runID,name,line)=data
			}
			kill appServerStats("last",name)
			merge appServerStats("last",name)=appServerStats("now",name)
			kill appServerStats("now",name)
		}
	}
	&sql(close APPSTATS)
}

ClassMethod SetError(testID As %String, status As %String, message As %String)
{
	set error=status
	set $ztrap="NotSystemError"
	do DecomposeStatus^%apiOBJ(status,.err)
	set error=err(1)
NotSystemError
	set $ztrap=""
	set $li(^WebStress.ControlD(testID,..SystemID()),2) = message_error
	set $li(^WebStress.ControlD(testID,..SystemID()),7)=6
}

ClassMethod SetProgress(testID As %String, message As %String)
{
	set progCount = $i(^WebStress.ControlD(testID,..SystemID(),"Progress"))
	set ^WebStress.ControlD(testID,..SystemID(),"Progress",progCount)=$lb(message,$zdatetime($horolog,3))
}

ClassMethod GeneratorProcs(testID As %String, runNumber As %Integer, runDescription As %String) As %Status
{
	set status=0
	set systemID = ..SystemID()
	set runningHere = 0
	set objTest = ##class(%WebStress.Tests).%OpenId(testID)
	if $IsObject(objTest) {
		set key=""
		for  {
			set objParams=objTest.Parameters.GetNext(.key)
			if key="" quit
			set generator = objParams.Generator.Name
			set addr = objParams.Generator.Address
			set port = objParams.Generator.DirectPort
			set dir = objParams.Generator.WebStressDir
			if $extract(dir,1)'="/" set dir="/"_dir
			if $extract(dir,$length(dir))'="/" set dir=dir_"/"
			set location="http://"_addr
			if port'="" set location=location_":"_port
			set location=location_dir
			set location=location_"%WebStress.Comms.Server.cls"
			set generator(generator)=location
			kill commsClient
			set commsClient = ##class(%WebStress.Comms.Client).%New(generator,location)	// IMB 2013-06-28 Security fix
			if $IsObject(commsClient) {
				do ..SetProgress(testID,"Starting Processes on generator: "_generator_" for script: "_objParams.Script.Name)
				if commsClient.GetGenID() = systemID set runningHere = 1
				set senderTime=$horolog*86400+$piece($horolog,",",2)
				set obj = commsClient.StartProcs(testID,runNumber,key,systemID,senderTime)
				if '$IsObject(obj) {
					do ..SetError(testID,"","Error starting processes on generator: "_generator)
					set status=0
					quit
				}
				if systemID '= obj.SystemIdentifier {
					;if obj.ErrorText'="" {
					;	do ..SetError(testID,"",obj.ErrorText_": "_generator)
					;	quit
					;}
					;else {
						set procStatus=obj.ProcessStatus.GetAt(1)
						set procCount = $i(^WebStress.ControlD(testID,..SystemID(),"ProcessStatus"))
						set procData=$lb(procStatus.Generator,procStatus.RequestedProcesses,procStatus.Script,procStatus.StartedProcesses,procStatus.WebServer,procStatus.WebServerPort)
						set ^WebStress.ControlD(testID,..SystemID(),"ProcessStatus",procCount)=procData
					;}
				}
				kill obj
			}
			else {
				set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Could not authenticate web service on generator: "_generator
				do ..SetProgress(testID,"Could not authenticate web service on generator: "_generator)
				set status = $system.Status.Error(5001,"Could not authenticate web service on generator: "_generator)
				quit
			}			
		}
		//todo - runninghere anomaly?
		// Now start the monitors
		set generator=""
		for  {
			set generator=$order(generator(generator),1,location)
			if generator="" quit
			kill commsClient
			set commsClient = ##class(%WebStress.Comms.Client).%New(generator,location)	// IMB 2013-06-28 Security fix
			if $IsObject(commsClient) {
				do ..SetProgress(testID,"Starting Monitor on generator: "_generator)
				set status = commsClient.StartMonitor(runNumber,testID,systemID,runDescription)
				if (status)&&('runningHere) {
					do ..SetProgress(testID,"Starting Monitor on this machine: "_systemID)
					do ..StartMonitor(runNumber,testID,systemID,runDescription)
				}
			}
			else {
				set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Could not authenticate web service on generator: "_generator
				do ..SetProgress(testID,"Could not authenticate web service on generator: "_generator)
				set status = $system.Status.Error(5001,"Could not authenticate web service on generator: "_generator)
				quit
			}
		}
	}
	quit status
}

/// This prepares all the background processes ready for the test
ClassMethod StartProcs(testID As %String, runNumber As %Integer, param As %Integer, senderID As %String, senderTime As %Integer) As %WebStress.Control
{
	do {
		set systemID = ..SystemID()
		if systemID '= senderID {
			set $li(^WebStress.ControlD(testID,..SystemID()),5) = runNumber
			set now=$horolog*86400+$piece($horolog,",",2)
			set timeDiff=now-senderTime
			set $li(^WebStress.ControlD(testID,..SystemID()),6)=timeDiff
		}
		else {
			set timeDiff=0, $li(^WebStress.ControlD(testID,..SystemID()),6)=timeDiff
		}
		set $li(^WebStress.ControlD(testID,..SystemID()),7)=0
		set objTest = ##class(%WebStress.Tests).%OpenId(testID)
		if $IsObject(objTest) {
			set startDate = objTest.StartDate
			set stopDate = objTest.StopDate
			set startTime = objTest.StartTime
			set stopTime = objTest.StopTime
			set runMins = objTest.RunMinutes
			set warmUp = objTest.WarmUpMinutes
			set coolDown = objTest.CoolDownMinutes
			set savepage = objTest.SavePageSource
			set savepagedir = objTest.SavePageSourceDir
			set proxyAddress = objTest.ProxyAddress
			set proxyPort = objTest.ProxyPort
			set SSLConfig = objTest.SSLConfig
			set paramsCount = objTest.Parameters.Count()
		
			set objParams = objTest.Parameters.GetAt(param)
			set scriptID = objParams.Script.%Id()
			set generator = objParams.Generator.Name
			set webserver = objParams.WebServer.Address
			set webserverport = objParams.WebServer.Port
			set processes = objParams.Processes
			set sessions = objParams.Sessions
			set scriptPause = objParams.ScriptPause
			set loopBackUrl = objParams.LoopBackNumber
			set loopBackPcnt = objParams.LoopBackPercent
				
			set objRespProc=##class(%WebStress.Control.Processes).%New()
			
			Set objRespProc.Script=##class(%WebStress.Scripts).%OpenId(scriptID,0).Name
			set objRespProc.Generator=objParams.Generator.Name
			set objRespProc.WebServer=objParams.WebServer.Name
			set objRespProc.WebServerPort=webserverport
			set objRespProc.RequestedProcesses=processes

			kill ^WebStress.RunFlag(testID)
			if (+startDate=0)||(+startTime=0) set ^WebStress.RunFlag(testID)=0
							
			set procCount=0
			for proc=1:1:processes {
				job ##class(%WebStress.Playback).Run(runNumber,testID,scriptID,generator,webserver,webserverport,sessions,startDate,stopDate,startTime,stopTime,runMins,warmUp,coolDown,scriptPause,loopBackUrl,loopBackPcnt,timeDiff,0,0,savepage,savepagedir,proxyAddress,proxyPort,SSLConfig)
				if $zchild'="" {
					set procCount=procCount+1
					set ^WebStress.ControlD(testID,..SystemID(),"Jobs",$zchild)=scriptID
				}
			}
				
			set objRespProc.StartedProcesses=procCount
			set procCount=$i(^WebStress.ControlD(testID,..SystemID(),"ProcessStatus"))
			set procData=$lb(objRespProc.Generator,objRespProc.RequestedProcesses,objRespProc.Script,objRespProc.StartedProcesses,objRespProc.WebServer,objRespProc.WebServerPort)
			set ^WebStress.ControlD(testID,..SystemID(),"ProcessStatus",procCount)=procData
			for tries=1:1:10 {
				set return = ..RunningCount(testID)
				if return quit
				hang 1 // Try for upto 10 attempts (10 seconds) for the jobs to initiate properly and lock their entries
			}
		}
		else {
			set status=%objlasterror
			do ..SetError(testID,status,"Test #"_testID_" : ")
		}
	} while 0
	quit ##class(%WebStress.Control).%OpenId(testID_"||"_..SystemID(),0)
}

ClassMethod StartMonitor(runNumber As %Integer, testID As %String, senderID As %String, runDescription As %String) As %String
{
	job ClassMethod^%apiOBJ("%WebStress.Control","Monitor",runNumber,testID,senderID,runDescription)
	set $li(^WebStress.ControlD(testID,..SystemID()),4) = $zchild
	quit $zchild
}

/// This is the background process that will monitor the progress of the run
ClassMethod Monitor(runNumber As %Integer, testID As %String, senderID As %String, runDescription As %String)
{
	set $ztrap="Trap"
	lock +^WebStress.ControlD(testID,..SystemID()):60 if '$test set $li(^WebStress.ControlD(testID,..SystemID()),2)="Monitor could not lock control global" quit

	set systemID = ..SystemID()
	// Set the flag to show if we are on the controller on not
	set controller = 0 if senderID = systemID set controller = 1

	// Start the build of the General results marker
	set objGeneral = ##class(%WebStress.Results.General).%New()
	set objGeneral.RunID = runNumber
	set objGeneral.TestID = testID
	set objGeneral.RunDescription = runDescription
	set objGeneral.PrepareTime = $zdatetime($horolog,3)
	
	// Set status of the monitor process
	set $li(^WebStress.ControlD(testID,..SystemID()),7)=2  // Waiting
	set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",1)=$zdt($horolog,3)
	set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",7)=runDescription
	
	set timeDiff = $lg(^WebStress.ControlD(testID,..SystemID()),6)
	
	set objTest = ##class(%WebStress.Tests).%OpenId(testID,0)
	if $IsObject(objTest) {
		set startDate = objTest.StartDate
		set stopDate = objTest.StopDate
		set startTime = objTest.StartTime
		set stopTime = objTest.StopTime
		set runMins = objTest.RunMinutes
		set warmUp = objTest.WarmUpMinutes
		set coolDown = objTest.CoolDownMinutes
		set CollectAppServerStats=objTest.CollectAppServerStats
		set CollectAppServerPeriod=objTest.CollectAppServerPeriod
		set lastAppServerPeriod = 0
		if (startDate'="")&&(startTime'="") {
			set thisTime=startDate*86400+startTime
			set correctedTime=thisTime-timeDiff
			set startDate=correctedTime\86400,startTime=correctedTime#86400
			set thisTime=stopDate*86400+stopTime
			set correctedTime=thisTime-timeDiff
			set stopDate=correctedTime\86400,stopTime=correctedTime#86400
		}
		//set status=$$RunWait^%WebStress.Playback(testID,startDate,startTime,0)
		// New playback code
		do ..SetProgress(testID,"Waiting for start signal")
		set objPlayback = ##class(%WebStress.Playback).%New()
		set status = ##class(%WebStress.Playback).RunWait(testID,startDate,stopDate,startTime,stopTime,0)
		if status=1 {
			set objGeneral.WarmUpTime = $zdatetime($horolog,3)
			set $li(^WebStress.ControlD(testID,..SystemID()),7)=3  //  Warmup			
			set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",2)=$zdt($horolog,3)
			do ..SetProgress(testID,"Warming up")
			// New playback code
			
			set objPlayback.TestID = testID
			set objPlayback.WarmUpMins = warmUp
			set objPlayback.CoolDownMins = coolDown
			set objPlayback.RunMins = runMins
			set objPlayback.StopDate = stopDate
			set objPlayback.StopTime = stopTime
			set objPlayback.ProcessID = $job
			// Need a status entry for this process as well
			set objStatusJob = ##class(%WebStress.Playback.Status).%New()
			set objStatusJob.TestID = testID
			set objStatusJob.RunID = runNumber
			set objStatusJob.ProcessID = $job
			set objStatusJob.Status = 11
			set objStatusJob.StatusText = "Monitoring"
			set objStatusJob.SystemID = ..SystemID()
			do objStatusJob.%Save()
			set objPlayback.Status = objStatusJob
			
			do objPlayback.GetTimes()
			set recordStart = objPlayback.RecordStart
			set recordStop = objPlayback.RecordStop
			set testStop = objPlayback.TestStop
			
			set (Recording,Recorded,stop) = 0
			do {
				// New playback code
				if Recorded < 2 set Recording = objPlayback.CheckRecordStatus()
				if Recording {
					if 'Recorded {
						set Recorded=1
						set objGeneral.RecordTime = $zdatetime($horolog,3)
						set $li(^WebStress.ControlD(testID,..SystemID()),7)=4  //  Recording
						set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",3)=$zdt($horolog,3)
						do ..SetProgress(testID,"Recording")
					}
					set now=$horolog*86400+$piece($horolog,",",2)
					set runTime=now-recordStart
					
					// Get a list of all the scripts being run
					kill scripts
					set key = ""
					for  {
						set key=$order(^WebStress.ControlD(testID,..SystemID(),"Jobs",key),1,scriptID)
						if key="" quit
						lock +^WebStress.Run(..SystemID(),key):0 if '$Test {
							if scriptID'="" set scripts(scriptID)=""
						}
						lock -^WebStress.Run(..SystemID(),key)
					}
					// Now initialise the iterations start time for the scripts
					set scriptID=""
					for  {
						set scriptID=$order(scripts(scriptID))
						if scriptID="" quit
						set ^WebStress.Iterations(testID,runNumber,..SystemID(),scriptID,"S")=runTime
					}
					
					// App server stats.
					if (controller = 1)&&(CollectAppServerStats) {
						set collect = 1
						if lastAppServerPeriod {
							if (lastAppServerPeriod + CollectAppServerPeriod)>($piece($horolog,",",1)*86400+$piece($horolog,",",2)) set collect = 0
						}
						if collect {
							do ..GetAppServerStats(testID,runNumber,.appServerStats)
							set lastAppServerPeriod=($piece($horolog,",",1)*86400)+$piece($horolog,",",2)
						}
						// If we are the controller then build the Results.Iterations from the separate generator's iterations
						if controller do ..BuildResultIterations(testID,runNumber)
					}
				}
				else {
					if Recorded=1 {
						set Recorded=2
						set objGeneral.CoolDownTime = $zdatetime($horolog,3)
						set $li(^WebStress.ControlD(testID,..SystemID()),7)=5  //  Cooldown
						set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",4)=$zdt($horolog,3)
						do ..SetProgress(testID,"Cool down")
					}
				}
				//if $$RunStop^%WebStress.Playback(testID,testStop) {
				// New playback code
				if objPlayback.RunStop(controller) {
					do ..SetProgress(testID,"Generators stopped")
					set objGeneral.StoppingTime = $zdatetime($horolog,3)
					set $li(^WebStress.ControlD(testID,..SystemID()),7)=6  //  Stopping
					set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",5)=$zdt($horolog,3)
					do ..SetProgress(testID,"Stopping")
					while ..RunningCount(testID) {
						hang 1
					}
					set $li(^WebStress.ControlD(testID,..SystemID()),7)=7  //  Stopped
					set objGeneral.StoppedTime = $zdatetime($horolog,3)
					set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",6)=$zdt($horolog,3)
					do ..SetProgress(testID,"Stopped")
					set stop=1
					set objPlayback.Status.Status = 7
					set objPlayback.Status.StatusText = "Stopped"
					do objPlayback.Status.%Save()
					quit
				}
				hang 1
			} while 'stop
		}
		else {
			set $li(^WebStress.ControlD(testID,..SystemID()),7)=6  //  Stopping
			set objGeneral.StoppingTime = $zdatetime($horolog,3)
			set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",5)=$zdt($horolog,3)
			do ..SetProgress(testID,"Stopping")
			set objPlayback.Status.Status = 6
			set objPlayback.Status.StatusText = "Stopping"
			do objPlayback.Status.%Save()
			while ..RunningCount(testID) {
				hang 1
			}
			set objGeneral.StoppedTime = $zdatetime($horolog,3)
			set $li(^WebStress.ControlD(testID,..SystemID()),7)=7  //  Stopped
			set $piece(^WebStress.Iterations(testID,runNumber,..SystemID()),",",6)=$zdt($horolog,3)
			do ..SetProgress(testID,"Stopped")
			set objPlayback.Status.Status = 7
			set objPlayback.Status.StatusText = "Stopped"
			do objPlayback.Status.%Save()
		}
		
		if (controller)&&(##class(%WebStress.Tests).%OpenId(testID,0).SetAppEncrypt=1) {
			// Test to see if any other tests are running and reset the encryption flag if possible
			do ..SetProgress(testID,"Checking for reset of encryption flag")
			set status = ..GetGeneratorDetails(testID,.generators)
			if status {
				set timeStop=$horolog*86400+$piece($horolog,",",2)+120
				do {
					set generator="",running=0
					for  {
						set generator=$order(generators(generator),1,location)
						if generator="" quit
						kill commsClient
						set commsClient = ##class(%WebStress.Comms.Client).%New(generator,location)	// IMB 2013-06-28 Security fix
						if $IsObject(commsClient) {
							lock -^WebStress.ControlD(testID,..SystemID())
							set running = commsClient.AnyTestsRunning()
							lock +^WebStress.ControlD(testID,..SystemID())
							if running quit
						}
						else {
							set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Could not authenticate web service on generator: "_generator
							do ..SetProgress(testID,"Could not authenticate web service on generator: "_generator)
							set status = $system.Status.Error(5001,"Could not authenticate web service on generator: "_generator)
							quit
						}
					}
					if (status)&&(running) {
						hang 10
					}
					else {
						set status = ..SetAppEncrypt(testID,0)
						do ..SetProgress(testID,"Encryption flag reset")
					}
					set timeNow=$horolog*86400+$piece($horolog,",",2)
				} while (timeNow<timeStop)&&(running)
			}
		}
		if (controller) {
			do ..SetProgress(testID,"Building statistics")
			set $li(^WebStress.ControlD(testID,..SystemID()),9)=$zdt($zts,1,1,2)
			do ..SetProgress(testID,"Building iterations statistics")
			do ..BuildResultIterations(testID,runNumber,runDescription)
			do ..SetProgress(testID,"Building summary statistics")
			do ##class(%WebStress.Results.Summary).Summary(testID,runNumber)
			do ..SetProgress(testID,"Building page summary statistics")
			do ##class(%WebStress.Results.PageSummary).Summary(testID,runNumber)
			do ..SetProgress(testID,"Complete")
		}
		
		// Save the general results marker
		set objGeneral.Generator = $get(^WebStress.GenSys(4,..SystemID())," ")
		do objGeneral.%Save()
	}
	else {
		set $li(^WebStress.ControlD(testID,..SystemID()),2)="Monitor could not open Test object #"_testID
	}
	quit
Trap
	set $li(^WebStress.ControlD(testID,..SystemID()),2)=$zerror
}

ClassMethod RunningCount(testID) As %Integer
{
	set count = 0
	set key = ""
	for  {
		set key=$order(^WebStress.ControlD(testID,..SystemID(),"Jobs",key))
		if key="" quit
		lock +^WebStress.Run(..SystemID(),key):0 if '$Test set count = count + 1
		lock -^WebStress.Run(..SystemID(),key)
	}
	quit count
}

ClassMethod GetMaxRunNumber(testID As %String) As %Integer
{
	quit +$order(^WebStress.Iterations(testID,""),-1)
}

ClassMethod TestStart(testID As %String) As %Status
{
	set status = ..GetGeneratorDetails(testID,.generators)
	if status {
		set generator=""
		for  {
			set generator=$order(generators(generator),1,location)
			if generator="" quit
			kill commsClient
			set commsClient = ##class(%WebStress.Comms.Client).%New(generator,location)	// IMB 2013-06-28 Security fix
			if $IsObject(commsClient) {
				do ..SetProgress(testID,"Setting start signal on generator: "_generator)
				set $li(^WebStress.ControlD(testID,..SystemID()),8)=$zdt($zts,1,1,2)
				set status = commsClient.TestStart(testID)
			}
			else {
				set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Could not authenticate web service on generator: "_generator
				do ..SetProgress(testID,"Could not authenticate web service on generator: "_generator)
				set status = $system.Status.Error(5001,"Could not authenticate web service on generator: "_generator)
				quit
			}
		}
	}
	quit status
}

ClassMethod TestStop(testID As %String) As %Status
{
	set status = ..GetGeneratorDetails(testID,.generators)
	if status {
		set generator=""
		for  {
			set generator=$order(generators(generator),1,location)
			if generator="" quit
			kill commsClient
			set commsClient = ##class(%WebStress.Comms.Client).%New(generator,location)	// IMB 2013-06-28 Security fix
			if $IsObject(commsClient) {
				do ..SetProgress(testID,"Setting stop signal on generator: "_generator)
				set $li(^WebStress.ControlD(testID,..SystemID()),9)=$zdt($zts,1,1,2)
				set status = commsClient.TestStop(testID)
			}
			else {
				set $li(^WebStress.ControlD(testID,..SystemID()),2) = "Could not authenticate web service on generator: "_generator
				do ..SetProgress(testID,"Could not authenticate web service on generator: "_generator)
				set status = $system.Status.Error(5001,"Could not authenticate web service on generator: "_generator)
				quit
			}
		}
	}
	quit status
}

ClassMethod SystemID() As %String
{
	// set thisMachine=$system.Server.HostName() // Doesn't work on 2007..->onwards !!!!
	set thisMachine = $piece($zu(131,1),":",1)
	set thisNamespace=$namespace
	set thisMgr=$system.Util.ManagerDirectory()
	quit thisMachine_"_"_thisNamespace_"_"_thisMgr
}

ClassMethod AnyTestsRunning() As %Integer
{
	lock +^WebStress.ControlD:0 set running = '$test
	lock -^WebStress.ControlD
	quit running
}

ClassMethod GetErrors(testID As %String, runID As %Integer, scriptID As %String) As %GlobalCharacterStream
{
	&sql(declare ERRORS cursor for
		select Process,Session,ErrorNumber,ErrorStatus,ErrorText,URLNumber,URLVerb,URLPath
		into :proc,:sess,:numb,:stat,:text,:url,:urlverb,:urlpath
		from %WebStress.Errors
		where TestID = :testID
		and RunID = :runID
		and ScriptID = :scriptID
		order by ErrorNumber
		)
	&sql(open ERRORS)
	set return = ##class(%GlobalCharacterStream).%New()
	set html="<table class=""TableBlock"" cellpadding=""5"" cellspacing=""5"">"
	do return.Write(html)
	set html="<tr><td class=""FormTitle"" colspan=""8"">Errors</td></tr>"
	do return.Write(html)
	set html="<tr><th>Number</th><th>Process</th><th>Session</th><th>Status</th><th>Text</th><th>URL#</th><th>Verb</th><th>Path</th></tr>"
	do return.Write(html)
	for  {
		&sql(FETCH ERRORS)
		if SQLCODE'=0 quit
		set stat=$select(stat=1:"Warning",1:"Fatal")
		set html="<tr><td class=""FormPromptLeft"">"_numb_"</td><td class=""FormPromptLeft"">"_proc_"</td><td class=""FormPromptLeft"">"_sess_"</td><td class=""RunStatus"_stat_""">"_stat_"</td><td class=""FormPromptLeft"">"_text_"</td><td class=""FormPromptLeft"">"_url_"</td><td class=""FormPromptLeft"">"_urlverb_"</td><td class=""FormPromptLeft"">"_urlpath_"</td></tr>"
		do return.Write(html)
	}
	set html="</table>"
	do return.Write(html)
	&sql(close ERRORS)
	quit return
}

ClassMethod BuildResultIterations(TestID As %Integer, RunID As %Integer, desc As %String = "")
{
	set systemID = ""
	for  {
		set systemID = $order(^WebStress.Iterations(TestID,RunID,systemID))
		if systemID = "" quit
		set tstart=$lg(^WebStress.ControlD(TestID,systemID),8)
		set tstop=$lg(^WebStress.ControlD(TestID,systemID),9)
		set generator = $get(^WebStress.GenSys(TestID,systemID))
		if generator '= "" {
			set scriptID=""
			for  {
				set scriptID=$order(^WebStress.Iterations(TestID,RunID,systemID,scriptID))
				if scriptID="" quit
				set iterations=+$get(^WebStress.Iterations(TestID,RunID,systemID,scriptID,"I"))
				set seconds=+$get(^WebStress.Iterations(TestID,RunID,systemID,scriptID,"S"))
				set script = ##class(%WebStress.Scripts).%OpenId(scriptID,0).Name
				&sql(select ID into :genID from %WebStress_Machines.Generators where Name = :generator)
				&sql(select Processes,Sessions,Target into :procs,:sess,:target from %WebStress_Tests.Parameters where Test = :TestID and Script = :scriptID and Generator = :genID)
				set classData=$lb("",iterations,seconds,procs,sess,target,TestID,tstart,tstop,desc)
				set ^WebStress.Results.IterationsD(TestID,RunID,script,generator)=classData
			}
		}
	}
}

ClassMethod SavePage(saveDir As %String, scriptID As %Integer, iteration As %Integer, url As %String, response As %Stream.GlobalCharacter)
{
	try {
		do response.Rewind()
		set pageDir = ##class(%Library.File).NormalizeDirectory(saveDir)
		set thisDir = pageDir_scriptID
		set thisDir = ##class(%Library.File).NormalizeDirectory(thisDir)
		if '##class(%Library.File).DirectoryExists(thisDir) {
			set status = ##class(%Library.File).CreateDirectoryChain(thisDir)
			if 'status quit  // Create error?
		}
		set thisDir = thisDir_iteration
		set thisDir = ##class(%Library.File).NormalizeDirectory(thisDir)
		if '##class(%Library.File).DirectoryExists(thisDir) {
			set status = ##class(%Library.File).CreateDirectoryChain(thisDir)
			if 'status quit  // Create error?
		}
		set len = $length(url,"/")
		set urlFileName = $piece(url,"/",len)
		if urlFileName '= "" {
			set fileName = thisDir_urlFileName
			set objFile = ##class(%Library.File).%New(fileName)
			do objFile.Open("WNS")
			// Get the first 'lump' and detect HTTP headers
			set first = response.Read(3000)
			set first = $piece(first,$char(13,10,13,10),2,999)
			do objFile.Write(first)
			for  {
				set data = response.Read()
				do objFile.Write(data)
				if response.AtEnd quit
			}
			do objFile.%Save()
			kill objFile
			do response.Rewind()
		}
	}
	catch {
		s ^imb=$zerror
	}
}

ClassMethod Clean() As %Status
{
	kill ^WebStress.ControlD
	kill ^WebStress.RunFlag
	kill ^WebStress.Interations
	kill ^WebStress.ErrorsD
	kill ^WebStress.Playback.StatusD
	kill ^WebStress.Record
	quit $$$OK
}

Storage Default
{
<Data name="AppServerStatus">
<Attribute>AppServerStatus</Attribute>
<Structure>subnode</Structure>
<Subscript>"AppServerStatus"</Subscript>
</Data>
<Data name="ControlDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ErrorText</Value>
</Value>
<Value name="4">
<Value>MonitorJob</Value>
</Value>
<Value name="5">
<Value>RunNumber</Value>
</Value>
<Value name="6">
<Value>TimeDiff</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>TimeStart</Value>
</Value>
<Value name="9">
<Value>TimeStop</Value>
</Value>
<Value name="11">
<Value>RunDescription</Value>
</Value>
</Data>
<Data name="GeneratorStatus">
<Attribute>GeneratorStatus</Attribute>
<Structure>subnode</Structure>
<Subscript>"GeneratorStatus"</Subscript>
</Data>
<Data name="Jobs">
<Attribute>Jobs</Attribute>
<Structure>subnode</Structure>
<Subscript>"Jobs"</Subscript>
</Data>
<Data name="ProcessStatus">
<Attribute>ProcessStatus</Attribute>
<Structure>subnode</Structure>
<Subscript>"ProcessStatus"</Subscript>
</Data>
<Data name="Progress">
<Attribute>Progress</Attribute>
<Structure>subnode</Structure>
<Subscript>"Progress"</Subscript>
</Data>
<DataLocation>^WebStress.ControlD</DataLocation>
<DefaultData>ControlDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.ControlD</IdLocation>
<IndexLocation>^WebStress.ControlI</IndexLocation>
<StreamLocation>^WebStress.ControlS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
