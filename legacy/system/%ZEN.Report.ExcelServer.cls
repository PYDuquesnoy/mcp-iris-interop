/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// Zen Report Excel Server definition and utility methods/queries.
Class %ZEN.Report.ExcelServer Extends RenderServer [ Deprecated, Final, System = 4 ]
{

Parameter TYPE = 3;

/// Generate the command line to run the script to start up the Excel Server.
ClassMethod CmdLine(pReportServer As %ZEN.Report.ExcelServer, Output pCmd As %String, Output pCmdArgs) As %String
{
	/*
	Program options:
		-port nnnnn
		-numthreads nnn
		-loglevel level
		-logfile filename
		-maxlogfilesize maximum log file size
		-logrotationcount maximum number of log files then cycles
		-numpingthreads n
		-pingport nnnn	*/

	Set pCmd = ""
	Set pPredictedCmdStr = ""
	Try {
		// Directory where the script is located
		Set tCmd = $system.Util.InstallDirectory()
		For tDir = "lib", "ExcelExporter" {
			Set tCmd = ##class(%File).SubDirectoryName(tCmd, tDir)
		}
	
		// Script
		Set tScript = "runserver"
		Set pCmd = ##class(%File).NormalizeFilename(tCmd_$S($$$isWINDOWS:"\",$$$isVMS:"",1:"/")_tScript_$S($$$isWINDOWS:".bat",$$$isVMS:".com",1:""))

		// build the command arguments
		Set pCmdArgs = ""
	
		// Parameters
		Set pCmdArgs($increment(pCmdArgs)) = "-port"
		Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.Port
		Set pCmdArgs($increment(pCmdArgs)) = "-numthreads"
		Set pCmdArgs($increment(pCmdArgs)) = +pReportServer.NumThreads
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

/// Lookup Zen Report Excel Servers, get basic data plus state.
Query ByServer() As %Query(ROWSPEC = "Name,Port,PingPort,Dummy,State,StateEx") [ SqlProc ]
{
}

ClassMethod ByServerExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tRS = ##class(%ResultSet).%New("%ZEN.Report.ExcelServer:ByName")
		Kill ^||%ISC.ZRS
		Set tSC = tRS.Execute()
		For {
			Quit:'tRS.Next()
			If tRS.Get("ServerType")'=3 Continue // Not an Excel Server
			Set name = tRS.Get("Name")
			Set ^||%ISC.ZRS(name) = $LB(name,tRS.Get("Port"),tRS.Get("PingPort"),"")
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Set qHandle = $LB("")
	Quit tSC
}

/// Lookup all Zen Report Excel Servers.
Query ByName(name As %String = "") As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Name,Port,PingPort,ServerType") [ SqlProc ]
{
 SELECT %ID, Name, Port, PingPort, ServerType
 FROM ExcelServer
 WHERE ServerType='3'
 ORDER BY Name
}

/// Type must be "3" for Excel Servers.
Property ServerType As %String [ InitialExpression = "3", ReadOnly ];

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
