/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen Report Render Server definition and utility methods/queries.
/// Also a superclass for other types of Zen Report Hot Servers.
Class %ZEN.Report.RenderServer Extends %Persistent [ Deprecated, System = 3 ]
{

Parameter DOMAIN = "%Utility";

/// "0" indicates a Render Server.
/// Subclasses must override this parameter.
Parameter TYPE = 0;

/// Get the Zen Report Hot Server name given its port.
ClassMethod PortToName(pPort As %String, Output pName As %String) As %Status
{
	Set Type = ..#TYPE
	Set pPort = +$G(pPort)
	Set pName = ""
	If pPort {
		If Type=0 {
			&SQL(SELECT Name into :tName FROM RenderServer WHERE Port=:pPort AND (ServerType='0' OR ServerType='' OR ServerType IS NULL))
		}
		ElseIf Type=2 {
			&SQL(SELECT Name into :tName FROM RenderServer WHERE Port=:pPort AND ServerType='2')
		}
		ElseIf Type=3 {
			&SQL(SELECT Name into :tName FROM RenderServer WHERE Port=:pPort AND ServerType='3')
		}
		Else {
			Quit $$$ERROR($$$GeneralError,"Unknown type for Zen Report Server")
		}
		If 'SQLCODE Set pName = tName Quit $$$OK
	}
	Quit $$$ERROR($$$GeneralError,"Cannot identify the Zen Report "_$S(Type="0":"Render",Type="":"Render",Type="2":"Print",Type="3":"Excel",1:"Unknown Type")_" Server by port '"_$G(pPort)_"'")
}

/// Determine the state of a Hot Server: <br>
/// 0 = Inactive and ready to be started; <br>
/// 1 = Active and responsive to PING; <br>
/// 2 = Unresponsive (one or both ports are in use but it is unresponsive to PING); <br>
/// 3 = Troubled (main port is not in use but it is responsive to PING); <br>
/// 4 = Error with port and/or ping port configuration; <br>
/// 5 = Ping returns mismatching main port and/or server type.
ClassMethod GetState(port As %Integer, pingport As %Integer, timeout As %Integer = 5, Output reportedPort As %String, Output reportedType As %String) As %Integer
{
	If '$G(port) || '$G(pingport) || ($G(port)>65535) || ($G(pingport)>65535) || (+port=+pingport) { Quit 4 }
	Set port = +port, pingport = +pingport
	Set reportedPort = "", reportedType = ""
	// Check main port
	Set tDevice = "|TCP|"_port
	Close tDevice Open tDevice:(:port:"S"):0 Close tDevice
	If $T { Set PortCheck = "free" }
	Else  { Set PortCheck = "ok" }
	// Check ping port
	Set tDevice = "|TCP|"_pingport
	Close tDevice Open tDevice:(:pingport:"S"):0 Close tDevice
	If $T { Set PingPortCheck = "free" }
	Else  { Set PingPortCheck = "ok" }
	// Check response to PING
	Set PingResponse = "no"
	If PingPortCheck="ok" {
		Set:timeout<2 timeout = 2
		If $$$ISOK(##class(%ZEN.Report.Ping).ping(pingport, timeout, .reportedPort, .reportedType)) {
			If $G(reportedPort)=port, $G(reportedType)=..#TYPE { Set PingResponse = "yes" }
			Else  { Set PingResponse="wrong" }
		}
	}
	// Determine state
	If (PingResponse="yes") {
		If PortCheck = "ok" { Quit 1 }
		Else  { Quit 3 }
	}
	ElseIf (PingResponse="wrong") {
		Quit 5
	}
	Else {
		// Didn't try to PING or failed to get a response
		If PortCheck="free" {
			If PingPortCheck="free" { Quit 0 }
		}
		Quit 2
	}
}

/// / Startup a Zen Report Hot Server given its name.
ClassMethod Start(pName As %String, Output pPreviousState As %Integer, Output pReturn As %String, pVerbose As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Set pPreviousState = 0
	Set pReturn = ""
	Lock +^%ISC.ZenReportServer.Management(pName)
	Try {
		Write:pVerbose "Starting ",pName,"...",!
		Set time = $ZTS
		Kill %objlasterror
		Set tServer = ##class(RenderServer).%OpenId(pName)
		If '$IsObject(tServer) Set tSC = %objlasterror Quit
		// Avoid starting a duplicate or a Zen Report Server that cannot start
		Set pPreviousState = ..GetState(tServer.Port, tServer.PingPort, tServer.ConnectionTimeout, .reportedPort, .reportedType)
		If pPreviousState=1 Quit
		If pPreviousState=2 Set tSC = $$$ERROR($$$GeneralError, "Unable to start") Do ..LogStartFailure(time,pName,pPreviousState,tSC) Quit
		If pPreviousState=3 Set tSC = ##class(%ZEN.Report.Ping).shutdown(tServer.PingPort, tServer.ConnectionTimeout, .Port, .Type) If $$$ISERR(tSC) Set tSC = $$$ERROR($$$GeneralError, "State was troubled - failed to cleanup/shutdown with error "_$system.Status.GetErrorText(tSC)) Do ..LogStartFailure(time,pName,pPreviousState,tSC) Quit
		If pPreviousState=4 Set tSC = $$$ERROR($$$GeneralError, "Wrong configuration of TCP port(s) - Main port="_tServer.Port_", Ping port="_tServer.PingPort) Do ..LogStartFailure(time,pName,pPreviousState,tSC) Quit
		If pPreviousState=5 Set tSC = $$$ERROR($$$GeneralError, "Mismatching configuration reported by PING - Main port="_reportedPort_", Server type="_reportedType) Do ..LogStartFailure(time,pName,pPreviousState,tSC) Quit
		Set tPredictedCmdStr = ..CmdLine(tServer,.tCmd,.tCmdArgs)
		Write:pVerbose !,"Executing: ",tPredictedCmdStr
		Set tSC = ##class(%Net.Remote.Utility).RunCommandViaCPIPE(tCmd,.pDevice,.pReturn,tServer.InitializationTimeout,2,.tCmdArgs)
		Close pDevice:"I"
		Write:pVerbose !!,"Returned from execution:",!,$S(pReturn="":"Nothing was returned",1:pReturn)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Lock -^%ISC.ZenReportServer.Management(pName)
	If $$$ISERR(tSC) Write:pVerbose !,"Error during execution of the command: ",$system.Status.GetErrorText(tSC) Do ..LogStartFailure(time,pName,pPreviousState,tSC)
	If $$$ISOK(tSC) && (pPreviousState'=1) {
		Do ..LogStart(time,pName,tCmd,pReturn)
		Set ^%SYS("zenreport","ACTIVE",+tServer.PingPort) = "" // Register
	}
	Quit tSC
}

/// Startup a Zen Report Hot Server given its main port.
ClassMethod StartByPort(pPort As %String, Output pPreviousState As %Integer, Output pReturn As %String, pVerbose As %Boolean = 0) As %Status
{
	Set tSC = ..PortToName(pPort,.Name)
	If $$$ISOK(tSC) Set tSC = ..Start(Name, .pPreviousState, .pReturn, pVerbose)
	Quit tSC
}

/// Stop a Zen Report Hot Server given its name.
ClassMethod Stop(pName, pVerbose As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Write:pVerbose "Stopping ",pName,"..."
		Set time = $ZTS
		Kill %objlasterror
		Set tServer = ##class(RenderServer).%OpenId(pName)
		If '$IsObject(tServer) Set tSC = %objlasterror Quit
		Write:pVerbose !!,"Connecting to Ping Port ",tServer.PingPort, " to send the shutdown command"
		Set tSC = ##class(%ZEN.Report.Ping).shutdown(tServer.PingPort, tServer.ConnectionTimeout, .Port, .Type)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Write:pVerbose !!,$S($$$ISOK(tSC):"Shutdown was successful",1:"Error during shutdown: "_$system.Status.GetErrorText(tSC))
	Do ..LogStop(time,pName,tSC)
	Kill ^%SYS("zenreport","ACTIVE",+tServer.PingPort) // Deregister
	Quit tSC
}

/// Generate the command line to run the script to start up the Render Server.
/// Subclasses must override this method.
ClassMethod CmdLine(pReportServer As %ZEN.Report.RenderServer, Output pCmd As %String, Output pCmdArgs) As %String
{
	Set pCmd = ""
	Set pPredictedCmdStr = ""
	Try {
		// Directory where the script is located
		Set tCmd = $system.Util.InstallDirectory()
		For tDir = "lib", "RenderServer" {
			Set tCmd = ##class(%File).SubDirectoryName(tCmd, tDir)
		}
	
		// Script
		Set tScript = "runwithfop"
		Set pCmd = ##class(%File).NormalizeFilename(tCmd_$S($$$isWINDOWS:"\",$$$isVMS:"",1:"/")_tScript_$S($$$isWINDOWS:".bat",$$$isVMS:".com",1:""))
	
		// build the command arguments
		Set pCmdArgs = ""
	
		// Parameters
		Set pCmdArgs($increment(pCmdArgs)) = "-port"
		Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.Port
		Set pCmdArgs($increment(pCmdArgs)) = "-numthreads"
		Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.NumThreads
		If pReportServer.ConfigFile'="" {
			Set pCmdArgs($increment(pCmdArgs)) = "-fop-config-file"
			Set pCmdArgs($increment(pCmdArgs)) = pReportServer.ConfigFile
		}
		Set pCmdArgs($increment(pCmdArgs)) = "-loglevel"
		Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.LogLevel
		If pReportServer.LogLevel {
			If (pReportServer.LogFile'="") {
				Set pCmdArgs($increment(pCmdArgs)) = "-logfile"
				Set pCmdArgs($increment(pCmdArgs)) = pReportServer.LogFile
			}
			If (pReportServer.MaxLogFileSize'="") {
				Set pCmdArgs($increment(pCmdArgs)) = "-maxlogfilesize"
				Set pCmdArgs($increment(pCmdArgs)) = pReportServer.MaxLogFileSize
			}
			If (pReportServer.LogRotationCount'="") {
				Set pCmdArgs($increment(pCmdArgs)) = "-logrotationcount"
				Set pCmdArgs($increment(pCmdArgs)) = pReportServer.LogRotationCount
			}
		}
		Set pCmdArgs($increment(pCmdArgs)) = "-numpingthreads"
		Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.NumPingThreads
		Set pCmdArgs($increment(pCmdArgs)) = "-pingport"
		Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.PingPort
		If pReportServer.InitQueueSize>0 {
			Set pCmdArgs($increment(pCmdArgs)) = "-initQueueSize"
			Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.InitQueueSize
		}
		If pReportServer.MemoryThreshold>0 {
			Set pCmdArgs($increment(pCmdArgs)) = "-memoryThreshold"
			Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.MemoryThreshold
			If pReportServer.ThresholdPollingPeriod>0 {
				Set pCmdArgs($increment(pCmdArgs)) = "-thresholdPollingPeriod"
				Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.ThresholdPollingPeriod
			}
		}

		/* Java location and additional arguments (not in use currently)
		Set tJava = ""
		Set:pReportServer.JavaHome'="" tJava = ##class(%File).SubDirectoryName(pReportServer.JavaHome, "bin")
		Set tJava = tJava_$S($$$isWINDOWS&(tJava=""):"java.exe", $$$isWINDOWS:"\java.exe", $$$isVMS:"java.exe", tJava="":"java", 1:"/java")
		Set tArgs = " -Xrs" // To ignore OS signals and not shutdown when the user logs off
		Set:pReportServer.JVMArgs'="" tArgs = tArgs_" "_pReportServer.JVMArgs // Add any additional user supplied JVM arguments
		*/
		
		// build the predicted command string (for displaying in logs, etc.)
		Set pPredictedCmdStr = pCmd
		For ctr=1:1:pCmdArgs {
			Set cmdArg = pCmdArgs(ctr)
			Set:(cmdArg[" ")||(cmdArg="") cmdArg = $char(34)_cmdArg_$char(34)
			Set pPredictedCmdStr = pPredictedCmdStr_" "_cmdArg
		}
	}
	Catch (ex) {
	}
	Quit pPredictedCmdStr
}

/// Lookup Zen Report Render Servers, get basic data plus state.
/// Subclasses must override query methods as needed.
Query ByServer() As %Query(ROWSPEC = "Name,Port,PingPort,Renderer,State,StateEx") [ SqlProc ]
{
}

ClassMethod ByServerExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tRS = ##class(%ResultSet).%New("%ZEN.Report.RenderServer:ByName")
		Kill ^||%ISC.ZRS
		Set tSC = tRS.Execute()
		For {
			Quit:'tRS.Next()
			Set tType = tRS.Get("ServerType")
			If (tType'=0) && (tType'="") Continue // Not a Render Server
			Set name = tRS.Get("Name")
			Set ^||%ISC.ZRS(name) = $LB(name,tRS.Get("Port"),tRS.Get("PingPort"),"FOP")
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Set qHandle = $LB("")
	Quit tSC
}

ClassMethod ByServerFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ByServerExecute ]
{
	Set index = $List(qHandle,1)
	Set index = $O(^||%ISC.ZRS(index))
	If index="" {
		Set Row = ""
		Set AtEnd = 1
	}
	Else {
		Set Row = ^||%ISC.ZRS(index)
		Set stInt = ..GetState($List(Row,2),$List(Row,3),$List(Row,4))
		Set stExt = $Case(stInt,0:$$$Text("Inactive"),1:$$$Text("Active"),2:$$$Text("Unresponsive"),3:$$$Text("Troubled"),4:$$$Text("Error"),5:$$$Text("Mismatch"),:"")
		Set $List(Row,5) = stInt, $List(Row,6) = stExt
	}
	Set qHandle = $LB(index)
	Quit $$$OK
}

ClassMethod ByServerClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ByServerExecute ]
{
	Set qHandle = ""
	Kill ^||%ISC.ZRS
	Quit $$$OK
}

/// Lookup all Zen Report Render Servers.
Query ByName(name As %String = "") As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Name,Port,PingPort,ServerType,Renderer") [ SqlProc ]
{
 SELECT %ID, Name, Port, PingPort, ServerType, 'FOP'
 FROM RenderServer
 WHERE ServerType='0' OR ServerType='' OR ServerType IS NULL
 ORDER BY Name
}

ClassMethod LogStart(time As %String = "0", name As %String = "", cmd As %String = "", return As %String)
{
	Set g = "^IRIS.Temp.ZRServer.StartStop"
	Set @g@(name,"start") = $G(@g@(name,"start")) + 1
	Set @g@(name,time,"start","cmd") = cmd
	Set @g@(name,time,"start","return") = return
	Quit
}

ClassMethod LogStartFailure(time As %String = "0", name As %String = "", state As %String = "", tSC As %String = "")
{
	Set g = "^IRIS.Temp.ZRServer.StartStop"
	Set @g@(name,"startfailure") = $G(@g@(name,"startfailure")) + 1
	Set @g@(name,time,"startfailure","state") = state
	Set @g@(name,time,"startfailure","tSC") = tSC
	Quit
}

ClassMethod LogReportInfo(time As %String = "0", endtime As %String = "0", port As %String = "", tSC As %String = "", info As %String = "", filename As %String = "")
{
	Set s = ..PortToName(port,.name)
	If $$$ISERR(s) Quit
	Set g = "^IRIS.Temp.ZRServer.Report"
	Set isOK = ($$$ISOK(tSC))
	If endtime-time>1 Set dur = ""
	Else  Set dur = $P(endtime,",",2)-$P(time,",",2)#86400
	Set @g@(name,"report",isOK) = $G(@g@(name,"report",isOK)) + 1
	Set @g@(name,"report",isOK,"duration") = $G(@g@(name,"report",isOK,"duration")) + dur
	Set @g@(name,time,"tSC") = tSC
	Set:info'="" @g@(name,time,"info") = info
	Set:filename'="" @g@(name,filename,"filename") = filename
	Set @g@(name,time,"port") = port
	Quit
}

ClassMethod LogStop(time As %String = "0", name As %String = "", tSC As %String = "")
{
	Set g = "^IRIS.Temp.ZRServer.StartStop"
	Set @g@(name,"stop") = $G(@g@(name,"stop")) + 1
	Set @g@(name,time,"stop","tSC") = tSC
	Quit
}

/// Invoked on system shutdown to terminate the external Hot JVM processes.
/// Lookup active (registered) Zen Report Servers.
ClassMethod TerminateAllRenderServers()
{
	Try {
		Set PingPort = ""
		For {
			Set PingPort = $O(^%SYS("zenreport","ACTIVE",PingPort))
			Quit:PingPort=""
			Set tSC = ##class(%ZEN.Report.Ping).shutdown(PingPort, 1)
		}
		Kill ^%SYS("zenreport","ACTIVE")
	}
	Catch {
	}
}

/// Invoked on system shutdown to terminate the external Hot JVM processes.
/// Lookup all Zen Report Server definitions.
ClassMethod TerminateAllRenderServers2()
{
	Try {
		Set tRS = ##class(%ResultSet).%New("%ZEN.Report.RenderServer:AllServers")
		Set tSC = tRS.Prepare()
		If $$$ISOK(tSC) {
			Set tSC = tRS.Execute()
			If $$$ISOK(tSC) {
				While (tRS.Next()) {
					Set PingPort = tRS.Get("PingPort")
					If PingPort Set tSC2 = ##class(%ZEN.Report.Ping).shutdown(PingPort, 1)
				}
			}
		}
	}
	Catch {
	}
}

/// Lookup all servers of all types
Query AllServers(name As %String = "") As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Name,Port,PingPort,ServerType") [ SqlProc ]
{
 SELECT %ID, Name, Port, PingPort, ServerType
 FROM RenderServer
}

/// Check if there exists a Zen Report Hot Server with a given name.
ClassMethod ZenReportServerExists(pName As %String, Output pType As %String) As %Boolean
{
	Kill tID, pType
	&sql( SELECT %ID, ServerType INTO :tID, :pType FROM RenderServer WHERE Name=:name )
	If (SQLCODE=0) && ($G(tID)'="") Quit 1
	Quit 0
}

/// Index for property Name.
Index ID On Name [ IdKey ];

/// Unique mnemonic identifier.
Property Name As %String [ Required ];

/// Type is "0" (or null/empty for backward compatibility) for Render Servers.
Property ServerType As %String [ InitialExpression = "0" ];

/// IP address or name of the machine where the JVM to be used by the Render Server is located.
/// Currently not exposed to the UI as we only support local JVMs.
Property Server As %String [ InitialExpression = "127.0.0.1", Required ];

/// TCP port number for communication with the Render Server.
Property Port As %String [ Required ];

/// TCP port number for pinging the Render Server.
Property PingPort As %String [ Required ];

/// Number of threads.
Property NumThreads As %Integer(MAXVAL = 100, MINVAL = 1) [ InitialExpression = 5 ];

/// Number of ping threads.
Property NumPingThreads As %Integer(MAXVAL = 10, MINVAL = 1) [ InitialExpression = 5 ];

/// Log level: <br>
/// 0 = no logging, <br>
/// 1 = log errors, <br>
/// 2 = log warnings, <br>
/// 3 = log info (default).
/// The logs are created in the user's home directory. 
/// These logs have the name renderserver.log.n.  renderserver.log.0 is the current log.
Property LogLevel As %String [ InitialExpression = "3", Required ];

/// Fully qualified name of the log file.
/// If a file name is not specified and logging is enabled, the file used is renderserver.log in the
/// user's home directory (or the root directory if the home directory does not exist).
Property LogFile As %String(MAXLEN = 260);

/// Maximum size, in bytes, for each log file.
/// The default is 32000 bytes and the maximum allowed is 2147483647 bytes (2 GB). A value of 0 indicates no maximum defined.
Property MaxLogFileSize As %Integer(MAXVAL = 2147483647, MINVAL = 0) [ InitialExpression = 32000 ];

/// Number of log files accumulated before we recycle through log files.
/// The default is 100.
Property LogRotationCount As %Integer(MAXVAL = 1000, MINVAL = 1) [ InitialExpression = 100 ];

/// Number of seconds to wait for the Render Server to start up.  The default is 5 s.
Property InitializationTimeout As %Integer(MAXVAL = 300, MINVAL = 2) [ InitialExpression = 5 ];

/// Number of seconds to wait for a connection to be established with the Render Server.  The default is 5 s.
Property ConnectionTimeout As %Integer(MAXVAL = 60, MINVAL = 2) [ InitialExpression = 5 ];

/// Initial size of rendering queue.
/// If left blank (default) it will be the same as the number of threads; otherwise it must be an integer between 1 and the number of threads.
Property InitQueueSize As %Integer;

/// Miliseconds to wait to poll memory threshold.  Used for memory checking.  The default is 0 (off).
Property ThresholdPollingPeriod As %Integer(MINVAL = 0) [ InitialExpression = 0 ];

/// Number of bytes that define memory usage threshold.  Used for memory checking.  The default is 0 (off).
Property MemoryThreshold As %Integer(MINVAL = 0) [ InitialExpression = 0 ];

/// Location of the JVM (similar to the JAVA_HOME environment variable).  It is used to find the target JVM
/// and assemble the command to start the Render Server. <br>
/// If there is a default JVM on the machine that is usable without the need to specify its location,
/// this setting may be left blank.
Property JavaHome As %String(MAXLEN = 260);

/// Optional additional arguments to be passed to the Java Virtual Machine (JVM) to include when assembling the 
/// command to start the Render Server. <br>
/// For example, you can specify system properties: <b>Dsystemvar=value</b> <br>
/// or set the maximum heap size: <b>Xmx256mb</b> <br>
/// and so on, as needed.
Property JVMArgs As %String(MAXLEN = 32000);

/// Fully qualified name of the renderer configuration file.
/// <br>Note: This property applies to Render Servers only.
Property ConfigFile As %String(MAXLEN = 260);

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Internal, Private, ServerOnly = 1 ]
{
	Set tName = ..Name
	If tName="" Quit $$$ERROR($$$GeneralError,$$$Text("Name must be provided"))
	If tName'?1an.anp Quit $$$ERROR($$$GeneralError,$$$Text("The Name cannot begin with a punctuation character"))
	If tName?.n Quit $$$ERROR($$$GeneralError,$$$Text("The Name cannot be composed of numeric digits only"))
	Set p = ..Port
	Set pp = ..PingPort
	If p'?1.n Quit $$$ERROR($$$GeneralError,$$$Text("The Port must be a number"))
	If pp'?1.n Quit $$$ERROR($$$GeneralError,$$$Text("The Ping Port must be a number"))
	Set p = +p
	Set pp = +pp
	If 'p Quit $$$ERROR($$$GeneralError,$$$Text("The Port cannot be zero"))
	If 'pp Quit $$$ERROR($$$GeneralError,$$$Text("The Ping Port cannot be zero"))
	If p>65535 Quit $$$ERROR($$$GeneralError,$$$Text("The Port cannot be greater than 65535"))
	If pp>65535 Quit $$$ERROR($$$GeneralError,$$$Text("The Ping Port cannot be greater than 65535"))
	If +p=+pp Quit $$$ERROR($$$GeneralError,$$$Text("The Port and the Ping Port cannot be the same"))
	If ..InitQueueSize>..NumThreads Quit $$$ERROR($$$GeneralError,$$$Text("Initial Queue Size cannot be greater than Num. Threads"))
	&sql( SELECT %ID INTO :tID FROM RenderServer WHERE (Port=:p OR PingPort=:p OR Port=:pp OR PingPort=:pp) AND %ID<>:tName )
	If (SQLCODE=0) && ($G(tID)'="") Quit $$$ERROR($$$GeneralError,$$$FormatText($$$Text("Another Zen Report Server '%1' is already using this Port or Ping Port"),tID))
	Quit $$$OK
}

Storage Default
{
<Data name="RenderServerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Server</Value>
</Value>
<Value name="3">
<Value>Port</Value>
</Value>
<Value name="4">
<Value>PingPort</Value>
</Value>
<Value name="5">
<Value>NumThreads</Value>
</Value>
<Value name="6">
<Value>NumPingThreads</Value>
</Value>
<Value name="7">
<Value>Renderer</Value>
</Value>
<Value name="8">
<Value>ConfigFile</Value>
</Value>
<Value name="9">
<Value>LogLevel</Value>
</Value>
<Value name="10">
<Value>HowOftenToClean</Value>
</Value>
<Value name="11">
<Value>NumFilesToClean</Value>
</Value>
<Value name="12">
<Value>NumberOfFilesToClean</Value>
</Value>
<Value name="13">
<Value>InitializationTimeout</Value>
</Value>
<Value name="14">
<Value>ConnectionTimeout</Value>
</Value>
<Value name="15">
<Value>JavaHome</Value>
</Value>
<Value name="16">
<Value>JVMArgs</Value>
</Value>
<Value name="17">
<Value>LogDirectory</Value>
</Value>
<Value name="18">
<Value>LogFile</Value>
</Value>
<Value name="19">
<Value>MaxLogFileSize</Value>
</Value>
<Value name="20">
<Value>LogRotationCount</Value>
</Value>
<Value name="21">
<Value>InitQueueSize</Value>
</Value>
<Value name="22">
<Value>ThresholdPollingPeriod</Value>
</Value>
<Value name="23">
<Value>MemoryThreshold</Value>
</Value>
<Value name="24">
<Value>ServerType</Value>
</Value>
</Data>
<DataLocation>^%SYS("zenreport","DEFINITION","DATA")</DataLocation>
<DefaultData>RenderServerDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%SYS("zenreport","INDEX","DATA")</IdLocation>
<IndexLocation>^%ZEN.Report.RenderServerI</IndexLocation>
<StreamLocation>^%ZEN.Report.RenderServerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
