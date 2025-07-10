/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %syPidtab)

Class Ens.Job Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Name of this job instance
Property Name As %String;

/// The number of times OnTask() has run.
Property TaskPass As %Integer;

Parameter FGLAUNCHWAIT = 30;

ClassMethod Launch(pConfigName As %String = "", pForeground As %Boolean, pDisableErrorTraps As %Boolean, pInterimJob As %String = "", Output pChildJob As %String, Output pListeningTelnetPort As %String = "") As %Status
{
#define WinConsoleSession $System.Util.GetSessionId(0)
	Set $ZT="Trap", tSC=$$$OK
	If ""=pInterimJob { ; test caller-supplied value for legacy compatibility
		Set pInterimJob="X"_$R(1000000)
		Set tSC=..Register(pConfigName,0,pForeground,pInterimJob,"",$$$eJobStatusStarting)
		Quit:$$$ISERR(tSC) tSC
	}
	Set pChildJob=""
	Set tCurrentNS=$namespace, tEventName=""
	Do {
		If pForeground {
			For tIndex=1:1 Quit:'$D($$$EnsRuntime("ForegroundJobsArgument",tIndex))
			If $G($$$EnsJobLocal("EnsPortal.StartStopFrame")) {
				// Do it the client-mediated way
				Set tEventName="EnsFGJobStart"_tIndex
				$$$sysTRACE("Starting terminal-wait job for config item '"_pConfigName_"', EventName: "_tEventName)
				Do $System.Event.Create(tEventName)
				Do $ZU(5,"%SYS")
				Job StartEnsembleJob^STU(tCurrentNS,pConfigName,pDisableErrorTraps,0,pForeground,pInterimJob,tEventName)::5  Set tJobFailed='$test
				Do $ZU(5,tCurrentNS)
				If tJobFailed {
					Set tSC=$$$EnsError($$$EnsErrJobFailed,pConfigName)
				} Else {
					Set pChildJob=$ZChild
					Set tResult=$System.Event.WaitMsg(tEventName,..#FGLAUNCHWAIT)
					If '$List(tResult,1) {
						Set tSC=$$$EnsError($$$EnsErrJobFailed,pConfigName_":"_tEventName)
					} Else {
						Set pListeningTelnetPort=$List(tResult,2)
						If pListeningTelnetPort<0 {
							Set tSC=$$$EnsError($$$EnsErrJobFailed,pConfigName_":"_tEventName_":"_pListeningTelnetPort)
						//} ElseIf pListeningTelnetPort>0 {
						}
					}
				}
				Do $System.Event.Delete(tEventName)
			} ElseIf $$$isWINDOWS || ($ZV["Mac OS X") {
				// Do it the local way if on right OS, not launched from EnsPortal.StartStopFrame
				Set $$$EnsRuntime("ForegroundJobsArgument",tIndex) = $lb(pConfigName,pDisableErrorTraps,pForeground,pInterimJob)
				#dim tCmdLineForTrace = ""
				#dim tCmd = ""
				#dim tCmdArgs = 0
				If $ZV["Mac OS X" {
					#; for Mac OS X, use AppleScript with Terminal.app
					Set tCmdLineForTrace="osascript -e 'tell application ""Terminal""' -e 'activate' -e 'do script with command """
						_$SYSTEM.Util.BinaryDirectory()_"iris session "_$P($ZU(86),"*",2)_" -U "_tCurrentNS
						_" Start"_tIndex_"^EnsJob ; exit""' -e 'tell the front window' -e 'set custom title to """_pConfigName_"""'"
						_" -e 'end tell' -e ' end tell'"

					Set tCmd = "osascript"
					Set tCmdArgs($I(tCmdArgs))="-e"
					Set tCmdArgs($I(tCmdArgs))="tell application ""Terminal"""
					Set tCmdArgs($I(tCmdArgs))="-e"
					Set tCmdArgs($I(tCmdArgs))="activate"
					Set tCmdArgs($I(tCmdArgs))="-e"
					Set tCmdArgs($I(tCmdArgs))="do script with command """_$SYSTEM.Util.BinaryDirectory()_"iris session "_$P($ZU(86),"*",2)_" -U "_tCurrentNS_" Start"_tIndex_"^EnsJob ; exit"""
					Set tCmdArgs($I(tCmdArgs))="-e"
					Set tCmdArgs($I(tCmdArgs))="tell the front window"
					Set tCmdArgs($I(tCmdArgs))="-e"
					Set tCmdArgs($I(tCmdArgs))="set custom title to """_pConfigName_""""
					Set tCmdArgs($I(tCmdArgs))="-e"
					Set tCmdArgs($I(tCmdArgs))="end tell"
					Set tCmdArgs($I(tCmdArgs))="-e"
					Set tCmdArgs($I(tCmdArgs))="end tell"

				} Else {
					// On Windows, start a IRISTERM via iris.exe
					Set tCmdLineForTrace=""""_$SYSTEM.Util.BinaryDirectory()_"iris"" terminal"
					// RJW938 adds /Title in Cache' 5.1 -- note, it doesn't work if it's quoted
					Set tCmdLineForTrace=tCmdLineForTrace_" /Title="_$TR(tCurrentNS_"::"_pConfigName," &^","___")
					Set tCmdLineForTrace=tCmdLineForTrace_" "_$P($ZU(86),"*",2)_" Start"_tIndex_"^^EnsJob "_tCurrentNS

					Set tCmd = $SYSTEM.Util.BinaryDirectory()_"iris"
					Set tCmdArgs($I(tCmdArgs))="terminal"
					Set tCmdArgs($I(tCmdArgs))="/Title="_$TR(tCurrentNS_"::"_pConfigName," &^","___")
					Set tCmdArgs($I(tCmdArgs))=$P($ZU(86),"*",2)
					#; don't use ^^ for $zf(-100)
					Set tCmdArgs($I(tCmdArgs))="Start"_tIndex_"^EnsJob"
					Set tCmdArgs($I(tCmdArgs))=tCurrentNS
				}
				If $$$isWINDOWS && ($$$WinConsoleSession'=0) {
					$$$LOGWARNING("Not launched from Portal; starting job in foreground mode on non-default desktop: "_pConfigName_". Use the Windows 'Interactive Services Detection Service' to facilitate desktop switching")
				} Else {
					$$$sysTRACE("Starting terminal for config item '"_pConfigName_"', Command: "_tCmdLineForTrace)
				}
				If $ZF(-100,"",tCmd,.tCmdArgs) {}
				Set pChildJob="fg"
			} Else {
				$$$LOGWARNING("Can't start job in foreground when not launched from portal and not on Windows or OS X; starting in background: "_pConfigName)
			}
		}
		If ""=pChildJob && $$$ISOK(tSC) {
			#; Do it the non-foreground normal way if foreground wasn't appropriate
			Do $ZU(5,"%SYS")
			Job StartEnsembleJob^STU(tCurrentNS,pConfigName,pDisableErrorTraps,0,0,pInterimJob)::5  Set tJobFailed='$test
			Do $ZU(5,tCurrentNS)
			Set:'tJobFailed pChildJob=$zchild
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT=""
	Do:$D(tCurrentNS) $ZU(5,tCurrentNS)
	Set tSC=$$$EnsSystemError
	Goto Exit
}

/// Scan within a configured range for an available port on which the telnet device can listen for a foreground terminal window to connect
ClassMethod OpenTelnetDevice(pEventName, Output pDevice, Output pPort) [ Internal ]
{
	#; pDevice and pPort are accepted by reference.
	#; The device is returned so that it can be closed by the caller at the appropriate moment.
	#; The port is returned so that it can be passed to the background job.

	#; Attempt to open a listening TCP port within the specified range
	Set pDevice="", pPort="", tJob=$P($Job,":")
	Set tDevice="|TCP|"_tJob, tIsOpen=0
	Set tPortRangeStart=$G(^Ens.Config("FGTelnetRange","start"),63300)
	Set tPortRangeEnd=$G(^Ens.Config("FGTelnetRange","end"),63499)
	For tPort=tPortRangeStart:1:tPortRangeEnd {
		Continue:$D($$$EnsRuntime("FGTelnetPort",tPort))
		try {
			Open tDevice:(/PORT=tPort:/MAKETELNET):0  If $Test Set tIsOpen=1 Quit
		} catch {
		}
		Quit:tIsOpen
	}
	If 'tIsOpen { $$$LOGWARNING("Found no available port in range "_tPortRangeStart_"-"_tPortRangeEnd_" to listen for telnet connection to foreground job "_tJob_"; continuing as background job") }
	Else { Set pDevice=tDevice, pPort=tPort }
	Quit tIsOpen
}

Parameter FGTELNETWAIT = 30;

/// Start a background Job in the specified namespace.
ClassMethod Start(pConfigName As %String, pDisableErrorTraps As %Boolean, pIsTempJob As %Boolean = 0, pForeground As %Boolean = 0, pInterimJob As %String = "", pEventName As %String = "") As %Status [ ProcedureBlock = 1 ]
{
	Set $ZT="Trap", tSC=$$$OK, tJob=$Job, tNS=$Namespace, (tPort,tTcpDev)=""
	Do {
		Set tRunning=(""'=$G($$$EnsRuntime("Name")))
		If pForeground&&(""'=pEventName) {
			#; Foreground telnet mode - signal back to Launch() with port number
			If 'tRunning {
				Do $System.Event.Signal(pEventName,-1) ; production is not running
			} ElseIf '..OpenTelnetDevice(pEventName,.tTcpDev,.tPort) {
				Do $System.Event.Signal(pEventName,0) ; found no available port - continue in background
			} Else {
				Set tIPAddr = ""
				#; Get method for determining IP address, should be one of "hostname","ip" or "custom"
				#; If "custom", then we try to get the value from ^Ens.Debug("ForegroundIP")
				Set tIPType = $zconvert($get(^Ens.Debug("ForegroundIPType"),"hostname"),"L")
				If (tIPType = "custom") {
					Set tIPAddr = $get(^Ens.Debug("ForegroundIP"))
				}
				ElseIf (tIPType = "ip") { // use IP address of this host as returned from getaddrinfo()
					Set tIPAddr = $piece($ZU(54,13,$ZU(54,0)),",",1)
				}
				#; If type is hostname or "" or an IP address hasn't been found, fall back on getting the fully qualified domain name as before
				If (tIPType = "hostname") || (tIPType = "") || (tIPAddr = "") {
					Set tIPAddr = $piece($ZU(54,13,$ZU(54,0)),",",2)
				}
				#; Add port to IP Address
				Set tIPAddr = tIPAddr_"["_tPort_"]"
				#; Add port to to-do list array for client to connect to
				Set $$$EnsRuntime("FGTelnetPort",tIPAddr)=""

				#; Signal to Launch() with the newly found listening port number
				Do $System.Event.Signal(pEventName,tPort)

				#; Wait for the client to connect in on our listening port
				Use tTcpDev Read tDummy:..#FGTELNETWAIT Set tNewConnection=$Test Close tTcpDev

				#; Remove our port from the to-do list
				Kill $$$EnsRuntime("FGTelnetPort",tIPAddr)

				If 'tNewConnection {
					$$$LOGWARNING("Client telnet failed to connect for foreground "_pConfigName_" job "_tJob_" on port "_tPort_" within "_..#FGTELNETWAIT_" seconds; continuing as background job")
				} Else {
					#; Now switch this job to become the telnet session
					#; tTelDev becomes principal device
					Set tTelDev="|TNT|"_tPort
					Use tTelDev 
					Do $ZU(132)

					#; Recognize breaks
					Do $ZU(128,2,1)

					$$$sysTRACE("Attached telnet device for foreground mode on port "_tPort)
				}
			}
		}
		#; if the production is not running, just quit
		Quit:'tRunning

		Set $$$EnsJobLocal("JobKey")=$ZStrip($Job,"*E'N"), $$$EnsJobLocal("ConfigName")=pConfigName

		#; Initialize local mirror config vars
		Merge $$$EnsJobLocal("Config")=^Ens.Config
		Merge $$$EnsJobLocal("Debug")=^Ens.Debug
		Set $$$EnsConfig("%ModIndexFlag")=$$$EnsMirrorIndex
		Do ##class(Ens.Util.Trace).SetTraceOptimizer(pConfigName)

		Set tClassName=$$$ConfigOnTaskClassName(pConfigName)
		$$$sysTRACE("Starting job for config item '"_pConfigName_"', classname '"_tClassName_"'")

		If pDisableErrorTraps Zbreak /ERRORTRAP:OFF

		$$$sysTRACE("Calling Register()")
		Set tSC = ..Register(pConfigName,''pIsTempJob,pForeground,tJob,pInterimJob,$$$eJobStatusRegistered) Quit:$$$ISERR(tSC)

		Set tInstance=$classmethod(tClassName,"%New",pConfigName)  If '$IsObject(tInstance) { Set tSC=%objlasterror  Quit }
		$$$LOGINFO("ConfigItem '"_pConfigName_"' "_$S(pConfigName=tClassName:"",1:"("_tClassName_") ")_"started in job "_tJob)
		Do ..SetStatus($$$eJobStatusRunning)

		$$$sysTRACE("Entering OnTask() loop")
		For {
			If ..ShouldTerminate() $$$sysTRACE("ShouldTerminate() returned TRUE") Quit
			#; Refresh local mirror config vars if needed
			Set nMirror=$$$EnsMirrorIndex  If nMirror'=$G($$$EnsConfig("%ModIndexFlag")) {
				$$$catTRACE("mirror","Starting update #"_nMirror_" of local mirror config variables")
				Kill $$$EnsJobLocal("Config") Merge $$$EnsJobLocal("Config")=^Ens.Config
				Kill $$$EnsJobLocal("Debug")  Merge $$$EnsJobLocal("Debug")=^Ens.Debug
				Set $$$EnsConfig("%ModIndexFlag")=nMirror
				Do ##class(Ens.Util.Trace).SetTraceOptimizer()
				$$$catTRACE("mirror","Completed update #"_nMirror_" of local mirror config variables")
			}
			Set tInstance.%QuitTask=0, tSC=tInstance.OnTask()  Quit:$$$ISERR(tSC)||tInstance.%QuitTask
		} ; end OnTask() loop
	} While 0
	ZN tNS
	Set $ZT="Trap2"
Exit
	Set tTimeUTC=$$$timeUTC
	Set tTxt="Terminating Job "_tJob_" / '"_pConfigName_"' with Status = "_$$$StatusDisplayString(tSC)_", %QuitTask="_$S($$$IsdefObject(tInstance):tInstance.%QuitTask,1:"")
	If $$$ISOK(tSC) {
		$$$sysTRACE(tTxt)
	} Else {
		$$$LOGWARNING(tTxt)
		If $D($$$EnsRuntime) {
			#; merge to ghost job, clean up, update status and monitor globals (avoid collision with re-used job id)
			Set tGhost="Z"_tJob_"_"_$R(10000)
			Merge $$$EnsJobStatus($$$SystemName,tGhost)=$$$EnsJobStatus($$$SystemName,tJob)
			Merge $$$EnsJobMonitorNode($$$SystemName_":"_tGhost)=$$$EnsJobMonitorNode($$$SystemName_":"_tJob)
			$$$SetHostMonitor(pConfigName,$$$eMonitorStatus,"Error")
			Set $$$EnsJobStatus($$$SystemName,tGhost,$$$eJobStatus)=$$$eJobStatusTerminated
			Set $$$EnsJobStatus($$$SystemName,tGhost,$$$eJobIsDead)=1
			$$$SetJobMonitor(pConfigName,$$$SystemName_":"_tGhost,$$$eMonitorStatus,"Terminated")
			Set $$$EnsJobStatus($$$SystemName,tGhost,$$$eJobDetail)=$$$StatusDisplayString(tSC)
		}
	}
	Kill tInstance
	Do ..UnRegister(pConfigName,tJob)
	Do ##Class(Ens.Queue).DeleteAllQueuesForJob()
	Quit tSC
Trap
	Set $ZT="Trap2"
	ZN tNS
	Set tSC=$$$EnsSystemError
	Kill:""'=tPort $$$EnsRuntime("FGTelnetPort",tPort)
	Goto Exit
Trap2
	Set $ZT="",tSC=$$$EnsSystemError
	Quit tSC
}

/// Compare globals with local copy and increment the 'modified' counter if changed
ClassMethod CheckMirrorGlobals() [ Internal ]
{
	Set nMirror=$G($$$EnsConfig("%ModIndexFlag"))
	If $$$EnsMirrorIndex=nMirror {
		#; Counter not updated; check it ourselves
		Kill $$$EnsConfig("%ModIndexFlag")
		Set tChange=$$compareArrays^EnsUtil($Name($$$EnsJobLocal("Debug")),$Name(^Ens.Debug))
		Set:""=tChange tChange=")"_$$compareArrays^EnsUtil($Name($$$EnsJobLocal("Config")),$Name(^Ens.Config))
		If ")"'=tChange {
			Kill $$$EnsJobLocal("Config") Merge $$$EnsJobLocal("Config")=^Ens.Config
			Kill $$$EnsJobLocal("Debug")  Merge $$$EnsJobLocal("Debug")=^Ens.Debug
			Set nMirrorNew=$$$EnsMirrorIndexInc  Set $$$EnsConfig("%ModIndexFlag")=nMirrorNew
			$$$LOGINFO("Completed local refresh #"_nMirrorNew_" of mirror config variables; 1st change found at '"_tChange_"'")
			Do ##class(Ens.Util.Trace).SetTraceOptimizer()
		} Else {
			Set $$$EnsConfig("%ModIndexFlag")=nMirror
		}
	}
}

ClassMethod Register(pConfigName As %String, pIsTempJob As %Integer, pForeground As %Boolean, pJob As %String, pInterimJob As %String, pJobStatus As %String) As %Status
{
	Set:""=pJobStatus pJobStatus=$$$eJobStatusRegistered
	Quit:$D($$$EnsJobStatus($$$SystemName,pJob)) $$$EnsError($$$EnsErrJobRegistryNotClean,pJob)
	if $e(pJob)'="X" $$$sysTRACE("Registering ConfigName '"_pConfigName_"' in job "_pJob)
	Lock +$$$EnsJobStatus($$$SystemName):300 Else  Quit $$$EnsError($$$EnsErrCanNotAcquireJobRootLock,300)
	Set $$$EnsJobStatus($$$SystemName,pJob,$$$eJobStatus)=pJobStatus
	Set $$$EnsJobStatus($$$SystemName,pJob,$$$eJobStartConfigName)=pConfigName
	Set $$$EnsJobStatus($$$SystemName,pJob,$$$eJobForeground)=pForeground
	Set $$$EnsJobStatus($$$SystemName,pJob,$$$eJobIsTempJob)=pIsTempJob
	Set $$$EnsJobStatus($$$SystemName,pJob,$$$eJobRegTime)=$$$timeUTC
	If pInterimJob'="" {
		Kill $$$EnsJobStatus($$$SystemName,pInterimJob)
		$$$KillJobMonitor($$$SystemName_":"_pInterimJob)
	}
	Lock -$$$EnsJobStatus($$$SystemName)
	If $e(pJob)'="X" {
		Lock:"Xternal"'=pInterimJob +$$$EnsJobLock($$$SystemName,pJob)
	
		// set up monitor global for this job
		// host-wide
		Set tTimeUTC=$$$timeUTC
		$$$RegisterHostMonitorJob(pConfigName,$$$SystemName_":"_pJob)
		$$$SetHostMonitor(pConfigName,$$$eMonitorStatus,"OK")

		// job-specific
		$$$SetJobMonitor(pConfigName,$$$SystemName_":"_pJob,$$$eMonitorStatus,"OK")
	}
	Quit $$$OK
}

ClassMethod SetStatus(pJobStatus As %Integer, pDetail As %String)
{
	Lock +$$$EnsJobStatus($$$SystemName,$Job):2  Else  Quit
	#; this prevents status-only entries from getting into this global
	If $data($$$EnsJobStatus($$$SystemName,$Job)) {
		Set $$$EnsJobStatus($$$SystemName,$Job,$$$eJobStatus)=pJobStatus
		If $g(pDetail)'="" Set $$$EnsJobStatus($$$SystemName,$Job,$$$eJobDetail)=pDetail
	}
	Lock -$$$EnsJobStatus($$$SystemName,$Job)
	Quit
}

ClassMethod UnRegister(pConfigName As %String, pJob)
{
	Lock +$$$EnsJobStatus($$$SystemName,pJob):10 Else  $$$LOGWARNING("fail to acquire job lock to unregister in job '"_pJob_"'")

	// clear monitor info for this job
	$$$KillHostMonitor(pConfigName,$$$eMonitorJob,$$$SystemName_":"_pJob)
	$$$KillJobMonitor($$$SystemName_":"_pJob)
	Kill $$$EnsJobStatus($$$SystemName,pJob)
	If $D(^IRIS.Temp.EnsTCPJobs(pJob),tParent)  Kill ^IRIS.Temp.EnsTCPJobs(pJob)  If $G(tParent)&&$G(^IRIS.Temp.EnsTCPJobs(tParent,"children")) If $I(^IRIS.Temp.EnsTCPJobs(tParent,"children"),-1) ; decrement parent's TCP connection job count if any

	Lock -$$$EnsJobStatus($$$SystemName,pJob)
	Lock:pJob=$Job -$$$EnsJobLock($$$SystemName,pJob)
	Quit
}

ClassMethod ShouldBeQuiescent() As %Boolean
{
	Lock +$$$EnsJobRequest($$$SystemName,$Job):2 Else  Quit 0
	Set tShouldQuiescent=($$$eJobRequestQuiescent=$g($$$EnsJobRequest($$$SystemName,$Job),$g($$$EnsJobRequest($$$SystemName),$g($$$EnsJobRequest))))
	Lock -$$$EnsJobRequest($$$SystemName,$Job)
	Quit tShouldQuiescent
}

ClassMethod ShouldTerminate() As %Boolean
{
	Lock +$$$EnsJobRequest($$$SystemName,$Job):2 Else  Quit 0
	Set tShouldTerminate=$g($$$EnsJobRequest($$$SystemName,$Job),$g($$$EnsJobRequest($$$SystemName),$g($$$EnsJobRequest)))=$$$eJobRequestTerminate
	Lock -$$$EnsJobRequest($$$SystemName,$Job)
	Quit tShouldTerminate
}

ClassMethod ShouldAbort() As %Boolean
{
	Lock +$$$EnsJobRequest($$$SystemName,$Job):2 Else  Quit 0
	Set tShouldAbort=$g($$$EnsJobRequest($$$SystemName,$Job))=$$$eJobRequestAbort
	Kill:tShouldAbort $$$EnsJobRequest($$$SystemName,$Job)
	Lock -$$$EnsJobRequest($$$SystemName,$Job)
	Quit tShouldAbort
}

ClassMethod ShouldSuspend() As %Boolean
{
	Lock +$$$EnsJobRequest($$$SystemName,$Job):2 Else  Quit 0
	Set tShouldSuspend=$g($$$EnsJobRequest($$$SystemName,$Job))=$$$eJobRequestSuspend
	Kill:tShouldSuspend $$$EnsJobRequest($$$SystemName,$Job)
	Lock -$$$EnsJobRequest($$$SystemName,$Job)
	Quit tShouldSuspend
}

/// Stop one job
ClassMethod Stop(pJob As %String, pTimeout As %Numeric = 10, pForce As %Boolean = 0) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, tLocked=0
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_Jobs:WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation) 
	}
	Do {
		Set tConfigName=$G($$$EnsJobStatus($$$SystemName,pJob,$$$eJobStartConfigName))

		$$$LOGINFO("Stopping job '"_pJob_"' ("_tConfigName_")")
		If $G($$$EnsJobStatus($$$SystemName,pJob,$$$eJobIsDead)) {
			If $d($$$EnsActiveMessage($$$SystemName_":"_pJob),tId) {
				Set tSC1=..RecoverActiveMessage(tId,tConfigName,0)
				If $$$ISERR(tSC1) $$$LOGSTATUS(tSC1)
				Kill $$$EnsActiveMessage($$$SystemName_":"_pJob)
			}
			Kill $$$EnsJobStatus($$$SystemName,pJob)
		}

		Lock +$$$EnsJobRequest($$$SystemName,pJob):2 Else  Set tSC=$$$EnsError($$$EnsErrCanNotAcquireJobLock,pJob,2) Quit
		Set $$$EnsJobRequest($$$SystemName,pJob)=$$$eJobRequestTerminate
		Lock -$$$EnsJobRequest($$$SystemName,pJob)
		Set tSC = ##class(Ens.Queue).SignalAllJobs(pJob) Quit:$$$ISERR(tSC)
		If pTimeout=-1 {
			Lock +$$$EnsJobLock($$$SystemName,pJob)  Set tTimedOut=0
		} Else {
			Lock +$$$EnsJobLock($$$SystemName,pJob):pTimeout  Set tTimedOut='$Test
		}
		Lock -$$$EnsJobLock($$$SystemName,pJob)
		Kill $$$EnsJobRequest($$$SystemName,pJob)
		If tTimedOut,'pForce Set tSC=$$$EnsError($$$EnsErrJobNotStopped,pJob,pTimeout)
		If tTimedOut,pForce {
			$$$LOGWARNING("forcibly stopping job '"_pJob_"' ("_tConfigName_")")
			#; Prevent other jobs starting with the same PID from setting the globals before we clean them up
			Lock +$$$EnsJobStatus($$$SystemName,pJob):10
			If '$Test Set tSC=$$$EnsError($$$EnsErrJobStatusLocked,pJob,10)  Quit
			Set tLocked=1
			Do $ZU(4,pJob)
			#; Acquire lock to prove job has died
			Lock +$$$EnsJobLock($$$SystemName,pJob):10
			If '$Test Set tSC=$$$EnsError($$$EnsErrJobNotStopped,pJob,pTimeout_"+"_10_"+")  Lock -$$$EnsJobStatus($$$SystemName,pJob)  Quit
			Lock -$$$EnsJobLock($$$SystemName,pJob)
			If $d($$$EnsActiveMessage($$$SystemName_":"_pJob),tId) {
				Set tSC1=..RecoverActiveMessage(tId,tConfigName,0)
				If $$$ISERR(tSC1) $$$LOGSTATUS(tSC1)
				Kill $$$EnsActiveMessage($$$SystemName_":"_pJob)
			}
			If ""'=tConfigName {
				#; host-wide status
				$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Error")
				Do ..UnRegister(tConfigName,pJob)
			}
			Do ##class(Ens.Queue).DeleteAllQueuesForJob(pJob)
			Lock -$$$EnsJobStatus($$$SystemName,pJob)
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Lock:tLocked -$$$EnsJobStatus($$$SystemName,pJob)
	Goto Exit
}

/// Stop multiple jobs
/// <parameter>pJobs</parameters> needs to be a multidimenstional array, where the keys are job ID's
ClassMethod StopJobs(pJobs As %String, pTimeout As %Numeric = 10, Output pErrors As %String) As %Status
{
	Set $ZT="Trap", tSC=$$$OK
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_Jobs:WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation) 
	}

	#dim tJob As %String // Single job ID
	Do {
		#; Set the globals before signalling jobs
		Set tJob="" For { Set tJob=$Order(pJobs(tJob),1,tIsTemp)  Quit:tJob=""
			Set tConfigName = $G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName))
			$$$LOGINFO("Stopping job '"_tJob_"' ("_tConfigName_")")
		
			If $G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobIsDead)) {
				If $d($$$EnsActiveMessage($$$SystemName_":"_tJob),tId) {
					Set tSC1=..RecoverActiveMessage(tId,tConfigName(tJob),0)
					If $$$ISERR(tSC1) $$$LOGSTATUS(tSC1)
					Kill $$$EnsActiveMessage($$$SystemName_":"_tJob)
				}
				Kill $$$EnsJobStatus($$$SystemName,tJob)
			}

			Lock +$$$EnsJobRequest($$$SystemName,tJob):2 Else  Set pErrors(tJob) = $$$EnsError($$$EnsErrCanNotAcquireJobLock,tJob,2) Continue
			Set $$$EnsJobRequest($$$SystemName,tJob) = $$$eJobRequestTerminate
			Lock -$$$EnsJobRequest($$$SystemName,tJob)
		}
		
		#; Signal jobs
		#dim tSignalledQueues As %String
		Set tJob="" For { Set tJob=$Order(pJobs(tJob),1,tIsTemp)  Quit:tJob=""
			#; Skip the jobs that failed to acquire the lock
			If $D(pErrors(tJob)) Continue

			Set tSC = ##class(Ens.Queue).SignalAllJobs(tJob, .tSignalledQueues) Continue:$$$ISERR(tSC)

			#dim tTimedOut As %Boolean
			If pTimeout=-1 {
				Lock +$$$EnsJobLock($$$SystemName,tJob)  Set tTimedOut = 0
			} Else {
				Lock +$$$EnsJobLock($$$SystemName,tJob):pTimeout  Set tTimedOut = '$Test
			}
			Lock -$$$EnsJobLock($$$SystemName,tJob)
			Kill $$$EnsJobRequest($$$SystemName,tJob)

			If tTimedOut {
				Set tSC = $$$EnsError($$$EnsErrJobNotStopped,tJob,pTimeout)
				Set pErrors(tJob) = tSC
			}
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Stop all jobs
ClassMethod StopAll(pTimeout As %Integer = 10, pForce As %Boolean = 0) As %Status
{
	Set $ZT="Trap", tSC=$$$OK
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_Jobs:WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation) 
	}
	Do {
		Lock +$$$EnsJobRequest($$$SystemName):2 Else  Set tSC=$$$EnsError($$$EnsErrCanNotAcquireJobRootLock,2) Quit
		Set $$$EnsJobRequest($$$SystemName)=$$$eJobRequestTerminate
		$$$SysWebTrace($$$Text("Requesting all jobs to terminate ..."))
		Lock -$$$EnsJobRequest($$$SystemName)
		Set tSC = ##class(Ens.Queue).SignalAllJobs() Quit:$$$ISERR(tSC)
		If pTimeout=-1 {
			Lock +$$$EnsJobLock($$$SystemName)
		} Else {
			Lock +$$$EnsJobLock($$$SystemName):pTimeout
			If '$Test,'pForce {
				Set tJobList="",tJob="" For { Set tJob=$o($$$EnsJobStatus($$$SystemName,tJob))  Quit:tJob=""
					Set:"Z"'=$E(tJob)&&($$$eJobStatusVisiting'=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus))) tJobList=tJobList_","_tJob
				}
				Set:tJobList'="" tSC=$$$EnsError($$$EnsErrJobsNotStopped,$E(tJobList,2,*),pTimeout)
			}
		}
		Lock -$$$EnsJobLock($$$SystemName)
		Kill $$$EnsJobRequest($$$SystemName)
		If pForce {
			Do {
				Set tJob=$o($$$EnsJobStatus($$$SystemName,""))  Quit:tJob=""
				$$$SysWebTrace($$$FormatText($$$Text("Force shutdown of job '%1'."),tJob))
				Do:"Z"'=$E(tJob) $ZU(4, tJob)
				If $d($$$EnsActiveMessage($$$SystemName_":"_tJob),tId) {
					Set tConfigName=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName))  Set:""=tConfigName tConfigName="%Production"
					Set tSC=..RecoverActiveMessage(tId,tConfigName,0)
					Kill $$$EnsActiveMessage($$$SystemName_":"_tJob)
				}
				Kill $$$EnsJobStatus($$$SystemName,tJob)
			} While (1)
		}
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod MakeQuiescent(pTimeout As %Numeric = 10, Output pIsQuiescent As %Boolean)
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Lock +$$$EnsJobRequest($$$SystemName):2 Else  Set tSC=$$$EnsError($$$EnsErrCanNotAcquireJobRootLock,2) Quit
		Set $$$EnsJobRequest($$$SystemName)=$$$eJobRequestQuiescent
		Lock -$$$EnsJobRequest($$$SystemName)

		Set tSC = ##class(Ens.Queue).SignalAllJobs() Quit:$$$ISERR(tSC)	
		#; now wait for all the jobs to reach quiescent state
		Do $system.Event.Create("^Ens.Event.JobRequester")
		Set tJob="" For { Set tJob=$o($$$EnsJobStatus($$$SystemName,tJob))  Quit:tJob=""
			If $G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobIsDead)) Continue
			If $G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus))=$$$eJobStatusVisiting Set tVisiting(tJob)=""  Continue
			If $G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus))=$$$eJobStatusQuiescent Continue
			Set tNonQuiescent(tJob)=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus))
		}
		Set tStartTime=$zh
		Set tPrintedInitList=0
		For  {
			Do ..MarkDeadJobs()
			Set tJob="" For { Set tJob=$o(tNonQuiescent(tJob)) Quit:tJob=""
				Set tNonQuiescent(tJob)=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus))
				If '$D($$$EnsJobStatus($$$SystemName,tJob)) {
					Kill tNonQuiescent(tJob)
					if tPrintedInitList $$$SysWebTrace($$$FormatText($$$Text("Job '%1' has terminated."),tJob))
				}
				ElseIf tNonQuiescent(tJob)=$$$eJobStatusQuiescent {
					Kill tNonQuiescent(tJob)
					if tPrintedInitList $$$SysWebTrace($$$FormatText($$$Text("Job '%1' has become quiescent."),tJob))
				}
			}
			Quit:$data(tNonQuiescent)=0
			If tPrintedInitList=0,$zh-tStartTime>3 {
				Set tPrintedInitList=1
				Set tJob="" For { Set tJob=$o(tNonQuiescent(tJob))  Quit:tJob=""
					Set tConfigName=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobGuestConfigName),$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName)))
					$$$SysWebTrace($$$FormatText($$$Text("Job '%1' %2 has non-quiescent status of '%3'."),tJob,tConfigName,tNonQuiescent(tJob)))
				}
			}
			if pTimeout'=-1 {
				Set tWaitTime=pTimeout-$zh+tStartTime
				If tWaitTime<=0 quit
			}
			If $system.Event.Wait("^Ens.Event.JobRequester",1)
		}
		;
		Set pIsQuiescent=$data(tNonQuiescent)=0
		If pIsQuiescent {
			$$$SysWebTrace($$$Text("System is quiescent"))
			Set tJob="" For { Set tJob=$o(tVisiting(tJob))  Quit:tJob=""
				Set tConfigName=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobGuestConfigName),$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName)))
				$$$SysWebTrace($$$FormatText($$$Text("Skipping 'visiting' job '%1' %2 with status of '%3'."),tJob,tConfigName,$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus))))
			}
		} Else {
			$$$SysWebTrace($$$Text("System is not quiescent"))
			Set tJob="" For { Set tJob=$o($$$EnsJobStatus($$$SystemName,tJob))  Quit:tJob=""
				If $G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobIsDead)) Continue
				Set tStatus=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStatus))
				If tStatus'=$$$eJobStatusQuiescent {
					Set tConfigName=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobGuestConfigName),$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName)))
					$$$SysWebTrace($$$FormatText($$$Text("Job '%1' %2 has non-quiescent status of '%3'."),tJob,tConfigName,tStatus))
				}
			}
		}
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod MakeNotQuiescent()
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Lock +$$$EnsJobRequest($$$SystemName):2 Else  Quit
		Kill $$$EnsJobRequest($$$SystemName)
		Lock -$$$EnsJobRequest($$$SystemName)
		Do $system.Event.Delete("^Ens.Event.JobRequester")
		Set tSC = ##class(Ens.Queue).SignalAllJobs() Quit:$$$ISERR(tSC)	
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Parameter JOBSTARTWAIT = 120;

ClassMethod MarkDeadJobs()
{
	#dim ex As %Exception.AbstractException

	#; check to see if these jobs are running, if not, mark them as ghosts
	Set tJob="" For { Set tJob=$o($$$EnsJobStatus($$$SystemName,tJob))  Quit:tJob=""

		If $e(tJob)="Z" Continue

		If $e(tJob)="X" {
			s H1=$$$timeUTCH
			/*	We could encounter an UNDEFINED here since:
					Job could still be being registered in Launch()
					or since we $ordered the job was registered as Alive and the X subscripts being removed in Register()
					We want to avoid trying to lock $$$EnsJobStatus.
			*/
			Try {
				s H2=$zdatetimeH($$$EnsJobStatus($$$SystemName,tJob,$$$eJobRegTime),3)
			} Catch ex {
				If (ex.Name '= "<UNDEFINED>") Throw ex
				/*	Writing/removing $$$EnsJobStatus($$$SystemName,"X...") by other processes is
					protected by locking so if there is an underlying error it will be detected elsewhere.
					If the global is being updated as we check here then we will still check for #JOBSTARTWAIT
					later if there is a delay starting so safe to Continue.
				*/
				Continue
			}
			s diff=($p(H1,",",1)*86400+$p(H1,",",2))-($p(H2,",",1)*86400+$p(H2,",",2))
			if diff<..#JOBSTARTWAIT continue
			#; past this point the job will be marked as dead
		}

		// Job is dead in the system table
		Continue:$ZU(61,0,$ZU(67,3,tJob))=2

		#; merge to ghost job, clean up, update status and monitor globals (avoid collision with re-used job id)
		Set tConfigName=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName))
		Set tGhost="Z"_tJob_"_"_$R(10000)

		Merge $$$EnsJobStatus($$$SystemName,tGhost)=$$$EnsJobStatus($$$SystemName,tJob)
		Set $$$EnsJobStatus($$$SystemName,tGhost,$$$eJobIsDead)=1
		Merge $$$EnsJobMonitorNode($$$SystemName_":"_tGhost)=$$$EnsJobMonitorNode($$$SystemName_":"_tJob)

		If $d($$$EnsActiveMessage($$$SystemName_":"_tJob),tId) {
			$$$LOGERROR("Marking job "_tJob_" ('"_tConfigName_"'), with active message '"_tId_"', as 'dead' (under ghost id "_tGhost_")")
			Set tSC=..RecoverActiveMessage(tId,tConfigName,1)
			Kill $$$EnsActiveMessage($$$SystemName_":"_tJob)
		} Else {
			$$$LOGERROR("Marking job "_tJob_" ('"_tConfigName_"') as 'dead' (under ghost id "_tGhost_")")
		}

		If ""'=tConfigName {
			#; host-wide status
			Set tTimeUTC=$$$timeUTC
			$$$RegisterHostMonitorJob(tConfigName,$$$SystemName_":"_tGhost) ; set HostMonitor reference to the new ghost job
			$$$SetHostMonitor(tConfigName,$$$eMonitorStatus,"Error")
			#; job-specific
			$$$SetJobMonitor(tConfigName,$$$SystemName_":"_tGhost,$$$eMonitorStatus,"Dead")

			Do ..UnRegister(tConfigName,tJob)
		}
		Do ##class(Ens.Queue).DeleteAllQueuesForJob(tJob)
	}
	Quit
}

ClassMethod RecoverActiveMessage(pId As %ObjectIdentity, pName As %String, pMarkAsCrashed As %Boolean = 1) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pRequestHeader=##Class(Ens.MessageHeader).%OpenId(pId)
		If pRequestHeader=$$$NULLOREF {
			If (pName="Ens.Enterprise.MsgBankOperation") {
				If $$$ISOK(##class(Ens.Queue).EnQueueId(pId,"Ens.Enterprise.MsgBankOperation",,1)) {
					$$$LOGINFO($$$FormatText($$$Text("Active message '%1', processed in job '%2', has been restored to the queue."),pId,pName))
				} Else {
					$$$LOGERROR($$$FormatText($$$Text("Active message '%1', processed in job '%2', failed to be restored to the queue."),pId,pName))
				}
				Quit
			} Else {
				$$$LOGERROR($$$FormatText($$$Text("Active message '%1', processed in job '%2', failed to be restored to the queue because %OpenId failed."),pId,pName))
				Quit
			}
		}
		If pRequestHeader.TargetQueueName="" {
			$$$LOGERROR($$$FormatText($$$Text("Active message '%1', processed in job '%2', failed to be restored to the queue because it does not have the TargetQueueName."),pId,pName))
			Quit
		}
		If ##class(Ens.Queue).ExistsInQueue(pRequestHeader) {
			$$$LOGERROR($$$FormatText($$$Text("Active message '%1', processed in job '%2', already exists in the queue, not restored."),pId,pName))
			Quit
		}
		If $$$ISOK(##class(Ens.Queue).PutBackToQueue(pRequestHeader)) {
			Set:pMarkAsCrashed $$$EnsCrashedMessage(pId)=""
			$$$LOGINFO($$$FormatText($$$Text("Active message '%1', processed in job '%2', has been restored to the queue."),pId,pName))
		} Else {
			$$$LOGERROR($$$FormatText($$$Text("Active message '%1', processed in job '%2', failed to be restored to the queue."),pId,pName))
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod CleanUpDeadJobs()
{
	Do ..MarkDeadJobs()
	#; Clean up Ens.JobStatus and Ens.JobMonitor and Ens.HostMonitor(tHost,$$$eMonitorJob)
	Set tJob="" For { Set tJob=$O($$$EnsJobStatus($$$SystemName,tJob))  Quit:tJob=""
		If $G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobIsDead)) {
			Set tConfigName=$G($$$EnsJobStatus($$$SystemName,tJob,$$$eJobStartConfigName))
			Kill $$$EnsJobStatus($$$SystemName,tJob)
			$$$KillJobMonitor($$$SystemName_":"_tJob)
			If ""'=tConfigName $$$KillHostMonitor(tConfigName,$$$eMonitorJob,$$$SystemName_":"_tJob)
		}
	}
	Quit
}

ClassMethod AbortOperation(pJob As %String = "") As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_Jobs:WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation) 
	}
	do {
		Set tJob=pJob
		Lock +$$$EnsJobRequest($$$SystemName,tJob):2 Else  Set tSC=$$$EnsError($$$EnsErrCanNotAcquireJobLock,tJob,2) Quit
		Set $$$EnsJobRequest($$$SystemName,tJob)=$$$eJobRequestAbort
		Lock -$$$EnsJobRequest($$$SystemName,tJob)
		Set tSC = ##class(Ens.Queue).SignalAllJobs(tJob)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod SuspendOperation(pJob As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	If '##class(EnsPortal.Utils).CheckResourceList("%Ens_MessageSuspend:USE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	do {
		Set tJob=pJob
		Lock +$$$EnsJobRequest($$$SystemName,tJob):2 Else  Set tSC=$$$EnsError($$$EnsErrCanNotAcquireJobLock,tJob,2) Quit
		Set $$$EnsJobRequest($$$SystemName,tJob)=$$$eJobRequestSuspend
		Lock -$$$EnsJobRequest($$$SystemName,tJob)
		Set tSC = ##class(Ens.Queue).SignalAllJobs(tJob)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// List the known jobs and their information
Query Enumerate() As %Query(ROWSPEC = "Job:%String,ConfigName:%String,Mode:%String,Status:%String,Detail:%String,ActiveMessage:%String,State:%String") [ SqlProc ]
{
}

ClassMethod EnumerateExecute(ByRef qHandle As %Binary) As %Status
{
 	Set qHandle=""
 	Do ..MarkDeadJobs()
 	Quit $$$OK
}

ClassMethod EnumerateClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
 	Quit $$$OK
}

ClassMethod EnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 Set $ZT="Trap",tSC=$$$OK
 do {
	Set Row="",AtEnd=0,qHandle=$Order($$$EnsJobStatus($$$SystemName,qHandle))
	If qHandle="" Set AtEnd=1 Quit
	Set tConfigName=$$$EnsJobStatus($$$SystemName,qHandle,$$$eJobStartConfigName)
	Set tMode=$Case($$$EnsJobStatus($$$SystemName,qHandle,$$$eJobForeground), 1:"Foreground", 0:"Background")
	Set tStatus=$$$EnsJobStatus($$$SystemName,qHandle,$$$eJobStatus)
	Set tDetail=$G($$$EnsJobStatus($$$SystemName,qHandle,$$$eJobDetail))
	Set tActiveMessage=$g($$$EnsActiveMessage($$$SystemName_":"_qHandle))
	Set tState=$Case($ZStrip($E(qHandle),"*N"),"Z":"Dead","X":"Starting",:"Alive")
	Set tJob=$Case(tState,"Dead":$E($P(qHandle,"_"),2,*),"Starting":"",:qHandle)
	Set:$$$isVMS&&$Case($E(tJob),0:0,"Z":0,"X":0,:1) $P(tJob,":")=$$$NUM($ZHex(+$P(tJob,":")),8)
	Set:tState="Dead" tStatus="last was: "_tStatus
 	Set Row=$ListBuild(tJob,tConfigName,tMode,tStatus,tDetail,tActiveMessage,tState)
 } while (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
