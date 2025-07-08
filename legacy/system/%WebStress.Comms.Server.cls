/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Comms.Server Extends %SOAP.WebService [ System = 4 ]
{

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
 set check=$system.Security.Check("%Development","USE")
 if check {
 	set check=##super()	
 }
 quit check
}

/// Name of the WebService.
Parameter SERVICENAME = "%WebStress";

/// TODO: change this to actual network address.
/// URL for invoking the WebService.
Parameter LOCATION = "http://localhost/csp/webdeploy";

/// TODO: change this to actual SOAP namespace.
/// SOAP Namespace for the WebService
Parameter NAMESPACE = "http://tempuri.org";

/// Prepares the processes ready for the test
ClassMethod StartProcs(testID As %String, runNumber As %Integer, param As %Integer, senderID As %String, senderTime As %Integer) As %WebStress.Control [ WebMethod ]
{
	set $ztrap="Trap"
	Quit ##class(%WebStress.Control).StartProcs(testID,runNumber,param,senderID,senderTime)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod StartMonitor(runNumber As %Integer, testID As %String, senderID As %String, runDescription As %String) As %Status [ WebMethod ]
{
	set $ztrap="Trap"
	Quit ##class(%WebStress.Control).StartMonitor(runNumber,testID,senderID,runDescription)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod DownloadData(stream As %GlobalBinaryStream, senderID As %String) As %String [ WebMethod ]
{
	set $ztrap="Trap"
	Quit ##class(%WebStress.Control).DownloadData(stream,senderID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod BuildCode(stream As %GlobalBinaryStream, senderID As %String) As %String [ WebMethod ]
{
	set $ztrap="Trap"
	Quit ##class(%WebStress.Control).BuildCode(stream,senderID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod CheckDataValid(request As %WebStress.Control.ValidData.Request) As %WebStress.Control.ValidData.Response.Generators [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).GeneratorDataValid(request)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod CheckGeneratorRunStatus(testID As %String, senderID As %String) As %WebStress.Control.GeneratorStatus [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).GeneratorRunStatus(testID,senderID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod CheckGeneratorIsRunning(testID As %String, senderID As %String) As %WebStress.Control.GeneratorStatus [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).GeneratorIsRunning(testID,senderID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod GetMaxRunNumber(testID As %String) As %Integer [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).GetMaxRunNumber(testID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod TestStart(testID As %String) As %Integer [ WebMethod ]
{
	set $ztrap="Trap"
	set ^WebStress.RunFlag(testID)=1
	quit $$$OK
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod TestStop(testID As %String) As %Integer [ WebMethod ]
{
	set $ztrap="Trap"
	set ^WebStress.RunFlag(testID)=2
	set $li(^WebStress.ControlD(testID),9)=6  //  Stopping
	quit $$$OK
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod GetRunData(testID As %String) As %String [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).RunData(testID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod GetIterationData(testID As %String, run As %Integer) As %String [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).IterationData(testID,run)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod StartDataTransfer(runID As %Integer, testID As %String, serverPort As %Integer, senderID As %String, generator As %String) As %String [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.DataTransfer).StartTransfer(runID,testID,serverPort,senderID,generator)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod ResetControlData(testID As %String, senderID As %String) As %String [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).SetControlData(testID,senderID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod AnyTestsRunning() As %Integer [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).AnyTestsRunning()
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod GetErrors(testID As %String, runID As %Integer, scriptID As %String) As %GlobalCharacterStream [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).GetErrors(testID,runID,scriptID)
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod GetGenID() As %String [ WebMethod ]
{
	set $ztrap="Trap"
	quit ##class(%WebStress.Control).SystemID()
Trap
	set $ztrap=""
	quit $zerror
}

ClassMethod TestAuthenticate() As %Status [ WebMethod ]
{
	quit $$$OK
}

}
