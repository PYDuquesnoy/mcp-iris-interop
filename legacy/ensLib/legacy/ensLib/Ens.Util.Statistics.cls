/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Container the queries used by Ensemble statistics page.
/// Also contains methods to record activity statistics for given dimensions.
Class Ens.Util.Statistics Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Returns a set of pre-defined counters
Query EnumerateCounters() As %Query(ROWSPEC = "Category:%String,Item:%String,Count:%Integer")
{
}

ClassMethod EnumerateCountersExecute(ByRef qHandle As %Binary) As %Status
{
 	Set qHandle=""
	Quit $$$OK
}

ClassMethod EnumerateCountersFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set Row="",AtEnd=0,qHandle=qHandle+1
		
		// each row of this query returns a different counter value
		If (qHandle = 1) {
			Set tCategory = "Messages"
			Set tItem = "Total"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens.MessageHeader)
		}
		ElseIf (qHandle = 2) {
			Set tCategory = "Messages"
			Set tItem = "Created"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens.MessageHeader WHERE Status = 1)
		}
		ElseIf (qHandle = 3) {
			Set tCategory = "Messages"
			Set tItem = "Queued"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens.MessageHeader WHERE Status = 2)
		}
		ElseIf (qHandle = 4) {
			Set tCategory = "Messages"
			Set tItem = "Delivered"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens.MessageHeader WHERE Status = 3)
		}
		ElseIf (qHandle = 5) {
			Set tCategory = "Messages"
			Set tItem = "Suspended"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens.MessageHeader WHERE Status = 5)
		}
		ElseIf (qHandle = 6) {
			Set tCategory = "Messages"
			Set tItem = "Discarded"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens.MessageHeader WHERE Status = 4)
		}
		ElseIf (qHandle = 7) {
			Set tCategory = "Sessions"
			Set tItem = "Total"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens.MessageHeader WHERE %ID = SessionId)
		}
		ElseIf (qHandle = 8) {
			Set tCategory = "Business Processes"
			Set tItem = "Total"
			&sql(SELECT COUNT(*) INTO :tCount FROM Ens_BP.Context)
		}
		Else {
			Set AtEnd=1
			Quit
		}

	 	Set Row=$ListBuild(tCategory,tItem,tCount)
	} While (0)

Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod EnumerateCountersClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// Returns status for a set of hosts<br>
/// <var>Name</var> is the name of the host item.<br>
/// <var>Type</var> is the type (Service, Operation, etc.) of the host item.<br>
/// <var>Status</var> is last reported status for the item.<br>
/// <var>AdapterState</var> is connected status of jobs for this host.<br>
/// <var>LastActivity</var> is local time of last activity on this host.<br>
/// <var>ElapsedTime</var> is number of seconds from time of last activity on this host to now.<br>
/// <var>Queue</var> is the current number of items in the queue associated with this item.<br>
/// <var>Count</var> is the number of activities processed since it was started.<br>
Query EnumerateHostStatus() As %Query(ROWSPEC = "Name:%String,Type:%String,Status:%String,AdapterState:%String,LastActivity:%TimeStamp,ElapsedTime:%Integer,Queue:%Integer,Count:%Integer") [ SqlProc ]
{
}

ClassMethod EnumerateHostStatusExecute(ByRef qHandle As %Binary) As %Status
{
 	Set qHandle=""
	Quit $$$OK
}

ClassMethod EnumerateHostStatusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set Row="",AtEnd=0

		For  {
			Set qHandle = $$$OrderHostMonitor(qHandle)
			If qHandle'="Ens.MonitorService",qHandle'="Ens.Alarm",qHandle'="Ens.Alert" Quit
		}

		If (qHandle = "") {
			Set AtEnd = 1
		} Else {
			// get last slot
			Set tNow = $$$timeUTCH
			Set tDay = +tNow
			Set tSlot = ($P(tNow,",",2) \ 10)

			Set tEnabled=$G($$$ConfigIsEnabled(qHandle),0)
			Set (tCountConnected,tCountDisconnected,tCountListening,tCount)=0
			Set tJob="" For { Set tJob=$$$OrderHostMonitor(qHandle,$$$eMonitorJob,tJob)  Quit:tJob=""
				Set tConn=$e($$$GetJobMonitor(qHandle,tJob,$$$eMonitorConnected))
				If tConn=1 {
					Set tCountConnected=tCountConnected+1, tCount=tCount+1
				} ElseIf tConn=0 {
					Set tCountDisconnected=tCountDisconnected+1, tCount=tCount+1
				} ElseIf tConn="." {
					Set tCountListening=tCountListening+1, tCount=tCount+1
				}
			}
			If tCount {
				Set tConnectState=$S(tCountConnected:tCountConnected_" job"_$S(tCountConnected=1:"",1:"s")_" connected",1:"")
				Set tConnectState=tConnectState_$S(tCountDisconnected:$S(""=tConnectState:"",1:", ")_tCountDisconnected_" job"_$S(tCountDisconnected=1:"",1:"s")_" disconnected",1:"")
				Set tConnectState=tConnectState_$S(tCountListening:$S(""=tConnectState:"",1:", ")_tCountListening_" job"_$S(tCountListening=1:"",1:"s")_" listening",1:"")
			} Else {
				If 'tEnabled {
					#; Check the config database for enabled - Enabled in DB but not in Production results from being suspended by the schedule handler
					Set tConnectState=$S(##class(Ens.Director).IsItemEnabled(qHandle):"unscheduled",1:"disabled")
				} Else {
					Set tStayConn=$G($$$ConfigSetting(qHandle,"Adapter","StayConnected"),"-")
					Set tConnectState=$S("-"=tStayConn:"n/a", 1:"not connecting")
				}
			}

			Set tQueueCount=$G($$$EnsQueue(qHandle,0,"count"))
			If tQueueCount=0 Set tQueueCount=""

			Set Row=$ListBuild(qHandle,
								$$$ConfigTypeName($G($$$ConfigBusinessType(qHandle))),
								$s(tEnabled:$$$GetHostMonitor(qHandle,$$$eMonitorStatus),1:"Disabled"),
								tConnectState,
								$$$timeUTCtoLocal($$$GetHostMonitor(qHandle,$$$eMonitorLastActivity)),
								$System.SQL.DATEDIFF("ss",$$$GetHostMonitor(qHandle,$$$eMonitorLastActivity),$$$timeUTC),
								tQueueCount,
								+$$$GetHostMonitor(qHandle,$$$eMonitorCount))
		}
	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod EnumerateHostStatusClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// Returns job status for a specific host
Query EnumerateJobStatus(pHostName As %String) As %Query(ROWSPEC = "Name:%String,Job:%String,Status:%String,AdapterState:%String,LastActivity:%TimeStamp,Count:%Integer,Method:%String,Retry:%Integer,ActiveMessage:%String") [ SqlProc ]
{
}

ClassMethod EnumerateJobStatusExecute(ByRef qHandle As %Binary, pHostName As %String = "") As %Status
{
 	Set qHandle = ""
 	Set qHandle("Host") = pHostName
	Quit $$$OK
}

ClassMethod EnumerateJobStatusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set Row="",AtEnd=0
		If (qHandle("Host") '= "") {
			// details for one host
			Set tHost = qHandle("Host")
			Set qHandle=$$$OrderHostMonitor(tHost,$$$eMonitorJob,qHandle)
		}
		If ((qHandle("Host") = "") || (qHandle = "")) {
			Set AtEnd = 1
		} Else {
		 	Set Row=$ListBuild(tHost
					, $P(qHandle,":",2)
					, $$$GetJobMonitor(tHost,qHandle,$$$eMonitorStatus)
					, $Case($e($$$GetJobMonitor(tHost,qHandle,$$$eMonitorConnected)),1:"Connected", ".":"Listening", 0:"Disconnected", :"")
					, $$$timeUTCtoLocal($$$GetJobMonitor(tHost,qHandle,$$$eMonitorLastActivity))
					, $$$GetJobMonitor(tHost,qHandle,$$$eMonitorCount)
					, $$$GetJobMonitor(tHost,qHandle,$$$eMonitorMethod)
					, $$$GetJobMonitor(tHost,qHandle,$$$eMonitorRetry)
					, $g($$$EnsActiveMessage(qHandle))
					)
		}
	} While 0
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod EnumerateJobStatusClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// For a host <var>pHost</var>, 
/// return an array of <var>count</var> counter values in <var>pValues</var>
/// subscripted by slot number. The final slot is the most recent values.<br>
/// <var>pCount</var> is the number of values (intervals) to return.
/// <var>pIntervalSize</var> is the size, in seconds of each slot (this should be a multiple of 10 and not greater than 3600).<br>
/// If <var>pSumOnly</var> is true, then do not fill in <var>pValues</var>.<br>
/// Returns the total number in all the slots.
ClassMethod GetCounterValues(pHost As %String, ByRef pValues As %Integer, pCount As %Integer, pIntervalSize As %Integer, pSumOnly As %Boolean = 0) As %Integer
{
	Set tTotal = 0

	// # of samples per interval
	Set tSampPerInt = (pIntervalSize \ $$$EnsCounterInterval)

	// # of intervals per day
	Set tIntPerDay = (86400 \ pIntervalSize)
	
	// find nearest complete interval
	Set tNow = $$$timeUTCH
	Set tDay = +tNow
	Set tInt = ($P(tNow,",",2) \ pIntervalSize) - 1
	If (tInt < 0) {
		// last interval of previous day
		Set tDay = (tDay - 1)
		Set tInt = tIntPerDay - 1
	}
	
	// find starting sample (end of nearest interval)
	Set tSlot = ((tInt+1) * tSampPerInt) - 1
	
	Set n = pCount
	While (n > 0) {
		Set tVal = 0

		// sum up samples for interval
		For s = 1:1:tSampPerInt {
			
			Set tVal = tVal + $$$GetHostCounter(pHost,tDay,tSlot)
			Set tSlot = tSlot - 1
			If (tSlot < 0) {
				// go back a day
				Set tDay = (tDay - 1)
				Set tSlot = (86400 \ $$$EnsCounterInterval) - 1
			}
		}

		Set tTotal = tTotal + tVal
		Set:'pSumOnly pValues(n) = tVal
		Set n = n - 1
	}
	Quit tTotal
}

/// Returns contents of BusinessMetric cache<br>
Query EnumerateMetrics() As %Query(ROWSPEC = "Name:%String,LastUpdate:%TimeStamp,IsRunning:%Boolean") [ SqlProc ]
{
}

ClassMethod EnumerateMetricsExecute(ByRef qHandle As %Binary) As %Status
{
 	Set qHandle=""
	Quit $$$OK
}

ClassMethod EnumerateMetricsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set Row="",AtEnd=0
		
		Set qHandle = $O($$$EnsMetrics(qHandle))
		 
		If (qHandle = "") {
			Set AtEnd = 1
		}
		Else {
			// find first instance
			Set inst = $O($$$EnsMetrics(qHandle,""))
			Set isRunning = 0
			Set lastUpdate = ""
			
			Set:inst'="" isRunning = +$G($$$EnsMetrics(qHandle,inst,"%IsRunning"))
			Set:inst'="" lastUpdate = $G($$$EnsMetrics(qHandle,inst,"%LastUpdate"))
			
		 	Set Row=$ListBuild(qHandle,lastUpdate,isRunning)
		}
	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod EnumerateMetricsClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// Returns values within a specific BusinessMetric cache<br>
Query EnumerateMetricProps(pName As %String = "") As %Query(ROWSPEC = "Instance:%String,Property:%String,Value:%String,History:%String") [ SqlProc ]
{
}

ClassMethod EnumerateMetricPropsExecute(ByRef qHandle As %Binary, pName As %String = "") As %Status
{
 	Set qHandle("Name") = pName
 	Set qHandle("Instance") = ""
 	Set qHandle("Property") = ""
	Quit $$$OK
}

ClassMethod EnumerateMetricPropsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set Row="",AtEnd=0
		Set tName = qHandle("Name")
		If (tName '= "") {
			If (qHandle("Instance") = "") {
				Set qHandle("Instance") = $O($$$EnsMetrics(tName,qHandle("Instance")))
			}
			While (qHandle("Instance") '= "") {
				For  {
					Set qHandle("Property") = $O($$$EnsMetrics(tName,qHandle("Instance"),qHandle("Property")))
					If qHandle("Property")'="%IsRunning",qHandle("Property")'="%LastUpdate" quit
				}
				If (qHandle("Property") '= "") {
					Quit
				}
				Else {
					// next instance
					Set qHandle("Instance") = $O($$$EnsMetrics(tName,qHandle("Instance")))
				}
			}
		}
		If (qHandle("Instance") = "") {
			Set AtEnd = 1
		}
		Else {
			Set tValue = $G($$$EnsMetrics(tName,qHandle("Instance"),qHandle("Property")))

			// build history list
			Set tHistory = ""
			Set tKey = $O($$$EnsMetrics(tName,qHandle("Instance"),qHandle("Property"),""))
			While (tKey '= "") {
				Set tHistory = tHistory _ $Case(tHistory="",1:"",:", ") _ $G($$$EnsMetrics(tName,qHandle("Instance"),qHandle("Property"),tKey))
				Set tKey = $O($$$EnsMetrics(tName,qHandle("Instance"),qHandle("Property"),tKey))
			}			
		 	Set Row=$ListBuild(qHandle("Instance"),qHandle("Property"),tValue,tHistory)
		}
	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod EnumerateMetricPropsClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
	Quit $$$OK
}

/// Get system metrics for the current namespace
ClassMethod GetSystemMetrics(ByRef pData, pState As %Integer = 1, pQueueLimit As %Integer = 5) As %Status [ Internal ]
{
	If '$system.Security.Check("%Ens_Dashboard","USE") Quit $$$ERROR($$$InsufficientPrivilegeForOperation)

	Try {
		Set tStatus = $$$OK

		If pState'=$$$eProductionStateStopped {
			// Don't get queue data if the production is stopped
			Set tRS = ##class(%Library.ResultSet).%New("Ens.Queue:Enumerate")
			Set tStatus1 = tRS.Execute()
			If $$$ISOK(tStatus1) {
				Set tQCount = 0
				While tRS.Next() {
					Set tName = tRS.Get("Name")
					If tName="" Continue
					Set tQueues(+tRS.Get("Count"),tName) = ""
					Set tQCount = tQCount+1
				}
				Set pData("QueueCount") = $Get(pData("QueueCount"))+tQCount
				Set pData("QueueCount",$Namespace) = tQCount
				Set tCount = ""
				Set tFound = 0
				For {
					Set tCount = $Order(tQueues(tCount),-1)
					Quit:tCount=""
					Set tName = ""
					For {
						Set tName = $Order(tQueues(tCount,tName))
						Quit:tName=""
						Set tFound = tFound+1
						Set pData("Queues",tCount,tName) = $Namespace
						Quit:tFound=pQueueLimit
					}
					Quit:tFound=pQueueLimit
				}
			}
		}

		Set tHost = ""
		For {
			Set tHost = $$$OrderHostMonitor(tHost)
			Quit:tHost=""
			If (tHost="Ens.MonitorService") || (tHost="Ens.Alarm") || (tHost="Ens.ScheduleService") Continue
			Set tType = $Get($$$ConfigBusinessType(tHost))
			If (tType="") || (tType=$$$eHostTypeProcess) || (tType=$$$eHostTypeActor) Continue  // BP
			Set tLastActivity = $$$GetHostMonitor(tHost,$$$eMonitorLastActivity)
			If tType=$$$eHostTypeService {
				Set pData("Count","In") = $Get(pData("Count","In"))+..GetCounterValues(tHost,,3,10,1)
				If tLastActivity ] $Get(pData("LastActivity","In")) {
					Set pData("LastActivity","In") = tLastActivity
				}
			}
			ElseIf tType=$$$eHostTypeOperation {
				Set pData("Count","Out") = $Get(pData("Count","Out"))+..GetCounterValues(tHost,,3,10,1)
				If tLastActivity ] $Get(pData("LastActivity","Out")) {
					Set pData("LastActivity","Out") = tLastActivity
				}
			}
		}

		If (pState=$$$eProductionStateRunning) || (pState=$$$eProductionStateUnknown) {
			Set tJobCount = 0
			Set tVisitorCount = 0
			Set tJobKey = ""
			For {
				Set tJobKey = $Order($$$EnsJobStatus($$$SystemName,tJobKey))
				Quit:tJobKey=""
				If $Extract(tJobKey,1)'=+$Extract(tJobKey,1) Continue  // ignore Znnn and Xnnn jobs (ghost and starting)
				Set tGuestConfigName = $Get($$$EnsJobStatus($$$SystemName,tJobKey,$$$eJobGuestConfigName))
				If tGuestConfigName'="" {
					Set tVisitorCount = tVisitorCount+1
				}
				Else {
					Set tJobCount = tJobCount+1
				}
				If $$$isVMS {
					Set tJobSub = $ZHex(+tJobKey) // force numeric to convert to hexadecimal
				}
				Else {
					Set tJobSub = tJobKey
				}
				If $Data(pData("BusyProcesses",tJobSub)) {
					Set $LI(pData("BusyProcesses",tJobSub),2) = $Select(tGuestConfigName'="":"*", 1:"")_$Namespace
					If tGuestConfigName'="" {
						Set $LI(pData("BusyProcesses",tJobSub),3) = "*"_tGuestConfigName
					}
					Else {
						Set tConfigName = $Get($$$EnsJobStatus($$$SystemName,+tJobKey,$$$eJobStartConfigName))
						If tConfigName'="" {
							Set $LI(pData("BusyProcesses",tJobSub),3) = tConfigName
						}
					}
				}
			}
			Set pData("JobCount") = $Get(pData("JobCount"))+tJobCount
			Set pData("JobCount",$Namespace) = tJobCount
			Set pData("VisitorCount") = $Get(pData("VisitorCount"))+tVisitorCount
			Set pData("VisitorCount",$Namespace) = tVisitorCount
		}

		Set tErrorCount = $$$GetLogMonitor($$$eLogTypeError,$$$eMonitorCount)+$$$GetLogMonitor($$$eLogTypeAssert,$$$eMonitorCount)
		Set pData("Errors","Count",$Namespace) = tErrorCount
		Set pData("Errors","Count") = tErrorCount+$Get(pData("Errors","Count"))
		Set tAlertCount = +$$$GetLogMonitor($$$eLogTypeAlert,$$$eMonitorCount)
		Set pData("Alerts","Count",$Namespace) = tAlertCount
		Set pData("Alerts","Count") = +$Get(pData("Alerts","Count"))
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}

	Quit tStatus
}

/// For InterSystems internal use<br>
/// This method removes the inmemory array.<br>
/// It is not intended to be called directly. If it is ensure pConfigName is not ""<br>
ClassMethod killInMemoryStats(pConfigName As %String = "") [ Internal ]
{
	Kill $$$StatsRootData(pConfigName)
	Quit
}

/// This method tests if statistics gathering has started.
ClassMethod StatsStarted(pConfigName As %String = "") As %Integer
{
	If (pConfigName'="") {Quit $D($$$StatsStart(pConfigName))} Else {Quit 0}
}

/// For InterSystems internal use<br>
/// This method sets the start time. It uses the $ZH function and is called from InitStats.
/// It is not intended to be called directly. If it is ensure pConfigName is not ""
ClassMethod setStatsStart(pConfigName As %String = "") [ Internal ]
{
	Set $$$StatsStart(pConfigName)=$ZH
	Quit
}

/// For InterSystems internal use<br>
/// This method returns seconds since the start time was set.
/// It returns -1 if stats were not started.
/// It is not intended to be called directly. If it is ensure pConfigName is not ""
ClassMethod statsTimeSinceStart(pConfigName As %String = "") As %Numeric [ Internal ]
{
	If $D($$$StatsStart(pConfigName),tStart) {
		Quit $ZH-tStart
	} Else {
		Quit -1
	}
}

/// Used to check if statistics are to be gathered.<br>
/// The code within the method is subject to change.<br>
ClassMethod StatsActive(pConfigName As %String = "") As %Boolean
{
	If (pConfigName'="")&&($G($$$EnsConfig("Stats","RecordStats",pConfigName),$G($$$EnsConfig("Stats","RecordStats"),0))) {
		Quit 1
	} Else { 
		Quit 0
	}
}

/// Used to check if statistics ought to be collected and initializes if needed.<br>
/// The code within the method is subject to change.<br>
ClassMethod InitStats(pConfigName As %String = "", pOverrideConfigSetting As %Boolean = 0) As %Boolean
{
	If (pConfigName'=""),(pOverrideConfigSetting||$G($$$EnsConfig("Stats","RecordStats",pConfigName),$G($$$EnsConfig("Stats","RecordStats"),0))) {
		Kill $$$StatsUserDimension(pConfigName) ;cleanup user dimension if RecordStats not called for some reason. 
		Do ..setStatsStart(pConfigName)
		Quit 1
	}
	Quit 0
}

/// This method returns the interval recording time.
ClassMethod StatsCounterInterval() As %Integer
{
	Quit $G($$$EnsConfig("Stats","Interval"),$$$EnsCounterInterval)
}

/// This method set the default interval recording time in seconds.<br>
/// The minimum is 1 second.<br>
/// It returns the interval used.<br>
ClassMethod SetStatsCounterInterval(pInterval As %Integer = 10) As %Integer
{
	If pInterval<1 Set pInterval=1
	Set pInterval = pInterval\1
	Set ^Ens.Config("Stats","Interval") = pInterval
	Quit pInterval
}

/// This method returns the maximum days to keep the statistics in temporary storage.<br>
/// If statistics are not moved from temporary to permanent storage this is a safety<br>
/// measure to prevent the temporary data growing.<br>
/// This method returns the interval recording time.<br>
/// The default if not set is 1 day.<br>
ClassMethod GetTempStatsDaystoKeep() As %Integer
{
	Quit $G($$$EnsConfig("Stats","TempStatsDaystoKeep"),$G(^Ens.Config("Stats","TempStatsDaystoKeep"),1))
}

/// This method set the maximum days to keep the statistics in temporary storage.<br>
/// The minimum is 1 day. Default is 1 day.<br>
/// It returns the interval used.<br>
ClassMethod SetTempStatsDaystoKeep(pDaysToKeep As %Integer = 1) As %Integer
{
	Set pDaysToKeep = +pDaysToKeep\1
	If pDaysToKeep<1 Set pDaysToKeep=1
	Set ^Ens.Config("Stats","TempStatsDaystoKeep") = pDaysToKeep
	Quit pDaysToKeep
}

/// This method will record the count and duration statistics to the temporary global.<br>
/// Passing in pCount will override default count of 1.<br>
/// Passing in pDuration will override calculated duration and override checking if stats have been started.<br>
/// Negative Duration (calculated or passed in) is not used.<br>
ClassMethod RecordStats(pConfigType As %Integer = 0, pConfigName As %String = "", pUserDimension As %String = "", pCleanupAfter As %Boolean = 1, pCount As %Integer = 1, pDuration As %Numeric)
{
	#dim tUTCH As %String
	#dim tDay, tSlot As %Integer
	
	If (pConfigName'="")&&($D(pDuration)||..StatsStarted(pConfigName)) {
		If '$D(pDuration) Set pDuration = ..statsTimeSinceStart(pConfigName)
		If (pDuration>=0) {
			If (pUserDimension = "") Set pUserDimension=..GetStatsUserDimension(pConfigName, pConfigType)	
			Try {
				Set tUTCH=$$$timeUTCH,tDay=+tUTCH,tSlot=$P(tUTCH,",",2)\..StatsCounterInterval()
				If $I($$$StatsPersistCounters(tDay,tSlot,pConfigType,pConfigName,pUserDimension,"count"),pCount) {}
				If $I($$$StatsPersistCounters(tDay,tSlot,pConfigType,pConfigName,pUserDimension,"duration"),pDuration) {}
				If $I($$$StatsPersistCounters(tDay,tSlot,pConfigType,pConfigName,pUserDimension,"d2"),(pDuration*pDuration)) {}
				If ($G($$$StatsQueueDuration(pConfigName),0)>0)&&$I($$$StatsPersistCounters(tDay,tSlot,pConfigType,pConfigName,pUserDimension,"queue"),$$$StatsQueueDuration(pConfigName)) {}
			} Catch {/* Protect against <SUBSCRIPT>*/}
		}
		If pCleanupAfter {Do ..killInMemoryStats(pConfigName)}
	}
	Quit
}

/// This returns the User Dimension from the in memory array.
ClassMethod GetStatsUserDimension(pConfigName As %String = "", pConfigType As %Integer = 0) As %String
{
	If (pConfigName="") {
		Quit $$$StatsDefaultDimension
	} ElseIf $D($$$StatsUserDimension(pConfigName))#2 {
		Quit $$$StatsUserDimension(pConfigName)
	} ElseIf $D($$$JobCurrentHeaderId)#2,(pConfigType>$$$eHostTypeUnknown),(pConfigType<=$$$eHostTypeActor) {
		#dim tMessageHeaderObj As Ens.MessageHeader
		#dim tUserDimension As %String = $$$StatsDefaultDimension
		Try {
			Set tMessageHeaderObj = $classmethod("Ens.MessageHeader","%OpenId",$$$JobCurrentHeaderId)
			Try {
				Set tUserDimension = $classmethod(tMessageHeaderObj.MessageBodyClassName,"%OpenId",tMessageHeaderObj.MessageBodyId).GetStatsDimension()
			} Catch {}
			If (tUserDimension = $$$StatsDefaultDimension)||(tUserDimension="") {
				Set tUserDimension = $S(tMessageHeaderObj.MessageBodyClassName'="":tMessageHeaderObj.MessageBodyClassName,1:$$$StatsDefaultDimension)
			}
		} Catch {Set tUserDimension = $$$StatsDefaultDimension}
		Quit tUserDimension
	}
	Quit $$$StatsDefaultDimension
}

/// This sets the User Dimension in the in memory array.
ClassMethod SetStatsUserDimension(pConfigName As %String = "", pUserDimension As %String = {$$$StatsDefaultDimension})
{
	If (pConfigName'="") Set $$$StatsUserDimension(pConfigName)=pUserDimension
	Quit
}

/// For InterSystems internal use<br>
/// This sets the Queue Duration in memory array. Accumulate since cleared when recorded.
ClassMethod SetStatsQueueDuration(pConfigName As %String = "", pDuration As %Numeric = 0) [ Internal ]
{
	If (pConfigName'="")&&(pDuration'=0) Set $$$StatsQueueDuration(pConfigName)=$G($$$StatsQueueDuration(pConfigName),0)+pDuration
	Quit
}

/// For InterSystems internal use<br>
/// This gets the Queue Duration in memory array.
ClassMethod GetStatsQueueDuration(pConfigName As %String = "") As %Numeric [ Internal ]
{
	If (pConfigName'="") Quit $G($$$StatsQueueDuration(pConfigName),0)
	Quit 0
}

/// This method enables or disables statistics recording for the configuration item passed in.<br>
/// The second parameter returned is the value of the setting prior to the change.<br>
/// The third parameter specifies if enabled or disabled. The default is enabled.<br>
/// The code within the method is subject to change.<br>
ClassMethod EnableStatsForConfig(pConfigName As Ens.DataType.ConfigName = "", Output pPrevious As %Boolean, pOn As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	If pConfigName = "" Quit $$$ERROR($$$EnsErrGeneral,"Invalid Config Name")
	Set pPrevious = $G(^Ens.Config("Stats","RecordStats",pConfigName))
	If (pOn = "") {
		Kill ^Ens.Config("Stats","RecordStats",pConfigName)
	} Else {
		Set ^Ens.Config("Stats","RecordStats",pConfigName) = pOn
	}
	Quit tSC
}

/// This method disable statistics recording for the configuration item passed in.<br>
/// The code within the method is subject to change.<br>
ClassMethod DisableStatsForConfig(pConfigName As Ens.DataType.ConfigName = "", Output pPrevious As %Boolean) As %Status
{
	Set tSC = ..EnableStatsForConfig(pConfigName,.pPrevious,0)
	Quit tSC
}

/// This method enables statistics recording for all items running in a production in this namespace.<br>
/// The first parameter is included to allow for future use.<br>
/// The second parameter returned is the value of the setting prior to the change.<br>
/// The third parameter specifies if enabled or disabled. The default is enabled.<br>
/// The code within the method is subject to change.<br>
ClassMethod EnableStatsForProduction(pProduction As %String = "", Output pPrevious As %Boolean, pOn As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Set pPrevious = $G(^Ens.Config("Stats","RecordStats"),0)
	Set ^Ens.Config("Stats","RecordStats") = pOn
	Quit tSC
}

/// This method disables statistics recording for all items running in a production in this namespace.<br>
/// The first parameter is included to allow for future use.<br>
/// The code within the method is subject to change.<br>
ClassMethod DisableStatsForProduction(pProduction As %String = "", Output pPrevious As %Boolean) As %Status
{
	Set tSC = ..EnableStatsForProduction(pProduction,.pPrevious,0)
	Quit tSC
}

/// This method reports which items are enabled for statistics gathering.<br>
/// The parameter is passed back an array if there are any items enabled/disabled individually.<br>
/// The second parameter AllItems will indicate if all items are enabled.<br>
ClassMethod ReportItemsEnabledForStats(ByRef pItems, Output pAllItems As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Set pItems=0
	Set tItem=$O(^Ens.Config("Stats","RecordStats",""))
	While (tItem'="") {
		Set pItems(tItem)=^Ens.Config("Stats","RecordStats",tItem)
		Set tItem=$O(^Ens.Config("Stats","RecordStats",tItem))
	}
	Set pAllItems=$G(^Ens.Config("Stats","RecordStats"),0)
	Quit tSC
}

/// Counters and Duration are stored in a temporary global before being moved to tables for analysis.<br>
/// This method removes the temporary data that is older than <parameter>pDaysToKeep</parameter>.<br>
/// This method is called daily in a running production by the background Ens.MonitorService using
/// <method>GetTempStatsDaystoKeep</method> for the pDaysToKeep value as a safeguard against growth of
/// uncollected data.<br>
/// If <parameter>pDaysToKeep</parameter> is 0 then the returned <parameter>pEntriesDeleted</parameter> will be -1
/// as the individual records deleted are not counted.<br>
/// If no value is passed in for pDaysToKeep then the purge will exit immediately.
ClassMethod PurgeUncollectedStats(pDaysToKeep As %Integer = -1, Output pEntriesDeleted As %Integer = 0, pNamespaceToPurge As %String = {$namespace}) As %Status
{
	Set tSC = $$$OK
	#; Ensure 0 or an integer passed in
	If (pDaysToKeep<0)||(pDaysToKeep'=(+pDaysToKeep\1)) Quit tSC

	If (pDaysToKeep=0) {
		Set tNSPJob=$O($$$StatsPersistCountersRoot(pNamespaceToPurge_"~"))
		While (tNSPJob'="") {
			#; Only purge for current namespace
			If $Piece(tNSPJob,"~")'=pNamespaceToPurge Quit
			Kill $$$StatsPersistCountersRoot(tNSPJob)
			Set tNSPJob=$O($$$StatsPersistCountersRoot(tNSPJob))
		}
		Set pEntriesDeleted=-1
		Quit tSC
	}

	Try {	
		Set tUTCH=$$$timeUTCH, tToday=+tUTCH, tInterval=##class(Ens.Util.Statistics).StatsCounterInterval()
		Set tSlotToStop=($P(tUTCH,",",2)\tInterval)
		Set tDayToStop=tToday-pDaysToKeep
		Set tNSPJob=$O($$$StatsPersistCountersRoot(pNamespaceToPurge_"~"))
		While (tNSPJob'="") {
			#; Only purge for current namespace
			If $Piece(tNSPJob,"~")'=pNamespaceToPurge Quit
			Set tDay=$O($$$StatsPersistCountersRoot(tNSPJob,""))
			 	While (tDay'="")&&(tDay<=tDayToStop) {
					Set tDaySlot=$O($$$StatsPersistCountersRoot(tNSPJob,tDay,""))
					While (tDaySlot'="")&&((tDay<tDayToStop)||(tDaySlot<=tSlotToStop)) {
						Kill $$$StatsPersistCountersRoot(tNSPJob,tDay,tDaySlot)
						Set pEntriesDeleted=pEntriesDeleted+1
						Set tDaySlot=$O($$$StatsPersistCountersRoot(tNSPJob,tDay,tDaySlot))
					}
					Set tDay=$O($$$StatsPersistCountersRoot(tNSPJob,tDay))
				}
			Set tNSPJob=$O($$$StatsPersistCountersRoot(tNSPJob))
		}
	} Catch thrownErr {
		Set tSC = thrownErr.AsStatus()
	}
	Quit tSC
}

/// This method enables recording of metrics for SAM<br>
/// The default is off<br>
ClassMethod EnableSAMForNamespace(Output pPrevious As %Boolean, pOn As %Boolean = 1) As %Status
{
	#dim tSC = $$$OK
	Set pPrevious = $$$SAMInteropPermEnabledGet
	Set $$$SAMInteropPermConfig = pOn
	Quit tSC
}

/// This method disables recording of metrics for SAM<br>
ClassMethod DisableSAMForNamespace(Output pPrevious As %Boolean) As %Status
{
	Return ..EnableSAMForNamespace(.pPrevious,0)
}

/// This method allows the inclusion of the Production name as a label in the
/// recording of metrics for SAM<br>
/// The default is to include<br>
ClassMethod EnableSAMIncludeProdLabel(Output pPrevious As %Boolean, pOn As %Boolean = 1) As %Status
{
	#dim tSC = $$$OK
	Set pPrevious = $$$SAMInteropPermIncludeProdLabelGet
	Set $$$SAMInteropPermIncludeProdLabel = pOn
	Quit tSC
}

/// This method disallows the inclusion of the Production name as a label in the
/// recording of metrics for SAM<br>
ClassMethod DisableSAMIncludeProdLabel(Output pPrevious As %Boolean) As %Status
{
	Return ..EnableSAMIncludeProdLabel(.pPrevious,0)
}

/// This method allows the inclusion of the host label in the
/// recording of metrics for SAM<br>
/// The default is to include<br>
ClassMethod EnableSAMIncludeHostLabel(Output pPrevious As %Boolean, pOn As %Boolean = 1) As %Status
{
	#dim tSC = $$$OK
	Set pPrevious = $$$SAMInteropPermIncludeHostLabelGet
	Set $$$SAMInteropPermIncludeHostLabel = pOn
	Quit tSC
}

/// This method disallows the inclusion of the host label in the
/// recording of metrics for SAM<br>
ClassMethod DisableSAMIncludeHostLabel(Output pPrevious As %Boolean) As %Status
{
	Return ..EnableSAMIncludeHostLabel(.pPrevious,0)
}

/// Return a SAM Sensor Sampler instantiated object based on a definition in XData <br>
/// Initialize using data from JSON definition in XDataName of pDefinitionClassname
ClassMethod GetSAMSensorSampler(pDefinitionClassname As %String, pDefinitionXDataName As %String, Output pIsSAMSamplingEnabled As %Boolean = 0, Output pSC As %Status = {$$$OK}) As Ens.SAM.SensorSampler
{
	#dim ex As %Exception.AbstractException

	#dim tSAMSensorSampler  = $$$NULLOREF

	Try {
		#dim tSensorDefinitionXData = ##class(%Dictionary.XDataDefinition).%OpenId(pDefinitionClassname_"||"_pDefinitionXDataName,,.pSC)

		If $$$ISOK(pSC) {

			#dim tSensorDefinition = {}.%FromJSON(tSensorDefinitionXData.Data)

			If $IsObject(tSensorDefinition) {
				Set tSAMSensorSampler = ..InstantiateSensorSampler(tSensorDefinition, .pIsSAMSamplingEnabled, .pSC)
			}

		}

	} Catch ex {Set pSC = ex.AsStatus()}

	Return tSAMSensorSampler
}

/// Return a SAM Sensor Sampler instantiated object based on a definition in dynamic object <br>
ClassMethod InstantiateSensorSampler(pSensorDefinition As %DynamicObject, Output pIsSAMSamplingEnabled As %Boolean = 0, ByRef pSC As %Status) As Ens.SAM.SensorSampler
{
	#dim tSAMSensorSampler  = $$$NULLOREF
	#dim ex As %Exception.AbstractException

	Try { 

		#; Set to a dynamic switch
		Set pIsSAMSamplingEnabled = $$$SAMInteropEnabled

		#; If SAM Sampling not enabled still continue to instantiate allowing for dynamic enabling/disabling
		Set tSAMSensorSampler = $classmethod(pSensorDefinition.sensorClass,"%New",pSensorDefinition.sensors)

	} Catch ex {Set pSC = ex.AsStatus()}

	Return tSAMSensorSampler
}

}
